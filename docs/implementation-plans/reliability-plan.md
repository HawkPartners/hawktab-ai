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

## Part 4: Evaluation Framework

**Status**: IN PROGRESS

### Current Progress (as of 2026-01-10)

**Infrastructure: ✅ Complete**
- `scripts/compare-to-golden.ts` - Compares pipeline output to golden datasets
- `scripts/calculate-metrics.ts` - Calculates accuracy metrics from comparison report
- `scripts/extract-data-json.ts` - Extracts streamlined data for golden dataset creation
- Pipeline auto-outputs `data-streamlined.json` alongside `tables.json`
- Raw agent outputs now capture complete model output (not filtered subsets)

**Golden Datasets: 🔄 In Progress**
| File | Status | Notes |
|------|--------|-------|
| `banner-expected.json` | ✅ Complete | Removed unused fields (crossRefStatus, aiRecommended). Added inline guidance for remaining fields. |
| `crosstab-expected.json` | ✅ Complete | Fixed skip logic issues (A3ar1c2, A4ar1c2 filters) discovered during review. |
| `verification-expected.json` | 🔄 Needs review | Copied from raw output, needs manual verification. |
| `data-expected.json` | 🔄 Needs review | Copied from raw output, needs manual verification against Joe's tabs. |

**Prompt Updates Made:**
- `src/prompts/banner/alternative.ts` - Clarified field guidance (humanInLoopRequired, requiresInference, uncertainties, inferenceReason)
- `src/agents/BannerAgent.ts` - Schema updated to remove unused fields
- `src/lib/contextBuilder.ts` - Types updated to match schema

**Next Steps:**
1. Finalize `verification-expected.json` review
2. Finalize `data-expected.json` review
3. Run first comparison: `npx tsx scripts/compare-to-golden.ts <pipeline-output>`
4. Review comparison report and annotate differences

---

### The Problem

Our current testing workflow is "run pipeline, eyeball JSON, manually compare." This doesn't scale and makes it hard to:
- Know if we're improving or regressing
- Focus review time on actual problems
- Track patterns in failures for prompt iteration

### The Solution: Golden Dataset + Annotation Workflow

This is the standard approach for human-preference-centered LLM evaluation:

1. **Golden Dataset**: Manually-reviewed "expected output" files for each agent, representing correct behavior
2. **Strict Comparison**: Automated diff between actual output and golden data (surfaces all differences)
3. **Human Annotation**: For each difference, mark as "wrong" or "acceptable", with attribution to the responsible component
4. **Metrics Tracking**: Track both strict accuracy and practical accuracy over time

### Golden Datasets (4 files per dataset)

Each agent produces output that we compare against a golden reference:

| Golden File | Source | What It Tests | Attribution |
|-------------|--------|---------------|-------------|
| `banner-expected.json` | `banner-output-raw.json` | Groups, columns, stat letters | banner_agent |
| `crosstab-expected.json` | `crosstab-output-raw.json` | Cut names, R expressions | crosstab_agent |
| `verified-tables-expected.json` | `verified-table-output-*.json` | Table structure, labels, NETs, T2B | table_agent, verification_agent |
| `data-expected.json` | `tables.json` (streamlined) | Calculated values, significance | system, r_script |

**Note**: We skip a separate `table-expected.json` because verification agent output supersedes table agent output (verification enhances the table definitions).

### What Each Golden Dataset Contains

**banner-expected.json** - Banner agent decisions:
- Banner group names
- Column names within each group
- Stat letters (A, B, C, etc.)

**crosstab-expected.json** - Crosstab agent decisions:
- Cut definitions (name + R expression)
- Group assignments for stat testing

**verified-tables-expected.json** - Table + Verification agent decisions:
- tableId, title, tableType
- rows (variable, label, filterValue)
- isNet, netComponents, indent
- isDerived, exclude, excludeReason
- hints

**data-expected.json** - Calculated data (streamlined):
```json
{
  "s1": {
    "Total": {
      "S1_row_1": { "n": 180, "count": 45, "pct": 25, "sig_higher_than": [], "sig_vs_total": null }
    },
    "Cards": {
      "S1_row_1": { "n": 60, "count": 20, "pct": 33, "sig_higher_than": ["B"], "sig_vs_total": "higher" }
    }
  }
}
```

This strips metadata and table-level fields from `tables.json`, keeping only the actual calculated values.

### Comparison Report Structure

The comparison script generates a unified report covering all golden datasets:

```json
{
  "metadata": {
    "dataset": "leqvio-monotherapy-demand-NOV217",
    "runTimestamp": "2026-01-09T16:54:54.155Z",
    "generatedAt": "2026-01-09T17:30:00.000Z",
    "status": "pending_review"
  },
  "summary": {
    "banner": { "total": 8, "matches": 8, "diffs": 0 },
    "crosstab": { "total": 19, "matches": 18, "diffs": 1 },
    "structure": { "total": 52, "matches": 48, "diffs": 4 },
    "data": { "total": 988, "matches": 970, "diffs": 18 }
  },
  "overall": {
    "totalDiffs": 23,
    "reviewed": 0,
    "acceptable": 0,
    "wrong": 0
  },
  "differences": [
    {
      "id": "diff_001",
      "category": "structure",
      "tableId": "a6_ranking",
      "diffType": "field_mismatch",
      "path": "tableType",
      "expected": "frequency",
      "actual": "ranking",
      "annotation": null,
      "attribution": null,
      "notes": ""
    },
    {
      "id": "diff_002",
      "category": "data",
      "tableId": "s1",
      "rowKey": "S1_row_1",
      "cut": "Cards",
      "diffType": "value_mismatch",
      "field": "pct",
      "expected": 33,
      "actual": 32,
      "annotation": null,
      "attribution": null,
      "notes": ""
    }
  ]
}
```

### Annotation Fields

For each difference, the reviewer fills in:

**annotation** (required):
- `null` - Not yet reviewed
- `"acceptable"` - Different but not wrong (e.g., label case difference)
- `"wrong"` - Actual error that needs fixing

**attribution** (required when `annotation: "wrong"`):
- `"banner_agent"` - Banner agent made incorrect decision
- `"crosstab_agent"` - Crosstab agent made incorrect decision
- `"table_agent"` - Table agent made incorrect decision
- `"verification_agent"` - Verification agent made incorrect decision
- `"r_script"` - R script generator bug
- `"system"` - Edge case our pipeline doesn't handle yet
- `"user"` - Bad input (wrong banner plan, datamap issues)
- `"data"` - Source data issue

**notes** (optional): Free text for context

### Metrics Calculation

After annotation, the script calculates:

```json
{
  "strictAccuracy": 0.77,
  "practicalAccuracy": 0.92,
  "errorRate": 0.08,
  "attributionBreakdown": {
    "table_agent": 2,
    "verification_agent": 1,
    "system": 1
  }
}
```

- **Strict Accuracy**: matches / total (before annotation)
- **Practical Accuracy**: (matches + acceptable) / total
- **Error Rate**: wrong / total

### Folder Structure

```
data/leqvio-monotherapy-demand-NOV217/
├── inputs/                            # Input files
│   ├── leqvio-monotherapy-demand-datamap.csv
│   ├── leqvio-monotherapy-demand-data.sav
│   ├── leqvio-monotherapy-demand-survey.docx
│   └── leqvio-monotherapy-demand-bannerplan-adjusted.docx
├── tabs/                              # Reference output
│   └── leqvio-monotherapy-demand-tabs-joe.xlsx
└── golden-datasets/                   # Evaluation framework
    ├── banner-expected.json           # Banner agent golden
    ├── crosstab-expected.json         # Crosstab agent golden
    ├── verified-tables-expected.json  # Table + Verification agent golden
    └── data-expected.json             # Calculated data golden (streamlined)
```

Pipeline outputs go to `outputs/` folder as usual. Comparison script reads from both locations.

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/extract-data-json.ts` | Extract streamlined data from tables.json (for creating data-expected.json) |
| `scripts/compare-to-golden.ts` | Generate comparison report from pipeline output vs golden datasets |
| `scripts/calculate-metrics.ts` | Calculate final metrics from annotated comparison report |

The pipeline also outputs `data-streamlined.json` alongside `tables.json` automatically.

### Workflow

1. **Create Golden Datasets** (one-time per dataset):
   - Run pipeline to get baseline outputs
   - Copy `banner-output-raw.json` → `golden-datasets/banner-expected.json`
   - Copy `crosstab-output-raw.json` → `golden-datasets/crosstab-expected.json`
   - Copy `verified-table-output-*.json` → `golden-datasets/verified-tables-expected.json`
   - Run `npx tsx scripts/extract-data-json.ts` → `golden-datasets/data-expected.json`
   - Review each file, correct any errors manually

2. **Evaluate a Run**:
   - Run pipeline: `npx tsx scripts/test-pipeline.ts`
   - Compare: `npx tsx scripts/compare-to-golden.ts <output-folder>`
   - Review: Open comparison report, annotate each difference
   - Metrics: `npx tsx scripts/calculate-metrics.ts <comparison-report>`

3. **Iterate**:
   - Identify patterns in "wrong" annotations
   - Fix prompts or code
   - Re-run, compare again
   - Track metrics over time

### Deliverables

1. **Golden datasets**: 4 files for primary dataset (banner, crosstab, verified-tables, data)
2. **Extract script**: `scripts/extract-data-json.ts` for creating streamlined data golden
3. **Comparison script**: `scripts/compare-to-golden.ts` for generating diff reports
4. **Metrics script**: `scripts/calculate-metrics.ts` for final metrics calculation
5. **Pipeline update**: Auto-output `data-streamlined.json` alongside `tables.json`

### Exit Criteria

- All 4 golden datasets exist for primary dataset
- Comparison script produces unified diff report covering all agents
- At least one full evaluation cycle completed (run → compare → annotate → calculate metrics)
- Attribution breakdown identifies which agents need prompt iteration

---

## Part 5: Iteration (Primary Dataset)

**Status**: NOT STARTED (begins after Part 4 Evaluation Framework complete)

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

---

## Part 6: Broader Testing

**Status**: NOT STARTED (begins after primary dataset is stable)

### Test Data Structure

Each dataset folder in `data/test-data/` needs:

| File | Source | Required |
|------|--------|----------|
| `*-datamap.csv` | Existing | Yes |
| `*.sav` | Existing | Yes |
| `*-survey.docx` | Upload | Yes (for VerificationAgent) |
| `*-bannerplan-original.docx` | Upload | Yes |
| `*-bannerplan-clean.docx` | Create | Yes |
| `*-bannerplan-adjusted.docx` | Create | Yes |
| `*-tabs-joe.xlsx` | Upload | Yes (reference output) |

### Testing Workflow

For each dataset:
1. Prepare files (upload survey, banner original, Joe's tabs; create clean + adjusted)
2. Run pipeline with adjusted banner
3. Compare to Joe's tabs:
   - **Data accuracy**: Do the numbers match?
   - **Significance**: Do the letters match?
4. Log bugs, fix, re-run
5. Mark dataset as passing only when satisfied

### Testing Strategy

**Recommended approach** (minimize wasted effort):

1. **Start with 2-3 diverse datasets**: Pick datasets that cover different question types (scales, rankings, multi-select, numeric). Early bugs likely affect multiple datasets.

2. **Fix forward, validate backward**: After fixing bugs on dataset N, quick-check dataset N-1 still passes before moving to N+1.

3. **Categorize bugs by root cause**: Group similar issues so one fix addresses multiple bugs (e.g., all T2B issues, all label issues).

4. **Track dataset status**:
   | Status | Meaning |
   |--------|---------|
   | Not Started | Files not prepared |
   | In Progress | Actively testing/fixing |
   | Passing | Output matches Joe's tabs (data + significance) |
   | Blocked | Has issue requiring architectural change |

5. **Prioritize by client importance**: If certain datasets are for active clients, prioritize those.

### Datasets (23 total)

```
data/test-data/
├── CART-Segmentation-Data_7.22.24_v2/
├── Cambridge-Savings-Bank-W1_4.9.24/
├── Cambridge-Savings-Bank-W2_4.1.25/
├── GVHD-Data_12.27.22/
├── Iptacopan-Data_2.23.24/
├── leqvio-monotherapy-demand-W1_3.13.23/
├── leqvio-monotherapy-demand-W2_8.16.24 v2/
├── leqvio-monotherapy-demand-W3_5.16.25/
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

### Current Pipeline

```
User Uploads → BannerAgent → CrosstabAgent → TableAgent → VerificationAgent → R Script → ExcelJS
                   ↓              ↓              ↓              ↓
              Banner PDF      DataMap        Questions      Survey Doc
              → Images        → Variables    → Tables       → Optimized Tables
```

### Key Files

| File | Purpose |
|------|---------|
| `src/agents/TableAgent.ts` | Table structure decisions |
| `src/agents/VerificationAgent.ts` | Survey-aware optimization |
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
*Updated: January 8, 2026*
*Status: Parts 1-3b complete, Part 4 in progress, Parts 5-6 pending*
