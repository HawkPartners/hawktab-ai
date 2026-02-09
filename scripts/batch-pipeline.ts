#!/usr/bin/env npx tsx
/**
 * Batch Pipeline Runner
 *
 * Scans data/ for dataset folders that have all three required files:
 *   1. .sav data file
 *   2. Banner plan (.docx or .pdf containing "banner")
 *   3. Survey document (.docx or .pdf containing "survey" or "questionnaire")
 *
 * Runs the pipeline on each qualifying folder sequentially.
 * Skips folders missing any of the three.
 *
 * Usage:
 *   npx tsx scripts/batch-pipeline.ts [options]
 *
 * Options:
 *   --format=joe|antares     Excel format (default: joe)
 *   --display=frequency|counts|both   Display mode (default: frequency)
 *   --stop-after-verification   Stop before R/Excel generation
 *   --concurrency=N            Parallel agent limit (default: 3)
 *   --dry-run                  Just show which folders qualify, don't run
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { runPipeline } from '../src/lib/pipeline/PipelineRunner';
import type { ExcelFormat, DisplayMode } from '../src/lib/excel/ExcelFormatter';

// =============================================================================
// File Detection (mirrors FileDiscovery.ts logic)
// =============================================================================

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
  };

  try {
    // Check for inputs/ subfolder
    let inputsFolder = folderPath;
    const contents = await fs.readdir(folderPath);
    if (contents.includes('inputs')) {
      inputsFolder = path.join(folderPath, 'inputs');
    }

    const files = await fs.readdir(inputsFolder);

    // Check for .sav
    const savFile = files.find(f => f.endsWith('.sav'));
    if (savFile) {
      result.hasSav = true;
      result.savFile = savFile;
    }

    // Check for banner plan
    const bannerFile = files.find(f =>
      f.toLowerCase().includes('banner') &&
      (f.endsWith('.docx') || f.endsWith('.pdf')) &&
      !f.startsWith('~$')
    );
    if (bannerFile) {
      result.hasBanner = true;
      result.bannerFile = bannerFile;
    }

    // Check for survey
    let surveyFile = files.find(f =>
      (f.toLowerCase().includes('survey') || f.toLowerCase().includes('questionnaire')) &&
      (f.endsWith('.docx') || f.endsWith('.pdf')) &&
      !f.startsWith('~$')
    );
    if (surveyFile) {
      result.hasSurvey = true;
      result.surveyFile = surveyFile;
    }

    result.ready = result.hasSav && result.hasBanner && result.hasSurvey;
  } catch {
    // Folder not readable, skip
  }

  return result;
}

// =============================================================================
// CLI Argument Parsing
// =============================================================================

function parseFormatFlag(): ExcelFormat {
  const arg = process.argv.find(a => a.startsWith('--format='));
  if (arg) {
    const value = arg.split('=')[1]?.toLowerCase();
    if (value === 'antares') return 'antares';
  }
  return 'joe';
}

function parseDisplayFlag(): DisplayMode {
  const arg = process.argv.find(a => a.startsWith('--display='));
  if (arg) {
    const value = arg.split('=')[1]?.toLowerCase();
    if (value === 'counts') return 'counts';
    if (value === 'both') return 'both';
  }
  return 'frequency';
}

function parseConcurrency(): number {
  const arg = process.argv.find(a => a.startsWith('--concurrency='));
  if (arg) {
    const value = parseInt(arg.split('=')[1], 10);
    if (!isNaN(value) && value > 0) return value;
  }
  return 3;
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const dataDir = path.join(process.cwd(), 'data');

  // Scan all subdirectories in data/
  const entries = await fs.readdir(dataDir, { withFileTypes: true });
  const folders = entries
    .filter(e => e.isDirectory())
    .map(e => path.join(dataDir, e.name))
    .sort();

  console.log(`\nScanning ${folders.length} folders in data/...\n`);

  // Check each folder
  const results: DatasetReadiness[] = [];
  for (const folder of folders) {
    const check = await checkFolder(folder);
    results.push(check);
  }

  // Report
  const ready = results.filter(r => r.ready);
  const notReady = results.filter(r => !r.ready);

  console.log(`READY (${ready.length}):`);
  for (const r of ready) {
    console.log(`  ${r.name}`);
    console.log(`    .sav:    ${r.savFile}`);
    console.log(`    banner:  ${r.bannerFile}`);
    console.log(`    survey:  ${r.surveyFile}`);
  }

  if (notReady.length > 0) {
    console.log(`\nSKIPPED (${notReady.length}):`);
    for (const r of notReady) {
      const missing = [
        !r.hasSav ? '.sav' : '',
        !r.hasBanner ? 'banner' : '',
        !r.hasSurvey ? 'survey' : '',
      ].filter(Boolean).join(', ');
      console.log(`  ${r.name} — missing: ${missing}`);
    }
  }

  if (dryRun) {
    console.log(`\n--dry-run: ${ready.length} datasets would run. Exiting.`);
    return;
  }

  if (ready.length === 0) {
    console.log('\nNo datasets ready to run. Add banner plans and surveys to data/ folders.');
    return;
  }

  // Run pipeline on each ready dataset sequentially
  const format = parseFormatFlag();
  const displayMode = parseDisplayFlag();
  const stopAfterVerification = process.argv.includes('--stop-after-verification');
  const concurrency = parseConcurrency();

  console.log(`\n${'='.repeat(60)}`);
  console.log(`BATCH RUN: ${ready.length} datasets`);
  console.log(`  format: ${format} | display: ${displayMode} | concurrency: ${concurrency}`);
  if (stopAfterVerification) console.log(`  stopping after verification (no R/Excel)`);
  console.log(`${'='.repeat(60)}\n`);

  const summary: { name: string; success: boolean; error?: string; durationMs: number }[] = [];

  for (let i = 0; i < ready.length; i++) {
    const dataset = ready[i];
    const startTime = Date.now();

    console.log(`\n${'─'.repeat(60)}`);
    console.log(`[${i + 1}/${ready.length}] ${dataset.name}`);
    console.log(`${'─'.repeat(60)}\n`);

    try {
      const result = await runPipeline(dataset.folder, {
        format,
        displayMode,
        stopAfterVerification,
        concurrency,
      });

      const durationMs = Date.now() - startTime;
      summary.push({
        name: dataset.name,
        success: result.success,
        error: result.error,
        durationMs,
      });

      if (result.success) {
        console.log(`\n[${dataset.name}] Completed in ${(durationMs / 1000 / 60).toFixed(1)} minutes`);
      } else {
        console.error(`\n[${dataset.name}] Failed: ${result.error}`);
      }
    } catch (err) {
      const durationMs = Date.now() - startTime;
      const errorMsg = err instanceof Error ? err.message : String(err);
      summary.push({
        name: dataset.name,
        success: false,
        error: errorMsg,
        durationMs,
      });
      console.error(`\n[${dataset.name}] Crashed: ${errorMsg}`);
    }
  }

  // Final summary
  console.log(`\n${'='.repeat(60)}`);
  console.log('BATCH SUMMARY');
  console.log(`${'='.repeat(60)}`);

  const succeeded = summary.filter(s => s.success);
  const failed = summary.filter(s => !s.success);
  const totalMs = summary.reduce((sum, s) => sum + s.durationMs, 0);

  for (const s of summary) {
    const status = s.success ? 'OK' : 'FAIL';
    const duration = (s.durationMs / 1000 / 60).toFixed(1);
    const error = s.error ? ` — ${s.error.substring(0, 80)}` : '';
    console.log(`  [${status}] ${s.name} (${duration}m)${error}`);
  }

  console.log(`\n  ${succeeded.length} succeeded, ${failed.length} failed`);
  console.log(`  Total time: ${(totalMs / 1000 / 60).toFixed(1)} minutes`);
  console.log('');
}

main().catch((error) => {
  console.error(`\nBatch runner error: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
