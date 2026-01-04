# Table Agent Architecture

## Overview

TableAgent replaces regex-based table detection with AI reasoning. The agent decides how survey data should be displayed as crosstabs based on `normalizedType` from the datamap.

---

## Pipeline

```
Datamap CSV → DataMapProcessor → Verbose Datamap
                                       ↓
                              TableAgent (AI) → Table Definitions
                                       ↓
                              R Script V2 → JSON calculations
                                       ↓
                              ExcelJS → Formatted Excel
```

---

## Implementation Status

| Step | Description | Status |
|------|-------------|--------|
| 0-3.5 | TableAgent core (schema, prompts, test script) | ✅ Complete |
| 5 | RScriptGeneratorV2 (JSON output) | ✅ Complete |
| 4 | API route integration | ✅ Complete |
| — | Delete old files | ✅ Complete |
| 5.5 | R significance testing | ⚠️ Verify before Step 6 |
| 6 | ExcelJS Formatter | ⏳ Next |
| 7 | Excel Cleanup Agent (optional) | 📋 Planned |

---

## Completed: Steps 0-5

### TableAgent (Steps 0-3.5)
- `src/agents/TableAgent.ts` - AI agent for table decisions
- `src/schemas/tableAgentSchema.ts` - Input/output types
- `src/prompts/table/` - Modular prompts (production, alternative)
- `scripts/test-table-agent.ts` - Standalone test script

### RScriptGeneratorV2 (Step 5)
- `src/lib/r/RScriptGeneratorV2.ts` - Consumes `TableDefinition[]`, outputs JSON
- Two table types: `frequency` and `mean_rows`
- Correct base sizing: `base_n = sum(!is.na(cut_data[[variable]]))`
- Output: `results/tables.json`

### API Integration (Step 4)
- `src/app/api/process-crosstab/route.ts` updated
- TableAgent runs after CrosstabAgent
- `generateRScriptV2()` replaces old `generateMasterRScript()`

### Cleanup
Deleted old files:
- `src/lib/tables/TablePlan.ts`
- `src/lib/r/RScriptGenerator.ts`, `Manifest.ts`, `PreflightGenerator.ts`, `ValidationGenerator.ts`
- `src/agents/RScriptAgent.ts`
- `src/app/api/generate-crosstabs/`, `generate-r/`, `validate/`

---

## Step 5.5: R Calculations Verification

**Flag**: Before implementing Step 6, verify R calculates everything needed:

| Calculation | Status | Notes |
|-------------|--------|-------|
| Count per cell | ✅ | `sum(cut_data[[variable]] == value)` |
| Percentage per cell | ✅ | `count / base_n * 100` |
| Mean/Median/SD | ✅ | For `mean_rows` tables |
| Base sizes (n) | ✅ | `sum(!is.na(cut_data[[variable]]))` |
| Significance testing | ❓ | Z-test (proportions), T-test (means) |

**Significance testing** is standard for Antares-style output. Need to add:
- Column-to-column comparison (z-test for proportions)
- Stat letters in output JSON indicating which columns differ significantly
- Configurable significance level (typically 95%)

This may require RScriptGeneratorV2 updates before ExcelJS work.

---

## Step 6: ExcelJS Formatter

**Goal**: Format JSON output into Antares-style Excel workbook.

### 6.1 Responsibilities

| Component | Job |
|-----------|-----|
| R | Calculate values (n, count, %, mean, median, sd) |
| ExcelJS | Place values in cells, apply formatting, process hints |

### 6.2 Key Features

- Multi-row headers (Group → Column → Stat letter)
- Base row with n values
- Data rows (values from JSON)
- Tables stitched into single workbook

### 6.3 Hints Processing

Process hints in ExcelJS by combining R-calculated values:

```typescript
// hint === 'scale-5': Add T2B (values 4+5), B2B (1+2), Middle (3)
const t2b_count = row_4.count + row_5.count;
const t2b_pct = round((t2b_count / base_n) * 100);

// hint === 'ranking': Add combined rank rows
// hint === 'scale-7': Add T3B, B3B, etc.
```

### 6.4 Input

Reads `results/tables.json` from R output.

---

## Step 7: Excel Cleanup Agent (Optional)

**Goal**: Use the survey/questionnaire document to polish labels before final Excel output.

### 7.1 Context

This is the **first agent in the pipeline that sees the actual survey document** (`leqvio-demand-survey.docx` in practice files). Previous agents work from:
- Datamap (variable definitions)
- Banner plan (cut definitions)
- SPSS data (raw values)

The survey contains the actual question text as presented to respondents.

### 7.2 Responsibilities

| Field | What Agent Adjusts |
|-------|-------------------|
| Question labels | Rewrite for clarity if needed |
| Answer labels | Match survey wording if datamap differs |
| Table titles | Clean formatting |

**Not adjusted**: Data values, calculations, structure

### 7.3 Why This Matters

Without this step:
- Labels come from datamap (often abbreviated/coded)
- Question text may not match what respondents saw
- Some variables may lack descriptive labels entirely

With this step:
- Labels match the actual survey instrument
- Output is immediately usable for reports
- Less manual cleanup required

### 7.4 Implementation Notes

- Input: Table JSON + survey document (parsed)
- Output: Adjusted label fields only
- Structured output with Zod schema (only adjustable fields)
- Confidence scoring for changes (high = exact match found, low = inference)

---

## After This Architecture

Once Steps 6-7 complete and validated against `data/test-data/practice-files/`:
→ Return to `docs/implementation-plans/pre-phase-2-testing-plan.md` (Milestone 2 continues there)

---

*Created: January 3, 2026*
*Updated: January 3, 2026 - Steps 4+5 complete, added 5.5 flag and Step 7 plan*
