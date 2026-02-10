import { NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';

import {
  archiveAndClearPipelineErrors,
  getErrorsDir,
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

export async function POST(
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

    const report = await archiveAndClearPipelineErrors(pipelineInfo.path);

    const errorsDir = getErrorsDir(pipelineInfo.path);
    await fs.mkdir(errorsDir, { recursive: true });
    const reportPath = path.join(errorsDir, 'clear-report.json');
    await fs.writeFile(reportPath, JSON.stringify(report, null, 2), 'utf-8');

    return NextResponse.json({
      success: true,
      pipelineId,
      dataset: pipelineInfo.dataset,
      report,
    });
  } catch (error) {
    console.error('[Errors Clear API] Error:', error);
    return NextResponse.json(
      { error: 'Failed to clear errors', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

