/**
 * DataMapGrouper
 *
 * Purpose: Group verbose datamap variables by parent question for table generation.
 * Extracted from TableAgent.ts as part of Part 4 refactor.
 *
 * This module handles the pre-processing step of grouping datamap variables
 * before deterministic table generation. It filters out non-processable types
 * (admin, text_open) and groups sub-variables by their parent question.
 */

import { type VerboseDataMapType } from '../../schemas/processingSchemas';

// =============================================================================
// Configuration
// =============================================================================

/**
 * Options for controlling which variable types to include
 */
export interface DataMapGrouperOptions {
  /** Include open-ended text variables (env: INCLUDE_OPEN_ENDS, default: false) */
  includeOpenEnds?: boolean;
  /** Include admin/metadata variables (env: INCLUDE_ADMIN, default: false) */
  includeAdmin?: boolean;
}

/**
 * Get options from environment variables
 */
export function getGrouperOptionsFromEnv(): DataMapGrouperOptions {
  return {
    includeOpenEnds: process.env.INCLUDE_OPEN_ENDS === 'true',
    includeAdmin: process.env.INCLUDE_ADMIN === 'true',
  };
}

// =============================================================================
// Types
// =============================================================================

/**
 * Single item in a question group (one variable from the datamap)
 */
export interface QuestionItem {
  /** SPSS variable name: "S8r1", "A1r1" */
  column: string;
  /** From description field */
  label: string;
  /** Parent context with identifiers: "A3ar1: Leqvio (inclisiran) - ..." */
  context?: string;
  /** Classified variable type: "numeric_range", "categorical_select", etc. */
  normalizedType: string;
  /** Raw value type: "Values: 0-100", "Values: 1-2" */
  valueType: string;
  /** Minimum value for numeric ranges */
  rangeMin?: number;
  /** Maximum value for numeric ranges */
  rangeMax?: number;
  /** Discrete allowed values for categorical/scale variables */
  allowedValues?: (number | string)[];
  /** Labels for scale points */
  scaleLabels?: Array<{ value: number | string; label: string }>;
}

/**
 * Group of items belonging to the same parent question
 */
export interface QuestionGroup {
  /** Parent question ID: "S8", "A1" */
  questionId: string;
  /** Question text from description or context */
  questionText: string;
  /** All variables for this question */
  items: QuestionItem[];
}

// =============================================================================
// Filtering Logic
// =============================================================================

/**
 * Normalized types to exclude from processing by default.
 * These types cannot be meaningfully displayed in crosstabs.
 */
export const EXCLUDED_NORMALIZED_TYPES = new Set([
  'admin',      // Administrative/metadata fields (record IDs, timestamps, etc.)
  'text_open',  // Free text responses - can't crosstab open-ended text
  'weight',     // Weight variables - used for weighting, not reportable
]);

/**
 * Check if a variable should be included in processing based on its type
 */
export function isProcessableVariable(
  variable: VerboseDataMapType,
  options: DataMapGrouperOptions = {}
): boolean {
  const normalizedType = variable.normalizedType || 'unknown';

  // Check if type is in excluded set
  if (normalizedType === 'admin' && !options.includeAdmin) {
    return false;
  }
  if (normalizedType === 'text_open' && !options.includeOpenEnds) {
    return false;
  }
  if (normalizedType === 'weight') {
    return false;  // Weight variables are never processable
  }

  return true;
}

/**
 * Filter datamap to only processable variables
 */
export function filterProcessableVariables(
  dataMap: VerboseDataMapType[],
  options: DataMapGrouperOptions = {}
): VerboseDataMapType[] {
  const processable = dataMap.filter(v => isProcessableVariable(v, options));

  const excludedCount = dataMap.length - processable.length;
  if (excludedCount > 0) {
    console.log(`[DataMapGrouper] Filtered out ${excludedCount} non-processable variables`);
  }

  return processable;
}

// =============================================================================
// Grouping Logic
// =============================================================================

/**
 * Group verbose datamap variables by parent question.
 * Returns array of QuestionGroup, one per parent question.
 *
 * Pre-filters to exclude admin and text_open types (not reportable) unless
 * options override this behavior.
 *
 * @param dataMap - Full verbose datamap from DataMapProcessor
 * @param options - Optional configuration for filtering
 * @returns Array of question groups ready for table generation
 */
export function groupDataMap(
  dataMap: VerboseDataMapType[],
  options?: DataMapGrouperOptions
): QuestionGroup[] {
  // Merge with env-based options
  const effectiveOptions = {
    ...getGrouperOptionsFromEnv(),
    ...options,
  };

  const groups: QuestionGroup[] = [];

  // Pre-filter: exclude non-processable types
  const processableData = filterProcessableVariables(dataMap, effectiveOptions);

  // Separate parents and subs from processable data
  const parents = processableData.filter(v => v.level === 'parent');
  const subs = processableData.filter(v => v.level === 'sub');

  // Group subs by parentQuestion
  const subGroups = new Map<string, VerboseDataMapType[]>();
  for (const sub of subs) {
    const parent = sub.parentQuestion;
    if (!parent || parent === 'NA') continue;
    if (!subGroups.has(parent)) subGroups.set(parent, []);
    subGroups.get(parent)!.push(sub);
  }

  // Create group for each sub group
  for (const [parentId, items] of subGroups) {
    // Check if all items share the same context
    const firstContext = items[0]?.context;
    const allSameContext = items.every(item => item.context === firstContext);

    // Only use context as questionText if all items share it
    // If context varies (e.g., different treatments), use parentId to avoid confusion
    // Each item still has its own context field for reference
    const questionText = (allSameContext && firstContext) ? firstContext : parentId;

    groups.push({
      questionId: parentId,
      questionText,
      items: items.map(item => ({
        column: item.column,
        label: item.description,
        context: item.context,
        normalizedType: item.normalizedType || 'unknown',
        valueType: item.valueType,
        rangeMin: item.rangeMin,
        rangeMax: item.rangeMax,
        allowedValues: item.allowedValues,
        scaleLabels: item.scaleLabels,
      })),
    });
  }

  // Also include standalone parents (no subs) that weren't grouped
  const parentsWithSubs = new Set(subGroups.keys());
  for (const parent of parents) {
    if (parentsWithSubs.has(parent.column)) continue;

    groups.push({
      questionId: parent.column,
      questionText: parent.description,
      items: [{
        column: parent.column,
        label: parent.description,
        context: parent.context,
        normalizedType: parent.normalizedType || 'unknown',
        valueType: parent.valueType,
        rangeMin: parent.rangeMin,
        rangeMax: parent.rangeMax,
        allowedValues: parent.allowedValues,
        scaleLabels: parent.scaleLabels,
      }],
    });
  }

  return groups;
}

// =============================================================================
// Utilities
// =============================================================================

/**
 * Get statistics about a grouped datamap
 */
export function getGroupingStats(groups: QuestionGroup[]): {
  totalGroups: number;
  totalItems: number;
  avgItemsPerGroup: number;
  typeDistribution: Record<string, number>;
} {
  const totalItems = groups.reduce((sum, g) => sum + g.items.length, 0);
  const typeDistribution: Record<string, number> = {};

  for (const group of groups) {
    for (const item of group.items) {
      const type = item.normalizedType;
      typeDistribution[type] = (typeDistribution[type] || 0) + 1;
    }
  }

  return {
    totalGroups: groups.length,
    totalItems,
    avgItemsPerGroup: groups.length > 0 ? totalItems / groups.length : 0,
    typeDistribution,
  };
}
