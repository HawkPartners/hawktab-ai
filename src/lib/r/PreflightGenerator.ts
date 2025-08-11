/**
 * PreflightGenerator.ts
 * 
 * Generates a preflight R script that analyzes the actual data to compute:
 * - Empirical min/max values for numeric variables
 * - Mean, median, standard deviation
 * - Quantiles for bucketing
 * - Row sum statistics for percentage groups
 * 
 * Outputs: preflight.json with statistics for use by master.R
 */

import type { TablePlan, SingleTableDefinition, MultiSubTableDefinition } from '@/lib/tables/TablePlan';

export interface PreflightStats {
  variables: Record<string, VariableStats>;
  rowSumGroups?: Record<string, RowSumStats>;
  metadata: {
    generatedAt: string;
    dataFile: string;
    totalVariables: number;
  };
}

export interface VariableStats {
  empiricalMin: number;
  empiricalMax: number;
  mean: number;
  median: number;
  sd: number;
  quantiles: {
    q10: number;
    q25: number;
    q50: number;
    q75: number;
    q90: number;
  };
  uniqueValues?: number;
  bucketEdges?: number[];
}

export interface RowSumStats {
  variables: string[];
  rowSumMean: number;
  rowSumStd: number;
  rowSumMin: number;
  rowSumMax: number;
  flaggedRows: number; // Count of rows with sum != 100 (±tolerance)
}

export class PreflightGenerator {
  /**
   * Generate a preflight R script based on the table plan
   */
  generatePreflightScript(
    dataFilePath: string,
    tablePlan: TablePlan,
    outputPath: string = 'r/preflight.json'
  ): string {
    const numericVars = this.extractNumericVariables(tablePlan);
    const percentageGroups = this.extractPercentageGroups(tablePlan);
    
    const script = `
# Preflight Analysis Script
# Generated: ${new Date().toISOString()}
# Purpose: Compute empirical statistics for data-driven bucketing

library(haven)
library(jsonlite)
library(dplyr)

# Load data
data <- read_sav("${dataFilePath}")

# Initialize stats container
stats <- list()
stats$variables <- list()
stats$rowSumGroups <- list()

# Helper function for safe statistics
safe_stats <- function(x) {
  x_clean <- na.omit(x)
  if (length(x_clean) == 0) {
    return(list(
      empiricalMin = NA,
      empiricalMax = NA,
      mean = NA,
      median = NA,
      sd = NA,
      quantiles = list(q10=NA, q25=NA, q50=NA, q75=NA, q90=NA),
      uniqueValues = 0
    ))
  }
  
  list(
    empiricalMin = min(x_clean),
    empiricalMax = max(x_clean),
    mean = mean(x_clean),
    median = median(x_clean),
    sd = sd(x_clean),
    quantiles = list(
      q10 = quantile(x_clean, 0.10, na.rm=TRUE)[[1]],
      q25 = quantile(x_clean, 0.25, na.rm=TRUE)[[1]],
      q50 = quantile(x_clean, 0.50, na.rm=TRUE)[[1]],
      q75 = quantile(x_clean, 0.75, na.rm=TRUE)[[1]],
      q90 = quantile(x_clean, 0.90, na.rm=TRUE)[[1]]
    ),
    uniqueValues = length(unique(x_clean))
  )
}

# Compute bucketing edges
compute_buckets <- function(x, n_buckets = 10) {
  x_clean <- na.omit(x)
  if (length(x_clean) == 0) return(NULL)
  
  unique_vals <- unique(x_clean)
  n_unique <- length(unique_vals)
  
  # If 6 or fewer unique values, use them as bucket edges
  if (n_unique <= 6) {
    return(sort(unique_vals))
  }
  
  # Otherwise, create equal-width buckets
  min_val <- min(x_clean)
  max_val <- max(x_clean)
  
  # Handle single value case
  if (min_val == max_val) {
    return(c(min_val))
  }
  
  # Create bucket edges
  seq(min_val, max_val, length.out = n_buckets + 1)
}

# Process numeric variables
numeric_vars <- c(${numericVars.map(v => `"${v}"`).join(', ')})

for (var_name in numeric_vars) {
  if (var_name %in% names(data)) {
    var_stats <- safe_stats(data[[var_name]])
    var_stats$bucketEdges <- compute_buckets(data[[var_name]])
    stats$variables[[var_name]] <- var_stats
  }
}

# Process percentage groups (row sum validation)
${percentageGroups.map(group => `
# Group: ${group.name}
group_vars <- c(${group.variables.map(v => `"${v}"`).join(', ')})
if (all(group_vars %in% names(data))) {
  group_data <- data[, group_vars]
  row_sums <- rowSums(group_data, na.rm = TRUE)
  
  stats$rowSumGroups[["${group.name}"]] <- list(
    variables = group_vars,
    rowSumMean = mean(row_sums, na.rm = TRUE),
    rowSumStd = sd(row_sums, na.rm = TRUE),
    rowSumMin = min(row_sums, na.rm = TRUE),
    rowSumMax = max(row_sums, na.rm = TRUE),
    flaggedRows = sum(abs(row_sums - 100) > 2, na.rm = TRUE)  # Rows not summing to 100 (±2 tolerance)
  )
}
`).join('\n')}

# Add metadata
stats$metadata <- list(
  generatedAt = Sys.time(),
  dataFile = "${dataFilePath}",
  totalVariables = length(stats$variables)
)

# Write output
output_json <- toJSON(stats, auto_unbox = TRUE, pretty = TRUE, na = "null")
writeLines(output_json, "${outputPath}")

cat("Preflight analysis complete. Output written to ${outputPath}\\n")
cat(paste("Analyzed", length(stats$variables), "numeric variables\\n"))
cat(paste("Validated", length(stats$rowSumGroups), "percentage groups\\n"))
`;

    return script.trim();
  }

  /**
   * Extract numeric variables that need preflight analysis
   */
  private extractNumericVariables(tablePlan: TablePlan): string[] {
    const variables: string[] = [];
    
    for (const table of tablePlan.tables) {
      if (table.tableType === 'single') {
        const singleTable = table as SingleTableDefinition;
        
        // Include numeric ranges and percentage variables
        if (singleTable.normalizedType === 'numeric_range' || 
            singleTable.normalizedType === 'percentage_per_option') {
          variables.push(singleTable.questionVar);
        }
      } else if (table.tableType === 'multi_subs') {
        const multiTable = table as MultiSubTableDefinition;
        
        // Include all sub-variables for numeric/percentage groups
        if (multiTable.normalizedType === 'numeric_range' || 
            multiTable.normalizedType === 'percentage_per_option') {
          for (const item of multiTable.items) {
            variables.push(item.var);
          }
        }
      }
    }
    
    return variables;
  }

  /**
   * Extract percentage groups that need row sum validation
   */
  private extractPercentageGroups(tablePlan: TablePlan): Array<{name: string; variables: string[]}> {
    const groups: Array<{name: string; variables: string[]}> = [];
    
    for (const table of tablePlan.tables) {
      if (table.tableType === 'multi_subs') {
        const multiTable = table as MultiSubTableDefinition;
        
        // Check for row sum constraint
        if (multiTable.rowSumConstraint || multiTable.normalizedType === 'percentage_per_option') {
          groups.push({
            name: multiTable.questionVar,
            variables: multiTable.items.map(item => item.var)
          });
        }
      }
    }
    
    return groups;
  }

  /**
   * Parse preflight results to use in master.R generation
   */
  async parsePreflightResults(jsonPath: string): Promise<PreflightStats | null> {
    try {
      const fs = await import('fs/promises');
      const jsonContent = await fs.readFile(jsonPath, 'utf8');
      return JSON.parse(jsonContent) as PreflightStats;
    } catch (error) {
      console.warn(`Could not read preflight results from ${jsonPath}:`, error);
      return null;
    }
  }
}