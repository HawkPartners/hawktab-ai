import '../src/lib/loadEnv';
import { DataMapProcessor } from '../src/lib/processors/DataMapProcessor';

async function testParser(filePath: string, name: string) {
  const processor = new DataMapProcessor();
  console.log(`\n${'='.repeat(60)}`);
  console.log(`TESTING: ${name}`);
  console.log(`${'='.repeat(60)}`);

  try {
    const result = await processor.processDataMap(filePath);

    if (!result.success) {
      console.log(`FAILED: ${result.errors.join(', ')}`);
      return;
    }

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

  } catch (error) {
    console.log(`ERROR: ${error instanceof Error ? error.message : error}`);
  }
}

async function main() {
  // Test Leqvio
  await testParser(
    'data/leqvio-monotherapy-demand-NOV217/inputs/leqvio-monotherapy-demand-datamap.csv',
    'Leqvio Monotherapy Demand'
  );

  // Test Titos
  await testParser(
    'data/test-data/titos-growth-strategy/original-datamap.csv',
    'Titos Growth Strategy'
  );

  // Test SPSS format (expect failure or poor results)
  await testParser(
    'data/test-data/Spravato_4.23.25/Spravato 4.23.25__Sheet1.csv',
    'Spravato (SPSS format)'
  );
}

main();
