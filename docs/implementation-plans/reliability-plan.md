# Reliability Plan

## Overview

This plan tracks the work to make HawkTab AI reliably produce publication-quality crosstabs.

**Philosophy**: We're replacing Joe's usefulness, not necessarily replicating his exact format. Functional, readable crosstabs that the team can write reports from.

---

## Part 1: Stable System for Testing

**Status**: IN PROGRESS

**Goal**: Get the pipeline to a stable state where we can run end-to-end and judge actual output quality, rather than fixing mid-pipeline failures.

### Checklist

- [ ] **Per-table R validation** — Validate each table's R code individually before running the full script, so one bad table doesn't crash the entire run
- [ ] **Confirm output is usable** — Run pipeline, review Excel output, confirm it's meaningful enough to judge (not broken/incomplete)
- [ ] **Fix R script generation bugs** — Address any remaining issues that cause R failures (hallucinated variables, syntax errors, etc.)

---

## Part 2: Finalize Leqvio Monotherapy Demand Testing

**Status**: NOT STARTED

**Goal**: Establish a reliable baseline for our primary dataset. Iterate on prompts until output is consistent and meets quality expectations.

### Process

1. **Run baseline pipeline** — Generate fresh output with stable system from Part 1
2. **Create golden datasets** — Review and clean up raw outputs to create expected files:
   - `banner-expected.json` (from `banner/banner-output-raw.json`)
   - `crosstab-expected.json` (from `crosstab/crosstab-output-raw.json`)
   - `verification-expected.json` (from `verification/verification-output-raw.json`)
3. **Run consistency check** — Run pipeline 3x on same dataset, compare each run to golden using `npx tsx scripts/compare-to-golden.ts`
4. **Iterate** — For each difference:
   - Is this a prompt issue? → Tweak VerificationAgent prompt
   - Is this a table we don't want? → Adjust exclusion logic
   - Is this variance we need to accept? → Note as acceptable
5. **Repeat steps 3-4** until output is consistent across runs

### Exit Criteria

- [ ] Pipeline produces consistent output across 3 runs (minimal variance)
- [ ] Output quality meets expectations (tables we want, labels we like)
- [ ] Golden datasets finalized and checked in

---

## Part 3: Loop/Stacked Data + Weights

**Status**: NOT STARTED

**Goal**: Detect whether a survey has loops or weighted data, handle both correctly, and ensure outputs reflect this (weighted/unweighted base rows, proper sheet organization).

> **Confirmation needed**: How does this fit in the UI flow? Is this a pipeline-only feature or does the UI need to surface loop/weight detection for user confirmation?

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

### Output Handling

When weights are detected and applied:

1. **Two base rows** (like Joe's output):
   - Unweighted base (n)
   - Weighted base (weighted n)
2. **Sheet options**:
   - Single sheet with weighted data + both base rows, OR
   - Separate weighted/unweighted sheets (TBD based on user preference)
3. **Clear labeling**: Make it obvious which data is weighted vs unweighted

### Success Criteria

- [ ] Correctly detect looped variables in datamap (multi-layer check)
- [ ] Correctly detect if data is already stacked
- [ ] Auto-stack when needed, producing correct row counts
- [ ] Detect weight variable with robust multi-condition logic
- [ ] Apply weights correctly when present
- [ ] Output shows weighted/unweighted base rows appropriately
- [ ] Tables match expected output for Tito's dataset

---

## Part 4: Strategic Broader Testing

**Status**: NOT STARTED

**Goal**: Validate reliability across different survey types. Each dataset tests different patterns and edge cases.

### Process

Same as Part 2: Run each dataset 3x, compare runs, make small prompt tweaks as needed until output is consistent.

### Test Datasets

| # | Dataset | Why It's Useful |
|---|---------|-----------------|
| 1 | `leqvio-monotherapy-demand-NOV217` | Baseline (Part 2) |
| 2 | `titos-future-growth` | Loop/Stacked + Weights (Part 3) |
| 3 | `spravato-hcp-maxdiff` | **MaxDiff survey** — Tests handling of MaxDiff research methodology, which has unique table structures and scoring. Also has multiple scale questions per question block that may need per-answer-option tables. |
| 4 | `therasphere-demand-conjoint` | **Conjoint survey** — Another complex methodology with choice-based tasks and derived utility scores. |
| 5 | TBD | Fill based on gaps discovered in earlier testing |

### Exit Criteria

- [ ] Each dataset produces consistent output across 3 runs
- [ ] No major prompt changes needed between runs (small tweaks only)
- [ ] Output quality acceptable for report writing

---

*Created: January 6, 2026*
*Updated: January 28, 2026*
*Status: Part 1 in progress, Parts 2-4 defined*
