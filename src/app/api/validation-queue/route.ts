/**
 * GET /api/validation-queue
 * Purpose: List sessions with validation status for UI
 * Reads: temp-outputs/output-* folders
 * Returns: { sessions: SessionSummary[], counts }
 */

import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import type { ValidationStatus } from '../../../schemas/humanValidationSchema';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import { applyRateLimit } from '@/lib/withRateLimit';
import { getApiErrorDetails } from '@/lib/api/errorDetails';

interface SessionSummary {
  sessionId: string;
  status: 'pending' | 'validated';
  createdAt: string;
  validatedAt?: string;
  files: {
    banner: boolean;
    dataMap: boolean;
    crosstab: boolean;
  };
  columnCount?: number;
  groupCount?: number;
}

export async function GET(_request: NextRequest) {
  try {
    const auth = await requireConvexAuth();

    const rateLimited = applyRateLimit(String(auth.convexOrgId), 'low', 'validation-queue');
    if (rateLimited) return rateLimited;

    const tempOutputsDir = path.join(process.cwd(), 'temp-outputs');
    
    // Check if temp-outputs directory exists
    try {
      await fs.access(tempOutputsDir);
    } catch {
      // Directory doesn't exist, return empty list
      return NextResponse.json({
        sessions: [],
        counts: {
          total: 0,
          pending: 0,
          validated: 0
        }
      });
    }

    // Read all session directories
    const dirContents = await fs.readdir(tempOutputsDir);
    const sessionDirs = dirContents.filter(name => name.startsWith('output-'));

    const sessions: SessionSummary[] = [];

    // Process each session directory
    for (const sessionDir of sessionDirs) {
      const sessionPath = path.join(tempOutputsDir, sessionDir);
      
      // Check if it's a directory
      const stats = await fs.stat(sessionPath);
      if (!stats.isDirectory()) continue;

      // Try to read validation status
      let validationStatus: ValidationStatus | null = null;
      try {
        const statusPath = path.join(sessionPath, 'validation-status.json');
        const statusContent = await fs.readFile(statusPath, 'utf-8');
        validationStatus = JSON.parse(statusContent);
      } catch {
        // No validation status file, skip this session
        continue;
      }

      // Check for presence of key files
      const files = await fs.readdir(sessionPath);
      const hasBanner = files.some(f => f.includes('banner') && f.endsWith('.json'));
      const hasDataMap = files.some(f => f.includes('dataMap') && f.endsWith('.json'));
      const hasCrosstab = files.some(f => f.includes('crosstab') && f.endsWith('.json'));

      // Try to get column and group counts from crosstab output
      let columnCount = 0;
      let groupCount = 0;
      try {
        const crosstabFile = files.find(f => f.includes('crosstab-output'));
        if (crosstabFile) {
          const crosstabPath = path.join(sessionPath, crosstabFile);
          const crosstabContent = await fs.readFile(crosstabPath, 'utf-8');
          const crosstabData = JSON.parse(crosstabContent);
          
          if (crosstabData.bannerCuts) {
            groupCount = crosstabData.bannerCuts.length;
            columnCount = crosstabData.bannerCuts.reduce(
              (total: number, group: { columns?: { length: number } }) => total + (group.columns?.length || 0), 
              0
            );
          }
        }
      } catch {
        // Failed to read crosstab data, continue with defaults
      }

      if (validationStatus) {
        sessions.push({
          sessionId: sessionDir,
          status: validationStatus.status,
          createdAt: validationStatus.createdAt,
          validatedAt: validationStatus.validatedAt,
          files: {
            banner: hasBanner,
            dataMap: hasDataMap,
            crosstab: hasCrosstab
          },
          columnCount,
          groupCount
        });
      }
    }

    // Sort by creation date (newest first)
    sessions.sort((a, b) => 
      new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );

    // Calculate counts
    const counts = {
      total: sessions.length,
      pending: sessions.filter(s => s.status === 'pending').length,
      validated: sessions.filter(s => s.status === 'validated').length
    };

    return NextResponse.json({
      sessions,
      counts
    });

  } catch (error) {
    console.error('[Validation Queue] Error reading sessions:', error);
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      {
        error: 'Failed to read validation queue',
        details: getApiErrorDetails(error),
      },
      { status: 500 }
    );
  }
}

// Filter sessions by status
export async function POST(request: NextRequest) {
  try {
    const authPost = await requireConvexAuth();

    const rateLimitedPost = applyRateLimit(String(authPost.convexOrgId), 'low', 'validation-queue');
    if (rateLimitedPost) return rateLimitedPost;

    const { status } = await request.json();
    
    if (status && !['pending', 'validated'].includes(status)) {
      return NextResponse.json(
        { error: 'Invalid status filter. Must be "pending" or "validated"' },
        { status: 400 }
      );
    }

    // Get all sessions
    const response = await GET(request as NextRequest);
    const data = await response.json();

    if (!data.sessions) {
      return response; // Return error response as-is
    }

    // Filter if status provided
    const filteredSessions = status 
      ? data.sessions.filter((s: SessionSummary) => s.status === status)
      : data.sessions;

    return NextResponse.json({
      sessions: filteredSessions,
      counts: data.counts,
      filter: status || 'all'
    });

  } catch (error) {
    console.error('[Validation Queue] Error filtering sessions:', error);
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      {
        error: 'Failed to filter validation queue',
        details: getApiErrorDetails(error),
      },
      { status: 500 }
    );
  }
}