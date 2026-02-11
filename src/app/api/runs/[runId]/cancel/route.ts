/**
 * POST /api/runs/[runId]/cancel
 * Cancel a pipeline run via Convex + in-memory AbortController.
 */
import { NextRequest, NextResponse } from 'next/server';
import { getConvexClient } from '@/lib/convex';
import { api } from '../../../../../../convex/_generated/api';
import { abortRun } from '@/lib/abortStore';
import type { Id } from '../../../../../../convex/_generated/dataModel';

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ runId: string }> }
) {
  try {
    const { runId } = await params;

    if (!runId) {
      return NextResponse.json({ error: 'Run ID is required' }, { status: 400 });
    }

    const convex = getConvexClient();

    // Update Convex status to cancelled
    await convex.mutation(api.runs.requestCancel, {
      runId: runId as Id<"runs">,
    });

    // Abort local process if running on this server
    const aborted = abortRun(runId);

    return NextResponse.json({
      success: true,
      localAbort: aborted,
    });
  } catch (error) {
    console.error('[Cancel API] Error:', error);
    return NextResponse.json(
      { error: 'Failed to cancel run', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
