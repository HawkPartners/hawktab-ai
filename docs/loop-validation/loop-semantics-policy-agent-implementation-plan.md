# Loop Semantics Policy Agent — Implementation Plan

## Problem statement (the “policy layer” gap)

When loops are detected, HawkTab correctly creates **stacked frames** (one row per loop entity/iteration). However, the pipeline does **not** currently have an explicit, machine-readable **policy** for:

- what the unit of analysis is on loop tables (respondent vs entity/occasion/assignment)
- which banner groups/cuts are **respondent-anchored** vs **entity-anchored**
- how to apply cuts/filters on stacked frames so bases and segments are *semantically correct*
- how to run **stat testing** when banner columns overlap or when loop rows are correlated within respondent

As a result, the system can generate:
- correct loop-table totals (entity counts) but **incorrect banner bases** (misapplied cuts)
- overlapping “category” banner groups that should partition entities (invalid interpretation)
- statistical letters that assume independence even when groups overlap (statistically invalid)

This is not a “Tito’s-only” bug; it’s the expected failure mode any time an instrument contains:
- **iteration-linked wide variables** not detected as loop variables (Gap 2), and/or
- banner groups that are intended to be entity-level (e.g., needs state per occasion)

### Why this matters (product + defensibility)

HawkTab’s value proposition is producing tables that are:
- **analytically meaningful** (correct bases and segments)
- **reproducible** (the same inputs produce the same semantics)
- **statistically defensible** (testing mode matches group overlap / partition)

Without a policy layer, we are “guessing” semantics implicitly in R generation.

---

## Goal

Add a **Loop Semantics Policy** step (only when loops are detected) that produces a constrained JSON policy describing:

- unit-of-analysis defaults
- per banner group: anchor type, partition expectations, and implementation strategy (alias/gating)
- stat testing mode selection per banner group based on overlap/partition intent
- any required iteration-linked mappings (wide gates like `S10a`/`S11a`, `Treatment_1/2`, etc.)

Then:
- apply the policy deterministically during R script generation
- validate it deterministically on real data (overlap/base-sum/sanity checks)
- surface assumptions + validation results as output artifacts (and eventually UI messaging/overrides)

---

## Non-goals (for this plan)

- **Roster/value-to-row linking** (Gap 3) as a full feature (e.g., “knowledge of assigned medication”)
  - We will detect/flag it in policy as “roster-linked” and avoid invalid inference, but not implement the linkage here.
- Supporting both entity-level and Joe-compatible respondent-level outputs simultaneously
  - We will design the policy schema to allow future “canonical iteration” mode, but default to entity-level on loop tables.

---

## Approach summary (LLM-first policy + deterministic apply + deterministic validate)

### Why LLM-first here is the right trade-off

The hardest part is *semantic intent*: interpreting banner plans and mapping them to stacked-frame behavior.
LLMs are strong at:
- classifying “respondent vs entity” intent
- detecting when groups should partition vs overlap
- proposing clean alias variables (reducing downstream expression complexity)

We still require deterministic validation because a plausible policy can be wrong silently.

### Core pattern

1. **Generate policy (LLM)**
2. **Apply policy (deterministic)**
3. **Validate policy on data (deterministic)**
4. **If validation fails**: degrade safely (warn + disable invalid stat testing, or require human review depending on severity)

---

## Inputs and outputs

### Inputs (only when `hasLoops === true`)

- **Loop summary** (from loop detection / collapser)
  - stacked frame names, iteration sets, loop variable families
- **Banner output** (BannerAgent raw + processed)
- **Cut expressions** (CrosstabAgent raw output)
- **Focused datamap view** (verbose datamap fields needed for validation)
  - variable existence
  - variable label/description/value labels (to help the agent reason)
- **Optional** survey markdown
  - used only when policy cannot be derived confidently (e.g., Tito’s-style wide gates without strong metadata anchors)

### Outputs

1. **Policy JSON** (structured, constrained)
2. **Policy validation report** (deterministic results)
3. Optional: **human review requirement** flag + explanation

Artifacts saved alongside other pipeline outputs:

```
outputs/<dataset>/pipeline-<ts>/
  loop-policy/
    loop-semantics-policy.json
    loop-semantics-policy-raw.json
    loop-semantics-validation.json
    scratchpad-loop-semantics.md
```

---

## Agent design

### Name

`LoopSemanticsPolicyAgent` (one call per looped dataset)

### When it runs

- Trigger: `hasLoops === true`
- Timing: after BannerAgent + CrosstabAgent complete (policy needs both), before R generation
- Parallelism: can run in parallel with TableGenerator / SkipLogic / Verification, but R generation must await it

### Tools

- `scratchpad` tool only (consistent with other agents)
- Use a context-isolated scratchpad (`createContextScratchpadTool`) because this step can run concurrently with other top-level work

### Model / config

New env vars (pattern-consistent):

```bash
LOOP_SEMANTICS_MODEL=gpt-5-mini
LOOP_SEMANTICS_MODEL_TOKENS=128000
LOOP_SEMANTICS_REASONING_EFFORT=medium
LOOP_SEMANTICS_PROMPT_VERSION=production
```

Rationale: this step is semantic and benefits from a bit more reasoning than “low”, but still a single call.

### Observability requirements

Follow existing agent call pattern:
- `retryWithPolicyHandling`
- `recordAgentMetrics('LoopSemanticsPolicyAgent', ...)`
- pass `abortSignal`
- structured output via Zod schema (no `undefined` in schema)

---

## Prompt strategy (policy generator)

We want the prompt to be explicit about:
- what we mean by respondent-anchored vs entity-anchored
- what “partition” means
- what stat testing modes are valid
- the allowed implementation strategies (alias column vs gated expression)

### Prompt outline (HTML-tag style)

```
<context>
You are generating a LOOP SEMANTICS POLICY for a crosstab pipeline.
Your output must be a JSON object matching the provided schema.
You must choose ONLY from the allowed option values.
</context>

<definitions>
- respondent-anchored: applies to respondent; on loop tables it means "entities from respondents in segment"
- entity-anchored: applies to the stacked entity; must be iteration-aware on stacked frames
- roster-linked: requires mapping a selected value to a roster row; DO NOT propose within-group stat tests
- partition: segments are mutually exclusive and collectively exhaustive on the intended base
</definitions>

<loop_summary>
... condensed loop summary: frames, iterations, loop variable families ...
</loop_summary>

<banner_plan>
... BannerAgent output: group names, column names, original text ...
</banner_plan>

<crosstab_cuts>
... CrosstabAgent output: adjusted R expressions for each banner column ...
</crosstab_cuts>

<datamap_excerpt>
... only variables referenced by cuts + any high-signal related variables (e.g., hLOCATION1/2) ...
</datamap_excerpt>

<allowed_strategies>
- alias_column: create derived variable on stacked frame and cut on it
- gated_expression: wrap iteration-linked comparisons with (.loop_iter == k & ...)
</allowed_strategies>

<allowed_stat_testing_modes>
- within_group_disjoint: only if partition validated (overlap near zero)
- vs_complement_only: segment vs not-segment (works with overlap)
- none
</allowed_stat_testing_modes>

<instructions>
1) For each banner group, decide anchor type, partition intent, and stat testing mode.
2) If entity-anchored, choose an implementation strategy and specify required iteration mappings.
3) Be conservative: if unsure, set humanReviewRequired=true and provide reasoning.
</instructions>
```

---

## Schema (policy JSON)

Create new schema file:

- `src/schemas/loopSemanticsPolicySchema.ts`

Key requirements:
- no `undefined`
- keep option sets small and explicit

### Proposed schema (high level)

- `policyVersion`: string
- `unitOfAnalysis`:
  - `loopTables`: `"entity"` | `"respondent_canonical_iteration"` (future)
  - `nonLoopTables`: `"respondent"`
- `stackedFrames`: array of:
  - `frameName`: string (e.g., `stacked_loop_1`)
  - `iterationVar`: string (e.g., `.loop_iter`)
  - `iterations`: string[] (do not assume contiguous)
- `bannerGroups`: array of:
  - `groupName`: string
  - `anchorType`: `"respondent"` | `"entity"` | `"roster_linked"`
  - `baseTypeOnLoopTables`: `"entity_count"` | `"respondent_count"` (default entity)
  - `shouldPartition`: boolean
  - `statTestingMode`: `"within_group_disjoint"` | `"vs_complement_only"` | `"none"`
  - `implementation`:
    - `strategy`: `"alias_column"` | `"gated_expression"` | `"none"`
    - `aliasName`: string ("" if not used)
    - `sourcesByIteration`: record<string, string> (iteration → variable name; empty object if not used)
    - `notes`: string
  - `confidence`: number (0..1)
  - `evidence`: string[]
- `humanReviewRequired`: boolean
- `warnings`: string[]

---

## Deterministic apply (R generation changes)

Where this plugs in:
- `RScriptGeneratorV2.ts` should accept `loopSemanticsPolicy` and generate:
  - alias columns during stacked frame construction **OR**
  - transformed cut expressions for `cuts_stacked_*`

### Recommended default: alias columns for entity-anchored banner groups

Why:
- fewer fragile expression rewrites
- easier to validate
- easier to explain in output artifacts

Example (Tito’s Needs State):
- `needs_state_code = if (.loop_iter==1) S10a else if (.loop_iter==2) S11a`

Example (UCB assigned treatment):
- `assigned_treatment = if (.loop_iter==1) Treatment_1 else Treatment_2`

---

## Deterministic validate (must be on real data)

Add an R-side validation block (generated into `master.R`) that evaluates the policy on the actual stacked frame:

For each **entity-anchored** banner group:
- compute each cut mask on the stacked frame
- compute:
  - base per cut
  - overlap counts (pairwise intersections)
  - sum-of-bases vs Total base

Then write a machine-readable JSON file:
- `loop-semantics-validation.json`

### Validation-driven safety behavior (fail-safe)

- If `shouldPartition=true` but overlap is non-trivial or base sums don’t match:
  - set a warning in pipeline summary
  - force `statTestingMode="none"` for that group (do not emit within-group stat letters)
  - optionally set `humanReviewRequired=true` depending on severity

This is what makes the approach defensible.

---

## Statistical defensibility (Phase I vs Phase II)

### Phase I (ship with policy agent)

Make stat testing **group-aware**:

- If validated disjoint partition: allow `within_group_disjoint`
- If overlap allowed: only allow `vs_complement_only` or `none`

This prevents obviously invalid letters (A vs B where A and B overlap).

### Phase II (more “textbook” for loop tables)

Loop tables often contain multiple entities per respondent → within-respondent correlation.

To be fully defensible, implement clustered inference on loop tables:
- use respondent ID as a cluster variable
- compute cluster-robust standard errors for differences in proportions/means

Implementation implications:
- we must ensure the stacked frame includes a stable respondent id column
- stat testing functions in R need a cluster-robust mode

This can be added later without changing the policy architecture; the policy can include:
- `correlationModel`: `"independent_rows"` (Phase I default) vs `"clustered_by_respondent"` (Phase II)

---

## UI + regeneration (forward-compatible)

Even if we don’t build UI now, the output artifacts should support:
- showing “assumptions” (unit of analysis + banner anchor types + stat testing modes)
- exposing warnings (“Location treated as respondent-anchored due to missing assignment variables”)
- allowing a regenerate with overrides:
  - stat confidence level
  - statTestingMode overrides (where valid)
  - canonical iteration mode (future)

This suggests we should persist the policy JSON and validation JSON in outputs so the UI can later read and present them.

---

## Implementation steps (codebase-specific)

1. **Schema**
   - add `src/schemas/loopSemanticsPolicySchema.ts`
2. **Prompt**
   - add `src/prompts/loopSemantics/production.ts` (and optional `alternative.ts`)
3. **Agent**
   - add `src/agents/LoopSemanticsPolicyAgent.ts` (pattern-consistent with other agents)
4. **Env**
   - update `src/lib/env.ts` with getters for `LOOP_SEMANTICS_*`
5. **Pipeline integration**
   - update `src/lib/pipeline/PipelineRunner.ts` to invoke the agent when loops detected, after Banner+Crosstab
   - write artifacts under `outputs/.../loop-policy/`
6. **R generation**
   - update `src/lib/r/RScriptGeneratorV2.ts`:
     - accept `loopSemanticsPolicy`
     - implement alias columns and/or gated expression transform for stacked cuts
     - generate validation block + write `loop-semantics-validation.json`
7. **Stat testing mode enforcement**
   - update R generation to conditionally compute stat letters:
     - skip within-group letters when overlap or non-partition
     - optionally implement segment vs complement tests
8. **Testing**
   - unit tests for policy schema parsing and deterministic application helpers
   - integration smoke: Tito’s (needs state + location) and UCB W4 (Treatment loop) using existing outputs

---

## Acceptance criteria

For a looped dataset (Tito’s):
- Needs State on loop tables:
  - partitions occasions (sum bases ≈ Total; overlaps ≈ 0)
  - stat testing mode is valid for that structure
- Location on loop tables:
  - either partitions occasions (if assignment vars exist) **or** is explicitly flagged as respondent-anchored with stat testing disabled for within-group comparisons
- All assumptions + warnings are persisted as artifacts

For UCB W4:
- Policy correctly identifies the C-section loop as entity-level
- Respondent segments (awareness, condition, etc.) are treated respondent-anchored
- If/when an “Assigned treatment” banner is introduced, `Treatment_1/2` mapping is captured without human intervention

