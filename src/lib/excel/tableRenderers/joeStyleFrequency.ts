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
import { FILLS, FONTS, ALIGNMENTS, COLUMN_WIDTHS_JOE, getGroupFill } from '../styles';
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
  // Phase 2: Additional table metadata
  surveySection?: string;
  baseText?: string;
  userNote?: string;
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
const DATA_START_COL = 3;

/**
 * Extended cut info that includes absolute column positions
 * This allows for spacer columns between banner groups
 */
export interface CutColumnInfo {
  name: string;
  statLetter: string;
  groupName: string;
  groupIndex: number;
  valueCol: number;  // Absolute column index for value
  sigCol: number;    // Absolute column index for sig
  isFirstInGroup: boolean;
  isLastInGroup: boolean;
}

/**
 * Build column layout with spacer columns between groups
 * Returns array of cut info with absolute column positions
 */
function buildColumnLayout(bannerGroups: BannerGroup[]): {
  cuts: CutColumnInfo[];
  groupSpacerCols: number[];  // Column indices of spacer columns
  totalCols: number;
} {
  const cuts: CutColumnInfo[] = [];
  const groupSpacerCols: number[] = [];
  let currentCol = DATA_START_COL;

  for (let groupIdx = 0; groupIdx < bannerGroups.length; groupIdx++) {
    const group = bannerGroups[groupIdx];
    const isLastGroup = groupIdx === bannerGroups.length - 1;

    for (let cutIdx = 0; cutIdx < group.columns.length; cutIdx++) {
      const col = group.columns[cutIdx];
      cuts.push({
        name: col.name,
        statLetter: col.statLetter,
        groupName: group.groupName,
        groupIndex: groupIdx,
        valueCol: currentCol,
        sigCol: currentCol + 1,
        isFirstInGroup: cutIdx === 0,
        isLastInGroup: cutIdx === group.columns.length - 1,
      });
      currentCol += 2; // value + sig
    }

    // Add spacer column after each group (except the last)
    if (!isLastGroup) {
      groupSpacerCols.push(currentCol);
      currentCol += 1;
    }
  }

  return {
    cuts,
    groupSpacerCols,
    totalCols: currentCol - 1, // Last used column
  };
}

// =============================================================================
// Helper Functions
// =============================================================================

function formatSignificance(sig: string[] | string | undefined): string {
  if (!sig) return '';
  if (typeof sig === 'string') return sig || '';
  if (Array.isArray(sig) && sig.length > 0) {
    // No commas - just concatenate letters (e.g., "AB" not "A,B")
    return sig.join('');
  }
  return '';
}

/**
 * Apply Joe-style border based on position
 * Joe format uses minimal borders - thick only at structural boundaries
 * Double-line border goes UNDER group names, NOT between columns
 */
function applyJoeBorder(
  cell: Cell,
  options: {
    isFirstCol?: boolean;      // Left edge of table (thick left)
    isLastCol?: boolean;       // Right edge of table (thick right)
    isFirstRow?: boolean;      // Top edge of section (thick top)
    isLastRow?: boolean;       // Bottom edge of section (thick bottom)
    isContextCol?: boolean;    // Context column (thick left AND right)
    isAfterLabel?: boolean;    // Right after label column (thick left)
    isBaseRow?: boolean;       // Base row (thick bottom for separation)
    isGroupNameRow?: boolean;  // Group name row (double-line bottom)
  }
): void {
  const { isFirstCol, isLastCol, isFirstRow, isLastRow, isContextCol, isAfterLabel, isBaseRow, isGroupNameRow } = options;

  // Build border based on position
  const border: Partial<Borders> = {};

  if (isFirstCol || isContextCol) {
    border.left = { style: 'medium', color: { argb: 'FF000000' } };
  }
  if (isLastCol) {
    border.right = { style: 'medium', color: { argb: 'FF000000' } };
  }
  if (isContextCol) {
    // Context column gets thick border on both sides
    border.right = { style: 'medium', color: { argb: 'FF000000' } };
  }
  if (isFirstRow) {
    border.top = { style: 'medium', color: { argb: 'FF000000' } };
  }
  if (isLastRow) {
    border.bottom = { style: 'medium', color: { argb: 'FF000000' } };
  }
  if (isBaseRow) {
    // Base row gets thick bottom border to separate from data
    border.bottom = { style: 'medium', color: { argb: 'FF000000' } };
  }
  if (isAfterLabel) {
    border.left = { style: 'medium', color: { argb: 'FF000000' } };
  }
  if (isGroupNameRow) {
    // Group name row gets double-line bottom border
    border.bottom = { style: 'double', color: { argb: 'FF000000' } };
  }

  cell.border = border;
}

// =============================================================================
// Header Rendering
// =============================================================================

export interface JoeHeaderInfo {
  headerRowCount: number;
  totalCols: number;
  cuts: CutColumnInfo[];
  groupSpacerCols: number[];
  bannerGroups: BannerGroup[];
}

/**
 * Render Joe-style headers (only once per worksheet)
 * Returns info needed for data rendering
 *
 * Joe format:
 * - Blue headers with wrap text
 * - Spacer column between each banner group
 * - No "Sig" text, red stat letters
 * - Minimal borders
 */
export function renderJoeHeaders(
  worksheet: Worksheet,
  bannerGroups: BannerGroup[],
  startRow: number
): JoeHeaderInfo {
  let currentRow = startRow;

  // Build column layout with spacers
  const { cuts, groupSpacerCols, totalCols } = buildColumnLayout(bannerGroups);

  // -------------------------------------------------------------------------
  // Row 1: Group headers (merged over value+sig column pairs for each group)
  // -------------------------------------------------------------------------
  // Context column - blank, blue, thick top+left border
  const contextHeader = worksheet.getCell(currentRow, CONTEXT_COL);
  contextHeader.value = '';
  contextHeader.fill = FILLS.joeHeader;
  applyJoeBorder(contextHeader, { isFirstRow: true, isContextCol: true });

  // Label column - blank, blue, thick top border
  const labelHeader = worksheet.getCell(currentRow, LABEL_COL);
  labelHeader.value = '';
  labelHeader.fill = FILLS.joeHeader;
  applyJoeBorder(labelHeader, { isFirstRow: true });

  // Group headers - each group spans its cuts' columns (KEEP merge for group names only)
  // Double-line border UNDER the group name row
  for (let groupIdx = 0; groupIdx < bannerGroups.length; groupIdx++) {
    const group = bannerGroups[groupIdx];
    const groupCuts = cuts.filter(c => c.groupIndex === groupIdx);
    const isLastGroup = groupIdx === bannerGroups.length - 1;

    if (groupCuts.length > 0) {
      const startCol = groupCuts[0].valueCol;
      const endCol = groupCuts[groupCuts.length - 1].sigCol;

      // Merge group name across all its columns (this is the ONLY merge we keep)
      if (endCol > startCol) {
        worksheet.mergeCells(currentRow, startCol, currentRow, endCol);
      }

      const groupCell = worksheet.getCell(currentRow, startCol);
      groupCell.value = group.groupName;
      groupCell.font = FONTS.header;
      groupCell.fill = FILLS.joeHeader;
      groupCell.alignment = { ...ALIGNMENTS.center, wrapText: true };
      // Thick top, double-line bottom (under group name)
      applyJoeBorder(groupCell, {
        isFirstRow: true,
        isGroupNameRow: true,  // Double-line bottom border under group name
        isAfterLabel: groupIdx === 0,
        isLastCol: isLastGroup,
      });
    }

    // Spacer column after group (if not last) - header blue, NO border (gap creates separation)
    if (!isLastGroup && groupSpacerCols[groupIdx]) {
      const spacerCell = worksheet.getCell(currentRow, groupSpacerCols[groupIdx]);
      spacerCell.value = '';
      spacerCell.fill = FILLS.joeHeader;
      // No border on spacer - the gap is the visual separation
    }
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 2: Column headers (cut names) - NO merge, value col gets name, sig col empty
  // -------------------------------------------------------------------------
  const contextHeader2 = worksheet.getCell(currentRow, CONTEXT_COL);
  contextHeader2.value = '';
  contextHeader2.fill = FILLS.joeHeader;
  applyJoeBorder(contextHeader2, { isContextCol: true });

  const labelHeader2 = worksheet.getCell(currentRow, LABEL_COL);
  labelHeader2.value = '';
  labelHeader2.fill = FILLS.joeHeader;

  for (const cut of cuts) {
    // Value column gets the cut name (NO merge)
    const valCell = worksheet.getCell(currentRow, cut.valueCol);
    valCell.value = cut.name;
    valCell.font = FONTS.header;
    valCell.fill = FILLS.joeHeader;
    valCell.alignment = { ...ALIGNMENTS.center, wrapText: true };
    applyJoeBorder(valCell, {
      isAfterLabel: cut.isFirstInGroup && cut.groupIndex === 0,
    });

    // Sig column is empty but styled
    const sigCell = worksheet.getCell(currentRow, cut.sigCol);
    sigCell.value = '';
    sigCell.fill = FILLS.joeHeader;
    applyJoeBorder(sigCell, {
      isLastCol: cut.isLastInGroup && cut.groupIndex === bannerGroups.length - 1,
    });
  }

  // Spacer columns - header blue, NO border (gap is the separation)
  for (const spacerCol of groupSpacerCols) {
    const spacerCell = worksheet.getCell(currentRow, spacerCol);
    spacerCell.value = '';
    spacerCell.fill = FILLS.joeHeader;
    // No border on spacer
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Row 3: Stat letters (red) - NO merge, value col gets letter, sig col empty
  // -------------------------------------------------------------------------
  const contextHeader3 = worksheet.getCell(currentRow, CONTEXT_COL);
  contextHeader3.value = '';
  contextHeader3.fill = FILLS.joeHeader;
  applyJoeBorder(contextHeader3, { isContextCol: true, isLastRow: true });

  const labelHeader3 = worksheet.getCell(currentRow, LABEL_COL);
  labelHeader3.value = '';
  labelHeader3.fill = FILLS.joeHeader;
  applyJoeBorder(labelHeader3, { isLastRow: true });

  for (const cut of cuts) {
    // Value column gets the stat letter (NO merge)
    const valCell = worksheet.getCell(currentRow, cut.valueCol);
    valCell.value = `(${cut.statLetter})`;
    valCell.font = FONTS.joeStatLetterRed;
    valCell.fill = FILLS.joeHeader;
    valCell.alignment = ALIGNMENTS.center;
    applyJoeBorder(valCell, {
      isAfterLabel: cut.isFirstInGroup && cut.groupIndex === 0,
      isLastRow: true,
    });

    // Sig column is empty but styled
    const sigCell = worksheet.getCell(currentRow, cut.sigCol);
    sigCell.value = '';
    sigCell.fill = FILLS.joeHeader;
    applyJoeBorder(sigCell, {
      isLastCol: cut.isLastInGroup && cut.groupIndex === bannerGroups.length - 1,
      isLastRow: true,
    });
  }

  // Spacer columns - header blue, NO border (gap is the separation)
  for (const spacerCol of groupSpacerCols) {
    const spacerCell = worksheet.getCell(currentRow, spacerCol);
    spacerCell.value = '';
    spacerCell.fill = FILLS.joeHeader;
    // No border on spacer
  }
  currentRow++;

  return {
    headerRowCount: currentRow - startRow,
    totalCols,
    cuts,
    groupSpacerCols,
    bannerGroups,
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
 *
 * Joe format:
 * - Purple context column (merged per table)
 * - Purple + bold+italic base row
 * - Yellow label column
 * - Color-coded data cells per banner group (blue, green, yellow, etc.)
 * - Spacer columns between banner groups
 * - Minimal borders (thick at structural boundaries only)
 * - Bold red significance letters (no commas)
 */
export function renderJoeStyleFrequencyTable(
  worksheet: Worksheet,
  table: FrequencyTableData,
  startRow: number,
  headerInfo: JoeHeaderInfo,
  valueType: ValueType = 'percent',
  _isFirstTable: boolean = false,
  totalRespondents: number = 0
): JoeFrequencyRenderResult {
  const { cuts, groupSpacerCols, bannerGroups } = headerInfo;
  let currentRow = startRow;
  const contextMergeStart = currentRow;

  // Get row keys from Total cut
  const totalCutData = table.data['Total'];
  const rowKeys = Object.keys(totalCutData || {}).filter(k => k !== 'stat_letter');
  const totalDataRows = rowKeys.length;
  const numGroups = bannerGroups.length;

  // -------------------------------------------------------------------------
  // Base (n) row - Purple background, bold+italic text, thick bottom border
  // NO merge - value col gets n, sig col empty
  // -------------------------------------------------------------------------
  const firstRowKey = rowKeys[0];

  // Context column - purple, thick left + top + bottom border
  const baseContextCell = worksheet.getCell(currentRow, CONTEXT_COL);
  baseContextCell.value = '';
  baseContextCell.fill = FILLS.joeContext;
  applyJoeBorder(baseContextCell, { isContextCol: true, isFirstRow: true, isBaseRow: true });

  // Label column - purple, bold+italic "Base: ...", thick bottom border
  const baseLabelCell = worksheet.getCell(currentRow, LABEL_COL);
  // Get base n from first row of Total cut
  const firstRowData = totalCutData?.[firstRowKey] as FrequencyRowData | undefined;
  const baseN = firstRowData?.n || 0;
  // Base text logic: use provided baseText, or fall back to count-based default
  let baseTextValue: string;
  if (table.baseText) {
    baseTextValue = `Base: ${table.baseText}`;
  } else if (totalRespondents > 0 && baseN === totalRespondents) {
    baseTextValue = 'Base: All respondents';
  } else {
    baseTextValue = 'Base: Shown this question';
  }
  baseLabelCell.value = baseTextValue;
  baseLabelCell.font = FONTS.joeBaseBold;
  baseLabelCell.fill = FILLS.joeBase;
  baseLabelCell.alignment = ALIGNMENTS.left;
  applyJoeBorder(baseLabelCell, { isFirstRow: true, isBaseRow: true });

  // Base n for each cut - purple background, bold+italic, NO merge
  for (const cut of cuts) {
    const cutData = table.data[cut.name];
    const rowData = cutData?.[firstRowKey] as FrequencyRowData | undefined;
    const n = rowData?.n || 0;

    // Value column gets the n value (NO merge)
    const valCell = worksheet.getCell(currentRow, cut.valueCol);
    valCell.value = n;
    valCell.font = FONTS.joeBaseBold;
    valCell.fill = FILLS.joeBase;
    valCell.alignment = ALIGNMENTS.center;
    applyJoeBorder(valCell, {
      isAfterLabel: cut.isFirstInGroup && cut.groupIndex === 0,
      isFirstRow: true,
      isBaseRow: true,
    });

    // Sig column is empty but styled
    const sigCell = worksheet.getCell(currentRow, cut.sigCol);
    sigCell.value = '';
    sigCell.fill = FILLS.joeBase;
    applyJoeBorder(sigCell, {
      isLastCol: cut.isLastInGroup && cut.groupIndex === numGroups - 1,
      isFirstRow: true,
      isBaseRow: true,
    });
  }

  // Spacer columns in base row - purple, WITH borders (continuous border across base row)
  for (const spacerCol of groupSpacerCols) {
    const spacerCell = worksheet.getCell(currentRow, spacerCol);
    spacerCell.value = '';
    spacerCell.fill = FILLS.joeBase;
    // Base row spacers get top and bottom borders for continuity
    spacerCell.border = {
      top: { style: 'medium', color: { argb: 'FF000000' } },
      bottom: { style: 'medium', color: { argb: 'FF000000' } },
    };
  }
  currentRow++;

  // -------------------------------------------------------------------------
  // Data rows: 1 row per answer option, alternating colors within table
  // -------------------------------------------------------------------------
  for (let rowIdx = 0; rowIdx < rowKeys.length; rowIdx++) {
    const rowKey = rowKeys[rowIdx];
    const totalRowData = totalCutData?.[rowKey] as FrequencyRowData | undefined;
    const isNet = totalRowData?.isNet || false;
    const indent = totalRowData?.indent || 0;
    const isLastDataRow = rowIdx === totalDataRows - 1;

    // Build label with indentation
    let rowLabel = totalRowData?.label || rowKey;
    if (indent > 0) {
      rowLabel = '  '.repeat(indent) + rowLabel;
    }

    // Context column - purple (will be merged later)
    const contextCell = worksheet.getCell(currentRow, CONTEXT_COL);
    contextCell.value = '';
    contextCell.fill = FILLS.joeContext;
    applyJoeBorder(contextCell, { isContextCol: true, isLastRow: isLastDataRow });

    // Label column - yellow
    const labelCell = worksheet.getCell(currentRow, LABEL_COL);
    labelCell.value = rowLabel;
    labelCell.font = isNet ? FONTS.labelNet : FONTS.label;
    labelCell.fill = FILLS.joeLabel;
    labelCell.alignment = ALIGNMENTS.wrapText;
    applyJoeBorder(labelCell, { isLastRow: isLastDataRow });

    // Value + Sig for each cut - color per banner group, alternating by row
    for (const cut of cuts) {
      const cutData = table.data[cut.name];
      const rowData = cutData?.[rowKey] as FrequencyRowData | undefined;
      // Pass rowIdx for alternating colors within the table
      const groupFill = getGroupFill(cut.groupIndex, rowIdx);

      // Value column (percent or count)
      const valCell = worksheet.getCell(currentRow, cut.valueCol);
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
      valCell.fill = groupFill;
      valCell.alignment = ALIGNMENTS.center;
      applyJoeBorder(valCell, {
        isAfterLabel: cut.isFirstInGroup && cut.groupIndex === 0,
        isLastRow: isLastDataRow,
      });

      // Sig column (bold red letters)
      const sigCell = worksheet.getCell(currentRow, cut.sigCol);
      const sigValue = formatSignificance(rowData?.sig_higher_than);
      sigCell.value = sigValue || '';
      sigCell.font = sigValue ? FONTS.significanceLetterRed : FONTS.data;
      sigCell.fill = groupFill;
      sigCell.alignment = ALIGNMENTS.center;
      applyJoeBorder(sigCell, {
        isLastCol: cut.isLastInGroup && cut.groupIndex === numGroups - 1,
        isLastRow: isLastDataRow,
      });
    }

    // Spacer columns in data rows - inherit color from left group (with row alternation), NO border
    for (let i = 0; i < groupSpacerCols.length; i++) {
      const spacerCol = groupSpacerCols[i];
      const spacerCell = worksheet.getCell(currentRow, spacerCol);
      spacerCell.value = '';
      // Inherit color from the group to the left (group index i), with row alternation
      spacerCell.fill = getGroupFill(i, rowIdx);
      // No border on spacer - the gap is the visual separation
    }

    currentRow++;
  }

  const contextMergeEnd = currentRow - 1;

  // -------------------------------------------------------------------------
  // Merge context column and add question text
  // -------------------------------------------------------------------------
  if (contextMergeEnd >= contextMergeStart) {
    worksheet.mergeCells(contextMergeStart, CONTEXT_COL, contextMergeEnd, CONTEXT_COL);

    // Build context text with new multi-line structure:
    // Line 1: Survey section (ALL CAPS, if present)
    // Line 2: "Derived table" marker (if isDerived)
    // Line 3: Question ID + text
    // Line 4: User note (if present)
    const contextLines: string[] = [];

    // 1. Survey section
    if (table.surveySection) {
      contextLines.push(table.surveySection);  // Already ALL CAPS from agent
    }

    // 2. Derived table marker (simplified)
    if (table.isDerived) {
      contextLines.push('Derived table');
    }

    // 3. Question text with ID prefix if needed
    let questionLine = table.questionText;
    if (table.questionId) {
      const startsWithId = table.questionText.toUpperCase().startsWith(table.questionId.toUpperCase());
      if (!startsWithId) {
        questionLine = `${table.questionId}: ${table.questionText}`;
      }
    }
    contextLines.push(questionLine);

    // 4. User note (if present - already in parenthetical format from agent)
    if (table.userNote) {
      contextLines.push(table.userNote);
    }

    const contextText = contextLines.join('\n');

    const mergedContextCell = worksheet.getCell(contextMergeStart, CONTEXT_COL);
    mergedContextCell.value = contextText;
    mergedContextCell.font = FONTS.context;
    mergedContextCell.fill = FILLS.joeContext;
    mergedContextCell.alignment = {
      ...ALIGNMENTS.wrapText,
      vertical: 'top',
    };
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

const SPACER_COL_WIDTH = 2; // Narrow spacer between groups

/**
 * Set column widths for Joe format
 * Uses headerInfo to get actual column positions (with spacers)
 */
export function setJoeColumnWidths(
  worksheet: Worksheet,
  headerInfo: JoeHeaderInfo
): void {
  worksheet.getColumn(CONTEXT_COL).width = COLUMN_WIDTHS_JOE.context;
  worksheet.getColumn(LABEL_COL).width = COLUMN_WIDTHS_JOE.label;

  // Set widths for value and sig columns
  for (const cut of headerInfo.cuts) {
    worksheet.getColumn(cut.valueCol).width = COLUMN_WIDTHS_JOE.value;
    worksheet.getColumn(cut.sigCol).width = COLUMN_WIDTHS_JOE.significance;
  }

  // Set narrow width for spacer columns
  for (const spacerCol of headerInfo.groupSpacerCols) {
    worksheet.getColumn(spacerCol).width = SPACER_COL_WIDTH;
  }
}
