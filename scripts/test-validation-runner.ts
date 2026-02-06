/**
 * Integration test for ValidationRunner
 *
 * Tests against all dataset files in data/test-data/ plus the primary Leqvio dataset.
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
  dataMapPath: string;
  spssPath: string;
  expectedFormat: 'antares' | 'spss_variable_info' | 'spss_values_only';
  /** Set true/false for known datasets, null for discovery (no assertion). */
  expectLoops: boolean | null;
}

/**
 * Helper to build a standard SPSS Variable Info dataset entry.
 * Convention: directory contains `<Name>__Sheet1.csv` + `<Name>.sav`
 */
function spss(
  name: string,
  slug: string,
  dir: string,
  csvFile: string,
  savFile: string,
  expectLoops: boolean | null = null
): DatasetDef {
  return {
    name,
    slug,
    dataMapPath: `data/test-data/${dir}/${csvFile}`,
    spssPath: `data/test-data/${dir}/${savFile}`,
    expectedFormat: 'spss_variable_info',
    expectLoops,
  };
}

const DATASETS: DatasetDef[] = [
  // === Known / Verified ===
  {
    name: 'Leqvio Monotherapy (Antares, no loops)',
    slug: 'leqvio-monotherapy',
    dataMapPath: 'data/leqvio-monotherapy-demand-NOV217/inputs/leqvio-monotherapy-demand-datamap.csv',
    spssPath: 'data/leqvio-monotherapy-demand-NOV217/inputs/leqvio-monotherapy-demand-data.sav',
    expectedFormat: 'antares',
    expectLoops: false,
  },
  {
    name: "Tito's (Antares, loops)",
    slug: 'titos',
    dataMapPath: 'data/test-data/titos-growth-strategy/original-datamap.csv',
    spssPath: 'data/test-data/titos-growth-strategy/250800.sav',
    expectedFormat: 'antares',
    expectLoops: true,
  },
  spss('Spravato', 'spravato', 'Spravato_4.23.25',
    'Spravato 4.23.25__Sheet1.csv', 'Spravato 4.23.25.sav', false),

  // === SPSS Variable Info Datasets ===
  spss('CAR-T Segmentation', 'cart-segmentation', 'CART-Segmentation-Data_7.22.24_v2',
    'CAR T Segmentation Data 7.22.24 v2__Sheet1.csv', 'CAR T Segmentation Data 7.22.24 v2.sav'),
  spss('Cambridge Savings Bank W1', 'csb-w1', 'Cambridge-Savings-Bank-W1_4.9.24',
    'Cambridge Savings Bank W1_4.9.24__Sheet1.csv', 'Cambridge Savings Bank W1_4.9.24.sav'),
  spss('Cambridge Savings Bank W2', 'csb-w2', 'Cambridge-Savings-Bank-W2_4.1.25',
    'Cambridge Savings Bank W2 4.1.25__Sheet1.csv', 'Cambridge Savings Bank W2 4.1.25.sav'),
  spss('GVHD', 'gvhd', 'GVHD-Data_12.27.22',
    'GVHD Data 12.27.22__Sheet1.csv', 'GVHD Data 12.27.22.sav'),
  spss('Iptacopan', 'iptacopan', 'Iptacopan-Data_2.23.24',
    'Iptacopan Data 2.23.24__Sheet1.csv', 'Iptacopan Data 2.23.24.sav'),
  spss('Leqvio Demand W1', 'leqvio-demand-w1', 'Leqvio-Demand-W1_3.13.23',
    'Leqvio Demand W1 3.13.23__Sheet1.csv', 'Leqvio Demand W1 3.13.23 .sav'),
  spss('Leqvio Demand W2', 'leqvio-demand-w2', 'Leqvio-Demand-W2_8.16.24 v2',
    'Leqvio Demand W2 8.16.24 v2__Sheet1.csv', 'Leqvio Demand W2 8.16.24 v2.sav'),
  spss('Leqvio Demand W3', 'leqvio-demand-w3', 'Leqvio-Demand-W3_5.16.25',
    'Leqvio Demand W3 5.16.25__Sheet1.csv', 'Leqvio Demand W3 5.16.25.sav'),
  spss('Leqvio Segmentation HCP W1', 'leqvio-seg-hcp-w1', 'Leqvio-Segmentation-Data-HCP-W1_7.11.23',
    'Leqvio Segmentation Data HCP W1 7.11.23__Sheet1.csv', 'Leqvio Segmentation Data HCP W1 7.11.23.sav'),
  spss('Leqvio Segmentation HCP W2', 'leqvio-seg-hcp-w2', 'Leqvio-Segmentation-Data-HCP-W2_2.21.2025',
    'Leqvio Segmentation Data HCP W2 2.21.2025__Sheet1.csv', 'Leqvio Segmentation Data HCP W2 2.21.2025.sav'),
  spss('Leqvio Segmentation Patients', 'leqvio-seg-patients', 'Leqvio-Segmentation-Patients-Data_7.7.23',
    'Leqvio Segmentation Patients Data 7.7.23__Sheet1.csv', 'Leqvio Segmentation Patients Data 7.7.23.sav'),
  spss('Meningitis Vax', 'meningitis-vax', 'Meningitis-Vax-Data_10.14.22',
    'Meningitis Vax Data 10.14.22__Sheet1.csv', 'Meningitis Vax Data 10.14.22.sav'),
  spss('Onc CE W2', 'onc-ce-w2', 'Onc-CE-W2-Data_5.10.20',
    'Onc CE W2 Data 5.10.20__Sheet1.csv', 'Onc CE W2 Data 5.10.20.sav'),
  spss('Onc CE W3', 'onc-ce-w3', 'Onc-CE-W3-Data_5.13.21',
    'Onc CE W3 Data 5.13.21__Sheet1.csv', 'Onc CE W3 Data 5.13.21.sav'),
  spss('Onc CE W4', 'onc-ce-w4', 'Onc-CE-W4-Data_3.11.22',
    'Onc CE W4 Data 3.11.22__Sheet1.csv', 'Onc CE W4 Data 3.11.22.sav'),
  spss('Onc CE W5', 'onc-ce-w5', 'Onc-CE-W5-Data_2.7.23',
    'Onc CE W5 Data 2.7.23__Sheet1.csv', 'Onc CE W5 Data 2.7.23.sav'),
  spss('Onc CE W6', 'onc-ce-w6', 'Onc-CE-W6-Data_3.18.24',
    'Onc CE W6 Data 3.18.24__Sheet1.csv', 'Onc CE W6 Data 3.18.24.sav'),
  spss('UCB Caregiver ATU W1', 'ucb-w1', 'UCB-Caregiver-ATU-W1-Data_1.11.23',
    'UCB Caregiver ATU W1 Data 1.11.23__Sheet1.csv', 'UCB Caregiver ATU W1 Data 1.11.23.sav'),
  spss('UCB Caregiver ATU W2', 'ucb-w2', 'UCB-Caregiver-ATU-W2-Data_9.1.23',
    'UCB Caregiver ATU W2 Data 9.1.23__Sheet1.csv', 'UCB Caregiver ATU W2 Data 9.1.23.sav'),
  spss('UCB Caregiver ATU W4', 'ucb-w4', 'UCB-Caregiver-ATU-W4-Data_8.16.24',
    'UCB Caregiver ATU W4 Data 8.16.24__Sheet1.csv', 'UCB Caregiver ATU W4 Data 8.16.24.sav'),
  // These two are SPSS Values Only format (no Variable Information section)
  {
    name: 'UCB Caregiver ATU W5',
    slug: 'ucb-w5',
    dataMapPath: 'data/test-data/UCB-Caregiver-ATU-W5-Data_1.7.25/UCB Caregiver ATU W5 Data 1.7.25__Sheet1.csv',
    spssPath: 'data/test-data/UCB-Caregiver-ATU-W5-Data_1.7.25/UCB Caregiver ATU W5 Data 1.7.25.sav',
    expectedFormat: 'spss_values_only',
    expectLoops: null,
  },
  {
    name: 'UCB Caregiver ATU W6',
    slug: 'ucb-w6',
    dataMapPath: 'data/test-data/UCB-Caregiver-ATU-W6-Data_1.23.24/UCB Caregiver ATU W6 Data 1.23.24__Sheet1.csv',
    spssPath: 'data/test-data/UCB-Caregiver-ATU-W6-Data_1.23.24/UCB Caregiver ATU W6 Data 1.23.24.sav',
    expectedFormat: 'spss_values_only',
    expectLoops: null,
  },
];

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
    format: string;
    variables: number;
    loops: number;
    errors: number;
    warnings: number;
    durationMs: number;
    loopDetails?: string;
  }> = {};

  for (const dataset of DATASETS) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`Testing: ${dataset.name}`);
    console.log('='.repeat(60));

    // Create per-dataset folder
    const datasetDir = path.join(runDir, dataset.slug);
    fs.mkdirSync(datasetDir, { recursive: true });

    const dataMapPath = path.join(process.cwd(), dataset.dataMapPath);
    const spssPath = path.join(process.cwd(), dataset.spssPath);

    // Check if files exist
    if (!fs.existsSync(dataMapPath)) {
      console.log(`  SKIP: DataMap not found at ${dataset.dataMapPath}`);
      skipped++;
      continue;
    }
    const spssExists = fs.existsSync(spssPath);
    if (!spssExists) {
      console.log(`  NOTE: SPSS file not found — R stages will be skipped`);
    }

    try {
      const result = await validate({
        dataMapPath,
        spssPath: spssExists ? spssPath : undefined,
        outputDir: datasetDir,
      });

      // Console report
      console.log(`\n  Format: ${result.format}`);
      console.log(`  Can Proceed: ${result.canProceed}`);
      console.log(`  Duration: ${result.durationMs}ms`);
      console.log(`  Errors: ${result.errors.length}`);
      console.log(`  Warnings: ${result.warnings.length}`);

      if (result.processingResult) {
        console.log(`  Variables: ${result.processingResult.verbose.length}`);
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
        dataset: dataset.name,
        format: result.format,
        canProceed: result.canProceed,
        durationMs: result.durationMs,
        variableCount: result.processingResult?.verbose.length ?? 0,
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

      if (result.format !== dataset.expectedFormat) {
        console.log(`  FAIL: Expected format '${dataset.expectedFormat}', got '${result.format}'`);
        testPassed = false;
      }

      if (!result.canProceed) {
        console.log(`  FAIL: Expected canProceed=true`);
        testPassed = false;
      }

      // Only assert on loops for datasets with known expectations
      if (dataset.expectLoops !== null) {
        if (dataset.expectLoops && !result.loopDetection?.hasLoops) {
          console.log(`  FAIL: Expected loops but none detected`);
          testPassed = false;
        }

        if (!dataset.expectLoops && result.loopDetection?.hasLoops) {
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

      datasetResults[dataset.slug] = {
        passed: testPassed,
        format: result.format,
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
      datasetResults[dataset.slug] = {
        passed: false,
        format: 'error',
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
  console.log('\n  Dataset                        | Format           | Vars  | Loops | Status');
  console.log('  ' + '-'.repeat(85));
  for (const [slug, r] of Object.entries(datasetResults)) {
    const status = r.passed ? 'PASS' : 'FAIL';
    const loopStr = r.loops > 0 ? String(r.loops) : '-';
    console.log(`  ${slug.padEnd(32)} | ${r.format.padEnd(16)} | ${String(r.variables).padStart(5)} | ${loopStr.padStart(5)} | ${status}`);
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
