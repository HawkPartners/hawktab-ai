/**
 * SkipLogicAgent
 *
 * Purpose: Read the survey document once and extract ALL skip/show/filter rules.
 * Replaces the per-table BaseFilterAgent approach with a single extraction pass.
 *
 * Single AI call — follows BannerAgent pattern.
 * Reads: Survey markdown
 * Writes: {outputDir}/skiplogic/ outputs
 */

import { generateText, Output, stepCountIs } from 'ai';
import {
  SkipLogicExtractionOutputSchema,
  type SkipLogicResult,
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
  formatScratchpadAsMarkdown,
} from './tools/scratchpad';
import { getSkipLogicPrompt } from '../prompts';
import { retryWithPolicyHandling } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import fs from 'fs/promises';
import path from 'path';

// Get modular prompt based on environment variable
const getSkipLogicAgentInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getSkipLogicPrompt(promptVersions.skipLogicPromptVersion);
};

export interface SkipLogicProcessingOptions {
  outputDir?: string;
  abortSignal?: AbortSignal;
}

/**
 * Extract all skip/show rules from the survey document.
 * Single AI call — reads survey once, outputs all rules.
 */
export async function extractSkipLogic(
  surveyMarkdown: string,
  options?: SkipLogicProcessingOptions
): Promise<SkipLogicResult> {
  const { outputDir, abortSignal } = options || {};
  const startTime = Date.now();

  console.log(`[SkipLogicAgent] Starting skip logic extraction`);
  console.log(`[SkipLogicAgent] Using model: ${getSkipLogicModelName()}`);
  console.log(`[SkipLogicAgent] Reasoning effort: ${getSkipLogicReasoningEffort()}`);
  console.log(`[SkipLogicAgent] Survey: ${surveyMarkdown.length} characters`);

  // Check for cancellation
  if (abortSignal?.aborted) {
    throw new DOMException('SkipLogicAgent aborted', 'AbortError');
  }

  // Clear scratchpad from any previous runs
  clearScratchpadEntries();

  const systemPrompt = `
${getSkipLogicAgentInstructions()}

## Survey Document
<survey>
${surveyMarkdown}
</survey>
`;

  const userPrompt = `Read the entire survey document above and extract skip/show/filter rules that define who should be included in a question's analytic base (i.e., rules that could require additional constraints beyond the default base of "banner cut + non-NA").

Be conservative: if you cannot point to clear evidence in the survey that the default base would be wrong, do NOT create a rule. Put that question in noRuleQuestions instead.

Walk through the survey systematically, section by section. Use the scratchpad to document your analysis for each question.

Output the complete list of rules and no-rule questions.`;

  const retryResult = await retryWithPolicyHandling(
    async () => {
      const { output, usage } = await generateText({
        model: getSkipLogicModel(),
        system: systemPrompt,
        maxRetries: 3,
        prompt: userPrompt,
        tools: {
          scratchpad: skipLogicScratchpadTool,
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

      if (!output) {
        throw new Error('Invalid output from SkipLogicAgent');
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
    },
    {
      abortSignal,
      onRetry: (attempt, err) => {
        if (err instanceof DOMException && err.name === 'AbortError') {
          throw err;
        }
        console.warn(`[SkipLogicAgent] Retry ${attempt}/3: ${err.message.substring(0, 120)}`);
      },
    }
  );

  if (retryResult.success && retryResult.result) {
    const extraction = retryResult.result;
    const durationMs = Date.now() - startTime;

    console.log(`[SkipLogicAgent] Extracted ${extraction.rules.length} rules, ${extraction.noRuleQuestions.length} no-rule questions in ${durationMs}ms`);

    // Collect scratchpad entries
    const scratchpadEntries = getAndClearScratchpadEntries();

    const result: SkipLogicResult = {
      extraction,
      metadata: {
        rulesExtracted: extraction.rules.length,
        noRuleQuestions: extraction.noRuleQuestions.length,
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
    extraction: { rules: [], noRuleQuestions: [] },
    metadata: {
      rulesExtracted: 0,
      noRuleQuestions: 0,
      durationMs: Date.now() - startTime,
    },
  };
}

// =============================================================================
// Development Outputs
// =============================================================================

async function saveSkipLogicOutputs(
  result: SkipLogicResult,
  outputDir: string,
  scratchpadEntries: Array<{ timestamp: string; agentName: string; action: string; content: string }>
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
