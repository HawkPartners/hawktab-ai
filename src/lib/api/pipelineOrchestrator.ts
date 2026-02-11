/**
 * Core pipeline orchestration: Path A/B coordination, R validation, Excel generation.
 * Extracted from process-crosstab/route.ts to keep the HTTP handler slim.
 */
import { updateJob } from '@/lib/jobStore';
import { BannerAgent } from '@/agents/BannerAgent';
import { processAllGroups as processCrosstabGroups } from '@/agents/CrosstabAgent';
import { verifyAllTablesParallel } from '@/agents/VerificationAgent';
import { groupDataMap } from '@/lib/tables/DataMapGrouper';
import { generateTables, convertToLegacyFormat } from '@/lib/tables/TableGenerator';
import { processSurvey } from '@/lib/processors/SurveyProcessor';
import { buildCutsSpec } from '@/lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '@/lib/tables/sortTables';
import { generateRScriptV2WithValidation } from '@/lib/r/RScriptGeneratorV2';
import { validateAndFixTables } from '@/lib/r/ValidationOrchestrator';
import { extractStreamlinedData } from '@/lib/data/extractStreamlinedData';
import { resetMetricsCollector, getMetricsCollector, getPipelineCostSummary } from '@/lib/observability';
import { ExcelFormatter } from '@/lib/excel/ExcelFormatter';
import { toExtendedTable, type ExtendedTableDefinition, type TableWithLoopFrame } from '@/schemas/verificationAgentSchema';
import type { TableAgentOutput } from '@/schemas/tableAgentSchema';
import type { VerboseDataMapType } from '@/schemas/processingSchemas';
import {
  persistSystemError,
  getGlobalSystemOutputDir,
  readPipelineErrors,
  summarizePipelineErrors,
} from '@/lib/errors/ErrorPersistence';
import { getFlaggedCrosstabColumns } from './hitlManager';
import { sanitizeDatasetName } from './fileHandler';
import type {
  PipelineSummary,
  AgentDataMapItem,
  PathAResult,
  PathBResult,
  PathBStatus,
  CrosstabReviewState,
  SavedFilePaths,
} from './types';
import { promises as fs } from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// -------------------------------------------------------------------------
// Pipeline Summary Helpers
// -------------------------------------------------------------------------

export async function writePipelineSummary(outputDir: string, summary: PipelineSummary): Promise<void> {
  await fs.writeFile(
    path.join(outputDir, 'pipeline-summary.json'),
    JSON.stringify(summary, null, 2)
  );
}

export async function updatePipelineSummary(
  outputDir: string,
  updates: Partial<PipelineSummary>
): Promise<void> {
  const summaryPath = path.join(outputDir, 'pipeline-summary.json');
  try {
    const existing = JSON.parse(await fs.readFile(summaryPath, 'utf-8')) as PipelineSummary;

    // Don't overwrite cancelled status (unless we're explicitly setting cancelled)
    if (existing.status === 'cancelled' && updates.status !== 'cancelled') {
      console.log('[API] Pipeline was cancelled - not overwriting summary');
      return;
    }

    const updated = { ...existing, ...updates };
    await fs.writeFile(summaryPath, JSON.stringify(updated, null, 2));
  } catch {
    // If file doesn't exist, ignore - should have been created already
    console.warn('[API] Could not update pipeline summary - file may not exist');
  }
}

/**
 * Helper to check if an error is an AbortError
 */
export function isAbortError(error: unknown): boolean {
  if (error instanceof DOMException && error.name === 'AbortError') {
    return true;
  }
  if (error instanceof Error) {
    return error.message.includes('aborted') || error.message.includes('AbortError');
  }
  return false;
}

/**
 * Handle pipeline cancellation - update status and clean up
 */
export async function handleCancellation(
  outputDir: string,
  jobId: string,
  pipelineId: string,
  datasetName: string,
  reason: string
): Promise<void> {
  console.log(`[API] Pipeline cancelled: ${reason}`);

  updateJob(jobId, {
    stage: 'cancelled',
    percent: 100,
    message: 'Pipeline cancelled by user',
    pipelineId,
    dataset: datasetName
  });

  try {
    await updatePipelineSummary(outputDir, {
      status: 'cancelled',
      currentStage: 'cancelled'
    });
  } catch {
    // Summary might not exist yet
  }
}

// -------------------------------------------------------------------------
// Parallel Path Execution
// -------------------------------------------------------------------------

/**
 * Path A: BannerAgent → CrosstabAgent
 * Extracts banner structure, then validates R expressions.
 * Review check happens AFTER CrosstabAgent completes (based on mapping uncertainty).
 */
async function executePathA(
  bannerAgent: BannerAgent,
  bannerPlanPath: string,
  agentDataMap: AgentDataMapItem[],
  outputDir: string,
  onProgress: (percent: number) => void,
  abortSignal?: AbortSignal
): Promise<PathAResult> {
  if (abortSignal?.aborted) {
    console.log('[PathA] Aborted before starting');
    throw new DOMException('Path A aborted', 'AbortError');
  }

  // 1. BannerAgent (0-40% of path progress)
  onProgress(5);
  console.log('[PathA] Starting BannerAgent...');
  const bannerResult = await bannerAgent.processDocument(bannerPlanPath, outputDir, abortSignal);

  const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
  const groupCount = extractedStructure?.bannerCuts?.length || 0;

  if (!bannerResult.success || groupCount === 0) {
    const errorMsg = bannerResult.errors?.join('; ') || 'Banner extraction failed - 0 groups extracted';
    throw new Error(errorMsg);
  }

  onProgress(40);
  console.log(`[PathA] BannerAgent complete: ${groupCount} groups extracted`);

  const agentBanner = bannerResult.agent || [];

  if (abortSignal?.aborted) {
    console.log('[PathA] Aborted before CrosstabAgent');
    throw new DOMException('Path A aborted', 'AbortError');
  }

  // 2. CrosstabAgent (40-100% of path progress)
  console.log('[PathA] Starting CrosstabAgent...');

  const crosstabResult = await processCrosstabGroups(
    agentDataMap,
    { bannerCuts: agentBanner.map(g => ({ groupName: g.groupName, columns: g.columns })) },
    outputDir,
    (completed, total) => {
      const percent = 40 + Math.floor((completed / total) * 60);
      onProgress(percent);
    },
    abortSignal
  );

  onProgress(100);
  console.log(`[PathA] CrosstabAgent complete: ${crosstabResult.result.bannerCuts.length} groups validated`);

  return { bannerResult, crosstabResult, agentBanner, reviewRequired: false };
}

/**
 * Path B: TableGenerator → VerificationAgent
 *
 * Uses deterministic TableGenerator (replaces LLM-based TableAgent) followed by
 * parallel VerificationAgent processing.
 */
async function executePathB(
  verboseDataMap: VerboseDataMapType[],
  surveyPath: string | null,
  outputDir: string,
  onProgress: (percent: number) => void,
  abortSignal?: AbortSignal
): Promise<PathBResult> {
  if (abortSignal?.aborted) {
    console.log('[PathB] Aborted before starting');
    throw new DOMException('Path B aborted', 'AbortError');
  }

  // 1. Process survey document (needed for VerificationAgent)
  let surveyMarkdown: string | null = null;
  if (surveyPath) {
    console.log('[PathB] Processing survey document...');
    const surveyResult = await processSurvey(surveyPath, outputDir);
    surveyMarkdown = surveyResult.markdown;
    if (surveyMarkdown) {
      console.log(`[PathB] Survey processed: ${surveyMarkdown.length} characters`);
    } else {
      console.warn(`[PathB] Survey processing failed: ${surveyResult.warnings.join(', ')}`);
    }
  }

  if (abortSignal?.aborted) {
    console.log('[PathB] Aborted after survey processing');
    throw new DOMException('Path B aborted', 'AbortError');
  }

  // 2. Generate tables deterministically (instant, no LLM)
  console.log('[PathB] Running TableGenerator...');
  const groups = groupDataMap(verboseDataMap);
  const generatorOutputs = generateTables(groups);
  const tableAgentResults: TableAgentOutput[] = convertToLegacyFormat(generatorOutputs);
  const tableCount = tableAgentResults.flatMap(r => r.tables).length;
  console.log(`[PathB] TableGenerator: ${tableCount} tables generated`);
  onProgress(30);

  if (abortSignal?.aborted) {
    console.log('[PathB] Aborted after table generation');
    throw new DOMException('Path B aborted', 'AbortError');
  }

  // 3. Run VerificationAgent
  if (!surveyMarkdown) {
    // Passthrough mode - no enhancement
    console.log('[PathB] No survey - using passthrough mode');
    const verifiedTables: ExtendedTableDefinition[] = tableAgentResults.flatMap(group =>
      group.tables.map(t => toExtendedTable(t, group.questionId))
    );

    // Save passthrough verification output
    const verificationDir = path.join(outputDir, 'verification');
    await fs.mkdir(verificationDir, { recursive: true });
    await fs.writeFile(
      path.join(verificationDir, 'verification-output-raw.json'),
      JSON.stringify({ tables: verifiedTables }, null, 2),
      'utf-8'
    );

    onProgress(100);
    console.log(`[PathB] Complete (passthrough): ${verifiedTables.length} tables`);
    return { tableAgentResults, verifiedTables, surveyMarkdown };
  }

  // Run VerificationAgent in parallel
  console.log('[PathB] Starting VerificationAgent (parallel, concurrency: 3)...');
  const verificationResult = await verifyAllTablesParallel(
    tableAgentResults,
    surveyMarkdown,
    verboseDataMap,
    { outputDir, concurrency: 3, abortSignal }
  );

  onProgress(100);
  console.log(`[PathB] Complete: ${verificationResult.tables.length} verified tables`);

  return {
    tableAgentResults,
    verifiedTables: verificationResult.tables,
    surveyMarkdown
  };
}

// -------------------------------------------------------------------------
// Main Pipeline Orchestrator
// -------------------------------------------------------------------------

export interface PipelineRunParams {
  jobId: string;
  sessionId: string;
  fileNames: {
    dataMap: string;
    bannerPlan: string;
    dataFile: string;
    survey: string | null;
  };
  savedPaths: SavedFilePaths;
  abortSignal?: AbortSignal;
  loopStatTestingMode?: 'suppress' | 'complement';
}

/**
 * Run the full pipeline from uploaded files.
 * This is the background processing function — it updates job status via polling
 * and writes results to disk. All errors are handled internally.
 */
export async function runPipelineFromUpload(params: PipelineRunParams): Promise<void> {
  const {
    jobId,
    sessionId,
    fileNames,
    savedPaths,
    abortSignal,
    loopStatTestingMode,
  } = params;

  const processingStartTime = Date.now();

  // Create output folder path — same pattern as test-pipeline.ts
  const datasetName = sanitizeDatasetName(fileNames.dataFile);
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const pipelineId = `pipeline-${timestamp}`;
  const outputDir = path.join(process.cwd(), 'outputs', datasetName, pipelineId);

  try {
    // Reset metrics collector for this pipeline run
    resetMetricsCollector();

    console.log(`[API] Starting full pipeline processing for session: ${sessionId}`);
    console.log(`[API] Output directory: ${outputDir}`);

    // Create output directory first
    await fs.mkdir(outputDir, { recursive: true });

    const { dataMapPath, bannerPlanPath, spssPath, surveyPath } = savedPaths;

    // Copy input files to inputs/ folder with original names
    const inputsDir = path.join(outputDir, 'inputs');
    await fs.mkdir(inputsDir, { recursive: true });
    await fs.copyFile(dataMapPath, path.join(inputsDir, fileNames.dataMap));
    await fs.copyFile(bannerPlanPath, path.join(inputsDir, fileNames.bannerPlan));
    await fs.copyFile(spssPath, path.join(inputsDir, fileNames.dataFile));
    if (surveyPath && fileNames.survey) {
      await fs.copyFile(surveyPath, path.join(inputsDir, fileNames.survey));
    }
    console.log('[API] Copied input files to inputs/ folder');

    // Copy SPSS to output dir root (needed for R script execution)
    const spssDestPath = path.join(outputDir, 'dataFile.sav');
    await fs.copyFile(spssPath, spssDestPath);

    // -------------------------------------------------------------------------
    // Step 1: DataMapProcessor
    // -------------------------------------------------------------------------
    updateJob(jobId, {
      stage: 'parsing',
      percent: 15,
      message: 'Processing data map...',
      pipelineId,
      dataset: datasetName
    });
    console.log('[API] Step 1: Processing data map...');

    // Use validation runner (.sav as source of truth)
    const { validate: runValidation } = await import('@/lib/validation/ValidationRunner');
    const validationResult = await runValidation({ spssPath, outputDir });
    const dataMapResult = validationResult.processingResult || {
      success: false, verbose: [], agent: [],
      validationPassed: false, confidence: 0,
      errors: ['Validation failed'], warnings: [],
    };
    const verboseDataMap = dataMapResult.verbose as VerboseDataMapType[];
    console.log(`[API] Processed ${verboseDataMap.length} variables`);

    // Write initial pipeline summary immediately (for sidebar visibility)
    const initialSummary: PipelineSummary = {
      pipelineId,
      dataset: datasetName,
      timestamp: new Date().toISOString(),
      source: 'ui',
      status: 'in_progress',
      currentStage: 'parallel_processing',
      options: {
        loopStatTestingMode,
      },
      inputs: {
        datamap: fileNames.dataMap,
        banner: fileNames.bannerPlan,
        spss: fileNames.dataFile,
        survey: fileNames.survey,
      }
    };
    await writePipelineSummary(outputDir, initialSummary);
    console.log('[API] Initial pipeline summary written');

    // -------------------------------------------------------------------------
    // Steps 2-5: Parallel Path Execution
    // Path A: BannerAgent → CrosstabAgent
    // Path B: TableAgent → Survey → VerificationAgent
    // -------------------------------------------------------------------------

    // Prepare data for both paths
    const agentDataMap: AgentDataMapItem[] = dataMapResult.agent.map(v => ({
      Column: v.Column,
      Description: v.Description,
      Answer_Options: v.Answer_Options,
    }));

    // Progress tracking for parallel execution (20-80% range)
    let currentParallelPercent = 20;
    const updateParallelProgress = (pathPercent: number) => {
      const overallPercent = 20 + Math.floor(pathPercent * 0.6);
      if (overallPercent > currentParallelPercent) {
        currentParallelPercent = overallPercent;
        updateJob(jobId, {
          stage: 'parallel_processing',
          percent: currentParallelPercent,
          message: 'Processing banner and tables...',
          pipelineId,
          dataset: datasetName
        });
      }
    };

    updateJob(jobId, {
      stage: 'parallel_processing',
      percent: 20,
      message: 'Processing banner and tables...',
      pipelineId,
      dataset: datasetName
    });

    console.log('[API] Starting parallel paths...');
    const parallelStartTime = Date.now();

    // Check for cancellation before starting parallel paths
    if (abortSignal?.aborted) {
      console.log('[API] Pipeline cancelled before parallel paths');
      await handleCancellation(outputDir, jobId, pipelineId, datasetName, 'Cancelled before processing');
      return;
    }

    const bannerAgent = new BannerAgent();

    // Write initial Path B status (will be running)
    const pathBStatusPath = path.join(outputDir, 'path-b-status.json');
    const pathBResultPath = path.join(outputDir, 'path-b-result.json');
    const pathBStartedAt = new Date().toISOString();
    const initialPathBStatus: PathBStatus = {
      status: 'running',
      startedAt: pathBStartedAt,
      completedAt: null,
      error: null
    };
    await fs.writeFile(pathBStatusPath, JSON.stringify(initialPathBStatus, null, 2));
    console.log('[API] Path B status initialized: running');

    // Start Path B as fire-and-forget (writes result to disk when complete)
    const pathBPromise = executePathB(verboseDataMap, surveyPath ?? null, outputDir, updateParallelProgress, abortSignal)
      .then(async (result) => {
        await fs.writeFile(pathBResultPath, JSON.stringify(result, null, 2));
        const completedStatus: PathBStatus = {
          status: 'completed',
          startedAt: pathBStartedAt,
          completedAt: new Date().toISOString(),
          error: null
        };
        await fs.writeFile(pathBStatusPath, JSON.stringify(completedStatus, null, 2));
        console.log('[API] Path B completed and result saved to disk');
        return result;
      })
      .catch(async (error) => {
        const errorMsg = error instanceof Error ? error.message : String(error);
        const isAborted = isAbortError(error);
        const errorStatus: PathBStatus = {
          status: 'error',
          startedAt: pathBStartedAt,
          completedAt: new Date().toISOString(),
          error: isAborted ? 'Cancelled' : errorMsg
        };
        await fs.writeFile(pathBStatusPath, JSON.stringify(errorStatus, null, 2));
        console.error(`[API] Path B failed: ${errorMsg}`);
        throw error;
      });

    // Await ONLY Path A — this is what we need for review check
    console.log('[API] Awaiting Path A (Banner → Crosstab)...');
    let pathAResult: PathAResult;
    try {
      pathAResult = await executePathA(bannerAgent, bannerPlanPath, agentDataMap, outputDir, updateParallelProgress, abortSignal);
    } catch (pathAError) {
      if (isAbortError(pathAError)) {
        console.log('[API] Pipeline was cancelled during Path A');
        await handleCancellation(outputDir, jobId, pipelineId, datasetName, 'Cancelled during agent processing');
        return;
      }

      const errorMsg = pathAError instanceof Error ? pathAError.message : String(pathAError);
      console.error(`[API] Path A failed: ${errorMsg}`);

      const failureSummary = {
        pipelineId,
        dataset: datasetName,
        timestamp: new Date().toISOString(),
        source: 'ui',
        status: 'error',
        error: `Banner/Crosstab processing failed: ${errorMsg}`,
        inputs: {
          datamap: fileNames.dataMap,
          banner: fileNames.bannerPlan,
          spss: fileNames.dataFile,
          survey: fileNames.survey,
        }
      };
      await fs.writeFile(
        path.join(outputDir, 'pipeline-summary.json'),
        JSON.stringify(failureSummary, null, 2)
      );

      updateJob(jobId, {
        stage: 'error',
        percent: 100,
        message: 'Banner extraction failed',
        error: errorMsg,
        pipelineId,
        dataset: datasetName
      });
      return;
    }

    const pathADuration = Date.now() - parallelStartTime;
    console.log(`[API] Path A completed in ${(pathADuration / 1000).toFixed(1)}s (Path B still running in background)`);

    const { bannerResult, crosstabResult } = pathAResult;

    const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
    const groupCount = extractedStructure?.bannerCuts?.length || 0;
    const columnCount = (extractedStructure?.processingMetadata as { totalColumns?: number })?.totalColumns || 0;

    console.log(`[API] Path A: ${groupCount} groups, ${columnCount} columns, ${crosstabResult.result.bannerCuts.length} validated`);

    // -------------------------------------------------------------------------
    // Handle Human-in-the-Loop Review for CrosstabAgent mappings
    // -------------------------------------------------------------------------
    const flaggedCrosstabColumns = getFlaggedCrosstabColumns(crosstabResult.result, bannerResult);

    if (flaggedCrosstabColumns.length > 0) {
      console.log(`[API] Review required: ${flaggedCrosstabColumns.length} columns need human review (CrosstabAgent mapping)`);
      console.log('[API] Showing review UI immediately - Path B continues in background');

      const reviewState: CrosstabReviewState = {
        pipelineId,
        status: 'awaiting_review',
        createdAt: new Date().toISOString(),
        crosstabResult: crosstabResult.result,
        flaggedColumns: flaggedCrosstabColumns,
        bannerResult,
        agentDataMap,
        outputDir,
        pathBStatus: 'running',
        pathBResult: null
      };

      await fs.writeFile(
        path.join(outputDir, 'crosstab-review-state.json'),
        JSON.stringify(reviewState, null, 2)
      );
      console.log('[API] Review state saved to crosstab-review-state.json');

      const reviewUrl = `/projects/${encodeURIComponent(pipelineId)}/review`;
      await updatePipelineSummary(outputDir, {
        status: 'pending_review',
        currentStage: 'crosstab_review',
        review: {
          flaggedColumnCount: flaggedCrosstabColumns.length,
          reviewUrl
        }
      });

      updateJob(jobId, {
        stage: 'crosstab_review_required',
        percent: 50,
        message: `Review required - ${flaggedCrosstabColumns.length} columns need mapping verification`,
        sessionId,
        pipelineId,
        dataset: datasetName,
        reviewRequired: true,
        reviewUrl,
        flaggedColumnCount: flaggedCrosstabColumns.length
      });

      console.log('[API] Pipeline paused for human review. Path B continues in background.');
      console.log(`[API] Resume via POST /api/pipelines/${pipelineId}/review`);
      return;
    }

    // No review needed — wait for Path B now, then continue to R script generation
    console.log('[API] All CrosstabAgent mappings have high confidence - no review needed');
    console.log('[API] Waiting for Path B to complete...');

    let pathBResultData: PathBResult;
    try {
      pathBResultData = await pathBPromise;
    } catch (pathBError) {
      if (isAbortError(pathBError)) {
        console.log('[API] Pipeline was cancelled during Path B');
        await handleCancellation(outputDir, jobId, pipelineId, datasetName, 'Cancelled during agent processing');
        return;
      }

      const errorMsg = pathBError instanceof Error ? pathBError.message : String(pathBError);
      console.error(`[API] Path B failed: ${errorMsg}`);

      const failureSummary = {
        pipelineId,
        dataset: datasetName,
        timestamp: new Date().toISOString(),
        source: 'ui',
        status: 'error',
        error: `Table processing failed: ${errorMsg}`,
        inputs: {
          datamap: fileNames.dataMap,
          banner: fileNames.bannerPlan,
          spss: fileNames.dataFile,
          survey: fileNames.survey,
        }
      };
      await fs.writeFile(
        path.join(outputDir, 'pipeline-summary.json'),
        JSON.stringify(failureSummary, null, 2)
      );

      updateJob(jobId, {
        stage: 'error',
        percent: 100,
        message: 'Table processing failed',
        error: errorMsg,
        pipelineId,
        dataset: datasetName
      });
      return;
    }

    const { tableAgentResults, verifiedTables, surveyMarkdown } = pathBResultData;
    const tableAgentTables = tableAgentResults.flatMap(r => r.tables);
    const parallelDuration = Date.now() - parallelStartTime;
    console.log(`[API] Both paths completed in ${(parallelDuration / 1000).toFixed(1)}s`);
    console.log(`[API] Path B: ${tableAgentTables.length} table definitions, ${verifiedTables.length} verified`);

    // Sort tables for logical Excel output order
    console.log('[API] Sorting tables...');
    const sortingMetadata = getSortingMetadata(verifiedTables);
    const sortedTables = sortTables(verifiedTables);
    console.log(`[API] Screeners: ${sortingMetadata.screenerCount}, Main: ${sortingMetadata.mainCount}, Other: ${sortingMetadata.otherCount}`);

    if (abortSignal?.aborted) {
      console.log('[API] Pipeline cancelled before R validation');
      await handleCancellation(outputDir, jobId, pipelineId, datasetName, 'Cancelled before R validation');
      return;
    }

    // -------------------------------------------------------------------------
    // Step 6: R Validation with Retry Loop
    // -------------------------------------------------------------------------
    updateJob(jobId, {
      stage: 'validating_r',
      percent: 75,
      message: 'Validating R code per table...',
      pipelineId,
      dataset: datasetName
    });
    console.log('[API] Step 6: Validating R code per table...');

    const cutsSpec = buildCutsSpec(crosstabResult.result);

    const tablesWithLoopFrame: TableWithLoopFrame[] = sortedTables.map(t => ({ ...t, loopDataFrame: '' }));

    const { validTables, excludedTables: newlyExcluded, validationReport: rValidationReport } = await validateAndFixTables(
      tablesWithLoopFrame,
      cutsSpec.cuts,
      surveyMarkdown || '',
      verboseDataMap,
      {
        outputDir,
        maxRetries: 8,
        dataFilePath: 'dataFile.sav',
        verbose: true,
      }
    );

    console.log(`[API] R Validation: ${rValidationReport.passedFirstTime} passed, ${rValidationReport.fixedAfterRetry} fixed, ${rValidationReport.excluded} excluded`);

    const allTablesForR = [...validTables, ...newlyExcluded];

    if (abortSignal?.aborted) {
      console.log('[API] Pipeline cancelled before R script generation');
      await handleCancellation(outputDir, jobId, pipelineId, datasetName, 'Cancelled before R script generation');
      return;
    }

    // -------------------------------------------------------------------------
    // Step 7: R Script Generation
    // -------------------------------------------------------------------------
    updateJob(jobId, {
      stage: 'generating_r',
      percent: 80,
      message: 'Generating R script...',
      pipelineId,
      dataset: datasetName
    });
    console.log('[API] Step 7: Generating R script...');

    const rDir = path.join(outputDir, 'r');
    await fs.mkdir(rDir, { recursive: true });

    const { script: masterScript, validation: staticValidationReport } = generateRScriptV2WithValidation(
      {
        tables: allTablesForR,
        cuts: cutsSpec.cuts,
        cutGroups: cutsSpec.groups,
        loopStatTestingMode,
      },
      { sessionId: pipelineId, outputDir: 'results' }
    );

    const masterPath = path.join(rDir, 'master.R');
    await fs.writeFile(masterPath, masterScript, 'utf-8');

    if (staticValidationReport.invalidTables > 0 || staticValidationReport.warnings.length > 0) {
      const staticValidationPath = path.join(rDir, 'static-validation-report.json');
      await fs.writeFile(staticValidationPath, JSON.stringify(staticValidationReport, null, 2), 'utf-8');
      console.log(`[API] Static validation issues: ${staticValidationReport.invalidTables} invalid, ${staticValidationReport.warnings.length} warnings`);
    }

    console.log(`[API] Generated R script (${Math.round(masterScript.length / 1024)} KB)`);
    console.log(`[API] Tables in script: ${allTablesForR.length} (${validTables.length} valid, ${newlyExcluded.length} excluded)`);

    // -------------------------------------------------------------------------
    // Step 8: R Execution
    // -------------------------------------------------------------------------
    updateJob(jobId, {
      stage: 'executing_r',
      percent: 85,
      message: 'Executing R script...',
      pipelineId,
      dataset: datasetName
    });
    console.log('[API] Step 8: Executing R script...');

    const resultsDir = path.join(outputDir, 'results');
    await fs.mkdir(resultsDir, { recursive: true });

    // Find R
    let rCommand = 'Rscript';
    const rPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
    for (const rPath of rPaths) {
      try {
        await execAsync(`${rPath} --version`, { timeout: 1000 });
        rCommand = rPath;
        console.log(`[API] Found R at: ${rPath}`);
        break;
      } catch {
        // Try next
      }
    }

    let rExecutionSuccess = false;
    let excelGenerated = false;

    try {
      await execAsync(
        `cd "${outputDir}" && ${rCommand} "${masterPath}"`,
        { maxBuffer: 10 * 1024 * 1024, timeout: 120000 }
      );

      const resultFiles = await fs.readdir(resultsDir);
      if (resultFiles.includes('tables.json')) {
        console.log(`[API] Successfully generated tables.json`);
        rExecutionSuccess = true;

        const tablesJsonPath = path.join(resultsDir, 'tables.json');

        // Extract streamlined data for golden dataset evaluation
        try {
          const tablesJsonContent = await fs.readFile(tablesJsonPath, 'utf-8');
          const tablesJsonData = JSON.parse(tablesJsonContent);
          const streamlinedData = extractStreamlinedData(tablesJsonData);
          const streamlinedPath = path.join(resultsDir, 'data-streamlined.json');
          await fs.writeFile(streamlinedPath, JSON.stringify(streamlinedData, null, 2), 'utf-8');
          console.log(`[API] Generated data-streamlined.json`);
        } catch (err) {
          console.warn('[API] Could not generate streamlined data:', err);
        }

        // -------------------------------------------------------------------------
        // Step 9: Excel Export
        // -------------------------------------------------------------------------
        updateJob(jobId, {
          stage: 'writing_outputs',
          percent: 95,
          message: 'Generating Excel workbook...',
          pipelineId,
          dataset: datasetName
        });
        console.log('[API] Step 9: Generating Excel workbook...');

        const excelPath = path.join(resultsDir, 'crosstabs.xlsx');

        try {
          const formatter = new ExcelFormatter();
          await formatter.formatFromFile(tablesJsonPath);
          await formatter.saveToFile(excelPath);
          excelGenerated = true;
          console.log(`[API] Generated crosstabs.xlsx`);
        } catch (excelError) {
          console.error(`[API] Excel generation failed:`, excelError);
        }
      }
    } catch (rError) {
      const errorMsg = rError instanceof Error ? rError.message : String(rError);
      if (errorMsg.includes('command not found')) {
        console.warn(`[API] R not installed - script saved for manual execution`);
      } else {
        console.error(`[API] R execution failed:`, errorMsg.substring(0, 200));
      }
    }

    // -------------------------------------------------------------------------
    // Cleanup temporary files
    // -------------------------------------------------------------------------
    console.log('[API] Cleaning up temporary files...');

    try {
      await fs.unlink(spssDestPath);
    } catch { /* File may not exist */ }

    try {
      await fs.rm(path.join(outputDir, 'banner-images'), { recursive: true });
    } catch { /* Folder may not exist */ }

    try {
      const allFiles = await fs.readdir(outputDir);
      for (const file of allFiles) {
        if (file.endsWith('.html') || (file.endsWith('.png') && file.includes('_html_'))) {
          await fs.unlink(path.join(outputDir, file));
        }
      }
    } catch { /* Ignore cleanup errors */ }

    // -------------------------------------------------------------------------
    // Write pipeline summary and complete
    // -------------------------------------------------------------------------

    if (abortSignal?.aborted) {
      console.log('[API] Pipeline cancelled - not writing final summary');
      await handleCancellation(outputDir, jobId, pipelineId, datasetName, 'Cancelled before completion');
      return;
    }

    const processingEndTime = Date.now();
    const durationMs = processingEndTime - processingStartTime;
    const durationSec = (durationMs / 1000).toFixed(1);

    const costMetrics = await getMetricsCollector().getSummary();

    const pipelineSummary: PipelineSummary = {
      pipelineId,
      dataset: datasetName,
      timestamp: new Date().toISOString(),
      source: 'ui',
      duration: {
        ms: durationMs,
        formatted: `${durationSec}s`
      },
      status: excelGenerated ? 'success' : (rExecutionSuccess ? 'partial' : 'error'),
      inputs: {
        datamap: fileNames.dataMap,
        banner: fileNames.bannerPlan,
        spss: fileNames.dataFile,
        survey: fileNames.survey,
      },
      outputs: {
        variables: verboseDataMap.length,
        tableGeneratorTables: tableAgentTables.length,
        verifiedTables: sortedTables.length,
        validatedTables: validTables.length,
        excludedTables: newlyExcluded.length,
        totalTablesInR: allTablesForR.length,
        cuts: cutsSpec.cuts.length,
        bannerGroups: groupCount,
        sorting: {
          screeners: sortingMetadata.screenerCount,
          main: sortingMetadata.mainCount,
          other: sortingMetadata.otherCount
        },
        rValidation: {
          passedFirstTime: rValidationReport.passedFirstTime,
          fixedAfterRetry: rValidationReport.fixedAfterRetry,
          excluded: rValidationReport.excluded,
          durationMs: rValidationReport.durationMs
        }
      },
      costs: {
        byAgent: costMetrics.byAgent.map(a => ({
          agent: a.agentName,
          model: a.model,
          calls: a.calls,
          inputTokens: a.totalInputTokens,
          outputTokens: a.totalOutputTokens,
          durationMs: a.totalDurationMs,
          estimatedCostUsd: a.estimatedCostUsd,
        })),
        totals: {
          calls: costMetrics.totals.calls,
          inputTokens: costMetrics.totals.inputTokens,
          outputTokens: costMetrics.totals.outputTokens,
          totalTokens: costMetrics.totals.totalTokens,
          durationMs: costMetrics.totals.durationMs,
          estimatedCostUsd: costMetrics.totals.estimatedCostUsd,
        },
      }
    };

    // Attach error persistence summary
    try {
      const errorRead = await readPipelineErrors(outputDir);
      const errorSummary = summarizePipelineErrors(errorRead.records);
      pipelineSummary.errors = { ...errorSummary, invalidLines: errorRead.invalidLines.length };
    } catch {
      // ignore
    }

    // Check if already cancelled before writing
    const summaryPath = path.join(outputDir, 'pipeline-summary.json');
    try {
      const existing = JSON.parse(await fs.readFile(summaryPath, 'utf-8'));
      if (existing.status === 'cancelled') {
        console.log('[API] Pipeline was cancelled - not overwriting summary');
        return;
      }
    } catch {
      // File doesn't exist, proceed with write
    }

    await fs.writeFile(summaryPath, JSON.stringify(pipelineSummary, null, 2));
    console.log(`[API] Pipeline completed in ${durationSec}s - summary saved`);

    const costSummaryText = await getPipelineCostSummary();
    console.log(costSummaryText);

    // Update job status
    if (excelGenerated) {
      updateJob(jobId, {
        stage: 'complete',
        percent: 100,
        message: `Complete! Generated ${allTablesForR.length} crosstab tables in ${durationSec}s`,
        sessionId,
        pipelineId,
        dataset: datasetName,
        downloadUrl: `/api/pipelines/${encodeURIComponent(pipelineId)}/files/results/crosstabs.xlsx`
      });
    } else if (rExecutionSuccess) {
      updateJob(jobId, {
        stage: 'complete',
        percent: 100,
        message: 'R execution complete but Excel generation failed.',
        sessionId,
        pipelineId,
        dataset: datasetName,
        warning: 'Excel generation failed. Check results/tables.json'
      });
    } else {
      updateJob(jobId, {
        stage: 'complete',
        percent: 100,
        message: 'R scripts generated. Execution failed - check R installation.',
        sessionId,
        pipelineId,
        dataset: datasetName,
        warning: 'R execution failed. Scripts saved in r/master.R'
      });
    }

  } catch (processingError) {
    if (isAbortError(processingError)) {
      console.log('[API] Pipeline processing was cancelled');
      await handleCancellation(outputDir, jobId, pipelineId, datasetName, 'Pipeline cancelled');
      return;
    }

    console.error('[API] Pipeline error:', processingError);
    try {
      await persistSystemError({
        outputDir: outputDir || getGlobalSystemOutputDir(),
        dataset: datasetName || '',
        pipelineId: pipelineId || '',
        stageNumber: 0,
        stageName: 'API',
        severity: 'fatal',
        actionTaken: 'failed_pipeline',
        error: processingError,
        meta: { jobId },
      });
    } catch {
      // ignore
    }
    updateJob(jobId, {
      stage: 'error',
      percent: 100,
      message: 'Processing error',
      error: processingError instanceof Error ? processingError.message : 'Unknown error',
      pipelineId,
      dataset: datasetName
    });
  }
}
