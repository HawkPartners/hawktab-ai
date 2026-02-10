import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';

import {
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

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  try {
    const { pipelineId } = await params;
    const err = validatePipelineId(pipelineId);
    if (err) return NextResponse.json({ error: err }, { status: 400 });

    const pipelineInfo = await findPipelineDir(pipelineId);
    if (!pipelineInfo) return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });

    // Path traversal prevention (belt and suspenders)
    const resolvedPipelineDir = path.resolve(pipelineInfo.path);
    if (!resolvedPipelineDir.startsWith(path.resolve(process.cwd(), 'outputs'))) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }

    const { records, invalidLines } = await readPipelineErrors(pipelineInfo.path);
    const summary = summarizePipelineErrors(records);

    const limit = Math.max(0, Math.min(5000, parseInt(request.nextUrl.searchParams.get('limit') || '200', 10) || 200));
    const offset = Math.max(0, parseInt(request.nextUrl.searchParams.get('offset') || '0', 10) || 0);

    return NextResponse.json({
      pipelineId,
      dataset: pipelineInfo.dataset,
      summary,
      invalidLines,
      records: records.slice(offset, offset + limit),
      pagination: {
        limit,
        offset,
        returned: Math.max(0, Math.min(limit, records.length - offset)),
        total: records.length,
      },
    });
  } catch (error) {
    console.error('[Errors API GET] Error:', error);
    return NextResponse.json(
      { error: 'Failed to get errors', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

