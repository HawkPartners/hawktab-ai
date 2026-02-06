/**
 * RDataReader.ts
 *
 * Primary data source: reads .sav files via R subprocess.
 * The .sav file is the single source of truth — no CSV datamaps needed.
 *
 * Uses haven::read_sav() + jsonlite::toJSON() to extract:
 * - Column names and row count
 * - Variable labels (question text), value labels (answer options)
 * - SPSS format (data types), stacking indicators
 * - Fill rates for specific columns (loop detection)
 *
 * Also provides convertToRawVariables() to bridge .sav metadata
 * into the DataMapProcessor's enrichment pipeline.
 */

import { spawn } from 'child_process';
import { writeFileSync, unlinkSync, existsSync } from 'fs';
import path from 'path';
import type { DataFileStats, SavVariableMetadata } from './types';
import type { RawDataMapVariable } from '../processors/DataMapProcessor';

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

// =============================================================================
// Structural Suffix Detection (moved from spss-utils.ts)
// =============================================================================

/**
 * Detect structural suffixes that indicate a sub-variable.
 *
 * Patterns (order matters — check most specific first):
 * - r\d+c\d+   → grid cell (S13r1c1)
 * - r\d+oe     → open-ended row (S2r98oe)
 * - r\d+       → row item (S8r1)
 * - c\d+       → column item (standalone column index)
 */
export function hasStructuralSuffix(varName: string): boolean {
  const lower = varName.toLowerCase();
  if (['record', 'uuid', 'date', 'status'].includes(lower)) return false;

  return /r\d+c\d+$/i.test(varName) ||
         /r\d+oe$/i.test(varName) ||
         /r\d+$/i.test(varName) ||
         /c\d+$/i.test(varName);
}

// =============================================================================
// .sav → RawDataMapVariable Conversion
// =============================================================================

/**
 * Convert DataFileStats (from .sav via R) into RawDataMapVariable[] for
 * the DataMapProcessor enrichment pipeline.
 *
 * Maps:
 * - column name → column
 * - variable label → description
 * - value labels → answerOptions (e.g., "1=Yes,2=No")
 * - SPSS format → valueType (Open Text for A-format, Values: min-max for numeric)
 * - structural suffix → level (parent vs sub)
 */
export function convertToRawVariables(stats: DataFileStats): RawDataMapVariable[] {
  return stats.columns.map((col) => {
    const meta: SavVariableMetadata | undefined = stats.variableMetadata?.[col];

    // Answer options from value labels
    let answerOptions = 'NA';
    if (meta?.valueLabels && meta.valueLabels.length > 0) {
      answerOptions = meta.valueLabels
        .map((vl) => `${vl.value}=${vl.label}`)
        .join(',');
    }

    // Value type from SPSS format
    let valueType = '';
    if (meta?.format) {
      if (meta.format.startsWith('A')) {
        valueType = 'Open Text';
      } else if (meta.valueLabels && meta.valueLabels.length > 0) {
        const values = meta.valueLabels.map((vl) => parseFloat(vl.value));
        const min = Math.min(...values);
        const max = Math.max(...values);
        valueType = `Values: ${min}-${max}`;
      }
    }

    const level = hasStructuralSuffix(col) ? 'sub' as const : 'parent' as const;
    const description = meta?.label || '';

    return {
      level,
      column: col,
      description,
      valueType,
      answerOptions,
      parentQuestion: 'NA',
    };
  });
}
