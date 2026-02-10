#!/usr/bin/env npx tsx
/**
 * Clear (archive) persisted pipeline errors for a given output directory or pipelineId.
 *
 * Usage:
 *   npx tsx scripts/clear-pipeline-errors.ts --outputDir="outputs/<dataset>/pipeline-.../"
 *   npx tsx scripts/clear-pipeline-errors.ts --pipelineId="pipeline-..."
 */

import fs from 'fs/promises';
import path from 'path';

import { archiveAndClearPipelineErrors, getErrorsDir } from '../src/lib/errors/ErrorPersistence';

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

async function main() {
  const outputDir = await resolveOutputDir();
  console.log(`Clearing persisted errors in: ${path.relative(process.cwd(), outputDir)}`);

  const report = await archiveAndClearPipelineErrors(outputDir);

  // Write a clear report artifact
  const errorsDir = getErrorsDir(outputDir);
  await fs.mkdir(errorsDir, { recursive: true });
  const reportPath = path.join(errorsDir, 'clear-report.json');
  await fs.writeFile(reportPath, JSON.stringify(report, null, 2), 'utf-8');

  console.log(`  hadErrorsFile: ${report.hadErrorsFile}`);
  if (report.archivedTo) console.log(`  archivedTo:   ${report.archivedTo}`);
  console.log(`  report:       ${path.relative(process.cwd(), reportPath)}`);
}

main().catch((err) => {
  console.error('clear-pipeline-errors failed:', err instanceof Error ? err.message : String(err));
  process.exitCode = 1;
});

