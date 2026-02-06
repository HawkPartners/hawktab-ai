#!/usr/bin/env npx tsx
/**
 * VerificationAgent Test Script
 *
 * Purpose: Run VerificationAgent in isolation using existing TableAgent output.
 *
 * Usage:
 *   npx tsx scripts/test-verification-agent.ts [table-output-path]
 *
 * Input can be:
 *   - Nothing: Uses most recent pipeline run for default dataset
 *   - Folder: Looks for table-output*.json and survey*.docx in folder
 *   - JSON file: Uses specific table output JSON
 *
 * Examples:
 *   npx tsx scripts/test-verification-agent.ts
 *   # Uses most recent pipeline run from outputs/<default-dataset>/
 *
 *   npx tsx scripts/test-verification-agent.ts outputs/some-dataset/pipeline-xxx
 *   # Uses specific pipeline output folder
 *
 * Output:
 *   outputs/<dataset>/verification-<timestamp>/
 *   - verified-table-output-*.json
 *   - scratchpad-verification-*.md
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { verifyAllTables, getIncludedTables, getExcludedTables } from '../src/agents/VerificationAgent';
import { processSurvey, getSurveyStats } from '../src/lib/processors/SurveyProcessor';
import { validate } from '../src/lib/validation/ValidationRunner';
import { TableAgentOutput } from '../src/schemas/tableAgentSchema';
import { VerboseDataMapType } from '../src/schemas/processingSchemas';

// =============================================================================
// Configuration
// =============================================================================

const DEFAULT_DATASET = 'data/leqvio-monotherapy-demand-NOV217';
const DEFAULT_DATASET_NAME = 'leqvio-monotherapy-demand-NOV217';
const PIPELINE_RUN_PREFIX = 'pipeline-';

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
// Input Resolution
// =============================================================================

interface ResolvedPaths {
  folder: string;
  tableOutput: string;
  surveyDoc: string | null;
  dataMapVerbose: string | null;
  spssPath: string | null;
}

async function findMostRecentPipelineRun(datasetName: string = DEFAULT_DATASET_NAME): Promise<string | null> {
  const datasetOutputs = path.join(process.cwd(), 'outputs', datasetName);

  try {
    const entries = await fs.readdir(datasetOutputs);
    const pipelineRuns = entries
      .filter((e) => e.startsWith(PIPELINE_RUN_PREFIX))
      .sort()
      .reverse();

    if (pipelineRuns.length === 0) return null;
    return path.join(datasetOutputs, pipelineRuns[0]);
  } catch {
    return null;
  }
}

async function resolveInputPaths(inputArg?: string): Promise<ResolvedPaths> {
  let folder: string;
  let datasetName = DEFAULT_DATASET_NAME;

  if (!inputArg) {
    // Find most recent pipeline run for default dataset
    const recent = await findMostRecentPipelineRun();
    if (!recent) {
      throw new Error(
        `No pipeline runs found in outputs/${DEFAULT_DATASET_NAME}/. Run test-pipeline.ts first.`
      );
    }
    folder = recent;
  } else if (inputArg.endsWith('.json')) {
    // Specific JSON file - use its folder
    folder = path.dirname(inputArg);
  } else {
    // Folder path
    folder = path.isAbsolute(inputArg) ? inputArg : path.join(process.cwd(), inputArg);
  }

  // Check folder exists
  try {
    await fs.stat(folder);
  } catch {
    throw new Error(`Folder not found: ${folder}`);
  }

  // Find table output JSON
  const files = await fs.readdir(folder);
  const tableOutputFile =
    inputArg?.endsWith('.json') && path.basename(inputArg).startsWith('table-output')
      ? path.basename(inputArg)
      : files.find((f) => f.startsWith('table-output') && f.endsWith('.json'));

  if (!tableOutputFile) {
    throw new Error(`No table-output*.json found in ${folder}`);
  }

  // Find survey document (optional)
  const surveyFile = files.find(
    (f) => f.toLowerCase().includes('survey') && (f.endsWith('.docx') || f.endsWith('.doc'))
  );

  // Find verbose datamap JSON (optional - for context)
  let dataMapVerbose: string | null = null;

  // Check for verbose JSON in current folder (case-insensitive)
  const verboseInFolder = files.find(
    (f) => f.toLowerCase().includes('datamap-verbose') && f.endsWith('.json')
  );
  if (verboseInFolder) {
    dataMapVerbose = path.join(folder, verboseInFolder);
  }

  // Find survey document - check folder then default dataset
  let surveyPath: string | null = null;
  if (surveyFile) {
    surveyPath = path.join(folder, surveyFile);
  } else {
    // Check default dataset folder (supports inputs/ subfolder)
    const defaultDatasetPath = path.join(process.cwd(), DEFAULT_DATASET);
    try {
      const datasetContents = await fs.readdir(defaultDatasetPath);
      const inputsPath = datasetContents.includes('inputs')
        ? path.join(defaultDatasetPath, 'inputs')
        : defaultDatasetPath;
      const inputFiles = await fs.readdir(inputsPath);
      const datasetSurvey = inputFiles.find(
        (f) => f.toLowerCase().includes('survey') && (f.endsWith('.docx') || f.endsWith('.doc'))
      );
      if (datasetSurvey) {
        surveyPath = path.join(inputsPath, datasetSurvey);
      }
    } catch {
      // Ignore if default dataset doesn't exist
    }
  }

  // Find .sav file - check folder then default dataset
  let spssPath: string | null = null;
  const savInFolder = files.find((f) => f.endsWith('.sav'));
  if (savInFolder) {
    spssPath = path.join(folder, savInFolder);
  } else {
    // Check default dataset folder (supports inputs/ subfolder)
    const defaultDatasetPath = path.join(process.cwd(), DEFAULT_DATASET);
    try {
      const datasetContents = await fs.readdir(defaultDatasetPath);
      const inputsPath = datasetContents.includes('inputs')
        ? path.join(defaultDatasetPath, 'inputs')
        : defaultDatasetPath;
      const inputFiles = await fs.readdir(inputsPath);
      const datasetSav = inputFiles.find((f) => f.endsWith('.sav'));
      if (datasetSav) {
        spssPath = path.join(inputsPath, datasetSav);
      }
    } catch {
      // Ignore if default dataset doesn't exist
    }
  }

  return {
    folder,
    tableOutput: path.join(folder, tableOutputFile),
    surveyDoc: surveyPath,
    dataMapVerbose,
    spssPath,
  };
}

// =============================================================================
// Data Loading
// =============================================================================

async function loadTableAgentOutput(filePath: string): Promise<TableAgentOutput[]> {
  const content = await fs.readFile(filePath, 'utf-8');
  const data = JSON.parse(content);

  // Handle enhanced output format (with processingInfo)
  if (data.results && Array.isArray(data.results)) {
    return data.results;
  }

  // Direct array
  if (Array.isArray(data)) {
    return data;
  }

  throw new Error('Could not find TableAgentOutput array in JSON file');
}

async function loadVerboseDataMap(
  verbosePath: string | null,
  spssPath: string | null,
  outputDir: string
): Promise<VerboseDataMapType[]> {
  // Try verbose JSON first
  if (verbosePath) {
    try {
      const content = await fs.readFile(verbosePath, 'utf-8');
      const data = JSON.parse(content);
      if (Array.isArray(data)) return data;
      if (data.variables && Array.isArray(data.variables)) return data.variables;
      if (data.verbose && Array.isArray(data.verbose)) return data.verbose;
    } catch {
      // Fall through to .sav
    }
  }

  // Try processing .sav via validation runner
  if (spssPath) {
    try {
      const report = await validate({ spssPath, outputDir });
      if (report.canProceed && report.processingResult) {
        return report.processingResult.verbose as VerboseDataMapType[];
      }
      log(`Warning: Validation failed: ${report.errors.map(e => e.message).join(', ')}`, 'yellow');
    } catch (error) {
      log(`Warning: Could not process .sav file: ${error}`, 'yellow');
    }
  }

  // Return empty array - verification will work but without datamap context
  return [];
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  log('', 'reset');
  log('='.repeat(60), 'magenta');
  log('  VerificationAgent Test Script', 'bright');
  log('='.repeat(60), 'magenta');
  log('', 'reset');

  // Resolve input paths
  const inputArg = process.argv[2];
  let paths: ResolvedPaths;

  try {
    paths = await resolveInputPaths(inputArg);
  } catch (error) {
    log(`ERROR: ${error instanceof Error ? error.message : String(error)}`, 'red');
    log('', 'reset');
    log('Usage:', 'yellow');
    log('  npx tsx scripts/test-verification-agent.ts              # Use most recent default dataset run', 'dim');
    log('  npx tsx scripts/test-verification-agent.ts <folder>     # Use specific test output folder', 'dim');
    log('  npx tsx scripts/test-verification-agent.ts <file.json>  # Use specific table output JSON', 'dim');
    process.exit(1);
  }

  log(`Folder:       ${paths.folder}`, 'blue');
  log(`Table Output: ${path.basename(paths.tableOutput)}`, 'dim');
  log(`Survey Doc:   ${paths.surveyDoc ? path.basename(paths.surveyDoc) : '(not found)'}`, paths.surveyDoc ? 'dim' : 'yellow');
  log(`DataMap:      ${paths.spssPath ? path.basename(paths.spssPath) : paths.dataMapVerbose ? path.basename(paths.dataMapVerbose) : '(not found)'}`, 'dim');
  log('', 'reset');

  // Load table agent output
  log('Loading TableAgent output...', 'blue');
  let tableOutput: TableAgentOutput[];
  try {
    tableOutput = await loadTableAgentOutput(paths.tableOutput);
    const totalTables = tableOutput.reduce((sum, g) => sum + g.tables.length, 0);
    log(`  Loaded ${tableOutput.length} question groups, ${totalTables} tables`, 'green');
  } catch (error) {
    log(`ERROR loading table output: ${error instanceof Error ? error.message : String(error)}`, 'red');
    process.exit(1);
  }

  // Create dedicated output folder for this run: outputs/<dataset>/verification-<timestamp>/
  // Extract dataset name from input folder path (e.g., outputs/dataset-name/pipeline-xxx → dataset-name)
  const folderParts = paths.folder.split(path.sep);
  const outputsIndex = folderParts.indexOf('outputs');
  const datasetName = outputsIndex >= 0 && folderParts[outputsIndex + 1]
    ? folderParts[outputsIndex + 1]
    : DEFAULT_DATASET_NAME;

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const outputFolderName = `verification-${timestamp}`;
  const outputPath = path.join(process.cwd(), 'outputs', datasetName, outputFolderName);
  await fs.mkdir(outputPath, { recursive: true });
  log(`Output folder: outputs/${datasetName}/${outputFolderName}`, 'cyan');
  log('', 'reset');

  // Load datamap
  log('Loading datamap...', 'blue');
  const dataMap = await loadVerboseDataMap(paths.dataMapVerbose, paths.spssPath, outputPath);
  log(`  Loaded ${dataMap.length} variables`, dataMap.length > 0 ? 'green' : 'yellow');

  // Process survey document
  let surveyMarkdown = '';
  if (paths.surveyDoc) {
    log('Processing survey document...', 'blue');
    try {
      const surveyResult = await processSurvey(paths.surveyDoc, outputPath);
      surveyMarkdown = surveyResult.markdown;
      const stats = getSurveyStats(surveyMarkdown);
      log(`  Converted to markdown: ${stats.characterCount} chars, ~${stats.estimatedTokens} tokens`, 'green');

      if (surveyResult.warnings.length > 0) {
        for (const warning of surveyResult.warnings) {
          log(`  Warning: ${warning}`, 'yellow');
        }
      }
    } catch (error) {
      log(`  Warning: Survey processing failed: ${error}`, 'yellow');
      log(`  Continuing without survey context...`, 'dim');
    }
  } else {
    log('No survey document found - running in passthrough mode', 'yellow');
  }

  // Run VerificationAgent
  log('', 'reset');
  log('-'.repeat(60), 'cyan');
  log('Running VerificationAgent...', 'bright');
  log('-'.repeat(60), 'cyan');
  log('', 'reset');

  const startTime = Date.now();
  const totalInputTables = tableOutput.reduce((sum, g) => sum + g.tables.length, 0);

  try {
    const results = await verifyAllTables(tableOutput, surveyMarkdown, dataMap, {
      outputDir: outputPath,
      onProgress: (completed, total, tableId) => {
        process.stdout.write(`\r  Progress: ${completed}/${total} tables (${tableId})...`);
      },
    });
    console.log(''); // Clear progress line

    const duration = Date.now() - startTime;

    // Summary
    log('', 'reset');
    log('='.repeat(60), 'green');
    log('  Processing Complete', 'bright');
    log('='.repeat(60), 'green');

    const includedTables = getIncludedTables(results);
    const excludedTables = getExcludedTables(results);

    log(`  Duration:       ${(duration / 1000).toFixed(1)}s`, 'reset');
    log(`  Input tables:   ${totalInputTables}`, 'reset');
    log(`  Output tables:  ${results.tables.length}`, 'reset');
    log(`  Included:       ${includedTables.length}`, 'reset');
    log(`  Excluded:       ${excludedTables.length}`, excludedTables.length > 0 ? 'yellow' : 'reset');
    log(`  Modified:       ${results.metadata.tablesModified}`, results.metadata.tablesModified > 0 ? 'green' : 'reset');
    log(`  Split:          ${results.metadata.tablesSplit}`, results.metadata.tablesSplit > 0 ? 'green' : 'reset');
    log(`  Confidence:     ${(results.metadata.averageConfidence * 100).toFixed(1)}%`, results.metadata.averageConfidence >= 0.8 ? 'green' : results.metadata.averageConfidence >= 0.6 ? 'yellow' : 'red');

    // Show changes summary
    if (results.allChanges.length > 0) {
      log('', 'reset');
      log('Changes made:', 'bright');
      for (const { tableId, changes } of results.allChanges.slice(0, 10)) {
        log(`  ${tableId}:`, 'cyan');
        for (const change of changes.slice(0, 3)) {
          log(`    - ${change}`, 'dim');
        }
        if (changes.length > 3) {
          log(`    ... and ${changes.length - 3} more`, 'dim');
        }
      }
      if (results.allChanges.length > 10) {
        log(`  ... and ${results.allChanges.length - 10} more tables`, 'dim');
      }
    }

    // Show excluded tables
    if (excludedTables.length > 0) {
      log('', 'reset');
      log('Excluded tables:', 'yellow');
      for (const table of excludedTables.slice(0, 5)) {
        log(`  ${table.tableId}: ${table.excludeReason}`, 'dim');
      }
      if (excludedTables.length > 5) {
        log(`  ... and ${excludedTables.length - 5} more`, 'dim');
      }
    }

    log('', 'reset');
    log(`Output: outputs/${datasetName}/${outputFolderName}/`, 'green');
    log(`Input:  ${paths.folder}/`, 'dim');
    log('', 'reset');

  } catch (error) {
    log(``, 'reset');
    log(`ERROR: ${error instanceof Error ? error.message : String(error)}`, 'red');
    if (error instanceof Error && error.stack) {
      log(error.stack, 'dim');
    }
    process.exit(1);
  }
}

main().catch((error) => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
