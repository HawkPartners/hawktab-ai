# Joe's Tab Format Implementation Plan

## Overview

This plan covers the work to transform HawkTab AI's Excel output from Antares-style (vertical stacking) to Joe's format (horizontal layout with adjacent significance columns). Joe's format is the preferred standard at HawkPartners for readability and usability.

**Why This Matters**: Joe's tabs are not just prettier - they're more functional. Users can sort, filter, and navigate easily. This positions HawkTab AI to serve both:
- Partners who want Antares-style tabs improved
- Internal teams who expect Joe-quality output

---

## Current State vs Target State

### Layout Comparison

| Aspect | Current (Antares-Style) | Target (Joe's Format) |
|--------|-------------------------|----------------------|
| Rows per answer | 3 (count, %, sig stacked) | 1 (% + sig in adjacent columns) |
| Significance display | Below percentage in separate row | Adjacent column, same row |
| Counts shown | Yes (separate row) | No (percentages only) |
| Context column | None | Column A for Q text, notes |
| Header freeze | None | Frozen at row 7-8 |
| Study metadata | None | Title, date, firm at top |
| Base description | Generic ("Base: Total") | Descriptive (extracted from survey) |
| Stat letter colors | Gray text | Color-coded (red/maroon) |
| Banner group shading | Basic | Alternating colors per group |

### Column Structure Comparison

**Current (Antares):**
```
| Label | Total | Cut A | Cut B | Cut C | ...
|-------|-------|-------|-------|-------|
| Opt 1 |   45  |   50  |   40  |   48  |  <- Count
|       |  25%  |  28%  |  22%  |  27%  |  <- Percent
|       |   -   |   C   |   -   |   A   |  <- Sig letters
| Opt 2 |   30  |   35  |   28  |   32  |  <- Count (next answer)
...
```

**Target (Joe's):**
```
| Context | Label | Total | Sig | Cut A | Sig | Cut B | Sig | Cut C | Sig |
|---------|-------|-------|-----|-------|-----|-------|-----|-------|-----|
| Q1...   | Opt 1 |  25%  |  -  |  28%  |  C  |  22%  |  -  |  27%  |  A  |
|         | Opt 2 |  17%  |  B  |  19%  |  -  |  16%  |  -  |  18%  |  -  |
...
```

---

## Joe's Format - Detailed Specification

### Header Section (Rows 1-7, Frozen)

| Row | Content | Styling |
|-----|---------|---------|
| 1 | Study title | Bold, larger font |
| 2 | "Updated Tabulations" or version | Regular |
| 3 | "Conducted by: HawkPartners" | Regular |
| 4 | Date (e.g., "January 2026") | Regular |
| 5 | Empty spacing row | - |
| 6 | Banner group headers (merged across columns) | Bold, background color |
| 7 | Cut names + stat letters (A), (B), (C) | Stat letters colored red |

### Column Layout

| Column | Width | Content |
|--------|-------|---------|
| A | ~25 | Section headers, question text, notes (merged vertically) |
| B | ~40 | Answer option labels |
| C | ~8 | Total percentage |
| D | ~4 | Total significance letters |
| E | ~8 | Cut 1 percentage |
| F | ~4 | Cut 1 significance letters |
| ... | ... | Pattern repeats for each cut |

### Data Rows

Each answer option is ONE row:
- Column A: Merged cell containing question context (spans all rows for that question)
- Column B: Answer label (may be indented for sub-options)
- Columns C onwards: Alternating % and sig columns

### Visual Features

1. **Freeze panes**: Header rows frozen so they stay visible when scrolling
2. **Color-coded stat letters**: (A), (B), (C) in header row are colored (red/maroon)
3. **Significance letters in data**: Also colored when present
4. **Alternating banner group colors**: Each group has distinct background shade
5. **Merged cells for context**: Question text spans all answer rows in Column A
6. **Section separators**: "SCREENING SECTION", "MAIN SECTION" headers

### Base Row

- Descriptive text: "Base: Total interventional radiologists/oncologists"
- Shows N for each cut (not percentages)
- Styled distinctly (bold, background color)

### Mean Rows Tables

Mean rows use the **same horizontal layout** as frequency:

```
| Context | Label                    | Total | Sig | Cut A | Sig | Cut B | Sig |
|---------|--------------------------|-------|-----|-------|-----|-------|-----|
| S1b...  | Mean Number of Patients  |       |     |       |     |       |     |
|         |   Radiation Segmentectomy| 33.7  |  C  | 40.7  |  A  | 36.3  |  -  |
|         |   Radiation Lobectomy    | 17.1  |  -  |  6.7  | EF  | 22.2  |  A  |
|         | Median Number of Patients|       |     |       |     |       |     |
|         |   Radiation Segmentectomy| 20.0  |  -  | 30.0  |  -  | 30.0  |  -  |
```

- Values are decimals (no % symbol)
- Sig letters work the same way (t-test results)
- Metric type (Mean, Median) as a row header

---

## ExcelJS Capabilities Confirmation

All required features are supported:

| Feature | ExcelJS API | Status |
|---------|-------------|--------|
| Freeze panes | `worksheet.views = [{ state: 'frozen', ySplit: 7 }]` | Supported |
| Merged cells | `worksheet.mergeCells(startRow, startCol, endRow, endCol)` | Supported |
| Font colors | `cell.font = { color: { argb: 'FFCC0000' } }` | Supported |
| Background fills | `cell.fill = { type: 'pattern', pattern: 'solid', fgColor: {...} }` | Supported |
| Column widths | `worksheet.getColumn(n).width = 25` | Supported |
| Text wrapping | `cell.alignment = { wrapText: true, vertical: 'top' }` | Supported |
| Borders | `cell.border = { top: {...}, bottom: {...}, ... }` | Supported |
| Number formatting | `cell.numFmt = '0%'` | Supported |
| Row heights | `worksheet.getRow(n).height = 20` | Supported |

---

## Implementation Phases

### Phase 1: Core Layout Restructure

**Goal**: Change from 3-row vertical stacking to 1-row horizontal layout with adjacent sig columns.

#### Tasks

1. **Create new renderer: `joeStyleTable.ts`**
   - New file in `src/lib/excel/tableRenderers/`
   - Implements horizontal layout with adjacent sig columns
   - Single row per answer option

2. **Update column structure calculation**
   - Each banner cut needs 2 columns (value + sig)
   - Total columns = 2 (context + label) + (cuts * 2)

3. **Update header rendering**
   - Row for banner group names (merged across their cut columns)
   - Row for cut names + stat letters
   - Stat letters in parentheses, colored

4. **Update data row rendering**
   - One row per answer option
   - Percentage in odd columns, sig letters in even columns
   - Support for NET row bolding and indentation

5. **Add context column (Column A)**
   - Merged cells spanning all answer rows for a question
   - Contains question text, section headers, notes

#### Exit Criteria
- [ ] Single row per answer option renders correctly
- [ ] Sig letters appear in adjacent column
- [ ] Basic layout matches Joe's structure

---

### Phase 2: Header Enhancement

**Goal**: Add study metadata, freeze panes, and proper header styling.

#### Tasks

1. **Add study metadata rows (1-4)**
   - Study title (from user input or filename)
   - "Updated Tabulations"
   - "Conducted by: HawkPartners"
   - Date

2. **Implement freeze panes**
   - Freeze after header rows so they stay visible
   - `worksheet.views = [{ state: 'frozen', xSplit: 2, ySplit: 8 }]`

3. **Style banner group headers**
   - Merge cells across each group's columns
   - Apply distinct background colors per group

4. **Color-code stat letters**
   - Stat letters in header: red/maroon color
   - Stat letters in data: same color scheme

5. **Style base row**
   - Bold text
   - Distinct background color
   - N values (not percentages)

#### Exit Criteria
- [ ] Study metadata appears at top
- [ ] Headers freeze when scrolling
- [ ] Stat letters are color-coded
- [ ] Base row is styled distinctly

---

### Phase 3: Context Column & Merged Cells

**Goal**: Add Column A with merged question context cells.

#### Tasks

1. **Calculate merge ranges for context column**
   - Group tables by questionId
   - Determine row span for each question's answer options

2. **Render merged context cells**
   - Section headers ("SCREENING SECTION")
   - Question text
   - Notes (e.g., "(NOTES: Multiple answers accepted)")

3. **Handle question text formatting**
   - Include question number prefix (e.g., "S9.")
   - Wrap text for long questions
   - Vertical alignment: top

4. **Add section separators**
   - Visual break between sections
   - Section name as merged header row

#### Exit Criteria
- [ ] Column A shows merged question context
- [ ] Section headers separate logical groups
- [ ] Text wraps properly in merged cells

---

### Phase 4: Visual Polish

**Goal**: Match Joe's visual styling for professional appearance.

#### Tasks

1. **Implement alternating banner group colors**
   - Each group has distinct background shade
   - Colors should be subtle (light pastels)

2. **Refine column widths**
   - Context column: ~25
   - Label column: ~40
   - Value columns: ~8
   - Sig columns: ~4

3. **Add borders**
   - Heavier borders between banner groups
   - Light borders between cells within groups

4. **Optimize row heights**
   - Consistent heights for data rows
   - Taller rows for wrapped text

5. **Font standardization**
   - Consistent font family (e.g., Aptos Narrow, Calibri)
   - Appropriate sizes for headers vs data

#### Exit Criteria
- [ ] Banner groups visually distinct
- [ ] Column widths optimized for content
- [ ] Professional, polished appearance

---

### Phase 5: Integration & Configuration

**Goal**: Integrate Joe-style renderer into pipeline with format selection.

#### Tasks

1. **Add format selection option**
   - Pipeline flag: `--format joe` vs `--format antares`
   - Default to Joe's format

2. **Update ExcelFormatter to use new renderer**
   - Route to joeStyleTable.ts when Joe format selected
   - Maintain backward compatibility with Antares style

3. **Handle both frequency and mean_rows tables**
   - Joe-style renderer for frequency tables
   - Determine appropriate layout for mean tables

4. **Test with multiple datasets**
   - Primary dataset (leqvio)
   - Verify output matches Joe's format

5. **Update documentation**
   - Document format options
   - Update CLAUDE.md with new capabilities

#### Exit Criteria
- [ ] Format selection works via flag
- [ ] Both formats produce correct output
- [ ] Documentation updated

---

## Data Requirements

### What We Need from Upstream

For Joe's format to work fully, we need:

| Data | Source | Current Status |
|------|--------|----------------|
| questionId | VerificationAgent | Now flows through (just fixed) |
| questionText | VerificationAgent | Available |
| Section grouping | Survey document | Need to extract |
| Descriptive base text | Survey document | Need to extract |
| Study title | User input / filename | Need to add |
| Study date | User input | Need to add |

### Metadata to Add

Consider adding to pipeline input:
```typescript
interface StudyMetadata {
  title: string;           // "TheraSphere 360 Demand Study"
  subtitle?: string;       // "Updated Tabulations"
  conductedBy: string;     // "HawkPartners"
  date: string;            // "January 2026"
}

interface ExcelOptions {
  format: 'joe' | 'antares';           // Default: 'joe'
  displayMode: 'frequency' | 'counts' | 'both';  // Default: 'frequency'
}
```

### Multiple Sheets Support

When `displayMode: 'both'`, generate two sheets in one workbook:

```typescript
// ExcelJS supports multiple worksheets
const workbook = new ExcelJS.Workbook();

if (displayMode === 'both') {
  const pctSheet = workbook.addWorksheet('Percentages');
  const countSheet = workbook.addWorksheet('Counts');
  renderJoeStyleTable(pctSheet, tables, { showCounts: false });
  renderJoeStyleTable(countSheet, tables, { showCounts: true });
} else {
  const sheet = workbook.addWorksheet('Crosstabs');
  renderJoeStyleTable(sheet, tables, { showCounts: displayMode === 'counts' });
}
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Merged cell complexity | Medium | Medium | Start simple, add complexity incrementally |
| Performance with large tables | Low | Medium | Test with largest datasets early |
| Edge cases (grids, rankings) | Medium | High | Document known limitations, handle gracefully |
| Backward compatibility | Low | Medium | Keep Antares renderer, add format flag |

---

## Success Metrics

1. **Visual match**: Output looks like Joe's tabs at first glance
2. **Functional match**: Users can sort/filter rows in Excel
3. **Readability**: Partners can use tabs for report writing without manual cleanup
4. **Performance**: Generation time remains under 20 minutes for typical datasets

---

## Decisions Made

### Display Mode Options

Users can select display mode (UI toggle, pipeline flag):

| Mode | Output | Sheets |
|------|--------|--------|
| `frequency` (default) | Percentages only | 1 sheet |
| `counts` | Counts only | 1 sheet |
| `both` | Percentages + Counts | 2 sheets in same workbook |

ExcelJS supports multiple worksheets: `workbook.addWorksheet('Percentages')` and `workbook.addWorksheet('Counts')`.

### Mean Rows Tables

Mean rows use the **same horizontal layout** as frequency tables:
- Single row per item
- Value in one column, sig letters in adjacent column
- Decimal formatting (no % symbol) for means/medians

**Metrics to include (Phase 1):**
- Mean
- Median

**Defer for later:**
- Mean (minus outliers) - requires outlier calculation
- Standard deviation display

### Section Groupings

**Deferred** - Focus on styling first. Section groupings can be added later when we have reliable survey parsing.

## Open Questions

1. What's the fallback when questionId is missing?
2. Should derived tables (T2B) be visually distinguished?

---

## Timeline Estimate

| Phase | Complexity | Dependencies |
|-------|------------|--------------|
| Phase 1: Core Layout | High | None |
| Phase 2: Header Enhancement | Medium | Phase 1 |
| Phase 3: Context Column | Medium | Phase 1 |
| Phase 4: Visual Polish | Low | Phases 1-3 |
| Phase 5: Integration | Low | Phases 1-4 |

Phases 2-3 can run in parallel after Phase 1 is complete.

---

*Created: January 27, 2026*
*Status: Planning*
*Related: reliability-plan.md Part 4b*
