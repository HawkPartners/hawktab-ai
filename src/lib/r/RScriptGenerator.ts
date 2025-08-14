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
  lines.push('# Helper function for percentage calculation');
  lines.push('calc_pct <- function(x, base) {');
  lines.push('  if (base == 0) return(0)');
  lines.push('  round(100 * x / base, 1)');
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
    lines.push('      cut_data <- data[cuts[[cut_name]], ]');
    lines.push('      base_n <- nrow(cut_data)');
    lines.push('      counts <- numeric(length(values))');
    lines.push('      for (i in seq_along(values)) {');
    lines.push(`        counts[i] <- sum(cut_data$\`${table.questionVar}\` == values[i], na.rm = TRUE)`);
    lines.push('      }');
    lines.push('      pcts <- sapply(counts, calc_pct, base = base_n)');
    lines.push('      col_data <- paste0(counts, " (", pcts, "%)")');
    lines.push(`      table_${tableId}[[cut_name]] <- col_data`);
    lines.push('    }');
    
  } else {
    // Numeric variable or levels to be inferred
    // Initialize data frame with proper structure
    lines.push(`    table_${tableId} <- data.frame(Metric = c("N", "Mean", "Median", "SD"), stringsAsFactors = FALSE)`);
    
    lines.push('    for (cut_name in names(cuts)) {');
    lines.push('      cut_data <- data[cuts[[cut_name]], ]');
    lines.push('      base_n <- nrow(cut_data)');
    lines.push(`      valid_n <- sum(!is.na(cut_data$\`${table.questionVar}\`), na.rm = TRUE)`);
    lines.push(`      mean_val <- round(mean(cut_data$\`${table.questionVar}\`, na.rm = TRUE), 2)`);
    lines.push(`      median_val <- round(median(cut_data$\`${table.questionVar}\`, na.rm = TRUE), 2)`);
    lines.push(`      sd_val <- round(sd(cut_data$\`${table.questionVar}\`, na.rm = TRUE), 2)`);
    lines.push(`      table_${tableId}[[cut_name]] <- c(`);
    lines.push('        paste0("N = ", valid_n),');
    lines.push('        paste0("Mean = ", mean_val),');
    lines.push('        paste0("Median = ", median_val),');
    lines.push('        paste0("SD = ", sd_val)');
    lines.push('      )');
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
  
  // Wrap in tryCatch for error handling
  lines.push('tryCatch({');
  
  lines.push(`  item_labels <- c(${table.items.map(item => `"${item.label}"`).join(', ')})`);
  
  // Initialize data frame with proper structure
  lines.push(`  table_${tableId} <- data.frame(Item = item_labels, stringsAsFactors = FALSE)`);
  
  lines.push('  for (cut_name in names(cuts)) {');
  lines.push('    cut_data <- data[cuts[[cut_name]], ]');
  lines.push('    base_n <- nrow(cut_data)');
  lines.push('    col_values <- character(0)');
  
  for (const item of table.items) {
    lines.push(`    if ("${item.var}" %in% names(cut_data)) {`);
    lines.push(`      count <- sum(cut_data$\`${item.var}\` == ${item.positiveValue}, na.rm = TRUE)`);
    lines.push('      pct <- calc_pct(count, base_n)');
    lines.push('      col_values <- c(col_values, paste0(count, " (", pct, "%)"))');
    lines.push('    } else {');
    lines.push('      col_values <- c(col_values, "N/A")');
    lines.push('    }');
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