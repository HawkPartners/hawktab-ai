/**
 * GET /api/generate-r/[sessionId]
 * Purpose: Generate a single-file R script and validation summary for a session
 * Reads: temp-outputs/<sessionId>/{dataFile.sav, cut-tables.json|crosstab-output-*.json, dataMap-agent*.json}
 * Writes: temp-outputs/<sessionId>/{r-script.R, r-validation.json}
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { RScriptAgent } from '@/agents/RScriptAgent';

export async function GET(_req: NextRequest, { params }: { params: Promise<{ sessionId: string }> }) {
  try {
    const { sessionId } = await params;
    if (!sessionId.startsWith('output-') || sessionId.includes('..') || sessionId.includes('/')) {
      return NextResponse.json({ error: 'Invalid sessionId' }, { status: 400 });
    }

    const sessionDir = path.join(process.cwd(), 'temp-outputs', sessionId);
    await fs.access(sessionDir);

    const savPath = path.join(sessionDir, 'dataFile.sav');
    try {
      await fs.access(savPath);
    } catch {
      return NextResponse.json({ error: 'Missing dataFile.sav in session folder' }, { status: 400 });
    }

    const agent = new RScriptAgent();
    const result = await agent.generate(sessionId);

    const rPath = path.join(sessionDir, 'r-script.R');
    const validationPath = path.join(sessionDir, 'r-validation.json');
    await Promise.all([
      fs.writeFile(rPath, result.script, 'utf-8'),
      fs.writeFile(validationPath, JSON.stringify({ issues: result.issues, stats: result.stats }, null, 2), 'utf-8'),
    ]);

    return NextResponse.json({
      success: true,
      sessionId,
      files: {
        r: `temp-outputs/${sessionId}/r-script.R`,
        validation: `temp-outputs/${sessionId}/r-validation.json`,
      },
      stats: result.stats,
    });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate R script' },
      { status: 500 },
    );
  }
}


