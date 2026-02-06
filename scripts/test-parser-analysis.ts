import '../src/lib/loadEnv';
import path from 'path';
import fs from 'fs/promises';
import { validate } from '../src/lib/validation/ValidationRunner';

async function testParser(spssPath: string, name: string) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`TESTING: ${name}`);
  console.log(`${'='.repeat(60)}`);

  // Create a temp output dir for validation
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputDir = path.join(process.cwd(), 'temp-outputs', `parser-analysis-${timestamp}`);
  await fs.mkdir(outputDir, { recursive: true });

  try {
    const report = await validate({ spssPath, outputDir });

    if (!report.canProceed || !report.processingResult) {
      console.log(`FAILED: ${report.errors.map(e => e.message).join(', ')}`);
      return;
    }

    const result = report.processingResult;

    // Analyze what was extracted
    const verbose = result.verbose;
    const parents = verbose.filter(v => v.level === 'parent');
    const subs = verbose.filter(v => v.level === 'sub');

    console.log(`\nExtraction Summary:`);
    console.log(`  Total variables: ${verbose.length}`);
    console.log(`  Parent questions: ${parents.length}`);
    console.log(`  Sub-variables: ${subs.length}`);
    console.log(`  Confidence: ${result.confidence.toFixed(2)}`);

    // Check for answer options
    const withOptions = verbose.filter(v => v.answerOptions && v.answerOptions !== 'NA');
    const withContext = verbose.filter(v => v.context);
    const withNormalizedType = verbose.filter(v => v.normalizedType);

    console.log(`\nRichness Analysis:`);
    console.log(`  With answer options: ${withOptions.length}`);
    console.log(`  With context: ${withContext.length}`);
    console.log(`  With normalized type: ${withNormalizedType.length}`);

    // Sample what answer options look like
    console.log(`\nSample Answer Options (first 3):`);
    for (const v of withOptions.slice(0, 3)) {
      const opts = v.answerOptions?.substring(0, 60) || '';
      console.log(`  ${v.column}: ${opts}...`);
    }

    // Check for potential gaps
    console.log(`\nPotential Gaps:`);
    const noDesc = verbose.filter(v => !v.description || v.description.length < 10);
    const noType = verbose.filter(v => !v.normalizedType);
    const subsNoContext = subs.filter(v => !v.context);

    console.log(`  Vars with short/no description: ${noDesc.length}`);
    console.log(`  Vars with no normalizedType: ${noType.length}`);
    console.log(`  Sub-vars missing context: ${subsNoContext.length} of ${subs.length}`);

    // Show a few vars missing context
    if (subsNoContext.length > 0) {
      console.log(`  Sample missing context: ${subsNoContext.slice(0, 3).map(v => v.column).join(', ')}`);
    }

    // Loop detection summary
    if (report.loopDetection?.hasLoops) {
      console.log(`\nLoop Detection:`);
      console.log(`  Loops found: ${report.loopDetection.loops.length}`);
      for (const loop of report.loopDetection.loops) {
        console.log(`  Pattern: ${loop.skeleton}, ${loop.iterations.length} iterations`);
      }
    }

  } catch (error) {
    console.log(`ERROR: ${error instanceof Error ? error.message : error}`);
  }
}

async function main() {
  // Test Leqvio
  await testParser(
    'data/leqvio-monotherapy-demand-NOV217/inputs/leqvio-monotherapy-demand-data.sav',
    'Leqvio Monotherapy Demand'
  );

  // Test Titos
  await testParser(
    'data/test-data/titos-growth-strategy/250800.sav',
    'Titos Growth Strategy'
  );

  // Test Spravato
  await testParser(
    'data/test-data/Spravato_4.23.25/Spravato 4.23.25.sav',
    'Spravato'
  );
}

main();
