#!/usr/bin/env npx tsx
/**
 * TableAgent Test Script
 *
 * Purpose: Run TableAgent in isolation to validate output before full pipeline integration.
 *
 * Usage:
 *   npx tsx scripts/test-table-agent.ts [datamap-path]
 *
 * Examples:
 *   npx tsx scripts/test-table-agent.ts
 *   # Uses latest verbose datamap from temp-outputs
 *
 *   npx tsx scripts/test-table-agent.ts temp-outputs/output-2026-01-03/dataMap-verbose-*.json
 *   # Uses specified datamap file
 *
 * Output:
 *   Saves to temp-outputs/table-test-<timestamp>/table-output-<timestamp>.json
 */

import fs from 'fs/promises';
import path from 'path';
import { processDataMap, groupDataMapByParent, EXCLUDED_NORMALIZED_TYPES } from '../src/agents/TableAgent';
import { VerboseDataMapType } from '../src/schemas/processingSchemas';

// ANSI colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
};

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function findLatestDataMap(): Promise<string | null> {
  const tempOutputsDir = path.join(process.cwd(), 'temp-outputs');

  try {
    // Get all output directories sorted by name (timestamp-based)
    const entries = await fs.readdir(tempOutputsDir, { withFileTypes: true });
    const outputDirs = entries
      .filter(e => e.isDirectory() && e.name.startsWith('output-'))
      .map(e => e.name)
      .sort()
      .reverse(); // Most recent first

    for (const dir of outputDirs) {
      const dirPath = path.join(tempOutputsDir, dir);
      const files = await fs.readdir(dirPath);

      // Look for verbose datamap files
      const verboseFile = files.find(f =>
        f.includes('dataMap') &&
        f.includes('verbose') &&
        f.endsWith('.json')
      );

      if (verboseFile) {
        return path.join(dirPath, verboseFile);
      }
    }
  } catch (error) {
    // temp-outputs doesn't exist or can't be read
  }

  return null;
}

async function loadDataMap(filePath: string): Promise<VerboseDataMapType[]> {
  const content = await fs.readFile(filePath, 'utf-8');
  const data = JSON.parse(content);

  // Handle both raw array and wrapped formats
  if (Array.isArray(data)) {
    return data;
  } else if (data.variables && Array.isArray(data.variables)) {
    return data.variables;
  } else if (data.verbose && Array.isArray(data.verbose)) {
    return data.verbose;
  }

  throw new Error('Could not find verbose datamap array in file');
}

async function main() {
  log('\n========================================', 'cyan');
  log('  TableAgent Test Script', 'bright');
  log('========================================\n', 'cyan');

  // Get datamap path from args or find latest
  let dataMapPath = process.argv[2];

  if (!dataMapPath) {
    log('No datamap path provided, searching for latest...', 'dim');
    dataMapPath = await findLatestDataMap() || '';

    if (!dataMapPath) {
      log('ERROR: No verbose datamap found in temp-outputs/', 'red');
      log('Run the full pipeline first to generate a datamap, or specify a path:', 'yellow');
      log('  npx tsx scripts/test-table-agent.ts <path-to-datamap.json>', 'dim');
      process.exit(1);
    }

    log(`Found: ${path.relative(process.cwd(), dataMapPath)}`, 'green');
  }

  // Load and validate datamap
  log('\nLoading datamap...', 'blue');
  let dataMap: VerboseDataMapType[];

  try {
    dataMap = await loadDataMap(dataMapPath);
    log(`Loaded ${dataMap.length} total variables`, 'green');
  } catch (error) {
    log(`ERROR: Failed to load datamap: ${error instanceof Error ? error.message : 'Unknown error'}`, 'red');
    process.exit(1);
  }

  // Show filtering stats
  const typeDistribution: Record<string, number> = {};
  for (const v of dataMap) {
    const type = v.normalizedType || 'undefined';
    typeDistribution[type] = (typeDistribution[type] || 0) + 1;
  }

  log('\nNormalized type distribution:', 'bright');
  let excludedCount = 0;
  for (const [type, count] of Object.entries(typeDistribution).sort((a, b) => b[1] - a[1])) {
    const isExcluded = EXCLUDED_NORMALIZED_TYPES.has(type);
    if (isExcluded) excludedCount += count;
    const marker = isExcluded ? ' (excluded)' : '';
    log(`  ${type}: ${count}${marker}`, isExcluded ? 'dim' : 'cyan');
  }

  const processableCount = dataMap.length - excludedCount;
  log(`\nProcessable: ${processableCount} variables (${excludedCount} excluded)`, 'green');

  // Preview grouping
  const groups = groupDataMapByParent(dataMap);
  log(`Question groups: ${groups.length}`, 'green');

  // Create output folder
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFolder = `table-test-${timestamp}`;

  log(`\nOutput folder: temp-outputs/${outputFolder}/`, 'dim');

  // Run TableAgent
  log('\n----------------------------------------', 'cyan');
  log('Running TableAgent...', 'bright');
  log('----------------------------------------\n', 'cyan');

  const startTime = Date.now();

  try {
    const { results, processingLog } = await processDataMap(dataMap, outputFolder, (completed, total) => {
      log(`  Progress: ${completed}/${total} question groups`, 'dim');
    });

    const duration = Date.now() - startTime;

    // Summary
    log('\n========================================', 'green');
    log('  Processing Complete', 'bright');
    log('========================================\n', 'green');

    const totalTables = results.reduce((sum, r) => sum + r.tables.length, 0);
    const avgConfidence = results.length > 0
      ? results.reduce((sum, r) => sum + r.confidence, 0) / results.length
      : 0;

    log(`Duration: ${(duration / 1000).toFixed(1)}s`, 'dim');
    log(`Question groups processed: ${results.length}`, 'cyan');
    log(`Total tables generated: ${totalTables}`, 'cyan');
    log(`Average confidence: ${(avgConfidence * 100).toFixed(1)}%`, avgConfidence >= 0.8 ? 'green' : avgConfidence >= 0.6 ? 'yellow' : 'red');

    // Table type distribution
    const tableTypeDistribution: Record<string, number> = {};
    for (const result of results) {
      for (const table of result.tables) {
        tableTypeDistribution[table.tableType] = (tableTypeDistribution[table.tableType] || 0) + 1;
      }
    }

    log('\nTable type distribution:', 'bright');
    for (const [type, count] of Object.entries(tableTypeDistribution).sort((a, b) => b[1] - a[1])) {
      log(`  ${type}: ${count}`, 'dim');
    }

    // Low confidence warnings
    const lowConfidence = results.filter(r => r.confidence < 0.7);
    if (lowConfidence.length > 0) {
      log('\nLow confidence questions (< 0.7):', 'yellow');
      for (const r of lowConfidence) {
        log(`  ${r.questionId}: ${(r.confidence * 100).toFixed(0)}% - ${r.reasoning.substring(0, 60)}...`, 'yellow');
      }
    }

    log(`\nOutput saved to: temp-outputs/${outputFolder}/`, 'green');
    log('', 'reset');

  } catch (error) {
    log(`\nERROR: TableAgent processing failed: ${error instanceof Error ? error.message : 'Unknown error'}`, 'red');
    if (error instanceof Error && error.stack) {
      log(error.stack, 'dim');
    }
    process.exit(1);
  }
}

main().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});
