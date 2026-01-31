/**
 * Frequency Table Renderer
 *
 * Renders frequency tables with Antares-style formatting:
 * - 3 rows per answer option: count, percent, significance
 * - Multi-row headers with group/column/stat letter
 * - Heavy borders between banner groups
 */

import type { Worksheet, Cell, Borders } from 'exceljs';
import { FILLS, BORDERS, FONTS, ALIGNMENTS } from '../styles';
import type { BannerGroup } from '../../r/RScriptGeneratorV2';

// =============================================================================
// Types
// =============================================================================

export interface FrequencyRowData {
  label: string;
  n: number;
  count: number;
  pct: number;
  sig_higher_than?: string[] | string;
  sig_vs_total?: string | null;
  isNet?: boolean;    // NET/roll-up row (should be bold)
  indent?: number;    // Indentation level (0 = normal, 1+ = indented under NET)
}

export interface FrequencyCutData {
  stat_letter: string;
  [rowKey: string]: FrequencyRowData | string; // string is for stat_letter
}

export interface FrequencyTableData {
  tableId: string;
  questionId: string;
  questionText: string;
  tableType: 'frequency';
  isDerived: boolean;
  sourceTableId: string;
  data: Record<string, FrequencyCutData>;
}

export interface RenderContext {
  totalRespondents: number;
  bannerGroups: BannerGroup[];
  comparisonGroups: string[];
  significanceLevel: number;
}

// =============================================================================
// Helper Functions
// =============================================================================

function applyBorderForColumn(
  cell: Cell,
  colIndex: number,
  groupBoundaries: number[],
  isLastCol: boolean
): void {
  // Check if this column is at a group boundary (last column of a group)
  if (groupBoundaries.includes(colIndex) || isLastCol) {
    cell.border = BORDERS.groupSeparatorRight as Partial<Borders>;
  } else {
    cell.border = BORDERS.thin as Partial<Borders>;
  }
}

function formatSignificance(sig: string[] | string | undefined): string {
  if (!sig) return '-';
  if (typeof sig === 'string') return sig || '-';
  if (Array.isArray(sig) && sig.length > 0) {
    return sig.join(',');
  }
  return '-';
}

// =============================================================================
// Main Renderer
// =============================================================================

export function renderFrequencyTable(
  worksheet: Worksheet,
  table: FrequencyTableData,
  startRow: number,
  context: RenderContext
): number {
  const { bannerGroups, comparisonGroups, totalRespondents, significanceLevel } = context;
  let currentRow = startRow;

  // Build flat list of cuts in order: Total first, then groups
  const cutOrder: { name: string; statLetter: string; groupName: string }[] = [];
  const groupBoundaries: number[] = []; // Column indices where groups end

  let colIndex = 1; // Start after label column
  for (const group of bannerGroups) {
    for (const col of group.columns) {
      cutOrder.push({ name: col.name, statLetter: col.statLetter, groupName: group.groupName });
      colIndex++;
    }
    // Mark the last column of each group as a boundary
    groupBoundaries.push(colIndex - 1);
  }

  const totalCols = cutOrder.length;

  // -------------------------------------------------------------------------
  // Row 1: Question Text (Title)
  // -------------------------------------------------------------------------
  // Build title: "QuestionId. QuestionText" (system always prepends for consistency)
  // Agent outputs verbatim question text without the question number prefix
  let titleText = table.questionId
    ? `${table.questionId}. ${table.questionText}`
    : table.questionText;
  if (table.isDerived && table.sourceTableId) {
    titleText += ` [Derived from ${table.sourceTableId}]`;
  }

  const titleCell = worksheet.getCell(currentRow, 1);
  titleCell.value = titleText;
  titleCell.font = FONTS.title;
  titleCell.fill = FILLS.title;
  titleCell.alignment = ALIGNMENTS.left;
  worksheet.mergeCells(currentRow, 1, currentRow, totalCols + 1);
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 2: Base description
  // -------------------------------------------------------------------------
  // Get base n from Total column first row
  const totalCutData = table.data['Total'];
  const rowKeys = Object.keys(totalCutData || {}).filter(k => k !== 'stat_letter');
  const firstRowKey = rowKeys[0];
  const firstRowData = totalCutData?.[firstRowKey] as FrequencyRowData | undefined;
  const baseN = firstRowData?.n || 0;

  const baseDescription = baseN === totalRespondents ? 'Base: Total' : 'Base: Shown this question';
  const baseCell = worksheet.getCell(currentRow, 1);
  baseCell.value = baseDescription;
  baseCell.font = FONTS.label;
  baseCell.fill = FILLS.title;
  baseCell.alignment = ALIGNMENTS.left;
  worksheet.mergeCells(currentRow, 1, currentRow, totalCols + 1);
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 3: Group headers (merged cells)
  // -------------------------------------------------------------------------
  let headerCol = 2; // Start after label column
  worksheet.getCell(currentRow, 1).value = '';
  worksheet.getCell(currentRow, 1).fill = FILLS.groupHeader;
  worksheet.getCell(currentRow, 1).border = BORDERS.thin as Partial<Borders>;

  for (const group of bannerGroups) {
    const startCol = headerCol;
    const endCol = headerCol + group.columns.length - 1;

    if (group.columns.length > 1) {
      worksheet.mergeCells(currentRow, startCol, currentRow, endCol);
    }

    const groupCell = worksheet.getCell(currentRow, startCol);
    groupCell.value = group.groupName;
    groupCell.font = FONTS.header;
    groupCell.fill = FILLS.groupHeader;
    groupCell.alignment = ALIGNMENTS.center;
    groupCell.border = BORDERS.groupSeparatorRight as Partial<Borders>;

    headerCol = endCol + 1;
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 4: Column headers (cut names)
  // -------------------------------------------------------------------------
  worksheet.getCell(currentRow, 1).value = '';
  worksheet.getCell(currentRow, 1).fill = FILLS.groupHeader;
  worksheet.getCell(currentRow, 1).border = BORDERS.thin as Partial<Borders>;

  for (let i = 0; i < cutOrder.length; i++) {
    const cell = worksheet.getCell(currentRow, i + 2);
    cell.value = cutOrder[i].name;
    cell.font = FONTS.header;
    cell.fill = FILLS.groupHeader;
    cell.alignment = ALIGNMENTS.center;
    applyBorderForColumn(cell, i + 2, groupBoundaries.map(b => b + 1), i === cutOrder.length - 1);
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 5: Stat letters
  // -------------------------------------------------------------------------
  worksheet.getCell(currentRow, 1).value = '';
  worksheet.getCell(currentRow, 1).fill = FILLS.groupHeader;
  worksheet.getCell(currentRow, 1).border = BORDERS.thin as Partial<Borders>;

  for (let i = 0; i < cutOrder.length; i++) {
    const cell = worksheet.getCell(currentRow, i + 2);
    cell.value = `(${cutOrder[i].statLetter})`;
    cell.font = FONTS.statLetter;
    cell.fill = FILLS.groupHeader;
    cell.alignment = ALIGNMENTS.center;
    applyBorderForColumn(cell, i + 2, groupBoundaries.map(b => b + 1), i === cutOrder.length - 1);
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 6: Base n row
  // -------------------------------------------------------------------------
  const baseLabel = worksheet.getCell(currentRow, 1);
  baseLabel.value = 'Base (n)';
  baseLabel.font = FONTS.label;
  baseLabel.fill = FILLS.baseRow;
  baseLabel.alignment = ALIGNMENTS.left;
  baseLabel.border = BORDERS.thin as Partial<Borders>;

  for (let i = 0; i < cutOrder.length; i++) {
    const cutName = cutOrder[i].name;
    const cutData = table.data[cutName];
    const rowData = cutData?.[firstRowKey] as FrequencyRowData | undefined;
    const n = rowData?.n || 0;

    const cell = worksheet.getCell(currentRow, i + 2);
    cell.value = n;
    cell.font = FONTS.data;
    cell.fill = FILLS.baseRow;
    cell.alignment = ALIGNMENTS.center;
    applyBorderForColumn(cell, i + 2, groupBoundaries.map(b => b + 1), i === cutOrder.length - 1);
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Data rows: 3 rows per answer option (count, percent, significance)
  // -------------------------------------------------------------------------
  for (const rowKey of rowKeys) {
    const totalRowData = totalCutData?.[rowKey] as FrequencyRowData | undefined;
    const isNet = totalRowData?.isNet || false;
    const indent = totalRowData?.indent || 0;

    // Build label with indentation prefix for component rows
    let rowLabel = totalRowData?.label || rowKey;
    if (indent > 0) {
      rowLabel = '  '.repeat(indent) + rowLabel;  // 2 spaces per indent level
    }

    // Row 1: Label + Count
    const labelCell = worksheet.getCell(currentRow, 1);
    labelCell.value = rowLabel;
    labelCell.font = isNet ? FONTS.labelNet : FONTS.label;  // Bold for NET rows
    labelCell.fill = FILLS.labelColumn;
    labelCell.alignment = ALIGNMENTS.wrapText;
    labelCell.border = BORDERS.thin as Partial<Borders>;

    for (let i = 0; i < cutOrder.length; i++) {
      const cutName = cutOrder[i].name;
      const cutData = table.data[cutName];
      const rowData = cutData?.[rowKey] as FrequencyRowData | undefined;

      const cell = worksheet.getCell(currentRow, i + 2);
      const count = rowData?.count;
      if (count !== undefined && count !== null) {
        cell.value = count;  // Store as number
      } else {
        cell.value = '-';
      }
      cell.font = FONTS.data;
      cell.fill = FILLS.data;
      cell.alignment = ALIGNMENTS.center;
      applyBorderForColumn(cell, i + 2, groupBoundaries.map(b => b + 1), i === cutOrder.length - 1);
    }
    currentRow++;

    // Row 2: Percent
    const pctLabelCell = worksheet.getCell(currentRow, 1);
    pctLabelCell.value = '';
    pctLabelCell.fill = FILLS.labelColumn;
    pctLabelCell.border = BORDERS.thin as Partial<Borders>;

    for (let i = 0; i < cutOrder.length; i++) {
      const cutName = cutOrder[i].name;
      const cutData = table.data[cutName];
      const rowData = cutData?.[rowKey] as FrequencyRowData | undefined;

      const cell = worksheet.getCell(currentRow, i + 2);
      const pct = rowData?.pct;
      if (pct !== undefined && pct !== null) {
        cell.value = pct / 100;  // Store as decimal (0.25 for 25%)
        cell.numFmt = '0%';       // Display as "25%"
      } else {
        cell.value = '-';
      }
      cell.font = FONTS.data;
      cell.fill = FILLS.data;
      cell.alignment = ALIGNMENTS.center;
      applyBorderForColumn(cell, i + 2, groupBoundaries.map(b => b + 1), i === cutOrder.length - 1);
    }
    currentRow++;

    // Row 3: Significance
    const sigLabelCell = worksheet.getCell(currentRow, 1);
    sigLabelCell.value = '';
    sigLabelCell.fill = FILLS.labelColumn;
    sigLabelCell.border = BORDERS.thin as Partial<Borders>;

    for (let i = 0; i < cutOrder.length; i++) {
      const cutName = cutOrder[i].name;
      const cutData = table.data[cutName];
      const rowData = cutData?.[rowKey] as FrequencyRowData | undefined;

      const cell = worksheet.getCell(currentRow, i + 2);
      cell.value = formatSignificance(rowData?.sig_higher_than);
      cell.font = FONTS.significance;
      cell.fill = FILLS.data;
      cell.alignment = ALIGNMENTS.center;
      applyBorderForColumn(cell, i + 2, groupBoundaries.map(b => b + 1), i === cutOrder.length - 1);
    }
    currentRow++;
  }

  // -------------------------------------------------------------------------
  // Footer rows
  // -------------------------------------------------------------------------
  currentRow++; // Gap

  const sigFooter = worksheet.getCell(currentRow, 1);
  sigFooter.value = `Significance at ${Math.round((1 - significanceLevel) * 100)}% level. T-test for means, Z-test for proportions.`;
  sigFooter.font = FONTS.footer;
  sigFooter.alignment = ALIGNMENTS.left;
  worksheet.mergeCells(currentRow, 1, currentRow, totalCols + 1);
  currentRow++;

  if (comparisonGroups.length > 0) {
    const groupFooter = worksheet.getCell(currentRow, 1);
    groupFooter.value = `Comparison groups: ${comparisonGroups.join(', ')}`;
    groupFooter.font = FONTS.footer;
    groupFooter.alignment = ALIGNMENTS.left;
    worksheet.mergeCells(currentRow, 1, currentRow, totalCols + 1);
    currentRow++;
  }

  return currentRow;
}
