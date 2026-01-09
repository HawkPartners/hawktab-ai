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
} from '../lib/env';
import {
  verificationScratchpadTool,
  clearScratchpadEntries,
  getAndClearScratchpadEntries,
  formatScratchpadAsMarkdown,
} from './tools/scratchpad';
import { getVerificationPrompt } from '../prompts/verification';
import fs from 'fs/promises';
import path from 'path';

// Retry configuration for transient failures
const MAX_RETRIES = 2;

// =============================================================================
// Types
// =============================================================================

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
}

export interface VerificationProcessingOptions {
  /** Output directory for development outputs (full path) */
  outputDir?: string;
  /** Progress callback */
  onProgress?: (completed: number, total: number, tableId: string) => void;
  /** Whether to skip verification and pass through (e.g., when no survey available) */
  passthrough?: boolean;
}

// =============================================================================
// Single Table Processing
// =============================================================================

/**
 * Process a single table through VerificationAgent
 */
export async function verifyTable(input: VerificationInput): Promise<VerificationAgentOutput> {
  console.log(`[VerificationAgent] Processing table: ${input.table.tableId}`);

  // If no survey markdown, pass through unchanged
  if (!input.surveyMarkdown || input.surveyMarkdown.trim() === '') {
    console.log(`[VerificationAgent] No survey markdown - passing through unchanged`);
    return createPassthroughOutput(input.table);
  }

  // Build system prompt with survey and datamap context
  const systemPrompt = `
${getVerificationPrompt()}

## Survey Document
<survey>
${input.surveyMarkdown}
</survey>

## Variable Context (Datamap)
<datamap>
${input.datamapContext}
</datamap>
`;

  const userPrompt = `
Review this table and output the desired end state:

Question: ${input.questionId} - ${input.questionText}

Table Definition:
${JSON.stringify(input.table, null, 2)}

Analyze the table against the survey document. Fix labels, split if needed, add NETs if appropriate, create T2B if it's a scale, or flag for exclusion if low value. Output the tables array representing the desired end state.
`;

  let lastError: Error | null = null;

  // Retry loop - try up to MAX_RETRIES + 1 times
  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    if (attempt > 0) {
      console.log(`[VerificationAgent] Retry attempt ${attempt}/${MAX_RETRIES} for table: ${input.table.tableId}`);
    }

    try {
      // Use generateText with structured output
      const { output } = await generateText({
        model: getVerificationModel(),
        system: systemPrompt,
        prompt: userPrompt,
        tools: {
          scratchpad: verificationScratchpadTool,
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
      });

      if (!output || !output.tables || output.tables.length === 0) {
        console.warn(
          `[VerificationAgent] Invalid output for table ${input.table.tableId} - passing through`
        );
        return createPassthroughOutput(input.table);
      }

      console.log(
        `[VerificationAgent] Table ${input.table.tableId} processed - ${output.tables.length} tables, ${output.changes.length} changes, confidence: ${output.confidence.toFixed(2)}`
      );

      return output;

    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      console.error(`[VerificationAgent] Error processing table ${input.table.tableId} (attempt ${attempt + 1}/${MAX_RETRIES + 1}):`, lastError.message);

      // Continue to retry unless it's the last attempt
      if (attempt < MAX_RETRIES) {
        continue;
      }
    }
  }

  // All retries exhausted - return passthrough
  console.error(`[VerificationAgent] All retries exhausted for table ${input.table.tableId}`);
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
  const { outputDir, onProgress, passthrough } = options;
  const processingLog: string[] = [];

  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

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

    const result = await verifyTable(input);
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

    // Save raw output (just what the agent produced - for golden dataset comparison)
    const rawOutput = {
      tables: results.tables,
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
