/**
 * Quick test script to verify the SurveyProcessor table conversion + color semantics.
 * Converts the CART survey and reports key metrics.
 */
import '../src/lib/loadEnv';
import { processSurvey } from '../src/lib/processors/SurveyProcessor';
import * as path from 'path';
import * as fs from 'fs/promises';
import * as os from 'os';

async function main() {
  const datasetDir = process.argv[2] || 'data/CART-Segmentation-Data_7.22.24_v2';

  // Find DOCX survey file
  const files = await fs.readdir(datasetDir);
  const surveyFile = files.find(f =>
    f.endsWith('.docx') &&
    !f.startsWith('~$') &&
    !f.toLowerCase().includes('banner')
  );

  if (!surveyFile) {
    console.error('No survey DOCX found in', datasetDir);
    process.exit(1);
  }

  const docxPath = path.resolve(datasetDir, surveyFile);
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'survey-test-'));

  console.log(`\nProcessing: ${surveyFile}`);
  console.log(`Temp dir: ${tmpDir}\n`);

  const result = await processSurvey(docxPath, tmpDir);

  if (result.warnings.length > 0) {
    console.log('Warnings:', result.warnings);
  }

  const md = result.markdown;

  // Count metrics
  const htmlTableCount = (md.match(/<table/gi) || []).length;
  const mdTableCount = (md.match(/^\|.*\|$/gm) || []).length;
  const progCount = (md.match(/\{\{PROG:/g) || []).length;
  const termCount = (md.match(/\{\{TERM:/g) || []).length;
  const strikeCount = (md.match(/~~/g) || []).length / 2; // pairs

  console.log('\n===== RESULTS =====');
  console.log(`Total characters:     ${md.length.toLocaleString()}`);
  console.log(`Remaining HTML <table> tags: ${htmlTableCount} (should be 0)`);
  console.log(`Markdown table rows:  ${mdTableCount}`);
  console.log(`{{PROG: ...}} markers: ${progCount}`);
  console.log(`{{TERM: ...}} markers: ${termCount}`);
  console.log(`Strikethrough pairs:  ${strikeCount}`);

  // Write output for inspection
  const outPath = path.join(tmpDir, 'survey-output.md');
  await fs.writeFile(outPath, md);
  console.log(`\nFull output written to: ${outPath}`);

  // Show a sample of PROG markers
  const progSamples = md.match(/\{\{PROG: [^}]+\}\}/g)?.slice(0, 5) || [];
  if (progSamples.length > 0) {
    console.log('\nSample PROG markers:');
    for (const s of progSamples) {
      console.log(`  ${s.substring(0, 120)}${s.length > 120 ? '...' : ''}`);
    }
  }

  // Show a sample of TERM markers
  const termSamples = md.match(/\{\{TERM: [^}]+\}\}/g)?.slice(0, 5) || [];
  if (termSamples.length > 0) {
    console.log('\nSample TERM markers:');
    for (const s of termSamples) {
      console.log(`  ${s.substring(0, 120)}${s.length > 120 ? '...' : ''}`);
    }
  }

  // Show a sample markdown table
  const tableLines = md.split('\n').filter(l => l.startsWith('|'));
  if (tableLines.length > 0) {
    console.log('\nSample markdown table (first 5 rows):');
    for (const l of tableLines.slice(0, 5)) {
      console.log(`  ${l.substring(0, 150)}`);
    }
  }

  // Cleanup
  await fs.rm(tmpDir, { recursive: true, force: true }).catch(() => {});
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
