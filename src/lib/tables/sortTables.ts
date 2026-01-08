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
  suffix: string; // e.g., "a", "b", "" (for sub-questions like S2a)
  tableId: string; // For secondary sorting within same question
}

/**
 * Parse a questionId to extract sortable components.
 *
 * Examples:
 *   "S8" -> { category: "screener", prefix: "S", number: 8, suffix: "" }
 *   "S2b" -> { category: "screener", prefix: "S", number: 2, suffix: "b" }
 *   "A3" -> { category: "main", prefix: "A", number: 3, suffix: "" }
 *   "Q5a" -> { category: "main", prefix: "Q", number: 5, suffix: "a" }
 *   "US_State" -> { category: "other", ... }
 */
function parseQuestionId(questionId: string, tableId: string): ParsedQuestion {
  // Pattern: letter prefix, then number, then optional letter suffix
  // Examples: S1, S2a, S12, A3b, B1, Q5
  const match = questionId.match(/^([A-Za-z]+)(\d+)([A-Za-z]?)$/);

  if (match) {
    const [, prefix, numStr, suffix] = match;
    const upperPrefix = prefix.toUpperCase();
    const number = parseInt(numStr, 10);

    // Screener questions start with 'S'
    if (upperPrefix === 'S') {
      return {
        category: 'screener',
        prefix: upperPrefix,
        number,
        suffix: suffix.toLowerCase(),
        tableId,
      };
    }

    // Main questions: A, B, C, D, Q, etc.
    return {
      category: 'main',
      prefix: upperPrefix,
      number,
      suffix: suffix.toLowerCase(),
      tableId,
    };
  }

  // Everything else goes to "other"
  return {
    category: 'other',
    prefix: '',
    number: Infinity,
    suffix: questionId.toLowerCase(),
    tableId,
  };
}

/**
 * Compare two parsed questions for sorting.
 * Returns negative if a < b, positive if a > b, 0 if equal.
 */
function compareParsedQuestions(a: ParsedQuestion, b: ParsedQuestion): number {
  // Category priority: screener < main < other
  const categoryOrder: Record<QuestionCategory, number> = {
    screener: 0,
    main: 1,
    other: 2,
  };

  const categoryDiff = categoryOrder[a.category] - categoryOrder[b.category];
  if (categoryDiff !== 0) return categoryDiff;

  // Within same category, sort by prefix (A before B before C...)
  if (a.prefix !== b.prefix) {
    return a.prefix.localeCompare(b.prefix);
  }

  // Same prefix, sort by number
  if (a.number !== b.number) {
    return a.number - b.number;
  }

  // Same number, sort by suffix (a before b before c, empty string first)
  if (a.suffix !== b.suffix) {
    // Empty suffix comes before any letter suffix
    if (a.suffix === '') return -1;
    if (b.suffix === '') return 1;
    return a.suffix.localeCompare(b.suffix);
  }

  // Fall back to tableId for deterministic ordering of tables within same question
  return a.tableId.localeCompare(b.tableId);
}

/**
 * Sort tables into logical order for Excel output.
 *
 * @param tables - Array of ExtendedTableDefinition from VerificationAgent
 * @returns Sorted array (new array, original not mutated)
 */
export function sortTables(tables: ExtendedTableDefinition[]): ExtendedTableDefinition[] {
  // Parse all question IDs
  const parsed = tables.map((table) => ({
    table,
    parsed: parseQuestionId(table.questionId, table.tableId),
  }));

  // Sort by parsed components
  parsed.sort((a, b) => compareParsedQuestions(a.parsed, b.parsed));

  // Return sorted tables
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
  const parsed = sorted.map((t) => parseQuestionId(t.questionId, t.tableId));

  return {
    screenerCount: parsed.filter((p) => p.category === 'screener').length,
    mainCount: parsed.filter((p) => p.category === 'main').length,
    otherCount: parsed.filter((p) => p.category === 'other').length,
    order: sorted.map((t) => ({ questionId: t.questionId, tableId: t.tableId })),
  };
}
