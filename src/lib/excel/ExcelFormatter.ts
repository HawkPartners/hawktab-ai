/**
 * Excel Formatter
 *
 * Main class for formatting tables.json into Antares-style Excel workbook.
 *
 * Features:
 * - Reads tables.json from R output
 * - Renders frequency and mean_rows tables
 * - Multi-row headers with group/column/stat letter
 * - Heavy borders between banner groups
 * - Stacks all tables on single worksheet
 */

import ExcelJS from 'exceljs';
import { promises as fs } from 'fs';

import { renderFrequencyTable, type FrequencyTableData } from './tableRenderers/frequencyTable';
import { renderMeanRowsTable, type MeanRowsTableData } from './tableRenderers/meanRowsTable';
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
  questionText: string;
  tableType: 'frequency' | 'mean_rows';
  data: Record<string, unknown>;
}

export interface TablesJson {
  metadata: TablesJsonMetadata;
  tables: Record<string, TableData>;
}

export interface FormatOptions {
  outputPath?: string;
  worksheetName?: string;
}

// =============================================================================
// Main Formatter Class
// =============================================================================

export class ExcelFormatter {
  private workbook: ExcelJS.Workbook;
  private worksheet: ExcelJS.Worksheet;

  constructor() {
    this.workbook = new ExcelJS.Workbook();
    this.workbook.creator = 'HawkTab AI';
    this.workbook.created = new Date();

    this.worksheet = this.workbook.addWorksheet('Crosstabs', {
      properties: { tabColor: { argb: 'FF006BB3' } }
    });
  }

  /**
   * Format tables.json into Excel workbook
   */
  async formatFromJson(tablesJson: TablesJson): Promise<ExcelJS.Workbook> {
    const { metadata, tables } = tablesJson;

    // Build render context from metadata
    const context = {
      totalRespondents: metadata.totalRespondents,
      bannerGroups: metadata.bannerGroups,
      comparisonGroups: metadata.comparisonGroups,
      significanceLevel: metadata.significanceLevel,
    };

    // Set column widths
    this.setColumnWidths(context.bannerGroups);

    // Render each table
    let currentRow: number = TABLE_SPACING.startRow;
    const tableIds = Object.keys(tables);

    console.log(`[ExcelFormatter] Formatting ${tableIds.length} tables...`);

    for (const tableId of tableIds) {
      const table = tables[tableId];

      if (table.tableType === 'frequency') {
        currentRow = renderFrequencyTable(
          this.worksheet,
          table as unknown as FrequencyTableData,
          currentRow,
          context
        );
      } else if (table.tableType === 'mean_rows') {
        currentRow = renderMeanRowsTable(
          this.worksheet,
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

    console.log(`[ExcelFormatter] Formatted ${tableIds.length} tables, ${currentRow} rows`);

    return this.workbook;
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

  /**
   * Set column widths based on banner groups
   */
  private setColumnWidths(bannerGroups: BannerGroup[]): void {
    // First column: labels
    this.worksheet.getColumn(1).width = COLUMN_WIDTHS.label;

    // Data columns
    let colIndex = 2;
    for (const group of bannerGroups) {
      for (const _col of group.columns) {
        this.worksheet.getColumn(colIndex).width = COLUMN_WIDTHS.data;
        colIndex++;
      }
    }
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
  outputPath?: string
): Promise<{ workbook: ExcelJS.Workbook; outputPath: string }> {
  const formatter = new ExcelFormatter();
  const workbook = await formatter.formatFromFile(jsonPath);

  const finalOutputPath = outputPath || jsonPath.replace('.json', '.xlsx');
  await formatter.saveToFile(finalOutputPath);

  return { workbook, outputPath: finalOutputPath };
}

/**
 * Format tables.json data to Excel buffer (for HTTP response)
 */
export async function formatTablesToBuffer(tablesJson: TablesJson): Promise<Buffer> {
  const formatter = new ExcelFormatter();
  await formatter.formatFromJson(tablesJson);
  return formatter.getBuffer();
}

/**
 * Load tables.json and format to buffer
 */
export async function formatTablesFileToBuffer(jsonPath: string): Promise<Buffer> {
  const formatter = new ExcelFormatter();
  await formatter.formatFromFile(jsonPath);
  return formatter.getBuffer();
}
