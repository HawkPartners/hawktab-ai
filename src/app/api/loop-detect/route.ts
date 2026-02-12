/**
 * @deprecated Phase 3.3 — Replaced by POST /api/validate-data which returns
 * loop detection, weight detection, stacked data detection, and data quality in one pass.
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';
import os from 'os';
import { validate } from '@/lib/validation/ValidationRunner';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import { applyRateLimit } from '@/lib/withRateLimit';

const MAX_UPLOAD_BYTES = 100 * 1024 * 1024; // 100 MB

export async function POST(request: NextRequest) {
  let tmpDir: string | null = null;

  try {
    const auth = await requireConvexAuth();

    const rateLimited = applyRateLimit(String(auth.convexOrgId), 'medium', 'loop-detect');
    if (rateLimited) return rateLimited;

    // Reject oversized uploads early
    const contentLength = Number(request.headers.get('content-length') || 0);
    if (contentLength > MAX_UPLOAD_BYTES) {
      return NextResponse.json(
        { error: `Upload too large (${Math.round(contentLength / 1024 / 1024)}MB). Maximum is 100MB.` },
        { status: 413 }
      );
    }

    const formData = await request.formData();
    const dataFile = formData.get('dataFile') as File | null;

    if (!dataFile) {
      return NextResponse.json({ error: 'Missing dataFile' }, { status: 400 });
    }

    if (!dataFile.name.toLowerCase().endsWith('.sav')) {
      return NextResponse.json({ error: 'dataFile must be a .sav file' }, { status: 400 });
    }

    if (dataFile.size > MAX_UPLOAD_BYTES) {
      return NextResponse.json(
        { error: `Data file is too large (${Math.round(dataFile.size / 1024 / 1024)}MB). Maximum is 100MB.` },
        { status: 413 }
      );
    }

    tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'hawktab-loop-detect-'));
    const spssPath = path.join(tmpDir, 'dataFile.sav');
    const buffer = Buffer.from(await dataFile.arrayBuffer());
    await fs.writeFile(spssPath, buffer);

    const validationResult = await validate({
      spssPath,
      outputDir: tmpDir,
    });

    const loopDetection = validationResult.loopDetection;
    const hasLoops = loopDetection?.hasLoops ?? false;
    const loopCount = loopDetection?.loops.length ?? 0;

    return NextResponse.json({ hasLoops, loopCount });
  } catch (error) {
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Loop detection failed' },
      { status: 500 }
    );
  } finally {
    if (tmpDir) {
      await fs.rm(tmpDir, { recursive: true, force: true });
    }
  }
}
