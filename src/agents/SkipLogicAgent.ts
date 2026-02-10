/**
 * SkipLogicAgent
 *
 * Purpose: Read the survey document once and extract ALL skip/show/filter rules.
 * Replaces the per-table BaseFilterAgent approach with a single extraction pass.
 *
 * Supports two modes:
 * - Single-pass: surveys under SKIPLOGIC_CHUNK_THRESHOLD (default 40K chars)
 * - Chunked: large surveys split at question boundaries, processed sequentially
 *   with accumulated context from prior chunks
 *
 * Reads: Survey markdown
 * Writes: {outputDir}/skiplogic/ outputs
 */

import { generateText, Output, stepCountIs } from 'ai';
import { RESEARCH_DATA_PREAMBLE, sanitizeForAzureContentFilter } from '../lib/promptSanitization';
import {
  SkipLogicExtractionOutputSchema,
  type SkipLogicResult,
  type SkipRule,
} from '../schemas/skipLogicSchema';
import {
  getSkipLogicModel,
  getSkipLogicModelName,
  getSkipLogicModelTokenLimit,
  getSkipLogicReasoningEffort,
  getPromptVersions,
} from '../lib/env';
import {
  skipLogicScratchpadTool,
  clearScratchpadEntries,
  getAndClearScratchpadEntries,
  getScratchpadEntries,
  formatScratchpadAsMarkdown,
  createContextScratchpadTool,
  getAllContextScratchpadEntries,
} from './tools/scratchpad';
import { getSkipLogicPrompt, SKIP_LOGIC_CORE_INSTRUCTIONS } from '../prompts/skiplogic';
import { retryWithPolicyHandling, type RetryContext } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import {
  segmentSurveyIntoChunks,
  buildSurveyOutline,
  formatAccumulatedRules,
  deduplicateRules,
  getSurveyStats,
} from '../lib/survey/surveyChunker';
import fs from 'fs/promises';
import path from 'path';

// =============================================================================
// Configuration
// =============================================================================

/** Character threshold for chunked mode. Surveys above this use chunked processing. */
function getChunkThreshold(): number {
  return parseInt(process.env.SKIPLOGIC_CHUNK_THRESHOLD || '40000', 10);
}

/** Character budget per chunk (how large each chunk can be). */
function getChunkSize(): number {
  return parseInt(process.env.SKIPLOGIC_CHUNK_SIZE || '40000', 10);
}

// Get modular prompt based on environment variable
const getSkipLogicAgentInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getSkipLogicPrompt(promptVersions.skipLogicPromptVersion);
};

export interface SkipLogicProcessingOptions {
  outputDir?: string;
  abortSignal?: AbortSignal;
}

// =============================================================================
// Router — decides single-pass vs chunked
// =============================================================================

/**
 * Extract all skip/show rules from the survey document.
 * Routes to single-pass or chunked mode based on survey size.
 */
export async function extractSkipLogic(
  surveyMarkdown: string,
  options?: SkipLogicProcessingOptions
): Promise<SkipLogicResult> {
  const stats = getSurveyStats(surveyMarkdown);
  const threshold = getChunkThreshold();

  console.log(`[SkipLogicAgent] Survey: ${stats.charCount} chars (~${stats.estimatedTokens} tokens), threshold: ${threshold} chars`);

  if (stats.charCount <= threshold) {
    return extractSkipLogicSinglePass(surveyMarkdown, options);
  } else {
    return extractSkipLogicChunked(surveyMarkdown, options);
  }
}

// =============================================================================
// Single-Pass Mode (existing behavior, unchanged)
// =============================================================================

/**
 * Extract skip/show rules in a single AI call.
 * Used for surveys that fit within the token budget.
 */
async function extractSkipLogicSinglePass(
  surveyMarkdown: string,
  options?: SkipLogicProcessingOptions
): Promise<SkipLogicResult> {
  const { outputDir, abortSignal } = options || {};
  const startTime = Date.now();
  const maxAttempts = 10;

  console.log(`[SkipLogicAgent] Single-pass mode`);
  console.log(`[SkipLogicAgent] Using model: ${getSkipLogicModelName()}`);
  console.log(`[SkipLogicAgent] Reasoning effort: ${getSkipLogicReasoningEffort()}`);
  console.log(`[SkipLogicAgent] Survey: ${surveyMarkdown.length} characters`);

  // Check for cancellation
  if (abortSignal?.aborted) {
    throw new DOMException('SkipLogicAgent aborted', 'AbortError');
  }

  // Clear scratchpad from any previous runs (only once at the start)
  clearScratchpadEntries();

  // Build base prompts (will be enhanced with scratchpad context on retries)
  const baseSystemPrompt = `
${RESEARCH_DATA_PREAMBLE}${getSkipLogicAgentInstructions()}

## Survey Document
<survey>
${sanitizeForAzureContentFilter(surveyMarkdown)}
</survey>
`;

  const baseUserPrompt = `Read the entire survey document above and extract skip/show/filter rules that define who should be included in a question's analytic base (i.e., rules that could require additional constraints beyond the default base of "banner cut + non-NA").

Be conservative: if you cannot point to clear evidence in the survey that the default base would be wrong, DO NOT create a rule.

Walk through the survey systematically, section by section. Use the scratchpad to document your analysis for each question.

Output the complete list of rules and no-rule questions.`;

  const retryResult = await retryWithPolicyHandling(
    async (ctx: RetryContext) => {
      // Policy-safe fallback: if Azure repeatedly content-filters the full survey,
      // return empty rules rather than failing the entire pipeline.
      if (ctx.shouldUsePolicySafeVariant) {
        console.warn('[SkipLogicAgent] Policy-safe mode triggered — returning empty rules to continue pipeline');
        return { rules: [] };
      }

      // Get scratchpad state before the call (for error context and prompt enhancement)
      const scratchpadBeforeCall = getScratchpadEntries().filter(e => e.agentName === 'SkipLogicAgent');

      // Enhance prompts with scratchpad context if this is a retry
      let systemPrompt = baseSystemPrompt;
      let userPrompt = baseUserPrompt;

      if (scratchpadBeforeCall.length > 0) {
        // This is a retry - include existing scratchpad entries so agent can resume
        const scratchpadContext = scratchpadBeforeCall
          .map((e, i) => `[${i + 1}] (${e.action}) ${e.content}`)
          .join('\n\n');

        systemPrompt = `${baseSystemPrompt}

## Previous Analysis (from scratchpad)
You have already analyzed part of this survey. Here are your previous scratchpad entries:
${scratchpadContext}

IMPORTANT: You are RETRYING after a previous attempt failed. Continue from where you left off - do NOT restart from the beginning. Use the scratchpad "read" action to see all your previous entries, then continue your analysis.`;

        userPrompt = `${baseUserPrompt}

NOTE: This is a retry attempt. You have already documented analysis for ${scratchpadBeforeCall.length} questions in your scratchpad. Use the scratchpad "read" action first to review your previous work, then continue analyzing the remaining questions. Do not duplicate work you've already done.`;
      }

      try {
        const result = await generateText({
          model: getSkipLogicModel(),
          system: systemPrompt,
          maxRetries: 0, // Centralized outer retries via retryWithPolicyHandling
          prompt: userPrompt,
          tools: {
            scratchpad: skipLogicScratchpadTool,
          },
          stopWhen: stepCountIs(25),
          maxOutputTokens: Math.min(getSkipLogicModelTokenLimit(), 100000),
          providerOptions: {
            openai: {
              reasoningEffort: getSkipLogicReasoningEffort(),
            },
          },
          output: Output.object({
            schema: SkipLogicExtractionOutputSchema,
          }),
          abortSignal,
        });

        const { output, usage } = result;

        // Get scratchpad state after the call
        const scratchpadAfterCall = getScratchpadEntries().filter(e => e.agentName === 'SkipLogicAgent');

        if (!output) {
          // Enhanced error message with context
          const errorDetails = [
            `Scratchpad entries: ${scratchpadAfterCall.length} (had ${scratchpadBeforeCall.length} before call)`,
            `Usage: ${usage?.inputTokens || 0} input, ${usage?.outputTokens || 0} output tokens`,
            `Result keys: ${Object.keys(result).join(', ')}`,
          ].join('; ');

          throw new Error(`Invalid output from SkipLogicAgent - ${errorDetails}`);
        }

        // Record metrics
        const durationMs = Date.now() - startTime;
        recordAgentMetrics(
          'SkipLogicAgent',
          getSkipLogicModelName(),
          { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
          durationMs
        );

        return output;
      } catch (error) {
        // Enhanced error logging with scratchpad context
        const scratchpadAfterError = getScratchpadEntries().filter(e => e.agentName === 'SkipLogicAgent');
        const errorMessage = error instanceof Error ? error.message : String(error);
        const errorType = error instanceof Error ? error.constructor.name : typeof error;

        console.error(`[SkipLogicAgent] Error details:`, {
          error: errorMessage,
          type: errorType,
          scratchpadEntries: scratchpadAfterError.length,
          lastScratchpadEntry: scratchpadAfterError.length > 0
            ? scratchpadAfterError[scratchpadAfterError.length - 1].content.substring(0, 200)
            : 'none',
        });

        throw error;
      }
    },
    {
      abortSignal,
      maxAttempts,
      onRetry: (attempt, err) => {
        if (err instanceof DOMException && err.name === 'AbortError') {
          throw err;
        }

        // Enhanced retry logging with scratchpad context
        const scratchpadEntries = getScratchpadEntries().filter(e => e.agentName === 'SkipLogicAgent');
        const errorMessage = err instanceof Error ? err.message : String(err);
        const errorType = err instanceof Error ? err.constructor.name : typeof err;

        console.warn(
          `[SkipLogicAgent] Retry ${attempt}/${maxAttempts}: ${errorMessage.substring(0, 200)}` +
          ` | Type: ${errorType}` +
          ` | Scratchpad entries preserved: ${scratchpadEntries.length}` +
          (scratchpadEntries.length > 0
            ? ` | Last entry: ${scratchpadEntries[scratchpadEntries.length - 1].content.substring(0, 100)}`
            : '')
        );
      },
    }
  );

  if (retryResult.success && retryResult.result) {
    const extraction = retryResult.result;
    const durationMs = Date.now() - startTime;

    console.log(`[SkipLogicAgent] Extracted ${extraction.rules.length} rules in ${durationMs}ms`);

    // Collect scratchpad entries (agent-specific to avoid contamination)
    const scratchpadEntries = getAndClearScratchpadEntries('SkipLogicAgent');

    const result: SkipLogicResult = {
      extraction,
      metadata: {
        rulesExtracted: extraction.rules.length,
        durationMs,
      },
    };

    // Save outputs
    if (outputDir) {
      await saveSkipLogicOutputs(result, outputDir, scratchpadEntries);
    }

    return result;
  }

  // Handle abort
  if (retryResult.error === 'Operation was cancelled') {
    throw new DOMException('SkipLogicAgent aborted', 'AbortError');
  }

  // All retries failed — return empty result
  const errorMessage = retryResult.error || 'Unknown error';
  console.error(`[SkipLogicAgent] Extraction failed: ${errorMessage}`);

  return {
    extraction: { rules: [] },
    metadata: {
      rulesExtracted: 0,
      durationMs: Date.now() - startTime,
    },
  };
}

// =============================================================================
// Chunked Mode — processes large surveys in sequential chunks
// =============================================================================

/**
 * Extract skip/show rules by chunking the survey at question boundaries
 * and processing each chunk sequentially with accumulated context.
 */
async function extractSkipLogicChunked(
  surveyMarkdown: string,
  options?: SkipLogicProcessingOptions
): Promise<SkipLogicResult> {
  const { outputDir, abortSignal } = options || {};
  const startTime = Date.now();
  const chunkSize = getChunkSize();
  const maxAttempts = 10;

  console.log(`[SkipLogicAgent] Chunked mode — survey exceeds threshold`);
  console.log(`[SkipLogicAgent] Using model: ${getSkipLogicModelName()}`);
  console.log(`[SkipLogicAgent] Reasoning effort: ${getSkipLogicReasoningEffort()}`);

  // Step 1: Build survey outline (compact view of full survey structure)
  const surveyOutline = buildSurveyOutline(surveyMarkdown);
  console.log(`[SkipLogicAgent] Survey outline: ${surveyOutline.length} chars`);

  // Step 2: Segment and chunk the survey
  const { chunks, metadata: chunkingMeta } = segmentSurveyIntoChunks(
    surveyMarkdown,
    chunkSize,
    2 // overlap segments
  );

  // Graceful fallback: if chunking produced only 1 chunk (no question boundaries detected)
  if (chunkingMeta.wasSinglePass) {
    console.warn(`[SkipLogicAgent] Chunker returned single chunk — falling back to single-pass with warning`);
    return extractSkipLogicSinglePass(surveyMarkdown, options);
  }

  console.log(`[SkipLogicAgent] Chunked mode: ${chunks.length} chunks (budget ${chunkSize} chars each)`);
  for (let i = 0; i < chunks.length; i++) {
    console.log(`[SkipLogicAgent]   Chunk ${i + 1}: ${chunks[i].length} chars (~${Math.ceil(chunks[i].length / 4)} tokens)`);
  }

  // Step 3: Process chunks sequentially
  const allRules: SkipRule[] = [];
  let totalInputTokens = 0;
  let totalOutputTokens = 0;

  for (let i = 0; i < chunks.length; i++) {
    // Check for cancellation before each chunk
    if (abortSignal?.aborted) {
      throw new DOMException('SkipLogicAgent aborted', 'AbortError');
    }

    const chunkNum = i + 1;
    const chunkStartTime = Date.now();
    console.log(`[SkipLogicAgent] Processing chunk ${chunkNum}/${chunks.length}...`);

    // Create context-isolated scratchpad for this chunk
    const chunkContextId = `chunk-${chunkNum}`;
    const chunkScratchpad = createContextScratchpadTool('SkipLogicAgent', chunkContextId);

    // Build chunk-specific prompts
    const systemPrompt = buildChunkedSystemPrompt(
      chunks[i],
      surveyOutline,
      allRules,
      chunkNum,
      chunks.length
    );

    const userPrompt = buildChunkedUserPrompt(chunkNum, chunks.length, allRules.length);

    const retryResult = await retryWithPolicyHandling(
      async (ctx: RetryContext) => {
        // Policy-safe fallback: skip this chunk rather than failing or looping.
        if (ctx.shouldUsePolicySafeVariant) {
          console.warn(`[SkipLogicAgent] Chunk ${chunkNum}: policy-safe mode triggered — returning empty rules for this chunk`);
          return { rules: [] };
        }

        const result = await generateText({
          model: getSkipLogicModel(),
          system: systemPrompt,
          maxRetries: 0, // Centralized outer retries via retryWithPolicyHandling
          prompt: userPrompt,
          tools: {
            scratchpad: chunkScratchpad,
          },
          stopWhen: stepCountIs(15),
          maxOutputTokens: Math.min(getSkipLogicModelTokenLimit(), 100000),
          providerOptions: {
            openai: {
              reasoningEffort: getSkipLogicReasoningEffort(),
            },
          },
          output: Output.object({
            schema: SkipLogicExtractionOutputSchema,
          }),
          abortSignal,
        });

        const { output, usage } = result;

        if (!output) {
          throw new Error(`Invalid output from SkipLogicAgent chunk ${chunkNum} - no structured output`);
        }

        // Record metrics per chunk
        const chunkDurationMs = Date.now() - chunkStartTime;
        recordAgentMetrics(
          'SkipLogicAgent',
          getSkipLogicModelName(),
          { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
          chunkDurationMs
        );

        totalInputTokens += usage?.inputTokens || 0;
        totalOutputTokens += usage?.outputTokens || 0;

        return output;
      },
      {
        abortSignal,
        maxAttempts,
        onRetry: (attempt, err) => {
          if (err instanceof DOMException && err.name === 'AbortError') {
            throw err;
          }
          console.warn(
            `[SkipLogicAgent] Chunk ${chunkNum} retry ${attempt}/${maxAttempts}: ${err.message.substring(0, 200)}`
          );
        },
      }
    );

    if (retryResult.success && retryResult.result) {
      const chunkRules = retryResult.result.rules;
      console.log(`[SkipLogicAgent] Chunk ${chunkNum}: extracted ${chunkRules.length} rules`);
      allRules.push(...chunkRules);
    } else {
      console.error(
        `[SkipLogicAgent] Chunk ${chunkNum} failed: ${retryResult.error || 'Unknown error'} — continuing with remaining chunks`
      );
      // Don't abort the whole pipeline — continue with other chunks
    }
  }

  // Step 4: Deduplicate rules from overlapping regions
  const ruleCountBeforeDedup = allRules.length;
  const deduplicatedRules = deduplicateRules(allRules);
  const removedByDedup = ruleCountBeforeDedup - deduplicatedRules.length;

  console.log(
    `[SkipLogicAgent] Deduplication: ${ruleCountBeforeDedup} → ${deduplicatedRules.length} rules (${removedByDedup} duplicates removed)`
  );

  const durationMs = Date.now() - startTime;
  console.log(`[SkipLogicAgent] Chunked mode complete: ${deduplicatedRules.length} rules in ${durationMs}ms`);

  // Step 5: Collect all scratchpad entries from all chunks
  const allScratchpadEntries = getAllContextScratchpadEntries();
  const flatScratchpadEntries = allScratchpadEntries.flatMap(ctx =>
    ctx.entries.map(entry => ({
      ...entry,
      // Prefix context ID for clarity in the output
      content: `[${ctx.contextId}] ${entry.content}`,
    }))
  );

  const result: SkipLogicResult = {
    extraction: { rules: deduplicatedRules },
    metadata: {
      rulesExtracted: deduplicatedRules.length,
      durationMs,
    },
  };

  // Step 6: Save outputs
  if (outputDir) {
    await saveSkipLogicOutputs(result, outputDir, flatScratchpadEntries, {
      mode: 'chunked',
      totalChunks: chunks.length,
      chunkCharCounts: chunkingMeta.chunkCharCounts,
      rulesBeforeDedup: ruleCountBeforeDedup,
      rulesAfterDedup: deduplicatedRules.length,
      totalInputTokens,
      totalOutputTokens,
    });
  }

  return result;
}

// =============================================================================
// Chunked Prompt Construction
// =============================================================================

/**
 * Build the system prompt for a chunked call.
 * Includes: core instructions, survey outline, chunk content, accumulated rules.
 */
function buildChunkedSystemPrompt(
  chunkContent: string,
  surveyOutline: string,
  accumulatedRules: SkipRule[],
  chunkNum: number,
  totalChunks: number
): string {
  const parts: string[] = [];

  // Core instructions (shared with single-pass)
  parts.push(`${RESEARCH_DATA_PREAMBLE}${SKIP_LOGIC_CORE_INSTRUCTIONS}`);

  // Chunked mode context
  parts.push(`
## Processing Mode: Chunked Survey Analysis

You are processing CHUNK ${chunkNum} of ${totalChunks} of a large survey document.
Focus ONLY on extracting rules for questions that appear in YOUR chunk.
Do NOT invent rules for questions you cannot see in the chunk below.

The survey outline below gives you the full question structure so you can reference
variables from other parts of the survey when describing conditions.`);

  // Survey outline (compact view of entire survey)
  parts.push(`
## Survey Outline (full survey structure)
<survey_outline>
${surveyOutline}
</survey_outline>`);

  // Accumulated rules from previous chunks (for chunks 2+)
  if (accumulatedRules.length > 0) {
    parts.push(`
## Rules Already Extracted (do NOT re-extract these)
The following rules were extracted from earlier chunks. If you encounter the same
rule or a rule that applies to the same questions with the same condition, skip it.
<previous_rules>
${formatAccumulatedRules(accumulatedRules)}
</previous_rules>`);
  }

  // Simplified scratchpad protocol for chunks
  parts.push(`
<scratchpad_protocol>
USE THE SCRATCHPAD TO DOCUMENT YOUR ANALYSIS:

Walk through the questions in this chunk systematically. For each question:
1. Note the question ID and any skip/show instructions
2. Classify as table-level, row-level, or no rule
3. Check if this rule was already extracted in a prior chunk (see "Rules Already Extracted" above)
4. If unclear, document why and do NOT create a rule unless evidence is strong

BEFORE PRODUCING YOUR FINAL OUTPUT:
Use the scratchpad "read" action to review your notes, then produce your output.
</scratchpad_protocol>`);

  // The chunk content itself
  parts.push(`
## Your Survey Chunk (${chunkNum} of ${totalChunks})
<survey_chunk>
${sanitizeForAzureContentFilter(chunkContent)}
</survey_chunk>`);

  return parts.join('\n');
}

/**
 * Build the user prompt for a chunked call.
 */
function buildChunkedUserPrompt(
  chunkNum: number,
  totalChunks: number,
  previousRuleCount: number
): string {
  const parts: string[] = [];

  parts.push(
    `Analyze the survey chunk above (chunk ${chunkNum} of ${totalChunks}) and extract skip/show/filter rules for questions in THIS chunk.`
  );

  parts.push(
    `Be conservative: if you cannot point to clear evidence that the default base would be wrong, DO NOT create a rule.`
  );

  if (previousRuleCount > 0) {
    parts.push(
      `${previousRuleCount} rules have already been extracted from earlier chunks. Do NOT re-extract rules for the same questions with the same conditions.`
    );
  }

  parts.push(
    `Use the scratchpad to document your analysis, then output the rules you found in this chunk.`
  );

  return parts.join('\n\n');
}

// =============================================================================
// Development Outputs
// =============================================================================

async function saveSkipLogicOutputs(
  result: SkipLogicResult,
  outputDir: string,
  scratchpadEntries: Array<{ timestamp: string; agentName: string; action: string; content: string }>,
  chunkingInfo?: {
    mode: string;
    totalChunks: number;
    chunkCharCounts: number[];
    rulesBeforeDedup: number;
    rulesAfterDedup: number;
    totalInputTokens: number;
    totalOutputTokens: number;
  }
): Promise<void> {
  try {
    const skiplogicDir = path.join(outputDir, 'skiplogic');
    await fs.mkdir(skiplogicDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');

    // Save extraction output
    const filename = `skiplogic-output-${timestamp}.json`;
    const filePath = path.join(skiplogicDir, filename);
    const enhancedOutput = {
      ...result,
      processingInfo: {
        timestamp: new Date().toISOString(),
        aiProvider: 'azure-openai',
        model: getSkipLogicModelName(),
        reasoningEffort: getSkipLogicReasoningEffort(),
        ...(chunkingInfo && { chunking: chunkingInfo }),
      },
    };
    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');
    console.log(`[SkipLogicAgent] Output saved to skiplogic/: ${filename}`);

    // Save raw output
    const rawPath = path.join(skiplogicDir, 'skiplogic-output-raw.json');
    await fs.writeFile(rawPath, JSON.stringify(result.extraction, null, 2), 'utf-8');

    // Save scratchpad
    if (scratchpadEntries.length > 0) {
      const scratchpadFilename = `scratchpad-skiplogic-${timestamp}.md`;
      const scratchpadPath = path.join(skiplogicDir, scratchpadFilename);
      const markdown = formatScratchpadAsMarkdown('SkipLogicAgent', scratchpadEntries);
      await fs.writeFile(scratchpadPath, markdown, 'utf-8');
      console.log(`[SkipLogicAgent] Scratchpad saved to skiplogic/: ${scratchpadFilename}`);
    }
  } catch (error) {
    console.error('[SkipLogicAgent] Failed to save outputs:', error);
  }
}
