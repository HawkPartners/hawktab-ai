#!/usr/bin/env npx tsx
/**
 * Pipeline Test Script
 *
 * Purpose: Run the full processing pipeline from raw files to Excel output,
 * without requiring the UI.
 *
 * Usage:
 *   npx tsx scripts/test-pipeline.ts [dataset-folder] [options]
 *
 * Options:
 *   --format=joe|antares     Excel format (default: joe)
 *   --display=frequency|counts|both   Display mode (default: frequency)
 *   --stop-after-verification   Stop before R/Excel generation
 *
 * Examples:
 *   npx tsx scripts/test-pipeline.ts
 *   # Uses default: data/leqvio-monotherapy-demand-NOV217/, format=joe, display=frequency
 *
 *   npx tsx scripts/test-pipeline.ts --format=joe --display=both
 *   # Joe format with both Percentages and Counts sheets
 *
 *   npx tsx scripts/test-pipeline.ts --format=antares
 *   # Legacy Antares format (3 rows per answer)
 *
 *   npx tsx scripts/test-pipeline.ts data/test-data/some-dataset
 *   # Explicit path to dataset folder
 *
 * Required files in dataset folder (or inputs/ subfolder):
 *   - *datamap*.csv  (datamap file)
 *   - *banner*.docx  (banner plan)
 *   - *.sav          (SPSS data file)
 *
 * Supports nested structure:
 *   dataset-folder/
 *   ├── inputs/           # Input files go here
 *   ├── tabs/             # Reference output (Joe's tabs)
 *   └── golden-datasets/  # For evaluation framework
 *
 * Pipeline stages:
 *   1. DataMapProcessor → Verbose datamap JSON
 *   2. BannerAgent → Banner extraction JSON
 *   3. CrosstabAgent → Validation with cuts
 *   4. TableAgent → Table definitions
 *   5. RScriptGeneratorV2 → master.R
 *   6. R execution → results/tables.json
 *   7. ExcelFormatter → results/crosstabs.xlsx
 *
 * Output:
 *   outputs/<dataset>/pipeline-<timestamp>/
 */

// Load environment variables
import { loadEnvConfig } from '@next/env';
loadEnvConfig(process.cwd());

import fs from 'fs/promises';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

// Processors and agents
import { DataMapProcessor } from '../src/lib/processors/DataMapProcessor';
import { BannerAgent } from '../src/agents/BannerAgent';
import { processAllGroups as processCrosstabGroups } from '../src/agents/CrosstabAgent';
import { groupDataMap } from '../src/lib/tables/DataMapGrouper';
import { generateTables, convertToLegacyFormat, getGeneratorStats } from '../src/lib/tables/TableGenerator';
import { verifyAllTablesParallel } from '../src/agents/VerificationAgent';
import { processSurvey } from '../src/lib/processors/SurveyProcessor';
import { generateRScriptV2WithValidation, type ValidationReport } from '../src/lib/r/RScriptGeneratorV2';
import { buildCutsSpec } from '../src/lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '../src/lib/tables/sortTables';
import { ExcelFormatter, type ExcelFormat, type DisplayMode } from '../src/lib/excel/ExcelFormatter';
import { extractStreamlinedData } from '../src/lib/data/extractStreamlinedData';
import { getPromptVersions } from '../src/lib/env';
import { resetMetricsCollector, getPipelineCostSummary, getMetricsCollector } from '../src/lib/observability';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';
import type { ExtendedTableDefinition } from '../src/schemas/verificationAgentSchema';

// Parse command line flags
const stopAfterVerification = process.argv.includes('--stop-after-verification');

// Parse --format flag (joe or antares, default: joe)
function parseFormatFlag(): ExcelFormat {
  const formatArg = process.argv.find(arg => arg.startsWith('--format='));
  if (formatArg) {
    const value = formatArg.split('=')[1]?.toLowerCase();
    if (value === 'antares') return 'antares';
  }
  return 'joe';
}

// Parse --display flag (frequency, counts, or both, default: frequency)
function parseDisplayFlag(): DisplayMode {
  const displayArg = process.argv.find(arg => arg.startsWith('--display='));
  if (displayArg) {
    const value = displayArg.split('=')[1]?.toLowerCase();
    if (value === 'counts') return 'counts';
    if (value === 'both') return 'both';
  }
  return 'frequency';
}

const excelFormat = parseFormatFlag();
const displayMode = parseDisplayFlag();

const execAsync = promisify(exec);

// =============================================================================
// Configuration
// =============================================================================

const DEFAULT_DATASET = 'data/leqvio-monotherapy-demand-NOV217';

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
  magenta: '\x1b[35m',
};

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logStep(step: number, total: number, message: string) {
  log(`[${step}/${total}] ${message}`, 'cyan');
}

// =============================================================================
// File Discovery
// =============================================================================

interface DatasetFiles {
  datamap: string;
  banner: string;
  spss: string;
  survey: string | null;  // Optional - needed for VerificationAgent
  name: string;
}

async function findDatasetFiles(folder: string): Promise<DatasetFiles> {
  const absFolder = path.isAbsolute(folder) ? folder : path.join(process.cwd(), folder);

  // Check for nested structure (inputs/ subfolder)
  let inputsFolder = absFolder;
  try {
    const subfolders = await fs.readdir(absFolder);
    if (subfolders.includes('inputs')) {
      inputsFolder = path.join(absFolder, 'inputs');
    }
  } catch {
    // Continue with absFolder
  }

  const files = await fs.readdir(inputsFolder);

  // Find datamap CSV
  const datamap = files.find(f =>
    f.toLowerCase().includes('datamap') && f.endsWith('.csv')
  );
  if (!datamap) {
    throw new Error(`No datamap CSV found in ${folder}. Expected file containing "datamap" with .csv extension.`);
  }

  // Find banner plan (prefer 'adjusted' > 'clean' > original)
  let banner = files.find(f =>
    f.toLowerCase().includes('banner') &&
    f.toLowerCase().includes('adjusted') &&
    (f.endsWith('.docx') || f.endsWith('.pdf'))
  );
  if (!banner) {
    banner = files.find(f =>
      f.toLowerCase().includes('banner') &&
      f.toLowerCase().includes('clean') &&
      (f.endsWith('.docx') || f.endsWith('.pdf'))
    );
  }
  if (!banner) {
    banner = files.find(f =>
      f.toLowerCase().includes('banner') &&
      (f.endsWith('.docx') || f.endsWith('.pdf'))
    );
  }
  if (!banner) {
    throw new Error(`No banner plan found in ${folder}. Expected file containing "banner" with .docx or .pdf extension.`);
  }

  // Find SPSS file
  const spss = files.find(f => f.endsWith('.sav'));
  if (!spss) {
    throw new Error(`No SPSS file found in ${folder}. Expected .sav file.`);
  }

  // Find survey/questionnaire document (optional - for VerificationAgent)
  // Priority: 1) file with 'survey' or 'questionnaire', 2) .docx that's not a banner plan
  let survey = files.find(f =>
    (f.toLowerCase().includes('survey') || f.toLowerCase().includes('questionnaire')) &&
    (f.endsWith('.docx') || f.endsWith('.pdf'))
  );
  if (!survey) {
    // Fall back to any .docx that's not a banner plan (likely the main survey document)
    survey = files.find(f =>
      f.endsWith('.docx') &&
      !f.toLowerCase().includes('banner')
    );
  }

  // Derive dataset name from folder (use the main folder, not inputs/)
  const name = path.basename(absFolder);

  return {
    datamap: path.join(inputsFolder, datamap),
    banner: path.join(inputsFolder, banner),
    spss: path.join(inputsFolder, spss),
    survey: survey ? path.join(inputsFolder, survey) : null,
    name,
  };
}

// =============================================================================
// Pipeline Stages
// =============================================================================

async function runPipeline(datasetFolder: string) {
  const startTime = Date.now();
  const totalSteps = stopAfterVerification ? 5 : 8;  // Fewer steps if stopping early

  // Reset metrics collector for this pipeline run
  resetMetricsCollector();

  log('', 'reset');
  log('='.repeat(70), 'magenta');
  log('  HawkTab AI - Pipeline Test', 'bright');
  log('='.repeat(70), 'magenta');
  log('', 'reset');

  // Discover files
  log(`Dataset folder: ${datasetFolder}`, 'blue');
  const files = await findDatasetFiles(datasetFolder);
  log(`  Datamap: ${path.basename(files.datamap)}`, 'dim');
  log(`  Banner:  ${path.basename(files.banner)}`, 'dim');
  log(`  SPSS:    ${path.basename(files.spss)}`, 'dim');
  log(`  Survey:  ${files.survey ? path.basename(files.survey) : '(not found - VerificationAgent will use passthrough)'}`, 'dim');
  log('', 'reset');

  // Get prompt versions for logging
  const promptVersions = getPromptVersions();
  log('Prompt Versions:', 'blue');
  log(`  Banner:        ${promptVersions.bannerPromptVersion}`, 'dim');
  log(`  Crosstab:      ${promptVersions.crosstabPromptVersion}`, 'dim');
  log(`  Table:         ${promptVersions.tablePromptVersion}`, 'dim');
  log(`  Verification:  ${promptVersions.verificationPromptVersion}`, 'dim');
  log('', 'reset');

  // Create output folder: outputs/<dataset>/pipeline-<timestamp>/
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFolder = `pipeline-${timestamp}`;
  const outputDir = path.join(process.cwd(), 'outputs', files.name, outputFolder);
  await fs.mkdir(outputDir, { recursive: true });
  log(`Output folder: outputs/${files.name}/${outputFolder}`, 'blue');
  log('', 'reset');

  // Copy SPSS file to output folder (needed for R)
  const spssDestPath = path.join(outputDir, 'dataFile.sav');
  await fs.copyFile(files.spss, spssDestPath);

  // -------------------------------------------------------------------------
  // Step 1: DataMapProcessor
  // -------------------------------------------------------------------------
  logStep(1, totalSteps, 'Processing datamap CSV...');
  const stepStart1 = Date.now();

  const dataMapProcessor = new DataMapProcessor();
  const dataMapResult = await dataMapProcessor.processDataMap(files.datamap, files.spss, outputDir);
  const verboseDataMap = dataMapResult.verbose as VerboseDataMapType[];
  log(`  Processed ${verboseDataMap.length} variables`, 'green');
  log(`  Duration: ${Date.now() - stepStart1}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Steps 2-5: Parallel Path Execution
  // Path A: BannerAgent → CrosstabAgent
  // Path B: TableAgent → Survey → VerificationAgent
  // -------------------------------------------------------------------------
  log('', 'reset');
  logStep(2, totalSteps, 'Starting parallel paths...');
  log(`  Path A: BannerAgent → CrosstabAgent`, 'dim');
  log(`  Path B: TableAgent → VerificationAgent`, 'dim');
  log('', 'reset');

  const parallelStartTime = Date.now();

  // Build simple data structures for CrosstabAgent
  const agentDataMap = dataMapResult.agent.map(v => ({
    Column: v.Column,
    Description: v.Description,
    Answer_Options: v.Answer_Options,
  }));

  // Path A: BannerAgent → CrosstabAgent
  const pathAPromise = (async () => {
    const pathAStart = Date.now();
    log(`  [Path A] Starting BannerAgent...`, 'cyan');

    const bannerAgent = new BannerAgent();
    const bannerResult = await bannerAgent.processDocument(files.banner, outputDir);

    if (!bannerResult.success) {
      log(`  [Path A] WARNING: Banner extraction had issues`, 'yellow');
    }

    const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
    const groupCount = extractedStructure?.bannerCuts?.length || 0;
    const columnCount = (extractedStructure?.processingMetadata as { totalColumns?: number })?.totalColumns || 0;

    if (groupCount === 0) {
      throw new Error('Banner extraction failed - 0 groups extracted');
    }

    log(`  [Path A] BannerAgent: ${groupCount} groups, ${columnCount} columns`, 'green');
    log(`  [Path A] Starting CrosstabAgent...`, 'cyan');

    const agentBanner = bannerResult.agent || [];
    const crosstabResult = await processCrosstabGroups(
      agentDataMap,
      { bannerCuts: agentBanner.map(g => ({ groupName: g.groupName, columns: g.columns })) },
      outputDir
    );

    log(`  [Path A] CrosstabAgent: ${crosstabResult.result.bannerCuts.length} groups validated`, 'green');
    log(`  [Path A] Complete in ${((Date.now() - pathAStart) / 1000).toFixed(1)}s`, 'dim');

    return { bannerResult, crosstabResult, agentBanner, groupCount, columnCount };
  })();

  // Path B: TableGenerator → Survey → VerificationAgent (Parallel)
  const pathBPromise = (async () => {
    const pathBStart = Date.now();
    log(`  [Path B] Starting TableGenerator...`, 'cyan');

    // Replace TableAgent (LLM) with TableGenerator (deterministic)
    const groups = groupDataMap(verboseDataMap);
    const generatedOutputs = generateTables(groups);
    const tableAgentResults = convertToLegacyFormat(generatedOutputs);
    const tableAgentTables = tableAgentResults.flatMap(r => r.tables);
    const stats = getGeneratorStats(generatedOutputs);
    log(`  [Path B] TableGenerator: ${tableAgentTables.length} tables (${stats.tableTypeDistribution['frequency'] || 0} freq, ${stats.tableTypeDistribution['mean_rows'] || 0} mean) in ${stats.totalRows} rows`, 'green');

    // Survey processing
    let surveyMarkdown: string | null = null;
    if (files.survey) {
      log(`  [Path B] Processing survey: ${path.basename(files.survey)}`, 'cyan');
      const surveyResult = await processSurvey(files.survey, outputDir);
      surveyMarkdown = surveyResult.markdown;
      if (surveyMarkdown) {
        log(`  [Path B] Survey: ${surveyMarkdown.length} characters`, 'green');
      } else {
        log(`  [Path B] Survey processing failed: ${surveyResult.warnings.join(', ')}`, 'yellow');
      }
    }

    // VerificationAgent (Parallel)
    let verifiedTables: ExtendedTableDefinition[];
    const { toExtendedTable } = await import('../src/schemas/verificationAgentSchema');

    if (surveyMarkdown) {
      log(`  [Path B] Starting VerificationAgent (parallel, concurrency: 3)...`, 'cyan');
      try {
        const verificationResult = await verifyAllTablesParallel(
          tableAgentResults,
          surveyMarkdown,
          verboseDataMap,
          { outputDir, concurrency: 3 }
        );
        verifiedTables = verificationResult.tables;
        log(`  [Path B] VerificationAgent: ${verifiedTables.length} tables (${verificationResult.metadata.tablesModified} modified)`, 'green');
      } catch (verifyError) {
        log(`  [Path B] VerificationAgent failed: ${verifyError instanceof Error ? verifyError.message : String(verifyError)}`, 'yellow');
        verifiedTables = tableAgentResults.flatMap(group =>
          group.tables.map(t => toExtendedTable(t, group.questionId))
        );
      }
    } else {
      log(`  [Path B] No survey - using TableGenerator output directly`, 'yellow');
      verifiedTables = tableAgentResults.flatMap(group =>
        group.tables.map(t => toExtendedTable(t, group.questionId))
      );

      // Create verification folder with passthrough output
      const verificationDir = path.join(outputDir, 'verification');
      await fs.mkdir(verificationDir, { recursive: true });
      await fs.writeFile(
        path.join(verificationDir, 'verification-output-raw.json'),
        JSON.stringify({ tables: verifiedTables }, null, 2),
        'utf-8'
      );
    }

    log(`  [Path B] Complete in ${((Date.now() - pathBStart) / 1000).toFixed(1)}s`, 'dim');

    return { tableAgentResults, verifiedTables };
  })();

  // Wait for both paths
  const [pathAResult, pathBResult] = await Promise.allSettled([pathAPromise, pathBPromise]);

  const parallelDuration = Date.now() - parallelStartTime;
  log('', 'reset');
  log(`Parallel paths completed in ${(parallelDuration / 1000).toFixed(1)}s`, 'green');

  // Check results
  if (pathAResult.status === 'rejected') {
    const errorMsg = pathAResult.reason instanceof Error ? pathAResult.reason.message : String(pathAResult.reason);
    throw new Error(`Path A (Banner/Crosstab) failed: ${errorMsg}`);
  }
  if (pathBResult.status === 'rejected') {
    const errorMsg = pathBResult.reason instanceof Error ? pathBResult.reason.message : String(pathBResult.reason);
    throw new Error(`Path B (Table/Verification) failed: ${errorMsg}`);
  }

  // Extract results
  const { bannerResult, crosstabResult, agentBanner, groupCount, columnCount } = pathAResult.value;
  const { tableAgentResults, verifiedTables } = pathBResult.value;
  const tableAgentTables = tableAgentResults.flatMap(r => r.tables);

  log(`  Path A: ${groupCount} groups, ${columnCount} columns, ${crosstabResult.result.bannerCuts.length} validated`, 'dim');
  log(`  Path B: ${tableAgentTables.length} table definitions, ${verifiedTables.length} verified`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Early exit if --stop-after-verification flag
  // -------------------------------------------------------------------------
  if (stopAfterVerification) {
    log('', 'reset');
    log('--stop-after-verification flag set, skipping R script and Excel generation', 'yellow');
    log('', 'reset');

    // Print cost summary
    const costSummary = await getPipelineCostSummary();
    log(costSummary, 'magenta');

    // Still output some summary info
    const totalDuration = Date.now() - startTime;
    log('='.repeat(70), 'magenta');
    log('  Pipeline Complete (Verification Only)', 'bright');
    log('='.repeat(70), 'magenta');
    log(`  Dataset:     ${files.name}`, 'reset');
    log(`  Variables:   ${verboseDataMap.length}`, 'reset');
    log(`  Tables:      ${verifiedTables.length} (${tableAgentTables.length} from TableGenerator)`, 'reset');
    log(`  Duration:    ${(totalDuration / 1000).toFixed(1)}s`, 'reset');
    log(`  Output:      outputs/${files.name}/${outputFolder}/`, 'reset');
    log('', 'reset');

    // Save summary with costs (verification-only mode)
    const earlyExitCostMetrics = await getMetricsCollector().getSummary();
    const earlyExitSummary = {
      dataset: files.name,
      timestamp: new Date().toISOString(),
      duration: { ms: totalDuration, formatted: `${(totalDuration / 1000).toFixed(1)}s` },
      mode: 'verification-only',
      promptVersions: {
        banner: promptVersions.bannerPromptVersion,
        crosstab: promptVersions.crosstabPromptVersion,
        table: promptVersions.tablePromptVersion,
        verification: promptVersions.verificationPromptVersion,
      },
      inputs: {
        datamap: path.basename(files.datamap),
        banner: path.basename(files.banner),
        spss: path.basename(files.spss),
        survey: files.survey ? path.basename(files.survey) : null,
      },
      outputs: {
        variables: verboseDataMap.length,
        tableGeneratorTables: tableAgentTables.length,
        verifiedTables: verifiedTables.length,
        bannerGroups: groupCount,
      },
      costs: {
        byAgent: earlyExitCostMetrics.byAgent.map(a => ({
          agent: a.agentName,
          model: a.model,
          calls: a.calls,
          inputTokens: a.totalInputTokens,
          outputTokens: a.totalOutputTokens,
          durationMs: a.totalDurationMs,
          estimatedCostUsd: a.estimatedCostUsd,
        })),
        totals: {
          calls: earlyExitCostMetrics.totals.calls,
          inputTokens: earlyExitCostMetrics.totals.inputTokens,
          outputTokens: earlyExitCostMetrics.totals.outputTokens,
          totalTokens: earlyExitCostMetrics.totals.totalTokens,
          durationMs: earlyExitCostMetrics.totals.durationMs,
          estimatedCostUsd: earlyExitCostMetrics.totals.estimatedCostUsd,
        },
      },
    };
    await fs.writeFile(
      path.join(outputDir, 'pipeline-summary.json'),
      JSON.stringify(earlyExitSummary, null, 2)
    );

    return;
  }

  // -------------------------------------------------------------------------
  // Sort tables for logical Excel output order
  // -------------------------------------------------------------------------
  log('Sorting tables...', 'cyan');
  const sortingMetadata = getSortingMetadata(verifiedTables);
  const sortedTables = sortTables(verifiedTables);
  log(`  Screeners: ${sortingMetadata.screenerCount}, Main: ${sortingMetadata.mainCount}, Other: ${sortingMetadata.otherCount}`, 'dim');
  log(`  Sorted ${sortedTables.length} tables`, 'green');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 6: RScriptGeneratorV2
  // -------------------------------------------------------------------------
  logStep(6, totalSteps, 'Generating R script...');
  const stepStart6 = Date.now();

  const cutsSpec = buildCutsSpec(crosstabResult.result);
  const rDir = path.join(outputDir, 'r');
  await fs.mkdir(rDir, { recursive: true });

  // Use sorted tables (ExtendedTableDefinition) for R script generation with validation
  const { script: masterScript, validation: validationReport } = generateRScriptV2WithValidation(
    { tables: sortedTables, cuts: cutsSpec.cuts },
    { sessionId: outputFolder, outputDir: 'results' }
  );

  const masterPath = path.join(rDir, 'master.R');
  await fs.writeFile(masterPath, masterScript, 'utf-8');

  // Save validation report if there were any issues
  if (validationReport.invalidTables > 0 || validationReport.warnings.length > 0) {
    const validationPath = path.join(rDir, 'validation-report.json');
    await fs.writeFile(validationPath, JSON.stringify(validationReport, null, 2), 'utf-8');
    log(`  ⚠️  Validation issues: ${validationReport.invalidTables} invalid, ${validationReport.warnings.length} warnings`, 'yellow');
    log(`  Validation report saved to: ${validationPath}`, 'dim');
  }

  log(`  Generated R script (${Math.round(masterScript.length / 1024)} KB)`, 'green');
  log(`  Valid tables: ${validationReport.validTables}/${validationReport.totalTables}`, 'green');
  log(`  Duration: ${Date.now() - stepStart6}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 7: R Execution
  // -------------------------------------------------------------------------
  logStep(7, totalSteps, 'Executing R script...');
  const stepStart7 = Date.now();

  // Create results directory
  const resultsDir = path.join(outputDir, 'results');
  await fs.mkdir(resultsDir, { recursive: true });

  // Find R
  let rCommand = 'Rscript';
  const rPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
  for (const rPath of rPaths) {
    try {
      await execAsync(`${rPath} --version`, { timeout: 1000 });
      rCommand = rPath;
      break;
    } catch {
      // Try next
    }
  }

  try {
    await execAsync(
      `cd "${outputDir}" && ${rCommand} "${masterPath}"`,
      { maxBuffer: 10 * 1024 * 1024, timeout: 120000 }
    );

    // Check for JSON output
    const resultFiles = await fs.readdir(resultsDir);
    const jsonFile = resultFiles.find(f => f === 'tables.json');

    if (jsonFile) {
      const jsonPath = path.join(resultsDir, jsonFile);
      const jsonContent = await fs.readFile(jsonPath, 'utf-8');
      const jsonData = JSON.parse(jsonContent);
      const tableCount = Object.keys(jsonData.tables || {}).length;

      log(`  Generated tables.json with ${tableCount} tables`, 'green');

      // Extract and save streamlined data (for golden dataset evaluation)
      const streamlinedData = extractStreamlinedData(jsonData);
      const streamlinedPath = path.join(resultsDir, 'data-streamlined.json');
      await fs.writeFile(streamlinedPath, JSON.stringify(streamlinedData, null, 2), 'utf-8');
      log(`  Generated data-streamlined.json`, 'green');
    } else {
      log(`  WARNING: No tables.json generated`, 'yellow');
    }

    log(`  Duration: ${Date.now() - stepStart7}ms`, 'dim');

    // -------------------------------------------------------------------------
    // Step 8: Excel Export
    // -------------------------------------------------------------------------
    logStep(8, totalSteps, 'Generating Excel workbook...');
    const stepStart8 = Date.now();

    const tablesJsonPath = path.join(resultsDir, 'tables.json');
    const excelPath = path.join(resultsDir, 'crosstabs.xlsx');

    try {
      const formatter = new ExcelFormatter({
        format: excelFormat,
        displayMode: displayMode,
      });
      await formatter.formatFromFile(tablesJsonPath);
      await formatter.saveToFile(excelPath);

      log(`  Generated crosstabs.xlsx (format: ${excelFormat}, display: ${displayMode})`, 'green');
      log(`  Duration: ${Date.now() - stepStart8}ms`, 'dim');
    } catch (excelError) {
      log(`  Excel generation failed: ${excelError instanceof Error ? excelError.message : String(excelError)}`, 'red');
    }

  } catch (rError) {
    const errorMsg = rError instanceof Error ? rError.message : String(rError);
    // Only "R not installed" if command literally not found (not just any error with "Rscript" in path)
    if (errorMsg.includes('command not found') && !errorMsg.includes('Error in')) {
      log(`  R not installed - script saved for manual execution`, 'yellow');
    } else {
      log(`  R execution failed:`, 'red');
      log(`  ${errorMsg.substring(0, 200)}`, 'dim');
    }
  }
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Summary
  // -------------------------------------------------------------------------
  const totalDuration = Date.now() - startTime;

  // Print cost summary
  const costSummary = await getPipelineCostSummary();
  log(costSummary, 'magenta');

  log('', 'reset');
  log('='.repeat(70), 'magenta');
  log('  Pipeline Complete', 'bright');
  log('='.repeat(70), 'magenta');
  log(`  Dataset:     ${files.name}`, 'reset');
  log(`  Variables:   ${verboseDataMap.length}`, 'reset');
  log(`  Tables:      ${sortedTables.length} (${tableAgentTables.length} from TableGenerator)`, 'reset');
  log(`  Cuts:        ${cutsSpec.cuts.length + 1} (including Total)`, 'reset');
  log(`  Duration:    ${(totalDuration / 1000).toFixed(1)}s`, 'reset');
  log(`  Output:      outputs/${files.name}/${outputFolder}/`, 'reset');
  log('', 'reset');

  // Get cost metrics for summary
  const costMetrics = await getMetricsCollector().getSummary();

  // Write summary file
  const summary = {
    dataset: files.name,
    timestamp: new Date().toISOString(),
    duration: { ms: totalDuration, formatted: `${(totalDuration / 1000).toFixed(1)}s` },
    promptVersions: {
      banner: promptVersions.bannerPromptVersion,
      crosstab: promptVersions.crosstabPromptVersion,
      table: promptVersions.tablePromptVersion,
      verification: promptVersions.verificationPromptVersion,
    },
    inputs: {
      datamap: path.basename(files.datamap),
      banner: path.basename(files.banner),
      spss: path.basename(files.spss),
      survey: files.survey ? path.basename(files.survey) : null,
    },
    outputs: {
      variables: verboseDataMap.length,
      tableGeneratorTables: tableAgentTables.length,
      verifiedTables: sortedTables.length,
      cuts: cutsSpec.cuts.length + 1,
      bannerGroups: groupCount,
      sorting: {
        screeners: sortingMetadata.screenerCount,
        main: sortingMetadata.mainCount,
        other: sortingMetadata.otherCount,
      },
    },
    costs: {
      byAgent: costMetrics.byAgent.map(a => ({
        agent: a.agentName,
        model: a.model,
        calls: a.calls,
        inputTokens: a.totalInputTokens,
        outputTokens: a.totalOutputTokens,
        durationMs: a.totalDurationMs,
        estimatedCostUsd: a.estimatedCostUsd,
      })),
      totals: {
        calls: costMetrics.totals.calls,
        inputTokens: costMetrics.totals.inputTokens,
        outputTokens: costMetrics.totals.outputTokens,
        totalTokens: costMetrics.totals.totalTokens,
        durationMs: costMetrics.totals.durationMs,
        estimatedCostUsd: costMetrics.totals.estimatedCostUsd,
      },
    },
  };
  await fs.writeFile(
    path.join(outputDir, 'pipeline-summary.json'),
    JSON.stringify(summary, null, 2)
  );

  // -------------------------------------------------------------------------
  // Cleanup temporary files
  // -------------------------------------------------------------------------
  log('Cleaning up temporary files...', 'dim');
  const filesToCleanup: string[] = [];

  // Remove dataFile.sav (only needed for R execution)
  const spssPath = path.join(outputDir, 'dataFile.sav');
  try {
    await fs.unlink(spssPath);
    filesToCleanup.push('dataFile.sav');
  } catch { /* File may not exist */ }

  // Remove banner-images/ folder (input images for BannerAgent)
  const bannerImagesDir = path.join(outputDir, 'banner-images');
  try {
    await fs.rm(bannerImagesDir, { recursive: true });
    filesToCleanup.push('banner-images/');
  } catch { /* Folder may not exist */ }

  // Remove survey conversion artifacts (HTML and PNG files)
  try {
    const allFiles = await fs.readdir(outputDir);
    for (const file of allFiles) {
      // Remove HTML files from survey conversion
      if (file.endsWith('.html')) {
        await fs.unlink(path.join(outputDir, file));
        filesToCleanup.push(file);
      }
      // Remove PNG files from survey conversion (typically have _html_ in name)
      if (file.endsWith('.png') && file.includes('_html_')) {
        await fs.unlink(path.join(outputDir, file));
        filesToCleanup.push(file);
      }
    }
  } catch { /* Ignore cleanup errors */ }

  if (filesToCleanup.length > 0) {
    log(`  Removed: ${filesToCleanup.join(', ')}`, 'dim');
  }

  log('Output files:', 'blue');
  const outputFiles = await fs.readdir(outputDir);
  for (const f of outputFiles) {
    log(`  ${f}`, 'dim');
  }
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  // Find first argument that doesn't start with '--' (that's the dataset folder)
  const datasetFolder = process.argv.slice(2).find(arg => !arg.startsWith('--')) || DEFAULT_DATASET;

  try {
    await runPipeline(datasetFolder);
  } catch (error) {
    log('', 'reset');
    log(`ERROR: ${error instanceof Error ? error.message : String(error)}`, 'red');
    process.exit(1);
  }
}

main().catch(console.error);
