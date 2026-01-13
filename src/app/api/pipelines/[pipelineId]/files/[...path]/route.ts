/**
 * GET /api/pipelines/[pipelineId]/files/[...path]
 * Purpose: Download a specific file from a pipeline run
 * Example: /api/pipelines/pipeline-2026-01-13T10-00-00-000Z/files/results/crosstabs.xlsx
 * Security: Validates pipelineId format and prevents path traversal
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';

/**
 * Find a pipeline directory by pipelineId across all datasets
 */
async function findPipelineDir(pipelineId: string): Promise<string | null> {
  const outputsDir = path.join(process.cwd(), 'outputs');

  try {
    await fs.access(outputsDir);
  } catch {
    return null;
  }

  const datasetDirs = await fs.readdir(outputsDir);

  for (const dataset of datasetDirs) {
    const datasetPath = path.join(outputsDir, dataset);
    const stat = await fs.stat(datasetPath);

    if (!stat.isDirectory()) continue;

    // Check if this pipeline exists in this dataset
    const pipelinePath = path.join(datasetPath, pipelineId);
    try {
      const pipelineStat = await fs.stat(pipelinePath);
      if (pipelineStat.isDirectory()) {
        return pipelinePath;
      }
    } catch {
      // Not in this dataset, continue
    }
  }

  return null;
}

/**
 * Get content type based on file extension
 */
function getContentType(filename: string): string {
  const ext = path.extname(filename).toLowerCase();
  const types: Record<string, string> = {
    '.json': 'application/json',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.csv': 'text/csv',
    '.txt': 'text/plain',
    '.md': 'text/markdown',
    '.r': 'text/plain',
    '.sav': 'application/octet-stream',
    '.pdf': 'application/pdf',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.doc': 'application/msword',
  };
  return types[ext] || 'application/octet-stream';
}

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string; path: string[] }> }
) {
  try {
    const { pipelineId, path: pathSegments } = await params;

    if (!pipelineId || !pathSegments || pathSegments.length === 0) {
      return NextResponse.json({ error: 'Pipeline ID and file path are required' }, { status: 400 });
    }

    // Validate pipelineId format (prevent path traversal)
    if (!pipelineId.startsWith('pipeline-') || pipelineId.includes('..')) {
      return NextResponse.json({ error: 'Invalid pipeline ID format' }, { status: 400 });
    }

    // Join path segments and validate (prevent path traversal)
    const relativePath = pathSegments.join('/');
    if (relativePath.includes('..') || relativePath.startsWith('/')) {
      return NextResponse.json({ error: 'Invalid file path' }, { status: 400 });
    }

    // Find the pipeline directory
    const pipelineDir = await findPipelineDir(pipelineId);

    if (!pipelineDir) {
      return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });
    }

    // Construct full file path
    const filePath = path.join(pipelineDir, relativePath);

    // Ensure the file is within the pipeline directory (double-check path traversal prevention)
    const resolvedPath = path.resolve(filePath);
    const resolvedPipelineDir = path.resolve(pipelineDir);
    if (!resolvedPath.startsWith(resolvedPipelineDir)) {
      return NextResponse.json({ error: 'Access denied' }, { status: 403 });
    }

    // Check if file exists
    try {
      const stat = await fs.stat(filePath);
      if (!stat.isFile()) {
        return NextResponse.json({ error: 'Not a file' }, { status: 400 });
      }
    } catch {
      return NextResponse.json({ error: 'File not found' }, { status: 404 });
    }

    // Read file content
    const fileBuffer = await fs.readFile(filePath);
    const filename = path.basename(filePath);
    const contentType = getContentType(filename);

    // Convert Buffer to Uint8Array for NextResponse
    const fileContent = new Uint8Array(fileBuffer);

    // Return file with appropriate headers
    return new NextResponse(fileContent, {
      status: 200,
      headers: {
        'Content-Type': contentType,
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Content-Length': fileContent.length.toString(),
      },
    });
  } catch (error) {
    console.error('[Pipeline Files] Error:', error);
    return NextResponse.json(
      { error: 'Failed to download file', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
