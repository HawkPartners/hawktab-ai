/**
 * Integration test for ValidationRunner
 *
 * Tests against real dataset files:
 * - Leqvio (Antares, no loops)
 * - Tito's (Antares, loops)
 * - Spravato (SPSS Variable Info)
 *
 * Output structure:
 *   outputs/_validation-test/
 *     run-<timestamp>/
 *       leqvio/
 *         validation-report.json
 *         loop-variables.json   (if loops detected)
 *       titos/
 *         validation-report.json
 *         loop-variables.json
 *       spravato/
 *         validation-report.json
 *       summary.json
 *
 * Usage: npx tsx scripts/test-validation-runner.ts
 */

import '../src/lib/loadEnv';
import path from 'path';
import fs from 'fs';
import { validate } from '../src/lib/validation/ValidationRunner';
import type { ValidationReport } from '../src/lib/validation/types';

const DATASETS = [
  {
    name: 'Leqvio (Antares, no loops)',
    slug: 'leqvio',
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
  {
    name: 'Spravato (SPSS Variable Info)',
    slug: 'spravato',
    dataMapPath: 'data/test-data/Spravato_4.23.25/Spravato 4.23.25__Sheet1.csv',
    spssPath: 'data/test-data/Spravato_4.23.25/Spravato 4.23.25.sav',
    expectedFormat: 'spss_variable_info',
    expectLoops: false,
  },
];

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

async function main() {
  // Create timestamped run folder
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const runDir = path.join(process.cwd(), 'outputs', '_validation-test', `run-${timestamp}`);
  fs.mkdirSync(runDir, { recursive: true });

  console.log(`Output: outputs/_validation-test/run-${timestamp}/`);

  let passed = 0;
  let failed = 0;
  const datasetResults: Record<string, { passed: boolean; format: string; variables: number; loops: number; errors: number; warnings: number; durationMs: number }> = {};

  for (const dataset of DATASETS) {
    console.log(`\n${'='.repeat(60)}`);
    console.log(`Testing: ${dataset.name}`);
    console.log('='.repeat(60));

    // Create per-dataset folder
    const datasetDir = path.join(runDir, dataset.slug);
    fs.mkdirSync(datasetDir, { recursive: true });

    const dataMapPath = path.join(process.cwd(), dataset.dataMapPath);
    const spssPath = dataset.spssPath
      ? path.join(process.cwd(), dataset.spssPath)
      : undefined;

    // Check if files exist
    if (!fs.existsSync(dataMapPath)) {
      console.log(`  SKIP: DataMap not found at ${dataset.dataMapPath}`);
      continue;
    }
    if (spssPath && !fs.existsSync(spssPath)) {
      console.log(`  NOTE: SPSS file not found — R stages will be skipped`);
    }

    try {
      const result = await validate({
        dataMapPath,
        spssPath,
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

      if (result.loopDetection?.hasLoops) {
        console.log(`  Loops: ${result.loopDetection.loops.length}`);
        for (const loop of result.loopDetection.loops) {
          console.log(`    - ${loop.skeleton}: ${loop.iterations.length} iters x ${loop.diversity} bases (${loop.variables.length} vars)`);
        }
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

      if (dataset.expectLoops && !result.loopDetection?.hasLoops) {
        console.log(`  FAIL: Expected loops but none detected`);
        testPassed = false;
      }

      if (!dataset.expectLoops && result.loopDetection?.hasLoops) {
        console.log(`  FAIL: Expected no loops but detected ${result.loopDetection.loops.length}`);
        testPassed = false;
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

  console.log(`\n${'='.repeat(60)}`);
  console.log(`Results: ${passed} passed, ${failed} failed`);
  console.log('='.repeat(60));

  // Save run summary
  const summary = {
    timestamp: new Date().toISOString(),
    passed,
    failed,
    datasets: datasetResults,
  };
  fs.writeFileSync(
    path.join(runDir, 'summary.json'),
    JSON.stringify(summary, null, 2)
  );
  console.log(`Run saved: outputs/_validation-test/run-${timestamp}/`);

  process.exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
