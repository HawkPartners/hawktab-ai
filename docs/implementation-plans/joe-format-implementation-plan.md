# Joe's Tab Format Implementation Plan

## Overview

This plan covers transforming HawkTab AI's Excel output from Antares-style (vertical stacking) to Joe's format (horizontal layout). The goal is **readability and usability**, not pixel-perfect copying of Joe's exact output.

**Core Principle**: Focus on high-impact changes that make tabs more usable for report writing. Partners should be able to sort, filter, navigate, and read without manual cleanup.

**Why This Matters**: This is make-or-break for product value. We need to serve:
- Partners who want improved Antares-style tabs
- Internal teams who expect Joe-quality output
- The sweet spot where both groups find the output useful

---

## High-Impact Changes (Priority Order)

### 1. Single Row Per Answer Option (Critical)
**Current**: 3 rows stacked (count, %, sig letters)
**Target**: 1 row with adjacent sig column

This is the #1 change. It enables sorting/filtering in Excel and dramatically improves readability.

### 2. Continuous Table Flow (High)
**Current**: Fixed 2-row gap between every table (`TABLE_SPACING.gapBetweenTables = 2`)
**Target**: Tables flow continuously, no gaps within a question group

Tables for the same question (base table + derived views) should flow together. Section breaks can have larger spacing.

### 3. Freeze Panes at Cut Row (High)
**Current**: No freeze panes
**Target**: Freeze at the row containing banner cuts (dynamically calculated, not hardcoded)

Users should always see the banner structure when scrolling. Freeze both:
- Rows: Everything up to and including the cut names/stat letters row
- Column A+B: Labels stay visible when scrolling horizontally

### 4. Color-Coded Significance Letters (High)
**Current**: Gray text, hard to notice
**Target**: Colored text (red/maroon) that stands out

The goal is **readability** - users should immediately see which cells have significant differences. The exact color matters less than visibility.

### 5. Tables Sorted by QuestionId (Medium)
**Current**: Arbitrary order (dictionary key iteration)
**Target**: All tables for a question grouped together (S1, S1-derived, S2, S2-derived, etc.)

We now have `questionId` flowing through - use it to sort tables logically.

### 6. Context Column (Medium)
**Current**: Question text in title row above table
**Target**: Column A merged per-table with questionId + questionText

Provides persistent question context. User always sees what question they're looking at.

---

## System Architecture Analysis

### What Each Component Provides

| Component | What It Outputs | What's Available for Excel |
|-----------|-----------------|---------------------------|
| **DataMapProcessor** | Variable metadata, types, relationships | Lost after TableGenerator |
| **BannerAgent** | Banner groups, cuts, stat letters | Flows through to Excel |
| **TableGenerator** | Table definitions (deterministic) | Flows through |
| **VerificationAgent** | Enhanced tables, NETs, derived tables | questionId, isDerived, sourceTableId now flow through |
| **R Script** | Calculated statistics + sig testing | All stats available |
| **ExcelFormatter** | Final .xlsx output | Consumes tables.json |

### Current Data Gaps

| Need | Current State | Impact |
|------|---------------|--------|
| **Table ordering** | Arbitrary | Tables scattered, hard to navigate |
| **Continuous flow** | Fixed 2-row gaps | Wastes space, breaks visual flow |
| **Freeze row position** | None | Headers scroll away |
| **Sig letter visibility** | Gray text | Easy to miss significance |
| **Question grouping** | Flat list | Related tables not together |

### What We DON'T Need (Defer)

| Feature | Why Defer |
|---------|-----------|
| Section headers ("SCREENING SECTION") | Requires survey parsing, low ROI for now |
| Descriptive base text | Complex extraction, generic text works |
| Study metadata rows | Nice-to-have, not critical for readability |

---

## Column Structure Change

### Current (Antares - Vertical Stacking)
```
| Label | Total | Cut A | Cut B | Cut C |
|-------|-------|-------|-------|-------|
| Opt 1 |   45  |   50  |   40  |   48  |  <- Count row
|       |  25%  |  28%  |  22%  |  27%  |  <- Percent row
|       |   -   |   C   |   -   |   A   |  <- Sig row
| Opt 2 |  ...  |       |       |       |  <- Next answer (3 more rows)
```
**Problem**: Can't sort rows. Sig letters easy to miss. Wastes vertical space.

### Target (Joe's - Horizontal Layout)

**Header rows** (group names merged across their cuts, cut names merged across value+sig):
```
|         |       |    Total    |         Segment         |
|         |       |-------------|-------------------------|
| Context | Label | Total | Sig | Cut A | Sig | Cut B | Sig |
|---------|-------|-------|-----|-------|-----|-------|-----|
```

**Data rows** (Column A merged per-table with question context):
```
| S1:     | Opt 1 |  25%  |  -  |  28%  |  C  |  22%  |  -  |
| What is | Opt 2 |  17%  |  B  |  19%  |  -  |  16%  |  -  |
| your... | Opt 3 |  42%  |  A  |  38%  |  -  |  45%  |  B  |
| (merged)|       |       |     |       |     |       |     |
```

**Column A Context** (per-table merged cell):
- Merged across all rows for that table
- Contains: questionId + questionText
- Later can include: subtitle, notes, base description

**Benefits**: Sortable rows. Sig letters adjacent and colored. Compact. Question context always visible.

### Column Calculation
```
Total columns = 1 (context) + 1 (label) + (number_of_cuts × 2)
               = 2 + (cuts × 2)  // context + label + (value + sig per cut)
```

---

## Implementation Phases

### Phase 1: Core Layout Restructure

**Goal**: Single row per answer with adjacent sig columns.

**Files to Create/Modify**:
- `src/lib/excel/tableRenderers/joeStyleFrequency.ts` (new)
- `src/lib/excel/tableRenderers/joeStyleMeanRows.ts` (new)
- `src/lib/excel/ExcelFormatter.ts` (route to new renderers)
- `src/lib/excel/styles.ts` (add sig letter colors)

**Key Implementation Details**:

1. **Column structure calculation**
   ```typescript
   // Column A = context (merged per table), Column B = label
   // Each cut needs 2 columns: value + significance
   const CONTEXT_COL = 1;  // Column A - merged per table
   const LABEL_COL = 2;    // Column B - answer labels
   const valueColOffset = (cutIndex: number) => 3 + (cutIndex * 2);  // 3, 5, 7, ...
   const sigColOffset = (cutIndex: number) => 4 + (cutIndex * 2);    // 4, 6, 8, ...
   ```

2. **Single row rendering + Context column**
   ```typescript
   const tableStartRow = currentRow;

   // Render data rows
   for (const rowKey of rowKeys) {
     // Label column (B)
     const labelCell = worksheet.getCell(currentRow, LABEL_COL);
     labelCell.value = rowData.label;

     // Data columns (value + sig for each cut)
     for (let i = 0; i < cuts.length; i++) {
       const valueCell = worksheet.getCell(currentRow, valueColOffset(i));
       valueCell.value = formatPercent(cutData.pct);

       const sigCell = worksheet.getCell(currentRow, sigColOffset(i));
       sigCell.value = formatSig(cutData.sig_higher_than);
       sigCell.font = FONTS.significanceLetter;  // Colored!
     }
     currentRow++;
   }

   // Merge context column (A) for entire table
   const tableEndRow = currentRow - 1;
   worksheet.mergeCells(tableStartRow, CONTEXT_COL, tableEndRow, CONTEXT_COL);
   const contextCell = worksheet.getCell(tableStartRow, CONTEXT_COL);
   contextCell.value = `${table.questionId}: ${table.questionText}`;
   contextCell.alignment = { vertical: 'top', wrapText: true };
   ```

3. **Header with stat letters**
   ```typescript
   // Cut name row
   for (let i = 0; i < cuts.length; i++) {
     const cutCell = worksheet.getCell(headerRow, valueColOffset(i));
     cutCell.value = cut.name;
     worksheet.mergeCells(headerRow, valueColOffset(i), headerRow, sigColOffset(i));
   }

   // Stat letter row (colored)
   for (let i = 0; i < cuts.length; i++) {
     const letterCell = worksheet.getCell(statLetterRow, valueColOffset(i));
     letterCell.value = `(${cut.statLetter})`;
     letterCell.font = { color: { argb: 'FFCC0000' } };  // Red
   }
   ```

**Exit Criteria**:
- [ ] Single row per answer option
- [ ] Sig letters in adjacent column
- [ ] Sig letters colored (not gray)
- [ ] Tables render without errors

---

### Phase 2: Continuous Flow & Sorting

**Goal**: Tables flow together, sorted by questionId.

**Files to Modify**:
- `src/lib/excel/ExcelFormatter.ts`
- `src/lib/excel/styles.ts` (TABLE_SPACING)

**Key Changes**:

1. **Remove fixed gaps**
   ```typescript
   // OLD
   currentRow += TABLE_SPACING.gapBetweenTables;  // Always 2

   // NEW
   const prevQuestionId = tables[i - 1]?.questionId;
   const currQuestionId = tables[i].questionId;
   if (prevQuestionId !== currQuestionId) {
     currentRow += 1;  // Small gap between different questions
   }
   // No gap between tables with same questionId (base + derived)
   ```

2. **Sort tables before rendering**
   ```typescript
   // Sort by questionId, then by isDerived (base tables first)
   const sortedTableIds = Object.keys(tables).sort((a, b) => {
     const tableA = tables[a];
     const tableB = tables[b];

     // First by questionId
     const qCompare = (tableA.questionId || '').localeCompare(tableB.questionId || '');
     if (qCompare !== 0) return qCompare;

     // Then base tables before derived
     if (tableA.isDerived !== tableB.isDerived) {
       return tableA.isDerived ? 1 : -1;
     }

     return 0;
   });
   ```

**Exit Criteria**:
- [ ] Tables sorted by questionId
- [ ] No gaps between related tables
- [ ] Small gap between different questions

---

### Phase 3: Dynamic Freeze Panes

**Goal**: Headers stay visible when scrolling.

**Key Implementation**:

```typescript
// In ExcelFormatter, after rendering header rows
async formatFromJson(tablesJson: TablesJson): Promise<ExcelJS.Workbook> {
  // ... render headers ...

  // Calculate freeze position dynamically
  // Freeze after: group header row + cut name row + stat letter row + base row
  const freezeRow = this.headerRowCount;  // Calculated based on what was rendered
  const freezeCol = 1;  // Freeze label column

  this.worksheet.views = [
    {
      state: 'frozen',
      ySplit: freezeRow,
      xSplit: freezeCol,
      topLeftCell: `B${freezeRow + 1}`
    }
  ];
}
```

**Important**: Don't hardcode row 7 or 8. Calculate based on actual header structure.

**Exit Criteria**:
- [ ] Headers freeze when scrolling down
- [ ] Label column freezes when scrolling right
- [ ] Freeze position adapts to header structure

---

### Phase 4: Visual Polish

**Goal**: Professional, readable appearance.

**Changes to `styles.ts`**:

```typescript
// Add significance letter styling
export const FONTS = {
  // ... existing ...
  significanceLetter: {
    size: 10,
    color: { argb: 'FFCC0000' },  // Red - stands out
    bold: false,
  },
  significanceLetterHeader: {
    size: 10,
    color: { argb: 'FFCC0000' },  // Red
    bold: true,
  },
};

// Adjust column widths for new layout
export const COLUMN_WIDTHS = {
  label: 35,      // Answer option labels
  value: 8,       // Percentage values
  significance: 5, // Sig letters (narrow)
};
```

**Exit Criteria**:
- [ ] Sig letters visually prominent
- [ ] Column widths appropriate for content
- [ ] Consistent, professional appearance

---

### Phase 5: Configuration & Integration

**Goal**: Format selection, display modes, backward compatibility.

**Configuration Interface**:
```typescript
interface ExcelOptions {
  format: 'joe' | 'antares';           // Default: 'joe'
  displayMode: 'frequency' | 'counts' | 'both';
}
```

**Multiple Sheets Support** (when `displayMode: 'both'`):
```typescript
if (options.displayMode === 'both') {
  const pctSheet = workbook.addWorksheet('Percentages');
  const countSheet = workbook.addWorksheet('Counts');
  // Render same tables to both sheets with different value display
}
```

**Pipeline Flag**:
```bash
npx tsx scripts/test-pipeline.ts --format joe --display frequency
```

**Exit Criteria**:
- [ ] Format selection works
- [ ] Display mode selection works
- [ ] Multiple sheets when 'both' selected
- [ ] Antares format still works (backward compatible)

---

## Mean Rows Tables

Mean rows use the **same horizontal layout**:
- Single row per item
- Value column + adjacent sig column
- Decimal format (no % symbol)

```
| Label                     | Total | Sig | Cut A | Sig | Cut B | Sig |
|---------------------------|-------|-----|-------|-----|-------|-----|
| Mean Number of Patients   |       |     |       |     |       |     |
|   Radiation Segmentectomy | 33.7  |  C  | 40.7  |  A  | 36.3  |  -  |
|   Radiation Lobectomy     | 17.1  |  -  |  6.7  | EF  | 22.2  |  A  |
| Median                    |       |     |       |     |       |     |
|   Radiation Segmentectomy | 20.0  |  -  | 30.0  |  -  | 30.0  |  -  |
```

---

## Decisions Made

### Display Mode Options

| Mode | Output | Sheets |
|------|--------|--------|
| `frequency` (default) | Percentages only | 1 |
| `counts` | Counts only | 1 |
| `both` | Both | 2 sheets in same workbook |

### What We're NOT Doing (Phase 1)

| Feature | Reason |
|---------|--------|
| Section headers ("SCREENING SECTION") | Requires survey parsing, adds complexity |
| Descriptive base text | Generic text works, extraction is complex |
| Study metadata rows (title, date, firm) | Nice-to-have, not critical for readability |
| Rich context content (notes, skip logic) | Start with questionId + questionText, enrich later |

These can be added in future iterations once core layout is solid.

---

## Testing Strategy

1. **Unit test new renderers** with mock table data
2. **Run full pipeline** on primary dataset (leqvio)
3. **Visual comparison** with Joe's reference tabs
4. **Functional testing**: Can users sort rows? Are sig letters visible?

---

## Success Criteria

1. **Sortable**: Users can sort answer rows in Excel
2. **Readable**: Sig letters are immediately visible (colored)
3. **Navigable**: Related tables grouped together
4. **Scrollable**: Headers stay visible when scrolling
5. **Compact**: Less vertical space wasted (1 row vs 3)

---

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `src/lib/excel/tableRenderers/joeStyleFrequency.ts` | Create | New horizontal renderer |
| `src/lib/excel/tableRenderers/joeStyleMeanRows.ts` | Create | Mean rows horizontal renderer |
| `src/lib/excel/ExcelFormatter.ts` | Modify | Route to new renderers, add freeze panes |
| `src/lib/excel/styles.ts` | Modify | Add sig letter colors, adjust widths |
| `scripts/test-pipeline.ts` | Modify | Add format/display flags |

---

*Created: January 27, 2026*
*Status: Planning*
*Related: reliability-plan.md Part 4b*
