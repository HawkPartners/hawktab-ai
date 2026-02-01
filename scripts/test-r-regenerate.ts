#!/usr/bin/env npx tsx
/**
 * Regenerate R Output
 *
 * Regenerates R script and results from an existing pipeline run.
 * Useful for testing changes to RScriptGeneratorV2 without full pipeline.
 *
 * Usage:
 *   npx tsx scripts/test-r-regenerate.ts [dataset] [pipelineId] [--skip-validation]
 *
 * Examples:
 *   npx tsx scripts/test-r-regenerate.ts
 *     -> Uses most recent pipeline from first dataset in outputs/
 *
 *   npx tsx scripts/test-r-regenerate.ts leqvio-monotherapy-demand-NOV217
 *     -> Uses most recent pipeline from that dataset
 *
 *   npx tsx scripts/test-r-regenerate.ts leqvio-monotherapy-demand-NOV217 pipeline-2026-01-28T12-10-00
 *     -> Uses specific pipeline
 *
 *   npx tsx scripts/test-r-regenerate.ts --skip-validation
 *     -> Skip R validation step (faster, no per-table retries)
 *
 * Output:
 *   Incremented files within the same pipeline folder:
 *     r/master-1.R, r/master-2.R, ...
 *     results/tables-1.json, tables-2.json, ...
 *     results/crosstabs-1.xlsx, crosstabs-2.xlsx, ...
 *     validation/validation-report-1.json, ...
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';
import { generateRScriptV2 } from '../src/lib/r/RScriptGeneratorV2';
import { validateAndFixTables } from '../src/lib/r/ValidationOrchestrator';
import { formatTablesFileToBuffer } from '../src/lib/excel/ExcelFormatter';
import { processSurvey } from '../src/lib/processors/SurveyProcessor';
import type { ExtendedTableDefinition } from '../src/schemas/verificationAgentSchema';
import type { CutDefinition, CutGroup } from '../src/lib/tables/CutsSpec';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';

// =============================================================================
// Console Colors
// =============================================================================

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

// =============================================================================
// Parse Arguments
// =============================================================================

// Parse --skip-validation flag
const skipValidation = process.argv.includes('--skip-validation');

// Parse positional arguments (dataset, pipelineId)
const args = process.argv.slice(2).filter(arg => !arg.startsWith('--'));
const argDataset = args[0];
const argPipelineId = args[1];

// =============================================================================
// File Discovery
// =============================================================================

const OUTPUTS_DIR = path.join(process.cwd(), 'outputs');

/**
 * Find all dataset folders in outputs/
 */
async function findDatasets(): Promise<string[]> {
  try {
    const entries = await fs.readdir(OUTPUTS_DIR, { withFileTypes: true });
    return entries
      .filter(e => e.isDirectory() && !e.name.startsWith('.'))
      .map(e => e.name)
      .sort();
  } catch {
    return [];
  }
}

/**
 * Find most recent pipeline folder within a dataset
 */
async function findMostRecentPipeline(dataset: string): Promise<string | null> {
  const datasetPath = path.join(OUTPUTS_DIR, dataset);

  try {
    const entries = await fs.readdir(datasetPath, { withFileTypes: true });
    const pipelines = entries
      .filter(e => e.isDirectory() && e.name.startsWith('pipeline-'))
      .map(e => e.name)
      .sort()
      .reverse();

    return pipelines[0] || null;
  } catch {
    return null;
  }
}

/**
 * Find next available output filename (increments to avoid overwriting)
 */
async function findNextOutputPath(
  dir: string,
  baseName: string,
  ext: string
): Promise<{ path: string; index: number }> {
  try {
    const entries = await fs.readdir(dir);
    const existing = entries.filter(e => e.startsWith(baseName) && e.endsWith(ext));

    if (existing.length === 0) {
      // First regeneration creates -1 version
      return { path: path.join(dir, `${baseName}-1${ext}`), index: 1 };
    }

    // Find highest number
    let maxNum = 0;
    for (const file of existing) {
      const match = file.match(new RegExp(`^${baseName}(?:-(\\d+))?\\${ext}$`));
      if (match) {
        const num = match[1] ? parseInt(match[1], 10) : 0;
        maxNum = Math.max(maxNum, num);
      }
    }

    const nextIndex = maxNum + 1;
    return { path: path.join(dir, `${baseName}-${nextIndex}${ext}`), index: nextIndex };
  } catch {
    return { path: path.join(dir, `${baseName}-1${ext}`), index: 1 };
  }
}

/**
 * Find a JSON file by pattern in a directory.
 */
async function findJsonFile(dir: string, pattern: string): Promise<string | null> {
  try {
    const files = await fs.readdir(dir);
    const match = files.find(f => f.includes(pattern) && f.endsWith('.json'));
    if (match) return path.join(dir, match);
  } catch {
    // Directory doesn't exist
  }
  return null;
}

/**
 * Find the SPSS data file. Checks data/<dataset>/inputs/.
 */
async function findSpssFile(dataset: string): Promise<string | null> {
  const dataInputsDir = path.join(process.cwd(), 'data', dataset, 'inputs');

  try {
    const inputFiles = await fs.readdir(dataInputsDir);
    const spssFile = inputFiles.find(f => f.endsWith('.sav'));
    if (spssFile) return path.join(dataInputsDir, spssFile);
  } catch {
    // Directory doesn't exist
  }

  return null;
}

/**
 * Find and process the survey markdown.
 */
async function findSurveyMarkdown(dataset: string, pipelinePath: string): Promise<string | null> {
  const dataInputsDir = path.join(process.cwd(), 'data', dataset, 'inputs');

  try {
    const inputFiles = await fs.readdir(dataInputsDir);
    const surveyFile = inputFiles.find(f =>
      (f.toLowerCase().includes('survey') || f.toLowerCase().includes('questionnaire')) &&
      (f.endsWith('.docx') || f.endsWith('.pdf'))
    );
    if (surveyFile) {
      const surveyResult = await processSurvey(path.join(dataInputsDir, surveyFile), pipelinePath);
      return surveyResult.markdown;
    }
  } catch {
    // Can't process survey
  }

  return null;
}

/**
 * Find the verbose datamap file.
 */
async function findVerboseDatamap(pipelinePath: string): Promise<VerboseDataMapType[] | null> {
  const datamapFile = await findJsonFile(pipelinePath, 'datamap-verbose');
  if (datamapFile) {
    const data = JSON.parse(await fs.readFile(datamapFile, 'utf-8'));
    return data as VerboseDataMapType[];
  }
  return null;
}

// =============================================================================
// Load Pipeline Data
// =============================================================================

interface CrosstabOutput {
  bannerCuts: Array<{
    groupName: string;
    columns: Array<{
      name: string;
      adjusted: string;
      confidence: number;
      reason: string;
    }>;
  }>;
}

interface VerifiedTableOutput {
  tables: ExtendedTableDefinition[];
}

function loadCutsFromCrosstabOutput(data: CrosstabOutput): { cuts: CutDefinition[]; cutGroups: CutGroup[] } {
  const cuts: CutDefinition[] = [];
  const cutGroups: CutGroup[] = [];

  let letterIndex = 0;
  const getNextLetter = () => {
    if (letterIndex < 26) {
      return String.fromCharCode(65 + letterIndex++);
    }
    const first = Math.floor(letterIndex / 26) - 1;
    const second = letterIndex % 26;
    letterIndex++;
    return String.fromCharCode(65 + first) + String.fromCharCode(65 + second);
  };

  for (const group of data.bannerCuts || []) {
    const groupCutDefs: CutDefinition[] = [];

    for (let i = 0; i < (group.columns || []).length; i++) {
      const col = group.columns[i];
      if (col.name && col.adjusted && col.confidence > 0) {
        const isTotal = col.name === 'Total' || group.groupName === 'Total';
        const statLetter = isTotal ? 'T' : getNextLetter();

        const cutDef: CutDefinition = {
          id: `${group.groupName.toLowerCase().replace(/\s+/g, '-')}.${col.name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')}`,
          name: col.name,
          rExpression: col.adjusted,
          statLetter,
          groupName: group.groupName,
          groupIndex: i,
        };
        cuts.push(cutDef);
        groupCutDefs.push(cutDef);
      }
    }

    if (groupCutDefs.length > 0) {
      cutGroups.push({
        groupName: group.groupName,
        cuts: groupCutDefs,
      });
    }
  }

  return { cuts, cutGroups };
}

// =============================================================================
// Run R Script
// =============================================================================

async function runRScript(scriptPath: string, workingDir: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const rscriptPaths = [
      '/opt/homebrew/bin/Rscript',
      '/usr/local/bin/Rscript',
      '/usr/bin/Rscript',
      'Rscript',
    ];

    let rscriptPath = 'Rscript';
    for (const p of rscriptPaths) {
      try {
        require('child_process').execSync(`${p} --version`, { stdio: 'ignore' });
        rscriptPath = p;
        break;
      } catch {
        // Try next
      }
    }

    log(`  Running: ${rscriptPath} ${path.basename(scriptPath)}`, 'dim');

    const proc = spawn(rscriptPath, [scriptPath], {
      cwd: workingDir,
    });

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      stdout += data.toString();
    });

    proc.stderr.on('data', (data) => {
      stderr += data.toString();
      // Only print actual errors, not package loading messages
      const msg = data.toString();
      if (!msg.includes('Attaching package') && !msg.includes('masked from')) {
        process.stderr.write(data);
      }
    });

    proc.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`R script failed with code ${code}\n${stderr}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const startTime = Date.now();
  const totalSteps = skipValidation ? 5 : 6;

  log('');
  log('======================================================================', 'magenta');
  log('  Regenerate R Output', 'bright');
  if (skipValidation) log('  (validation skipped)', 'yellow');
  log('======================================================================', 'magenta');
  log('');

  // 1. Find source pipeline
  log(`[1/${totalSteps}] Finding source pipeline...`, 'cyan');

  let dataset = argDataset;
  let pipelineId = argPipelineId;

  // Find dataset if not provided
  if (!dataset) {
    const datasets = await findDatasets();
    if (datasets.length === 0) {
      log('No datasets found in outputs/', 'red');
      process.exit(1);
    }
    dataset = datasets[0];
    log(`  Using dataset: ${dataset}`, 'dim');
  }

  // Find pipeline if not provided
  if (!pipelineId) {
    const foundPipeline = await findMostRecentPipeline(dataset);
    if (!foundPipeline) {
      log(`No pipeline folders found in outputs/${dataset}/`, 'red');
      process.exit(1);
    }
    pipelineId = foundPipeline;
    log(`  Using most recent pipeline: ${pipelineId}`, 'dim');
  }

  const pipelinePath = path.join(OUTPUTS_DIR, dataset, pipelineId);

  // Verify pipeline exists
  try {
    await fs.access(pipelinePath);
  } catch {
    log(`Pipeline not found: ${pipelinePath}`, 'red');
    process.exit(1);
  }

  log(`  Source: outputs/${dataset}/${pipelineId}`, 'blue');

  // 2. Load verified tables and cuts
  log('');
  log(`[2/${totalSteps}] Loading pipeline data...`, 'cyan');

  // Find verified tables (try verified-table-output first, then verification-output-raw)
  const verificationDir = path.join(pipelinePath, 'verification');
  let verifiedTablesFile = await findJsonFile(verificationDir, 'verified-table-output');
  if (!verifiedTablesFile) {
    verifiedTablesFile = await findJsonFile(verificationDir, 'verification-output-raw');
  }

  // Find crosstab output
  const crosstabDir = path.join(pipelinePath, 'crosstab');
  const crosstabFile = await findJsonFile(crosstabDir, 'crosstab-output');

  if (!verifiedTablesFile) {
    log('  Missing: verified tables (verification/verified-table-output-*.json)', 'red');
    process.exit(1);
  }
  if (!crosstabFile) {
    log('  Missing: crosstab output (crosstab/crosstab-output-*.json)', 'red');
    process.exit(1);
  }

  const verifiedData: VerifiedTableOutput = JSON.parse(await fs.readFile(verifiedTablesFile, 'utf-8'));
  const crosstabData: CrosstabOutput = JSON.parse(await fs.readFile(crosstabFile, 'utf-8'));

  let tables = verifiedData.tables;
  const { cuts, cutGroups } = loadCutsFromCrosstabOutput(crosstabData);

  log(`  Loaded ${tables.length} tables`, 'green');
  log(`  Loaded ${cuts.length} cuts in ${cutGroups.length} groups`, 'green');

  // 3. Find SPSS file and copy to working location
  const spssSourcePath = await findSpssFile(dataset);
  if (!spssSourcePath) {
    log(`  Missing: SPSS file in data/${dataset}/inputs/`, 'red');
    process.exit(1);
  }
  log(`  SPSS: ${path.basename(spssSourcePath)}`, 'dim');

  // Copy SPSS to pipeline folder (temporary)
  const spssDestPath = path.join(pipelinePath, 'dataFile.sav');
  await fs.copyFile(spssSourcePath, spssDestPath);
  log(`  Copied SPSS data to pipeline folder`, 'dim');

  // 4. R Validation step (unless skipped)
  let regenerationIndex = 1;

  if (!skipValidation) {
    log('');
    log(`[3/${totalSteps}] Validating R code per table...`, 'cyan');

    // Load survey markdown and datamap for retry capability
    const surveyMarkdown = await findSurveyMarkdown(dataset, pipelinePath);
    const verboseDataMap = await findVerboseDatamap(pipelinePath);

    if (!surveyMarkdown) {
      log('  Survey not found - retries will use passthrough', 'yellow');
    }
    if (!verboseDataMap) {
      log('  Datamap not found - retries will use empty context', 'yellow');
    }

    const { validTables, excludedTables, validationReport } = await validateAndFixTables(
      tables,
      cuts,
      surveyMarkdown || '',
      verboseDataMap || [],
      {
        outputDir: pipelinePath,
        maxRetries: 3,
        dataFilePath: 'dataFile.sav',
        verbose: true,
      }
    );

    log(`  Passed first time: ${validationReport.passedFirstTime}`, 'green');
    if (validationReport.fixedAfterRetry > 0) {
      log(`  Fixed after retry: ${validationReport.fixedAfterRetry}`, 'yellow');
    }
    if (excludedTables.length > 0) {
      log(`  Excluded: ${excludedTables.length}`, 'red');
    }

    // Use all tables (valid + excluded) so excluded sheet still works
    tables = [...validTables, ...excludedTables];

    // Find next validation report index
    const validationDir = path.join(pipelinePath, 'validation');
    const { index } = await findNextOutputPath(validationDir, 'validation-report', '.json');
    regenerationIndex = index;

    // Save validation report with incremented name
    const reportPath = path.join(validationDir, `validation-report-${regenerationIndex}.json`);
    await fs.writeFile(reportPath, JSON.stringify(validationReport, null, 2), 'utf-8');
    log(`  Saved: validation/validation-report-${regenerationIndex}.json`, 'dim');
  } else {
    // If skipping validation, determine regeneration index from existing R scripts
    const rDir = path.join(pipelinePath, 'r');
    const { index } = await findNextOutputPath(rDir, 'master', '.R');
    regenerationIndex = index;
  }

  // Step numbers depend on whether validation is skipped
  const rStepNum = skipValidation ? 3 : 4;
  const runStepNum = skipValidation ? 4 : 5;
  const excelStepNum = skipValidation ? 5 : 6;

  // 5. Generate R script
  log('');
  log(`[${rStepNum}/${totalSteps}] Generating R script...`, 'cyan');

  const rDir = path.join(pipelinePath, 'r');
  await fs.mkdir(rDir, { recursive: true });

  const rScript = generateRScriptV2({
    tables,
    cuts,
    cutGroups,
    dataFilePath: 'dataFile.sav',
    significanceLevel: 0.10,
    bannerGroups: cutGroups.map(g => ({
      groupName: g.groupName,
      columns: g.cuts.map(c => ({ name: c.name, statLetter: c.statLetter })),
    })),
  });

  const rScriptPath = path.join(rDir, `master-${regenerationIndex}.R`);
  await fs.writeFile(rScriptPath, rScript);
  log(`  Saved: r/master-${regenerationIndex}.R (${Math.round(rScript.length / 1024)} KB)`, 'green');

  // 6. Run R script
  log('');
  log(`[${runStepNum}/${totalSteps}] Running R script...`, 'cyan');

  // Create results directory if needed
  const resultsDir = path.join(pipelinePath, 'results');
  await fs.mkdir(resultsDir, { recursive: true });

  // The R script writes to results/tables.json, so we need to run it then rename
  try {
    await runRScript(rScriptPath, pipelinePath);
    log('  R script completed', 'green');

    // Rename tables.json to tables-N.json
    const tablesJsonPath = path.join(resultsDir, 'tables.json');
    const tablesJsonNewPath = path.join(resultsDir, `tables-${regenerationIndex}.json`);

    try {
      await fs.access(tablesJsonPath);
      await fs.rename(tablesJsonPath, tablesJsonNewPath);
      log(`  Renamed: results/tables.json → tables-${regenerationIndex}.json`, 'dim');
    } catch {
      log('  Missing: results/tables.json (R script may have failed)', 'red');
      process.exit(1);
    }

    // 7. Generate Excel
    log('');
    log(`[${excelStepNum}/${totalSteps}] Generating Excel...`, 'cyan');

    try {
      const excelBuffer = await formatTablesFileToBuffer(tablesJsonNewPath);
      const { path: excelPath } = await findNextOutputPath(resultsDir, 'crosstabs', '.xlsx');
      await fs.writeFile(excelPath, excelBuffer);
      log(`  Saved: results/${path.basename(excelPath)}`, 'green');
    } catch (err) {
      log(`  Excel generation failed: ${err}`, 'red');
      process.exit(1);
    }

  } catch (err) {
    log(`  R script failed: ${err}`, 'red');
    process.exit(1);
  }

  // Cleanup SPSS file
  try {
    await fs.unlink(spssDestPath);
    log(`  Cleaned up dataFile.sav`, 'dim');
  } catch {
    // ignore
  }

  // Summary
  const totalDuration = Date.now() - startTime;
  log('');
  log('======================================================================', 'green');
  log('  Complete!', 'bright');
  log('======================================================================', 'green');
  log('');
  log(`Duration: ${(totalDuration / 1000).toFixed(1)}s`, 'blue');
  log(`Pipeline: outputs/${dataset}/${pipelineId}`, 'blue');
  log(`Regeneration: #${regenerationIndex}`, 'blue');
  log('');
  log('Files:', 'yellow');
  log(`  r/master-${regenerationIndex}.R            - Generated R script`, 'dim');
  log(`  results/tables-${regenerationIndex}.json   - R calculations`, 'dim');
  log(`  results/crosstabs-${regenerationIndex}.xlsx - Excel workbook`, 'dim');
  if (!skipValidation) {
    log(`  validation/validation-report-${regenerationIndex}.json - Validation results`, 'dim');
  }
  log('');
  log('Compare with original:', 'yellow');
  log(`  Original: results/crosstabs.xlsx`, 'dim');
  log(`  New:      results/crosstabs-${regenerationIndex}.xlsx`, 'dim');
  log('');
}

main().catch((err) => {
  log(`Error: ${err.message}`, 'red');
  console.error(err);
  process.exit(1);
});
