# Loop Context Agent — Implementation Plan

## Problem Statement

### The Bug: Cuts/Filters on Stacked Frames Can Be Semantically Wrong

When survey data contains loops (e.g., "describe your first drinking occasion, then your second"), the pipeline stacks the data so each row represents one **occasion**, not one respondent. A respondent with 2 occasions gets 2 rows.

The problem: **some variables are iteration-linked even though they are not part of the detected loop-variable families**. When we stack, those iteration-linked variables are duplicated across every stacked row for that respondent. Any cut/filter that references them will then be evaluated on the wrong unit-of-analysis.

This is not limited to “banner cuts”. It can affect:
- Banner cuts applied to loop tables (`cuts_stacked_loop_*`)
- Table-level filters applied to loop tables (e.g., skip-logic-derived filters)
- Any future logic that evaluates expressions on a stacked frame

### Concrete Example (Tito's Growth Strategy)

The survey asks respondents about two drinking occasions:
- **S10a**: "Which best describes the reason for having a drink?" → asked about **occasion 1**
- **S11a**: Same question → asked about **occasion 2**
- **A1–A19**: Detailed occasion questions → looped for both occasions (stored as A1_1/A1_2, A2_1/A2_2, etc.)

S10a and S11a are **iteration-linked (wide) variables** — in this survey they correspond to occasion 1 vs occasion 2, but they aren't loop variables (no `_1`/`_2` suffix). They're stored as separate columns.

**Original data (3 respondents):**

| respondent | S10a | S11a | A2_1 | A2_2 |
|-----------|------|------|------|------|
| R1 | 1 (C/B) | 3 (Expl) | 5 | 7 |
| R2 | 3 (Expl) | 1 (C/B) | 4 | NA |
| R3 | 1 (C/B) | 1 (C/B) | 5 | 5 |

**After stacking (our system creates this):**

| row | respondent | S10a | S11a | A2 | .loop_iter |
|-----|-----------|------|------|----|-----------|
| 1 | R1 | 1 | 3 | 5 | 1 |
| 2 | R2 | 3 | 1 | 4 | 1 |
| 3 | R3 | 1 | 1 | 5 | 1 |
| 4 | R1 | 1 | 3 | 7 | 2 |
| 5 | R2 | 3 | 1 | NA | 2 |
| 6 | R3 | 1 | 1 | 5 | 2 |

**S10a and S11a are identical in both rows for each respondent.** The stacking duplicates all non-loop columns.

**Current banner cut for "Connection/Belonging": `S10a == 1 | S11a == 1`**

| row | respondent | .loop_iter | Cut matches? | Actually C/B occasion? |
|-----|-----------|-----------|--------------|----------------------|
| 1 | R1 | 1 | YES (S10a=1) | YES (occasion 1 = C/B) |
| 2 | R2 | 1 | YES (S11a=1) | NO (occasion 1 = Exploration) |
| 3 | R3 | 1 | YES (both) | YES |
| 4 | R1 | 2 | YES (S10a=1) | NO (occasion 2 = Exploration) |
| 5 | R2 | 2 | YES (S11a=1) | YES (occasion 2 = C/B) |
| 6 | R3 | 2 | YES (both) | YES |

**Result: All 6 rows match. But only 4 are actually C/B occasions.**

- Row 2 is wrong: R2's occasion 1 is Exploration, but included because R2 has S11a=1 (occasion 2)
- Row 4 is wrong: R1's occasion 2 is Exploration, but included because R1 has S10a=1 (occasion 1)

**Correct cut:** `(.loop_iter == 1 & S10a == 1) | (.loop_iter == 2 & S11a == 1)`

This correctly yields rows 1, 3, 5, 6 — only actual C/B occasions.

### Real-World Impact

In the Tito's pipeline output:
- **Total base (A2)**: 7420 occasions (correct)
- **C/B base (A2)**: 1409 (wrong — includes non-C/B occasions)
- **Expected C/B base (A2)**: ~852 (431 from occasion 1 + 421 from occasion 2)

The needs state banner cuts also **overlap** (a single occasion row can match multiple needs states), meaning they don't partition the data. With the correct cuts, each occasion belongs to exactly one needs state and all cuts sum to 7420.

### Why This Can't Be Solved with Banner Plan Changes

Even if the banner plan used just `S10a == 1` (without the OR), the stacked frame still breaks:
- A respondent with S10a=1 has both rows matching (S10a is constant across iterations)
- Their occasion 2 row (which may be Exploration, not C/B) gets incorrectly included
- The only correct stacked expression requires `.loop_iter` awareness

### Scope: This Affects Loops Beyond “2 Occasions”

Loops are a standard market research design. Every looped survey will have "gate" variables that:
1. Determine what the respondent loops through (product, occasion, brand, etc.)
2. Are stored as separate columns per iteration (S10a for iter 1, S11a for iter 2)
3. Are NOT loop variables (don't follow the `_1`/`_2` naming convention)
4. Get duplicated in both rows when stacked

The validation test corpus already shows loop structures that require generality:
- Iteration counts can be **2, 3, 4, 12, 16+**
- Iteration identifiers can be **non-contiguous** (e.g., “11–18” style iterators from grid exports)

So the fix must not assume:
- exactly 2 iterations
- iteration values are `1..N` with no gaps

The system needs a general solution that works for any loop dimension and any iteration set.

---

## Solution Overview

### Loop Context Resolution (Deterministic-first, LLM fallback)

We need a **loop context resolver** that produces an “iteration-linked mapping”:

- **Respondent-level variables**: apply to every stacked row for that respondent (safe to evaluate on stacked frames)
- **Iteration-linked (wide) variables**: one column per iteration (or one question per iteration) but not detected as loop variables; must be gated by `.loop_iter` (or unified into a per-row derived column)

**Key principle**: keep upstream agents stable. The CrosstabAgent output can remain “human/banner natural”. The resolver output is used deterministically at R generation time to make stacked-frame evaluation correct.

### Pipeline Flow

```
Current:
  Loop Detection → [parallel agents] → R Script Generator → cuts on stacked frame

New:
  Loop Detection → LoopContextResolver → [parallel agents] → R Script Generator
                         ↓                                          ↓
            iteration-linked variable map          makes stacked-frame expressions correct
```

The LoopContextResolver runs only when loops are detected. It should be **deterministic-first** (cheap + auditable), and only call an LLM when the deterministic evidence is insufficient.

---

## Deterministic-first Resolver (Option A)

The goal is not to “guess” semantics; it’s to exploit any **hard evidence** already present in the `.sav`-derived metadata.

### A0) Evidence source: variable-name iteration suffixes (when present)

Many datasets include “iteration-linked (wide)” variables where the iteration is encoded directly in the column name, even though they are not part of the detected loop-variable families.

Example (UCB caregiver waves):
- `Treatment_1` and `Treatment_2` exist as separate columns but are not part of the `C*` loop-variable families.
- These are clearly iteration-linked to the same 2-iteration medication loop (medication 1 vs medication 2).

When a non-loop column matches a strict pattern like:
- `^(?<root>[A-Za-z][A-Za-z0-9]*)_(?<iter>\\d+)$` (e.g., `Treatment_1`)

and that `iter` is present in a loop group’s iteration set, the resolver can deterministically map:
- `Treatment_1 → iteration 1`
- `Treatment_2 → iteration 2`

This tends to be more robust than relying on survey text, and does not require an LLM.

### A1) Evidence source: platform-exported “shadow metadata” variables (when present)

Some instruments export auxiliary variables whose **labels contain the exact rendered question text**, including roster/loop placeholders. Tito’s is an example:

- `pagetimeS10a`’s label contains `$ {LOCATION1...}`
- `pagetimeS11a`’s label contains `$ {LOCATION2...}`

Other “shadow metadata” variables that sometimes embed similar rendered-question text include things like “last seen question” / dropout trackers (e.g., `vdropout`-style variables whose value labels enumerate question text).

This is useful because it gives a **deterministic iteration token** (`LOCATION1` vs `LOCATION2`) tied to a concrete survey question (`S10a` vs `S11a`).

Important clarification (because the name is misleading):
- We do **not** use the numeric “page time” values for analysis.
- We only use the **variable label string** as metadata/evidence (the same way we use SPSS labels/value labels).

This evidence source is **optional**: many datasets will not have `pagetime*` (or equivalent shadow-metadata) variables at all, even when loops exist. When absent, skip it.

### A2) Evidence source: other label/description tokens in the verbose datamap (when present)

More generally, we can scan `.sav` labels/contexts for iteration-markers like:
- `LOCATION1`, `LOCATION2`, `BRAND3`, `PRODUCT4`
- “First / Second / Third …” phrasing embedded in labels
- Any stable roster token + numeric suffix used by the instrument

When found, build mappings like:
- `S10a → iteration 1` (because the only strong evidence tying `S10a` to an iteration token is `LOCATION1`)

### A2b) Evidence source: “sibling columns” with identical question text (when present)

Some instruments store per-iteration questions as different question IDs/columns with identical wording (e.g., `S10a` and `S11a` both described as “Which best describes the reason…”).

This shows up in `.sav` metadata as **duplicate descriptions** across multiple columns.

When the resolver finds a small sibling set (often size = number of loop iterations) where:
- columns are not loop variables
- descriptions are identical after normalization
- and other evidence suggests they correspond to iterations (e.g., one of the sibling columns is used in “loop 1” sections of the survey)

then we can map those siblings to iterations deterministically *only if* we have an anchor (e.g., survey structure, token evidence, or LLM fallback). Without an anchor, “identical description” alone is not sufficient to assign iteration numbers.

### A3) Confidence + safety checks

The resolver should emit a confidence per mapping and apply basic sanity checks:
- Only map variables that are actually referenced by stacked-frame expressions (cuts/filters), to reduce scope and risk
- Do not assume iteration values are `1..N`; use the iteration set from loop detection output
- If evidence is weak or conflicting, return “unknown” and defer to LLM fallback (or require human review)

### Not in scope (separate class of problem): roster/value-to-row linking

Be careful not to conflate “iteration-linked wide columns” with cases where a respondent-level roster/grid needs to be matched to the currently stacked entity.

Example pattern:
- `Treatment_1` contains a coded medication ID
- `B3r*` contains knowledge ratings per medication row
- You might want “knowledge of the assigned medication”, which requires mapping **values** in `Treatment_*` to the correct `B3rK` row.

That is a **roster linking** problem (value-label matching) and is not solved by `.loop_iter` gating alone.

### A4) Empirical signal coverage (from our validation corpus)

In `outputs/_validation-test/run-2026-02-06T03-35-32/` there are 15 datasets where loop detection fired (15 `loop-variables.json` files).

Using only “multi-index placeholder” evidence (strings like `$ {LOCATION2...}` / `$ {Treatment_2...}` inside `.sav`-derived labels/contexts), **4/15** datasets (~27%) had a clear iterator-token root with multiple indices:
- Tito’s: `LOCATION` → `{1,2}`
- UCB W4/W5/W6: `Treatment_` → `{1,2}`

This is not a guarantee of full deterministic resolution for every iteration-linked variable, but it’s a good indication that:
- deterministic-first resolution will work *some of the time* (cheap + auditable)
- we still need an LLM fallback path for the remainder

---

## Derived Per-Row Alias Columns (Option B)

Instead of rewriting every expression to add `.loop_iter` guards, we can **materialize per-row “occasion-level” aliases** on the stacked frame, then simplify expressions.

Example (2-iteration case, conceptually generalizable):
- Create `needs_state_raw` on `stacked_loop_1`:
  - if `.loop_iter == 1` then `needs_state_raw = S10a`
  - if `.loop_iter == 2` then `needs_state_raw = S11a`

Then the correct stacked cut becomes:
- `needs_state_raw == 1`

This approach:
- concentrates iteration logic in one place (data frame construction)
- makes downstream expressions simpler and less error-prone

Trade-offs:
- you still need the same “which variables belong to which iteration” mapping (Option A / LLM fallback)
- you may need to **transform cut expressions** to reference the alias column (or generate cuts directly against the alias)

---

## LLM Fallback: LoopContextAgent (Optional, not default)

When deterministic evidence is insufficient, a lightweight agent can read the survey markdown and identify **iteration-linked variables** (including cases that don’t follow obvious naming patterns).

The agent should be treated as a **fallback** mechanism for generality across diverse instruments, not as the primary path for every looped dataset.

---

## Agent Design

### When It Runs

- **Condition**: Only when `hasLoops === true` *and* the deterministic resolver cannot confidently map all iteration-linked variables that appear in stacked-frame expressions (cuts/filters).
- **Timing**: After loop detection + survey processing + deterministic resolver attempt.
- **Concurrency**: This does **not** need to block Banner/Crosstab/SkipLogic. It only needs to complete before **R generation**. It can run in parallel with other agent paths and be awaited right before writing `master.R`.

### Inputs

| Input | Source | Purpose |
|-------|--------|---------|
| Survey markdown | `processSurvey()` output | Understand survey flow, identify which questions precede each loop |
| Loop group summary | `LoopGroupMapping[]` from LoopCollapser | Know which variables are looped, how many iterations, variable names |
| Non-loop variable list | Verbose datamap, filtered to non-loop variables | Give the agent concrete variable names to map (S10a, S11a, etc.) |

**Why not give it the full datamap?** The full verbose datamap for Tito's is ~2000 entries. We only need the agent to see non-loop variables and their descriptions. The loop variables are already accounted for by the stacking system.

**Proposed input construction:**

```typescript
// Filter datamap to non-loop variables only
const nonLoopVars = verboseDataMap
  .filter(v => !collapsedVariableNames.has(v.column))
  .map(v => ({
    column: v.column,
    description: v.description,
    normalizedType: v.normalizedType, // Include type so agent can see 'admin' vars
    answerOptions: v.answerOptions
  }));
```

This gives the agent a focused set of variables to evaluate against the survey flow.

### Output Schema

```typescript
const LoopContextOutputSchema = z.object({
  iterationLinkedVariables: z.array(z.object({
    variableName: z.string(),           // e.g., "S10a"
    linkedIteration: z.string(),        // e.g., "1" (matches loop iteration values)
    surveyEvidence: z.string(),         // e.g., "S10a appears in 'First Occasion' section before loop"
    confidence: z.number(),             // 0-1
  })),
  reasoning: z.string(),               // Brief summary of how the agent determined the mappings
  loopGateDescription: z.string(),     // e.g., "Respondents describe up to 2 drinking occasions"
});
```

**Example output:**

```json
{
  "iterationLinkedVariables": [
    { "variableName": "S10a", "linkedIteration": "1", "surveyEvidence": "Asked in 'First Occasion' section", "confidence": 0.95 },
    { "variableName": "S10b", "linkedIteration": "1", "surveyEvidence": "Follow-up to S10a", "confidence": 0.95 },
    { "variableName": "S11a", "linkedIteration": "2", "surveyEvidence": "Asked in 'Second Occasion' section", "confidence": 0.95 },
    { "variableName": "S11b", "linkedIteration": "2", "surveyEvidence": "Follow-up to S11a", "confidence": 0.95 }
  ],
  "reasoning": "Survey has two occasion loops. S10a/S10b are asked before the first loop; S11a/S11b before the second.",
  "loopGateDescription": "Respondents describe up to 2 drinking occasions with looped questions A1-A19"
}
```

### Prompt Strategy

The prompt should be focused and structured:

1. **Context**: "This survey contains looped questions. Respondents answer the same set of questions multiple times (once per [occasion/product/brand]). The looped questions have been identified. Your job is to find non-loop variables that are tied to specific loop iterations."

2. **Loop group info**: "The following variables are looped across {N} iterations: {list of base names}. Iteration values: {1, 2, ...}."

3. **Survey document**: Full survey markdown (same as SkipLogicAgent receives)

4. **Non-loop variables**: "These variables are NOT part of the loop. Determine which, if any, are asked specifically about one loop iteration (e.g., asked before/within a specific iteration's section)."

5. **Output instructions**: "For each iteration-linked variable, identify which loop iteration it belongs to. Variables that are truly respondent-level (demographics, screener) should NOT be listed."

### Agent Configuration

```bash
# .env.local
LOOP_CONTEXT_MODEL=gpt-5-mini
LOOP_CONTEXT_MODEL_TOKENS=128000
LOOP_CONTEXT_REASONING_EFFORT=low    # Focused task, low should suffice
```

---

## Hidden Variable Cascading (Deterministic)

After the agent returns its mapping, a **deterministic post-processing step** cascades the mapping to related hidden variables.

### Logic

For each iteration-linked variable identified by the agent (e.g., `S10a → iteration 1`):

1. **h-prefix check**: Does `hS10a` exist in the datamap? If yes, add `hS10a → iteration 1`
2. **d-prefix check**: Does `dS10a` exist? If yes, add `dS10a → iteration 1`
3. **Sub-question check**: Do `S10b`, `S10c`, etc. exist? If yes, check if they're follow-ups (same section, piped from S10a). If the agent already tagged them, great. If not, cascade.

### Why Deterministic?

Hidden variables (h-prefix) are derived from their parent survey variables. If `S10a → iteration 1`, then `hS10a` (the hidden coded version) is definitionally also `→ iteration 1`. No AI judgment needed.

The DataMapProcessor already classifies h-prefix variables as `admin` type (line 231-236 in DataMapProcessor.ts), so the agent may not encounter them in the survey document. The cascading ensures they're covered.

### Implementation

```typescript
function cascadeOccasionMappings(
  agentMappings: OccasionLinkedVariable[],
  verboseDataMap: VerboseDataMap[]
): OccasionLinkedVariable[] {
  const allMappings = [...agentMappings];
  const existingVars = new Set(verboseDataMap.map(v => v.column));
  const mappedVars = new Set(agentMappings.map(m => m.variableName));

  for (const mapping of agentMappings) {
    const varName = mapping.variableName;

    // h-prefix: hS10a from S10a
    const hVar = `h${varName}`;
    if (existingVars.has(hVar) && !mappedVars.has(hVar)) {
      allMappings.push({
        ...mapping,
        variableName: hVar,
        surveyEvidence: `Hidden variable derived from ${varName}`,
      });
    }

    // d-prefix: dS10a from S10a
    const dVar = `d${varName}`;
    if (existingVars.has(dVar) && !mappedVars.has(dVar)) {
      allMappings.push({
        ...mapping,
        variableName: dVar,
        surveyEvidence: `Derived variable from ${varName}`,
      });
    }
  }

  return allMappings;
}
```

---

## R Script Generator Changes

### Cut Transformation for Stacked Frames

When generating `cuts_stacked_loop_N`, the R script generator needs to check each cut expression for iteration-linked variables and transform accordingly.

**Current flow (lines 507-520 of RScriptGeneratorV2.ts):**

```typescript
// For each cut, generate: `cutName` = with(frameName, expr)
for (const cut of cuts) {
  lines.push(`, \`${cut.name}\` = with(${frameName}, ${cut.expression})`);
}
```

**New flow:**

```typescript
for (const cut of cuts) {
  const transformedExpr = transformCutForStackedFrame(
    cut.expression,
    occasionLinkedVarMap,  // Map<variableName, iterationValue>
    frameName
  );
  lines.push(`, \`${cut.name}\` = with(${frameName}, ${transformedExpr})`);
}
```

### Transformation Logic

The transformer needs to parse the R expression and replace iteration-linked variable references with `.loop_iter`-gated versions.

**Input**: `(S10a == 1 | S11a == 1)`
**Occasion map**: `{ S10a: "1", S11a: "2" }`
**Output**: `((.loop_iter == 1 & S10a == 1) | (.loop_iter == 2 & S11a == 1))`

**Input**: `S10a == 1` (single variable)
**Output**: `(.loop_iter == 1 & S10a == 1)` (only matches iteration 1 occasions)

**Input**: `S9r1 == 1` (respondent-level, NOT iteration-linked)
**Output**: `S9r1 == 1` (unchanged — correctly matches both rows)

### Implementation Approach

The transformation should be **string-based pattern matching**, not a full R parser. The cut expressions from the CrosstabAgent follow predictable patterns:

- `VAR == VALUE`
- `VAR %in% c(VALUES)`
- `(EXPR | EXPR)` (OR combinations)
- `(EXPR & EXPR)` (AND combinations)

For each atomic comparison (`VAR == VALUE` or `VAR %in% c(...)`):
1. Check if `VAR` is in the iteration-linked map
2. If yes, wrap: `(.loop_iter == {iteration} & VAR == VALUE)`
3. If no, leave unchanged

```typescript
function transformCutForStackedFrame(
  expression: string,
  occasionMap: Map<string, string>,  // variableName → iteration
  frameName: string
): string {
  // For each iteration-linked variable in the expression
  for (const [varName, iteration] of occasionMap) {
    // Match patterns: varName == X, varName %in% c(...)
    const eqPattern = new RegExp(`(${escapeRegex(varName)}\\s*==\\s*\\S+)`, 'g');
    const inPattern = new RegExp(`(${escapeRegex(varName)}\\s*%in%\\s*c\\([^)]+\\))`, 'g');

    expression = expression.replace(eqPattern, `(.loop_iter == ${iteration} & $1)`);
    expression = expression.replace(inPattern, `(.loop_iter == ${iteration} & $1)`);
  }
  return expression;
}
```

### Non-Stacked Cuts Are Unchanged

The `cuts` list (for `data` frame) continues using the original expressions. The CrosstabAgent output is not modified. Only the `cuts_stacked_loop_N` list gets transformed expressions.

This means:
- Non-loop tables (S1, S6, etc.) on the `data` frame: original expression applies → respondent-level analysis
- Loop tables (A2, A3, etc.) on `stacked_loop_1`: transformed expression applies → occasion-level analysis

---

## Pipeline Integration

### Call Sequence

```typescript
// In PipelineRunner.ts, after survey processing and loop detection:

let occasionLinkedVarMap: Map<string, string> | undefined;

if (hasLoops && surveyMarkdown) {
  log('Starting LoopContextAgent...', 'cyan');
  const loopContextResult = await runLoopContextAgent({
    surveyMarkdown,
    loopMappings: loopCollapseResult.loopMappings,
    nonLoopVariables: buildNonLoopVarList(dataMapResult.verbose, loopCollapseResult),
    outputDir,
    abortSignal,
  });

  // Cascade to hidden/derived variables
  const cascaded = cascadeOccasionMappings(
    loopContextResult.occasionLinkedVariables,
    dataMapResult.verbose
  );

  // Build lookup map: variableName → iteration
  occasionLinkedVarMap = new Map(
    cascaded.map(v => [v.variableName, v.linkedIteration])
  );

  log(`LoopContextAgent: ${cascaded.length} iteration-linked variables mapped`, 'green');
}

// Pass to R script generator
const rInput: RScriptV2Input = {
  tables: tablesWithLoopFrame,
  cuts: finalCuts,
  loopMappings: loopCollapseResult?.loopMappings,
  occasionLinkedVarMap,  // NEW FIELD
  // ...
};
```

### Timing

The LoopContextAgent runs **before** the parallel paths (Path A/B/C). It adds a small amount of time to the pipeline, but only when loops are detected. Expected duration: 10-30 seconds (single AI call, focused task, low reasoning effort).

If latency is a concern, it could potentially run in parallel with Path B (TableGenerator) since they don't depend on each other. But Path A (CrosstabAgent) and Path C (SkipLogic) also don't depend on it — only the R script generator does.

### Output Artifacts

```
outputs/{dataset}/pipeline-{ts}/
  loopcontext/
    loopcontext-output-{timestamp}.json    # Agent output
    loopcontext-output-raw.json            # Raw structured output
    scratchpad-loopcontext.md              # Agent reasoning trace
```

---

## Edge Cases & Considerations

### 1. Surveys with 3+ loop iterations

Some surveys loop 3+ times (e.g., "describe your top 3 brands"). The agent needs to handle:
- S10a → iteration 1, S11a → iteration 2, S12a → iteration 3
- The output schema already supports arbitrary iteration values

### 2. No iteration-linked variables found

Some loops use purely structural gating (e.g., loop through brands from a multi-select). In this case, the resolver returns an empty `iterationLinkedVariables` array, and the R script generator makes no transformations.

### 3. Iteration-linked variables used in skip logic filters

If a FilterTranslator output references an iteration-linked variable (e.g., S10a/S11a-style gates) in a skip rule, the same transformation may be needed for table-level filters on stacked data. This is a secondary concern — address after banner cuts are working.

### 4. Variables that SHOULD appear in multiple iterations

Some variables genuinely apply to all stacked rows (e.g., demographics, general attitudes). These should NOT be in the iteration-linked mapping. The resolver/agent’s job is to distinguish:
- **Respondent-level**: Demographics, screener, general attitudes → NOT iteration-linked
- **Iteration-linked (wide)**: Variables that are asked/defined per-iteration but are stored as separate non-suffixed columns → iteration-linked

### 5. Banner cuts with mixed variable types

A single cut expression might reference both iteration-linked AND respondent-level variables:
```r
S10a == 1 & S6 == 1   # C/B needs state AND male
```

The transformer should only gate the iteration-linked variable:
```r
(.loop_iter == 1 & S10a == 1) & S6 == 1
```

### 6. The duplicate Total cut in stacked frames

(Separate bug found during this investigation)

The current R output has two `Total` entries in `cuts_stacked_loop_1`:
```r
Total = rep(TRUE, nrow(stacked_loop_1))       # correct length
`Total` = with(stacked_loop_1, rep(TRUE, nrow(data)))  # wrong length: 5098 instead of 10196
```

The second entry uses `nrow(data)` instead of `nrow(stacked_loop_1)`. This is a separate code bug in how cuts are pre-computed for stacked frames. Fix independently.

### 7. Stat letters bug for stacked frames

(Separate bug found during this investigation)

`generateFrequencyTable` and `generateMeanRowsTable` reference `cut_stat_letters` instead of `cut_stat_letters_${frameName}` for loop tables. The stat letters for the stacked frame are pre-computed but never used. Fix independently.

---

## Testing Strategy

### Unit Testing

1. **Cut transformation function**: Test with various expression patterns
   - Simple: `S10a == 1` → `(.loop_iter == 1 & S10a == 1)`
   - OR: `(S10a == 1 | S11a == 1)` → `((.loop_iter == 1 & S10a == 1) | (.loop_iter == 2 & S11a == 1))`
   - Mixed: `S10a == 1 & S6 == 1` → `(.loop_iter == 1 & S10a == 1) & S6 == 1`
   - No match: `S9r1 == 1` → `S9r1 == 1` (unchanged)
   - %in%: `S10a %in% c(1, 2)` → `(.loop_iter == 1 & S10a %in% c(1, 2))`

2. **Hidden variable cascading**: Test h-prefix and d-prefix detection

### Integration Testing

1. **Tito's dataset**: Run full pipeline, verify:
   - C/B base on A2 (stacked) ≈ 852 (not 1409)
   - All 8 needs state cuts sum to 7420
   - Non-stacked tables (S1) unchanged
   - Location cuts (S9r*) unchanged (respondent-level, no transformation)

2. **Non-loop dataset (Leqvio)**: Run full pipeline, verify no regressions (agent should not be called)

### Manual Validation

Cross-reference with the user's manual Excel calculations:
- S10a == 1 in A2_1: 431 (occasion 1 C/B count)
- S11a == 1 in A2_2: ~421 (occasion 2 C/B count)
- Total C/B occasions: ~852

---

## File Changes Summary

| File | Change | Type |
|------|--------|------|
| `src/agents/LoopContextAgent.ts` | New file — agent implementation | New |
| `src/prompts/loopcontext/` | New directory — prompt template | New |
| `src/schemas/loopContextSchema.ts` | New file — output schema | New |
| `src/lib/env.ts` | Add `getLoopContextModel()`, etc. | Edit |
| `src/lib/pipeline/PipelineRunner.ts` | Call LoopContextAgent, pass mapping to R generator | Edit |
| `src/lib/r/RScriptGeneratorV2.ts` | Transform cuts for stacked frames, accept `occasionLinkedVarMap` | Edit |
| `.env.local` | Add `LOOP_CONTEXT_*` config | Edit |
| `src/lib/processors/DataMapProcessor.ts` | (maybe) Add cascading helper | Edit |

---

## Open Questions

1. **Should the LoopContextAgent run in parallel with other agents?** It doesn't block Banner/CrosstabAgent/SkipLogic, but the R script generator needs its output. If it runs in parallel with Path A/B/C, the R script generation step would need to await it.

2. **What if the agent makes a mistake?** Consider adding a `humanReviewRequired` flag if confidence is below a threshold. The pipeline could still run with a warning in the output.

3. **Could this be semi-deterministic?** For surveys where the variable names follow a pattern (S10a/S11a, S10b/S11b — where the number increments with iteration), we could detect this without AI. The agent provides a safety net for non-obvious patterns.
