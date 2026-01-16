// Single API endpoint for complete crosstab processing workflow
// Reference: Architecture doc "Single Endpoint Implementation"

/**
 * POST /api/process-crosstab
 * Purpose: Single entrypoint for upload → full pipeline processing
 * Reads: formData(dataMap, bannerPlan, dataFile, surveyDocument?)
 * Writes: outputs/{dataset}/pipeline-{timestamp}/
 * Status: Job tracked via /api/process-crosstab/status?jobId=...
 */
import { NextRequest, NextResponse } from 'next/server';
import { createJob, updateJob, getAbortSignal } from '../../../lib/jobStore';
import { runAllGuardrails } from '../../../guardrails/inputValidation';
import { generateSessionId, saveUploadedFile } from '../../../lib/storage';
import { logAgentExecution } from '../../../lib/tracing';
import { validateEnvironment } from '../../../lib/env';
import { BannerAgent } from '../../../agents/BannerAgent';
import { processAllGroups as processCrosstabGroups } from '../../../agents/CrosstabAgent';
import { groupDataMapByParent, processQuestionGroupsWithCallback } from '../../../agents/TableAgent';
import { verifyTable, type VerificationInput } from '../../../agents/VerificationAgent';
import { createPassthroughOutput, summarizeVerificationResults } from '../../../schemas/verificationAgentSchema';
import { TableQueue } from '../../../lib/pipeline/TableQueue';
import { processSurvey } from '../../../lib/processors/SurveyProcessor';
import { DataMapProcessor } from '../../../lib/processors/DataMapProcessor';
import { promises as fs } from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import { buildCutsSpec } from '../../../lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '../../../lib/tables/sortTables';
import { generateRScriptV2WithValidation } from '../../../lib/r/RScriptGeneratorV2';
import { ExcelFormatter } from '../../../lib/excel/ExcelFormatter';
import { toExtendedTable, type ExtendedTableDefinition } from '../../../schemas/verificationAgentSchema';
import type { VerboseDataMapType } from '../../../schemas/processingSchemas';
import type { TableAgentOutput } from '../../../schemas/tableAgentSchema';
import type { BannerProcessingResult } from '../../../agents/BannerAgent';
import type { ValidationResultType } from '../../../schemas/agentOutputSchema';

const execAsync = promisify(exec);

// -------------------------------------------------------------------------
// Pipeline Status Types and Helpers
// -------------------------------------------------------------------------

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
  outputs?: {
    variables: number;
    tableAgentTables: number;
    verifiedTables: number;
    tables: number;
    cuts: number;
    bannerGroups: number;
    sorting: {
      screeners: number;
      main: number;
      other: number;
    };
  };
  error?: string;
  review?: {
    flaggedColumnCount: number;
    reviewUrl: string;
  };
}

async function writePipelineSummary(outputDir: string, summary: PipelineSummary): Promise<void> {
  await fs.writeFile(
    path.join(outputDir, 'pipeline-summary.json'),
    JSON.stringify(summary, null, 2)
  );
}

async function updatePipelineSummary(
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
function isAbortError(error: unknown): boolean {
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
async function handleCancellation(
  outputDir: string,
  jobId: string,
  pipelineId: string,
  datasetName: string,
  reason: string
): Promise<void> {
  console.log(`[API] Pipeline cancelled: ${reason}`);

  // Update job store
  updateJob(jobId, {
    stage: 'cancelled',
    percent: 100,
    message: 'Pipeline cancelled by user',
    pipelineId,
    dataset: datasetName
  });

  // Update pipeline summary (if it exists)
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
// Types for parallel path execution
// -------------------------------------------------------------------------

interface AgentDataMapItem {
  Column: string;
  Description: string;
  Answer_Options: string;
}

interface BannerGroupAgent {
  groupName: string;
  columns: Array<{
    name: string;
    original: string;
  }>;
}

interface PathAResult {
  bannerResult: BannerProcessingResult;
  crosstabResult: { result: ValidationResultType; processingLog: string[] };
  agentBanner: BannerGroupAgent[];
  reviewRequired: boolean;  // Always false - actual review check happens after parallel paths complete
}

interface PathBResult {
  tableAgentResults: TableAgentOutput[];
  verifiedTables: ExtendedTableDefinition[];
}

// -------------------------------------------------------------------------
// Human-in-the-Loop Review Types and Helpers
// -------------------------------------------------------------------------

// -------------------------------------------------------------------------
// CrosstabAgent Human-in-the-Loop Review Types
// -------------------------------------------------------------------------

interface FlaggedCrosstabColumn {
  groupName: string;
  columnName: string;
  original: string;           // From banner document
  proposed: string;           // CrosstabAgent's R expression
  confidence: number;
  reason: string;             // Why this mapping was chosen
  alternatives: Array<{
    expression: string;
    confidence: number;
    reason: string;
  }>;
  uncertainties: string[];
  expressionType?: string;
}

interface CrosstabReviewState {
  pipelineId: string;
  status: 'awaiting_review' | 'approved' | 'cancelled';
  createdAt: string;
  crosstabResult: ValidationResultType;  // Full result for context
  flaggedColumns: FlaggedCrosstabColumn[];
  bannerResult: BannerProcessingResult;  // Original banner for reference
  agentDataMap: AgentDataMapItem[];
  outputDir: string;
  pathBStatus: 'completed';
  pathBResult: PathBResult;              // Tables ready (completed in parallel)
  decisions?: Array<{
    groupName: string;
    columnName: string;
    action: 'approve' | 'select_alternative' | 'provide_hint' | 'edit' | 'skip';
    selectedAlternative?: number;  // Index into alternatives[]
    hint?: string;                 // For re-run
    editedExpression?: string;     // Direct edit
  }>;
}

/**
 * Check CrosstabAgent output for columns that need human review
 * Returns columns with low confidence, explicit flags, or expression types that always need review
 */
function getFlaggedCrosstabColumns(
  crosstabResult: ValidationResultType,
  bannerResult: BannerProcessingResult
): FlaggedCrosstabColumn[] {
  const flagged: FlaggedCrosstabColumn[] = [];

  // Build a lookup for original expressions from banner
  const originalLookup = new Map<string, string>();
  const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
  if (extractedStructure?.bannerCuts) {
    for (const group of extractedStructure.bannerCuts) {
      for (const col of group.columns) {
        const key = `${group.groupName}::${col.name}`;
        originalLookup.set(key, col.original);
      }
    }
  }

  for (const group of crosstabResult.bannerCuts) {
    for (const col of group.columns) {
      // Check if this column needs review based on:
      // 1. Explicit humanReviewRequired flag
      // 2. Low confidence (< 0.75)
      // 3. Expression types that always need review
      const requiresReviewByType = col.expressionType &&
        ['placeholder', 'conceptual_filter', 'from_list'].includes(col.expressionType);

      if (col.humanReviewRequired ||
          col.confidence < 0.75 ||
          requiresReviewByType) {
        const lookupKey = `${group.groupName}::${col.name}`;
        flagged.push({
          groupName: group.groupName,
          columnName: col.name,
          original: originalLookup.get(lookupKey) || col.name,
          proposed: col.adjusted,
          confidence: col.confidence,
          reason: col.reason,
          alternatives: col.alternatives || [],
          uncertainties: col.uncertainties || [],
          expressionType: col.expressionType
        });
      }
    }
  }

  return flagged;
}

// -------------------------------------------------------------------------
// Parallel path helper functions
// -------------------------------------------------------------------------

/**
 * Path A: BannerAgent → CrosstabAgent
 * Extracts banner structure, then validates R expressions
 * Review check happens AFTER CrosstabAgent completes (based on mapping uncertainty)
 */
async function executePathA(
  bannerAgent: BannerAgent,
  bannerPlanPath: string,
  agentDataMap: AgentDataMapItem[],
  outputDir: string,
  onProgress: (percent: number) => void,
  abortSignal?: AbortSignal
): Promise<PathAResult> {
  // Check for cancellation before starting
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

  // Check for cancellation before CrosstabAgent
  if (abortSignal?.aborted) {
    console.log('[PathA] Aborted before CrosstabAgent');
    throw new DOMException('Path A aborted', 'AbortError');
  }

  // 2. CrosstabAgent (40-100% of path progress)
  // Note: Review check happens AFTER this completes, based on CrosstabAgent's mapping confidence
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

  // Note: reviewRequired is always false here - actual review check happens after parallel paths complete
  return { bannerResult, crosstabResult, agentBanner, reviewRequired: false };
}

/**
 * Path B: TableAgent → VerificationAgent (Producer-Consumer Pattern)
 *
 * TableAgent produces table definitions as each question group completes.
 * VerificationAgent consumes tables as they become available.
 * Both run concurrently to minimize total processing time.
 */
async function executePathB(
  verboseDataMap: VerboseDataMapType[],
  surveyPath: string | null,
  outputDir: string,
  onProgress: (percent: number) => void,
  abortSignal?: AbortSignal
): Promise<PathBResult> {
  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[PathB] Aborted before starting');
    throw new DOMException('Path B aborted', 'AbortError');
  }

  // 1. Load survey markdown upfront (needed for VerificationAgent from the start)
  let surveyMarkdown: string | null = null;
  if (surveyPath) {
    console.log('[PathB] Processing survey document first...');
    const surveyResult = await processSurvey(surveyPath, outputDir);
    surveyMarkdown = surveyResult.markdown;
    if (surveyMarkdown) {
      console.log(`[PathB] Survey processed: ${surveyMarkdown.length} characters`);
    } else {
      console.warn(`[PathB] Survey processing failed: ${surveyResult.warnings.join(', ')}`);
    }
  }

  // Check for cancellation after survey processing
  if (abortSignal?.aborted) {
    console.log('[PathB] Aborted after survey processing');
    throw new DOMException('Path B aborted', 'AbortError');
  }

  // If no survey markdown, fall back to sequential passthrough mode
  if (!surveyMarkdown) {
    console.log('[PathB] No survey - running TableAgent only (passthrough mode)');
    return executePathBPassthrough(verboseDataMap, outputDir, onProgress, abortSignal);
  }

  // 2. Set up producer-consumer pipeline
  const groups = groupDataMapByParent(verboseDataMap);
  const tableQueue = new TableQueue();

  // Build datamap lookup for VerificationAgent
  const datamapByColumn = new Map<string, VerboseDataMapType>();
  for (const entry of verboseDataMap) {
    datamapByColumn.set(entry.column, entry);
  }

  // Progress tracking
  const totalGroups = groups.length;
  let producerComplete = 0;
  let consumerComplete = 0;
  let expectedTables = 0; // We'll update this as we learn how many tables each group produces

  const updateCombinedProgress = () => {
    // Estimate: producer progress (0-50%) + consumer progress (50-100%)
    // We use producerComplete/totalGroups for producer since we know groups upfront
    // Consumer progress is based on completed vs pushed tables
    const producerPercent = (producerComplete / totalGroups) * 50;
    const consumerPercent = expectedTables > 0
      ? (consumerComplete / expectedTables) * 50
      : 0;
    const combinedPercent = Math.floor(producerPercent + consumerPercent);
    onProgress(combinedPercent);
  };

  console.log(`[PathB] Starting producer-consumer pipeline: ${totalGroups} question groups`);
  onProgress(5);

  // 3. Start TableAgent producer (pushes tables to queue as each group completes)
  const producerPromise = (async () => {
    try {
      const result = await processQuestionGroupsWithCallback(
        groups,
        (table, questionId, questionText) => {
          tableQueue.push({ table, questionId, questionText });
          expectedTables++;
        },
        {
          outputDir,
          abortSignal,
          onProgress: (completed, _total) => {
            producerComplete = completed;
            updateCombinedProgress();
          }
        }
      );
      console.log(`[PathB] Producer complete: ${tableQueue.pushed} tables pushed`);
      return result;
    } finally {
      // Always mark queue done, even on error
      tableQueue.markDone();
    }
  })();

  // 4. Start VerificationAgent consumer (pulls tables from queue)
  const consumerPromise = runVerificationConsumer(
    tableQueue,
    surveyMarkdown,
    datamapByColumn,
    outputDir,
    () => {
      consumerComplete++;
      updateCombinedProgress();
    },
    abortSignal
  );

  // 5. Wait for both producer and consumer to complete
  const [producerResult, consumerResult] = await Promise.all([
    producerPromise,
    consumerPromise
  ]);

  onProgress(100);
  console.log(`[PathB] Complete: ${consumerResult.tables.length} verified tables`);

  return {
    tableAgentResults: producerResult.results,
    verifiedTables: consumerResult.tables
  };
}

/**
 * Passthrough mode for Path B when no survey document is available.
 * Tables pass through VerificationAgent without enhancement.
 */
async function executePathBPassthrough(
  verboseDataMap: VerboseDataMapType[],
  outputDir: string,
  onProgress: (percent: number) => void,
  abortSignal?: AbortSignal
): Promise<PathBResult> {
  const groups = groupDataMapByParent(verboseDataMap);

  onProgress(5);
  console.log('[PathB/Passthrough] Starting TableAgent...');

  const { results: tableAgentResults } = await processQuestionGroupsWithCallback(
    groups,
    () => {}, // No queue push needed in passthrough mode
    {
      outputDir,
      abortSignal,
      onProgress: (completed, total) => {
        const percent = Math.floor((completed / total) * 80);
        onProgress(percent);
      }
    }
  );

  const tableCount = tableAgentResults.flatMap(r => r.tables).length;
  console.log(`[PathB/Passthrough] TableAgent complete: ${tableCount} table definitions`);

  // Convert to extended tables (passthrough)
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
  console.log(`[PathB/Passthrough] Complete: ${verifiedTables.length} tables (passthrough)`);

  return { tableAgentResults, verifiedTables };
}

/**
 * Run VerificationAgent as a consumer, pulling tables from the queue.
 */
async function runVerificationConsumer(
  queue: TableQueue,
  surveyMarkdown: string,
  datamapByColumn: Map<string, VerboseDataMapType>,
  outputDir: string,
  onTableComplete: () => void,
  abortSignal?: AbortSignal
): Promise<{ tables: ExtendedTableDefinition[]; metadata: ReturnType<typeof summarizeVerificationResults> }> {
  const allTables: ExtendedTableDefinition[] = [];
  const results: Array<{ tableId: string; output: ReturnType<typeof createPassthroughOutput> }> = [];
  let tablesProcessed = 0;

  console.log('[PathB/Consumer] Starting verification consumer...');

  while (true) {
    // Check for cancellation
    if (abortSignal?.aborted) {
      console.log(`[PathB/Consumer] Aborted after ${tablesProcessed} tables`);
      throw new DOMException('Verification consumer aborted', 'AbortError');
    }

    // Pull next table from queue (blocks if empty, returns null when done)
    const item = await queue.pull();
    if (item === null) {
      // Queue empty and producer done
      break;
    }

    const { table, questionId, questionText } = item;
    const startTime = Date.now();

    // Build verification input
    const datamapContext = getDatamapContextForTable(table, datamapByColumn);
    const input: VerificationInput = {
      table,
      questionId,
      questionText,
      surveyMarkdown,
      datamapContext
    };

    // Process with retry for rate limiting
    let output;
    try {
      output = await verifyTableWithRetry(input, abortSignal);
    } catch (error) {
      // Re-throw abort errors
      if (error instanceof DOMException && error.name === 'AbortError') {
        throw error;
      }
      // Non-abort error - use passthrough
      console.error(`[PathB/Consumer] Error verifying table ${table.tableId}:`, error);
      output = createPassthroughOutput(table);
    }

    // Add tables with questionId
    for (const t of output.tables) {
      allTables.push({ ...t, questionId } as ExtendedTableDefinition);
    }
    results.push({ tableId: table.tableId, output });

    const duration = Date.now() - startTime;
    tablesProcessed++;

    console.log(
      `[PathB/Consumer] Table "${table.tableId}" verified in ${duration}ms - ` +
      `${output.tables.length} outputs, ${output.changes.length} changes`
    );

    onTableComplete();
  }

  // Calculate metadata from results
  const metadata = summarizeVerificationResults(results.map(r => r.output));

  console.log(
    `[PathB/Consumer] Complete: ${tablesProcessed} tables processed → ${allTables.length} output tables`
  );

  // Save verification output
  const verificationDir = path.join(outputDir, 'verification');
  await fs.mkdir(verificationDir, { recursive: true });
  await fs.writeFile(
    path.join(verificationDir, 'verification-output-raw.json'),
    JSON.stringify({ tables: allTables }, null, 2),
    'utf-8'
  );

  return { tables: allTables, metadata };
}

/**
 * Get formatted datamap context for variables in a table.
 * Matches the logic in VerificationAgent.
 */
function getDatamapContextForTable(
  table: { rows: Array<{ variable: string }> },
  datamapByColumn: Map<string, VerboseDataMapType>
): string {
  const variables = new Set<string>();
  for (const row of table.rows) {
    variables.add(row.variable);
  }

  const entries: string[] = [];
  for (const variable of variables) {
    const entry = datamapByColumn.get(variable);
    if (entry) {
      entries.push(
        `- ${entry.column}: ${entry.description} [${entry.normalizedType}] ${entry.valueType}`
      );
    }
  }

  return entries.join('\n');
}

/**
 * Verify a table with retry logic for rate limiting.
 */
async function verifyTableWithRetry(
  input: VerificationInput,
  abortSignal?: AbortSignal,
  maxRetries = 3
): Promise<ReturnType<typeof createPassthroughOutput>> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await verifyTable(input, abortSignal);
    } catch (error) {
      // Always propagate abort errors
      if (error instanceof DOMException && error.name === 'AbortError') {
        throw error;
      }

      // Check for rate limit error
      const isRateLimit = error instanceof Error && (
        error.message.includes('rate limit') ||
        error.message.includes('429') ||
        error.message.includes('Too Many Requests')
      );

      if (isRateLimit && attempt < maxRetries) {
        const delay = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s
        console.log(
          `[PathB/Consumer] Rate limited on ${input.table.tableId}, ` +
          `retry ${attempt}/${maxRetries} in ${delay}ms`
        );
        await new Promise(r => setTimeout(r, delay));
        continue;
      }

      // Non-retryable error or max retries exceeded
      throw error;
    }
  }

  // Should not reach here, but TypeScript needs it
  throw new Error('Max retries exceeded');
}

/**
 * Sanitize dataset name for use in file paths
 */
function sanitizeDatasetName(filename: string): string {
  return filename
    .replace(/\.(sav|csv|xlsx?)$/i, '') // Remove extension
    .replace(/[^a-zA-Z0-9-_]/g, '-')     // Replace special chars
    .replace(/-+/g, '-')                  // Collapse multiple dashes
    .replace(/^-|-$/g, '')               // Remove leading/trailing dashes
    .toLowerCase();
}

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  const sessionId = generateSessionId();
  const job = createJob();

  // Get the abort signal for this job (used for cancellation support)
  const abortSignal = getAbortSignal(job.jobId);

  try {
    // Validate environment configuration
    const envValidation = validateEnvironment();
    if (!envValidation.valid) {
      return NextResponse.json(
        {
          error: 'Environment configuration invalid',
          details: envValidation.errors
        },
        { status: 500 }
      );
    }

    // Parse form data
    const formData = await request.formData();
    const dataMapFile = formData.get('dataMap') as File;
    const bannerPlanFile = formData.get('bannerPlan') as File;
    const dataFile = formData.get('dataFile') as File;
    const surveyFile = formData.get('surveyDocument') as File | null;

    if (!dataMapFile || !bannerPlanFile || !dataFile) {
      return NextResponse.json(
        { error: 'Missing required files: dataMap, bannerPlan, and dataFile are required' },
        { status: 400 }
      );
    }

    // Run input guardrails
    const files = {
      dataMap: dataMapFile,
      bannerPlan: bannerPlanFile,
      dataFile: dataFile
    };

    const guardrailResult = await runAllGuardrails(files);
    if (!guardrailResult.success) {
      return NextResponse.json(
        {
          error: 'File validation failed',
          details: guardrailResult.errors,
          warnings: guardrailResult.warnings
        },
        { status: 400 }
      );
    }

    // Save files to temporary storage
    updateJob(job.jobId, { stage: 'parsing', percent: 10, message: 'Validating and saving files...' });

    const fileSavePromises = [
      saveUploadedFile(dataMapFile, sessionId, `dataMap.${dataMapFile.name.split('.').pop()}`),
      saveUploadedFile(bannerPlanFile, sessionId, `bannerPlan.${bannerPlanFile.name.split('.').pop()}`),
      saveUploadedFile(dataFile, sessionId, `dataFile.${dataFile.name.split('.').pop()}`)
    ];

    // Save survey file if provided
    if (surveyFile) {
      fileSavePromises.push(
        saveUploadedFile(surveyFile, sessionId, `survey.${surveyFile.name.split('.').pop()}`)
      );
    }

    const fileResults = await Promise.all(fileSavePromises);

    const failedSaves = fileResults.filter(result => !result.success);
    if (failedSaves.length > 0) {
      return NextResponse.json(
        {
          error: 'Failed to save uploaded files',
          details: failedSaves.map(result => result.error)
        },
        { status: 500 }
      );
    }

    // Log successful file upload
    const fileCount = surveyFile ? 4 : 3;
    logAgentExecution(sessionId, 'FileUploadProcessor',
      { fileCount, sessionId },
      { saved: true },
      Date.now() - startTime
    );

    // Kick off background processing and return immediately so client can poll
    ;(async () => {
      const processingStartTime = Date.now();

      // Create output folder path immediately - same pattern as test-pipeline.ts
      const datasetName = sanitizeDatasetName(dataFile.name);
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const pipelineId = `pipeline-${timestamp}`;
      const outputDir = path.join(process.cwd(), 'outputs', datasetName, pipelineId);

      try {
        console.log(`[API] Starting full pipeline processing for session: ${sessionId}`);
        console.log(`[API] Output directory: ${outputDir}`);

        // Create output directory first
        await fs.mkdir(outputDir, { recursive: true });

        const dataMapPath = fileResults[0].filePath!;
        const bannerPlanPath = fileResults[1].filePath!;
        const spssPath = fileResults[2].filePath!;
        const surveyPath = surveyFile ? fileResults[3]?.filePath : null;

        // Copy input files to inputs/ folder with original names
        const inputsDir = path.join(outputDir, 'inputs');
        await fs.mkdir(inputsDir, { recursive: true });
        await fs.copyFile(dataMapPath, path.join(inputsDir, dataMapFile.name));
        await fs.copyFile(bannerPlanPath, path.join(inputsDir, bannerPlanFile.name));
        await fs.copyFile(spssPath, path.join(inputsDir, dataFile.name));
        if (surveyPath && surveyFile) {
          await fs.copyFile(surveyPath, path.join(inputsDir, surveyFile.name));
        }
        console.log('[API] Copied input files to inputs/ folder');

        // Copy SPSS to output dir root (needed for R script execution)
        const spssDestPath = path.join(outputDir, 'dataFile.sav');
        await fs.copyFile(spssPath, spssDestPath);

        // -------------------------------------------------------------------------
        // Step 1: DataMapProcessor
        // -------------------------------------------------------------------------
        updateJob(job.jobId, {
          stage: 'parsing',
          percent: 15,
          message: 'Processing data map...',
          pipelineId,
          dataset: datasetName
        });
        console.log('[API] Step 1: Processing data map...');

        const dataMapProcessor = new DataMapProcessor();
        const dataMapResult = await dataMapProcessor.processDataMap(dataMapPath, spssPath, outputDir);
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
          inputs: {
            datamap: dataMapFile.name,
            banner: bannerPlanFile.name,
            spss: dataFile.name,
            survey: surveyFile?.name || null
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
        const agentDataMap = dataMapResult.agent.map(v => ({
          Column: v.Column,
          Description: v.Description,
          Answer_Options: v.Answer_Options,
        }));

        // Progress tracking for parallel execution (20-80% range)
        let currentParallelPercent = 20;
        const updateParallelProgress = (pathPercent: number) => {
          // Map path's 0-100% to the 20-80% overall range (60 percentage points)
          const overallPercent = 20 + Math.floor(pathPercent * 0.6);
          if (overallPercent > currentParallelPercent) {
            currentParallelPercent = overallPercent;
            updateJob(job.jobId, {
              stage: 'parallel_processing',
              percent: currentParallelPercent,
              message: 'Processing banner and tables...',
              pipelineId,
              dataset: datasetName
            });
          }
        };

        updateJob(job.jobId, {
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
          await handleCancellation(outputDir, job.jobId, pipelineId, datasetName, 'Cancelled before processing');
          return;
        }

        const bannerAgent = new BannerAgent();

        const [pathAResult, pathBResult] = await Promise.allSettled([
          executePathA(bannerAgent, bannerPlanPath, agentDataMap, outputDir, updateParallelProgress, abortSignal),
          executePathB(verboseDataMap, surveyPath ?? null, outputDir, updateParallelProgress, abortSignal)
        ]);

        const parallelDuration = Date.now() - parallelStartTime;
        console.log(`[API] Parallel paths completed in ${(parallelDuration / 1000).toFixed(1)}s`);

        // Check results from both paths
        const pathAFailed = pathAResult.status === 'rejected';
        const pathBFailed = pathBResult.status === 'rejected';

        // Check if either path was aborted (cancelled)
        const pathAAborted = pathAFailed && isAbortError(pathAResult.reason);
        const pathBAborted = pathBFailed && isAbortError(pathBResult.reason);

        if (pathAAborted || pathBAborted) {
          console.log('[API] Pipeline was cancelled during parallel execution');
          await handleCancellation(outputDir, job.jobId, pipelineId, datasetName, 'Cancelled during agent processing');
          return;
        }

        if (pathAFailed) {
          const errorMsg = pathAResult.reason instanceof Error
            ? pathAResult.reason.message
            : String(pathAResult.reason);
          console.error(`[API] Path A failed: ${errorMsg}`);

          // Write a partial summary for debugging
          const failureSummary = {
            pipelineId,
            dataset: datasetName,
            timestamp: new Date().toISOString(),
            source: 'ui',
            status: 'error',
            error: `Banner/Crosstab processing failed: ${errorMsg}`,
            inputs: {
              datamap: dataMapFile.name,
              banner: bannerPlanFile.name,
              spss: dataFile.name,
              survey: surveyFile?.name || null
            }
          };
          await fs.writeFile(
            path.join(outputDir, 'pipeline-summary.json'),
            JSON.stringify(failureSummary, null, 2)
          );

          updateJob(job.jobId, {
            stage: 'error',
            percent: 100,
            message: 'Banner extraction failed',
            error: errorMsg,
            pipelineId,
            dataset: datasetName
          });
          return; // Stop pipeline - Path A is required
        }

        if (pathBFailed) {
          const errorMsg = pathBResult.reason instanceof Error
            ? pathBResult.reason.message
            : String(pathBResult.reason);
          console.error(`[API] Path B failed: ${errorMsg}`);

          // Write a partial summary for debugging
          const failureSummary = {
            pipelineId,
            dataset: datasetName,
            timestamp: new Date().toISOString(),
            source: 'ui',
            status: 'error',
            error: `Table processing failed: ${errorMsg}`,
            inputs: {
              datamap: dataMapFile.name,
              banner: bannerPlanFile.name,
              spss: dataFile.name,
              survey: surveyFile?.name || null
            }
          };
          await fs.writeFile(
            path.join(outputDir, 'pipeline-summary.json'),
            JSON.stringify(failureSummary, null, 2)
          );

          updateJob(job.jobId, {
            stage: 'error',
            percent: 100,
            message: 'Table processing failed',
            error: errorMsg,
            pipelineId,
            dataset: datasetName
          });
          return; // Stop pipeline - Path B is required
        }

        // Both paths succeeded - extract values
        const { bannerResult, crosstabResult } = pathAResult.value;
        const { tableAgentResults, verifiedTables } = pathBResult.value;

        // Log summary from both paths
        const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
        const groupCount = extractedStructure?.bannerCuts?.length || 0;
        const columnCount = (extractedStructure?.processingMetadata as { totalColumns?: number })?.totalColumns || 0;
        const tableAgentTables = tableAgentResults.flatMap(r => r.tables);

        console.log(`[API] Path A: ${groupCount} groups, ${columnCount} columns, ${crosstabResult.result.bannerCuts.length} validated`);
        console.log(`[API] Path B: ${tableAgentTables.length} table definitions, ${verifiedTables.length} verified`);

        // -------------------------------------------------------------------------
        // Handle Human-in-the-Loop Review for CrosstabAgent mappings
        // -------------------------------------------------------------------------
        const flaggedCrosstabColumns = getFlaggedCrosstabColumns(crosstabResult.result, bannerResult);

        if (flaggedCrosstabColumns.length > 0) {
          console.log(`[API] Review required: ${flaggedCrosstabColumns.length} columns need human review (CrosstabAgent mapping)`);

          // Write review state to disk
          const reviewState: CrosstabReviewState = {
            pipelineId,
            status: 'awaiting_review',
            createdAt: new Date().toISOString(),
            crosstabResult: crosstabResult.result,
            flaggedColumns: flaggedCrosstabColumns,
            bannerResult,
            agentDataMap,
            outputDir,
            pathBStatus: 'completed',
            pathBResult: { tableAgentResults, verifiedTables }
          };

          await fs.writeFile(
            path.join(outputDir, 'crosstab-review-state.json'),
            JSON.stringify(reviewState, null, 2)
          );
          console.log('[API] Review state saved to crosstab-review-state.json');

          // Update pipeline summary to pending_review
          const reviewUrl = `/pipelines/${encodeURIComponent(pipelineId)}/review`;
          await updatePipelineSummary(outputDir, {
            status: 'pending_review',
            currentStage: 'crosstab_review',
            review: {
              flaggedColumnCount: flaggedCrosstabColumns.length,
              reviewUrl
            }
          });

          // Update job status for polling
          updateJob(job.jobId, {
            stage: 'crosstab_review_required',
            percent: 75,
            message: `Review required - ${flaggedCrosstabColumns.length} columns need mapping verification`,
            sessionId,
            pipelineId,
            dataset: datasetName,
            reviewRequired: true,
            reviewUrl,
            flaggedColumnCount: flaggedCrosstabColumns.length
          });

          console.log(`[API] Pipeline paused for human review. Tables ready: ${verifiedTables.length}`);
          console.log(`[API] Resume via POST /api/pipelines/${pipelineId}/review`);

          // Don't proceed to R script - wait for human approval
          return;
        }

        // No review needed - continue to R script generation
        console.log('[API] All CrosstabAgent mappings have high confidence - no review needed');

        // Sort tables for logical Excel output order
        console.log('[API] Sorting tables...');
        const sortingMetadata = getSortingMetadata(verifiedTables);
        const sortedTables = sortTables(verifiedTables);
        console.log(`[API] Screeners: ${sortingMetadata.screenerCount}, Main: ${sortingMetadata.mainCount}, Other: ${sortingMetadata.otherCount}`);

        // Check for cancellation before R script generation
        if (abortSignal?.aborted) {
          console.log('[API] Pipeline cancelled before R script generation');
          await handleCancellation(outputDir, job.jobId, pipelineId, datasetName, 'Cancelled before R script generation');
          return;
        }

        // -------------------------------------------------------------------------
        // Step 6: R Script Generation
        // -------------------------------------------------------------------------
        updateJob(job.jobId, {
          stage: 'generating_r',
          percent: 80,
          message: 'Generating R script...',
          pipelineId,
          dataset: datasetName
        });
        console.log('[API] Step 6: Generating R script...');

        const cutsSpec = buildCutsSpec(crosstabResult!.result);
        const rDir = path.join(outputDir, 'r');
        await fs.mkdir(rDir, { recursive: true });

        const { script: masterScript, validation: validationReport } = generateRScriptV2WithValidation(
          { tables: sortedTables, cuts: cutsSpec.cuts },
          { sessionId: pipelineId, outputDir: 'results' }
        );

        const masterPath = path.join(rDir, 'master.R');
        await fs.writeFile(masterPath, masterScript, 'utf-8');

        // Save validation report if there were any issues
        if (validationReport.invalidTables > 0 || validationReport.warnings.length > 0) {
          const validationPath = path.join(rDir, 'validation-report.json');
          await fs.writeFile(validationPath, JSON.stringify(validationReport, null, 2), 'utf-8');
          console.log(`[API] Validation issues: ${validationReport.invalidTables} invalid, ${validationReport.warnings.length} warnings`);
        }

        console.log(`[API] Generated R script (${Math.round(masterScript.length / 1024)} KB)`);
        console.log(`[API] Valid tables: ${validationReport.validTables}/${validationReport.totalTables}`);

        // -------------------------------------------------------------------------
        // Step 7: R Execution
        // -------------------------------------------------------------------------
        updateJob(job.jobId, {
          stage: 'executing_r',
          percent: 85,
          message: 'Executing R script...',
          pipelineId,
          dataset: datasetName
        });
        console.log('[API] Step 7: Executing R script...');

        // Create results directory
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

          // Check for JSON output
          const resultFiles = await fs.readdir(resultsDir);
          if (resultFiles.includes('tables.json')) {
            console.log(`[API] Successfully generated tables.json`);
            rExecutionSuccess = true;

            // -------------------------------------------------------------------------
            // Step 8: Excel Export
            // -------------------------------------------------------------------------
            updateJob(job.jobId, {
              stage: 'writing_outputs',
              percent: 95,
              message: 'Generating Excel workbook...',
              pipelineId,
              dataset: datasetName
            });
            console.log('[API] Step 8: Generating Excel workbook...');

            const tablesJsonPath = path.join(resultsDir, 'tables.json');
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

        // Remove dataFile.sav (only needed for R execution)
        try {
          await fs.unlink(spssDestPath);
        } catch { /* File may not exist */ }

        // Remove banner-images/ folder
        try {
          await fs.rm(path.join(outputDir, 'banner-images'), { recursive: true });
        } catch { /* Folder may not exist */ }

        // Remove survey conversion artifacts
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

        // Check for cancellation before writing final summary
        if (abortSignal?.aborted) {
          console.log('[API] Pipeline cancelled - not writing final summary');
          await handleCancellation(outputDir, job.jobId, pipelineId, datasetName, 'Cancelled before completion');
          return;
        }

        const processingEndTime = Date.now();
        const durationMs = processingEndTime - processingStartTime;
        const durationSec = (durationMs / 1000).toFixed(1);

        const pipelineSummary = {
          pipelineId,
          dataset: datasetName,
          timestamp: new Date().toISOString(),
          source: 'ui',  // Mark as UI-created (vs test script)
          duration: {
            ms: durationMs,
            formatted: `${durationSec}s`
          },
          status: excelGenerated ? 'success' : (rExecutionSuccess ? 'partial' : 'error'),
          inputs: {
            datamap: dataMapFile.name,
            banner: bannerPlanFile.name,
            spss: dataFile.name,
            survey: surveyFile?.name || null
          },
          outputs: {
            variables: verboseDataMap.length,
            tableAgentTables: tableAgentTables.length,
            verifiedTables: sortedTables.length,
            tables: sortedTables.length,
            cuts: cutsSpec.cuts.length,
            bannerGroups: groupCount,
            sorting: {
              screeners: sortingMetadata.screenerCount,
              main: sortingMetadata.mainCount,
              other: sortingMetadata.otherCount
            }
          }
        };

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

        // Update job status
        if (excelGenerated) {
          updateJob(job.jobId, {
            stage: 'complete',
            percent: 100,
            message: `Complete! Generated ${sortedTables.length} crosstab tables in ${durationSec}s`,
            sessionId,
            pipelineId,
            dataset: datasetName,
            downloadUrl: `/api/pipelines/${encodeURIComponent(pipelineId)}/files/results/crosstabs.xlsx`
          });
        } else if (rExecutionSuccess) {
          updateJob(job.jobId, {
            stage: 'complete',
            percent: 100,
            message: 'R execution complete but Excel generation failed.',
            sessionId,
            pipelineId,
            dataset: datasetName,
            warning: 'Excel generation failed. Check results/tables.json'
          });
        } else {
          updateJob(job.jobId, {
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
        // Check if this was a cancellation
        if (isAbortError(processingError)) {
          console.log('[API] Pipeline processing was cancelled');
          await handleCancellation(outputDir, job.jobId, pipelineId, datasetName, 'Pipeline cancelled');
          return;
        }

        console.error('[API] Pipeline error:', processingError);
        updateJob(job.jobId, {
          stage: 'error',
          percent: 100,
          message: 'Processing error',
          error: processingError instanceof Error ? processingError.message : 'Unknown error',
          pipelineId,
          dataset: datasetName
        });
      }
    })();

    return NextResponse.json({ accepted: true, jobId: job.jobId, sessionId });

    } catch (error) {
      console.error('[API] Early processing error:', error);
      updateJob(job.jobId, { stage: 'error', percent: 100, message: 'Processing error', error: error instanceof Error ? error.message : 'Unknown processing error' });
      return NextResponse.json(
        {
          error: 'Data processing failed',
          sessionId,
          details: process.env.NODE_ENV === 'development'
            ? (error instanceof Error ? error.message : String(error))
            : 'Processing error occurred',
          jobId: job.jobId
        },
        { status: 500 }
      );
    }

}

// Handle other HTTP methods
export async function GET() {
  return NextResponse.json(
    {
      error: 'Method not allowed',
      message: 'This endpoint only accepts POST requests with file uploads'
    },
    { status: 405 }
  );
}
