#!/usr/bin/env npx tsx
/**
 * Pipeline Test Script
 *
 * Thin wrapper around PipelineRunner for command-line usage.
 * All pipeline logic lives in src/lib/pipeline/PipelineRunner.ts.
 *
 * Usage:
 *   npx tsx scripts/test-pipeline.ts [dataset-folder] [options]
 *
 * Options:
 *   --format=joe|antares     Excel format (default: joe). Note: antares is deprecated.
 *   --display=frequency|counts|both   Display mode (default: frequency)
 *   --separate-workbooks     When --display=both, output two .xlsx files instead of two sheets
 *   --stop-after-verification   Stop before R/Excel generation
 *   --concurrency=N            Parallel agent limit (default: 3)
 *   --show-defaults            Show current pipeline configuration and exit
 *
 * Examples:
 *   npx tsx scripts/test-pipeline.ts
 *   npx tsx scripts/test-pipeline.ts data/test-data/titos-growth-strategy
 *   npx tsx scripts/test-pipeline.ts --display=both --separate-workbooks
 *   npx tsx scripts/test-pipeline.ts --stop-after-verification
 *   npx tsx scripts/test-pipeline.ts --show-defaults
 */

// Load environment variables
import '../src/lib/loadEnv';

import { runPipeline } from '../src/lib/pipeline/PipelineRunner';
import { DEFAULT_PIPELINE_OPTIONS } from '../src/lib/pipeline/types';
import { getStatTestingConfig, formatStatTestingConfig } from '../src/lib/env';
import type { ExcelFormat, DisplayMode } from '../src/lib/excel/ExcelFormatter';

// =============================================================================
// CLI Argument Parsing
// =============================================================================

function parseFormatFlag(): ExcelFormat {
  const arg = process.argv.find(a => a.startsWith('--format='));
  if (arg) {
    const value = arg.split('=')[1]?.toLowerCase();
    if (value === 'antares') return 'antares';
  }
  return 'joe';
}

function parseDisplayFlag(): DisplayMode {
  const arg = process.argv.find(a => a.startsWith('--display='));
  if (arg) {
    const value = arg.split('=')[1]?.toLowerCase();
    if (value === 'counts') return 'counts';
    if (value === 'both') return 'both';
  }
  return 'frequency';
}

function parseConcurrency(): number {
  const arg = process.argv.find(a => a.startsWith('--concurrency='));
  if (arg) {
    const value = parseInt(arg.split('=')[1], 10);
    if (!isNaN(value) && value > 0) return value;
  }
  return 3;
}

function parseThemeFlag(): string {
  const arg = process.argv.find(a => a.startsWith('--theme='));
  if (arg) {
    return arg.split('=')[1]?.toLowerCase() || 'classic';
  }
  return 'classic';
}

// =============================================================================
// Main
// =============================================================================

function showDefaults(): void {
  const defaults = DEFAULT_PIPELINE_OPTIONS;
  const statConfig = getStatTestingConfig();

  console.log('\nHawkTab AI — Current Pipeline Defaults');
  console.log('═'.repeat(45));
  console.log(`\nOutput:`);
  console.log(`  Format: ${defaults.format}`);
  console.log(`  Display Mode: ${defaults.displayMode}`);
  console.log(`  Separate Workbooks: ${defaults.separateWorkbooks}`);
  console.log(`\nProcessing:`);
  console.log(`  Concurrency: ${defaults.concurrency}`);
  console.log(`\nStatistical Testing:`);
  console.log(`  ${formatStatTestingConfig(statConfig)}`);
  console.log('');
}

async function main() {
  if (process.argv.includes('--show-defaults')) {
    showDefaults();
    return;
  }

  const datasetFolder = process.argv.slice(2).find(arg => !arg.startsWith('--'));

  const result = await runPipeline(datasetFolder, {
    format: parseFormatFlag(),
    displayMode: parseDisplayFlag(),
    separateWorkbooks: process.argv.includes('--separate-workbooks'),
    stopAfterVerification: process.argv.includes('--stop-after-verification'),
    concurrency: parseConcurrency(),
    theme: parseThemeFlag(),
  });

  if (!result.success) {
    console.error(`\nPipeline failed: ${result.error}`);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(`\nUnexpected error: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
