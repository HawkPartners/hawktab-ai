/**
 * FilterTranslatorAgent
 *
 * Purpose: Translate skip logic rules (from SkipLogicAgent) into R filter expressions
 * using the actual datamap. Per-rule loop with concurrency 3 — follows VerificationAgent pattern.
 *
 * Reads: SkipRule[] + VerboseDataMap
 * Writes: {outputDir}/filtertranslator/ outputs
 */

import { generateText, Output, stepCountIs } from 'ai';
import { RESEARCH_DATA_PREAMBLE, sanitizeForAzureContentFilter } from '../lib/promptSanitization';
import pLimit from 'p-limit';
import {
  FilterTranslationOutputSchema,
  type SkipRule,
  type TableFilter,
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
  createContextScratchpadTool,
  getAllContextScratchpadEntries,
  clearAllContextScratchpads,
  formatScratchpadAsMarkdown,
} from './tools/scratchpad';
import { getFilterTranslatorPrompt } from '../prompts';
import { formatFullDatamapContext, validateFilterVariables } from '../lib/filters/filterUtils';
import { retryWithPolicyHandling, isRateLimitError, type RetryContext } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import { shouldFlagForReview, getReviewThresholds } from '../lib/review';
import { persistAgentErrorAuto } from '../lib/errors/ErrorPersistence';
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
  concurrency?: number;
}

/**
 * Translate skip logic rules into R filter expressions.
 * Per-rule loop with concurrency 3 — each rule gets its own focused AI call.
 */
export async function translateSkipRules(
  rules: SkipRule[],
  verboseDataMap: VerboseDataMapType[],
  options?: FilterTranslatorProcessingOptions
): Promise<FilterTranslationResult> {
  const { outputDir, abortSignal, concurrency = 3 } = options || {};
  const startTime = Date.now();
  const maxAttempts = 10;

  console.log(`[FilterTranslatorAgent] Starting filter translation`);
  console.log(`[FilterTranslatorAgent] Using model: ${getFilterTranslatorModelName()}`);
  console.log(`[FilterTranslatorAgent] Reasoning effort: ${getFilterTranslatorReasoningEffort()}`);
  console.log(`[FilterTranslatorAgent] Rules to translate: ${rules.length}`);
  console.log(`[FilterTranslatorAgent] Datamap: ${verboseDataMap.length} variables`);
  console.log(`[FilterTranslatorAgent] Concurrency: ${concurrency}`);

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

  // Clear context scratchpads
  clearAllContextScratchpads();

  // Format the full datamap context (shared across all calls)
  const datamapContext = formatFullDatamapContext(verboseDataMap);
  const validVariables = new Set<string>(verboseDataMap.map(v => v.column));

  const systemPromptFull = `
${RESEARCH_DATA_PREAMBLE}${getFilterTranslatorAgentInstructions()}

## Complete Datamap (All Variables)
<datamap>
${sanitizeForAzureContentFilter(datamapContext)}
</datamap>
`;

  const policySafeDatamapContext = verboseDataMap
    .map(v => {
      const allowed = v.allowedValues ? v.allowedValues.slice(0, 25).join(', ') : '';
      const normalized = v.normalizedType || 'unknown';
      // Intentionally omit description/answerOptions in policy-safe mode.
      return `${v.column}:\n  Type: ${normalized}\n  Values: ${v.valueType}\n  ${allowed ? `Allowed Values: ${allowed}` : ''}`.trim();
    })
    .join('\n\n');

  const systemPromptPolicySafe = `
${RESEARCH_DATA_PREAMBLE}${getFilterTranslatorAgentInstructions()}

NOTE: Policy-safe mode is enabled due to repeated Azure content filtering. The full datamap's free-text labels may be redacted. Rely on variable names, types, and allowed values.

## Policy-Safe Datamap (Redacted Free Text)
<datamap>
${sanitizeForAzureContentFilter(policySafeDatamapContext)}
</datamap>
`;

  // Process rules in parallel with concurrency limit
  const limit = pLimit(concurrency);
  let completedCount = 0;

  const ruleResults = await Promise.all(
    rules.map((rule) => limit(async () => {
      // Check for cancellation
      if (abortSignal?.aborted) {
        throw new DOMException('FilterTranslatorAgent aborted', 'AbortError');
      }

      const ruleStartTime = Date.now();
      const contextId = rule.ruleId;
      const scratchpad = createContextScratchpadTool('FilterTranslatorAgent', contextId);

      const baseUserPrompt = `Translate the following skip/show rule into R filter expressions using the datamap provided above.

Find the corresponding variables in the datamap and create the R expression.
IMPORTANT: Do NOT assume variable naming patterns from other questions. Check the datamap for the EXACT variable names for each question referenced in this rule.

Prefer the minimal additional constraint (avoid over-filtering). Provide alternatives where the interpretation is ambiguous.
If you cannot confidently map variables, leave the expression empty and set confidence near 0.

Rule to translate:
${JSON.stringify(rule, null, 2)}

Create a separate filter entry for each questionId in the rule's appliesTo list: ${JSON.stringify(rule.appliesTo)}`;

      try {
        const result = await retryWithPolicyHandling(
          async (ctx: RetryContext) => {
            const userPrompt = ctx.attempt > 1
              ? `${baseUserPrompt}

<retry_context>
Your previous attempt failed validation in the pipeline.
Reason: ${ctx.lastErrorSummary}

Fix the issue and retry. DO NOT invent variable names. Use ONLY variables present in the datamap.
</retry_context>`
              : baseUserPrompt;

            const { output, usage } = await generateText({
              model: getFilterTranslatorModel(),
              system: ctx.shouldUsePolicySafeVariant ? systemPromptPolicySafe : systemPromptFull,
              maxRetries: 0, // Centralized outer retries via retryWithPolicyHandling
              prompt: userPrompt,
              tools: {
                scratchpad,
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
              throw new Error(`Invalid output for rule ${rule.ruleId}`);
            }

            // Record metrics per call (ALWAYS do this for every AI call)
            recordAgentMetrics(
              'FilterTranslatorAgent',
              getFilterTranslatorModelName(),
              { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
              Date.now() - ruleStartTime
            );

            // Deterministic validation: fail fast if the model hallucinated variable names.
            // This forces a retry where we can tell the model exactly what was wrong.
            const invalids: string[] = [];
            for (const f of output.filters || []) {
              if (f.filterExpression && f.filterExpression.trim() !== '') {
                const v = validateFilterVariables(f.filterExpression, validVariables);
                if (!v.valid) invalids.push(...v.invalidVariables);
              }
              for (const s of f.splits || []) {
                if (s.filterExpression && s.filterExpression.trim() !== '') {
                  const v = validateFilterVariables(s.filterExpression, validVariables);
                  if (!v.valid) invalids.push(...v.invalidVariables);
                }
              }
            }
            if (invalids.length > 0) {
              const unique = [...new Set(invalids)].slice(0, 25);
              throw new Error(
                `INVALID VARIABLES: ${unique.join(', ')}. Use ONLY datamap columns; do not synthesize names.`
              );
            }

            return output;
          },
          {
            abortSignal,
            maxAttempts,
            onRetry: (attempt, err) => {
              if (err instanceof DOMException && err.name === 'AbortError') {
                throw err;
              }
              const retryType = isRateLimitError(err) ? 'rate limit' : 'error';
              console.warn(`[FilterTranslatorAgent] Retry ${attempt}/${maxAttempts} for rule ${rule.ruleId} (${retryType}): ${err.message.substring(0, 120)}`);
            },
          }
        );

        completedCount++;
        const duration = Date.now() - ruleStartTime;

        if (result.success && result.result) {
          console.log(`[FilterTranslatorAgent] [${completedCount}/${rules.length}] Rule ${rule.ruleId}: ${result.result.filters.length} filters in ${duration}ms`);
          return { ruleId: rule.ruleId, filters: result.result.filters, error: null };
        } else {
          console.warn(`[FilterTranslatorAgent] [${completedCount}/${rules.length}] Rule ${rule.ruleId} failed: ${result.error}`);
          if (outputDir) {
            try {
              await persistAgentErrorAuto({
                outputDir,
                agentName: 'FilterTranslatorAgent',
                severity: 'error',
                actionTaken: 'continued',
                itemId: rule.ruleId,
                error: new Error(result.error || 'Unknown error'),
                meta: {
                  ruleId: rule.ruleId,
                  appliesTo: rule.appliesTo,
                  durationMs: duration,
                },
              });
            } catch {
              // ignore
            }
          }
          return { ruleId: rule.ruleId, filters: [] as TableFilter[], error: result.error || 'Unknown error' };
        }
      } catch (err) {
        if (err instanceof DOMException && err.name === 'AbortError') {
          throw err;
        }
        completedCount++;
        const errorMsg = err instanceof Error ? err.message : String(err);
        console.warn(`[FilterTranslatorAgent] [${completedCount}/${rules.length}] Rule ${rule.ruleId} error: ${errorMsg}`);
        if (outputDir) {
          try {
            await persistAgentErrorAuto({
              outputDir,
              agentName: 'FilterTranslatorAgent',
              severity: 'error',
              actionTaken: 'continued',
              itemId: rule.ruleId,
              error: err,
              meta: {
                ruleId: rule.ruleId,
                appliesTo: rule.appliesTo,
              },
            });
          } catch {
            // ignore
          }
        }
        return { ruleId: rule.ruleId, filters: [] as TableFilter[], error: errorMsg };
      }
    }))
  );

  const durationMs = Date.now() - startTime;

  // Aggregate all filters from all rule results
  const allFilters: TableFilter[] = [];
  for (const ruleResult of ruleResults) {
    allFilters.push(...ruleResult.filters);
  }

  // Post-validate: check all filter expressions against datamap
  // When invalid variables are found, clear the expression and drop confidence to 0
  // so shouldFlagForReview() will catch it downstream.
  const validatedFilters = allFilters.map(filter => {
    // Validate primary expression
    if (filter.filterExpression && filter.filterExpression.trim() !== '') {
      const validation = validateFilterVariables(filter.filterExpression, validVariables);
      if (!validation.valid) {
        console.warn(
          `[FilterTranslatorAgent] INVALID VARIABLES in filter for ${filter.questionId}: ` +
          `"${filter.filterExpression}" uses non-existent variables: ${validation.invalidVariables.join(', ')}. ` +
          `Clearing expression (confidence → 0 triggers review).`
        );
        return {
          ...filter,
          filterExpression: '',
          confidence: 0,
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

      // If any splits had invalid variables, drop confidence to trigger review
      const hasInvalidSplits = validatedSplits.some(s => s.filterExpression === '');
      if (hasInvalidSplits) {
        return {
          ...filter,
          splits: validatedSplits,
          confidence: Math.min(filter.confidence, 0.3),
          reasoning: filter.reasoning + ' [VALIDATION: Some split expressions had non-existent variables.]',
        };
      }

      return { ...filter, splits: validatedSplits };
    }

    return filter;
  });

  const validatedTranslation: FilterTranslationOutput = { filters: validatedFilters };
  const highConfidenceCount = validatedFilters.filter(f => f.confidence >= 0.8).length;
  const filterThreshold = getReviewThresholds().filter;
  const reviewRequiredCount = validatedFilters.filter(f => shouldFlagForReview(f.confidence, filterThreshold)).length;
  const failedRules = ruleResults.filter(r => r.error).length;

  console.log(`[FilterTranslatorAgent] Translated ${validatedFilters.length} filters from ${rules.length} rules (${highConfidenceCount} high confidence, ${reviewRequiredCount} need review, ${failedRules} failed) in ${durationMs}ms`);

  // Collect all scratchpad entries
  const allScratchpadEntries = getAllContextScratchpadEntries();
  const flatScratchpadEntries = allScratchpadEntries.flatMap(ctx => ctx.entries);

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
    await saveFilterTranslatorOutputs(result, outputDir, flatScratchpadEntries);
  }

  return result;
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
