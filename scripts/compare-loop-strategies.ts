/**
 * Loop Detection Strategy Comparison
 *
 * Runs the CURRENT loop detection vs a PROPOSED stricter approach against
 * multiple datasets side by side. Shows which loop groups would be reclassified
 * as "fixed grids" (skip stacking) under the new rules.
 *
 * Usage: npx tsx scripts/compare-loop-strategies.ts
 *        npx tsx scripts/compare-loop-strategies.ts --include-all   # run all 15 datasets
 */

import '../src/lib/loadEnv';
import path from 'path';
import fs from 'fs';
import { validate } from '../src/lib/validation/ValidationRunner';
import type { LoopGroup, LoopFillRateResult } from '../src/lib/validation/types';

// =============================================================================
// Datasets
// =============================================================================

const CORE_DATASETS = [
  { name: 'Tito\'s Growth Strategy', path: 'data/titos-growth-strategy/titos-growth-strategy-data.sav' },
  { name: 'Caplyta MaxDiff', path: 'data/caplyta-maxdiff/Data Caplyta MR_final_updated MDX appended.sav' },
];

const EXTRA_DATASETS = [
  { name: 'Iptacopan', path: 'data/Iptacopan-Data_2.23.24/Iptacopan Data 2.23.24.sav' },
  { name: 'Leqvio Demand W1', path: 'data/Leqvio-Demand-W1_3.13.23/Leqvio Demand W1 3.13.23 .sav' },
  { name: 'Leqvio Demand W2', path: 'data/Leqvio-Demand-W2_8.16.24 v2/Leqvio Demand W2 8.16.24 v2.sav' },
  { name: 'Leqvio Monotherapy', path: 'data/leqvio-monotherapy-demand-NOV217/inputs/leqvio-monotherapy-demand-data.sav' },
  { name: 'Leqvio Seg HCP W1', path: 'data/Leqvio-Segmentation-Data-HCP-W1_7.11.23/Leqvio Segmentation Data HCP W1 7.11.23.sav' },
  { name: 'Leqvio Seg Patients', path: 'data/Leqvio-Segmentation-Patients-Data_7.7.23/Leqvio Segmentation Patients Data 7.7.23.sav' },
  { name: 'GVHD', path: 'data/GVHD-Data_12.27.22/GVHD Data 12.27.22.sav' },
  { name: 'CART Segmentation', path: 'data/CART-Segmentation-Data_7.22.24_v2/CAR T Segmentation Data 7.22.24 v2.sav' },
  { name: 'UCB Caregiver W1', path: 'data/UCB-Caregiver-ATU-W1-Data_1.11.23/UCB Caregiver ATU W1 Data 1.11.23.sav' },
  { name: 'UCB Caregiver W2', path: 'data/UCB-Caregiver-ATU-W2-Data_9.1.23/UCB Caregiver ATU W2 Data 9.1.23.sav' },
  { name: 'UCB Dravet W3', path: 'data/UCB-W3/UCB Dravet Wave 3 Data 1.23.24.sav' },
  { name: 'Spravato', path: 'data/Spravato_4.23.25/Spravato 4.23.25.sav' },
  { name: 'UCB Caregiver W4', path: 'data/UCB-Caregiver-ATU-W4-Data_8.16.24/UCB Caregiver ATU W4 Data 8.16.24.sav' },
];

// =============================================================================
// Proposed Stricter Rules
// =============================================================================

interface ProposedClassification {
  group: LoopGroup;
  fillRateResult: LoopFillRateResult | null;
  currentVerdict: 'loop (stack)';
  proposedVerdict: 'loop (stack)' | 'fixed_grid (skip stacking)';
  reasons: string[];
}

/**
 * Apply proposed stricter rules to decide whether a detected loop group
 * should actually be stacked.
 *
 * Rules (any matching rule → fixed_grid):
 *   1. All fill rates >= 0.95 AND iterations >= 8
 *   2. Diversity/iteration ratio < 0.5 AND all fill rates >= 0.95
 */
function classifyWithProposedRules(
  group: LoopGroup,
  fillRateResult: LoopFillRateResult | null,
): ProposedClassification {
  const result: ProposedClassification = {
    group,
    fillRateResult,
    currentVerdict: 'loop (stack)',
    proposedVerdict: 'loop (stack)',
    reasons: [],
  };

  if (!fillRateResult) {
    result.reasons.push('No fill rate data — keeping as loop');
    return result;
  }

  const rates = Object.values(fillRateResult.fillRates);
  const allHighFill = rates.length > 0 && rates.every((r) => r >= 0.95);
  const iterCount = group.iterations.length;
  const diversityRatio = group.diversity / iterCount;

  // Rule 1: Uniform high fill + many iterations = fixed grid
  if (allHighFill && iterCount >= 8) {
    result.proposedVerdict = 'fixed_grid (skip stacking)';
    result.reasons.push(
      `100% fill across all ${iterCount} iterations (threshold: >=8) — fixed grid, not a true loop`
    );
  }

  // Rule 2: Low diversity relative to iterations + high fill = repeated grid
  if (allHighFill && diversityRatio < 0.5) {
    if (result.proposedVerdict !== 'fixed_grid (skip stacking)') {
      result.proposedVerdict = 'fixed_grid (skip stacking)';
    }
    result.reasons.push(
      `Diversity/iteration ratio = ${diversityRatio.toFixed(2)} (${group.diversity} bases / ${iterCount} iters) — few questions repeated many times`
    );
  }

  if (result.proposedVerdict === 'loop (stack)') {
    result.reasons.push('Passes proposed rules — genuine loop, keep stacking');
  }

  return result;
}

// =============================================================================
// Display Helpers
// =============================================================================

function printHeader(text: string) {
  const line = '═'.repeat(70);
  console.log(`\n${line}`);
  console.log(`  ${text}`);
  console.log(line);
}

function printSubHeader(text: string) {
  console.log(`\n  ── ${text} ──`);
}

function verdictColor(verdict: string): string {
  if (verdict.includes('fixed_grid')) return `\x1b[33m${verdict}\x1b[0m`;  // yellow
  return `\x1b[32m${verdict}\x1b[0m`;  // green
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const args = process.argv.slice(2);
  const includeAll = args.includes('--include-all');

  const datasets = includeAll
    ? [...CORE_DATASETS, ...EXTRA_DATASETS]
    : CORE_DATASETS;

  console.log('\n  Loop Detection Strategy Comparison');
  console.log(`  Datasets: ${datasets.length} (${includeAll ? 'all' : 'core only — use --include-all for all 15'})`);

  const tmpBase = 'outputs/_loop-comparison';

  // Summary table for the end
  const summary: Array<{
    dataset: string;
    currentLoops: number;
    proposedLoops: number;
    proposedGrids: number;
    details: string[];
  }> = [];

  for (const dataset of datasets) {
    printHeader(dataset.name);

    if (!fs.existsSync(dataset.path)) {
      console.log(`  SKIPPED — file not found: ${dataset.path}`);
      summary.push({ dataset: dataset.name, currentLoops: -1, proposedLoops: -1, proposedGrids: -1, details: ['file not found'] });
      continue;
    }

    const tmpDir = path.join(tmpBase, dataset.name.replace(/[^a-zA-Z0-9]/g, '-'));
    fs.mkdirSync(tmpDir, { recursive: true });

    try {
      const result = await validate({ spssPath: dataset.path, outputDir: tmpDir });

      const rows = result.dataFileStats?.rowCount ?? 0;
      const cols = result.dataFileStats?.columns.length ?? 0;
      console.log(`  ${rows} respondents, ${cols} variables`);

      if (!result.loopDetection?.hasLoops) {
        console.log(`  No loops detected (current or proposed).`);
        summary.push({ dataset: dataset.name, currentLoops: 0, proposedLoops: 0, proposedGrids: 0, details: ['no loops'] });
        continue;
      }

      const loops = result.loopDetection.loops;
      console.log(`  Current detection: ${loops.length} loop group(s)`);

      // Classify each group with proposed rules
      const classifications: ProposedClassification[] = [];

      for (const loop of loops) {
        const fillResult = result.fillRateResults.find(
          (fr) => fr.loopGroup.skeleton === loop.skeleton
        ) ?? null;

        const classification = classifyWithProposedRules(loop, fillResult);
        classifications.push(classification);
      }

      // Display each group
      for (const c of classifications) {
        const g = c.group;
        const fr = c.fillRateResult;
        const rates = fr ? Object.values(fr.fillRates) : [];
        const avgFill = rates.length > 0 ? (rates.reduce((a, b) => a + b, 0) / rates.length * 100).toFixed(0) : '?';
        const minFill = rates.length > 0 ? (Math.min(...rates) * 100).toFixed(0) : '?';
        const diversityRatio = (g.diversity / g.iterations.length).toFixed(2);

        printSubHeader(g.skeleton);
        console.log(`    Iterations:      ${g.iterations.length} → [${g.iterations.slice(0, 8).join(', ')}${g.iterations.length > 8 ? ', ...' : ''}]`);
        console.log(`    Diversity:       ${g.diversity} bases (ratio: ${diversityRatio})`);
        console.log(`    Variables:       ${g.variables.length}`);
        console.log(`    Fill rate:       avg ${avgFill}%, min ${minFill}%`);
        console.log(`    Fill pattern:    ${fr?.pattern ?? 'unknown'}`);
        console.log(`    Current:         ${verdictColor(c.currentVerdict)}`);
        console.log(`    Proposed:        ${verdictColor(c.proposedVerdict)}`);
        for (const reason of c.reasons) {
          console.log(`      → ${reason}`);
        }
      }

      const proposedLoops = classifications.filter((c) => c.proposedVerdict === 'loop (stack)').length;
      const proposedGrids = classifications.filter((c) => c.proposedVerdict === 'fixed_grid (skip stacking)').length;

      const details = classifications.map(
        (c) => `${c.group.skeleton}: ${c.proposedVerdict}`
      );
      summary.push({
        dataset: dataset.name,
        currentLoops: loops.length,
        proposedLoops,
        proposedGrids,
        details,
      });
    } catch (err) {
      console.log(`  ERROR: ${err instanceof Error ? err.message : String(err)}`);
      summary.push({ dataset: dataset.name, currentLoops: -1, proposedLoops: -1, proposedGrids: -1, details: ['error'] });
    }
  }

  // ==========================================================================
  // Summary Table
  // ==========================================================================
  printHeader('SUMMARY');

  const nameWidth = Math.max(...summary.map((s) => s.dataset.length), 12);

  console.log(
    `  ${'Dataset'.padEnd(nameWidth)}  ${'Current'.padStart(7)}  ${'Proposed'.padStart(8)}  ${'Grids'.padStart(5)}  Change`
  );
  console.log(`  ${'─'.repeat(nameWidth)}  ${'─'.repeat(7)}  ${'─'.repeat(8)}  ${'─'.repeat(5)}  ${'─'.repeat(30)}`);

  for (const s of summary) {
    if (s.currentLoops < 0) {
      console.log(`  ${s.dataset.padEnd(nameWidth)}  ${'skip'.padStart(7)}  ${'skip'.padStart(8)}  ${'skip'.padStart(5)}  ${s.details[0]}`);
      continue;
    }

    const changed = s.currentLoops !== s.proposedLoops;
    const changeMarker = changed ? ` ← ${s.proposedGrids} reclassified as grid` : ' (no change)';

    console.log(
      `  ${s.dataset.padEnd(nameWidth)}  ${String(s.currentLoops).padStart(7)}  ${String(s.proposedLoops).padStart(8)}  ${String(s.proposedGrids).padStart(5)}  ${changeMarker}`
    );
  }

  console.log('');
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
