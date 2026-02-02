# HawkTab AI Improvement Plan

## Overview

This document consolidates feedback from comparing our pipeline output against Joe's reference tabs for the Leqvio Monotherapy Demand study (NOV217). Each theme describes the problem observed and the recommended fix.

**Source**: `outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-02-01T05-49-17-899Z/feedback.md`

---

## Classification Overview

| Theme | Issue Type | Fix Category | Status |
|-------|------------|--------------|--------|
| A: Base Filtering | Agent misinterpretation of survey logic | **Prompt-level** | ✅ Complete |
| B: Redundant NETs | Missing guardrail | **Prompt-level** | ✅ Complete |
| C: Missing Rollups | Incomplete guidance for conceptual groupings | **Prompt-level** | ✅ Complete |
| D: Binning | Partial prompt, partial system | **Mixed** | ✅ Complete |
| E: Calculations | Statistical implementation | **System-level** | |
| F: Presentation | Missing examples | **Prompt-level** | |
| G: Over-splitting | Architectural limitation | **System-level** | |
| H: Future Features | New capabilities | **System-level** | |

---

## Theme A: Base Filtering ✅

**Problems**: A5 over-filtered to zero (redundant `!is.na()` checks), A6 invented filter for hypothetical question (inferred from content, not explicit instructions), A4a/A9 inconsistent bases.

**Solution**: Updated `src/prompts/basefilter/production.ts`:
1. Added **Foundational Principle** to `<skip_show_logic_patterns>`: Find explicit logic, don't infer whether filters should exist. The inference you DO make is filter scope (table vs row level).
2. Added **Keep Expressions Simple** to `<r_expression_syntax>`: Removed `!is.na()` example, warned against redundant NA checks.
3. Added **Intent Restatement** to `<scratchpad_protocol>`: "Intent:" field forces plain-language thinking before writing filters.
4. Added **Examples 5 & 6**: Hypothetical question (no filter) and "differs from" logic (simple filter).

---

## Theme B: Redundant NETs ✅

**Problems**: S2B `Clinicians (NET)` = 100%, S5 `Any affiliation (NET)` = 0%, S8 `>=70% (NET)` = 100% (qualification criterion), A7 NET sums to 100%.

**Solution**: Expanded Guideline 9 in `src/prompts/verification/alternative.ts` `<constraints>` to explicitly list signs a NET will be trivial: TERMINATE-based rollups, study design characteristics, inverse of "None of these", grouping all options of single-select.

---

## Theme C: Missing Rollups ✅

**Problems**: S3a missing "Specialized Cardiologist (Total)" grouping Interventional + Preventative; A2b missing "Recommend a Statin First (Total)" grouping two statin-first options.

**Solution**: Expanded TOOL 2: NET ROWS in `src/prompts/verification/alternative.ts` to add a third type: **Conceptual Grouping NETs**. Added patterns to look for: "General vs Specific" distinctions, shared prefix/suffix, conceptually opposite groups.

---

## Theme D: Binning & Distribution ✅

**Problems**: S6_DIST bins lacked interpretable cut points, S10_BINNED chose bins without knowing actual distribution, S10 missing "mean excluding outliers", S12 missing binned distribution.

**Solution**: Mixed system and prompt changes:

1. **System: Pass distribution data to VerificationAgent** — Created `src/lib/stats/DistributionCalculator.ts` that uses R subprocess to calculate actual stats (n, min, max, mean, median, q1, q3) from SPSS data. Extended `TableMetaSchema` with `distribution` field. Integrated into `PipelineRunner.ts` before VerificationAgent call.

2. **System: Display trimmed mean in Excel** — Added "Mean (minus outliers)" row to `src/lib/excel/tableRenderers/joeStyleMeanRows.ts` (data already calculated by R).

3. **Prompt: Binning guidance with distribution data** — Updated TOOL 5 in `src/prompts/verification/alternative.ts` with guidance on using distribution stats to choose natural breakpoints (None/Any/High, quartile-based, round numbers near landmarks).

---

## Theme E: Calculations & Statistical Accuracy

Core accuracy issues that affect trust in the output.

### Problem Examples

| Issue | Details |
|-------|---------|
| Stat testing | Our significance callouts don't always match Joe's |
| S11 mean/median | Our mean=168, median=125 vs Joe's mean=175.9, median=150 |

### Current Stat Testing State

| Feature | Status | Details |
|---------|--------|---------|
| Confidence level | ✅ Configurable | Default 0.10 (90%) |
| Dual thresholds | ✅ Supported | `[0.05, 0.10]` → uppercase (95%) / lowercase (90%) |
| Z-test for proportions | ✅ Implemented | Unpooled z-test |
| T-test for means | ✅ Implemented | Welch's t-test |
| Within-group comparisons | ✅ Works | Compares columns in same banner group |
| Comparison to Total | ✅ Works | All columns vs Total |
| Stat letters | ✅ Works | T, A, B, C... deterministic assignment |

**What's hardcoded (candidates for configurability):**

| Feature | Current State | Potential Option |
|---------|---------------|------------------|
| Test type (proportions) | Always unpooled z-test | Pooled z-test, chi-square |
| Test type (means) | Always Welch's t-test | Student's t-test |
| Minimum base | No minimum (tests all cells) | Configurable minimum n |
| Multiple comparison correction | None | Bonferroni correction |
| Overlap handling | Not implemented | Dependent sample handling |

### Critical Bug Found: Fake Significance Testing for Means

**Location**: `src/lib/r/RScriptGeneratorV2.ts` lines 1163-1172 and 1199-1204

**The problem**: For `mean_rows` tables, we are NOT doing statistical significance testing. The code just checks if one mean is larger than another and marks it "significant" — no t-test, no p-value calculation.

```r
# CURRENT (WRONG):
if (row_data$mean > other_data$mean) {
  sig_higher <- c(sig_higher, toupper(other_letter))  # Fake!
}
```

**The fix**: We already store `n`, `mean`, `sd` for each cell. Use these to calculate a proper Welch's t-test:

```r
# CORRECT:
se <- sqrt(sd1^2/n1 + sd2^2/n2)
t_stat <- (mean1 - mean2) / se
df <- ((sd1^2/n1 + sd2^2/n2)^2) / ((sd1^2/n1)^2/(n1-1) + (sd2^2/n2)^2/(n2-1))
p_value <- 2 * pt(-abs(t_stat), df)
if (p_value < p_threshold && mean1 > mean2) {
  sig_higher <- c(sig_higher, other_letter)
}
```

**Scope**: This affects ALL mean_rows tables in the output. Every significance letter for means is currently fake.

**Principle**: No shortcuts in statistical testing. Everything must be legitimate, defensible statistics.

### E2: Mean/Median Mismatch — Investigation Results

**S11 comparison** (same n=180):

| Stat | Our Output | Joe's Output | Difference |
|------|------------|--------------|------------|
| Mean | 168.0 | 175.9 | -7.9 |
| Median | 125 | 150 | -25 |
| Mean (minus outliers) | 152.6 (IQR method) | 159.8 | -7.2 |

**What we verified:**
- Our calculation is correct for the data we have (R confirms mean=168, median=125)
- No values below 10 in data (TERMINATE IF <10 was applied)
- No invalid values where S11 > S10
- 3 outliers exist (600, 750, 900) but don't explain median difference

**Conclusion: Our statistics are correct.**

We calculate mean and median correctly from the data. The difference with Joe's output likely reflects different data versions, weighting, or methodology on his end — but that's not our concern. Our goal isn't to copy Joe; it's to do legitimate statistics.

**Status: Investigated and resolved. No action needed.**

### Recommended Configuration Interface

```typescript
interface StatTestingConfig {
  // Thresholds
  confidenceLevels: number[];  // e.g., [0.90] or [0.95, 0.90]

  // Test options
  proportionTest: 'unpooled_z' | 'pooled_z';
  meanTest: 'welch_t' | 'student_t';

  // Base handling
  minimumBase: number;  // Default: 0 (no minimum)

  // Multiple comparisons
  correction: 'none' | 'bonferroni';

  // Display
  letterCase: 'uppercase_only' | 'dual_case';
}
```

**Defaults for HawkPartners:**
- 90% confidence (single level, uppercase letters)
- Unpooled z-test for proportions, Welch's t-test for means
- No minimum base (test all cells, note small bases in reporting)
- No multiple comparison correction

---

## Theme F: Presentation & Hierarchy

Presentation improvements that enhance readability without affecting accuracy.

### Problem Examples

| Table | Issue |
|-------|-------|
| S3a | Indentation too shallow — components not indented under NETs |
| A1 | Rows repeat full "Leqvio (inclisiran): As an adjunct to..." instead of factoring out treatment name |
| A2a | Common prefix repeated three times instead of factored into header |
| A3 | Inconsistent row ordering across related tables |

### Root Cause Analysis

The prompt lacks examples of advanced presentation patterns:
- Factoring out common prefixes into header rows
- Maintaining consistent row ordering across related tables
- Using header rows to group conceptually related items

### Recommended Fix

**Location**: `src/prompts/verification/alternative.ts` — Add new section `<presentation_patterns>`

```markdown
<presentation_patterns>
ADVANCED PRESENTATION: IMPROVING SCANNABILITY

PATTERN 1: FACTOR OUT COMMON PREFIXES
When multiple rows share a long common prefix, extract it as a header row.

BEFORE (verbose, hard to scan):
- "Recommend approach X for patients with condition A and threshold >=55"
- "Recommend approach X for patients with condition A and threshold >=70"
- "Recommend approach X for patients with condition A and threshold >=100"

AFTER (scannable):
- "Recommend approach X for patients with condition A and:" [HEADER]
  - "Threshold >=55"
  - "Threshold >=70"
  - "Threshold >=100"

Implementation:
{ "variable": "_CAT_", "label": "Recommend approach X for... and:", "filterValue": "_HEADER_", "indent": 0 },
{ "variable": "Q8", "label": "Threshold >=55", "filterValue": "1", "indent": 1 },
{ "variable": "Q8", "label": "Threshold >=70", "filterValue": "2", "indent": 1 },
{ "variable": "Q8", "label": "Threshold >=100", "filterValue": "3", "indent": 1 }


PATTERN 2: GROUP BY PRIMARY DIMENSION
When rows combine two dimensions (e.g., brand × condition), use one dimension as header rows.

BEFORE (interleaved, confusing):
- "Brand A: Condition 1"
- "Brand A: Condition 2"
- "Brand B: Condition 1"
- "Brand B: Condition 2"

AFTER (grouped by brand):
- "Brand A" [HEADER]
  - "Condition 1"
  - "Condition 2"
- "Brand B" [HEADER]
  - "Condition 1"
  - "Condition 2"


PATTERN 3: CONSISTENT ROW ORDERING ACROSS RELATED TABLES
When multiple tables cover the same items (brands, products, categories):
- Use the SAME row order across all related tables
- Default to datamap order unless there's a strong analytical reason to reorder
- WHY: Users copy rows across tables for comparison. Consistent order means rows align.

PRINCIPLE: Stability > Optimization
A consistent mediocre order is better than an inconsistent "optimal" order.


PATTERN 4: LOGICAL GROUPING WITHIN TABLES
When a table mixes conceptually different rows:
- Group related rows together using category headers
- Separate standalone items from rollup groups
- Example ordering: Individual items first, then NETs; OR NETs first, then components
- Pick one approach and apply consistently
</presentation_patterns>
```

---

## Theme G: Over-splitting

Over-splitting creates too many tables; this is why our output has **way more tables than Joe's**.

### Problem Examples

| Tables affected | Issue |
|-----------------|-------|
| `A3a_brand` ✅ | Good — shows both situations in one table |
| `A3a_situation_brand` ❌ | Over-split — creates separate tables for each situation, redundant |
| Same pattern for A3b, A4a | Bloats workbook with redundant splits |

### Root Cause Analysis

Over-splitting happens because of how the pipeline processes tables:

1. **VerificationAgent** creates situation views: `a3a`, `a3a_in_addition`, `a3a_without_statins`

2. **BaseFilterAgent** processes each table **independently** — it doesn't know what other tables exist

3. When it sees `a3a`, it correctly splits by brand → `a3a_leqvio`, `a3a_praluent`, etc.

4. When it sees `a3a_in_addition`, it **doesn't know** `a3a_leqvio` already exists, so it correctly splits again → `a3a_in_addition_leqvio`, etc.

5. **Result**: 15 tables instead of 5, but each split was locally correct

**The core issue**: This is an **architectural limitation**, not an agent error. BaseFilterAgent processes tables in isolation without visibility into what tables already exist in the system.

### Classification: Architectural (Not Prompt-Level)

This isn't fixable with prompt guidance. Possible system-level solutions:

1. **Give BaseFilterAgent visibility** into all tables created so far in this run
2. **Process related tables together** instead of one at a time
3. **Post-processing step** to identify and merge/remove redundant tables
4. **Prevent upstream splits** — have VerificationAgent not create the situation views, letting BaseFilterAgent handle all splitting

**Status**: Known limitation. Acceptable for MVP. Future enhancement could add cross-table awareness to reduce redundancy.

---

## Theme H: Future Features (Not MVP)

Not blocking for Feb 16 deadline, but worth tracking.

### H1. Pre/Post comparison tables

**What Joe does**: Creates pre/post comparison tables spanning multiple questions (A3 vs A4, A3a vs A4a) with "Mean difference (pre- vs post)" calculations.

**What we produce**: Separate tables for pre (A3) and post (A4) questions.

**Why NOT blocking**: Analyst can derive comparison themselves. Antares' existing tools don't produce these either.

**Future enhancement**: Detect pre/post pairs (LAST 100 vs NEXT 100), pass paired context to VerificationAgent, instruct to create comparison tables.

### H2. Selectable Excel color themes

**Problem**: We have effectively one styling look-and-feel.

**Expected**: Offer 4+ curated color themes that users select at run start. Themes should preserve semantics (header fill, alternating row fill, banner separation) while allowing palette customization.

**Tasks**:
- Map current color usage to semantic roles
- Define 4+ palettes that plug into those semantic roles
- Expose theme selector (config / run metadata)

### H3. Interactive browser-based review

**Current workflow** (inefficient):
- Reviewer looks at static Excel
- Decides what to exclude/keep
- Has to regenerate to see changes

**Desired workflow**:
- After pipeline runs, generate preview **in browser**
- Reviewer can visually see all tables
- Toggle tables on/off (exclude/keep)
- Give feedback on specific tables
- See changes **live** before clicking submit
- Then generate final Excel

**Timeline**: NOT MVP (Feb 16 deadline), but memorializing for future.

---

## Implementation Roadmap

### Phase 1: Prompt Updates (Immediate)

These changes can be made to improve the next pipeline run:

**BaseFilterAgent (`src/prompts/basefilter/production.ts`):**
1. ~~Add "Don't Invent Filters" foundational principle~~ ✅ Done (Theme A)
2. ~~Add "NA Filtering is Already Done" reminder~~ ✅ Done (Theme A)
3. ~~Add "Writing Clear Filters" guidance~~ ✅ Done (Theme A)

**VerificationAgent (`src/prompts/verification/alternative.ts`):**
1. ~~Add Rule 10 (no trivial NETs)~~ ✅ Done (Theme B)
2. ~~Expand TOOL 2 with conceptual grouping NETs~~ ✅ Done (Theme C)
3. ~~Expand TOOL 5 with binning heuristics~~ ✅ Done (Theme D)
4. Add `<presentation_patterns>` section (Theme F)

### Phase 2: System Changes (Requires Code)

| Change | Files Affected | Complexity | Status |
|--------|----------------|------------|--------|
| Fix fake mean significance testing | `src/lib/r/RScriptGeneratorV2.ts` | Medium | |
| ~~Reintroduce trimmed mean~~ | ~~`joeStyleMeanRows.ts`~~ | ~~Low~~ | ✅ Done (Theme D) |
| ~~Pass distribution data to agent~~ | ~~`DistributionCalculator.ts`, `PipelineRunner.ts`~~ | ~~Medium~~ | ✅ Done (Theme D) |
| Stat testing configurability | Pipeline config, R generation | High | |