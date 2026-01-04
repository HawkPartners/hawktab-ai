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
| 4 | API route integration | ✅ Complete |
| 5 | RScriptGeneratorV2 (JSON output) | ✅ Complete |
| 5.5 | R calculations enhancement (sig testing, outliers, rounding) | ✅ Complete |
| — | Delete old files | ✅ Complete |
| 6 | ExcelJS Formatter | ⏳ Next |
| 7 | VerificationAgent (survey → label cleanup) | 📋 Detailed plan ready |

---

## Completed: Steps 0-5.5

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

### R Calculations Enhancement (Step 5.5)
- Fixed SD rounding (2 → 1 decimal) to match mean/median formatting
- Added IQR-based outlier-adjusted mean calculation (`mean_no_outliers`)
- Implemented significance testing (Z-test for proportions, T-test for means) with within-group and Total comparisons
- Enhanced `CutDefinition` and `CutsSpec` to preserve group structure for stat testing
- Updated JSON output with `sig_higher_than` and `sig_vs_total` fields

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

**Goal**: Format JSON output into Antares-style Excel workbook with professional crosstab formatting.

**Reference**: `docs/reference-crosstab-images/referenence-antares-output.png`

---

### 6.1 Table Layout (Antares Style)

Each table is wrapped in a box with:

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ S5 - Employment/Commercial affiliation (Select all that apply)               │
│ Base: Total                                                                  │
├────────────┬───────┬║════════════════════════════════║┬═══════════════┬──────┤
│            │ Total │║         Specialty              ║│     Role      │ ...  │
│            │       │║ Cards │ PCPs │ Nephs │ Endos   ║│ Phys  │ NP/PA │      │
│            │  (T)  │║  (A)  │  (B) │  (C)  │  (D)    ║│  (F)  │  (G)  │      │
├────────────┼───────┼║───────┼──────┼───────┼─────────║┼───────┼───────┼──────┤
│ Base n     │  180  │║  120  │   53 │     0 │      7  ║│  166  │   14  │      │
├────────────┼───────┼║───────┼──────┼───────┼─────────║┼───────┼───────┼──────┤
│ Option 1   │    45 │║    30 │   10 │     0 │      5  ║│   38  │    7  │ count│
│            │   25% │║   25% │  19% │     - │    71%  ║│   23% │   50% │ pct  │
│            │     - │║  B,C  │    - │     - │ A,B,C   ║│    G  │     - │ sig  │
├────────────┼───────┼║───────┼──────┼───────┼─────────║┼───────┼───────┼──────┤
│ Option 2   │   ... │                                                         │
├────────────┴───────┴─────────────────────────────────────────────────────────┤
│ Significance at 90% level. T-test for means, Z-test for proportions.         │
│ Comparison groups: A/B/C/D/E, F/G, H/I, J/K/L/M, N/O/P/Q, R/S                │
└──────────────────────────────────────────────────────────────────────────────┘
```

Key elements:
- **║** = Heavy border between banner groups
- **│** = Light border within groups
- Box wraps entire table
- 3-row header (Group name → Column name → Stat letter)

---

### 6.2 Header Structure

| Row | Content | Example |
|-----|---------|---------|
| Title | Question text | `S5 - Employment/Commercial affiliation` |
| Base | Base description | `Base: Total` or `Base: Shown this question` |
| Header 1 | Group names (merged cells) | `Specialty`, `Role`, `Tiers` |
| Header 2 | Column names | `Cards`, `PCPs`, `Physician`, `NP/PA` |
| Header 3 | Stat letters in parentheses | `(T)`, `(A)`, `(B)`, `(C)` |
| Base Row | n values for each cut | `180`, `120`, `53`, `0` |

**Base description logic:**
- If `n === totalRespondents` → `"Base: Total"`
- Else → `"Base: Shown this question"`

---

### 6.3 Data Row Formats

#### 6.3.1 Frequency Tables

Each answer option = **3 rows**:

| Row | Content | Example |
|-----|---------|---------|
| 1 | Count (n) | `45` |
| 2 | Percent | `25%` |
| 3 | Significance | `B,C` or `-` |

Always show all 3 rows, even if no significance (use `-`).

#### 6.3.2 Mean Rows Tables (Multiple Items)

When table has **>1 row**, each item = **2 rows**:

| Row | Content | Example |
|-----|---------|---------|
| 1 | Mean | `95.2` |
| 2 | Significance | `D` or `-` |

This keeps the table compact. SD/median omitted for multi-row mean tables.

#### 6.3.3 Mean Rows Tables (Single Item)

When table has **exactly 1 row**, show **4 rows**:

| Row | Content | Example |
|-----|---------|---------|
| 1 | Mean | `95.2` |
| 2 | Median | `100` |
| 3 | SD | `6.5` |
| 4 | Significance | `-` |

---

### 6.4 Border Styling

| Border Type | Style | Where |
|-------------|-------|-------|
| Heavy | `medium` (2px) | Between banner groups |
| Light | `thin` (1px) | Within groups, between rows |
| Box | `medium` | Around entire table |

ExcelJS border styles:
```typescript
// Heavy border between groups
{ style: 'medium', color: { argb: 'FF000000' } }

// Light border within groups
{ style: 'thin', color: { argb: 'FF000000' } }
```

---

### 6.5 Color Coding

| Element | Color | Purpose |
|---------|-------|---------|
| Title row | Light gray `#E0E0E0` | Table header |
| Base description | Light gray `#E0E0E0` | Part of header |
| Group header row | Light blue `#D9E1F2` | Banner groups |
| Column header row | Light blue `#D9E1F2` | Column names |
| Stat letter row | Light blue `#D9E1F2` | (T), (A), (B) |
| Base n row | Light yellow `#FFF2CC` | Highlight base sizes |
| Label column | Light teal `#E2EFDA` | Row labels |
| Data cells | White | Values |

Optional: Different background tints per banner group (as in Antares reference).

---

### 6.6 Footer

Below each table, add 2 lines:

```
Significance at 90% level. T-test for means, Z-test for proportions.
Comparison groups: A/B/C/D/E, F/G, H/I, J/K/L/M, N/O/P/Q, R/S
```

Footer derives comparison groups from banner structure:
- Each banner group's stat letters joined with `/`
- Groups separated by `, `

---

### 6.7 Hints Processing → New Tables (in RScriptGeneratorV2)

Hints do NOT modify existing tables. Instead, **RScriptGeneratorV2 generates additional R code** to create derived tables. This keeps calculations at the data source (R) and ExcelJS simple (just renders whatever tables exist).

**Flow:**
```
TableAgent output (has hints: "ranking" or "scale-5")
         ↓
RScriptGeneratorV2 sees hints
         ↓
Generates BOTH:
  - Original tables (e.g., A6_rank1, A6_rank2, ...)
  - Derived tables (e.g., A6_top3_combined)
         ↓
R executes, outputs all tables to JSON
         ↓
ExcelJS renders whatever tables exist (dumb and simple)
```

#### 6.7.1 Scale-5 Hint

When `hints: "scale-5"` (5-point Likert scale):

RScriptGeneratorV2 generates R code for an additional table with 3 derived rows:
- **T2B (Top 2 Box)**: Count/% where value = 4 OR 5
- **B2B (Bottom 2 Box)**: Count/% where value = 1 OR 2
- **Middle**: Count/% where value = 3

```r
# Generated R code for T2B/B2B table
t2b_count <- sum(cut_data[[var]] %in% c(4, 5), na.rm = TRUE)
t2b_pct <- round((t2b_count / base_n) * 100)

b2b_count <- sum(cut_data[[var]] %in% c(1, 2), na.rm = TRUE)
b2b_pct <- round((b2b_count / base_n) * 100)

middle_count <- sum(cut_data[[var]] == 3, na.rm = TRUE)
middle_pct <- round((middle_count / base_n) * 100)
```

New table ID: `"a8r1_t2b_b2b"`
New table title: `"A8r1 - Likelihood (T2B/B2B)"`

#### 6.7.2 Scale-7 Hint

When `hints: "scale-7"` (7-point Likert scale):

RScriptGeneratorV2 generates R code for an additional table with 3 derived rows:
- **T2B**: Count/% where value = 6 OR 7
- **B2B**: Count/% where value = 1 OR 2
- **Middle**: Count/% where value = 3, 4, OR 5

#### 6.7.3 Ranking Hint

When `hints: "ranking"`:

RScriptGeneratorV2 generates R code for an additional table showing **Top 3 Combined**.

**Why R must do this**: Can't just sum rank1 + rank2 + rank3 percentages. Need to count unique respondents who ranked the item in top 3 from raw data:

```r
# Generated R code for Top 3 Combined
# For each item, count respondents who gave rank 1, 2, or 3
top3_count <- sum(cut_data[[var]] <= 3, na.rm = TRUE)
top3_pct <- round((top3_count / base_n) * 100)
```

New table ID: `"a6_top3_combined"`
New table title: `"A6 - Top 3 Ranked"`

This applies regardless of ranking depth (4, 7, or 10 options).

---

### 6.8 Required R Script Changes

Add to `tables.json` metadata:

```json
{
  "metadata": {
    "generatedAt": "...",
    "tableCount": 49,
    "cutCount": 21,
    "significanceLevel": 0.1,
    "totalRespondents": 180,  // NEW: for base description logic
    "bannerGroups": [         // NEW: for headers & border placement
      {
        "groupName": "Total",
        "columns": [{ "name": "Total", "statLetter": "T" }]
      },
      {
        "groupName": "Specialty",
        "columns": [
          { "name": "Cards", "statLetter": "A" },
          { "name": "PCPs", "statLetter": "B" },
          { "name": "Nephs", "statLetter": "C" },
          { "name": "Endos", "statLetter": "D" },
          { "name": "Lipids", "statLetter": "E" }
        ]
      }
      // ... remaining groups
    ],
    "comparisonGroups": ["A/B/C/D/E", "F/G", "H/I", "J/K/L/M", "N/O/P/Q", "R/S"]
  }
}
```

**Changes to `RScriptGeneratorV2.ts`:**
1. Accept `totalRespondents` parameter (from SPSS row count)
2. Accept `bannerGroups` structure (from verbose banner output)
3. Derive `comparisonGroups` from banner group structure
4. Include all in JSON metadata output

---

### 6.9 Input/Output

**Input:**
- `results/tables.json` - R calculation output
- Banner groups structure (embedded in metadata or passed separately)

**Output:**
- `crosstabs-{sessionId}.xlsx` - Formatted Excel workbook
- All tables on single worksheet, stacked with 2-row gaps

---

### 6.10 File Structure

```
src/lib/excel/
├── ExcelFormatter.ts      # Main formatter class
├── tableRenderers/
│   ├── frequencyTable.ts  # Frequency table renderer
│   └── meanRowsTable.ts   # Mean rows table renderer
└── styles.ts              # Color/border constants

# Hints processing happens in RScriptGeneratorV2, not ExcelJS
# ExcelJS just renders whatever tables exist in tables.json
```

---

### 6.11 Implementation Checklist

| Task | File(s) | Status |
|------|---------|--------|
| **R Script Updates** | | |
| Add totalRespondents to metadata | `src/lib/r/RScriptGeneratorV2.ts` | ✅ |
| Add bannerGroups to metadata | `src/lib/r/RScriptGeneratorV2.ts` | ✅ |
| Add comparisonGroups to metadata | `src/lib/r/RScriptGeneratorV2.ts` | ✅ |
| Generate derived tables for scale-5 hints | `src/lib/r/RScriptGeneratorV2.ts` | ✅ |
| Generate derived tables for scale-7 hints | `src/lib/r/RScriptGeneratorV2.ts` | ✅ |
| Generate derived tables for ranking hints | `src/lib/r/RScriptGeneratorV2.ts` | ✅ |
| **ExcelJS Formatter** | | |
| Create ExcelFormatter main class | `src/lib/excel/ExcelFormatter.ts` | ✅ |
| Create frequency table renderer | `src/lib/excel/tableRenderers/frequencyTable.ts` | ✅ |
| Create mean rows table renderer | `src/lib/excel/tableRenderers/meanRowsTable.ts` | ✅ |
| Create styles constants | `src/lib/excel/styles.ts` | ✅ |
| **Integration** | | |
| Update export-workbook route | `src/app/api/export-workbook/[sessionId]/route.ts` | ✅ |
| Create test script | `scripts/test-excel-formatter.ts` | ⏳ |
| Integrate into main pipeline | `src/app/api/process-crosstab/route.ts` | ⏳ |

---

### 6.12 ExcelJS Capabilities Used

| Feature | ExcelJS API | Notes |
|---------|-------------|-------|
| Merged cells | `worksheet.mergeCells(startRow, startCol, endRow, endCol)` | For group headers |
| Border styles | `cell.border = { top: { style: 'medium' } }` | Heavy between groups |
| Fill colors | `cell.fill = { type: 'pattern', fgColor: { argb: 'FFD9E1F2' } }` | Header backgrounds |
| Column widths | `worksheet.getColumn(n).width = 12` | Fixed or auto-fit |
| Row heights | `worksheet.getRow(n).height = 20` | Consistent spacing |
| Number formats | `cell.numFmt = '0%'` | Percent display |
| Font styles | `cell.font = { bold: true }` | Headers |
| Alignment | `cell.alignment = { horizontal: 'center' }` | Center values |

**Note:** ExcelJS doesn't support true superscript. Significance letters go on separate row.

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
*Updated: January 4, 2026 - Completed Step 5.5 (R calculations enhancement), streamlined documentation to focus on Steps 6-7*
*Updated: January 4, 2026 - Step 6 fully planned: Antares-style layout, hints processing in RScriptGeneratorV2, ExcelJS renders tables*
