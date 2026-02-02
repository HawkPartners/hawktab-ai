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
