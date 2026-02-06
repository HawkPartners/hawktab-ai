/**
 * Integration test for ValidationRunner
 *
 * Tests against all dataset files in data/test-data/ plus the primary Leqvio dataset.
 * Uses .sav as the single source of truth — no CSV datamaps needed.
 *
 * Output structure:
 *   outputs/_validation-test/
 *     run-<timestamp>/
 *       <slug>/
 *         validation-report.json
 *         loop-variables.json   (if loops detected)
 *       summary.json
 *
 * Usage: npx tsx scripts/test-validation-runner.ts
 */

import '../src/lib/loadEnv';
import path from 'path';
import fs from 'fs';
import { validate } from '../src/lib/validation/ValidationRunner';
import type { ValidationReport } from '../src/lib/validation/types';

// =============================================================================
// Dataset Definitions
// =============================================================================

interface DatasetDef {
  name: string;
  slug: string;
  spssPath: string;
  /** Set true/false for known datasets, null for discovery (no assertion). */
  expectLoops: boolean | null;
}

/**
 * Helper to build a dataset entry from test-data directory.
 * Convention: directory contains `<Name>.sav`
 */
function dataset(
  name: string,
  slug: string,
  dir: string,
  savFile: string,
  expectLoops: boolean | null = null
): DatasetDef {
  return {
    name,
    slug,
    spssPath: `data/test-data/${dir}/${savFile}`,
    expectLoops,
  };
}

const DATASETS: DatasetDef[] = [
  // === Known / Verified ===
  {
    name: 'Leqvio Monotherapy (no loops)',
    slug: 'leqvio-monotherapy',
    spssPath: 'data/leqvio-monotherapy-demand-NOV217/inputs/leqvio-monotherapy-demand-data.sav',
    expectLoops: false,
  },
  {
    name: "Tito's (loops)",
    slug: 'titos',
    spssPath: 'data/test-data/titos-growth-strategy/250800.sav',
    expectLoops: true,
  },
  dataset('Spravato', 'spravato', 'Spravato_4.23.25',
    'Spravato 4.23.25.sav', false),

  // === SPSS Datasets ===
  dataset('CAR-T Segmentation', 'cart-segmentation', 'CART-Segmentation-Data_7.22.24_v2',
    'CAR T Segmentation Data 7.22.24 v2.sav'),
  dataset('Cambridge Savings Bank W1', 'csb-w1', 'Cambridge-Savings-Bank-W1_4.9.24',
    'Cambridge Savings Bank W1_4.9.24.sav'),
  dataset('Cambridge Savings Bank W2', 'csb-w2', 'Cambridge-Savings-Bank-W2_4.1.25',
    'Cambridge Savings Bank W2 4.1.25.sav'),
  dataset('GVHD', 'gvhd', 'GVHD-Data_12.27.22',
    'GVHD Data 12.27.22.sav'),
  dataset('Iptacopan', 'iptacopan', 'Iptacopan-Data_2.23.24',
    'Iptacopan Data 2.23.24.sav'),
  dataset('Leqvio Demand W1', 'leqvio-demand-w1', 'Leqvio-Demand-W1_3.13.23',
    'Leqvio Demand W1 3.13.23 .sav'),
  dataset('Leqvio Demand W2', 'leqvio-demand-w2', 'Leqvio-Demand-W2_8.16.24 v2',
    'Leqvio Demand W2 8.16.24 v2.sav'),
  dataset('Leqvio Demand W3', 'leqvio-demand-w3', 'Leqvio-Demand-W3_5.16.25',
    'Leqvio Demand W3 5.16.25.sav'),
  dataset('Leqvio Segmentation HCP W1', 'leqvio-seg-hcp-w1', 'Leqvio-Segmentation-Data-HCP-W1_7.11.23',
    'Leqvio Segmentation Data HCP W1 7.11.23.sav'),
  dataset('Leqvio Segmentation HCP W2', 'leqvio-seg-hcp-w2', 'Leqvio-Segmentation-Data-HCP-W2_2.21.2025',
    'Leqvio Segmentation Data HCP W2 2.21.2025.sav'),
  dataset('Leqvio Segmentation Patients', 'leqvio-seg-patients', 'Leqvio-Segmentation-Patients-Data_7.7.23',
    'Leqvio Segmentation Patients Data 7.7.23.sav'),
  dataset('Meningitis Vax', 'meningitis-vax', 'Meningitis-Vax-Data_10.14.22',
    'Meningitis Vax Data 10.14.22.sav'),
  dataset('Onc CE W2', 'onc-ce-w2', 'Onc-CE-W2-Data_5.10.20',
    'Onc CE W2 Data 5.10.20.sav'),
  dataset('Onc CE W3', 'onc-ce-w3', 'Onc-CE-W3-Data_5.13.21',
    'Onc CE W3 Data 5.13.21.sav'),
  dataset('Onc CE W4', 'onc-ce-w4', 'Onc-CE-W4-Data_3.11.22',
    'Onc CE W4 Data 3.11.22.sav'),
  dataset('Onc CE W5', 'onc-ce-w5', 'Onc-CE-W5-Data_2.7.23',
    'Onc CE W5 Data 2.7.23.sav'),
  dataset('Onc CE W6', 'onc-ce-w6', 'Onc-CE-W6-Data_3.18.24',
    'Onc CE W6 Data 3.18.24.sav'),
  dataset('UCB Caregiver ATU W1', 'ucb-w1', 'UCB-Caregiver-ATU-W1-Data_1.11.23',
    'UCB Caregiver ATU W1 Data 1.11.23.sav'),
  dataset('UCB Caregiver ATU W2', 'ucb-w2', 'UCB-Caregiver-ATU-W2-Data_9.1.23',
    'UCB Caregiver ATU W2 Data 9.1.23.sav'),
  dataset('UCB Caregiver ATU W4', 'ucb-w4', 'UCB-Caregiver-ATU-W4-Data_8.16.24',
    'UCB Caregiver ATU W4 Data 8.16.24.sav'),
  dataset('UCB Caregiver ATU W5', 'ucb-w5', 'UCB-Caregiver-ATU-W5-Data_1.7.25',
    'UCB Caregiver ATU W5 Data 1.7.25.sav'),
  dataset('UCB Caregiver ATU W6', 'ucb-w6', 'UCB-Caregiver-ATU-W6-Data_1.23.24',
    'UCB Caregiver ATU W6 Data 1.23.24.sav'),
];

// =============================================================================
// Enrichment Summary
// =============================================================================

/**
 * Build distribution stats for normalizedType and parent/sub level.
 * Makes it easy to spot-check enrichment quality without opening verbose JSON.
 */
function buildEnrichmentSummary(result: ValidationReport) {
  if (!result.processingResult?.verbose.length) return null;

  const vars = result.processingResult.verbose;

  // normalizedType distribution
  const typeCounts: Record<string, number> = {};
  for (const v of vars) {
    const t = (v as { normalizedType?: string }).normalizedType || '(none)';
    typeCounts[t] = (typeCounts[t] || 0) + 1;
  }

  // parent/sub distribution
  const levelCounts: Record<string, number> = { parent: 0, sub: 0 };
  for (const v of vars) {
    levelCounts[v.level] = (levelCounts[v.level] || 0) + 1;
  }

  // context coverage (how many subs got parent context)
  const subsWithContext = vars.filter(v => v.level === 'sub' && v.context).length;

  return {
    total: vars.length,
    levels: levelCounts,
    subsWithContext,
    normalizedTypes: typeCounts,
  };
}

// =============================================================================
// Loop Variables Report
// =============================================================================

/**
 * Build a detailed loop variables report for manual review in Q.
 */
function buildLoopVariablesReport(result: ValidationReport) {
  if (!result.loopDetection?.hasLoops) return null;

  return result.loopDetection.loops.map((loop) => ({
    pattern: loop.skeleton,
    iteratorPosition: loop.iteratorPosition,
    iterations: loop.iterations,
    iterationCount: loop.iterations.length,
    diversity: loop.diversity,
    baseCount: loop.bases.length,
    totalVariables: loop.variables.length,
    // Sorted variable list for easy scanning
    variables: [...loop.variables].sort(),
    // Group variables by iteration for side-by-side comparison
    byIteration: Object.fromEntries(
      loop.iterations.map((iter) => [
        `iteration_${iter}`,
        loop.variables
          .filter((v) => {
            // Match variables belonging to this iteration
            // by checking if the token at iterator position equals this value
            const sepIndex = v.lastIndexOf('_');
            if (sepIndex === -1) return false;
            const afterSep = v.substring(sepIndex + 1);
            // Handle cases like A4_1r1 where iter is embedded
            return afterSep === iter || afterSep.startsWith(iter);
          })
          .sort(),
      ])
    ),
  }));
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  // Create timestamped run folder
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const runDir = path.join(process.cwd(), 'outputs', '_validation-test', `run-${timestamp}`);
  fs.mkdirSync(runDir, { recursive: true });

  console.log(`Output: outputs/_validation-test/run-${timestamp}/`);
  console.log(`Datasets: ${DATASETS.length}`);

  let passed = 0;
  let failed = 0;
  let skipped = 0;
  const datasetResults: Record<string, {
    passed: boolean;
    variables: number;
    loops: number;
    errors: number;
    warnings: number;
    durationMs: number;
    loopDetails?: string;
  }> = {};

  for (const ds of DATASETS) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`Testing: ${ds.name}`);
    console.log('='.repeat(60));

    // Create per-dataset folder
    const datasetDir = path.join(runDir, ds.slug);
    fs.mkdirSync(datasetDir, { recursive: true });

    const spssPath = path.join(process.cwd(), ds.spssPath);

    // Check if .sav exists
    if (!fs.existsSync(spssPath)) {
      console.log(`  SKIP: .sav not found at ${ds.spssPath}`);
      skipped++;
      continue;
    }

    try {
      const result = await validate({
        spssPath,
        outputDir: datasetDir,
      });

      // Console report
      console.log(`\n  Format: ${result.format}`);
      console.log(`  Can Proceed: ${result.canProceed}`);
      console.log(`  Duration: ${result.durationMs}ms`);
      console.log(`  Errors: ${result.errors.length}`);
      console.log(`  Warnings: ${result.warnings.length}`);

      const enrichmentSummary = buildEnrichmentSummary(result);
      if (result.processingResult) {
        console.log(`  Variables: ${result.processingResult.verbose.length}`);
      }
      if (enrichmentSummary) {
        console.log(`  Levels: ${enrichmentSummary.levels.parent} parent, ${enrichmentSummary.levels.sub} sub (${enrichmentSummary.subsWithContext} with context)`);
        const typeEntries = Object.entries(enrichmentSummary.normalizedTypes)
          .sort(([, a], [, b]) => b - a);
        for (const [type, count] of typeEntries) {
          const pct = ((count / enrichmentSummary.total) * 100).toFixed(0);
          console.log(`    ${type}: ${count} (${pct}%)`);
        }
      }

      let loopSummary = 'none';
      if (result.loopDetection?.hasLoops) {
        console.log(`  Loops: ${result.loopDetection.loops.length}`);
        const loopParts: string[] = [];
        for (const loop of result.loopDetection.loops) {
          const desc = `${loop.skeleton}: ${loop.iterations.length} iters x ${loop.diversity} bases (${loop.variables.length} vars)`;
          console.log(`    - ${desc}`);
          loopParts.push(desc);
        }
        loopSummary = loopParts.join('; ');
      }

      if (result.dataFileStats) {
        console.log(`  Data Rows: ${result.dataFileStats.rowCount}`);
        console.log(`  Data Columns: ${result.dataFileStats.columns.length}`);
      }

      for (const w of result.warnings) {
        console.log(`  Warning [Stage ${w.stage}]: ${w.message}`);
      }
      for (const e of result.errors) {
        console.log(`  Error [Stage ${e.stage}]: ${e.message}`);
      }

      // Save validation report (without processingResult to keep it readable)
      const reportForDisk = {
        dataset: ds.name,
        format: result.format,
        canProceed: result.canProceed,
        durationMs: result.durationMs,
        variableCount: result.processingResult?.verbose.length ?? 0,
        enrichmentSummary,
        errors: result.errors,
        warnings: result.warnings,
        loopDetection: result.loopDetection,
        dataFileStats: result.dataFileStats,
        fillRateResults: result.fillRateResults,
      };
      fs.writeFileSync(
        path.join(datasetDir, 'validation-report.json'),
        JSON.stringify(reportForDisk, null, 2)
      );

      // Save untyped variables (normalizedType missing) for audit
      if (result.processingResult?.verbose.length) {
        const untypedVars = result.processingResult.verbose
          .filter((v) => !(v as { normalizedType?: string }).normalizedType)
          .map((v) => ({
            column: v.column,
            description: v.description,
            level: v.level,
            valueType: v.valueType,
            answerOptions: v.answerOptions,
            parentQuestion: v.parentQuestion,
            context: v.context || '',
          }));

        if (untypedVars.length > 0) {
          fs.writeFileSync(
            path.join(datasetDir, 'untyped-variables.json'),
            JSON.stringify(untypedVars, null, 2)
          );
          console.log(`  Saved untyped-variables.json (${untypedVars.length} variables without normalizedType)`);
        }
      }

      // Save loop variables detail file (for checking in Q)
      const loopReport = buildLoopVariablesReport(result);
      if (loopReport) {
        fs.writeFileSync(
          path.join(datasetDir, 'loop-variables.json'),
          JSON.stringify(loopReport, null, 2)
        );
        console.log(`  Saved loop-variables.json (${loopReport.length} groups)`);
      }

      // Assertions
      let testPassed = true;

      if (!result.canProceed) {
        console.log(`  FAIL: Expected canProceed=true`);
        testPassed = false;
      }

      // Only assert on loops for datasets with known expectations
      if (ds.expectLoops !== null) {
        if (ds.expectLoops && !result.loopDetection?.hasLoops) {
          console.log(`  FAIL: Expected loops but none detected`);
          testPassed = false;
        }

        if (!ds.expectLoops && result.loopDetection?.hasLoops) {
          console.log(`  FAIL: Expected no loops but detected ${result.loopDetection.loops.length}`);
          testPassed = false;
        }
      }

      if (testPassed) {
        console.log(`  PASS`);
        passed++;
      } else {
        failed++;
      }

      datasetResults[ds.slug] = {
        passed: testPassed,
        variables: result.processingResult?.verbose.length ?? 0,
        loops: result.loopDetection?.loops.length ?? 0,
        errors: result.errors.length,
        warnings: result.warnings.length,
        durationMs: result.durationMs,
        loopDetails: loopSummary,
      };
    } catch (err) {
      console.log(`  ERROR: ${err instanceof Error ? err.message : String(err)}`);
      failed++;
      datasetResults[ds.slug] = {
        passed: false,
        variables: 0,
        loops: 0,
        errors: 1,
        warnings: 0,
        durationMs: 0,
      };
    }
  }

  // =========================================================================
  // Summary
  // =========================================================================
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Results: ${passed} passed, ${failed} failed, ${skipped} skipped (${DATASETS.length} total)`);
  console.log('='.repeat(60));

  // Print compact table
  console.log('\n  Dataset                        | Vars  | Loops | Status');
  console.log('  ' + '-'.repeat(65));
  for (const [slug, r] of Object.entries(datasetResults)) {
    const status = r.passed ? 'PASS' : 'FAIL';
    const loopStr = r.loops > 0 ? String(r.loops) : '-';
    console.log(`  ${slug.padEnd(32)} | ${String(r.variables).padStart(5)} | ${loopStr.padStart(5)} | ${status}`);
  }

  // Save run summary
  const summary = {
    timestamp: new Date().toISOString(),
    passed,
    failed,
    skipped,
    total: DATASETS.length,
    datasets: datasetResults,
  };
  fs.writeFileSync(
    path.join(runDir, 'summary.json'),
    JSON.stringify(summary, null, 2)
  );
  console.log(`\nRun saved: outputs/_validation-test/run-${timestamp}/`);

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
