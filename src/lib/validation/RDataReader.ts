/**
 * RDataReader.ts
 *
 * Reads SPSS data files via R subprocess.
 * Follows the exact pattern from DistributionCalculator.ts:136-199.
 *
 * Uses haven::read_sav() + jsonlite::toJSON() to extract:
 * - Column names and row count
 * - Stacking indicator columns (LOOP, ITERATION, etc.)
 * - Fill rates for specific columns (loop detection)
 */

import { spawn } from 'child_process';
import { writeFileSync, unlinkSync, existsSync } from 'fs';
import path from 'path';
import type { DataFileStats } from './types';

// =============================================================================
// R Path Discovery
// =============================================================================

const R_PATHS = [
  '/opt/homebrew/bin/Rscript',
  '/usr/local/bin/Rscript',
  '/usr/bin/Rscript',
  'Rscript',
];

function findRCommand(): string {
  for (const rPath of R_PATHS) {
    if (rPath === 'Rscript' || existsSync(rPath)) {
      return rPath;
    }
  }
  return 'Rscript';
}

// =============================================================================
// R Script Execution
// =============================================================================

async function executeRScript(
  scriptContent: string,
  scriptPath: string
): Promise<string> {
  writeFileSync(scriptPath, scriptContent);
  const rCommand = findRCommand();

  return new Promise((resolve, reject) => {
    const proc = spawn(rCommand, [scriptPath]);
    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (d) => (stdout += d));
    proc.stderr.on('data', (d) => (stderr += d));

    proc.on('close', (code) => {
      // Clean up script file
      try {
        unlinkSync(scriptPath);
      } catch {
        // Ignore cleanup errors
      }

      if (code !== 0) {
        reject(new Error(`R script failed (code ${code}): ${stderr}`));
      } else {
        resolve(stdout);
      }
    });

    proc.on('error', (err) => {
      try {
        unlinkSync(scriptPath);
      } catch {
        // Ignore cleanup errors
      }
      reject(new Error(`Failed to spawn R process: ${err.message}`));
    });
  });
}

// =============================================================================
// Public API
// =============================================================================

/**
 * Get basic stats about a data file: columns, row count, stacking columns.
 */
export async function getDataFileStats(
  dataPath: string,
  outputDir: string
): Promise<DataFileStats> {
  const escapedPath = dataPath.replace(/\\/g, '/');
  const scriptPath = path.join(outputDir, '_validation_stats.R');

  const script = `
suppressMessages(library(haven))
suppressMessages(library(jsonlite))

data <- read_sav("${escapedPath}")
cols <- colnames(data)

# Detect stacking indicator columns
stacking_patterns <- c("LOOP", "ITERATION", "ITER", "STACK", "REPEAT", "WAVE")
stacking_cols <- cols[toupper(cols) %in% stacking_patterns]

# Extract per-column metadata (labels, value labels, format)
metadata <- lapply(cols, function(col_name) {
  col <- data[[col_name]]
  lbl <- attr(col, "label")
  vl <- attr(col, "labels")
  fmt <- attr(col, "format.spss")

  value_labels <- list()
  if (!is.null(vl)) {
    value_labels <- mapply(function(v, l) {
      list(value = as.character(v), label = l)
    }, vl, names(vl), SIMPLIFY = FALSE, USE.NAMES = FALSE)
  }

  list(
    column = col_name,
    label = ifelse(is.null(lbl), "", lbl),
    format = ifelse(is.null(fmt), "", fmt),
    valueLabels = value_labels
  )
})
names(metadata) <- cols

result <- list(
  rowCount = nrow(data),
  columns = cols,
  stackingColumns = stacking_cols,
  variableMetadata = metadata
)

cat(toJSON(result, auto_unbox = TRUE))
`;

  const stdout = await executeRScript(script, scriptPath);

  try {
    return JSON.parse(stdout) as DataFileStats;
  } catch {
    throw new Error(`Failed to parse R output for data stats: ${stdout.substring(0, 200)}`);
  }
}

/**
 * Get fill rates for specific columns.
 * Returns the proportion of non-NA values for each column.
 * Only requests the specified columns to avoid performance issues on large files.
 */
export async function getColumnFillRates(
  dataPath: string,
  columns: string[],
  outputDir: string
): Promise<Record<string, number>> {
  if (columns.length === 0) return {};

  const escapedPath = dataPath.replace(/\\/g, '/');
  const colsArray = columns.map((c) => `"${c}"`).join(', ');
  const scriptPath = path.join(outputDir, '_validation_fillrates.R');

  const script = `
suppressMessages(library(haven))
suppressMessages(library(jsonlite))

data <- read_sav("${escapedPath}")
cols_to_check <- c(${colsArray})

# Only check columns that exist in the data
existing_cols <- intersect(cols_to_check, colnames(data))

fill_rates <- list()
n <- nrow(data)

for (col in existing_cols) {
  non_na <- sum(!is.na(data[[col]]))
  fill_rates[[col]] <- non_na / n
}

cat(toJSON(fill_rates, auto_unbox = TRUE))
`;

  const stdout = await executeRScript(script, scriptPath);

  try {
    return JSON.parse(stdout) as Record<string, number>;
  } catch {
    throw new Error(`Failed to parse R output for fill rates: ${stdout.substring(0, 200)}`);
  }
}

/**
 * Check if R and haven are available.
 */
export async function checkRAvailability(outputDir: string): Promise<boolean> {
  const scriptPath = path.join(outputDir, '_validation_check.R');
  const script = `suppressMessages(library(haven)); cat("ok")`;

  try {
    const stdout = await executeRScript(script, scriptPath);
    return stdout.trim() === 'ok';
  } catch {
    return false;
  }
}
