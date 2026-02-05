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

**Status**: COMPLETE ✓

**Goal**: Confirm output quality and consistency for our primary dataset through practical testing.

**What was done**:
- Multiple pipeline runs with top-to-bottom review against Joe's reference output
- Built BaseFilterAgent to handle skip/show logic and table splitting
- Fixed R script generation issues (NULL→NA serialization, category headers, stat testing)
- Fixed Excel formatter issues (base row display for category headers)

**Result**: Pipeline produces usable crosstabs. Most tables match Joe's output. Three edge-case issues documented for future refinement.

**Outstanding Issues**: See [Pipeline Feedback Log](./pipeline-feedback.md) for 3 documented issues:
1. Multi-column grid filters (A4a tables) — BaseFilterAgent
2. Unnecessary derived table with base=0 (a5_12m) — BaseFilterAgent
3. Ranking question base calculation (A6 tables) — R Script Generator

**Decision**: Moving forward to Parts 3-4 to validate system robustness across different datasets. The issues above are edge cases related to complex question types (multi-column grids, ranking questions) and do not block broader testing.

---

## Part 3: Loop Detection & Data Validation

**Status**: NOT STARTED

**Goal**: Validate data inputs before they reach the pipeline. Catch problems early (wrong format, mismatched files, already-stacked data) and provide clear user guidance.

**Test Case**: `data/titos-future-growth/` (Tito's Future Growth)
**Detailed Plan**: See [Loop Detection & Data Validation](./loop-detection-and-validation.md) for full implementation plan.

### Key Design Decisions

1. **Wide format only** — We don't process already-stacked data. If we detect stacking, we ask users for the original wide format.
2. **SPSS Variable Info parser** — Build parser for the 81% of datamaps in SPSS format. Unlocks broader testing.
3. **Gemini's diversity approach for loop detection** — More robust than regex patterns. Uses tokenization and "internal diversity" to distinguish loops from grids.
4. **Fill-rate validation** — Confirms data matches format. If `_2` columns are empty but `_1` has data, the data is likely already stacked.
5. **R + Haven for all data reading** — Consistency with pipeline. No JavaScript SPSS readers.
6. **Weights deferred** — Weight detection is out of scope. Moved to Part 5.

### Validation Stages

| Stage | What It Checks | Action on Failure |
|-------|----------------|-------------------|
| 1. File | Files exist, parseable, format detected | Block |
| 2. DataMap | Variables extracted, survey vars identified | Block |
| 3. Data File | Has rows/columns, stacking columns present? | Block/Warn |
| 4. Cross-Validation | DataMap ↔ Data match (>50% required) | Block |
| 5. Loop | Loop detection + fill-rate validation | Warn (ask for wide) |

### Loop Detection Algorithm

The key insight: **a loop has many distinct question roots sharing an iterator, while a grid has one root with multiple indices.**

```
Loop:  A1_1, A2_1, A3_1  →  Diversity = 3 (3 bases share _1)  ✓
Grid:  A22r1, A22r2, A22r3  →  Diversity = 1 (only A22)  ✗
```

Algorithm:
1. Tokenize variable names → `A4_1` becomes `['A', '4', '_', '1']`
2. Create skeletons → `A-N-_-N`
3. Group variables by skeleton
4. Calculate diversity at each numeric position
5. Iterator position = highest diversity per iteration value

### Fill-Rate Validation

After detecting loop patterns, validate data format:

| `_1` Fill Rate | `_2` Fill Rate | Interpretation |
|----------------|----------------|----------------|
| 85% | 60% | Valid wide format → Proceed |
| 85% | <1% | Already stacked → Ask for wide |
| Varies | N/A | No loop / uncertain → Confirm |

### Success Criteria

- [ ] Correctly detect loop patterns using diversity approach
- [ ] Correctly identify already-stacked data via fill rates
- [ ] Block with clear message when data appears stacked
- [ ] Handle both Antares and SPSS Variable Info datamap formats
- [ ] Cross-validate datamap ↔ data with >50% threshold
- [ ] User-facing messages are clear and actionable

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

## Part 5: Weight Detection

**Status**: NOT STARTED

**Goal**: Detect weight variables in data files and apply them to crosstab calculations.

**Prerequisites**: Parts 3-4 complete. The validation and broader testing infrastructure should be stable before adding weight complexity.

### Why Deferred

Weight detection adds complexity:
1. Heuristic detection (column names like `weight`, `wt`, `wgt`)
2. User confirmation (is this really a weight?)
3. R script changes for weighted calculations
4. Excel output changes (weighted/unweighted base rows)

We want the core validation system tested before layering this on.

### Planned Approach

**Detection**: Look for common weight column names in data file.

**User Confirmation**:
```
We found a possible weight variable: "wt"
Apply weights to calculations?

[Yes, apply weights]  [No, unweighted]  [That's not a weight]
```

**Output**:
- Two base rows: Unweighted base (n), Weighted base (weighted n)
- All percentages/means calculated with weights

### Success Criteria

- [ ] Detect weight variable with robust multi-condition logic
- [ ] User confirmation before applying
- [ ] Apply weights correctly in R calculations
- [ ] Output shows both weighted/unweighted base rows

---

## Part 6: Survey Classification & Confidence Scoring

**Status**: NOT STARTED

**Goal**: Automatically detect survey methodology type from datamap patterns, and provide multi-dimensional confidence scores to surface when human review is needed.

**Prerequisites**: Parts 3-5 complete. This is enhancement-level work once the core system is reliable.

### Survey Classification

Different research methodologies need different handling. If we can detect the type, we can:
1. Set user expectations ("This looks like a MaxDiff survey...")
2. Prompt for missing context (MaxDiff needs actual message text, not just "Message 1")
3. Pre-configure agent behavior
4. Flag when we're out of our depth

| Type | Detection Signals | Why It Matters |
|------|-------------------|----------------|
| **MaxDiff** | Variables named `MD*`, `maxdiff*`; "best/worst" or "most/least appealing" in descriptions | Needs message text; has utility scores |
| **Conjoint/DCM** | Variables named `DCM*`, `conjoint*`, `choice*`; utility score patterns | Has choice tasks and derived utilities |
| **ATU** | "awareness" + "trial/usage" patterns; "ever heard/used" | Standard table structures expected |
| **Message Testing** | "message N" patterns; "appeal" + "message" | Needs actual message content |
| **Segmentation** | "segment" or "cluster" in variables | May have derived segment assignments |
| **Standard** | None of the above | Default handling |

### Multi-Dimensional Confidence Scoring

Instead of a single confidence score, track confidence across dimensions:

| Dimension | What It Measures | When Low Score Matters |
|-----------|------------------|------------------------|
| **Structure** | Did we parse brackets/values/options correctly? | Parser may have failed |
| **Parent-Child** | Are relationships between variables clear? | Context enrichment issues |
| **Variable Types** | Did we identify types correctly? | Wrong table treatment |
| **Loop Detection** | If loops detected, how certain? | May ask for wrong format |
| **Survey Classification** | How confident in methodology type? | May miss required context |

### Flagging Thresholds

```
If overall confidence < 70%:
  → Flag for human review before proceeding
  → "We're not confident we parsed this correctly. Please review."

If loop confidence < 80% AND loops detected:
  → Ask user to confirm loop detection
  → "We think this has looped questions. Is that right?"

If survey type confidence < 60%:
  → Don't auto-configure, ask user
  → "What type of research is this? MaxDiff / Conjoint / Standard / Other"
```

### Implementation Notes

This is UI-level work. The pipeline produces confidence scores; the UI decides what to surface. The validation layer (Part 3) provides the foundation—this part adds intelligence on top.

### Success Criteria

- [ ] Detect MaxDiff surveys with >80% accuracy
- [ ] Detect Conjoint surveys with >80% accuracy
- [ ] Multi-dimensional confidence scores available
- [ ] UI prompts when confidence is low
- [ ] Survey type influences agent behavior or user prompts

---

*Created: January 6, 2026*
*Updated: February 5, 2026*
*Status: Parts 1-2 complete, Part 3 design complete, ready for implementation*
