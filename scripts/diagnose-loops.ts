/**
 * Loop Detection Diagnostic Script
 *
 * Point this at any .sav file to see exactly what the LoopDetector finds.
 * Shows every detected loop group with full variable lists, skeleton patterns,
 * iterations, diversity scores, and fill rate analysis.
 *
 * Usage:
 *   npx tsx scripts/diagnose-loops.ts path/to/data.sav
 *   npx tsx scripts/diagnose-loops.ts path/to/data.sav --verbose   # show all variables per group
 */

import '../src/lib/loadEnv';
import path from 'path';
import fs from 'fs';
import { validate } from '../src/lib/validation/ValidationRunner';
import { tokenize, createSkeleton } from '../src/lib/validation/LoopDetector';
import type { LoopGroup } from '../src/lib/validation/types';

// =============================================================================
// CLI Args
// =============================================================================

const args = process.argv.slice(2);
const verbose = args.includes('--verbose');
// Join all non-flag args to handle paths with spaces (unquoted)
const savPath = args.filter((a) => !a.startsWith('--')).join(' ') || null;

if (!savPath) {
  console.error('Usage: npx tsx scripts/diagnose-loops.ts <path-to-sav> [--verbose]');
  process.exit(1);
}

if (!fs.existsSync(savPath)) {
  console.error(`ERROR: File not found: ${savPath}`);
  process.exit(1);
}

// =============================================================================
// Helpers
// =============================================================================

function printSeparator(label: string) {
  console.log(`\n${'='.repeat(70)}`);
  console.log(`  ${label}`);
  console.log('='.repeat(70));
}

function printLoopGroup(loop: LoopGroup, index: number) {
  console.log(`\n  ── Loop Group ${index + 1} ──`);
  console.log(`  Skeleton:          ${loop.skeleton}`);
  console.log(`  Iterator position: token[${loop.iteratorPosition}]`);
  console.log(`  Iterations:        ${loop.iterations.length} → [${loop.iterations.join(', ')}]`);
  console.log(`  Diversity:         ${loop.diversity} unique bases per iteration`);
  console.log(`  Total variables:   ${loop.variables.length}`);
  console.log(`  Base patterns (${loop.bases.length}):`);

  const basesToShow = verbose ? loop.bases : loop.bases.slice(0, 10);
  for (const base of basesToShow) {
    console.log(`    ${base}`);
  }
  if (!verbose && loop.bases.length > 10) {
    console.log(`    ... and ${loop.bases.length - 10} more (use --verbose to see all)`);
  }

  // Show example variables: pick first base, show its iteration columns
  if (loop.bases.length > 0) {
    const firstBase = loop.bases[0];
    // The base pattern has a * where the iteration goes. Find the matching vars.
    const exampleVars = loop.variables
      .filter((v) => {
        // Check if this variable matches the first base pattern
        const pattern = firstBase.replace('*', '(.+)');
        return new RegExp(`^${pattern}$`).test(v);
      })
      .slice(0, 5);
    if (exampleVars.length > 0) {
      console.log(`  Example (${firstBase}):`);
      for (const v of exampleVars) {
        console.log(`    ${v}`);
      }
    }
  }

  if (verbose) {
    console.log(`  All variables:`);
    for (const v of loop.variables) {
      console.log(`    ${v}`);
    }
  }
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const startTime = Date.now();
  const fileName = path.basename(savPath!);

  console.log(`\n  Loop Detection Diagnostic`);
  console.log(`  File: ${fileName}`);
  console.log(`  Path: ${path.resolve(savPath!)}`);
  console.log(`  Mode: ${verbose ? 'verbose' : 'summary'}`);

  // Create a temp output dir for validation
  const tmpDir = path.join('outputs', '_loop-diagnostic', `run-${Date.now()}`);
  fs.mkdirSync(tmpDir, { recursive: true });

  // -------------------------------------------------------------------------
  // Run Validation (stages 1-4)
  // -------------------------------------------------------------------------
  printSeparator('Stage 1: Data File Validation');

  const result = await validate({
    spssPath: savPath!,
    outputDir: tmpDir,
  });

  const colCount = result.dataFileStats?.columns.length ?? 0;
  console.log(`  Rows:       ${result.dataFileStats?.rowCount ?? 'unknown'}`);
  console.log(`  Columns:    ${colCount || 'unknown'}`);
  console.log(`  Can proceed: ${result.canProceed}`);

  if (result.errors.length > 0) {
    console.log(`\n  Errors:`);
    for (const e of result.errors) {
      console.log(`    [${e.severity}] ${e.message}`);
    }
  }

  if (result.warnings.length > 0) {
    console.log(`\n  Warnings:`);
    for (const w of result.warnings) {
      console.log(`    ${w.message}`);
    }
  }

  // -------------------------------------------------------------------------
  // Loop Detection Results
  // -------------------------------------------------------------------------
  printSeparator('Stage 2: Loop Detection Results');

  const loopDetection = result.loopDetection;

  if (!loopDetection || !loopDetection.hasLoops) {
    console.log('\n  No loops detected.');
    console.log(`\n  All ${result.dataFileStats?.columns.length ?? '?'} variables are non-loop.`);

    if (verbose && result.processingResult) {
      console.log('\n  Sample variable tokenization:');
      const sampleVars = result.processingResult.verbose.slice(0, 20);
      for (const v of sampleVars) {
        const tokens = tokenize(v.column);
        const skeleton = createSkeleton(tokens);
        console.log(`    ${v.column.padEnd(30)} → ${skeleton}`);
      }
    }

    cleanup(tmpDir, startTime);
    return;
  }

  console.log(`  Loops found:         ${loopDetection.loops.length} group(s)`);
  console.log(`  Loop variables:      ${loopDetection.loops.reduce((sum, l) => sum + l.variables.length, 0)}`);
  console.log(`  Non-loop variables:  ${loopDetection.nonLoopVariables.length}`);

  // Sort loops by diversity (highest first) for readability
  const sortedLoops = [...loopDetection.loops].sort((a, b) => b.diversity - a.diversity);

  for (let i = 0; i < sortedLoops.length; i++) {
    printLoopGroup(sortedLoops[i], i);
  }

  // -------------------------------------------------------------------------
  // Fill Rate Analysis
  // -------------------------------------------------------------------------
  if (result.fillRateResults.length > 0) {
    printSeparator('Stage 3: Fill Rate Analysis');

    for (const fr of result.fillRateResults) {
      console.log(`\n  Skeleton: ${fr.loopGroup.skeleton}`);
      console.log(`  Pattern:  ${fr.pattern}`);

      const explanation: Record<string, string> = {
        valid_wide: 'All iterations have similar fill rates — true wide-format loop',
        likely_stacked: 'Only iteration 1 filled, others nearly empty — data may already be stacked',
        expected_dropout: 'Fill rates decrease across iterations — optional/cascading questions',
        uncertain: 'Ambiguous pattern — could be either',
      };
      console.log(`  Meaning:  ${explanation[fr.pattern] ?? fr.pattern}`);

      console.log(`  Fill rates by iteration:`);
      const rates = Object.entries(fr.fillRates).sort(([a], [b]) => Number(a) - Number(b));
      for (const [iter, rate] of rates) {
        const bar = '█'.repeat(Math.round(rate * 50));
        const pct = (rate * 100).toFixed(1);
        console.log(`    iter ${iter.padStart(3)}: ${pct.padStart(6)}%  ${bar}`);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Non-loop Variable Summary
  // -------------------------------------------------------------------------
  printSeparator('Stage 4: Non-loop Variables');

  const nonLoop = loopDetection.nonLoopVariables;
  console.log(`  ${nonLoop.length} variables not assigned to any loop group.`);

  if (verbose) {
    // Group non-loop vars by skeleton for readability
    const skeletonMap = new Map<string, string[]>();
    for (const v of nonLoop) {
      const tokens = tokenize(v);
      const skeleton = createSkeleton(tokens);
      const group = skeletonMap.get(skeleton) || [];
      group.push(v);
      skeletonMap.set(skeleton, group);
    }

    // Sort by group size descending
    const sorted = Array.from(skeletonMap.entries()).sort((a, b) => b[1].length - a[1].length);
    console.log(`\n  Grouped by skeleton pattern (${sorted.length} patterns):`);

    for (const [skeleton, vars] of sorted.slice(0, 30)) {
      console.log(`    ${skeleton.padEnd(30)} (${vars.length} vars): ${vars.slice(0, 5).join(', ')}${vars.length > 5 ? '...' : ''}`);
    }
    if (sorted.length > 30) {
      console.log(`    ... and ${sorted.length - 30} more patterns`);
    }
  } else {
    // Just show first 20
    console.log(`  First 20: ${nonLoop.slice(0, 20).join(', ')}${nonLoop.length > 20 ? '...' : ''}`);
    console.log(`  (use --verbose to see all, grouped by skeleton pattern)`);
  }

  // -------------------------------------------------------------------------
  // Weight Detection (bonus)
  // -------------------------------------------------------------------------
  if (result.weightDetection && result.weightDetection.candidates.length > 0) {
    printSeparator('Bonus: Weight Candidates');
    for (const c of result.weightDetection.candidates.slice(0, 5)) {
      console.log(`  ${c.column.padEnd(25)} score=${c.score.toFixed(2)}  mean=${c.mean.toFixed(3)}  label="${c.label}"`);
    }
  }

  // -------------------------------------------------------------------------
  // Save JSON report
  // -------------------------------------------------------------------------
  const reportPath = path.join(tmpDir, 'loop-diagnostic.json');
  const report = {
    file: fileName,
    timestamp: new Date().toISOString(),
    rows: result.dataFileStats?.rowCount,
    columns: result.dataFileStats?.columns.length,
    loopGroups: loopDetection.loops.map((l) => ({
      skeleton: l.skeleton,
      iteratorPosition: l.iteratorPosition,
      iterations: l.iterations,
      diversity: l.diversity,
      baseCount: l.bases.length,
      variableCount: l.variables.length,
      bases: l.bases,
      variables: l.variables,
    })),
    fillRateResults: result.fillRateResults.map((fr) => ({
      skeleton: fr.loopGroup.skeleton,
      pattern: fr.pattern,
      fillRates: fr.fillRates,
    })),
    nonLoopVariableCount: nonLoop.length,
    nonLoopVariables: nonLoop,
  };
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(`\n  Full report saved to: ${reportPath}`);

  cleanup(tmpDir, startTime);
}

function cleanup(tmpDir: string, startTime: number) {
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log(`\n  Done in ${elapsed}s`);
  console.log(`  Output: ${tmpDir}\n`);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
