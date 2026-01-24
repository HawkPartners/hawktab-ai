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
| 4 | TableAgent Refactor + Evaluation Framework | Phase 1-3 COMPLETE, Phase 4-5 pending |
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

### Completed: Phase 3

#### Phase 3: Test TableGenerator Independently

**Status**: COMPLETE

Test script created (`scripts/test-table-generator.ts`). Validated on primary dataset.

Additional dataset testing deferred to Part 6-7 (strategic broader testing).

### Pending: Phase 4-5

#### Phase 4: Pipeline Integration + Parallelism + Observability

**Status**: NOT STARTED

This phase combines integration, prompt updates, parallelism, and cost tracking into one cohesive step.

**Summary of what this phase accomplishes:**
1. Replace TableAgent (LLM) with TableGenerator (deterministic code) in the pipeline
2. Add parallel processing for VerificationAgent (3 concurrent batches)
3. Integrate token/cost tracking across all agents
4. Make minimal, surgical updates to VerificationAgent prompt for new input format
5. Add `--stop-after-verification` flag for fast iteration

**Key constraints:**
- Maintain backward compatibility with existing pipeline outputs
- Keep VerificationAgent prompt changes minimal (~20 lines)
- Preserve XML-structured prompt framework
- Ensure logging works correctly for parallel VerificationAgent instances

**Primary test dataset:** `data/leqvio-monotherapy-demand-NOV217/`

**Step A: Wire Up TableGenerator**

Replace TableAgent with DataMapGrouper + TableGenerator in pipeline:

| File | Change |
|------|--------|
| `scripts/test-pipeline.ts` | Replace TableAgent import/calls with new modules |
| `src/app/api/process-crosstab/route.ts` | Update `executePathB()` and `executePathBPassthrough()` |

```typescript
// Replace this:
const tableOutput = await runTableAgent(groups);

// With this:
import { groupDataMap } from '@/lib/tables/DataMapGrouper';
import { generateTables, convertToLegacyFormat } from '@/lib/tables/TableGenerator';

const groups = groupDataMap(verboseDataMap);
const tableOutput = convertToLegacyFormat(generateTables(groups));
// tableOutput is now compatible with existing verifyAllTables()
```

**Step B: Add Parallel VerificationAgent**

Currently VerificationAgent processes tables sequentially. Add parallel processing:

```typescript
async function verifyAllTablesParallel(
  tableOutput: TableAgentOutput[],
  surveyMarkdown: string,
  verboseDataMap: VerboseDataMapType[],
  options: { concurrency?: number; abortSignal?: AbortSignal }
): Promise<VerificationResults>
```

Implementation approach:
- Collect all tables into array
- Split into N batches (default: 3 concurrent)
- Process batches with `Promise.all()` or p-limit
- Merge results maintaining order
- Respect abort signal across all batches

**Logging for parallel instances:**
- Each VerificationAgent call should log with table identifier: `[VerificationAgent:tableId]`
- Scratchpad entries need tableId association for debugging
- Metrics recording must be thread-safe (collect per-call, aggregate after)
- Consider logging batch start/end: `[VerificationAgent] Starting batch 1/3 (14 tables)`

**Step C: Token & Cost Tracking**

**Status**: Infrastructure created, integration pending

Observability utilities created in `src/lib/observability/`:

| File | Purpose |
|------|---------|
| `CostCalculator.ts` | Fetches LiteLLM pricing database, calculates costs |
| `AgentMetrics.ts` | Collects metrics across agents, formats summaries |
| `index.ts` | Clean exports |

**Usage pattern for each agent:**
```typescript
import { recordAgentMetrics } from '@/lib/observability';

const startTime = Date.now();
const { output, usage } = await generateText({ ... });

recordAgentMetrics(
  'VerificationAgent',
  getVerificationModelName(),
  { input: usage.promptTokens, output: usage.completionTokens },
  Date.now() - startTime
);
```

**At end of pipeline:**
```typescript
import { getPipelineCostSummary } from '@/lib/observability';
console.log(await getPipelineCostSummary());
```

**Features:**
- Auto-fetches LiteLLM pricing database (6000+ models, regularly updated)
- Falls back to hardcoded pricing if fetch fails
- Handles model name normalization (azure/gpt-4o, deployment names, etc.)
- Aggregates per-agent and total pipeline metrics

**Remaining work:**
- [ ] Add `recordAgentMetrics()` calls to BannerAgent
- [ ] Add `recordAgentMetrics()` calls to CrosstabAgent
- [ ] Add `recordAgentMetrics()` calls to VerificationAgent
- [ ] Add summary output to test-pipeline.ts

**Step D: Update VerificationAgent Prompt**

**CRITICAL: Be surgical with prompt changes.** The current XML-structured prompt framework is working well. Make minimal, targeted changes only for what has actually changed.

**What has changed:**
- Input is now a flat overview table from TableGenerator (not pre-split from TableAgent LLM)
- Tables include optional `meta` field with structural hints

**What stays the same (DO NOT CHANGE):**
- XML structure (`<task_context>`, `<the_75_25_rule>`, etc.)
- The 75/25 rule framework
- All action types (passthrough, fix labels, split, NETs, T2B, exclude)
- Output schema (ExtendedTableDefinition)
- Scratchpad protocol
- Confidence scoring framework

**Specific changes needed (~20 lines out of 430):**

1. **Update context language**: Replace "TableAgent completed 90% of the work" with "TableGenerator created a flat overview table"

2. **Add meta field documentation** (small paragraph):
   ```
   Tables may include a `meta` field with structural information:
   - itemCount: Number of unique variables
   - rowCount: Total rows in the table
   - gridDimensions: { rows, cols } if grid pattern detected
   - valueRange: [min, max] of allowed values
   Use these hints to inform splitting decisions, but always verify against survey context.
   ```

3. **Adjust split guidance**: Since input is never pre-split, the agent now has full responsibility for expansion decisions. Add guidance on when to keep vs drop the overview table:
   - If overview has ≤16 rows: Keep overview + add derived views
   - If overview has >16 rows: Derived views are likely sufficient, overview can be dropped
   - Use judgment based on analytical value (a 40-row overview table is noise, not signal)

**Files to update:**
- `src/prompts/verification/production.ts`
- `src/prompts/verification/alternative.ts`

Copy the existing XML framework exactly. Only change the specific sections noted above.

**Step E: Run & Iterate**

**Add early-stop flag for faster iteration:**
```bash
# Full pipeline (Banner → Crosstab → TableGenerator → Verification → R → Excel)
npx tsx scripts/test-pipeline.ts

# Stop after VerificationAgent (skip R script + Excel generation)
npx tsx scripts/test-pipeline.ts --stop-after-verification
```

This allows rapid iteration on TableGenerator → VerificationAgent flow without waiting for R/Excel. Metrics still capture Banner, Crosstab, and Verification costs.

**Iteration process:**
1. Run pipeline with `--stop-after-verification` flag
2. Review scratchpad traces in `verification/scratchpad-verification-*.md`
3. Check output tables for correct expansions (rankings, grids, T2B)
4. Review cost summary output
5. If issues found: make surgical prompt changes, re-run
6. Once verification output looks good: run full pipeline without flag
7. Verify R script + Excel generation still works

**Files to Create/Modify:**

| File | Action | Status |
|------|--------|--------|
| `src/lib/observability/CostCalculator.ts` | CREATE - LiteLLM pricing + cost calculation | DONE |
| `src/lib/observability/AgentMetrics.ts` | CREATE - Token/cost tracking utilities | DONE |
| `src/lib/observability/index.ts` | CREATE - Clean exports | DONE |
| `src/agents/VerificationAgent.ts` | UPDATE - Add parallel processing, metrics capture | Pending |
| `src/agents/BannerAgent.ts` | UPDATE - Add metrics capture | Pending |
| `src/agents/CrosstabAgent.ts` | UPDATE - Add metrics capture | Pending |
| `scripts/test-pipeline.ts` | UPDATE - Use TableGenerator, display metrics | Pending |
| `src/prompts/verification/*.ts` | UPDATE - Contextual changes for new input format | Pending |

#### Phase 5: Golden Dataset Creation

**Status**: NOT STARTED (begins after Phase 4 verified working)

1. Run full pipeline on primary dataset with new architecture
2. Manual review of output for correctness
3. Copy outputs to golden datasets:
   - `verification-output-raw.json` → `verification-expected.json`
   - `data-streamlined.json` → `data-expected.json`
4. Run comparison: `npx tsx scripts/compare-to-golden.ts`
5. Document any acceptable differences vs strict matches

### Exit Criteria (Part 4)

- [x] TableGenerator produces correct overview tables for all question types
- [x] TableGenerator maintains API compatibility
- [x] TableGenerator tested on primary dataset
- [ ] Pipeline runs end-to-end with TableGenerator replacing TableAgent
- [ ] VerificationAgent processes tables in parallel (3 concurrent)
- [ ] Token consumption and cost estimates tracked for all agents
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
*Status: Parts 1-3b complete, Part 4 Phase 1-3 complete (TableGenerator tested), Part 4 Phase 4-5 + Parts 5-7 pending*
