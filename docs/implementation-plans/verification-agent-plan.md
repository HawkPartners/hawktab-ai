# VerificationAgent Implementation Plan

**Status**: Planning
**Created**: 2026-01-07
**Priority**: High - Part 2 of Reliability Plan

---

## Overview

The VerificationAgent is the final intelligence layer before R script generation. It takes TableAgent output and enhances it using the actual survey document.

**Key Insight**: TableAgent makes reasonable guesses based on datamap structure, but it can't know:
- What the actual answer options say (e.g., "Value 1" vs "FDA approved for this indication")
- Whether a question should be split by treatment
- When roll-up/NET rows are semantically appropriate
- Which scale questions need T2B/B2B derived tables

**Design Principle**: The agent outputs the **desired end state** - not discrete actions. This handles complex cases naturally (e.g., "split by treatment AND add NETs AND create T2B").

### Pipeline Position

```
BannerAgent → CrosstabAgent → TableAgent → VerificationAgent → RScriptGeneratorV2 → Excel
                                    ↓              ↓
                              table-output.json   Survey (markdown)
                                                        ↓
                                              verified-table-output.json
```

VerificationAgent runs AFTER TableAgent completes all tables. Processes one table at a time.

---

## Part 1: SurveyProcessor

Convert survey DOCX to markdown for agent consumption.

### Location

`src/lib/processors/SurveyProcessor.ts`

### Implementation

Use LibreOffice for DOCX → HTML, then turndown for HTML → Markdown:

```typescript
import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';
import * as path from 'path';
import TurndownService from 'turndown';

const execAsync = promisify(exec);

export interface SurveyResult {
  markdown: string;
  warnings: string[];
}

export async function processSurvey(docxPath: string, outputDir: string): Promise<SurveyResult> {
  try {
    // Step 1: DOCX → HTML via LibreOffice
    await execAsync(
      `"/Applications/LibreOffice.app/Contents/MacOS/soffice" --headless --convert-to html --outdir "${outputDir}" "${docxPath}"`
    );

    // Step 2: Read HTML
    const basename = path.basename(docxPath, path.extname(docxPath));
    const htmlPath = path.join(outputDir, `${basename}.html`);
    const html = await fs.readFile(htmlPath, 'utf-8');

    // Step 3: HTML → Markdown
    const turndown = new TurndownService({ headingStyle: 'atx' });
    const markdown = turndown.turndown(html);

    // Cleanup temp HTML
    await fs.unlink(htmlPath).catch(() => {});

    return { markdown, warnings: [] };
  } catch (error) {
    return {
      markdown: '',
      warnings: [`Survey conversion failed: ${error}`],
    };
  }
}
```

### Graceful Fallback

If survey not provided or conversion fails: VerificationAgent passes tables through unchanged.

### Dependencies

- LibreOffice (already required for BannerAgent)
- `turndown` npm package (install: `npm install turndown @types/turndown`)

---

## Part 2: VerificationAgent

### Output Model

For each input table, the agent returns the **desired end state**:

```typescript
interface VerificationAgentOutput {
  tables: ExtendedTableDefinition[];  // 1+ output tables
  changes: string[];                   // What was modified
  confidence: number;                  // 0.0-1.0
}
```

| Output | Meaning |
|--------|---------|
| 1 table, unchanged | Pass through |
| 1 table, modified | Updated labels/structure |
| N tables | Split into multiple |
| 1 table with `exclude: true` | Move to reference sheet |
| 1+ tables with derived | Created T2B/B2B |

### Schema

```typescript
// src/schemas/verificationAgentSchema.ts
import { z } from 'zod';

export const ExtendedTableRowSchema = z.object({
  variable: z.string(),
  label: z.string(),
  filterValue: z.string(),          // Can be comma-separated: "4,5"
  isNet: z.boolean().optional(),
  netComponents: z.array(z.string()).optional(),
  indent: z.number().optional(),
});

export const ExtendedTableDefinitionSchema = z.object({
  tableId: z.string(),
  title: z.string(),
  tableType: z.enum(['frequency', 'mean_rows', 'grid_by_value', 'grid_by_item', 'multi_select', 'ranking']),
  rows: z.array(ExtendedTableRowSchema),
  hints: z.array(z.string()),       // Keep for compat, mostly empty
  sourceTableId: z.string().optional(),
  isDerived: z.boolean().optional(),
  exclude: z.boolean().optional(),
  excludeReason: z.string().optional(),
});

export const VerificationAgentOutputSchema = z.object({
  tables: z.array(ExtendedTableDefinitionSchema),
  changes: z.array(z.string()),
  confidence: z.number().min(0).max(1),
});
```

### Agent Implementation

`src/agents/VerificationAgent.ts` - same pattern as other agents:

1. Scratchpad tool for reasoning transparency
2. Structured output with Zod schema
3. Table-by-table processing loop
4. Combine results into verified output JSON

### Input Context

For each table, provide:
- The table definition from TableAgent
- The survey markdown (full document initially, can optimize later)
- The verbose datamap entry for variables in that table (prevents hallucination)

### Prompt Structure

```
You are a survey research expert reviewing crosstab table definitions.

## Survey Document
<survey>
{surveyMarkdown}
</survey>

## Variable Context
<datamap>
{verboseDatamapForThisTable}
</datamap>

## What You Can Do
- Fix labels: Replace "Value 1" with actual survey answer text
- Split tables: Create separate tables per treatment if survey shows them separately
- Add NET rows: Add roll-up rows when survey groups options (isNet: true, netComponents)
- Create T2B/B2B: For satisfaction/agreement scales, create derived summary tables
- Flag for exclusion: Set exclude: true for 100% response or low-value tables

## Constraints
- NEVER change variable names (SPSS column references)
- NEVER invent new variables
- filterValue must match actual data values

## Output
Return the desired tables array with your changes.
```

---

## Part 3: Derived Tables (T2B/B2B)

### Current Problem

RScriptGeneratorV2 generates T2B deterministically from hints, but collapses all dimensions - a multi-treatment scale becomes one T2B table instead of T2B per treatment.

### New Approach

VerificationAgent **creates** derived tables explicitly with proper structure:

```json
{
  "tables": [
    {
      "tableId": "a8_leqvio",
      "title": "A8 - Leqvio Satisfaction",
      "rows": [/* 5-point scale rows */]
    },
    {
      "tableId": "a8_leqvio_t2b",
      "title": "A8 - Leqvio Satisfaction (T2B/B2B)",
      "rows": [
        { "variable": "A8r1", "label": "Top 2 Box (4-5)", "filterValue": "4,5" },
        { "variable": "A8r1", "label": "Middle (3)", "filterValue": "3" },
        { "variable": "A8r1", "label": "Bottom 2 Box (1-2)", "filterValue": "1,2" }
      ],
      "isDerived": true,
      "sourceTableId": "a8_leqvio"
    }
  ]
}
```

### What Changes

| Component | Before | After |
|-----------|--------|-------|
| TableAgent | Adds scale hints | Adds no hints |
| VerificationAgent | N/A | Creates derived tables |
| RScriptGeneratorV2 | Generates from hints | Processes uniformly |

---

## Part 4: Downstream Updates

### RScriptGeneratorV2

1. **Handle comma-separated filterValues**: `"4,5"` → count values 4 OR 5
2. **Handle NET rows**: Aggregate `netComponents` for `isNet: true` rows
3. **Remove hint-based derived table generation**: No longer needed
4. **Separate excluded tables**: Don't generate R code for `exclude: true` tables

### ExcelFormatter

1. **Reference sheet**: Tables with `exclude: true` go to separate "Reference" sheet
2. **Indented rows**: Display rows with `indent > 0` with visual indentation
3. **Derived table grouping**: Optionally group derived tables near their source

---

## Part 5: Testing

### Dedicated Test Script

Create `scripts/test-verification-agent.ts` that:
1. Takes existing TableAgent output (e.g., from `temp-outputs/test-pipeline-*/table-output-*.json`)
2. Runs SurveyProcessor on the survey document
3. Runs VerificationAgent
4. Saves output to `verified-table-output-*.json` and `verification-scratchpad-*.md`

This allows testing VerificationAgent in isolation without re-running the full pipeline.

### Integration

Once working, add to `scripts/test-pipeline.ts` as a new stage between TableAgent and RScriptGeneratorV2.

---

## Part 6: Risks & Open Questions

### Key Risks

| Risk | Mitigation |
|------|------------|
| Survey too long for context | Start with full doc; if needed, extract section around question number |
| Agent creates invalid filterValues | R script validates values exist in data |
| NET calculation incorrect | Test against manual calculation |

### Open Questions

1. **NET row R implementation**: Aggregate `netComponents` in R, or generate synthetic variable?
2. **Context optimization**: If survey too long, extract relevant section per question (regex find question number, take window)
3. **TableAgent hints**: Remove hint logic entirely, or keep as fallback when no survey provided?
4. **Excluded tables**: Show in "Reference" sheet with full calculations, or just metadata?

---

## Appendix: Examples

### A. Label Update

**Before** (TableAgent):
```json
{ "variable": "A1r1", "label": "Leqvio (inclisiran) - Value 1", "filterValue": "1" }
```

**After** (VerificationAgent):
```json
{ "variable": "A1r1", "label": "FDA approved for ASCVD risk reduction", "filterValue": "1" }
```

### B. Split + T2B

**Before**: One table with all treatments × all scale values

**After**: 6 tables
- `a8_leqvio` + `a8_leqvio_t2b`
- `a8_praluent` + `a8_praluent_t2b`
- `a8_repatha` + `a8_repatha_t2b`

### C. NET Rows

**Before**:
```json
{ "variable": "S2br1", "label": "Physician", "filterValue": "1" },
{ "variable": "S2br2", "label": "Nurse Practitioner", "filterValue": "2" },
{ "variable": "S2br3", "label": "Physician Assistant", "filterValue": "3" }
```

**After**:
```json
{ "variable": "S2br1", "label": "Physician", "filterValue": "1" },
{ "variable": "_NET_APP", "label": "APP (Total)", "isNet": true, "netComponents": ["S2br2", "S2br3"] },
{ "variable": "S2br2", "label": "Nurse Practitioner", "filterValue": "2", "indent": 1 },
{ "variable": "S2br3", "label": "Physician Assistant", "filterValue": "3", "indent": 1 }
```

### D. Exclude

```json
{
  "tableId": "s4",
  "title": "S4 - Board Certification",
  "exclude": true,
  "excludeReason": "100% board certified - no analytical value",
  "rows": [...]
}
```

---

*Created: January 7, 2026*
*Part of: Reliability Plan - Part 2*
