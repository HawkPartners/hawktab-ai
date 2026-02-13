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
import { uploadPipelineOutputs, downloadReviewFiles, downloadToTemp, deleteReviewFiles, type ReviewR2Keys } from '@/lib/r2/R2FileManager';
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
import { sendHeartbeat } from '@/lib/api/heartbeat';
import { sendPipelineNotification } from '@/lib/notifications/email';

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ runId: string }> }
) {
  let outerRunId: string | undefined;
  try {
    const { runId: rawRunId } = await params;
    outerRunId = rawRunId;

    if (!rawRunId || !/^[a-zA-Z0-9_.-]+$/.test(rawRunId)) {
      return NextResponse.json({ error: 'Run ID is required' }, { status: 400 });
    }
    const runId = rawRunId; // narrowed to string for the rest of the try block

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

    // Read review state from disk, with R2 fallback for container restart recovery
    const reviewStatePath = path.join(outputDir, 'crosstab-review-state.json');
    let reviewState: CrosstabReviewState;
    let recoveredFromR2 = false;
    let recoveredOutputDir = outputDir;
    // Runtime-validate reviewR2Keys shape from v.any() Convex field
    const rawR2Keys = runResult?.reviewR2Keys;
    const reviewR2Keys: ReviewR2Keys | undefined =
      rawR2Keys && typeof rawR2Keys === 'object' && !Array.isArray(rawR2Keys) &&
      (typeof (rawR2Keys as Record<string, unknown>).reviewState === 'string' ||
       typeof (rawR2Keys as Record<string, unknown>).reviewState === 'undefined')
        ? (rawR2Keys as ReviewR2Keys)
        : undefined;

    try {
      reviewState = JSON.parse(await fs.readFile(reviewStatePath, 'utf-8'));
    } catch {
      // Local file missing — try R2 recovery
      if (reviewR2Keys?.reviewState) {
        console.log('[Review API] Local review state missing — attempting R2 recovery');
        try {
          recoveredOutputDir = path.join(process.cwd(), 'outputs', '_recovered', runId);
          await downloadReviewFiles(reviewR2Keys, recoveredOutputDir);

          const recoveredPath = path.join(recoveredOutputDir, 'crosstab-review-state.json');
          reviewState = JSON.parse(await fs.readFile(recoveredPath, 'utf-8'));
          // Update outputDir reference in review state to point to recovered location
          reviewState.outputDir = recoveredOutputDir;
          recoveredFromR2 = true;
          console.log('[Review API] Successfully recovered review state from R2');
        } catch (r2Err) {
          console.error('[Review API] R2 recovery failed:', r2Err);
          const isReviewRun = run.status === 'pending_review';
          return NextResponse.json(
            { error: isReviewRun
                ? 'Review state was lost after a server restart. Please start a new run.'
                : 'Review state not found - pipeline may not require review' },
            { status: isReviewRun ? 409 : 404 }
          );
        }
      } else {
        const isReviewRun = run.status === 'pending_review';
        return NextResponse.json(
          { error: isReviewRun
              ? 'Review state was lost after a server restart. Please start a new run.'
              : 'Review state not found - pipeline may not require review' },
          { status: isReviewRun ? 409 : 404 }
        );
      }
    }

    if (reviewState.status !== 'awaiting_review') {
      return NextResponse.json(
        { error: `Cannot submit review - status is ${reviewState.status}` },
        { status: 400 }
      );
    }

    console.log(`[Review API] wizardConfig in review state: present=${reviewState.wizardConfig !== undefined}, displayMode=${reviewState.wizardConfig?.displayMode ?? 'undefined'}, separateWorkbooks=${reviewState.wizardConfig?.separateWorkbooks ?? 'undefined'}`);
    console.log(`[Review API] Processing review for run ${runId} with ${decisions.length} decisions`);

    // Save decisions to review state on disk
    reviewState.status = 'approved';
    reviewState.decisions = decisions;
    const activeOutputDir = recoveredFromR2 ? recoveredOutputDir : outputDir;
    await fs.writeFile(
      path.join(activeOutputDir, 'crosstab-review-state.json'),
      JSON.stringify(reviewState, null, 2)
    );

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
      activeOutputDir
    );

    const totalColumns = modifiedCrosstabResult.bannerCuts.reduce((sum, g) => sum + g.columns.length, 0);
    console.log(`[Review API] Applied decisions: ${modifiedCrosstabResult.bannerCuts.length} groups, ${totalColumns} columns`);

    // Check if Path B is complete (local disk → R2 fallback)
    const pathBResultPath = path.join(activeOutputDir, 'path-b-result.json');
    let pathBResult: PathBResult | null = reviewState.pathBResult;

    if (!pathBResult) {
      try {
        pathBResult = JSON.parse(await fs.readFile(pathBResultPath, 'utf-8'));
        console.log('[Review API] Path B result loaded from disk');
      } catch (pathBErr: unknown) {
        // Distinguish file-not-found from corrupt JSON to avoid 30-min polling loop
        const isFileNotFound = pathBErr instanceof Error && 'code' in pathBErr && (pathBErr as NodeJS.ErrnoException).code === 'ENOENT';
        if (!isFileNotFound && !recoveredFromR2) {
          // File exists but is corrupt — don't enter polling loop
          console.error('[Review API] path-b-result.json exists but failed to parse:', pathBErr);
          return NextResponse.json(
            { error: 'Table processing results are corrupted. Please start a new run.' },
            { status: 500 }
          );
        }
        // If we recovered from R2, the download already tried to fetch path-b-result.json.
        // Check if it was downloaded during recovery; if not, try to determine status.
        if (recoveredFromR2) {
          // Check Convex reviewState.pathBStatus
          const convexReviewState = (runResult?.reviewState as Record<string, unknown>) || {};
          const pathBStatus = convexReviewState.pathBStatus as string | undefined;

          if (pathBStatus === 'completed') {
            // Path B finished but file wasn't in R2 (race condition or upload failure)
            // Try R2 key directly
            if (reviewR2Keys?.pathBResult) {
              try {
                await downloadToTemp(reviewR2Keys.pathBResult, pathBResultPath);
                pathBResult = JSON.parse(await fs.readFile(pathBResultPath, 'utf-8'));
                console.log('[Review API] Path B result loaded from R2 (direct key)');
              } catch {
                // R2 key exists but download failed
                pathBResult = null;
              }
            }
          } else if (pathBStatus === 'running') {
            // Path B process was running on the old container — it's dead now
            return NextResponse.json(
              { error: 'Table processing was interrupted by a server restart. Please start a new run.' },
              { status: 409 }
            );
          } else if (pathBStatus === 'error') {
            return NextResponse.json(
              { error: 'Table processing failed. Please start a new run.' },
              { status: 500 }
            );
          }
        } else {
          pathBResult = null;
        }
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

      let result;
      try {
        result = await completePipeline(activeOutputDir, pipelineId, modifiedCrosstabResult, pathBResult, reviewState, decisions, runId);
      } catch (pipeErr) {
        // Clean up R2 review files even on pipeline failure (prevent orphans)
        if (reviewR2Keys) {
          try { await deleteReviewFiles(reviewR2Keys); } catch { /* non-fatal */ }
        }
        throw pipeErr;
      }

      // Upload outputs to R2
      const convexOrgId = String(auth.convexOrgId);
      const projectId = String(run.projectId);
      let r2Outputs: Record<string, string> | undefined;
      let r2UploadFailed = false;
      try {
        const manifest = await uploadPipelineOutputs(convexOrgId, projectId, runId, activeOutputDir);
        r2Outputs = manifest.outputs;
        console.log(`[Review API] Uploaded ${Object.keys(r2Outputs).length} outputs to R2`);
      } catch (r2Error) {
        r2UploadFailed = true;
        console.error('[Review API] R2 upload failed — downloads will be unavailable:', r2Error);
      }

      // Clean up R2 review state files (non-fatal)
      if (reviewR2Keys) {
        try {
          await deleteReviewFiles(reviewR2Keys);
          console.log('[Review API] Cleaned up R2 review files');
        } catch (cleanupErr) {
          console.warn('[Review API] R2 review file cleanup failed (non-fatal):', cleanupErr);
        }
      }

      // Clean up recovered directory (non-fatal, ephemeral disk handles this on redeploy)
      if (recoveredFromR2 && recoveredOutputDir !== outputDir) {
        fs.rm(recoveredOutputDir, { recursive: true }).catch(() => { /* best-effort */ });
      }

      // Keep heartbeat alive while R2 work completes (heartbeat stopped when completePipeline returned)
      await sendHeartbeat(runId);

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

      // Send email notification (fire-and-forget)
      const launchedBy = (run as Record<string, unknown>).launchedBy as string | undefined;
      sendPipelineNotification({
        runId,
        status: terminalStatus as 'success' | 'partial' | 'error',
        launchedBy,
        convexProjectId: String(run.projectId),
        tableCount: result.tableCount,
        durationFormatted: result.durationMs ? `${(result.durationMs / 1000).toFixed(1)}s` : undefined,
        errorMessage: terminalStatus === 'error' ? terminalMessage : undefined,
      }).catch(() => { /* swallowed */ });

      return NextResponse.json({
        success: result.success,
        runId,
        status: terminalStatus,
        message: terminalMessage,
      });
    } else if (recoveredFromR2) {
      // Recovered from R2 but Path B result is unavailable — can't poll local disk on new container
      return NextResponse.json(
        { error: 'Table processing results could not be recovered after server restart. Please start a new run.' },
        { status: 409 }
      );
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
      waitAndCompletePipeline(activeOutputDir, pipelineId, modifiedCrosstabResult, reviewState, decisions, runId)
        .then(async (result) => {
          // Upload to R2
          const convexOrgId = String(auth.convexOrgId);
          const projectId = String(run.projectId);
          let r2Outputs: Record<string, string> | undefined;
          let r2Failed = false;
          try {
            const manifest = await uploadPipelineOutputs(convexOrgId, projectId, runId, activeOutputDir);
            r2Outputs = manifest.outputs;
          } catch {
            r2Failed = true;
          }

          // Clean up R2 review state files (non-fatal)
          if (reviewR2Keys) {
            try {
              await deleteReviewFiles(reviewR2Keys);
            } catch { /* non-fatal */ }
          }

          // Clean up recovered directory (non-fatal)
          if (recoveredFromR2 && recoveredOutputDir !== outputDir) {
            fs.rm(recoveredOutputDir, { recursive: true }).catch(() => { /* best-effort */ });
          }

          // Keep heartbeat alive while R2 work completes (heartbeat stopped when completePipeline returned)
          await sendHeartbeat(runId);

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

          // Send email notification (fire-and-forget)
          const bgLaunchedBy = (run as Record<string, unknown>).launchedBy as string | undefined;
          sendPipelineNotification({
            runId,
            status: bgTerminalStatus as 'success' | 'partial' | 'error',
            launchedBy: bgLaunchedBy,
            convexProjectId: String(run.projectId),
            tableCount: result.tableCount,
            durationFormatted: result.durationMs ? `${(result.durationMs / 1000).toFixed(1)}s` : undefined,
            errorMessage: bgTerminalStatus === 'error' ? bgTerminalMessage : undefined,
          }).catch(() => { /* swallowed */ });
        })
        .catch(async (err) => {
          console.error('[Review API] Background completion error:', err);
          try {
            await mutateInternal(internal.runs.updateStatus, {
              runId: runId as Id<"runs">,
              status: 'error',
              stage: 'complete',
              progress: 100,
              message: 'Pipeline failed during background completion',
              error: err instanceof Error ? err.message : String(err),
            });
          } catch { /* last resort — Convex may be unreachable */ }
        });

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
    // Mark run as errored immediately so the UI doesn't show a stuck spinner
    if (outerRunId) {
      try {
        await mutateInternal(internal.runs.updateStatus, {
          runId: outerRunId as Id<"runs">,
          status: 'error',
          stage: 'error',
          progress: 100,
          message: 'Unexpected failure during review completion',
          error: 'Unexpected failure during review completion',
        });
      } catch { /* last resort — Convex may be unreachable */ }
    }
    return NextResponse.json(
      { error: 'Failed to process review', details: getApiErrorDetails(error) },
      { status: 500 }
    );
  }
}
