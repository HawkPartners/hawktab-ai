# HawkTab AI Improvement Plan

## Overview

This document consolidates feedback from comparing our pipeline output against Joe's reference tabs for the Leqvio Monotherapy Demand study (NOV217). Feedback is organized by theme to enable systematic problem-solving.

**Source**: `outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-02-01T05-49-17-899Z/feedback.md`

---

## Part 1: Reorganized Feedback by Theme

### Theme A: Base Filtering Calibration (High Priority)

BaseFilterAgent is inconsistently applying filters — sometimes too restrictive (eliminating valid respondents), sometimes not restrictive enough, and sometimes applying filters where none should exist.

---

#### A1. Over-filtering to zero — A5 (0 respondents vs Joe's 123)

**Table**: `A5` — "How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?"

**Problem**: Our filter was so restrictive it eliminated everyone.
- **Our base**: 0 ("Those whose prescribing for Leqvio, Repatha or Praluent in A4 differed from their responses in A3")
- **Joe's base**: 123 ("Those who changed their PCSKi prescribing after the new indication for uncontrolled LDL-C")
- **Our data**: All 0%
- **Joe's data**: Within 3 months 53%, 4-6 months 28%, 7-12 months 15%, Over a year 5%

**Likely cause**: BaseFilterAgent interpreted "differed from A3" too literally, computed the diff incorrectly, or the table failed during R execution.

**Investigation needed**:
- Check if this table failed during R validation/execution
- Review scratchpad for A5 to see BaseFilterAgent's reasoning
- Compare our filter expression to what would correctly identify "changers"

---

#### A2. Over-filtering on hypothetical questions — A6 (138 vs Joe's 180)

**Table**: `A6` ranking questions (treatment paths)

**Problem**: Filter applied where none exists in the survey.
- **Our base**: 138 ("Shown this question")
- **Joe's base**: 180 (Total HCPs)
- **Our data**: 68% for "Start statin first, add/switch to ezetimibe or Nexletol/Nexlizet if needed"
- **Joe's data**: 52% for same option

**Math check**: 68% × 138 ≈ 94 respondents. 94 ÷ 180 = 52%. Underlying counts match — we're dividing by wrong base.

**Survey confirms no skip logic**: A6 is a hypothetical scenario question:
- "Again, please assume that the FDA decides that all PCSK9 inhibitors... will now be indicated for use..."
- "For your NEXT 100 patients with uncontrolled LDL-C..."
- Hypothetical questions are asked to ALL respondents, not filtered by actual prescribing behavior.

**Root pattern**: Agent is being "too smart" — inferring skip logic from question content rather than actual survey programming. This is the key insight: **hypothetical/scenario questions don't have skip logic**.

**Fix direction**: Prompt guidance distinguishing:
- **Actual behavior questions**: "How many did you prescribe?" → may have skip logic
- **Hypothetical/scenario questions**: "Assume X... what would you do?" → typically asked to everyone

---

#### A3. Under-filtering — A9 tables

**Table**: `A9` family

**Problem**: Opposite of A5/A6 — here BaseFilterAgent is NOT applying enough filtering when it should be.

**Pattern note**: BaseFilterAgent calibration is inconsistent across tables:
- A5: over-filtered to 0 respondents
- A6: over-filtered (138 vs 180)
- A9: under-filtered (not enough)

**Investigation needed**:
- Trace BaseFilterAgent scratchpad for A9
- Compare our base to Joe's base
- Understand what filter should have been applied

---

#### A4. Base definition discrepancy — A4a (131 vs Joe's 142)

**Table**: `A4a_leqvio` — "For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy..."

**Problem**: Different base sizes, but both datasets sum to 100%.
- **Our base**: 131 ("Those who indicated they would prescribe Leqvio to at least one of the NEXT 100 patients")
- **Joe's base**: 142 ("Those who would prescribe any of their next 100 patients on this therapy")
- **Our data**: 42.10% / 57.90% (sums to 100%)
- **Joe's data**: 42.8% / 57.2% (sums to 100%)

**Why this is different**: Both sum to 100%, so this is a **base definition issue**, not a calculation error.

**Key question**: Why does Joe include 142 respondents and we include 131?
- Different interpretation of the qualifying condition?
- Joe including respondents we filtered out (or vice versa)?
- A Joe-specific quirk?

**Interesting**: `A4b` bases match (both 135). Something specific happened in A4a filtering.

**Scope**: This family (A3a, A3b, A4a, A4b) shares similar structures. Need systematic investigation.

**Architectural implications**: May push toward:
- Code-execution agent approach for validating splits programmatically
- Few-shot examples for BaseFilterAgent showing these cases
- More explicit base definition logic

---

### Theme B: Redundant/Useless NETs (Guardrail Needed)

Multiple instances of NETs that equal 100% or are structurally uninformative. This should be a clear guardrail: **never emit a NET that equals 100%**.

---

#### B1. 100% NET in S2B

**Table**: `S2B` — "What is your primary role?"

**Problem**: Agent created a `Clinicians (NET)` row that equals **100%**, which is redundant/useless.
- Our `S2B`: `Clinicians (NET)` shows **100%** (base 162), while underlying rows are Physicians 93%, NP 3%, PA 4%, Other 0%

**Expected**: Instead of a 100% net, create meaningful group nets:
- `Physicians (NET)` = Physicians
- `Advanced Practice Providers (NET)` = Nurse Practitioner + Physician's Assistant

**Note**: `S2` correctly includes these meaningful nets. Logic is inconsistent across similar questions.

---

#### B2. Degenerate table with no variation — S5/ES5

**Table**: `S5` — "Are you or any member of your family currently employed by..."

**Problem**: Table provides no useful information. Every affiliation option is **0%** and `None of these` is **100%** (NET is 0%).

**Expected**: If data/terminate criteria imply a degenerate table (all 0s except single 100%), we should **exclude** the table or move it to "Excluded/Not informative" section with an audit note.

**Same root issue**: Terminate/screener logic forces the distribution. Agent isn't checking for "informational value" (variance).

---

#### B3. Impossible bins from qualification — S8_TREATING_DISTRIBUTION

**Table**: `S8_TREATING_DISTRIBUTION` — "What percent of your professional time is spent performing each of the following activities?"

**Problem**: Multiple issues:
- NET `Treating/Managing patients (>=70% of time) (NET)` is **100%** (because it's a qualification criterion) — not informative
- Includes bins that are structurally impossible given the qualifier (0–19%, 20–49%, 50–69%) which show **0%** because those respondents were screened out, not because no one chose them

**Expected**:
- Don't show forced/trivial nets (100% because of a qualifier)
- Don't show bins impossible due to qualification logic; show only valid range (70–79%, 80–100%) or include audit note

**Fix direction**: When a question is used as a qualification criterion, automatically:
- Suppress the "qualified" NET if it will be 100%
- Hide or label bins outside the allowed range as N/A

---

#### B4. 100% NET in A7

**Table**: `A7`

**Problem**: NET sums to 100% — adds no information.

**This is the 4th+ instance of this pattern.** Clear guardrail needed.

---

### Theme C: Missing Meaningful Rollups/NETs (Enhancement)

The flip side of Theme B — cases where we WANT NETs that add insight, not trivial ones.

---

#### C1. Missing rollup in S3a — "Specialized Cardiologist (Total)"

**Table**: `S3a` — "What type of Cardiologist are you primarily?"

**Problem**: We list only raw categories without a helpful rollup NET/Total or hierarchical indentation.

**Expected**: Create a rollup reflecting the conceptual split:
- `General Cardiologist` (57%)
- `Specialized Cardiologist (Total)` (43%), with indented components:
  - `Interventional Cardiologist` (34%)
  - `Preventative Cardiologist` (9%)

This matches Joe's organization and improves readability.

**Likely cause**: Agent isn't reliably inferring "useful abstract rollups" from labels (General vs Specialized).

**Fix direction**: Prompt/guardrail: when labels imply a natural umbrella category (e.g., "general" vs multiple "specialized" types), create a `(... Total)` rollup and indent components.

---

#### C2. Missing meaningful NET in A2b — "Statin First (Total)"

**Table**: `A2b` — "Which of these best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?"

**Data accuracy**: ✅ Correct (66%, 32%, 2% match)

**Problem**: Joe adds a meaningful NET we don't:
- **Joe's approach**:
  - `Recommend a Statin First (Total)` → 98%
    - `Recommend a statin first, add or switch to ezetimibe if needed...` → 66%
    - `Recommend a statin + ezetimibe first...` → 32%
  - `Recommend a PCSK9i first` → 2%
- **Our approach**: Three flat rows without the "Statin First" rollup

**Fix direction**: Prompt guidance to identify conceptual groupings in answer options and create rollup NETs when they add value (not when they'd be trivial/100%).

---

### Theme D: Binning & Distribution Intelligence

VerificationAgent lacks distribution context when choosing bins, leading to inconsistent or suboptimal binning decisions.

---

#### D1. Binning cutoffs need clearer guidance — S6_DIST

**Table**: `S6_DIST` — "How many years have you been in clinical practice, post residency/training?"

**Problem**: Our bins (3–5, 6–10, 11–15, 16–20, 21–25, 26–30, 31–35) aren't wrong, but inconsistent with Joe's more readable structure:
- `15 Years or Less Time (Total)` → `3–9` and `10–15`
- `More Than 15 Years (Total)` → `16–25` and `26–35`

**Root issue**: No consistent strategy for how to pick bins. Agent defaults to "even-ish bins across full range" rather than interpretable cut points.

**Fix direction**:
- Prompt guidance: choose a small number of bins (4–6), favor interpretable cut points (5/10/15/20 years) for experience/tenure questions
- Create rollups (≤X vs >X) when there's a natural breakpoint

---

#### D2. Data-informed binning needed — S10_BINNED

**Table**: `S10_BINNED` — "How many adult patients, age 18 or older, do you personally manage in your practice in a month?"

**Problem**: Agent chooses bins without knowing actual response distribution. Bins may be fine but not as helpful as they could be, and may vary across runs.

**Our bins**: `50–99`, `100–199`, `200 or more (NET)`, `200–299`, `300–499`, `500+`
**Joe's bins**: More tailored set reflecting actual distribution: `50–200`, `201–250`, `251–399`, `400–499`, `500–699`, etc.

**Fix direction**:
- Add lightweight "distribution summary" input for numeric questions (min/max, median, quartiles, percentiles)
- Or: deterministic post-processing step that adjusts bins based on actual distribution, then rerenders

---

#### D3. Missing "mean excluding outliers" — S10

**Table**: `S10` (same question)

**Problem**: We show mean/median/std dev but no longer show **mean excluding outliers** (we used to).

**Expected**: Include both:
- Mean (overall)
- Mean (excluding outliers) with clear, consistent definition

**Fix direction**: Reintroduce trimmed/winsorized mean line with explicit method (e.g., percentile trim or IQR rule), record method in metadata.

---

#### D4. Missing binned distribution + useless NET — S12

**Table**: `S12` — "Of those, how many patients have had an event (MI, CAD, coronary revascularization, etc.)"

**Problem**: Multiple issues:
1. **Useless NET**: "Total patients with an event (NET)" at 147.70 isn't informative
2. **Missing binned distribution**: Joe provides numeric binned distribution for "Within the Last Year":
   - `15 or Fewer (Total)` → 1-5, 6-15
   - `More Than 15 (Total)` → 16-25, 26-99, 100+
3. **Missing summary stats**: Joe includes Mean (overall), Mean (minus outliers), Median

**Expected**: For numeric sub-questions, provide binned distributions with rollups and summary stats.

---

### Theme E: Calculation & Statistical Accuracy

Core accuracy issues that affect trust in the output.

---

#### E1. Stat testing alignment & configurability

**Scope**: General (affects many tables)

**Problem**: Our significance callouts don't always match Joe's. Users will notice, and we need an auditable explanation.

**Joe's workbook footnote** (this study):
- Comparison Groups: `CPO/PA/HL/1234/YN/AC`
- Tests: T-test for means, Z-test for percentages
- Significance display: Uppercase letters indicate significance at the 90% level

**Joe's typical process** (from email):
- Default confidence level: HawkPartners = **90% CL** (almost always)
- Exceptions: Some clients (e.g., Jazz) require **95% CL** and/or multiple levels
- Minimum base: **No minimum** — test all cuts, even < 10 (team notes small bases in reporting)
- Test details: Determined by WinCross (tabulation software) including overlap handling

**What we need** (stat testing contract):
- **Default behavior**: Sensible for HawkPartners (90% CL, letters, etc.)
- **Explicit + configurable metadata** at run start (can adapt to exceptions)
- **Explainability**: When results differ, explain exactly why (test choice, overlap handling, weighting, rounding, base handling)

**Investigation tasks**:
- Baseline comparison: Identify tables/cuts where significance differs; document disagreeing cells
- Spec the stat testing contract (CL defaults, lettering, minimum base policy, overlap handling)
- Implementation audit: Confirm what tests we run for percentages and means
- Gap assessment: Which mismatches are fixable vs inherent

---

#### E2. Mean/median mismatch — S11

**Table**: `S11` — "Of those adult patients for whom you are the primary treatment decision maker, roughly how many have a confirmed diagnosis of hypercholesterolemia with established cardiovascular disease (CVD)?"

**Problem**: Our mean and median differ substantially from Joe's despite same base (180).
- **Our output**: Mean 168.00, Median 125.00, Std Dev 133.10
- **Joe's output**: Mean 175.9, Mean (minus outliers) 159.8, Median 150.0
- **Differences**: Mean ~8, Median **25** (125 vs 150)

**Possible causes**:
- Different inclusion/exclusion of certain values (e.g., values below 10)?
- Different handling of outliers or extreme values?
- Different interpretation of raw data or top-coding?
- Note: Survey says "Respondents were required to have at least 10 such patients to qualify" — may affect low-value handling

**Investigation tasks**:
- Compare raw data values we're using vs what Joe might be using
- Check if there's a minimum threshold being applied differently
- Verify our calculation logic for mean/median on this question

---

### Theme F: Visual Presentation & Hierarchy

Presentation improvements that enhance readability without affecting accuracy.

---

#### F1. Indentation defaults are too shallow

**Scope**: General (affects many tables)

**Problem**: Our tables often use only one indentation level, making hierarchical rollups (NET → components) harder to scan.

**Example**: In `S3a`, Joe indents component rows under `Specialized Cardiologist (Total)` while our output presents all rows at same level.

**Fix direction**:
- Make indentation depth a default formatting policy (configurable)
- When creating a Total/NET rollup row, automatically indent component rows more aggressively

---

#### F2. Grouping by shared elements — A1 presentation

**Table**: `A1` — "Which statement below best describes the current indication for each of the following treatments?"

**Data accuracy**: ✅ Correct — percentages match Joe's

**Presentation opportunities**:
1. **Grouping by treatment**: Joe uses treatment names (Leqvio, Praluent, Repatha, Nexletol) as **header rows** with indication options indented beneath. We repeat full "Leqvio (inclisiran): As an adjunct to..." in every row.
2. **Smart label truncation**: Joe truncates repeated text since users can map abbreviated labels. We show full verbatim, which clutters.
3. **Split tables**: Joe produces overview table **plus** separate tables for each indication context. We only produce overview.

These aren't errors — our output is functional and accurate. Polish items for future.

**Fix direction**:
- Prompt guidance: "when rows share a common prefix (e.g., treatment name), factor it out into a header row"
- Guidance for smart truncation when verbatim labels repeat known context
- Split-table generation could be future enhancement

---

#### F3. Factor out common prefix — A2a

**Table**: `A2a` — "Which of these best describes the current post-ACS guideline recommendation regarding lipid-lowering?"

**Data accuracy**: ✅ Correct

**Problem**: All answer options share common prefix: "Recommend a non-statin lipid-lowering agent for patients on maximally tolerated statins with..."

**Joe's approach**: Extracts prefix as header row (no data), shows only differentiating part indented:
- `LDL-C levels >=55 mg/dL` → 58%
- `LDL-C levels >=70 mg/dL` → 36%
- `LDL-C levels >=100 mg/dL` → 6%

**Our approach**: Full verbatim for each row, repeating prefix three times.

**Meta-note**: This pattern (and F2) could become **few-shot examples** showing how to creatively organize tables for readability.

---

#### F4. Multiple hierarchy and ordering issues — A3

**Table**: `A3` — "For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies?"

**Data accuracy**: ✅ Correct (means match Joe's)

**Issues**:

1. **Frequency distributions from means**: Joe creates binned distributions for each therapy (`None (0)`, `Any (1+)`, `25 or more`). This turns mean data into more actionable frequency info. Could be a few-shot example pattern.

2. **NET hierarchy is awkward**: Our "Any PCSK9 inhibitor (NET)" at the bottom looks visually odd. Should be indented under components or positioned to show relationship. Concept of "NETs under NETs" — hierarchical rollups — isn't well-supported.

3. **Logical ordering within table**: "Statin only" should probably appear above "Any add-on therapy" to separate conceptual groups (monotherapy vs add-on).

4. **Consistent row ordering across questions**: Joe maintains consistent order: Statin, Leqvio, Praluent, Repatha, Zetia, Nexletol, Other. **Why it matters**: Users copy data across questions for side-by-side comparison. Consistent order means rows align when pasted. **Guidance**: Default to datamap ordering unless there's a strong reason to reorder. Stability > optimization.

---

### Theme G: Table Generation Scope

Over-splitting creates too many tables; missing split tables lose useful views.

---

#### G1. Over-splitting tables — A3a, A3b, A4a `_situation_brand` pattern

**Tables affected**:
- `A3a_brand` ✅ good — shows both situations (with statin / without statin) in one table
- `A3a_situation_brand` ❌ over-split — creates separate tables for each situation, redundant with above
- Same pattern for `A3b_brand` → `A3b_situation_brand`
- Same pattern for `A4a_brand` → `A4a_situation_brand`

**Problem**: Combined `_brand` tables are informative and sufficient. Then we also generate `_situation_brand` tables that split by situation, adding median/std dev but creating redundancy.

**Why it matters**: This is why our output has **WAY more tables than Joe's**. The over-splitting bloats the workbook.

**Trade-offs** (user is torn):
- ✅ Split tables do technically add new info (median, std dev)
- ❌ HawkPartners doesn't report much on median/std dev
- ❓ Other firms (Antares, etc.) might want this detail
- ❓ Future feature (exclude/keep toggle) would let users remove unwanted tables

**User's lean**: Probably don't over-split by default, since combined table is usually sufficient. But not a hard rule.

**Fix direction**: Prompt guidance to prefer combined tables over split-by-situation tables when combined version already shows comparison. Only split when it adds substantial value.

---

### Theme H: Future Features (Not MVP)

Not blocking for Feb 16 deadline, but worth tracking.

---

#### H1. Pre/Post comparison tables

**What Joe does**: Creates pre/post comparison tables spanning multiple questions (A3 vs A4, A3a vs A4a, A3b vs A4b comparisons) with "Mean difference (pre- vs post)" calculations.

**What we produce**: Separate tables for pre (A3) and post (A4) questions.

**Why NOT blocking**:
- Analyst can derive comparison themselves — see pre table, see post table, calculate difference
- Antares' existing tools don't produce these either
- Our output already exceeds what Antares can do (meaningful NETs, rollups, derived tables)

**Future enhancement**: Detect pre/post pairs (LAST 100 vs NEXT 100), pass paired context to VerificationAgent, instruct to create comparison tables in addition to separate tables.

---

#### H2. Selectable Excel color themes

**Problem**: We have effectively one styling look-and-feel. Users want flexibility in workbook color palette while preserving readability and visual hierarchy.

**Expected**: Offer 4+ curated color themes (templates) that users select at run start. Themes should:
- Preserve semantics (header fill, alternating row fill, banner column separation, emphasis rows)
- Maintain contrast and readability
- Be consistent across workbook

**Tasks**:
- Map current color usage to semantic roles
- Define 4+ palettes that plug into those semantic roles
- Expose theme selector (config / run metadata)

---

#### H3. Interactive browser-based review

**Context**: While reviewing over-split tables, user noted current workflow is inefficient:
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

**Timeline**: NOT MVP (Feb 16 deadline), but worth memorializing.

---

## Part 2: Implementation Priorities

*To be filled in after discussing solutions with Jason.*

---

## Appendix: Joe's Email (Verbatim)

> Hi Jason,
>
> Nice to hear from you. I hope you had a nice holiday season.
>
> To answer your questions, almost all HawkPartners studies are done at a 90% confidence level -- that is the default. I really don't know why that's the case -- it started a LONG(!) time ago. The one notable exception are studies for Jazz Pharmaceuticals who want their projects stat-tested at 95% CL and/or any other study where the team informs me that they want different or multiple confidence levels.
>
> There is no minimum base for stat-testing as many of the HCP studies have only a hundred or so respondents so some of the subgroups get into the single digits. So stat-testing is done on all data cuts, even those with <10. I believe that you and your colleagues make note of this in your reports/slides.
>
> The tabulation software (which you can review here: http://www.analyticalgroup.com/wincross.html) determines the appropriate method of stat-testing -- including overlap handling, etc. As I'm not a statistician to determine the correct stat-test, I appreciate this feature of the tabulation software. I believe there is a detailed explanation of the stat-testing within the Wincross website.
>
> Please let me know if you have any other questions.
>
> Happy 2026,
> Joe
