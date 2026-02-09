/**
 * Feedback API for post-run output feedback collection.
 *
 * GET /api/pipelines/[pipelineId]/feedback
 * - Returns feedback.json (if present) + summary
 *
 * POST /api/pipelines/[pipelineId]/feedback
 * - Appends a new entry to feedback.json (creates file if missing)
 *
 * Storage: outputs/<dataset>/<pipelineId>/feedback.json
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';
import {
  PipelineFeedbackFileSchema,
  PipelineFeedbackSummarySchema,
  SubmitPipelineFeedbackRequestSchema,
  type PipelineFeedbackFile,
  type PipelineFeedbackSummary,
} from '@/schemas/pipelineFeedbackSchema';

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

function buildSummary(file: PipelineFeedbackFile | null): PipelineFeedbackSummary {
  if (!file || file.entries.length === 0) {
    return PipelineFeedbackSummarySchema.parse({
      hasFeedback: false,
      entryCount: 0,
      lastSubmittedAt: '',
      lastRating: 0,
    });
  }

  const last = file.entries[file.entries.length - 1];
  return PipelineFeedbackSummarySchema.parse({
    hasFeedback: true,
    entryCount: file.entries.length,
    lastSubmittedAt: last.createdAt,
    lastRating: last.rating,
  });
}

async function readFeedbackFile(feedbackPath: string): Promise<PipelineFeedbackFile | null> {
  try {
    const raw = await fs.readFile(feedbackPath, 'utf-8');
    const parsed = JSON.parse(raw);
    return PipelineFeedbackFileSchema.parse(parsed);
  } catch {
    return null;
  }
}

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  try {
    const { pipelineId } = await params;
    const err = validatePipelineId(pipelineId);
    if (err) return NextResponse.json({ error: err }, { status: 400 });

    const pipelineInfo = await findPipelineDir(pipelineId);
    if (!pipelineInfo) return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });

    const feedbackPath = path.join(pipelineInfo.path, 'feedback.json');

    // Path traversal prevention (belt and suspenders)
    const resolvedFeedbackPath = path.resolve(feedbackPath);
    const resolvedPipelineDir = path.resolve(pipelineInfo.path);
    if (!resolvedFeedbackPath.startsWith(resolvedPipelineDir)) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }

    const feedbackFile = await readFeedbackFile(feedbackPath);
    const summary = buildSummary(feedbackFile);

    return NextResponse.json({
      pipelineId,
      dataset: pipelineInfo.dataset,
      feedback: feedbackFile,
      summary,
    });
  } catch (error) {
    console.error('[Feedback API GET] Error:', error);
    return NextResponse.json(
      { error: 'Failed to get feedback', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  try {
    const { pipelineId } = await params;
    const err = validatePipelineId(pipelineId);
    if (err) return NextResponse.json({ error: err }, { status: 400 });

    const pipelineInfo = await findPipelineDir(pipelineId);
    if (!pipelineInfo) return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });

    const feedbackPath = path.join(pipelineInfo.path, 'feedback.json');

    // Path traversal prevention (belt and suspenders)
    const resolvedFeedbackPath = path.resolve(feedbackPath);
    const resolvedPipelineDir = path.resolve(pipelineInfo.path);
    if (!resolvedFeedbackPath.startsWith(resolvedPipelineDir)) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }

    // Parse and validate request
    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
    }

    const parsed = SubmitPipelineFeedbackRequestSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid request body', details: parsed.error.flatten() }, { status: 400 });
    }

    const rating = parsed.data.rating;
    const notes = parsed.data.notes;
    const tableIds = parsed.data.tableIds
      .map(t => String(t).trim())
      .filter(Boolean);

    const hasAnySignal = (notes.trim().length > 0) || rating > 0 || tableIds.length > 0;
    if (!hasAnySignal) {
      return NextResponse.json(
        { error: 'Feedback must include at least one of: notes, rating, or table IDs' },
        { status: 400 }
      );
    }

    const now = new Date().toISOString();

    const existing = await readFeedbackFile(feedbackPath);
    const feedbackFile: PipelineFeedbackFile = existing ?? {
      pipelineId,
      dataset: pipelineInfo.dataset,
      createdAt: now,
      updatedAt: now,
      entries: [],
    };

    feedbackFile.entries.push({
      id: `feedback-${randomUUID()}`,
      createdAt: now,
      rating,
      notes,
      tableIds,
    });
    feedbackFile.updatedAt = now;

    // Validate before write
    const validated = PipelineFeedbackFileSchema.parse(feedbackFile);
    await fs.writeFile(feedbackPath, JSON.stringify(validated, null, 2), 'utf-8');

    const summary = buildSummary(validated);

    return NextResponse.json({
      success: true,
      pipelineId,
      dataset: pipelineInfo.dataset,
      feedback: validated,
      summary,
    });
  } catch (error) {
    console.error('[Feedback API POST] Error:', error);
    return NextResponse.json(
      { error: 'Failed to submit feedback', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

