/**
 * CrosstabAgent
 * Purpose: Validate banner groups against data map; emit adjusted R expressions + confidence
 * Reads: agent banner groups + processed data map
 * Writes (dev): temp-outputs/output-<ts>/crosstab-output-<ts>.json (with processing info)
 * Invariants: group-by-group validation; uses scratchpad
 */

import { generateText, Output, stepCountIs } from 'ai';
import { ValidationResultSchema, ValidatedGroupSchema, combineValidationResults, type ValidationResultType, type ValidatedGroupType } from '../schemas/agentOutputSchema';
import { DataMapType } from '../schemas/dataMapSchema';
import { BannerGroupType, BannerPlanInputType } from '../schemas/bannerPlanSchema';
import {
  getCrosstabModel,
  getCrosstabModelName,
  getCrosstabModelTokenLimit,
  getCrosstabReasoningEffort,
  getPromptVersions,
} from '../lib/env';
import { crosstabScratchpadTool, clearScratchpadEntries, getAndClearScratchpadEntries, formatScratchpadAsMarkdown } from './tools/scratchpad';
import { getCrosstabPrompt } from '../prompts';
import fs from 'fs/promises';
import path from 'path';

// Get modular validation instructions based on environment variable
const getCrosstabValidationInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getCrosstabPrompt(promptVersions.crosstabPromptVersion);
};

// Process single banner group using Vercel AI SDK
export async function processGroup(
  dataMap: DataMapType,
  group: BannerGroupType,
  abortSignal?: AbortSignal
): Promise<ValidatedGroupType> {
  console.log(`[CrosstabAgent] Processing group: ${group.groupName} (${group.columns.length} columns)`);

  // Check for cancellation before AI call
  if (abortSignal?.aborted) {
    console.log(`[CrosstabAgent] Aborted before processing group ${group.groupName}`);
    throw new DOMException('CrosstabAgent aborted', 'AbortError');
  }

  // Build system prompt with context injection
  const systemPrompt = `
${getCrosstabValidationInstructions()}

CURRENT CONTEXT DATA:

DATA MAP (${dataMap.length} variables):
${JSON.stringify(dataMap, null, 2)}

BANNER GROUP TO VALIDATE:
Group: "${group.groupName}"
${JSON.stringify(group, null, 2)}

PROCESSING REQUIREMENTS:
- Validate all ${group.columns.length} columns in this group
- Generate R syntax for each column's "original" expression
- Provide confidence scores and detailed reasoning
- Use scratchpad to show your validation process

Begin validation now.
`;

  try {
    // Use generateText with structured output and multi-step tool calling
    const { output } = await generateText({
      model: getCrosstabModel(),  // Task-based: crosstab model for complex validation
      system: systemPrompt,
      maxRetries: 3,  // SDK handles transient/network errors
      prompt: `Validate banner group "${group.groupName}" with ${group.columns.length} columns against the data map.`,
      tools: {
        scratchpad: crosstabScratchpadTool,
      },
      stopWhen: stepCountIs(25),  // AI SDK 5+: replaces maxTurns/maxSteps
      maxOutputTokens: Math.min(getCrosstabModelTokenLimit(), 100000),
      // Configure reasoning effort for Azure OpenAI GPT-5/o-series models
      providerOptions: {
        openai: {
          reasoningEffort: getCrosstabReasoningEffort(),
        },
      },
      output: Output.object({
        schema: ValidatedGroupSchema,
      }),
      abortSignal,  // Pass abort signal to AI SDK
    });

    if (!output || !output.columns) {
      throw new Error(`Invalid agent response for group ${group.groupName}`);
    }

    console.log(`[CrosstabAgent] Group ${group.groupName} processed successfully - ${output.columns.length} columns validated`);

    return output;

  } catch (error) {
    // Check if this is an abort error - propagate immediately
    if (error instanceof DOMException && error.name === 'AbortError') {
      console.log(`[CrosstabAgent] Aborted by signal during group ${group.groupName}`);
      throw error;
    }

    const errorMessage = error instanceof Error ? error.message : String(error);
    console.error(`[CrosstabAgent] Error processing group ${group.groupName}:`, errorMessage);

    // Return fallback result with zero confidence (will be skipped by R generator)
    return {
      groupName: group.groupName,
      columns: group.columns.map(col => ({
        name: col.name,
        adjusted: `# Error: Processing failed for "${col.original}"`,
        confidence: 0.0,
        reason: `Processing error: ${errorMessage}. Manual review required.`
      }))
    };
  }
}

// Process all banner groups using group-by-group strategy
export async function processAllGroups(
  dataMap: DataMapType,
  bannerPlan: BannerPlanInputType,
  outputDir?: string,
  onProgress?: (completedGroups: number, totalGroups: number) => void,
  abortSignal?: AbortSignal
): Promise<{ result: ValidationResultType; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  // Check for cancellation before starting
  if (abortSignal?.aborted) {
    console.log('[CrosstabAgent] Aborted before processing started');
    throw new DOMException('CrosstabAgent aborted', 'AbortError');
  }

  // Clear scratchpad from any previous runs
  clearScratchpadEntries();

  logEntry(`[CrosstabAgent] Starting group-by-group processing: ${bannerPlan.bannerCuts.length} groups`);
  logEntry(`[CrosstabAgent] Using model: ${getCrosstabModelName()}`);
  logEntry(`[CrosstabAgent] Reasoning effort: ${getCrosstabReasoningEffort()}`);

  const results: ValidatedGroupType[] = [];

  // Process each group individually (group-by-group approach)
  for (let i = 0; i < bannerPlan.bannerCuts.length; i++) {
    // Check for cancellation between groups
    if (abortSignal?.aborted) {
      console.log(`[CrosstabAgent] Aborted after ${i} groups`);
      throw new DOMException('CrosstabAgent aborted', 'AbortError');
    }

    const group = bannerPlan.bannerCuts[i];
    const groupStartTime = Date.now();

    logEntry(`[CrosstabAgent] Processing group ${i + 1}/${bannerPlan.bannerCuts.length}: "${group.groupName}" (${group.columns.length} columns)`);

    const groupResult = await processGroup(dataMap, group, abortSignal);
    results.push(groupResult);

    const groupDuration = Date.now() - groupStartTime;
    const avgConfidence = groupResult.columns.reduce((sum, col) => sum + col.confidence, 0) / groupResult.columns.length;

    logEntry(`[CrosstabAgent] Group "${group.groupName}" completed in ${groupDuration}ms - Avg confidence: ${avgConfidence.toFixed(2)}`);
    try { onProgress?.(i + 1, bannerPlan.bannerCuts.length); } catch {}
  }

  const combinedResult = combineValidationResults(results);

  // Collect scratchpad entries for the processing log
  const scratchpadEntries = getAndClearScratchpadEntries();
  logEntry(`[CrosstabAgent] Collected ${scratchpadEntries.length} scratchpad entries`);

  // Save outputs with processing log and scratchpad
  if (outputDir) {
    await saveDevelopmentOutputs(combinedResult, outputDir, processingLog, scratchpadEntries);
  }

  logEntry(`[CrosstabAgent] All ${results.length} groups processed successfully - Total columns: ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)}`);

  return { result: combinedResult, processingLog };
}

// Parallel processing option (for future optimization)
export async function processAllGroupsParallel(
  dataMap: DataMapType,
  bannerPlan: BannerPlanInputType
): Promise<{ result: ValidationResultType; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  logEntry(`[CrosstabAgent] Starting parallel processing: ${bannerPlan.bannerCuts.length} groups`);
  logEntry(`[CrosstabAgent] Using model: ${getCrosstabModelName()}`);
  logEntry(`[CrosstabAgent] Reasoning effort: ${getCrosstabReasoningEffort()}`);

  try {
    logEntry(`[CrosstabAgent] Starting parallel group processing`);
    const groupPromises = bannerPlan.bannerCuts.map((group, index) => {
      logEntry(`[CrosstabAgent] Queuing group ${index + 1}: "${group.groupName}"`);
      return processGroup(dataMap, group);
    });

    const results = await Promise.all(groupPromises);
    const combinedResult = combineValidationResults(results);

    logEntry(`[CrosstabAgent] Parallel processing completed - ${results.length} groups, ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)} total columns`);

    return { result: combinedResult, processingLog };

  } catch (error) {
    logEntry(`[CrosstabAgent] Parallel processing failed, falling back to sequential: ${error instanceof Error ? error.message : 'Unknown error'}`);

    // Fall back to sequential processing
    const results: ValidatedGroupType[] = [];

    for (const group of bannerPlan.bannerCuts) {
      logEntry(`[CrosstabAgent] Sequential fallback processing: "${group.groupName}"`);
      const groupResult = await processGroup(dataMap, group);
      results.push(groupResult);
    }

    logEntry(`[CrosstabAgent] Sequential fallback completed`);
    return { result: combineValidationResults(results), processingLog };
  }
}

// Validation helpers
export const validateAgentResult = (result: unknown): ValidationResultType => {
  return ValidationResultSchema.parse(result);
};

export const isValidAgentResult = (result: unknown): result is ValidationResultType => {
  return ValidationResultSchema.safeParse(result).success;
};

// Save development outputs
// NOTE: This replaces both saveDevelopmentOutputsWithTrace() and _saveDevelopmentOutputs()
// Key changes from old version:
//   - Removed: tracingEnabled, tracesDashboard (OpenAI-specific)
//   - Added: aiProvider, model (Azure-specific)
//   - Removed: _traceId parameter (was unused)
//   - Added: scratchpadEntries for reasoning transparency
async function saveDevelopmentOutputs(
  result: ValidationResultType,
  outputDir: string,
  processingLog?: string[],
  scratchpadEntries?: Array<{ timestamp: string; action: string; content: string }>
): Promise<void> {
  try {
    // Create crosstab subfolder for all CrosstabAgent outputs
    const crosstabDir = path.join(outputDir, 'crosstab');
    await fs.mkdir(crosstabDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `crosstab-output-${timestamp}.json`;
    const filePath = path.join(crosstabDir, filename);

    // Enhanced output with processing information
    const enhancedOutput = {
      ...result,
      processingInfo: {
        timestamp: new Date().toISOString(),
        processingMode: 'group-by-group',
        aiProvider: 'azure-openai',
        model: getCrosstabModelName(),
        reasoningEffort: getCrosstabReasoningEffort(),
        totalGroups: result.bannerCuts.length,
        totalColumns: result.bannerCuts.reduce((total, group) => total + group.columns.length, 0),
        averageConfidence: result.bannerCuts.length > 0
          ? result.bannerCuts
              .flatMap(group => group.columns)
              .reduce((sum, col) => sum + col.confidence, 0)
            / result.bannerCuts.flatMap(group => group.columns).length
          : 0,
        processingLog: processingLog || [],
        scratchpadTrace: scratchpadEntries || []
      }
    };

    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');

    // Save raw output (complete model output - for golden dataset comparison)
    // This is the full combined result: bannerCuts with groupName, columns (name, adjusted, confidence, reason)
    const rawPath = path.join(crosstabDir, 'crosstab-output-raw.json');
    await fs.writeFile(rawPath, JSON.stringify(result, null, 2), 'utf-8');

    // Save scratchpad trace as separate markdown file for easy reading
    if (scratchpadEntries && scratchpadEntries.length > 0) {
      const scratchpadFilename = `scratchpad-crosstab-${timestamp}.md`;
      const scratchpadPath = path.join(crosstabDir, scratchpadFilename);
      const markdown = formatScratchpadAsMarkdown('CrosstabAgent', scratchpadEntries);
      await fs.writeFile(scratchpadPath, markdown, 'utf-8');
      console.log(`[CrosstabAgent] Development output saved to crosstab/: ${filename}, ${scratchpadFilename}`);
    } else {
      console.log(`[CrosstabAgent] Development output saved to crosstab/: ${filename}`);
    }
  } catch (error) {
    console.error('[CrosstabAgent] Failed to save development outputs:', error);
  }
}
