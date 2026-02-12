/**
 * GET /api/projects/[projectId]/download/[filename]
 * Download an input file (user-uploaded) via R2 presigned URL.
 * Validates the filename against the project's intake record,
 * reconstructs the R2 key, and redirects to a presigned URL.
 */
import { NextRequest, NextResponse } from 'next/server';
import { getConvexClient } from '@/lib/convex';
import { api } from '../../../../../../../convex/_generated/api';
import { getDownloadUrl } from '@/lib/r2/R2FileManager';
import { buildKey } from '@/lib/r2/r2';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import type { Id } from '../../../../../../../convex/_generated/dataModel';
import { applyRateLimit } from '@/lib/withRateLimit';
import { getApiErrorDetails } from '@/lib/api/errorDetails';

/** Strict filename validation — alphanumeric, hyphens, underscores, dots, spaces */
const SAFE_FILENAME_RE = /^[a-zA-Z0-9_\-. ]+$/;

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ projectId: string; filename: string }> },
) {
  try {
    const { projectId, filename } = await params;
    const decodedFilename = decodeURIComponent(filename);

    if (!projectId || !decodedFilename) {
      return NextResponse.json({ error: 'Project ID and filename are required' }, { status: 400 });
    }

    if (!SAFE_FILENAME_RE.test(decodedFilename)) {
      return NextResponse.json({ error: 'Invalid filename' }, { status: 400 });
    }

    // Authenticate and verify org ownership
    const auth = await requireConvexAuth();

    const rateLimited = applyRateLimit(String(auth.convexOrgId), 'low', 'projects/download');
    if (rateLimited) return rateLimited;

    const convex = getConvexClient();
    const project = await convex.query(api.projects.get, {
      projectId: projectId as Id<"projects">,
    });

    if (!project) {
      return NextResponse.json({ error: 'Project not found' }, { status: 404 });
    }

    if (String(project.orgId) !== String(auth.convexOrgId)) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

    // Validate the requested filename is one of the project's actual input files
    const intake = project.intake as Record<string, string | null> | undefined;
    if (!intake) {
      return NextResponse.json({ error: 'No input files available' }, { status: 404 });
    }

    const knownInputFilenames = new Set(
      Object.values(intake).filter((v): v is string => typeof v === 'string' && v.length > 0),
    );

    if (!knownInputFilenames.has(decodedFilename)) {
      return NextResponse.json({ error: 'File not found' }, { status: 404 });
    }

    // Reconstruct the R2 key: {orgId}/{projectId}/inputs/{filename}
    const r2Key = buildKey(String(auth.convexOrgId), projectId, 'inputs', decodedFilename);

    // Generate presigned URL (1 hour expiry)
    const url = await getDownloadUrl(r2Key, 3600);

    return NextResponse.redirect(url);
  } catch (error) {
    console.error('[Input Download API] Error:', error);
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      { error: 'Failed to generate download URL', details: getApiErrorDetails(error) },
      { status: 500 },
    );
  }
}
