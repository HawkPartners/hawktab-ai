#!/usr/bin/env npx tsx
/**
 * Validate NET Base Fix
 *
 * Purpose: Generate R code for mean_rows tables with known differential missingness,
 * run it against actual .sav data, and verify that NET bases now equal nrow(cut_data)
 * instead of sum(!is.na(first_component)).
 *
 * This validates the fix applied to RScriptGeneratorV2.ts (Points 1 & 2).
 *
 * No AI calls — deterministic + R execution. Safe to run.
 *
 * Usage:
 *   npx tsx scripts/validate-net-base-fix.ts
 *   npx tsx scripts/validate-net-base-fix.ts data/test-data/titos-growth-strategy
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import { validate } from '../src/lib/validation/ValidationRunner';
import { groupDataMap } from '../src/lib/tables/DataMapGrouper';
import { generateTables, convertToLegacyFormat } from '../src/lib/tables/TableGenerator';
import { toExtendedTable } from '../src/schemas/verificationAgentSchema';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';
import type { ExtendedTableDefinition, ExtendedTableRow } from '../src/schemas/verificationAgentSchema';

const execAsync = promisify(exec);

const COLORS = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
  magenta: '\x1b[35m',
};

function log(message: string, color: keyof typeof COLORS = 'reset') {
  console.log(`${COLORS[color]}${message}${COLORS.reset}`);
}

async function findR(): Promise<string> {
  const rPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
  for (const rPath of rPaths) {
    try {
      await execAsync(`${rPath} --version`, { timeout: 2000 });
      return rPath;
    } catch { /* try next */ }
  }
  throw new Error('Rscript not found');
}

async function findSavFiles(folderPath: string): Promise<string[]> {
  const savFiles: string[] = [];
  for (const subdir of ['', 'inputs']) {
    const searchDir = subdir ? path.join(folderPath, subdir) : folderPath;
    try {
      const files = await fs.readdir(searchDir);
      for (const f of files) {
        if (f.endsWith('.sav')) savFiles.push(path.join(searchDir, f));
      }
    } catch { /* skip */ }
  }
  return savFiles;
}

interface MeanRowsTableWithNet {
  tableId: string;
  questionId: string;
  allVariables: string[];
  // Synthetic NET we'll create for testing (all variables as components)
  netLabel: string;
  netComponents: string[];
}

/**
 * Generate a minimal R script that tests the new NET computation logic
 * for a specific table against the actual .sav data.
 */
function generateTestR(
  spssPath: string,
  tables: MeanRowsTableWithNet[],
): string {
  const lines: string[] = [
    'suppressMessages(library(haven))',
    `d <- read_sav("${spssPath.replace(/\\/g, '/')}")`,
    'total_n <- nrow(d)',
    'cat(paste0("TOTAL_N:", total_n, "\\n"))',
    '',
    '# Helper: safe variable access',
    'safe_get_var <- function(data, varname) {',
    '  if (varname %in% colnames(data)) return(data[[varname]])',
    '  return(NULL)',
    '}',
    '',
    'round_half_up <- function(x, digits = 0) {',
    '  posmult <- x * 10^digits',
    '  round(posmult + 1e-10) / 10^digits',
    '}',
    '',
  ];

  for (const table of tables) {
    const componentVars = table.netComponents.map(v => `"${v}"`).join(', ');

    lines.push(`# === Table: ${table.tableId} (${table.questionId}) ===`);
    lines.push(`net_vars <- c(${componentVars})`);
    lines.push('');

    // OLD method: sum of means, base = first component non-NA
    lines.push('# OLD method: sum-of-means, base = sum(!is.na(first_component))');
    lines.push('old_component_means <- sapply(net_vars, function(v) {');
    lines.push('  col <- safe_get_var(d, v)');
    lines.push('  if (!is.null(col)) mean(col, na.rm = TRUE) else NA');
    lines.push('})');
    lines.push('old_net_mean <- if (all(is.na(old_component_means))) NA else round_half_up(sum(old_component_means, na.rm = TRUE), 1)');
    lines.push('old_first_col <- safe_get_var(d, net_vars[1])');
    lines.push('old_n <- if (!is.null(old_first_col)) sum(!is.na(old_first_col)) else 0');
    lines.push('');

    // NEW method: mean of row-sums, base = nrow(cut_data)
    lines.push('# NEW method: mean-of-row-sums, base = nrow(data)');
    lines.push('net_cols <- lapply(net_vars, function(v) {');
    lines.push('  col <- safe_get_var(d, v)');
    lines.push('  if (!is.null(col)) as.numeric(col) else rep(NA_real_, nrow(d))');
    lines.push('})');
    lines.push('net_matrix <- do.call(cbind, net_cols)');
    lines.push('row_all_na <- apply(net_matrix, 1, function(r) all(is.na(r)))');
    lines.push('row_sums <- rowSums(net_matrix, na.rm = TRUE)');
    lines.push('row_sums[row_all_na] <- NA');
    lines.push('new_net_mean <- if (all(is.na(row_sums))) NA else round_half_up(mean(row_sums, na.rm = TRUE), 1)');
    lines.push('new_n <- nrow(d)');
    lines.push('');

    // Per-component non-NA counts (for context)
    lines.push('comp_counts <- sapply(net_vars, function(v) {');
    lines.push('  col <- safe_get_var(d, v)');
    lines.push('  if (!is.null(col)) sum(!is.na(col)) else 0');
    lines.push('})');
    lines.push('');

    // Output
    lines.push(`cat(paste0("TABLE:${table.tableId}\\n"))`);
    lines.push(`cat(paste0("  question: ${table.questionId}\\n"))`);
    lines.push('cat(paste0("  components: ", length(net_vars), "\\n"))');
    lines.push('cat(paste0("  OLD base: ", old_n, "\\n"))');
    lines.push('cat(paste0("  NEW base: ", new_n, "\\n"))');
    lines.push('cat(paste0("  OLD mean: ", old_net_mean, "\\n"))');
    lines.push('cat(paste0("  NEW mean: ", new_net_mean, "\\n"))');
    lines.push('cat(paste0("  base_match: ", old_n == new_n, "\\n"))');
    lines.push('cat(paste0("  base_diff: ", new_n - old_n, "\\n"))');
    lines.push('# Component non-NA counts');
    lines.push('for (i in seq_along(net_vars)) {');
    lines.push('  cat(paste0("  comp:", net_vars[i], ":", comp_counts[i], "\\n"))');
    lines.push('}');
    lines.push('cat("\\n")');
    lines.push('');
  }

  return lines.join('\n');
}

interface TableResult {
  tableId: string;
  questionId: string;
  oldBase: number;
  newBase: number;
  oldMean: number | null;
  newMean: number | null;
  baseDiff: number;
  baseMatch: boolean;
  componentCounts: { variable: string; nonNA: number }[];
}

function parseROutput(stdout: string): { totalN: number; tables: TableResult[] } {
  let totalN = 0;
  const tables: TableResult[] = [];
  let current: Partial<TableResult> & { componentCounts: { variable: string; nonNA: number }[] } = { componentCounts: [] };

  for (const line of stdout.split('\n')) {
    const trimmed = line.trim();
    if (trimmed.startsWith('TOTAL_N:')) {
      totalN = parseInt(trimmed.split(':')[1], 10);
    } else if (trimmed.startsWith('TABLE:')) {
      if (current.tableId) {
        tables.push(current as TableResult);
      }
      current = { tableId: trimmed.split(':')[1], componentCounts: [] };
    } else if (trimmed.startsWith('question:')) {
      current.questionId = trimmed.split(': ')[1];
    } else if (trimmed.startsWith('OLD base:')) {
      current.oldBase = parseInt(trimmed.split(': ')[1], 10);
    } else if (trimmed.startsWith('NEW base:')) {
      current.newBase = parseInt(trimmed.split(': ')[1], 10);
    } else if (trimmed.startsWith('OLD mean:')) {
      const val = trimmed.split(': ')[1];
      current.oldMean = val === 'NA' ? null : parseFloat(val);
    } else if (trimmed.startsWith('NEW mean:')) {
      const val = trimmed.split(': ')[1];
      current.newMean = val === 'NA' ? null : parseFloat(val);
    } else if (trimmed.startsWith('base_match:')) {
      current.baseMatch = trimmed.split(': ')[1] === 'TRUE';
    } else if (trimmed.startsWith('base_diff:')) {
      current.baseDiff = parseInt(trimmed.split(': ')[1], 10);
    } else if (trimmed.startsWith('comp:')) {
      const parts = trimmed.split(':');
      current.componentCounts.push({ variable: parts[1], nonNA: parseInt(parts[2], 10) });
    }
  }
  if (current.tableId) {
    tables.push(current as TableResult);
  }

  return { totalN, tables };
}

async function main() {
  const startTime = Date.now();

  log('='.repeat(70), 'magenta');
  log('  NET Base Fix Validation', 'bright');
  log('  Comparing OLD vs NEW NET computation on real data', 'dim');
  log('='.repeat(70), 'magenta');
  log('', 'reset');

  const rCommand = await findR();

  // Discover datasets
  const searchPath = process.argv[2]
    ? (path.isAbsolute(process.argv[2]) ? process.argv[2] : path.join(process.cwd(), process.argv[2]))
    : undefined;

  const testDataDir = path.join(process.cwd(), 'data', 'test-data');
  let datasets: { name: string; folderPath: string }[] = [];

  if (searchPath) {
    datasets = [{ name: path.basename(searchPath), folderPath: searchPath }];
  } else {
    const folders = await fs.readdir(testDataDir);
    for (const folder of folders) {
      const folderPath = path.join(testDataDir, folder);
      const stat = await fs.stat(folderPath).catch(() => null);
      if (stat?.isDirectory()) {
        datasets.push({ name: folder, folderPath });
      }
    }
    // Add primary dataset
    const leqvioPath = path.join(process.cwd(), 'data', 'leqvio-monotherapy-demand-NOV217');
    try { await fs.stat(leqvioPath); datasets.push({ name: 'leqvio-monotherapy-demand-NOV217', folderPath: leqvioPath }); } catch { /* skip */ }
  }

  log(`Found ${datasets.length} datasets`, 'blue');
  log('', 'reset');

  const tmpDir = path.join(process.cwd(), '.tmp-validate');
  await fs.mkdir(tmpDir, { recursive: true });

  const allResults: { name: string; totalN: number; tables: TableResult[]; error?: string }[] = [];
  let totalFixed = 0;
  let totalTables = 0;

  for (let di = 0; di < datasets.length; di++) {
    const dataset = datasets[di];
    log(`[${di + 1}/${datasets.length}] ${dataset.name}...`, 'cyan');

    try {
      // Find .sav
      const savFiles = await findSavFiles(dataset.folderPath);
      if (savFiles.length === 0) {
        log(`  No .sav file — skipped`, 'dim');
        continue;
      }

      // Load datamap
      const validationResult = await validate({ spssPath: savFiles[0], outputDir: tmpDir });
      if (!validationResult.processingResult) {
        log(`  Validation failed — skipped`, 'red');
        allResults.push({ name: dataset.name, totalN: 0, tables: [], error: 'Validation failed' });
        continue;
      }

      const verboseDataMap = validationResult.processingResult.verbose as VerboseDataMapType[];

      // Run TableGenerator
      const groups = groupDataMap(verboseDataMap);
      const generatedOutputs = generateTables(groups);
      const tableResults = convertToLegacyFormat(generatedOutputs);

      // Find mean_rows tables and create synthetic NET for each
      const testTables: MeanRowsTableWithNet[] = [];
      for (const group of tableResults) {
        for (const table of group.tables) {
          if (table.tableType === 'mean_rows' && table.rows.length >= 2) {
            testTables.push({
              tableId: table.tableId,
              questionId: group.questionId,
              allVariables: table.rows.map(r => r.variable),
              netLabel: `${group.questionId} NET (all)`,
              netComponents: table.rows.map(r => r.variable),
            });
          }
        }
      }

      if (testTables.length === 0) {
        log(`  No mean_rows tables — skipped`, 'dim');
        continue;
      }

      // Generate and run R test script
      const rScript = generateTestR(savFiles[0], testTables);
      const tmpScript = path.join(tmpDir, `test-${dataset.name.replace(/[^a-zA-Z0-9]/g, '_')}.R`);
      await fs.writeFile(tmpScript, rScript, 'utf-8');

      const { stdout } = await execAsync(`${rCommand} "${tmpScript}"`, {
        maxBuffer: 10 * 1024 * 1024,
        timeout: 30000,
      });

      const parsed = parseROutput(stdout);
      allResults.push({ name: dataset.name, totalN: parsed.totalN, tables: parsed.tables });

      // Count fixed tables
      const fixedTables = parsed.tables.filter(t => !t.baseMatch);
      totalFixed += fixedTables.length;
      totalTables += parsed.tables.length;

      if (fixedTables.length === 0) {
        log(`  ${parsed.tables.length} tables — all bases already matched (N=${parsed.totalN})`, 'green');
      } else {
        log(`  ${fixedTables.length}/${parsed.tables.length} tables FIXED (N=${parsed.totalN})`, 'yellow');
        for (const t of fixedTables.slice(0, 3)) {
          const meanChange = t.oldMean !== null && t.newMean !== null
            ? ` | mean: ${t.oldMean} → ${t.newMean}`
            : '';
          log(`    ${t.tableId}: base ${t.oldBase} → ${t.newBase} (+${t.baseDiff})${meanChange}`, 'dim');
        }
        if (fixedTables.length > 3) {
          log(`    ... and ${fixedTables.length - 3} more`, 'dim');
        }
      }
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      log(`  ERROR: ${errMsg.substring(0, 120)}`, 'red');
      allResults.push({ name: dataset.name, totalN: 0, tables: [], error: errMsg });
    }
  }

  // Cleanup
  await fs.rm(tmpDir, { recursive: true }).catch(() => {});

  // Summary
  log('', 'reset');
  log('='.repeat(70), 'magenta');
  log('  Validation Summary', 'bright');
  log('='.repeat(70), 'magenta');
  log(`  Datasets tested:      ${allResults.length}`, 'reset');
  log(`  Total mean_rows tables: ${totalTables}`, 'reset');
  log(`  Tables where fix changes base: ${totalFixed}`, totalFixed > 0 ? 'yellow' : 'green');
  log(`  Tables already correct:        ${totalTables - totalFixed}`, 'green');
  log('', 'reset');

  if (totalFixed > 0) {
    log('The fix changes NET base computation for these tables.', 'yellow');
    log('OLD: base = sum(!is.na(first_component)) — component-specific, potentially wrong', 'dim');
    log('NEW: base = nrow(cut_data) — table base, always correct', 'dim');
  } else {
    log('No tables had base discrepancies — fix is a no-op on these datasets.', 'green');
  }

  // Save results
  const auditTimestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const auditDir = path.join(process.cwd(), 'outputs', 'audits');
  await fs.mkdir(auditDir, { recursive: true });

  const jsonOutput = {
    audit: 'net-base-fix-validation',
    timestamp: new Date().toISOString(),
    durationMs: Date.now() - startTime,
    summary: {
      datasetsCount: allResults.length,
      totalMeanRowsTables: totalTables,
      tablesFixChangesBase: totalFixed,
      tablesAlreadyCorrect: totalTables - totalFixed,
    },
    results: allResults.map(r => ({
      name: r.name,
      totalN: r.totalN,
      error: r.error || null,
      tablesTotal: r.tables.length,
      tablesFixed: r.tables.filter(t => !t.baseMatch).length,
      tables: r.tables.map(t => ({
        tableId: t.tableId,
        questionId: t.questionId,
        oldBase: t.oldBase,
        newBase: t.newBase,
        baseDiff: t.baseDiff,
        oldMean: t.oldMean,
        newMean: t.newMean,
        componentCounts: t.componentCounts,
      })),
    })),
  };

  const jsonPath = path.join(auditDir, `net-base-fix-validation-${auditTimestamp}.json`);
  await fs.writeFile(jsonPath, JSON.stringify(jsonOutput, null, 2), 'utf-8');

  // Human-readable report
  const reportLines: string[] = [
    'NET Base Fix Validation Report',
    '='.repeat(70),
    `Date: ${new Date().toISOString()}`,
    `Duration: ${((Date.now() - startTime) / 1000).toFixed(1)}s`,
    '',
    'SUMMARY',
    '-'.repeat(40),
    `Datasets tested:             ${allResults.length}`,
    `Total mean_rows tables:      ${totalTables}`,
    `Tables where fix changes base: ${totalFixed}`,
    `Tables already correct:        ${totalTables - totalFixed}`,
    '',
    'FIX DESCRIPTION',
    '-'.repeat(40),
    'Point 1: NET base = nrow(cut_data) instead of sum(!is.na(first_component))',
    'Point 2: NET mean = mean of per-respondent row-sums instead of sum of component means',
    '',
    'DETAIL BY DATASET',
    '-'.repeat(40),
  ];

  for (const r of allResults) {
    if (r.error) {
      reportLines.push(`[ERROR] ${r.name}: ${r.error}`);
      continue;
    }
    if (r.tables.length === 0) continue;

    const fixed = r.tables.filter(t => !t.baseMatch);
    if (fixed.length === 0) {
      reportLines.push(`[OK]    ${r.name}: ${r.tables.length} tables, all bases correct (N=${r.totalN})`);
    } else {
      reportLines.push(`[FIXED] ${r.name}: ${fixed.length}/${r.tables.length} tables had wrong base (N=${r.totalN})`);
      for (const t of fixed) {
        const meanStr = t.oldMean !== null && t.newMean !== null
          ? ` | mean: ${t.oldMean} → ${t.newMean}`
          : '';
        reportLines.push(`          ${t.tableId} (${t.questionId}): base ${t.oldBase} → ${t.newBase}${meanStr}`);
        // Show worst component discrepancy
        if (t.componentCounts.length > 0) {
          const worst = t.componentCounts.reduce((a, b) => a.nonNA < b.nonNA ? a : b);
          reportLines.push(`            worst component: ${worst.variable} = ${worst.nonNA}/${t.newBase} non-NA`);
        }
      }
    }
  }

  const reportPath = path.join(auditDir, `net-base-fix-validation-${auditTimestamp}.txt`);
  await fs.writeFile(reportPath, reportLines.join('\n'), 'utf-8');

  log('', 'reset');
  log('Output saved:', 'blue');
  log(`  ${path.relative(process.cwd(), jsonPath)}`, 'dim');
  log(`  ${path.relative(process.cwd(), reportPath)}`, 'dim');
  log(`Duration: ${((Date.now() - startTime) / 1000).toFixed(1)}s`, 'dim');
}

main().catch((error) => {
  console.error('Validation failed:', error);
  process.exit(1);
});
