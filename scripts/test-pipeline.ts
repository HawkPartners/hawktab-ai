#!/usr/bin/env npx tsx
/**
 * Pipeline Test Script
 *
 * Purpose: Run the full processing pipeline from raw files to R script generation,
 * without requiring the UI. Stops before Excel generation.
 *
 * Usage:
 *   npx tsx scripts/test-pipeline.ts [dataset-folder]
 *
 * Examples:
 *   npx tsx scripts/test-pipeline.ts
 *   # Uses default: data/test-data/practice-files/
 *
 *   npx tsx scripts/test-pipeline.ts data/test-data/practice-files
 *   # Explicit path to dataset folder
 *
 * Required files in dataset folder:
 *   - *datamap*.csv  (datamap file)
 *   - *banner*.docx  (banner plan)
 *   - *.sav          (SPSS data file)
 *
 * Pipeline stages:
 *   1. DataMapProcessor → Verbose datamap JSON
 *   2. BannerAgent → Banner extraction JSON
 *   3. CrosstabAgent → Validation with cuts
 *   4. TableAgent → Table definitions
 *   5. RScriptGeneratorV2 → master.R
 *   6. R execution → results/tables.json
 *
 * Output:
 *   temp-outputs/test-pipeline-<dataset>-<timestamp>/
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
import { generateRScriptV2 } from '../src/lib/r/RScriptGeneratorV2';
import { buildCutsSpec } from '../src/lib/tables/CutsSpec';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';

const execAsync = promisify(exec);

// =============================================================================
// Configuration
// =============================================================================

const DEFAULT_DATASET = 'data/test-data/practice-files';

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
  name: string;
}

async function findDatasetFiles(folder: string): Promise<DatasetFiles> {
  const absFolder = path.isAbsolute(folder) ? folder : path.join(process.cwd(), folder);
  const files = await fs.readdir(absFolder);

  // Find datamap CSV
  const datamap = files.find(f =>
    f.toLowerCase().includes('datamap') && f.endsWith('.csv')
  );
  if (!datamap) {
    throw new Error(`No datamap CSV found in ${folder}. Expected file containing "datamap" with .csv extension.`);
  }

  // Find banner plan (prefer 'clean' version)
  let banner = files.find(f =>
    f.toLowerCase().includes('banner') &&
    f.toLowerCase().includes('clean') &&
    (f.endsWith('.docx') || f.endsWith('.pdf'))
  );
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

  // Derive dataset name from folder
  const name = path.basename(absFolder);

  return {
    datamap: path.join(absFolder, datamap),
    banner: path.join(absFolder, banner),
    spss: path.join(absFolder, spss),
    name,
  };
}

// =============================================================================
// Pipeline Stages
// =============================================================================

async function runPipeline(datasetFolder: string) {
  const startTime = Date.now();
  const totalSteps = 6;

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
  log('', 'reset');

  // Create output folder
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFolder = `test-pipeline-${files.name}-${timestamp}`;
  const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolder);
  await fs.mkdir(outputDir, { recursive: true });
  log(`Output folder: temp-outputs/${outputFolder}`, 'blue');
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
  const dataMapResult = await dataMapProcessor.processDataMap(files.datamap, files.spss, outputFolder);
  const verboseDataMap = dataMapResult.verbose as VerboseDataMapType[];
  log(`  Processed ${verboseDataMap.length} variables`, 'green');
  log(`  Duration: ${Date.now() - stepStart1}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 2: BannerAgent
  // -------------------------------------------------------------------------
  logStep(2, totalSteps, 'Extracting banner plan...');
  const stepStart2 = Date.now();

  const bannerAgent = new BannerAgent();
  const bannerResult = await bannerAgent.processDocument(files.banner, outputFolder);

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
    outputFolder,
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
  const stepStart4 = Date.now();

  const { results: tableAgentResults } = await processTableAgent(verboseDataMap, outputFolder);
  const allTables = tableAgentResults.flatMap(r => r.tables);

  log(`  Generated ${allTables.length} table definitions`, 'green');
  log(`  Duration: ${Date.now() - stepStart4}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 5: RScriptGeneratorV2
  // -------------------------------------------------------------------------
  logStep(5, totalSteps, 'Generating R script...');
  const stepStart5 = Date.now();

  const cutsSpec = buildCutsSpec(crosstabResult.result);
  const rDir = path.join(outputDir, 'r');
  await fs.mkdir(rDir, { recursive: true });

  const masterScript = generateRScriptV2(
    { tables: allTables, cuts: cutsSpec.cuts },
    { sessionId: outputFolder, outputDir: 'results' }
  );

  const masterPath = path.join(rDir, 'master.R');
  await fs.writeFile(masterPath, masterScript, 'utf-8');

  log(`  Generated R script (${Math.round(masterScript.length / 1024)} KB)`, 'green');
  log(`  Duration: ${Date.now() - stepStart5}ms`, 'dim');
  log('', 'reset');

  // -------------------------------------------------------------------------
  // Step 6: R Execution
  // -------------------------------------------------------------------------
  logStep(6, totalSteps, 'Executing R script...');
  const stepStart6 = Date.now();

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
    } else {
      log(`  WARNING: No tables.json generated`, 'yellow');
    }

    log(`  Duration: ${Date.now() - stepStart6}ms`, 'dim');
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
  log(`  Tables:      ${allTables.length}`, 'reset');
  log(`  Cuts:        ${cutsSpec.cuts.length + 1} (including Total)`, 'reset');
  log(`  Duration:    ${(totalDuration / 1000).toFixed(1)}s`, 'reset');
  log(`  Output:      temp-outputs/${outputFolder}/`, 'reset');
  log('', 'reset');

  // Write summary file
  const summary = {
    dataset: files.name,
    timestamp: new Date().toISOString(),
    duration: { ms: totalDuration, formatted: `${(totalDuration / 1000).toFixed(1)}s` },
    inputs: {
      datamap: path.basename(files.datamap),
      banner: path.basename(files.banner),
      spss: path.basename(files.spss),
    },
    outputs: {
      variables: verboseDataMap.length,
      tables: allTables.length,
      cuts: cutsSpec.cuts.length + 1,
      bannerGroups: groupCount,
    },
  };
  await fs.writeFile(
    path.join(outputDir, 'pipeline-summary.json'),
    JSON.stringify(summary, null, 2)
  );

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
