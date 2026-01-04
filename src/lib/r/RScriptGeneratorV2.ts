/**
 * R Script Generator V2
 *
 * Purpose: Generate R script that consumes TableAgentOutput and produces JSON
 *
 * Key differences from V1:
 * - Input: TableDefinition[] (from TableAgent) instead of TablePlan
 * - Output: JSON file (not CSV)
 * - Two table types: frequency and mean_rows
 * - Correct base sizing: always rebase on who answered the question
 */

import type { TableDefinition } from '../../schemas/tableAgentSchema';
import type { CutDefinition } from '../tables/CutsSpec';

// =============================================================================
// Types
// =============================================================================

export interface RScriptV2Input {
  tables: TableDefinition[];
  cuts: CutDefinition[];
  dataFilePath?: string;  // Default: "dataFile.sav"
}

export interface RScriptV2Options {
  sessionId?: string;
  outputDir?: string;  // Default: "results"
}

// =============================================================================
// Main Generator
// =============================================================================

export function generateRScriptV2(
  input: RScriptV2Input,
  options: RScriptV2Options = {}
): string {
  const { tables, cuts, dataFilePath = 'dataFile.sav' } = input;
  const { sessionId = 'unknown', outputDir = 'results' } = options;

  const lines: string[] = [];

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------
  lines.push('# HawkTab AI - R Script V2');
  lines.push(`# Session: ${sessionId}`);
  lines.push(`# Generated: ${new Date().toISOString()}`);
  lines.push(`# Tables: ${tables.length}`);
  lines.push(`# Cuts: ${cuts.length + 1}`);  // +1 for Total
  lines.push('');

  // -------------------------------------------------------------------------
  // Libraries
  // -------------------------------------------------------------------------
  lines.push('# Load required libraries');
  lines.push('library(haven)');
  lines.push('library(dplyr)');
  lines.push('library(jsonlite)');
  lines.push('');

  // -------------------------------------------------------------------------
  // Load Data
  // -------------------------------------------------------------------------
  lines.push('# Load SPSS data file');
  lines.push(`data <- read_sav("${dataFilePath}")`);
  lines.push('print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))');
  lines.push('');

  // -------------------------------------------------------------------------
  // Cuts Definition
  // -------------------------------------------------------------------------
  generateCutsDefinition(lines, cuts);

  // -------------------------------------------------------------------------
  // Helper Functions
  // -------------------------------------------------------------------------
  generateHelperFunctions(lines);

  // -------------------------------------------------------------------------
  // Table Calculations
  // -------------------------------------------------------------------------
  lines.push('# =============================================================================');
  lines.push('# Table Calculations');
  lines.push('# =============================================================================');
  lines.push('');
  lines.push('all_tables <- list()');
  lines.push('');

  for (const table of tables) {
    if (table.tableType === 'frequency') {
      generateFrequencyTable(lines, table);
    } else if (table.tableType === 'mean_rows') {
      generateMeanRowsTable(lines, table);
    } else {
      // Fallback: treat unknown types as frequency
      console.warn(`[RScriptGeneratorV2] Unknown tableType "${table.tableType}", treating as frequency`);
      generateFrequencyTable(lines, table);
    }
  }

  // -------------------------------------------------------------------------
  // JSON Output
  // -------------------------------------------------------------------------
  generateJsonOutput(lines, tables, cuts, outputDir);

  return lines.join('\n');
}

// =============================================================================
// Cuts Definition
// =============================================================================

function generateCutsDefinition(lines: string[], cuts: CutDefinition[]): void {
  lines.push('# Define cuts (banner columns)');
  lines.push('cuts <- list(');
  lines.push('  Total = rep(TRUE, nrow(data))');

  for (const cut of cuts) {
    // Clean the R expression (remove comments if any)
    const expr = cut.rExpression.replace(/^\s*#.*$/gm, '').trim();
    if (expr && !expr.startsWith('#')) {
      // Escape backticks in cut name for R
      const safeName = cut.name.replace(/`/g, "'");
      lines.push(`,  \`${safeName}\` = with(data, ${expr})`);
    }
  }

  lines.push(')');
  lines.push('');
  lines.push('print(paste("Defined", length(cuts), "cuts"))');
  lines.push('');
}

// =============================================================================
// Helper Functions
// =============================================================================

function generateHelperFunctions(lines: string[]): void {
  lines.push('# =============================================================================');
  lines.push('# Helper Functions');
  lines.push('# =============================================================================');
  lines.push('');

  // Round half up (not banker's rounding)
  lines.push('# Round half up (12.5 -> 13, not banker\'s rounding which gives 12)');
  lines.push('round_half_up <- function(x, digits = 0) {');
  lines.push('  floor(x * 10^digits + 0.5) / 10^digits');
  lines.push('}');
  lines.push('');

  // Apply cut safely (handle NA in cut expression)
  lines.push('# Apply cut mask safely (NA in cut = exclude)');
  lines.push('apply_cut <- function(data, cut_mask) {');
  lines.push('  safe_mask <- cut_mask');
  lines.push('  safe_mask[is.na(safe_mask)] <- FALSE');
  lines.push('  data[safe_mask, ]');
  lines.push('}');
  lines.push('');

  // Safe variable access
  lines.push('# Safely get variable column (returns NULL if not found)');
  lines.push('safe_get_var <- function(data, var_name) {');
  lines.push('  if (var_name %in% names(data)) {');
  lines.push('    return(data[[var_name]])');
  lines.push('  }');
  lines.push('  return(NULL)');
  lines.push('}');
  lines.push('');
}

// =============================================================================
// Frequency Table Generator
// =============================================================================

function generateFrequencyTable(lines: string[], table: TableDefinition): void {
  const tableId = escapeRString(table.tableId);
  const title = escapeRString(table.title);

  lines.push(`# -----------------------------------------------------------------------------`);
  lines.push(`# Table: ${table.tableId} (frequency)`);
  lines.push(`# Title: ${table.title}`);
  lines.push(`# Rows: ${table.rows.length}`);
  lines.push(`# -----------------------------------------------------------------------------`);
  lines.push('');

  lines.push(`table_${sanitizeVarName(table.tableId)} <- list(`);
  lines.push(`  tableId = "${tableId}",`);
  lines.push(`  title = "${title}",`);
  lines.push(`  tableType = "frequency",`);
  lines.push(`  hints = c(${table.hints.map(h => `"${h}"`).join(', ')}),`);
  lines.push('  data = list()');
  lines.push(')');
  lines.push('');

  lines.push('for (cut_name in names(cuts)) {');
  lines.push('  cut_data <- apply_cut(data, cuts[[cut_name]])');
  lines.push(`  table_${sanitizeVarName(table.tableId)}$data[[cut_name]] <- list()`);
  lines.push('');

  // Generate each row
  for (let i = 0; i < table.rows.length; i++) {
    const row = table.rows[i];
    const varName = escapeRString(row.variable);
    const label = escapeRString(row.label);
    const filterValue = escapeRString(row.filterValue);
    const rowKey = `${row.variable}_row_${i + 1}`;

    lines.push(`  # Row ${i + 1}: ${row.variable} == "${row.filterValue}"`);
    lines.push(`  var_col <- safe_get_var(cut_data, "${varName}")`);
    lines.push('  if (!is.null(var_col)) {');
    lines.push('    # CRITICAL: Base = respondents who answered this question (non-NA)');
    lines.push('    base_n <- sum(!is.na(var_col))');
    lines.push(`    count <- sum(var_col == "${filterValue}", na.rm = TRUE)`);
    lines.push('    pct <- if (base_n > 0) round_half_up(count / base_n * 100) else 0');
    lines.push('');
    lines.push(`    table_${sanitizeVarName(table.tableId)}$data[[cut_name]][["${escapeRString(rowKey)}"]] <- list(`);
    lines.push(`      label = "${label}",`);
    lines.push('      n = base_n,');
    lines.push('      count = count,');
    lines.push('      pct = pct');
    lines.push('    )');
    lines.push('  } else {');
    lines.push(`    table_${sanitizeVarName(table.tableId)}$data[[cut_name]][["${escapeRString(rowKey)}"]] <- list(`);
    lines.push(`      label = "${label}",`);
    lines.push('      n = 0,');
    lines.push('      count = 0,');
    lines.push('      pct = 0,');
    lines.push(`      error = "Variable ${varName} not found"`);
    lines.push('    )');
    lines.push('  }');
    lines.push('');
  }

  lines.push('}');
  lines.push('');
  lines.push(`all_tables[["${tableId}"]] <- table_${sanitizeVarName(table.tableId)}`);
  lines.push(`print(paste("Generated frequency table: ${tableId}"))`);
  lines.push('');
}

// =============================================================================
// Mean Rows Table Generator
// =============================================================================

function generateMeanRowsTable(lines: string[], table: TableDefinition): void {
  const tableId = escapeRString(table.tableId);
  const title = escapeRString(table.title);

  lines.push(`# -----------------------------------------------------------------------------`);
  lines.push(`# Table: ${table.tableId} (mean_rows)`);
  lines.push(`# Title: ${table.title}`);
  lines.push(`# Rows: ${table.rows.length}`);
  lines.push(`# -----------------------------------------------------------------------------`);
  lines.push('');

  lines.push(`table_${sanitizeVarName(table.tableId)} <- list(`);
  lines.push(`  tableId = "${tableId}",`);
  lines.push(`  title = "${title}",`);
  lines.push(`  tableType = "mean_rows",`);
  lines.push(`  hints = c(${table.hints.map(h => `"${h}"`).join(', ')}),`);
  lines.push('  data = list()');
  lines.push(')');
  lines.push('');

  lines.push('for (cut_name in names(cuts)) {');
  lines.push('  cut_data <- apply_cut(data, cuts[[cut_name]])');
  lines.push(`  table_${sanitizeVarName(table.tableId)}$data[[cut_name]] <- list()`);
  lines.push('');

  // Generate each row
  for (let i = 0; i < table.rows.length; i++) {
    const row = table.rows[i];
    const varName = escapeRString(row.variable);
    const label = escapeRString(row.label);
    const rowKey = row.variable;  // For mean_rows, use variable name as key

    lines.push(`  # Row ${i + 1}: ${row.variable} (numeric summary)`);
    lines.push(`  var_col <- safe_get_var(cut_data, "${varName}")`);
    lines.push('  if (!is.null(var_col)) {');
    lines.push('    # Get valid (non-NA) values');
    lines.push('    valid_vals <- var_col[!is.na(var_col)]');
    lines.push('    n <- length(valid_vals)');
    lines.push('');
    lines.push('    # Calculate summary statistics');
    lines.push('    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA');
    lines.push('    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA');
    lines.push('    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 2) else NA');
    lines.push('');
    lines.push(`    table_${sanitizeVarName(table.tableId)}$data[[cut_name]][["${escapeRString(rowKey)}"]] <- list(`);
    lines.push(`      label = "${label}",`);
    lines.push('      n = n,');
    lines.push('      mean = mean_val,');
    lines.push('      median = median_val,');
    lines.push('      sd = sd_val');
    lines.push('    )');
    lines.push('  } else {');
    lines.push(`    table_${sanitizeVarName(table.tableId)}$data[[cut_name]][["${escapeRString(rowKey)}"]] <- list(`);
    lines.push(`      label = "${label}",`);
    lines.push('      n = 0,');
    lines.push('      mean = NA,');
    lines.push('      median = NA,');
    lines.push('      sd = NA,');
    lines.push(`      error = "Variable ${varName} not found"`);
    lines.push('    )');
    lines.push('  }');
    lines.push('');
  }

  lines.push('}');
  lines.push('');
  lines.push(`all_tables[["${tableId}"]] <- table_${sanitizeVarName(table.tableId)}`);
  lines.push(`print(paste("Generated mean_rows table: ${tableId}"))`);
  lines.push('');
}

// =============================================================================
// JSON Output
// =============================================================================

function generateJsonOutput(
  lines: string[],
  tables: TableDefinition[],
  cuts: CutDefinition[],
  outputDir: string
): void {
  lines.push('# =============================================================================');
  lines.push('# Save Results as JSON');
  lines.push('# =============================================================================');
  lines.push('');
  lines.push(`# Create output directory`);
  lines.push(`if (!dir.exists("${outputDir}")) {`);
  lines.push(`  dir.create("${outputDir}", recursive = TRUE)`);
  lines.push('}');
  lines.push('');

  lines.push('# Build final output structure');
  lines.push('output <- list(');
  lines.push('  metadata = list(');
  lines.push(`    generatedAt = "${new Date().toISOString()}",`);
  lines.push(`    tableCount = ${tables.length},`);
  lines.push(`    cutCount = ${cuts.length + 1}`);  // +1 for Total
  lines.push('  ),');
  lines.push('  tables = all_tables');
  lines.push(')');
  lines.push('');

  lines.push('# Write JSON output');
  lines.push(`output_path <- file.path("${outputDir}", "tables.json")`);
  lines.push('write_json(output, output_path, pretty = TRUE, auto_unbox = TRUE)');
  lines.push('print(paste("JSON output saved to:", output_path))');
  lines.push('');

  lines.push('# Summary');
  lines.push('print(paste(rep("=", 60), collapse = ""))');
  lines.push('print(paste("SUMMARY"))');
  lines.push('print(paste("  Tables generated:", length(all_tables)))');
  lines.push('print(paste("  Cuts applied:", length(cuts)))');
  lines.push('print(paste("  Output:", output_path))');
  lines.push('print(paste(rep("=", 60), collapse = ""))');
}

// =============================================================================
// Utility Functions
// =============================================================================

/**
 * Escape special characters for R string literals
 */
function escapeRString(str: string): string {
  return str
    .replace(/\\/g, '\\\\')  // Backslash first
    .replace(/"/g, '\\"')     // Double quotes
    .replace(/\n/g, '\\n')    // Newlines
    .replace(/\r/g, '\\r')    // Carriage returns
    .replace(/\t/g, '\\t');   // Tabs
}

/**
 * Sanitize a string for use as an R variable name
 */
function sanitizeVarName(str: string): string {
  return str
    .replace(/[^a-zA-Z0-9_]/g, '_')  // Replace non-alphanumeric with underscore
    .replace(/^([0-9])/, '_$1');      // Prefix with _ if starts with digit
}

// =============================================================================
// Exports for Testing
// =============================================================================

export {
  generateCutsDefinition,
  generateHelperFunctions,
  generateFrequencyTable,
  generateMeanRowsTable,
  generateJsonOutput,
  escapeRString,
  sanitizeVarName,
};
