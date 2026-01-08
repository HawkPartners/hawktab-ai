# Significance Testing Implementation Plan

**Status**: Ready for Implementation
**Created**: 2026-01-07
**Last Updated**: 2026-01-08
**Priority**: High - Required for Part 3 of Reliability Plan

---

## Summary

Two changes needed to match WinCross defaults:

1. **Switch from pooled to unpooled z-test formula**
2. **Remove the n<5 minimum sample size block**

That's it. No configuration schemas, no optional rigor features, no verification phase.

---

## Context from Joe

Joe confirmed HawkPartners' significance testing practices (January 2026):

> "Almost all HawkPartners studies are done at a 90% confidence level -- that is the default."

> "There is no minimum base for stat-testing as many of the HCP studies have only a hundred or so respondents so some of the subgroups get into the single digits. So stat-testing is done on all data cuts, even those with <10."

> "The tabulation software determines the appropriate method of stat-testing -- including overlap handling, etc. As I'm not a statistician to determine the correct stat-test, I appreciate this feature of the tabulation software."

**Key insight**: Joe uses WinCross defaults. WinCross does NOT auto-select test methods based on data - the user selects the test type, and the default is **unpooled independent z-test**. Per WinCross documentation:

- Default: "Independent (using unpooled proportions)"
- Alternative: "Independent (using pooled proportions)" - user-selected
- No minimum sample size enforced

Source: [WinCross Independent Z-Tests](http://analyticalgroup.com/WinCrossHelp16/wincross_help/z-test_for_percents.htm)

---

## Current State

**File**: `src/lib/r/RScriptGeneratorV2.ts`

### Z-Test Function (Lines 312-333)

```r
sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {
  if (n1 < 5 || n2 < 5) return(NA)  # ❌ REMOVE THIS

  # Pooled proportion  ❌ CHANGE TO UNPOOLED
  p_pool <- (count1 + count2) / (n1 + n2)
  if (p_pool == 0 || p_pool == 1) return(NA)

  # Standard error (pooled formula)  ❌ CHANGE TO UNPOOLED
  se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
  if (se == 0) return(NA)

  # Z statistic
  p1 <- count1 / n1
  p2 <- count2 / n2
  z <- (p1 - p2) / se

  # Two-tailed p-value  ✅ CORRECT
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2))
}
```

---

## Implementation

### Change 1: Unpooled Z-Test Formula

**Current (pooled)**:
```r
p_pool <- (count1 + count2) / (n1 + n2)
se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
```

**New (unpooled)**:
```r
p1 <- count1 / n1
p2 <- count2 / n2
se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
```

The unpooled formula calculates standard error using each sample's own proportion rather than a combined pooled estimate. This is more conservative (wider SE) and is the industry standard for survey crosstabs.

### Change 2: Remove Minimum Sample Size

**Delete this line**:
```r
if (n1 < 5 || n2 < 5) return(NA)
```

WinCross tests everything regardless of sample size. Joe confirmed this is correct for HawkPartners studies where HCP subgroups can have single-digit respondents.

### Updated Function

```r
sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {
  # Calculate proportions
  p1 <- count1 / n1
  p2 <- count2 / n2

  # Edge case: can't test if either proportion is undefined
  if (is.na(p1) || is.na(p2)) return(NA)

  # Edge case: can't test if both are 0% or both are 100%
  if ((p1 == 0 && p2 == 0) || (p1 == 1 && p2 == 1)) return(NA)

  # Standard error (unpooled formula - WinCross default)
  se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
  if (is.na(se) || se == 0) return(NA)

  # Z statistic
  z <- (p1 - p2) / se

  # Two-tailed p-value
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2))
}
```

---

## Significance Display Behavior

**Current behavior (correct, no change needed)**:

Significance letters appear under data points that are **higher** than the compared column. The logic at line 628:

```r
if (is.list(result) && !is.na(result$significant) && result$significant && result$higher) {
  sig_higher <- c(sig_higher, cut_stat_letters[[other_cut]])
}
```

Example: If column A (PCPs) shows 45% and column B (Cardiologists) shows 32%, and the difference is significant at 90%, then column A displays "B" beneath the 45% to indicate "this value is significantly higher than column B."

---

## What We're NOT Changing

| Item | Reason |
|------|--------|
| Confidence level (90%) | Already correct - matches HawkPartners default |
| Two-tailed test | Already correct - matches WinCross |
| Within-group comparisons | Already implemented |
| T-test for means | Current Welch's t-test approximation is acceptable |
| Bonferroni/FDR correction | Not used by WinCross by default, not needed |
| Configurable test methods | Over-engineering - Joe uses defaults |
| Overlap/dependent tests | Only needed for multi-select banners (future scope) |

---

## Validation

After implementing the changes:

1. Run `npx tsx scripts/test-pipeline.ts` on practice-files
2. Compare significance letters in `results/crosstabs.xlsx` to Joe's tabs
3. If letters match, we're done

No automated verification framework needed - manual comparison is sufficient for this scope.

---

## Files to Modify

| File | Change |
|------|--------|
| `src/lib/r/RScriptGeneratorV2.ts` | Update `sig_test_proportion` function (lines 312-333) |

---

## Formula Reference

### Unpooled Two-Proportion Z-Test

**Test statistic**:
```
z = (p₁ - p₂) / SE

SE = sqrt(p₁(1-p₁)/n₁ + p₂(1-p₂)/n₂)
```

**P-value**: `2 × (1 - Φ(|z|))` where Φ is the standard normal CDF

**Decision**: Significant if p-value < 0.10 (90% confidence)

### Why Unpooled?

- **Pooled**: Assumes null hypothesis (p₁ = p₂) is true when calculating SE. Better for hypothesis testing.
- **Unpooled**: Uses each sample's observed proportion. More conservative, standard for survey research.

WinCross defaults to unpooled because survey crosstabs are typically exploratory (comparing observed differences) rather than testing a specific null hypothesis.

---

*This plan is intentionally simple. The goal is to match Joe's WinCross output, nothing more.*
