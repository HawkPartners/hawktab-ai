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
import { RESEARCH_DATA_PREAMBLE, sanitizeForAzureContentFilter } from '../lib/promptSanitization';
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
import type { LoopGroupMapping } from '../lib/validation/LoopCollapser';
import type { CutDefinition } from '../lib/tables/CutsSpec';
import { persistAgentErrorAuto } from '../lib/errors/ErrorPersistence';
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

  /** Loop group mappings — used to validate sourcesByIteration against per-frame columns */
  loopMappings: LoopGroupMapping[];

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
  const maxAttempts = 10;

  // Check for cancellation
  if (input.abortSignal?.aborted) {
    const abortErr = new DOMException('LoopSemanticsPolicyAgent aborted', 'AbortError');
    // Persist for post-run diagnostics (best-effort)
    try {
      await persistAgentErrorAuto({
        outputDir: input.outputDir,
        agentName: 'LoopSemanticsPolicyAgent',
        severity: 'warning',
        actionTaken: 'aborted',
        error: abortErr,
        meta: { bannerGroups: input.bannerGroups.length, loops: input.loopSummary.length },
      });
    } catch {
      // ignore
    }
    throw abortErr;
  }

  // Build system prompt
  const promptVersions = getPromptVersions();
  const systemInstructions = getLoopSemanticsPrompt(promptVersions.loopSemanticsPromptVersion);

  const systemPrompt = `${RESEARCH_DATA_PREAMBLE}${systemInstructions}`;

  // Build user prompt with runtime data
  const baseUserPrompt = buildUserPrompt(input);

  // Build set of known columns for validation (datamap + deterministic findings)
  const knownColumns = new Set(input.datamapExcerpt.map(e => e.column));
  for (const f of input.deterministicFindings.iterationLinkedVariables) {
    knownColumns.add(f.variableName);
  }

  // Build per-stacked-frame column sets for sourcesByIteration validation.
  // A sourcesByIteration variable must exist in the SPECIFIC stacked frame it targets,
  // not just anywhere in the datamap. Valid sources include:
  // 1. The loop group's own collapsed base names + iteration columns (_1/_2 pattern)
  // 2. Iteration-linked variables found by the DeterministicResolver (e.g., S10a/S11a)
  //    that map to the same loop group — these are non-loop columns that are semantically
  //    tied to specific iterations and are valid alias sources via case_when.
  const columnsByFrame = buildPerFrameColumnSets(
    input.loopMappings,
    knownColumns,
    input.deterministicFindings,
  );

  // Clear scratchpad from any previous runs (only once at the start)
  clearAllContextScratchpads();

  const maxSemanticRetries = 2; // corrective retries for hallucinated variables

  // Wrap the AI call with retry logic for policy errors
  try {
    let result: LoopSemanticsPolicy | null = null;

    for (let semanticAttempt = 0; semanticAttempt <= maxSemanticRetries; semanticAttempt++) {
      // Build prompt — first attempt uses base, retries append correction
      let currentPrompt = baseUserPrompt;
      if (semanticAttempt > 0 && result) {
        const corrections = buildCorrectionPrompt(result, knownColumns, columnsByFrame);
        currentPrompt = baseUserPrompt + '\n\n' + corrections;
        console.log(
          `[LoopSemanticsPolicyAgent] Semantic retry ${semanticAttempt}/${maxSemanticRetries}: ` +
          `correcting hallucinated variables`,
        );
      }

      // Create fresh scratchpad for each attempt
      const scratchpad = createContextScratchpadTool('LoopSemanticsPolicy', `policy-attempt-${semanticAttempt}`);

      const retryResult = await retryWithPolicyHandling(
        async () => {
          const { output, usage } = await generateText({
            model: getLoopSemanticsModel(),
            system: systemPrompt,
            maxRetries: 0, // Centralized outer retries via retryWithPolicyHandling
            prompt: currentPrompt,
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
          maxAttempts,
          onRetry: (attempt, err) => {
            if (err instanceof DOMException && err.name === 'AbortError') {
              throw err;
            }
            console.warn(`[LoopSemanticsPolicyAgent] Retry ${attempt}/${maxAttempts}: ${err.message.substring(0, 120)}`);
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

      result = retryResult.result;

      // Validate sourcesByIteration against per-frame columns (not full datamap).
      // A variable must exist in the stacked frame it's assigned to, not just anywhere.
      const hallucinations = findHallucinatedVariables(result, knownColumns, columnsByFrame);
      if (hallucinations.length === 0) {
        // Clean — no retries needed
        break;
      }

      if (semanticAttempt < maxSemanticRetries) {
        // Will retry — log what we found
        console.warn(
          `[LoopSemanticsPolicyAgent] Found ${hallucinations.length} hallucinated variable(s): ` +
          hallucinations.map(h => `"${h.variable}" in group "${h.groupName}"`).join(', '),
        );
      } else {
        // Final attempt still has hallucinations — strip them as last resort
        console.warn(
          `[LoopSemanticsPolicyAgent] Exhausted ${maxSemanticRetries} semantic retries, ` +
          `stripping ${hallucinations.length} remaining hallucinated variable(s)`,
        );
        for (const bg of result.bannerGroups) {
          if (bg.implementation.strategy !== 'alias_column') continue;
          const frameColumns = bg.stackedFrameName
            ? columnsByFrame.get(bg.stackedFrameName)
            : undefined;
          const validationSet = frameColumns || knownColumns;
          const before = bg.implementation.sourcesByIteration.length;
          bg.implementation.sourcesByIteration = bg.implementation.sourcesByIteration.filter(
            s => validationSet.has(s.variable),
          );
          const removed = before - bg.implementation.sourcesByIteration.length;
          if (removed > 0) {
            bg.confidence = Math.min(bg.confidence, 0.5);
            const warning = `${bg.groupName}: Stripped ${removed} variable(s) not found in ${bg.stackedFrameName || 'datamap'} after ${maxSemanticRetries} correction retries`;
            bg.evidence.push(warning);
            result.warnings.push(warning);
          }
        }
      }
    }

    if (!result) {
      throw new Error('LoopSemanticsPolicyAgent produced no result');
    }

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
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') {
      // Persist aborts too (best-effort)
      try {
        await persistAgentErrorAuto({
          outputDir: input.outputDir,
          agentName: 'LoopSemanticsPolicyAgent',
          severity: 'warning',
          actionTaken: 'aborted',
          error,
          meta: { bannerGroups: input.bannerGroups.length, loops: input.loopSummary.length },
        });
      } catch {
        // ignore
      }
      throw error;
    }

    try {
      await persistAgentErrorAuto({
        outputDir: input.outputDir,
        agentName: 'LoopSemanticsPolicyAgent',
        severity: 'error',
        actionTaken: 'continued',
        error,
        meta: { bannerGroups: input.bannerGroups.length, loops: input.loopSummary.length },
      });
    } catch {
      // ignore
    }

    throw error;
  }
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

  // Loop summary (enriched with per-frame variable base names + deterministic resolver variables)
  const enrichedLoopSummary = input.loopSummary.map((ls, _idx) => {
    const mapping = input.loopMappings.find(m => m.stackedFrameName === ls.stackedFrameName);
    const groupIdx = mapping ? input.loopMappings.indexOf(mapping) : -1;

    // Start with LoopCollapser's base names (_1/_2 suffix variables)
    const baseNames = mapping ? mapping.variables.map(v => v.baseName) : [];

    // Add DeterministicResolver variables linked to this loop group.
    // These are non-loop columns (e.g., S10a/S11a) that the resolver identified
    // as belonging to specific iterations — valid alias sources the agent should know about.
    if (groupIdx >= 0) {
      for (const linked of input.deterministicFindings.iterationLinkedVariables) {
        if (linked.linkedLoopGroup === groupIdx && !baseNames.includes(linked.variableName)) {
          baseNames.push(linked.variableName);
        }
      }
    }

    return {
      ...ls,
      variableBaseNames: baseNames,
    };
  });
  sections.push('<loop_summary>');
  sections.push(sanitizeForAzureContentFilter(JSON.stringify(enrichedLoopSummary, null, 2)));
  sections.push('IMPORTANT: Each stacked frame\'s "variableBaseNames" lists the ONLY variables that');
  sections.push('are valid for sourcesByIteration aliases on that frame. Do NOT use variables that');
  sections.push('are not in this list — they exist in the main data but are not loop-iteration-specific.');
  sections.push('</loop_summary>\n');

  // Deterministic findings
  sections.push('<deterministic_findings>');
  if (input.deterministicFindings.iterationLinkedVariables.length > 0) {
    sections.push(sanitizeForAzureContentFilter(input.deterministicFindings.evidenceSummary));
    sections.push('\nDetailed mappings:');
    sections.push(sanitizeForAzureContentFilter(JSON.stringify(input.deterministicFindings.iterationLinkedVariables, null, 2)));
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
    sections.push(`  ${entry.column}: ${sanitizeForAzureContentFilter(entry.description)} [${entry.normalizedType}]`);
    if (entry.answerOptions) {
      sections.push(`    Options: ${sanitizeForAzureContentFilter(entry.answerOptions.substring(0, 200))}`);
    }
  }
  sections.push('</datamap_excerpt>\n');

  sections.push('Output your classification for every banner group listed above.');
  sections.push('Set policyVersion to "1.0".');

  return sections.join('\n');
}

// =============================================================================
// Semantic Validation Helpers
// =============================================================================

interface HallucinatedVariable {
  groupName: string;
  variable: string;
  iteration: string;
}

/**
 * Find sourcesByIteration entries that reference variables not available in their
 * target stacked frame. Uses per-frame column sets when available, falling back
 * to full datamap columns.
 */
function findHallucinatedVariables(
  policy: LoopSemanticsPolicy,
  knownColumns: Set<string>,
  columnsByFrame?: Map<string, Set<string>>,
): HallucinatedVariable[] {
  const hallucinations: HallucinatedVariable[] = [];
  for (const bg of policy.bannerGroups) {
    if (bg.implementation.strategy !== 'alias_column') continue;
    // Validate against the specific stacked frame's columns if available
    const frameColumns = bg.stackedFrameName && columnsByFrame
      ? columnsByFrame.get(bg.stackedFrameName)
      : undefined;
    const validationSet = frameColumns || knownColumns;
    for (const s of bg.implementation.sourcesByIteration) {
      if (!validationSet.has(s.variable)) {
        hallucinations.push({
          groupName: bg.groupName,
          variable: s.variable,
          iteration: s.iteration,
        });
      }
    }
  }
  return hallucinations;
}

/**
 * Build a corrective prompt appendix that tells the agent exactly which variables
 * it hallucinated and what columns actually exist, so it can fix its output.
 */
function buildCorrectionPrompt(
  previousResult: LoopSemanticsPolicy,
  knownColumns: Set<string>,
  columnsByFrame?: Map<string, Set<string>>,
): string {
  const sections: string[] = [];
  sections.push('<correction>');
  sections.push('IMPORTANT: Your previous output contained variables in sourcesByIteration that DO NOT EXIST in the target stacked frame.');
  sections.push('A sourcesByIteration variable must be a column that exists in the SPECIFIC stacked frame, not just anywhere in the dataset.');
  sections.push('The following variables were invalid:\n');

  for (const bg of previousResult.bannerGroups) {
    if (bg.implementation.strategy !== 'alias_column') continue;
    const frameColumns = bg.stackedFrameName && columnsByFrame
      ? columnsByFrame.get(bg.stackedFrameName)
      : undefined;
    const validationSet = frameColumns || knownColumns;
    const bad = bg.implementation.sourcesByIteration.filter(s => !validationSet.has(s.variable));
    if (bad.length === 0) continue;

    const good = bg.implementation.sourcesByIteration.filter(s => validationSet.has(s.variable));
    sections.push(`Group "${bg.groupName}" (target frame: ${bg.stackedFrameName || 'unknown'}):`);
    sections.push(`  INVALID variables (not in ${bg.stackedFrameName || 'datamap'}): ${bad.map(s => `${s.variable} (iteration ${s.iteration})`).join(', ')}`);
    if (good.length > 0) {
      sections.push(`  VALID variables (exist in frame): ${good.map(s => `${s.variable} (iteration ${s.iteration})`).join(', ')}`);
    }

    // Show which variables ARE available in the target frame
    if (frameColumns) {
      const badPrefixes = bad.map(s => s.variable.replace(/\d+$/, ''));
      const suggestions = [...frameColumns].filter(col => {
        return badPrefixes.some(prefix => col.startsWith(prefix));
      });
      if (suggestions.length > 0) {
        sections.push(`  Similar columns in ${bg.stackedFrameName}: ${suggestions.join(', ')}`);
      }
      sections.push(`  Total columns available in ${bg.stackedFrameName}: ${frameColumns.size}`);
    }
    sections.push('');
  }

  sections.push('Please re-classify all banner groups with ONLY variables that exist in the TARGET stacked frame.');
  sections.push('If a variable does not exist in the stacked frame for a given iteration, OMIT that iteration from sourcesByIteration.');
  sections.push('It is acceptable to have fewer entries than loop iterations — missing iterations map to NA.');
  sections.push('If no valid variables exist for a group, reclassify it as respondent-anchored.');
  sections.push('</correction>');

  return sections.join('\n');
}

// =============================================================================
// Per-Frame Column Sets
// =============================================================================

/**
 * Build a map of stacked frame name → set of column names valid for alias sourcesByIteration.
 *
 * Valid alias sources include:
 * 1. The loop group's own base names and iteration columns (_1/_2 pattern from LoopCollapser)
 * 2. Iteration-linked variables from the DeterministicResolver that map to the same loop group.
 *    These are non-loop columns (e.g., S10a/S11a) that are semantically tied to specific
 *    iterations — they exist on the stacked frame (carried through by bind_rows) and are
 *    valid case_when sources because each one holds a DIFFERENT iteration's value.
 *
 * Main data columns NOT identified by either source are excluded — they have the SAME value
 * across all iterations for a given respondent, so using them as alias sources is semantically
 * wrong (the case_when would just pick the same value regardless of .loop_iter).
 */
function buildPerFrameColumnSets(
  loopMappings: LoopGroupMapping[],
  _datamapColumns: Set<string>,
  deterministicFindings?: DeterministicResolverResult,
): Map<string, Set<string>> {
  const result = new Map<string, Set<string>>();

  for (let groupIdx = 0; groupIdx < loopMappings.length; groupIdx++) {
    const mapping = loopMappings[groupIdx];
    const frameColumns = new Set<string>();

    // Source 1: Loop group's own variables (LoopCollapser — _1/_2 suffix pattern)
    for (const v of mapping.variables) {
      frameColumns.add(v.baseName);
      for (const origCol of Object.values(v.iterationColumns)) {
        frameColumns.add(origCol);
      }
    }

    // Source 2: Iteration-linked variables from DeterministicResolver
    // These are non-loop columns (no _1/_2 suffix) that the resolver identified
    // as belonging to specific iterations of this loop group (e.g., S10a → iter 1,
    // S11a → iter 2). They exist on the stacked frame and are valid alias sources.
    if (deterministicFindings) {
      for (const linked of deterministicFindings.iterationLinkedVariables) {
        if (linked.linkedLoopGroup === groupIdx) {
          frameColumns.add(linked.variableName);
        }
      }
    }

    result.set(mapping.stackedFrameName, frameColumns);
  }

  return result;
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
