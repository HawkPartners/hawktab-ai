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
 *   --format=joe|antares     Excel format (default: joe)
 *   --display=frequency|counts|both   Display mode (default: frequency)
 *   --stop-after-verification   Stop before R/Excel generation
 *   --concurrency=N            Parallel agent limit (default: 3)
 *
 * Examples:
 *   npx tsx scripts/test-pipeline.ts
 *   npx tsx scripts/test-pipeline.ts data/test-data/titos-growth-strategy
 *   npx tsx scripts/test-pipeline.ts --format=antares --display=both
 *   npx tsx scripts/test-pipeline.ts --stop-after-verification
 */

// Load environment variables
import '../src/lib/loadEnv';

import { runPipeline } from '../src/lib/pipeline/PipelineRunner';
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

// =============================================================================
// Main
// =============================================================================

async function main() {
  const datasetFolder = process.argv.slice(2).find(arg => !arg.startsWith('--'));

  const result = await runPipeline(datasetFolder, {
    format: parseFormatFlag(),
    displayMode: parseDisplayFlag(),
    stopAfterVerification: process.argv.includes('--stop-after-verification'),
    concurrency: parseConcurrency(),
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
