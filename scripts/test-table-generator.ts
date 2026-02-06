#!/usr/bin/env npx tsx
/**
 * TableGenerator Test Script
 *
 * Purpose: Run the new deterministic TableGenerator in isolation to validate
 * it produces correct table structures from datamap input.
 *
 * This script tests the Part 4 refactor: DataMapGrouper → TableGenerator
 *
 * Usage:
 *   npx tsx scripts/test-table-generator.ts [input-path]
 *
 * Input can be:
 *   - Nothing: Uses default data/leqvio-monotherapy-demand-NOV217/
 *   - CSV file: Processes raw datamap CSV first
 *   - JSON file: Uses existing verbose datamap JSON
 *   - Folder: Looks for *datamap*.csv in folder (or inputs/ subfolder)
 *
 * Examples:
 *   npx tsx scripts/test-table-generator.ts
 *   # Uses default dataset
 *
 *   npx tsx scripts/test-table-generator.ts data/test-data/some-dataset
 *   # Finds datamap CSV in folder (supports inputs/ subfolder)
 *
 * Output:
 *   temp-outputs/test-table-generator-<timestamp>/
 *     - groups.json: Output from DataMapGrouper
 *     - tables.json: Output from TableGenerator
 *     - stats.json: Statistics and summary
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { validate } from '../src/lib/validation/ValidationRunner';
import { groupDataMap, getGroupingStats } from '../src/lib/tables/DataMapGrouper';
import { generateTables, getGeneratorStats, convertToLegacyFormat } from '../src/lib/tables/TableGenerator';
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
  log('  TableGenerator Test Script', 'bright');
  log('  (Part 4: Deterministic Table Generation)', 'dim');
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
    log('  npx tsx scripts/test-table-generator.ts              # Use default dataset', 'dim');
    log('  npx tsx scripts/test-table-generator.ts <folder>     # Find datamap in folder', 'dim');
    log('  npx tsx scripts/test-table-generator.ts <file.csv>   # Process CSV file', 'dim');
    log('  npx tsx scripts/test-table-generator.ts <file.json>  # Use verbose JSON', 'dim');
    process.exit(1);
  }

  log(`Input: ${input.path}`, 'blue');
  log(`Type:  ${input.type}`, 'dim');
  log('', 'reset');

  // Create output folder
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputDir = path.join(process.cwd(), 'temp-outputs', `test-table-generator-${timestamp}`);
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
  for (const [type, count] of Object.entries(typeDistribution).sort((a, b) => b[1] - a[1])) {
    log(`  ${type}: ${count}`, 'cyan');
  }

  // Step 1: Run DataMapGrouper
  log('', 'reset');
  log('-'.repeat(60), 'cyan');
  log('Step 1: DataMapGrouper', 'bright');
  log('-'.repeat(60), 'cyan');

  const startGrouping = Date.now();
  const groups = groupDataMap(dataMap);
  const groupingDuration = Date.now() - startGrouping;

  const groupingStats = getGroupingStats(groups);
  log(`  Groups created: ${groupingStats.totalGroups}`, 'green');
  log(`  Total items: ${groupingStats.totalItems}`, 'dim');
  log(`  Avg items/group: ${groupingStats.avgItemsPerGroup.toFixed(1)}`, 'dim');
  log(`  Duration: ${groupingDuration}ms`, 'dim');

  // Save groups
  const groupsPath = path.join(outputDir, 'groups.json');
  await fs.writeFile(groupsPath, JSON.stringify(groups, null, 2), 'utf-8');
  log(`  Saved: groups.json`, 'dim');

  // Step 2: Run TableGenerator
  log('', 'reset');
  log('-'.repeat(60), 'cyan');
  log('Step 2: TableGenerator', 'bright');
  log('-'.repeat(60), 'cyan');

  const startGeneration = Date.now();
  const outputs = generateTables(groups);
  const generationDuration = Date.now() - startGeneration;

  const generatorStats = getGeneratorStats(outputs);
  log(`  Tables generated: ${generatorStats.totalTables}`, 'green');
  log(`  Total rows: ${generatorStats.totalRows}`, 'dim');
  log(`  Avg rows/table: ${generatorStats.avgRowsPerTable.toFixed(1)}`, 'dim');
  log(`  Duration: ${generationDuration}ms`, 'dim');

  log('', 'reset');
  log('Table types:', 'bright');
  for (const [type, count] of Object.entries(generatorStats.tableTypeDistribution).sort((a, b) => b[1] - a[1])) {
    log(`  ${type}: ${count}`, 'cyan');
  }

  // Save tables
  const tablesPath = path.join(outputDir, 'tables.json');
  await fs.writeFile(tablesPath, JSON.stringify(outputs, null, 2), 'utf-8');
  log(`  Saved: tables.json`, 'dim');

  // Save legacy format (for comparison with old TableAgent)
  const legacyOutputs = convertToLegacyFormat(outputs);
  const legacyPath = path.join(outputDir, 'tables-legacy.json');
  await fs.writeFile(legacyPath, JSON.stringify({ results: legacyOutputs }, null, 2), 'utf-8');
  log(`  Saved: tables-legacy.json (for comparison)`, 'dim');

  // Save stats
  const stats = {
    input: {
      path: input.path,
      type: input.type,
      totalVariables: dataMap.length,
      typeDistribution,
    },
    grouping: {
      ...groupingStats,
      durationMs: groupingDuration,
    },
    generation: {
      ...generatorStats,
      durationMs: generationDuration,
    },
    timestamp: new Date().toISOString(),
  };
  const statsPath = path.join(outputDir, 'stats.json');
  await fs.writeFile(statsPath, JSON.stringify(stats, null, 2), 'utf-8');

  // Summary
  log('', 'reset');
  log('='.repeat(60), 'green');
  log('  Summary', 'bright');
  log('='.repeat(60), 'green');
  log(`  Variables: ${dataMap.length}`, 'reset');
  log(`  Groups: ${groupingStats.totalGroups}`, 'reset');
  log(`  Tables: ${generatorStats.totalTables}`, 'reset');
  log(`  Rows: ${generatorStats.totalRows}`, 'reset');
  log(`  Duration: ${groupingDuration + generationDuration}ms total`, 'reset');
  log('', 'reset');
  log(`Output: ${outputDir}/`, 'green');
  log('', 'reset');

  // Verification notes
  log('Verification checklist:', 'yellow');
  log('  [ ] Every question group produces exactly one table', 'dim');
  log('  [ ] numeric_range -> mean_rows with empty filterValue', 'dim');
  log('  [ ] binary_flag -> frequency with filterValue "1"', 'dim');
  log('  [ ] categorical_select -> frequency with value codes', 'dim');
  log('  [ ] meta fields correctly populated', 'dim');
  log('', 'reset');
}

main().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
