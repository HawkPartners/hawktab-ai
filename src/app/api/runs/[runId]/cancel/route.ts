/**
 * POST /api/runs/[runId]/cancel
 * Cancel a pipeline run via Convex + in-memory AbortController.
 */
import { NextRequest, NextResponse } from 'next/server';
import { getConvexClient } from '@/lib/convex';
import { api } from '../../../../../../convex/_generated/api';
import { abortRun } from '@/lib/abortStore';
import { requireConvexAuth } from '@/lib/requireConvexAuth';
import { canPerform } from '@/lib/permissions';
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

    // Authenticate, verify role, and verify org ownership
    const auth = await requireConvexAuth();
    if (!canPerform(auth.role, 'cancel_run')) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }
    const convex = getConvexClient();

    const run = await convex.query(api.runs.get, { runId: runId as Id<"runs"> });
    if (!run) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }
    if (String(run.orgId) !== String(auth.convexOrgId)) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

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
    const errorMsg = error instanceof Error ? error.message : 'Unknown error';
    if (errorMsg.includes('Authentication required') || errorMsg.includes('Unauthorized')) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      { error: 'Failed to cancel run', details: process.env.NODE_ENV === 'development' ? errorMsg : undefined },
      { status: 500 }
    );
  }
}
