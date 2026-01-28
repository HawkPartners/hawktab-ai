# Crosstab Output Enhancements - Implementation Plan

A phased plan to bring HawkTab crosstab output to production quality, matching industry standards and Joe's reference output.

---

## Phase 1: Critical Bug Fix - Range FilterValue Support

**Priority:** HIGH - Currently breaking useful feature (binned distributions)

### Problem
VerificationAgent creates binned distribution tables with range syntax (`filterValue: "0-4"`), but R script only handles single values and comma-separated lists. Result: 0% for all binned rows.

### Changes Required

**File: `src/lib/r/RScriptGeneratorV2.ts`**
- Detect range syntax in filterValue (pattern: `/^\d+-\d+$/`)
- Generate appropriate R filter: `VAR >= X & VAR <= Y`
- Handle in `generateFilterExpression()` or equivalent

**Example transformation:**
```
filterValue: "0-4"   → data$S6 >= 0 & data$S6 <= 4
filterValue: "10-35" → data$S6 >= 10 & data$S6 <= 35
```

### Acceptance Criteria
- [ ] Range filterValues produce correct percentages
- [ ] Existing single-value and comma-separated filterValues still work
- [ ] S6 distribution table shows correct data (not 0%)

---

## Phase 2: Schema Enhancements

**Goal:** Add new fields to support richer table metadata

### Changes Required

**File: `src/schemas/verificationAgentSchema.ts`**

Add to `ExtendedTableDefinitionSchema`:
```typescript
// Survey section (e.g., "SCREENING SECTION", "AWARENESS")
surveySection: z.string(),

// Table category beyond frequency/mean_rows
// blank = only table for question, otherwise: overview | summary | derived
tableCategory: z.enum(['', 'overview', 'summary', 'derived']),

// Base text - WHO was asked (not the question text)
baseText: z.string(),

// Optional user-facing note for additional context
userNote: z.string(),
```

**File: `src/schemas/tableAgentSchema.ts`**
- Review if any fields need to flow through from TableAgent

**File: `src/lib/excel/ExcelFormatter.ts`**
- Update `TableData` interface to include new fields

### Acceptance Criteria
- [ ] Schema validates with new fields
- [ ] TypeScript types updated throughout pipeline
- [ ] No breaking changes to existing flow

---

## Phase 3: Verification Agent Improvements

**Goal:** Better metadata extraction and consistency

### 3.1 Question Text Accuracy

**File: `src/prompts/verification/production.ts`**

Update prompt to enforce:
- Use EXACT question text from survey (no paraphrasing)
- Format: Period separator, not colon (`S1.` not `S1:`)
- Copy verbatim - preserve original punctuation

### 3.2 Survey Section Extraction

**File: `src/prompts/verification/production.ts`**

Add instruction to:
- Identify survey section for each question
- Populate `surveySection` field
- Common sections: "SCREENING", "AWARENESS", "USAGE", "ATTITUDES", etc.

### 3.3 Table Category Classification

**File: `src/prompts/verification/production.ts`**

Add instruction for `tableCategory`:
- Leave blank if only one table for the question
- `overview` - main/full table when multiple exist
- `summary` - rolled-up/aggregated view
- `derived` - calculated from another table (T2B, binned, etc.)

### 3.4 Base Text Determination

**File: `src/prompts/verification/production.ts`**

Add instruction for `baseText`:
- Describe WHO was asked, not WHAT was asked
- Good: "Total interventional radiologists/oncologists"
- Good: "Those who manage/treat any other primary & secondary liver cancers"
- Bad: "What is your primary specialty/role?" (this is question text, not base)

**Fallback approach (if skip logic too complex):**
- "All respondents" - for questions everyone saw
- "Filtered respondents" - for questions with skip logic

### 3.5 User-Facing Notes

**File: `src/prompts/verification/production.ts`**

Add instruction for `userNote`:
- Use sparingly for helpful context
- Examples: "(Asked if S2 = 1 or 2)", "Multiple answers accepted", "Responses sorted descending"

### Acceptance Criteria
- [ ] Question text matches survey exactly
- [ ] Period separator used consistently
- [ ] Survey sections populated
- [ ] Table categories assigned correctly
- [ ] Base text describes population, not question
- [ ] User notes added where helpful

---

## Phase 4: R Script Enhancements

**Goal:** Calculate all tables, generate demo table, support multiple significance thresholds

### 4.1 Calculate Excluded Tables

**File: `src/lib/r/RScriptGeneratorV2.ts`**

Current behavior: Excluded tables are skipped entirely
New behavior: Calculate them but flag as excluded

- Remove the skip logic for excluded tables
- Generate R code for all tables
- Add `excluded: true` flag in output JSON
- Add `excludeReason` in output

### 4.2 Demo Table Generation (Banner x Banner)

**File: `src/lib/r/RScriptGeneratorV2.ts`**

Add function to generate demo table:
- Auto-generated from banner structure (no AI)
- Rows = all banner groups and their cuts (with hierarchy)
- Columns = same cuts as all other tables
- Always generated, always first in output

```
tableId: "_demo_banner_x_banner"
questionText: "Banner Profile"
surveySection: "DEMO"
```

### 4.3 Multiple Significance Thresholds

**File: `src/lib/r/RScriptGeneratorV2.ts`**

Support up to 2 significance thresholds:
- Run significance tests at both levels (e.g., 95% and 90%)
- Output separate sig letters for each threshold
- Higher threshold = uppercase (A, B, C)
- Lower threshold = lowercase (a, b, c)

**Configuration:**
```typescript
significanceThresholds: [0.95, 0.90]  // or just [0.95]
```

### 4.4 Metadata in Output

**File: `src/lib/r/RScriptGeneratorV2.ts`**

Include in `tables.json` metadata:
```json
{
  "metadata": {
    "significanceTest": "unpooled z-test for column proportions",
    "significanceThresholds": [0.95, 0.90],
    "generatedAt": "...",
    "totalRespondents": 168
  }
}
```

### Acceptance Criteria
- [ ] Excluded tables calculated and in output
- [ ] Demo table generated and appears first
- [ ] Multiple significance thresholds working
- [ ] Uppercase/lowercase letters correct
- [ ] Metadata includes significance info

---

## Phase 5: Excel Formatter Enhancements

**Goal:** New sheets, better display of metadata

### 5.1 Table of Contents Sheet

**File: `src/lib/excel/ExcelFormatter.ts`**
**New file: `src/lib/excel/tableRenderers/tableOfContents.ts`**

Create ToC as first sheet:
- List all tables with: Table #, Question ID, Question Text, Section
- Group by survey section
- Hyperlinks to table locations (if feasible)

### 5.2 Excluded Tables Sheet

**File: `src/lib/excel/ExcelFormatter.ts`**
**New file: `src/lib/excel/tableRenderers/excludedSheet.ts`**

Create "Excluded" sheet:
- Render excluded tables with same formatting
- Show exclusion reason for each
- Separate from main crosstabs

### 5.3 Demo Table Rendering

**File: `src/lib/excel/ExcelFormatter.ts`**

Ensure demo table (banner x banner):
- Renders first, before all other tables
- Same Joe formatting as other tables
- Proper hierarchy/indentation for banner groups

### 5.4 Multi-Threshold Significance Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Handle uppercase/lowercase sig letters:
- Both use red color
- Uppercase = higher threshold
- Lowercase = lower threshold
- Can appear together (e.g., "Aa" means sig at both levels)

### 5.5 Survey Section Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Display survey section:
- Show above or alongside question text
- Format: "SCREENING SECTION" (all caps, or styled differently)

### 5.6 Base Text Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Update base row:
- Use `baseText` field (not question text)
- Format: "Base: [baseText]"
- Falls back to "Base: All respondents" if empty

### 5.7 Table Category Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Show table category in context/title:
- Derived tables: "[Derived from {sourceTableId}]"
- Summary tables: "Summary Table" or similar
- Overview tables: "Overview" when multiple tables exist

### 5.8 User Note Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Display `userNote` field:
- Show below question text or in context column
- Parenthetical format: "(Asked if S2 = 1 or 2)"

### Acceptance Criteria
- [ ] ToC sheet generated with all tables listed
- [ ] Excluded tables on separate sheet
- [ ] Demo table appears first
- [ ] Sig letters show uppercase/lowercase correctly
- [ ] Survey section displayed
- [ ] Base text shows population, not question
- [ ] Table category shown for derived/summary
- [ ] User notes displayed when present

---

## Phase 6: Multi-Banner Support (Future)

**Goal:** Handle multiple banners with proper sheet organization

### When Multiple Banners Exist

**Sheet organization - Option A (separate workbooks):**
```
Percentages.xlsx:
  - ToC
  - Banner 1
  - Banner 2
  - Excluded

Counts.xlsx:
  - ToC
  - Banner 1
  - Banner 2
  - Excluded
```

**Sheet organization - Option B (single workbook):**
```
Workbook.xlsx:
  - ToC
  - Banner 1 - Percentages
  - Banner 1 - Counts
  - Banner 2 - Percentages
  - Banner 2 - Counts
  - Excluded
```

### Files Affected
- `src/lib/excel/ExcelFormatter.ts` - Sheet organization logic
- `src/lib/r/RScriptGeneratorV2.ts` - Multi-banner R code generation
- Banner metadata and configuration

### Note
This phase depends on having multi-banner support in the pipeline. Current system assumes single banner. Implement when multi-banner becomes a requirement.

---

## Summary: File Change Map

| File | Phases |
|------|--------|
| `src/lib/r/RScriptGeneratorV2.ts` | 1, 4.1, 4.2, 4.3, 4.4 |
| `src/schemas/verificationAgentSchema.ts` | 2 |
| `src/prompts/verification/production.ts` | 3.1, 3.2, 3.3, 3.4, 3.5 |
| `src/lib/excel/ExcelFormatter.ts` | 2, 5.1, 5.2, 5.3 |
| `src/lib/excel/tableRenderers/joeStyleFrequency.ts` | 5.4, 5.5, 5.6, 5.7, 5.8 |
| `src/lib/excel/tableRenderers/joeStyleMeanRows.ts` | 5.4, 5.5, 5.6, 5.7, 5.8 |
| `src/lib/excel/tableRenderers/tableOfContents.ts` | 5.1 (new file) |
| `src/lib/excel/tableRenderers/excludedSheet.ts` | 5.2 (new file) |

---

## Execution Order Recommendation

1. **Phase 1** - Bug fix first (range filterValue) - unblocks binning feature
2. **Phase 2** - Schema changes - foundation for everything else
3. **Phase 3** - Verification agent - populates new fields
4. **Phase 4** - R script - calculates everything correctly
5. **Phase 5** - Excel formatter - displays everything correctly
6. **Phase 6** - Multi-banner - future enhancement

Each phase builds on the previous. Complete phases in order.

---

*Created: 2026-01-27*
