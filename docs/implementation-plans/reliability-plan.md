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

**Status**: COMPLETE

**Goal**: Validate data inputs before they reach the pipeline. Catch problems early (wrong format, mismatched files, already-stacked data) and provide clear user guidance.

**Test Case**: `data/test-data/titos-growth-strategy/` (Tito's Future Growth)

### Key Design Decisions

1. **Wide format only** — We don't process already-stacked data. If we detect stacking, we ask users for the original wide format.
2. **SPSS Variable Info parser** — Build parser for the 81% of datamaps in SPSS format. Unlocks broader testing.
3. **Gemini's diversity approach for loop detection** — More robust than regex patterns. Uses tokenization and "internal diversity" to distinguish loops from grids.
4. **Fill-rate validation** — A useful signal, but not a perfect test. If `_2` columns are *near-empty* while `_1` has substantial data, the data may be already stacked — but some true-wide “up to N” loops also have legitimately low `_2` fill. Treat this as a warning + cross-check, not a single definitive rule.
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
| 85% | <1% | **High suspicion** already stacked → Ask for wide (but confirm via additional signals) |
| Varies | N/A | No loop / uncertain → Confirm |

**Note:** low later-iteration fill can be real (expected dropout), not necessarily “already stacked”. Prefer checking the pattern across many loop variables (most bases should show a similar drop pattern if it’s real) and/or ask the user to confirm.

### Success Criteria

- [x] Correctly detect loop patterns using diversity approach
- [x] Correctly identify already-stacked data via fill rates
- [x] Block with clear message when data appears stacked
- [x] Handle both Antares and SPSS Variable Info datamap formats
- [x] Cross-validate datamap ↔ data with >50% threshold
- [x] User-facing messages are clear and actionable
- [x] Stack looped data from wide format for pipeline consumption

---

## Part 4: Strategic Broader Testing

**Status**: IN PROGRESS

**Goal**: Validate reliability across different survey types. Learn what different projects throw at the system and discover failure modes. Breadth over depth — expose the system to many datasets rather than perfecting any one.

### Why Now

Parts 1-3 established a solid foundation: stable pipeline, validated primary dataset, loop/stacked data support. Continued focus on Leqvio and Tito's risks overfitting. By running batch tests across 11+ datasets, we discover where failures accrue across project types and can make high-leverage fixes that improve the system broadly.

Additionally, the UI (when built) will surface agent uncertainty and low-confidence alternatives via HITL review. Many issues that look like "failures" in CLI output are actually resolvable in the UI — the agent surfaces alternatives, and a reviewer selects the right one. Part 4 testing also validates this: are the alternatives being surfaced? Would a reviewer be able to correct the issue?

### Process

1. **Batch run** — Run all ready datasets through the pipeline via `scripts/batch-pipeline.ts`
2. **Consolidate feedback** — Review each dataset's output, note issues with tableIds and `lastModifiedBy`
3. **Identify patterns** — Look for systemic issues across datasets (not one-off quirks)
4. **Tweak at the highest level** — Make prompt or logic changes that address the broadest class of failures
5. **Repeat** — Run the batch again, measure improvement

The batch runner produces `outputs/batch-summary-<timestamp>.json` with cross-dataset analytics (cost, time, tables, R validation rates, agent breakdown) to track progress across iterations.

### Test Datasets

| # | Dataset | Type | Status |
|---|---------|------|--------|
| 1 | `leqvio-monotherapy-demand-NOV217` | HCP Demand (pharma) | Baseline (Part 2) |
| 2 | `titos-growth-strategy` | Consumer/Beverage (loops + weights) | Loop testing (Part 3) |
| 3 | `Spravato_4.23.25` | HCP Segmentation (pharma) | Ready |
| 4 | `CART-Segmentation-Data_7.22.24_v2` | HCP Segmentation (pharma) | Ready |
| 5 | `Iptacopan-Data_2.23.24` | HCP Access Perceptions (pharma) | Ready |
| 6 | `Leqvio-Segmentation-Data-HCP-W1_7.11.23` | HCP Segmentation (pharma) | Ready |
| 7 | `UCB-Caregiver-ATU-W1-Data_1.11.23` | Caregiver ATU (rare disease) | Ready |
| 8 | `UCB-Caregiver-ATU-W2-Data_9.1.23` | Caregiver ATU wave 2 | Ready |
| 9 | `UCB-W3` | Caregiver ATU wave 3 | Ready |
| 10 | `UCB-Caregiver-ATU-W4-Data_8.16.24` | Caregiver ATU wave 4 | Ready |
| 11 | `UCB-Caregiver-ATU-W5-Data_1.7.25` | Caregiver ATU wave 5 | Ready |

**Not ready** (missing banner or survey): `GVHD-Data`, `Leqvio-Demand-W1`, `Leqvio-Demand-W2`, `Leqvio-Segmentation-Patients-Data`

**Coverage gaps**: No MaxDiff dataset yet. Good range of HCP segmentation, ATU (5 waves), demand, access perceptions, and consumer/beverage with loops.

### Exit Criteria

- [ ] Each dataset produces consistent output across 3 runs
- [ ] No major prompt changes needed between runs (small tweaks only)
- [ ] Output quality acceptable for report writing
- [ ] Batch summary shows stable cost/time/quality metrics across iterations

---

> **Note**: Weight Detection and Survey Classification & Confidence Scoring were previously Parts 5 and 6 of this plan. They have been moved to the [Product Roadmap](./product-roadmap.md) as feature completeness items (2.6 and 2.7) since they are enhancements that build on the core reliability foundation, not part of the testing process itself.

*Created: January 6, 2026*
*Updated: February 8, 2026*
*Status: Parts 1-3 complete, Part 4 in progress*
