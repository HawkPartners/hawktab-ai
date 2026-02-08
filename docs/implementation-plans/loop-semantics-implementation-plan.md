# Loop Semantics Policy — Consolidated Implementation Plan

## Problem Statement

When survey data contains loops (e.g., "describe your first drinking occasion, then your second"), the pipeline stacks data so each row represents one **entity** (occasion/medication/brand), not one respondent. The stacking correctly renames loop variables (`A2_1/A2_2 -> A2`) but **duplicates all non-loop columns** across every stacked row.

The problem: **some banner cuts reference "iteration-linked wide variables"** — variables that belong to a specific loop iteration but are NOT part of the detected loop-variable families. When these are duplicated, cuts evaluate on the wrong unit of analysis.

### Verified With Real Data (Tito's Growth Strategy, pipeline 2026-02-07)

The Needs State banner cuts use `(S10a == 1 | S11a == 1)` where S10a describes occasion 1 and S11a describes occasion 2. On the stacked frame:

| Metric | Actual | Expected | Error |
|--------|--------|----------|-------|
| Total base (A2) | 7,420 | 7,420 | Correct |
| Connection/Belonging base (A2) | 1,409 | ~852 | **+65% inflated** |
| Sum of 8 needs state bases | 11,046 | 7,420 | **48.9% overlap** |

The needs states should **partition** occasions (each occasion has exactly one needs state) but instead overlap massively. Root cause: S10a and S11a are never renamed during stacking, so both values are present on every stacked row, and the OR logic causes cross-occasion contamination.

**Correct stacked cut:** `(.loop_iter == 1 & S10a == 1) | (.loop_iter == 2 & S11a == 1)` — each row only matches the needs state for ITS specific occasion.

### Secondary Bugs Found (Fix Independently)

1. **Duplicate Total in stacked cuts** (`master.R` line 40 vs 41): `rep(TRUE, nrow(data))` should be `nrow(stacked_loop_1)`. Bug is in `generateStackingPreamble()` at `RScriptGeneratorV2.ts:507-519`.

2. **Stat letters bug for stacked frames**: `generateFrequencyTable` and `generateMeanRowsTable` reference `cut_stat_letters` instead of `cut_stat_letters_${frameName}` for loop tables.

---

## Solution Architecture

### Core Pattern: Deterministic Resolve + LLM Classify + Deterministic Apply + Deterministic Validate

```
Loop Detection → Deterministic Resolver (metadata evidence)
                         |
                         v
              candidate iteration-linked variable mappings
                         |
                         v
    [parallel: Banner, Crosstab, SkipLogic, TableGen, etc.]
                         |
                         v  (all parallel paths complete)
                         |
           LoopSemanticsPolicyAgent (LLM)
           receives: banner groups + cuts + loop summary + deterministic mappings + datamap
           produces: per-banner-group policy JSON
                         |
                         v
           Deterministic Apply (alias columns in R generation)
                         |
                         v
           R-side Validation (base sum checks, overlap detection)
                         |
                         v
           Stat Testing Guard (disable within-group letters for overlapping groups)
```

### Why This Architecture

1. **Deterministic resolver** handles the mechanical question: "which variable maps to which iteration?" This is often answerable from metadata (variable suffixes, SPSS label tokens like `${LOCATION1}`). It's cheap, auditable, and works for ~27% of looped datasets without any LLM call.

2. **LLM policy agent** handles the semantic question: "what kind of banner group is this on stacked frames?" This requires understanding intent — Needs State is entity-anchored (classifies the occasion), Location is respondent-anchored (describes where the respondent drinks, not where THIS occasion was). Only the LLM can make this distinction.

3. **Always call the LLM** when loops are detected. The deterministic resolver provides evidence that makes the LLM's job easier, but it doesn't replace the per-banner-group classification. If deterministic evidence is available, pass it; if not, the LLM works from banner names + cuts + datamap context.

4. **Alias columns** over expression rewriting. Creating `needs_state_code = ifelse(.loop_iter==1, S10a, S11a)` on the stacked frame, then cutting on `needs_state_code == 1`, is more robust than regex-replacing R expressions. One place to get right, simple downstream expressions.

5. **R-side validation** catches errors automatically. If bases don't sum to Total for a partition group, the system knows the policy is wrong.

6. **Stat testing guard** is essential for defensibility. If a banner group overlaps, within-group stat letters are statistically invalid and must be suppressed.

---

## Phase 1: Deterministic Resolver + Policy Agent + Alias Columns

### What Ships

- Deterministic resolver scans metadata for iteration-linked variable evidence
- LLM policy agent classifies each banner group (entity-anchored vs respondent-anchored)
- R script generator creates alias columns on stacked frames for entity-anchored groups
- Stacked cuts reference alias columns instead of raw iteration-linked variables
- Policy JSON artifact saved for auditing

### 1.1 Deterministic Resolver

**New file:** `src/lib/validation/LoopContextResolver.ts`

This is a pure function (no LLM). It scans available metadata to find iteration-linked variable mappings.

**Interface:**

```typescript
export interface IterationLinkedVariable {
  variableName: string;        // e.g., "S10a"
  linkedIteration: string;     // e.g., "1" (from loop iteration set)
  evidenceSource: string;      // e.g., "label_token:LOCATION1", "variable_suffix:_1"
  confidence: number;          // 0-1
}

export interface DeterministicResolverResult {
  iterationLinkedVariables: IterationLinkedVariable[];
  evidenceSummary: string;     // human-readable summary for LLM prompt + artifacts
}

export function resolveIterationLinkedVariables(
  verboseDataMap: VerboseDataMap[],
  loopMappings: LoopGroupMapping[],
  collapsedVariableNames: Set<string>,
): DeterministicResolverResult;
```

**Evidence hierarchy (checked in order):**

**A0: Variable-name iteration suffixes.** Non-loop columns matching `^(?<root>[A-Za-z][A-Za-z0-9]*)_(?<iter>\d+)$` where `iter` is in a loop group's iteration set. Example: `Treatment_1` and `Treatment_2` in UCB datasets. This is the most reliable signal.

**A1: Platform-exported shadow metadata tokens.** Scan all variable labels/descriptions in the verbose datamap for iteration-marker tokens like `${LOCATION1}`, `${LOCATION2}`, `${Treatment_1}`, etc. The pagetime variables in Tito's contain these: `pagetimeA10_1` has label containing `${LOCATION1.r1.val}`. When found, trace back: if `pagetimeS10a`'s label contains `LOCATION1`, then `S10a -> iteration 1`. More specifically: scan ALL non-loop variable labels for tokens matching `(?<root>[A-Z][A-Z_]*?)(?<iter>\d+)` where the iter values span the loop iteration set.

**A2: Sibling columns with identical descriptions.** Find non-loop columns with identical (normalized) descriptions whose count matches the number of loop iterations. Example: S10a and S11a both described as "Which best describes the reason for having a drink?" If the count matches and other evidence anchors at least one sibling to an iteration, cascade to the full set. Without an anchor, flag as candidates but don't assign iterations.

**A3: Hidden variable cascading (post-processing).** After any source produces mappings, cascade deterministically:
- h-prefix: If `S10a -> iter 1`, then `hS10a -> iter 1` (if `hS10a` exists)
- d-prefix: If `S10a -> iter 1`, then `dS10a -> iter 1` (if `dS10a` exists)

**Where this runs in the pipeline:** Immediately after loop detection/collapse (Step 1 in PipelineRunner), before parallel agent paths. It's instant (pure data scan, no I/O).

**Codebase reference:** The collapsed variable names come from `collapseLoopVariables()` return value (`LoopCollapseResult.collapsedVariableNames` at `src/lib/validation/LoopCollapser.ts:46`). The verbose datamap is the enriched variable list from `DataMapProcessor` (`src/lib/processors/DataMapProcessor.ts`).

### 1.2 Loop Semantics Policy Schema

**New file:** `src/schemas/loopSemanticsPolicySchema.ts`

```typescript
import { z } from 'zod';

export const BannerGroupPolicySchema = z.object({
  /** Name matching the banner group from BannerAgent output */
  groupName: z.string(),

  /** How this banner group relates to the stacked entity */
  anchorType: z.enum(['respondent', 'entity']),

  /** Whether cuts in this group should be mutually exclusive on loop tables */
  shouldPartition: z.boolean(),

  /** Implementation strategy for entity-anchored groups */
  implementation: z.object({
    /** "alias_column" for entity-anchored, "none" for respondent-anchored */
    strategy: z.enum(['alias_column', 'gated_expression', 'none']),

    /** Name for the derived column on stacked frame. Empty string if not used.
     *  Use ".hawktab_" prefix to avoid collisions with survey variables. */
    aliasName: z.string(),

    /** Map of iteration value -> source variable name.
     *  e.g., { "1": "S10a", "2": "S11a" }. Empty object if not used. */
    sourcesByIteration: z.record(z.string(), z.string()),

    /** Brief explanation of the implementation choice */
    notes: z.string(),
  }),

  /** Agent confidence in this classification (0-1) */
  confidence: z.number(),

  /** Evidence supporting this classification */
  evidence: z.array(z.string()),
});

export const LoopSemanticsPolicySchema = z.object({
  /** Schema version for forward compatibility */
  policyVersion: z.string(),

  /** Per-banner-group semantic classifications */
  bannerGroups: z.array(BannerGroupPolicySchema),

  /** Whether a human should review before trusting these results */
  humanReviewRequired: z.boolean(),

  /** Warnings about edge cases or low confidence decisions */
  warnings: z.array(z.string()),

  /** Brief reasoning summary */
  reasoning: z.string(),
});

export type LoopSemanticsPolicy = z.infer<typeof LoopSemanticsPolicySchema>;
export type BannerGroupPolicy = z.infer<typeof BannerGroupPolicySchema>;
```

**Key design decisions:**
- No `undefined` anywhere (Azure OpenAI requirement per CLAUDE.md)
- Empty string/empty object/empty array for unused fields
- `.hawktab_` prefix convention for alias names to prevent collisions
- No stat testing fields in schema (Phase 2 adds validation-driven stat behavior)
- No roster-linked anchor type (out of scope)
- No `baseTypeOnLoopTables` choice (default entity_count always)

### 1.3 Loop Semantics Policy Agent

**New file:** `src/agents/LoopSemanticsPolicyAgent.ts`

Follows the exact agent call pattern from `VerificationAgent.ts`.

**When it runs:** After all parallel paths complete (Banner + Crosstab + SkipLogic + TableGen), before R generation. It needs the banner output and crosstab cuts as input.

**Pipeline insertion point:** `PipelineRunner.ts` between the `Promise.allSettled` resolution (line ~458) and the loop data frame tagging block (line ~618). Specifically, after `pathAResult` is resolved (which contains banner + crosstab outputs).

**Inputs:**

```typescript
interface LoopSemanticsPolicyInput {
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

  /** Optional survey markdown (for ambiguous cases) */
  surveyMarkdown?: string;
}
```

**Datamap excerpt construction:** Filter the verbose datamap to include:
1. All variables referenced in cut rExpressions (parse variable names from R expressions)
2. Any h-prefix or d-prefix variants of those variables
3. Any variables flagged by the deterministic resolver

This keeps the prompt focused. The full Tito's datamap is ~2000+ entries; the excerpt will be ~30-50.

**Output:** `LoopSemanticsPolicy` (the Zod schema above)

**Agent configuration (env.ts additions):**

```bash
# .env.local
LOOP_SEMANTICS_MODEL=gpt-5-mini
LOOP_SEMANTICS_MODEL_TOKENS=128000
LOOP_SEMANTICS_REASONING_EFFORT=medium
LOOP_SEMANTICS_PROMPT_VERSION=production
```

Add to `src/lib/env.ts` following the exact pattern of existing agents:
- `getLoopSemanticsModel()` — returns `provider.chat(config.loopSemanticsModel)`
- `getLoopSemanticsModelName()` — returns `azure/${config.loopSemanticsModel}`
- `getLoopSemanticsModelTokenLimit()` — returns token limit
- `getLoopSemanticsReasoningEffort()` — returns reasoning effort

Add to `src/lib/types.ts`:
- `AgentReasoningConfig.loopSemanticsReasoningEffort`
- `ProcessingLimits.loopSemanticsModelTokens`
- `PromptVersions.loopSemanticsPromptVersion`

**Observability:**
- `retryWithPolicyHandling()` wrapper
- `recordAgentMetrics('LoopSemanticsPolicyAgent', ...)`
- `abortSignal` passthrough
- `stopWhen: stepCountIs(15)`
- Context-isolated scratchpad: `createContextScratchpadTool('LoopSemanticsPolicy', 'policy')`

### 1.4 Prompt Template

**New file:** `src/prompts/loopSemantics/production.ts`

**IMPORTANT — Generalizability requirement:** This prompt must work across an infinite variety of surveys. Every survey has different variable names, different loop structures (occasions, medications, brands, products, waves), different banner group types, and different naming conventions. The prompt MUST NOT contain dataset-specific variable names, question content, or domain-specific terminology. All specificity comes from the dynamic inputs injected at runtime (loop summary, banner groups, cuts, datamap excerpt, deterministic findings). If plan mode or any implementation step touches this prompt, it must preserve this generality. Do not hard-code patterns from any single dataset.

The prompt must be explicit about what we mean by each anchor type and what the agent needs to decide. Structure:

```
<context>
You are generating a LOOP SEMANTICS POLICY for a crosstab pipeline.

This survey contains looped questions — respondents answer the same set of questions
multiple times, once per entity (e.g., occasion, product, brand, medication, wave).
The data has been stacked so each row represents one loop entity, not one respondent.
A respondent who answered for 3 entities has 3 rows.

Every survey is different. Loop entities could be anything — drinking occasions, medications,
brands evaluated, store visits, advertising exposures, etc. Variable naming conventions vary
widely across survey platforms and research firms. Do not assume any specific naming pattern.

Your job: classify each banner group as respondent-anchored or entity-anchored,
and for entity-anchored groups, specify how to create alias columns on the stacked frame.
</context>

<definitions>
RESPONDENT-ANCHORED:
  Describes the RESPONDENT as a whole — not any specific loop iteration.
  Examples: demographics, general attitudes, screener responses, any variable where
  a single column holds one value per respondent regardless of how many loop entities they have.
  On loop tables, this means "entities from respondents in this segment."
  The cut expression applies identically to every stacked row for a given respondent.
  NO transformation needed — the existing cut is semantically correct on the stacked frame.

ENTITY-ANCHORED:
  Describes the specific LOOP ENTITY / ITERATION, not the respondent as a whole.
  The banner plan's cut references variables that are DIFFERENT per iteration, but those
  variables are stored as separate non-loop columns (one column per iteration) rather than
  as recognized loop variables with _1/_2/_N suffixes.
  REQUIRES an alias column that selects the correct source variable based on .loop_iter,
  so that each stacked row is evaluated against the variable for ITS iteration only.

HOW TO DISTINGUISH:
  The key signal is whether a banner group's cut expression references variables that map
  to DIFFERENT loop iterations. Common patterns:
  - OR-joined comparisons on parallel variables: (VarA == X | VarB == X) where VarA is
    the iteration-1 version and VarB is the iteration-2 version of the same question
  - The deterministic_findings section may explicitly map these variables to iterations
  - If a variable exists as a single column with no per-iteration variant, and it describes
    a respondent-level attribute, it is respondent-anchored
  - If a variable has no _1/_2 suffix but the deterministic resolver or datamap labels
    show it belongs to a specific iteration, it is entity-anchored

  When in doubt, check:
  1. Does the variable have a single value per respondent, or different values per iteration?
  2. Does the deterministic resolver map it to a specific iteration?
  3. Does the variable's description or label reference a specific loop entity?
</definitions>

<loop_summary>
{loopSummary JSON — stacked frame names, iteration values, variable counts, skeletons}
</loop_summary>

<deterministic_findings>
{deterministicFindings — the resolver's variable-to-iteration mappings and evidence}
NOTE: These mappings were found deterministically from .sav metadata (variable suffixes,
label tokens, sibling patterns). Treat them as strong evidence. If a variable appears here
with a linked iteration, it is almost certainly entity-anchored.
If this section is empty, you must infer iteration-linked variables from the banner
expressions, datamap descriptions, and structural patterns in the cuts.
</deterministic_findings>

<banner_groups_and_cuts>
{For each banner group: group name, column names, original text, R expressions}
</banner_groups_and_cuts>

<datamap_excerpt>
{Focused variable list — only variables referenced by cuts and nearby context.
 Each entry has: column name, description, normalizedType, answerOptions}
</datamap_excerpt>

<instructions>
For each banner group:

1. Determine anchorType ("respondent" or "entity"):
   - If the group's cuts reference variables that DIFFER per iteration → "entity"
   - If the group's cuts reference variables that are CONSTANT across iterations → "respondent"
   - OR-joined comparisons across parallel per-iteration variables are a strong signal
     of entity-anchored (the banner plan is combining iteration-specific variables)
   - Single-column variables that describe a respondent attribute (demographics, general
     preferences, screener qualifications) are respondent-anchored
   - Use the deterministic findings as primary evidence when available

2. For entity-anchored groups, specify implementation:
   - strategy: "alias_column"
   - aliasName: a descriptive name with ".hawktab_" prefix derived from the group's
     semantic meaning (e.g., ".hawktab_category_code", ".hawktab_treatment_type")
   - sourcesByIteration: map each iteration value to the source variable for that iteration
     (e.g., { "1": "VarA", "2": "VarB", "3": "VarC" } for a 3-iteration loop)
   - The alias column will select the correct source per .loop_iter value using case_when
   - Stacked-frame cuts will then reference the alias instead of the raw per-iteration variables

3. For respondent-anchored groups:
   - strategy: "none"
   - aliasName: ""
   - sourcesByIteration: {}

4. Set shouldPartition:
   - true if each loop entity should belong to exactly one cut in the group
     (single-select / mutually exclusive response options)
   - false if entities can match multiple cuts in the group
     (multi-select / non-exclusive response options)
   - When unsure, look at the answer options: if they are coded as discrete categories
     from a single-select question, shouldPartition is likely true

5. Set confidence (0-1) and provide evidence strings explaining your reasoning.

6. If you are uncertain about any group's classification, set humanReviewRequired=true
   at the top level and explain in warnings. It is better to flag uncertainty than to
   silently produce a wrong classification.
</instructions>

<common_pitfalls>
PITFALL 1: Confusing multi-select binary flags with parallel iteration variables.
  - Multi-select flags (e.g., LocationR1, LocationR2, LocationR3) are DIFFERENT questions
    about the SAME respondent ("do you visit location 1? location 2?"). These are
    respondent-anchored — every stacked row for that respondent has the same values.
  - Parallel iteration variables (e.g., GateQ1, GateQ2) are the SAME question about
    DIFFERENT iterations ("what category was entity 1? what category was entity 2?").
    These are entity-anchored — each variable corresponds to one specific iteration.
  - Key tell: if the number of OR-joined variables in a cut MATCHES the number of loop
    iterations, that's a strong signal of parallel iteration variables.

PITFALL 2: Assuming all banner groups need transformation.
  - Most banner groups are respondent-anchored (demographics, attitudes, screener segments).
    Only groups whose cuts reference iteration-linked variables need alias columns.
  - When in doubt, "respondent" is the safer default — it preserves current behavior.

PITFALL 3: Getting sourcesByIteration wrong.
  - The number of entries in sourcesByIteration MUST match the number of loop iterations.
  - Each entry maps an iteration value (from the loop_summary) to the variable used for
    that iteration. Do NOT reverse the mapping.
  - If you cannot confidently assign every iteration to a source variable, set
    humanReviewRequired=true rather than guessing.
</common_pitfalls>

<few_shot_examples>
EXAMPLE 1: Entity-anchored group (category classification per entity)
  Loop: 2 iterations (entity 1, entity 2)
  Banner group: "Category" with cuts:
    "Premium" = (Q5a == 1 | Q5b == 1)
    "Value"   = (Q5a == 2 | Q5b == 2)
  Deterministic findings: Q5a → iteration 1, Q5b → iteration 2

  Classification:
    anchorType: "entity"
    shouldPartition: true  (single-select categories, mutually exclusive)
    strategy: "alias_column"
    aliasName: ".hawktab_category"
    sourcesByIteration: { "1": "Q5a", "2": "Q5b" }
    confidence: 0.95
    evidence: ["Deterministic resolver maps Q5a→iter1, Q5b→iter2",
               "OR pattern across 2 variables matches 2 iterations",
               "Single-select answer options (mutually exclusive)"]

EXAMPLE 2: Respondent-anchored group (demographic segment)
  Loop: 2 iterations
  Banner group: "Gender" with cuts:
    "Male"   = (Gender == 1)
    "Female" = (Gender == 2)
  Deterministic findings: (no mention of Gender)

  Classification:
    anchorType: "respondent"
    shouldPartition: true  (mutually exclusive demographics)
    strategy: "none"
    aliasName: ""
    sourcesByIteration: {}
    confidence: 0.95
    evidence: ["Gender is a single column with one value per respondent",
               "Not referenced in deterministic findings",
               "Demographic variable — same value across all loop iterations"]

EXAMPLE 3: Respondent-anchored group (multi-select behavior)
  Loop: 3 iterations
  Banner group: "Channel Used" with cuts:
    "Online"   = (ChR1 == 1)
    "In-Store" = (ChR2 == 1)
    "Mobile"   = (ChR3 == 1)
  Deterministic findings: (no mention of ChR*)

  Classification:
    anchorType: "respondent"
    shouldPartition: false  (multi-select, respondent can use multiple channels)
    strategy: "none"
    aliasName: ""
    sourcesByIteration: {}
    confidence: 0.90
    evidence: ["ChR1/ChR2/ChR3 are binary flags for different channels, not iterations",
               "3 variables but they represent 3 channels, not 3 loop iterations",
               "Not referenced in deterministic findings"]

  WHY THIS IS NOT ENTITY-ANCHORED: There are 3 variables and 3 iterations, which
  might look like a match. But the variables represent DIFFERENT CONCEPTS (channels),
  not the SAME concept for different iterations. The deterministic findings don't map
  them to iterations, and their descriptions reference different channels, not different
  loop entities.

EXAMPLE 4: Entity-anchored group, 3 iterations, no deterministic evidence
  Loop: 3 iterations (brand 1, brand 2, brand 3)
  Banner group: "Brand Attitude" with cuts:
    "Favorable"   = (BA1 == 1 | BA2 == 1 | BA3 == 1)
    "Unfavorable"  = (BA1 == 2 | BA2 == 2 | BA3 == 2)
  Deterministic findings: (empty)
  Datamap: BA1 description = "Attitude toward brand evaluated first"
           BA2 description = "Attitude toward brand evaluated second"
           BA3 description = "Attitude toward brand evaluated third"

  Classification:
    anchorType: "entity"
    shouldPartition: true
    strategy: "alias_column"
    aliasName: ".hawktab_brand_attitude"
    sourcesByIteration: { "1": "BA1", "2": "BA2", "3": "BA3" }
    confidence: 0.85  (lower because no deterministic evidence, relying on descriptions)
    evidence: ["OR pattern across 3 variables matches 3 iterations",
               "Descriptions reference 'first', 'second', 'third' — ordinal iteration language",
               "No deterministic evidence but structural + description evidence is strong"]
</few_shot_examples>
```

### 1.5 R Script Generator Changes

**File to modify:** `src/lib/r/RScriptGeneratorV2.ts`

**New input field:** Add `loopSemanticsPolicy?: LoopSemanticsPolicy` to `RScriptV2Input` interface (line 40).

**Change 1: Generate alias columns during stacking preamble**

In `generateStackingPreamble()` (line ~458), after the `bind_rows` code that creates each stacked frame, add alias column creation:

```r
# After stacked_loop_1 is created via bind_rows...

# Create alias columns for entity-anchored banner groups
stacked_loop_1 <- stacked_loop_1 %>% dplyr::mutate(
  .hawktab_needs_state = dplyr::case_when(
    .loop_iter == 1 ~ S10a,
    .loop_iter == 2 ~ S11a,
    TRUE ~ NA_real_
  )
)
```

The `case_when` is generated from `policy.bannerGroups[].implementation.sourcesByIteration`. For each entity-anchored group with `strategy == "alias_column"`, emit a `case_when` block.

**Change 2: Transform stacked-frame cuts to use alias columns**

In the stacked cuts generation (line ~507-519), for each cut that belongs to an entity-anchored banner group:
- Parse the cut's `rExpression` to find references to iteration-linked variables
- Replace the entire expression with one that references the alias column

Example:
- **Original cut:** `(S10a == 1 | S11a == 1)` for "Connection / Belonging" in group "Needs State"
- **Policy says:** Needs State is entity-anchored, aliasName = `.hawktab_needs_state`, sourcesByIteration = `{"1": "S10a", "2": "S11a"}`
- **Transformed stacked cut:** `.hawktab_needs_state == 1`

The transformation logic:
1. For each cut in `cuts_stacked_loop_N`, check if its `groupName` matches an entity-anchored banner group
2. If yes, generate the simplified expression using the alias column
3. If no (respondent-anchored), use the original `rExpression` unchanged

**Implementation approach for expression transformation:**

The simplest path: for entity-anchored groups, the LLM policy already knows the alias column name and the value patterns. The agent could also output a `transformedExpression` per cut (e.g., `.hawktab_needs_state == 1`). But this adds LLM surface area.

Better approach: **deterministic transformation.** For each entity-anchored cut:
1. Find all `sourcesByIteration` variable names referenced in the expression
2. In the expression, replace each `VARNAME` (e.g., `S10a`, `S11a`) with the `aliasName`
3. Collapse the OR: `(.hawktab_needs_state == 1 | .hawktab_needs_state == 1)` simplifies to `.hawktab_needs_state == 1`

More robustly: since all source variables map to the same alias and the value being compared is the same across the OR branches, the transformation is: **extract the comparison value and apply it to the alias column.**

Pattern for the typical case:
- Input: `(S10a == 1 | S11a == 1)` where S10a and S11a are sources for `.hawktab_needs_state`
- All sources are being compared to the same value (1)
- Output: `.hawktab_needs_state == 1`

Pattern for `%in%`:
- Input: `(S10a %in% c(1,2) | S11a %in% c(1,2))`
- Output: `.hawktab_needs_state %in% c(1,2)`

**New helper function:** `src/lib/r/transformStackedCuts.ts`

```typescript
export function transformCutForAlias(
  rExpression: string,
  sourceVariables: string[],  // e.g., ["S10a", "S11a"]
  aliasName: string,          // e.g., ".hawktab_needs_state"
): string;
```

This function:
1. Checks if the expression references any of the source variables
2. If none referenced, returns the expression unchanged
3. If referenced, replaces each source variable name with the alias name
4. Deduplicates OR branches that become identical after replacement
5. Returns the simplified expression

**Change 3: Fix the duplicate Total bug** (while we're in this code)

In `generateStackingPreamble()`, the Total cut for stacked frames uses `nrow(data)` instead of `nrow(stacked_frame)`. Fix: use `nrow(${frameName})`. And remove the duplicate Total entry.

**Change 4: Fix stat letters reference for stacked frames**

In `generateFrequencyTable()` (line ~915) and `generateMeanRowsTable()` (line ~1112), when `isLoopTable` is true, use `cut_stat_letters_${frameName}` instead of `cut_stat_letters`.

### 1.6 Pipeline Integration

**File to modify:** `src/lib/pipeline/PipelineRunner.ts`

**Step 1 addition (after loop collapse, ~line 295):** Run deterministic resolver.

```typescript
let deterministicFindings: DeterministicResolverResult | undefined;

if (validationResult.loopDetection?.hasLoops) {
  deterministicFindings = resolveIterationLinkedVariables(
    verboseDataMap,
    loopMappings,
    collapseResult.collapsedVariableNames,
  );
  log(`Deterministic resolver: found ${deterministicFindings.iterationLinkedVariables.length} iteration-linked variables`, 'cyan');
}
```

**After parallel paths complete (~line 460-500):** Run policy agent.

```typescript
let loopSemanticsPolicy: LoopSemanticsPolicy | undefined;

if (loopMappings.length > 0 && bannerResult && crosstabResult) {
  log('Running LoopSemanticsPolicyAgent...', 'cyan');

  loopSemanticsPolicy = await runLoopSemanticsPolicyAgent({
    loopSummary: loopMappings.map(m => ({
      stackedFrameName: m.stackedFrameName,
      iterations: m.iterations,
      variableCount: m.variables.length,
      skeleton: m.skeleton,
    })),
    bannerGroups: bannerResult.bannerPlan.groups,
    cuts: cutsSpec.cuts.map(c => ({
      name: c.name,
      groupName: c.groupName,
      rExpression: c.rExpression,
    })),
    deterministicFindings: deterministicFindings || { iterationLinkedVariables: [], evidenceSummary: '' },
    datamapExcerpt: buildDatamapExcerpt(verboseDataMap, cutsSpec.cuts),
    surveyMarkdown,
    outputDir,
    abortSignal,
  });

  // Save policy artifact
  await writeJSON(path.join(outputDir, 'loop-policy', 'loop-semantics-policy.json'), loopSemanticsPolicy);

  const entityGroups = loopSemanticsPolicy.bannerGroups.filter(g => g.anchorType === 'entity');
  log(`LoopSemanticsPolicyAgent: ${entityGroups.length} entity-anchored, ${loopSemanticsPolicy.bannerGroups.length - entityGroups.length} respondent-anchored`, 'green');
}
```

**Pass to R generator (~line 687):**

```typescript
const { script, validation } = generateRScriptV2WithValidation(
  {
    tables: allTablesForR,
    cuts: cutsSpec.cuts,
    statTestingConfig: effectiveStatConfig,
    significanceThresholds: effectiveStatConfig.thresholds,
    loopMappings: loopMappings.length > 0 ? loopMappings : undefined,
    loopSemanticsPolicy,  // NEW
  },
  { sessionId: outputFolder, outputDir: 'results' }
);
```

### 1.7 Output Artifacts

```
outputs/<dataset>/pipeline-<ts>/
  loop-policy/
    loop-semantics-policy.json       # Structured policy (machine + human readable)
    loop-semantics-policy-raw.json   # Raw LLM structured output
    scratchpad-loop-semantics.md     # Agent reasoning trace
    deterministic-resolver.json      # Pre-LLM evidence findings
```

---

## Phase 2: R-Side Validation + Stat Testing Guard

### What Ships

- R script generates a validation block that checks policy assertions on real data
- Validation results saved as JSON artifact
- Within-group stat testing disabled for banner groups that fail partition validation
- Pipeline summary includes warnings about policy validation results

### 2.1 R-Side Validation Block

**File to modify:** `src/lib/r/RScriptGeneratorV2.ts`

After all tables are computed but before writing `tables.json`, generate an R validation block for each entity-anchored banner group where `shouldPartition == true`:

```r
# ============================================================
# Loop Semantics Policy Validation
# ============================================================

loop_policy_validation <- list()

# Validate: Needs State (entity-anchored, shouldPartition=true)
ns_masks <- list(
  `Connection / Belonging` = with(stacked_loop_1, .hawktab_needs_state == 1),
  `Status / Image` = with(stacked_loop_1, .hawktab_needs_state == 2),
  # ... etc
)
ns_total <- nrow(stacked_loop_1)
ns_bases <- sapply(ns_masks, sum, na.rm = TRUE)
ns_sum_bases <- sum(ns_bases)
ns_na_count <- sum(is.na(stacked_loop_1$.hawktab_needs_state))

# Pairwise overlap check (sample pairs)
ns_overlaps <- list()
ns_names <- names(ns_masks)
for (i in seq_along(ns_masks)) {
  for (j in seq_len(i - 1)) {
    overlap <- sum(ns_masks[[i]] & ns_masks[[j]], na.rm = TRUE)
    if (overlap > 0) {
      ns_overlaps[[paste0(ns_names[i], " x ", ns_names[j])]] <- overlap
    }
  }
}

loop_policy_validation[["Needs State"]] <- list(
  groupName = "Needs State",
  anchorType = "entity",
  shouldPartition = TRUE,
  totalBase = ns_total,
  sumOfBases = ns_sum_bases,
  naCount = ns_na_count,
  partitionValid = (ns_sum_bases + ns_na_count == ns_total) && (length(ns_overlaps) == 0),
  bases = as.list(ns_bases),
  overlaps = ns_overlaps
)

# Write validation results
writeLines(
  toJSON(loop_policy_validation, auto_unbox = TRUE, pretty = TRUE),
  file.path(output_dir, "loop-semantics-validation.json")
)
```

This validation answers: "did the alias column + cut transformation actually produce the expected partition behavior?"

**Validation output artifact:**

```
outputs/<dataset>/pipeline-<ts>/
  validation/
    loop-semantics-validation.json
```

### 2.2 Stat Testing Guard

**File to modify:** `src/lib/r/RScriptGeneratorV2.ts`

In `generateSignificanceTesting()` (line ~1278), add logic:

1. After the R validation block runs and writes `loop-semantics-validation.json`, read it back
2. For each banner group in the validation results:
   - If `shouldPartition == true` AND `partitionValid == true`: allow within-group stat testing
   - If `shouldPartition == true` AND `partitionValid == false`: **skip within-group comparisons** for this group, emit warning
   - If `shouldPartition == false`: skip within-group comparisons (overlap is expected)

**Implementation in R:**

```r
# Read validation results
policy_val <- fromJSON(file.path(output_dir, "loop-semantics-validation.json"))

# Build set of groups where within-group testing is invalid
skip_within_group <- character(0)
for (group_name in names(policy_val)) {
  group <- policy_val[[group_name]]
  if (group$anchorType == "entity") {
    if (!isTRUE(group$partitionValid)) {
      skip_within_group <- c(skip_within_group, group_name)
      cat(paste0("WARNING: Skipping within-group stat testing for '", group_name,
                  "' — partition validation failed (sum=", group$sumOfBases,
                  " vs total=", group$totalBase, ")\n"))
    }
  }
}
```

Then in the significance testing loop, check `if (group_name %in% skip_within_group) next` before computing within-group comparisons.

**For non-loop tables:** Within-group stat testing proceeds normally (respondent-level, no stacking issues). The guard only applies to tables where `loopDataFrame` is set.

**Key nuance:** The stat testing guard doesn't need to be perfect on day one. The minimum viable behavior is: if partition validation fails, suppress all within-group stat letters for that group on loop tables. This is conservative (better to omit a letter than print a wrong one) and can be refined later.

---

## File Changes Summary

### Phase 1 (New Files)

| File | Purpose |
|------|---------|
| `src/lib/validation/LoopContextResolver.ts` | Deterministic iteration-linked variable resolver |
| `src/schemas/loopSemanticsPolicySchema.ts` | Policy output Zod schema |
| `src/agents/LoopSemanticsPolicyAgent.ts` | LLM policy agent |
| `src/prompts/loopSemantics/production.ts` | Agent prompt template |
| `src/lib/r/transformStackedCuts.ts` | Expression transformation helpers |

### Phase 1 (Modified Files)

| File | Change |
|------|--------|
| `src/lib/env.ts` | Add `getLoopSemantics*()` getters |
| `src/lib/types.ts` | Add config interface fields |
| `src/lib/pipeline/PipelineRunner.ts` | Call resolver + agent, pass policy to R gen |
| `src/lib/r/RScriptGeneratorV2.ts` | Accept policy, generate alias columns, transform stacked cuts, fix duplicate Total bug, fix stat letters reference bug |
| `.env.local` | Add `LOOP_SEMANTICS_*` config |

### Phase 2 (Modified Files)

| File | Change |
|------|--------|
| `src/lib/r/RScriptGeneratorV2.ts` | Generate R validation block, add stat testing guard |

---

## Testing Strategy

### Unit Tests

1. **Deterministic resolver** (`LoopContextResolver.ts`):
   - Test A0: variable suffix detection (`Treatment_1` -> iter 1)
   - Test A1: label token detection (`${LOCATION1}` -> iter 1)
   - Test A2: sibling detection (identical descriptions)
   - Test A3: hidden variable cascading (h-prefix, d-prefix)
   - Edge: no evidence found -> empty result
   - Edge: conflicting evidence -> low confidence

2. **Expression transformation** (`transformStackedCuts.ts`):
   - `(S10a == 1 | S11a == 1)` with alias `.hawktab_needs_state` -> `.hawktab_needs_state == 1`
   - `S10a == 1` (single source) -> `.hawktab_needs_state == 1`
   - `S9r1 == 1` (not iteration-linked) -> unchanged
   - `S10a %in% c(1,2) | S11a %in% c(1,2)` -> `.hawktab_needs_state %in% c(1,2)`
   - `(S10a == 1 | S11a == 1) & S6 == 1` (mixed) -> `.hawktab_needs_state == 1 & S6 == 1`
   - Edge: expression has no iteration-linked vars -> unchanged

3. **Schema validation**: Confirm Zod schema parses/rejects correctly

### Integration Testing (Tito's Dataset)

Run full pipeline (user runs), verify:
- Policy JSON shows Needs State as entity-anchored, Location as respondent-anchored
- Alias column `.hawktab_needs_state` is created on `stacked_loop_1`
- Stacked cuts use `.hawktab_needs_state == X` instead of `(S10a == X | S11a == X)`
- C/B base on A2 (stacked) is ~852 (not 1409)
- All 8 needs state cuts sum to ~7420 (partition)
- Non-stacked tables (S1) are unchanged
- Location cuts (S9r*) on stacked tables are unchanged (respondent-anchored)
- R-side validation confirms partition is valid

### Regression Testing (Non-Loop Dataset)

Run Leqvio (no loops), verify:
- No policy agent called
- No alias columns generated
- All output identical to pre-change

### Manual Validation Cross-Reference

Compare stacked A2 table bases with known values:
- S10a == 1 count in A2_1 data: 431 (occasion 1 C/B)
- S11a == 1 count in A2_2 data: ~421 (occasion 2 C/B)
- Expected C/B base on stacked A2: ~852
- Expected Total on stacked A2: 7,420

---

## Edge Cases

### Multiple loop groups
A dataset could have two independent loops (e.g., "occasions" and "brands"). Each loop group gets its own stacked frame. The policy agent classifies banner groups per stacked frame. Alias columns are frame-specific. The schema and pipeline already support multiple `LoopGroupMapping` entries — this edge case is about making sure the policy agent receives and classifies banner groups in the context of the correct stacked frame.

### Entity-anchored groups that DON'T partition
A banner group could be entity-anchored (uses iteration-linked variables) but not partition (multi-select per iteration). The alias column is still needed for correct iteration gating, but `shouldPartition` should be false. The Phase 2 validation and stat testing guard handle this correctly — no within-group stat letters are expected for non-partition groups.

---

## Expected Tito's Policy Output

```json
{
  "policyVersion": "1.0",
  "bannerGroups": [
    {
      "groupName": "Needs State",
      "anchorType": "entity",
      "shouldPartition": true,
      "implementation": {
        "strategy": "alias_column",
        "aliasName": ".hawktab_needs_state",
        "sourcesByIteration": { "1": "S10a", "2": "S11a" },
        "notes": "S10a describes occasion 1 needs state, S11a describes occasion 2. Each occasion has exactly one needs state."
      },
      "confidence": 0.95,
      "evidence": [
        "Deterministic resolver: pagetimeS10a label contains LOCATION1 token",
        "Deterministic resolver: pagetimeS11a label contains LOCATION2 token",
        "Cut pattern (S10a == X | S11a == X) indicates parallel per-iteration variables",
        "Answer options are mutually exclusive (single select, 8 categories)"
      ]
    },
    {
      "groupName": "Location",
      "anchorType": "respondent",
      "shouldPartition": false,
      "implementation": {
        "strategy": "none",
        "aliasName": "",
        "sourcesByIteration": {},
        "notes": "S9r* variables are respondent-level multi-select (where respondent drinks). Not iteration-specific."
      },
      "confidence": 0.90,
      "evidence": [
        "S9r* variables are not referenced by deterministic resolver",
        "S9r* are multi-select binary flags at respondent level",
        "No S9r*_1/S9r*_2 variants exist — single set of columns for all occasions"
      ]
    }
  ],
  "humanReviewRequired": false,
  "warnings": [],
  "reasoning": "Needs State uses S10a/S11a which are parallel per-iteration variables. Location uses S9r* which are respondent-level. Deterministic evidence from LOCATION tokens confirms the iteration mapping."
}
```

### Expected Transformed R Output (master.R stacked cuts)

```r
# Create alias columns for entity-anchored banner groups
stacked_loop_1 <- stacked_loop_1 %>% dplyr::mutate(
  .hawktab_needs_state = dplyr::case_when(
    .loop_iter == 1 ~ S10a,
    .loop_iter == 2 ~ S11a,
    TRUE ~ NA_real_
  )
)

# Cuts for stacked_loop_1
cuts_stacked_loop_1 <- list(
  Total = rep(TRUE, nrow(stacked_loop_1))
,  `Connection / Belonging` = with(stacked_loop_1, .hawktab_needs_state == 1)
,  `Status / Image` = with(stacked_loop_1, .hawktab_needs_state == 2)
,  `Exploration / Discovery` = with(stacked_loop_1, .hawktab_needs_state == 3)
,  `Celebration` = with(stacked_loop_1, .hawktab_needs_state == 4)
,  `Indulgence` = with(stacked_loop_1, .hawktab_needs_state == 5)
,  `Escape / Relief` = with(stacked_loop_1, .hawktab_needs_state == 6)
,  `Performance` = with(stacked_loop_1, .hawktab_needs_state == 7)
,  `Tradition` = with(stacked_loop_1, .hawktab_needs_state == 8)
,  `Own Home` = with(stacked_loop_1, S9r1 == 1)
,  `Others' Home` = with(stacked_loop_1, S9r2 == 1)
# ... Location cuts unchanged (respondent-anchored)
)
```
