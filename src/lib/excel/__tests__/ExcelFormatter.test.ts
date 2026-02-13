import { describe, it, expect } from 'vitest';
import { ExcelFormatter, formatTablesToBuffer } from '../ExcelFormatter';
import type { TablesJson, TablesJsonMetadata, TableData } from '../ExcelFormatter';
import ExcelJS from 'exceljs';

function makeTablesJson(overrides: {
  tables?: Record<string, TableData>;
  metadata?: Partial<TablesJsonMetadata>;
} = {}): TablesJson {
  const defaultMetadata: TablesJsonMetadata = {
    generatedAt: new Date().toISOString(),
    tableCount: 1,
    cutCount: 2,
    significanceLevel: 0.10,
    totalRespondents: 200,
    bannerGroups: [
      {
        groupName: 'Total',
        columns: [{ name: 'Total', statLetter: 'T' }],
      },
      {
        groupName: 'Gender',
        columns: [
          { name: 'Male', statLetter: 'A' },
          { name: 'Female', statLetter: 'B' },
        ],
      },
    ],
    comparisonGroups: ['A/B'],
    ...overrides.metadata,
  };

  const defaultTables: Record<string, TableData> = {
    q1: {
      tableId: 'q1',
      questionId: 'Q1',
      questionText: 'What is your preference?',
      tableType: 'frequency',
      isDerived: false,
      sourceTableId: '',
      data: {
        T: {
          base: 200,
          rows: { 'Q1::1': { count: 120, percent: 60 }, 'Q1::2': { count: 80, percent: 40 } },
        },
        A: {
          base: 100,
          rows: { 'Q1::1': { count: 70, percent: 70 }, 'Q1::2': { count: 30, percent: 30 } },
        },
        B: {
          base: 100,
          rows: { 'Q1::1': { count: 50, percent: 50 }, 'Q1::2': { count: 50, percent: 50 } },
        },
      },
    },
    ...overrides.tables,
  };

  return {
    metadata: defaultMetadata,
    tables: defaultTables,
  };
}

describe('ExcelFormatter', () => {
  it('produces a valid workbook from tablesJson', async () => {
    const tablesJson = makeTablesJson();
    const formatter = new ExcelFormatter();
    const workbook = await formatter.formatFromJson(tablesJson);
    expect(workbook).toBeInstanceOf(ExcelJS.Workbook);
    expect(workbook.worksheets.length).toBeGreaterThan(0);
  });

  it('produces non-empty buffer via formatTablesToBuffer', async () => {
    const tablesJson = makeTablesJson();
    const buffer = await formatTablesToBuffer(tablesJson);
    expect(buffer).toBeInstanceOf(Buffer);
    expect(buffer.length).toBeGreaterThan(0);
  });

  it('default format is joe with single crosstabs sheet', async () => {
    const tablesJson = makeTablesJson();
    const formatter = new ExcelFormatter();
    const workbook = await formatter.formatFromJson(tablesJson);
    const sheetNames = workbook.worksheets.map(s => s.name);
    expect(sheetNames).toContain('Table of Contents');
    expect(sheetNames).toContain('Crosstabs');
  });

  it('displayMode "both" creates two data sheets in one workbook', async () => {
    const tablesJson = makeTablesJson();
    const formatter = new ExcelFormatter({ displayMode: 'both' });
    const workbook = await formatter.formatFromJson(tablesJson);
    const sheetNames = workbook.worksheets.map(s => s.name);
    expect(sheetNames).toContain('Percentages');
    expect(sheetNames).toContain('Counts');
  });

  it('places excluded tables on separate sheet', async () => {
    const tablesJson = makeTablesJson({
      tables: {
        q1: {
          tableId: 'q1',
          questionId: 'Q1',
          questionText: 'Included table',
          tableType: 'frequency',
          isDerived: false,
          sourceTableId: '',
          data: {
            T: { base: 200, rows: { 'Q1::1': { count: 120, percent: 60 } } },
          },
        },
        q2: {
          tableId: 'q2',
          questionId: 'Q2',
          questionText: 'Excluded table',
          tableType: 'frequency',
          isDerived: false,
          sourceTableId: '',
          excluded: true,
          excludeReason: 'Low value',
          data: {
            T: { base: 200, rows: { 'Q2::1': { count: 100, percent: 50 } } },
          },
        },
      },
      metadata: { tableCount: 2 },
    });
    const formatter = new ExcelFormatter();
    const workbook = await formatter.formatFromJson(tablesJson);
    const sheetNames = workbook.worksheets.map(s => s.name);
    expect(sheetNames).toContain('Excluded Tables');
  });

  it('hideExcludedTables omits excluded sheet', async () => {
    const tablesJson = makeTablesJson({
      tables: {
        q1: {
          tableId: 'q1',
          questionId: 'Q1',
          questionText: 'Included',
          tableType: 'frequency',
          isDerived: false,
          sourceTableId: '',
          data: { T: { base: 100, rows: {} } },
        },
        q2: {
          tableId: 'q2',
          questionId: 'Q2',
          questionText: 'Excluded',
          tableType: 'frequency',
          isDerived: false,
          sourceTableId: '',
          excluded: true,
          excludeReason: 'test',
          data: { T: { base: 100, rows: {} } },
        },
      },
    });
    const formatter = new ExcelFormatter({ hideExcludedTables: true });
    const workbook = await formatter.formatFromJson(tablesJson);
    const sheetNames = workbook.worksheets.map(s => s.name);
    expect(sheetNames).not.toContain('Excluded Tables');
  });

  it('handles weighted metadata without error', async () => {
    const tablesJson = makeTablesJson({
      metadata: { weighted: true, weightVariable: 'wt' },
    });
    const formatter = new ExcelFormatter();
    const workbook = await formatter.formatFromJson(tablesJson);
    expect(workbook.worksheets.length).toBeGreaterThan(0);
  });

  it('handles empty tables gracefully', async () => {
    const tablesJson = makeTablesJson({ tables: {} });
    const formatter = new ExcelFormatter();
    const workbook = await formatter.formatFromJson(tablesJson);
    // Should at least have Table of Contents
    expect(workbook.worksheets.length).toBeGreaterThanOrEqual(1);
    const sheetNames = workbook.worksheets.map(s => s.name);
    expect(sheetNames).toContain('Table of Contents');
  });
});
