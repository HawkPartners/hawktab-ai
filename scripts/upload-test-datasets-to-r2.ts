#!/usr/bin/env npx tsx
/**
 * Upload Test Datasets to R2
 *
 * Scans data/ for ready datasets (same heuristics as batch-pipeline.ts)
 * and uploads them to R2 under the `dev-test/` prefix, plus a manifest.json.
 *
 * Usage:
 *   npx tsx scripts/upload-test-datasets-to-r2.ts [--dry-run]
 */

import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { uploadFile } from '../src/lib/r2/r2';
import type { TestDatasetManifest, TestDatasetEntry, TestDatasetFile } from '../src/lib/loadTest/types';
import { getContentTypeForFile } from '../src/lib/loadTest/helpers';

// ---------------------------------------------------------------------------
// File Detection (mirrors batch-pipeline.ts checkFolder)
// ---------------------------------------------------------------------------

interface DatasetReadiness {
  folder: string;
  name: string;
  hasSav: boolean;
  hasBanner: boolean;
  hasSurvey: boolean;
  ready: boolean;
  savFile?: string;
  bannerFile?: string;
  surveyFile?: string;
  inputsFolder: string;
}

async function checkFolder(folderPath: string): Promise<DatasetReadiness> {
  const name = path.basename(folderPath);
  const result: DatasetReadiness = {
    folder: folderPath,
    name,
    hasSav: false,
    hasBanner: false,
    hasSurvey: false,
    ready: false,
    inputsFolder: folderPath,
  };

  try {
    let inputsFolder = folderPath;
    const contents = await fs.readdir(folderPath);
    if (contents.includes('inputs')) {
      inputsFolder = path.join(folderPath, 'inputs');
    }
    result.inputsFolder = inputsFolder;

    const files = await fs.readdir(inputsFolder);

    // .sav
    const savFile = files.find(f => f.endsWith('.sav'));
    if (savFile) {
      result.hasSav = true;
      result.savFile = savFile;
    }

    // Banner
    const bannerFile = files.find(f => {
      const lower = f.toLowerCase();
      return lower.includes('banner') &&
        (f.endsWith('.docx') || f.endsWith('.pdf')) &&
        !f.startsWith('~$');
    });
    if (bannerFile) {
      result.hasBanner = true;
      result.bannerFile = bannerFile;
    }

    // Survey
    const surveyFile = files.find(f => {
      const lower = f.toLowerCase();
      return (lower.includes('survey') || lower.includes('questionnaire') || lower.includes('qre') || lower.includes('qnr')) &&
        (f.endsWith('.docx') || f.endsWith('.pdf')) &&
        !f.startsWith('~$');
    });
    if (surveyFile) {
      result.hasSurvey = true;
      result.surveyFile = surveyFile;
    }

    result.ready = result.hasSav && result.hasSurvey;
  } catch {
    // Folder not readable
  }

  return result;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const dataDir = path.join(process.cwd(), 'data');

  const entries = await fs.readdir(dataDir, { withFileTypes: true });
  const folders = entries
    .filter(e => e.isDirectory())
    .map(e => path.join(dataDir, e.name))
    .sort();

  console.log(`\nScanning ${folders.length} folders in data/...\n`);

  const checks: DatasetReadiness[] = [];
  for (const folder of folders) {
    const check = await checkFolder(folder);
    checks.push(check);
  }

  const ready = checks.filter(r => r.ready);
  const notReady = checks.filter(r => !r.ready);

  console.log(`READY (${ready.length}):`);
  for (const r of ready) {
    console.log(`  ${r.name}`);
    console.log(`    .sav:    ${r.savFile}`);
    console.log(`    banner:  ${r.hasBanner ? r.bannerFile : '(none — will auto-generate)'}`);
    console.log(`    survey:  ${r.surveyFile}`);
  }

  if (notReady.length > 0) {
    console.log(`\nNOT READY (${notReady.length}):`);
    for (const r of notReady) {
      const missing = [
        !r.hasSav ? '.sav' : '',
        !r.hasSurvey ? 'survey' : '',
      ].filter(Boolean);
      console.log(`  ${r.name} — missing: ${missing.join(', ')}`);
    }
  }

  if (dryRun) {
    console.log(`\n--dry-run: ${ready.length} datasets would be uploaded to R2.`);
    return;
  }

  if (ready.length === 0) {
    console.log('\nNo datasets ready to upload.');
    return;
  }

  // Upload each dataset
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Uploading ${ready.length} datasets to R2 (dev-test/)...`);
  console.log(`${'='.repeat(60)}\n`);

  const manifest: TestDatasetManifest = {
    version: 1,
    generatedAt: new Date().toISOString(),
    datasets: [],
  };

  let totalFiles = 0;
  let totalBytes = 0;

  for (const dataset of ready) {
    console.log(`[${dataset.name}] Uploading...`);
    const datasetFiles: TestDatasetFile[] = [];

    // Build list of files to upload
    const filesToUpload: { filename: string; role: 'sav' | 'survey' | 'banner' }[] = [];
    if (dataset.savFile) filesToUpload.push({ filename: dataset.savFile, role: 'sav' });
    if (dataset.surveyFile) filesToUpload.push({ filename: dataset.surveyFile, role: 'survey' });
    if (dataset.bannerFile) filesToUpload.push({ filename: dataset.bannerFile, role: 'banner' });

    for (const file of filesToUpload) {
      const localPath = path.join(dataset.inputsFolder, file.filename);
      const buffer = await fs.readFile(localPath);
      const r2Key = `dev-test/${dataset.name}/${file.filename}`;
      const contentType = getContentTypeForFile(file.filename);

      await uploadFile(r2Key, buffer, contentType);

      datasetFiles.push({
        filename: file.filename,
        role: file.role,
        r2Key,
        sizeBytes: buffer.length,
      });

      totalFiles++;
      totalBytes += buffer.length;
      console.log(`  ${file.role.padEnd(7)} ${file.filename} (${(buffer.length / 1024 / 1024).toFixed(1)} MB) → ${r2Key}`);
    }

    const entry: TestDatasetEntry = {
      name: dataset.name,
      files: datasetFiles,
      ready: true,
      hasBanner: dataset.hasBanner,
    };
    manifest.datasets.push(entry);
  }

  // Upload manifest
  const manifestJson = JSON.stringify(manifest, null, 2);
  await uploadFile('dev-test/manifest.json', manifestJson, 'application/json');
  console.log(`\nManifest uploaded: dev-test/manifest.json`);

  // Summary
  console.log(`\n${'='.repeat(60)}`);
  console.log(`UPLOAD COMPLETE`);
  console.log(`  Datasets: ${manifest.datasets.length}`);
  console.log(`  Files:    ${totalFiles}`);
  console.log(`  Total:    ${(totalBytes / 1024 / 1024).toFixed(1)} MB`);
  console.log(`${'='.repeat(60)}\n`);
}

main().catch((error) => {
  console.error(`\nUpload error: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
