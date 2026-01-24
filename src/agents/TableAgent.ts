/**
 * @deprecated This module is deprecated as of Part 4 refactor.
 *
 * TableGenerator.ts now handles table generation deterministically:
 *   VerboseDataMap → DataMapGrouper → TableGenerator → VerificationAgent
 *
 * This LLM-based approach is kept for reference but will be deleted in future cleanup.
 *
 * New files to use instead:
 * - src/lib/tables/DataMapGrouper.ts - Groups datamap by parent question
 * - src/lib/tables/TableGenerator.ts - Deterministic table generation
 *
 * ---
 * Original description:
 * TableAgent
 * Purpose: Decide how survey data should be displayed as crosstab tables
 * Reads: Grouped datamap variables (VerboseDataMapType[])
 * Writes (dev): temp-outputs/output-<ts>/table-output-<ts>.json
 * Invariants: Maps data structures (normalizedType) to display formats (tableType)
 */

import { generateText, Output, stepCountIs } from 'ai';
import {
  TableAgentInputSchema,
  TableAgentOutputSchema,
  type TableAgentInput,
  type TableAgentOutput,
  type TableDefinition,
} from '../schemas/tableAgentSchema';
import { type VerboseDataMapType } from '../schemas/processingSchemas';
import {
  getTableModel,
  getTableModelName,
  getTableModelTokenLimit,
  getTableReasoningEffort,
  getPromptVersions,
} from '../lib/env';
import { tableScratchpadTool, clearScratchpadEntries, getAndClearScratchpadEntries, formatScratchpadAsMarkdown } from './tools/scratchpad';
import { getTablePrompt } from '../prompts';
import { retryWithPolicyHandling } from '../lib/retryWithPolicyHandling';
import fs from 'fs/promises';
import path from 'path';

// Get modular prompt based on environment variable
const getTableAgentInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getTablePrompt(promptVersions.tablePromptVersion);
};

// =============================================================================
// Grouping Logic - Pre-processing before agent calls
// =============================================================================

/**
 * Normalized types to exclude from TableAgent processing
 * These types cannot be meaningfully displayed in crosstabs
 */
export const EXCLUDED_NORMALIZED_TYPES = new Set([
  'admin',      // Administrative/metadata fields (record IDs, timestamps, etc.)
  'text_open',  // Free text responses - can't crosstab open-ended text
]);

/**
 * Check if a variable should be included in TableAgent processing
 */
export function isProcessableVariable(variable: VerboseDataMapType): boolean {
  const normalizedType = variable.normalizedType || 'unknown';
  return !EXCLUDED_NORMALIZED_TYPES.has(normalizedType);
}

/**
 * Group verbose datamap variables by parent question
 * Returns array of TableAgentInput, one per question group
 *
 * Pre-filters to exclude admin and text_open types (not reportable)
 */
export function groupDataMapByParent(dataMap: VerboseDataMapType[]): TableAgentInput[] {
  const groups: TableAgentInput[] = [];

  // Pre-filter: exclude non-processable types
  const processableData = dataMap.filter(isProcessableVariable);

  // Log filtering stats
  const excludedCount = dataMap.length - processableData.length;
  if (excludedCount > 0) {
    console.log(`[TableAgent] Filtered out ${excludedCount} non-processable variables (admin, text_open)`);
  }

  // Separate parents and subs from processable data
  const parents = processableData.filter(v => v.level === 'parent');
  const subs = processableData.filter(v => v.level === 'sub');

  // Group subs by parentQuestion
  const subGroups = new Map<string, VerboseDataMapType[]>();
  for (const sub of subs) {
    const parent = sub.parentQuestion;
    if (!parent || parent === 'NA') continue;
    if (!subGroups.has(parent)) subGroups.set(parent, []);
    subGroups.get(parent)!.push(sub);
  }

  // Create input for each sub group
  for (const [parentId, items] of subGroups) {
    // Check if all items share the same context
    const firstContext = items[0]?.context;
    const allSameContext = items.every(item => item.context === firstContext);

    // Only use context as questionText if all items share it
    // If context varies (e.g., different treatments), use parentId to avoid confusion
    // Each item still has its own context field for the agent to see
    const questionText = (allSameContext && firstContext) ? firstContext : parentId;

    groups.push({
      questionId: parentId,
      questionText,
      items: items.map(item => ({
        column: item.column,
        label: item.description,
        context: item.context,  // Pass context for treatment/item identifiers
        normalizedType: item.normalizedType || 'unknown',
        valueType: item.valueType,
        rangeMin: item.rangeMin,
        rangeMax: item.rangeMax,
        allowedValues: item.allowedValues,
        scaleLabels: item.scaleLabels,
      }))
    });
  }

  // Also include standalone parents (no subs) that aren't admin
  const parentsWithSubs = new Set(subGroups.keys());
  for (const parent of parents) {
    if (parentsWithSubs.has(parent.column)) continue;

    groups.push({
      questionId: parent.column,
      questionText: parent.description,
      items: [{
        column: parent.column,
        label: parent.description,
        context: parent.context,  // Pass context for consistency
        normalizedType: parent.normalizedType || 'unknown',
        valueType: parent.valueType,
        rangeMin: parent.rangeMin,
        rangeMax: parent.rangeMax,
        allowedValues: parent.allowedValues,
        scaleLabels: parent.scaleLabels,
      }]
    });
  }

  return groups;
}

// =============================================================================
// Agent Processing
// =============================================================================

/**
 * Process single question group using Vercel AI SDK
 */
export async function processQuestionGroup(
  input: TableAgentInput,
  abortSignal?: AbortSignal
): Promise<TableAgentOutput> {
  console.log(`[TableAgent] Processing question: ${input.questionId} (${input.items.length} items)`);

  // Check for cancellation before AI call
  if (abortSignal?.aborted) {
    console.log(`[TableAgent] Aborted before processing question ${input.questionId}`);
    throw new DOMException('TableAgent aborted', 'AbortError');
  }

  // Build system prompt with context injection
  const systemPrompt = `
${getTableAgentInstructions()}

CURRENT QUESTION GROUP:

${JSON.stringify(input, null, 2)}

PROCESSING REQUIREMENTS:
- Analyze the ${input.items.length} items in this question
- Determine the appropriate tableType based on normalizedType and semantics
- Generate one or more table definitions
- Provide confidence score and reasoning

Begin analysis now.
`;

  // Check if this is an abort error
  const checkAbortError = (error: unknown): boolean => {
    return error instanceof DOMException && error.name === 'AbortError';
  };

  // Wrap the AI call with retry logic for policy errors
  const retryResult = await retryWithPolicyHandling(
    async () => {
      const { output } = await generateText({
        model: getTableModel(),  // Task-based: table model for display decisions
        system: systemPrompt,
        maxRetries: 3,  // SDK handles transient/network errors
        prompt: `Analyze question "${input.questionId}" with ${input.items.length} items and decide how to display as crosstab table(s).`,
        tools: {
          scratchpad: tableScratchpadTool,
        },
        stopWhen: stepCountIs(15),  // Fewer steps needed than CrosstabAgent
        maxOutputTokens: Math.min(getTableModelTokenLimit(), 100000),
        // Configure reasoning effort for Azure OpenAI GPT-5/o-series models
        providerOptions: {
          openai: {
            reasoningEffort: getTableReasoningEffort(),
          },
        },
        output: Output.object({
          schema: TableAgentOutputSchema,
        }),
        abortSignal,  // Pass abort signal to AI SDK
      });

      if (!output || !output.tables) {
        throw new Error(`Invalid agent response for question ${input.questionId}`);
      }

      return output;
    },
    {
      abortSignal,
      onRetry: (attempt, err) => {
        // Check for abort errors and propagate them
        if (checkAbortError(err)) {
          throw err;
        }
        console.warn(`[TableAgent] Retry ${attempt}/3 for question "${input.questionId}": ${err.message}`);
      },
    }
  );

  if (retryResult.success && retryResult.result) {
    console.log(`[TableAgent] Question ${input.questionId} processed - ${retryResult.result.tables.length} tables generated, confidence: ${retryResult.result.confidence.toFixed(2)}`);
    return retryResult.result;
  }

  // Handle abort errors
  if (retryResult.error === 'Operation was cancelled') {
    console.log(`[TableAgent] Aborted by signal during question ${input.questionId}`);
    throw new DOMException('TableAgent aborted', 'AbortError');
  }

  // All retries failed - return fallback result with low confidence
  const errorMessage = retryResult.error || 'Unknown error';
  const retryContext = retryResult.wasPolicyError
    ? ` (failed after ${retryResult.attempts} retries due to content policy)`
    : '';
  console.error(`[TableAgent] Error processing question ${input.questionId}:`, errorMessage + retryContext);

  return {
    questionId: input.questionId,
    questionText: input.questionText,
    tables: [{
      tableId: input.questionId.toLowerCase(),
      title: `Error: ${input.questionId}`,
      tableType: 'frequency',  // Safe default
      rows: input.items.map(item => ({
        variable: item.column,
        label: item.label,
        filterValue: '',  // Required field for Azure compatibility
      })),
      hints: [],  // No hints for fallback
    }],
    confidence: 0.0,
    reasoning: `Error processing question: ${errorMessage}${retryContext}. Manual review required.`,
  };
}

/**
 * Process all question groups
 */
export async function processAllGroups(
  groups: TableAgentInput[],
  outputDir?: string,
  onProgress?: (completed: number, total: number) => void,
  abortSignal?: AbortSignal
): Promise<{ results: TableAgentOutput[]; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[TableAgent] Aborted before processing started');
    throw new DOMException('TableAgent aborted', 'AbortError');
  }

  // Clear scratchpad from any previous runs
  clearScratchpadEntries();

  logEntry(`[TableAgent] Starting processing: ${groups.length} question groups`);
  logEntry(`[TableAgent] Using model: ${getTableModelName()}`);
  logEntry(`[TableAgent] Reasoning effort: ${getTableReasoningEffort()}`);

  const results: TableAgentOutput[] = [];

  // Process each group individually
  for (let i = 0; i < groups.length; i++) {
    // Check for cancellation between groups
    if (abortSignal?.aborted) {
      console.log(`[TableAgent] Aborted after ${i} groups`);
      throw new DOMException('TableAgent aborted', 'AbortError');
    }

    const group = groups[i];
    const startTime = Date.now();

    logEntry(`[TableAgent] Processing group ${i + 1}/${groups.length}: "${group.questionId}" (${group.items.length} items)`);

    const result = await processQuestionGroup(group, abortSignal);
    results.push(result);

    const duration = Date.now() - startTime;
    logEntry(`[TableAgent] Question "${group.questionId}" completed in ${duration}ms - ${result.tables.length} tables, confidence: ${result.confidence.toFixed(2)}`);

    try { onProgress?.(i + 1, groups.length); } catch {}
  }

  // Collect scratchpad entries
  const scratchpadEntries = getAndClearScratchpadEntries();
  logEntry(`[TableAgent] Collected ${scratchpadEntries.length} scratchpad entries`);

  // Calculate summary stats
  const totalTables = results.reduce((sum, r) => sum + r.tables.length, 0);
  const avgConfidence = results.length > 0
    ? results.reduce((sum, r) => sum + r.confidence, 0) / results.length
    : 0;

  logEntry(`[TableAgent] Processing complete - ${results.length} groups → ${totalTables} tables, avg confidence: ${avgConfidence.toFixed(2)}`);

  // Save outputs
  if (outputDir) {
    await saveDevelopmentOutputs(groups, results, outputDir, processingLog, scratchpadEntries);
  }

  return { results, processingLog };
}

/**
 * Process from raw verbose datamap (convenience function)
 * Handles grouping and processing in one call
 */
export async function processDataMap(
  dataMap: VerboseDataMapType[],
  outputDir?: string,
  onProgress?: (completed: number, total: number) => void,
  abortSignal?: AbortSignal
): Promise<{ results: TableAgentOutput[]; processingLog: string[] }> {
  const groups = groupDataMapByParent(dataMap);
  console.log(`[TableAgent] Grouped ${dataMap.length} variables into ${groups.length} question groups`);
  return processAllGroups(groups, outputDir, onProgress, abortSignal);
}

/**
 * Process question groups with callback for each table produced.
 * Used by PathBCoordinator for producer-consumer pipeline.
 *
 * This function enables overlapping execution with VerificationAgent:
 * - Tables are emitted via onTable() as each question group completes
 * - VerificationAgent can start processing immediately without waiting for all tables
 *
 * @param groups - Pre-grouped question inputs from groupDataMapByParent()
 * @param onTable - Callback invoked for each table produced (for queue push)
 * @param options - Processing options including outputDir, abortSignal, onProgress
 * @returns Full results and processing log (same as processAllGroups)
 */
export async function processQuestionGroupsWithCallback(
  groups: TableAgentInput[],
  onTable: (table: TableDefinition, questionId: string, questionText: string) => void,
  options: {
    outputDir?: string;
    abortSignal?: AbortSignal;
    onProgress?: (completed: number, total: number) => void;
  } = {}
): Promise<{ results: TableAgentOutput[]; processingLog: string[] }> {
  const { outputDir, abortSignal, onProgress } = options;
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[TableAgent] Aborted before processing started');
    throw new DOMException('TableAgent aborted', 'AbortError');
  }

  // Clear scratchpad from any previous runs
  clearScratchpadEntries();

  logEntry(`[TableAgent] Starting streaming processing: ${groups.length} question groups`);
  logEntry(`[TableAgent] Using model: ${getTableModelName()}`);
  logEntry(`[TableAgent] Reasoning effort: ${getTableReasoningEffort()}`);

  const results: TableAgentOutput[] = [];
  let totalTablesEmitted = 0;

  // Process each group individually
  for (let i = 0; i < groups.length; i++) {
    // Check for cancellation between groups
    if (abortSignal?.aborted) {
      console.log(`[TableAgent] Aborted after ${i} groups`);
      throw new DOMException('TableAgent aborted', 'AbortError');
    }

    const group = groups[i];
    const startTime = Date.now();

    logEntry(`[TableAgent] Processing group ${i + 1}/${groups.length}: "${group.questionId}" (${group.items.length} items)`);

    const result = await processQuestionGroup(group, abortSignal);
    results.push(result);

    // Emit each table via callback for producer-consumer queue
    for (const table of result.tables) {
      try {
        onTable(table, result.questionId, result.questionText);
        totalTablesEmitted++;
      } catch (err) {
        // Log but don't fail on callback errors
        console.error(`[TableAgent] Error in onTable callback for ${table.tableId}:`, err);
      }
    }

    const duration = Date.now() - startTime;
    logEntry(`[TableAgent] Question "${group.questionId}" completed in ${duration}ms - ${result.tables.length} tables emitted, confidence: ${result.confidence.toFixed(2)}`);

    try { onProgress?.(i + 1, groups.length); } catch {}
  }

  // Collect scratchpad entries
  const scratchpadEntries = getAndClearScratchpadEntries();
  logEntry(`[TableAgent] Collected ${scratchpadEntries.length} scratchpad entries`);

  // Calculate summary stats
  const avgConfidence = results.length > 0
    ? results.reduce((sum, r) => sum + r.confidence, 0) / results.length
    : 0;

  logEntry(`[TableAgent] Streaming complete - ${results.length} groups → ${totalTablesEmitted} tables emitted, avg confidence: ${avgConfidence.toFixed(2)}`);

  // Save outputs
  if (outputDir) {
    await saveDevelopmentOutputs(groups, results, outputDir, processingLog, scratchpadEntries);
  }

  return { results, processingLog };
}

// =============================================================================
// Output Helpers
// =============================================================================

/**
 * Get all table definitions from results
 */
export function getAllTableDefinitions(results: TableAgentOutput[]): TableDefinition[] {
  return results.flatMap(r => r.tables);
}

/**
 * Get table definitions by type
 */
export function getTableDefinitionsByType(
  results: TableAgentOutput[],
  tableType: string
): TableDefinition[] {
  return results
    .flatMap(r => r.tables)
    .filter(t => t.tableType === tableType);
}

/**
 * Calculate overall confidence
 */
export function calculateOverallConfidence(results: TableAgentOutput[]): number {
  if (results.length === 0) return 0;
  return results.reduce((sum, r) => sum + r.confidence, 0) / results.length;
}

// =============================================================================
// Validation
// =============================================================================

export const validateTableAgentInput = (input: unknown): TableAgentInput => {
  return TableAgentInputSchema.parse(input);
};

export const validateTableAgentOutput = (output: unknown): TableAgentOutput => {
  return TableAgentOutputSchema.parse(output);
};

export const isValidTableAgentOutput = (output: unknown): output is TableAgentOutput => {
  return TableAgentOutputSchema.safeParse(output).success;
};

// =============================================================================
// Development Outputs
// =============================================================================

async function saveDevelopmentOutputs(
  _groups: TableAgentInput[],  // Kept for API compatibility; grouped data saved by DataMapProcessor
  results: TableAgentOutput[],
  outputDir: string,
  processingLog?: string[],
  scratchpadEntries?: Array<{ timestamp: string; action: string; content: string }>
): Promise<void> {
  try {
    // Create table subfolder for TableAgent outputs
    const tableDir = path.join(outputDir, 'table');
    await fs.mkdir(tableDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    // NOTE: Grouped datamap input is already saved by DataMapProcessor at root level
    // (as <dataset>-datamap-table-agent-*.json), so we don't duplicate it here

    const filename = `table-output-${timestamp}.json`;
    const filePath = path.join(tableDir, filename);

    // Calculate summary statistics
    const totalTables = results.reduce((sum, r) => sum + r.tables.length, 0);
    const avgConfidence = results.length > 0
      ? results.reduce((sum, r) => sum + r.confidence, 0) / results.length
      : 0;

    // Table type distribution
    const tableTypeDistribution: Record<string, number> = {};
    for (const result of results) {
      for (const table of result.tables) {
        tableTypeDistribution[table.tableType] = (tableTypeDistribution[table.tableType] || 0) + 1;
      }
    }

    // Enhanced output with processing information
    const enhancedOutput = {
      results,
      processingInfo: {
        timestamp: new Date().toISOString(),
        aiProvider: 'azure-openai',
        model: getTableModelName(),
        reasoningEffort: getTableReasoningEffort(),
        totalQuestionGroups: results.length,
        totalTablesGenerated: totalTables,
        averageConfidence: avgConfidence,
        tableTypeDistribution,
        processingLog: processingLog || [],
        scratchpadTrace: scratchpadEntries || [],
      },
    };

    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');

    // Save raw output (complete model output - for golden dataset comparison)
    // This is the full combined result: array of TableAgentOutput (questionId, questionText, tables, confidence, reasoning)
    const rawPath = path.join(tableDir, 'table-output-raw.json');
    await fs.writeFile(rawPath, JSON.stringify({ results }, null, 2), 'utf-8');

    // Save scratchpad trace as separate markdown file
    if (scratchpadEntries && scratchpadEntries.length > 0) {
      const scratchpadFilename = `scratchpad-table-${timestamp}.md`;
      const scratchpadPath = path.join(tableDir, scratchpadFilename);
      const markdown = formatScratchpadAsMarkdown('TableAgent', scratchpadEntries);
      await fs.writeFile(scratchpadPath, markdown, 'utf-8');
      console.log(`[TableAgent] Development output saved to table/: ${filename}, ${scratchpadFilename}`);
    } else {
      console.log(`[TableAgent] Development output saved to table/: ${filename}`);
    }
  } catch (error) {
    console.error('[TableAgent] Failed to save development outputs:', error);
  }
}
