/**
 * Table of Contents Sheet Renderer
 *
 * Creates a ToC sheet listing all tables in the workbook.
 * Columns: #, Question ID, Question Text, Section
 */

import type { Workbook, Worksheet } from 'exceljs';
import { FILLS, FONTS, ALIGNMENTS } from '../styles';
import type { TableData } from '../ExcelFormatter';

// =============================================================================
// Constants
// =============================================================================

const TOC_COLUMNS = {
  number: 1,
  questionId: 2,
  questionText: 3,
  section: 4,
};

const COL_WIDTHS = {
  number: 6,
  questionId: 15,
  questionText: 60,
  section: 20,
};

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Truncate text to a maximum length with ellipsis
 */
function truncate(text: string, maxLength: number): string {
  if (!text || text.length <= maxLength) return text || '';
  return text.substring(0, maxLength - 3) + '...';
}

// =============================================================================
// Main Renderer
// =============================================================================

export interface ToCRenderResult {
  worksheet: Worksheet;
  tableCount: number;
}

/**
 * Render Table of Contents sheet
 *
 * Lists all included tables with:
 * - Row number
 * - Question ID
 * - Question text (truncated)
 * - Survey section
 */
export function renderTableOfContents(
  workbook: Workbook,
  tables: TableData[]
): ToCRenderResult {
  const worksheet = workbook.addWorksheet('Table of Contents', {
    properties: { tabColor: { argb: 'FF92D050' } }  // Green tab color
  });

  // Set column widths
  worksheet.getColumn(TOC_COLUMNS.number).width = COL_WIDTHS.number;
  worksheet.getColumn(TOC_COLUMNS.questionId).width = COL_WIDTHS.questionId;
  worksheet.getColumn(TOC_COLUMNS.questionText).width = COL_WIDTHS.questionText;
  worksheet.getColumn(TOC_COLUMNS.section).width = COL_WIDTHS.section;

  // Header row
  const headerRow = worksheet.getRow(1);
  headerRow.values = ['#', 'Question ID', 'Question Text', 'Section'];

  // Style header cells
  for (let col = 1; col <= 4; col++) {
    const cell = headerRow.getCell(col);
    cell.font = FONTS.header;
    cell.fill = FILLS.joeHeader;
    cell.alignment = ALIGNMENTS.center;
    cell.border = {
      bottom: { style: 'medium', color: { argb: 'FF000000' } },
    };
  }

  // Filter to included tables only (not excluded)
  const includedTables = tables.filter(t => !t.excluded);

  // Group tables by section for sorting (optional - keeps tables in section order)
  // For now, maintain original order from R script

  let rowNum = 2;
  for (let i = 0; i < includedTables.length; i++) {
    const table = includedTables[i];
    const row = worksheet.getRow(rowNum);

    // Row number
    const numCell = row.getCell(TOC_COLUMNS.number);
    numCell.value = i + 1;
    numCell.alignment = ALIGNMENTS.center;

    // Question ID
    const idCell = row.getCell(TOC_COLUMNS.questionId);
    idCell.value = table.questionId || table.tableId;
    idCell.alignment = ALIGNMENTS.left;

    // Question text (truncated)
    const textCell = row.getCell(TOC_COLUMNS.questionText);
    textCell.value = truncate(table.questionText, 100);
    textCell.alignment = { ...ALIGNMENTS.left, wrapText: true };

    // Section
    const sectionCell = row.getCell(TOC_COLUMNS.section);
    sectionCell.value = table.surveySection || '';
    sectionCell.alignment = ALIGNMENTS.left;

    // Alternating row colors for readability
    if (i % 2 === 1) {
      for (let col = 1; col <= 4; col++) {
        row.getCell(col).fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: 'FFF5F5F5' },  // Very light gray
        };
      }
    }

    rowNum++;
  }

  // Freeze header row
  worksheet.views = [{
    state: 'frozen',
    ySplit: 1,
    topLeftCell: 'A2',
    activeCell: 'A2',
  }];

  return {
    worksheet,
    tableCount: includedTables.length,
  };
}
