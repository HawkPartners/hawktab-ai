/**
 * VerificationAgent
 *
 * Purpose: Enhance TableAgent output using the actual survey document
 * Reads: TableAgent output (table definitions) + Survey markdown + Datamap context
 * Writes (dev): temp-outputs/output-<ts>/verified-table-output-<ts>.json
 *
 * Capabilities:
 * - Fix labels: Replace "Value 1" with actual survey answer text
 * - Split tables: Separate by treatment when appropriate
 * - Add NET rows: Roll-up rows for grouped answer options
 * - Create derived tables: T2B/B2B for satisfaction/agreement scales
 * - Flag exclusions: Mark low-value tables for reference sheet
 */

import { generateText, Output, stepCountIs } from 'ai';
import pLimit from 'p-limit';
import {
  VerificationAgentOutputSchema,
  type VerificationAgentOutput,
  type ExtendedTableDefinition,
  type VerificationResults,
  createPassthroughOutput,
  summarizeVerificationResults,
} from '../schemas/verificationAgentSchema';
import { type TableDefinition, type TableAgentOutput } from '../schemas/tableAgentSchema';
import { type VerboseDataMapType } from '../schemas/processingSchemas';
import {
  getVerificationModel,
  getVerificationModelName,
  getVerificationModelTokenLimit,
  getVerificationReasoningEffort,
  getPromptVersions,
} from '../lib/env';
import {
  verificationScratchpadTool,
  clearScratchpadEntries,
  getAndClearScratchpadEntries,
  formatScratchpadAsMarkdown,
  createContextScratchpadTool,
  getAllContextScratchpadEntries,
  clearAllContextScratchpads,
} from './tools/scratchpad';
import { getVerificationPrompt } from '../prompts';
import { retryWithPolicyHandling } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import { getPipelineEventBus } from '../lib/events';
import fs from 'fs/promises';
import path from 'path';

// Get modular prompt based on environment variable
const getVerificationAgentInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getVerificationPrompt(promptVersions.verificationPromptVersion);
};

// =============================================================================
// Types
// =============================================================================

export interface RValidationError {
  /** Error message from R execution */
  errorMessage: string;
  /** Which retry attempt this is (1-based) */
  failedAttempt: number;
  /** Maximum retry attempts allowed */
  maxAttempts: number;
}

export interface VerificationInput {
  /** Table definition from TableAgent */
  table: TableDefinition;
  /** Question context */
  questionId: string;
  questionText: string;
  /** Survey markdown (full or section) */
  surveyMarkdown: string;
  /** Verbose datamap entries for variables in this table (as formatted string) */
  datamapContext: string;
  /** R validation error context for retry attempts (optional) */
  rValidationError?: RValidationError;
}

export interface VerificationProcessingOptions {
  /** Output directory for development outputs (full path) */
  outputDir?: string;
  /** Progress callback */
  onProgress?: (completed: number, total: number, tableId: string) => void;
  /** Whether to skip verification and pass through (e.g., when no survey available) */
  passthrough?: boolean;
  /** Abort signal for cancellation support */
  abortSignal?: AbortSignal;
}

// =============================================================================
// Single Table Processing
// =============================================================================

/**
 * Process a single table through VerificationAgent
 */
export async function verifyTable(
  input: VerificationInput,
  abortSignal?: AbortSignal,
  contextScratchpad?: ReturnType<typeof createContextScratchpadTool>
): Promise<VerificationAgentOutput> {
  console.log(`[VerificationAgent] Processing table: ${input.table.tableId}`);
  const startTime = Date.now();

  // Check for cancellation before processing
  if (abortSignal?.aborted) {
    console.log(`[VerificationAgent] Aborted before processing table ${input.table.tableId}`);
    throw new DOMException('VerificationAgent aborted', 'AbortError');
  }

  // If no survey markdown, pass through unchanged
  if (!input.surveyMarkdown || input.surveyMarkdown.trim() === '') {
    console.log(`[VerificationAgent] No survey markdown - passing through unchanged`);
    return createPassthroughOutput(input.table);
  }

  // Build system prompt with survey and datamap context
  const systemPrompt = `
${getVerificationAgentInstructions()}

## Survey Document
<survey>
${input.surveyMarkdown}
</survey>

## Variable Context (Datamap)
<datamap>
${input.datamapContext}
</datamap>
`;

  // Build user prompt
  let userPrompt = `Review this table and output the desired end state:

Question: ${input.questionId} - ${input.questionText}

Table Definition:
${JSON.stringify(input.table, null, 2)}

Analyze the table against the survey document. Fix labels, split if needed, add NETs if appropriate, create T2B if it's a scale, or flag for exclusion if low value. Output the tables array representing the desired end state.
`;

  // Append retry error context at the bottom if this is a retry attempt
  if (input.rValidationError) {
    const { errorMessage, failedAttempt, maxAttempts } = input.rValidationError;
    userPrompt += `
<r_validation_retry>
RETRY ATTEMPT ${failedAttempt}/${maxAttempts}

Your previous output for this table failed R validation with the following error:
"${errorMessage}"

<common_fixes>
- "object 'X' not found" → Variable name doesn't exist in datamap. Check exact spelling and case.
- "Variable 'X' not found" → Variable name is hallucinated. Use ONLY variables from the datamap.
- "Variable '_NET_*' not found" → You created a NET but forgot isNet: true and/or netComponents.
  For synthetic NET variables, you MUST set isNet: true AND populate netComponents with exact variable names from the datamap.
- "NET component variable 'X' not found" → A variable in netComponents doesn't exist. Check exact spelling/case against datamap.
- "non-numeric argument" → filterValue or variable type mismatch. Check datamap for correct types.
</common_fixes>

Please carefully review the error message and the datamap context above, then retry your output for this table. Follow all system prompt instructions as normal.
</r_validation_retry>
`;
  }

  // Check if this is an abort error
  const checkAbortError = (error: unknown): boolean => {
    return error instanceof DOMException && error.name === 'AbortError';
  };

  // Use context scratchpad if provided (for parallel execution), else use global
  const scratchpad = contextScratchpad || verificationScratchpadTool;

  // Wrap the AI call with retry logic for policy errors
  const retryResult = await retryWithPolicyHandling(
    async () => {
      const { output, usage } = await generateText({
        model: getVerificationModel(),
        system: systemPrompt,
        maxRetries: 3,  // SDK handles transient/network errors
        prompt: userPrompt,
        tools: {
          scratchpad,
        },
        stopWhen: stepCountIs(15),
        maxOutputTokens: Math.min(getVerificationModelTokenLimit(), 100000),
        // Configure reasoning effort for Azure OpenAI GPT-5/o-series models
        providerOptions: {
          openai: {
            reasoningEffort: getVerificationReasoningEffort(),
          },
        },
        output: Output.object({
          schema: VerificationAgentOutputSchema,
        }),
        abortSignal,  // Pass abort signal to AI SDK
      });

      if (!output || !output.tables || output.tables.length === 0) {
        throw new Error(`Invalid output for table ${input.table.tableId}`);
      }

      // Record metrics
      const durationMs = Date.now() - startTime;
      recordAgentMetrics(
        'VerificationAgent',
        getVerificationModelName(),
        { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
        durationMs
      );

      return output;
    },
    {
      abortSignal,
      onRetry: (attempt, err) => {
        // Check for abort errors and propagate them
        if (checkAbortError(err)) {
          throw err;
        }
        console.warn(`[VerificationAgent] Retry ${attempt}/3 for table "${input.table.tableId}": ${err.message}`);
      },
    }
  );

  if (retryResult.success && retryResult.result) {
    console.log(
      `[VerificationAgent] Table ${input.table.tableId} processed - ${retryResult.result.tables.length} tables, ${retryResult.result.changes.length} changes, confidence: ${retryResult.result.confidence.toFixed(2)}`
    );
    return retryResult.result;
  }

  // Handle abort errors
  if (retryResult.error === 'Operation was cancelled') {
    console.log(`[VerificationAgent] Aborted by signal during table ${input.table.tableId}`);
    throw new DOMException('VerificationAgent aborted', 'AbortError');
  }

  // All retries failed - return passthrough on error
  const errorMessage = retryResult.error || 'Unknown error';
  const retryContext = retryResult.wasPolicyError
    ? ` (failed after ${retryResult.attempts} retries due to content policy)`
    : '';
  console.error(`[VerificationAgent] Error processing table ${input.table.tableId}:`, errorMessage + retryContext);

  return createPassthroughOutput(input.table);
}

// =============================================================================
// Batch Processing
// =============================================================================

/**
 * Process all tables from TableAgent output through VerificationAgent
 */
export async function verifyAllTables(
  tableAgentOutput: TableAgentOutput[],
  surveyMarkdown: string,
  verboseDataMap: VerboseDataMapType[],
  options: VerificationProcessingOptions = {}
): Promise<VerificationResults> {
  const { outputDir, onProgress, passthrough, abortSignal } = options;
  const processingLog: string[] = [];

  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[VerificationAgent] Aborted before processing started');
    throw new DOMException('VerificationAgent aborted', 'AbortError');
  }

  // Clear scratchpad from any previous runs
  clearScratchpadEntries();

  // Collect all tables with their question context
  const allTables: Array<{
    table: TableDefinition;
    questionId: string;
    questionText: string;
  }> = [];

  for (const questionGroup of tableAgentOutput) {
    for (const table of questionGroup.tables) {
      allTables.push({
        table,
        questionId: questionGroup.questionId,
        questionText: questionGroup.questionText,
      });
    }
  }

  logEntry(`[VerificationAgent] Starting processing: ${allTables.length} tables`);
  logEntry(`[VerificationAgent] Using model: ${getVerificationModelName()}`);
  logEntry(`[VerificationAgent] Reasoning effort: ${getVerificationReasoningEffort()}`);
  logEntry(`[VerificationAgent] Survey markdown: ${surveyMarkdown.length} characters`);

  // If passthrough mode or no survey, return all tables unchanged
  if (passthrough || !surveyMarkdown || surveyMarkdown.trim() === '') {
    logEntry(`[VerificationAgent] Passthrough mode - returning tables unchanged`);
    const passthroughResults = allTables.map(({ table, questionId }) => {
      const output = createPassthroughOutput(table);
      // Attach questionId to passthrough tables
      return {
        ...output,
        tables: output.tables.map((t) => ({ ...t, questionId })),
      };
    });
    const allVerifiedTables = passthroughResults.flatMap((r) => r.tables);

    return {
      tables: allVerifiedTables,
      metadata: summarizeVerificationResults(passthroughResults),
      allChanges: [],
    };
  }

  // Build datamap lookup for quick access
  const datamapByColumn = new Map<string, VerboseDataMapType>();
  for (const entry of verboseDataMap) {
    datamapByColumn.set(entry.column, entry);
  }

  const results: VerificationAgentOutput[] = [];
  const questionIdByIndex: string[] = []; // Track questionId for each result

  // Process each table
  for (let i = 0; i < allTables.length; i++) {
    // Check for cancellation between tables
    if (abortSignal?.aborted) {
      console.log(`[VerificationAgent] Aborted after ${i} tables`);
      throw new DOMException('VerificationAgent aborted', 'AbortError');
    }

    const { table, questionId, questionText } = allTables[i];
    const startTime = Date.now();

    logEntry(
      `[VerificationAgent] Processing table ${i + 1}/${allTables.length}: "${table.tableId}"`
    );

    // Get datamap context for variables in this table
    const datamapContext = getDatamapContextForTable(table, datamapByColumn);

    const input: VerificationInput = {
      table,
      questionId,
      questionText,
      surveyMarkdown,
      datamapContext,
    };

    const result = await verifyTable(input, abortSignal);
    results.push(result);
    questionIdByIndex.push(questionId); // Track questionId for this result

    const duration = Date.now() - startTime;
    logEntry(
      `[VerificationAgent] Table "${table.tableId}" completed in ${duration}ms - ${result.tables.length} output tables, ${result.changes.length} changes`
    );

    try {
      onProgress?.(i + 1, allTables.length, table.tableId);
    } catch {
      // Ignore progress callback errors
    }
  }

  // Collect scratchpad entries
  const scratchpadEntries = getAndClearScratchpadEntries();
  logEntry(`[VerificationAgent] Collected ${scratchpadEntries.length} scratchpad entries`);

  // Combine all verified tables, attaching questionId from the tracked array
  const allVerifiedTables: ExtendedTableDefinition[] = results.flatMap((r, i) =>
    r.tables.map((t) => ({ ...t, questionId: questionIdByIndex[i] }))
  );

  // Collect all changes
  const allChanges = results
    .map((r, i) => ({
      tableId: allTables[i].table.tableId,
      changes: r.changes,
    }))
    .filter((c) => c.changes.length > 0);

  // Calculate metadata
  const metadata = summarizeVerificationResults(results);

  logEntry(
    `[VerificationAgent] Processing complete - ${allTables.length} input → ${allVerifiedTables.length} output tables`
  );
  logEntry(
    `[VerificationAgent] Modified: ${metadata.tablesModified}, Split: ${metadata.tablesSplit}, Excluded: ${metadata.tablesExcluded}`
  );

  const verificationResults: VerificationResults = {
    tables: allVerifiedTables,
    metadata,
    allChanges,
  };

  // Save outputs
  if (outputDir) {
    await saveDevelopmentOutputs(
      verificationResults,
      outputDir,
      processingLog,
      scratchpadEntries
    );
  }

  return verificationResults;
}

// =============================================================================
// Parallel Processing
// =============================================================================

/**
 * Process all tables in parallel with configurable concurrency
 */
export async function verifyAllTablesParallel(
  tableAgentOutput: TableAgentOutput[],
  surveyMarkdown: string,
  verboseDataMap: VerboseDataMapType[],
  options: VerificationProcessingOptions & { concurrency?: number } = {}
): Promise<VerificationResults> {
  const { outputDir, onProgress, passthrough, abortSignal, concurrency = 3 } = options;
  const processingLog: string[] = [];

  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[VerificationAgent] Aborted before processing started');
    throw new DOMException('VerificationAgent aborted', 'AbortError');
  }

  // Clear both global and context scratchpads from any previous runs
  clearScratchpadEntries();
  clearAllContextScratchpads();

  // Build lookup table once (shared, immutable)
  const datamapByColumn = new Map<string, VerboseDataMapType>();
  for (const entry of verboseDataMap) {
    datamapByColumn.set(entry.column, entry);
  }

  // Flatten all tables with their context
  const allTables: Array<{
    table: TableDefinition;
    questionId: string;
    questionText: string;
    index: number;
  }> = [];

  for (const questionGroup of tableAgentOutput) {
    for (const table of questionGroup.tables) {
      allTables.push({
        table,
        questionId: questionGroup.questionId,
        questionText: questionGroup.questionText,
        index: allTables.length,
      });
    }
  }

  logEntry(`[VerificationAgent] Starting parallel processing: ${allTables.length} tables (concurrency: ${concurrency})`);
  logEntry(`[VerificationAgent] Using model: ${getVerificationModelName()}`);
  logEntry(`[VerificationAgent] Reasoning effort: ${getVerificationReasoningEffort()}`);
  logEntry(`[VerificationAgent] Survey markdown: ${surveyMarkdown.length} characters`);

  // If passthrough mode or no survey, return all tables unchanged
  if (passthrough || !surveyMarkdown || surveyMarkdown.trim() === '') {
    logEntry(`[VerificationAgent] Passthrough mode - returning tables unchanged`);
    const { toExtendedTable } = await import('../schemas/verificationAgentSchema');
    const passthroughTables = allTables.map(({ table, questionId }) =>
      toExtendedTable(table, questionId)
    );

    return {
      tables: passthroughTables,
      metadata: {
        totalInputTables: allTables.length,
        totalOutputTables: passthroughTables.length,
        tablesModified: 0,
        tablesSplit: 0,
        tablesExcluded: 0,
        averageConfidence: 1.0,
      },
      allChanges: [],
    };
  }

  // Create limiter for concurrency control
  const limit = pLimit(concurrency);
  let completed = 0;

  // Track active slots for event emission
  const activeSlots = new Map<string, number>(); // tableId -> slotIndex
  let nextSlotIndex = 0;

  // Process in parallel with limit
  const resultPromises = allTables.map(({ table, questionId, questionText, index }) =>
    limit(async () => {
      if (abortSignal?.aborted) {
        throw new DOMException('VerificationAgent aborted', 'AbortError');
      }

      // Assign slot index (round-robin)
      const slotIndex = nextSlotIndex % concurrency;
      nextSlotIndex++;
      activeSlots.set(table.tableId, slotIndex);

      const startTime = Date.now();

      // Emit slot:start event
      getPipelineEventBus().emitSlotStart('VerificationAgent', slotIndex, table.tableId);

      const datamapContext = getDatamapContextForTable(table, datamapByColumn);
      const input: VerificationInput = {
        table,
        questionId,
        questionText,
        surveyMarkdown,
        datamapContext,
      };

      // Use context-specific scratchpad
      const contextScratchpad = createContextScratchpadTool('VerificationAgent', table.tableId);
      const result = await verifyTable(input, abortSignal, contextScratchpad);

      // Emit slot:complete event
      const durationMs = Date.now() - startTime;
      getPipelineEventBus().emitSlotComplete('VerificationAgent', slotIndex, table.tableId, durationMs);
      activeSlots.delete(table.tableId);

      completed++;

      // Emit agent:progress event
      getPipelineEventBus().emitAgentProgress('VerificationAgent', completed, allTables.length);

      try {
        onProgress?.(completed, allTables.length, table.tableId);
      } catch { /* ignore progress errors */ }

      return { result, questionId, index };
    })
  );

  const resolvedResults = await Promise.all(resultPromises);

  // Sort by original index to maintain order
  resolvedResults.sort((a, b) => a.index - b.index);

  // Aggregate results
  const results = resolvedResults.map((r) => r.result);
  const questionIdByIndex = resolvedResults.map((r) => r.questionId);

  // Aggregate scratchpad entries from all contexts
  const contextEntries = getAllContextScratchpadEntries();
  const allScratchpadEntries = contextEntries.flatMap((ctx) =>
    ctx.entries.map((e) => ({ ...e, contextId: ctx.contextId }))
  );
  logEntry(`[VerificationAgent] Collected ${allScratchpadEntries.length} scratchpad entries from ${contextEntries.length} contexts`);

  // Combine all verified tables, attaching questionId from the tracked array
  const allVerifiedTables: ExtendedTableDefinition[] = results.flatMap((r, i) =>
    r.tables.map((t) => ({ ...t, questionId: questionIdByIndex[i] }))
  );

  // Collect all changes
  const allChanges = results
    .map((r, i) => ({
      tableId: allTables[i].table.tableId,
      changes: r.changes,
    }))
    .filter((c) => c.changes.length > 0);

  // Calculate metadata
  const metadata = summarizeVerificationResults(results);

  logEntry(
    `[VerificationAgent] Parallel processing complete - ${allTables.length} input → ${allVerifiedTables.length} output tables`
  );
  logEntry(
    `[VerificationAgent] Modified: ${metadata.tablesModified}, Split: ${metadata.tablesSplit}, Excluded: ${metadata.tablesExcluded}`
  );

  const verificationResults: VerificationResults = {
    tables: allVerifiedTables,
    metadata,
    allChanges,
  };

  // Save outputs
  if (outputDir) {
    // Map context entries to the expected format for saveDevelopmentOutputs
    const scratchpadEntries = allScratchpadEntries.map((e) => ({
      timestamp: e.timestamp,
      agentName: e.agentName,
      action: e.action,
      content: `[${e.contextId}] ${e.content}`,
    }));
    await saveDevelopmentOutputs(
      verificationResults,
      outputDir,
      processingLog,
      scratchpadEntries
    );
  }

  return verificationResults;
}

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Get formatted datamap context for variables in a table
 */
function getDatamapContextForTable(
  table: TableDefinition,
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
        `${variable}:
  Description: ${entry.description}
  Type: ${entry.normalizedType || 'unknown'}
  Values: ${entry.valueType}
  ${entry.scaleLabels ? `Scale Labels: ${JSON.stringify(entry.scaleLabels)}` : ''}
  ${entry.allowedValues ? `Allowed Values: ${entry.allowedValues.join(', ')}` : ''}`
      );
    }
  }

  return entries.length > 0 ? entries.join('\n\n') : 'No datamap context available';
}

/**
 * Get non-excluded tables from results
 */
export function getIncludedTables(results: VerificationResults): ExtendedTableDefinition[] {
  return results.tables.filter((t) => !t.exclude);
}

/**
 * Get excluded tables from results
 */
export function getExcludedTables(results: VerificationResults): ExtendedTableDefinition[] {
  return results.tables.filter((t) => t.exclude);
}

// =============================================================================
// Development Outputs
// =============================================================================

async function saveDevelopmentOutputs(
  results: VerificationResults,
  outputDir: string,
  processingLog: string[],
  scratchpadEntries: Array<{ timestamp: string; agentName: string; action: string; content: string }>
): Promise<void> {
  try {
    // Create verification subfolder for all VerificationAgent outputs
    const verificationDir = path.join(outputDir, 'verification');
    await fs.mkdir(verificationDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    // Save verified table output
    const filename = `verified-table-output-${timestamp}.json`;
    const filePath = path.join(verificationDir, filename);

    const enhancedOutput = {
      ...results,
      processingInfo: {
        timestamp: new Date().toISOString(),
        aiProvider: 'azure-openai',
        model: getVerificationModelName(),
        reasoningEffort: getVerificationReasoningEffort(),
        processingLog,
      },
    };

    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');
    console.log(`[VerificationAgent] Development output saved to verification/: ${filename}`);

    // Save raw output (complete model output - for golden dataset comparison)
    // This includes tables and allChanges (model decisions), but NOT metadata (system-calculated)
    const rawOutput = {
      tables: results.tables,
      allChanges: results.allChanges,
    };
    const rawPath = path.join(verificationDir, 'verification-output-raw.json');
    await fs.writeFile(rawPath, JSON.stringify(rawOutput, null, 2), 'utf-8');

    // Save scratchpad trace as separate markdown file
    if (scratchpadEntries.length > 0) {
      const scratchpadFilename = `scratchpad-verification-${timestamp}.md`;
      const scratchpadPath = path.join(verificationDir, scratchpadFilename);
      const markdown = formatScratchpadAsMarkdown('VerificationAgent', scratchpadEntries);
      await fs.writeFile(scratchpadPath, markdown, 'utf-8');
      console.log(`[VerificationAgent] Scratchpad saved to verification/: ${scratchpadFilename}`);
    }
  } catch (error) {
    console.error('[VerificationAgent] Failed to save development outputs:', error);
  }
}
