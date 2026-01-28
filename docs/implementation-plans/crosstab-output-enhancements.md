# Crosstab Output Enhancements - Implementation Plan

A phased plan to bring HawkTab crosstab output to production quality, matching industry standards and Joe's reference output.

---

## Phase 1: Critical Bug Fix - Range FilterValue Support ✅ COMPLETED

<details>
<summary>Click to expand Phase 1 details</summary>

**Priority:** HIGH - Currently breaking useful feature (binned distributions)

### Problem
VerificationAgent creates binned distribution tables with range syntax (`filterValue: "0-4"`), but R script only handles single values and comma-separated lists. Result: 0% for all binned rows.

### Changes Made

**File: `src/lib/r/RScriptGeneratorV2.ts`**
- Added range pattern detection: `/^(\d+)-(\d+)$/`
- Generates R filter: `as.numeric(var_col) >= X & as.numeric(var_col) <= Y`
- Handles ranges where min value may not exist in data (safe filtering)

**File: `src/prompts/verification/production.ts`**
- Added ACTION 3: ADD BINNED DISTRIBUTION FOR NUMERIC VARIABLES
- Documented range format: `"0-4"` means >= 0 AND <= 4 (inclusive)
- Renumbered subsequent actions (3→4, 4→5, 5→6, 6→7)

**Example transformation:**
```
filterValue: "0-4"   → sum(as.numeric(var_col) >= 0 & as.numeric(var_col) <= 4, na.rm = TRUE)
filterValue: "10-35" → sum(as.numeric(var_col) >= 10 & as.numeric(var_col) <= 35, na.rm = TRUE)
```

### Acceptance Criteria
- [x] Range filterValues produce correct percentages
- [x] Existing single-value and comma-separated filterValues still work
- [x] S6 distribution table shows correct data (not 0%)

*Completed: 2026-01-27*

</details>

---

## Phase 2: Schema Enhancements ✅ COMPLETED

<details>
<summary>Click to expand Phase 2 details</summary>

**Goal:** Add new fields to support richer table metadata

### Changes Made

**File: `src/schemas/verificationAgentSchema.ts`**
- Added `surveySection: z.string()` - Section name from survey (verbatim, ALL CAPS)
- Added `baseText: z.string()` - Who was asked (not the question text)
- Added `userNote: z.string()` - Agent-generated context note
- Updated `toExtendedTable()` helper with default empty strings

**Note:** `tableCategory` was NOT added. Use existing `isDerived` boolean instead.

**File: `src/prompts/verification/production.ts`**
- Added `<additional_metadata>` section with instructions for:
  - surveySection: Extract verbatim from survey, strip "SECTION X:" prefix
  - baseText: Describe WHO was asked, infer from skip logic/context
  - userNote: Sparingly add helpful context in parentheses
- Updated `<output_specifications>` with new fields
- Updated "ALL FIELDS REQUIRED" list

**File: `src/lib/r/RScriptGeneratorV2.ts`**
- Updated `generateFrequencyTable()` to pass through surveySection, baseText, userNote
- Updated `generateMeanRowsTable()` to pass through surveySection, baseText, userNote

**File: `src/lib/excel/ExcelFormatter.ts`**
- Updated `TableData` interface with optional surveySection, baseText, userNote fields

### Acceptance Criteria
- [x] Schema validates with new fields
- [x] TypeScript types updated throughout pipeline
- [x] No breaking changes to existing flow
- [x] R script passes new fields through to JSON output
- [x] Verification agent prompt includes instructions for new fields

*Completed: 2026-01-27*

</details>

---

## Phase 3: Verification Agent Improvements ✅ COMPLETED

<details>
<summary>Click to expand Phase 3 details</summary>

**Goal:** Better metadata extraction and consistency

### Changes Made

**File: `src/prompts/verification/production.ts`**

**3.1 Question Text Accuracy**
- Updated ACTION 1 to emphasize EXACT VERBATIM text from survey
- Only allowed modification: remove piping codes (or use generic placeholders like "[BRAND]")
- Explicitly states "do NOT paraphrase"

**3.2 Survey Section Extraction** (Done in Phase 2)
- Added `<additional_metadata>` section with surveySection instructions
- Extract verbatim from survey, ALL CAPS, strip "SECTION X:" prefix

**3.3 Table Category Classification** - SKIPPED
- Not needed as separate field
- Use existing `isDerived` boolean instead

**3.4 Base Text Determination** (Done in Phase 2)
- Added baseText instructions in `<additional_metadata>` section
- Only populate when NOT all respondents (skip logic/filtering)
- Empty string "" triggers count-based fallback in Excel

**3.5 User-Facing Notes** (Done in Phase 2)
- Added userNote instructions in `<additional_metadata>` section
- Use sparingly, parenthetical format

### Acceptance Criteria
- [x] Question text matches survey exactly (verbatim, no paraphrasing)
- [x] Survey sections populated via surveySection field
- [x] Table categories: using isDerived instead (no new field needed)
- [x] Base text describes population, not question
- [x] User notes added where helpful

*Completed: 2026-01-27*

</details>

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

### Prerequisites from Phase 2

Phase 2 added these fields to `ExtendedTableDefinition` (now flowing through to `tables.json`):
- `surveySection` - Section name from survey (e.g., "SCREENER", "INDICATION AWARENESS")
- `baseText` - Description of who was asked (e.g., "Total interventional radiologists")
- `userNote` - Agent-generated context (e.g., "(Multiple answers accepted)")

Phase 5 must render these fields appropriately.

**Note on tableCategory:** We do NOT have a separate `tableCategory` field. Use the existing `isDerived` boolean instead:
- `isDerived: true` → Show "[Derived from {sourceTableId}]" annotation
- `isDerived: false` → No category annotation needed

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

Display `surveySection` field (from Phase 2):
- Show above or alongside question text in context column
- Format: ALL CAPS (agent already outputs it this way)
- Example: "SCREENER" or "INDICATION AWARENESS, ALLOCATIONS & MONOTHERAPY PERCEPTIONS"

### 5.6 Base Text Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Update base row to use `baseText` field (from Phase 2):
- Currently hardcoded as "Base: {questionText.substring(0, 50)}..."
- Change to: "Base: {baseText}" when `baseText` is non-empty
- Falls back to "Base: All respondents" if `baseText` is empty string

### 5.7 Derived Table Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Use existing `isDerived` and `sourceTableId` fields:
- If `isDerived: true` AND `sourceTableId` is non-empty: Show "[Derived from {sourceTableId}]"
- This already partially exists in the code—verify it's working correctly

**No separate `tableCategory` field needed.**

### 5.8 User Note Display

**File: `src/lib/excel/tableRenderers/joeStyleFrequency.ts`**
**File: `src/lib/excel/tableRenderers/joeStyleMeanRows.ts`**

Display `userNote` field (from Phase 2):
- Show below question text in context column (or as a separate line)
- Already in parenthetical format from agent: "(Multiple answers accepted)"
- Only display if non-empty string

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

1. ~~**Phase 1** - Bug fix first (range filterValue) - unblocks binning feature~~ ✅ COMPLETED
2. ~~**Phase 2** - Schema changes - foundation for everything else~~ ✅ COMPLETED
3. ~~**Phase 3** - Verification agent prompt improvements~~ ✅ COMPLETED
4. **Phase 4** - R script enhancements (excluded tables, demo table, multi-threshold) ← NEXT
5. **Phase 5** - Excel formatter - displays new metadata fields
6. **Phase 6** - Multi-banner - future enhancement

Each phase builds on the previous. Complete phases in order.

---

*Created: 2026-01-27*
