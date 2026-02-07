/**
 * FilterTranslatorAgent
 *
 * Purpose: Translate skip logic rules (from SkipLogicAgent) into R filter expressions
 * using the actual datamap. Single AI call — follows CrosstabAgent pattern.
 *
 * Reads: SkipRule[] + VerboseDataMap
 * Writes: {outputDir}/filtertranslator/ outputs
 */

import { generateText, Output, stepCountIs } from 'ai';
import {
  FilterTranslationOutputSchema,
  type SkipRule,
  type FilterTranslationOutput,
  type FilterTranslationResult,
} from '../schemas/skipLogicSchema';
import { type VerboseDataMapType } from '../schemas/processingSchemas';
import {
  getFilterTranslatorModel,
  getFilterTranslatorModelName,
  getFilterTranslatorModelTokenLimit,
  getFilterTranslatorReasoningEffort,
  getPromptVersions,
} from '../lib/env';
import {
  filterTranslatorScratchpadTool,
  clearScratchpadEntries,
  getAndClearScratchpadEntries,
  formatScratchpadAsMarkdown,
} from './tools/scratchpad';
import { getFilterTranslatorPrompt } from '../prompts';
import { formatFullDatamapContext, validateFilterVariables } from '../lib/filters/filterUtils';
import { retryWithPolicyHandling } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import fs from 'fs/promises';
import path from 'path';

// Get modular prompt based on environment variable
const getFilterTranslatorAgentInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getFilterTranslatorPrompt(promptVersions.filterTranslatorPromptVersion);
};

export interface FilterTranslatorProcessingOptions {
  outputDir?: string;
  abortSignal?: AbortSignal;
}

/**
 * Translate skip logic rules into R filter expressions.
 * Single AI call — receives all rules and datamap, outputs all filters.
 */
export async function translateSkipRules(
  rules: SkipRule[],
  verboseDataMap: VerboseDataMapType[],
  options?: FilterTranslatorProcessingOptions
): Promise<FilterTranslationResult> {
  const { outputDir, abortSignal } = options || {};
  const startTime = Date.now();

  console.log(`[FilterTranslatorAgent] Starting filter translation`);
  console.log(`[FilterTranslatorAgent] Using model: ${getFilterTranslatorModelName()}`);
  console.log(`[FilterTranslatorAgent] Reasoning effort: ${getFilterTranslatorReasoningEffort()}`);
  console.log(`[FilterTranslatorAgent] Rules to translate: ${rules.length}`);
  console.log(`[FilterTranslatorAgent] Datamap: ${verboseDataMap.length} variables`);

  // Check for cancellation
  if (abortSignal?.aborted) {
    throw new DOMException('FilterTranslatorAgent aborted', 'AbortError');
  }

  // If no rules to translate, return empty result
  if (rules.length === 0) {
    console.log(`[FilterTranslatorAgent] No rules to translate — returning empty result`);
    return {
      translation: { filters: [] },
      metadata: {
        filtersTranslated: 0,
        highConfidenceCount: 0,
        reviewRequiredCount: 0,
        durationMs: 0,
      },
    };
  }

  // Clear scratchpad
  clearScratchpadEntries();

  // Format the full datamap context
  const datamapContext = formatFullDatamapContext(verboseDataMap);

  const systemPrompt = `
${getFilterTranslatorAgentInstructions()}

## Complete Datamap (All Variables)
<datamap>
${datamapContext}
</datamap>
`;

  const userPrompt = `Translate the following skip/show rules into R filter expressions using the datamap provided above.

For each rule, find the corresponding variables in the datamap and create the R expression.
Provide alternatives where the interpretation is ambiguous.

Rules to translate:
${JSON.stringify(rules, null, 2)}

Important: Each rule may apply to multiple questions. Create a separate filter entry for each questionId in the rule's appliesTo list.`;

  const retryResult = await retryWithPolicyHandling(
    async () => {
      const { output, usage } = await generateText({
        model: getFilterTranslatorModel(),
        system: systemPrompt,
        maxRetries: 3,
        prompt: userPrompt,
        tools: {
          scratchpad: filterTranslatorScratchpadTool,
        },
        stopWhen: stepCountIs(15),
        maxOutputTokens: Math.min(getFilterTranslatorModelTokenLimit(), 100000),
        providerOptions: {
          openai: {
            reasoningEffort: getFilterTranslatorReasoningEffort(),
          },
        },
        output: Output.object({
          schema: FilterTranslationOutputSchema,
        }),
        abortSignal,
      });

      if (!output) {
        throw new Error('Invalid output from FilterTranslatorAgent');
      }

      // Record metrics
      const durationMs = Date.now() - startTime;
      recordAgentMetrics(
        'FilterTranslatorAgent',
        getFilterTranslatorModelName(),
        { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
        durationMs
      );

      return output;
    },
    {
      abortSignal,
      onRetry: (attempt, err) => {
        if (err instanceof DOMException && err.name === 'AbortError') {
          throw err;
        }
        console.warn(`[FilterTranslatorAgent] Retry ${attempt}/3: ${err.message}`);
      },
    }
  );

  if (retryResult.success && retryResult.result) {
    const translation = retryResult.result;
    const durationMs = Date.now() - startTime;

    // Post-validate: check all filter expressions against datamap
    const validVariables = new Set<string>(verboseDataMap.map(v => v.column));
    const validatedFilters = translation.filters.map(filter => {
      // Validate primary expression
      if (filter.filterExpression && filter.filterExpression.trim() !== '') {
        const validation = validateFilterVariables(filter.filterExpression, validVariables);
        if (!validation.valid) {
          console.warn(
            `[FilterTranslatorAgent] INVALID VARIABLES in filter for ${filter.questionId}: ` +
            `"${filter.filterExpression}" uses non-existent variables: ${validation.invalidVariables.join(', ')}. ` +
            `Clearing and flagging for review.`
          );
          return {
            ...filter,
            filterExpression: '',
            humanReviewRequired: true,
            reasoning: filter.reasoning + ` [VALIDATION: Variables ${validation.invalidVariables.join(', ')} not found in datamap.]`,
          };
        }
      }

      // Validate split expressions
      if (filter.splits.length > 0) {
        const validatedSplits = filter.splits.map(split => {
          const splitValidation = validateFilterVariables(split.filterExpression, validVariables);
          if (!splitValidation.valid) {
            console.warn(
              `[FilterTranslatorAgent] INVALID VARIABLES in split for ${filter.questionId}: ` +
              `"${split.filterExpression}" uses: ${splitValidation.invalidVariables.join(', ')}`
            );
            return { ...split, filterExpression: '' };
          }
          return split;
        });

        // If any splits had invalid variables, flag for review
        const hasInvalidSplits = validatedSplits.some(s => s.filterExpression === '');
        if (hasInvalidSplits) {
          return {
            ...filter,
            splits: validatedSplits,
            humanReviewRequired: true,
            reasoning: filter.reasoning + ' [VALIDATION: Some split expressions had non-existent variables.]',
          };
        }

        return { ...filter, splits: validatedSplits };
      }

      return filter;
    });

    const validatedTranslation: FilterTranslationOutput = { filters: validatedFilters };
    const highConfidenceCount = validatedFilters.filter(f => f.confidence >= 0.8).length;
    const reviewRequiredCount = validatedFilters.filter(f => f.humanReviewRequired).length;

    console.log(`[FilterTranslatorAgent] Translated ${validatedFilters.length} filters (${highConfidenceCount} high confidence, ${reviewRequiredCount} need review) in ${durationMs}ms`);

    // Collect scratchpad entries
    const scratchpadEntries = getAndClearScratchpadEntries();

    const result: FilterTranslationResult = {
      translation: validatedTranslation,
      metadata: {
        filtersTranslated: validatedFilters.length,
        highConfidenceCount,
        reviewRequiredCount,
        durationMs,
      },
    };

    // Save outputs
    if (outputDir) {
      await saveFilterTranslatorOutputs(result, outputDir, scratchpadEntries);
    }

    return result;
  }

  // Handle abort
  if (retryResult.error === 'Operation was cancelled') {
    throw new DOMException('FilterTranslatorAgent aborted', 'AbortError');
  }

  // All retries failed
  const errorMessage = retryResult.error || 'Unknown error';
  console.error(`[FilterTranslatorAgent] Translation failed: ${errorMessage}`);

  return {
    translation: { filters: [] },
    metadata: {
      filtersTranslated: 0,
      highConfidenceCount: 0,
      reviewRequiredCount: 0,
      durationMs: Date.now() - startTime,
    },
  };
}

// =============================================================================
// Development Outputs
// =============================================================================

async function saveFilterTranslatorOutputs(
  result: FilterTranslationResult,
  outputDir: string,
  scratchpadEntries: Array<{ timestamp: string; agentName: string; action: string; content: string }>
): Promise<void> {
  try {
    const translatorDir = path.join(outputDir, 'filtertranslator');
    await fs.mkdir(translatorDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    // Save translation output
    const filename = `filtertranslator-output-${timestamp}.json`;
    const filePath = path.join(translatorDir, filename);
    const enhancedOutput = {
      ...result,
      processingInfo: {
        timestamp: new Date().toISOString(),
        aiProvider: 'azure-openai',
        model: getFilterTranslatorModelName(),
        reasoningEffort: getFilterTranslatorReasoningEffort(),
      },
    };
    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');
    console.log(`[FilterTranslatorAgent] Output saved to filtertranslator/: ${filename}`);

    // Save raw output
    const rawPath = path.join(translatorDir, 'filtertranslator-output-raw.json');
    await fs.writeFile(rawPath, JSON.stringify(result.translation, null, 2), 'utf-8');

    // Save scratchpad
    if (scratchpadEntries.length > 0) {
      const scratchpadFilename = `scratchpad-filtertranslator-${timestamp}.md`;
      const scratchpadPath = path.join(translatorDir, scratchpadFilename);
      const markdown = formatScratchpadAsMarkdown('FilterTranslatorAgent', scratchpadEntries);
      await fs.writeFile(scratchpadPath, markdown, 'utf-8');
      console.log(`[FilterTranslatorAgent] Scratchpad saved to filtertranslator/: ${scratchpadFilename}`);
    }
  } catch (error) {
    console.error('[FilterTranslatorAgent] Failed to save outputs:', error);
  }
}
