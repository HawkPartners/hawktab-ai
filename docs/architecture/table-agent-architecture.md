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
```

**TableAgent.ts structure:**
- Import pattern from BannerAgent (similar structure)
- Uses `getTableModel()` from env
- Takes: processed datamap (grouped), survey markdown
- Returns: JSON table definitions per parent group
- Processes one parent group at a time (loop externally)

---

### Step 2: Survey Upload & Markdown Conversion

**UI changes:**
- Add survey file upload field (DOCX)
- Store survey alongside banner/datamap

**Conversion:**
- Add `src/lib/processors/SurveyProcessor.ts`
- Use existing DOCX → Markdown library (e.g., `mammoth`)
- Preserve question structure, answer options, skip logic notes

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
3. Process survey → Markdown (new)
4. Group datamap by parent question
5. Loop: For each parent group, call TableAgent
6. Collect all table definitions
7. Generate R code from definitions
8. Run R → JSON output
9. ExcelJS formatter → Excel

**New endpoint or update existing:**
- Accept survey file in addition to banner/datamap
- Return table definitions + formatted output

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

| Order | Step | Dependency | Effort |
|-------|------|------------|--------|
| 0 | Env variable separation | None | Small |
| 1 | Agent structure (files) | Step 0 | Small |
| 2 | Survey processor | None | Medium |
| 3 | Table agent prompt | Step 1 | Medium |
| 4 | Integration (API) | Steps 1-3 | Medium |
| 5 | R script updates | Step 4 | Medium |
| 6 | ExcelJS formatter | Step 5 | Medium |

**Iteration approach**: After Step 4, run on test data and iterate on prompt + table types based on what's missing.

---

*Created: January 3, 2026*
