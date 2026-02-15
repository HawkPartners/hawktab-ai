/**
 * Download all pipeline files from R2 for a specific run.
 * Useful for debugging failed cloud runs locally.
 *
 * Usage:
 *   npx tsx scripts/download-run-from-r2.ts <runId>
 *   npx tsx scripts/download-run-from-r2.ts jh74s4prbqf1p9q5edgpkgrpf5817tw1
 *
 * Files are downloaded to: outputs/_downloaded/<runId>/
 */
import '../src/lib/loadEnv';
import { getConvexClient } from '../src/lib/convex';
import { api } from '../convex/_generated/api';
import { downloadFile } from '../src/lib/r2/r2';
import type { Id } from '../convex/_generated/dataModel';
import { promises as fs } from 'fs';
import * as path from 'path';

async function downloadRunFiles(runId: string) {
  const convex = getConvexClient();

  console.log(`[Download] Fetching run: ${runId}`);
  const run = await convex.query(api.runs.get, { runId: runId as Id<'runs'> });

  if (!run) {
    console.error(`[Download] Run not found: ${runId}`);
    process.exit(1);
  }

  const result = run.result as Record<string, unknown> | undefined;
  const r2Files = result?.r2Files as {
    inputs?: Record<string, string>;
    outputs?: Record<string, string>;
  } | undefined;

  if (!r2Files?.outputs) {
    console.error('[Download] No R2 files available for this run');
    process.exit(1);
  }

  const outputFiles = r2Files.outputs;
  const fileCount = Object.keys(outputFiles).length;

  console.log(`[Download] Found ${fileCount} files in R2`);
  console.log('[Download] Files to download:');
  for (const relativePath of Object.keys(outputFiles).sort()) {
    console.log(`  - ${relativePath}`);
  }

  // Create download directory
  const downloadDir = path.join(process.cwd(), 'outputs', '_downloaded', runId);
  await fs.mkdir(downloadDir, { recursive: true });
  console.log(`\n[Download] Downloading to: ${downloadDir}`);

  // Download all files
  let downloaded = 0;
  let failed = 0;

  for (const [relativePath, r2Key] of Object.entries(outputFiles)) {
    const localPath = path.join(downloadDir, relativePath);

    try {
      // Create parent directory
      await fs.mkdir(path.dirname(localPath), { recursive: true });

      // Download file
      const buffer = await downloadFile(r2Key);
      await fs.writeFile(localPath, buffer);

      downloaded++;
      console.log(`  ✓ ${relativePath}`);
    } catch (error) {
      failed++;
      console.error(`  ✗ ${relativePath}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  console.log(`\n[Download] Complete: ${downloaded} downloaded, ${failed} failed`);
  console.log(`[Download] Files saved to: ${downloadDir}`);

  // Show key files
  console.log('\n[Download] Key files to check:');
  const keyFiles = [
    'r/master.R',
    'results/tables.json',
    'pipeline-summary.json',
    'validation/validation-execution.log',
    'errors/errors.ndjson',
  ];

  for (const file of keyFiles) {
    const exists = Object.keys(outputFiles).includes(file);
    console.log(`  ${exists ? '✓' : '✗'} ${file}`);
  }
}

// Main
const runId = process.argv[2];

if (!runId) {
  console.error('Usage: npx tsx scripts/download-run-from-r2.ts <runId>');
  process.exit(1);
}

downloadRunFiles(runId).catch((error) => {
  console.error('[Download] Error:', error);
  process.exit(1);
});
