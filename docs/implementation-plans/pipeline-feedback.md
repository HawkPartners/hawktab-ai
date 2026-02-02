# Pipeline Feedback Log

This document captures issues discovered during pipeline runs that we're deferring to address later. We're moving on to test with different projects to validate the system more broadly, but we don't want to lose track of these specific issues.

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

## Issue 2: [Placeholder for additional issues]

*Add additional issues as discovered during review.*

---

## Notes

- These issues represent edge cases that require either prompt tuning or architectural changes
- The core pipeline is working well enough to test with other datasets
- We'll return to address these systematically after broader validation
