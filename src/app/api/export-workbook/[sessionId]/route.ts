/**
 * GET /api/export-workbook/[sessionId]
 * Purpose: Generate Excel workbook from tables.json (Antares-style formatting)
 * Reads: results/tables.json
 * Returns: Excel workbook download
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { formatTablesFileToBuffer } from '@/lib/excel/ExcelFormatter';
import { requireConvexAuth, AuthenticationError } from '@/lib/requireConvexAuth';
import { applyRateLimit } from '@/lib/withRateLimit';

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ sessionId: string }> }
) {
  try {
    const auth = await requireConvexAuth();

    const rateLimited = applyRateLimit(String(auth.convexOrgId), 'medium', 'export-workbook');
    if (rateLimited) return rateLimited;

    const { sessionId } = await params;

    // Strict allowlist — alphanumeric, underscore, hyphen after known prefixes
    if (!/^(output|test-pipeline)-[a-zA-Z0-9_-]+$/.test(sessionId)) {
      return NextResponse.json({ error: 'Invalid sessionId' }, { status: 400 });
    }

    const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);
    const resultsDir = path.join(sessionPath, 'results');
    const tablesJsonPath = path.join(resultsDir, 'tables.json');

    // Check if tables.json exists
    try {
      await fs.access(tablesJsonPath);
    } catch {
      return NextResponse.json(
        { error: 'No tables.json found. Execute R script first.' },
        { status: 404 }
      );
    }

    console.log(`[Excel Export] Formatting tables.json from: ${sessionId}`);

    // Format tables.json to Excel buffer
    const buffer = await formatTablesFileToBuffer(tablesJsonPath);

    console.log(`[Excel Export] Generated workbook: ${buffer.byteLength} bytes`);

    // Return as downloadable file (convert Buffer to Uint8Array for NextResponse)
    return new NextResponse(new Uint8Array(buffer), {
      status: 200,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="crosstabs-${sessionId}.xlsx"`,
        'Content-Length': buffer.byteLength.toString()
      }
    });

  } catch (error) {
    console.error('[Excel Export] Error:', error);
    if (error instanceof AuthenticationError) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
    return NextResponse.json(
      {
        error: 'Failed to generate Excel workbook',
        details: process.env.NODE_ENV === 'development'
          ? error instanceof Error ? error.message : String(error)
          : undefined
      },
      { status: 500 }
    );
  }
}
