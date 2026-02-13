import { describe, it, expect } from 'vitest';
import { sortTables, getSortingMetadata } from '../sortTables';
import { makeTable } from '../../__tests__/fixtures';

describe('sortTables', () => {
  it('sorts screener (S) before main (A) before other', () => {
    const tables = [
      makeTable({ tableId: 'us_state', questionId: 'US_State' }),
      makeTable({ tableId: 'a1', questionId: 'A1' }),
      makeTable({ tableId: 's1', questionId: 'S1' }),
    ];
    const sorted = sortTables(tables);
    expect(sorted.map(t => t.questionId)).toEqual(['S1', 'A1', 'US_State']);
  });

  it('sorts by prefix within main category (A before B before C)', () => {
    const tables = [
      makeTable({ tableId: 'c1', questionId: 'C1' }),
      makeTable({ tableId: 'a1', questionId: 'A1' }),
      makeTable({ tableId: 'b1', questionId: 'B1' }),
    ];
    const sorted = sortTables(tables);
    expect(sorted.map(t => t.questionId)).toEqual(['A1', 'B1', 'C1']);
  });

  it('sorts numerically (A2 before A10)', () => {
    const tables = [
      makeTable({ tableId: 'a10', questionId: 'A10' }),
      makeTable({ tableId: 'a2', questionId: 'A2' }),
    ];
    const sorted = sortTables(tables);
    expect(sorted.map(t => t.questionId)).toEqual(['A2', 'A10']);
  });

  it('sorts suffixes (S2 before S2a before S2b before S2dk)', () => {
    const tables = [
      makeTable({ tableId: 's2dk', questionId: 'S2dk' }),
      makeTable({ tableId: 's2b', questionId: 'S2b' }),
      makeTable({ tableId: 's2a', questionId: 'S2a' }),
      makeTable({ tableId: 's2', questionId: 'S2' }),
    ];
    const sorted = sortTables(tables);
    expect(sorted.map(t => t.questionId)).toEqual(['S2', 'S2a', 'S2b', 'S2dk']);
  });

  it('sorts loop iterations (A7 before A7_1 before A7_2)', () => {
    const tables = [
      makeTable({ tableId: 'a7_2', questionId: 'A7_2' }),
      makeTable({ tableId: 'a7_1', questionId: 'A7_1' }),
      makeTable({ tableId: 'a7', questionId: 'A7' }),
    ];
    const sorted = sortTables(tables);
    expect(sorted.map(t => t.questionId)).toEqual(['A7', 'A7_1', 'A7_2']);
  });

  it('sorts non-derived before derived with same questionId', () => {
    const tables = [
      makeTable({ tableId: 'a3_t2b', questionId: 'A3', isDerived: true, sourceTableId: 'a3' }),
      makeTable({ tableId: 'a3', questionId: 'A3', isDerived: false }),
    ];
    const sorted = sortTables(tables);
    expect(sorted[0].isDerived).toBe(false);
    expect(sorted[1].isDerived).toBe(true);
  });

  it('uses tableId as tiebreaker for identical questionId and derived status', () => {
    const tables = [
      makeTable({ tableId: 'a3_brand_b', questionId: 'A3', isDerived: true, sourceTableId: 'a3' }),
      makeTable({ tableId: 'a3_brand_a', questionId: 'A3', isDerived: true, sourceTableId: 'a3' }),
    ];
    const sorted = sortTables(tables);
    expect(sorted.map(t => t.tableId)).toEqual(['a3_brand_a', 'a3_brand_b']);
  });

  it('handles scrambled mixed categories correctly', () => {
    const tables = [
      makeTable({ tableId: 'region', questionId: 'Region' }),
      makeTable({ tableId: 'a2', questionId: 'A2' }),
      makeTable({ tableId: 's3', questionId: 'S3' }),
      makeTable({ tableId: 'a1', questionId: 'A1' }),
      makeTable({ tableId: 's1', questionId: 'S1' }),
      makeTable({ tableId: 'b1', questionId: 'B1' }),
    ];
    const sorted = sortTables(tables);
    const ids = sorted.map(t => t.questionId);
    // Screeners first, then main (A before B), then other
    expect(ids).toEqual(['S1', 'S3', 'A1', 'A2', 'B1', 'Region']);
  });

  it('returns empty array for empty input', () => {
    expect(sortTables([])).toEqual([]);
  });

  it('returns single table unchanged', () => {
    const table = makeTable({ tableId: 'a1', questionId: 'A1' });
    const sorted = sortTables([table]);
    expect(sorted).toHaveLength(1);
    expect(sorted[0].tableId).toBe('a1');
  });

  it('does not mutate original array', () => {
    const tables = [
      makeTable({ tableId: 'a2', questionId: 'A2' }),
      makeTable({ tableId: 'a1', questionId: 'A1' }),
    ];
    const original = [...tables];
    sortTables(tables);
    // Original should not be reordered
    expect(tables[0].questionId).toBe(original[0].questionId);
    expect(tables[1].questionId).toBe(original[1].questionId);
  });

  describe('getSortingMetadata', () => {
    it('returns correct category counts', () => {
      const tables = [
        makeTable({ tableId: 's1', questionId: 'S1' }),
        makeTable({ tableId: 's2', questionId: 'S2' }),
        makeTable({ tableId: 'a1', questionId: 'A1' }),
        makeTable({ tableId: 'region', questionId: 'Region' }),
      ];
      const meta = getSortingMetadata(tables);
      expect(meta.screenerCount).toBe(2);
      expect(meta.mainCount).toBe(1);
      expect(meta.otherCount).toBe(1);
      expect(meta.order).toHaveLength(4);
    });
  });
});
