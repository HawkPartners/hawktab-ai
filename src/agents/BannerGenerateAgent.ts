/**
 * BannerGenerateAgent
 *
 * Purpose: Generate banner cuts from a verbose datamap when no banner plan document exists.
 * Uses AI to design analytically valuable cross-tabulation groups from survey variable metadata.
 *
 * Inputs: verboseDataMap, optional researchObjectives/cutSuggestions/projectType
 * Output: AgentBannerGroup[] (identical shape to BannerAgent output)
 *
 * Follows LoopSemanticsPolicyAgent pattern: standalone async function, not a class.
 */

import { generateText, Output, stepCountIs } from 'ai';
import { z } from 'zod';
import { RESEARCH_DATA_PREAMBLE, sanitizeForAzureContentFilter } from '../lib/promptSanitization';
import {
  getBannerGenerateModel,
  getBannerGenerateModelName,
  getBannerGenerateModelTokenLimit,
  getBannerGenerateReasoningEffort,
} from '../lib/env';
import {
  createContextScratchpadTool,
  getAllContextScratchpadEntries,
  clearAllContextScratchpads,
  formatScratchpadAsMarkdown,
} from './tools/scratchpad';
import { getBannerGeneratePrompt, buildBannerGenerateUserPrompt } from '../prompts';
import { retryWithPolicyHandling } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import type { AgentBannerGroup } from '../lib/contextBuilder';
import type { VerboseDataMap } from '../lib/processors/DataMapProcessor';
import fs from 'fs/promises';
import path from 'path';

// =============================================================================
// Types
// =============================================================================

export interface BannerGenerateInput {
  /** Verbose datamap from DataMapProcessor */
  verboseDataMap: VerboseDataMap[];
  /** Optional research objectives to guide cut selection */
  researchObjectives?: string;
  /** Optional cut suggestions (treated as near-requirements) */
  cutSuggestions?: string;
  /** Optional project type hint */
  projectType?: string;
  /** Output directory for saving artifacts */
  outputDir: string;
  /** Abort signal for cancellation */
  abortSignal?: AbortSignal;
}

export interface BannerGenerateResult {
  /** Generated banner groups (same shape as BannerAgent output) */
  agent: AgentBannerGroup[];
  /** Model confidence in the generated banner */
  confidence: number;
  /** Brief reasoning summary */
  reasoning: string;
}

// =============================================================================
// Output Schema
// =============================================================================

const BannerGenerateOutputSchema = z.object({
  bannerGroups: z.array(z.object({
    groupName: z.string().describe('Descriptive name for this banner group'),
    columns: z.array(z.object({
      name: z.string().describe('Display label for this column'),
      original: z.string().describe('Filter expression referencing datamap variables (e.g., "Q3==1")'),
    })).describe('Columns in this banner group (3-12 recommended)'),
  })).describe('3-7 banner groups'),
  confidence: z.number().min(0).max(1).describe('Confidence in the quality of generated cuts (0-1)'),
  reasoning: z.string().describe('Brief summary of design rationale'),
});

// =============================================================================
// Main Entry Point
// =============================================================================

/**
 * Generate banner cuts from a verbose datamap using AI.
 * Called when no banner plan document is available.
 */
export async function generateBannerCuts(
  input: BannerGenerateInput,
): Promise<BannerGenerateResult> {
  console.log(`[BannerGenerateAgent] Generating banner cuts from ${input.verboseDataMap.length} variables`);
  const startTime = Date.now();

  // Check for cancellation
  if (input.abortSignal?.aborted) {
    throw new DOMException('BannerGenerateAgent aborted', 'AbortError');
  }

  // Build prompts
  const systemPrompt = `${RESEARCH_DATA_PREAMBLE}${getBannerGeneratePrompt()}`;

  // Build compact datamap for the user prompt
  const compactDataMap = input.verboseDataMap.map(v => ({
    column: v.column,
    description: sanitizeForAzureContentFilter(v.description || ''),
    normalizedType: v.normalizedType,
    answerOptions: sanitizeForAzureContentFilter(v.answerOptions || ''),
  }));

  const userPrompt = buildBannerGenerateUserPrompt({
    verboseDataMap: compactDataMap,
    researchObjectives: input.researchObjectives,
    cutSuggestions: input.cutSuggestions,
    projectType: input.projectType,
  });

  // Clear scratchpad from any previous runs
  clearAllContextScratchpads();

  // Create context-isolated scratchpad
  const scratchpad = createContextScratchpadTool('BannerGenerate', 'generate');

  const maxAttempts = 10;

  // Wrap the AI call with retry logic for policy errors
  const retryResult = await retryWithPolicyHandling(
    async () => {
      const { output, usage } = await generateText({
        model: getBannerGenerateModel(),
        system: systemPrompt,
        maxRetries: 0, // Centralized outer retries via retryWithPolicyHandling
        prompt: userPrompt,
        tools: {
          scratchpad,
        },
        stopWhen: stepCountIs(15),
        maxOutputTokens: Math.min(getBannerGenerateModelTokenLimit(), 100000),
        providerOptions: {
          openai: {
            reasoningEffort: getBannerGenerateReasoningEffort(),
          },
        },
        output: Output.object({
          schema: BannerGenerateOutputSchema,
        }),
        abortSignal: input.abortSignal,
      });

      if (!output || !output.bannerGroups || output.bannerGroups.length === 0) {
        throw new Error('BannerGenerateAgent produced empty output');
      }

      // Record metrics
      const durationMs = Date.now() - startTime;
      recordAgentMetrics(
        'BannerGenerateAgent',
        getBannerGenerateModelName(),
        { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
        durationMs,
      );

      return output;
    },
    {
      abortSignal: input.abortSignal,
      maxAttempts,
      onRetry: (attempt, err) => {
        if (err instanceof DOMException && err.name === 'AbortError') {
          throw err;
        }
        console.warn(`[BannerGenerateAgent] Retry ${attempt}/${maxAttempts}: ${err.message.substring(0, 120)}`);
      },
    },
  );

  // Handle abort
  if (retryResult.error === 'Operation was cancelled') {
    throw new DOMException('BannerGenerateAgent aborted', 'AbortError');
  }

  if (!retryResult.success || !retryResult.result) {
    throw new Error(`BannerGenerateAgent failed: ${retryResult.error || 'Unknown error'}`);
  }

  const result = retryResult.result;

  // Convert to AgentBannerGroup[] format
  const agentBanner: AgentBannerGroup[] = result.bannerGroups.map(g => ({
    groupName: g.groupName,
    columns: g.columns.map(c => ({
      name: c.name,
      original: c.original,
    })),
  }));

  // Save artifacts
  const bannerDir = path.join(input.outputDir, 'banner');
  await fs.mkdir(bannerDir, { recursive: true });

  // Save generated banner JSON
  await fs.writeFile(
    path.join(bannerDir, 'banner-generated.json'),
    JSON.stringify({
      source: 'BannerGenerateAgent',
      confidence: result.confidence,
      reasoning: result.reasoning,
      bannerGroups: agentBanner,
      metadata: {
        variableCount: input.verboseDataMap.length,
        researchObjectives: input.researchObjectives || null,
        cutSuggestions: input.cutSuggestions || null,
        projectType: input.projectType || null,
        model: getBannerGenerateModelName(),
        durationMs: Date.now() - startTime,
      },
    }, null, 2),
    'utf-8',
  );

  // Save scratchpad trace
  const contextEntries = getAllContextScratchpadEntries();
  const allScratchpadEntries = contextEntries.flatMap((ctx) =>
    ctx.entries.map((e) => ({ ...e, contextId: ctx.contextId }))
  );
  if (allScratchpadEntries.length > 0) {
    const scratchpadMd = formatScratchpadAsMarkdown('BannerGenerateAgent', allScratchpadEntries);
    await fs.writeFile(
      path.join(bannerDir, 'scratchpad-banner-generate.md'),
      scratchpadMd,
      'utf-8',
    );
    clearAllContextScratchpads();
  }

  const totalColumns = agentBanner.reduce((sum, g) => sum + g.columns.length, 0);
  console.log(
    `[BannerGenerateAgent] Done: ${agentBanner.length} groups, ${totalColumns} columns ` +
    `(confidence: ${result.confidence.toFixed(2)}, ${Date.now() - startTime}ms)`,
  );

  return {
    agent: agentBanner,
    confidence: result.confidence,
    reasoning: result.reasoning,
  };
}
