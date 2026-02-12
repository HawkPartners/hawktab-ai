/**
 * POST /api/runs/[runId]/review
 * Submit review decisions and resume pipeline.
 * UI reads review state from Convex subscriptions (no GET needed).
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import { getConvexClient, mutateInternal } from '@/lib/convex';
import { api } from '../../../../../../convex/_generated/api';
import { internal } from '../../../../../../convex/_generated/api';
import { uploadPipelineOutputs } from '@/lib/r2/R2FileManager';
import {
  applyDecisions,
  completePipeline,
  waitAndCompletePipeline,
  type CrosstabDecision,
} from '@/lib/api/reviewCompletion';
import type { Id } from '../../../../../../convex/_generated/dataModel';
import type { PathBResult, CrosstabReviewState } from '@/lib/api/types';
import { applyRateLimit } from '@/lib/withRateLimit';
import { getApiErrorDetails } from '@/lib/api/errorDetails';

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

    const rateLimited = applyRateLimit(String(auth.convexOrgId), 'high', 'runs/review');
    if (rateLimited) return rateLimited;

    // Get run from Convex
    const convex = getConvexClient();
    const run = await convex.query(api.runs.get, { runId: runId as Id<"runs"> });

    if (!run) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }

    // Verify org ownership
    if (String(run.orgId) !== String(auth.convexOrgId)) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
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

    // Validate outputDir resolves under the expected outputs directory
    const resolvedOutput = path.resolve(outputDir);
    const allowedBase = path.resolve(process.cwd(), 'outputs');
    if (!resolvedOutput.startsWith(allowedBase + path.sep) && resolvedOutput !== allowedBase) {
      return NextResponse.json({ error: 'Invalid output path' }, { status: 400 });
    }

    // Read review state from disk (expanded CrosstabReviewState with all context)
    const reviewStatePath = path.join(outputDir, 'crosstab-review-state.json');
    let reviewState: CrosstabReviewState;
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
    await mutateInternal(internal.runs.updateStatus, {
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
      // Path B complete — run full remaining pipeline
      await mutateInternal(internal.runs.updateStatus, {
        runId: runId as Id<"runs">,
        status: 'resuming',
        stage: 'filtering',
        progress: 55,
        message: 'Applying filters and running verification...',
      });

      const result = await completePipeline(outputDir, pipelineId, modifiedCrosstabResult, pathBResult, reviewState, decisions, runId);

      // Upload outputs to R2
      const convexOrgId = String(auth.convexOrgId);
      const projectId = String(run.projectId);
      let r2Outputs: Record<string, string> | undefined;
      let r2UploadFailed = false;
      try {
        const manifest = await uploadPipelineOutputs(convexOrgId, projectId, runId, outputDir);
        r2Outputs = manifest.outputs;
        console.log(`[Review API] Uploaded ${Object.keys(r2Outputs).length} outputs to R2`);
      } catch (r2Error) {
        r2UploadFailed = true;
        console.error('[Review API] R2 upload failed — downloads will be unavailable:', r2Error);
      }

      // Downgrade to 'partial' if pipeline succeeded but R2 upload failed (files can't be downloaded)
      const terminalStatus = result.status === 'success' && r2UploadFailed ? 'partial' : result.status;
      const terminalMessage = result.status === 'success' && r2UploadFailed
        ? `Generated ${result.tableCount ?? 0} tables but file upload failed — contact support.`
        : result.message;

      // Update Convex with terminal status
      await mutateInternal(internal.runs.updateStatus, {
        runId: runId as Id<"runs">,
        status: terminalStatus,
        stage: 'complete',
        progress: 100,
        message: terminalMessage,
        result: {
          ...runResult,
          downloadUrl: terminalStatus === 'success'
            ? `/api/runs/${encodeURIComponent(runId)}/download/crosstabs.xlsx`
            : undefined,
          r2Files: r2Outputs ? { inputs: {}, outputs: r2Outputs } : runResult?.r2Files,
          reviewState: undefined, // Clear review state from result
          summary: {
            tables: result.tableCount ?? 0,
            cuts: result.cutCount ?? 0,
            bannerGroups: result.bannerGroups ?? 0,
            durationMs: result.durationMs ?? 0,
          },
        },
        ...(terminalStatus === 'error' ? { error: terminalMessage } : {}),
      });

      return NextResponse.json({
        success: result.success,
        runId,
        status: terminalStatus,
        message: terminalMessage,
      });
    } else {
      // Path B still running — fire-and-forget background completion
      console.log('[Review API] Path B still running - will complete in background');

      await mutateInternal(internal.runs.updateStatus, {
        runId: runId as Id<"runs">,
        status: 'resuming',
        stage: 'waiting_for_tables',
        progress: 55,
        message: 'Review saved. Waiting for table processing...',
      });

      // Background completion
      waitAndCompletePipeline(outputDir, pipelineId, modifiedCrosstabResult, reviewState, decisions, runId)
        .then(async (result) => {
          // Upload to R2
          const convexOrgId = String(auth.convexOrgId);
          const projectId = String(run.projectId);
          let r2Outputs: Record<string, string> | undefined;
          let r2Failed = false;
          try {
            const manifest = await uploadPipelineOutputs(convexOrgId, projectId, runId, outputDir);
            r2Outputs = manifest.outputs;
          } catch {
            r2Failed = true;
          }

          // Downgrade to 'partial' if pipeline succeeded but R2 upload failed
          const bgTerminalStatus = result.status === 'success' && r2Failed ? 'partial' : result.status;
          const bgTerminalMessage = result.status === 'success' && r2Failed
            ? `Generated ${result.tableCount ?? 0} tables but file upload failed — contact support.`
            : result.message;

          await mutateInternal(internal.runs.updateStatus, {
            runId: runId as Id<"runs">,
            status: bgTerminalStatus,
            stage: 'complete',
            progress: 100,
            message: bgTerminalMessage,
            result: {
              ...runResult,
              downloadUrl: bgTerminalStatus === 'success'
                ? `/api/runs/${encodeURIComponent(runId)}/download/crosstabs.xlsx`
                : undefined,
              r2Files: r2Outputs ? { inputs: {}, outputs: r2Outputs } : runResult?.r2Files,
              reviewState: undefined,
              summary: {
                tables: result.tableCount ?? 0,
                cuts: result.cutCount ?? 0,
                bannerGroups: result.bannerGroups ?? 0,
                durationMs: result.durationMs ?? 0,
              },
            },
            ...(bgTerminalStatus === 'error' ? { error: bgTerminalMessage } : {}),
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
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      { error: 'Failed to process review', details: getApiErrorDetails(error) },
      { status: 500 }
    );
  }
}
