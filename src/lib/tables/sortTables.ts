/**
 * Table Sorting Utility
 *
 * Purpose: Sort tables into a logical order for the final Excel output.
 *
 * Ordering rules:
 * 1. Screener questions (S1, S2, S2a, S2b, etc.) - sorted alphanumerically
 * 2. Main questions (A1, B1, Q1, etc.) - sorted alphanumerically
 * 3. Other questions (anything that doesn't match patterns) - at the bottom
 *
 * Within each question, ordering is:
 *   prefix → number → suffix → loopIteration → non-derived before derived → tableId tiebreaker
 *
 * Usage:
 *   const sortedTables = sortTables(verifiedTables);
 */

import type { ExtendedTableDefinition } from '@/schemas/verificationAgentSchema';

/**
 * Question category for sorting priority
 */
type QuestionCategory = 'screener' | 'main' | 'other';

/**
 * Parsed question identifier for sorting
 */
interface ParsedQuestion {
  category: QuestionCategory;
  prefix: string; // e.g., "S", "A", "B", "Q"
  number: number; // e.g., 1, 2, 10
  suffix: string; // e.g., "a", "b", "dk", "" (sub-question letters)
  loopIteration: number; // e.g., 1, 2, 0 (0 = not a loop variant)
  isDerived: boolean; // T2B, binned, brand-split, etc.
  sourceQuestionId: string; // For derived: the parent questionId for sorting proximity
  tableId: string; // For secondary sorting within same question
}

/**
 * Extract a normalized questionId from a tableId string.
 *
 * Derived tables have tableIds like "s8_binned", "a23_grey_goose", "s10b_detail".
 * We extract the base question identity for sorting proximity.
 */
function extractQuestionIdFromTableId(sourceTableId: string): string {
  const match = sourceTableId.match(/^([a-z]+)(\d+)([a-z]*)(?:_(\d+))?/i);
  if (match) {
    const [, prefix, num, suffix, loop] = match;
    return `${prefix.toUpperCase()}${num}${suffix}${loop ? '_' + loop : ''}`;
  }
  return sourceTableId;
}

/**
 * Parse a questionId to extract sortable components.
 *
 * Examples:
 *   "S8"      -> { category: "screener", prefix: "S", number: 8, suffix: "", loopIteration: 0 }
 *   "S2b"     -> { category: "screener", prefix: "S", number: 2, suffix: "b", loopIteration: 0 }
 *   "A3"      -> { category: "main", prefix: "A", number: 3, suffix: "", loopIteration: 0 }
 *   "A3DK"    -> { category: "main", prefix: "A", number: 3, suffix: "dk", loopIteration: 0 }
 *   "A7_1"    -> { category: "main", prefix: "A", number: 7, suffix: "", loopIteration: 1 }
 *   "A13a_1"  -> { category: "main", prefix: "A", number: 13, suffix: "a", loopIteration: 1 }
 *   "A14b_2"  -> { category: "main", prefix: "A", number: 14, suffix: "b", loopIteration: 2 }
 *   "US_State" -> { category: "other", ... }
 */
function parseQuestionId(
  questionId: string,
  tableId: string,
  isDerived: boolean,
  sourceTableId: string,
): ParsedQuestion {
  // Pattern: prefix(letters) + number + optional suffix(letters) + optional _loopIteration
  const match = questionId.match(/^([A-Za-z]+)(\d+)([A-Za-z]*)(?:_(\d+))?$/);

  if (match) {
    const [, prefix, numStr, suffix, loopStr] = match;
    const upperPrefix = prefix.toUpperCase();
    const number = parseInt(numStr, 10);
    const loopIteration = loopStr ? parseInt(loopStr, 10) : 0;
    const category: QuestionCategory = upperPrefix === 'S' ? 'screener' : 'main';

    return {
      category,
      prefix: upperPrefix,
      number,
      suffix: suffix.toLowerCase(),
      loopIteration,
      isDerived,
      sourceQuestionId: sourceTableId ? extractQuestionIdFromTableId(sourceTableId) : '',
      tableId,
    };
  }

  // Fallback for truly unstructured names (US_State, Region, qCARD_SPECIALTY)
  return {
    category: 'other',
    prefix: '',
    number: Infinity,
    suffix: questionId.toLowerCase(),
    loopIteration: 0,
    isDerived,
    sourceQuestionId: '',
    tableId,
  };
}

/**
 * Compare two parsed questions for sorting.
 * Returns negative if a < b, positive if a > b, 0 if equal.
 */
function compareParsedQuestions(a: ParsedQuestion, b: ParsedQuestion): number {
  // 1. Category priority: screener < main < other
  const categoryOrder: Record<QuestionCategory, number> = {
    screener: 0,
    main: 1,
    other: 2,
  };

  const categoryDiff = categoryOrder[a.category] - categoryOrder[b.category];
  if (categoryDiff !== 0) return categoryDiff;

  // 2. Within same category, sort by prefix (A < B < C...)
  if (a.prefix !== b.prefix) {
    return a.prefix.localeCompare(b.prefix);
  }

  // 3. Same prefix, sort by question number
  if (a.number !== b.number) {
    return a.number - b.number;
  }

  // 4. Same number, sort by suffix (empty < "a" < "b" < ...)
  if (a.suffix !== b.suffix) {
    if (a.suffix === '') return -1;
    if (b.suffix === '') return 1;
    return a.suffix.localeCompare(b.suffix);
  }

  // 5. Same suffix, sort by loop iteration (0=no loop first, then 1, 2, ...)
  if (a.loopIteration !== b.loopIteration) {
    return a.loopIteration - b.loopIteration;
  }

  // 6. Non-derived before derived (base table first, then T2B/binned/etc.)
  if (a.isDerived !== b.isDerived) {
    return a.isDerived ? 1 : -1;
  }

  // 7. Fall back to tableId for deterministic ordering
  return a.tableId.localeCompare(b.tableId);
}

/**
 * Sort tables into logical order for Excel output.
 *
 * @param tables - Array of ExtendedTableDefinition from VerificationAgent
 * @returns Sorted array (new array, original not mutated)
 */
export function sortTables(tables: ExtendedTableDefinition[]): ExtendedTableDefinition[] {
  const parsed = tables.map((table) => ({
    table,
    parsed: parseQuestionId(
      table.questionId,
      table.tableId,
      table.isDerived,
      table.sourceTableId,
    ),
  }));

  parsed.sort((a, b) => compareParsedQuestions(a.parsed, b.parsed));

  return parsed.map((p) => p.table);
}

/**
 * Get sorting metadata for debugging/logging.
 */
export function getSortingMetadata(tables: ExtendedTableDefinition[]): {
  screenerCount: number;
  mainCount: number;
  otherCount: number;
  order: Array<{ questionId: string; tableId: string }>;
} {
  const sorted = sortTables(tables);
  const parsed = sorted.map((t) =>
    parseQuestionId(t.questionId, t.tableId, t.isDerived, t.sourceTableId),
  );

  return {
    screenerCount: parsed.filter((p) => p.category === 'screener').length,
    mainCount: parsed.filter((p) => p.category === 'main').length,
    otherCount: parsed.filter((p) => p.category === 'other').length,
    order: sorted.map((t) => ({ questionId: t.questionId, tableId: t.tableId })),
  };
}
