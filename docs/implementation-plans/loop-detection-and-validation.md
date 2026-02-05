# Loop Detection & Data Validation Implementation Plan

## Overview

This document consolidates the design work for HawkTab AI's data validation layer, including loop detection, format handling, and early error catching. The goal is to validate inputs before they reach the pipeline, catching problems early and providing clear guidance to users.

**Key Design Decisions:**
1. **Wide format only** — We don't process already-stacked data. If we detect stacking, we ask users for the original wide format.
2. **R + Haven for all data reading** — Consistency with the pipeline. No JavaScript SPSS readers.
3. **Gemini's diversity approach for loop detection** — More robust than regex, handles exotic naming patterns.
4. **Weights deferred to Part 5** — Not in scope for this implementation.

**Original Analysis (git history):**
- `loop-detection-evaluation.md` — Validation of diversity approach on Tito's data
- `loop-detection-comparison.md` — Comparison with existing regex approach
- `data-validation-layer.md` — 5-stage validation flow design
- `datamap-parser-analysis.md` — Format detection findings
- `datamap-enrichment-proposal.md` — Variable classification proposals

---

## Scope

### In Scope
- Format detection (Antares vs SPSS Variable Info)
- DataMap validation (structure, variables)
- Data file validation (via R + Haven)
- Cross-validation (DataMap ↔ Data file)
- Loop detection (Gemini's tokenization + diversity approach)
- Fill-rate validation (catch "stacked disguised as wide")
- User-facing error messages and guidance

### Out of Scope (Part 3)
- Weight detection (deferred to Part 5)
- Auto-stacking transformation (we require wide format)
- New SPSS Variable Info parser implementation (separate task)
- Research type classification (deferred)

---

## Architecture

```
User uploads files
        ↓
┌─────────────────────────────────────┐
│ Stage 1: File Validation            │
│ - Files exist and parseable?        │
│ - DataMap format detected?          │
└─────────────────────────────────────┘
        ↓ (Block if fails)
┌─────────────────────────────────────┐
│ Stage 2: DataMap Validation         │
│ - Variables extracted?              │
│ - Survey vars identified?           │
└─────────────────────────────────────┘
        ↓ (Block if no survey vars)
┌─────────────────────────────────────┐
│ Stage 3: Data File Validation       │
│ - Has rows/columns? (via R)         │
│ - Stacking columns present?         │
└─────────────────────────────────────┘
        ↓
┌─────────────────────────────────────┐
│ Stage 4: Cross-Validation           │
│ - DataMap ↔ Data column match?      │
│ - >50% match required               │
└─────────────────────────────────────┘
        ↓ (Block if <50% match)
┌─────────────────────────────────────┐
│ Stage 5: Loop Validation            │
│ - Detect loops (diversity approach) │
│ - If loops found:                   │
│   - Check fill rates per iteration  │
│   - _2 empty? → Ask for wide format │
│   - All have data? → Valid wide     │
└─────────────────────────────────────┘
        ↓
Pipeline proceeds OR user action required
```

---

## Loop Detection Algorithm

### Why Diversity-Based Detection?

The core insight from Gemini's proposal: **a loop has many distinct question roots sharing an iterator, while a grid has one question root with multiple indices.**

| Pattern | Diversity | Classification |
|---------|-----------|----------------|
| `A1_1, A2_1, A3_1, A4_1` (4 bases share `_1`) | High (4) | Loop ✓ |
| `A22r1, A22r2, A22r3` (1 base, different rows) | Low (1) | Grid ✗ |

This works because loops repeat the same questions across iterations (Location 1, Location 2), so many different question bases (A1, A2, A3...) all share the same iterator suffix (_1, _2).

### Algorithm Steps

#### Step 1: Tokenize Variable Names

Break variable names into tokens of letters and numbers:

```typescript
function tokenize(varName: string): Token[] {
  // "A4_1" → ['A', '4', '_', '1']
  // "A22r1c1" → ['A', '22', 'r', '1', 'c', '1']
  // "Q1L1" → ['Q', '1', 'L', '1']
}

interface Token {
  type: 'alpha' | 'numeric' | 'separator';
  value: string;
}
```

#### Step 2: Create Skeletons

Replace actual values with type markers:

```typescript
function createSkeleton(tokens: Token[]): string {
  // ['A', '4', '_', '1'] → 'A-N-_-N'
  // ['A', '22', 'r', '1', 'c', '1'] → 'A-N-r-N-c-N'
}
```

#### Step 3: Group by Skeleton

Variables with the same skeleton might be part of a loop:

```typescript
const skeletonGroups: Map<string, string[]> = new Map();
// 'A-N-_-N' → ['A1_1', 'A2_1', 'A3_1', 'A1_2', 'A2_2', 'A3_2']
```

#### Step 4: Calculate Diversity at Each Position

For each numeric position in the skeleton, check how many unique "base" values exist:

```typescript
// Skeleton: A-N-_-N has 2 numeric positions
// Position 1 (the question number): ['1', '2', '3'] from both _1 and _2 → diversity = 3
// Position 3 (the iterator): ['1', '2'] → check diversity of bases PER iteration

// For position 3:
// _1: ['A1', 'A2', 'A3'] → diversity = 3 bases
// _2: ['A1', 'A2', 'A3'] → diversity = 3 bases
// Average diversity = 3
```

**The iterator position is the one where:**
1. Multiple iterations exist (at least 2 values)
2. Each iteration contains many different bases (high diversity)

#### Step 5: Select Iterator Position

Pick the position with **highest diversity** per iteration value. This handles complex patterns like `A1_1r1c1` where multiple positions vary.

### TypeScript Interface

```typescript
interface LoopDetectionResult {
  hasLoops: boolean;
  confidence: 'high' | 'medium' | 'low';
  loopGroups: LoopGroup[];
  warnings: string[];
}

interface LoopGroup {
  skeleton: string;                 // 'A-N-_-N'
  iteratorPosition: number;         // Which token position is the iterator
  iterations: string[];             // ['1', '2']
  baseVariables: string[];          // ['A1', 'A2', 'A3', ...]
  diversity: number;                // Internal diversity score
  sampleVariables: string[];        // Examples for UI: ['A1_1', 'A1_2', ...]
}
```

### Test Cases

| Test | Input | Expected |
|------|-------|----------|
| Standard loop | `A1_1, A2_1, A1_2, A2_2` | Detect loop at `_N` position |
| Grid (reject) | `A22r1c1, A22r1c2, A22r2c1` | Reject (diversity 1, only A22) |
| Nested grid in loop | `C2_1r1c1, C2_1r2c1, C2_2r1c1` | Detect `_1/_2` loop, ignore `r/c` grid |
| Iterator at end | `Q1L1, Q2L1, Q1L2` | Detect loop at `LN` position |
| Iterator at start | `L1Q1, L1Q2, L2Q1` | Detect loop at position 0 |
| No loop | `S1, S2, S3, S4` | No loop detected |

---

## Fill-Rate Validation

### Purpose

Loop detection identifies the **pattern**. Fill-rate validation confirms the **data** matches expectations.

If we detect a loop pattern but `_2` columns are empty, the data has likely already been stacked. We don't process stacked data — we ask for the original wide format.

### Algorithm

```typescript
interface LoopFillRateResult {
  status: 'valid_wide' | 'likely_stacked' | 'uncertain';
  message: string;
  recommendation: string | null;
}

async function validateLoopFillRates(
  loopGroup: LoopGroup,
  dataReader: RDataReader
): Promise<LoopFillRateResult> {

  const fillRates: Map<string, number> = new Map();

  for (const iteration of loopGroup.iterations) {
    let totalCells = 0;
    let nonNullCells = 0;

    for (const baseVar of loopGroup.baseVariables) {
      const colName = `${baseVar}_${iteration}`;  // Reconstruct column name
      const stats = await dataReader.getColumnStats(colName);

      if (stats) {
        totalCells += stats.rowCount;
        nonNullCells += stats.nonNullCount;
      }
    }

    fillRates.set(iteration, nonNullCells / totalCells);
  }

  return analyzePattern(fillRates);
}

function analyzePattern(fillRates: Map<string, number>): LoopFillRateResult {
  const rates = Array.from(fillRates.values());
  const first = rates[0] || 0;
  const others = rates.slice(1);
  const avgOthers = others.reduce((a, b) => a + b, 0) / others.length;

  // Pattern: First has data, others are empty → Already stacked
  if (first > 0.1 && avgOthers < 0.01) {
    return {
      status: 'likely_stacked',
      message: `Loop iteration _1 has ${(first * 100).toFixed(0)}% fill rate, but _2+ are empty.`,
      recommendation: 'Please provide the original wide format data.'
    };
  }

  // Pattern: All have similar data → Valid wide format
  if (Math.abs(first - avgOthers) < 0.3) {
    return {
      status: 'valid_wide',
      message: 'Loop iterations have expected data distribution.',
      recommendation: null
    };
  }

  // Pattern: Decreasing fill rates → Expected dropout (valid wide)
  if (rates.every((r, i) => i === 0 || r <= rates[i - 1])) {
    return {
      status: 'valid_wide',
      message: 'Loop iterations show expected dropout pattern.',
      recommendation: null
    };
  }

  return {
    status: 'uncertain',
    message: 'Unable to determine data format from fill patterns.',
    recommendation: 'Please confirm this is wide (unstacked) format.'
  };
}
```

### Why This Matters

| Data State | `_1` Fill Rate | `_2` Fill Rate | Action |
|------------|----------------|----------------|--------|
| Wide format (correct) | 85% | 60% | Proceed |
| Already stacked | 85% | 0-1% | Ask for wide format |
| No loop (misdetected) | Varies | N/A | Skip validation |

---

## Format Detection

### DataMap Format Detection

Based on analysis of 26 datamap files:
- **Antares Standard**: 12% (currently supported)
- **SPSS Variable Info**: 81% (not yet supported)
- **SPSS Values Only**: 8% (unusable without variable info)

```typescript
type DataMapFormat = 'antares' | 'spss_variable_info' | 'spss_values_only' | 'unknown';

function detectDataMapFormat(content: string): DataMapFormat {
  // Antares: Has [variable]: pattern for question definitions
  if (/^\[[\w_]+\]:/.test(content)) {
    return 'antares';
  }

  // SPSS Variable Info: Has header row with Position, Label, etc.
  if (content.includes('Variable,Position,Label') ||
      content.includes('Variable Information')) {
    return 'spss_variable_info';
  }

  // SPSS Values Only: Has Variable Values section but no Variable Information
  if (content.includes('Variable Values') &&
      !content.includes('Variable Information')) {
    return 'spss_values_only';
  }

  return 'unknown';
}
```

### Stacking Column Detection

Check for columns that indicate already-stacked data:

```typescript
const STACKING_INDICATORS = [
  'LOOP', 'ITERATION', 'OBSERVATION', 'WAVE', 'LOOP_ID', 'OBS'
];

function detectStackingColumns(columns: string[]): string[] {
  return columns.filter(col =>
    STACKING_INDICATORS.some(ind =>
      col.toUpperCase() === ind || col.toUpperCase().includes(`_${ind}`)
    )
  );
}
```

---

## Data Reading with R + Haven

### Why R Instead of JavaScript?

| Aspect | R + Haven | JS SPSS Readers |
|--------|-----------|-----------------|
| SPSS compatibility | Full (industry standard) | Partial |
| Value labels | Complete support | Often incomplete |
| Missing values | Proper handling | Frequently wrong |
| Production path | Same as pipeline | Different code path |

Using the same data reading path for validation and processing means we catch the same issues early.

### Implementation Pattern

```r
# scripts/validation.R
library(haven)
library(jsonlite)

validate_data_file <- function(data_path) {
  # Read with haven
  data <- read_sav(data_path)

  # Column stats
  columns <- names(data)
  row_count <- nrow(data)

  # Fill rates for loop validation
  fill_rates <- sapply(data, function(col) {
    sum(!is.na(col) & col != "") / length(col)
  })

  # Stacking column detection
  stacking_cols <- columns[grepl("LOOP|ITERATION|OBSERVATION|WAVE",
                                   columns, ignore.case = TRUE)]

  list(
    columns = columns,
    row_count = row_count,
    fill_rates = as.list(fill_rates),
    stacking_columns = stacking_cols
  )
}

# Output JSON for Node consumption
result <- validate_data_file(commandArgs(trailingOnly = TRUE)[1])
cat(toJSON(result, auto_unbox = TRUE))
```

```typescript
// src/lib/validation/RDataReader.ts
import { execSync } from 'child_process';

export class RDataReader {
  constructor(private dataPath: string) {}

  async getStats(): Promise<DataFileStats> {
    const result = execSync(
      `Rscript --vanilla scripts/validation.R "${this.dataPath}"`,
      { encoding: 'utf-8' }
    );
    return JSON.parse(result);
  }

  async getColumnFillRate(column: string): Promise<number> {
    const stats = await this.getStats();
    return stats.fill_rates[column] || 0;
  }
}
```

---

## User-Facing Messages

### Success States

```
✓ Files validated successfully
  • DataMap: 192 survey variables (Antares format)
  • Data: 500 respondents, 237 columns
  • Loop pattern: None detected
```

```
✓ Loop pattern detected
  • Found 12 questions that repeat across 2 iterations
  • Sample: A1_1/A1_2, A2_1/A2_2, A3_1/A3_2...
  • Data format: Valid wide format
  • Ready to proceed
```

### Warning States

```
⚠️ Possible stacking column detected

Found column named "LOOP" in your data file.

If this data is already stacked, please provide the original
wide format for best results.

[This is wide format, proceed]  [Upload different file]
```

```
⚠️ Loop iterations appear empty

We detected a loop pattern (A1_1, A1_2, etc.) but the _2
columns have no data.

This usually means the data has already been stacked.
Please provide the original wide format.

[Upload wide format]  [Proceed anyway (not recommended)]
```

### Error States

```
✗ DataMap format not recognized

We support Antares and SPSS Variable Information formats.

Your file appears to be: SPSS Values Only
This format doesn't include question text, which we need.

Please export the full Variable Information from SPSS.
```

```
✗ DataMap and data file don't match

Only 23% of datamap variables were found in the data file.

This usually means:
• Wrong version of the datamap
• Wrong data file
• Files from different surveys

Please verify you're uploading matching files.
```

---

## Implementation Location

```
src/lib/validation/
├── index.ts                    # ValidationRunner - orchestrates stages
├── FileValidator.ts            # Stage 1 - file existence and parsing
├── DataMapValidator.ts         # Stage 2 - structure validation
├── DataFileValidator.ts        # Stage 3 - calls R for data stats
├── CrossValidator.ts           # Stage 4 - datamap ↔ data matching
├── LoopValidator.ts            # Stage 5 - detection + fill rates
├── RDataReader.ts              # R + Haven integration
└── types.ts                    # Shared interfaces

scripts/
├── validation.R                # R script for data file operations
└── loop-validation.R           # R script for fill rate analysis

src/schemas/
└── validation.ts               # Zod schemas for validation results
```

---

## TypeScript Interfaces

```typescript
// Validation Result Types

interface ValidationResult {
  valid: boolean;
  stage: 'file' | 'datamap' | 'datafile' | 'cross' | 'loop';
  errors: ValidationError[];
  warnings: ValidationWarning[];
}

interface ValidationError {
  code: string;
  message: string;
  userMessage: string;
  action: 'block';
}

interface ValidationWarning {
  code: string;
  message: string;
  userMessage: string;
  action: 'warn' | 'confirm';
  confirmOptions?: string[];
}

// Loop Detection Types

interface LoopDetectionResult {
  hasLoops: boolean;
  confidence: 'high' | 'medium' | 'low';
  loopGroups: LoopGroup[];
  warnings: string[];
}

interface LoopGroup {
  skeleton: string;
  iteratorPosition: number;
  iterations: string[];
  baseVariables: string[];
  diversity: number;
  sampleVariables: string[];
}

// Fill Rate Validation Types

interface LoopFillRateResult {
  status: 'valid_wide' | 'likely_stacked' | 'uncertain';
  message: string;
  recommendation: string | null;
}

// Format Detection Types

type DataMapFormat = 'antares' | 'spss_variable_info' | 'spss_values_only' | 'unknown';

interface FormatDetectionResult {
  format: DataMapFormat;
  confidence: number;
  signals: string[];
}
```

---

## What This Catches

| Issue | Stage | Action |
|-------|-------|--------|
| Wrong file format | 1 | Block |
| Corrupted files | 1 | Block |
| Wrong datamap version | 4 | Block (if <50% match) |
| Mismatched files | 4 | Block |
| Already stacked data | 5 | Warn + ask for wide |
| LOOP column in data | 3 | Warn |
| Empty survey | 2 | Block |
| SPSS Values Only format | 1 | Block with guidance |

## What This Doesn't Catch

| Issue | Why Not | Workaround |
|-------|---------|------------|
| Wrong answer option labels | Can't validate without survey doc | VerificationAgent review |
| Skip logic errors | Not in datamap | BaseFilterAgent inference |
| Piped text issues | Runtime data dependency | Manual review |
| Weight variable issues | Deferred to Part 5 | User confirmation later |

---

## Testing Plan

### Unit Tests

1. **Tokenization**: Test various naming patterns
2. **Skeleton creation**: Verify consistent skeleton generation
3. **Diversity calculation**: Test against known loop/grid patterns
4. **Fill rate analysis**: Test pattern recognition

### Integration Tests

1. **Tito's Growth Strategy**: Known looped survey, already stacked
2. **Leqvio Monotherapy**: No loops, Antares format
3. **Synthetic test cases**: Create edge case files

### Test Data Location

```
data/titos-future-growth/       # Loop test case
data/leqvio-monotherapy/        # Non-loop baseline
test-data/validation/           # Synthetic edge cases
```

---

## Success Criteria

- [ ] Correctly detect loop patterns using diversity approach
- [ ] Correctly identify already-stacked data via fill rates
- [ ] Block with clear message when data appears stacked
- [ ] Handle both Antares and SPSS Variable Info formats
- [ ] Cross-validate datamap ↔ data with >50% threshold
- [ ] All validation runs via R + Haven (no JS SPSS readers)
- [ ] User-facing messages are clear and actionable

---

*Created: February 5, 2026*
*Consolidated from: loop-detection-evaluation.md, loop-detection-comparison.md, data-validation-layer.md, datamap-parser-analysis.md, datamap-enrichment-proposal.md*
