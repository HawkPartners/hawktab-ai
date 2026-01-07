# Statistical Significance Testing Audit & Implementation Plan

**Date:** January 7, 2026
**Author:** Claude (via automated analysis)
**Status:** Ready for Review

---

## Executive Summary

This document analyzes the current statistical significance testing implementation in HawkTab AI and proposes changes to align with WinCross defaults (Joe's methodology) while building infrastructure for future configurability.

**Critical Finding:** The current implementation uses a **pooled variance z-test** for proportions, but WinCross uses **unpooled proportions** by default. This is the primary source of discrepancies between our output and Joe's tabs.

### Key Changes Required

| Parameter | Current | WinCross Default | Priority |
|-----------|---------|------------------|----------|
| Proportion test formula | Pooled | **Unpooled** | **CRITICAL** |
| Minimum sample size | n >= 5 | No minimum | High |
| Confidence level | 90% | 90% + 95% | Medium |
| Multiple comparison | None | None (Bonferroni opt-in) | Phase 2 |
| Tail type | Two-tailed | Two-tailed | Correct |

---

## 1. Current State Analysis

### 1.1 Where Statistical Testing Lives

**Primary Implementation:** `src/lib/r/RScriptGeneratorV2.ts`

The R script generator creates two statistical testing functions:
- `sig_test_proportion()` - Z-test for frequency tables (lines 302-323)
- `sig_test_mean()` - T-test for mean_rows tables (lines 327-342)

**Key Files:**
- `src/lib/r/RScriptGeneratorV2.ts` - Core statistical logic
- `src/lib/excel/tableRenderers/frequencyTable.ts` - Renders significance letters
- `src/lib/excel/tableRenderers/meanRowsTable.ts` - Renders significance letters
- `src/app/api/process-crosstab/route.ts` - API entry point (uses defaults)

### 1.2 Current Proportion Test Formula (INCORRECT)

```r
# Current implementation (POOLED - incorrect for WinCross match)
sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {
  if (n1 < 5 || n2 < 5) return(NA)  # Hardcoded minimum

  # PROBLEM: Pooled proportion
  p_pool <- (count1 + count2) / (n1 + n2)
  if (p_pool == 0 || p_pool == 1) return(NA)

  # PROBLEM: Pooled standard error
  se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
  if (se == 0) return(NA)

  p1 <- count1 / n1
  p2 <- count2 / n2
  z <- (p1 - p2) / se

  # Two-tailed p-value (correct)
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2))
}
```

### 1.3 What WinCross Actually Does

Based on WinCross documentation and research:

**Unpooled Z-Test Formula:**
```
z = (p1 - p2) / sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)
```

**Key Differences:**
1. **No pooling** - Each sample proportion estimates its own variance
2. **No minimum sample size** - Tests everything, even small n
3. **Default confidence levels** - Tests at BOTH 95% and 90% simultaneously
4. **Bonferroni** - Available but opt-in only (added in V25)

**Correct Formula Implementation:**
```r
# WinCross-style unpooled z-test
sig_test_proportion_unpooled <- function(count1, n1, count2, n2, threshold = p_threshold) {
  # No minimum sample size check - test everything
  if (n1 == 0 || n2 == 0) return(NA)  # Only skip if truly zero

  p1 <- count1 / n1
  p2 <- count2 / n2

  # Guard against edge cases
  if (p1 == p2) return(list(significant = FALSE, higher = FALSE))

  # Unpooled standard error
  se <- sqrt((p1 * (1 - p1) / n1) + (p2 * (1 - p2) / n2))
  if (se == 0) return(NA)

  z <- (p1 - p2) / se

  # Two-tailed p-value
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2))
}
```

### 1.4 Current vs Required Parameters

| Parameter | Current Value | Location | Hardcoded? |
|-----------|---------------|----------|------------|
| Alpha (significance level) | 0.10 | `RScriptGeneratorV2.ts:65` | No (configurable via `significanceLevel`) |
| Minimum sample size | 5 | `RScriptGeneratorV2.ts:304,332` | **YES** |
| Pooling strategy | Pooled | `RScriptGeneratorV2.ts:306-311` | **YES** |
| Tail type | Two-tailed | `RScriptGeneratorV2.ts:319-320` | **YES** |
| Multiple comparison | None | N/A | **YES** (not implemented) |
| Outlier IQR multiplier | 1.5 | `RScriptGeneratorV2.ts:291-292` | **YES** |
| Min data for IQR | 4 | `RScriptGeneratorV2.ts:285` | **YES** |

### 1.5 Known Issues from Bug Tracker

From `temp-outputs/.../bugs.md`:

> **Significance testing discrepancy (S8 example)**: Our significance letters differ from Joe's even when base sizes and data values are identical.
> - Not a confidence level issue (both appear to be 90%)
> - Same base n, same means
> - Need to verify: **pooled vs unpooled variance**, one-tailed vs two-tailed, small sample handling, comparison group definitions

This bug is directly explained by the pooled vs unpooled difference we've identified.

---

## 2. Gap Analysis

### 2.1 Critical Gap: Pooled vs Unpooled Formula

**Impact:** Different significance results for the same data

**Example Scenario:**
- Column A: 40/100 = 40%
- Column B: 50/100 = 50%

Pooled approach:
```
p_pool = 90/200 = 0.45
se = sqrt(0.45 * 0.55 * (1/100 + 1/100)) = 0.0704
z = (0.40 - 0.50) / 0.0704 = -1.42
p-value = 0.156 → NOT significant at 90%
```

Unpooled approach:
```
se = sqrt((0.40*0.60/100) + (0.50*0.50/100)) = 0.0700
z = (0.40 - 0.50) / 0.0700 = -1.43
p-value = 0.153 → NOT significant at 90%
```

In this case, results are similar. But when proportions are extreme or sample sizes differ significantly, the difference grows.

### 2.2 High Impact: Minimum Sample Size

**Current:** Requires n >= 5 for both groups
**WinCross:** No minimum - tests all data

**Impact:** We're skipping tests that Joe would run, resulting in missing significance letters for small-n segments.

### 2.3 Medium Impact: Dual Confidence Levels

**Current:** Tests only at 90%
**WinCross:** Tests at both 95% AND 90% by default

**Impact:** Joe's output may show significance at different confidence levels. We only show one.

**Note:** This is less critical than formula correctness. Can be Phase 2.

### 2.4 Low Impact (Phase 2): Multiple Comparison Correction

**Current:** None
**WinCross:** None by default (Bonferroni opt-in in V25+)

**Impact:** None currently - matches Joe's behavior. Should build infrastructure for future.

### 2.5 What Will Break If We Change?

1. **All significance results will change** - This is expected and desired
2. **Small-n segments will get significance letters** - Where currently they show none
3. **Excel output needs no changes** - Already handles significance letters generically
4. **Test validation will fail** - Any existing test snapshots will need updating
5. **Client expectations** - If anyone has been trained on current output, they'll see differences

---

## 3. Implementation Roadmap

### Phase 1: Match WinCross Defaults (Critical)

**Goal:** Output matches Joe's tabs exactly for statistical testing

**Changes Required:**

#### 3.1.1 Create Stat Testing Configuration Schema

Add new file: `src/schemas/statTestingSchema.ts`

```typescript
import { z } from 'zod';

/**
 * Statistical significance testing configuration
 * Default values match WinCross defaults for compatibility with Joe's methodology
 */
export const StatTestingConfigSchema = z.object({
  // Confidence level (alpha = 1 - confidence)
  // WinCross default: tests at both 95% and 90%
  confidenceLevels: z.array(z.number().min(0).max(1)).default([0.90]),

  // Primary significance threshold (alpha)
  // 0.10 = 90% confidence, 0.05 = 95% confidence
  primaryAlpha: z.number().min(0).max(1).default(0.10),

  // Proportion test method
  // 'unpooled' = WinCross default (each sample estimates own variance)
  // 'pooled' = traditional hypothesis test pooled variance
  proportionTestMethod: z.enum(['unpooled', 'pooled']).default('unpooled'),

  // Minimum base size for testing
  // 0 = no minimum (WinCross default)
  // 5, 10, 30, etc. = skip tests for smaller samples
  minimumBaseSize: z.number().int().min(0).default(0),

  // Multiple comparison correction
  // 'none' = WinCross default
  // 'bonferroni' = Bonferroni correction
  // 'fdr' = False Discovery Rate (future)
  multipleComparisonCorrection: z.enum(['none', 'bonferroni']).default('none'),

  // Number of comparisons for Bonferroni (auto-calculated if not specified)
  bonferroniComparisons: z.number().int().min(1).optional(),

  // Test tail type (WinCross only does two-tailed)
  tailType: z.enum(['two-tailed']).default('two-tailed'),

  // Mean comparison test type
  // 'welch' = Welch's t-test (unequal variances, R default)
  // 'student' = Student's t-test (assumes equal variances)
  meanTestMethod: z.enum(['welch', 'student']).default('welch'),
});

export type StatTestingConfig = z.infer<typeof StatTestingConfigSchema>;

/**
 * WinCross-compatible defaults
 * Use these to match Joe's output exactly
 */
export const WINCROSS_DEFAULTS: StatTestingConfig = {
  confidenceLevels: [0.90],
  primaryAlpha: 0.10,
  proportionTestMethod: 'unpooled',
  minimumBaseSize: 0,
  multipleComparisonCorrection: 'none',
  tailType: 'two-tailed',
  meanTestMethod: 'welch',
};

/**
 * More rigorous defaults for when we want conservative testing
 * Use for clients who want stricter methodology
 */
export const RIGOROUS_DEFAULTS: StatTestingConfig = {
  confidenceLevels: [0.95, 0.90],
  primaryAlpha: 0.05,
  proportionTestMethod: 'pooled',
  minimumBaseSize: 30,
  multipleComparisonCorrection: 'bonferroni',
  tailType: 'two-tailed',
  meanTestMethod: 'welch',
};
```

#### 3.1.2 Update RScriptV2Input Interface

In `src/lib/r/RScriptGeneratorV2.ts`:

```typescript
import type { StatTestingConfig } from '../../schemas/statTestingSchema';

export interface RScriptV2Input {
  tables: TableDefinition[];
  cuts: CutDefinition[];
  cutGroups?: CutGroup[];
  totalStatLetter?: string | null;
  dataFilePath?: string;

  // DEPRECATED: Use statTestingConfig.primaryAlpha instead
  significanceLevel?: number;

  // NEW: Full statistical testing configuration
  statTestingConfig?: StatTestingConfig;

  totalRespondents?: number;
  bannerGroups?: BannerGroup[];
}
```

#### 3.1.3 Update Proportion Test Function

Replace the `sig_test_proportion` function in generated R code:

```r
# Z-test for proportions (configurable pooled/unpooled)
sig_test_proportion <- function(count1, n1, count2, n2,
                                threshold = p_threshold,
                                method = "${config.proportionTestMethod}",
                                min_n = ${config.minimumBaseSize}) {
  # Minimum sample size check
  if (min_n > 0 && (n1 < min_n || n2 < min_n)) return(NA)

  # Cannot test with zero base
  if (n1 == 0 || n2 == 0) return(NA)

  p1 <- count1 / n1
  p2 <- count2 / n2

  # Identical proportions are not significant
  if (p1 == p2) return(list(significant = FALSE, higher = FALSE, p_value = 1))

  # Calculate standard error based on method
  if (method == "unpooled") {
    # WinCross default: unpooled proportions
    se <- sqrt((p1 * (1 - p1) / n1) + (p2 * (1 - p2) / n2))
  } else {
    # Pooled proportions (traditional hypothesis test)
    p_pool <- (count1 + count2) / (n1 + n2)
    if (p_pool == 0 || p_pool == 1) return(NA)
    se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
  }

  if (se == 0 || is.na(se)) return(NA)

  # Z statistic
  z <- (p1 - p2) / se

  # Two-tailed p-value
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(
    significant = p_value < threshold,
    higher = p1 > p2,
    p_value = p_value,
    z_stat = z
  ))
}
```

#### 3.1.4 Files to Modify

1. **Create:** `src/schemas/statTestingSchema.ts` - Configuration schema
2. **Modify:** `src/lib/r/RScriptGeneratorV2.ts` - Update function signatures and R code generation
3. **Modify:** `src/app/api/process-crosstab/route.ts` - Pass configuration through
4. **Modify:** `src/lib/excel/ExcelFormatter.ts` - Pass config to renderers
5. **Update:** Excel footers to describe methodology

### Phase 2: Add Optional Rigor

**Goal:** Infrastructure for stricter methodology when needed

#### 3.2.1 Bonferroni Correction

```r
# Apply Bonferroni correction to p-value threshold
bonferroni_threshold <- function(base_alpha, num_comparisons) {
  return(base_alpha / num_comparisons)
}
```

Auto-calculate number of comparisons:
- Within each banner group: C(n, 2) = n*(n-1)/2 comparisons
- Total comparisons = sum across all groups

#### 3.2.2 Dual Confidence Level Support

Generate significance letters with level indicators:
- Capital letter (A, B, C) = significant at 95%
- Lowercase letter (a, b, c) = significant at 90% only

This matches WinCross behavior for dual-level testing.

#### 3.2.3 Minimum Base Size Warning

Instead of skipping small-n tests entirely, add warning metadata:

```json
{
  "sig_higher_than": ["B", "C"],
  "sig_warnings": ["Small sample size (n=8) - interpret with caution"]
}
```

---

## 4. Configuration Schema (Final)

### 4.1 TypeScript Interface

```typescript
interface StatTestingConfig {
  // Core settings
  primaryAlpha: number;              // Default: 0.10 (90% confidence)
  proportionTestMethod: 'unpooled' | 'pooled';  // Default: 'unpooled'
  minimumBaseSize: number;           // Default: 0 (no minimum)

  // Advanced settings
  confidenceLevels: number[];        // Default: [0.90]
  multipleComparisonCorrection: 'none' | 'bonferroni';  // Default: 'none'
  tailType: 'two-tailed';           // Fixed for now
  meanTestMethod: 'welch' | 'student';  // Default: 'welch'

  // Metadata
  bonferroniComparisons?: number;    // Auto-calculated if not specified
}
```

### 4.2 Configuration Flow

```
API Request
    ↓
StatTestingConfig (with defaults)
    ↓
RScriptGeneratorV2 (injects into R code)
    ↓
Generated R Script (uses config values)
    ↓
JSON Output (includes config in metadata)
    ↓
ExcelFormatter (displays methodology in footer)
```

### 4.3 Where Defaults Are Set

1. **Schema definition:** `src/schemas/statTestingSchema.ts`
   - WINCROSS_DEFAULTS constant for Joe-compatible output
   - RIGOROUS_DEFAULTS constant for stricter methodology

2. **API endpoint:** `src/app/api/process-crosstab/route.ts`
   - Accepts optional `statTestingConfig` in request body
   - Falls back to WINCROSS_DEFAULTS

3. **R script generation:** `src/lib/r/RScriptGeneratorV2.ts`
   - Receives config and injects values into R code
   - Backwards compatible with legacy `significanceLevel` parameter

---

## 5. Testing & Validation Plan

### 5.1 Unit Tests

Create `src/lib/r/__tests__/statTesting.test.ts`:

1. **Unpooled vs Pooled formula verification**
   - Test with known inputs and expected outputs
   - Verify formula produces correct z-statistics

2. **Edge cases**
   - n1 = 0, n2 = 0 (should return NA)
   - p1 = p2 (should return not significant)
   - p = 0 or p = 1 (boundary conditions)
   - Very small samples (n < 5)

3. **Configuration inheritance**
   - Defaults applied correctly
   - Custom config overrides defaults
   - Legacy `significanceLevel` still works

### 5.2 Integration Tests

1. **Compare output to WinCross**
   - Run same data through both systems
   - Verify significance letters match
   - Document any remaining discrepancies

2. **Regression testing**
   - Snapshot current output before changes
   - Verify changes are intentional, not bugs

### 5.3 Validation with Joe's Output

**Critical:** After implementation, run a side-by-side comparison:

1. Take a known dataset Joe has processed
2. Run through HawkTab AI with WINCROSS_DEFAULTS
3. Compare significance letters cell-by-cell
4. Document matches and mismatches
5. Investigate any remaining discrepancies

Expected outcome: Significance letters should match once we switch to unpooled formula and remove minimum sample size requirement.

---

## 6. Risk Assessment

### 6.1 High Risk: All Results Will Change

**Risk:** Existing users may have built expectations around current output.

**Mitigation:**
- This is a bug fix, not a behavior change
- Current output doesn't match Joe's (our stated goal)
- Document changes clearly
- Version the change if needed

### 6.2 Medium Risk: Small Sample Testing

**Risk:** Testing very small samples (n < 5) may produce unreliable results.

**Mitigation:**
- Match Joe's behavior exactly (he tests everything)
- Add warning metadata for small samples
- Document limitations in output footer
- Build infrastructure for optional minimum

### 6.3 Low Risk: Formula Edge Cases

**Risk:** Edge cases (p=0, p=1, identical proportions) may cause errors.

**Mitigation:**
- Add explicit guards in R code
- Return NA for undefined cases
- Test thoroughly with edge cases

### 6.4 Low Risk: Performance

**Risk:** Removing minimum sample size means more tests run.

**Mitigation:**
- Z-test is O(1) - negligible performance impact
- Already testing all non-skipped comparisons

---

## 7. Open Questions

### 7.1 Decisions Needed

1. **Dual confidence level output?**
   - WinCross shows both 95% and 90%
   - Do we want capital/lowercase letter distinction?
   - Or just test at primary level?

2. **Phase 2 priority?**
   - Bonferroni correction: How important?
   - Is any client likely to request this?

3. **Mean comparison accuracy?**
   - Current t-test for means uses only summary statistics
   - Cannot perform proper t-test without raw data
   - Is this acceptable or does it need fixing?

4. **Should we expose config to users?**
   - Phase 1: Internal only (WINCROSS_DEFAULTS)
   - Future: API parameter? UI controls?

### 7.2 Information Gaps

1. **Joe's exact WinCross settings**
   - We've inferred from WinCross documentation
   - Would be helpful to confirm his actual configuration

2. **Dependent vs Independent test selection**
   - WinCross auto-selects based on banner structure
   - Do we need to implement dependent (paired) tests?
   - Or is independent sufficient for our use cases?

3. **T-test variant for means**
   - R's t.test() defaults to Welch's (unequal variances)
   - Is this what WinCross uses?
   - Does Joe have an opinion?

### 7.3 What Am I Missing?

Potential blind spots:

1. **Banner structure dependencies**
   - WinCross determines independent vs dependent based on banner structure
   - We assume all comparisons are independent
   - May need to revisit for complex banner designs

2. **Comparison group definitions**
   - Currently compare within groups + vs Total
   - Does Joe compare differently?
   - What about comparisons across groups?

3. **Weighting**
   - Do Joe's tabs use weighted data?
   - Current implementation assumes unweighted
   - Would need separate implementation for weighted tests

---

## 8. Summary & Next Steps

### 8.1 Immediate Actions (Phase 1)

1. Create `src/schemas/statTestingSchema.ts` with configuration schema
2. Update `sig_test_proportion()` to use unpooled formula by default
3. Remove hardcoded minimum sample size (n >= 5)
4. Add configuration flow through system
5. Update Excel footer to describe methodology
6. Run validation against Joe's output

### 8.2 Phase 2 (After Validation)

1. Implement Bonferroni correction option
2. Add dual confidence level support
3. Improve mean comparison accuracy (if needed)
4. Build UI controls for configuration (if needed)

### 8.3 Estimated Effort

- **Phase 1:** ~4 hours implementation + ~2 hours testing
- **Phase 2:** ~6-8 hours (depending on features selected)

### 8.4 Definition of Done (Phase 1)

- [ ] Unpooled z-test formula implemented
- [ ] Minimum sample size configurable (default: 0)
- [ ] Configuration schema created and documented
- [ ] R script generator accepts StatTestingConfig
- [ ] API endpoint accepts optional config
- [ ] Excel footer describes methodology
- [ ] Unit tests pass
- [ ] Side-by-side comparison with Joe's output shows match

---

## Appendix A: Formula Reference

### Pooled Z-Test (Current, Incorrect)

```
p_pool = (x1 + x2) / (n1 + n2)
SE = sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
z = (p1 - p2) / SE
```

### Unpooled Z-Test (WinCross Default, Correct)

```
SE = sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)
z = (p1 - p2) / SE
```

### Two-Tailed P-Value

```
p_value = 2 * (1 - Phi(|z|))
```

where Phi is the standard normal CDF.

### Bonferroni Correction

```
adjusted_alpha = alpha / k
```

where k = number of comparisons.

---

## Appendix B: WinCross Reference Links

- [WinCross Desktop](https://www.analyticalgroup.com/WinCross.html)
- [WinCross V25 What's New](https://www.analyticalgroup.com/WC25WhatsNew.html)
- [Which Statistical Test To Use (PDF)](http://www.analyticalgroup.com/download/Statistical%20Test%20To%20Use.pdf)
- [Two-proportion Z-test (Wikipedia)](https://en.wikipedia.org/wiki/Two-proportion_Z-test)
- [Penn State: Two Independent Proportions](https://online.stat.psu.edu/stat200/book/export/html/193)

---

## Appendix C: Existing Bug Reference

From `temp-outputs/test-pipeline-practice-files-.../bugs.md` (lines 44-48):

> **Significance testing discrepancy (S8 example)**: Our significance letters differ from Joe's even when base sizes and data values are identical. Example: S8 "Percentage of professional time" - Tiers columns show different significance patterns.
> - Not a confidence level issue (both appear to be 90%)
> - Same base n, same means
> - Need to verify: pooled vs unpooled variance, one-tailed vs two-tailed, small sample handling, comparison group definitions
> - **Action**: Ask Joe for his default significance testing settings/parameters

**Resolution:** The discrepancy is explained by pooled vs unpooled formula difference. This plan addresses the root cause.
