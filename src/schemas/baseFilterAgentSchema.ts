import { z } from 'zod';
import { ExtendedTableDefinitionSchema } from './verificationAgentSchema';

/**
 * BaseFilterAgent Schemas
 *
 * Purpose: Define input/output structures for the BaseFilterAgent that detects
 * skip/show logic in survey questions and applies appropriate base filters.
 *
 * Key capabilities:
 * - Detect SHOW IF / SKIP IF instructions in survey context
 * - Apply additional R filter expressions to table calculations
 * - Split tables when rows have different base requirements
 * - Flag ambiguous cases for human review
 *
 * Design principle: Agent analyzes each table and determines the appropriate
 * action (pass, filter, or split) based on survey document skip logic.
 */

// =============================================================================
// Action Types
// =============================================================================

/**
 * Action types for BaseFilterAgent decisions.
 * - 'pass': No skip logic detected, table passes through unchanged
 * - 'filter': Skip logic detected, additionalFilter applied to entire table
 * - 'split': Different rows have different bases, table split into multiple tables
 */
export const BaseFilterActionSchema = z.enum(['pass', 'filter', 'split']);

export type BaseFilterAction = z.infer<typeof BaseFilterActionSchema>;

// =============================================================================
// Result Schema
// =============================================================================

/**
 * Result for a single table processed by BaseFilterAgent.
 * Contains the action taken and the resulting table(s).
 */
export const BaseFilterTableResultSchema = z.object({
  /** Action taken by the agent */
  action: BaseFilterActionSchema,

  /** Original table ID that was processed */
  originalTableId: z.string(),

  /**
   * Output tables (1 for pass/filter, 1+ for split).
   * Each table includes additionalFilter and baseText fields.
   */
  tables: z.array(ExtendedTableDefinitionSchema),

  /** Confidence in the base filter decision (0.0-1.0) */
  confidence: z.number().min(0).max(1),

  /** Explanation of the reasoning for this decision */
  reasoning: z.string(),

  /** Whether this decision requires human review due to ambiguity */
  humanReviewRequired: z.boolean(),
});

export type BaseFilterTableResult = z.infer<typeof BaseFilterTableResultSchema>;

// =============================================================================
// Agent Output Schema
// =============================================================================

/**
 * Output from BaseFilterAgent for batch processing.
 * Contains results for all processed tables.
 */
export const BaseFilterAgentOutputSchema = z.object({
  /** Results for each processed table */
  results: z.array(BaseFilterTableResultSchema),
});

export type BaseFilterAgentOutput = z.infer<typeof BaseFilterAgentOutputSchema>;

// =============================================================================
// Single Table Output Schema (for parallel processing)
// =============================================================================

/**
 * Output from BaseFilterAgent for a single table.
 * Used when processing tables individually (e.g., in parallel).
 */
export const BaseFilterSingleTableOutputSchema = z.object({
  /** Action taken by the agent */
  action: BaseFilterActionSchema,

  /**
   * Output tables (1 for pass/filter, 1+ for split).
   * Each table includes additionalFilter and baseText fields.
   */
  tables: z.array(ExtendedTableDefinitionSchema),

  /** Confidence in the base filter decision (0.0-1.0) */
  confidence: z.number().min(0).max(1),

  /** Explanation of the reasoning for this decision */
  reasoning: z.string(),

  /** Whether this decision requires human review due to ambiguity */
  humanReviewRequired: z.boolean(),
});

export type BaseFilterSingleTableOutput = z.infer<typeof BaseFilterSingleTableOutputSchema>;

// =============================================================================
// Validation Utilities
// =============================================================================

/**
 * Validate BaseFilterAgent output.
 */
export const validateBaseFilterOutput = (data: unknown): BaseFilterAgentOutput => {
  return BaseFilterAgentOutputSchema.parse(data);
};

export const isValidBaseFilterOutput = (data: unknown): data is BaseFilterAgentOutput => {
  return BaseFilterAgentOutputSchema.safeParse(data).success;
};

/**
 * Validate single table output.
 */
export const validateSingleTableOutput = (data: unknown): BaseFilterSingleTableOutput => {
  return BaseFilterSingleTableOutputSchema.parse(data);
};

export const isValidSingleTableOutput = (data: unknown): data is BaseFilterSingleTableOutput => {
  return BaseFilterSingleTableOutputSchema.safeParse(data).success;
};

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Create a passthrough result (no changes needed).
 */
export function createPassthroughResult(
  table: z.infer<typeof ExtendedTableDefinitionSchema>
): BaseFilterTableResult {
  return {
    action: 'pass',
    originalTableId: table.tableId,
    tables: [table],
    confidence: 1.0,
    reasoning: 'No skip/show logic detected for this table',
    humanReviewRequired: false,
  };
}

/**
 * Get summary statistics for base filter results.
 */
export function summarizeBaseFilterResults(results: BaseFilterTableResult[]): {
  totalInputTables: number;
  totalOutputTables: number;
  passCount: number;
  filterCount: number;
  splitCount: number;
  reviewRequiredCount: number;
  averageConfidence: number;
} {
  const totalInputTables = results.length;
  const totalOutputTables = results.reduce((sum, r) => sum + r.tables.length, 0);
  const passCount = results.filter((r) => r.action === 'pass').length;
  const filterCount = results.filter((r) => r.action === 'filter').length;
  const splitCount = results.filter((r) => r.action === 'split').length;
  const reviewRequiredCount = results.filter((r) => r.humanReviewRequired).length;
  const averageConfidence =
    results.length > 0
      ? results.reduce((sum, r) => sum + r.confidence, 0) / results.length
      : 0;

  return {
    totalInputTables,
    totalOutputTables,
    passCount,
    filterCount,
    splitCount,
    reviewRequiredCount,
    averageConfidence,
  };
}
