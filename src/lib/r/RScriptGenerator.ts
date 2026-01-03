/**
 * R Script Generator
 * Purpose: Generate master R script from manifest for crosstab execution
 */
import type { RManifest } from './Manifest';
import type { TableDefinition, MultiSubTableDefinition } from '../tables/TablePlan';

export function generateMasterRScript(manifest: RManifest, sessionId: string): string {
  const { tablePlan, cutsSpec } = manifest;
  
  // Generate R script
  const lines: string[] = [];
  
  // Header
  lines.push('# HawkTab AI - Generated R Script');
  lines.push(`# Session: ${sessionId}`);
  lines.push(`# Generated: ${new Date().toISOString()}`);
  lines.push(`# Tables: ${tablePlan.tables.length}`);
  lines.push(`# Cuts: ${cutsSpec.cuts.length}`);
  lines.push('');
  
  // Load required libraries
  lines.push('# Load required libraries');
  lines.push('library(haven)');
  lines.push('library(dplyr)');
  lines.push('# library(tidyr) # Optional - not used in current implementation');
  lines.push('');
  
  // Load data
  lines.push('# Load SPSS data file');
  lines.push('data <- read_sav("dataFile.sav")');
  lines.push('print(paste("Loaded", nrow(data), "rows and", ncol(data), "columns"))');
  lines.push('');
  
  // Define cuts (including Total)
  lines.push('# Define cuts');
  lines.push('cuts <- list(');
  lines.push('  Total = rep(TRUE, nrow(data))');
  
  for (const cut of cutsSpec.cuts) {
    // Clean the R expression (remove comments if any)
    const expr = cut.rExpression.replace(/^\s*#.*$/gm, '').trim();
    if (expr && !expr.startsWith('#')) {
      lines.push(`,  \`${cut.name}\` = with(data, ${expr})`);
    }
  }
  lines.push(')');
  lines.push('');
  
  // Helper functions
  lines.push('# Helper function for percentage calculation (rounded to whole number, half up)');
  lines.push('calc_pct <- function(x, base) {');
  lines.push('  if (base == 0) return(0)');
  lines.push('  floor(100 * x / base + 0.5)  # Round half up (12.5 -> 13)');
  lines.push('}');
  lines.push('');

  // Helper function for rounding numbers (half up, not banker's rounding)
  lines.push('# Helper function for rounding (half up: 12.5 -> 13, not banker\'s rounding)');
  lines.push('round_half_up <- function(x, digits = 0) {');
  lines.push('  floor(x * 10^digits + 0.5) / 10^digits');
  lines.push('}');
  lines.push('');

  // Helper function to safely apply cuts (handles NA values)
  lines.push('# Helper function to safely apply cuts (NA in cut expression = exclude)');
  lines.push('apply_cut <- function(data, cut_mask) {');
  lines.push('  safe_mask <- cut_mask');
  lines.push('  safe_mask[is.na(safe_mask)] <- FALSE');
  lines.push('  data[safe_mask, ]');
  lines.push('}');
  lines.push('');
  
  // Generate table functions
  lines.push('# Generate crosstab tables');
  lines.push('results <- list()');
  lines.push('');
  
  for (const table of tablePlan.tables) {
    if (table.tableType === 'single') {
      generateSingleTable(lines, table, sessionId);
    } else if (table.tableType === 'multi_subs') {
      generateMultiSubTable(lines, table as MultiSubTableDefinition, sessionId);
    }
  }
  
  // Save all results
  lines.push('# Create results directory and save CSV files');
  lines.push('if (!dir.exists("results")) {');
  lines.push('  dir.create("results")');
  lines.push('}');
  lines.push('');
  
  // Save individual CSV files
  lines.push('# Save individual table CSVs');
  lines.push('for (name in names(results)) {');
  lines.push('  tryCatch({');
  lines.push('    filename <- paste0("results/", name, ".csv")');
  lines.push('    write.csv(results[[name]], filename, row.names = FALSE)');
  lines.push('    print(paste("✓ Saved:", filename))');
  lines.push('  }, error = function(e) {');
  lines.push('    print(paste("✗ Error saving", name, ":", e$message))');
  lines.push('  })');
  lines.push('}');
  lines.push('');
  
  // Create combined workbook-style CSV
  lines.push('# Create combined workbook with all tables');
  lines.push('tryCatch({');
  lines.push('  combined <- data.frame()');
  lines.push('  row_offset <- 1');
  lines.push('  ');
  lines.push('  # Create metadata for table locations');
  lines.push('  table_index <- data.frame(');
  lines.push('    Table = character(),');
  lines.push('    StartRow = integer(),');
  lines.push('    EndRow = integer(),');
  lines.push('    stringsAsFactors = FALSE');
  lines.push('  )');
  lines.push('  ');
  lines.push('  # Combine all tables with spacing');
  lines.push('  all_lines <- list()');
  lines.push('  current_row <- 1');
  lines.push('  ');
  lines.push('  for (name in names(results)) {');
  lines.push('    # Add table title');
  lines.push('    all_lines[[length(all_lines) + 1]] <- c(paste0("TABLE: ", name), rep("", ncol(results[[name]]) - 1))');
  lines.push('    current_row <- current_row + 1');
  lines.push('    ');
  lines.push('    # Add table data');
  lines.push('    table_data <- results[[name]]');
  lines.push('    for (i in 1:nrow(table_data)) {');
  lines.push('      row_data <- as.character(table_data[i, ])');
  lines.push('      all_lines[[length(all_lines) + 1]] <- row_data');
  lines.push('    }');
  lines.push('    ');
  lines.push('    # Record table location');
  lines.push('    table_index <- rbind(table_index, data.frame(');
  lines.push('      Table = name,');
  lines.push('      StartRow = current_row,');
  lines.push('      EndRow = current_row + nrow(table_data) - 1,');
  lines.push('      stringsAsFactors = FALSE');
  lines.push('    ))');
  lines.push('    current_row <- current_row + nrow(table_data)');
  lines.push('    ');
  lines.push('    # Add spacing between tables');
  lines.push('    all_lines[[length(all_lines) + 1]] <- rep("", ncol(results[[name]]))');
  lines.push('    all_lines[[length(all_lines) + 1]] <- rep("", ncol(results[[name]]))');
  lines.push('    current_row <- current_row + 2');
  lines.push('  }');
  lines.push('  ');
  lines.push('  # Convert to data frame and save');
  lines.push('  max_cols <- max(sapply(all_lines, length))');
  lines.push('  combined_df <- as.data.frame(do.call(rbind, lapply(all_lines, function(x) {');
  lines.push('    c(x, rep("", max_cols - length(x)))');
  lines.push('  })))');
  lines.push('  ');
  lines.push('  write.csv(combined_df, "results/COMBINED_TABLES.csv", row.names = FALSE)');
  lines.push('  write.csv(table_index, "results/TABLE_INDEX.csv", row.names = FALSE)');
  lines.push('  print(paste("✓ Created combined workbook: results/COMBINED_TABLES.csv"))');
  lines.push('  print(paste("✓ Created table index: results/TABLE_INDEX.csv"))');
  lines.push('}, error = function(e) {');
  lines.push('  print(paste("✗ Error creating combined workbook:", e$message))');
  lines.push('})');
  lines.push('');
  
  lines.push('print(paste(rep("=", 50), collapse=""))');
  lines.push('print(paste("SUMMARY: Generated", length(results), "tables"))');
  lines.push('print(paste("Results saved in:", getwd(), "/results"))');
  lines.push('print(paste("Combined workbook: COMBINED_TABLES.csv"))');
  lines.push('print(paste("Table index: TABLE_INDEX.csv"))');
  
  return lines.join('\n');
}

function generateSingleTable(lines: string[], table: TableDefinition, _sessionId: string): void {
  const tableId = table.id;
  
  lines.push(`# Table: ${table.title}`);
  lines.push(`# Variable: ${table.questionVar}`);
  
  // Wrap in tryCatch for error handling
  lines.push('tryCatch({');
  
  // Check if variable exists
  lines.push(`  if ("${table.questionVar}" %in% names(data)) {`);
  
  // Check if it's a single table type with levels
  if (table.tableType === 'single' && table.levels && table.levels.length > 0) {
    // Categorical variable with defined levels
    lines.push(`    levels <- c(${table.levels.map((l) => `"${l.label}"`).join(', ')})`);
    lines.push(`    values <- c(${table.levels.map((l) => l.value).join(', ')})`);
    
    // Initialize data frame with proper structure
    lines.push(`    table_${tableId} <- data.frame(Level = levels, stringsAsFactors = FALSE)`);
    
    lines.push('    for (cut_name in names(cuts)) {');
    lines.push('      cut_data <- apply_cut(data, cuts[[cut_name]])');
    lines.push('      # Base = number of valid responses (non-NA) for this question in this cut');
    lines.push(`      base_n <- sum(!is.na(cut_data$\`${table.questionVar}\`))`);
    lines.push('      counts <- numeric(length(values))');
    lines.push('      for (i in seq_along(values)) {');
    lines.push(`        counts[i] <- sum(cut_data$\`${table.questionVar}\` == values[i], na.rm = TRUE)`);
    lines.push('      }');
    lines.push('      pcts <- sapply(counts, calc_pct, base = base_n)');
    lines.push('      col_data <- paste0(pcts, "% (", counts, ")")');
    lines.push(`      table_${tableId}[[cut_name]] <- col_data`);
    lines.push('    }');
    
  } else {
    // Numeric variable - use smart bucketing with high-level split
    const varName = table.questionVar;

    // Helper function to round to nice numbers based on range
    lines.push(`    # Smart bucketing for numeric variable ${varName}`);
    lines.push(`    var_data <- data$\`${varName}\`[!is.na(data$\`${varName}\`)]`);
    lines.push('    if (length(var_data) > 0) {');
    lines.push('      var_min <- min(var_data)');
    lines.push('      var_max <- max(var_data)');
    lines.push('      var_median <- median(var_data)');
    lines.push('      var_range <- var_max - var_min');
    lines.push('      ');
    lines.push('      # Determine nice rounding unit based on range');
    lines.push('      round_unit <- if (var_range <= 20) 5 else if (var_range <= 100) 10 else if (var_range <= 500) 25 else 100');
    lines.push('      ');
    lines.push('      # Round midpoint to nice number');
    lines.push('      midpoint <- round_half_up(var_median / round_unit, 0) * round_unit');
    lines.push('      ');
    lines.push('      # Create 4 bucket boundaries (2 below midpoint, 2 above)');
    lines.push('      lower_half_size <- midpoint - var_min');
    lines.push('      upper_half_size <- var_max - midpoint');
    lines.push('      ');
    lines.push('      # Calculate sub-bucket boundaries');
    lines.push('      lower_mid <- round_half_up((var_min + midpoint) / 2 / round_unit, 0) * round_unit');
    lines.push('      upper_mid <- round_half_up((midpoint + var_max) / 2 / round_unit, 0) * round_unit');
    lines.push('      ');
    lines.push('      # Ensure boundaries are distinct');
    lines.push('      if (lower_mid <= var_min) lower_mid <- var_min + round_unit');
    lines.push('      if (lower_mid >= midpoint) lower_mid <- midpoint - round_unit');
    lines.push('      if (upper_mid <= midpoint) upper_mid <- midpoint + round_unit');
    lines.push('      if (upper_mid >= var_max) upper_mid <- var_max - round_unit');
    lines.push('      ');
    lines.push('      # Create bucket labels');
    lines.push('      bucket_labels <- c(');
    lines.push('        paste0(midpoint, " or Less (Total)"),');
    lines.push('        paste0("  ", var_min, " - ", lower_mid - 1),');
    lines.push('        paste0("  ", lower_mid, " - ", midpoint),');
    lines.push('        paste0("More Than ", midpoint, " (Total)"),');
    lines.push('        paste0("  ", midpoint + 1, " - ", upper_mid),');
    lines.push('        paste0("  ", upper_mid + 1, "+"),');
    lines.push('        "Mean (overall)",');
    lines.push('        "Mean (minus outliers)",');
    lines.push('        "Median (overall)"');
    lines.push('      )');
    lines.push('      ');
    lines.push(`      table_${tableId} <- data.frame(Metric = bucket_labels, stringsAsFactors = FALSE)`);
    lines.push('      ');
    lines.push('      for (cut_name in names(cuts)) {');
    lines.push('        cut_data <- apply_cut(data, cuts[[cut_name]])');
    lines.push(`        cut_var <- cut_data$\`${varName}\``);
    lines.push('        valid_n <- sum(!is.na(cut_var))');
    lines.push('        ');
    lines.push('        # Calculate bucket counts');
    lines.push('        bucket1_count <- sum(cut_var >= var_min & cut_var < lower_mid, na.rm = TRUE)');
    lines.push('        bucket2_count <- sum(cut_var >= lower_mid & cut_var <= midpoint, na.rm = TRUE)');
    lines.push('        lower_total <- bucket1_count + bucket2_count');
    lines.push('        ');
    lines.push('        bucket3_count <- sum(cut_var > midpoint & cut_var <= upper_mid, na.rm = TRUE)');
    lines.push('        bucket4_count <- sum(cut_var > upper_mid, na.rm = TRUE)');
    lines.push('        upper_total <- bucket3_count + bucket4_count');
    lines.push('        ');
    lines.push('        # Calculate percentages');
    lines.push('        lower_total_pct <- calc_pct(lower_total, valid_n)');
    lines.push('        bucket1_pct <- calc_pct(bucket1_count, valid_n)');
    lines.push('        bucket2_pct <- calc_pct(bucket2_count, valid_n)');
    lines.push('        upper_total_pct <- calc_pct(upper_total, valid_n)');
    lines.push('        bucket3_pct <- calc_pct(bucket3_count, valid_n)');
    lines.push('        bucket4_pct <- calc_pct(bucket4_count, valid_n)');
    lines.push('        ');
    lines.push('        mean_val <- round_half_up(mean(cut_var, na.rm = TRUE), 0)');
    lines.push('        median_val <- round_half_up(median(cut_var, na.rm = TRUE), 0)');
    lines.push('        ');
    lines.push('        # Calculate mean minus outliers using IQR method');
    lines.push('        q1 <- quantile(cut_var, 0.25, na.rm = TRUE)');
    lines.push('        q3 <- quantile(cut_var, 0.75, na.rm = TRUE)');
    lines.push('        iqr <- q3 - q1');
    lines.push('        lower_bound <- q1 - 1.5 * iqr');
    lines.push('        upper_bound <- q3 + 1.5 * iqr');
    lines.push('        non_outlier_vals <- cut_var[!is.na(cut_var) & cut_var >= lower_bound & cut_var <= upper_bound]');
    lines.push('        mean_minus_outliers <- if (length(non_outlier_vals) > 0) round_half_up(mean(non_outlier_vals), 0) else mean_val');
    lines.push('        ');
    lines.push(`        table_${tableId}[[cut_name]] <- c(`);
    lines.push('          paste0(lower_total_pct, "% (", lower_total, ")"),');
    lines.push('          paste0(bucket1_pct, "% (", bucket1_count, ")"),');
    lines.push('          paste0(bucket2_pct, "% (", bucket2_count, ")"),');
    lines.push('          paste0(upper_total_pct, "% (", upper_total, ")"),');
    lines.push('          paste0(bucket3_pct, "% (", bucket3_count, ")"),');
    lines.push('          paste0(bucket4_pct, "% (", bucket4_count, ")"),');
    lines.push('          mean_val,');
    lines.push('          mean_minus_outliers,');
    lines.push('          median_val');
    lines.push('        )');
    lines.push('      }');
    lines.push('    } else {');
    lines.push('      # Fallback if no valid data');
    lines.push(`      table_${tableId} <- data.frame(Metric = c("N", "Mean", "Median"), stringsAsFactors = FALSE)`);
    lines.push('      for (cut_name in names(cuts)) {');
    lines.push(`        table_${tableId}[[cut_name]] <- c("0", "N/A", "N/A")`);
    lines.push('      }');
    lines.push('    }');
  }
  
  lines.push(`    results[["${tableId}"]] <- table_${tableId}`);
  lines.push(`    print(paste("✓ Generated table: ${table.title}"))`);
  lines.push('  } else {');
  lines.push(`    print(paste("⚠ Warning: Variable '${table.questionVar}' not found in data"))`);
  lines.push('  }');
  lines.push('}, error = function(e) {');
  lines.push(`  print(paste("✗ Error generating table '${table.title}':", e$message))`);
  lines.push('})');
  lines.push('');
}

function generateMultiSubTable(lines: string[], table: MultiSubTableDefinition, _sessionId: string): void {
  const tableId = table.id;

  lines.push(`# Multi-sub Table: ${table.title}`);
  lines.push(`# Items: ${table.items.length}`);
  lines.push(`# Normalized Type: ${table.normalizedType || 'default'}`);

  // Wrap in tryCatch for error handling
  lines.push('tryCatch({');

  lines.push(`  item_labels <- c(${table.items.map(item => `"${item.label}"`).join(', ')})`);

  // Initialize data frame with proper structure
  lines.push(`  table_${tableId} <- data.frame(Item = item_labels, stringsAsFactors = FALSE)`);

  lines.push('  for (cut_name in names(cuts)) {');
  lines.push('    cut_data <- apply_cut(data, cuts[[cut_name]])');

  // Bug 2 Fix: Sub-level numeric_range variables should show mean, not frequency
  if (table.normalizedType === 'numeric_range') {
    // Numeric range sub-variables: calculate mean for each item
    lines.push('    col_values <- character(0)');

    for (const item of table.items) {
      lines.push(`    if ("${item.var}" %in% names(cut_data)) {`);
      lines.push(`      mean_val <- round_half_up(mean(cut_data$\`${item.var}\`, na.rm = TRUE), 1)`);
      lines.push('      col_values <- c(col_values, as.character(mean_val))');
      lines.push('    } else {');
      lines.push('      col_values <- c(col_values, "N/A")');
      lines.push('    }');
    }
  } else {
    // Default behavior: frequency counting for binary/categorical sub-variables
    lines.push('    # Base = respondents who were asked this question (use first item to check, all share same skip logic)');
    lines.push(`    base_n <- sum(!is.na(cut_data$\`${table.items[0].var}\`))`);
    lines.push('    col_values <- character(0)');

    for (const item of table.items) {
      lines.push(`    if ("${item.var}" %in% names(cut_data)) {`);
      lines.push(`      count <- sum(cut_data$\`${item.var}\` == ${item.positiveValue}, na.rm = TRUE)`);
      lines.push('      pct <- calc_pct(count, base_n)');
      lines.push('      col_values <- c(col_values, paste0(pct, "% (", count, ")"))');
      lines.push('    } else {');
      lines.push('      col_values <- c(col_values, "N/A")');
      lines.push('    }');
    }
  }

  lines.push(`    table_${tableId}[[cut_name]] <- col_values`);
  lines.push('  }');

  lines.push(`  results[["${tableId}"]] <- table_${tableId}`);
  lines.push(`  print(paste("✓ Generated multi-sub table: ${table.title}"))`);
  lines.push('}, error = function(e) {');
  lines.push(`  print(paste("✗ Error generating multi-sub table '${table.title}':", e$message))`);
  lines.push('})');
  lines.push('');
}