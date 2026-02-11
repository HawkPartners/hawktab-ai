/**
 * GET /api/pipelines/[pipelineId]
 * Purpose: Get details for a specific pipeline run
 * Reads: outputs/{dataset}/pipeline-{timestamp}/pipeline-summary.json + file listing
 * Returns: Pipeline summary with list of available files and their sizes
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { formatDuration } from '@/lib/utils/formatDuration';
import { PipelineFeedbackFileSchema, type PipelineFeedbackSummary } from '@/schemas/pipelineFeedbackSchema';

export interface FileInfo {
  name: string;
  path: string;
  type: 'input' | 'output' | 'intermediate';
  size: number;
  downloadUrl: string;
}

export interface PipelineDetails {
  pipelineId: string;
  dataset: string;
  timestamp: string;
  duration: {
    ms: number;
    formatted: string;
  };
  status: 'success' | 'partial' | 'error' | 'in_progress' | 'pending_review' | 'cancelled' | 'awaiting_tables';
  currentStage?: string;
  inputs: {
    datamap: string;
    banner: string;
    spss: string;
    survey: string | null;
  };
  outputs: {
    variables: number;
    tables: number;
    cuts: number;
    bannerGroups: number;
  };
  files: FileInfo[];
  feedback: PipelineFeedbackSummary;
  review?: {
    flaggedColumnCount: number;
    reviewUrl: string;
  };
}

/**
 * Find a pipeline directory by pipelineId across all datasets
 */
async function findPipelineDir(pipelineId: string): Promise<{ path: string; dataset: string } | null> {
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
        return { path: pipelinePath, dataset };
      }
    } catch {
      // Not in this dataset, continue
    }
  }

  return null;
}

/**
 * Get file size in bytes
 */
async function getFileSize(filePath: string): Promise<number> {
  try {
    const stat = await fs.stat(filePath);
    return stat.size;
  } catch {
    return 0;
  }
}

/**
 * Recursively list files in a directory
 */
async function listFiles(
  dirPath: string,
  basePath: string,
  pipelineId: string
): Promise<FileInfo[]> {
  const files: FileInfo[] = [];

  try {
    const entries = await fs.readdir(dirPath, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);
      const relativePath = path.relative(basePath, fullPath);

      if (entry.isDirectory()) {
        // Recursively list files in subdirectory (but skip deep nesting)
        if (relativePath.split(path.sep).length < 3) {
          const subFiles = await listFiles(fullPath, basePath, pipelineId);
          files.push(...subFiles);
        }
      } else {
        // Determine file type based on location and extension
        let type: 'input' | 'output' | 'intermediate' = 'intermediate';
        if (relativePath.startsWith('results/')) {
          type = 'output';
        } else if (relativePath.startsWith('inputs/')) {
          type = 'input';
        }

        // Skip very large files and internal files
        const size = await getFileSize(fullPath);
        if (size > 50 * 1024 * 1024) continue; // Skip files > 50MB
        if (entry.name.startsWith('.')) continue; // Skip hidden files

        files.push({
          name: entry.name,
          path: relativePath,
          type,
          size,
          downloadUrl: `/api/pipelines/${encodeURIComponent(pipelineId)}/files/${encodeURIComponent(relativePath)}`,
        });
      }
    }
  } catch (error) {
    console.error(`[Pipeline Details] Error listing files in ${dirPath}:`, error);
  }

  return files;
}

async function readFeedbackSummary(pipelineDir: string): Promise<PipelineFeedbackSummary> {
  const feedbackPath = path.join(pipelineDir, 'feedback.json');

  try {
    const raw = await fs.readFile(feedbackPath, 'utf-8');
    const parsed = PipelineFeedbackFileSchema.parse(JSON.parse(raw));
    const last = parsed.entries.length > 0 ? parsed.entries[parsed.entries.length - 1] : null;
    return {
      hasFeedback: parsed.entries.length > 0,
      entryCount: parsed.entries.length,
      lastSubmittedAt: last ? last.createdAt : '',
      lastRating: last ? last.rating : 0,
    };
  } catch {
    return {
      hasFeedback: false,
      entryCount: 0,
      lastSubmittedAt: '',
      lastRating: 0,
    };
  }
}

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  try {
    const { pipelineId } = await params;

    if (!pipelineId) {
      return NextResponse.json({ error: 'Pipeline ID is required' }, { status: 400 });
    }

    // Validate pipelineId format (prevent path traversal)
    if (!pipelineId.startsWith('pipeline-') || pipelineId.includes('..')) {
      return NextResponse.json({ error: 'Invalid pipeline ID format' }, { status: 400 });
    }

    // Find the pipeline directory
    const pipelineInfo = await findPipelineDir(pipelineId);

    if (!pipelineInfo) {
      return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });
    }

    // Read pipeline summary
    const summaryPath = path.join(pipelineInfo.path, 'pipeline-summary.json');
    let summary;
    try {
      const summaryContent = await fs.readFile(summaryPath, 'utf-8');
      summary = JSON.parse(summaryContent);
    } catch {
      return NextResponse.json({ error: 'Pipeline summary not found' }, { status: 404 });
    }

    const feedback = await readFeedbackSummary(pipelineInfo.path);

    // List all files in the pipeline directory
    const allFiles = await listFiles(pipelineInfo.path, pipelineInfo.path, pipelineId);

    // Filter to only include crosstabs.xlsx as output and input files from inputs/ folder
    const files = allFiles.filter(f => {
      // Only show crosstabs.xlsx as output
      if (f.type === 'output') {
        return f.name === 'crosstabs.xlsx';
      }
      // Show input files from inputs/ folder
      if (f.type === 'input' && f.path.startsWith('inputs/')) {
        return true;
      }
      return false;
    });

    // Sort files: outputs first, then inputs
    files.sort((a, b) => {
      const typeOrder = { output: 0, input: 1, intermediate: 2 };
      return typeOrder[a.type] - typeOrder[b.type];
    });

    // Tables count can be in different fields depending on pipeline source
    const tablesCount = summary.outputs?.tables
      || summary.outputs?.verifiedTables
      || summary.outputs?.tableAgentTables
      || 0;

    // Map internal status to display status
    const rawStatus: string = summary.status || 'success';
    let displayStatus: 'success' | 'partial' | 'error' | 'in_progress' | 'pending_review' | 'cancelled' | 'awaiting_tables';
    if (rawStatus === 'resuming') {
      displayStatus = 'in_progress';
    } else if (rawStatus === 'success' || rawStatus === 'partial' || rawStatus === 'error' || rawStatus === 'in_progress' || rawStatus === 'pending_review' || rawStatus === 'cancelled' || rawStatus === 'awaiting_tables') {
      displayStatus = rawStatus;
    } else {
      displayStatus = 'success';
    }

    // Determine duration display
    const isActive = displayStatus === 'in_progress' || displayStatus === 'pending_review' || displayStatus === 'awaiting_tables';
    const isCancelled = displayStatus === 'cancelled';
    let durationFormatted: string;
    if (isActive) {
      durationFormatted = 'Processing...';
    } else if (isCancelled) {
      durationFormatted = 'Cancelled';
    } else {
      durationFormatted = summary.duration?.ms ? formatDuration(summary.duration.ms) : (summary.duration?.formatted || 'Unknown');
    }

    const details: PipelineDetails = {
      pipelineId: summary.pipelineId || pipelineId,
      dataset: summary.dataset || pipelineInfo.dataset,
      timestamp: summary.timestamp,
      duration: {
        ms: summary.duration?.ms || 0,
        formatted: durationFormatted,
      },
      status: displayStatus,
      currentStage: summary.currentStage,
      inputs: summary.inputs || {
        datamap: '',
        banner: '',
        spss: '',
        survey: null,
      },
      outputs: {
        variables: summary.outputs?.variables || 0,
        tables: tablesCount,
        cuts: summary.outputs?.cuts || 0,
        bannerGroups: summary.outputs?.bannerGroups || 0,
      },
      files,
      feedback,
    };

    // Add review info for pending_review status
    if (displayStatus === 'pending_review' && summary.review) {
      details.review = {
        flaggedColumnCount: summary.review.flaggedColumnCount || 0,
        reviewUrl: summary.review.reviewUrl || `/projects/${encodeURIComponent(pipelineId)}/review`,
      };
    }

    return NextResponse.json(details);
  } catch (error) {
    console.error('[Pipeline Details] Error:', error);
    return NextResponse.json(
      { error: 'Failed to get pipeline details', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
