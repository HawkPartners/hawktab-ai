# Reliability Plan

## Overview

This plan tracks the work to make HawkTab AI reliably produce publication-quality crosstabs that match partner expectations (using Joe's output as the reference standard).

**Philosophy**: We're replacing Joe's usefulness (the manual work of generating crosstabs), not necessarily replicating his exact format. Antares-style output is our MVP target - functional, readable crosstabs that the team can write reports from.

**Current State**: Pipeline working end-to-end. Full test run completed against primary dataset (`leqvio-monotherapy-demand-NOV217`).

**What We're Validating**: Each part involves comparing our output to Joe's tabs for both:
- **Data accuracy** - counts, percentages, means, bases match
- **Significance testing** - letters appear on the correct cells

---

## Part 1: Bug Capture

**Status**: COMPLETE

Review the primary test output against Joe's tabs. Capture all differences in the session's `bugs.md` file.

**Test Run Location**: `temp-outputs/test-pipeline-leqvio-monotherapy-demand-NOV217-<timestamp>/`

**Process**:
1. Open `results/crosstabs.xlsx` and Joe's reference tabs side-by-side
2. Compare table-by-table, cell-by-cell where needed
3. Log issues in `bugs.md` under appropriate category:
   - Data Accuracy Issues (numbers don't match)
   - Formatting/UX Issues (presentation differences)
4. For each issue, note: what we produce vs what's expected, which component likely responsible

**Key Files**:
- `bugs.md` - Issue tracker for current test run
- `results/crosstabs.xlsx` - Our output
- `results/tables.json` - Raw R calculations
- `scratchpad-*.md` - Agent reasoning traces

**Exit Criteria**: All significant differences documented and categorized.

---

## Part 2: VerificationAgent

**Status**: COMPLETE

VerificationAgent has been implemented with the following capabilities:
- Survey-aware label cleanup
- Table restructuring decisions
- NET/roll-up row identification
- Low-value table flagging
- Per-agent environment configuration (model, tokens, reasoning effort)

**Test Output Location**: `temp-outputs/test-verification-agent-*/`

**Implementation Details**:
- `src/agents/VerificationAgent.ts` - Core agent implementation
- `src/schemas/verificationAgentSchema.ts` - Output schema with extended row types
- `src/lib/processors/SurveyProcessor.ts` - DOCX → Markdown conversion
- Environment variables: `VERIFICATION_MODEL`, `VERIFICATION_MODEL_TOKENS`, `VERIFICATION_REASONING_EFFORT`, `VERIFICATION_PROMPT_VERSION`

### What It Does

The VerificationAgent is the first agent in the pipeline that sees the actual survey document. This gives it unique capabilities that earlier agents lack.

**Position in Pipeline**:
```
TableAgent (group) → VerificationAgent (same group) → next group...
                            ↓
                     Survey Document (markdown)
```

**Inputs**:
- TableAgent output for current group (table definitions)
- Survey document converted to markdown
- DataMap context (variable metadata)

**Capabilities** (expanded from original scope):

| Capability | Description |
|------------|-------------|
| **Label Cleanup** | Replace generic labels ("Value 1") with survey text ("Not at all likely") |
| **Scale Anchors** | Add scale definitions to labels (e.g., "1 = Not at all likely, 5 = Extremely likely") |
| **Table Restructuring** | Decide if tables should be split or combined based on survey structure |
| **NET/Roll-up Rows** | Identify when roll-up rows are appropriate and add them |
| **Low-Value Flagging** | Flag tables that may not add value (100% response, etc.) |
| **Skip Logic Validation** | Cross-reference against survey skip logic |

**Cannot Change** (data integrity preserved):
- Variable names (SPSS column references)
- Filter value codes (data mappings)
- Calculated values (counts, percentages, means)
- Core table structure from R output

**Outputs**:
- Survey-optimized table definitions
- Confidence score per table
- Change log (what was modified and why)

### Technical Approach

**SurveyProcessor**: New utility to convert DOCX/PDF survey documents to markdown for agent consumption.

**Processing Pattern**: Same group-by-group pattern as TableAgent:
```typescript
for (const group of questionGroups) {
  const tableOutput = await runTableAgent(group);
  const verifiedOutput = await runVerificationAgent(tableOutput, surveyMarkdown);
  results.push(verifiedOutput);
}
```

**Graceful Fallback**: On error, return original TableAgent output unchanged.

### What This Solves (from bugs.md)

- Separate tables per treatment (restructuring decision with survey context)
- Multi-dimensional scale questions (needs survey to understand structure)
- NET/Roll-up rows (survey shows when roll-ups are appropriate)
- Hide low-value tables (100% response questions)
- Label improvements with actual survey text

---

## Part 3: Significance Testing

**Status**: COMPLETE

Our significance testing differs from Joe's WinCross output. Two fixes needed.

### Context from Joe

Joe confirmed HawkPartners' significance testing practices (January 2026):

> "Almost all HawkPartners studies are done at a 90% confidence level -- that is the default."

> "There is no minimum base for stat-testing as many of the HCP studies have only a hundred or so respondents so some of the subgroups get into the single digits. So stat-testing is done on all data cuts, even those with <10."

> "The tabulation software determines the appropriate method of stat-testing -- including overlap handling, etc."

**Key insight**: Joe uses WinCross defaults. WinCross does NOT auto-select test methods - the user selects the test type, and the default is **unpooled independent z-test** with no minimum sample size.

### Changes Needed

| Parameter | Current | WinCross Default | Action |
|-----------|---------|------------------|--------|
| Z-test Formula | Pooled | **Unpooled** | Fix required |
| Min Sample Size | n < 5 → NA | No minimum | Fix required |
| Confidence Level | 90% | 90% | No change |
| T-test | Welch's | Welch's | No change |

### Implementation

Two changes in `src/lib/r/RScriptGeneratorV2.ts`:

1. **Switch to unpooled z-test formula**:
   - Current: `SE = sqrt(p_pool * (1-p_pool) * (1/n1 + 1/n2))`
   - New: `SE = sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)`

2. **Remove n<5 hard block**: Delete the line that returns NA for small samples

That's it. No configuration schemas, no optional features.

### Validation

1. Run `npx tsx scripts/test-pipeline.ts` on primary dataset
2. Compare significance letters to Joe's output
3. If they match, Part 3 is complete

**Detailed Plan**: See `docs/implementation-plans/significance-testing-plan.md`

---

## Part 3b: SPSS Validation Clarity

**Status**: COMPLETE

### The Problem

Current SPSS validation logs show scary-looking mismatches that are actually expected:

```
- 1 variables in datamap missing from SPSS file
- 2 variables in SPSS file not documented in datamap
```

Users may think something is wrong when it's actually fine. The mismatches are explainable:
- `834_flag` → `x834_flag` (SPSS can't start variable names with numbers)
- `region_dupe1` (SPSS duplicate column not in datamap)

### The Solution: Categorize & Explain

Use a waterfall approach to categorize each mismatch:

```
All Mismatches
    │
    ▼
┌─────────────────────────────────┐
│ Try x-prefix: "x" + varName     │  → Found? → "SPSS numeric-start naming"
└─────────────────────────────────┘
    │ remaining
    ▼
┌─────────────────────────────────┐
│ Try dupe pattern: *_dupe*       │  → Found? → "SPSS duplicate column"
└─────────────────────────────────┘
    │ remaining
    ▼
┌─────────────────────────────────┐
│ Try case-insensitive match      │  → Found? → "Case mismatch (harmless)"
└─────────────────────────────────┘
    │ remaining
    ▼
┌─────────────────────────────────┐
│ Whatever's left = UNEXPECTED    │  → Flag for user attention
└─────────────────────────────────┘
```

### New Log Output

```
SPSS Validation Complete:
- Matched 191/192 variables (99%)

Explained differences:
  • 834_flag ↔ x834_flag (numeric-start naming convention)
  • region ↔ region_dupe1 (duplicate column)

Unexpected differences: 0

✓ All differences resolved - data is consistent
```

### Implementation

**File**: `src/lib/processors/SPSSReader.ts`

1. Add `categorizeMismatch()` function that tries each pattern
2. Update `generateValidationSummary()` to show categorized output
3. Only flag "Unexpected differences" as needing attention

**Level of Effort**: ~30-60 minutes

### Exit Criteria

- Validation logs show categorized mismatches with explanations
- Users can distinguish "expected SPSS behavior" from "actual problems"
- Zero unexplained mismatches for primary dataset

---

## Part 4: Evaluation Framework + TableAgent Refactor

**Status**: IN PROGRESS

### Background: How We Got Here

We originally planned Part 4 as two phases:
- **Part 4a**: Build golden datasets by manually reviewing current pipeline output
- **Part 4b**: Refactor TableAgent → TableGenerator after golden datasets complete

While building `verification-expected.json`, we discovered repeating failure modes:
- **Grid questions** (A1, A3a, A3b, A4, A4a): TableAgent pre-splits tables, preventing VerificationAgent from creating proper expansions (by-row, by-column, combined views)
- **Ranking questions** (A6): TableAgent creates 4 separate rank tables, preventing combined rank views (top 2, top 3) and by-item views

These failures stem from TableAgent doing work that VerificationAgent should do. Continuing to manually build golden datasets for an architecture we're about to replace is inefficient.

**The pivot**: Build TableGenerator first, update VerificationAgent, run the new pipeline, then use *that* output as the golden dataset baseline.

### What We Accomplished (Original Part 4a)

**Infrastructure: ✅ Complete**
- `scripts/compare-to-golden.ts` - Compares pipeline output to golden datasets
- `scripts/calculate-metrics.ts` - Calculates accuracy metrics from comparison report
- `scripts/extract-data-json.ts` - Extracts streamlined data for golden dataset creation
- Pipeline auto-outputs `data-streamlined.json` alongside `tables.json`

**Golden Datasets: Partial**
| File | Status | Notes |
|------|--------|-------|
| `banner-expected.json` | ✅ Complete | Reviewed and finalized |
| `crosstab-expected.json` | ✅ Complete | Fixed skip logic issues discovered during review |
| `verification-expected.json` | 🔄 Partial | Started manual review, identified repeating failure modes |
| `data-expected.json` | ⏸️ Deferred | Will create after pipeline refactor |

**Failure Modes Identified During Review:**
- A1: 4×2 grid not expanded (7 tables needed, only 1 produced)
- A3a: 5×2 grid not expanded (8 tables needed)
- A3b: 5×2 grid not expanded (8 tables needed)
- A4: 7×2 grid not expanded (10 tables needed)
- A4a: 5×2 grid not expanded (8 tables needed)
- A6: Ranking not expanded (15 tables needed: 4 by-rank + 8 by-item + 3 combined)

These are structural failures in how TableAgent handles multi-dimensional questions.

---

### The Core Insight

TableAgent's "intelligence" is largely deterministic:
1. `normalizedType` → `tableType` mapping (lookup table)
2. Creating rows from datamap items (copy operation)
3. Adding hints like `ranking`, `scale-5` (pattern detection)

The datamap already IS the table definition, just in a different shape. Meanwhile, TableAgent's splitting logic prevents VerificationAgent from doing proper expansion.

**New architecture:**
```
Before: DataMap → TableAgent (LLM) → VerificationAgent (LLM) → R Script
After:  DataMap → TableGenerator (code) → VerificationAgent (LLM) → R Script
```

**Benefits:**
- **Faster** - No LLM call for table generation; enables parallelization of VerificationAgent calls
- **Consistent** - Same input → same output, every time
- **Debuggable** - Fix code, not prompts
- **Cheaper** - One fewer API call per question group

---

### Implementation Phases

#### Phase 1: Build TableGenerator

**Create** `src/lib/tables/TableGenerator.ts`

Deterministic function that converts datamap → overview tables:

```typescript
function generateOverviewTables(dataMap: DataMapQuestion[]): TableDefinition[] {
  return dataMap.map(question => {
    const tableType = question.items[0].normalizedType === 'numeric_range'
      ? 'mean_rows'
      : 'frequency';

    const hints = detectHints(question);

    return {
      tableId: `${question.questionId.toLowerCase()}_overview`,
      questionId: question.questionId,
      title: question.questionText,
      tableType,
      rows: generateRows(question.items, tableType),
      hints
    };
  });
}
```

**Rules:**
- `numeric_range` → `mean_rows`, `filterValue: ""`
- `categorical_select` → `frequency`, one row per value with `filterValue` = value code
- `binary_flag` → `frequency`, `filterValue: "1"`
- Detect hints: `ranking`, `scale-5`, `scale-7`
- One overview table per question (no splitting)

**Metadata to include** (helpful for VerificationAgent):
- `itemCount` - Number of items in question
- `valueRange` - [min, max] for categorical/ranking
- `pattern` - Detected pattern (`ranking`, `grid`, `simple`)

#### Phase 2: Deprecate TableAgent

**Do not delete yet** - keep for reference and fallback testing.

**Deprecate:**
- Mark `src/agents/TableAgent.ts` as deprecated (add comment)
- Mark `src/prompts/table/` as deprecated
- Document which env vars are no longer used: `TABLE_MODEL`, `TABLE_REASONING_EFFORT`, `TABLE_PROMPT_VERSION`, `TABLE_MODEL_TOKENS`

#### Phase 3: Test TableGenerator Independently

Before integrating into pipeline:
1. Run TableGenerator on primary dataset datamap
2. Compare output structure to what TableAgent currently produces
3. Verify: same schemas, correct tableType mapping, proper filterValues
4. Verify: hints are detected correctly (ranking, scale-5, scale-7)

**Test script:** `npx tsx scripts/test-table-generator.ts`

#### Phase 4: Integrate into Pipeline

**Update pipeline orchestration:**
- Replace TableAgent calls with TableGenerator
- Maintain queue-based producer pattern for VerificationAgent compatibility
- Maintain AbortSignal support
- Maintain progress callback contract

**Files to update:**
- `scripts/test-pipeline.ts` - Replace TableAgent with TableGenerator
- `src/app/api/process-crosstab/route.ts` - Replace in `executePathB()` and `executePathBPassthrough()`

**Keep function signatures compatible:**
The API route uses `processQuestionGroupsWithCallback()`. TableGenerator must provide equivalent:
```typescript
// Must maintain this signature for API compatibility
function processQuestionGroupsWithCallback(
  groups: TableAgentInput[],
  onTable: (table: TableDefinition, questionId: string, questionText: string) => void,
  options: { outputDir?, abortSignal?, onProgress? }
): Promise<{ results: TableAgentOutput[]; processingLog: string[] }>
```

#### Phase 5: Update VerificationAgent

VerificationAgent now handles ALL expansion logic.

**Update prompt for new responsibilities:**
- Grid expansion (by-row, by-column views)
- Ranking expansion (by-rank, by-item, combined ranks T1/T2/T3)
- NETs and T2B for scales
- Label enhancement from survey

**Handle long tables:**
- Don't require agent to rewrite large overview tables
- Agent outputs only NEW derived tables
- Pipeline merges original overview with derived tables

**Consider batching:**
- For large expansions (15+ derived tables), consider multiple tool calls
- Or: make expansion deterministic code, LLM only for label enhancement

#### Phase 6: Run Pipeline + Create Golden Dataset

1. Run full pipeline on primary dataset: `npx tsx scripts/test-pipeline.ts`
2. Review output for correctness
3. Copy outputs to golden datasets:
   - `verification-output-raw.json` → `verification-expected.json`
   - `data-streamlined.json` → `data-expected.json`
4. Manual review and corrections
5. Run comparison: `npx tsx scripts/compare-to-golden.ts`

#### Phase 7: Optimize

**Token usage:**
- Measure token consumption per question
- Identify opportunities to reduce prompt size
- Consider caching survey context

**Parallelization:**
- With deterministic TableGenerator, can fan out to N VerificationAgent calls
- Test optimal parallelism (rate limits permitting)
- Potentially dramatic pipeline speedup

---

### TableAgent Integration Points (Reference)

For anyone picking up this work, here's where TableAgent is currently integrated:

| Category | Files | Impact |
|----------|-------|--------|
| **Agent Core** | `src/agents/TableAgent.ts` | Replace with TableGenerator |
| **Schemas** | `src/schemas/tableAgentSchema.ts` | **KEEP** - downstream tools depend on `TableDefinition`, `TableRow` |
| **Environment** | `src/lib/env.ts` | Deprecate `getTableModel()`, `getTableReasoningEffort()` |
| **Prompts** | `src/prompts/table/` | Deprecate (keep for reference) |
| **API Route** | `src/app/api/process-crosstab/route.ts` | Update `executePathB()`, `executePathBPassthrough()` |
| **Pipeline** | `scripts/test-pipeline.ts` | Update Path B execution |
| **Test Scripts** | `scripts/test-table-agent.ts` | Update to test TableGenerator |
| **Logging** | Output files `table/table-output-*.json` | Maintain same structure for compatibility |

**Critical constraint:** `TableDefinition` and `TableRow` schemas must NOT change. R script generator and Excel formatter depend on exact structure.

---

### Golden Dataset Approach (Post-Refactor)

After pipeline refactor, golden datasets are created from the NEW pipeline output:

| Golden File | Source | What It Tests |
|-------------|--------|---------------|
| `banner-expected.json` | `banner-output-raw.json` | Banner agent decisions |
| `crosstab-expected.json` | `crosstab-output-raw.json` | Crosstab agent decisions |
| `verification-expected.json` | `verification-output-raw.json` | **Now includes all expansions** |
| `data-expected.json` | `data-streamlined.json` | Calculated values, significance |

The evaluation framework (scripts, comparison logic, annotation workflow) remains the same.

---

### Exit Criteria

- [ ] TableGenerator produces correct overview tables for all question types
- [ ] TableGenerator maintains API compatibility (function signatures, output schemas)
- [ ] Pipeline runs end-to-end with TableGenerator replacing TableAgent
- [ ] VerificationAgent correctly expands grids and rankings
- [ ] Golden datasets created from new pipeline output
- [ ] At least one full evaluation cycle completed
- [ ] No regression in output quality vs Joe's tabs

---

## Part 5: Iteration (Primary Dataset)

**Status**: NOT STARTED (begins after Part 4 complete)

### What We're Validating

For each table in our output vs Joe's tabs:

| Check | Description |
|-------|-------------|
| **Data Match** | Base n, counts, percentages, means all match |
| **Significance Match** | Letters appear on same cells |
| **Structure Match** | Same tables exist, rows in same order |
| **Labels Acceptable** | Row labels readable and accurate |

### Banner Plan Versions

Three versions of the banner plan exist for each dataset:

| Version | Description |
|---------|-------------|
| **Original** | The actual banner plan document as received |
| **Clean** | Original but with clearer, unambiguous language (no "IF HCP" - explicit variable references) |
| **Adjusted** | Maps to Joe's actual tabs (which may differ from original due to email changes, iterations) |

**Why this matters**: Joe's tabs may not match the original banner plan exactly. To truly validate our output matches Joe's, we need the adjusted version that reflects what Joe actually produced.

**For primary dataset**: Create `leqvio-monotherapy-demand-bannerplan-adjusted.docx` before completing Part 5 iteration.

### Process

1. Create banner-plan-adjusted for primary dataset (if not exists)
2. Re-run `npx tsx scripts/test-pipeline.ts` with adjusted banner
3. Compare output to Joe's tabs (data accuracy + significance letters)
4. Update bugs.md with any new/remaining issues
5. Address issues (prompt tweaks, code fixes)
6. Repeat until primary dataset output matches Joe's tabs

**Success Criteria**:
- Data accuracy matches Joe's tabs (counts, percentages, means)
- Significance letters match Joe's tabs
- Formatting acceptable for partner use
- No blocking issues for report writing

### Data Sampling Validation (due diligence)

As part of Part 5 iteration, validate ~15-20 tables against Joe's tabs to confirm R calculations are correct:

| Category | Tables to Sample | What to Check |
|----------|------------------|---------------|
| Frequency | 3-4 tables | Counts, percentages, significance letters |
| Mean | 3-4 tables | Mean values, base n |
| Ranking | 2-3 tables | Rank counts by position |
| Scale + T2B | 2-3 tables | T2B/B2B roll-ups correct |
| Multi-select | 1-2 tables | Multiple responses counted correctly |

**Also verify:**
- Base (n) consistent for same banner column across different questions
- Total column matches sum/aggregate of subgroups where expected

If sampled tables match, data-expected.json can be considered validated without cell-by-cell review of all 50+ tables.

---

## Part 6: Loop/Stacked Data Support

**Status**: NOT STARTED (begins after Part 5 primary dataset is stable)

### The Problem

Some surveys use **loops** where the same questions are asked multiple times (e.g., about different drinks, brands, or concepts). These appear in the datamap as variables with suffixes like `A13_1`, `A13_2` (same question for iteration 1 and 2).

**Example** (Tito's Future Growth survey):
- `A4_1`: "What type of drink did you have?" (for drink 1)
- `A4_2`: "What type of drink did you have?" (for drink 2)
- `A13_1`: "What brand did you have?" (for drink 1)
- `A13_2`: "What brand did you have?" (for drink 2)

The desired output is a table where **banner columns are loop iterations** (Location 1, Location 2), not respondent subgroups. This lets analysts compare responses across iterations.

### Why It's Not a Rewrite

The core pipeline flow is unchanged. We're adding a **second interpretation** of what a "banner column" means:

| Current (filter-based) | Loop (suffix-based) |
|------------------------|---------------------|
| Column = respondent subset | Column = variable suffix |
| `S2 == 1` filters to cardiologists | `_1` uses Location 1 variables |
| One question runs against multiple filters | Multiple variables (same base) run for one table |

### Implementation Approach

**Step 1: Loop Detection (DataMapProcessor)**

Detect loops deterministically from the datamap:
- Look for variables with matching question text (~90%+ similarity) but different suffixes (`_1`, `_2`, etc.)
- Flag detected loop variables in the verbose datamap output
- Add `isLoop: true` and `loopGroup: "A4"` to loop variables

```typescript
// In datamap-verbose output
{
  "variableName": "A4_1",
  "questionText": "What type of drink did you have?",
  "isLoop": true,
  "loopGroup": "A4",
  "loopIteration": 1
}
```

**Step 2: Banner/Crosstab Handling**

When the banner plan specifies loop iterations (e.g., "Location 1 | Location 2"):
- BannerAgent recognizes this as a loop banner group
- CrosstabAgent outputs variable suffix mappings instead of filter expressions

```json
{
  "groupName": "Location",
  "isLoopBanner": true,
  "columns": [
    { "name": "Location 1", "loopSuffix": "_1" },
    { "name": "Location 2", "loopSuffix": "_2" }
  ]
}
```

**Step 3: R Script Generation**

For loop banners, substitute variable suffixes instead of applying filters:

```r
# Current (filter-based)
subset <- data[data$S2 == 1, ]
table(subset$A13)

# Loop (suffix-based)
# Location 1 column: table(data$A13_1)
# Location 2 column: table(data$A13_2)
```

**Step 4: TableAgent Recognition**

Recognize that `A13_1` and `A13_2` are iterations of the same base question. Create one table definition for `A13` with a loop flag, rather than separate tables.

### Test Case

**Primary loop test**: `stacked-data-temp/` (Tito's Future Growth)
- Consumer survey with drink location loops
- Variables: `A3_1`/`A3_2`, `A4_1`/`A4_2`, `A13_1`/`A13_2`, etc.
- Tests: Loop detection, loop banner generation, R script suffix substitution

### Process

1. Run current pipeline on Tito's to identify failure points
2. Implement loop detection in DataMapProcessor
3. Update BannerAgent/CrosstabAgent prompts to recognize loop banners
4. Extend RScriptGeneratorV2 to handle loop suffix substitution
5. Test until loop tables render correctly

### Success Criteria

- Loop variables automatically detected and flagged in datamap output
- Loop banner groups correctly produce suffix-based columns
- Tables comparing loop iterations render with correct data
- Standard (non-loop) surveys continue to work unchanged

### Future Enhancement: Within-Subject Significance

Current sig testing compares independent groups. Loop comparisons are within-subject (same person's Location 1 vs Location 2). For now, use the same test (valid but conservative). Later, consider McNemar's test for proportions.

---

## Part 7: Strategic Broader Testing

**Status**: NOT STARTED (begins after Part 6 loop support is validated)

### Strategy: Coverage by Failure Mode

Instead of testing all 23 datasets, we select **5 datasets strategically** to cover the major failure modes. If these 5 pass, we can claim coverage of ~80% of workload types.

### Failure Mode Categories

| Category | What It Tests | Dataset Candidate |
|----------|---------------|-------------------|
| **Baseline** | Standard HCP survey, filter-based banners | `leqvio-monotherapy-demand-NOV217` ✓ (Part 5) |
| **Loop/Stacked** | Loop variables, suffix-based banners | `titos-future-growth` ✓ (Part 6) |
| **Multi-select + NET heavy** | Multi-select questions, many NET/roll-up rows | TBD from test-data |
| **Numeric-heavy (means)** | Continuous variables, mean calculations | TBD from test-data |
| **Weights + small bases** | Weighted data, HCP-style small subgroups | TBD from test-data |

### Dataset Selection Process

1. Review test-data datamaps to identify which datasets fit each category
2. Prefer datasets where we have Joe's tabs for validation
3. Document why each dataset was selected

### Test Data Structure

Each selected dataset needs:

| File | Source | Required |
|------|--------|----------|
| `*-datamap.csv` | Existing | Yes |
| `*.sav` | Existing | Yes |
| `*-survey.docx` | Upload | Yes (for VerificationAgent) |
| `*-bannerplan-original.docx` | Upload | Yes |
| `*-bannerplan-adjusted.docx` | Create | Yes (maps to Joe's actual output) |
| `*-tabs-joe.xlsx` | Upload | Yes (reference output) |

### Testing Workflow

For each of the 3 remaining datasets (after baseline + loop):

1. Prepare files (upload survey, banner original, Joe's tabs; create adjusted banner)
2. Run pipeline with adjusted banner
3. Compare to Joe's tabs (data accuracy + significance)
4. Log bugs specific to that failure mode
5. Fix issues, re-run
6. Quick regression check on previously-passing datasets

### Track Dataset Status

| Dataset | Category | Status | Notes |
|---------|----------|--------|-------|
| leqvio-monotherapy-demand-NOV217 | Baseline | Part 5 | Primary dataset |
| titos-future-growth | Loop/Stacked | Part 6 | Loop test case |
| TBD | Multi-select + NET | Not Started | |
| TBD | Numeric-heavy | Not Started | |
| TBD | Weights + small bases | Not Started | |

### Success Criteria

- All 5 datasets produce output matching Joe's tabs (data + significance)
- Each failure mode category has at least one passing dataset
- Regression: fixes for later datasets don't break earlier ones
- Documentation: clear record of what was tested and why

### Available Datasets (for selection)

```
data/test-data/
├── CART-Segmentation-Data_7.22.24_v2/
├── Cambridge-Savings-Bank-W1_4.9.24/
├── Cambridge-Savings-Bank-W2_4.1.25/
├── GVHD-Data_12.27.22/
├── Iptacopan-Data_2.23.24/
├── Leqvio-Demand-W1_3.13.23/
├── Leqvio-Demand-W2_8.16.24 v2/
├── Leqvio-Demand-W3_5.16.25/
├── Leqvio-Segmentation-Data-HCP-W1_7.11.23/
├── Leqvio-Segmentation-Data-HCP-W2_2.21.2025/
├── Leqvio-Segmentation-Patients-Data_7.7.23/
├── Meningitis-Vax-Data_10.14.22/
├── Onc-CE-W2-Data_5.10.20/
├── Onc-CE-W3-Data_5.13.21/
├── Onc-CE-W4-Data_3.11.22/
├── Onc-CE-W5-Data_2.7.23/
├── Onc-CE-W6-Data_3.18.24/
├── Spravato_4.23.25/
├── UCB-Caregiver-ATU-W1-Data_1.11.23/
├── UCB-Caregiver-ATU-W2-Data_9.1.23/
├── UCB-Caregiver-ATU-W4-Data_8.16.24/
├── UCB-Caregiver-ATU-W5-Data_1.7.25/
└── UCB-Caregiver-ATU-W6-Data_1.23.24/
```

---

## Reference

### Current Pipeline (Pre-Part 4)

```
User Uploads → BannerAgent → CrosstabAgent → TableAgent → VerificationAgent → R Script → ExcelJS
                   ↓              ↓              ↓              ↓
              Banner PDF      DataMap        Questions      Survey Doc
              → Images        → Variables    → Tables       → Optimized Tables
```

### Target Pipeline (Post-Part 4)

```
User Uploads → BannerAgent → CrosstabAgent → TableGenerator → VerificationAgent → R Script → ExcelJS
                   ↓              ↓              ↓                   ↓
              Banner PDF      DataMap        DataMap             Survey Doc
              → Images        → Variables    → Overview Tables   → Expanded Tables
                                             (deterministic)     (grids, rankings, NETs)
```

### Key Files

| File | Purpose |
|------|---------|
| `src/lib/tables/TableGenerator.ts` | **NEW** - Deterministic table generation |
| `src/agents/TableAgent.ts` | **DEPRECATED** - LLM-based table decisions |
| `src/agents/VerificationAgent.ts` | Survey-aware optimization + expansion |
| `src/lib/r/RScriptGeneratorV2.ts` | R script generation + significance testing |
| `src/lib/excel/ExcelFormatter.ts` | Excel output formatting |
| `scripts/test-pipeline.ts` | End-to-end test script |

### Primary Test Data

Primary test case: `data/leqvio-monotherapy-demand-NOV217/`

**Structure**:
```
leqvio-monotherapy-demand-NOV217/
├── inputs/
│   ├── leqvio-monotherapy-demand-datamap.csv
│   ├── leqvio-monotherapy-demand-data.sav
│   ├── leqvio-monotherapy-demand-survey.docx
│   ├── leqvio-monotherapy-demand-bannerplan-original.docx
│   └── leqvio-monotherapy-demand-bannerplan-clean.docx
├── tabs/
│   └── leqvio-monotherapy-demand-tabs-joe.xlsx (reference output)
└── golden-datasets/
    └── (to be created for evaluation framework)
```

---

*Created: January 6, 2026*
*Updated: January 23, 2026*
*Status: Parts 1-3b complete, Part 4 in progress (TableGenerator refactor), Parts 5-7 pending*
