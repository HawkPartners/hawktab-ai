/**
 * Shared review completion logic.
 * Extracted from the old /api/pipelines/[pipelineId]/review route so that
 * both the new /api/runs/[runId]/review route and any future callers can
 * reuse it without duplication.
 */
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
import type { TableWithLoopFrame } from '@/schemas/verificationAgentSchema';
import type { TableAgentOutput } from '@/schemas/tableAgentSchema';
import type { ValidationResultType, ValidatedGroupType } from '@/schemas/agentOutputSchema';
import type { FlaggedCrosstabColumn, AgentDataMapItem, PathBResult } from './types';

const execAsync = promisify(exec);

// -------------------------------------------------------------------------
// Types
// -------------------------------------------------------------------------

export interface CrosstabDecision {
  groupName: string;
  columnName: string;
  action: 'approve' | 'select_alternative' | 'provide_hint' | 'edit' | 'skip';
  selectedAlternative?: number;
  hint?: string;
  editedExpression?: string;
}

export interface ReviewState {
  pipelineId: string;
  status: 'awaiting_review' | 'approved' | 'cancelled';
  createdAt: string;
  crosstabResult: ValidationResultType;
  flaggedColumns: FlaggedCrosstabColumn[];
  agentDataMap: AgentDataMapItem[];
  outputDir: string;
  pathBStatus: 'running' | 'completed' | 'error';
  pathBResult: PathBResult | null;
  decisions?: CrosstabDecision[];
}

interface PipelineSummary {
  pipelineId: string;
  dataset: string;
  timestamp: string;
  source: 'ui' | 'cli';
  status: string;
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
  review?: Record<string, unknown>;
}

// -------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------

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
    console.warn('[ReviewCompletion] Could not update pipeline summary');
  }
}

/**
 * Find a pipeline directory by pipelineId across all datasets.
 */
export async function findPipelineDir(pipelineId: string): Promise<{ path: string; dataset: string } | null> {
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

// -------------------------------------------------------------------------
// Apply Decisions
// -------------------------------------------------------------------------

/**
 * Apply review decisions to crosstab result.
 * Returns modified ValidationResultType with user's decisions applied.
 */
export async function applyDecisions(
  crosstabResult: ValidationResultType,
  flaggedColumns: FlaggedCrosstabColumn[],
  decisions: CrosstabDecision[],
  agentDataMap: AgentDataMapItem[],
  outputDir: string
): Promise<ValidationResultType> {
  const decisionMap = new Map<string, CrosstabDecision>();
  for (const d of decisions) {
    decisionMap.set(`${d.groupName}::${d.columnName}`, d);
  }

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
        console.log(`[Review] Skipping column: ${key}`);
        continue;
      }

      if (decision?.action === 'select_alternative' && decision.selectedAlternative !== undefined && flagged) {
        const alt = flagged.alternatives[decision.selectedAlternative];
        if (alt) {
          console.log(`[Review] Using alternative ${decision.selectedAlternative} for: ${key}`);
          modifiedColumns.push({
            ...col,
            adjusted: alt.expression,
            confidence: 1.0,
            reason: `User selected alternative: ${alt.userSummary}`,
            humanReviewRequired: false
          });
          continue;
        }
      }

      if (decision?.action === 'edit' && decision.editedExpression) {
        console.log(`[Review] Using edited expression for: ${key}`);
        modifiedColumns.push({
          ...col,
          adjusted: decision.editedExpression,
          confidence: 1.0,
          reason: 'User edited expression directly',
          humanReviewRequired: false
        });
        continue;
      }

      if (decision?.action === 'provide_hint' && decision.hint && flagged) {
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
            if (rerunCol.confidence > 0.9) {
              console.log(`[Review] Re-run successful with confidence ${rerunCol.confidence} - auto-approving`);
              modifiedColumns.push({
                ...rerunCol,
                confidence: 1.0,
                reasoning: `Re-run with hint "${decision.hint}": ${rerunCol.reasoning}`,
              });
            } else {
              console.log(`[Review] Re-run had confidence ${rerunCol.confidence} - using anyway`);
              modifiedColumns.push({
                ...rerunCol,
                reasoning: `Re-run with hint "${decision.hint}": ${rerunCol.reasoning}`,
              });
            }
            continue;
          }
        } catch (rerunError) {
          console.error(`[Review] Re-run failed for ${key}:`, rerunError);
          // Fall through to approve as-is
        }
      }

      // Default: approve as-is
      if (decision?.action === 'approve' || !decision) {
        modifiedColumns.push({
          ...col,
          confidence: decision ? 1.0 : col.confidence,
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

// -------------------------------------------------------------------------
// Complete Pipeline
// -------------------------------------------------------------------------

export interface CompletePipelineResult {
  success: boolean;
  status: 'success' | 'partial' | 'error';
  message: string;
  outputDir: string;
}

/**
 * Complete the pipeline after review decisions are applied and Path B is ready.
 * Handles R script generation, R execution, and Excel output.
 */
export async function completePipeline(
  outputDir: string,
  pipelineId: string,
  modifiedCrosstabResult: ValidationResultType,
  pathBResult: PathBResult,
  reviewState: ReviewState,
  decisions: CrosstabDecision[]
): Promise<CompletePipelineResult> {
  try {
    const { verifiedTables } = pathBResult;

    // Sort tables
    const sortingMetadata = getSortingMetadata(verifiedTables);
    const sortedTables = sortTables(verifiedTables);
    console.log(`[ReviewCompletion] Sorted tables: ${sortedTables.length} (screeners: ${sortingMetadata.screenerCount})`);

    // Generate R script
    const cutsSpec = buildCutsSpec(modifiedCrosstabResult);
    const rDir = path.join(outputDir, 'r');
    await fs.mkdir(rDir, { recursive: true });

    const tablesForR: TableWithLoopFrame[] = sortedTables.map(t => ({ ...t, loopDataFrame: '' }));
    const { script: masterScript, validation: validationReport } = generateRScriptV2WithValidation(
      { tables: tablesForR, cuts: cutsSpec.cuts },
      { sessionId: pipelineId, outputDir: 'results' }
    );

    const masterPath = path.join(rDir, 'master.R');
    await fs.writeFile(masterPath, masterScript, 'utf-8');
    console.log(`[ReviewCompletion] Generated R script (${Math.round(masterScript.length / 1024)} KB)`);

    if (validationReport.invalidTables > 0 || validationReport.warnings.length > 0) {
      await fs.writeFile(
        path.join(rDir, 'validation-report.json'),
        JSON.stringify(validationReport, null, 2)
      );
    }

    // Execute R script
    const resultsDir = path.join(outputDir, 'results');
    await fs.mkdir(resultsDir, { recursive: true });

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

    // Copy SPSS file for R execution
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
      console.warn('[ReviewCompletion] Could not copy SPSS file - R may fail');
    }

    try {
      await execAsync(
        `cd "${outputDir}" && ${rCommand} "${masterPath}"`,
        { maxBuffer: 10 * 1024 * 1024, timeout: 120000 }
      );

      const resultFiles = await fs.readdir(resultsDir);
      if (resultFiles.includes('tables.json')) {
        console.log('[ReviewCompletion] R execution successful');
        rExecutionSuccess = true;

        const tablesJsonPath = path.join(resultsDir, 'tables.json');
        const excelPath = path.join(resultsDir, 'crosstabs.xlsx');

        try {
          const formatter = new ExcelFormatter();
          await formatter.formatFromFile(tablesJsonPath);
          await formatter.saveToFile(excelPath);
          excelGenerated = true;
          console.log('[ReviewCompletion] Excel generated successfully');
        } catch (excelError) {
          console.error('[ReviewCompletion] Excel generation failed:', excelError);
        }
      }
    } catch (rError) {
      const errorMsg = rError instanceof Error ? rError.message : String(rError);
      console.error('[ReviewCompletion] R execution failed:', errorMsg.substring(0, 200));
    }

    // Cleanup temp SPSS
    try {
      await fs.unlink(path.join(outputDir, 'dataFile.sav'));
    } catch { /* May not exist */ }

    // Calculate duration
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
      console.warn('[ReviewCompletion] Could not read summary for duration calculation');
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
        reviewUrl: `/projects/${pipelineId}/review`,
        decisions,
        completedAt: completionTime.toISOString()
      },
      outputs: {
        variables: 0,
        tableAgentTables: reviewState.pathBResult?.tableAgentResults?.flatMap((r: TableAgentOutput) => r.tables).length || 0,
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

    console.log(`[ReviewCompletion] Pipeline completed in ${formatDuration(totalDurationMs)}`);

    return {
      success: true,
      status: finalStatus as 'success' | 'partial' | 'error',
      message: excelGenerated ? 'Pipeline completed successfully' : (rExecutionSuccess ? 'R complete but Excel failed' : 'R execution failed'),
      outputDir,
    };
  } catch (error) {
    console.error('[ReviewCompletion] Background completion failed:', error);
    await updatePipelineSummary(outputDir, {
      status: 'error',
      error: error instanceof Error ? error.message : 'Background completion failed'
    });

    return {
      success: false,
      status: 'error',
      message: error instanceof Error ? error.message : 'Background completion failed',
      outputDir,
    };
  }
}

/**
 * Wait for Path B to complete (polling disk) and then finish the pipeline.
 */
export async function waitAndCompletePipeline(
  outputDir: string,
  pipelineId: string,
  modifiedCrosstabResult: ValidationResultType,
  reviewState: ReviewState,
  decisions: CrosstabDecision[]
): Promise<CompletePipelineResult> {
  const pathBResultPath = path.join(outputDir, 'path-b-result.json');
  const pathBStatusPath = path.join(outputDir, 'path-b-status.json');

  const maxWaitMs = 1800000; // 30 minutes
  const pollIntervalMs = 5000;
  const startTime = Date.now();

  console.log(`[ReviewCompletion] Waiting for Path B to complete (up to 30 min)...`);

  while (Date.now() - startTime < maxWaitMs) {
    try {
      const pathBResult = JSON.parse(await fs.readFile(pathBResultPath, 'utf-8'));
      console.log('[ReviewCompletion] Path B completed - starting pipeline completion');
      return await completePipeline(outputDir, pipelineId, modifiedCrosstabResult, pathBResult, reviewState, decisions);
    } catch { /* not ready yet */ }

    try {
      const statusData = JSON.parse(await fs.readFile(pathBStatusPath, 'utf-8'));
      if (statusData.status === 'error') {
        console.error('[ReviewCompletion] Path B failed:', statusData.error);
        await updatePipelineSummary(outputDir, {
          status: 'error',
          error: `Table processing failed: ${statusData.error}`
        });
        return {
          success: false,
          status: 'error',
          message: `Table processing failed: ${statusData.error}`,
          outputDir,
        };
      }
    } catch { /* status file may not exist yet */ }

    await new Promise(r => setTimeout(r, pollIntervalMs));
  }

  // Timed out
  console.error('[ReviewCompletion] Timed out waiting for Path B (30 min)');
  await updatePipelineSummary(outputDir, {
    status: 'error',
    error: 'Timed out waiting for table processing to complete'
  });

  return {
    success: false,
    status: 'error',
    message: 'Timed out waiting for table processing to complete',
    outputDir,
  };
}
