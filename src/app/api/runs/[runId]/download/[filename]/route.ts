/**
 * GET /api/runs/[runId]/download/[filename]
 * Download a pipeline output file via R2 presigned URL.
 * Looks up the R2 key from the run's result.r2Files, generates
 * a presigned URL, and redirects.
 */
import { NextRequest, NextResponse } from 'next/server';
import { getConvexClient } from '@/lib/convex';
import { api } from '../../../../../../../convex/_generated/api';
import { getDownloadUrl } from '@/lib/r2/R2FileManager';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import type { Id } from '../../../../../../../convex/_generated/dataModel';
import { applyRateLimit } from '@/lib/withRateLimit';

// Map user-friendly filenames to the R2 output keys
const FILENAME_TO_OUTPUT_PATH: Record<string, string> = {
  'crosstabs.xlsx': 'results/crosstabs.xlsx',
  'tables.json': 'results/tables.json',
  'master.R': 'r/master.R',
  'pipeline-summary.json': 'pipeline-summary.json',
};

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ runId: string; filename: string }> },
) {
  try {
    const { runId, filename } = await params;

    if (!runId || !filename) {
      return NextResponse.json({ error: 'Run ID and filename are required' }, { status: 400 });
    }

    // Authenticate and verify org ownership
    const auth = await requireConvexAuth();

    const rateLimited = applyRateLimit(String(auth.convexOrgId), 'low', 'runs/download');
    if (rateLimited) return rateLimited;

    const convex = getConvexClient();
    const run = await convex.query(api.runs.get, { runId: runId as Id<"runs"> });

    if (!run) {
      return NextResponse.json({ error: 'Run not found' }, { status: 404 });
    }

    if (String(run.orgId) !== String(auth.convexOrgId)) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

    const result = run.result as Record<string, unknown> | undefined;
    const r2Files = result?.r2Files as { inputs?: Record<string, string>; outputs?: Record<string, string> } | undefined;

    if (!r2Files?.outputs) {
      return NextResponse.json({ error: 'No R2 files available for this run' }, { status: 404 });
    }

    // Look up the output path for this filename
    const outputPath = FILENAME_TO_OUTPUT_PATH[filename];
    if (!outputPath) {
      return NextResponse.json(
        { error: `Unknown file: ${filename}`, available: Object.keys(FILENAME_TO_OUTPUT_PATH) },
        { status: 404 },
      );
    }

    const r2Key = r2Files.outputs[outputPath];
    if (!r2Key) {
      return NextResponse.json(
        { error: `File not available: ${filename}` },
        { status: 404 },
      );
    }

    // Generate presigned URL (1 hour expiry)
    const url = await getDownloadUrl(r2Key, 3600);

    // Redirect to presigned URL
    return NextResponse.redirect(url);
  } catch (error) {
    console.error('[Download API] Error:', error);
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    const errorMsg = error instanceof Error ? error.message : 'Unknown error';
    return NextResponse.json(
      { error: 'Failed to generate download URL', details: process.env.NODE_ENV === 'development' ? errorMsg : undefined },
      { status: 500 },
    );
  }
}
