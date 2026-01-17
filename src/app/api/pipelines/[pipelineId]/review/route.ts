/**
 * Review API for Human-in-the-Loop CrosstabAgent Review
 *
 * GET /api/pipelines/[pipelineId]/review
 * - Returns crosstab-review-state.json for the pipeline
 * - Shows flagged columns with mapping details (proposed R, alternatives, etc.)
 *
 * POST /api/pipelines/[pipelineId]/review
 * - Accepts review decisions (approve/select_alternative/provide_hint/edit/skip per column)
 * - Applies decisions to crosstab result
 * - Completes pipeline: generates R script and Excel output
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import { processGroup } from '@/agents/CrosstabAgent';
import { buildCutsSpec } from '@/lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '@/lib/tables/sortTables';
import { generateRScriptV2WithValidation } from '@/lib/r/RScriptGeneratorV2';
import { ExcelFormatter } from '@/lib/excel/ExcelFormatter';
import { formatDuration } from '@/lib/utils/formatDuration';
import type { BannerProcessingResult } from '@/agents/BannerAgent';
import type { ExtendedTableDefinition } from '@/schemas/verificationAgentSchema';
import type { TableAgentOutput } from '@/schemas/tableAgentSchema';
import type { ValidationResultType, ValidatedGroupType } from '@/schemas/agentOutputSchema';

const execAsync = promisify(exec);

// -------------------------------------------------------------------------
// Types
// -------------------------------------------------------------------------

interface FlaggedCrosstabColumn {
  groupName: string;
  columnName: string;
  original: string;
  proposed: string;
  confidence: number;
  reason: string;
  alternatives: Array<{
    expression: string;
    confidence: number;
    reason: string;
  }>;
  uncertainties: string[];
  expressionType?: string;
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

interface CrosstabReviewState {
  pipelineId: string;
  status: 'awaiting_review' | 'approved' | 'cancelled';
  createdAt: string;
  crosstabResult: ValidationResultType;
  flaggedColumns: FlaggedCrosstabColumn[];
  bannerResult: BannerProcessingResult;
  agentDataMap: AgentDataMapItem[];
  outputDir: string;
  pathBStatus: 'completed';
  pathBResult: PathBResult;
  decisions?: CrosstabDecision[];
}

interface CrosstabDecision {
  groupName: string;
  columnName: string;
  action: 'approve' | 'select_alternative' | 'provide_hint' | 'edit' | 'skip';
  selectedAlternative?: number;  // Index into alternatives[]
  hint?: string;                 // For re-run
  editedExpression?: string;     // Direct edit
}

interface ReviewRequest {
  decisions: CrosstabDecision[];
}

type PipelineStatus = 'in_progress' | 'pending_review' | 'resuming' | 'awaiting_tables' | 'success' | 'partial' | 'error' | 'cancelled';

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
    decisions?: CrosstabDecision[];
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
 * Apply review decisions to crosstab result
 * Returns modified ValidationResultType with user's decisions applied
 */
async function applyDecisions(
  crosstabResult: ValidationResultType,
  flaggedColumns: FlaggedCrosstabColumn[],
  decisions: CrosstabDecision[],
  agentDataMap: AgentDataMapItem[],
  outputDir: string
): Promise<ValidationResultType> {
  // Build decision lookup
  const decisionMap = new Map<string, CrosstabDecision>();
  for (const d of decisions) {
    decisionMap.set(`${d.groupName}::${d.columnName}`, d);
  }

  // Build flagged column lookup for alternatives
  const flaggedMap = new Map<string, FlaggedCrosstabColumn>();
  for (const f of flaggedColumns) {
    flaggedMap.set(`${f.groupName}::${f.columnName}`, f);
  }

  const modifiedGroups: ValidatedGroupType[] = [];

  for (const group of crosstabResult.bannerCuts) {
    const modifiedColumns = [];

    for (const col of group.columns) {
      const key = `${group.groupName}::${col.name}`;
      const decision = decisionMap.get(key);
      const flagged = flaggedMap.get(key);

      if (decision?.action === 'skip') {
        // Skip this column entirely
        console.log(`[Review] Skipping column: ${key}`);
        continue;
      }

      if (decision?.action === 'select_alternative' && decision.selectedAlternative !== undefined && flagged) {
        // Use selected alternative
        const alt = flagged.alternatives[decision.selectedAlternative];
        if (alt) {
          console.log(`[Review] Using alternative ${decision.selectedAlternative} for: ${key}`);
          modifiedColumns.push({
            ...col,
            adjusted: alt.expression,
            confidence: 1.0, // User approved
            reason: `User selected alternative: ${alt.reason}`,
            humanReviewRequired: false
          });
          continue;
        }
      }

      if (decision?.action === 'edit' && decision.editedExpression) {
        // Use user's edited expression
        console.log(`[Review] Using edited expression for: ${key}`);
        modifiedColumns.push({
          ...col,
          adjusted: decision.editedExpression,
          confidence: 1.0, // User provided
          reason: 'User edited expression directly',
          humanReviewRequired: false
        });
        continue;
      }

      if (decision?.action === 'provide_hint' && decision.hint && flagged) {
        // Re-run CrosstabAgent for this column with the hint
        console.log(`[Review] Re-running with hint for: ${key}`);
        try {
          const rerunResult = await processGroup(
            agentDataMap,
            {
              groupName: group.groupName,
              columns: [{ name: col.name, original: flagged.original }]
            },
            { hint: decision.hint, outputDir }
          );

          if (rerunResult.columns.length > 0) {
            const rerunCol = rerunResult.columns[0];
            // Auto-approve if high confidence (> 0.9)
            if (rerunCol.confidence > 0.9) {
              console.log(`[Review] Re-run successful with confidence ${rerunCol.confidence} - auto-approving`);
              modifiedColumns.push({
                ...rerunCol,
                confidence: 1.0, // User approved via hint
                reason: `Re-run with hint "${decision.hint}": ${rerunCol.reason}`,
                humanReviewRequired: false
              });
            } else {
              // Still uncertain - use the re-run result but note it
              console.log(`[Review] Re-run had confidence ${rerunCol.confidence} - using anyway`);
              modifiedColumns.push({
                ...rerunCol,
                reason: `Re-run with hint "${decision.hint}": ${rerunCol.reason}`,
                humanReviewRequired: false
              });
            }
            continue;
          }
        } catch (rerunError) {
          console.error(`[Review] Re-run failed for ${key}:`, rerunError);
          // Fall through to approve as-is
        }
      }

      // Default: approve as-is (or no decision provided for non-flagged columns)
      if (decision?.action === 'approve' || !decision) {
        modifiedColumns.push({
          ...col,
          confidence: decision ? 1.0 : col.confidence, // 1.0 if explicitly approved
          humanReviewRequired: false
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

  return { bannerCuts: modifiedGroups };
}

/**
 * Complete the pipeline after Path B is ready (fire-and-forget)
 * This function handles R script generation and Excel output
 */
async function completePipeline(
  outputDir: string,
  pipelineId: string,
  modifiedCrosstabResult: ValidationResultType,
  pathBResult: PathBResult,
  reviewState: CrosstabReviewState,
  decisions: CrosstabDecision[]
): Promise<void> {
  try {
    const { verifiedTables } = pathBResult;

    // Sort tables
    const sortingMetadata = getSortingMetadata(verifiedTables);
    const sortedTables = sortTables(verifiedTables);
    console.log(`[Review API] Sorted tables: ${sortedTables.length} (screeners: ${sortingMetadata.screenerCount})`);

    // Generate R script
    const cutsSpec = buildCutsSpec(modifiedCrosstabResult);
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

    // Calculate total duration from pipeline start
    const completionTime = new Date();
    let totalDurationMs = 0;
    try {
      const summaryPath = path.join(outputDir, 'pipeline-summary.json');
      const existingSummary = JSON.parse(await fs.readFile(summaryPath, 'utf-8')) as PipelineSummary;
      if (existingSummary.timestamp) {
        const startTime = new Date(existingSummary.timestamp).getTime();
        totalDurationMs = completionTime.getTime() - startTime;
      }
    } catch {
      // If we can't read the summary, we can't calculate duration
      console.warn('[Review API] Could not read summary for duration calculation');
    }

    // Update pipeline summary
    const finalStatus = excelGenerated ? 'success' : (rExecutionSuccess ? 'partial' : 'error');
    await updatePipelineSummary(outputDir, {
      status: finalStatus,
      currentStage: undefined,
      duration: totalDurationMs > 0 ? {
        ms: totalDurationMs,
        formatted: formatDuration(totalDurationMs)
      } : undefined,
      review: {
        flaggedColumnCount: reviewState.flaggedColumns.length,
        reviewUrl: `/pipelines/${pipelineId}/review`,
        decisions,
        completedAt: completionTime.toISOString()
      },
      outputs: {
        variables: 0,
        tableAgentTables: reviewState.pathBResult?.tableAgentResults?.flatMap(r => r.tables).length || 0,
        verifiedTables: sortedTables.length,
        tables: sortedTables.length,
        cuts: cutsSpec.cuts.length,
        bannerGroups: modifiedCrosstabResult.bannerCuts.length,
        sorting: {
          screeners: sortingMetadata.screenerCount,
          main: sortingMetadata.mainCount,
          other: sortingMetadata.otherCount
        }
      }
    });

    console.log(`[Review API] Pipeline completed in ${formatDuration(totalDurationMs)}`);
  } catch (error) {
    console.error('[Review API] Background completion failed:', error);
    await updatePipelineSummary(outputDir, {
      status: 'error',
      error: error instanceof Error ? error.message : 'Background completion failed'
    });
  }
}

/**
 * Wait for Path B to complete and then finish the pipeline
 * This is used when Path B is still running at review submission time
 */
async function waitAndCompletePipeline(
  outputDir: string,
  pipelineId: string,
  modifiedCrosstabResult: ValidationResultType,
  reviewState: CrosstabReviewState,
  decisions: CrosstabDecision[]
): Promise<void> {
  const pathBResultPath = path.join(outputDir, 'path-b-result.json');
  const pathBStatusPath = path.join(outputDir, 'path-b-status.json');

  const maxWaitMs = 1800000; // 30 minutes
  const pollIntervalMs = 5000; // 5 seconds
  const startTime = Date.now();

  console.log(`[Review API] Waiting for Path B to complete (up to 30 min)...`);

  while (Date.now() - startTime < maxWaitMs) {
    // Check for result file
    try {
      const pathBResult = JSON.parse(await fs.readFile(pathBResultPath, 'utf-8'));
      console.log('[Review API] Path B completed - starting pipeline completion');
      await completePipeline(outputDir, pipelineId, modifiedCrosstabResult, pathBResult, reviewState, decisions);
      return;
    } catch { /* not ready yet */ }

    // Check for error status
    try {
      const statusData = JSON.parse(await fs.readFile(pathBStatusPath, 'utf-8'));
      if (statusData.status === 'error') {
        console.error('[Review API] Path B failed:', statusData.error);
        await updatePipelineSummary(outputDir, {
          status: 'error',
          error: `Table processing failed: ${statusData.error}`
        });
        return;
      }
    } catch { /* status file may not exist yet */ }

    // Wait before next poll
    await new Promise(r => setTimeout(r, pollIntervalMs));
  }

  // Timed out
  console.error('[Review API] Timed out waiting for Path B (30 min)');
  await updatePipelineSummary(outputDir, {
    status: 'error',
    error: 'Timed out waiting for table processing to complete'
  });
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

    // Try crosstab review state first (new), then banner review state (legacy)
    const crosstabReviewStatePath = path.join(pipelineInfo.path, 'crosstab-review-state.json');
    const bannerReviewStatePath = path.join(pipelineInfo.path, 'banner-review-state.json');

    // Check for crosstab review state (preferred)
    try {
      const reviewState = JSON.parse(await fs.readFile(crosstabReviewStatePath, 'utf-8')) as CrosstabReviewState;

      // Read real-time Path B status from disk (may have updated since review state was written)
      let pathBStatus: 'running' | 'completed' | 'error' = reviewState.pathBStatus;
      const pathBStatusPath = path.join(pipelineInfo.path, 'path-b-status.json');
      try {
        const statusData = JSON.parse(await fs.readFile(pathBStatusPath, 'utf-8'));
        pathBStatus = statusData.status;
      } catch {
        // Status file not found - use value from review state
      }

      return NextResponse.json({
        reviewType: 'crosstab',
        pipelineId: reviewState.pipelineId,
        status: reviewState.status,
        createdAt: reviewState.createdAt,
        flaggedColumns: reviewState.flaggedColumns,
        pathBStatus, // Real-time status from path-b-status.json
        totalColumns: reviewState.crosstabResult.bannerCuts.reduce(
          (sum, g) => sum + g.columns.length, 0
        ),
        decisions: reviewState.decisions || []
      });
    } catch {
      // No crosstab review state, try banner (legacy)
    }

    // Check for banner review state (legacy)
    try {
      const bannerReviewState = JSON.parse(await fs.readFile(bannerReviewStatePath, 'utf-8'));
      return NextResponse.json({
        reviewType: 'banner',
        pipelineId: bannerReviewState.pipelineId,
        status: bannerReviewState.status,
        createdAt: bannerReviewState.createdAt,
        flaggedColumns: bannerReviewState.flaggedColumns,
        pathBStatus: bannerReviewState.pathBStatus,
        totalColumns: bannerReviewState.bannerResult?.agent?.reduce(
          (sum: number, g: { columns: unknown[] }) => sum + g.columns.length, 0
        ) || 0,
        decisions: bannerReviewState.decisions || []
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
    const reviewStatePath = path.join(outputDir, 'crosstab-review-state.json');
    let reviewState: CrosstabReviewState;
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

    console.log(`[Review API] Processing review for ${pipelineId} with ${decisions.length} decisions`);

    // Save decisions to review state immediately
    reviewState.status = 'approved';
    reviewState.decisions = decisions;
    await fs.writeFile(reviewStatePath, JSON.stringify(reviewState, null, 2));

    // Apply decisions to crosstab result
    const modifiedCrosstabResult = await applyDecisions(
      reviewState.crosstabResult,
      reviewState.flaggedColumns,
      decisions,
      reviewState.agentDataMap,
      outputDir
    );

    const totalColumns = modifiedCrosstabResult.bannerCuts.reduce((sum, g) => sum + g.columns.length, 0);
    console.log(`[Review API] Applied decisions: ${modifiedCrosstabResult.bannerCuts.length} groups, ${totalColumns} columns`);

    // Check if Path B is complete
    const pathBResultPath = path.join(outputDir, 'path-b-result.json');
    let pathBResult: PathBResult | null = reviewState.pathBResult;

    if (!pathBResult) {
      // Try to load from disk
      try {
        pathBResult = JSON.parse(await fs.readFile(pathBResultPath, 'utf-8'));
        console.log('[Review API] Path B result loaded from disk');
      } catch {
        // Path B still running
        pathBResult = null;
      }
    }

    if (pathBResult) {
      // Path B is complete - finish pipeline synchronously
      await updatePipelineSummary(outputDir, {
        status: 'resuming',
        currentStage: 'generating_output'
      });

      await completePipeline(outputDir, pipelineId, modifiedCrosstabResult, pathBResult, reviewState, decisions);

      // Read final status
      const summaryPath = path.join(outputDir, 'pipeline-summary.json');
      const summary = JSON.parse(await fs.readFile(summaryPath, 'utf-8'));

      return NextResponse.json({
        success: true,
        pipelineId,
        status: summary.status,
        message: 'Pipeline completed successfully'
      });
    } else {
      // Path B still running - return immediately and complete in background
      console.log('[Review API] Path B still running - returning immediately, will complete in background');

      await updatePipelineSummary(outputDir, {
        status: 'awaiting_tables',
        currentStage: 'waiting_for_tables',
        review: {
          flaggedColumnCount: reviewState.flaggedColumns.length,
          reviewUrl: `/pipelines/${pipelineId}/review`,
          decisions
        }
      });

      // Fire-and-forget: Start background completion
      // Note: In serverless environments, this may be terminated after response is sent
      // But for local/long-running servers, it will continue
      waitAndCompletePipeline(outputDir, pipelineId, modifiedCrosstabResult, reviewState, decisions)
        .catch(err => console.error('[Review API] Background completion error:', err));

      return NextResponse.json({
        success: true,
        pipelineId,
        status: 'awaiting_tables',
        message: 'Review saved. Pipeline will complete when table processing finishes.'
      });
    }

  } catch (error) {
    console.error('[Review API POST] Error:', error);
    return NextResponse.json(
      { error: 'Failed to process review', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
