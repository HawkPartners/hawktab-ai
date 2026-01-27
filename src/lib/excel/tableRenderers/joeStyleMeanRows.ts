/**
 * Joe-Style Mean Rows Table Renderer
 *
 * Renders mean_rows tables with Joe's horizontal format:
 * - Single row per item (with mean value)
 * - Context column (merged per table) with questionId: questionText
 * - Label column for item names
 * - Value + Sig column pairs for each cut
 * - Mean values displayed as decimals (no percentage)
 */

import type { Worksheet, Cell, Borders } from 'exceljs';
import { FILLS, BORDERS, FONTS, ALIGNMENTS } from '../styles';
import type { JoeHeaderInfo } from './joeStyleFrequency';

// =============================================================================
// Types
// =============================================================================

export interface MeanRowData {
  label: string;
  n: number;
  mean: number | null;
  mean_label?: string;
  median: number | null;
  median_label?: string;
  sd: number | null;
  mean_no_outliers?: number | null;
  mean_no_outliers_label?: string;
  sig_higher_than?: string[] | string;
  sig_vs_total?: string | null;
  isNet?: boolean;
  indent?: number;
}

export interface MeanCutData {
  stat_letter: string;
  [rowKey: string]: MeanRowData | string;
}

export interface MeanRowsTableData {
  tableId: string;
  questionId: string;
  questionText: string;
  tableType: 'mean_rows';
  isDerived: boolean;
  sourceTableId: string;
  data: Record<string, MeanCutData>;
}

// =============================================================================
// Column Layout Helpers
// =============================================================================

const CONTEXT_COL = 1;
const LABEL_COL = 2;

function valueColOffset(cutIndex: number): number {
  return 3 + (cutIndex * 2);
}

function sigColOffset(cutIndex: number): number {
  return 4 + (cutIndex * 2);
}

// =============================================================================
// Helper Functions
// =============================================================================

function formatSignificance(sig: string[] | string | undefined): string {
  if (!sig) return '';
  if (typeof sig === 'string') return sig || '';
  if (Array.isArray(sig) && sig.length > 0) {
    return sig.join(',');
  }
  return '';
}

function applyBorderForColumn(
  cell: Cell,
  colIndex: number,
  groupBoundaries: number[],
  isLastCol: boolean
): void {
  if (groupBoundaries.includes(colIndex) || isLastCol) {
    cell.border = BORDERS.groupSeparatorRight as Partial<Borders>;
  } else {
    cell.border = BORDERS.thin as Partial<Borders>;
  }
}

/**
 * Set cell value as number or dash if null/undefined
 */
function setCellNumber(cell: Cell, val: number | null | undefined, decimalPlaces: number = 2): void {
  if (val === null || val === undefined || isNaN(val)) {
    cell.value = '-';
  } else {
    cell.value = val;
    cell.numFmt = decimalPlaces === 0 ? '0' : `0.${'0'.repeat(decimalPlaces)}`;
  }
}

// =============================================================================
// Main Renderer
// =============================================================================

export interface JoeMeanRowsRenderResult {
  endRow: number;
  contextMergeStart: number;
  contextMergeEnd: number;
}

/**
 * Render a single mean_rows table in Joe format
 * Returns the end row for chaining
 */
export function renderJoeStyleMeanRowsTable(
  worksheet: Worksheet,
  table: MeanRowsTableData,
  startRow: number,
  headerInfo: JoeHeaderInfo
): JoeMeanRowsRenderResult {
  const { cutOrder, groupBoundaries } = headerInfo;
  let currentRow = startRow;
  const contextMergeStart = currentRow;

  // Get row keys from Total cut
  const totalCutData = table.data['Total'];
  const rowKeys = Object.keys(totalCutData || {}).filter(k => k !== 'stat_letter');

  // -------------------------------------------------------------------------
  // Base (n) row
  // -------------------------------------------------------------------------
  const firstRowKey = rowKeys[0];

  // Context column (will be merged later)
  const baseContextCell = worksheet.getCell(currentRow, CONTEXT_COL);
  baseContextCell.value = '';
  baseContextCell.fill = FILLS.labelColumn;
  baseContextCell.border = BORDERS.thin as Partial<Borders>;

  // Label column
  const baseLabelCell = worksheet.getCell(currentRow, LABEL_COL);
  baseLabelCell.value = 'Base (n)';
  baseLabelCell.font = FONTS.label;
  baseLabelCell.fill = FILLS.baseRow;
  baseLabelCell.alignment = ALIGNMENTS.left;
  baseLabelCell.border = BORDERS.thin as Partial<Borders>;

  // Base n for each cut
  for (let i = 0; i < cutOrder.length; i++) {
    const cutName = cutOrder[i].name;
    const cutData = table.data[cutName];
    const rowData = cutData?.[firstRowKey] as MeanRowData | undefined;
    const n = rowData?.n || 0;

    const valCol = valueColOffset(i);
    const sigCol = sigColOffset(i);

    // Value column (n)
    const valCell = worksheet.getCell(currentRow, valCol);
    valCell.value = n;
    valCell.font = FONTS.data;
    valCell.fill = FILLS.baseRow;
    valCell.alignment = ALIGNMENTS.center;
    valCell.border = BORDERS.thin as Partial<Borders>;

    // Sig column (empty for base row)
    const sigCell = worksheet.getCell(currentRow, sigCol);
    sigCell.value = '';
    sigCell.fill = FILLS.baseRow;
    applyBorderForColumn(sigCell, sigCol, groupBoundaries, i === cutOrder.length - 1);
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Data rows: 1 row per item
  // -------------------------------------------------------------------------
  for (const rowKey of rowKeys) {
    const totalRowData = totalCutData?.[rowKey] as MeanRowData | undefined;
    const isNet = totalRowData?.isNet || false;
    const indent = totalRowData?.indent || 0;

    // Build label with indentation
    let rowLabel = totalRowData?.label || rowKey;
    if (indent > 0) {
      rowLabel = '  '.repeat(indent) + rowLabel;
    }

    // Context column (will be merged later)
    const contextCell = worksheet.getCell(currentRow, CONTEXT_COL);
    contextCell.value = '';
    contextCell.fill = FILLS.labelColumn;
    contextCell.border = BORDERS.thin as Partial<Borders>;

    // Label column
    const labelCell = worksheet.getCell(currentRow, LABEL_COL);
    labelCell.value = rowLabel;
    labelCell.font = isNet ? FONTS.labelNet : FONTS.label;
    labelCell.fill = FILLS.labelColumn;
    labelCell.alignment = ALIGNMENTS.wrapText;
    labelCell.border = BORDERS.thin as Partial<Borders>;

    // Value + Sig for each cut
    for (let i = 0; i < cutOrder.length; i++) {
      const cutName = cutOrder[i].name;
      const cutData = table.data[cutName];
      const rowData = cutData?.[rowKey] as MeanRowData | undefined;

      const valCol = valueColOffset(i);
      const sigCol = sigColOffset(i);

      // Value column (mean)
      const valCell = worksheet.getCell(currentRow, valCol);
      setCellNumber(valCell, rowData?.mean, 2);
      valCell.font = FONTS.data;
      valCell.fill = FILLS.data;
      valCell.alignment = ALIGNMENTS.center;
      valCell.border = BORDERS.thin as Partial<Borders>;

      // Sig column (red letters)
      const sigCell = worksheet.getCell(currentRow, sigCol);
      const sigValue = formatSignificance(rowData?.sig_higher_than);
      sigCell.value = sigValue || '';
      sigCell.font = sigValue ? FONTS.significanceLetterRed : FONTS.data;
      sigCell.fill = FILLS.data;
      sigCell.alignment = ALIGNMENTS.center;
      applyBorderForColumn(sigCell, sigCol, groupBoundaries, i === cutOrder.length - 1);
    }

    currentRow++;
  }

  const contextMergeEnd = currentRow - 1;

  // -------------------------------------------------------------------------
  // Merge context column and add question text
  // -------------------------------------------------------------------------
  if (contextMergeEnd >= contextMergeStart) {
    worksheet.mergeCells(contextMergeStart, CONTEXT_COL, contextMergeEnd, CONTEXT_COL);

    // Build context text
    let contextText = table.questionText;
    if (table.questionId) {
      const startsWithId = table.questionText.toUpperCase().startsWith(table.questionId.toUpperCase());
      if (!startsWithId) {
        contextText = `${table.questionId}: ${table.questionText}`;
      }
    }
    if (table.isDerived && table.sourceTableId) {
      contextText += ` [Derived from ${table.sourceTableId}]`;
    }

    const mergedContextCell = worksheet.getCell(contextMergeStart, CONTEXT_COL);
    mergedContextCell.value = contextText;
    mergedContextCell.font = FONTS.context;
    mergedContextCell.fill = FILLS.labelColumn;
    mergedContextCell.alignment = {
      ...ALIGNMENTS.wrapText,
      vertical: 'top',
    };
    mergedContextCell.border = BORDERS.thin as Partial<Borders>;
  }

  return {
    endRow: currentRow,
    contextMergeStart,
    contextMergeEnd,
  };
}
