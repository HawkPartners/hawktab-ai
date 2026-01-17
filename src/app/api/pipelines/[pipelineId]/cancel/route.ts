/**
 * POST /api/pipelines/[pipelineId]/cancel
 * Purpose: Cancel a pipeline run and update its status
 *
 * This endpoint:
 * 1. Triggers the AbortController for the in-memory job (actually stops processing)
 * 2. Updates pipeline-summary.json status to 'cancelled'
 * 3. Updates banner-review-state.json if it exists
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { cancelJobByPipelineId } from '@/lib/jobStore';

/**
 * Find a pipeline directory by pipelineId across all datasets
 */
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
      if (pipelineStat.isDirectory()) {
        return { path: pipelinePath, dataset };
      }
    } catch {
      // Not in this dataset, continue
    }
  }

  return null;
}

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  try {
    const { pipelineId } = await params;

    if (!pipelineId) {
      return NextResponse.json({ error: 'Pipeline ID is required' }, { status: 400 });
    }

    // Validate pipelineId format (prevent path traversal)
    if (!pipelineId.startsWith('pipeline-') || pipelineId.includes('..')) {
      return NextResponse.json({ error: 'Invalid pipeline ID format' }, { status: 400 });
    }

    // Find the pipeline directory
    const pipelineInfo = await findPipelineDir(pipelineId);

    if (!pipelineInfo) {
      return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });
    }

    // Read current pipeline summary
    const summaryPath = path.join(pipelineInfo.path, 'pipeline-summary.json');
    let summary;
    try {
      const summaryContent = await fs.readFile(summaryPath, 'utf-8');
      summary = JSON.parse(summaryContent);
    } catch {
      return NextResponse.json({ error: 'Pipeline summary not found' }, { status: 404 });
    }

    // Check if pipeline can be cancelled
    const cancellableStatuses = ['in_progress', 'pending_review', 'resuming'];
    if (!cancellableStatuses.includes(summary.status)) {
      return NextResponse.json(
        { error: `Pipeline cannot be cancelled - status is '${summary.status}'` },
        { status: 400 }
      );
    }

    // Trigger the AbortController for this pipeline's job (actually stops the agents)
    const jobCancelled = cancelJobByPipelineId(pipelineId);
    if (jobCancelled) {
      console.log(`[Cancel Pipeline] Aborted in-memory job for pipeline ${pipelineId}`);
    } else {
      console.log(`[Cancel Pipeline] No in-memory job found for pipeline ${pipelineId} (may have already finished or been resumed)`);
    }

    // Update pipeline summary to cancelled
    const updatedSummary = {
      ...summary,
      status: 'cancelled',
      currentStage: 'cancelled',
      cancelledAt: new Date().toISOString(),
    };

    await fs.writeFile(summaryPath, JSON.stringify(updatedSummary, null, 2));

    // Also update banner-review-state.json if it exists
    const reviewStatePath = path.join(pipelineInfo.path, 'banner-review-state.json');
    try {
      const reviewStateContent = await fs.readFile(reviewStatePath, 'utf-8');
      const reviewState = JSON.parse(reviewStateContent);
      reviewState.status = 'cancelled';
      reviewState.cancelledAt = new Date().toISOString();
      await fs.writeFile(reviewStatePath, JSON.stringify(reviewState, null, 2));
    } catch {
      // No review state file, that's fine
    }

    // Also update crosstab-review-state.json if it exists
    const crosstabReviewStatePath = path.join(pipelineInfo.path, 'crosstab-review-state.json');
    try {
      const crosstabReviewStateContent = await fs.readFile(crosstabReviewStatePath, 'utf-8');
      const crosstabReviewState = JSON.parse(crosstabReviewStateContent);
      crosstabReviewState.status = 'cancelled';
      crosstabReviewState.cancelledAt = new Date().toISOString();
      await fs.writeFile(crosstabReviewStatePath, JSON.stringify(crosstabReviewState, null, 2));
    } catch {
      // No crosstab review state file, that's fine
    }

    console.log(`[Cancel Pipeline] Pipeline ${pipelineId} cancelled successfully`);

    return NextResponse.json({
      success: true,
      pipelineId,
      status: 'cancelled',
      cancelledAt: updatedSummary.cancelledAt,
      jobAborted: jobCancelled  // True if we actually stopped a running job
    });
  } catch (error) {
    console.error('[Cancel Pipeline] Error:', error);
    return NextResponse.json(
      { error: 'Failed to cancel pipeline', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
