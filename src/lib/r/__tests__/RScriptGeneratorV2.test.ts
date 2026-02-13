import { describe, it, expect } from 'vitest';
import { validateTable, validateAllTables, generateRScriptV2WithValidation } from '../RScriptGeneratorV2';
import { makeTable, makeRow } from '../../__tests__/fixtures';
import type { TableWithLoopFrame } from '@/schemas/verificationAgentSchema';
import type { CutDefinition } from '../../tables/CutsSpec';

function withLoopFrame(table: ReturnType<typeof makeTable>): TableWithLoopFrame {
  return { ...table, loopDataFrame: '' };
}

function makeCut(overrides: Partial<CutDefinition> = {}): CutDefinition {
  return {
    id: 'cut_a',
    name: 'Group A',
    rExpression: 'Q1 == 1',
    statLetter: 'A',
    groupName: 'Demo',
    groupIndex: 0,
    ...overrides,
  };
}

describe('RScriptGeneratorV2', () => {
  describe('validateTable', () => {
    it('validates a correct frequency table', () => {
      const table = makeTable({
        tableType: 'frequency',
        rows: [
          makeRow({ variable: 'Q1', filterValue: '1' }),
          makeRow({ variable: 'Q1', filterValue: '2' }),
        ],
      });
      const result = validateTable(table);
      expect(result.valid).toBe(true);
      expect(result.errors).toHaveLength(0);
    });

    it('validates a correct mean_rows table', () => {
      const table = makeTable({
        tableType: 'mean_rows',
        rows: [
          makeRow({ variable: 'Q1r1', filterValue: '' }),
          makeRow({ variable: 'Q1r2', filterValue: '' }),
        ],
      });
      const result = validateTable(table);
      expect(result.valid).toBe(true);
    });

    it('rejects table with no rows', () => {
      const table = makeTable({ rows: [] });
      const result = validateTable(table);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('no rows'))).toBe(true);
    });

    it('allows _HEADER_ filterValue rows on frequency table', () => {
      const table = makeTable({
        tableType: 'frequency',
        rows: [
          makeRow({ variable: 'Q1', filterValue: '_HEADER_' }),
          makeRow({ variable: 'Q1', filterValue: '1' }),
        ],
      });
      const result = validateTable(table);
      expect(result.valid).toBe(true);
    });

    it('flags empty filterValue on frequency table as error', () => {
      const table = makeTable({
        tableType: 'frequency',
        rows: [
          makeRow({ variable: 'Q1', filterValue: '' }),
        ],
      });
      const result = validateTable(table);
      expect(result.valid).toBe(false);
      expect(result.errors.some(e => e.includes('Empty filterValue'))).toBe(true);
    });

    it('warns on non-empty filterValue in mean_rows table', () => {
      const table = makeTable({
        tableType: 'mean_rows',
        rows: [
          makeRow({ variable: 'Q1r1', filterValue: '5' }),
        ],
      });
      const result = validateTable(table);
      expect(result.valid).toBe(true); // valid but has warning
      expect(result.warnings.length).toBeGreaterThan(0);
    });
  });

  describe('validateAllTables', () => {
    it('separates valid and invalid tables', () => {
      const tables = [
        makeTable({ tableId: 'valid1', rows: [makeRow()] }),
        makeTable({ tableId: 'invalid1', rows: [] }),
        makeTable({ tableId: 'valid2', rows: [makeRow({ variable: 'Q2', filterValue: '1' })] }),
      ];
      const { validTables, report } = validateAllTables(tables);
      expect(validTables).toHaveLength(2);
      expect(report.invalidTables).toBe(1);
      expect(report.skippedTables).toHaveLength(1);
      expect(report.skippedTables[0].tableId).toBe('invalid1');
    });
  });

  describe('generateRScriptV2WithValidation', () => {
    const baseCuts = [makeCut()];

    it('produces R script with required library calls', () => {
      const result = generateRScriptV2WithValidation({
        tables: [withLoopFrame(makeTable({ rows: [makeRow()] }))],
        cuts: baseCuts,
      });
      expect(result.script).toContain('library(haven)');
      expect(result.script).toContain('library(dplyr)');
      expect(result.script).toContain('library(jsonlite)');
      expect(result.script).toContain('read_sav');
      expect(result.script).toContain('write_json');
    });

    it('includes cut definitions in output', () => {
      const result = generateRScriptV2WithValidation({
        tables: [withLoopFrame(makeTable({ rows: [makeRow()] }))],
        cuts: baseCuts,
      });
      expect(result.script).toContain('Q1 == 1');
      expect(result.script).toContain('"A"');
    });

    it('includes weight variable when provided', () => {
      const result = generateRScriptV2WithValidation({
        tables: [withLoopFrame(makeTable({ rows: [makeRow()] }))],
        cuts: baseCuts,
        weightVariable: 'wt',
      });
      expect(result.script).toContain('wt');
      expect(result.script).toContain('Weight variable: wt');
    });

    it('omits weight references when no weightVariable', () => {
      const result = generateRScriptV2WithValidation({
        tables: [withLoopFrame(makeTable({ rows: [makeRow()] }))],
        cuts: baseCuts,
      });
      expect(result.script).not.toContain('Weight variable:');
    });

    it('includes significance thresholds in script config', () => {
      const result = generateRScriptV2WithValidation({
        tables: [withLoopFrame(makeTable({ rows: [makeRow()] }))],
        cuts: baseCuts,
        significanceThresholds: [0.05, 0.10],
      });
      expect(result.script).toContain('0.05');
      expect(result.script).toContain('0.1');
    });

    it('skips invalid tables and counts them in report', () => {
      const result = generateRScriptV2WithValidation({
        tables: [
          withLoopFrame(makeTable({ tableId: 'valid', rows: [makeRow()] })),
          withLoopFrame(makeTable({ tableId: 'invalid', rows: [] })),
        ],
        cuts: baseCuts,
      });
      expect(result.validation.invalidTables).toBe(1);
      expect(result.validation.skippedTables).toHaveLength(1);
      expect(result.script).not.toContain('"invalid"');
    });

    it('produces valid R script header even with empty tables input', () => {
      const result = generateRScriptV2WithValidation({
        tables: [],
        cuts: baseCuts,
      });
      expect(result.script).toContain('library(haven)');
      expect(result.validation.totalTables).toBe(0);
    });
  });
});
