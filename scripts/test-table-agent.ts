#!/usr/bin/env npx tsx
/**
 * TableAgent Test Script
 *
 * Purpose: Run TableAgent in isolation to validate table structure decisions.
 *
 * Usage:
 *   npx tsx scripts/test-table-agent.ts [input-path]
 *
 * Input can be:
 *   - Nothing: Uses default data/leqvio-monotherapy-demand-NOV217/
 *   - CSV file: Processes raw datamap CSV first, then runs TableAgent
 *   - JSON file: Uses existing verbose datamap JSON
 *   - Folder: Looks for *datamap*.csv in folder (or inputs/ subfolder)
 *
 * Examples:
 *   npx tsx scripts/test-table-agent.ts
 *   # Uses default dataset
 *
 *   npx tsx scripts/test-table-agent.ts data/test-data/some-dataset
 *   # Finds datamap CSV in folder (supports inputs/ subfolder)
 *
 *   npx tsx scripts/test-table-agent.ts outputs/some-dataset/pipeline-xxx/dataMap-verbose-xxx.json
 *   # Uses existing verbose JSON
 *
 * Output:
 *   outputs/<dataset>/table-<timestamp>/
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { processDataMap, groupDataMapByParent, EXCLUDED_NORMALIZED_TYPES } from '../src/agents/TableAgent';
import { validate } from '../src/lib/validation/ValidationRunner';
import { VerboseDataMapType } from '../src/schemas/processingSchemas';

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

// =============================================================================
// Input Resolution
// =============================================================================

interface InputInfo {
  type: 'csv' | 'json';
  path: string;
  spssPath: string;  // .sav file for validation runner
  name: string;
}

async function resolveInput(inputArg?: string): Promise<InputInfo> {
  const input = inputArg || DEFAULT_DATASET;
  const absPath = path.isAbsolute(input) ? input : path.join(process.cwd(), input);

  // Check if path exists
  let stat;
  try {
    stat = await fs.stat(absPath);
  } catch {
    throw new Error(`Input not found: ${input}`);
  }

  // If it's a directory, look for .sav file
  if (stat.isDirectory()) {
    // Check for nested structure (inputs/ subfolder)
    let inputsFolder = absPath;
    const subfolders = await fs.readdir(absPath);
    if (subfolders.includes('inputs')) {
      inputsFolder = path.join(absPath, 'inputs');
    }

    const files = await fs.readdir(inputsFolder);
    const savFile = files.find(f => f.endsWith('.sav'));
    if (!savFile) {
      throw new Error(`No .sav file found in ${input}`);
    }
    return {
      type: 'csv',
      path: path.join(inputsFolder, savFile),
      spssPath: path.join(inputsFolder, savFile),
      name: path.basename(absPath),
    };
  }

  // It's a file
  if (input.endsWith('.sav')) {
    return {
      type: 'csv',
      path: absPath,
      spssPath: absPath,
      name: path.basename(path.dirname(absPath)),
    };
  }

  if (input.endsWith('.json')) {
    // For JSON input, try to find a .sav in the same directory
    const dir = path.dirname(absPath);
    const files = await fs.readdir(dir);
    const savFile = files.find(f => f.endsWith('.sav'));
    return {
      type: 'json',
      path: absPath,
      spssPath: savFile ? path.join(dir, savFile) : '',
      name: path.basename(path.dirname(absPath)),
    };
  }

  throw new Error(`Unsupported file type: ${input}. Expected .sav or .json`);
}

// =============================================================================
// Data Loading
// =============================================================================

async function loadDataMap(input: InputInfo, outputFolder: string): Promise<VerboseDataMapType[]> {
  if (input.type === 'csv') {
    log(`Processing .sav: ${path.basename(input.spssPath)}`, 'blue');
    const report = await validate({ spssPath: input.spssPath, outputDir: outputFolder });
    if (!report.canProceed || !report.processingResult) {
      throw new Error(`Validation failed: ${report.errors.map(e => e.message).join(', ')}`);
    }
    log(`  Generated ${report.processingResult.verbose.length} variables`, 'green');
    return report.processingResult.verbose as VerboseDataMapType[];
  }

  // JSON file
  log(`Loading JSON: ${path.basename(input.path)}`, 'blue');
  const content = await fs.readFile(input.path, 'utf-8');
  const data = JSON.parse(content);

  // Handle various JSON structures
  if (Array.isArray(data)) {
    return data;
  } else if (data.variables && Array.isArray(data.variables)) {
    return data.variables;
  } else if (data.verbose && Array.isArray(data.verbose)) {
    return data.verbose;
  }

  throw new Error('Could not find verbose datamap array in JSON file');
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  log('', 'reset');
  log('='.repeat(60), 'magenta');
  log('  TableAgent Test Script', 'bright');
  log('='.repeat(60), 'magenta');
  log('', 'reset');

  // Resolve input
  const inputArg = process.argv[2];
  let input: InputInfo;

  try {
    input = await resolveInput(inputArg);
  } catch (error) {
    log(`ERROR: ${error instanceof Error ? error.message : String(error)}`, 'red');
    log('', 'reset');
    log('Usage:', 'yellow');
    log('  npx tsx scripts/test-table-agent.ts              # Use default dataset', 'dim');
    log('  npx tsx scripts/test-table-agent.ts <folder>     # Find datamap in folder (supports inputs/ subfolder)', 'dim');
    log('  npx tsx scripts/test-table-agent.ts <file.csv>   # Process CSV file', 'dim');
    log('  npx tsx scripts/test-table-agent.ts <file.json>  # Use verbose JSON', 'dim');
    process.exit(1);
  }

  log(`Input: ${input.path}`, 'blue');
  log(`Type:  ${input.type}`, 'dim');
  log('', 'reset');

  // Create output folder: outputs/<dataset>/table-<timestamp>/
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFolder = `table-${timestamp}`;
  const outputDir = path.join(process.cwd(), 'outputs', input.name, outputFolder);
  await fs.mkdir(outputDir, { recursive: true });

  // Load datamap
  let dataMap: VerboseDataMapType[];
  try {
    dataMap = await loadDataMap(input, outputDir);
    log(`Loaded ${dataMap.length} total variables`, 'green');
  } catch (error) {
    log(`ERROR loading datamap: ${error instanceof Error ? error.message : String(error)}`, 'red');
    process.exit(1);
  }

  // Show type distribution
  const typeDistribution: Record<string, number> = {};
  for (const v of dataMap) {
    const type = v.normalizedType || 'undefined';
    typeDistribution[type] = (typeDistribution[type] || 0) + 1;
  }

  log('', 'reset');
  log('Normalized type distribution:', 'bright');
  let excludedCount = 0;
  for (const [type, count] of Object.entries(typeDistribution).sort((a, b) => b[1] - a[1])) {
    const isExcluded = EXCLUDED_NORMALIZED_TYPES.has(type);
    if (isExcluded) excludedCount += count;
    const marker = isExcluded ? ' (excluded)' : '';
    log(`  ${type}: ${count}${marker}`, isExcluded ? 'dim' : 'cyan');
  }

  const processableCount = dataMap.length - excludedCount;
  log(``, 'reset');
  log(`Processable: ${processableCount} variables (${excludedCount} excluded)`, 'green');

  // Preview grouping
  const groups = groupDataMapByParent(dataMap);
  log(`Question groups: ${groups.length}`, 'green');
  log(`Output folder: outputs/${input.name}/${outputFolder}/`, 'dim');

  // Run TableAgent
  log('', 'reset');
  log('-'.repeat(60), 'cyan');
  log('Running TableAgent...', 'bright');
  log('-'.repeat(60), 'cyan');
  log('', 'reset');

  const startTime = Date.now();

  try {
    const { results } = await processDataMap(dataMap, outputDir, (completed, total) => {
      process.stdout.write(`\r  Progress: ${completed}/${total} question groups...`);
    });
    console.log(''); // Clear progress line

    const duration = Date.now() - startTime;

    // Summary
    log('', 'reset');
    log('='.repeat(60), 'green');
    log('  Processing Complete', 'bright');
    log('='.repeat(60), 'green');

    const totalTables = results.reduce((sum, r) => sum + r.tables.length, 0);
    const avgConfidence = results.length > 0
      ? results.reduce((sum, r) => sum + r.confidence, 0) / results.length
      : 0;

    log(`  Duration:    ${(duration / 1000).toFixed(1)}s`, 'reset');
    log(`  Groups:      ${results.length}`, 'reset');
    log(`  Tables:      ${totalTables}`, 'reset');
    log(`  Confidence:  ${(avgConfidence * 100).toFixed(1)}%`, avgConfidence >= 0.8 ? 'green' : avgConfidence >= 0.6 ? 'yellow' : 'red');

    // Table type distribution
    const tableTypeDistribution: Record<string, number> = {};
    for (const result of results) {
      for (const table of result.tables) {
        tableTypeDistribution[table.tableType] = (tableTypeDistribution[table.tableType] || 0) + 1;
      }
    }

    log('', 'reset');
    log('Table types:', 'bright');
    for (const [type, count] of Object.entries(tableTypeDistribution).sort((a, b) => b[1] - a[1])) {
      log(`  ${type}: ${count}`, 'dim');
    }

    // Low confidence warnings
    const lowConfidence = results.filter(r => r.confidence < 0.7);
    if (lowConfidence.length > 0) {
      log('', 'reset');
      log('Low confidence (< 0.7):', 'yellow');
      for (const r of lowConfidence.slice(0, 5)) {
        log(`  ${r.questionId}: ${(r.confidence * 100).toFixed(0)}%`, 'yellow');
      }
      if (lowConfidence.length > 5) {
        log(`  ... and ${lowConfidence.length - 5} more`, 'dim');
      }
    }

    log('', 'reset');
    log(`Output: outputs/${input.name}/${outputFolder}/`, 'green');
    log('', 'reset');

  } catch (error) {
    log(``, 'reset');
    log(`ERROR: ${error instanceof Error ? error.message : String(error)}`, 'red');
    process.exit(1);
  }
}

main().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
