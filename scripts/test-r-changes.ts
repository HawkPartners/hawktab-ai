#!/usr/bin/env npx tsx
/**
 * @deprecated Use test-r-regenerate.ts instead.
 *
 * Migration:
 *   npx tsx scripts/test-r-regenerate.ts [dataset] [pipelineId] [--skip-validation]
 *
 * The new script:
 *   - Uses incremented files (master-1.R, tables-1.json) instead of temp-outputs folders
 *   - Has cleaner interface matching export-excel.ts pattern
 *   - Outputs stay in the source pipeline folder for easier comparison
 *
 * ---
 *
 * Test R Script Changes (DEPRECATED)
 *
 * Purpose: Test changes to RScriptGeneratorV2 without running the full pipeline.
 * Uses existing pipeline outputs and generates new results to a separate folder.
 *
 * Usage:
 *   npx tsx scripts/test-r-changes.ts [source-folder]
 *
 * Options:
 *   --skip-validation   Skip R validation step (faster, but no per-table error catching)
 *
 * Input:
 *   - Nothing: Uses latest pipeline folder in outputs/
 *   - Folder path: Uses specified pipeline output folder
 *
 * Output:
 *   Creates a new timestamped folder:
 *   temp-outputs/test-r-changes-{timestamp}/
 *     source-folder.txt    - Reference to source pipeline folder
 *     validation/          - R validation results (if not skipped)
 *     r/master.R           - Generated R script
 *     results/tables.json  - R output
 *     results/crosstabs-changes.xlsx - Excel output
 */

console.warn('\x1b[33m' + '=' .repeat(70) + '\x1b[0m');
console.warn('\x1b[33mDEPRECATED: Use test-r-regenerate.ts instead\x1b[0m');
console.warn('\x1b[33m  npx tsx scripts/test-r-regenerate.ts [dataset] [pipelineId]\x1b[0m');
console.warn('\x1b[33m' + '=' .repeat(70) + '\x1b[0m');
console.warn('');

// Load environment variables
import { loadEnvConfig } from '@next/env';
loadEnvConfig(process.cwd());

import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';
import { generateRScriptV2 } from '../src/lib/r/RScriptGeneratorV2';
import { validateAndFixTables } from '../src/lib/r/ValidationOrchestrator';
import type { ExtendedTableDefinition } from '../src/schemas/verificationAgentSchema';
import type { CutDefinition, CutGroup } from '../src/lib/tables/CutsSpec';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';
import { formatTablesFileToBuffer } from '../src/lib/excel/ExcelFormatter';

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

// Parse flags
const skipValidation = process.argv.includes('--skip-validation');

// =============================================================================
// Find Source Folder
// =============================================================================

/**
 * Find the latest pipeline output folder.
 * Searches outputs/<dataset>/pipeline-* directories.
 */
async function findLatestPipelineFolder(): Promise<string | null> {
  // First try outputs/ directory (new structure)
  const outputsDir = path.join(process.cwd(), 'outputs');

  try {
    const datasets = await fs.readdir(outputsDir, { withFileTypes: true });

    for (const dataset of datasets.filter(d => d.isDirectory()).reverse()) {
      const datasetDir = path.join(outputsDir, dataset.name);
      const entries = await fs.readdir(datasetDir, { withFileTypes: true });

      const pipelineDirs = entries
        .filter(e => e.isDirectory() && e.name.startsWith('pipeline-'))
        .map(e => e.name)
        .sort()
        .reverse();

      if (pipelineDirs.length > 0) {
        return path.join(datasetDir, pipelineDirs[0]);
      }
    }
  } catch {
    // Directory doesn't exist
  }

  // Fall back to temp-outputs/ (legacy structure)
  const tempOutputsDir = path.join(process.cwd(), 'temp-outputs');

  try {
    const entries = await fs.readdir(tempOutputsDir, { withFileTypes: true });

    const pipelineDirs = entries
      .filter(e => e.isDirectory() && e.name.startsWith('test-pipeline-'))
      .map(e => e.name)
      .sort()
      .reverse();

    if (pipelineDirs.length > 0) {
      return path.join(tempOutputsDir, pipelineDirs[0]);
    }
  } catch {
    // Directory doesn't exist
  }

  return null;
}

/**
 * Find a JSON file by pattern, searching both root and subdirectories.
 */
async function findFileByPattern(dir: string, pattern: string, subdirs: string[] = []): Promise<string | null> {
  // Search subdirectories first (new pipeline structure)
  for (const subdir of subdirs) {
    const subdirPath = path.join(dir, subdir);
    try {
      const files = await fs.readdir(subdirPath);
      const match = files.find(f => f.includes(pattern) && f.endsWith('.json'));
      if (match) return path.join(subdirPath, match);
    } catch {
      // Subdirectory doesn't exist
    }
  }

  // Fall back to root directory (legacy structure)
  try {
    const files = await fs.readdir(dir);
    const match = files.find(f => f.includes(pattern) && f.endsWith('.json'));
    if (match) return path.join(dir, match);
  } catch {
    // ignore
  }

  return null;
}

/**
 * Find the SPSS data file. Checks pipeline output first, then data/inputs/.
 */
async function findSpssFile(sourceFolder: string): Promise<string | null> {
  // Check pipeline output folder
  const sourceFiles = await fs.readdir(sourceFolder);
  const spssInOutput = sourceFiles.find(f => f.endsWith('.sav'));
  if (spssInOutput) return path.join(sourceFolder, spssInOutput);

  // Check data/<dataset>/inputs/ (SPSS file is always here)
  // Derive dataset name from the pipeline output path
  const parentDir = path.dirname(sourceFolder);
  const datasetName = path.basename(parentDir);
  const dataInputsDir = path.join(process.cwd(), 'data', datasetName, 'inputs');

  try {
    const inputFiles = await fs.readdir(dataInputsDir);
    const spssInData = inputFiles.find(f => f.endsWith('.sav'));
    if (spssInData) return path.join(dataInputsDir, spssInData);
  } catch {
    // Directory doesn't exist
  }

  return null;
}

/**
 * Find the survey markdown file. Checks pipeline output for processed survey.
 * Falls back to processing the survey document from data/inputs/.
 */
async function findSurveyMarkdown(sourceFolder: string): Promise<string | null> {
  // Check for processed survey in verification output
  const verifiedFile = await findFileByPattern(sourceFolder, 'verified-table-output', ['verification']);
  if (verifiedFile) {
    // The verified output directory should have the survey already processed
    // But we need the raw markdown - check if there's a survey file we can process
  }

  // Check data/<dataset>/inputs/ for survey document
  const parentDir = path.dirname(sourceFolder);
  const datasetName = path.basename(parentDir);
  const dataInputsDir = path.join(process.cwd(), 'data', datasetName, 'inputs');

  try {
    const inputFiles = await fs.readdir(dataInputsDir);
    const surveyFile = inputFiles.find(f =>
      (f.toLowerCase().includes('survey') || f.toLowerCase().includes('questionnaire')) &&
      (f.endsWith('.docx') || f.endsWith('.pdf'))
    );
    if (surveyFile) {
      // Process survey document
      const { processSurvey } = await import('../src/lib/processors/SurveyProcessor');
      const surveyResult = await processSurvey(path.join(dataInputsDir, surveyFile), sourceFolder);
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
async function findVerboseDatamap(sourceFolder: string): Promise<VerboseDataMapType[] | null> {
  const datamapFile = await findFileByPattern(sourceFolder, 'datamap-verbose', []);
  if (datamapFile) {
    const data = JSON.parse(await fs.readFile(datamapFile, 'utf-8'));
    return data as VerboseDataMapType[];
  }
  return null;
}

// =============================================================================
// Load Data
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
  const getNextLetter = () => String.fromCharCode(65 + letterIndex++);

  for (const group of data.bannerCuts || []) {
    const groupCutDefs: CutDefinition[] = [];

    for (const col of group.columns || []) {
      if (col.name && col.adjusted) {
        const cutDef: CutDefinition = {
          id: col.name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, ''),
          name: col.name,
          rExpression: col.adjusted,
          statLetter: getNextLetter(),
          groupName: group.groupName,
          groupIndex: cuts.length,
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
      process.stdout.write(data);
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
        reject(new Error(`R script failed with code ${code}`));
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
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
  const totalSteps = skipValidation ? 5 : 6;

  log('');
  log('======================================================================', 'magenta');
  log('  Test R Script Changes', 'bright');
  if (skipValidation) log('  (validation skipped)', 'yellow');
  log('======================================================================', 'magenta');
  log('');

  // 1. Find source folder
  let sourceFolder = process.argv.find(arg => !arg.startsWith('--') && !arg.includes('test-r-changes'));

  if (!sourceFolder) {
    sourceFolder = await findLatestPipelineFolder() ?? '';
    if (!sourceFolder) {
      log('No pipeline-* folder found in outputs/', 'red');
      log('Run test-pipeline.ts first to generate pipeline outputs.', 'dim');
      process.exit(1);
    }
  } else {
    if (!path.isAbsolute(sourceFolder)) {
      sourceFolder = path.join(process.cwd(), sourceFolder);
    }
  }

  try {
    await fs.access(sourceFolder);
  } catch {
    log(`Source folder not found: ${sourceFolder}`, 'red');
    process.exit(1);
  }

  log(`Source: ${sourceFolder}`, 'blue');

  // 2. Create output folder
  const outputFolder = path.join(process.cwd(), 'temp-outputs', `test-r-changes-${timestamp}`);
  const rDir = path.join(outputFolder, 'r');
  const resultsDir = path.join(outputFolder, 'results');

  await fs.mkdir(rDir, { recursive: true });
  await fs.mkdir(resultsDir, { recursive: true });

  log(`Output: temp-outputs/${path.basename(outputFolder)}`, 'blue');
  log('');

  // 3. Find required files (search subdirectories)
  log(`[1/${totalSteps}] Finding source files...`, 'cyan');

  const verifiedTablesFile = await findFileByPattern(sourceFolder, 'verified-table-output', ['verification']);
  // Also try verification-output-raw.json as fallback
  const rawVerifiedFile = verifiedTablesFile || await findFileByPattern(sourceFolder, 'verification-output-raw', ['verification']);

  const crosstabFile = await findFileByPattern(sourceFolder, 'crosstab-output', ['crosstab']);

  const spssSourcePath = await findSpssFile(sourceFolder);

  if (!rawVerifiedFile) {
    log('  Missing: verified-table-output-*.json or verification-output-raw.json', 'red');
    log('  Searched: root, verification/', 'dim');
    process.exit(1);
  }
  if (!crosstabFile) {
    log('  Missing: crosstab-output-*.json', 'red');
    log('  Searched: root, crosstab/', 'dim');
    process.exit(1);
  }
  if (!spssSourcePath) {
    log('  Missing: *.sav file', 'red');
    log('  Searched: pipeline output folder, data/<dataset>/inputs/', 'dim');
    process.exit(1);
  }

  log(`  Tables: ${path.relative(sourceFolder, rawVerifiedFile)}`, 'dim');
  log(`  Cuts: ${path.relative(sourceFolder, crosstabFile)}`, 'dim');
  log(`  SPSS: ${spssSourcePath}`, 'dim');

  // 4. Load data
  log('');
  log(`[2/${totalSteps}] Loading data...`, 'cyan');

  const verifiedData: VerifiedTableOutput = JSON.parse(await fs.readFile(rawVerifiedFile, 'utf-8'));
  const crosstabData: CrosstabOutput = JSON.parse(await fs.readFile(crosstabFile, 'utf-8'));

  let tables = verifiedData.tables;
  const { cuts, cutGroups } = loadCutsFromCrosstabOutput(crosstabData);

  log(`  Loaded ${tables.length} tables`, 'green');
  log(`  Loaded ${cuts.length} cuts in ${cutGroups.length} groups`, 'green');

  // 5. Copy SPSS file to output folder
  const spssDestPath = path.join(outputFolder, 'dataFile.sav');
  await fs.copyFile(spssSourcePath, spssDestPath);
  log(`  Copied SPSS data to output folder`, 'dim');

  // 6. R Validation step (unless skipped)
  if (!skipValidation) {
    log('');
    log(`[3/${totalSteps}] Validating R code per table...`, 'cyan');

    // Load survey markdown and datamap for retry capability
    const surveyMarkdown = await findSurveyMarkdown(sourceFolder);
    const verboseDataMap = await findVerboseDatamap(sourceFolder);

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
        outputDir: outputFolder,
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
  }

  // Generate R script step number
  const rStepNum = skipValidation ? 3 : 4;
  const runStepNum = skipValidation ? 4 : 5;
  const excelStepNum = skipValidation ? 5 : 6;

  // 7. Generate R script
  log('');
  log(`[${rStepNum}/${totalSteps}] Generating R script...`, 'cyan');

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

  const rScriptPath = path.join(rDir, 'master.R');
  await fs.writeFile(rScriptPath, rScript);
  log(`  Saved: r/master.R (${Math.round(rScript.length / 1024)} KB)`, 'green');

  // Save source reference
  await fs.writeFile(
    path.join(outputFolder, 'source-folder.txt'),
    `Source: ${sourceFolder}\nTimestamp: ${new Date().toISOString()}\n`
  );

  // 8. Run R script
  log('');
  log(`[${runStepNum}/${totalSteps}] Running R script...`, 'cyan');

  try {
    await runRScript(rScriptPath, outputFolder);
    log('  R script completed', 'green');
  } catch (err) {
    log(`  R script failed: ${err}`, 'red');
    process.exit(1);
  }

  // Verify tables.json was created
  const tablesJsonPath = path.join(resultsDir, 'tables.json');
  try {
    await fs.access(tablesJsonPath);
  } catch {
    log('  Missing: results/tables.json (R script may have failed)', 'red');
    process.exit(1);
  }

  // 9. Generate Excel
  log('');
  log(`[${excelStepNum}/${totalSteps}] Generating Excel...`, 'cyan');

  try {
    const excelBuffer = await formatTablesFileToBuffer(tablesJsonPath);
    const excelPath = path.join(resultsDir, 'crosstabs-changes.xlsx');
    await fs.writeFile(excelPath, excelBuffer);
    log(`  Saved: results/crosstabs-changes.xlsx`, 'green');
  } catch (err) {
    log(`  Excel generation failed: ${err}`, 'red');
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
  log(`Output folder: temp-outputs/${path.basename(outputFolder)}`, 'blue');
  log('');
  log('Files:', 'yellow');
  log('  r/master.R                  - Generated R script (with current code)', 'dim');
  log('  results/tables.json         - R calculations', 'dim');
  log('  results/crosstabs-changes.xlsx - Excel workbook', 'dim');
  if (!skipValidation) {
    log('  validation/                 - R validation results', 'dim');
  }
  log('');
  log('Compare with original:', 'yellow');
  log(`  Original: ${path.basename(sourceFolder)}/results/`, 'dim');
  log(`  New:      temp-outputs/${path.basename(outputFolder)}/results/`, 'dim');
  log('');
}

main().catch((err) => {
  log(`Error: ${err.message}`, 'red');
  console.error(err);
  process.exit(1);
});
