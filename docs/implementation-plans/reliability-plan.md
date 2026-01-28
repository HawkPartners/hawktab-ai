# Reliability Plan

## Overview

This plan tracks the work to make HawkTab AI reliably produce publication-quality crosstabs that match partner expectations (using Joe's output as the reference standard).

**Philosophy**: We're replacing Joe's usefulness (the manual work of generating crosstabs), not necessarily replicating his exact format. Antares-style output is our MVP target - functional, readable crosstabs that the team can write reports from.

**Current State**: Part 4 complete. VerificationAgent prompt refactored (Jan 24) - now using scratchpad properly. Schema updated (`title` → `questionText`). Ready for Excel formatting polish before Part 5.

---

## Status Summary

| Part | Description | Status |
|------|-------------|--------|
| 1 | Bug Capture | COMPLETE |
| 2 | VerificationAgent | COMPLETE |
| 3 | Significance Testing (unpooled z-test) | COMPLETE |
| 3b | SPSS Validation Clarity | COMPLETE |
| 4 | TableAgent Refactor + Evaluation Framework | COMPLETE |
| 4b | Pre-Golden Dataset Polish | IN PROGRESS |
| 5 | Iteration on primary dataset (leqvio) | Not started |
| 6 | Loop/Stacked Data Support (Tito's) | Not started |
| 7 | Strategic Broader Testing (5 datasets) | Not started |

---

## Completed Parts (Collapsed)

<details>
<summary><strong>Part 1: Bug Capture</strong> - COMPLETE</summary>

Review primary test output against Joe's tabs. Capture all differences in `bugs.md`.

**Test Run Location**: `temp-outputs/test-pipeline-leqvio-monotherapy-demand-NOV217-<timestamp>/`

**Exit Criteria**: All significant differences documented and categorized.
</details>

<details>
<summary><strong>Part 2: VerificationAgent</strong> - COMPLETE</summary>

VerificationAgent implemented with:
- Survey-aware label cleanup
- Table restructuring decisions
- NET/roll-up row identification
- Low-value table flagging
- Per-agent environment configuration

**Files**: `src/agents/VerificationAgent.ts`, `src/schemas/verificationAgentSchema.ts`, `src/lib/processors/SurveyProcessor.ts`
</details>

<details>
<summary><strong>Part 3: Significance Testing</strong> - COMPLETE</summary>

Switched to unpooled z-test formula to match WinCross defaults:
- `SE = sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)` (unpooled)
- Removed n<5 hard block (no minimum sample size)
- 90% confidence level maintained

**Detailed Plan**: `docs/implementation-plans/significance-testing-plan.md`
</details>

<details>
<summary><strong>Part 3b: SPSS Validation Clarity</strong> - COMPLETE</summary>

Categorized SPSS validation mismatches with explanations:
- `x` prefix for numeric-start variables
- `_dupe` suffix for duplicate columns
- Case-insensitive matches

Users can now distinguish expected SPSS behavior from actual problems.
</details>

<details>
<summary><strong>Part 4: TableAgent Refactor + Evaluation Framework</strong> - COMPLETE (Jan 24, 2026)</summary>

### Architecture Change

```
Before: DataMap → TableAgent (LLM) → VerificationAgent → R Script
After:  DataMap → DataMapGrouper → TableGenerator → VerificationAgent (Parallel) → R Script
                      (code)           (code)            (LLM, 3x concurrent)
```

### Phase 1-2: DataMapGrouper + TableGenerator - COMPLETE

**New Files Created:**

| File | Purpose |
|------|---------|
| `src/lib/tables/DataMapGrouper.ts` | Groups datamap by parent question, filters admin/text_open |
| `src/lib/tables/TableGenerator.ts` | Deterministic table generation with mapping rules |
| `scripts/test-table-generator.ts` | Test script for validation |

**Mapping Rules:**
| normalizedType | tableType | filterValue |
|----------------|-----------|-------------|
| `numeric_range` | `mean_rows` | `""` (empty) |
| `binary_flag` | `frequency` | `"1"` |
| `categorical_select` | `frequency` | value code |

### Phase 3: Test TableGenerator - COMPLETE

Test script validated on primary dataset.

### Phase 4: Pipeline Integration + Parallelism + Observability - COMPLETE

**Changes Made:**

| File | Change |
|------|--------|
| `scripts/test-pipeline.ts` | Replaced TableAgent with TableGenerator, added `--stop-after-verification` flag, added cost summary output, uses parallel verification |
| `src/agents/tools/scratchpad.ts` | Added context-isolated scratchpad functions for parallel execution |
| `src/agents/VerificationAgent.ts` | Added `verifyAllTablesParallel()` with p-limit concurrency, metrics capture |
| `src/agents/BannerAgent.ts` | Added metrics capture |
| `src/agents/CrosstabAgent.ts` | Added metrics capture |
| `src/prompts/verification/production.ts` | Updated context for TableGenerator, added meta field docs |
| `src/prompts/verification/alternative.ts` | Same prompt updates |
| `package.json` | Added p-limit dependency |

**Performance Results (primary dataset, initial run):**
- 42 tables processed by VerificationAgent in parallel (concurrency: 3)
- 105 tables output (splits, T2B, per-item views)
- Total pipeline: ~13 minutes
- Total cost: ~$0.60
  - BannerAgent: $0.02 (1 call, 15K tokens)
  - CrosstabAgent: $0.08 (8 calls, 130K tokens)
  - VerificationAgent: $0.50 (42 calls, 660K tokens)

### Phase 5: Prompt Refactor + Schema Update (Jan 24, 2026)

**Problem**: VerificationAgent was not using scratchpad at all. The prompt framed the task as "selective refinement" with an "80/20 rule" that taught the model to pass through most tables unchanged.

**Changes Made:**

| Change | Description |
|--------|-------------|
| Schema: `title` → `questionText` | Renamed across all schemas, R script, Excel renderers. Agent can now clean/improve questionText. |
| Prompt: Reframed objective | From "selective refinement" to "analyze and optimize every table" |
| Prompt: Removed 75/25 rule | No longer telling model most tables need no changes |
| Prompt: Mandatory scratchpad | Made scratchpad MANDATORY (like BannerAgent) not "efficient" |
| Prompt: Analysis checklist | 5-step checklist: Locate → Labels → Type → Exclusion → Document |
| Prompt: Ranking guidance | Added comprehensive per-item/per-rank/top-N rollup guidance |
| Prompt: Flexible box scores | Added guidance by scale size (5pt, 7pt, 10pt, 11pt) |

**Result**: Model now uses scratchpad for every table. Quality of derived tables significantly improved.

**Post-Refactor Performance** (Jan 24, 2026):
- 127 tables output
- Total pipeline: ~17 minutes
- Total cost: ~$0.52

### Exit Criteria

- [x] TableGenerator produces correct overview tables for all question types
- [x] TableGenerator maintains API compatibility
- [x] TableGenerator tested on primary dataset
- [x] Pipeline runs end-to-end with TableGenerator replacing TableAgent
- [x] VerificationAgent processes tables in parallel (3 concurrent)
- [x] Token consumption and cost estimates tracked for all agents
- [x] VerificationAgent correctly expands grids and rankings

</details>

---

## Part 4b: Pre-Golden Dataset Polish

**Status**: IN PROGRESS

Before creating golden datasets and starting formal Part 5 iteration, address formatting and consistency issues discovered in pipeline runs. Realizing we need to match closer to Joe's output because it is more readable and easier to understand.. Additionally, ask for GPT-5 access because I'm anticipating more power needed from VerificationAgent.. Need to find where the following goes (sorting answer  options within a table, currently if many scale questions in one quesiton model might not create a separate table per answer option for the full scale., the spravato hcp messaging survey I'm doing is a good test case for this., test this next after stacked data support is implemented. also mean rows for scales. joes output is also just better for reporting.)

**Latest Run Stats** (2026-01-24): 17 minutes, 127 tables, $0.52

### Known Issues to Investigate

| Issue | Category | Notes |
|-------|----------|-------|
| Base sizing issues | Data | Some bases don't sum to 100 (allocation questions?) |
| ExcelJS formatting | Presentation | Significance letters not color-coded, text input causes green flags, readability |
| Table sorting/grouping | Structure | QuestionId not always present, tables for same question scattered |
| QuestionText consistency | Presentation | Should keep original question text + subtext for table variations (like Joe) |
| Summary table missing | Presentation | Joe includes summary table at top with sample sizes and key metrics |

### Tasks

- [x] Investigate base sizing issues (allocation vs percentage questions)
- [x] Review ExcelJS formatting improvements:
  - [x] Color code significance letters (make them noticeable)
  - [x] Use merged rows/columns where appropriate
  - [x] Switch from text input to numerical input (remove green flag warnings)
  - [x] General readability improvements
- [x] Check table sorting logic:
  - [ ] Ensure questionId is ALWAYS populated on every table
  - [ ] Ensure questionText is ALWAYS populated
  - [ ] Group related tables (all A1 variants together, findable by question ID)
  - [ ] Keep original question text as main title, add subtext for table variations (e.g., "A1 — Current Indication" then subtext "Leqvio only" or "Allocation view")
- [x] Review VerificationAgent scratchpad traces - **NOW PRODUCING RESULTS** after prompt reframe
- [ ] Add summary table at top of Excel file (like Joe does):
  - Sample sizes across different cuts
  - High-level percentages of key questions
- [ ] Make targeted prompt adjustments if needed (questionText consistency)

### Exit Criteria

- [ ] All tables have appropriate base rows
- [ ] Excel output is readable without manual adjustments (no green flags, sig letters visible)
- [ ] Tables sorted in logical order with consistent questionId/questionText
- [ ] Summary table at top of output
- [ ] No obviously wrong model decisions in output

---

## Part 5: Iteration (Primary Dataset)

**Status**: NOT STARTED (begins after Part 4b complete)

For each table in our output vs Joe's tabs, validate:
- Data accuracy (base n, counts, percentages, means)
- Significance match (letters on correct cells)
- Structure match (same tables, rows in same order)
- Labels acceptable

**Banner Plan Versions**: Original, Clean, Adjusted (maps to Joe's actual output)

**Success Criteria**: Output matches Joe's tabs, no blocking issues for report writing.

---

## Part 6: Loop/Stacked Data + Weights

**Status**: NOT STARTED (begins after Part 5)

Support surveys with loops (same questions asked multiple times for different contexts) and weighted data.

**Test Case**: `stacked-data-example/` (Tito's Future Growth)

### Understanding Stacked Data

In looped surveys, respondents answer the same questions for multiple items (e.g., Location 1 and Location 2):

**Original (wide) format:**
```
record  hLOCATION1  hLOCATION2  A4_1  A4_2
5       "home"      "bar"       6     3      ← Respondent saw 2 locations
8       "home"      ""          2     ""     ← Respondent saw 1 location
```

**Stacked (long) format:**
```
record  LOOP  hLOCATION1  A4_1
5       1     "home"      6     ← First location as separate row
5       2     "bar"       3     ← Second location as separate row
8       1     "home"      2     ← Only one row (one location)
```

The `LOOP` variable is organizational metadata, not useful for banner cuts. Banner cuts still filter by actual values (e.g., `hLOCATION1 == "home"`).

### Detection Steps

**Step 1: Loop Detection (in DataMapProcessor)**

Loop detection requires multiple layers — pattern matching alone isn't enough because `A4_1`, `A4_2` could also mean two answer options of one question.

| Layer | Check | What It Confirms |
|-------|-------|------------------|
| 1 | Variable name pattern (`_1`, `_2` suffix) | Candidates for loop |
| 2 | Both are **parent questions** (not answer options) | Not just multi-select rows |
| 3 | **Answer options match** between the two | Same question structure repeated |
| 4 | Data file: `_2` only answered by subset of `_1` responders | Confirms loop behavior |

Example from Tito's dataset:
- `A4_1` and `A4_2` both have the same 15 drink type answer options
- `A4_1` is answered by all qualified respondents
- `A4_2` is only answered by respondents who saw 2 locations
- This confirms it's the same question asked in two loop iterations

The DataMapProcessor already distinguishes parent questions from answer options (layer 2 is built). Layer 3 (matching answer options) and layer 4 (data validation) add confidence.

```
A4_1, A5_1, A6_1, A7_1, A8_1...  → Loop iteration 1
A4_2, A5_2, A6_2, A7_2, A8_2...  → Loop iteration 2
```

If many variables pass all layers → loop detected with high confidence.

**Step 2: Stacking Detection (in data file)**

Check if data is already stacked:
- If `_2` variables are empty/missing in data → already stacked
- If `_2` variables have data → not stacked, needs transformation

**Step 3: Auto-Stack (R transformation)**

If loop detected AND data not stacked, generate R code to reshape:
```r
# Reshape wide → long using tidyr
library(tidyr)
stacked_data <- data %>%
  pivot_longer(
    cols = matches("_1$|_2$"),
    names_pattern = "(.*)_(\\d+)",
    names_to = c(".value", "LOOP")
  )
```

### Weight Detection

**Step 1: Find weight variable**

Look for columns named `weight`, `wt`, `wgt`, or similar in data file.

**Step 2: Apply in R if present**

```r
# Weighted frequencies
weighted_table <- data %>%
  group_by(variable) %>%
  summarise(weighted_n = sum(weight), ...)

# Weighted means
weighted.mean(data$value, data$weight)
```

### HITL Confirmations

| Detection | HITL Prompt | Options |
|-----------|-------------|---------|
| Stacked data detected | "This data appears to be stacked (looped survey). Confirm?" | Yes / No, it's not |
| Weight variable found | "We found a weight variable (`wt`). Apply weights?" | Yes, apply / No, unweighted / That's not a weight |
| No weight found | "No weight variable detected. Is this data weighted?" | Correct, unweighted / Actually, weight is in column X |

The stacked confirmation is mostly trust-building — it doesn't change our processing much. The weight confirmation is more important because it affects calculations.

### Key Implementation Notes

1. **Banner cuts unchanged**: Still filter by actual values (location, brand, etc.), not by LOOP number
2. **We don't create weights**: If user needs weighting and data isn't weighted, they should upload a weighted .sav file
3. **Stacking is automatic**: If we detect wide format, we transform it — user just confirms we detected correctly

### Implementation Notes

This will require iteration. We don't know what every loop dataset looks like, but the multi-layer detection should be robust for Antares-style surveys. Start with Tito's as the test case and refine as we encounter other patterns.

The detection logic is deterministic (no AI needed) but may need tuning:
- What suffix patterns to recognize (`_1`/`_2` vs `r1`/`r2` vs other conventions)
- Threshold for "enough matching answer options" to confirm loop
- Edge cases where loops have slight variations between iterations

### Success Criteria

- Correctly detect looped variables in datamap (multi-layer check)
- Correctly detect if data is already stacked
- Auto-stack when needed, producing correct row counts
- Detect and apply weights when present
- Tables match expected output for Tito's dataset

---

## Part 7: Strategic Broader Testing

**Status**: NOT STARTED (begins after Part 6)

Test 5 datasets strategically to cover major failure modes:

| Category | Dataset |
|----------|---------|
| Baseline | `leqvio-monotherapy-demand-NOV217` (Part 5) |
| Loop/Stacked + Weights | `titos-future-growth` (Part 6) |
| Multi-select + NET heavy | TBD |
| Numeric-heavy (means) | TBD |
| Complex banner logic | TBD |

---

## Reference

### Current Pipeline Architecture

```
User Uploads → BannerAgent → CrosstabAgent → DataMapGrouper → TableGenerator → VerificationAgent → R Script → Excel
                   ↓              ↓               ↓                ↓                 ↓
              Banner PDF      DataMap        Grouped           Overview          Expanded
              → Cuts          → Variables    Questions         Tables            Tables
                                                               (deterministic)   (parallel, 3x)
```

### Key Files

| File | Purpose |
|------|---------|
| `src/lib/tables/DataMapGrouper.ts` | Groups datamap by parent question |
| `src/lib/tables/TableGenerator.ts` | Deterministic table generation |
| `src/agents/TableAgent.ts` | **DEPRECATED** - LLM-based table decisions |
| `src/agents/VerificationAgent.ts` | Survey-aware optimization + expansion (parallel) |
| `src/lib/observability/` | Token tracking and cost estimation |
| `src/lib/r/RScriptGeneratorV2.ts` | R script generation + significance testing |
| `scripts/test-pipeline.ts` | End-to-end test script |
| `scripts/test-table-generator.ts` | TableGenerator test script |

### Primary Test Data

`data/leqvio-monotherapy-demand-NOV217/` with inputs/, tabs/, and golden-datasets/ subfolders.

---

*Created: January 6, 2026*
*Updated: January 24, 2026*
*Status: Parts 1-4 complete, Part 4b (polish) in progress, Parts 5-7 pending*
