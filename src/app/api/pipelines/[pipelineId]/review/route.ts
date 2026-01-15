/**
 * Review API for Human-in-the-Loop Banner Review
 *
 * GET /api/pipelines/[pipelineId]/review
 * - Returns banner-review-state.json for the pipeline
 * - Used by review UI to display flagged columns
 *
 * POST /api/pipelines/[pipelineId]/review
 * - Accepts review decisions (approve/edit/skip per column)
 * - Resumes pipeline: runs CrosstabAgent with approved banner
 * - Completes pipeline: generates R script and Excel output
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import { processAllGroups as processCrosstabGroups } from '@/agents/CrosstabAgent';
import { buildCutsSpec } from '@/lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '@/lib/tables/sortTables';
import { generateRScriptV2WithValidation } from '@/lib/r/RScriptGeneratorV2';
import { ExcelFormatter } from '@/lib/excel/ExcelFormatter';
import type { BannerProcessingResult } from '@/agents/BannerAgent';
import type { ExtendedTableDefinition } from '@/schemas/verificationAgentSchema';
import type { TableAgentOutput } from '@/schemas/tableAgentSchema';

const execAsync = promisify(exec);

// -------------------------------------------------------------------------
// Types
// -------------------------------------------------------------------------

interface FlaggedColumn {
  groupName: string;
  columnName: string;
  original: string;
  adjusted: string;
  confidence: number;
  uncertainties: string[];
  requiresInference: boolean;
  inferenceReason: string;
  humanInLoopRequired: boolean;
}

interface AgentDataMapItem {
  Column: string;
  Description: string;
  Answer_Options: string;
}

interface PathBResult {
  tableAgentResults: TableAgentOutput[];
  verifiedTables: ExtendedTableDefinition[];
}

interface BannerReviewState {
  pipelineId: string;
  status: 'awaiting_review' | 'approved' | 'cancelled';
  createdAt: string;
  bannerResult: BannerProcessingResult;
  flaggedColumns: FlaggedColumn[];
  agentDataMap: AgentDataMapItem[];
  outputDir: string;
  pathBStatus: 'running' | 'completed' | 'error';
  pathBResult?: PathBResult;
  pathBError?: string;
  decisions?: ReviewDecision[];
}

interface ReviewDecision {
  groupName: string;
  columnName: string;
  action: 'approve' | 'edit' | 'skip';
  editedValue?: string;
}

interface ReviewRequest {
  decisions: ReviewDecision[];
}

type PipelineStatus = 'in_progress' | 'pending_review' | 'resuming' | 'success' | 'partial' | 'error' | 'cancelled';

interface PipelineSummary {
  pipelineId: string;
  dataset: string;
  timestamp: string;
  source: 'ui' | 'cli';
  status: PipelineStatus;
  currentStage?: string;
  inputs: {
    datamap: string;
    banner: string;
    spss: string;
    survey: string | null;
  };
  duration?: {
    ms: number;
    formatted: string;
  };
  outputs?: Record<string, unknown>;
  error?: string;
  review?: {
    flaggedColumnCount: number;
    reviewUrl: string;
    decisions?: ReviewDecision[];
    completedAt?: string;
  };
}

// -------------------------------------------------------------------------
// Helper Functions
// -------------------------------------------------------------------------

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
 * Update pipeline summary with partial updates
 */
async function updatePipelineSummary(
  outputDir: string,
  updates: Partial<PipelineSummary>
): Promise<void> {
  const summaryPath = path.join(outputDir, 'pipeline-summary.json');
  try {
    const existing = JSON.parse(await fs.readFile(summaryPath, 'utf-8')) as PipelineSummary;
    const updated = { ...existing, ...updates };
    await fs.writeFile(summaryPath, JSON.stringify(updated, null, 2));
  } catch {
    console.warn('[Review API] Could not update pipeline summary');
  }
}

/**
 * Apply review decisions to banner result
 * Returns modified banner groups for CrosstabAgent
 */
function applyDecisions(
  bannerResult: BannerProcessingResult,
  decisions: ReviewDecision[]
): Array<{ groupName: string; columns: Array<{ name: string; original: string }> }> {
  const decisionMap = new Map<string, ReviewDecision>();
  for (const d of decisions) {
    decisionMap.set(`${d.groupName}/${d.columnName}`, d);
  }

  const agentBanner = bannerResult.agent || [];
  const modifiedGroups: Array<{ groupName: string; columns: Array<{ name: string; original: string }> }> = [];

  for (const group of agentBanner) {
    const modifiedColumns: Array<{ name: string; original: string }> = [];

    for (const col of group.columns) {
      const key = `${group.groupName}/${col.name}`;
      const decision = decisionMap.get(key);

      if (decision?.action === 'skip') {
        // Skip this column entirely
        console.log(`[Review] Skipping column: ${key}`);
        continue;
      }

      if (decision?.action === 'edit' && decision.editedValue) {
        // Use edited value
        console.log(`[Review] Edited column: ${key}`);
        modifiedColumns.push({
          name: col.name,
          original: decision.editedValue
        });
      } else {
        // Approve as-is (or no decision provided)
        modifiedColumns.push({
          name: col.name,
          original: col.original
        });
      }
    }

    if (modifiedColumns.length > 0) {
      modifiedGroups.push({
        groupName: group.groupName,
        columns: modifiedColumns
      });
    }
  }

  return modifiedGroups;
}

// -------------------------------------------------------------------------
// GET Handler - Fetch review state
// -------------------------------------------------------------------------

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  try {
    const { pipelineId } = await params;

    if (!pipelineId) {
      return NextResponse.json({ error: 'Pipeline ID is required' }, { status: 400 });
    }

    // Validate pipelineId format
    if (!pipelineId.startsWith('pipeline-') || pipelineId.includes('..')) {
      return NextResponse.json({ error: 'Invalid pipeline ID format' }, { status: 400 });
    }

    // Find pipeline directory
    const pipelineInfo = await findPipelineDir(pipelineId);
    if (!pipelineInfo) {
      return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });
    }

    // Read review state
    const reviewStatePath = path.join(pipelineInfo.path, 'banner-review-state.json');
    try {
      const reviewState = JSON.parse(await fs.readFile(reviewStatePath, 'utf-8')) as BannerReviewState;
      return NextResponse.json({
        pipelineId: reviewState.pipelineId,
        status: reviewState.status,
        createdAt: reviewState.createdAt,
        flaggedColumns: reviewState.flaggedColumns,
        pathBStatus: reviewState.pathBStatus,
        totalColumns: reviewState.bannerResult.agent?.reduce(
          (sum, g) => sum + g.columns.length, 0
        ) || 0,
        decisions: reviewState.decisions || []
      });
    } catch {
      return NextResponse.json(
        { error: 'Review state not found - pipeline may not require review' },
        { status: 404 }
      );
    }
  } catch (error) {
    console.error('[Review API GET] Error:', error);
    return NextResponse.json(
      { error: 'Failed to get review state', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}

// -------------------------------------------------------------------------
// POST Handler - Submit review decisions and resume pipeline
// -------------------------------------------------------------------------

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ pipelineId: string }> }
) {
  const resumeStartTime = Date.now();

  try {
    const { pipelineId } = await params;

    if (!pipelineId) {
      return NextResponse.json({ error: 'Pipeline ID is required' }, { status: 400 });
    }

    // Validate pipelineId format
    if (!pipelineId.startsWith('pipeline-') || pipelineId.includes('..')) {
      return NextResponse.json({ error: 'Invalid pipeline ID format' }, { status: 400 });
    }

    // Parse request body
    const body = await request.json() as ReviewRequest;
    const { decisions } = body;

    if (!decisions || !Array.isArray(decisions)) {
      return NextResponse.json({ error: 'Decisions array is required' }, { status: 400 });
    }

    // Find pipeline directory
    const pipelineInfo = await findPipelineDir(pipelineId);
    if (!pipelineInfo) {
      return NextResponse.json({ error: 'Pipeline not found' }, { status: 404 });
    }

    const outputDir = pipelineInfo.path;

    // Read review state
    const reviewStatePath = path.join(outputDir, 'banner-review-state.json');
    let reviewState: BannerReviewState;
    try {
      reviewState = JSON.parse(await fs.readFile(reviewStatePath, 'utf-8'));
    } catch {
      return NextResponse.json(
        { error: 'Review state not found - pipeline may not require review' },
        { status: 404 }
      );
    }

    // Check state is awaiting review
    if (reviewState.status !== 'awaiting_review') {
      return NextResponse.json(
        { error: `Cannot submit review - pipeline status is ${reviewState.status}` },
        { status: 400 }
      );
    }

    // Update pipeline summary to resuming
    await updatePipelineSummary(outputDir, {
      status: 'resuming',
      currentStage: 'crosstab_agent'
    });

    console.log(`[Review API] Resuming pipeline ${pipelineId} with ${decisions.length} decisions`);

    // Save decisions to review state
    reviewState.status = 'approved';
    reviewState.decisions = decisions;
    await fs.writeFile(reviewStatePath, JSON.stringify(reviewState, null, 2));

    // Apply decisions to banner and run CrosstabAgent
    const modifiedBanner = applyDecisions(reviewState.bannerResult, decisions);
    console.log(`[Review API] Modified banner: ${modifiedBanner.length} groups`);

    const crosstabResult = await processCrosstabGroups(
      reviewState.agentDataMap,
      { bannerCuts: modifiedBanner },
      outputDir,
      (completed, total) => {
        console.log(`[Review API] CrosstabAgent progress: ${completed}/${total}`);
      }
    );

    console.log(`[Review API] CrosstabAgent complete: ${crosstabResult.result.bannerCuts.length} groups validated`);

    // Get Path B results
    if (!reviewState.pathBResult) {
      return NextResponse.json(
        { error: 'Path B results not found in review state' },
        { status: 500 }
      );
    }

    const { verifiedTables } = reviewState.pathBResult;

    // Sort tables
    const sortingMetadata = getSortingMetadata(verifiedTables);
    const sortedTables = sortTables(verifiedTables);
    console.log(`[Review API] Sorted tables: ${sortedTables.length} (screeners: ${sortingMetadata.screenerCount})`);

    // Generate R script
    const cutsSpec = buildCutsSpec(crosstabResult.result);
    const rDir = path.join(outputDir, 'r');
    await fs.mkdir(rDir, { recursive: true });

    const { script: masterScript, validation: validationReport } = generateRScriptV2WithValidation(
      { tables: sortedTables, cuts: cutsSpec.cuts },
      { sessionId: pipelineId, outputDir: 'results' }
    );

    const masterPath = path.join(rDir, 'master.R');
    await fs.writeFile(masterPath, masterScript, 'utf-8');
    console.log(`[Review API] Generated R script (${Math.round(masterScript.length / 1024)} KB)`);

    // Save validation report if there were issues
    if (validationReport.invalidTables > 0 || validationReport.warnings.length > 0) {
      await fs.writeFile(
        path.join(rDir, 'validation-report.json'),
        JSON.stringify(validationReport, null, 2)
      );
    }

    // Execute R script
    const resultsDir = path.join(outputDir, 'results');
    await fs.mkdir(resultsDir, { recursive: true });

    // Find R
    let rCommand = 'Rscript';
    const rPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
    for (const rPath of rPaths) {
      try {
        await execAsync(`${rPath} --version`, { timeout: 1000 });
        rCommand = rPath;
        break;
      } catch {
        // Try next
      }
    }

    let rExecutionSuccess = false;
    let excelGenerated = false;

    // Copy SPSS file for R execution (it may have been cleaned up)
    const inputsDir = path.join(outputDir, 'inputs');
    try {
      const inputFiles = await fs.readdir(inputsDir);
      const spssFile = inputFiles.find(f => f.endsWith('.sav'));
      if (spssFile) {
        const spssSource = path.join(inputsDir, spssFile);
        const spssDest = path.join(outputDir, 'dataFile.sav');
        await fs.copyFile(spssSource, spssDest);
      }
    } catch {
      console.warn('[Review API] Could not copy SPSS file - R may fail');
    }

    try {
      await execAsync(
        `cd "${outputDir}" && ${rCommand} "${masterPath}"`,
        { maxBuffer: 10 * 1024 * 1024, timeout: 120000 }
      );

      const resultFiles = await fs.readdir(resultsDir);
      if (resultFiles.includes('tables.json')) {
        console.log('[Review API] R execution successful');
        rExecutionSuccess = true;

        // Generate Excel
        const tablesJsonPath = path.join(resultsDir, 'tables.json');
        const excelPath = path.join(resultsDir, 'crosstabs.xlsx');

        try {
          const formatter = new ExcelFormatter();
          await formatter.formatFromFile(tablesJsonPath);
          await formatter.saveToFile(excelPath);
          excelGenerated = true;
          console.log('[Review API] Excel generated successfully');
        } catch (excelError) {
          console.error('[Review API] Excel generation failed:', excelError);
        }
      }
    } catch (rError) {
      const errorMsg = rError instanceof Error ? rError.message : String(rError);
      console.error('[Review API] R execution failed:', errorMsg.substring(0, 200));
    }

    // Cleanup
    try {
      await fs.unlink(path.join(outputDir, 'dataFile.sav'));
    } catch { /* May not exist */ }

    // Calculate duration
    const resumeDuration = Date.now() - resumeStartTime;

    // Update pipeline summary
    const finalStatus = excelGenerated ? 'success' : (rExecutionSuccess ? 'partial' : 'error');
    await updatePipelineSummary(outputDir, {
      status: finalStatus,
      currentStage: undefined,
      review: {
        flaggedColumnCount: reviewState.flaggedColumns.length,
        reviewUrl: `/pipelines/${pipelineId}/review`,
        decisions,
        completedAt: new Date().toISOString()
      },
      outputs: {
        variables: 0, // Would need to recalculate
        tableAgentTables: reviewState.pathBResult.tableAgentResults.flatMap(r => r.tables).length,
        verifiedTables: sortedTables.length,
        tables: sortedTables.length,
        cuts: cutsSpec.cuts.length,
        bannerGroups: crosstabResult.result.bannerCuts.length,
        sorting: {
          screeners: sortingMetadata.screenerCount,
          main: sortingMetadata.mainCount,
          other: sortingMetadata.otherCount
        }
      }
    });

    console.log(`[Review API] Pipeline resumed and completed in ${(resumeDuration / 1000).toFixed(1)}s`);

    return NextResponse.json({
      success: true,
      pipelineId,
      status: finalStatus,
      duration: {
        ms: resumeDuration,
        formatted: `${(resumeDuration / 1000).toFixed(1)}s`
      },
      outputs: {
        tables: sortedTables.length,
        cuts: cutsSpec.cuts.length,
        excelGenerated,
        downloadUrl: excelGenerated
          ? `/api/pipelines/${encodeURIComponent(pipelineId)}/files/results/crosstabs.xlsx`
          : undefined
      }
    });

  } catch (error) {
    console.error('[Review API POST] Error:', error);
    return NextResponse.json(
      { error: 'Failed to process review', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
