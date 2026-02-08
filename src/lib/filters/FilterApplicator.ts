/**
 * FilterApplicator
 *
 * Deterministic code that applies pre-computed filters from FilterTranslatorAgent
 * to table definitions. NOT an AI agent — just applies the translations.
 *
 * Logic per table:
 * 1. Look up ALL filters for this table's questionId
 * 2. No filters → pass through unchanged
 * 3. Table-level filter only → set additionalFilter + baseText
 * 4. Row-level split only → create one table per split definition
 * 5. Both table-level + row-level → each split table gets combined filter using &
 */

import type { ExtendedTableDefinition } from '../../schemas/verificationAgentSchema';
import type { FilterTranslationOutput, TableFilter } from '../../schemas/skipLogicSchema';
import type { FilterApplicatorResult } from '../../schemas/skipLogicSchema';
import { validateFilterVariables } from './filterUtils';

/**
 * Apply pre-computed filters to tables.
 *
 * @param tables - Extended table definitions (from TableGenerator → toExtendedTable)
 * @param filters - Translated filter output from FilterTranslatorAgent
 * @param validVariables - Set of valid variable names from datamap
 */
export function applyFilters(
  tables: ExtendedTableDefinition[],
  filters: FilterTranslationOutput,
  validVariables: Set<string>,
): FilterApplicatorResult {
  // Build lookup: questionId → filters
  const filtersByQuestion = new Map<string, TableFilter[]>();
  for (const filter of filters.filters) {
    const existing = filtersByQuestion.get(filter.questionId) || [];
    existing.push(filter);
    filtersByQuestion.set(filter.questionId, existing);
  }

  const outputTables: ExtendedTableDefinition[] = [];
  let passCount = 0;
  let filterCount = 0;
  let splitCount = 0;
  let reviewRequiredCount = 0;

  for (const table of tables) {
    const questionId = table.questionId;

    // Look up filters for this question
    const questionFilters = filtersByQuestion.get(questionId);

    // No filters → pass through unchanged
    if (!questionFilters || questionFilters.length === 0) {
      outputTables.push(table);
      passCount++;
      continue;
    }

    // Separate table-level and row-level filters
    const tableLevelFilters = questionFilters.filter(f => f.action === 'filter' && f.filterExpression.trim() !== '');
    const rowLevelFilters = questionFilters.filter(f => f.action === 'split' && f.splits.length > 0);

    // Track review requirements
    const hasReviewRequired = questionFilters.some(f => f.humanReviewRequired);
    if (hasReviewRequired) {
      reviewRequiredCount++;
    }

    // Case: No actionable filters (expressions may have been cleared by validation)
    if (tableLevelFilters.length === 0 && rowLevelFilters.length === 0) {
      // Pass through but flag if review is needed
      outputTables.push({
        ...table,
        filterReviewRequired: hasReviewRequired || table.filterReviewRequired,
      });
      passCount++;
      continue;
    }

    // Case: Table-level filter only (no row-level splits)
    if (tableLevelFilters.length > 0 && rowLevelFilters.length === 0) {
      // Combine multiple table-level filters with &
      const combinedExpression = tableLevelFilters
        .map(f => f.filterExpression)
        .join(' & ');

      // Combine base texts
      const combinedBaseText = tableLevelFilters
        .map(f => f.baseText)
        .filter(t => t.trim() !== '')
        .join('; ');

      // Final validation
      const validation = validateFilterVariables(combinedExpression, validVariables);
      if (!validation.valid) {
        console.warn(
          `[FilterApplicator] Skipping invalid filter for ${table.tableId}: ` +
          `variables ${validation.invalidVariables.join(', ')} not found`
        );
        outputTables.push({
          ...table,
          filterReviewRequired: true,
        });
        passCount++;
        continue;
      }

      outputTables.push({
        ...table,
        additionalFilter: combinedExpression,
        baseText: combinedBaseText,
        filterReviewRequired: hasReviewRequired,
        lastModifiedBy: 'FilterApplicator',
      });
      filterCount++;
      continue;
    }

    // Case: Row-level split (with or without table-level filter)
    if (rowLevelFilters.length > 0) {
      // Get table-level expression to combine with splits (if any)
      const tableLevelExpression = tableLevelFilters.length > 0
        ? tableLevelFilters.map(f => f.filterExpression).join(' & ')
        : '';

      for (const rowFilter of rowLevelFilters) {
        for (const split of rowFilter.splits) {
          // Skip splits with empty expressions (cleared by validation)
          if (split.filterExpression.trim() === '') continue;

          // Find matching rows in the table
          const matchingRows = table.rows.filter(row =>
            split.rowVariables.includes(row.variable)
          );

          // Skip if no matching rows found
          if (matchingRows.length === 0) continue;

          // Combine table-level + split-level expression
          const combinedExpression = tableLevelExpression
            ? `(${tableLevelExpression}) & (${split.filterExpression})`
            : split.filterExpression;

          // Final validation
          const validation = validateFilterVariables(combinedExpression, validVariables);
          if (!validation.valid) {
            console.warn(
              `[FilterApplicator] Skipping invalid split for ${table.tableId}/${split.splitLabel}: ` +
              `variables ${validation.invalidVariables.join(', ')} not found`
            );
            continue;
          }

          // Create split table
          const splitTableId = `${table.tableId}_${split.splitLabel.toLowerCase().replace(/[^a-z0-9]+/g, '_')}`;

          outputTables.push({
            ...table,
            tableId: splitTableId,
            rows: matchingRows,
            additionalFilter: combinedExpression,
            baseText: split.baseText,
            splitFromTableId: table.tableId,
            tableSubtitle: split.splitLabel || table.tableSubtitle,
            filterReviewRequired: hasReviewRequired,
            lastModifiedBy: 'FilterApplicator',
          });
        }
      }

      splitCount++;
      continue;
    }
  }

  console.log(
    `[FilterApplicator] Applied filters: ${tables.length} input → ${outputTables.length} output tables ` +
    `(pass: ${passCount}, filter: ${filterCount}, split: ${splitCount}, review: ${reviewRequiredCount})`
  );

  return {
    tables: outputTables,
    summary: {
      totalInputTables: tables.length,
      totalOutputTables: outputTables.length,
      passCount,
      filterCount,
      splitCount,
      reviewRequiredCount,
    },
  };
}
