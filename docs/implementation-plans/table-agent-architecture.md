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
| 5.5 | R calculations enhancement (sig testing, outliers, rounding) | ✅ Complete |
| 6 | ExcelJS Formatter | ⏳ Next |
| 7 | VerificationAgent (survey → label cleanup) | 📋 Detailed plan ready |

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

## Step 5.5: R Calculations Enhancement

**Goal**: Enhance RScriptGeneratorV2 with significance testing, outlier-adjusted means, and proper rounding before moving to ExcelJS formatting.

### 5.5.1 Current State vs. Required

| Calculation | Current | Required | Notes |
|-------------|---------|----------|-------|
| Count per cell | ✅ | ✅ | `sum(cut_data[[variable]] == value)` |
| Percentage per cell | ✅ | ✅ | Rounded to whole number |
| Mean | ✅ | ✅ | Rounded to 1 decimal |
| Median | ✅ | ✅ | Rounded to 1 decimal |
| Standard Deviation | ✅ (2 dec) | ❌ (1 dec) | Change from 2 to 1 decimal |
| Mean (minus outliers) | ❌ | ⏳ | IQR-based outlier removal |
| Significance testing | ❌ | ⏳ | Z-test (proportions), T-test (means) |
| Base sizes (n) | ✅ | ✅ | `sum(!is.na(cut_data[[variable]]))` |

### 5.5.2 SD Rounding Fix

**Current** (line 289 in RScriptGeneratorV2.ts):
```r
sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA
```

**Required**:
```r
sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA
```

All summary stats (mean, median, SD) should use 1 decimal place. Percentages remain whole numbers.

### 5.5.3 Mean (Minus Outliers)

Add outlier-adjusted mean calculation using IQR method:

```r
# Calculate mean excluding outliers (IQR method)
calculate_mean_no_outliers <- function(x) {
  valid <- x[!is.na(x)]
  if (length(valid) < 4) return(NA)  # Need enough data for IQR

  q1 <- quantile(valid, 0.25)
  q3 <- quantile(valid, 0.75)
  iqr <- q3 - q1

  lower_bound <- q1 - 1.5 * iqr
  upper_bound <- q3 + 1.5 * iqr

  no_outliers <- valid[valid >= lower_bound & valid <= upper_bound]
  if (length(no_outliers) == 0) return(NA)

  return(round_half_up(mean(no_outliers), 1))
}
```

**Output in mean_rows tables**:
```json
{
  "label": "Leqvio (inclisiran)",
  "n": 175,
  "mean": 42.3,
  "mean_label": "Mean (overall)",
  "median": 40.0,
  "median_label": "Median (overall)",
  "sd": 12.1,
  "mean_no_outliers": 41.8,
  "mean_no_outliers_label": "Mean (minus outliers)"
}
```

The `_label` fields clarify what each stat represents. ExcelJS uses these for row labels.

### 5.5.4 Significance Testing

**Key requirement**: Compare columns **within groups** + compare each column to **Total**.

#### 5.5.4.1 Enhanced CutDefinition

Current `CutDefinition` loses group structure. Enhance to preserve stat testing context:

```typescript
// src/lib/tables/CutsSpec.ts (updated)

export type CutDefinition = {
  id: string;
  name: string;
  rExpression: string;
  statLetter: string;     // NEW: "A", "B", "C", etc.
  groupName: string;      // NEW: "Specialty", "Role", etc.
  groupIndex: number;     // NEW: Position within group (for comparison order)
};

export type CutGroup = {
  groupName: string;
  cuts: CutDefinition[];
};

export type CutsSpec = {
  cuts: CutDefinition[];
  groups: CutGroup[];     // NEW: Preserve group structure for stat testing
  totalCut: CutDefinition | null;  // NEW: Reference to Total column
};
```

#### 5.5.4.2 Updated buildCutsSpec

```typescript
export function buildCutsSpec(validation: ValidationResultType): CutsSpec {
  const cuts: CutDefinition[] = [];
  const groups: CutGroup[] = [];
  let totalCut: CutDefinition | null = null;

  for (const group of validation.bannerCuts) {
    const groupCuts: CutDefinition[] = [];

    for (let i = 0; i < group.columns.length; i++) {
      const col = group.columns[i];
      const id = `${slugify(group.groupName)}.${slugify(col.name)}`;
      const cut: CutDefinition = {
        id,
        name: col.name,
        rExpression: col.adjusted,
        statLetter: col.statLetter,
        groupName: group.groupName,
        groupIndex: i,
      };

      cuts.push(cut);
      groupCuts.push(cut);

      // Track Total column separately
      if (col.name === 'Total' || group.groupName === 'Total') {
        totalCut = cut;
      }
    }

    groups.push({ groupName: group.groupName, cuts: groupCuts });
  }

  return { cuts, groups, totalCut };
}
```

#### 5.5.4.3 R Significance Testing Functions

Add to helper functions in R script:

```r
# =============================================================================
# Significance Testing (90% confidence level, p < 0.10)
# =============================================================================

p_threshold <- 0.10  # 90% significance level

# Z-test for proportions (frequency tables)
sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {
  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size

  # Pooled proportion
  p_pool <- (count1 + count2) / (n1 + n2)
  if (p_pool == 0 || p_pool == 1) return(NA)  # Can't test

  # Standard error
  se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))
  if (se == 0) return(NA)

  # Z statistic
  p1 <- count1 / n1
  p2 <- count2 / n2
  z <- (p1 - p2) / se

  # Two-tailed p-value
  p_value <- 2 * (1 - pnorm(abs(z)))

  return(p_value < threshold)
}

# T-test for means (mean_rows tables)
sig_test_mean <- function(vals1, vals2, threshold = p_threshold) {
  n1 <- sum(!is.na(vals1))
  n2 <- sum(!is.na(vals2))

  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size

  tryCatch({
    result <- t.test(vals1, vals2, na.rm = TRUE)
    return(result$p.value < threshold)
  }, error = function(e) {
    return(NA)
  })
}
```

#### 5.5.4.4 Comparison Logic

For each cell, compare:
1. **Within-group**: Compare to other columns in the same group
2. **To Total**: Compare to the Total column

```r
# For a frequency cell in column A (group: Specialty)
# Compare to: B, C, D, E (same group) + T (Total)
# Output: sig_vs = ["B", "C"]  # A is significantly higher than B and C
#         sig_vs_total = TRUE  # A is significantly different from Total
```

#### 5.5.4.5 Updated Output Structure

**Note**: Only `sig_higher_than` is needed. If A is significantly higher than B, that implicitly means B is lower than A. No need for `sig_lower_than`.

**Frequency table cell**:
```json
{
  "label": "Statin only",
  "n": 175,
  "count": 98,
  "pct": 56,
  "sig_higher_than": ["B", "C"],
  "sig_vs_total": "higher"
}
```

**Mean_rows table cell**:
```json
{
  "label": "Leqvio (inclisiran)",
  "n": 175,
  "mean": 42.3,
  "median": 40.0,
  "sd": 12.1,
  "mean_no_outliers": 41.8,
  "sig_higher_than": ["B"],
  "sig_vs_total": null
}
```

### 5.5.5 RScriptV2 Input Changes

Extend input to include group structure for stat testing:

```typescript
// Current
export interface RScriptV2Input {
  tables: TableDefinition[];
  cuts: CutDefinition[];
  dataFilePath?: string;
}

// Updated
export interface RScriptV2Input {
  tables: TableDefinition[];
  cuts: CutDefinition[];
  cutGroups: CutGroup[];           // NEW: Preserve group structure
  totalStatLetter: string | null;  // NEW: Letter for Total column (usually "T")
  dataFilePath?: string;
  significanceLevel?: number;      // NEW: Default 0.10 (90% confidence)
}
```

### 5.5.6 SD Display Logic (Row Count Based)

**Problem**: Single-row mean tables (e.g., "how many hours at the doctor?") should show full stats (mean, median, SD, mean_no_outliers). Multi-row mean tables should just show mean per row.

**Solution**: ExcelJS determines display based on row count - no hint needed.

```typescript
// In ExcelJS formatter
const isSingleRow = table.rows.length === 1;

if (isSingleRow) {
  // Show full stats: mean, median, SD, mean_no_outliers
} else {
  // Show only mean per row (cleaner for multi-item tables)
}
```

R always calculates all stats. ExcelJS decides what to display based on table structure.

**Why row count is better than hints**:
- Deterministic - no AI inference needed
- Simpler - row count is already available
- Reliable - can't be "wrong" like a misidentified hint

### 5.5.7 Implementation Checklist

| Task | File(s) | Status |
|------|---------|--------|
| Fix SD rounding (2 → 1 decimal) | `RScriptGeneratorV2.ts` | ✅ |
| Add `calculate_mean_no_outliers` function | `RScriptGeneratorV2.ts` | ✅ |
| Enhance `CutDefinition` with `statLetter`, `groupName` | `CutsSpec.ts` | ✅ |
| Update `buildCutsSpec` to preserve groups | `CutsSpec.ts` | ✅ |
| Add significance testing helper functions | `RScriptGeneratorV2.ts` | ✅ |
| Update frequency table output with sig fields | `RScriptGeneratorV2.ts` | ✅ |
| Update mean_rows table output with sig fields | `RScriptGeneratorV2.ts` | ✅ |
| Update `RScriptV2Input` interface | `RScriptGeneratorV2.ts` | ✅ |
| Test with practice files | `scripts/test-pipeline.ts` | ⏳ Manual test needed |

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

## Step 7: VerificationAgent

**Goal**: Verify and enhance table labels against the actual survey document before Excel rendering.

### 7.1 The Problem

Current pipeline produces output like:
```json
{ "label": "Leqvio (inclisiran) - Value 1", "filterValue": "1" }
{ "label": "Praluent - Value 3", "filterValue": "3" }
```

Market researchers need:
```json
{ "label": "Leqvio (inclisiran) - Not at all likely", "filterValue": "1" }
{ "label": "Praluent - Somewhat likely", "filterValue": "3" }
```

**Root cause**: No agent in the current pipeline sees the survey document (`leqvio-demand-survey.docx`). Agents work from:
- Datamap (variable codes, abbreviated labels)
- Banner plan (cut definitions)
- SPSS data (raw values)

The survey contains:
- Actual question text as presented to respondents
- Scale anchors ("1 = Not at all likely", "5 = Extremely likely")
- Full response option wording

### 7.2 Pipeline Position

```
R JSON output → VerificationAgent → Cleaned JSON → ExcelJS Formatter
                       ↓
              Survey Document (→ Markdown)
```

The agent runs **after** R calculations, **before** ExcelJS formatting. This keeps:
- R output pure (data calculations only)
- ExcelJS simple (just render what it receives)
- Verification testable independently

### 7.3 Responsibilities

| Field | What Agent Adjusts | Example |
|-------|-------------------|---------|
| `row.label` | Add scale anchors, clarify wording | `"Value 1"` → `"Not at all likely (1)"` |
| `questionText` | Match survey wording if different | Clean up truncated text |
| `title` | Improve table title clarity | `"A6 - Items ranked #1"` → `"A6 - Treatment paths ranked first"` |

**NOT adjusted** (data integrity preserved):
- `variable` names
- `filterValue` codes
- Calculated values (n, %, mean, etc.)
- Table structure (`tableType`, row order)

### 7.4 Architecture

#### 7.4.1 Processing Strategy: Table-by-Table

Same pattern as CrosstabAgent and TableAgent:
- Process each table definition individually
- Inject survey markdown + table JSON into agent context
- Collect results, combine into final output
- Graceful fallback on errors (return original labels)

```typescript
for (const table of tableDefinitions) {
  const verified = await verifyTable(table, surveyMarkdown);
  results.push(verified);
}
```

#### 7.4.2 Survey → Markdown Conversion

New utility: `SurveyProcessor`

```typescript
// src/lib/processors/SurveyProcessor.ts
export async function parseSurveyToMarkdown(
  surveyPath: string
): Promise<string> {
  // 1. Detect file type (.docx, .pdf, .txt)
  // 2. Extract text content (mammoth for docx, pdf-parse for pdf)
  // 3. Convert to clean markdown
  // 4. Return markdown string
}
```

Output format:
```markdown
# Survey: Leqvio Demand Study

## S1. What is your primary specialty?
- 1 = Cardiology
- 2 = Endocrinology
- 3 = Internal Medicine
...

## A5. How likely are you to prescribe each treatment?
Scale: 1 = Not at all likely, 5 = Extremely likely

| Treatment | 1 | 2 | 3 | 4 | 5 |
|-----------|---|---|---|---|---|
| Leqvio    | ○ | ○ | ○ | ○ | ○ |
| Repatha   | ○ | ○ | ○ | ○ | ○ |
...
```

#### 7.4.3 Scratchpad Tool

Reuse existing scratchpad pattern for reasoning transparency:

```typescript
// src/agents/tools/scratchpad.ts - add verification entries
export const verificationScratchpadTool = tool({
  description: 'Log verification reasoning',
  parameters: z.object({
    action: z.enum(['LOOKUP', 'MATCH', 'CHANGE', 'KEEP', 'CONFIDENCE']),
    content: z.string(),
  }),
  execute: async ({ action, content }) => {
    addScratchpadEntry('verification', action, content);
    return { logged: true };
  }
});
```

---

### 7.5 Schemas

#### 7.5.1 Input Schema

```typescript
// src/schemas/verificationAgentSchema.ts

export const VerificationInputRowSchema = z.object({
  variable: z.string(),
  label: z.string(),
  filterValue: z.string(),
});

export const VerificationInputTableSchema = z.object({
  tableId: z.string(),
  title: z.string(),
  tableType: z.string(),
  questionId: z.string(),
  questionText: z.string(),
  rows: z.array(VerificationInputRowSchema),
  hints: z.array(z.string()),
});

export const VerificationAgentInputSchema = z.object({
  table: VerificationInputTableSchema,
  surveyMarkdown: z.string(),  // Full survey as markdown
});

export type VerificationAgentInput = z.infer<typeof VerificationAgentInputSchema>;
```

#### 7.5.2 Output Schema

```typescript
// Only fields the agent can modify (Azure OpenAI requires all fields)

export const VerifiedRowSchema = z.object({
  variable: z.string(),           // Pass-through (unchanged)
  label: z.string(),              // May be updated
  filterValue: z.string(),        // Pass-through (unchanged)
  labelChanged: z.boolean(),      // Did we modify the label?
  originalLabel: z.string(),      // For audit trail
});

export const VerificationAgentOutputSchema = z.object({
  tableId: z.string(),            // Pass-through
  title: z.string(),              // May be updated
  titleChanged: z.boolean(),
  questionText: z.string(),       // May be updated
  questionTextChanged: z.boolean(),
  rows: z.array(VerifiedRowSchema),

  // Confidence and reasoning
  confidence: z.number().min(0).max(1),
  reasoning: z.string(),

  // Summary stats for logging
  changesApplied: z.number(),     // Count of modified labels
});

export type VerificationAgentOutput = z.infer<typeof VerificationAgentOutputSchema>;
```

---

### 7.6 Environment Configuration

Add to `src/lib/env.ts`:

```typescript
// In getEnvironmentConfig():
const verificationModel = process.env.VERIFICATION_MODEL || 'gpt-5-nano';

// In processingLimits:
verificationModelTokens: parseInt(
  process.env.VERIFICATION_MODEL_TOKENS || '128000'
),

// Add getter functions:
export const getVerificationModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.verificationModel);
};

export const getVerificationModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.verificationModel}`;
};

export const getVerificationModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.verificationModelTokens;
};
```

Add to `src/lib/types.ts`:

```typescript
// In ProcessingLimits interface:
verificationModelTokens: number;

// In EnvironmentConfig interface:
verificationModel: string;

// In PromptVersions interface:
verificationPromptVersion: string;
```

Environment variables:
```bash
# .env.local
VERIFICATION_MODEL=gpt-5-nano          # Azure deployment name
VERIFICATION_MODEL_TOKENS=128000       # Token limit
VERIFICATION_PROMPT_VERSION=production # Prompt variant
```

---

### 7.7 Prompts

#### 7.7.1 Production Prompt

```typescript
// src/prompts/verification/production.ts

export const VERIFICATION_AGENT_INSTRUCTIONS_PRODUCTION = `
You are a survey research quality assurance specialist. Your job is to verify that crosstab table labels accurately reflect the survey instrument.

You have access to:
1. A table definition with variable names, labels, and filter values
2. The complete survey document in markdown format

YOUR TASK:
1. Find the question in the survey that corresponds to this table
2. Verify each row label matches the survey wording
3. For scale questions (1-5, 1-7, etc.), add scale anchor text to labels
4. Update question text if the survey wording is clearer
5. Improve table title if needed for clarity

---

SCALE ANCHORS (critical):

When you see labels like "Value 1", "Value 2", etc., look up the scale in the survey:
- Find the scale definition (e.g., "1 = Not at all likely, 5 = Extremely likely")
- Replace generic labels with descriptive text

Before: { "label": "Leqvio - Value 1", "filterValue": "1" }
After:  { "label": "Leqvio - Not at all likely (1)", "filterValue": "1" }

Include the numeric value in parentheses for reference.

---

MATCHING STRATEGY:

1. LOOKUP: Search survey markdown for question ID (e.g., "A5", "S12")
2. MATCH: Compare survey text with table labels
3. CHANGE: If survey wording is clearer or more complete, update the label
4. KEEP: If label already matches survey, leave unchanged

---

CONSTRAINTS:

DO NOT CHANGE:
- variable names (these are SPSS column names)
- filterValue codes (these map to data values)
- Table structure or row order
- Calculated values

ONLY CHANGE:
- label text (to match survey wording, add scale anchors)
- questionText (to match survey wording)
- title (for clarity)

---

USE YOUR SCRATCHPAD:

ENTRY 1 - LOOKUP: "Searching for question [ID] in survey..."
ENTRY 2 - MATCH: "Found question at [location]. Scale: [describe if applicable]."
ENTRY 3 - CHANGES: "Updating [N] labels: [list changes]."
ENTRY 4 - CONFIDENCE: "[0.X] - [reasoning]"

---

CONFIDENCE SCORING:

0.95-1.0: Exact match found in survey, scale anchors clear
0.85-0.94: Match found, minor wording differences resolved
0.70-0.84: Inferred match, some uncertainty
0.50-0.69: Partial match, may need review
Below 0.50: Could not locate in survey, no changes made

---

OUTPUT:

Return the verified table with:
- Updated labels where improvements found
- labelChanged: true for any modified row
- originalLabel preserved for audit
- Confidence score and reasoning
`;
```

#### 7.7.2 Prompt Index

```typescript
// src/prompts/verification/index.ts

import { VERIFICATION_AGENT_INSTRUCTIONS_PRODUCTION } from './production';
import { VERIFICATION_AGENT_INSTRUCTIONS_ALTERNATIVE } from './alternative';

export const getVerificationPrompt = (version: string): string => {
  switch (version) {
    case 'alternative':
      return VERIFICATION_AGENT_INSTRUCTIONS_ALTERNATIVE;
    case 'production':
    default:
      return VERIFICATION_AGENT_INSTRUCTIONS_PRODUCTION;
  }
};

export { VERIFICATION_AGENT_INSTRUCTIONS_PRODUCTION };
```

---

### 7.8 Agent Implementation

```typescript
// src/agents/VerificationAgent.ts

import { generateText, Output, stepCountIs } from 'ai';
import {
  VerificationAgentInputSchema,
  VerificationAgentOutputSchema,
  type VerificationAgentInput,
  type VerificationAgentOutput,
} from '../schemas/verificationAgentSchema';
import { getVerificationModel, getVerificationModelName, getVerificationModelTokenLimit, getPromptVersions } from '../lib/env';
import { verificationScratchpadTool, clearScratchpadEntries, getAndClearScratchpadEntries } from './tools/scratchpad';
import { getVerificationPrompt } from '../prompts';

/**
 * Verify a single table against survey document
 */
export async function verifyTable(
  input: VerificationAgentInput
): Promise<VerificationAgentOutput> {
  console.log(`[VerificationAgent] Verifying table: ${input.table.tableId}`);

  try {
    const promptVersions = getPromptVersions();
    const instructions = getVerificationPrompt(promptVersions.verificationPromptVersion);

    const systemPrompt = `
${instructions}

SURVEY DOCUMENT:

${input.surveyMarkdown}

TABLE TO VERIFY:

${JSON.stringify(input.table, null, 2)}

Begin verification now.
`;

    const { output } = await generateText({
      model: getVerificationModel(),
      system: systemPrompt,
      prompt: `Verify table "${input.table.tableId}" (${input.table.rows.length} rows) against the survey document. Focus on scale anchors and label clarity.`,
      tools: {
        scratchpad: verificationScratchpadTool,
      },
      stopWhen: stepCountIs(10),
      maxOutputTokens: Math.min(getVerificationModelTokenLimit(), 8000),
      output: Output.object({
        schema: VerificationAgentOutputSchema,
      }),
    });

    if (!output) {
      throw new Error(`Invalid agent response for table ${input.table.tableId}`);
    }

    console.log(`[VerificationAgent] Table ${input.table.tableId}: ${output.changesApplied} changes, confidence: ${output.confidence.toFixed(2)}`);

    return output;

  } catch (error) {
    console.error(`[VerificationAgent] Error verifying table ${input.table.tableId}:`, error);

    // Return original table with no changes on error
    return {
      tableId: input.table.tableId,
      title: input.table.title,
      titleChanged: false,
      questionText: input.table.questionText,
      questionTextChanged: false,
      rows: input.table.rows.map(row => ({
        variable: row.variable,
        label: row.label,
        filterValue: row.filterValue,
        labelChanged: false,
        originalLabel: row.label,
      })),
      confidence: 0.0,
      reasoning: `Error during verification: ${error instanceof Error ? error.message : 'Unknown error'}`,
      changesApplied: 0,
    };
  }
}

/**
 * Verify all tables against survey
 */
export async function verifyAllTables(
  tables: VerificationAgentInput['table'][],
  surveyMarkdown: string,
  onProgress?: (completed: number, total: number) => void
): Promise<{ results: VerificationAgentOutput[]; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (msg: string) => {
    console.log(msg);
    processingLog.push(`${new Date().toISOString()}: ${msg}`);
  };

  clearScratchpadEntries();
  logEntry(`[VerificationAgent] Starting: ${tables.length} tables to verify`);
  logEntry(`[VerificationAgent] Using model: ${getVerificationModelName()}`);
  logEntry(`[VerificationAgent] Survey context: ${surveyMarkdown.length} characters`);

  const results: VerificationAgentOutput[] = [];

  for (let i = 0; i < tables.length; i++) {
    const table = tables[i];
    const startTime = Date.now();

    logEntry(`[VerificationAgent] Verifying ${i + 1}/${tables.length}: "${table.tableId}"`);

    const result = await verifyTable({ table, surveyMarkdown });
    results.push(result);

    const duration = Date.now() - startTime;
    logEntry(`[VerificationAgent] Table "${table.tableId}" done in ${duration}ms - ${result.changesApplied} changes`);

    try { onProgress?.(i + 1, tables.length); } catch {}
  }

  // Summary stats
  const totalChanges = results.reduce((sum, r) => sum + r.changesApplied, 0);
  const avgConfidence = results.length > 0
    ? results.reduce((sum, r) => sum + r.confidence, 0) / results.length
    : 0;

  logEntry(`[VerificationAgent] Complete: ${totalChanges} total changes across ${results.length} tables, avg confidence: ${avgConfidence.toFixed(2)}`);

  return { results, processingLog };
}
```

---

### 7.9 API Integration

Option A: Standalone endpoint for testing

```typescript
// src/app/api/verify-tables/route.ts

import { NextRequest, NextResponse } from 'next/server';
import { verifyAllTables } from '@/agents/VerificationAgent';
import { parseSurveyToMarkdown } from '@/lib/processors/SurveyProcessor';

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const tablesJson = formData.get('tables') as string;
    const surveyFile = formData.get('survey') as File;

    // Parse inputs
    const tables = JSON.parse(tablesJson);
    const surveyBuffer = await surveyFile.arrayBuffer();
    const surveyMarkdown = await parseSurveyToMarkdown(Buffer.from(surveyBuffer));

    // Run verification
    const { results, processingLog } = await verifyAllTables(tables, surveyMarkdown);

    return NextResponse.json({
      success: true,
      results,
      summary: {
        tablesVerified: results.length,
        totalChanges: results.reduce((sum, r) => sum + r.changesApplied, 0),
        averageConfidence: results.reduce((sum, r) => sum + r.confidence, 0) / results.length,
      },
      processingLog,
    });

  } catch (error) {
    return NextResponse.json(
      { success: false, error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
```

Option B: Integrate into main pipeline (after R, before ExcelJS)

```typescript
// In src/app/api/process-crosstab/route.ts

// After R script execution, before ExcelJS:
if (surveyFile) {
  const surveyMarkdown = await parseSurveyToMarkdown(surveyFile);
  const { results: verifiedTables } = await verifyAllTables(
    rOutputTables,
    surveyMarkdown
  );
  // Pass verifiedTables to ExcelJS instead of rOutputTables
}
```

---

### 7.10 Test Script

```typescript
// scripts/test-verification-agent.ts

import { verifyAllTables } from '../src/agents/VerificationAgent';
import { parseSurveyToMarkdown } from '../src/lib/processors/SurveyProcessor';
import fs from 'fs/promises';
import path from 'path';

async function main() {
  console.log('=== VerificationAgent Test ===\n');

  // Load latest table output
  const tableOutputPath = process.argv[2] ||
    'temp-outputs/table-test-2026-01-04T04-42-54-851Z/table-output-2026-01-04T04-48-58-509Z.json';

  const surveyPath = 'data/test-data/practice-files/leqvio-demand-survey.docx';

  console.log(`Loading tables from: ${tableOutputPath}`);
  console.log(`Loading survey from: ${surveyPath}\n`);

  const tableOutput = JSON.parse(await fs.readFile(tableOutputPath, 'utf-8'));
  const surveyMarkdown = await parseSurveyToMarkdown(surveyPath);

  // Extract table definitions from results
  const tables = tableOutput.results.flatMap((r: any) =>
    r.tables.map((t: any) => ({
      ...t,
      questionId: r.questionId,
      questionText: r.questionText,
    }))
  );

  console.log(`Found ${tables.length} tables to verify`);
  console.log(`Survey markdown: ${surveyMarkdown.length} characters\n`);

  // Run verification
  const { results, processingLog } = await verifyAllTables(
    tables,
    surveyMarkdown,
    (completed, total) => console.log(`Progress: ${completed}/${total}`)
  );

  // Save results
  const outputDir = `temp-outputs/verification-test-${new Date().toISOString().replace(/[:.]/g, '-')}`;
  await fs.mkdir(outputDir, { recursive: true });

  await fs.writeFile(
    path.join(outputDir, 'verified-tables.json'),
    JSON.stringify({ results, processingLog }, null, 2)
  );

  // Summary
  const totalChanges = results.reduce((sum, r) => sum + r.changesApplied, 0);
  const avgConfidence = results.reduce((sum, r) => sum + r.confidence, 0) / results.length;

  console.log('\n=== Summary ===');
  console.log(`Tables verified: ${results.length}`);
  console.log(`Total label changes: ${totalChanges}`);
  console.log(`Average confidence: ${avgConfidence.toFixed(2)}`);
  console.log(`Output saved to: ${outputDir}`);
}

main().catch(console.error);
```

---

### 7.11 Implementation Checklist

| Task | File(s) | Status |
|------|---------|--------|
| Add verification types to ProcessingLimits | `src/lib/types.ts` | ⏳ |
| Add verification env config | `src/lib/env.ts` | ⏳ |
| Create SurveyProcessor | `src/lib/processors/SurveyProcessor.ts` | ⏳ |
| Create verificationAgentSchema | `src/schemas/verificationAgentSchema.ts` | ⏳ |
| Create verification prompts | `src/prompts/verification/*.ts` | ⏳ |
| Create VerificationAgent | `src/agents/VerificationAgent.ts` | ⏳ |
| Update agents/index.ts | `src/agents/index.ts` | ⏳ |
| Update schemas/index.ts | `src/schemas/index.ts` | ⏳ |
| Update prompts/index.ts | `src/prompts/index.ts` | ⏳ |
| Create test script | `scripts/test-verification-agent.ts` | ⏳ |
| Create API route (optional) | `src/app/api/verify-tables/route.ts` | ⏳ |
| Integrate into main pipeline | `src/app/api/process-crosstab/route.ts` | ⏳ |

### 7.12 Dependencies

New npm packages needed:
```bash
npm install mammoth    # DOCX → text extraction
npm install pdf-parse  # PDF → text extraction (if supporting PDF surveys)
```

---

### 7.13 Future Enhancements

1. **Caching**: Cache survey markdown for repeated runs with same document
2. **Batch optimization**: If survey is small enough, process multiple tables per API call
3. **Confidence thresholds**: Only apply changes above certain confidence level
4. **Manual review queue**: Flag low-confidence changes for human review
5. **Survey format detection**: Auto-detect survey structure (Qualtrics, SurveyMonkey, etc.)

---

## After This Architecture

Once Steps 6-7 complete and validated against `data/test-data/practice-files/`:
→ Return to `docs/implementation-plans/pre-phase-2-testing-plan.md` (Milestone 2 continues there)

---

*Created: January 3, 2026*
*Updated: January 4, 2026 - Detailed Step 5.5 (R calculations enhancement) and Step 7 (VerificationAgent) plans*
