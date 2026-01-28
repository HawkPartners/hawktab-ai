/**
 * Excel Formatter
 *
 * Main class for formatting tables.json into Excel workbook.
 *
 * Supports two formats:
 * - 'joe' (default): Horizontal layout with 1 row per answer, value+sig column pairs
 * - 'antares': Vertical layout with 3 rows per answer (count, percent, sig stacked)
 *
 * Features:
 * - Reads tables.json from R output
 * - Renders frequency and mean_rows tables
 * - Multi-row headers with group/column/stat letter
 * - Heavy borders between banner groups
 * - Freeze panes for headers and label columns (Joe format)
 * - Multi-sheet support for display modes (frequency/counts/both)
 */

import ExcelJS from 'exceljs';
import { promises as fs } from 'fs';

import { renderFrequencyTable, type FrequencyTableData } from './tableRenderers/frequencyTable';
import { renderMeanRowsTable, type MeanRowsTableData } from './tableRenderers/meanRowsTable';
import {
  renderJoeHeaders,
  renderJoeStyleFrequencyTable,
  setJoeColumnWidths,
  type JoeHeaderInfo,
  type ValueType,
} from './tableRenderers/joeStyleFrequency';
import { renderJoeStyleMeanRowsTable } from './tableRenderers/joeStyleMeanRows';
import { COLUMN_WIDTHS, TABLE_SPACING } from './styles';
import type { BannerGroup } from '../r/RScriptGeneratorV2';

// =============================================================================
// Types
// =============================================================================

export interface TablesJsonMetadata {
  generatedAt: string;
  tableCount: number;
  cutCount: number;
  significanceLevel: number;
  totalRespondents: number;
  bannerGroups: BannerGroup[];
  comparisonGroups: string[];
}

export interface TableData {
  tableId: string;
  questionId: string;
  questionText: string;
  tableType: 'frequency' | 'mean_rows';
  isDerived: boolean;
  sourceTableId: string;
  data: Record<string, unknown>;
  // Phase 2: Additional table metadata
  surveySection?: string;  // Section name from survey (e.g., "SCREENER")
  baseText?: string;       // Who was asked (e.g., "Total interventional radiologists")
  userNote?: string;       // Context note (e.g., "(Multiple answers accepted)")
}

export interface TablesJson {
  metadata: TablesJsonMetadata;
  tables: Record<string, TableData>;
}

export type ExcelFormat = 'joe' | 'antares';
export type DisplayMode = 'frequency' | 'counts' | 'both';

export interface ExcelFormatOptions {
  format?: ExcelFormat;        // 'joe' (default) or 'antares'
  displayMode?: DisplayMode;   // 'frequency' (default), 'counts', or 'both'
}

export interface FormatOptions extends ExcelFormatOptions {
  outputPath?: string;
  worksheetName?: string;
}

// =============================================================================
// Render Context
// =============================================================================

interface RenderContext {
  totalRespondents: number;
  bannerGroups: BannerGroup[];
  comparisonGroups: string[];
  significanceLevel: number;
}

// =============================================================================
// Main Formatter Class
// =============================================================================

export class ExcelFormatter {
  private workbook: ExcelJS.Workbook;
  private options: ExcelFormatOptions;

  constructor(options: ExcelFormatOptions = {}) {
    this.workbook = new ExcelJS.Workbook();
    this.workbook.creator = 'HawkTab AI';
    this.workbook.created = new Date();
    this.options = {
      format: options.format ?? 'joe',
      displayMode: options.displayMode ?? 'frequency',
    };
  }

  /**
   * Format tables.json into Excel workbook
   */
  async formatFromJson(tablesJson: TablesJson): Promise<ExcelJS.Workbook> {
    const { metadata, tables } = tablesJson;

    // Build render context from metadata
    const context: RenderContext = {
      totalRespondents: metadata.totalRespondents,
      bannerGroups: metadata.bannerGroups,
      comparisonGroups: metadata.comparisonGroups,
      significanceLevel: metadata.significanceLevel,
    };

    const tableIds = Object.keys(tables);
    console.log(`[ExcelFormatter] Formatting ${tableIds.length} tables (format: ${this.options.format}, display: ${this.options.displayMode})...`);

    if (this.options.format === 'joe') {
      this.formatJoeStyle(tables, tableIds, context);
    } else {
      this.formatAntaresStyle(tables, tableIds, context);
    }

    console.log(`[ExcelFormatter] Formatted ${tableIds.length} tables`);

    return this.workbook;
  }

  /**
   * Format in Joe style (horizontal layout)
   */
  private formatJoeStyle(
    tables: Record<string, TableData>,
    tableIds: string[],
    context: RenderContext
  ): void {
    const { displayMode } = this.options;

    // Calculate total cuts for column widths
    const cutCount = context.bannerGroups.reduce((sum, g) => sum + g.columns.length, 0);

    if (displayMode === 'both') {
      // Two sheets: Percentages and Counts
      const pctSheet = this.workbook.addWorksheet('Percentages', {
        properties: { tabColor: { argb: 'FF006BB3' } }
      });
      const countSheet = this.workbook.addWorksheet('Counts', {
        properties: { tabColor: { argb: 'FF4472C4' } }
      });

      this.renderJoeSheet(pctSheet, tables, tableIds, context, cutCount, 'percent');
      this.renderJoeSheet(countSheet, tables, tableIds, context, cutCount, 'count');
    } else {
      // Single sheet
      const valueType: ValueType = displayMode === 'counts' ? 'count' : 'percent';
      const sheetName = displayMode === 'counts' ? 'Counts' : 'Crosstabs';
      const worksheet = this.workbook.addWorksheet(sheetName, {
        properties: { tabColor: { argb: 'FF006BB3' } }
      });

      this.renderJoeSheet(worksheet, tables, tableIds, context, cutCount, valueType);
    }
  }

  /**
   * Render a single Joe-style worksheet
   */
  private renderJoeSheet(
    worksheet: ExcelJS.Worksheet,
    tables: Record<string, TableData>,
    tableIds: string[],
    context: RenderContext,
    _cutCount: number,
    valueType: ValueType
  ): void {
    // Render headers (once at top) - this builds the column layout
    const headerInfo = renderJoeHeaders(worksheet, context.bannerGroups, TABLE_SPACING.startRow);
    let currentRow = TABLE_SPACING.startRow + headerInfo.headerRowCount;

    // Set column widths (needs headerInfo for spacer columns)
    setJoeColumnWidths(worksheet, headerInfo);

    // Render each table - NO gaps between tables (Joe style = continuous flow)
    for (const tableId of tableIds) {
      const table = tables[tableId];

      if (table.tableType === 'frequency') {
        const result = renderJoeStyleFrequencyTable(
          worksheet,
          table as unknown as FrequencyTableData,
          currentRow,
          headerInfo,
          valueType,
          false,
          context.totalRespondents
        );
        currentRow = result.endRow;
      } else if (table.tableType === 'mean_rows') {
        const result = renderJoeStyleMeanRowsTable(
          worksheet,
          table as unknown as MeanRowsTableData,
          currentRow,
          headerInfo,
          context.totalRespondents
        );
        currentRow = result.endRow;
      } else {
        console.warn(`[ExcelFormatter] Unknown table type: ${table.tableType}, skipping ${tableId}`);
        continue;
      }
    }

    // Freeze panes: headers (top) and context+label columns (left)
    this.applyJoeFreezePanes(worksheet, headerInfo);
  }

  /**
   * Apply freeze panes for Joe format
   * Freezes header rows and context+label columns
   */
  private applyJoeFreezePanes(worksheet: ExcelJS.Worksheet, headerInfo: JoeHeaderInfo): void {
    const headerRowCount = headerInfo.headerRowCount;
    const frozenCols = 2; // Context + Label columns

    worksheet.views = [{
      state: 'frozen',
      ySplit: headerRowCount,
      xSplit: frozenCols,
      topLeftCell: `C${headerRowCount + 1}`,
      activeCell: 'A1',
    }];
  }

  /**
   * Format in Antares style (vertical stacked layout)
   */
  private formatAntaresStyle(
    tables: Record<string, TableData>,
    tableIds: string[],
    context: RenderContext
  ): void {
    const worksheet = this.workbook.addWorksheet('Crosstabs', {
      properties: { tabColor: { argb: 'FF006BB3' } }
    });

    // Set column widths
    this.setAntaresColumnWidths(worksheet, context.bannerGroups);

    // Render each table
    let currentRow: number = TABLE_SPACING.startRow;

    for (const tableId of tableIds) {
      const table = tables[tableId];

      if (table.tableType === 'frequency') {
        currentRow = renderFrequencyTable(
          worksheet,
          table as unknown as FrequencyTableData,
          currentRow,
          context
        );
      } else if (table.tableType === 'mean_rows') {
        currentRow = renderMeanRowsTable(
          worksheet,
          table as unknown as MeanRowsTableData,
          currentRow,
          context
        );
      } else {
        console.warn(`[ExcelFormatter] Unknown table type: ${table.tableType}, skipping ${tableId}`);
        continue;
      }

      // Add gap between tables
      currentRow += TABLE_SPACING.gapBetweenTables;
    }
  }

  /**
   * Set column widths for Antares format
   */
  private setAntaresColumnWidths(worksheet: ExcelJS.Worksheet, bannerGroups: BannerGroup[]): void {
    // First column: labels
    worksheet.getColumn(1).width = COLUMN_WIDTHS.label;

    // Data columns
    let colIndex = 2;
    for (const group of bannerGroups) {
      for (const _col of group.columns) {
        worksheet.getColumn(colIndex).width = COLUMN_WIDTHS.data;
        colIndex++;
      }
    }
  }

  /**
   * Format from file path
   */
  async formatFromFile(jsonPath: string): Promise<ExcelJS.Workbook> {
    const jsonContent = await fs.readFile(jsonPath, 'utf-8');
    const tablesJson = JSON.parse(jsonContent) as TablesJson;
    return this.formatFromJson(tablesJson);
  }

  /**
   * Save workbook to file
   */
  async saveToFile(outputPath: string): Promise<void> {
    await this.workbook.xlsx.writeFile(outputPath);
    console.log(`[ExcelFormatter] Saved workbook to: ${outputPath}`);
  }

  /**
   * Get workbook as buffer (for HTTP response)
   */
  async getBuffer(): Promise<Buffer> {
    return Buffer.from(await this.workbook.xlsx.writeBuffer());
  }
}

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Format tables.json file to Excel workbook
 */
export async function formatTablesToExcel(
  jsonPath: string,
  outputPath?: string,
  options?: ExcelFormatOptions
): Promise<{ workbook: ExcelJS.Workbook; outputPath: string }> {
  const formatter = new ExcelFormatter(options);
  const workbook = await formatter.formatFromFile(jsonPath);

  const finalOutputPath = outputPath || jsonPath.replace('.json', '.xlsx');
  await formatter.saveToFile(finalOutputPath);

  return { workbook, outputPath: finalOutputPath };
}

/**
 * Format tables.json data to Excel buffer (for HTTP response)
 */
export async function formatTablesToBuffer(
  tablesJson: TablesJson,
  options?: ExcelFormatOptions
): Promise<Buffer> {
  const formatter = new ExcelFormatter(options);
  await formatter.formatFromJson(tablesJson);
  return formatter.getBuffer();
}

/**
 * Load tables.json and format to buffer
 */
export async function formatTablesFileToBuffer(
  jsonPath: string,
  options?: ExcelFormatOptions
): Promise<Buffer> {
  const formatter = new ExcelFormatter(options);
  await formatter.formatFromFile(jsonPath);
  return formatter.getBuffer();
}
