/**
 * POST /api/runs/[runId]/review
 * Submit review decisions and resume pipeline.
 * UI reads review state from Convex subscriptions (no GET needed).
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { requireConvexAuth } from '@/lib/requireConvexAuth';
import { getConvexClient } from '@/lib/convex';
import { api } from '../../../../../../convex/_generated/api';
import { uploadPipelineOutputs } from '@/lib/r2/R2FileManager';
import {
  applyDecisions,
  completePipeline,
  waitAndCompletePipeline,
  type CrosstabDecision,
  type ReviewState,
} from '@/lib/api/reviewCompletion';
import type { Id } from '../../../../../../convex/_generated/dataModel';
import type { PathBResult } from '@/lib/api/types';

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ runId: string }> }
) {
  try {
    const { runId } = await params;

    if (!runId) {
      return NextResponse.json({ error: 'Run ID is required' }, { status: 400 });
    }

    // Authenticate
    const auth = await requireConvexAuth();

    // Get run from Convex
    const convex = getConvexClient();
    const run = await convex.query(api.runs.get, { runId: runId as Id<"runs"> });

    if (!run) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }

    // Parse request body
    let body: { decisions: CrosstabDecision[] };
    try {
      body = await request.json();
    } catch {
      return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
    }

    const { decisions } = body;
    if (!decisions || !Array.isArray(decisions)) {
      return NextResponse.json({ error: 'Decisions array is required' }, { status: 400 });
    }

    // Get pipelineId from run result
    const runResult = run.result as Record<string, unknown> | undefined;
    const pipelineId = runResult?.pipelineId as string | undefined;
    const outputDir = runResult?.outputDir as string | undefined;

    if (!pipelineId || !outputDir) {
      return NextResponse.json(
        { error: 'Run does not have pipeline context (pipelineId/outputDir missing)' },
        { status: 400 }
      );
    }

    // Read review state from disk
    const reviewStatePath = path.join(outputDir, 'crosstab-review-state.json');
    let reviewState: ReviewState;
    try {
      reviewState = JSON.parse(await fs.readFile(reviewStatePath, 'utf-8'));
    } catch {
      return NextResponse.json(
        { error: 'Review state not found - pipeline may not require review' },
        { status: 404 }
      );
    }

    if (reviewState.status !== 'awaiting_review') {
      return NextResponse.json(
        { error: `Cannot submit review - status is ${reviewState.status}` },
        { status: 400 }
      );
    }

    console.log(`[Review API] Processing review for run ${runId} with ${decisions.length} decisions`);

    // Save decisions to review state on disk
    reviewState.status = 'approved';
    reviewState.decisions = decisions;
    await fs.writeFile(reviewStatePath, JSON.stringify(reviewState, null, 2));

    // Update Convex: mark run as resuming
    await convex.mutation(api.runs.updateStatus, {
      runId: runId as Id<"runs">,
      status: 'resuming',
      stage: 'applying_review',
      progress: 55,
      message: 'Applying review decisions...',
    });

    // Apply decisions to crosstab result
    const modifiedCrosstabResult = await applyDecisions(
      reviewState.crosstabResult,
      reviewState.flaggedColumns,
      decisions,
      reviewState.agentDataMap,
      outputDir
    );

    const totalColumns = modifiedCrosstabResult.bannerCuts.reduce((sum, g) => sum + g.columns.length, 0);
    console.log(`[Review API] Applied decisions: ${modifiedCrosstabResult.bannerCuts.length} groups, ${totalColumns} columns`);

    // Check if Path B is complete
    const pathBResultPath = path.join(outputDir, 'path-b-result.json');
    let pathBResult: PathBResult | null = reviewState.pathBResult;

    if (!pathBResult) {
      try {
        pathBResult = JSON.parse(await fs.readFile(pathBResultPath, 'utf-8'));
        console.log('[Review API] Path B result loaded from disk');
      } catch {
        pathBResult = null;
      }
    }

    if (pathBResult) {
      // Path B complete — finish pipeline synchronously
      await convex.mutation(api.runs.updateStatus, {
        runId: runId as Id<"runs">,
        status: 'resuming',
        stage: 'generating_output',
        progress: 60,
        message: 'Generating R script and Excel...',
      });

      const result = await completePipeline(outputDir, pipelineId, modifiedCrosstabResult, pathBResult, reviewState, decisions);

      // Upload outputs to R2
      const convexOrgId = String(auth.convexOrgId);
      const projectId = String(run.projectId);
      let r2Outputs: Record<string, string> | undefined;
      try {
        const manifest = await uploadPipelineOutputs(convexOrgId, projectId, runId, outputDir);
        r2Outputs = manifest.outputs;
        console.log(`[Review API] Uploaded ${Object.keys(r2Outputs).length} outputs to R2`);
      } catch (r2Error) {
        console.warn('[Review API] R2 upload failed (non-fatal):', r2Error);
      }

      // Update Convex with terminal status
      await convex.mutation(api.runs.updateStatus, {
        runId: runId as Id<"runs">,
        status: result.status,
        stage: 'complete',
        progress: 100,
        message: result.message,
        result: {
          ...runResult,
          downloadUrl: result.status === 'success'
            ? `/api/runs/${encodeURIComponent(runId)}/download/crosstabs.xlsx`
            : undefined,
          r2Files: r2Outputs ? { inputs: {}, outputs: r2Outputs } : runResult?.r2Files,
          reviewState: undefined, // Clear review state from result
        },
        ...(result.status === 'error' ? { error: result.message } : {}),
      });

      return NextResponse.json({
        success: result.success,
        runId,
        status: result.status,
        message: result.message,
      });
    } else {
      // Path B still running — fire-and-forget background completion
      console.log('[Review API] Path B still running - will complete in background');

      await convex.mutation(api.runs.updateStatus, {
        runId: runId as Id<"runs">,
        status: 'resuming',
        stage: 'waiting_for_tables',
        progress: 55,
        message: 'Review saved. Waiting for table processing...',
      });

      // Background completion
      waitAndCompletePipeline(outputDir, pipelineId, modifiedCrosstabResult, reviewState, decisions)
        .then(async (result) => {
          // Upload to R2
          const convexOrgId = String(auth.convexOrgId);
          const projectId = String(run.projectId);
          let r2Outputs: Record<string, string> | undefined;
          try {
            const manifest = await uploadPipelineOutputs(convexOrgId, projectId, runId, outputDir);
            r2Outputs = manifest.outputs;
          } catch {
            // non-fatal
          }

          await convex.mutation(api.runs.updateStatus, {
            runId: runId as Id<"runs">,
            status: result.status,
            stage: 'complete',
            progress: 100,
            message: result.message,
            result: {
              ...runResult,
              downloadUrl: result.status === 'success'
                ? `/api/runs/${encodeURIComponent(runId)}/download/crosstabs.xlsx`
                : undefined,
              r2Files: r2Outputs ? { inputs: {}, outputs: r2Outputs } : runResult?.r2Files,
              reviewState: undefined,
            },
            ...(result.status === 'error' ? { error: result.message } : {}),
          });
        })
        .catch(err => console.error('[Review API] Background completion error:', err));

      return NextResponse.json({
        success: true,
        runId,
        status: 'resuming',
        message: 'Review saved. Pipeline will complete when table processing finishes.',
      });
    }
  } catch (error) {
    console.error('[Review API POST] Error:', error);
    return NextResponse.json(
      { error: 'Failed to process review', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
