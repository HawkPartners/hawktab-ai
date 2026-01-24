# Reliability Plan

## Overview

This plan tracks the work to make HawkTab AI reliably produce publication-quality crosstabs that match partner expectations (using Joe's output as the reference standard).

**Philosophy**: We're replacing Joe's usefulness (the manual work of generating crosstabs), not necessarily replicating his exact format. Antares-style output is our MVP target - functional, readable crosstabs that the team can write reports from.

**Current State**: Part 4 Phase 1-2 complete. TableGenerator replaces LLM-based TableAgent with deterministic code.

---

## Status Summary

| Part | Description | Status |
|------|-------------|--------|
| 1 | Bug Capture | COMPLETE |
| 2 | VerificationAgent | COMPLETE |
| 3 | Significance Testing (unpooled z-test) | COMPLETE |
| 3b | SPSS Validation Clarity | COMPLETE |
| 4 | TableAgent Refactor + Evaluation Framework | Phase 1-2 COMPLETE, Phase 3-7 pending |
| 5 | Iteration on primary dataset (leqvio) | Not started |
| 6 | Loop/Stacked Data Support (Tito's) | Not started |
| 7 | Strategic Broader Testing (5 datasets) | Not started |

---

## Completed Parts (Collapsed)

<details>
<summary><strong>Part 1: Bug Capture</strong> - COMPLETE</summary>

Review primary test output against Joe's tabs. Capture all differences in `bugs.md`.

**Test Run Location**: `temp-outputs/test-pipeline-leqvio-monotherapy-demand-NOV217-<timestamp>/`

**Exit Criteria**: All significant differences documented and categorized.
</details>

<details>
<summary><strong>Part 2: VerificationAgent</strong> - COMPLETE</summary>

VerificationAgent implemented with:
- Survey-aware label cleanup
- Table restructuring decisions
- NET/roll-up row identification
- Low-value table flagging
- Per-agent environment configuration

**Files**: `src/agents/VerificationAgent.ts`, `src/schemas/verificationAgentSchema.ts`, `src/lib/processors/SurveyProcessor.ts`
</details>

<details>
<summary><strong>Part 3: Significance Testing</strong> - COMPLETE</summary>

Switched to unpooled z-test formula to match WinCross defaults:
- `SE = sqrt(p1*(1-p1)/n1 + p2*(1-p2)/n2)` (unpooled)
- Removed n<5 hard block (no minimum sample size)
- 90% confidence level maintained

**Detailed Plan**: `docs/implementation-plans/significance-testing-plan.md`
</details>

<details>
<summary><strong>Part 3b: SPSS Validation Clarity</strong> - COMPLETE</summary>

Categorized SPSS validation mismatches with explanations:
- `x` prefix for numeric-start variables
- `_dupe` suffix for duplicate columns
- Case-insensitive matches

Users can now distinguish expected SPSS behavior from actual problems.
</details>

---

## Part 4: TableAgent Refactor + Evaluation Framework

**Status**: Phase 1-2 COMPLETE, Phase 3-7 pending

### Architecture Change

```
Before: DataMap → TableAgent (LLM) → VerificationAgent → R Script
After:  DataMap → DataMapGrouper → TableGenerator → VerificationAgent → R Script
                      (code)           (code)            (LLM)
```

**Benefits:**
- **Faster** - 1ms vs seconds for table generation
- **Consistent** - Same input → same output, every time
- **Debuggable** - Fix code, not prompts
- **Better Context** - VerificationAgent sees full overview tables, can create any derived views

### Completed: Phase 1-2 (DataMapGrouper + TableGenerator)

<details>
<summary><strong>Phase 1-2 Implementation Details</strong> - COMPLETE (Jan 23, 2026)</summary>

**New Files Created:**

| File | Purpose |
|------|---------|
| `src/lib/tables/DataMapGrouper.ts` | Groups datamap by parent question, filters admin/text_open |
| `src/lib/tables/TableGenerator.ts` | Deterministic table generation with mapping rules |
| `scripts/test-table-generator.ts` | Test script for validation |

**Mapping Rules:**
| normalizedType | tableType | filterValue |
|----------------|-----------|-------------|
| `numeric_range` | `mean_rows` | `""` (empty) |
| `binary_flag` | `frequency` | `"1"` |
| `categorical_select` | `frequency` | value code |

**Schema Updates:**
- Added `TableMetaSchema` (itemCount, rowCount, valueRange, gridDimensions)
- Made `hints` field optional/deprecated
- Removed `hints` from `ExtendedTableDefinitionSchema`

**Downstream Files Updated (hints removed):**
- `src/lib/r/RScriptGeneratorV2.ts`
- `src/lib/excel/ExcelFormatter.ts`
- `src/lib/excel/tableRenderers/frequencyTable.ts`
- `src/lib/excel/tableRenderers/meanRowsTable.ts`
- `src/lib/data/extractStreamlinedData.ts`
- `src/prompts/verification/production.ts`
- `src/prompts/verification/alternative.ts`
- `scripts/extract-data-json.ts`
- `scripts/compare-to-golden.ts`

**Deprecated Files (headers added):**
- `src/agents/TableAgent.ts`
- `src/prompts/table/index.ts`
- `src/prompts/table/production.ts`
- `src/prompts/table/alternative.ts`

**Test Results (primary dataset):**
- 192 variables processed
- 42 groups created
- 42 tables generated (29 frequency, 13 mean_rows)
- 359 total rows
- Duration: 1ms

**Key Insight:** Old TableAgent pre-split tables (e.g., A6 ranking into 4 separate tables), which *prevented* VerificationAgent from creating combined views (Top 3 Box, per-item distribution). New approach gives VerificationAgent the full overview table so it can make informed expansion decisions.
</details>

### Pending: Phase 3-7

#### Phase 3: Test TableGenerator Independently

**Status**: Ready to proceed

Test script created (`scripts/test-table-generator.ts`). Already validated on primary dataset.

**Remaining work:**
- [ ] Test on 2-3 additional datasets from `data/test-data/` to verify generalizability
- [ ] Document any edge cases found

#### Phase 4: Integrate into Pipeline

Replace TableAgent calls in pipeline orchestration:

| File | Change |
|------|--------|
| `scripts/test-pipeline.ts` | Replace TableAgent with DataMapGrouper + TableGenerator |
| `src/app/api/process-crosstab/route.ts` | Update `executePathB()` and `executePathBPassthrough()` |

**New flow:**
```typescript
const groups = groupDataMap(verboseDataMap, { includeOpenEnds: false });
const tableOutput = generateTables(groups);
const verifiedTables = await verifyAllTablesParallel(tableOutput, surveyMarkdown, {
  concurrency: 3,
  abortSignal
});
```

#### Phase 5: Update VerificationAgent Prompt

VerificationAgent now handles ALL expansion logic. Update prompt to:
- Reference `meta` fields (itemCount, rowCount, gridDimensions)
- Guide splitting decisions based on survey context
- Handle rankings → by-rank, by-item, combined views
- Handle grids → by-row, by-column views

#### Phase 6: Run Pipeline + Create Golden Dataset

1. Run full pipeline on primary dataset
2. Review output for correctness
3. Copy outputs to golden datasets
4. Run comparison: `npx tsx scripts/compare-to-golden.ts`

#### Phase 7: Optimize

- Measure token consumption
- Test optimal parallelism for VerificationAgent
- Consider caching survey context

### Exit Criteria (Part 4)

- [x] TableGenerator produces correct overview tables for all question types
- [x] TableGenerator maintains API compatibility
- [ ] Pipeline runs end-to-end with TableGenerator replacing TableAgent
- [ ] VerificationAgent correctly expands grids and rankings
- [ ] Golden datasets created from new pipeline output
- [ ] At least one full evaluation cycle completed
- [ ] No regression in output quality vs Joe's tabs

---

## Part 5: Iteration (Primary Dataset)

**Status**: NOT STARTED (begins after Part 4 complete)

For each table in our output vs Joe's tabs, validate:
- Data accuracy (base n, counts, percentages, means)
- Significance match (letters on correct cells)
- Structure match (same tables, rows in same order)
- Labels acceptable

**Banner Plan Versions**: Original, Clean, Adjusted (maps to Joe's actual output)

**Success Criteria**: Output matches Joe's tabs, no blocking issues for report writing.

---

## Part 6: Loop/Stacked Data Support

**Status**: NOT STARTED (begins after Part 5)

Support surveys with loops where same questions asked multiple times (e.g., different drinks/brands).

**Test Case**: `stacked-data-temp/` (Tito's Future Growth)

**Key changes:**
- Loop detection in DataMapProcessor
- Banner columns as loop iterations (suffix-based) vs respondent subgroups (filter-based)
- R script variable suffix substitution

---

## Part 7: Strategic Broader Testing

**Status**: NOT STARTED (begins after Part 6)

Test 5 datasets strategically to cover major failure modes:

| Category | Dataset |
|----------|---------|
| Baseline | `leqvio-monotherapy-demand-NOV217` (Part 5) |
| Loop/Stacked | `titos-future-growth` (Part 6) |
| Multi-select + NET heavy | TBD |
| Numeric-heavy (means) | TBD |
| Weights + small bases | TBD |

---

## Reference

### Current Pipeline Architecture

```
User Uploads → BannerAgent → CrosstabAgent → DataMapGrouper → TableGenerator → VerificationAgent → R Script → Excel
                   ↓              ↓               ↓                ↓                 ↓
              Banner PDF      DataMap        Grouped           Overview          Expanded
              → Cuts          → Variables    Questions         Tables            Tables
```

### Key Files

| File | Purpose |
|------|---------|
| `src/lib/tables/DataMapGrouper.ts` | Groups datamap by parent question |
| `src/lib/tables/TableGenerator.ts` | Deterministic table generation |
| `src/agents/TableAgent.ts` | **DEPRECATED** - LLM-based table decisions |
| `src/agents/VerificationAgent.ts` | Survey-aware optimization + expansion |
| `src/lib/r/RScriptGeneratorV2.ts` | R script generation + significance testing |
| `scripts/test-pipeline.ts` | End-to-end test script |
| `scripts/test-table-generator.ts` | TableGenerator test script |

### Primary Test Data

`data/leqvio-monotherapy-demand-NOV217/` with inputs/, tabs/, and golden-datasets/ subfolders.

---

*Created: January 6, 2026*
*Updated: January 24, 2026*
*Status: Parts 1-3b complete, Part 4 Phase 1-2 complete (TableGenerator), Parts 4 Phase 3-7 + Parts 5-7 pending*
