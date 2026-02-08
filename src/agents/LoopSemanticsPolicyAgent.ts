/**
 * LoopSemanticsPolicyAgent
 *
 * Purpose: Classify each banner group as respondent-anchored or entity-anchored
 * on stacked loop data, and specify alias column implementation for entity-anchored groups.
 *
 * Inputs: Loop summary, banner groups + cuts, deterministic resolver findings, datamap excerpt
 * Output: LoopSemanticsPolicy (structured per-banner-group classification)
 *
 * Runs once per pipeline execution (not per table — one policy for the whole dataset).
 */

import { generateText, Output, stepCountIs } from 'ai';
import {
  LoopSemanticsPolicySchema,
  type LoopSemanticsPolicy,
} from '../schemas/loopSemanticsPolicySchema';
import {
  getLoopSemanticsModel,
  getLoopSemanticsModelName,
  getLoopSemanticsModelTokenLimit,
  getLoopSemanticsReasoningEffort,
  getPromptVersions,
} from '../lib/env';
import {
  createContextScratchpadTool,
  getAllContextScratchpadEntries,
  clearAllContextScratchpads,
  formatScratchpadAsMarkdown,
} from './tools/scratchpad';
import { getLoopSemanticsPrompt } from '../prompts';
import { retryWithPolicyHandling } from '../lib/retryWithPolicyHandling';
import { recordAgentMetrics } from '../lib/observability';
import type { DeterministicResolverResult } from '../lib/validation/LoopContextResolver';
import type { VerboseDataMap } from '../lib/processors/DataMapProcessor';
import type { CutDefinition } from '../lib/tables/CutsSpec';
import fs from 'fs/promises';
import path from 'path';

// =============================================================================
// Types
// =============================================================================

export interface LoopSemanticsPolicyInput {
  /** Loop group summary (frames, iterations, variable families) */
  loopSummary: {
    stackedFrameName: string;
    iterations: string[];
    variableCount: number;
    skeleton: string;
  }[];

  /** Banner groups from BannerAgent output */
  bannerGroups: {
    groupName: string;
    columns: { name: string; original: string }[];
  }[];

  /** Cut expressions from CrosstabAgent output */
  cuts: {
    name: string;
    groupName: string;
    rExpression: string;
  }[];

  /** Deterministic resolver findings (always provided, may be empty) */
  deterministicFindings: DeterministicResolverResult;

  /** Focused datamap: only variables referenced by cuts + nearby context */
  datamapExcerpt: {
    column: string;
    description: string;
    normalizedType: string;
    answerOptions: string;
  }[];

  /** Output directory for saving artifacts */
  outputDir: string;

  /** Abort signal for cancellation */
  abortSignal?: AbortSignal;
}

// =============================================================================
// Main Entry Point
// =============================================================================

/**
 * Run the LoopSemanticsPolicyAgent to classify each banner group.
 */
export async function runLoopSemanticsPolicyAgent(
  input: LoopSemanticsPolicyInput,
): Promise<LoopSemanticsPolicy> {
  console.log(`[LoopSemanticsPolicyAgent] Classifying ${input.bannerGroups.length} banner groups`);
  const startTime = Date.now();

  // Check for cancellation
  if (input.abortSignal?.aborted) {
    throw new DOMException('LoopSemanticsPolicyAgent aborted', 'AbortError');
  }

  // Build system prompt
  const promptVersions = getPromptVersions();
  const systemInstructions = getLoopSemanticsPrompt(promptVersions.loopSemanticsPromptVersion);

  const systemPrompt = systemInstructions;

  // Build user prompt with runtime data
  const userPrompt = buildUserPrompt(input);

  // Clear scratchpad from any previous runs (only once at the start)
  clearAllContextScratchpads();

  // Create context-isolated scratchpad
  const scratchpad = createContextScratchpadTool('LoopSemanticsPolicy', 'policy');

  // Wrap the AI call with retry logic for policy errors
  const retryResult = await retryWithPolicyHandling(
    async () => {
      const { output, usage } = await generateText({
        model: getLoopSemanticsModel(),
        system: systemPrompt,
        maxRetries: 3,
        prompt: userPrompt,
        tools: {
          scratchpad,
        },
        stopWhen: stepCountIs(15),
        maxOutputTokens: Math.min(getLoopSemanticsModelTokenLimit(), 100000),
        providerOptions: {
          openai: {
            reasoningEffort: getLoopSemanticsReasoningEffort(),
          },
        },
        output: Output.object({
          schema: LoopSemanticsPolicySchema,
        }),
        abortSignal: input.abortSignal,
      });

      if (!output || !output.bannerGroups) {
        throw new Error('Invalid output from LoopSemanticsPolicyAgent');
      }

      // Record metrics
      const durationMs = Date.now() - startTime;
      recordAgentMetrics(
        'LoopSemanticsPolicyAgent',
        getLoopSemanticsModelName(),
        { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
        durationMs,
      );

      return output;
    },
    {
      abortSignal: input.abortSignal,
      onRetry: (attempt, err) => {
        if (err instanceof DOMException && err.name === 'AbortError') {
          throw err;
        }
        console.warn(`[LoopSemanticsPolicyAgent] Retry ${attempt}/3: ${err.message.substring(0, 120)}`);
      },
    },
  );

  // Handle abort
  if (retryResult.error === 'Operation was cancelled') {
    throw new DOMException('LoopSemanticsPolicyAgent aborted', 'AbortError');
  }

  if (!retryResult.success || !retryResult.result) {
    throw new Error(`LoopSemanticsPolicyAgent failed: ${retryResult.error || 'Unknown error'}`);
  }

  const result = retryResult.result;

  // Save scratchpad trace
  const contextEntries = getAllContextScratchpadEntries();
  const allScratchpadEntries = contextEntries.flatMap((ctx) =>
    ctx.entries.map((e) => ({ ...e, contextId: ctx.contextId }))
  );
  if (allScratchpadEntries.length > 0) {
    const loopPolicyDir = path.join(input.outputDir, 'loop-policy');
    await fs.mkdir(loopPolicyDir, { recursive: true });
    const scratchpadMd = formatScratchpadAsMarkdown('LoopSemanticsPolicyAgent', allScratchpadEntries);
    await fs.writeFile(
      path.join(loopPolicyDir, 'scratchpad-loop-semantics.md'),
      scratchpadMd,
      'utf-8',
    );
    clearAllContextScratchpads();
  }

  console.log(
    `[LoopSemanticsPolicyAgent] Done: ${result.bannerGroups.filter((g: { anchorType: string }) => g.anchorType === 'entity').length} entity-anchored, ` +
    `${result.bannerGroups.filter((g: { anchorType: string }) => g.anchorType === 'respondent').length} respondent-anchored ` +
    `(${Date.now() - startTime}ms)`,
  );

  return result;
}

// =============================================================================
// Prompt Assembly
// =============================================================================

/**
 * Build the user prompt with runtime data from the pipeline.
 */
function buildUserPrompt(input: LoopSemanticsPolicyInput): string {
  const sections: string[] = [];

  sections.push('Classify each banner group as respondent-anchored or entity-anchored.\n');

  // Loop summary
  sections.push('<loop_summary>');
  sections.push(JSON.stringify(input.loopSummary, null, 2));
  sections.push('</loop_summary>\n');

  // Deterministic findings
  sections.push('<deterministic_findings>');
  if (input.deterministicFindings.iterationLinkedVariables.length > 0) {
    sections.push(input.deterministicFindings.evidenceSummary);
    sections.push('\nDetailed mappings:');
    sections.push(JSON.stringify(input.deterministicFindings.iterationLinkedVariables, null, 2));
  } else {
    sections.push('No iteration-linked variables found via deterministic evidence.');
    sections.push('You must infer from banner expressions, datamap descriptions, and structural patterns.');
  }
  sections.push('NOTE: These mappings were found deterministically from .sav metadata (variable suffixes,');
  sections.push('label tokens, sibling patterns). Treat them as strong evidence. If a variable appears here');
  sections.push('with a linked iteration, it is almost certainly entity-anchored.');
  sections.push('</deterministic_findings>\n');

  // Banner groups and cuts
  sections.push('<banner_groups_and_cuts>');
  for (const group of input.bannerGroups) {
    sections.push(`\nGroup: "${group.groupName}"`);
    sections.push(`  Columns: ${group.columns.map(c => c.name).join(', ')}`);

    // Find cuts for this group
    const groupCuts = input.cuts.filter(c => c.groupName === group.groupName);
    if (groupCuts.length > 0) {
      sections.push('  Cuts:');
      for (const cut of groupCuts) {
        sections.push(`    "${cut.name}" = ${cut.rExpression}`);
      }
    }
  }
  sections.push('</banner_groups_and_cuts>\n');

  // Datamap excerpt
  sections.push('<datamap_excerpt>');
  for (const entry of input.datamapExcerpt) {
    sections.push(`  ${entry.column}: ${entry.description} [${entry.normalizedType}]`);
    if (entry.answerOptions) {
      sections.push(`    Options: ${entry.answerOptions.substring(0, 200)}`);
    }
  }
  sections.push('</datamap_excerpt>\n');

  sections.push('Output your classification for every banner group listed above.');
  sections.push('Set policyVersion to "1.0".');

  return sections.join('\n');
}

// =============================================================================
// Datamap Excerpt Builder
// =============================================================================

/**
 * Build a focused datamap excerpt containing only variables referenced by cuts
 * and nearby context (h-prefix/d-prefix variants, deterministic findings).
 */
export function buildDatamapExcerpt(
  verboseDataMap: VerboseDataMap[],
  cuts: CutDefinition[],
  deterministicFindings?: DeterministicResolverResult,
): { column: string; description: string; normalizedType: string; answerOptions: string }[] {
  // Build set of variable names we need
  const neededVars = new Set<string>();

  // 1. Parse variable names from cut R expressions
  for (const cut of cuts) {
    const vars = extractVariableNames(cut.rExpression);
    for (const v of vars) {
      neededVars.add(v);
    }
  }

  // 2. Add h-prefix and d-prefix variants
  const prefixedVars = new Set<string>();
  for (const v of neededVars) {
    prefixedVars.add(`h${v}`);
    prefixedVars.add(`d${v}`);
  }
  for (const pv of prefixedVars) {
    neededVars.add(pv);
  }

  // 3. Add variables from deterministic findings
  if (deterministicFindings) {
    for (const f of deterministicFindings.iterationLinkedVariables) {
      neededVars.add(f.variableName);
    }
  }

  // Build lookup and filter
  const varByColumn = new Map<string, VerboseDataMap>();
  for (const v of verboseDataMap) {
    varByColumn.set(v.column, v);
  }

  const excerpt: { column: string; description: string; normalizedType: string; answerOptions: string }[] = [];
  const addedColumns = new Set<string>();

  for (const varName of neededVars) {
    if (addedColumns.has(varName)) continue;
    const entry = varByColumn.get(varName);
    if (!entry) continue;

    excerpt.push({
      column: entry.column,
      description: entry.description || '',
      normalizedType: entry.normalizedType || '',
      answerOptions: entry.answerOptions || '',
    });
    addedColumns.add(varName);
  }

  return excerpt;
}

/**
 * Extract variable names from an R expression.
 * Finds word-boundary identifiers that look like SPSS variable names,
 * excluding R keywords and functions.
 */
function extractVariableNames(rExpression: string): string[] {
  const rKeywords = new Set([
    'TRUE', 'FALSE', 'NA', 'NULL', 'Inf', 'NaN',
    'if', 'else', 'for', 'in', 'while', 'repeat', 'next', 'break',
    'function', 'return', 'c', 'rep', 'nrow', 'ncol',
    'with', 'data', 'eval', 'parse', 'text',
    'is', 'na', 'as', 'numeric', 'character', 'logical',
    'sum', 'mean', 'max', 'min', 'length',
    'TRUE', 'FALSE',
  ]);

  // Match word-boundary identifiers (but not numbers, not inside strings)
  const matches = rExpression.match(/\b([A-Za-z][A-Za-z0-9_.]*)\b/g) || [];

  const vars = new Set<string>();
  for (const m of matches) {
    // Skip R keywords, operators, and functions
    if (rKeywords.has(m)) continue;
    // Skip pure numbers
    if (/^\d+$/.test(m)) continue;
    // Skip common R functions
    if (m === 'grepl' || m === 'nchar' || m === 'paste' || m === 'paste0') continue;
    vars.add(m);
  }

  return [...vars];
}
