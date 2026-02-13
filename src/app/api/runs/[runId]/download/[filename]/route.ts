/**
 * GET /api/runs/[runId]/download/[filename]
 * Download a pipeline output file via R2 presigned URL.
 * Looks up the R2 key from the run's result.r2Files, generates
 * a presigned URL with Content-Disposition for a user-friendly filename,
 * and redirects.
 */
import { NextRequest, NextResponse } from 'next/server';
import { getConvexClient } from '@/lib/convex';
import { api } from '../../../../../../../convex/_generated/api';
import { getDownloadUrl } from '@/lib/r2/R2FileManager';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import type { Id } from '../../../../../../../convex/_generated/dataModel';
import { applyRateLimit } from '@/lib/withRateLimit';
import { getApiErrorDetails } from '@/lib/api/errorDetails';

// Map user-friendly filenames to the R2 output keys — crosstab Excel files only.
// Internal files (tables.json, master.R, pipeline-summary.json) are intentionally
// excluded to avoid leaking implementation details to end users.
const FILENAME_TO_OUTPUT_PATH: Record<string, string> = {
  'crosstabs.xlsx': 'results/crosstabs.xlsx',
  'crosstabs-weighted.xlsx': 'results/crosstabs-weighted.xlsx',
  'crosstabs-unweighted.xlsx': 'results/crosstabs-unweighted.xlsx',
  'crosstabs-counts.xlsx': 'results/crosstabs-counts.xlsx',
  'crosstabs-weighted-counts.xlsx': 'results/crosstabs-weighted-counts.xlsx',
};

// Map internal filenames to user-friendly variant suffixes for download naming
const FILENAME_TO_VARIANT_SUFFIX: Record<string, string> = {
  'crosstabs.xlsx': '',
  'crosstabs-weighted.xlsx': ' (Weighted)',
  'crosstabs-unweighted.xlsx': ' (Unweighted)',
  'crosstabs-counts.xlsx': ' (Counts)',
  'crosstabs-weighted-counts.xlsx': ' (Weighted Counts)',
};

/**
 * Strip characters that are illegal in filenames across OS platforms.
 * Trims leading/trailing whitespace and dots.
 */
function sanitizeFilename(name: string): string {
  return name
    .replace(/[/\\:*?"<>|]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/^\.+|\.+$/g, '');
}

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
        { error: 'File not found' },
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

    // Build a user-friendly download filename: "CrosstabAI - {ProjectName} - {date}{variant}.xlsx"
    let contentDisposition: string | undefined;
    try {
      const project = await convex.query(api.projects.get, { projectId: run.projectId });
      if (project?.name) {
        const sanitizedName = sanitizeFilename(project.name);
        // Use run completion time, falling back to creation time
        const completionDate = new Date(run._creationTime).toISOString().split('T')[0];
        const variantSuffix = FILENAME_TO_VARIANT_SUFFIX[filename] ?? '';
        const friendlyFilename = `CrosstabAI - ${sanitizedName} - ${completionDate}${variantSuffix}.xlsx`;
        contentDisposition = `attachment; filename="${friendlyFilename}"`;
      }
    } catch {
      // Non-fatal — fall back to default filename from R2
    }

    // Generate presigned URL (1 hour expiry) with optional Content-Disposition
    const url = await getDownloadUrl(r2Key, 3600, contentDisposition);

    // Redirect to presigned URL
    return NextResponse.redirect(url);
  } catch (error) {
    console.error('[Download API] Error:', error);
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      { error: 'Failed to generate download URL', details: getApiErrorDetails(error) },
      { status: 500 },
    );
  }
}
