/**
 * Excluded Tables Sheet Renderer
 *
 * Renders tables marked as excluded: true on a separate sheet.
 * Each excluded table shows its reason and full data.
 */

import type { Workbook, Worksheet } from 'exceljs';
import { FONTS, ALIGNMENTS } from '../styles';
import type { TableData } from '../ExcelFormatter';
import type { JoeHeaderInfo, FrequencyTableData } from './joeStyleFrequency';
import type { MeanRowsTableData } from './joeStyleMeanRows';
import { renderJoeStyleFrequencyTable } from './joeStyleFrequency';
import { renderJoeStyleMeanRowsTable } from './joeStyleMeanRows';

// =============================================================================
// Types
// =============================================================================

export interface ExcludedSheetRenderResult {
  worksheet: Worksheet | null;
  excludedCount: number;
}

// =============================================================================
// Constants
// =============================================================================

const REASON_ROW_HEIGHT = 25;
const GAP_BETWEEN_TABLES = 2;

// =============================================================================
// Main Renderer
// =============================================================================

/**
 * Render Excluded Tables sheet
 *
 * For each excluded table:
 * 1. Render a reason header row
 * 2. Render the full table data (reusing existing renderers)
 *
 * Returns null worksheet if no excluded tables exist.
 */
export function renderExcludedSheet(
  workbook: Workbook,
  excludedTables: TableData[],
  headerInfo: JoeHeaderInfo,
  totalRespondents: number
): ExcludedSheetRenderResult {
  if (excludedTables.length === 0) {
    return {
      worksheet: null,
      excludedCount: 0,
    };
  }

  const worksheet = workbook.addWorksheet('Excluded Tables', {
    properties: { tabColor: { argb: 'FFFF6B6B' } }  // Red tab color
  });

  // Copy column widths from main sheet structure
  const { cuts, groupSpacerCols } = headerInfo;

  // Context column
  worksheet.getColumn(1).width = 25;
  // Label column
  worksheet.getColumn(2).width = 35;

  // Value and sig columns
  for (const cut of cuts) {
    worksheet.getColumn(cut.valueCol).width = 15;
    worksheet.getColumn(cut.sigCol).width = 5;
  }

  // Spacer columns
  for (const spacerCol of groupSpacerCols) {
    worksheet.getColumn(spacerCol).width = 2;
  }

  let currentRow = 1;

  // Add sheet header
  const sheetHeader = worksheet.getCell(currentRow, 1);
  sheetHeader.value = 'EXCLUDED TABLES';
  sheetHeader.font = { ...FONTS.title, size: 14 };
  sheetHeader.alignment = ALIGNMENTS.left;
  currentRow += 2;

  // Render each excluded table
  for (const table of excludedTables) {
    // Reason header row
    const reasonCell = worksheet.getCell(currentRow, 1);
    reasonCell.value = `${table.tableId}: ${table.questionText}`;
    reasonCell.font = FONTS.header;
    reasonCell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFFCE4D6' },  // Light peach
    };
    reasonCell.alignment = { ...ALIGNMENTS.left, wrapText: true };

    // Exclude reason in next cell
    const excludeReasonCell = worksheet.getCell(currentRow, 2);
    excludeReasonCell.value = `Reason: ${table.excludeReason || 'Not specified'}`;
    excludeReasonCell.font = { ...FONTS.data, italic: true };
    excludeReasonCell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFFCE4D6' },  // Light peach
    };
    excludeReasonCell.alignment = ALIGNMENTS.left;

    worksheet.getRow(currentRow).height = REASON_ROW_HEIGHT;
    currentRow++;

    // Render the table data (reusing existing renderers)
    if (table.tableType === 'frequency') {
      const result = renderJoeStyleFrequencyTable(
        worksheet,
        table as unknown as FrequencyTableData,
        currentRow,
        headerInfo,
        'percent',
        false,
        totalRespondents
      );
      currentRow = result.endRow;
    } else if (table.tableType === 'mean_rows') {
      const result = renderJoeStyleMeanRowsTable(
        worksheet,
        table as unknown as MeanRowsTableData,
        currentRow,
        headerInfo,
        totalRespondents
      );
      currentRow = result.endRow;
    }

    // Add gap between tables
    currentRow += GAP_BETWEEN_TABLES;
  }

  return {
    worksheet,
    excludedCount: excludedTables.length,
  };
}
