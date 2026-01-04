import { z } from 'zod';

/**
 * TableAgent Schemas
 * Purpose: Define input/output structures for the TableAgent that decides how to display
 * survey data as crosstabs.
 *
 * Key distinction:
 * - normalizedType: Data structure from DataMapProcessor (e.g., "numeric_range", "categorical_select")
 * - tableType: Display format for crosstab output (e.g., "frequency", "mean_rows", "grid_by_value")
 *
 * The agent maps data structures to display formats based on survey semantics.
 */

// =============================================================================
// Table Type Catalog
// =============================================================================

/**
 * Available table types the agent can output.
 * Each maps to a specific display format in the final Excel output.
 */
export const TableTypeSchema = z.enum([
  'frequency',      // Single categorical question - each answer option is a row
  'mean_rows',      // Multiple numeric items - each item is a row showing mean/median/sd
  'grid_by_value',  // Grid question - each item is a row, filtered to one value
  'grid_by_item',   // Grid question - each value is a row for a single item
  'multi_select',   // Multi-select question - each option is a row (value=1)
  'ranking',        // Ranking questions - each option is a row showing mean rank
]);

export type TableType = z.infer<typeof TableTypeSchema>;

/**
 * Available statistics for table calculations
 */
export const StatTypeSchema = z.enum([
  'count',    // Raw count
  'percent',  // Percentage of base
  'mean',     // Arithmetic mean
  'median',   // Median value
  'sd',       // Standard deviation
]);

export type StatType = z.infer<typeof StatTypeSchema>;

// =============================================================================
// Input Schemas
// =============================================================================

/**
 * Scale label mapping (e.g., 1="Very satisfied", 2="Satisfied", etc.)
 */
export const ScaleLabelSchema = z.object({
  value: z.union([z.number(), z.string()]),
  label: z.string(),
});

export type ScaleLabel = z.infer<typeof ScaleLabelSchema>;

/**
 * Single item in a question group (one variable from the datamap)
 */
export const TableAgentInputItemSchema = z.object({
  column: z.string(),           // Variable name: "S8r1", "A1r1"
  label: z.string(),            // From description: "Treating/Managing patients"
  context: z.string().optional(), // Parent context with identifiers: "A3ar1: Leqvio (inclisiran) - ..."
  normalizedType: z.string(),   // "numeric_range", "categorical_select", "binary_flag", etc.
  valueType: z.string(),        // Raw value type: "Values: 0-100", "Values: 1-2"

  // Optional type-specific metadata
  rangeMin: z.number().optional(),
  rangeMax: z.number().optional(),
  allowedValues: z.array(z.union([z.number(), z.string()])).optional(),
  scaleLabels: z.array(ScaleLabelSchema).optional(),
});

export type TableAgentInputItem = z.infer<typeof TableAgentInputItemSchema>;

/**
 * Grouped input for a single question (what agent receives per call)
 * Questions are grouped by parent before being sent to the agent.
 */
export const TableAgentInputSchema = z.object({
  questionId: z.string(),       // Parent question ID: "S8", "A1"
  questionText: z.string(),     // Question text from description (parent) or context (sub)

  // All variables for this question
  items: z.array(TableAgentInputItemSchema).min(1),

  // Optional survey markdown context (for enhanced reasoning)
  surveyContext: z.string().optional(),
});

export type TableAgentInput = z.infer<typeof TableAgentInputSchema>;

// =============================================================================
// Output Schemas
// NOTE: All properties must be REQUIRED for Azure OpenAI structured output compatibility
// Azure OpenAI does not support optional properties in JSON Schema
// Use empty strings/arrays or sentinel values instead of optional
// =============================================================================

/**
 * Single row in a table definition
 */
export const TableRowSchema = z.object({
  variable: z.string(),         // SPSS variable name: "S8r1", "A1r1"
  label: z.string(),            // Display label: "Treating/Managing patients"

  // For grid_by_value: which value this row represents
  // Use empty string "" when not applicable (Azure requires all fields)
  filterValue: z.string(),
});

export type TableRow = z.infer<typeof TableRowSchema>;

/**
 * Hints for downstream processing
 * These help deterministic code generate additional derived tables (T2B, combined ranks, etc.)
 */
export const TableHintSchema = z.enum([
  'ranking',   // This is a ranking question - downstream may add combined rank tables
  'scale-5',   // 5-point Likert scale - downstream may add T2B, B2B, Middle
  'scale-7',   // 7-point Likert scale - downstream may add T3B, B3B, etc.
]);

export type TableHint = z.infer<typeof TableHintSchema>;

/**
 * Single table definition (one question may produce multiple tables)
 * Note: stats are NOT included - they are inferred deterministically from tableType downstream
 */
export const TableDefinitionSchema = z.object({
  tableId: z.string(),          // Unique ID: "s8", "a1_indication_a"
  title: z.string(),            // Display title for the table
  tableType: TableTypeSchema,   // From catalog: "mean_rows", "grid_by_value", etc.

  // Rows in the table
  rows: z.array(TableRowSchema),

  // Hints for downstream processing (empty array if none apply)
  // Helps deterministic code generate derived tables (T2B for scales, combined ranks, etc.)
  hints: z.array(TableHintSchema),
});

export type TableDefinition = z.infer<typeof TableDefinitionSchema>;

/**
 * Complete output for a question group
 */
export const TableAgentOutputSchema = z.object({
  questionId: z.string(),       // Parent question ID (matches input)
  questionText: z.string(),     // For reference

  // One or more tables for this question
  tables: z.array(TableDefinitionSchema).min(1),

  // Agent confidence in this interpretation (0.0-1.0)
  confidence: z.number().min(0).max(1),

  // Brief explanation of decisions made
  reasoning: z.string(),
});

export type TableAgentOutput = z.infer<typeof TableAgentOutputSchema>;

// =============================================================================
// Validation Utilities
// =============================================================================

/**
 * Validate TableAgent input
 */
export const validateTableAgentInput = (data: unknown): TableAgentInput => {
  return TableAgentInputSchema.parse(data);
};

export const isValidTableAgentInput = (data: unknown): data is TableAgentInput => {
  return TableAgentInputSchema.safeParse(data).success;
};

/**
 * Validate TableAgent output
 */
export const validateTableAgentOutput = (data: unknown): TableAgentOutput => {
  return TableAgentOutputSchema.parse(data);
};

export const isValidTableAgentOutput = (data: unknown): data is TableAgentOutput => {
  return TableAgentOutputSchema.safeParse(data).success;
};

// =============================================================================
// Helper Functions
// =============================================================================

/**
 * Get all unique variables referenced in table definitions
 */
export const getTableVariables = (output: TableAgentOutput): string[] => {
  const variables = new Set<string>();
  for (const table of output.tables) {
    for (const row of table.rows) {
      variables.add(row.variable);
    }
  }
  return Array.from(variables);
};

/**
 * Get all table IDs from output
 */
export const getTableIds = (output: TableAgentOutput): string[] => {
  return output.tables.map(t => t.tableId);
};

/**
 * Check if output contains specific table type
 */
export const hasTableType = (output: TableAgentOutput, type: TableType): boolean => {
  return output.tables.some(t => t.tableType === type);
};

/**
 * Filter tables by type
 */
export const getTablesByType = (output: TableAgentOutput, type: TableType): TableDefinition[] => {
  return output.tables.filter(t => t.tableType === type);
};

/**
 * Calculate average confidence across multiple outputs
 */
export const calculateAverageConfidence = (outputs: TableAgentOutput[]): number => {
  if (outputs.length === 0) return 0;
  const sum = outputs.reduce((acc, o) => acc + o.confidence, 0);
  return sum / outputs.length;
};

/**
 * Combine multiple outputs into a single array of table definitions
 */
export const combineTableDefinitions = (outputs: TableAgentOutput[]): TableDefinition[] => {
  return outputs.flatMap(o => o.tables);
};
