# Reliability Plan

## Overview

This plan tracks the work to make HawkTab AI reliably produce publication-quality crosstabs.

**Philosophy**: We're replacing Joe's usefulness, not necessarily replicating his exact format. Functional, readable crosstabs that the team can write reports from.

---

## Part 1: Stable System for Testing

**Status**: COMPLETE ✓

**Goal**: Get the pipeline to a stable state where we can run end-to-end and judge actual output quality.

**What was done**:
- Per-table R validation (one bad table doesn't crash everything)
- Fixed mean_rows NET generation (sum component means for allocation questions)
- Improved retry error messages for VerificationAgent
- Result: 147 tables, 0 R validation failures

---

## Part 2: Finalize Leqvio Monotherapy Demand Testing

**Status**: IN PROGRESS — Iteration 1 reviewed, awaiting prompt iteration

**Goal**: Confirm output quality and consistency for our primary dataset through practical testing.

### Current State

**Most recent run**: `outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-02-01T05-49-17-899Z`
- ✅ **REVIEWED** — Detailed top-to-bottom review completed (Feb 1, 2026)
- 24 feedback items captured in `feedback.md`
- See feedback file for prioritized themes and next steps

**Key findings from review**:
- BaseFilterAgent calibration is inconsistent (over/under filtering) — highest priority
- 100% NET guardrail needed (4+ instances) — simple fix, high impact
- S11 mean/median mismatch needs investigation — calculation accuracy
- Presentation polish items captured as few-shot example opportunities
- Pre/post comparison tables NOT blocking — analysts can derive themselves

**Next step**: Iterate on prompts (especially BaseFilterAgent) using feedback, then run again to validate improvements.

**Review process**:
1. Open Excel, go through tables top-to-bottom
2. Highlight context column for tables that look weird
3. Create `feedback.md` in the pipeline folder with notes (use tableId from context column for specificity)

### BaseFilterAgent Pivot (COMPLETE)

During Part 2 review, we discovered tables with incorrect bases due to skip/show logic (e.g., A3a showing one base for all therapies when each therapy should have its own base).

**What we built**: BaseFilterAgent — a new pipeline step that:
- Detects skip/show logic in the survey document
- Interprets whether logic applies at table or row level
- Splits tables when rows need different bases
- Applies additionalFilter as R constraint after banner cut
- Validates filter variables against datamap (catches hallucinations)
- Removes analytically invalid NETs when component rows have different bases

**Result**: Tables now have correct bases. A3a splits by therapy, each with accurate base (135, 126, 177). Percentages sum to 100%. Numbers match Joe's output exactly. This was a quick pivot — the system now handles complex show logic without survey-specific hacks.

### Process

1. **Run the pipeline** — Generate output with the stable system from Part 1
2. **Review the output** — Open the Excel, look at the tables. Does it have what you need? Are the labels right? Are there tables you'd remove or add?
3. **Run it again** — Second run. Compare to first. Notice any differences between runs - anything missing or inconsistent?
4. **Adjust if needed** — If there's unreliability (e.g., a table appears in one run but not another), adjust the prompt to fix it
5. **Third run** — Confirm the fix worked and output is stable
6. **Move on** — When it feels right, you're done. You're the judge.

---

## Part 3: Loop/Stacked Data + Weights

**Status**: NOT STARTED

**Goal**: Detect whether a survey has loops or weighted data, handle both correctly, and ensure outputs reflect this (weighted/unweighted base rows, proper sheet organization).

**Test Case**: `stacked-data-example/` (Tito's Future Growth)

### Testing Process

Same practical approach as Part 2:
1. Run the pipeline on Tito's dataset
2. Look at the output - does it handle the stacked data correctly? Are weights applied?
3. Run 2-3x to check consistency
4. Adjust as needed, then move on

> **Confirmation needed**: How does this fit in the UI flow? Is this a pipeline-only feature or does the UI need to surface loop/weight detection for user confirmation?

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

**Goal**: Validate reliability across different survey types. Learn what different projects throw at the system and discover failure modes.

### Process

For each dataset:
1. Run the pipeline
2. Look at the output - does it work? What's wrong?
3. Run it 2-3x if needed to check consistency
4. Note what works and what doesn't
5. Make small prompt tweaks if needed
6. Move on to the next dataset

The goal is breadth - expose the system to different patterns so we learn where it breaks. Don't get stuck perfecting one dataset.

### Test Datasets

| # | Dataset | Why It's Useful |
|---|---------|-----------------|
| 1 | `leqvio-monotherapy-demand-NOV217` | Baseline (Part 2) |
| 2 | `titos-future-growth` | Loop/Stacked + Weights (Part 3) |
| 3 | `spravato-hcp-maxdiff` | **MaxDiff survey** — Tests handling of MaxDiff research methodology, which has unique table structures and scoring. Also has multiple scale questions per question block that may need per-answer-option tables. |
| 4 | `therasphere-demand-conjoint` | **Conjoint survey** — Another complex methodology with choice-based tasks and derived utility scores. |
| 5 | `caplidar-maxdiff` | **Second MaxDiff** — HawkPartners does a lot of MaxDiff work, so testing another one is important. |
| 6 | TBD | Fill based on gaps discovered in earlier testing (e.g., surveys with strikethrough question numbers, blank questions, draft-like features) |

### Note: Upfront Context Capture

As we test broader datasets, we'll likely discover that we need more information upfront. Currently the system just accepts file uploads and treats everything the same - but different project types need different context.

**Examples of missing context:**
- **Project type** — Is this MaxDiff? ATU? Conjoint? Knowing this changes what we expect.
- **MaxDiff messages** — The datamap often just says "Message 1, Message 2" but the VerificationAgent needs the actual message text to make useful tables. Either the user provides a message list, or we need a way to link to it.
- **Research objective** — What is this study trying to answer? Helps prioritize which tables matter.
- **Stacked/looped data** — User confirmation (addressed in Part 3)

**Higher-level question:** What information are we NOT capturing that's necessary for reliability? This will become clearer as we test different project types. The UI may need to ask qualifying questions based on what the user uploads.

### Exit Criteria

- [ ] Each dataset produces consistent output across 3 runs
- [ ] No major prompt changes needed between runs (small tweaks only)
- [ ] Output quality acceptable for report writing

---

*Created: January 6, 2026*
*Updated: February 1, 2026*
*Status: Part 1 complete, Part 2 iteration 1 reviewed — 24 feedback items captured, awaiting prompt iteration*
