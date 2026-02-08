# Pipeline Feedback Log

> **Context**: This document is part of the [Reliability Plan](./reliability-plan.md), specifically finalizing **Part 2: Leqvio Monotherapy Demand Testing**.

## Summary

**Dataset**: `leqvio-monotherapy-demand-NOV217`
**Pipeline Run**: 2026-02-02
**Overall Assessment**: Pipeline is working well. The issues below are edge cases related to complex question types (multi-column grids, ranking questions).

**Decision**: We are intentionally moving forward to Part 3 (Loop/Stacked Data) and Part 4 (Broader Testing) to validate the system's robustness across different datasets. These issues are documented for future refinement but do not block progress.

**Issues Found**: 3 (all medium/low severity)

---

## Issue 1: BaseFilterAgent Multi-Column Grid Filters (A4a_leqvio)

**Discovered**: 2026-02-02
**Dataset**: leqvio-monotherapy-demand-NOV217
**Table**: a4a_leqvio
**Severity**: Medium (causes incorrect base sizes)

### Problem

The BaseFilterAgent generated an incorrect filter for `a4a_leqvio`:
- **Generated filter**: `A4r2c1 > 0`
- **Correct filter**: `A4r2c1 > 0 | A4r2c2 > 0`

This caused a base size mismatch:
- **Joe's base**: 142
- **Our base**: 131
- **Missing respondents**: ~11

### Root Cause

A4 is a two-column grid:
- Column 1 (`c1`): "In addition to statin"
- Column 2 (`c2`): "Without a statin"

The survey logic for A4a says "ONLY SHOW THERAPY WHERE A4 > 0" — meaning show the row if the respondent allocated ANY patients to that therapy (either with statin OR without statin).

The BaseFilterAgent only checked column 1 (`A4r2c1 > 0`), missing respondents who said they'd prescribe Leqvio **only** without a statin.

### Data Verification

```r
# R verification showing the issue:
A4r2c1 > 0 only (c1 only): 4
A4r2c2 > 0 only (c2 only): 11      # <-- These 11 are excluded by our filter!
Both > 0: 131
Either > 0: 146
Current filter (A4r2c1 > 0): 135
```

### Why A3a Works But A4a Doesn't

- **A3** has single-column structure: `A3r2` = Leqvio total allocation
- **A4** has two-column structure: `A4r2c1` + `A4r2c2` = Leqvio total allocation

The BaseFilterAgent correctly handled A3a (`A3r2 > 0`) but didn't recognize A4's multi-column structure.

### Fix Options

1. **Prompt enhancement**: Teach BaseFilterAgent to recognize multi-column grids (variables with `c1`/`c2` suffixes) and combine them with OR logic
2. **Pattern detection**: Add preprocessing to identify two-column variables and provide hints to the agent
3. **Manual review flag**: Flag tables where the source question has multiple columns for human review

### Related Tables

This same issue likely affects all A4a split tables:
- `a4a_praluent` (filter: `A4r3c1 > 0` — should be `A4r3c1 > 0 | A4r3c2 > 0`)
- `a4a_repatha` (filter: `A4r4c1 > 0` — should be `A4r4c1 > 0 | A4r4c2 > 0`)
- etc.

---

## Issue 2: Unnecessary Derived Table with Base=0 (a5_12m)

**Discovered**: 2026-02-02
**Dataset**: leqvio-monotherapy-demand-NOV217
**Table**: a5_12m
**Severity**: Low (table can be excluded from output)

### Problem

The pipeline created a derived table `a5_12m` from `a5` with an overly restrictive filter that resulted in **base=0** (no respondents qualify).

- **Original table**: `a5` (correct, should be kept)
- **Derived table**: `a5_12m` (base=0, should not have been created)

### Filter Applied

```r
additionalFilter: "A4r2c1 != A3r2 | A4r3c1 != A3r3 | A4r4c1 != A3r4"
```

The reasoning was: "A5 is asked only if prescribing in A4 is greater or less than A3 for rows 2/3/4 (Leqvio, Praluent, Repatha)."

### Why It Fails

This filter compares apples to oranges:
- `A4r2c1` = Leqvio "in addition to statin" only (one column of A4)
- `A3r2` = Leqvio total allocation (all of A3)

The comparison `A4r2c1 != A3r2` doesn't make sense because A4 splits the allocation into two columns (c1 and c2) while A3 has a single value. The correct comparison would need to use `(A4r2c1 + A4r2c2) != A3r2`.

### Impact

- The original `a5` table is correct and present in output
- The derived `a5_12m` table is invalid (base=0) but also present
- **Workaround**: Exclude `a5_12m` from final output

### Root Cause

The BaseFilterAgent (or VerificationAgent creating the derived table) didn't account for A4's two-column structure when building the comparison filter. This is the same underlying issue as Issue 1.

### Fix Options

1. **Improve column-sum detection**: When comparing variables with different column structures, sum the multi-column variable first
2. **Add base validation**: Flag or auto-exclude tables where the filter produces base=0
3. **Conservative splitting**: Don't create derived tables unless high confidence the filter is correct

---

## Issue 3: Ranking Question Base Calculation (A6 tables)

**Discovered**: 2026-02-02
**Dataset**: leqvio-monotherapy-demand-NOV217
**Tables**: All A6 tables (a6_A6r1_detail through a6_A6r8_detail)
**Severity**: Medium (incorrect base sizes throughout)

### Problem

A6 ranking tables have incorrect base sizes:
- **Joe's base**: 180 (all respondents)
- **Our base**: Varies (138, 37, 11, 145, 48, 53, 141, 4 depending on row)

### Root Cause

A6 is a **ranking question** where respondents rank treatment paths 1-4 (most to least likely). Not everyone ranks all options, so NA values vary by row:

```
Total respondents: 180

Non-NA counts by A6 row:
  A6r1: 138 non-NA
  A6r2: 37 non-NA
  A6r3: 11 non-NA
  A6r4: 145 non-NA
  A6r5: 48 non-NA
  A6r6: 53 non-NA
  A6r7: 141 non-NA
  A6r8: 4 non-NA
```

Our R script calculates: `base_n = sum(!is.na(A6r4))` = 145

But for ranking questions, the convention is to use the **full question base** (180), not the non-NA count per row variable. If someone didn't rank a treatment path, that's meaningful data (0% for that rank).

### This Is NOT a BaseFilterAgent Issue

BaseFilterAgent has `additionalFilter: ""` for all A6 tables. The issue is in **R script generation** - specifically how `base_n` is calculated for frequency tables.

### Fix Options

1. **Question type detection**: Identify ranking questions and use question-level base instead of variable-level non-NA count
2. **Explicit base variable**: Allow tables to specify a base variable (e.g., "use A6r1 non-NA count for all A6 rows")
3. **Force all-respondents base**: Add a flag for tables where base should be all respondents regardless of NA
4. **VerificationAgent hint**: Have agent specify base calculation method for ranking questions

### Related Tables

All A6 detail tables are affected:
- a6_A6r1_detail, a6_A6r2_detail, a6_A6r3_detail, a6_A6r4_detail
- a6_A6r5_detail, a6_A6r6_detail, a6_A6r7_detail, a6_A6r8_detail

---

## Common Theme

All three issues stem from **complex question types** that our agents don't fully recognize:

| Issue | Question Type | Component Affected |
|-------|--------------|-------------------|
| 1 | Multi-column grid (A4) | BaseFilterAgent |
| 2 | Multi-column grid comparison | BaseFilterAgent |
| 3 | Ranking question | R Script Generator |

**Future Fix Direction**: Add question type detection (grid columns, ranking) and adjust base/filter logic accordingly.

---

## Notes

- These issues are edge cases—the majority of tables in this run match Joe's output
- The core pipeline is production-ready for testing with other datasets
- We'll revisit these after validating with diverse survey types in Parts 3-4

---
---

# Tito's Growth Strategy — Pipeline Findings

> **Context**: Findings from 7 pipeline runs against the Tito's Future Growth Strategy dataset (stacked data, 5,098 respondents, 2 loop iterations). February 7, 2026.
>
> **Note**: The major stacked-data semantics issues (base size inflation from stacked data, occasion-level vs respondent-level decision) are addressed by `loop-semantics-implementation-plan.md` and are NOT repeated here. This section only captures findings that require separate fixes.

**Issues Found**: 12 (across priority levels)

---

## Issue 4: FilterTranslator Variable Family Inconsistency [PROMPT] — P0

**Dataset**: titos-growth-strategy
**Severity**: P0 (affects correctness)

### Problem

The FilterTranslator produces wildly different R expressions for the same skip logic rule across runs. The A6 on-premise filter used 5 different variable families across 6 runs: `dLOCATIONr*`, `hLOCATIONr*`, `hPREMISE*`, and combinations.

### Root Cause

The datamap has multiple variable families that could represent "on-premise" and the agent has zero guidance on which to prefer. No premise/location guidance exists in prompts. The datamap doesn't document which `hPREMISE` value means on-premise vs off-premise, and there are overlapping variable families (`hPREMISE`, `hLOCATION`, `dLOCATION`, `S9r`) that the agent chooses between randomly.

### Fix Options

1. Add explicit variable preference rules to FilterTranslator prompt: when overlapping variable families exist for the same concept, prefer hidden/derived variables (`h`-prefix) over raw survey variables
2. Consider passing the CrosstabAgent's variable mapping as context so FilterTranslator knows which variable families were already chosen for banner cuts
3. Add post-translation validation that checks all referenced variables actually exist in the datamap

**Where to fix:** `src/prompts/filtertranslator/` prompt files

---

## Issue 5: R Identifier Sanitization [CODE] — P0

**Dataset**: titos-growth-strategy
**Severity**: P0 (caused pipeline crash)

### Problem

In one run, the pipeline died with an R parse error because `loopDataFrame` was set to a human-readable string like `"Location 1 / Location 2"` instead of a valid R identifier, which got inserted directly into generated R code.

### Root Cause

`RScriptGeneratorV2.ts:920` and `RValidationGenerator.ts:222` both use `table.loopDataFrame` directly as an R variable name with no sanitization. The fix for the successful run (merging loop groups into `stacked_loop_1`) papered over it, but there's no safety net.

### Fix

Add validation that `loopDataFrame` is a valid R identifier (alphanumeric + underscore, starts with letter/dot). If not, sanitize it or throw a clear error.

**Where to fix:** `src/lib/r/RScriptGeneratorV2.ts`, `src/lib/r/RValidationGenerator.ts`

---

## Issue 6: Verification Agent Reasoning Effort [CONFIG] — P1

**Dataset**: titos-growth-strategy
**Severity**: P1 (affects output quality)

### Problem

At `low` reasoning effort, the VerificationAgent misses intuitive analytical additions that a human analyst would make:
- S9 (multi-select location question): No NET for "any location > 0" or frequency distribution
- Scratchpad depth varies 30x (1.5KB to 46KB) — sometimes thorough, sometimes superficial

### Fix

Bump `VERIFICATION_REASONING_EFFORT` from `low` to `medium` in `.env.local`. Keep all other agents at `low` since BannerAgent and CrosstabAgent are stable there.

**Cost impact:** Verification is already 65-83% of total pipeline cost ($0.45 of $0.67). Medium will increase this, but correctness > cost at this stage.

---

## Issue 7: Scratchpad Contamination Across Parallel Paths [CODE] — P1

**Dataset**: titos-growth-strategy
**Severity**: P1 (affects reliability)

### Problem

When the pipeline runs Path A (Banner/Crosstab), Path B (TableGenerator), and Path C (SkipLogic/Filter) in parallel, the global scratchpad buffer mixes entries across agents. `getAndClearScratchpadEntries()` drains ALL entries regardless of agent, so one path's clear can wipe another path's entries.

### Root Cause

`scratchpad.ts:12` has a single global `scratchpadEntries` array. Context-isolated scratchpads exist for Verification's parallel per-table calls, but top-level agents (Banner, SkipLogic, Crosstab) still use the global buffer.

### Fix

Change `getAndClearScratchpadEntries()` to accept an `agentName` parameter and only drain entries for that agent. Or switch all top-level agents to context-isolated scratchpads.

**Where to fix:** `src/agents/tools/scratchpad.ts`, then update callers in `PipelineRunner.ts`

---

## Issue 8: CrosstabAgent Location Group Ambiguity [PROMPT] — P1

**Dataset**: titos-growth-strategy
**Severity**: P1 (affects consistency)

### Problem

The banner says "Assigned S9_1" which is ambiguous. The CrosstabAgent oscillated between `S9rN == 1` (checkbox binary) and `hLOCATION1 == N` (hidden assignment). These produce different respondent subsets. 60/40 split across 5 runs.

### Fix Options

1. Add deterministic rule to CrosstabAgent prompt: "When 'Assigned' prefix appears alongside hidden h-prefix variables in the datamap, prefer the hidden assignment variable"
2. Clarify the banner input format so the ambiguity doesn't exist

**Where to fix:** `src/prompts/crosstabAgentPrompt.ts`

---

## Issue 9: Strikethrough / Visual Formatting Blindness [CODE/ARCH] — P1

**Dataset**: titos-growth-strategy
**Severity**: P1 (causes incorrect skip logic)

### Problem

The survey has values 4 and 5 crossed out in the A4/A13 condition, but ALL runs include them. The AI cannot detect strikethrough formatting because the survey text is converted to plain text before the agent sees it.

### Fix (two-part)

1. **DOCX preprocessor**: When converting survey DOCX to text, preserve formatting as inline tokens: `~~strikethrough~~`, `[HIGHLIGHT: text]`, `[COMMENT: text]`. This is deterministic and reliable.
2. **Prompt instruction**: Tell SkipLogicAgent: "Text marked with `~~strikethrough~~` has been removed from the instrument. Exclude struck-through values from all rule conditions."

**Where to fix:** Survey processing code (wherever DOCX is converted to text), then SkipLogic prompt

---

## Issue 10: SkipLogic Row-Level Rule Inconsistency [PROMPT] — P1

**Dataset**: titos-growth-strategy
**Severity**: P1 (affects consistency)

### Problem

Row-level display logic (like "show responses based on selection") is extracted in some runs but missed in others. When missed, FilterTranslator can't translate what doesn't exist. Also, certain questions get lumped into one coarse rule when they have distinct conditions.

### Fix

1. Update SkipLogic prompt to explicitly treat "PN:" (programming note) patterns as first-class output
2. Enforce rule granularity: "Create one rule per question when conditions differ"
3. Consider bumping SkipLogic reasoning to `medium` (runs once per pipeline, minimal cost)

**Where to fix:** `src/prompts/skiplogic/` prompt files

---

## Issue 11: Verification Agent NET/Split Inconsistency [PROMPT] — P1

**Dataset**: titos-growth-strategy
**Severity**: P1 (affects consistency)

### Problem

The VerificationAgent's NET creation and table splitting strategy varies dramatically across runs:
- Multi-select questions: Sometimes adds NETs, sometimes doesn't
- Grid questions: Three completely different split strategies across runs
- Naming inconsistency: `_bins` vs `_binned` vs `_dist_bins`

### Fix

1. Add explicit prompt rules for NET creation
2. Add deterministic split rules for grids
3. Define a naming convention for derived tables in the prompt
4. **Longer term:** Move repeatable enrichment decisions out of the LLM (deterministic NETs for multi-select, standard T2B/B2B for scales)

**Where to fix:** `src/prompts/verification/production.ts`

---

## Issue 12: Value Label Conflicts in Stacked Data [CODE] — P1

**Dataset**: titos-growth-strategy
**Severity**: P1 (subtle data inconsistency)

### Problem

R execution log shows loop variables with conflicting value labels between iterations (label for a given value differs between iteration 1 and iteration 2). When stacking, one label wins arbitrarily.

### Fix

In the R stacking code, add explicit conflict resolution: prefer the first iteration's labels (document this), or log a warning that surfaces in the pipeline summary.

**Where to fix:** `src/lib/r/RScriptGeneratorV2.ts` stacking logic

---

## Issue 13: _HEADER_ Duplication Warnings [CODE] — P2

**Dataset**: titos-growth-strategy
**Severity**: P2 (cosmetic/warnings)

### Problem

Static validation reports duplicate `_CAT_:_HEADER_` combinations in tables. Multiple category header rows all use `variable: "_CAT_", filterValue: "_HEADER_"`, triggering uniqueness warnings.

### Fix

Either make the validation aware that `_HEADER_` rows are exempt from uniqueness checks, or give each header a unique suffix.

**Where to fix:** Static validation logic in `RValidationGenerator.ts` or `RScriptGeneratorV2.ts`

---

## Issue 14: CrosstabAgent Alternatives Not Emitted [PROMPT] — P2

**Dataset**: titos-growth-strategy
**Severity**: P2 (reduces HITL effectiveness)

### Problem

The CrosstabAgent's scratchpad discusses alternative variable mappings, but the structured output has empty `alternatives` arrays. The reasoning mentions them, the output drops them.

### Fix

Add prompt instruction: "If you consider alternative variable families during reasoning, you MUST include them in the `alternatives` array."

**Where to fix:** `src/prompts/crosstabAgentPrompt.ts`

---

## Issue 15: FilterTranslator Confidence Threshold [CODE] — P2

**Dataset**: titos-growth-strategy
**Severity**: P2 (safety gap)

### Problem

Low-confidence filters (0.4) are sometimes NOT flagged for human review. There's no enforced threshold.

### Fix

Add a post-processing check: if any filter has confidence < 0.7, force `humanReviewRequired: true` regardless of what the agent said.

**Where to fix:** FilterTranslator output processing in `PipelineRunner.ts` or the agent wrapper

---

## Tito's — What's Working Well (don't touch)

- **BannerAgent**: 100% consistent output across all runs
- **CrosstabAgent Needs State group**: Identical expressions every run
- **Simple filter translations**: Always correct
- **T2B/B2B for scale questions**: Consistently added
- **R validation pass rate**: 63/63 in the successful run, 0 retries needed
- **Loop group merging**: Correct architectural decision
- **Label cleaning**: Reliable
- **Pipeline cost trajectory**: Down from $0.98 to $0.67 (32% reduction)

## Tito's — Agent Reliability Ranking

| Agent | Rating | Notes |
|-------|--------|-------|
| BannerAgent | Excellent | No changes needed |
| CrosstabAgent | Good | Location group ambiguity is the only issue |
| SkipLogicAgent | Fair | Row-level rules + strikethrough are the gaps |
| VerificationAgent | Needs Work | Most variable, most impactful, most expensive |
| FilterTranslatorAgent | Poor | Least deterministic, needs the most prompt work |
