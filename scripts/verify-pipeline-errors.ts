#!/usr/bin/env npx tsx
/**
 * Verify persisted pipeline error coverage for a given output directory or pipelineId.
 *
 * This is **report-only**: it never fails a pipeline run. It writes a verification report JSON.
 *
 * Usage:
 *   npx tsx scripts/verify-pipeline-errors.ts --outputDir="outputs/<dataset>/pipeline-.../"
 *   npx tsx scripts/verify-pipeline-errors.ts --pipelineId="pipeline-..."
 */

import fs from 'fs/promises';
import path from 'path';

import {
  getErrorsDir,
  getErrorsLogPath,
  readPipelineErrors,
  summarizePipelineErrors,
} from '../src/lib/errors/ErrorPersistence';

function parseFlag(prefix: string): string | null {
  const arg = process.argv.find(a => a.startsWith(prefix));
  if (!arg) return null;
  return arg.split('=').slice(1).join('=').trim() || null;
}

function validatePipelineId(pipelineId: string): string | null {
  if (!pipelineId) return 'Pipeline ID is required';
  if (!pipelineId.startsWith('pipeline-') || pipelineId.includes('..')) return 'Invalid pipeline ID format';
  return null;
}

async function findPipelineDir(pipelineId: string): Promise<{ path: string; dataset: string } | null> {
  const outputsDir = path.join(process.cwd(), 'outputs');
  try {
    await fs.access(outputsDir);
  } catch {
    return null;
  }

  const datasetDirs = await fs.readdir(outputsDir);
  for (const dataset of datasetDirs) {
    const datasetPath = path.join(outputsDir, dataset);
    let stat: { isDirectory(): boolean };
    try {
      stat = await fs.stat(datasetPath);
    } catch {
      continue;
    }
    if (!stat.isDirectory()) continue;

    const pipelinePath = path.join(datasetPath, pipelineId);
    try {
      const pipelineStat = await fs.stat(pipelinePath);
      if (pipelineStat.isDirectory()) return { path: pipelinePath, dataset };
    } catch {
      // continue
    }
  }

  return null;
}

async function resolveOutputDir(): Promise<string> {
  const outputDirFlag = parseFlag('--outputDir=');
  if (outputDirFlag) return path.isAbsolute(outputDirFlag) ? outputDirFlag : path.join(process.cwd(), outputDirFlag);

  const pipelineId = parseFlag('--pipelineId=');
  if (!pipelineId) {
    throw new Error('Provide either --outputDir=... or --pipelineId=...');
  }
  const err = validatePipelineId(pipelineId);
  if (err) throw new Error(err);

  const found = await findPipelineDir(pipelineId);
  if (!found) throw new Error(`Pipeline not found for pipelineId="${pipelineId}"`);
  return found.path;
}

async function fileExists(p: string): Promise<boolean> {
  try {
    await fs.access(p);
    return true;
  } catch {
    return false;
  }
}

async function readJsonIfExists<T = unknown>(p: string): Promise<T | null> {
  try {
    const raw = await fs.readFile(p, 'utf-8');
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

async function main() {
  const outputDir = await resolveOutputDir();
  const relOutputDir = path.relative(process.cwd(), outputDir);
  console.log(`Verifying error persistence in: ${relOutputDir}`);

  const errorsPath = getErrorsLogPath(outputDir);
  const hasErrorsFile = await fileExists(errorsPath);

  const { records, invalidLines } = await readPipelineErrors(outputDir);
  const summary = summarizePipelineErrors(records);

  // Heuristic: loops detected but loop policy missing should have an error record
  const loopSummaryPath = path.join(outputDir, 'loop-summary.json');
  const loopPolicyPath = path.join(outputDir, 'loop-policy', 'loop-semantics-policy.json');

  const loopSummary = await readJsonIfExists<{ groups?: unknown[] }>(loopSummaryPath);
  const loopsDetected = Array.isArray(loopSummary?.groups) && loopSummary!.groups!.length > 0;
  const hasLoopPolicy = await fileExists(loopPolicyPath);
  const hasLoopPolicyErrorRecord = records.some(r => r.agentName === 'LoopSemanticsPolicyAgent');

  const gaps: string[] = [];
  if (loopsDetected && !hasLoopPolicy && !hasLoopPolicyErrorRecord) {
    gaps.push('Loops detected (loop-summary.json) but loop-semantics-policy.json missing and no LoopSemanticsPolicyAgent error record found.');
  }

  const report = {
    verifiedAt: new Date().toISOString(),
    outputDir: relOutputDir,
    errorsFile: {
      path: path.relative(process.cwd(), errorsPath),
      exists: hasErrorsFile,
    },
    parsed: {
      records: records.length,
      invalidLines: invalidLines.length,
    },
    summary,
    heuristics: {
      loopsDetected,
      hasLoopPolicy,
      hasLoopPolicyErrorRecord,
      gaps,
    },
    invalidLines: invalidLines.slice(0, 50), // cap to keep report readable
  };

  // Write report
  const errorsDir = getErrorsDir(outputDir);
  await fs.mkdir(errorsDir, { recursive: true });
  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  const reportPath = path.join(errorsDir, `verify-report-${ts}.json`);
  await fs.writeFile(reportPath, JSON.stringify(report, null, 2), 'utf-8');

  console.log(`  errorsFile:   ${hasErrorsFile ? 'present' : 'absent'}`);
  console.log(`  records:      ${records.length}`);
  console.log(`  invalidLines: ${invalidLines.length}`);
  if (gaps.length > 0) {
    console.log(`  gaps:         ${gaps.length}`);
    for (const g of gaps) console.log(`    - ${g}`);
  } else {
    console.log(`  gaps:         0`);
  }
  console.log(`  report:       ${path.relative(process.cwd(), reportPath)}`);
}

main().catch((err) => {
  console.error('verify-pipeline-errors failed:', err instanceof Error ? err.message : String(err));
  process.exitCode = 1;
});

