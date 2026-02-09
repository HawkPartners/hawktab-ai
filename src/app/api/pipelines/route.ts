/**
 * GET /api/pipelines
 * Purpose: List all pipeline runs across all datasets
 * Reads: outputs/{dataset}/pipeline-{timestamp}/pipeline-summary.json
 * Returns: Array of pipeline summaries sorted by timestamp (newest first)
 */
import { NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { formatDuration } from '@/lib/utils/formatDuration';

export interface PipelineListItem {
  pipelineId: string;
  dataset: string;
  timestamp: string;
  duration: string;
  status: 'success' | 'partial' | 'error' | 'in_progress' | 'pending_review' | 'cancelled' | 'awaiting_tables';
  tables: number;
  cuts: number;
  variables: number;
  bannerGroups: number;
  hasExcel: boolean;
  hasFeedback: boolean;
  inputs: {
    datamap: string;
    banner: string;
    spss: string;
    survey: string | null;
  };
  reviewUrl?: string;
  flaggedColumnCount?: number;
}

export async function GET() {
  try {
    const outputsDir = path.join(process.cwd(), 'outputs');

    // Check if outputs directory exists
    try {
      await fs.access(outputsDir);
    } catch {
      // No outputs directory yet
      return NextResponse.json({ pipelines: [] });
    }

    const pipelines: PipelineListItem[] = [];

    // Read all dataset directories
    const datasetDirs = await fs.readdir(outputsDir);

    for (const dataset of datasetDirs) {
      const datasetPath = path.join(outputsDir, dataset);
      const stat = await fs.stat(datasetPath);

      if (!stat.isDirectory()) continue;

      // Read all pipeline directories within the dataset
      const pipelineDirs = await fs.readdir(datasetPath);

      for (const pipelineDir of pipelineDirs) {
        if (!pipelineDir.startsWith('pipeline-')) continue;

        const pipelinePath = path.join(datasetPath, pipelineDir);
        const pipelineStat = await fs.stat(pipelinePath);

        if (!pipelineStat.isDirectory()) continue;

        // Try to read pipeline-summary.json
        const summaryPath = path.join(pipelinePath, 'pipeline-summary.json');
        try {
          const summaryContent = await fs.readFile(summaryPath, 'utf-8');
          const summary = JSON.parse(summaryContent);

          // Check if Excel file exists
          const excelPath = path.join(pipelinePath, 'results', 'crosstabs.xlsx');
          let hasExcel = false;
          try {
            await fs.access(excelPath);
            hasExcel = true;
          } catch {
            // No Excel file
          }

          // Check if feedback exists
          const feedbackPath = path.join(pipelinePath, 'feedback.json');
          let hasFeedback = false;
          try {
            await fs.access(feedbackPath);
            hasFeedback = true;
          } catch {
            // No feedback
          }

          // Only show UI-created pipelines in the sidebar (skip test script runs)
          if (summary.source !== 'ui') {
            continue;
          }

          // Map internal status to display status
          const rawStatus: string = summary.status || 'success';
          let displayStatus: 'success' | 'partial' | 'error' | 'in_progress' | 'pending_review' | 'cancelled' | 'awaiting_tables';
          if (rawStatus === 'resuming') {
            displayStatus = 'in_progress';
          } else if (rawStatus === 'success' || rawStatus === 'partial' || rawStatus === 'error' || rawStatus === 'in_progress' || rawStatus === 'pending_review' || rawStatus === 'cancelled' || rawStatus === 'awaiting_tables') {
            displayStatus = rawStatus;
          } else {
            displayStatus = 'success'; // Default fallback
          }

          // Tables count can be in different fields depending on pipeline source
          const tablesCount = summary.outputs?.tables
            || summary.outputs?.verifiedTables
            || summary.outputs?.tableAgentTables
            || 0;

          const pipelineItem: PipelineListItem = {
            pipelineId: summary.pipelineId || pipelineDir,
            dataset: summary.dataset || dataset,
            timestamp: summary.timestamp,
            duration: summary.duration?.ms ? formatDuration(summary.duration.ms) : (summary.duration?.formatted || 'Unknown'),
            status: displayStatus,
            tables: tablesCount,
            cuts: summary.outputs?.cuts || 0,
            variables: summary.outputs?.variables || 0,
            bannerGroups: summary.outputs?.bannerGroups || 0,
            hasExcel,
            hasFeedback,
            inputs: {
              datamap: summary.inputs?.datamap || '',
              banner: summary.inputs?.banner || '',
              spss: summary.inputs?.spss || '',
              survey: summary.inputs?.survey || null,
            },
          };

          // Add review info for pending_review pipelines
          if (displayStatus === 'pending_review' && summary.review) {
            pipelineItem.reviewUrl = summary.review.reviewUrl;
            pipelineItem.flaggedColumnCount = summary.review.flaggedColumnCount;
          }

          pipelines.push(pipelineItem);
        } catch {
          // Skip pipelines without valid summary
          console.warn(`[Pipelines API] Skipping ${pipelineDir}: no valid summary`);
        }
      }
    }

    // Sort by timestamp (newest first)
    pipelines.sort((a, b) => {
      const dateA = new Date(a.timestamp).getTime();
      const dateB = new Date(b.timestamp).getTime();
      return dateB - dateA;
    });

    return NextResponse.json({ pipelines });
  } catch (error) {
    console.error('[Pipelines API] Error listing pipelines:', error);
    return NextResponse.json(
      { error: 'Failed to list pipelines', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
