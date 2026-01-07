# Significance Testing Implementation Plan

**Status**: Planning
**Created**: 2026-01-07
**Last Updated**: 2026-01-07
**Priority**: High - Required for production parity with Joe's WinCross output

---

## Executive Summary

Our statistical significance testing implementation needs updates to match WinCross defaults. The primary issue is that we use **pooled proportions** for z-tests, but WinCross defaults to **unpooled proportions**. This explains the significance testing discrepancies noted in `bugs.md`.

### Quick Reference: Current vs Target

| Parameter | Current Implementation | WinCross Default | Action Needed |
|-----------|----------------------|------------------|---------------|
| Confidence Level | 90% (α=0.10) | 90% default | ✅ No change |
| Z-test Type | Two-tailed | Two-tailed | ✅ No change |
| Z-test Formula | **Pooled** proportions | **Unpooled** proportions | ❌ **Fix required** |
| Min Sample Size | n < 5 → NA | No minimum | ❌ **Fix required** |
| Multiple Comparison | None | None (Bonferroni opt-in V25+) | ✅ No change |
| T-test | Welch's (unequal variance) | T-test for means | ✅ Verify compatible |

---

## Part 1: Current State Analysis

### 1.1 Primary Statistical Testing Code

**File**: `src/lib/r/RScriptGeneratorV2.ts`

#### Z-Test for Proportions (Lines 301-323)
```r
sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {
  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size ❌ REMOVE

  # Pooled proportion ❌ CHANGE TO UNPOOLED
  p_pool <- (count1 + count2) / (n1 + n2)
  if (p_pool == 0 || p_pool == 1) return(NA)

  # Standard error (pooled formula) ❌ CHANGE TO UNPOOLED
  se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
  if (se == 0) return(NA)

  # Z statistic
  p1 <- count1 / n1
  p2 <- count2 / n2
  z <- (p1 - p2) / se

  # Two-tailed p-value ✅ CORRECT
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2))
}
```

**Issues Identified**:
1. **Pooled formula used**: We calculate `p_pool = (count1 + count2) / (n1 + n2)` and use it for SE
2. **Minimum sample size enforced**: `n1 < 5 || n2 < 5` returns NA
3. **Edge case handling**: Returns NA when `p_pool == 0 || p_pool == 1`

#### T-Test for Means (Lines 327-342)
```r
sig_test_mean <- function(vals1, vals2, threshold = p_threshold) {
  n1 <- sum(!is.na(vals1))
  n2 <- sum(!is.na(vals2))

  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size

  tryCatch({
    result <- t.test(vals1, vals2, na.rm = TRUE)  # Welch's t-test (default)
    m1 <- mean(vals1, na.rm = TRUE)
    m2 <- mean(vals2, na.rm = TRUE)
    return(list(significant = result$p.value < threshold, higher = m1 > m2))
  }, error = function(e) {
    return(NA)
  })
}
```

**Notes**: R's `t.test()` defaults to Welch's t-test (unequal variances). This is generally more robust than Student's t-test and is a reasonable default.

### 1.2 Configuration Interface

**File**: `src/lib/r/RScriptGeneratorV2.ts` (Lines 35-44)

```typescript
export interface RScriptV2Input {
  tables: TableDefinition[];
  cuts: CutDefinition[];
  cutGroups?: CutGroup[];
  totalStatLetter?: string | null;
  dataFilePath?: string;
  significanceLevel?: number;       // Default: 0.10 (90% confidence)
  totalRespondents?: number;
  bannerGroups?: BannerGroup[];
}
```

**Current configurability**:
- ✅ `significanceLevel` - Can be overridden (defaults to 0.10)
- ❌ Z-test method (pooled/unpooled) - Hardcoded as pooled
- ❌ Minimum sample size - Hardcoded as 5
- ❌ T-test type - Hardcoded as Welch's
- ❌ Multiple comparison correction - Hardcoded as none

### 1.3 Downstream Consumers

Files that use significance testing results:

1. **Excel Renderers**:
   - `src/lib/excel/tableRenderers/frequencyTable.ts` - Displays `sig_higher_than`, `sig_vs_total`
   - `src/lib/excel/tableRenderers/meanRowsTable.ts` - Same significance display

2. **Excel Formatter**:
   - `src/lib/excel/ExcelFormatter.ts` - Uses `significanceLevel` from metadata for footer text

3. **Significance footer text** (Lines 296 in frequencyTable.ts):
   ```typescript
   sigFooter.value = `Significance at ${Math.round((1 - significanceLevel) * 100)}% level. T-test for means, Z-test for proportions.`;
   ```

---

## Part 2: Gap Analysis

### 2.1 Critical Gap: Pooled vs Unpooled Z-Test

**WinCross behavior** (from documentation):
> "If the data are independent, the Dependent Paired/Overlap (Multi) test is the same as the Independent (using unpooled proportions) test."

**Formula comparison**:

| Method | Standard Error Formula | When to Use |
|--------|----------------------|-------------|
| **Pooled** | `SE = sqrt(p_pool * (1-p_pool) * (1/n1 + 1/n2))` | Hypothesis testing H₀: p₁=p₂ |
| **Unpooled** | `SE = sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)` | Confidence intervals, conservative |

**Why WinCross uses unpooled**:
1. More conservative (wider SE → fewer false positives)
2. Doesn't assume null hypothesis is true when calculating SE
3. Industry standard for survey crosstabs

**Impact of fixing this**:
- Some cells currently marked as significant may lose significance
- Matches Joe's output more closely
- More defensible methodology

### 2.2 Minimum Sample Size Gap

**Current behavior**: `n < 5` returns NA (no test performed)

**WinCross behavior**: No minimum enforced - tests all data

**Considerations**:
- Small samples (n<5) have very low statistical power
- Results may be unreliable but still mathematically valid
- Joe's output tests everything, so we should too for parity

**Recommendation**: Remove minimum, but add a **warning flag** for small samples

### 2.3 Missing Configuration Infrastructure

Current configuration is too limited. We need:

1. **Statistical testing config object** that can be passed through the pipeline
2. **Sensible defaults** that match WinCross
3. **Override capability** at multiple levels (global, per-job, per-table if needed)

### 2.4 Mean Rows T-Test Limitation

**Current issue** (Lines 785-794 in RScriptGeneratorV2.ts):
```r
if (table_type == "mean_rows") {
  # For means, we need the raw values - use count/pct as proxy
  # In practice, need to store raw values or use different approach
  if (!is.na(row_data$mean) && !is.na(other_data$mean)) {
    if (row_data$mean > other_data$mean) {
      # Simplified: flag if mean is higher (proper t-test needs raw data)
      sig_higher <- c(sig_higher, cut_stat_letters[[other_cut]])
    }
  }
}
```

**Problem**: We're not actually running a t-test for within-group mean comparisons - just flagging when one mean is higher. This is because we only store summary statistics (mean, sd, n), not raw values.

**Options**:
1. Store raw values during processing (memory intensive)
2. Use approximate t-test from summary stats (mean, sd, n)
3. Accept current limitation and document

**Recommendation for Phase 1**: Use approximate t-test formula with summary statistics:
```r
# Welch's t-test from summary statistics
t_stat <- (mean1 - mean2) / sqrt(sd1^2/n1 + sd2^2/n2)
df <- ((sd1^2/n1 + sd2^2/n2)^2) / ((sd1^2/n1)^2/(n1-1) + (sd2^2/n2)^2/(n2-1))
p_value <- 2 * pt(-abs(t_stat), df)
```

---

## Part 3: Implementation Roadmap

### Phase 1: Match WinCross Defaults (Priority: HIGH)

**Goal**: Ensure our output matches Joe's WinCross output for the same data.

#### Step 1.1: Create SignificanceConfig Schema

**File**: `src/schemas/significanceConfigSchema.ts` (NEW)

```typescript
import { z } from 'zod';

export const ProportionTestMethodSchema = z.enum(['unpooled', 'pooled']);
export const MeanTestMethodSchema = z.enum(['welch', 'student']);
export const MultipleCorrectionMethodSchema = z.enum(['none', 'bonferroni', 'fdr']);

export const SignificanceConfigSchema = z.object({
  // Confidence level (alpha = 1 - confidenceLevel)
  // 0.90 means 90% confidence, alpha = 0.10
  confidenceLevel: z.number().min(0.5).max(0.999).default(0.90),

  // Proportion test configuration
  proportionTest: z.object({
    method: ProportionTestMethodSchema.default('unpooled'),
    // Future: could add 'pooled' for hypothesis testing contexts
  }).default({}),

  // Mean test configuration
  meanTest: z.object({
    method: MeanTestMethodSchema.default('welch'),
    // Future: could add 'student' for equal variance assumption
  }).default({}),

  // Minimum sample sizes (0 = no minimum)
  minSampleSizes: z.object({
    forProportionTest: z.number().int().min(0).default(0),
    forMeanTest: z.number().int().min(0).default(0),
    warningThreshold: z.number().int().min(0).default(10),
  }).default({}),

  // Multiple comparison correction
  multipleComparison: z.object({
    method: MultipleCorrectionMethodSchema.default('none'),
    // Bonferroni: adjusted_alpha = alpha / number_of_comparisons
    // FDR: Benjamini-Hochberg procedure
  }).default({}),

  // What to compare against
  comparisons: z.object({
    withinGroup: z.boolean().default(true),   // Compare A vs B, C, D, E within same group
    vsTotal: z.boolean().default(true),       // Compare each column vs Total
  }).default({}),
});

export type SignificanceConfig = z.infer<typeof SignificanceConfigSchema>;

// WinCross-matching defaults
export const WINCROSS_DEFAULTS: SignificanceConfig = {
  confidenceLevel: 0.90,
  proportionTest: { method: 'unpooled' },
  meanTest: { method: 'welch' },
  minSampleSizes: { forProportionTest: 0, forMeanTest: 0, warningThreshold: 10 },
  multipleComparison: { method: 'none' },
  comparisons: { withinGroup: true, vsTotal: true },
};

// Conservative defaults (recommended for new projects)
export const CONSERVATIVE_DEFAULTS: SignificanceConfig = {
  confidenceLevel: 0.95,
  proportionTest: { method: 'unpooled' },
  meanTest: { method: 'welch' },
  minSampleSizes: { forProportionTest: 5, forMeanTest: 5, warningThreshold: 30 },
  multipleComparison: { method: 'bonferroni' },
  comparisons: { withinGroup: true, vsTotal: true },
};
```

#### Step 1.2: Update RScriptV2Input Interface

**File**: `src/lib/r/RScriptGeneratorV2.ts`

```typescript
import type { SignificanceConfig } from '@/schemas/significanceConfigSchema';
import { WINCROSS_DEFAULTS } from '@/schemas/significanceConfigSchema';

export interface RScriptV2Input {
  tables: TableDefinition[];
  cuts: CutDefinition[];
  cutGroups?: CutGroup[];
  totalStatLetter?: string | null;
  dataFilePath?: string;
  totalRespondents?: number;
  bannerGroups?: BannerGroup[];

  // DEPRECATED: Use significanceConfig instead
  significanceLevel?: number;

  // NEW: Full significance testing configuration
  significanceConfig?: SignificanceConfig;
}
```

#### Step 1.3: Update Z-Test Function (Unpooled)

**File**: `src/lib/r/RScriptGeneratorV2.ts` - `generateHelperFunctions()`

```r
# Z-test for proportions (configurable pooled/unpooled)
# Default: unpooled (matches WinCross)
sig_test_proportion <- function(count1, n1, count2, n2,
                                 threshold = p_threshold,
                                 method = proportion_method,
                                 min_n = min_sample_proportion) {
  # Sample size check (0 = no minimum)
  if (min_n > 0 && (n1 < min_n || n2 < min_n)) return(NA)

  # Calculate proportions
  p1 <- count1 / n1
  p2 <- count2 / n2

  # Standard error (method-dependent)
  if (method == "pooled") {
    p_pool <- (count1 + count2) / (n1 + n2)
    if (p_pool == 0 || p_pool == 1) return(NA)
    se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
  } else {
    # Unpooled (default - matches WinCross)
    se <- sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
  }

  if (is.na(se) || se == 0) return(NA)

  # Z statistic
  z <- (p1 - p2) / se

  # Two-tailed p-value
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(list(significant = p_value < threshold, higher = p1 > p2, p_value = p_value))
}
```

#### Step 1.4: Update T-Test Function (Summary Stats)

```r
# T-test for means using summary statistics
# Uses Welch's approximation (unequal variances)
sig_test_mean_summary <- function(mean1, sd1, n1, mean2, sd2, n2,
                                   threshold = p_threshold,
                                   min_n = min_sample_mean) {
  # Sample size check
  if (min_n > 0 && (n1 < min_n || n2 < min_n)) return(NA)
  if (n1 < 2 || n2 < 2) return(NA)  # Need at least 2 for variance
  if (is.na(sd1) || is.na(sd2)) return(NA)
  if (sd1 == 0 && sd2 == 0) return(NA)  # No variance to test

  # Welch's t-test formula
  se <- sqrt(sd1^2/n1 + sd2^2/n2)
  if (se == 0) return(NA)

  t_stat <- (mean1 - mean2) / se

  # Welch-Satterthwaite degrees of freedom
  df <- (sd1^2/n1 + sd2^2/n2)^2 /
        ((sd1^2/n1)^2/(n1-1) + (sd2^2/n2)^2/(n2-1))

  # Two-tailed p-value
  p_value <- 2 * pt(-abs(t_stat), df)

  return(list(significant = p_value < threshold, higher = mean1 > mean2, p_value = p_value))
}
```

#### Step 1.5: Add Configuration Variables to R Script Header

**New section in generated R script**:
```r
# =============================================================================
# Significance Testing Configuration
# =============================================================================

# Threshold (alpha level)
p_threshold <- 0.10  # 90% confidence

# Test methods
proportion_method <- "unpooled"  # "unpooled" (WinCross default) or "pooled"
mean_method <- "welch"           # "welch" (unequal variance) or "student"

# Minimum sample sizes (0 = no minimum, matches WinCross)
min_sample_proportion <- 0
min_sample_mean <- 0
warning_threshold <- 10  # Flag results with n < this

# Multiple comparison correction
correction_method <- "none"  # "none", "bonferroni", "fdr"
```

#### Step 1.6: Update Significance Testing Pass

Update the significance testing loop to:
1. Use new functions with configurable parameters
2. Store p-values for potential Bonferroni correction
3. Track small sample warnings

### Phase 2: Add Optional Rigor (Priority: MEDIUM)

**Goal**: Provide more conservative options for users who want them.

#### Step 2.1: Implement Bonferroni Correction

After collecting all p-values in a table:
```r
# Apply Bonferroni correction
if (correction_method == "bonferroni") {
  n_comparisons <- length(all_p_values)
  adjusted_threshold <- p_threshold / n_comparisons
  # Re-evaluate all significance flags with adjusted threshold
}
```

**Considerations**:
- Count comparisons within each table separately
- For within-group comparisons: k groups means k*(k-1)/2 pairwise comparisons
- Store both raw and adjusted significance

#### Step 2.2: Add FDR Correction (Future)

Benjamini-Hochberg procedure - more powerful than Bonferroni for many comparisons.

#### Step 2.3: Small Sample Warnings

Add metadata to results:
```json
{
  "sig_higher_than": ["B", "C"],
  "sig_vs_total": "higher",
  "warnings": ["small_sample"],  // NEW
  "sample_size": 8              // NEW (for transparency)
}
```

### Phase 3: Testing & Validation (Priority: HIGH)

#### Step 3.1: Create Test Cases

**File**: `scripts/test-significance.ts` (NEW)

Test scenarios:
1. **Known values**: Hand-calculated z-tests with known correct results
2. **Edge cases**: n=1, n=2, p=0, p=1, identical proportions
3. **Pooled vs unpooled**: Verify different results with same data
4. **Joe comparison**: Run on practice-files and compare to Joe's output

#### Step 3.2: Regression Test

Before/after comparison:
1. Run current code on practice-files, save results
2. Apply changes
3. Run new code on same data
4. Document which cells changed significance and why

#### Step 3.3: Validation Against Joe's Output

Using the S8 example from bugs.md:
- Extract exact values from Joe's tabs
- Run our calculation with both pooled and unpooled
- Verify unpooled matches Joe's significance letters

---

## Part 4: Configuration Flow

### 4.1 Where Defaults Are Set

```
src/schemas/significanceConfigSchema.ts
    └── WINCROSS_DEFAULTS (base defaults)
         └── RScriptV2Input.significanceConfig (per-job override)
              └── Future: per-table override (not implemented)
```

### 4.2 How Configuration Flows Through System

```
API Request
    ↓
process-crosstab/route.ts (receives optional config)
    ↓
RScriptGeneratorV2.generateRScriptV2(input)
    ↓
R Script (config embedded as variables)
    ↓
R Execution (uses config for all tests)
    ↓
JSON Output (includes config in metadata)
    ↓
ExcelFormatter (displays config in footer)
```

### 4.3 Proposed API Interface

```typescript
// In API request body
{
  files: [...],
  options: {
    significanceConfig: {
      confidenceLevel: 0.95,  // Override: use 95% instead of 90%
      multipleComparison: {
        method: 'bonferroni'  // Override: add correction
      }
      // Other fields use defaults
    }
  }
}
```

---

## Part 5: Risk Assessment

### 5.1 What Could Go Wrong

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Output changes unexpectedly | High | Medium | Run regression tests, document all changes |
| Unpooled gives more conservative results | Expected | Low | This is the intended behavior |
| Edge cases break (n=0, p=0) | Medium | High | Add comprehensive edge case tests |
| Mean t-test approximation inaccurate | Low | Medium | Validate against raw data t-test |
| Performance degradation | Low | Low | R script execution is already slow |

### 5.2 Breaking Changes

**Existing behavior that will change**:
1. Some cells currently marked significant will lose significance (due to unpooled SE)
2. Cells with n < 5 will now show significance (may be spurious)

**Mitigation**:
- Version the output format
- Document methodology in Excel footer
- Provide "legacy" mode if needed (unlikely)

### 5.3 Validation Strategy

1. **Unit tests**: Test statistical functions in isolation
2. **Integration tests**: Test full pipeline with known data
3. **Comparison tests**: Compare output to Joe's WinCross results
4. **Manual review**: Spot-check specific tables that previously differed

---

## Part 6: Open Questions

### 6.1 Decisions Needed

1. **Should we keep n<5 check as a warning?**
   - Recommendation: Remove as hard block, add as warning flag
   - Need to decide how to display warnings in Excel

2. **What about dependent samples?**
   - WinCross has separate tests for paired/overlap data
   - Our banner structure is generally independent (mutually exclusive cuts)
   - Recommendation: Assume independent for now, document limitation

3. **Mean rows t-test: summary stats or raw data?**
   - Summary stats approach is approximate but avoids storing raw data
   - Recommendation: Use summary stats formula for Phase 1

4. **Should we expose config in UI?**
   - Eventually yes, but not in Phase 1
   - API-only configuration first

### 6.2 What's Unclear

1. **Exact WinCross formula for dependent tests** - May need if we support LOC+ banners
2. **Joe's specific settings** - We inferred 90% confidence, but should confirm
3. **How WinCross handles ties** - When proportions are equal, what's the p-value?

### 6.3 Future Considerations

1. **Chi-square tests** - For overall table-level significance
2. **Effect size measures** - Cohen's d, odds ratios
3. **Confidence intervals** - Display alongside point estimates
4. **Power analysis** - Flag underpowered comparisons

---

## Part 7: Implementation Checklist

### Phase 1: Match WinCross (Target: Week 1)

- [ ] Create `significanceConfigSchema.ts` with Zod schema
- [ ] Update `RScriptV2Input` interface to accept config
- [ ] Implement unpooled z-test formula in R generator
- [ ] Implement summary-stats t-test formula
- [ ] Add configuration variables to generated R script
- [ ] Remove n<5 hard block, add warning flag
- [ ] Update Excel footer to reflect methodology
- [ ] Write test script with known values
- [ ] Compare output to Joe's practice-files results
- [ ] Update bugs.md with resolution

### Phase 2: Optional Rigor (Target: Week 2)

- [ ] Implement Bonferroni correction
- [ ] Add small sample warnings to JSON output
- [ ] Update Excel to display warnings appropriately
- [ ] Document configuration options
- [ ] Add API parameter for config override

### Phase 3: Polish (Target: Week 3)

- [ ] Implement FDR correction (optional)
- [ ] Add comprehensive test suite
- [ ] Performance testing
- [ ] Documentation update
- [ ] Code review and cleanup

---

## Appendix A: Formula Reference

### A.1 Two-Proportion Z-Test (Unpooled)

**Null hypothesis**: H₀: p₁ = p₂
**Test statistic**:
```
z = (p₁ - p₂) / SE

SE = sqrt(p₁(1-p₁)/n₁ + p₂(1-p₂)/n₂)  # Unpooled
```

**P-value**: `2 * (1 - Φ(|z|))` where Φ is standard normal CDF

### A.2 Two-Proportion Z-Test (Pooled)

**Standard error** (for hypothesis testing):
```
p_pooled = (x₁ + x₂) / (n₁ + n₂)
SE = sqrt(p_pooled * (1 - p_pooled) * (1/n₁ + 1/n₂))
```

### A.3 Welch's T-Test (from summary statistics)

**Test statistic**:
```
t = (x̄₁ - x̄₂) / sqrt(s₁²/n₁ + s₂²/n₂)
```

**Degrees of freedom** (Welch-Satterthwaite):
```
df = (s₁²/n₁ + s₂²/n₂)² / ((s₁²/n₁)²/(n₁-1) + (s₂²/n₂)²/(n₂-1))
```

### A.4 Bonferroni Correction

**Adjusted alpha**:
```
α_adjusted = α / m

where m = number of comparisons
```

---

## Appendix B: References

### WinCross Documentation
- [WinCross Independent Z-Tests](http://analyticalgroup.com/WinCrossHelp16/wincross_help/z-test_for_percents.htm)
- [WinCross Default Statistics Settings](http://analyticalgroup.com/WinCrossHelp16/wincross_help/default_settings_statistics.htm)
- [WinCross V25 What's New](https://www.analyticalgroup.com/WC25WhatsNew.html) - Bonferroni added

### Statistical References
- [Two-Proportion Z-test (Wikipedia)](https://en.wikipedia.org/wiki/Two-proportion_Z-test)
- [Penn State STAT 200: Two Independent Proportions](https://online.stat.psu.edu/stat200/book/export/html/193)
- [NCSS: Tests for Two Proportions](https://www.ncss.com/wp-content/themes/ncss/pdf/Procedures/PASS/Tests_for_Two_Proportions.pdf)

### Codebase References
- Bug tracker: `temp-outputs/.../bugs.md` (S8 significance discrepancy)
- Current implementation: `src/lib/r/RScriptGeneratorV2.ts`
- Excel rendering: `src/lib/excel/tableRenderers/frequencyTable.ts`
