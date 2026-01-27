/**
 * Joe-Style Frequency Table Renderer
 *
 * Renders frequency tables with Joe's horizontal format:
 * - Single row per answer option
 * - Context column (merged per table) with questionId: questionText
 * - Label column for answer options
 * - Value + Sig column pairs for each cut
 * - Supports both percent and count display modes
 */

import type { Worksheet, Cell, Borders } from 'exceljs';
import { FILLS, BORDERS, FONTS, ALIGNMENTS, COLUMN_WIDTHS_JOE } from '../styles';
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
  isNet?: boolean;
  indent?: number;
}

export interface FrequencyCutData {
  stat_letter: string;
  [rowKey: string]: FrequencyRowData | string;
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

export type ValueType = 'percent' | 'count';

// =============================================================================
// Column Layout Helpers
// =============================================================================

const CONTEXT_COL = 1;
const LABEL_COL = 2;

/**
 * Get value column index for a cut (0-indexed cutIndex)
 * Pattern: C, E, G, ... (odd columns starting at 3)
 */
function valueColOffset(cutIndex: number): number {
  return 3 + (cutIndex * 2);
}

/**
 * Get significance column index for a cut (0-indexed cutIndex)
 * Pattern: D, F, H, ... (even columns starting at 4)
 */
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
  // Check if this column is at a group boundary
  if (groupBoundaries.includes(colIndex) || isLastCol) {
    cell.border = BORDERS.groupSeparatorRight as Partial<Borders>;
  } else {
    cell.border = BORDERS.thin as Partial<Borders>;
  }
}

// =============================================================================
// Header Rendering
// =============================================================================

export interface JoeHeaderInfo {
  headerRowCount: number;
  totalCols: number;
  cutOrder: { name: string; statLetter: string; groupName: string }[];
  groupBoundaries: number[];
}

/**
 * Render Joe-style headers (only once per worksheet)
 * Returns info needed for data rendering
 */
export function renderJoeHeaders(
  worksheet: Worksheet,
  bannerGroups: BannerGroup[],
  startRow: number
): JoeHeaderInfo {
  let currentRow = startRow;

  // Build flat list of cuts
  const cutOrder: { name: string; statLetter: string; groupName: string }[] = [];
  const groupBoundaries: number[] = []; // Sig column indices where groups end

  for (const group of bannerGroups) {
    for (const col of group.columns) {
      cutOrder.push({ name: col.name, statLetter: col.statLetter, groupName: group.groupName });
    }
    // Mark the sig column of the last cut in this group as a boundary
    if (cutOrder.length > 0) {
      groupBoundaries.push(sigColOffset(cutOrder.length - 1));
    }
  }

  const totalCols = sigColOffset(cutOrder.length - 1); // Last sig column

  // -------------------------------------------------------------------------
  // Row 1: Group headers (merged over value+sig column pairs)
  // -------------------------------------------------------------------------
  // Context and Label columns are blank
  const contextHeader = worksheet.getCell(currentRow, CONTEXT_COL);
  contextHeader.value = '';
  contextHeader.fill = FILLS.groupHeader;
  contextHeader.border = BORDERS.thin as Partial<Borders>;

  const labelHeader = worksheet.getCell(currentRow, LABEL_COL);
  labelHeader.value = '';
  labelHeader.fill = FILLS.groupHeader;
  labelHeader.border = BORDERS.thin as Partial<Borders>;

  // Group headers span their cuts' value+sig pairs
  let cutIdx = 0;
  for (const group of bannerGroups) {
    const startCol = valueColOffset(cutIdx);
    const endCol = sigColOffset(cutIdx + group.columns.length - 1);

    if (endCol > startCol) {
      worksheet.mergeCells(currentRow, startCol, currentRow, endCol);
    }

    const groupCell = worksheet.getCell(currentRow, startCol);
    groupCell.value = group.groupName;
    groupCell.font = FONTS.header;
    groupCell.fill = FILLS.groupHeader;
    groupCell.alignment = ALIGNMENTS.center;
    groupCell.border = BORDERS.groupSeparatorRight as Partial<Borders>;

    cutIdx += group.columns.length;
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 2: Column headers (cut names) + Sig headers
  // -------------------------------------------------------------------------
  worksheet.getCell(currentRow, CONTEXT_COL).value = '';
  worksheet.getCell(currentRow, CONTEXT_COL).fill = FILLS.groupHeader;
  worksheet.getCell(currentRow, CONTEXT_COL).border = BORDERS.thin as Partial<Borders>;

  worksheet.getCell(currentRow, LABEL_COL).value = '';
  worksheet.getCell(currentRow, LABEL_COL).fill = FILLS.groupHeader;
  worksheet.getCell(currentRow, LABEL_COL).border = BORDERS.thin as Partial<Borders>;

  for (let i = 0; i < cutOrder.length; i++) {
    const valCol = valueColOffset(i);
    const sigCol = sigColOffset(i);

    // Value column header (cut name)
    const valCell = worksheet.getCell(currentRow, valCol);
    valCell.value = cutOrder[i].name;
    valCell.font = FONTS.header;
    valCell.fill = FILLS.groupHeader;
    valCell.alignment = ALIGNMENTS.center;
    valCell.border = BORDERS.thin as Partial<Borders>;

    // Sig column header
    const sigCell = worksheet.getCell(currentRow, sigCol);
    sigCell.value = 'Sig';
    sigCell.font = FONTS.header;
    sigCell.fill = FILLS.groupHeader;
    sigCell.alignment = ALIGNMENTS.center;
    applyBorderForColumn(sigCell, sigCol, groupBoundaries, i === cutOrder.length - 1);
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 3: Stat letters
  // -------------------------------------------------------------------------
  worksheet.getCell(currentRow, CONTEXT_COL).value = '';
  worksheet.getCell(currentRow, CONTEXT_COL).fill = FILLS.groupHeader;
  worksheet.getCell(currentRow, CONTEXT_COL).border = BORDERS.thin as Partial<Borders>;

  worksheet.getCell(currentRow, LABEL_COL).value = '';
  worksheet.getCell(currentRow, LABEL_COL).fill = FILLS.groupHeader;
  worksheet.getCell(currentRow, LABEL_COL).border = BORDERS.thin as Partial<Borders>;

  for (let i = 0; i < cutOrder.length; i++) {
    const valCol = valueColOffset(i);
    const sigCol = sigColOffset(i);

    // Stat letter under value column
    const valCell = worksheet.getCell(currentRow, valCol);
    valCell.value = `(${cutOrder[i].statLetter})`;
    valCell.font = FONTS.statLetter;
    valCell.fill = FILLS.groupHeader;
    valCell.alignment = ALIGNMENTS.center;
    valCell.border = BORDERS.thin as Partial<Borders>;

    // Empty sig column in stat letter row
    const sigCell = worksheet.getCell(currentRow, sigCol);
    sigCell.value = '';
    sigCell.fill = FILLS.groupHeader;
    applyBorderForColumn(sigCell, sigCol, groupBoundaries, i === cutOrder.length - 1);
  }
  currentRow++;

  return {
    headerRowCount: currentRow - startRow,
    totalCols,
    cutOrder,
    groupBoundaries,
  };
}

// =============================================================================
// Main Renderer
// =============================================================================

export interface JoeFrequencyRenderResult {
  endRow: number;
  contextMergeStart: number;
  contextMergeEnd: number;
}

/**
 * Render a single frequency table in Joe format
 * Returns the end row for chaining
 */
export function renderJoeStyleFrequencyTable(
  worksheet: Worksheet,
  table: FrequencyTableData,
  startRow: number,
  headerInfo: JoeHeaderInfo,
  valueType: ValueType = 'percent'
): JoeFrequencyRenderResult {
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
    const rowData = cutData?.[firstRowKey] as FrequencyRowData | undefined;
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
  // Data rows: 1 row per answer option
  // -------------------------------------------------------------------------
  for (const rowKey of rowKeys) {
    const totalRowData = totalCutData?.[rowKey] as FrequencyRowData | undefined;
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
      const rowData = cutData?.[rowKey] as FrequencyRowData | undefined;

      const valCol = valueColOffset(i);
      const sigCol = sigColOffset(i);

      // Value column (percent or count)
      const valCell = worksheet.getCell(currentRow, valCol);
      if (valueType === 'percent') {
        const pct = rowData?.pct;
        if (pct !== undefined && pct !== null) {
          valCell.value = pct / 100;
          valCell.numFmt = '0%';
        } else {
          valCell.value = '-';
        }
      } else {
        const count = rowData?.count;
        if (count !== undefined && count !== null) {
          valCell.value = count;
        } else {
          valCell.value = '-';
        }
      }
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

// =============================================================================
// Column Width Setup
// =============================================================================

/**
 * Set column widths for Joe format
 */
export function setJoeColumnWidths(
  worksheet: Worksheet,
  cutCount: number
): void {
  worksheet.getColumn(CONTEXT_COL).width = COLUMN_WIDTHS_JOE.context;
  worksheet.getColumn(LABEL_COL).width = COLUMN_WIDTHS_JOE.label;

  for (let i = 0; i < cutCount; i++) {
    worksheet.getColumn(valueColOffset(i)).width = COLUMN_WIDTHS_JOE.value;
    worksheet.getColumn(sigColOffset(i)).width = COLUMN_WIDTHS_JOE.significance;
  }
}
