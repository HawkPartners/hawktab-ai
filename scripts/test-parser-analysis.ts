#!/usr/bin/env npx tsx
/**
 * Parser Analysis Script
 *
 * Purpose: Quick analysis of .sav file parsing across multiple datasets.
 * Shows extraction quality, richness, and potential gaps.
 *
 * Usage:
 *   npx tsx scripts/test-parser-analysis.ts
 *
 * Output:
 *   outputs/_parser-analysis/run-<timestamp>/
 */

import '../src/lib/loadEnv';
import path from 'path';
import fs from 'fs/promises';
import { validate } from '../src/lib/validation/ValidationRunner';

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
// Parser Test
// =============================================================================

async function testParser(spssPath: string, name: string, outputDir: string) {
  log(`\n${'='.repeat(60)}`, 'magenta');
  log(`TESTING: ${name}`, 'bright');
  log(`${'='.repeat(60)}`, 'magenta');

  const datasetStart = Date.now();

  // Check file exists before attempting validation
  try {
    await fs.access(spssPath);
  } catch {
    log(`SKIPPED: .sav file not found at ${spssPath}`, 'yellow');
    return;
  }

  try {
    const report = await validate({ spssPath, outputDir });

    if (!report.canProceed || !report.processingResult) {
      log(`FAILED: ${report.errors.map(e => e.message).join(', ')}`, 'red');
      return;
    }

    const result = report.processingResult;

    // Analyze what was extracted
    const verbose = result.verbose;
    const parents = verbose.filter(v => v.level === 'parent');
    const subs = verbose.filter(v => v.level === 'sub');

    log(`\nExtraction Summary:`, 'blue');
    log(`  Total variables: ${verbose.length}`, 'reset');
    log(`  Parent questions: ${parents.length}`, 'reset');
    log(`  Sub-variables: ${subs.length}`, 'reset');
    log(`  Confidence: ${result.confidence.toFixed(2)}`, result.confidence >= 0.8 ? 'green' : 'yellow');

    // Check for answer options
    const withOptions = verbose.filter(v => v.answerOptions && v.answerOptions !== 'NA');
    const withContext = verbose.filter(v => v.context);
    const withNormalizedType = verbose.filter(v => v.normalizedType);

    log(`\nRichness Analysis:`, 'blue');
    log(`  With answer options: ${withOptions.length}`, 'reset');
    log(`  With context: ${withContext.length}`, 'reset');
    log(`  With normalized type: ${withNormalizedType.length}`, 'reset');

    // Normalized type distribution
    const typeDistribution: Record<string, number> = {};
    for (const v of verbose) {
      const type = v.normalizedType || 'undefined';
      typeDistribution[type] = (typeDistribution[type] || 0) + 1;
    }

    log(`\nType Distribution:`, 'blue');
    for (const [type, count] of Object.entries(typeDistribution).sort((a, b) => b[1] - a[1])) {
      const pct = ((count / verbose.length) * 100).toFixed(1);
      log(`  ${type}: ${count} (${pct}%)`, 'cyan');
    }

    // Sample what answer options look like
    log(`\nSample Answer Options (first 3):`, 'blue');
    for (const v of withOptions.slice(0, 3)) {
      const opts = v.answerOptions?.substring(0, 60) || '';
      log(`  ${v.column}: ${opts}...`, 'dim');
    }

    // Check for potential gaps
    log(`\nPotential Gaps:`, 'yellow');
    const noDesc = verbose.filter(v => !v.description || v.description.length < 10);
    const noType = verbose.filter(v => !v.normalizedType);
    const subsNoContext = subs.filter(v => !v.context);

    log(`  Vars with short/no description: ${noDesc.length}`, 'reset');
    log(`  Vars with no normalizedType: ${noType.length}`, 'reset');
    log(`  Sub-vars missing context: ${subsNoContext.length} of ${subs.length}`, 'reset');

    // Show a few vars missing context
    if (subsNoContext.length > 0) {
      log(`  Sample missing context: ${subsNoContext.slice(0, 3).map(v => v.column).join(', ')}`, 'dim');
    }

    // Loop detection summary
    if (report.loopDetection?.hasLoops) {
      log(`\nLoop Detection:`, 'blue');
      log(`  Loops found: ${report.loopDetection.loops.length}`, 'green');
      for (const loop of report.loopDetection.loops) {
        log(`  Pattern: ${loop.skeleton}, ${loop.iterations.length} iterations`, 'dim');
      }
    }

    const datasetDuration = Date.now() - datasetStart;
    log(`\nDuration: ${(datasetDuration / 1000).toFixed(1)}s`, 'dim');

  } catch (error) {
    log(`ERROR: ${error instanceof Error ? error.message : error}`, 'red');
  }
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const totalStart = Date.now();

  log('', 'reset');
  log('='.repeat(60), 'magenta');
  log('  Parser Analysis', 'bright');
  log('='.repeat(60), 'magenta');
  log('', 'reset');

  // Create output directory
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputDir = path.join(process.cwd(), 'outputs', '_parser-analysis', `run-${timestamp}`);
  await fs.mkdir(outputDir, { recursive: true });
  log(`Output: outputs/_parser-analysis/run-${timestamp}`, 'blue');

  // Test Leqvio
  await testParser(
    'data/leqvio-monotherapy-demand-NOV217/inputs/leqvio-monotherapy-demand-data.sav',
    'Leqvio Monotherapy Demand',
    outputDir
  );

  // Test Titos
  await testParser(
    'data/test-data/titos-growth-strategy/250800.sav',
    'Titos Growth Strategy',
    outputDir
  );

  // Test Spravato
  await testParser(
    'data/test-data/Spravato_4.23.25/Spravato 4.23.25.sav',
    'Spravato',
    outputDir
  );

  // Total duration
  const totalDuration = Date.now() - totalStart;
  log('', 'reset');
  log('='.repeat(60), 'green');
  log(`  Total Duration: ${(totalDuration / 1000).toFixed(1)}s`, 'bright');
  log('='.repeat(60), 'green');
  log('', 'reset');
}

main().catch((error) => {
  log(`Error: ${error instanceof Error ? error.message : String(error)}`, 'red');
  console.error(error);
  process.exit(1);
});
