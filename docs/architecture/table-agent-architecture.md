# Table Agent Architecture

## Overview

This document describes a new architecture for generating crosstab table definitions using an AI agent rather than deterministic pattern matching.

**Core insight**: Survey structures vary wildly across different studies. Variable naming conventions, parent-child relationships, and base filter logic differ from survey to survey. A rules-based approach requires constant patching for each new survey structure. An AI agent can reason about survey semantics and generalize across any structure.

---

## Why This Change

### The Problem with Deterministic Parsing

Our current approach uses regex patterns to detect relationships:
- `A3ar1` → base filter `A3r2 > 0`
- `A3br1` → base filter `A3ar1c2 > 0`

This works for surveys that follow this exact naming convention. But:
- Different surveys use `Q5a`, `Brand_Awareness_Detail`, `Demographics.Age`
- Every new survey requires new pattern matching rules
- We've spent hours fixing patterns that only work for one dataset
- This doesn't scale to 23+ datasets

### The Right Comparison

We kept asking: "Is AI as reliable as deterministic code?"

Wrong question. The right question: "Is AI as reliable as Joe?"

| Metric | Deterministic Code | AI Agent | Joe |
|--------|-------------------|----------|-----|
| Speed | Fast | Fast | 3+ days |
| Cost | Cheap | Cheap | Expensive |
| Reliability | Breaks on variation | Handles variation | Makes mistakes |
| Generalization | None | Yes | Yes |

We're replacing a human doing knowledge work. AI is the right tool.

---

## Where This Fits

### Current Pipeline

```
Banner PDF → BannerAgent → Banner Plan
Datamap CSV → DataMapProcessor → Processed Datamap
                                        ↓
                              TablePlan.ts (regex patterns) ← PROBLEM
                                        ↓
                              RScriptGenerator → R → CSV
```

### New Pipeline

```
Banner PDF → BannerAgent → Banner Plan
Datamap CSV → DataMapProcessor → Processed Datamap
Survey DOCX → Markdown Converter → Survey Markdown    ← NEW INPUT
                                        ↓
                              TableAgent (AI reasoning) ← REPLACES TablePlan
                                        ↓
                              Table Definitions (JSON)
                                        ↓
                              R (calculations) → JSON
                                        ↓
                              ExcelJS (formatting) → Excel
```

---

## Table Agent Design

### Inputs

1. **Processed Datamap**
   - Parent-child relationships (already extracted)
   - Variable types (`categorical_select`, `numeric_range`, `scale`, `binary_flag`)
   - Answer options
   - Context strings
   - Grouped by parent question (agent sees all subs together)

2. **Survey Markdown**
   - Question flow and text
   - Skip logic context (who sees what)
   - Helps agent reason about base filters

3. **System Prompt**
   - Role: Market researcher creating crosstabs
   - Table type conventions (when to use means vs. frequencies)
   - Guidance on base filter reasoning
   - Output format specification

### Processing Approach

**Grouping**: Questions are grouped by parent before being sent to the agent.

Instead of processing `A3ar1c1`, `A3ar1c2`, `A3ar2c1` individually, the agent receives:
```
Parent: A3a
Type: numeric_range
Children: [A3ar1c1, A3ar1c2, A3ar2c1, A3ar2c2, ...]
Context: "For each treatment, approximately what % received therapy in addition to vs. without a statin?"
```

The agent then decides: "This needs 5 tables (one per treatment), each showing means for the two statin conditions."

**Base Filter Reasoning**: The agent is prompted to think through:
- Who sees this question?
- Is it conditional on a previous answer?
- What does the question text imply about the respondent base?

Example: Agent reads "For each treatment you just indicated that you prescribe without a statin..." and reasons → base filter should include only those who indicated prescribing without a statin.

**Processing**: One question group at a time.

### Output

For each question group, the agent outputs a table definition:

```json
{
  "parentId": "A3a",
  "tables": [
    {
      "tableId": "A3ar1",
      "title": "Leqvio (inclisiran) - For each treatment...",
      "tableType": "mean",
      "rows": [
        { "label": "In addition to statin", "var": "A3ar1c1" },
        { "label": "Without statin", "var": "A3ar1c2" }
      ],
      "baseFilter": {
        "description": "Those who prescribed Leqvio (A3r2 > 0)",
        "expression": "A3r2 > 0"
      },
      "calculations": ["mean"]
    },
    {
      "tableId": "A3ar2",
      "title": "Praluent (alirocumab) - For each treatment...",
      "tableType": "mean",
      "rows": [
        { "label": "In addition to statin", "var": "A3ar2c1" },
        { "label": "Without statin", "var": "A3ar2c2" }
      ],
      "baseFilter": {
        "description": "Those who prescribed Praluent (A3r3 > 0)",
        "expression": "A3r3 > 0"
      },
      "calculations": ["mean"]
    }
  ]
}
```

**Note**: The agent receives a parent question group and outputs potentially multiple tables for that group. The exact JSON schema is still being refined. Key fields:
- Parent identification (agent processes by parent group)
- Array of tables for that parent
- Each table: type, rows, base filter, calculations

---

## Output: From Table Definition to Final Format

### Approach: R for Calculations, ExcelJS for Formatting

**R's job**: Execute calculations based on table definitions
- Apply base filters
- Calculate frequencies, means, percentages per banner cut
- Output structured JSON (not CSV)

**ExcelJS's job**: Format JSON into Excel
- Pre-defined templates for each `tableType`
- Multi-row headers (Group names → Column names → Stat letters)
- Base row with n values
- Data rows (count + percentage)
- Sigma row at bottom
- Tables stitched into single workbook

### Table Types (to be defined)

The Table Agent outputs a `tableType` which maps to a formatting template:
- `frequency` - categorical questions, show counts and percentages
- `mean` - numeric ranges, show mean values
- `scale` - Likert scales, show frequencies + T2B/B2B calculations
- `multi_select` - multiple response questions

**This is iterative**: As we run the agent on different surveys, we'll discover new table types needed and add them to both the system prompt and the ExcelJS templates.

---

## UI Requirements

This architecture requires a new input: the survey document.

**New upload flow**:
1. User uploads survey (DOCX)
2. System converts to Markdown (using existing libraries)
3. Markdown passed to Table Agent alongside datamap

**Conversion**: Use existing DOCX → Markdown libraries. Preserve as much detail as possible (question numbers, answer options, skip logic notes).

---

## What We Keep

- **DataMapProcessor**: Extracts types, parent-child relationships, answer options
- **BannerAgent**: Unchanged - still extracts banner cuts from banner plan
- **R execution pipeline**: Unchanged (but outputs JSON instead of CSV)

## What We Replace

- **TablePlan.ts**: Regex-based pattern matching → Agent reasoning
- **Hard-coded base filter logic**: Agent figures out from survey context
- **CSV output**: JSON output for ExcelJS consumption

---

## Open Questions

1. **Output schema**: What exact fields does the ExcelJS formatter need? Need to align agent output → R output → ExcelJS input.

2. **Table types**: What types do we need? Start with basics (frequency, mean, scale), add more as we iterate.

---

## Implementation Checklist

### Step 0: Environment Variable Separation

**Goal**: Give each agent its own model configuration for flexibility.

Update `.env.example` and `env.ts`:

```
# Current (shared)
REASONING_MODEL=o4-mini
BASE_MODEL=gpt-5-nano

# New (per-agent)
CROSSTAB_MODEL=o4-mini
BANNER_MODEL=gpt-5-nano
TABLE_MODEL=gpt-5-nano

CROSSTAB_MODEL_TOKENS=100000
BANNER_MODEL_TOKENS=128000
TABLE_MODEL_TOKENS=128000

CROSSTAB_PROMPT_VERSION=production
BANNER_PROMPT_VERSION=production
TABLE_PROMPT_VERSION=production
```

Update `src/lib/env.ts`:
- Add `getCrosstabModel()`, `getBannerModel()`, `getTableModel()`
- Keep `getReasoningModel()` and `getBaseModel()` as aliases for backward compatibility
- Add `TABLE_PROMPT_VERSION` to `promptVersions`

---

### Step 1: Agent Structure Setup

**Create files following existing pattern:**

```
src/
├── agents/
│   ├── BannerAgent.ts      (existing)
│   ├── CrosstabAgent.ts    (existing)
│   ├── RScriptAgent.ts     (existing)
│   └── TableAgent.ts       ← NEW
├── prompts/
│   ├── banner/             (existing)
│   ├── crosstab/           (existing)
│   └── table/              ← NEW
│       ├── index.ts        (prompt selector)
│       └── production.ts   (main prompt)
├── schemas/
│   └── tableAgentSchema.ts ← NEW (Zod schemas for input/output)
```

---

#### 1.1 Key Concept: Table Type ≠ Normalized Type

**Critical distinction the agent must understand:**

| Concept | What It Is | Example |
|---------|-----------|---------|
| `normalizedType` | Data structure from DataMapProcessor | `numeric_range`, `categorical_select`, `binary_flag` |
| `tableType` | Display format for crosstab output | `frequency`, `mean_rows`, `grid_by_value`, `grid_by_item` |

The agent's job is to **map data structures to display formats** based on survey context.

---

#### 1.2 Input Structure

**Verbose DataMap field mapping:**

| Field | Parent Question | Sub Question |
|-------|-----------------|--------------|
| `column` | Question ID (e.g., "S6") | Sub-variable ID (e.g., "S8r1") |
| `description` | Question text | Answer option label |
| `context` | Empty | Parent question text |
| `parentQuestion` | "NA" | Parent ID (e.g., "S8") |

**Grouped input format** (what agent receives per call):

```typescript
interface TableAgentInput {
  // The parent question (synthesized for sub groups)
  questionId: string;        // "S8" or "A1"
  questionText: string;      // From description (parent) or context (sub)

  // All variables for this question
  items: {
    column: string;          // Variable name: "S8r1", "A1r1"
    label: string;           // From description: "Treating/Managing patients"
    normalizedType: string;  // "numeric_range", "categorical_select"
    valueType: string;       // "Values: 0-100", "Values: 1-2"
    rangeMin?: number;
    rangeMax?: number;
    allowedValues?: (number | string)[];
    scaleLabels?: { value: number | string; label: string }[];
  }[];

  // Survey markdown context (optional, helps with reasoning)
  surveyContext?: string;
}
```

**Example: S8 (numeric range subs)**
```json
{
  "questionId": "S8",
  "questionText": "Approximately what percentage of your professional time is spent performing each of the following activities?",
  "items": [
    { "column": "S8r1", "label": "Treating/Managing patients", "normalizedType": "numeric_range", "rangeMin": 0, "rangeMax": 100 },
    { "column": "S8r2", "label": "Performing academic functions", "normalizedType": "numeric_range", "rangeMin": 0, "rangeMax": 100 },
    { "column": "S8r3", "label": "Participating in clinical research", "normalizedType": "numeric_range", "rangeMin": 0, "rangeMax": 100 },
    { "column": "S8r4", "label": "Performing other functions", "normalizedType": "numeric_range", "rangeMin": 0, "rangeMax": 100 }
  ]
}
```

**Example: A1 (categorical grid)**
```json
{
  "questionId": "A1",
  "questionText": "To the best of your knowledge, which statement below best describes the current indication for each of the following treatments?",
  "items": [
    { "column": "A1r1", "label": "Leqvio (inclisiran)", "normalizedType": "categorical_select", "allowedValues": [1, 2] },
    { "column": "A1r2", "label": "Praluent (alirocumab)", "normalizedType": "categorical_select", "allowedValues": [1, 2] },
    { "column": "A1r3", "label": "Repatha (evolocumab)", "normalizedType": "categorical_select", "allowedValues": [1, 2] },
    { "column": "A1r4", "label": "Nexletol/Nexlizet", "normalizedType": "categorical_select", "allowedValues": [1, 2] }
  ]
}
```

---

#### 1.3 What the Agent Reasons About

The agent decides **how to display** data based on:
1. Data structure (normalizedType, allowedValues, rangeMin/rangeMax)
2. Question semantics (what do the values represent?)
3. Crosstab conventions (what makes sense as rows? what stats to show?)

**The agent does NOT handle:**
- Base filters (R handles: `!is.na(variable)`)
- Banner filters (CrosstabAgent already validated these)
- Data validation (separate concern)

**Example reasoning for S8:**
> "S8 has 4 items, each with numeric_range 0-100. These are percentages per activity category.
> Best display: One table with activities as ROWS, showing mean/median stats.
> Table type: `mean_rows`"

**Example reasoning for A1:**
> "A1 has 4 treatments, each with values 1-2 representing two different indication statements.
> In the survey, this is a grid: treatments (rows) × indications (columns A/B).
> For crosstabs, I can't show a 2-column grid directly.
> Options:
>   1. Group by value: Table for value=1 (all treatments), Table for value=2 (all treatments)
>   2. Group by item: Table per treatment showing both values as rows
> Best display: Both views are useful. Create:
>   - Table 'A1_indication_A': All treatments, filtered to value=1
>   - Table 'A1_indication_B': All treatments, filtered to value=2
>   - Optionally: Per-treatment tables
> Table type: `grid_by_value`"

---

#### 1.4 Table Type Catalog

The prompt includes a catalog of available table types:

| Table Type | When to Use | Row Structure | Stats Shown |
|------------|-------------|---------------|-------------|
| `frequency` | Single categorical question | Each answer option is a row | Count, % |
| `mean_rows` | Multiple numeric items | Each item is a row | Mean, Median, SD |
| `grid_by_value` | Grid question with N values | Each item is a row (filtered to one value) | Count, % |
| `grid_by_item` | Grid question with N values | Each value is a row | Count, % |
| `multi_select` | Multi-select (binary subs) | Each option is a row (value=1) | Count, % |
| `ranking` | Ranking questions | Each option is a row | Mean rank |

**Agent selects table type + may output multiple tables per question group.**

---

#### 1.5 Output Schema

```typescript
interface TableAgentOutput {
  questionId: string;           // Parent question ID
  questionText: string;         // For reference

  tables: {
    tableId: string;            // Unique ID: "a1_indication_a", "s8"
    title: string;              // Display title
    tableType: string;          // From catalog: "mean_rows", "grid_by_value", etc.

    rows: {
      variable: string;         // SPSS variable name
      label: string;            // Display label
      filterValue?: number | string;  // For grid_by_value: which value this row represents
    }[];

    stats: string[];            // ["count", "percent"] or ["mean", "median", "sd"]
  }[];

  confidence: number;           // 0.0-1.0 - how confident in this interpretation
  reasoning: string;            // Brief explanation of decisions made
}
```

**Note on Base Filters:**

Base filters (who answered this question) are NOT part of TableAgent output. R handles this automatically:

```r
# Standard crosstab logic - every cell applies:
# 1. Base filter: !is.na(question_variable)  -- who answered
# 2. Banner filter: S2 == 1                  -- the banner cut (e.g., Males)

data %>% filter(!is.na(A3r1) & banner_condition)
```

This is standard crosstab behavior, not special logic. The TableAgent only decides **display format** - R handles **who to include**.

**Example output for S8:**
```json
{
  "questionId": "S8",
  "questionText": "Approximately what percentage...",
  "tables": [{
    "tableId": "s8",
    "title": "Professional Time Allocation",
    "tableType": "mean_rows",
    "rows": [
      { "variable": "S8r1", "label": "Treating/Managing patients" },
      { "variable": "S8r2", "label": "Performing academic functions" },
      { "variable": "S8r3", "label": "Participating in clinical research" },
      { "variable": "S8r4", "label": "Performing other functions" }
    ],
    "stats": ["mean", "median", "sd"]
  }],
  "confidence": 0.95,
  "reasoning": "Numeric range items representing percentages. Display as rows with mean stats."
}
```

**Example output for A1:**
```json
{
  "questionId": "A1",
  "questionText": "To the best of your knowledge...",
  "tables": [
    {
      "tableId": "a1_indication_a",
      "title": "Current Indication - As adjunct to diet (Value A)",
      "tableType": "grid_by_value",
      "rows": [
        { "variable": "A1r1", "label": "Leqvio (inclisiran)", "filterValue": 1 },
        { "variable": "A1r2", "label": "Praluent (alirocumab)", "filterValue": 1 },
        { "variable": "A1r3", "label": "Repatha (evolocumab)", "filterValue": 1 },
        { "variable": "A1r4", "label": "Nexletol/Nexlizet", "filterValue": 1 }
      ],
      "stats": ["count", "percent"]
    },
    {
      "tableId": "a1_indication_b",
      "title": "Current Indication - As adjunct to diet + statin (Value B)",
      "tableType": "grid_by_value",
      "rows": [
        { "variable": "A1r1", "label": "Leqvio (inclisiran)", "filterValue": 2 },
        { "variable": "A1r2", "label": "Praluent (alirocumab)", "filterValue": 2 },
        { "variable": "A1r3", "label": "Repatha (evolocumab)", "filterValue": 2 },
        { "variable": "A1r4", "label": "Nexletol/Nexlizet", "filterValue": 2 }
      ],
      "stats": ["count", "percent"]
    }
  ],
  "confidence": 0.85,
  "reasoning": "Grid question with 4 treatments × 2 indication options. Created separate tables for each indication value since crosstabs can't show 2-column grids."
}
```

---

#### 1.6 Implementation Files

**`src/agents/TableAgent.ts`**
- Functional approach (like CrosstabAgent)
- `processQuestionGroup(input: TableAgentInput): Promise<TableAgentOutput>`
- `processAllGroups(groups: TableAgentInput[]): Promise<TableAgentOutput[]>`
- Uses `getTableModel()` from env
- Uses scratchpad tool for reasoning transparency
- Saves development outputs to temp-outputs/

**`src/schemas/tableAgentSchema.ts`**
- Zod schemas for `TableAgentInput` and `TableAgentOutput`
- Export types for use in agent and downstream

**`src/prompts/table/index.ts`**
- Prompt selector with env override (`TABLE_PROMPT_VERSION`)

**`src/prompts/table/production.ts`**
- System prompt with:
  - Role definition (market researcher creating crosstabs)
  - Table type catalog with descriptions
  - Input format explanation
  - Output schema specification
  - Example reasoning patterns

---

#### 1.7 Grouping Logic (Pre-Agent)

Before calling the agent, we need to group the verbose datamap by parent:

```typescript
function groupDataMapByParent(dataMap: VerboseDataMapType[]): TableAgentInput[] {
  const groups: TableAgentInput[] = [];

  // Separate parents and subs
  const parents = dataMap.filter(v => v.level === 'parent' && v.normalizedType !== 'admin');
  const subs = dataMap.filter(v => v.level === 'sub');

  // Group subs by parentQuestion
  const subGroups = new Map<string, VerboseDataMapType[]>();
  for (const sub of subs) {
    const parent = sub.parentQuestion;
    if (!parent || parent === 'NA') continue;
    if (!subGroups.has(parent)) subGroups.set(parent, []);
    subGroups.get(parent)!.push(sub);
  }

  // Create input for each sub group
  for (const [parentId, items] of subGroups) {
    // Get question text from context (all subs share same context)
    const questionText = items[0]?.context || parentId;

    groups.push({
      questionId: parentId,
      questionText,
      items: items.map(item => ({
        column: item.column,
        label: item.description,
        normalizedType: item.normalizedType || 'unknown',
        valueType: item.valueType,
        rangeMin: item.rangeMin,
        rangeMax: item.rangeMax,
        allowedValues: item.allowedValues,
        scaleLabels: item.scaleLabels,
      }))
    });
  }

  // Also include standalone parents (no subs)
  const parentsWithSubs = new Set(subGroups.keys());
  for (const parent of parents) {
    if (parentsWithSubs.has(parent.column)) continue;

    groups.push({
      questionId: parent.column,
      questionText: parent.description,
      items: [{
        column: parent.column,
        label: parent.description,
        normalizedType: parent.normalizedType || 'unknown',
        valueType: parent.valueType,
        rangeMin: parent.rangeMin,
        rangeMax: parent.rangeMax,
        allowedValues: parent.allowedValues,
        scaleLabels: parent.scaleLabels,
      }]
    });
  }

  return groups;
}
```

---

### Step 2: Survey Upload & Markdown Conversion (DEFERRED - Optional Enhancement)

**Status: Deferred**

The datamap already contains sufficient information for table type decisions:
- Question text (description for parents, context for subs)
- Answer options (scaleLabels, allowedValues)
- Variable structure (parent-child relationships)
- Normalized types

**When to revisit:**
- If TableAgent consistently struggles with ambiguous cases
- If we need richer context for complex skip logic interpretation
- If users specifically request survey-aware processing

**Original plan (if needed later):**
- Add survey file upload field (DOCX)
- Add `src/lib/processors/SurveyProcessor.ts`
- Use DOCX → Markdown library (e.g., `mammoth`)
- Pass as optional `surveyContext` field in TableAgentInput

**For now:** TableAgent works from datamap alone. The prompt guides the agent to reason about display formats without needing the original survey document.

---

### Step 3: Table Agent Prompt

**`src/prompts/table/production.ts`:**
- Role: Market researcher creating crosstabs
- Input format: Processed datamap group + survey markdown
- Output format: JSON table definition schema
- Guidance on:
  - Table type selection (frequency, mean, scale, multi_select)
  - Base filter reasoning ("Who sees this question?")
  - Row construction from variables

**System prompt should reference:**
- Available table types and when to use each
- How to read the datamap structure
- How to infer base filters from survey context

---

### Step 4: Integration (API Route)

**Update processing flow:**
1. Process banner (existing)
2. Process datamap (existing)
3. Group datamap by parent question (new - uses `groupDataMapByParent()`)
4. Loop: For each parent group, call TableAgent
5. Collect all table definitions
6. Generate R code from definitions
7. Run R → JSON output
8. ExcelJS formatter → Excel

**API changes:**
- No new file inputs required (survey upload deferred)
- Add TableAgent processing step between datamap and R generation
- Return table definitions in response for debugging

---

### Step 5: R Script Updates

**Modify `RScriptGenerator.ts`:**
- Accept table definitions from TableAgent output
- Generate R code based on `tableType` field
- Output JSON instead of CSV

**Table type templates:**
- `frequency`: counts + percentages per cut
- `mean`: mean values per cut
- `scale`: frequencies + T2B/B2B calculations
- `multi_select`: multiple response handling

---

### Step 6: ExcelJS Formatter

**Create `src/lib/formatters/ExcelFormatter.ts`:**
- Read R JSON output
- Apply template per `tableType`
- Generate Antares-style formatting:
  - Multi-row headers
  - Base row
  - Data rows (count + %)
  - Sigma row
- Stitch tables into single workbook

---

### Implementation Order

| Order | Step | Dependency | Effort | Status |
|-------|------|------------|--------|--------|
| 0 | Env variable separation | None | Small | ✅ Complete |
| 1 | Agent structure (files) | Step 0 | Medium | ✅ Complete |
| 1.1 | - Schema definitions (`tableAgentSchema.ts`) | Step 0 | Small | ✅ Complete |
| 1.2 | - Prompt files (`prompts/table/`) | Step 1.1 | Small | ✅ Complete |
| 1.3 | - Agent implementation (`TableAgent.ts`) | Steps 1.1, 1.2 | Medium | ✅ Complete |
| 1.4 | - Grouping logic (pre-agent) | Step 1.1 | Small | ✅ Complete |
| 2 | Survey processor | None | Medium | ⏸️ Deferred |
| 3 | Table agent prompt (iterate) | Step 1 | Medium | ✅ Complete (initial survey) |
| 3.5 | Standalone testing mode | Step 1 | Small | ✅ Complete |
| 4 | Integration (API) | Steps 3, 3.5 | Medium | |
| 5 | R script updates | Step 4 | Medium | |
| 6 | ExcelJS formatter | Step 5 | Medium | |

**Key simplifications:**
- **Step 2 deferred**: Datamap has sufficient context for table type decisions. Survey markdown could help with scale label assignment but may be handled by a downstream agent during ExcelJS formatting instead.
- **Base filters removed from TableAgent**: R handles this automatically (`!is.na(variable) & banner_filter`). TableAgent only decides display format.

**Iteration approach**: After Step 1, test with sample datamap data. Use Step 3.5 (standalone mode) to iterate on prompt without waiting for full pipeline. Once table type selection is reliable, integrate into full API flow.

---

### Step 3.5: Standalone Testing Mode

**Goal**: Run TableAgent in isolation to validate output before wiring into full R pipeline.

**Implementation options:**

1. **Environment flag** (`TABLE_AGENT_ONLY=true`):
   - When set, API stops after TableAgent processing
   - Returns JSON table definitions instead of triggering R script
   - Easy toggle between testing and full pipeline

2. **Dedicated test endpoint** (`/api/test-table-agent`):
   - Accepts processed datamap JSON directly
   - Returns TableAgent output for review
   - No file uploads needed - good for rapid iteration

3. **CLI script** (`scripts/test-table-agent.ts`):
   - Reads datamap from temp-outputs or specified path
   - Runs TableAgent and saves output
   - Can run outside Next.js for faster iteration

**Recommended approach**: Start with option 1 (env flag) for minimal code changes. Add option 3 (CLI) if faster iteration needed.

**Output location**: `temp-outputs/output-<ts>/table-output-<ts>.json`

**What to validate:**
- Are question groups identified correctly?
- Is tableType selection appropriate for each normalizedType?
- Are row labels accurate?
- Are stats choices sensible?
- Does confidence scoring reflect actual certainty?

---

### Step 3 Results: Alternative Prompt Approach

After iterating on the production prompt, we developed an **alternative prompt** (`src/prompts/table/alternative.ts`) with significant simplifications. Set `TABLE_PROMPT_VERSION=alternative` to use.

**Key differences from production prompt:**

| Aspect | Production | Alternative |
|--------|------------|-------------|
| Table types | 6 types (frequency, mean_rows, grid_by_value, grid_by_item, multi_select, ranking) | **2 types** (frequency, mean_rows) |
| Derived variables | Implicitly allowed | **Explicitly forbidden** |
| Table quantity | "Be generous with table views" | **Row limit rule, split only when needed** |
| Hints | Not included | **Added for downstream processing** |

**Alternative prompt key features:**

1. **Decision Rule**: Direct mapping from `normalizedType` to `tableType`
   - `numeric_range` → `mean_rows`
   - `categorical_select` → `frequency`
   - `binary_flag` → `frequency` (filterValue="1")

2. **Row Limit Rule**: Max 20 rows per table
   - Only applies when multiple dimensions exist to split by
   - Single variable with many values (e.g., US States) stays as one table
   - Cascading split: first by dimension, then by sub-dimension if still > 20

3. **Hints Array**: Metadata for downstream deterministic processing
   - `"ranking"` - ranking question, downstream may add combined ranks
   - `"scale-5"` - 5-point Likert, downstream may add T2B/B2B
   - `"scale-7"` - 7-point Likert, downstream may add T3B/B3B

**Schema addition** (`TableDefinitionSchema`):
```typescript
hints: z.array(z.enum(['ranking', 'scale-5', 'scale-7']))
```

**Results on initial survey (42 question groups):**
- Correct table type selection based on normalizedType
- Appropriate splitting for large grids (e.g., A8: 5×3×5 → 5 tables of 15 rows each)
- Hints correctly applied (scale-5 for Likert questions, ranking for rank questions)
- No derived variables or hallucinated table types

---

### Data Flow: TableAgent → R → ExcelJS

Clarified pipeline responsibilities:

```
TableAgent                    R Script                      ExcelJS
───────────                   ────────                      ───────
Table definitions             For each (row × banner):      Takes JSON output
- tableId                     - Apply filterValue           Places values in cells
- tableType                   - Calculate count/%           Applies formatting
- rows (variable, filterValue)- Output JSON with values
- hints
                              Output:
                              { row, banner, n, count, % }
```

**R does all calculation**. ExcelJS is purely a formatter/renderer.

---

*Created: January 3, 2026*
*Updated: January 4, 2026 - Step 3 complete (alternative prompt), hints field added, row limit rule implemented*
