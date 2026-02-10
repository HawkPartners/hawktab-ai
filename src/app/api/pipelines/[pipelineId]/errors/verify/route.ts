import { NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';

import {
  getErrorsDir,
  readPipelineErrors,
  summarizePipelineErrors,
} from '@/lib/errors/ErrorPersistence';

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
    const stat = await fs.stat(datasetPath);
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

function validatePipelineId(pipelineId: string): string | null {
  if (!pipelineId) return 'Pipeline ID is required';
  if (!pipelineId.startsWith('pipeline-') || pipelineId.includes('..')) return 'Invalid pipeline ID format';
  return null;
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

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  try {
    const { pipelineId } = await params;
    const err = validatePipelineId(pipelineId);
    if (err) return NextResponse.json({ error: err }, { status: 400 });

    const pipelineInfo = await findPipelineDir(pipelineId);
    if (!pipelineInfo) return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });

    // Path traversal prevention
    const resolvedPipelineDir = path.resolve(pipelineInfo.path);
    if (!resolvedPipelineDir.startsWith(path.resolve(process.cwd(), 'outputs'))) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }

    const { records, invalidLines } = await readPipelineErrors(pipelineInfo.path);
    const summary = summarizePipelineErrors(records);

    // Heuristic: loops detected but loop policy missing should have an error record
    const loopSummaryPath = path.join(pipelineInfo.path, 'loop-summary.json');
    const loopPolicyPath = path.join(pipelineInfo.path, 'loop-policy', 'loop-semantics-policy.json');

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
      outputDir: path.relative(process.cwd(), pipelineInfo.path),
      parsed: { records: records.length, invalidLines: invalidLines.length },
      summary,
      heuristics: {
        loopsDetected,
        hasLoopPolicy,
        hasLoopPolicyErrorRecord,
        gaps,
      },
      invalidLines: invalidLines.slice(0, 50),
    };

    // Write verification report artifact
    const errorsDir = getErrorsDir(pipelineInfo.path);
    await fs.mkdir(errorsDir, { recursive: true });
    const ts = new Date().toISOString().replace(/[:.]/g, '-');
    const reportPath = path.join(errorsDir, `verify-report-${ts}.json`);
    await fs.writeFile(reportPath, JSON.stringify(report, null, 2), 'utf-8');

    return NextResponse.json({
      success: true,
      pipelineId,
      dataset: pipelineInfo.dataset,
      report,
      reportPath: path.relative(process.cwd(), reportPath),
    });
  } catch (error) {
    console.error('[Errors Verify API] Error:', error);
    return NextResponse.json(
      { error: 'Failed to verify errors', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

