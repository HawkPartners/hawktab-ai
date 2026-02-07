/**
 * @deprecated Replaced by SkipLogicAgent + FilterTranslatorAgent + FilterApplicator.
 * This file is kept only for backward compatibility with existing pipeline outputs.
 * Do not add new features here. See src/agents/SkipLogicAgent.ts and src/agents/FilterTranslatorAgent.ts.
 *
 * BaseFilterAgent
 *
 * Purpose: Detect skip/show logic in survey questions and apply appropriate
 * base filters for accurate table calculations.
 *
 * Reads: ExtendedTableDefinition[] + Survey markdown + Datamap context
 * Writes (dev): temp-outputs/output-<ts>/basefilter/basefilter-output-<ts>.json
 *
 * Capabilities:
 * - Detect SHOW IF / SKIP IF instructions in survey context
 * - Apply additional R filter expressions to table calculations
 * - Split tables when rows have different base requirements
 * - Flag ambiguous cases for human review
 */

import { generateText, Output, stepCountIs } from 'ai';
import pLimit from 'p-limit';
import {
  BaseFilterSingleTableOutputSchema,
  type BaseFilterTableResult,
  type BaseFilterAgentOutput,
  createPassthroughResult,
  summarizeBaseFilterResults,
} from '../schemas/baseFilterAgentSchema';
import { type ExtendedTableDefinition } from '../schemas/verificationAgentSchema';
import { type VerboseDataMapType } from '../schemas/processingSchemas';
import {
  getBaseFilterModel,
  getBaseFilterModelName,
  getBaseFilterModelTokenLimit,
  getBaseFilterReasoningEffort,
  getPromptVersions,
} from '../lib/env';
import {
  baseFilterScratchpadTool,
  clearScratchpadEntries,
  getAndClearScratchpadEntries,
  formatScratchpadAsMarkdown,
  createContextScratchpadTool,
  getAllContextScratchpadEntries,
  clearAllContextScratchpads,
} from './tools/scratchpad';
import { getBaseFilterPrompt } from '../prompts';
import { retryWithPolicyHandling } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import { getPipelineEventBus } from '../lib/events';
import {
  formatFullDatamapContext,
  validateFilterVariables,
} from '../lib/filters/filterUtils';
import fs from 'fs/promises';
import path from 'path';

// Get modular prompt based on environment variable
const getBaseFilterAgentInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getBaseFilterPrompt(promptVersions.baseFilterPromptVersion);
};

// =============================================================================
// Types
// =============================================================================

export interface BaseFilterInput {
  /** Table definition from VerificationAgent */
  table: ExtendedTableDefinition;
  /** Survey markdown (full or section) */
  surveyMarkdown: string;
  /** Verbose datamap entries (as formatted string) */
  datamapContext: string;
  /** Set of valid variable names for validation */
  validVariables: Set<string>;
}

export interface BaseFilterProcessingOptions {
  /** Output directory for development outputs (full path) */
  outputDir?: string;
  /** Progress callback */
  onProgress?: (completed: number, total: number, tableId: string) => void;
  /** Whether to skip analysis and pass through (e.g., when no survey available) */
  passthrough?: boolean;
  /** Abort signal for cancellation support */
  abortSignal?: AbortSignal;
  /** Concurrency level for parallel processing */
  concurrency?: number;
}

// =============================================================================
// Single Table Processing
// =============================================================================

/**
 * Analyze a single table for skip/show logic
 */
export async function analyzeTableBase(
  input: BaseFilterInput,
  abortSignal?: AbortSignal,
  contextScratchpad?: ReturnType<typeof createContextScratchpadTool>
): Promise<BaseFilterTableResult> {
  console.log(`[BaseFilterAgent] Analyzing table: ${input.table.tableId}`);
  const startTime = Date.now();

  // Check for cancellation before processing
  if (abortSignal?.aborted) {
    console.log(`[BaseFilterAgent] Aborted before processing table ${input.table.tableId}`);
    throw new DOMException('BaseFilterAgent aborted', 'AbortError');
  }

  // If no survey markdown, pass through unchanged
  if (!input.surveyMarkdown || input.surveyMarkdown.trim() === '') {
    console.log(`[BaseFilterAgent] No survey markdown - passing through unchanged`);
    return createPassthroughResult(input.table);
  }

  // Build system prompt with survey and FULL datamap context
  const systemPrompt = `
${getBaseFilterAgentInstructions()}

## Survey Document
<survey>
${input.surveyMarkdown}
</survey>

## Complete Datamap (All Variables)
The following is the COMPLETE datamap for this survey. You have access to ALL variables, not just those in the current table. This is important because skip/show logic often references RELATED variables (e.g., Q8 usage counts when processing Q10 follow-up questions). Look for corresponding condition variables when analyzing per-row show logic.

<datamap>
${input.datamapContext}
</datamap>
`;

  // Build user prompt
  const userPrompt = `Analyze this table for skip/show logic and determine the appropriate base filter:

Table Definition:
${JSON.stringify(input.table, null, 2)}

Analyze the survey document for any skip logic that affects who should be counted in this table's base. Output your decision with the appropriate action (pass, filter, or split).
`;

  // Check if this is an abort error
  const checkAbortError = (error: unknown): boolean => {
    return error instanceof DOMException && error.name === 'AbortError';
  };

  // Use context scratchpad if provided (for parallel execution), else use global
  const scratchpad = contextScratchpad || baseFilterScratchpadTool;

  // Wrap the AI call with retry logic for policy errors
  const retryResult = await retryWithPolicyHandling(
    async () => {
      const { output, usage } = await generateText({
        model: getBaseFilterModel(),
        system: systemPrompt,
        maxRetries: 3,  // SDK handles transient/network errors
        prompt: userPrompt,
        tools: {
          scratchpad,
        },
        stopWhen: stepCountIs(15),
        maxOutputTokens: Math.min(getBaseFilterModelTokenLimit(), 100000),
        // Configure reasoning effort for Azure OpenAI GPT-5/o-series models
        providerOptions: {
          openai: {
            reasoningEffort: getBaseFilterReasoningEffort(),
          },
        },
        output: Output.object({
          schema: BaseFilterSingleTableOutputSchema,
        }),
        abortSignal,  // Pass abort signal to AI SDK
      });

      if (!output || !output.tables || output.tables.length === 0) {
        throw new Error(`Invalid output for table ${input.table.tableId}`);
      }

      // Record metrics
      const durationMs = Date.now() - startTime;
      recordAgentMetrics(
        'BaseFilterAgent',
        getBaseFilterModelName(),
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
        console.warn(`[BaseFilterAgent] Retry ${attempt}/3 for table "${input.table.tableId}": ${err.message}`);
      },
    }
  );

  if (retryResult.success && retryResult.result) {
    const result = retryResult.result;

    // Build initial result
    const initialResult: BaseFilterTableResult = {
      action: result.action,
      originalTableId: input.table.tableId,
      tables: result.tables,
      confidence: result.confidence,
      reasoning: result.reasoning,
      humanReviewRequired: result.humanReviewRequired,
    };

    // Validate filter variables against datamap (catch hallucinations)
    const validatedResult = validateAndFixAgentOutput(initialResult, input.validVariables);

    // Set provenance tracking: if BaseFilterAgent made meaningful changes, mark it as the last modifier
    if (validatedResult.action !== 'pass') {
      for (const table of validatedResult.tables) {
        table.lastModifiedBy = 'BaseFilterAgent';
      }
    }

    console.log(
      `[BaseFilterAgent] Table ${input.table.tableId} processed - action: ${validatedResult.action}, ${validatedResult.tables.length} tables, confidence: ${validatedResult.confidence.toFixed(2)}`
    );

    return validatedResult;
  }

  // Handle abort errors
  if (retryResult.error === 'Operation was cancelled') {
    console.log(`[BaseFilterAgent] Aborted by signal during table ${input.table.tableId}`);
    throw new DOMException('BaseFilterAgent aborted', 'AbortError');
  }

  // All retries failed - return passthrough on error
  const errorMessage = retryResult.error || 'Unknown error';
  const retryContext = retryResult.wasPolicyError
    ? ` (failed after ${retryResult.attempts} retries due to content policy)`
    : '';
  console.error(`[BaseFilterAgent] Error processing table ${input.table.tableId}:`, errorMessage + retryContext);

  return createPassthroughResult(input.table);
}

// =============================================================================
// Batch Processing (Sequential)
// =============================================================================

/**
 * Analyze all tables for skip/show logic (sequential processing)
 */
export async function analyzeAllTableBases(
  tables: ExtendedTableDefinition[],
  surveyMarkdown: string,
  verboseDataMap: VerboseDataMapType[],
  options: BaseFilterProcessingOptions = {}
): Promise<BaseFilterAgentOutput> {
  const { outputDir, onProgress, passthrough, abortSignal } = options;
  const processingLog: string[] = [];

  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[BaseFilterAgent] Aborted before processing started');
    throw new DOMException('BaseFilterAgent aborted', 'AbortError');
  }

  // Clear scratchpad from any previous runs
  clearScratchpadEntries();

  logEntry(`[BaseFilterAgent] Starting processing: ${tables.length} tables`);
  logEntry(`[BaseFilterAgent] Using model: ${getBaseFilterModelName()}`);
  logEntry(`[BaseFilterAgent] Reasoning effort: ${getBaseFilterReasoningEffort()}`);
  logEntry(`[BaseFilterAgent] Survey markdown: ${surveyMarkdown.length} characters`);

  // If passthrough mode or no survey, return all tables unchanged
  if (passthrough || !surveyMarkdown || surveyMarkdown.trim() === '') {
    logEntry(`[BaseFilterAgent] Passthrough mode - returning tables unchanged`);
    const passthroughResults = tables.map((table) => createPassthroughResult(table));

    return { results: passthroughResults };
  }

  // Format the FULL datamap as context (same for all tables)
  // This allows the agent to see related variables (e.g., Q8 usage when processing Q10 follow-ups)
  const datamapContext = formatFullDatamapContext(verboseDataMap);
  logEntry(`[BaseFilterAgent] Datamap context: ${verboseDataMap.length} variables`);

  // Build set of valid variable names for validation (catch hallucinations)
  const validVariables = new Set<string>(verboseDataMap.map(v => v.column));

  const results: BaseFilterTableResult[] = [];

  // Process each table
  for (let i = 0; i < tables.length; i++) {
    // Check for cancellation between tables
    if (abortSignal?.aborted) {
      console.log(`[BaseFilterAgent] Aborted after ${i} tables`);
      throw new DOMException('BaseFilterAgent aborted', 'AbortError');
    }

    const table = tables[i];
    const startTime = Date.now();

    logEntry(`[BaseFilterAgent] Processing table ${i + 1}/${tables.length}: "${table.tableId}"`);

    const input: BaseFilterInput = {
      table,
      surveyMarkdown,
      datamapContext,
      validVariables,
    };

    const result = await analyzeTableBase(input, abortSignal);
    results.push(result);

    const duration = Date.now() - startTime;
    logEntry(
      `[BaseFilterAgent] Table "${table.tableId}" completed in ${duration}ms - action: ${result.action}, ${result.tables.length} output tables`
    );

    try {
      onProgress?.(i + 1, tables.length, table.tableId);
    } catch {
      // Ignore progress callback errors
    }
  }

  // Collect scratchpad entries
  const scratchpadEntries = getAndClearScratchpadEntries();
  logEntry(`[BaseFilterAgent] Collected ${scratchpadEntries.length} scratchpad entries`);

  const summary = summarizeBaseFilterResults(results);
  logEntry(
    `[BaseFilterAgent] Processing complete - ${summary.totalInputTables} input → ${summary.totalOutputTables} output tables`
  );
  logEntry(
    `[BaseFilterAgent] Pass: ${summary.passCount}, Filter: ${summary.filterCount}, Split: ${summary.splitCount}`
  );

  const output: BaseFilterAgentOutput = { results };

  // Save outputs
  if (outputDir) {
    await saveDevelopmentOutputs(output, outputDir, processingLog, scratchpadEntries);
  }

  return output;
}

// =============================================================================
// Parallel Processing
// =============================================================================

/**
 * Analyze all tables in parallel with configurable concurrency
 */
export async function analyzeAllTableBasesParallel(
  tables: ExtendedTableDefinition[],
  surveyMarkdown: string,
  verboseDataMap: VerboseDataMapType[],
  options: BaseFilterProcessingOptions = {}
): Promise<BaseFilterAgentOutput> {
  const { outputDir, onProgress, passthrough, abortSignal, concurrency = 3 } = options;
  const processingLog: string[] = [];

  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[BaseFilterAgent] Aborted before processing started');
    throw new DOMException('BaseFilterAgent aborted', 'AbortError');
  }

  // Clear both global and context scratchpads from any previous runs
  clearScratchpadEntries();
  clearAllContextScratchpads();

  logEntry(`[BaseFilterAgent] Starting parallel processing: ${tables.length} tables (concurrency: ${concurrency})`);
  logEntry(`[BaseFilterAgent] Using model: ${getBaseFilterModelName()}`);
  logEntry(`[BaseFilterAgent] Reasoning effort: ${getBaseFilterReasoningEffort()}`);
  logEntry(`[BaseFilterAgent] Survey markdown: ${surveyMarkdown.length} characters`);

  // If passthrough mode or no survey, return all tables unchanged
  if (passthrough || !surveyMarkdown || surveyMarkdown.trim() === '') {
    logEntry(`[BaseFilterAgent] Passthrough mode - returning tables unchanged`);
    const passthroughResults = tables.map((table) => createPassthroughResult(table));

    return { results: passthroughResults };
  }

  // Format the FULL datamap as context (same for all tables, computed once)
  // This allows the agent to see related variables (e.g., Q8 usage when processing Q10 follow-ups)
  const datamapContext = formatFullDatamapContext(verboseDataMap);
  logEntry(`[BaseFilterAgent] Datamap context: ${verboseDataMap.length} variables`);

  // Build set of valid variable names for validation (catch hallucinations)
  const validVariables = new Set<string>(verboseDataMap.map(v => v.column));

  // Create limiter for concurrency control
  const limit = pLimit(concurrency);
  let completed = 0;

  // Track active slots for event emission
  let nextSlotIndex = 0;

  // Process in parallel with limit
  const resultPromises = tables.map((table, index) =>
    limit(async () => {
      if (abortSignal?.aborted) {
        throw new DOMException('BaseFilterAgent aborted', 'AbortError');
      }

      // Assign slot index (round-robin)
      const slotIndex = nextSlotIndex % concurrency;
      nextSlotIndex++;

      const startTime = Date.now();

      // Emit slot:start event
      getPipelineEventBus().emitSlotStart('BaseFilterAgent', slotIndex, table.tableId);

      const input: BaseFilterInput = {
        table,
        surveyMarkdown,
        datamapContext,
        validVariables,
      };

      // Use context-specific scratchpad
      const contextScratchpad = createContextScratchpadTool('BaseFilterAgent', table.tableId);
      const result = await analyzeTableBase(input, abortSignal, contextScratchpad);

      // Emit slot:complete event
      const durationMs = Date.now() - startTime;
      getPipelineEventBus().emitSlotComplete('BaseFilterAgent', slotIndex, table.tableId, durationMs);

      completed++;

      // Emit agent:progress event
      getPipelineEventBus().emitAgentProgress('BaseFilterAgent', completed, tables.length);

      try {
        onProgress?.(completed, tables.length, table.tableId);
      } catch { /* ignore progress errors */ }

      return { result, index };
    })
  );

  const resolvedResults = await Promise.all(resultPromises);

  // Sort by original index to maintain order
  resolvedResults.sort((a, b) => a.index - b.index);

  // Extract results
  const results = resolvedResults.map((r) => r.result);

  // Aggregate scratchpad entries from all contexts
  const contextEntries = getAllContextScratchpadEntries();
  const allScratchpadEntries = contextEntries.flatMap((ctx) =>
    ctx.entries.map((e) => ({ ...e, contextId: ctx.contextId }))
  );
  logEntry(`[BaseFilterAgent] Collected ${allScratchpadEntries.length} scratchpad entries from ${contextEntries.length} contexts`);

  const summary = summarizeBaseFilterResults(results);
  logEntry(
    `[BaseFilterAgent] Parallel processing complete - ${summary.totalInputTables} input → ${summary.totalOutputTables} output tables`
  );
  logEntry(
    `[BaseFilterAgent] Pass: ${summary.passCount}, Filter: ${summary.filterCount}, Split: ${summary.splitCount}`
  );

  const output: BaseFilterAgentOutput = { results };

  // Save outputs
  if (outputDir) {
    // Map context entries to the expected format for saveDevelopmentOutputs
    const scratchpadEntries = allScratchpadEntries.map((e) => ({
      timestamp: e.timestamp,
      agentName: e.agentName,
      action: e.action,
      content: `[${e.contextId}] ${e.content}`,
    }));
    await saveDevelopmentOutputs(output, outputDir, processingLog, scratchpadEntries);
  }

  return output;
}

// =============================================================================
// Helper Functions
// =============================================================================

// Note: formatFullDatamapContext, extractVariablesFromFilter, and validateFilterVariables
// are now imported from '../lib/filters/filterUtils'

/**
 * Post-process agent output to validate filter expressions.
 * If a filter uses non-existent variables (hallucination), clear the filter and flag for review.
 */
function validateAndFixAgentOutput(
  result: BaseFilterTableResult,
  validVariables: Set<string>
): BaseFilterTableResult {
  let hasInvalidFilters = false;
  const fixedTables = result.tables.map(table => {
    if (!table.additionalFilter || table.additionalFilter.trim() === '') {
      return table;
    }

    const validation = validateFilterVariables(table.additionalFilter, validVariables);

    if (!validation.valid) {
      console.warn(
        `[BaseFilterAgent] HALLUCINATION DETECTED in table "${table.tableId}": ` +
        `Filter "${table.additionalFilter}" uses non-existent variables: ${validation.invalidVariables.join(', ')}. ` +
        `Clearing filter and flagging for review.`
      );
      hasInvalidFilters = true;

      // Clear the filter and flag for review
      return {
        ...table,
        additionalFilter: '',
        baseText: '',
        filterReviewRequired: true,
      };
    }

    return table;
  });

  // If we had to fix any filters, update the result
  if (hasInvalidFilters) {
    return {
      ...result,
      tables: fixedTables,
      humanReviewRequired: true,
      reasoning: result.reasoning + ' [VALIDATION: Some filters contained non-existent variables and were cleared.]',
    };
  }

  return result;
}

// =============================================================================
// Development Outputs
// =============================================================================

async function saveDevelopmentOutputs(
  output: BaseFilterAgentOutput,
  outputDir: string,
  processingLog: string[],
  scratchpadEntries: Array<{ timestamp: string; agentName: string; action: string; content: string }>
): Promise<void> {
  try {
    // Create basefilter subfolder for all BaseFilterAgent outputs
    const basefilterDir = path.join(outputDir, 'basefilter');
    await fs.mkdir(basefilterDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    // Save basefilter output
    const filename = `basefilter-output-${timestamp}.json`;
    const filePath = path.join(basefilterDir, filename);

    const summary = summarizeBaseFilterResults(output.results);
    const enhancedOutput = {
      ...output,
      summary,
      processingInfo: {
        timestamp: new Date().toISOString(),
        aiProvider: 'azure-openai',
        model: getBaseFilterModelName(),
        reasoningEffort: getBaseFilterReasoningEffort(),
        processingLog,
      },
    };

    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');
    console.log(`[BaseFilterAgent] Development output saved to basefilter/: ${filename}`);

    // Save raw output (for evaluation comparison)
    const rawOutput = {
      results: output.results,
    };
    const rawPath = path.join(basefilterDir, 'basefilter-output-raw.json');
    await fs.writeFile(rawPath, JSON.stringify(rawOutput, null, 2), 'utf-8');

    // Save scratchpad trace as separate markdown file
    if (scratchpadEntries.length > 0) {
      const scratchpadFilename = `scratchpad-basefilter-${timestamp}.md`;
      const scratchpadPath = path.join(basefilterDir, scratchpadFilename);
      const markdown = formatScratchpadAsMarkdown('BaseFilterAgent', scratchpadEntries);
      await fs.writeFile(scratchpadPath, markdown, 'utf-8');
      console.log(`[BaseFilterAgent] Scratchpad saved to basefilter/: ${scratchpadFilename}`);
    }
  } catch (error) {
    console.error('[BaseFilterAgent] Failed to save development outputs:', error);
  }
}
