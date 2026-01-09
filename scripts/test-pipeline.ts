#!/usr/bin/env npx tsx
/**
 * Pipeline Test Script
 *
 * Purpose: Run the full processing pipeline from raw files to Excel output,
 * without requiring the UI.
 *
 * Usage:
 *   npx tsx scripts/test-pipeline.ts [dataset-folder]
 *
 * Examples:
 *   npx tsx scripts/test-pipeline.ts
 *   # Uses default: data/leqvio-monotherapy-demand-NOV217/
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
import { processDataMap as processTableAgent } from '../src/agents/TableAgent';
import { verifyAllTables } from '../src/agents/VerificationAgent';
import { processSurvey } from '../src/lib/processors/SurveyProcessor';
import { generateRScriptV2WithValidation, type ValidationReport } from '../src/lib/r/RScriptGeneratorV2';
import { buildCutsSpec } from '../src/lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '../src/lib/tables/sortTables';
import { ExcelFormatter } from '../src/lib/excel/ExcelFormatter';
import { extractStreamlinedData } from '../src/lib/data/extractStreamlinedData';
import { getPromptVersions } from '../src/lib/env';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';
import type { ExtendedTableDefinition } from '../src/schemas/verificationAgentSchema';

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
  const totalSteps = 8;  // Added VerificationAgent step

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
  // Step 2: BannerAgent
  // -------------------------------------------------------------------------
  logStep(2, totalSteps, 'Extracting banner plan...');
  log(`  Using prompt version: ${promptVersions.bannerPromptVersion}`, 'dim');
  const stepStart2 = Date.now();

  const bannerAgent = new BannerAgent();
  const bannerResult = await bannerAgent.processDocument(files.banner, outputDir);

  if (!bannerResult.success) {
    log(`  WARNING: Banner extraction had issues`, 'yellow');
  }
  const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
  const groupCount = extractedStructure?.bannerCuts?.length || 0;
  const columnCount = (extractedStructure?.processingMetadata as { totalColumns?: number })?.totalColumns || 0;
  log(`  Extracted ${groupCount} groups, ${columnCount} columns`, 'green');
  log(`  Duration: ${Date.now() - stepStart2}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 3: CrosstabAgent
  // -------------------------------------------------------------------------
  logStep(3, totalSteps, 'Validating banner expressions...');
  log(`  Using prompt version: ${promptVersions.crosstabPromptVersion}`, 'dim');
  const stepStart3 = Date.now();

  // Build simple data structures for CrosstabAgent
  const agentDataMap = dataMapResult.agent.map(v => ({
    Column: v.Column,
    Description: v.Description,
    Answer_Options: v.Answer_Options,
  }));

  const agentBanner = bannerResult.agent || [];

  const crosstabResult = await processCrosstabGroups(
    agentDataMap,
    { bannerCuts: agentBanner.map(g => ({ groupName: g.groupName, columns: g.columns })) },
    outputDir,
    (completed, total) => {
      process.stdout.write(`\r  Processing group ${completed}/${total}...`);
    }
  );
  console.log(''); // Clear the progress line

  log(`  Validated ${crosstabResult.result.bannerCuts.length} groups`, 'green');
  log(`  Duration: ${Date.now() - stepStart3}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 4: TableAgent
  // -------------------------------------------------------------------------
  logStep(4, totalSteps, 'Analyzing table structures...');
  log(`  Using prompt version: ${promptVersions.tablePromptVersion}`, 'dim');
  const stepStart4 = Date.now();

  const { results: tableAgentResults } = await processTableAgent(verboseDataMap, outputDir);
  const tableAgentTables = tableAgentResults.flatMap(r => r.tables);

  log(`  Generated ${tableAgentTables.length} table definitions`, 'green');
  log(`  Duration: ${Date.now() - stepStart4}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 5: VerificationAgent
  // -------------------------------------------------------------------------
  logStep(5, totalSteps, 'Verifying tables with survey document...');
  log(`  Using prompt version: ${promptVersions.verificationPromptVersion}`, 'dim');
  const stepStart5 = Date.now();

  let verifiedTables: ExtendedTableDefinition[];

  if (files.survey) {
    try {
      // First, process the survey document to get markdown
      log(`  Processing survey: ${path.basename(files.survey)}`, 'dim');
      const surveyResult = await processSurvey(files.survey, outputDir);

      if (!surveyResult.markdown) {
        throw new Error(`Survey processing failed: ${surveyResult.warnings.join(', ')}`);
      }

      log(`  Survey markdown: ${surveyResult.markdown.length} characters`, 'dim');

      // Now run VerificationAgent with the markdown
      const verificationResult = await verifyAllTables(
        tableAgentResults,
        surveyResult.markdown,
        verboseDataMap,
        { outputDir }
      );
      verifiedTables = verificationResult.tables;
      log(`  Verified ${verifiedTables.length} tables (${verificationResult.metadata.tablesModified} modified)`, 'green');
    } catch (verifyError) {
      log(`  VerificationAgent failed, using TableAgent output: ${verifyError instanceof Error ? verifyError.message : String(verifyError)}`, 'yellow');
      // Fallback: convert TableAgent output to ExtendedTableDefinition format with questionId
      const { toExtendedTable } = await import('../src/schemas/verificationAgentSchema');
      verifiedTables = tableAgentResults.flatMap(group =>
        group.tables.map(t => toExtendedTable(t, group.questionId))
      );

      // Still create verification folder with raw output for consistency
      const verificationDir = path.join(outputDir, 'verification');
      await fs.mkdir(verificationDir, { recursive: true });
      const rawOutput = { tables: verifiedTables };
      await fs.writeFile(
        path.join(verificationDir, 'verification-output-raw.json'),
        JSON.stringify(rawOutput, null, 2),
        'utf-8'
      );
    }
  } else {
    log(`  No survey file - using TableAgent output directly`, 'yellow');
    // Convert TableAgent output to ExtendedTableDefinition format with questionId
    const { toExtendedTable } = await import('../src/schemas/verificationAgentSchema');
    verifiedTables = tableAgentResults.flatMap(group =>
      group.tables.map(t => toExtendedTable(t, group.questionId))
    );

    // Still create verification folder with raw output for consistency
    const verificationDir = path.join(outputDir, 'verification');
    await fs.mkdir(verificationDir, { recursive: true });
    const rawOutput = { tables: verifiedTables };
    await fs.writeFile(
      path.join(verificationDir, 'verification-output-raw.json'),
      JSON.stringify(rawOutput, null, 2),
      'utf-8'
    );
  }

  log(`  Duration: ${Date.now() - stepStart5}ms`, 'dim');
  log('', 'reset');

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
      const formatter = new ExcelFormatter();
      await formatter.formatFromFile(tablesJsonPath);
      await formatter.saveToFile(excelPath);

      log(`  Generated crosstabs.xlsx`, 'green');
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

  log('', 'reset');
  log('='.repeat(70), 'magenta');
  log('  Pipeline Complete', 'bright');
  log('='.repeat(70), 'magenta');
  log(`  Dataset:     ${files.name}`, 'reset');
  log(`  Variables:   ${verboseDataMap.length}`, 'reset');
  log(`  Tables:      ${sortedTables.length} (${tableAgentTables.length} from TableAgent)`, 'reset');
  log(`  Cuts:        ${cutsSpec.cuts.length + 1} (including Total)`, 'reset');
  log(`  Duration:    ${(totalDuration / 1000).toFixed(1)}s`, 'reset');
  log(`  Output:      outputs/${files.name}/${outputFolder}/`, 'reset');
  log('', 'reset');

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
      tableAgentTables: tableAgentTables.length,
      verifiedTables: sortedTables.length,
      cuts: cutsSpec.cuts.length + 1,
      bannerGroups: groupCount,
      sorting: {
        screeners: sortingMetadata.screenerCount,
        main: sortingMetadata.mainCount,
        other: sortingMetadata.otherCount,
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
  const datasetFolder = process.argv[2] || DEFAULT_DATASET;

  try {
    await runPipeline(datasetFolder);
  } catch (error) {
    log('', 'reset');
    log(`ERROR: ${error instanceof Error ? error.message : String(error)}`, 'red');
    process.exit(1);
  }
}

main().catch(console.error);
