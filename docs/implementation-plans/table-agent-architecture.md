# Table Agent Architecture

## Overview

TableAgent replaces regex-based table detection with AI reasoning. The agent decides how survey data should be displayed as crosstabs based on `normalizedType` from the datamap.

**Core insight**: We're replacing a human (Joe) doing knowledge work, not replacing deterministic code. AI handles survey variation; regex doesn't scale across 23+ datasets.

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

## Completed Steps (0-3.5)

| Step | What Was Done |
|------|---------------|
| 0 | Per-agent env variables (`TABLE_MODEL`, `TABLE_PROMPT_VERSION`) |
| 1 | Agent structure: `TableAgent.ts`, `tableAgentSchema.ts`, `prompts/table/` |
| 2 | Survey processor - **Deferred** (datamap has sufficient context) |
| 3 | Alternative prompt with 2 table types (frequency, mean_rows), hints, row limit rule |
| 3.5 | Standalone test script (`scripts/test-table-agent.ts`) |

**Key outputs from Step 3:**
- `TableAgentOutput` with `tableType: 'frequency' | 'mean_rows'`
- `hints: ('ranking' | 'scale-5' | 'scale-7')[]` for downstream T2B/B2B
- `filterValue` on each row (value code for frequency, empty for mean_rows)

---

## Implementation Order

| Step | Description | Status |
|------|-------------|--------|
| **5** | R Script Generator V2 | 🔄 In Progress |
| 4 | API Route Integration | ⏳ After Step 5 |
| 6 | ExcelJS Formatter | ⏳ After Steps 4+5 |
| — | Delete old files | ⏳ After verification |

---

## Step 5: R Script Generator V2

**Goal**: Create `RScriptGeneratorV2.ts` that consumes `TableAgentOutput[]` and outputs JSON.

### 5.1 Input/Output

**Input:**
```typescript
interface RScriptV2Input {
  tables: TableDefinition[];    // From TableAgentOutput[].tables.flat()
  cuts: CutDefinition[];        // From CutsSpec (unchanged)
}
```

**Output:** `temp-outputs/output-<ts>/results/tables.json`

### 5.2 R Script Structure

```r
library(haven)
library(dplyr)
library(jsonlite)

data <- read_sav("dataFile.sav")

# Cuts from CrosstabAgent (unchanged)
cuts <- list(
  Total = rep(TRUE, nrow(data)),
  `Male` = with(data, S2 == 1),
  ...
)

# Helper functions
apply_cut <- function(data, cut_mask) {
  safe_mask <- cut_mask
  safe_mask[is.na(safe_mask)] <- FALSE
  data[safe_mask, ]
}

round_half_up <- function(x, digits = 0) {
  floor(x * 10^digits + 0.5) / 10^digits
}

# Generate tables (see 5.3 for logic)
all_results <- list()
# ... table generation ...

write_json(all_results, "results/tables.json", pretty = TRUE, auto_unbox = TRUE)
```

### 5.3 Table Type Logic

**FREQUENCY TABLE** (`tableType === 'frequency'`):

```r
# For each row: count where variable == filterValue
for (row in table$rows) {
  # BASE = who answered this question (CRITICAL: rebase on non-NA)
  base_n <- sum(!is.na(cut_data[[row$variable]]))

  # COUNT = who selected this value
  count <- sum(cut_data[[row$variable]] == row$filterValue, na.rm = TRUE)

  # PERCENT
  pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0
}
```

**MEAN_ROWS TABLE** (`tableType === 'mean_rows'`):

```r
# For each row: calculate mean/median/sd
for (row in table$rows) {
  valid_vals <- cut_data[[row$variable]][!is.na(cut_data[[row$variable]])]

  n <- length(valid_vals)
  mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA
  median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA
  sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA
}
```

### 5.4 Base Sizing (CRITICAL)

Every calculation must rebase on who answered the question:

```r
# Step 1: Apply banner cut
cut_data <- apply_cut(data, cuts[[cut_name]])

# Step 2: Rebase on question respondents (non-NA)
base_n <- sum(!is.na(cut_data[[variable]]))

# Step 3: Calculate within that base
count <- sum(cut_data[[variable]] == value, na.rm = TRUE)
```

**Why**: Total sample = 180, but Q5 asked to 120 (skip logic). Q5 × Male = males who answered Q5, not all males.

### 5.5 JSON Output Format

```json
{
  "metadata": {
    "generatedAt": "2026-01-04T...",
    "tableCount": 42,
    "cutCount": 19
  },
  "tables": {
    "s8": {
      "tableId": "s8",
      "title": "Professional Time Allocation",
      "tableType": "mean_rows",
      "hints": [],
      "data": {
        "Total": {
          "S8r1": { "label": "Treating patients", "n": 180, "mean": 65.2, "median": 70.0, "sd": 18.4 }
        },
        "Male": {
          "S8r1": { "label": "Treating patients", "n": 90, "mean": 62.1, "median": 65.0, "sd": 17.2 }
        }
      }
    },
    "q1": {
      "tableId": "q1",
      "title": "Gender",
      "tableType": "frequency",
      "hints": [],
      "data": {
        "Total": {
          "Q1_row_1": { "label": "Male", "n": 180, "count": 90, "pct": 50 }
        }
      }
    }
  }
}
```

### 5.6 Hints Processing

**Decision**: Process hints in ExcelJS, not R.

R calculates individual values. ExcelJS combines them:
```typescript
// hint === 'scale-5': Add T2B (values 4+5), B2B (1+2), Middle (3)
const t2b_count = row_4.count + row_5.count;
const t2b_pct = round((t2b_count / base_n) * 100);
```

### 5.7 Implementation Checklist

| Task | Status |
|------|--------|
| Create `src/lib/r/RScriptGeneratorV2.ts` | Pending |
| Implement frequency table generation | Pending |
| Implement mean_rows table generation | Pending |
| Add JSON output | Pending |
| Test with TableAgent output | Pending |
| Verify base sizing | Pending |

---

## Step 4: API Route Integration

**Goal**: Replace old TablePlan flow with TableAgent + RScriptGeneratorV2.

### 4.1 Current Flow (to be replaced)

```typescript
// OLD (route.ts lines 244-265):
const tablePlan = buildTablePlanFromDataMap(dataMap);  // regex-based
const cutsSpec = buildCutsSpec(validation);
const manifest = buildRManifest(...);
const masterScript = generateMasterRScript(manifest, ...);  // outputs CSV
```

### 4.2 New Flow

```typescript
// NEW:
import { processDataMap } from '../../../agents/TableAgent';
import { generateRScriptV2 } from '../../../lib/r/RScriptGeneratorV2';

// Run TableAgent
const { results: tableAgentResults } = await processDataMap(dataMap, outputFolder);
const allTables = tableAgentResults.flatMap(r => r.tables);

// Get cuts (unchanged)
const cutsSpec = buildCutsSpec(validation);

// Generate R script V2
const masterScript = generateRScriptV2({
  tables: allTables,
  cuts: cutsSpec.cuts
});
```

### 4.3 Changes Required

| Location | Change |
|----------|--------|
| Imports | Add `processDataMap`, `generateRScriptV2` |
| Line ~162 | Add TableAgent step after CrosstabAgent |
| Line ~244 | Replace `buildTablePlanFromDataMap()` |
| Line ~263 | Replace `generateMasterRScript()` |
| Remove | Old manifest building code |

---

## Step 6: ExcelJS Formatter

**Goal**: Format JSON output into Antares-style Excel workbook.

### 6.1 Responsibilities

| Component | Job |
|-----------|-----|
| R | Calculate values (n, count, %, mean, median, sd) |
| ExcelJS | Place values in cells, apply formatting |

### 6.2 Key Features

- Multi-row headers (Group → Column → Stat letter)
- Base row with n values
- Data rows (values from JSON)
- Hints processing (T2B, B2B for scale-5/7)
- Tables stitched into single workbook

### 6.3 Input

Reads `results/tables.json` from R output.

---

## Post-Implementation: Code Cleanup

**DELETE after Steps 4+5 verified:**

| File | Reason |
|------|--------|
| `src/lib/tables/TablePlan.ts` | Replaced by TableAgent |
| `src/lib/r/RScriptGenerator.ts` | Replaced by RScriptGeneratorV2 |
| `src/lib/r/Manifest.ts` | No longer needed |
| `src/lib/tables/CutsSpec.ts` | Keep - still used |

Also remove imports of deleted files from route.ts.

**No fallback. Full replacement.**

---

## Testing Strategy

### Local (Step 5)
1. Run `scripts/test-table-agent.ts` to get TableAgent output
2. Generate R script with RScriptGeneratorV2
3. Execute `Rscript master.R`
4. Inspect `results/tables.json`

### Full Pipeline (Step 4)
1. Run API with test files
2. Check temp-outputs for all outputs
3. Verify JSON structure
4. Spot-check calculations against SPSS

---

*Created: January 3, 2026*
*Updated: January 4, 2026 - Simplified to focus on Steps 4-6 (Steps 0-3.5 complete)*
