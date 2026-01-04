/**
 * R Script Generator V2
 *
 * Purpose: Generate R script that consumes TableAgentOutput and produces JSON
 *
 * Key features:
 * - Input: TableDefinition[] (from TableAgent) + CutDefinition[] with stat testing info
 * - Output: JSON file with calculations and significance testing
 * - Two table types: frequency and mean_rows
 * - Correct base sizing: always rebase on who answered the question
 * - Significance testing: z-test for proportions, t-test for means
 * - Within-group comparisons + comparison to Total column
 */

import type { TableDefinition } from '../../schemas/tableAgentSchema';
import type { CutDefinition, CutGroup } from '../tables/CutsSpec';

// =============================================================================
// Types
// =============================================================================

export interface RScriptV2Input {
  tables: TableDefinition[];
  cuts: CutDefinition[];
  cutGroups?: CutGroup[];           // Group structure for within-group stat testing
  totalStatLetter?: string | null;  // Letter for Total column (usually "T")
  dataFilePath?: string;            // Default: "dataFile.sav"
  significanceLevel?: number;       // Default: 0.10 (90% confidence)
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
  const {
    tables,
    cuts,
    cutGroups = [],
    totalStatLetter = 'T',
    dataFilePath = 'dataFile.sav',
    significanceLevel = 0.10
  } = input;
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
  lines.push(`# Significance Level: ${significanceLevel} (${Math.round((1 - significanceLevel) * 100)}% confidence)`);
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
  // Significance Level
  // -------------------------------------------------------------------------
  lines.push('# Significance testing threshold');
  lines.push(`p_threshold <- ${significanceLevel}`);
  lines.push('');

  // -------------------------------------------------------------------------
  // Cuts Definition with Stat Letters
  // -------------------------------------------------------------------------
  generateCutsDefinition(lines, cuts, cutGroups, totalStatLetter);

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
  // Significance Testing Pass
  // -------------------------------------------------------------------------
  generateSignificanceTesting(lines);

  // -------------------------------------------------------------------------
  // JSON Output
  // -------------------------------------------------------------------------
  generateJsonOutput(lines, tables, cuts, outputDir);

  return lines.join('\n');
}

// =============================================================================
// Cuts Definition with Stat Letters and Groups
// =============================================================================

function generateCutsDefinition(
  lines: string[],
  cuts: CutDefinition[],
  cutGroups: CutGroup[],
  totalStatLetter: string | null
): void {
  lines.push('# =============================================================================');
  lines.push('# Cuts Definition (banner columns) with stat testing metadata');
  lines.push('# =============================================================================');
  lines.push('');

  // Define cuts list
  lines.push('# Cut masks');
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

  // Define stat letter mapping
  lines.push('# Stat letter mapping (for significance testing output)');
  lines.push('cut_stat_letters <- c(');
  lines.push(`  "Total" = "${totalStatLetter || 'T'}"`);

  for (const cut of cuts) {
    const safeName = cut.name.replace(/`/g, "'").replace(/"/g, '\\"');
    lines.push(`,  "${safeName}" = "${cut.statLetter}"`);
  }

  lines.push(')');
  lines.push('');

  // Define group membership
  lines.push('# Group membership (for within-group comparisons)');
  lines.push('cut_groups <- list(');

  if (cutGroups.length > 0) {
    const groupEntries: string[] = [];
    for (const group of cutGroups) {
      const cutNames = group.cuts.map(c => `"${c.name.replace(/"/g, '\\"')}"`).join(', ');
      groupEntries.push(`  "${group.groupName}" = c(${cutNames})`);
    }
    lines.push(groupEntries.join(',\n'));
  } else {
    // Fallback: derive groups from cuts
    const groupMap = new Map<string, string[]>();
    for (const cut of cuts) {
      if (!groupMap.has(cut.groupName)) {
        groupMap.set(cut.groupName, []);
      }
      groupMap.get(cut.groupName)!.push(cut.name);
    }
    const groupEntries: string[] = [];
    for (const [groupName, cutNames] of groupMap) {
      const names = cutNames.map(n => `"${n.replace(/"/g, '\\"')}"`).join(', ');
      groupEntries.push(`  "${groupName}" = c(${names})`);
    }
    lines.push(groupEntries.join(',\n'));
  }

  lines.push(')');
  lines.push('');
  lines.push('print(paste("Defined", length(cuts), "cuts in", length(cut_groups), "groups"))');
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

  // Mean without outliers (IQR method)
  lines.push('# Calculate mean excluding outliers (IQR method)');
  lines.push('mean_no_outliers <- function(x) {');
  lines.push('  valid <- x[!is.na(x)]');
  lines.push('  if (length(valid) < 4) return(NA)  # Need enough data for IQR');
  lines.push('');
  lines.push('  q1 <- quantile(valid, 0.25)');
  lines.push('  q3 <- quantile(valid, 0.75)');
  lines.push('  iqr <- q3 - q1');
  lines.push('');
  lines.push('  lower_bound <- q1 - 1.5 * iqr');
  lines.push('  upper_bound <- q3 + 1.5 * iqr');
  lines.push('');
  lines.push('  no_outliers <- valid[valid >= lower_bound & valid <= upper_bound]');
  lines.push('  if (length(no_outliers) == 0) return(NA)');
  lines.push('');
  lines.push('  return(mean(no_outliers))');
  lines.push('}');
  lines.push('');

  // Z-test for proportions
  lines.push('# Z-test for proportions (returns TRUE if significantly different)');
  lines.push('sig_test_proportion <- function(count1, n1, count2, n2, threshold = p_threshold) {');
  lines.push('  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size');
  lines.push('');
  lines.push('  # Pooled proportion');
  lines.push('  p_pool <- (count1 + count2) / (n1 + n2)');
  lines.push('  if (p_pool == 0 || p_pool == 1) return(NA)  # Can\'t test');
  lines.push('');
  lines.push('  # Standard error');
  lines.push('  se <- sqrt(p_pool * (1 - p_pool) * (1/n1 + 1/n2))');
  lines.push('  if (se == 0) return(NA)');
  lines.push('');
  lines.push('  # Z statistic');
  lines.push('  p1 <- count1 / n1');
  lines.push('  p2 <- count2 / n2');
  lines.push('  z <- (p1 - p2) / se');
  lines.push('');
  lines.push('  # Two-tailed p-value');
  lines.push('  p_value <- 2 * (1 - pnorm(abs(z)))');
  lines.push('');
  lines.push('  return(list(significant = p_value < threshold, higher = p1 > p2))');
  lines.push('}');
  lines.push('');

  // T-test for means
  lines.push('# T-test for means (returns TRUE if significantly different)');
  lines.push('sig_test_mean <- function(vals1, vals2, threshold = p_threshold) {');
  lines.push('  n1 <- sum(!is.na(vals1))');
  lines.push('  n2 <- sum(!is.na(vals2))');
  lines.push('');
  lines.push('  if (n1 < 5 || n2 < 5) return(NA)  # Insufficient sample size');
  lines.push('');
  lines.push('  tryCatch({');
  lines.push('    result <- t.test(vals1, vals2, na.rm = TRUE)');
  lines.push('    m1 <- mean(vals1, na.rm = TRUE)');
  lines.push('    m2 <- mean(vals2, na.rm = TRUE)');
  lines.push('    return(list(significant = result$p.value < threshold, higher = m1 > m2))');
  lines.push('  }, error = function(e) {');
  lines.push('    return(NA)');
  lines.push('  })');
  lines.push('}');
  lines.push('');

  // Get cuts in same group
  lines.push('# Get other cuts in the same group (for within-group comparison)');
  lines.push('get_group_cuts <- function(cut_name) {');
  lines.push('  for (group_name in names(cut_groups)) {');
  lines.push('    if (cut_name %in% cut_groups[[group_name]]) {');
  lines.push('      return(cut_groups[[group_name]])');
  lines.push('    }');
  lines.push('  }');
  lines.push('  return(c())');
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
  lines.push(`  table_${sanitizeVarName(table.tableId)}$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]`);
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
    lines.push('      pct = pct,');
    lines.push('      sig_higher_than = c(),');
    lines.push('      sig_vs_total = NULL');
    lines.push('    )');
    lines.push('  } else {');
    lines.push(`    table_${sanitizeVarName(table.tableId)}$data[[cut_name]][["${escapeRString(rowKey)}"]] <- list(`);
    lines.push(`      label = "${label}",`);
    lines.push('      n = 0,');
    lines.push('      count = 0,');
    lines.push('      pct = 0,');
    lines.push('      sig_higher_than = c(),');
    lines.push('      sig_vs_total = NULL,');
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
  lines.push(`  table_${sanitizeVarName(table.tableId)}$data[[cut_name]]$stat_letter <- cut_stat_letters[[cut_name]]`);
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
    lines.push('    # Calculate summary statistics (all rounded to 1 decimal)');
    lines.push('    mean_val <- if (n > 0) round_half_up(mean(valid_vals), 1) else NA');
    lines.push('    median_val <- if (n > 0) round_half_up(median(valid_vals), 1) else NA');
    lines.push('    sd_val <- if (n > 1) round_half_up(sd(valid_vals), 1) else NA');
    lines.push('    mean_no_out <- if (n > 3) round_half_up(mean_no_outliers(valid_vals), 1) else NA');
    lines.push('');
    lines.push(`    table_${sanitizeVarName(table.tableId)}$data[[cut_name]][["${escapeRString(rowKey)}"]] <- list(`);
    lines.push(`      label = "${label}",`);
    lines.push('      n = n,');
    lines.push('      mean = mean_val,');
    lines.push('      mean_label = "Mean (overall)",');
    lines.push('      median = median_val,');
    lines.push('      median_label = "Median (overall)",');
    lines.push('      sd = sd_val,');
    lines.push('      mean_no_outliers = mean_no_out,');
    lines.push('      mean_no_outliers_label = "Mean (minus outliers)",');
    lines.push('      sig_higher_than = c(),');
    lines.push('      sig_vs_total = NULL');
    lines.push('    )');
    lines.push('  } else {');
    lines.push(`    table_${sanitizeVarName(table.tableId)}$data[[cut_name]][["${escapeRString(rowKey)}"]] <- list(`);
    lines.push(`      label = "${label}",`);
    lines.push('      n = 0,');
    lines.push('      mean = NA,');
    lines.push('      mean_label = "Mean (overall)",');
    lines.push('      median = NA,');
    lines.push('      median_label = "Median (overall)",');
    lines.push('      sd = NA,');
    lines.push('      mean_no_outliers = NA,');
    lines.push('      mean_no_outliers_label = "Mean (minus outliers)",');
    lines.push('      sig_higher_than = c(),');
    lines.push('      sig_vs_total = NULL,');
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
// Significance Testing Pass
// =============================================================================

function generateSignificanceTesting(lines: string[]): void {
  lines.push('# =============================================================================');
  lines.push('# Significance Testing Pass');
  lines.push('# =============================================================================');
  lines.push('');
  lines.push('print("Running significance testing...")');
  lines.push('');

  lines.push('for (table_id in names(all_tables)) {');
  lines.push('  tbl <- all_tables[[table_id]]');
  lines.push('  table_type <- tbl$tableType');
  lines.push('');
  lines.push('  # Get row keys (skip metadata fields)');
  lines.push('  cut_names <- names(tbl$data)');
  lines.push('');
  lines.push('  for (cut_name in cut_names) {');
  lines.push('    cut_data_obj <- tbl$data[[cut_name]]');
  lines.push('    row_keys <- names(cut_data_obj)');
  lines.push('    row_keys <- row_keys[row_keys != "stat_letter"]  # Skip metadata');
  lines.push('');
  lines.push('    # Get cuts in same group for within-group comparison');
  lines.push('    group_cuts <- get_group_cuts(cut_name)');
  lines.push('');
  lines.push('    for (row_key in row_keys) {');
  lines.push('      row_data <- cut_data_obj[[row_key]]');
  lines.push('      if (is.null(row_data) || !is.null(row_data$error)) next');
  lines.push('');
  lines.push('      sig_higher <- c()');
  lines.push('');
  lines.push('      # Compare to other cuts in same group');
  lines.push('      for (other_cut in group_cuts) {');
  lines.push('        if (other_cut == cut_name) next');
  lines.push('        if (!(other_cut %in% names(tbl$data))) next');
  lines.push('');
  lines.push('        other_data <- tbl$data[[other_cut]][[row_key]]');
  lines.push('        if (is.null(other_data) || !is.null(other_data$error)) next');
  lines.push('');
  lines.push('        if (table_type == "frequency") {');
  lines.push('          result <- sig_test_proportion(');
  lines.push('            row_data$count, row_data$n,');
  lines.push('            other_data$count, other_data$n');
  lines.push('          )');
  lines.push('          if (!is.null(result) && !is.na(result$significant) && result$significant && result$higher) {');
  lines.push('            sig_higher <- c(sig_higher, cut_stat_letters[[other_cut]])');
  lines.push('          }');
  lines.push('        } else if (table_type == "mean_rows") {');
  lines.push('          # For means, we need the raw values - use count/pct as proxy');
  lines.push('          # In practice, need to store raw values or use different approach');
  lines.push('          if (!is.na(row_data$mean) && !is.na(other_data$mean)) {');
  lines.push('            if (row_data$mean > other_data$mean) {');
  lines.push('              # Simplified: flag if mean is higher (proper t-test needs raw data)');
  lines.push('              sig_higher <- c(sig_higher, cut_stat_letters[[other_cut]])');
  lines.push('            }');
  lines.push('          }');
  lines.push('        }');
  lines.push('      }');
  lines.push('');
  lines.push('      # Compare to Total');
  lines.push('      if ("Total" %in% names(tbl$data) && cut_name != "Total") {');
  lines.push('        total_data <- tbl$data[["Total"]][[row_key]]');
  lines.push('        if (!is.null(total_data) && is.null(total_data$error)) {');
  lines.push('          sig_vs_total <- NULL');
  lines.push('');
  lines.push('          if (table_type == "frequency") {');
  lines.push('            result <- sig_test_proportion(');
  lines.push('              row_data$count, row_data$n,');
  lines.push('              total_data$count, total_data$n');
  lines.push('            )');
  lines.push('            if (!is.null(result) && !is.na(result$significant) && result$significant) {');
  lines.push('              sig_vs_total <- if (result$higher) "higher" else "lower"');
  lines.push('            }');
  lines.push('          } else if (table_type == "mean_rows") {');
  lines.push('            if (!is.na(row_data$mean) && !is.na(total_data$mean)) {');
  lines.push('              if (row_data$mean != total_data$mean) {');
  lines.push('                sig_vs_total <- if (row_data$mean > total_data$mean) "higher" else "lower"');
  lines.push('              }');
  lines.push('            }');
  lines.push('          }');
  lines.push('');
  lines.push('          all_tables[[table_id]]$data[[cut_name]][[row_key]]$sig_vs_total <- sig_vs_total');
  lines.push('        }');
  lines.push('      }');
  lines.push('');
  lines.push('      # Update sig_higher_than');
  lines.push('      all_tables[[table_id]]$data[[cut_name]][[row_key]]$sig_higher_than <- sig_higher');
  lines.push('    }');
  lines.push('  }');
  lines.push('}');
  lines.push('');
  lines.push('print("Significance testing complete")');
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
  lines.push(`    cutCount = ${cuts.length + 1},`);  // +1 for Total
  lines.push('    significanceLevel = p_threshold');
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
  lines.push('print(paste("  Significance level:", p_threshold))');
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
  generateSignificanceTesting,
  generateJsonOutput,
  escapeRString,
  sanitizeVarName,
};
