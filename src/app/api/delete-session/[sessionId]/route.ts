/**
 * DELETE /api/delete-session/[sessionId]
 * Purpose: Remove a session directory and all artifacts
 * Reads: temp-outputs/<sessionId>
 * Side-effects: Recursively deletes folder
 */

import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import { applyRateLimit } from '@/lib/withRateLimit';

// Delete session folder
export async function DELETE(_request: NextRequest, { params }: { params: Promise<{ sessionId: string }> }) {
  try {
    const auth = await requireConvexAuth();

    const rateLimited = applyRateLimit(String(auth.convexOrgId), 'low', 'delete-session');
    if (rateLimited) return rateLimited;

    const { sessionId } = await params;

    // Security check: strict allowlist — only alphanumeric, underscore, hyphen after "output-"
    if (!/^output-[a-zA-Z0-9_-]+$/.test(sessionId)) {
      return NextResponse.json(
        { error: 'Invalid session ID format' },
        { status: 400 }
      );
    }

    const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);

    // Check if session directory exists
    try {
      await fs.access(sessionPath);
    } catch {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    // Verify it's actually a directory
    const stats = await fs.stat(sessionPath);
    if (!stats.isDirectory()) {
      return NextResponse.json(
        { error: 'Session path is not a directory' },
        { status: 400 }
      );
    }

    // Delete the entire directory recursively
    await fs.rm(sessionPath, { recursive: true, force: true });

    console.log(`[Delete Session] Successfully deleted session: ${sessionId}`);

    return NextResponse.json({
      success: true,
      sessionId,
      message: 'Session folder deleted successfully'
    });

  } catch (error) {
    console.error('[Delete Session] Error deleting session:', error);
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      {
        error: 'Failed to delete session folder',
        details: process.env.NODE_ENV === 'development'
          ? error instanceof Error ? error.message : String(error)
          : undefined
      },
      { status: 500 }
    );
  }
}