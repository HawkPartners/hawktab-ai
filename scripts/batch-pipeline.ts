#!/usr/bin/env npx tsx
/**
 * Batch Pipeline Runner
 *
 * Scans data/ for dataset folders that have the required files:
 *   1. .sav data file (required)
 *   2. Survey document (.docx or .pdf containing "survey", "questionnaire", "qre", or "qnr") (required)
 *   3. Banner plan (.docx or .pdf containing "banner") (optional — AI generates cuts when missing)
 *
 * Runs the pipeline on each qualifying folder sequentially.
 * Skips folders missing .sav or survey.
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
 *   --weight=VAR               Apply weight variable (e.g., --weight=wt)
 *   --no-weight                Suppress weight detection warnings
 *   --loop-stat-testing=MODE   Loop within-group stats (suppress|complement)
 *   --timeout=N                Per-dataset timeout in minutes (default: 95)
 *   --fail-fast=N              Abort after N consecutive same-class failures (default: 3)
 *   --resume                   Skip datasets with existing pipeline-summary.json
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { runPipeline } from '../src/lib/pipeline/PipelineRunner';
import type { ExcelFormat, DisplayMode } from '../src/lib/excel/ExcelFormatter';

// =============================================================================
// Types
// =============================================================================

interface RunResult {
  name: string;
  success: boolean;
  error?: string;
  durationMs: number;
  outputDir?: string;
  tableCount?: number;
  totalCostUsd?: number;
  skipped?: boolean;
  skipReason?: string;
}

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

    // Check for banner plan ("banner plan" or "banner")
    const bannerFile = files.find(f => {
      const lower = f.toLowerCase();
      return (lower.includes('banner')) &&
        (f.endsWith('.docx') || f.endsWith('.pdf')) &&
        !f.startsWith('~$');
    });
    if (bannerFile) {
      result.hasBanner = true;
      result.bannerFile = bannerFile;
    }

    // Check for survey ("survey", "questionnaire", "qre", or "qnr")
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

function parseThemeFlag(): string {
  const arg = process.argv.find(a => a.startsWith('--theme='));
  if (arg) {
    return arg.split('=')[1]?.toLowerCase() || 'classic';
  }
  return 'classic';
}

function parseWeightFlag(): string | undefined {
  const arg = process.argv.find(a => a.startsWith('--weight='));
  if (arg) {
    return arg.split('=').slice(1).join('=');
  }
  return undefined;
}

function parseLoopStatTestingMode(): 'suppress' | 'complement' | undefined {
  const arg = process.argv.find(a => a.startsWith('--loop-stat-testing='));
  if (arg) {
    const value = arg.split('=')[1]?.toLowerCase();
    if (value === 'suppress' || value === 'complement') {
      return value;
    }
    console.warn(`Unknown --loop-stat-testing "${value}". Valid: suppress, complement`);
  }
  return undefined;
}

function parseTimeoutFlag(): number {
  const arg = process.argv.find(a => a.startsWith('--timeout='));
  if (arg) {
    const value = parseInt(arg.split('=')[1], 10);
    if (!isNaN(value) && value > 0) return value;
    console.warn(`Invalid --timeout value. Using default 95 minutes.`);
  }
  return 95;
}

function parseFailFastThreshold(): number {
  const arg = process.argv.find(a => a.startsWith('--fail-fast='));
  if (arg) {
    const value = parseInt(arg.split('=')[1], 10);
    if (!isNaN(value) && value > 0) return value;
    console.warn(`Invalid --fail-fast value. Using default 3.`);
  }
  return 3;
}

function hasResumeFlag(): boolean {
  return process.argv.includes('--resume');
}

// =============================================================================
// Fail-Fast Tracker
// =============================================================================

type BatchErrorClass = 'rate_limit' | 'timeout' | 'circuit_breaker' | 'policy' | 'transient' | 'health_check' | 'unknown';

interface FailFastTracker {
  consecutiveCount: number;
  lastClassification: BatchErrorClass | null;
  threshold: number;
}

function createFailFastTracker(threshold: number): FailFastTracker {
  return { consecutiveCount: 0, lastClassification: null, threshold };
}

function classifyBatchError(errorMsg: string): BatchErrorClass {
  const lower = errorMsg.toLowerCase();
  if (lower.includes('rate limit') || lower.includes('429') || lower.includes('quota')) return 'rate_limit';
  if (lower.includes('timeout') || lower.includes('timed out') || lower.includes('aborted')) return 'timeout';
  if (lower.includes('circuit breaker') || lower.includes('circuit_breaker')) return 'circuit_breaker';
  if (lower.includes('content policy') || lower.includes('content_filter') || lower.includes('content management')) return 'policy';
  if (lower.includes('health check') || lower.includes('healthcheck') || lower.includes('deployment') && lower.includes('unavailable')) return 'health_check';
  if (lower.includes('econnreset') || lower.includes('econnrefused') || lower.includes('socket') || lower.includes('network')) return 'transient';
  return 'unknown';
}

function recordFailFastSuccess(tracker: FailFastTracker): void {
  tracker.consecutiveCount = 0;
  tracker.lastClassification = null;
}

/** Returns true if the batch should abort */
function recordFailFastFailure(tracker: FailFastTracker, errorMsg: string): boolean {
  const classification = classifyBatchError(errorMsg);
  if (classification === tracker.lastClassification) {
    tracker.consecutiveCount++;
  } else {
    tracker.consecutiveCount = 1;
    tracker.lastClassification = classification;
  }
  return tracker.consecutiveCount >= tracker.threshold;
}

// =============================================================================
// Resume Check
// =============================================================================

async function checkResume(datasetName: string): Promise<{ outputDir: string } | null> {
  const outputsDir = path.join(process.cwd(), 'outputs', datasetName);
  try {
    const entries = await fs.readdir(outputsDir, { withFileTypes: true });
    // Sort descending to check most recent pipeline run first
    const pipelineDirs = entries
      .filter(e => e.isDirectory() && e.name.startsWith('pipeline-'))
      .map(e => e.name)
      .sort()
      .reverse();

    for (const dir of pipelineDirs) {
      const summaryPath = path.join(outputsDir, dir, 'pipeline-summary.json');
      try {
        const raw = await fs.readFile(summaryPath, 'utf-8');
        const parsed = JSON.parse(raw);
        // Validate it has essential fields (not truncated)
        if (parsed.dataset && parsed.timestamp) {
          return { outputDir: path.join(outputsDir, dir) };
        }
      } catch {
        // Truncated or invalid JSON — try next
      }
    }
  } catch {
    // outputs/<name> doesn't exist yet
  }
  return null;
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
    console.log(`    banner:  ${r.hasBanner ? r.bannerFile : '(will generate from datamap)'}`);
    console.log(`    survey:  ${r.surveyFile}`);
  }

  if (notReady.length > 0) {
    console.log(`\nNOT READY (${notReady.length}):`);
    for (const r of notReady) {
      const missing = [
        !r.hasSav ? '.sav' : '',
        !r.hasBanner ? 'banner' : '',
        !r.hasSurvey ? 'survey' : '',
      ].filter(Boolean);
      const has = [
        r.hasSav ? `.sav (${r.savFile})` : '',
        r.hasBanner ? `banner (${r.bannerFile})` : '',
        r.hasSurvey ? `survey (${r.surveyFile})` : '',
      ].filter(Boolean);
      console.log(`  ${r.name}`);
      if (has.length > 0) console.log(`    has:     ${has.join(', ')}`);
      console.log(`    missing: ${missing.join(', ')}`);
    }
  }

  if (dryRun) {
    const timeoutMin = parseTimeoutFlag();
    const ffThreshold = parseFailFastThreshold();
    const resumeFlag = hasResumeFlag();
    console.log(`\n--dry-run: ${ready.length} datasets would run.`);
    console.log(`  timeout: ${timeoutMin}m | fail-fast: ${ffThreshold} | resume: ${resumeFlag}`);
    return;
  }

  if (ready.length === 0) {
    console.log('\nNo datasets ready to run. Add banner plans and surveys to data/ folders.');
    return;
  }

  // Run pipeline on each ready dataset sequentially
  const format = parseFormatFlag();
  const displayMode = parseDisplayFlag();
  const separateWorkbooks = process.argv.includes('--separate-workbooks');
  const stopAfterVerification = process.argv.includes('--stop-after-verification');
  const concurrency = parseConcurrency();
  const theme = parseThemeFlag();
  const weightVariable = parseWeightFlag();
  const noWeight = process.argv.includes('--no-weight');
  const loopStatTestingMode = parseLoopStatTestingMode();
  const timeoutMinutes = parseTimeoutFlag();
  const failFastThreshold = parseFailFastThreshold();
  const resume = hasResumeFlag();

  console.log(`\n${'='.repeat(60)}`);
  console.log(`BATCH RUN: ${ready.length} datasets`);
  console.log(`  format: ${format} | display: ${displayMode} | concurrency: ${concurrency}`);
  console.log(`  timeout: ${timeoutMinutes}m per dataset | fail-fast: ${failFastThreshold} consecutive`);
  if (resume) console.log(`  resume: skipping datasets with existing pipeline-summary.json`);
  if (stopAfterVerification) console.log(`  stopping after verification (no R/Excel)`);
  console.log(`${'='.repeat(60)}\n`);

  // ---------------------------------------------------------------------------
  // Graceful shutdown (SIGINT / SIGTERM)
  // ---------------------------------------------------------------------------
  let shuttingDown = false;
  let sigintCount = 0;
  let currentDatasetAbortController: AbortController | null = null;

  const signalHandler = (signal: string) => {
    sigintCount++;
    if (sigintCount === 1) {
      console.log(`\n[batch] Received ${signal} — finishing current dataset then stopping...`);
      shuttingDown = true;
      // Abort the currently running pipeline
      if (currentDatasetAbortController) {
        currentDatasetAbortController.abort();
      }
    } else {
      console.log(`\n[batch] Received second ${signal} — force exiting.`);
      process.exit(1);
    }
  };

  process.on('SIGINT', () => signalHandler('SIGINT'));
  process.on('SIGTERM', () => signalHandler('SIGTERM'));

  // ---------------------------------------------------------------------------
  // Main loop
  // ---------------------------------------------------------------------------
  const summary: RunResult[] = [];
  const failFast = createFailFastTracker(failFastThreshold);
  let terminationReason: string | undefined;

  for (let i = 0; i < ready.length; i++) {
    const dataset = ready[i];

    // Check for graceful shutdown
    if (shuttingDown) {
      terminationReason = 'User interrupted (SIGINT/SIGTERM)';
      console.log(`\n[batch] Shutdown requested — skipping remaining ${ready.length - i} datasets.`);
      break;
    }

    console.log(`\n${'─'.repeat(60)}`);
    console.log(`[${i + 1}/${ready.length}] ${dataset.name}`);
    console.log(`${'─'.repeat(60)}\n`);

    // Check for resume (skip datasets with existing output)
    if (resume) {
      const existing = await checkResume(dataset.name);
      if (existing) {
        console.log(`[${dataset.name}] SKIP — existing output found: ${path.basename(existing.outputDir)}`);
        summary.push({
          name: dataset.name,
          success: true,
          durationMs: 0,
          outputDir: existing.outputDir,
          skipped: true,
          skipReason: 'Existing pipeline-summary.json found (--resume)',
        });
        continue;
      }
    }

    // Create per-dataset AbortController
    const datasetAbort = new AbortController();
    currentDatasetAbortController = datasetAbort;
    const startTime = Date.now();

    // Timeout promise (belt-and-suspenders — PipelineRunner has its own 90-min timeout)
    const timeoutMs = timeoutMinutes * 60 * 1000;
    let timeoutHandle: ReturnType<typeof setTimeout> | null = null;
    const timeoutPromise = new Promise<never>((_resolve, reject) => {
      timeoutHandle = setTimeout(() => {
        datasetAbort.abort();
        reject(new Error(`Batch-level timeout: dataset exceeded ${timeoutMinutes} minutes`));
      }, timeoutMs);
    });

    try {
      const result = await Promise.race([
        runPipeline(dataset.folder, {
          format,
          displayMode,
          separateWorkbooks,
          stopAfterVerification,
          concurrency,
          theme,
          weightVariable,
          noWeight,
          loopStatTestingMode,
          abortSignal: datasetAbort.signal,
        }),
        timeoutPromise,
      ]);

      // Clear the timeout since pipeline finished
      if (timeoutHandle) clearTimeout(timeoutHandle);
      currentDatasetAbortController = null;

      const durationMs = Date.now() - startTime;
      summary.push({
        name: dataset.name,
        success: result.success,
        error: result.error,
        durationMs,
        outputDir: result.outputDir,
        tableCount: result.tableCount,
        totalCostUsd: result.totalCostUsd,
      });

      if (result.success) {
        console.log(`\n[${dataset.name}] Completed in ${(durationMs / 1000 / 60).toFixed(1)} minutes`);
        recordFailFastSuccess(failFast);
      } else {
        console.error(`\n[${dataset.name}] Failed: ${result.error}`);
        const shouldAbort = recordFailFastFailure(failFast, result.error || 'unknown');
        if (shouldAbort) {
          terminationReason = `Fail-fast: ${failFast.consecutiveCount} consecutive ${failFast.lastClassification} failures`;
          console.error(`\n[batch] ABORTING — ${terminationReason}`);
          break;
        }
      }
    } catch (err) {
      // Clear the timeout since we exited (via error or timeout)
      if (timeoutHandle) clearTimeout(timeoutHandle);
      currentDatasetAbortController = null;

      const durationMs = Date.now() - startTime;
      const errorMsg = err instanceof Error ? err.message : String(err);
      summary.push({
        name: dataset.name,
        success: false,
        error: errorMsg,
        durationMs,
      });
      console.error(`\n[${dataset.name}] Crashed: ${errorMsg}`);

      const shouldAbort = recordFailFastFailure(failFast, errorMsg);
      if (shouldAbort) {
        terminationReason = `Fail-fast: ${failFast.consecutiveCount} consecutive ${failFast.lastClassification} failures`;
        console.error(`\n[batch] ABORTING — ${terminationReason}`);
        break;
      }
    }
  }

  // Clean up signal handlers
  process.removeAllListeners('SIGINT');
  process.removeAllListeners('SIGTERM');

  // =========================================================================
  // Aggregate batch report from per-pipeline summaries
  // =========================================================================

  const batchReport = await buildBatchReport(summary, format, displayMode, concurrency, timeoutMinutes, failFastThreshold, resume, terminationReason);

  // Print console summary
  printBatchSummary(batchReport);

  // Save batch report JSON to outputs/
  const outputsDir = path.join(process.cwd(), 'outputs');
  const batchTimestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const batchReportPath = path.join(outputsDir, `batch-summary-${batchTimestamp}.json`);
  await fs.writeFile(batchReportPath, JSON.stringify(batchReport, null, 2));
  console.log(`\nBatch report saved: ${batchReportPath}\n`);
}

// =============================================================================
// Batch Report Builder
// =============================================================================

interface BatchReport {
  timestamp: string;
  config: { format: string; displayMode: string; concurrency: number; timeoutMinutes: number; failFastThreshold: number; resume: boolean };
  terminationReason?: string;
  datasets: DatasetReport[];
  aggregates: BatchAggregates;
}

interface DatasetReport {
  name: string;
  success: boolean;
  error?: string;
  durationMs: number;
  durationFormatted: string;
  outputDir?: string;
  skipped?: boolean;
  skipReason?: string;
  tables?: {
    generated: number;
    verified: number;
    validated: number;
    excluded: number;
    total: number;
  };
  rValidation?: {
    passedFirstTime: number;
    fixedAfterRetry: number;
    excluded: number;
    firstPassRate: number;
  };
  costs?: {
    totalUsd: number;
    totalTokens: number;
    totalCalls: number;
    byAgent: { agent: string; model: string; calls: number; tokens: number; costUsd: number; durationMs: number }[];
  };
  postpass?: {
    totalFixes: number;
    totalWarnings: number;
  };
  loops?: {
    detected: boolean;
    totalGroups: number;
    totalBaseVars: number;
    totalIterationVars: number;
    patterns: string[];
  };
  variables?: number;
  cuts?: number;
  bannerGroups?: number;
}

interface BatchAggregates {
  totalDatasets: number;
  succeeded: number;
  failed: number;
  skipped: number;
  totalDurationMs: number;
  totalDurationFormatted: string;
  avgDurationMs: number;
  avgDurationFormatted: string;
  totalCostUsd: number;
  avgCostUsd: number;
  totalTokens: number;
  avgTokens: number;
  totalCalls: number;
  tables: {
    avgGenerated: number;
    avgValidated: number;
    avgExcluded: number;
    avgFirstPassRate: number;
  };
  postpass: {
    avgFixes: number;
    avgWarnings: number;
  };
  loops: {
    datasetsWithLoops: number;
    avgLoopGroups: number;
  };
  agentBreakdown: {
    agent: string;
    avgCalls: number;
    avgTokens: number;
    avgCostUsd: number;
    avgDurationMs: number;
  }[];
}

function formatDuration(ms: number): string {
  const mins = ms / 1000 / 60;
  if (mins >= 60) {
    const hrs = Math.floor(mins / 60);
    const rem = Math.round(mins % 60);
    return `${hrs}h ${rem}m`;
  }
  return `${mins.toFixed(1)}m`;
}

async function buildBatchReport(
  runs: RunResult[],
  format: string,
  displayMode: string,
  concurrency: number,
  timeoutMinutes: number,
  failFastThreshold: number,
  resume: boolean,
  terminationReason?: string,
): Promise<BatchReport> {
  const datasets: DatasetReport[] = [];

  for (const run of runs) {
    const report: DatasetReport = {
      name: run.name,
      success: run.success,
      error: run.error,
      durationMs: run.durationMs,
      durationFormatted: formatDuration(run.durationMs),
      outputDir: run.outputDir,
      skipped: run.skipped,
      skipReason: run.skipReason,
    };

    // Read per-pipeline files if we have an output directory
    if (run.outputDir) {
      try {
        // pipeline-summary.json
        const summaryPath = path.join(run.outputDir, 'pipeline-summary.json');
        const summaryRaw = await fs.readFile(summaryPath, 'utf-8');
        const ps = JSON.parse(summaryRaw);

        report.variables = ps.outputs?.variables;
        report.cuts = ps.outputs?.cuts;
        report.bannerGroups = ps.outputs?.bannerGroups;

        report.tables = {
          generated: ps.outputs?.tableGeneratorTables ?? 0,
          verified: ps.outputs?.verifiedTables ?? 0,
          validated: ps.outputs?.validatedTables ?? 0,
          excluded: ps.outputs?.excludedTables ?? 0,
          total: ps.outputs?.totalTablesInR ?? 0,
        };

        if (ps.outputs?.rValidation) {
          const rv = ps.outputs.rValidation;
          const total = rv.totalTables || 1;
          report.rValidation = {
            passedFirstTime: rv.passedFirstTime ?? 0,
            fixedAfterRetry: rv.fixedAfterRetry ?? 0,
            excluded: rv.excluded ?? 0,
            firstPassRate: Math.round(((rv.passedFirstTime ?? 0) / total) * 100),
          };
        }

        if (ps.costs) {
          report.costs = {
            totalUsd: ps.costs.totals?.estimatedCostUsd ?? 0,
            totalTokens: ps.costs.totals?.totalTokens ?? 0,
            totalCalls: ps.costs.totals?.calls ?? 0,
            byAgent: (ps.costs.byAgent || []).map((a: Record<string, unknown>) => ({
              agent: a.agentName as string,
              model: a.model as string,
              calls: a.calls as number,
              tokens: a.totalTokens as number,
              costUsd: a.estimatedCostUsd as number,
              durationMs: a.totalDurationMs as number,
            })),
          };
        }
      } catch {
        // pipeline-summary.json not found or parse error — skip
      }

      try {
        // postpass-report.json
        const postpassPath = path.join(run.outputDir, 'postpass', 'postpass-report.json');
        const postpassRaw = await fs.readFile(postpassPath, 'utf-8');
        const pp = JSON.parse(postpassRaw);
        report.postpass = {
          totalFixes: pp.stats?.totalFixes ?? 0,
          totalWarnings: pp.stats?.totalWarnings ?? 0,
        };
      } catch {
        // No postpass report
      }

      try {
        // loop-summary.json
        const loopPath = path.join(run.outputDir, 'loop-summary.json');
        const loopRaw = await fs.readFile(loopPath, 'utf-8');
        const ls = JSON.parse(loopRaw);
        const patterns: string[] = (ls.fillRateResults || []).map((f: Record<string, unknown>) => String(f.pattern));
        report.loops = {
          detected: (ls.totalLoopGroups ?? 0) > 0,
          totalGroups: ls.totalLoopGroups ?? 0,
          totalBaseVars: ls.totalBaseVars ?? 0,
          totalIterationVars: ls.totalIterationVars ?? 0,
          patterns: [...new Set(patterns)],
        };
      } catch {
        report.loops = { detected: false, totalGroups: 0, totalBaseVars: 0, totalIterationVars: 0, patterns: [] };
      }
    }

    datasets.push(report);
  }

  // Compute aggregates across successful runs (excluding skipped)
  const skippedDatasets = datasets.filter(d => d.skipped);
  const succeeded = datasets.filter(d => d.success && !d.skipped);
  const failed = datasets.filter(d => !d.success);
  const n = succeeded.length || 1; // avoid divide-by-zero

  const totalDurationMs = datasets.reduce((s, d) => s + d.durationMs, 0);
  const totalCostUsd = succeeded.reduce((s, d) => s + (d.costs?.totalUsd ?? 0), 0);
  const totalTokens = succeeded.reduce((s, d) => s + (d.costs?.totalTokens ?? 0), 0);
  const totalCalls = succeeded.reduce((s, d) => s + (d.costs?.totalCalls ?? 0), 0);

  // Table averages
  const avgGenerated = succeeded.reduce((s, d) => s + (d.tables?.generated ?? 0), 0) / n;
  const avgValidated = succeeded.reduce((s, d) => s + (d.tables?.validated ?? 0), 0) / n;
  const avgExcluded = succeeded.reduce((s, d) => s + (d.tables?.excluded ?? 0), 0) / n;
  const firstPassRates = succeeded.filter(d => d.rValidation).map(d => d.rValidation!.firstPassRate);
  const avgFirstPassRate = firstPassRates.length > 0
    ? firstPassRates.reduce((s, r) => s + r, 0) / firstPassRates.length
    : 0;

  // Postpass averages
  const avgFixes = succeeded.reduce((s, d) => s + (d.postpass?.totalFixes ?? 0), 0) / n;
  const avgWarnings = succeeded.reduce((s, d) => s + (d.postpass?.totalWarnings ?? 0), 0) / n;

  // Loop stats
  const datasetsWithLoops = succeeded.filter(d => d.loops?.detected).length;
  const loopDatasets = succeeded.filter(d => d.loops?.detected);
  const avgLoopGroups = loopDatasets.length > 0
    ? loopDatasets.reduce((s, d) => s + (d.loops?.totalGroups ?? 0), 0) / loopDatasets.length
    : 0;

  // Per-agent breakdown across all successful runs
  const agentMap = new Map<string, { calls: number; tokens: number; costUsd: number; durationMs: number; count: number }>();
  for (const d of succeeded) {
    for (const a of d.costs?.byAgent ?? []) {
      const existing = agentMap.get(a.agent) ?? { calls: 0, tokens: 0, costUsd: 0, durationMs: 0, count: 0 };
      existing.calls += a.calls;
      existing.tokens += a.tokens;
      existing.costUsd += a.costUsd;
      existing.durationMs += a.durationMs;
      existing.count += 1;
      agentMap.set(a.agent, existing);
    }
  }

  const agentBreakdown = [...agentMap.entries()].map(([agent, totals]) => ({
    agent,
    avgCalls: Math.round((totals.calls / totals.count) * 10) / 10,
    avgTokens: Math.round(totals.tokens / totals.count),
    avgCostUsd: Math.round((totals.costUsd / totals.count) * 1000) / 1000,
    avgDurationMs: Math.round(totals.durationMs / totals.count),
  }));

  return {
    timestamp: new Date().toISOString(),
    config: { format, displayMode, concurrency, timeoutMinutes, failFastThreshold, resume },
    terminationReason,
    datasets,
    aggregates: {
      totalDatasets: datasets.length,
      succeeded: succeeded.length,
      failed: failed.length,
      skipped: skippedDatasets.length,
      totalDurationMs,
      totalDurationFormatted: formatDuration(totalDurationMs),
      avgDurationMs: Math.round(totalDurationMs / n),
      avgDurationFormatted: formatDuration(Math.round(totalDurationMs / n)),
      totalCostUsd: Math.round(totalCostUsd * 100) / 100,
      avgCostUsd: Math.round((totalCostUsd / n) * 100) / 100,
      totalTokens,
      avgTokens: Math.round(totalTokens / n),
      totalCalls,
      tables: {
        avgGenerated: Math.round(avgGenerated),
        avgValidated: Math.round(avgValidated),
        avgExcluded: Math.round(avgExcluded),
        avgFirstPassRate: Math.round(avgFirstPassRate),
      },
      postpass: {
        avgFixes: Math.round(avgFixes * 10) / 10,
        avgWarnings: Math.round(avgWarnings * 10) / 10,
      },
      loops: {
        datasetsWithLoops,
        avgLoopGroups: Math.round(avgLoopGroups * 10) / 10,
      },
      agentBreakdown,
    },
  };
}

// =============================================================================
// Console Output
// =============================================================================

function printBatchSummary(report: BatchReport): void {
  const { aggregates: agg, datasets } = report;

  console.log(`\n${'='.repeat(70)}`);
  console.log('BATCH SUMMARY');
  console.log(`${'='.repeat(70)}`);

  // Termination reason
  if (report.terminationReason) {
    console.log(`\n  TERMINATED: ${report.terminationReason}`);
  }

  // Per-dataset results
  console.log('\nPER DATASET:');
  for (const d of datasets) {
    const status = d.skipped ? 'SKIP' : d.success ? 'OK  ' : 'FAIL';
    const cost = d.costs ? `$${d.costs.totalUsd.toFixed(2)}` : '—';
    const tables = d.tables ? `${d.tables.validated}v/${d.tables.excluded}x` : '—';
    const firstPass = d.rValidation ? `${d.rValidation.firstPassRate}% 1st-pass` : '';
    const loops = d.loops?.detected ? `loops:${d.loops.totalGroups}` : '';
    const error = d.error ? `  ${d.error.substring(0, 60)}` : '';
    const skipNote = d.skipped ? '  (existing output)' : '';
    console.log(`  [${status}] ${d.name.padEnd(40)} ${d.durationFormatted.padStart(6)}  ${cost.padStart(6)}  ${tables.padStart(8)}  ${firstPass}  ${loops}${skipNote}`);
    if (error) console.log(`         ${error}`);
  }

  // Aggregate stats
  console.log(`\n${'─'.repeat(70)}`);
  console.log('AGGREGATES (across successful runs, excluding skipped):');
  const skippedLabel = agg.skipped > 0 ? `, ${agg.skipped} skipped` : '';
  console.log(`  Datasets:     ${agg.succeeded} succeeded, ${agg.failed} failed${skippedLabel}`);
  console.log(`  Total time:   ${agg.totalDurationFormatted}  |  Avg: ${agg.avgDurationFormatted}`);
  console.log(`  Total cost:   $${agg.totalCostUsd.toFixed(2)}  |  Avg: $${agg.avgCostUsd.toFixed(2)}/dataset`);
  console.log(`  Total tokens: ${agg.totalTokens.toLocaleString()}  |  Avg: ${agg.avgTokens.toLocaleString()}/dataset`);
  console.log(`  Total calls:  ${agg.totalCalls}`);

  console.log(`\n  Tables:       Avg ${agg.tables.avgGenerated} generated → ${agg.tables.avgValidated} validated, ${agg.tables.avgExcluded} excluded`);
  console.log(`  R 1st-pass:   ${agg.tables.avgFirstPassRate}% average`);
  console.log(`  PostPass:     Avg ${agg.postpass.avgFixes} fixes, ${agg.postpass.avgWarnings} warnings per dataset`);
  console.log(`  Loops:        ${agg.loops.datasetsWithLoops}/${agg.succeeded} datasets have loops (avg ${agg.loops.avgLoopGroups} groups)`);

  // Agent breakdown
  if (agg.agentBreakdown.length > 0) {
    console.log(`\n  AGENT BREAKDOWN (averages per dataset):`);
    console.log(`  ${'Agent'.padEnd(30)} ${'Calls'.padStart(6)} ${'Tokens'.padStart(10)} ${'Cost'.padStart(8)} ${'Time'.padStart(8)}`);
    for (const a of agg.agentBreakdown) {
      console.log(`  ${a.agent.padEnd(30)} ${String(a.avgCalls).padStart(6)} ${a.avgTokens.toLocaleString().padStart(10)} ${'$' + a.avgCostUsd.toFixed(3).padStart(7)} ${formatDuration(a.avgDurationMs).padStart(8)}`);
    }
  }

  console.log(`\n${'='.repeat(70)}`);
}

main().catch((error) => {
  console.error(`\nBatch runner error: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
