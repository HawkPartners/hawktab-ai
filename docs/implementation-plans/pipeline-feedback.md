# Pipeline Feedback Log

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