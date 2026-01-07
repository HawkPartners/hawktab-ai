# Reliability Plan

## Overview

This plan tracks the work to make HawkTab AI reliably produce publication-quality crosstabs that match partner expectations (using Joe's output as the reference standard).

**Philosophy**: We're replacing Joe's usefulness (the manual work of generating crosstabs), not necessarily replicating his exact format. Antares-style output is our MVP target - functional, readable crosstabs that the team can write reports from.

**Current State**: Pipeline working end-to-end. Full test run completed against `practice-files` dataset.

---

## Part 1: Bug Capture

**Status**: COMPLETE

Review the practice-files test output against Joe's tabs. Capture all differences in the session's `bugs.md` file.

**Test Run Location**: `temp-outputs/test-pipeline-practice-files-2026-01-04T19-20-00-967Z/`

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

**Status**: NOT STARTED (begins after Part 1 complete)

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

## Part 3: Non-VerificationAgent Problems

**Status**: NOT STARTED (begins after Part 2 complete)

Problems that the VerificationAgent cannot solve. These require changes to R calculations, RScriptGenerator, or ExcelJS formatter.

### Categories

**R Calculations**:
- 0% vs N/A distinction (base n = 0 should show dash, not 0%)
- A3a/A3b allocation questions accuracy

**RScriptGenerator**:
- T2B/B2B dimensionality collapse (loses row-level structure for multi-row scales)
- Top 3 Combined placement (should appear once at end, not after each ranking table)

**ExcelJS Formatter**:
- Table ordering (Screener → Main → Admin, alphanumeric within each)
- Column width / text wrapping
- Percentages stored as text (should be actual numbers)

### Process

After VerificationAgent is implemented:
1. Re-run practice-files test
2. Review remaining issues in bugs.md
3. Fix each by category (R → RScriptGenerator → ExcelJS)
4. Track fixes in this section

---

## Part 4: Significance Testing

**Status**: NOT STARTED (begins after Part 3 complete)

Our significance testing differs from Joe's WinCross output. After talking with Joe, we identified the root cause: we use **pooled proportions** for z-tests, but WinCross defaults to **unpooled proportions**.

### Key Changes Needed

| Parameter | Current | WinCross Default | Action |
|-----------|---------|------------------|--------|
| Z-test Formula | Pooled | **Unpooled** | Fix required |
| Min Sample Size | n < 5 → NA | No minimum | Fix required |
| Confidence Level | 90% | 90% | No change |
| T-test | Welch's | Welch's | No change |

### Implementation

1. **Update z-test function**: Change from pooled to unpooled standard error formula
   - Pooled: `SE = sqrt(p_pool * (1-p_pool) * (1/n1 + 1/n2))`
   - Unpooled: `SE = sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)`

2. **Remove n<5 hard block**: WinCross tests everything, so should we

3. **Add SignificanceConfig schema**: Allow configuration of test parameters for flexibility

4. **Update Excel footer**: Document methodology used

### Validation

- Run on practice-files with new formula
- Compare significance letters to Joe's output
- Document which cells changed and why

**Detailed Plan**: See `docs/implementation-plans/significance-testing-plan.md`

---

## Part 5: Iteration (Practice-Files)

**Status**: NOT STARTED (begins after Parts 2-4 complete)

### Banner Plan Versions

Three versions of the banner plan exist for each dataset:

| Version | Description |
|---------|-------------|
| **Original** | The actual banner plan document as received |
| **Clean** | Original but with clearer, unambiguous language (no "IF HCP" - explicit variable references) |
| **Adjusted** | Maps to Joe's actual tabs (which may differ from original due to email changes, iterations) |

**Why this matters**: Joe's tabs may not match the original banner plan exactly. To truly validate our output matches Joe's, we need the adjusted version that reflects what Joe actually produced.

**For practice-files**: Create `leqvio-demand-bannerplan-adjusted.docx` before completing Part 5 iteration.

### Process

1. Create banner-plan-adjusted for practice-files (if not exists)
2. Re-run `npx tsx scripts/test-pipeline.ts` with adjusted banner
3. Compare output to Joe's tabs
4. Update bugs.md with any new/remaining issues
5. Address issues (prompt tweaks, code fixes)
6. Repeat until practice-files output matches Joe's tabs

**Success Criteria**:
- Data accuracy matches Joe's tabs
- Formatting acceptable for partner use
- No blocking issues for report writing

---

## Part 6: Broader Testing

**Status**: NOT STARTED (begins after practice-files is stable)

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
3. Compare to Joe's tabs
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
   | Passing | Output matches Joe's tabs |
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
| `src/agents/VerificationAgent.ts` | Survey-aware optimization (to be created) |
| `src/lib/r/RScriptGeneratorV2.ts` | R script generation |
| `src/lib/excel/ExcelFormatter.ts` | Excel output formatting |
| `scripts/test-pipeline.ts` | End-to-end test script |

### Practice-Files Test Data

Primary test case: `data/test-data/practice-files/`
- `leqvio-demand-datamap.csv` (existing)
- `leqvio-demand-W2.sav` (existing)
- `leqvio-demand-survey.docx` (for VerificationAgent)
- `leqvio-demand-bannerplan-original.docx`
- `leqvio-demand-bannerplan-clean.docx` (current testing)
- `leqvio-demand-bannerplan-adjusted.docx` (to create for final validation)
- `leqvio-demand-tabs-joe.xlsx` (reference output)

---

*Created: January 6, 2026*
*Status: Part 1 complete, Part 2 next*
