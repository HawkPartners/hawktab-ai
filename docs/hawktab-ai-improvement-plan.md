# HawkTab AI Improvement Plan

## Overview

This document consolidates feedback from comparing our pipeline output against Joe's reference tabs for the Leqvio Monotherapy Demand study (NOV217). Each theme describes the problem observed and the recommended fix.

**Source**: `outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-02-01T05-49-17-899Z/feedback.md`

---

## Classification Overview

| Theme | Issue Type | Fix Category |
|-------|------------|--------------|
| A: Base Filtering | Agent misinterpretation of survey logic | **Prompt-level** |
| B: Redundant NETs | Missing guardrail | **Prompt-level** |
| C: Missing Rollups | Incomplete guidance for conceptual groupings | **Prompt-level** |
| D: Binning | Partial prompt, partial system | **Mixed** |
| E: Calculations | Statistical implementation | **System-level** |
| F: Presentation | Missing examples | **Prompt-level** |
| G: Over-splitting | Architectural limitation | **System-level** |
| H: Future Features | New capabilities | **System-level** |

---

## Theme A: Base Filtering

BaseFilterAgent is inconsistently applying filters — sometimes too restrictive (eliminating valid respondents), sometimes not restrictive enough, and sometimes applying filters where none should exist.

### Problem Examples

| Table | Issue | Our Base | Joe's Base |
|-------|-------|----------|------------|
| A5 | Over-filtered to zero | 0 | 123 |
| A6 | Over-filtered (hypothetical question) | 138 | 180 |
| A9 | Under-filtered | — | — |
| A4a | Base definition mismatch | 131 | 142 |

**A5**: Our filter was so restrictive it eliminated everyone. The agent wrote an overly complex expression with strict NA checks that created an impossible condition.

**A6**: Filter applied where none exists in the survey. A6 is a hypothetical scenario question ("Assume the FDA decides...") which should be asked to ALL respondents. The agent inferred skip logic from question content rather than actual survey programming.

**A9**: Opposite problem — BaseFilterAgent is NOT applying enough filtering when it should be.

**A4a**: Different base sizes (131 vs 142), but both datasets sum to 100%. This is a base definition issue, not a calculation error.

### Root Cause Analysis

The BaseFilterAgent made two distinct types of errors:

1. **Invented a filter where none was specified** (A6) — The agent saw question content about specific products and inferred that only users of those products should be asked. But there was no explicit `[ASK IF]` or `[SHOW IF]` instruction.

2. **Over-engineered an explicit filter** (A5) — The survey clearly said `ASK IF PRESCRIBING IN A4 is > or < A3`. This IS an explicit filter. But the agent wrote an overly complex expression with strict NA checks that created an impossible condition.

### Recommended Fix

**Location**: `src/prompts/basefilter/production.ts` — Add to `<decision_framework>` before Step 1

```markdown
FOUNDATIONAL PRINCIPLE: DON'T INVENT FILTERS

Your job is to find and implement EXPLICIT skip/show/ask logic from the survey.
You are NOT inferring whether a filter should exist — you are finding filters that DO exist.

Use the survey's conventions as your guide:
- If other questions in this survey have explicit [ASK IF], [SHOW IF], or base instructions,
  and this question does NOT, that's intentional. The designer chose not to filter it.
- Question content (topics, products, behaviors mentioned) is NOT evidence of a filter.
  A question can discuss specific products without being filtered to users of those products.
- Ranking questions, hypothetical scenarios, and future-intent questions are often asked
  to everyone. Don't assume they need filters based on current behavior.

The only inference you make: When an explicit filter EXISTS, does it apply at the
table level or the row level? You do NOT infer whether a filter should exist.
```

**Location**: Add to `<decision_framework>` after the foundational principle

```markdown
REMEMBER: NA FILTERING IS ALREADY DONE

The default base calculation is: banner cut + non-NA values.
This means respondents with NA (not answered, not applicable, not shown) are ALREADY excluded.

Your `additionalFilter` adds constraints ON TOP of this default. You are not reimplementing
the default — you are adding further restrictions when the survey specifies them.

DO NOT add `!is.na(variable)` checks to your filters. That's redundant.
If a respondent has NA for the question, they're already excluded from the base.
```

**Location**: Add to `<r_expression_syntax>` section

```markdown
WRITING CLEAR FILTERS:

Before writing any filter expression, restate the intent in plain language:
- "ASK IF Q4 > or < Q3" → "Ask only if Q4 differs from Q3"
- "SHOW IF aware of brand" → "Show only to those who selected 'aware' at the awareness question"

Then write the simplest expression that captures that intent.

AVOID over-engineering:
- NA is already filtered by default — don't add !is.na() checks
- Don't create complex boolean logic when a simple comparison suffices
- If your filter has more than 2-3 conditions joined by & or |, step back and ask
  if you're overcomplicating the intent
```

---

## Theme B: Redundant NETs

Multiple instances of NETs that equal 100% or are structurally uninformative. This should be a clear guardrail: **never emit a NET that equals 100%**.

### Problem Examples

| Table | Issue |
|-------|-------|
| S2B | `Clinicians (NET)` = 100% (all respondents are clinicians) |
| S5 | Every affiliation = 0%, `None of these` = 100% (degenerate screener) |
| S8 | `Treating patients >=70% (NET)` = 100% (qualification criterion) |
| A7 | NET sums to 100% |

### Root Cause Analysis

The VerificationAgent creates NETs based on logical groupings without considering whether they'll be meaningful. It created NETs for:
- Characteristics all respondents share by study design
- The inverse of "None of these" in screener questions
- Answer options that include terminate criteria

### Recommended Fix

**Location**: `src/prompts/verification/alternative.ts` — Add to `<constraints>` as a RULE

```markdown
10. AVOID TRIVIAL NETs
    Before creating a NET, use the survey to ask: "Will this NET be ~100% or ~0%?"

    Signs a NET will be trivial:
    - It rolls up answer options where all but one has a TERMINATE instruction
    - It captures a characteristic all respondents share by study design
    - It's the inverse of a "None of these" option in a screener/exclusion question

    If a NET would be trivial, don't create it. Instead, look for meaningful
    sub-groupings within the answer options that would show actual variation.
```

---

## Theme C: Missing Rollups

The flip side of Theme B — cases where we WANT NETs that add insight, not trivial ones.

### Problem Examples

| Table | Missing Rollup |
|-------|----------------|
| S3a | `Specialized Cardiologist (Total)` grouping Interventional + Preventative |
| A2b | `Recommend a Statin First (Total)` grouping two statin-first options |

### Root Cause Analysis

The agent explicitly decided "no NETs needed" for categorical questions because they weren't scale questions. The scratchpad shows: "Labels verified... no NETs or T2B (not a scale)."

The prompt's NET guidance focuses on same-variable NETs (combining scale values) and multi-variable NETs (combining binary variables). It doesn't address **conceptual groupings** in categorical questions where labels imply natural umbrella categories.

### Recommended Fix

**Location**: `src/prompts/verification/alternative.ts` — Expand `TOOL 2: NET ROWS`

```markdown
TOOL 2: NET ROWS

WHEN TO USE: Categorical questions where logical groupings add analytical value

THREE TYPES OF NETs:

A. SAME-VARIABLE NETs (single variable, combined scale values)
   Use when answer options on a scale should be grouped.
   Example: satisfaction scale values 4,5 → "Satisfied (T2B)"

B. MULTI-VARIABLE NETs (multiple binary variables summed)
   Use for multi-select questions where you want "Any of X" rollups.
   Example: combining Teacher1, Teacher2, SubTeacher → "Any teacher (NET)"

C. CONCEPTUAL GROUPING NETs (categorical with implied hierarchies)
   Use when categorical answer options suggest natural umbrella categories,
   even if not explicitly stated in the survey.

   LOOK FOR THESE PATTERNS:

   Pattern 1: "General" vs "Specific" distinctions
   - Answer options include one broad/general category and multiple specific variants
   - Example: "General Practitioner" vs "Cardiologist," "Neurologist," "Oncologist"
   - Create: "Specialist (Total)" combining the specific variants

   Pattern 2: Shared prefix/suffix indicating family
   - Answer options share naming patterns suggesting they belong together
   - Example: "Full-time employee," "Part-time employee" vs "Contractor," "Consultant"
   - Create: "Employee (Total)" and "Non-Employee (Total)"

   Pattern 3: Conceptually opposite or complementary groups
   - Answer options can be grouped by conceptual similarity
   - Example: Multiple "Option A first" approaches vs one "Option B first" approach
   - Create: "Option A First (Total)" to highlight the conceptual split

   IMPLEMENTATION:
   { "variable": "Q5", "label": "Broad Category (Total)", "filterValue": "1,3,4", "isNet": true, "indent": 0 },
   { "variable": "Q5", "label": "Specific Type A", "filterValue": "1", "indent": 1 },
   { "variable": "Q5", "label": "Specific Type B", "filterValue": "3", "indent": 1 },
   { "variable": "Q5", "label": "Specific Type C", "filterValue": "4", "indent": 1 },
   { "variable": "Q5", "label": "Other Category", "filterValue": "2", "indent": 0 }

   RULE: Only create conceptual NETs when the grouping is OBVIOUS from the labels.
   Don't invent groupings that aren't clearly implied by the answer text.
   If you're uncertain whether a grouping makes sense, don't create the NET.
```

---

## Theme D: Binning & Distribution

VerificationAgent lacks distribution context when choosing bins, leading to inconsistent or suboptimal binning decisions.

### Problem Examples

| Table | Issue |
|-------|-------|
| S6_DIST | Bins (3-5, 6-10, 11-15...) lack interpretable cut points vs Joe's (≤15 vs >15) |
| S10_BINNED | Agent chooses bins without knowing actual response distribution |
| S10 | Missing "mean excluding outliers" (we used to show this) |
| S12 | Missing binned distribution + useless NET |

### Root Cause Analysis

| Sub-issue | Fix Category |
|-----------|--------------|
| D1, D2 (binning choices) | System-level (pass distribution data to agent) |
| D3 (trimmed mean) | System-level (reintroduce trimmed mean) |
| D4 (missing binned distribution) | Prompt-level (one-shot example) |

### Recommended Fix

#### System-Level Changes

**Change 1: Pass distribution data to VerificationAgent**

For mean_rows questions, calculate actual distribution stats from the data and pass to the agent:
```typescript
meta: {
  distribution: {
    min: 50,
    max: 1200,
    mean: 245,
    median: 175,
    q1: 100,
    q3: 350
  }
}
```

This lets the agent create sensible bins based on where the data actually falls, not guesses.

**Implementation**: Add a pre-processing step (in TableGenerator or a new stats calculator) that reads the data CSV, calculates stats for numeric variables, and includes them in the table's meta field.

**Change 2: Reintroduce trimmed mean**

Add "Mean (excluding outliers)" back to numeric question output:
- Calculate using IQR rule or percentile trim
- Include in the distribution data passed to VerificationAgent
- Render in Excel output

#### Prompt-Level Change

**Location**: `src/prompts/verification/alternative.ts` — Add one-shot example to `TOOL 5: BINNED DISTRIBUTIONS`

```markdown
FREQUENCY DISTRIBUTIONS FOR MEAN QUESTIONS:

For mean_rows questions, consider creating a frequency distribution alongside the mean.
This shows HOW MANY respondents fall into each range, not just the average.

A common pattern: None / Any / Above threshold

Example for "How many patients did you prescribe X to last month?":
- None (0): What % prescribed to zero patients?
- Any (1+): What % prescribed to at least one?
- Above median (e.g., 15+): What % are high-volume prescribers?

This turns a single mean into an actionable distribution.

If distribution data is available in the table's meta field (min, max, median, quartiles),
use it to choose meaningful thresholds for your bins.
```

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
1. Add "Don't Invent Filters" foundational principle
2. Add "NA Filtering is Already Done" reminder
3. Add "Writing Clear Filters" guidance

**VerificationAgent (`src/prompts/verification/alternative.ts`):**
1. Add Rule 10 (no trivial NETs)
2. Expand TOOL 2 with conceptual grouping NETs
3. Expand TOOL 5 with binning heuristics
4. Add `<presentation_patterns>` section

### Phase 2: System Changes (Requires Code)

| Change | Files Affected | Complexity |
|--------|----------------|------------|
| Fix fake mean significance testing | `src/lib/r/RScriptGeneratorV2.ts` | Medium |
| Reintroduce trimmed mean | `src/lib/r/RScriptGeneratorV2.ts` | Medium |
| Pass distribution data to agent | TableGenerator, VerificationAgent | Medium |
| Stat testing configurability | Pipeline config, R generation | High |