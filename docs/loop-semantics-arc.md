# The Loop Semantics Arc

## From Inflated Bases to Defensible Crosstabs

This document traces the evolution from our first complete Tito's Growth Strategy pipeline output to the current system — what was wrong, what we built to fix it, and why it matters for every looped survey HawkTab will process.

---

## The Starting Point

**First successful pipeline run:** `pipeline-2026-02-07T13-38-58-276Z`

The Tito's Growth Strategy survey asks respondents about two drinking occasions (loops). The SPSS data contains iteration-linked variables: `A2_1` / `A2_2` for the main occasion question, `S10a` for the needs state of occasion 1, `S11a` for the needs state of occasion 2.

The pipeline correctly detected the loop, collapsed the iteration variables (`A2_1` / `A2_2` -> `A2`), and stacked the data so each row represents one occasion rather than one respondent. The stacked frame had 7,420 occasion-rows (from ~3,710 respondents x 2 occasions).

The numbers on non-loop tables (demographics, screeners) looked correct. The total base on stacked tables also looked correct. But the moment you looked at banner cuts on stacked tables, things fell apart.

---

## The Two Problems

### Problem 1: Needs State Cross-Occasion Contamination

The banner plan defines 8 needs state cuts (Connection/Belonging, Status/Image, etc.) using expressions like `(S10a == 1 | S11a == 1)`.

On non-loop tables, this is fine — it means "respondents who selected Connection/Belonging for either occasion." Each respondent appears once, so the OR correctly combines both occasions.

On the stacked frame, this same expression produces wrong results. Here's why:

S10a and S11a are **not loop variables**. They don't get renamed during stacking. Every stacked row — whether it represents occasion 1 or occasion 2 — carries **both** S10a and S11a with their original values.

So when the system evaluates `(S10a == 1 | S11a == 1)` on a stacked row for occasion 2:
- S10a still holds occasion 1's needs state (duplicated from the respondent)
- S11a holds occasion 2's needs state (also duplicated)
- The OR matches if EITHER occasion was Connection/Belonging

This means an occasion 2 row gets counted as Connection/Belonging even if occasion 2's actual needs state was something completely different — just because occasion 1 happened to be C/B.

**The result:**

| Metric | First Run | Expected | Error |
|--------|-----------|----------|-------|
| Total base (A2) | 7,420 | 7,420 | Correct |
| Connection/Belonging base (A2) | 1,409 | ~852 | **+65% inflated** |
| Sum of 8 needs state bases | 11,046 | 7,420 | **48.9% overlap** |

The 8 needs states should partition occasions (each occasion has exactly one needs state), but instead they overlapped massively. Every percentage in every Needs State column on every stacked table was wrong.

### Problem 2: Location Variable Mismatch

The banner plan specifies location cuts as "Assigned S9_1" (Own Home), "Assigned S9_2" (Others' Home), etc.

The crosstab agent mapped these to `S9r1 == 1`, `S9r2 == 1`, etc. But S9r1 is a numeric count variable (range 0-35): "how many drinks did you have at home?" So `S9r1 == 1` means "respondents who had exactly 1 drink at home" — wrong variable, wrong comparison.

The correct variable is `hLOCATIONr1` — a hidden binary assignment flag whose description in the data map literally reads: "RANDOMLY ASSIGN RESPONDENTS FOR THE LOCATIONS (LEFT-SIDE) S9_1 THROUGH S9_16." This is what "Assigned S9_1" actually refers to.

---

## What We Built

### The Deterministic Resolver

**File:** `src/lib/validation/LoopContextResolver.ts`

A pure function (no LLM) that scans metadata to find iteration-linked variables that aren't part of the detected loop families. It checks:

- **Variable-name suffixes:** `Treatment_1`, `Treatment_2` patterns
- **Platform tokens:** Labels containing `${LOCATION1}`, `${LOCATION2}` markers
- **Sibling patterns:** Non-loop columns with identical descriptions whose count matches the iteration count
- **Hidden variable cascading:** If `S10a -> iter 1`, then `hS10a -> iter 1`

For Tito's, the resolver found 132 iteration-linked variables and built evidence connecting S10a to occasion 1 and S11a to occasion 2 via LOCATION tokens in pagetime variable labels.

### The Loop Semantics Policy Agent

**File:** `src/agents/LoopSemanticsPolicyAgent.ts`

An LLM agent that classifies each banner group as one of two types:

**Respondent-anchored:** The cut describes the respondent as a whole, not any specific occasion. Demographics, general attitudes, assignment flags. On the stacked frame, the cut evaluates identically for every row of a given respondent. No transformation needed.

**Entity-anchored:** The cut describes the specific occasion/entity. The banner's expression references variables that are different per iteration but stored as separate non-loop columns. Requires an alias column that selects the correct source variable based on `.loop_iter`.

For Tito's, the agent classified:
- **Needs State:** entity-anchored (S10a/S11a are parallel per-iteration variables)
- **Location:** respondent-anchored (hLOCATIONr* are respondent-level assignment flags)

### Alias Columns and Cut Transformation

**Files:** `src/lib/r/RScriptGeneratorV2.ts`, `src/lib/r/transformStackedCuts.ts`

For entity-anchored groups, the R script generator creates an alias column on the stacked frame:

```r
stacked_loop_1 <- stacked_loop_1 %>% dplyr::mutate(
  `.hawktab_needs_state` = dplyr::case_when(
    .loop_iter == 1 ~ S10a,
    .loop_iter == 2 ~ S11a,
    TRUE ~ NA_real_
  )
)
```

Then stacked cuts are deterministically transformed:

| Original cut | Transformed cut |
|---|---|
| `(S10a == 1 \| S11a == 1)` | `.hawktab_needs_state == 1` |
| `(S10a == 2 \| S11a == 2)` | `.hawktab_needs_state == 2` |

Each occasion row now checks only its own needs state variable. No cross-occasion contamination.

### Crosstab Agent Hints

A small but important addition to the crosstab agent prompt: when banner expressions include words like "assigned," "given," or "shown," the agent is guided to search for hidden variables (h-prefix, d-prefix) that encode the actual assignment. This led the agent to correctly select `hLOCATIONr1` instead of `S9r1`.

### R-Side Validation

After all tables are computed, the R script validates the policy's assertions on real data:

```json
{
  "Needs State": {
    "totalBase": 10196,
    "sumOfBases": 7420,
    "naCount": 2776,
    "partitionValid": true,
    "overlaps": []
  }
}
```

7,420 + 2,776 = 10,196. Zero overlaps. The partition is mathematically proven correct.

---

## The Results

**Post-policy pipeline run:** `pipeline-2026-02-08T07-04-55-204Z` (regeneration #4)

### Needs State Bases (Stacked Tables)

| Cut | First Run | Post-Policy | Change |
|-----|-----------|-------------|--------|
| Connection / Belonging | 1,409 | 852 | -39.5% (was inflated +65%) |
| Status / Image | — | 212 | — |
| Exploration / Discovery | — | 514 | — |
| Celebration | — | 919 | — |
| Indulgence | — | 1,379 | — |
| Escape / Relief | — | 2,576 | — |
| Performance | — | 732 | — |
| Tradition | — | 236 | — |
| **Sum** | **11,046** | **7,420** | Clean partition |
| **Overlaps** | Massive | **0** | Eliminated |

### Location Bases

| Cut | First Run | Post-Policy | What Changed |
|-----|-----------|-------------|--------------|
| Own Home | 819 | 3,018 | Correct variable (hLOCATIONr1 assignment flag vs S9r1 drink count) |

### Non-Loop Tables

Unchanged. The needs state cut on non-loop tables still uses `(S10a == 1 | S11a == 1)` — respondent-level, no transformation needed. This is correct: "respondents who had a Connection/Belonging occasion."

---

## Semantic Interpretation

The same banner group ("Needs State") means different things depending on the table type. This is by design.

**On non-loop tables** (demographics, screeners): "Respondents who selected Connection/Belonging as their needs state for **at least one** of their occasions." Unit of analysis: the respondent. Each person counted once.

**On stacked/loop tables** (occasion-level questions): "Occasions that were specifically classified as Connection/Belonging." Unit of analysis: the occasion. Each occasion evaluated against its own needs state only.

Both interpretations are defensible. The first asks "what kind of person has C/B occasions?" The second asks "what happens during C/B occasions specifically?" The loop semantics policy ensures each context gets the right treatment automatically.

---

## Why This Matters

A 65% inflation in a banner column means every percentage in that column is wrong. If a client sees that 45% of Connection/Belonging occasions involved Tito's, but the real number is 32% because the base was inflated, that's not a rounding error — that's a wrong answer driving a wrong business decision.

The previous approach (used by Joe and by our first pipeline run) had no mechanism to detect this. The numbers looked plausible. The tables formatted correctly. Nothing flagged an error. You'd only catch it if you manually verified the base counts against the raw data — which nobody does for a 60-table crosstab.

The loop semantics system catches it structurally. The deterministic resolver identifies which variables are iteration-linked. The policy agent classifies how each banner group should behave on stacked data. The alias columns implement the correct filtering. And the R-side validation proves the result is right.

This isn't just a fix for Tito's. Any survey with loops — occasion studies, brand tracking, medication evaluations, product comparisons — has the same structural risk. The system now handles it generically.

---

## Files Changed

| File | Purpose |
|------|---------|
| `src/lib/validation/LoopContextResolver.ts` | Deterministic iteration-linked variable resolver |
| `src/schemas/loopSemanticsPolicySchema.ts` | Policy output schema |
| `src/agents/LoopSemanticsPolicyAgent.ts` | LLM policy agent |
| `src/prompts/loopSemantics/production.ts` | Agent prompt template |
| `src/lib/r/transformStackedCuts.ts` | Expression transformation helpers |
| `src/lib/r/RScriptGeneratorV2.ts` | Alias column generation, cut transformation, validation |
| `src/lib/pipeline/PipelineRunner.ts` | Resolver + agent integration |
| `src/prompts/crosstabAgentPrompt.ts` | Hidden variable hints |
