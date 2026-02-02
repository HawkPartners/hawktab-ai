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
| E: Calculations | Statistical implementation | **System-level** | ✅ Complete |
| F: Presentation | Missing examples | **Prompt-level** | ✅ Complete |

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

## Theme E: Calculations & Statistical Accuracy ✅

**Problems**: Fake significance testing for means (just comparing values without t-test), hardcoded stat testing options, no logging of statistical assumptions.

**Solution**: System-level changes to `src/lib/env.ts`, `src/lib/r/RScriptGeneratorV2.ts`, `src/lib/pipeline/`:

1. **Fixed fake mean significance** — Replaced simple mean comparison with proper Welch's t-test using summary statistics (n, mean, sd). Both within-group and vs-Total comparisons now use legitimate p-value calculations.

2. **Made stat testing configurable** — Added `StatTestingConfig` interface with env vars (`STAT_THRESHOLDS`, `STAT_PROPORTION_TEST`, `STAT_MEAN_TEST`, `STAT_MIN_BASE`) and CLI flags (`--stat-thresholds`, `--stat-min-base`).

3. **Added stat testing logging** — Configuration now logged to console, R script header, and `pipeline-summary.json`.

**Note on mean/median mismatch**: Investigated S11 discrepancy with Joe's output. Our statistics are correct for the data we have; differences likely reflect different data versions or methodology on Joe's end. No action needed.

---

## Theme F: Presentation & Hierarchy ✅

**Problems**: Verbose repeated prefixes in row labels, inconsistent row ordering across related tables.

**Solution**: Enhanced TOOL 6 in `src/prompts/verification/alternative.ts`:
1. Added "Factoring out common prefixes" pattern with before/after example showing how to extract shared text into a header row
2. Added row ordering principle: maintain datamap order unless actively restructuring

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
4. ~~Expand TOOL 6 with prefix factoring example + row ordering~~ ✅ Done (Theme F)

### Phase 2: System Changes (Requires Code)

| Change | Files Affected | Complexity | Status |
|--------|----------------|------------|--------|
| ~~Fix fake mean significance testing~~ | ~~`src/lib/r/RScriptGeneratorV2.ts`~~ | ~~Medium~~ | ✅ Done (Theme E) |
| ~~Reintroduce trimmed mean~~ | ~~`joeStyleMeanRows.ts`~~ | ~~Low~~ | ✅ Done (Theme D) |
| ~~Pass distribution data to agent~~ | ~~`DistributionCalculator.ts`, `PipelineRunner.ts`~~ | ~~Medium~~ | ✅ Done (Theme D) |
| ~~Stat testing configurability~~ | ~~`env.ts`, `PipelineRunner.ts`, `cli/index.tsx`~~ | ~~High~~ | ✅ Done (Theme E) |