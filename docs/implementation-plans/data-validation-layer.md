# Data Validation Layer

## Purpose

Catch problems early, before they propagate through the pipeline. Every validation should either:
1. **Block** - Stop pipeline with clear error
2. **Warn** - Continue but flag for user attention
3. **Auto-fix** - Correct silently (only for unambiguous issues)

---

## Validation Stages

```
┌─────────────────────────────────────────────────────────────────────┐
│  Stage 1: File Validation                                           │
│  "Do we have what we need?"                                         │
├─────────────────────────────────────────────────────────────────────┤
│  Stage 2: DataMap Validation                                        │
│  "Can we understand the survey structure?"                          │
├─────────────────────────────────────────────────────────────────────┤
│  Stage 3: Data File Validation                                      │
│  "Is the data in expected format?"                                  │
├─────────────────────────────────────────────────────────────────────┤
│  Stage 4: Cross-Validation (DataMap ↔ Data)                         │
│  "Do the files match each other?"                                   │
├─────────────────────────────────────────────────────────────────────┤
│  Stage 5: Loop Validation                                           │
│  "Is this really wide format as claimed?"                           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Stage 1: File Validation

**What we check:**

| Check | Action | Rationale |
|-------|--------|-----------|
| DataMap file exists | Block | Can't proceed without it |
| Data file exists | Block | Can't proceed without it |
| DataMap is parseable CSV | Block | Corrupted file |
| Data file is parseable (CSV/SAV) | Block | Corrupted file |
| DataMap format detected | Block | Must be Antares or SPSS Variable Info |
| Banner file exists (if provided) | Warn | Can proceed without banner |

**Output:**
```typescript
interface FileValidationResult {
  valid: boolean;
  dataMapFormat: 'antares' | 'spss_variable_info' | 'unknown';
  dataFileFormat: 'csv' | 'sav';
  warnings: string[];
  errors: string[];
}
```

---

## Stage 2: DataMap Validation

**What we check:**

| Check | Action | Rationale |
|-------|--------|-----------|
| At least 1 survey variable extracted | Block | Parser failure or wrong format |
| At least 1 variable has answer options | Warn | Might be open-ended only survey |
| Variable count > 0 | Block | Empty datamap |
| Duplicate variable names | Block | Ambiguous references |
| Variables have descriptions | Warn | May affect table labels |

**Leveraging enriched datamap:**

```typescript
// With variable source classification
const surveyVars = variables.filter(v => v.variableSource === 'survey');
const adminVars = variables.filter(v => v.variableSource === 'admin');
const listVars = variables.filter(v => v.variableSource === 'list');

// Validation
if (surveyVars.length === 0) {
  return { valid: false, error: "No survey variables detected" };
}

if (surveyVars.length < 5) {
  warnings.push(`Only ${surveyVars.length} survey variables found. Is this the complete datamap?`);
}
```

**Output:**
```typescript
interface DataMapValidationResult {
  valid: boolean;
  stats: {
    totalVariables: number;
    surveyVariables: number;
    adminVariables: number;
    listVariables: number;
    qualityVariables: number;
    withAnswerOptions: number;
    withDescriptions: number;
  };
  researchType: ResearchTypeClassification;
  warnings: string[];
  errors: string[];
}
```

---

## Stage 3: Data File Validation

**What we check:**

| Check | Action | Rationale |
|-------|--------|-----------|
| Has rows | Block | Empty data file |
| Has columns | Block | Empty data file |
| Row count reasonable | Warn | <10 or >100k might indicate issues |
| No duplicate column names | Block | Ambiguous references |
| Has respondent ID column | Warn | Needed for stacking |

**Stacking indicator check:**

```typescript
// Check for columns that indicate already-stacked data
const STACKING_INDICATORS = ['LOOP', 'ITERATION', 'OBSERVATION', 'WAVE', 'LOOP_ID'];

const stackingColumns = dataColumns.filter(col =>
  STACKING_INDICATORS.some(ind => col.toUpperCase().includes(ind))
);

if (stackingColumns.length > 0) {
  warnings.push(
    `Found potential stacking columns: ${stackingColumns.join(', ')}. ` +
    `If this data is already stacked, please provide the original wide format.`
  );
}
```

**Output:**
```typescript
interface DataFileValidationResult {
  valid: boolean;
  stats: {
    rowCount: number;
    columnCount: number;
  };
  possibleStackingColumns: string[];
  warnings: string[];
  errors: string[];
}
```

---

## Stage 4: Cross-Validation (DataMap ↔ Data)

**What we check:**

| Check | Action | Rationale |
|-------|--------|-----------|
| All survey vars exist in data | Warn | Might be wrong datamap version |
| Extra columns in data (not in datamap) | Info | Might be computed/added later |
| >50% of datamap vars missing from data | Block | Likely mismatched files |
| ID column matches | Warn | Stacking needs consistent IDs |

**Implementation:**

```typescript
function crossValidate(dataMapVars: string[], dataColumns: string[]): CrossValidationResult {
  const dataMapSet = new Set(dataMapVars.map(v => v.toLowerCase()));
  const dataSet = new Set(dataColumns.map(c => c.toLowerCase()));

  const inDataMapNotData = dataMapVars.filter(v => !dataSet.has(v.toLowerCase()));
  const inDataNotDataMap = dataColumns.filter(c => !dataMapSet.has(c.toLowerCase()));

  const matchRate = (dataMapVars.length - inDataMapNotData.length) / dataMapVars.length;

  if (matchRate < 0.5) {
    return {
      valid: false,
      error: `Only ${(matchRate * 100).toFixed(0)}% of datamap variables found in data. Are these the right files?`
    };
  }

  const warnings = [];
  if (inDataMapNotData.length > 0) {
    warnings.push(`${inDataMapNotData.length} datamap variables not in data: ${inDataMapNotData.slice(0, 5).join(', ')}...`);
  }

  return { valid: true, matchRate, warnings, inDataMapNotData, inDataNotDataMap };
}
```

---

## Stage 5: Loop Validation

This is the critical validation for detecting format issues.

### 5a: Loop Detection

Using Gemini's tokenization + diversity approach to identify loop patterns:

```typescript
interface LoopDetectionResult {
  hasLoops: boolean;
  loopGroups: LoopGroup[];
  confidence: 'high' | 'medium' | 'low';
}

interface LoopGroup {
  baseVariables: string[];      // ['A1', 'A2', 'A3', ...]
  iterations: string[];         // ['1', '2']
  iteratorPosition: number;     // Position in token array
  diversity: number;            // Internal diversity score
  sampleVariables: string[];    // ['A1_1', 'A1_2', 'A2_1', ...]
}
```

### 5b: Loop Data Validation (The Key Check)

**If loops detected, validate that data matches claimed format:**

```typescript
async function validateLoopData(
  loopGroups: LoopGroup[],
  dataReader: DataReader  // Abstract interface to read columns
): Promise<LoopValidationResult> {

  const results: LoopGroupValidation[] = [];

  for (const group of loopGroups) {
    const iterationStats: Map<string, { total: number; nonNull: number }> = new Map();

    // Check data presence in each iteration
    for (const iteration of group.iterations) {
      let totalCells = 0;
      let nonNullCells = 0;

      for (const baseVar of group.baseVariables) {
        const colName = reconstructColumnName(baseVar, iteration, group.iteratorPosition);
        const columnData = await dataReader.getColumn(colName);

        if (columnData) {
          totalCells += columnData.length;
          nonNullCells += columnData.filter(v => v !== null && v !== '').length;
        }
      }

      iterationStats.set(iteration, { total: totalCells, nonNull: nonNullCells });
    }

    // Analyze pattern
    const validation = analyzeIterationPattern(iterationStats);
    results.push({ group, ...validation });
  }

  return aggregateResults(results);
}

function analyzeIterationPattern(
  stats: Map<string, { total: number; nonNull: number }>
): LoopGroupValidation {

  const entries = Array.from(stats.entries());
  const fillRates = entries.map(([iter, s]) => ({
    iteration: iter,
    fillRate: s.nonNull / s.total
  }));

  // Pattern 1: All iterations have similar fill rates → Wide format (expected)
  // Pattern 2: First iteration has data, others are empty → Already stacked!
  // Pattern 3: Decreasing fill rates → Wide format with dropout (expected for loops)

  const firstFillRate = fillRates[0]?.fillRate || 0;
  const otherFillRates = fillRates.slice(1).map(f => f.fillRate);
  const avgOtherFillRate = otherFillRates.reduce((a, b) => a + b, 0) / otherFillRates.length;

  // If first iteration has data but others are essentially empty
  if (firstFillRate > 0.1 && avgOtherFillRate < 0.01) {
    return {
      status: 'likely_stacked',
      message: `Loop iteration _1 has ${(firstFillRate * 100).toFixed(0)}% fill rate, but _2+ are empty. This data appears to be already stacked.`,
      recommendation: 'Please provide the original wide format data.'
    };
  }

  // If all iterations have similar data → normal wide format
  if (Math.abs(firstFillRate - avgOtherFillRate) < 0.3) {
    return {
      status: 'valid_wide',
      message: 'Loop iterations have expected data distribution.',
      recommendation: null
    };
  }

  // Decreasing fill rates → expected for loops (not everyone completes all iterations)
  if (fillRates.every((f, i) => i === 0 || f.fillRate <= fillRates[i-1].fillRate)) {
    return {
      status: 'valid_wide_with_dropout',
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

### 5c: Validation Output

```typescript
interface LoopValidationResult {
  formatStatus: 'valid_wide' | 'likely_stacked' | 'uncertain';
  loopGroups: LoopGroupValidation[];

  // Clear user-facing messages
  userMessage: string;
  userAction: 'proceed' | 'confirm' | 'block';

  // If stacking needed
  stackingRecommendation?: {
    shouldStack: boolean;
    iteratorColumn: string;  // What we'll call the LOOP column
    iterations: string[];     // ['1', '2']
    variablesToStack: string[];
  };
}
```

---

## Validation Flow Summary

```
User uploads files
        ↓
┌─────────────────────────────────────┐
│ Stage 1: File Validation            │
│ - Files exist?                      │
│ - Parseable?                        │
│ - Format detected?                  │
└─────────────────────────────────────┘
        ↓ (Block if fails)
┌─────────────────────────────────────┐
│ Stage 2: DataMap Validation         │
│ - Variables extracted?              │
│ - Survey vars identified?           │
│ - Research type classified?         │
└─────────────────────────────────────┘
        ↓ (Block if no survey vars)
┌─────────────────────────────────────┐
│ Stage 3: Data File Validation       │
│ - Has rows/columns?                 │
│ - Stacking columns present? (Warn)  │
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
│ - Detect loops (Gemini approach)    │
│ - If loops found:                   │
│   - Check fill rates per iteration  │
│   - _2 empty? → Likely stacked      │
│   - All have data? → Valid wide     │
└─────────────────────────────────────┘
        ↓
┌─────────────────────────────────────┐
│ Result                              │
│ - valid: boolean                    │
│ - warnings: string[]                │
│ - loopsDetected: boolean            │
│ - needsStacking: boolean            │
│ - stackingConfig: {...}             │
└─────────────────────────────────────┘
```

---

## User-Facing Messages

### Success States

```
✓ Files validated successfully
  • DataMap: 192 survey variables, 45 admin variables
  • Data: 500 respondents, 237 columns
  • Research type: Standard survey (high confidence)
```

```
✓ Loop pattern detected
  • Found 12 questions that repeat across 2 iterations
  • Sample: A1_1/A1_2, A2_1/A2_2, A3_1/A3_2...
  • We'll stack this automatically during processing
```

### Warning States

```
⚠️ Possible stacking column detected
  Found column named "LOOP" in your data file.

  If this data is already stacked, please provide the original
  wide format for best results.

  [This is wide format, proceed] [Upload different file]
```

```
⚠️ Loop iterations appear empty
  We detected a loop pattern (A1_1, A1_2, etc.) but the _2
  columns have no data.

  This usually means the data has already been stacked.
  Please provide the original wide format.

  [Upload wide format] [Proceed anyway (not recommended)]
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

## Data Reading: Use R + Haven

**Important:** All data file reading should use R with the `haven` package, not JavaScript-based SPSS readers.

### Why Haven, Not JS Libraries

| Aspect | R + Haven | JS SPSS Readers |
|--------|-----------|-----------------|
| SPSS compatibility | Full (industry standard) | Partial, edge cases break |
| Value labels | Complete support | Often incomplete |
| Missing value codes | Proper handling | Frequently wrong |
| Large files | Handles well | Memory issues |
| Production path | Same as final pipeline | Different code path = different bugs |

### Implementation Pattern

```r
# validation.R - Called from Node via child_process or Rscript

library(haven)
library(jsonlite)

validate_data_file <- function(data_path, datamap_vars) {
  # Read data with haven
  data <- read_sav(data_path)

  # Get column info
  columns <- names(data)
  row_count <- nrow(data)

  # Check for stacking indicators
  stacking_cols <- columns[grepl("LOOP|ITERATION|OBSERVATION", columns, ignore.case = TRUE)]

  # For loop validation: get fill rates per column
  fill_rates <- sapply(data, function(col) {
    sum(!is.na(col) & col != "") / length(col)
  })

  # Return as JSON for Node to consume
  result <- list(
    columns = columns,
    row_count = row_count,
    stacking_columns = stacking_cols,
    fill_rates = as.list(fill_rates)
  )

  toJSON(result, auto_unbox = TRUE)
}
```

```typescript
// ValidationRunner.ts - Node side

import { execSync } from 'child_process';

async function getDataFileStats(dataPath: string): Promise<DataFileStats> {
  const result = execSync(
    `Rscript --vanilla scripts/validation.R "${dataPath}"`,
    { encoding: 'utf-8' }
  );
  return JSON.parse(result);
}
```

### Consistency with Pipeline

This ensures validation uses the **same data reading path** as the rest of the pipeline:

```
Validation    →  R + Haven  →  Column stats, fill rates
TableGenerator → R + Haven  →  Actual crosstab calculations
Excel Output   → R + Haven  →  Final numbers
```

If validation reads data differently than the pipeline, we'd catch different errors than what actually happens. Same tools = same behavior.

### Docker Context

In production (Docker container with R image), this is the natural path anyway. The R + Haven approach is:
- How a professional statistician would do it
- What the pipeline already uses
- What will run in the cloud environment

---

## Implementation Location

```
src/lib/validation/
├── index.ts                    # Main ValidationRunner
├── FileValidator.ts            # Stage 1
├── DataMapValidator.ts         # Stage 2
├── DataFileValidator.ts        # Stage 3 (calls R for data reading)
├── CrossValidator.ts           # Stage 4
├── LoopValidator.ts            # Stage 5 (calls R for fill rates)
└── types.ts                    # Shared interfaces

scripts/
├── validation.R                # R script for data file operations
└── loop-validation.R           # R script for fill rate analysis
```

---

## What This Catches

| Issue | Stage | Action |
|-------|-------|--------|
| Wrong file format | 1 | Block |
| Corrupted files | 1 | Block |
| Wrong datamap version | 4 | Block (if <50% match) |
| Mismatched files | 4 | Block |
| Already stacked data | 5 | Warn + recommend |
| Loops needing stacking | 5 | Auto-configure |
| Empty survey | 2 | Block |
| Admin-only file | 2 | Block |

---

## What This Doesn't Catch

| Issue | Why Not | Workaround |
|-------|---------|------------|
| Wrong answer option labels | Can't validate without survey doc | VerificationAgent review |
| Skip logic errors | Not in datamap | BaseFilterAgent inference |
| Piped text issues | Runtime data dependency | Manual review |
| Weight variable misidentification | Heuristic-based | User confirmation |

---

*Created: February 5, 2026*
