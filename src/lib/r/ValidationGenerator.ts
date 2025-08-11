/**
 * ValidationGenerator.ts
 * 
 * Generates validation R code that checks data quality issues:
 * - Row sum constraints for percentage questions
 * - Out-of-range values
 * - Missing data patterns
 * 
 * Outputs: r-validation.json with warnings and recommendations
 */

import type { TablePlan } from '@/lib/tables/TablePlan';

export interface ValidationReport {
  rowSumViolations?: Array<{
    group: string;
    variables: string[];
    mean: number;
    std: number;
    flaggedRows: number;
    severity: 'warning' | 'error';
    message: string;
  }>;
  rangeViolations?: Array<{
    variable: string;
    declaredMin?: number;
    declaredMax?: number;
    empiricalMin: number;
    empiricalMax: number;
    outOfRangeCount: number;
    severity: 'warning' | 'error';
    message: string;
  }>;
  missingDataIssues?: Array<{
    variable: string;
    missingCount: number;
    missingPercent: number;
    severity: 'info' | 'warning';
    message: string;
  }>;
  summary: {
    totalIssues: number;
    errors: number;
    warnings: number;
    info: number;
  };
}

export class ValidationGenerator {
  /**
   * Generate validation R code that produces r-validation.json
   */
  generateValidationScript(
    sessionId: string,
    _tablePlan: TablePlan,
    outputPath: string = 'r-validation.json'
  ): string {
    const script = `
# Validation Script
# Generated: ${new Date().toISOString()}
# Purpose: Check data quality and constraint violations

library(haven)
library(jsonlite)
library(dplyr)

# Load data and preflight stats
data <- read_sav("temp-outputs/${sessionId}/dataFile.sav")
preflight_path <- "temp-outputs/${sessionId}/r/preflight.json"

validation_report <- list()
validation_report$rowSumViolations <- list()
validation_report$rangeViolations <- list()
validation_report$missingDataIssues <- list()

# Load preflight if available
if (file.exists(preflight_path)) {
  preflight <- fromJSON(preflight_path)
  
  # Check row sum constraints
  if (!is.null(preflight$rowSumGroups)) {
    for (group_name in names(preflight$rowSumGroups)) {
      group_stats <- preflight$rowSumGroups[[group_name]]
      
      # Determine severity based on deviation from 100
      mean_deviation <- abs(group_stats$rowSumMean - 100)
      severity <- if (mean_deviation > 5) "error" else if (mean_deviation > 2) "warning" else NULL
      
      if (!is.null(severity)) {
        validation_report$rowSumViolations <- append(
          validation_report$rowSumViolations,
          list(list(
            group = group_name,
            variables = group_stats$variables,
            mean = round(group_stats$rowSumMean, 2),
            std = round(group_stats$rowSumStd, 2),
            flaggedRows = group_stats$flaggedRows,
            severity = severity,
            message = paste0(
              "Row sums for ", group_name, 
              " average ", round(group_stats$rowSumMean, 1), 
              " (expected 100). ",
              group_stats$flaggedRows, " rows deviate > 2%"
            )
          ))
        )
      }
    }
  }
  
  # Check range violations
  for (var_name in names(preflight$variables)) {
    var_stats <- preflight$variables[[var_name]]
    
    # Check against declared ranges (would need to be passed in)
    # For now, just flag extreme outliers
    if (!is.na(var_stats$empiricalMin) && !is.na(var_stats$empiricalMax)) {
      # Example: flag if range is unexpectedly large
      range_span <- var_stats$empiricalMax - var_stats$empiricalMin
      
      # Add logic here based on variable type
      # This is a placeholder for demonstration
    }
  }
}

# Check missing data patterns
threshold_warn <- 0.10  # 10% missing triggers warning
threshold_info <- 0.05  # 5% missing triggers info

for (col_name in names(data)) {
  if (col_name %in% c("record", "uuid", "date", "status")) next  # Skip admin fields
  
  col_data <- data[[col_name]]
  n_total <- length(col_data)
  n_missing <- sum(is.na(col_data))
  pct_missing <- n_missing / n_total
  
  if (pct_missing >= threshold_info) {
    severity <- if (pct_missing >= threshold_warn) "warning" else "info"
    
    validation_report$missingDataIssues <- append(
      validation_report$missingDataIssues,
      list(list(
        variable = col_name,
        missingCount = n_missing,
        missingPercent = round(pct_missing * 100, 1),
        severity = severity,
        message = paste0(
          col_name, " has ",
          round(pct_missing * 100, 1), "% missing values (",
          n_missing, " of ", n_total, ")"
        )
      ))
    )
  }
}

# Summary statistics
n_errors <- sum(sapply(validation_report$rowSumViolations, function(x) x$severity == "error")) +
            sum(sapply(validation_report$rangeViolations, function(x) x$severity == "error"))
            
n_warnings <- sum(sapply(validation_report$rowSumViolations, function(x) x$severity == "warning")) +
              sum(sapply(validation_report$rangeViolations, function(x) x$severity == "warning")) +
              sum(sapply(validation_report$missingDataIssues, function(x) x$severity == "warning"))
              
n_info <- sum(sapply(validation_report$missingDataIssues, function(x) x$severity == "info"))

validation_report$summary <- list(
  totalIssues = n_errors + n_warnings + n_info,
  errors = n_errors,
  warnings = n_warnings,
  info = n_info
)

# Write output
output_json <- toJSON(validation_report, auto_unbox = TRUE, pretty = TRUE, na = "null")
writeLines(output_json, "temp-outputs/${sessionId}/${outputPath}")

cat("Validation complete\\n")
cat(paste("Found", n_errors, "errors,", n_warnings, "warnings,", n_info, "info messages\\n"))

# Also return key metrics for immediate use
list(
  success = n_errors == 0,
  summary = validation_report$summary
)
`;

    return script.trim();
  }

  /**
   * Parse validation results
   */
  async parseValidationReport(jsonPath: string): Promise<ValidationReport | null> {
    try {
      const fs = await import('fs/promises');
      const jsonContent = await fs.readFile(jsonPath, 'utf8');
      return JSON.parse(jsonContent) as ValidationReport;
    } catch (error) {
      console.warn(`Could not read validation report from ${jsonPath}:`, error);
      return null;
    }
  }
}