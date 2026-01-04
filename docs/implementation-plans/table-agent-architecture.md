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
| 6 | ExcelJS Formatter | ⏳ Next |

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

*Created: January 3, 2026*
*Updated: January 4, 2026 - Steps 4+5 complete, Step 6 next*
