/**
 * R Validation Script Generator
 *
 * Purpose: Generate R scripts that validate each table individually using tryCatch().
 * This allows us to identify which tables fail without crashing the entire script.
 *
 * Key features:
 * - Wraps each table's calculation in tryCatch()
 * - Outputs validation-results.json with success/failure per table
 * - Enables targeted retries for failed tables only
 */

import type { ExtendedTableDefinition, ExtendedTableRow } from '../../schemas/verificationAgentSchema';
import type { CutDefinition } from '../tables/CutsSpec';
import {
  escapeRString,
  sanitizeVarName,
} from './RScriptGeneratorV2';

// =============================================================================
// Types
// =============================================================================

export interface ValidationScriptResult {
  script: string;
  tableIds: string[];
}

export interface SingleTableValidationResult {
  script: string;
  tableId: string;
}

// =============================================================================
// Main Generator
// =============================================================================

/**
 * Generate a validation R script that tests all tables with tryCatch().
 * Each table is tested independently, and results are written to validation-results.json.
 */
export function generateValidationScript(
  tables: ExtendedTableDefinition[],
  cuts: CutDefinition[],
  dataFilePath: string = 'dataFile.sav',
  outputPath: string = 'validation-results.json'
): ValidationScriptResult {
  const lines: string[] = [];
  const tableIds: string[] = [];

  // Validate ALL tables, including excluded ones
  // Exclusion only affects rendering, not validation - we want to catch errors everywhere
  const tablesToValidate = tables;

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------
  lines.push('# HawkTab AI - R Validation Script');
  lines.push(`# Generated: ${new Date().toISOString()}`);
  lines.push(`# Tables to validate: ${tablesToValidate.length}`);
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
  generateCutsDefinitionMinimal(lines, cuts);

  // -------------------------------------------------------------------------
  // Helper Functions
  // -------------------------------------------------------------------------
  generateHelperFunctionsMinimal(lines);

  // -------------------------------------------------------------------------
  // Validation Results Container
  // -------------------------------------------------------------------------
  lines.push('# Initialize validation results');
  lines.push('validation_results <- list()');
  lines.push('');

  // -------------------------------------------------------------------------
  // Validate Each Table
  // -------------------------------------------------------------------------
  lines.push('# =============================================================================');
  lines.push('# Table Validation (each wrapped in tryCatch)');
  lines.push('# =============================================================================');
  lines.push('');

  for (const table of tablesToValidate) {
    tableIds.push(table.tableId);
    generateTableValidation(lines, table);
  }

  // -------------------------------------------------------------------------
  // Write Results
  // -------------------------------------------------------------------------
  lines.push('# =============================================================================');
  lines.push('# Write Validation Results');
  lines.push('# =============================================================================');
  lines.push('');
  lines.push(`write_json(validation_results, "${outputPath}", pretty = TRUE, auto_unbox = TRUE)`);
  lines.push(`print(paste("Validation results written to:", "${outputPath}"))`);
  lines.push('');
  lines.push('# Summary');
  lines.push('success_count <- sum(sapply(validation_results, function(x) x$success))');
  lines.push('fail_count <- length(validation_results) - success_count');
  lines.push('print(paste("Validation complete:", success_count, "passed,", fail_count, "failed"))');

  return {
    script: lines.join('\n'),
    tableIds,
  };
}

/**
 * Generate a validation script for a single table (used for retry validation).
 * This is a minimal script that only tests one table.
 */
export function generateSingleTableValidationScript(
  table: ExtendedTableDefinition,
  cuts: CutDefinition[],
  dataFilePath: string = 'dataFile.sav',
  outputPath: string = 'single-validation-result.json'
): SingleTableValidationResult {
  const lines: string[] = [];

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------
  lines.push('# HawkTab AI - Single Table Validation');
  lines.push(`# Table: ${table.tableId}`);
  lines.push(`# Generated: ${new Date().toISOString()}`);
  lines.push('');

  // -------------------------------------------------------------------------
  // Libraries
  // -------------------------------------------------------------------------
  lines.push('library(haven)');
  lines.push('library(dplyr)');
  lines.push('library(jsonlite)');
  lines.push('');

  // -------------------------------------------------------------------------
  // Load Data
  // -------------------------------------------------------------------------
  lines.push(`data <- read_sav("${dataFilePath}")`);
  lines.push('');

  // -------------------------------------------------------------------------
  // Cuts Definition (minimal)
  // -------------------------------------------------------------------------
  generateCutsDefinitionMinimal(lines, cuts);

  // -------------------------------------------------------------------------
  // Helper Functions
  // -------------------------------------------------------------------------
  generateHelperFunctionsMinimal(lines);

  // -------------------------------------------------------------------------
  // Validate Single Table
  // -------------------------------------------------------------------------
  lines.push('validation_results <- list()');
  lines.push('');
  generateTableValidation(lines, table);

  // -------------------------------------------------------------------------
  // Write Result
  // -------------------------------------------------------------------------
  lines.push(`write_json(validation_results, "${outputPath}", pretty = TRUE, auto_unbox = TRUE)`);

  return {
    script: lines.join('\n'),
    tableId: table.tableId,
  };
}

// =============================================================================
// Table Validation Generator
// =============================================================================

function generateTableValidation(lines: string[], table: ExtendedTableDefinition): void {
  const tableId = escapeRString(table.tableId);
  const varName = sanitizeVarName(table.tableId);

  lines.push(`# -----------------------------------------------------------------------------`);
  lines.push(`# Table: ${table.tableId} (${table.tableType})`);
  lines.push(`# -----------------------------------------------------------------------------`);
  lines.push('');

  lines.push(`validation_results[["${tableId}"]] <- tryCatch({`);
  lines.push('');

  if (table.tableType === 'frequency') {
    generateFrequencyTableValidation(lines, table, varName);
  } else if (table.tableType === 'mean_rows') {
    generateMeanRowsTableValidation(lines, table, varName);
  }

  lines.push('');
  lines.push(`  list(success = TRUE, tableId = "${tableId}", rowCount = ${table.rows.length})`);
  lines.push('');
  lines.push('}, error = function(e) {');
  lines.push(`  list(success = FALSE, tableId = "${tableId}", error = conditionMessage(e))`);
  lines.push('})');
  lines.push('');
  lines.push(`print(paste("Validated:", "${tableId}", "-", if(validation_results[["${tableId}"]]$success) "PASS" else paste("FAIL:", validation_results[["${tableId}"]]$error)))`);
  lines.push('');
}

function generateFrequencyTableValidation(
  lines: string[],
  table: ExtendedTableDefinition,
  _varName: string
): void {
  // For each row, validate that the variable exists and filterValue works
  for (let i = 0; i < table.rows.length; i++) {
    const row = table.rows[i] as ExtendedTableRow;
    const varNameEscaped = escapeRString(row.variable);
    const filterValue = row.filterValue;

    // Check if this is a NET with components
    const isNetWithComponents = row.isNet && row.netComponents && row.netComponents.length > 0;

    if (isNetWithComponents) {
      // NET row: validate all component variables exist
      lines.push(`  # Row ${i + 1}: NET - ${row.label}`);
      for (const comp of row.netComponents) {
        const compEscaped = escapeRString(comp);
        lines.push(`  if (!("${compEscaped}" %in% names(data))) stop("NET component variable '${compEscaped}' not found")`);
      }
    } else {
      // Standard row: validate variable exists and filterValue is valid
      lines.push(`  # Row ${i + 1}: ${row.variable} == ${filterValue}`);
      lines.push(`  if (!("${varNameEscaped}" %in% names(data))) stop("Variable '${varNameEscaped}' not found")`);

      // Check for range pattern (e.g., "0-4", "10-35")
      const rangeMatch = filterValue.match(/^(\d+)-(\d+)$/);
      // Check for multiple values (e.g., "4,5")
      const filterValues = filterValue.split(',').map(v => v.trim()).filter(v => v);
      const hasMultipleValues = filterValues.length > 1;

      if (rangeMatch) {
        // Range validation
        const [, minVal, maxVal] = rangeMatch;
        lines.push(`  test_val <- sum(as.numeric(data[["${varNameEscaped}"]]) >= ${minVal} & as.numeric(data[["${varNameEscaped}"]]) <= ${maxVal}, na.rm = TRUE)`);
      } else if (hasMultipleValues) {
        // Multiple values validation
        lines.push(`  test_val <- sum(as.numeric(data[["${varNameEscaped}"]]) %in% c(${filterValues.join(', ')}), na.rm = TRUE)`);
      } else if (filterValue && filterValue.trim() !== '') {
        // Single value validation - try numeric conversion
        lines.push(`  test_val <- sum(as.numeric(data[["${varNameEscaped}"]]) == ${filterValue}, na.rm = TRUE)`);
      }
    }
  }
}

function generateMeanRowsTableValidation(
  lines: string[],
  table: ExtendedTableDefinition,
  _varName: string
): void {
  // For mean_rows, validate that all variables exist and are numeric-like
  for (let i = 0; i < table.rows.length; i++) {
    const row = table.rows[i] as ExtendedTableRow;
    const varNameEscaped = escapeRString(row.variable);

    // Check if this is a NET with components
    const isNetWithComponents = row.isNet && row.netComponents && row.netComponents.length > 0;

    if (isNetWithComponents) {
      // NET row: validate all component variables exist and are numeric
      lines.push(`  # Row ${i + 1}: NET - ${row.label} (sum of component means)`);
      for (const comp of row.netComponents) {
        const compEscaped = escapeRString(comp);
        lines.push(`  if (!("${compEscaped}" %in% names(data))) stop("NET component variable '${compEscaped}' not found")`);
        lines.push(`  test_vals <- data[["${compEscaped}"]]`);
        lines.push(`  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {`);
        lines.push(`    stop("NET component '${compEscaped}' is not numeric (type: ", class(test_vals)[1], ")")`);
        lines.push(`  }`);
      }
    } else {
      // Standard row: validate variable exists and is numeric
      lines.push(`  # Row ${i + 1}: ${row.variable} (mean)`);
      lines.push(`  if (!("${varNameEscaped}" %in% names(data))) stop("Variable '${varNameEscaped}' not found")`);
      lines.push(`  test_vals <- data[["${varNameEscaped}"]]`);
      lines.push(`  if (!is.numeric(test_vals) && !inherits(test_vals, "haven_labelled")) {`);
      lines.push(`    stop("Variable '${varNameEscaped}' is not numeric (type: ", class(test_vals)[1], ")")`);
      lines.push(`  }`);
    }
  }
}

// =============================================================================
// Minimal Cuts Definition (for validation only)
// =============================================================================

function generateCutsDefinitionMinimal(lines: string[], cuts: CutDefinition[]): void {
  lines.push('# Cuts Definition (minimal for validation)');
  lines.push('cuts <- list(');
  lines.push('  Total = rep(TRUE, nrow(data))');

  for (const cut of cuts) {
    const expr = cut.rExpression.replace(/^\s*#.*$/gm, '').trim();
    if (expr && !expr.startsWith('#')) {
      const safeName = cut.name.replace(/`/g, "'");
      lines.push(`,  \`${safeName}\` = with(data, ${expr})`);
    }
  }

  lines.push(')');
  lines.push('');
}

// =============================================================================
// Minimal Helper Functions
// =============================================================================

function generateHelperFunctionsMinimal(lines: string[]): void {
  lines.push('# Apply cut mask safely');
  lines.push('apply_cut <- function(data, cut_mask) {');
  lines.push('  safe_mask <- cut_mask');
  lines.push('  safe_mask[is.na(safe_mask)] <- FALSE');
  lines.push('  data[safe_mask, ]');
  lines.push('}');
  lines.push('');

  lines.push('# Safely get variable column');
  lines.push('safe_get_var <- function(data, var_name) {');
  lines.push('  if (var_name %in% names(data)) return(data[[var_name]])');
  lines.push('  return(NULL)');
  lines.push('}');
  lines.push('');
}
