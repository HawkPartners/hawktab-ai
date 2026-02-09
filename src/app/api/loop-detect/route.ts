import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import path from 'path';
import os from 'os';
import { validate } from '@/lib/validation/ValidationRunner';

export async function POST(request: NextRequest) {
  let tmpDir: string | null = null;

  try {
    const formData = await request.formData();
    const dataFile = formData.get('dataFile') as File | null;

    if (!dataFile) {
      return NextResponse.json({ error: 'Missing dataFile' }, { status: 400 });
    }

    if (!dataFile.name.toLowerCase().endsWith('.sav')) {
      return NextResponse.json({ error: 'dataFile must be a .sav file' }, { status: 400 });
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
