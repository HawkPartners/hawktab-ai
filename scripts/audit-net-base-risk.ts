#!/usr/bin/env npx tsx
/**
 * NET Base Risk Audit
 *
 * Purpose: Scan all test datasets to identify mean_rows tables where the current
 * NET base computation (sum(!is.na(first_component))) would produce a different
 * base than nrow(cut_data). This detects the S9-style bug across all datasets.
 *
 * No AI calls — purely deterministic. Safe to run.
 *
 * Usage:
 *   npx tsx scripts/audit-net-base-risk.ts
 *   npx tsx scripts/audit-net-base-risk.ts data/test-data/titos-growth-strategy
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
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';

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

// Find Rscript binary
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

interface MeanRowsTable {
  tableId: string;
  questionId: string;
  variables: string[];  // all row variables in this table
}

interface DatasetResult {
  name: string;
  spssPath: string;
  totalN: number;
  meanRowsTables: number;
  atRiskTables: AtRiskTable[];
  error?: string;
}

interface AtRiskTable {
  tableId: string;
  questionId: string;
  totalN: number;
  variables: VariableNAInfo[];
}

interface VariableNAInfo {
  variable: string;
  nonNACount: number;
  naCount: number;
  pctMissing: number;
}

async function discoverDatasets(searchPath?: string): Promise<{ name: string; spssPath: string }[]> {
  const datasets: { name: string; spssPath: string }[] = [];

  if (searchPath) {
    // Single dataset
    const name = path.basename(searchPath);
    const savFiles = await findSavFiles(searchPath);
    if (savFiles.length > 0) {
      datasets.push({ name, spssPath: savFiles[0] });
    }
    return datasets;
  }

  // Scan data/test-data/
  const testDataDir = path.join(process.cwd(), 'data', 'test-data');
  const folders = await fs.readdir(testDataDir);

  for (const folder of folders) {
    const folderPath = path.join(testDataDir, folder);
    const stat = await fs.stat(folderPath).catch(() => null);
    if (!stat?.isDirectory()) continue;

    const savFiles = await findSavFiles(folderPath);
    if (savFiles.length > 0) {
      datasets.push({ name: folder, spssPath: savFiles[0] });
    }
  }

  // Also check the primary dataset and stacked data example
  for (const extra of ['data/leqvio-monotherapy-demand-NOV217', 'data/stacked-data-example']) {
    const extraPath = path.join(process.cwd(), extra);
    try {
      const savFiles = await findSavFiles(extraPath);
      if (savFiles.length > 0) {
        datasets.push({ name: path.basename(extraPath), spssPath: savFiles[0] });
      }
    } catch { /* skip if not found */ }
  }

  return datasets;
}

async function findSavFiles(folderPath: string): Promise<string[]> {
  // Check root and inputs/ subdirectory
  const savFiles: string[] = [];

  for (const subdir of ['', 'inputs']) {
    const searchDir = subdir ? path.join(folderPath, subdir) : folderPath;
    try {
      const files = await fs.readdir(searchDir);
      for (const f of files) {
        if (f.endsWith('.sav')) {
          savFiles.push(path.join(searchDir, f));
        }
      }
    } catch { /* dir doesn't exist */ }
  }

  return savFiles;
}

async function getMeanRowsTables(verboseDataMap: VerboseDataMapType[]): Promise<MeanRowsTable[]> {
  const groups = groupDataMap(verboseDataMap);
  const generatedOutputs = generateTables(groups);
  const tableResults = convertToLegacyFormat(generatedOutputs);

  const meanRowsTables: MeanRowsTable[] = [];

  for (const group of tableResults) {
    for (const table of group.tables) {
      if (table.tableType === 'mean_rows') {
        meanRowsTables.push({
          tableId: table.tableId,
          questionId: group.questionId,
          variables: table.rows.map(r => r.variable),
        });
      }
    }
  }

  return meanRowsTables;
}

async function checkNACounts(
  rCommand: string,
  spssPath: string,
  variables: string[],
): Promise<{ totalN: number; variableCounts: Map<string, number> }> {
  // Generate R script that loads the .sav and reports non-NA counts for specified variables
  const varList = variables.map(v => `"${v}"`).join(', ');
  const rScript = `
suppressMessages(library(haven))
d <- read_sav("${spssPath.replace(/\\/g, '/')}")
total_n <- nrow(d)
cat(paste0("TOTAL_N:", total_n, "\\n"))
vars <- c(${varList})
for (v in vars) {
  if (v %in% colnames(d)) {
    non_na <- sum(!is.na(d[[v]]))
    cat(paste0("VAR:", v, ":", non_na, "\\n"))
  } else {
    cat(paste0("VAR:", v, ":MISSING\\n"))
  }
}
`;

  const tmpScript = path.join(process.cwd(), '.tmp-audit-na.R');
  await fs.writeFile(tmpScript, rScript, 'utf-8');

  try {
    const { stdout } = await execAsync(`${rCommand} "${tmpScript}"`, {
      maxBuffer: 10 * 1024 * 1024,
      timeout: 30000,
    });

    let totalN = 0;
    const variableCounts = new Map<string, number>();

    for (const line of stdout.split('\n')) {
      if (line.startsWith('TOTAL_N:')) {
        totalN = parseInt(line.split(':')[1], 10);
      } else if (line.startsWith('VAR:')) {
        const parts = line.split(':');
        const varName = parts[1];
        const count = parts[2] === 'MISSING' ? -1 : parseInt(parts[2], 10);
        variableCounts.set(varName, count);
      }
    }

    return { totalN, variableCounts };
  } finally {
    await fs.unlink(tmpScript).catch(() => {});
  }
}

async function auditDataset(
  rCommand: string,
  dataset: { name: string; spssPath: string },
  tmpDir: string,
): Promise<DatasetResult> {
  try {
    // Step 1: Load datamap via validation
    const validationResult = await validate({ spssPath: dataset.spssPath, outputDir: tmpDir });
    if (!validationResult.processingResult) {
      return {
        name: dataset.name,
        spssPath: dataset.spssPath,
        totalN: 0,
        meanRowsTables: 0,
        atRiskTables: [],
        error: 'Validation failed — no processing result',
      };
    }

    const verboseDataMap = validationResult.processingResult.verbose as VerboseDataMapType[];

    // Step 2: Run TableGenerator (deterministic)
    const meanRowsTables = await getMeanRowsTables(verboseDataMap);

    if (meanRowsTables.length === 0) {
      return {
        name: dataset.name,
        spssPath: dataset.spssPath,
        totalN: 0,
        meanRowsTables: 0,
        atRiskTables: [],
      };
    }

    // Step 3: Collect all unique variables from mean_rows tables
    const allVars = new Set<string>();
    for (const table of meanRowsTables) {
      for (const v of table.variables) {
        allVars.add(v);
      }
    }

    // Step 4: Check NA counts via R (single call for all variables)
    const { totalN, variableCounts } = await checkNACounts(
      rCommand,
      dataset.spssPath,
      Array.from(allVars),
    );

    // Step 5: Identify at-risk tables
    const atRiskTables: AtRiskTable[] = [];

    for (const table of meanRowsTables) {
      const varInfos: VariableNAInfo[] = [];
      let hasRisk = false;

      for (const variable of table.variables) {
        const nonNACount = variableCounts.get(variable);
        if (nonNACount === undefined || nonNACount === -1) continue;

        const naCount = totalN - nonNACount;
        const pctMissing = totalN > 0 ? (naCount / totalN) * 100 : 0;

        varInfos.push({ variable, nonNACount, naCount, pctMissing });

        // Flag if non-NA count differs from total N by more than 1%
        if (pctMissing > 1) {
          hasRisk = true;
        }
      }

      if (hasRisk) {
        atRiskTables.push({
          tableId: table.tableId,
          questionId: table.questionId,
          totalN,
          variables: varInfos.filter(v => v.pctMissing > 1),
        });
      }
    }

    return {
      name: dataset.name,
      spssPath: dataset.spssPath,
      totalN,
      meanRowsTables: meanRowsTables.length,
      atRiskTables,
    };
  } catch (error) {
    return {
      name: dataset.name,
      spssPath: dataset.spssPath,
      totalN: 0,
      meanRowsTables: 0,
      atRiskTables: [],
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

async function main() {
  const startTime = Date.now();

  log('='.repeat(70), 'magenta');
  log('  NET Base Risk Audit', 'bright');
  log('  Scanning datasets for mean_rows tables with differential missingness', 'dim');
  log('='.repeat(70), 'magenta');
  log('', 'reset');

  const rCommand = await findR();
  log(`Using R: ${rCommand}`, 'dim');

  // Discover datasets
  const searchPath = process.argv[2]
    ? (path.isAbsolute(process.argv[2]) ? process.argv[2] : path.join(process.cwd(), process.argv[2]))
    : undefined;

  const datasets = await discoverDatasets(searchPath);
  log(`Found ${datasets.length} datasets to audit`, 'blue');
  log('', 'reset');

  // Create tmp dir for validation artifacts
  const tmpDir = path.join(process.cwd(), '.tmp-audit');
  await fs.mkdir(tmpDir, { recursive: true });

  // Audit each dataset
  const results: DatasetResult[] = [];

  for (let i = 0; i < datasets.length; i++) {
    const dataset = datasets[i];
    log(`[${i + 1}/${datasets.length}] ${dataset.name}...`, 'cyan');

    const result = await auditDataset(rCommand, dataset, tmpDir);
    results.push(result);

    if (result.error) {
      log(`  ERROR: ${result.error}`, 'red');
    } else if (result.meanRowsTables === 0) {
      log(`  No mean_rows tables — skipped`, 'dim');
    } else if (result.atRiskTables.length === 0) {
      log(`  ${result.meanRowsTables} mean_rows tables — all OK (N=${result.totalN})`, 'green');
    } else {
      log(`  ${result.meanRowsTables} mean_rows tables — ${result.atRiskTables.length} AT RISK (N=${result.totalN})`, 'yellow');
      for (const table of result.atRiskTables) {
        const worstVar = table.variables.reduce((a, b) => a.pctMissing > b.pctMissing ? a : b);
        log(`    ${table.tableId}: ${table.variables.length} vars with >1% missing (worst: ${worstVar.variable} at ${worstVar.pctMissing.toFixed(1)}% missing, n=${worstVar.nonNACount} vs N=${table.totalN})`, 'yellow');
      }
    }
  }

  // Cleanup
  await fs.rm(tmpDir, { recursive: true }).catch(() => {});

  // Compute summary stats
  const withMeanRows = results.filter(r => r.meanRowsTables > 0 && !r.error);
  const atRisk = results.filter(r => r.atRiskTables.length > 0);
  const clean = withMeanRows.filter(r => r.atRiskTables.length === 0);
  const errored = results.filter(r => r.error);
  const duration = Date.now() - startTime;

  // Summary to console
  log('', 'reset');
  log('='.repeat(70), 'magenta');
  log('  Summary', 'bright');
  log('='.repeat(70), 'magenta');

  log(`  Total datasets:       ${results.length}`, 'reset');
  log(`  With mean_rows:       ${withMeanRows.length}`, 'reset');
  log(`  Clean (no risk):      ${clean.length}`, 'green');
  log(`  AT RISK:              ${atRisk.length}`, atRisk.length > 0 ? 'yellow' : 'green');
  log(`  Errors:               ${errored.length}`, errored.length > 0 ? 'red' : 'dim');
  log('', 'reset');

  if (atRisk.length > 0) {
    log('AT-RISK DATASETS:', 'yellow');
    for (const r of atRisk) {
      log(`  ${r.name}:`, 'yellow');
      for (const table of r.atRiskTables) {
        log(`    ${table.tableId} (${table.questionId}): ${table.variables.length} vars, N=${table.totalN}`, 'yellow');
        for (const v of table.variables.slice(0, 5)) {
          log(`      ${v.variable}: ${v.nonNACount}/${table.totalN} non-NA (${v.pctMissing.toFixed(1)}% missing)`, 'dim');
        }
        if (table.variables.length > 5) {
          log(`      ... and ${table.variables.length - 5} more`, 'dim');
        }
      }
    }
    log('', 'reset');
    log('These datasets have mean_rows tables where component variables have', 'yellow');
    log('significantly different non-NA counts from total N. A NET row using', 'yellow');
    log('sum(!is.na(first_component)) as base would produce wrong numbers.', 'yellow');
  } else if (withMeanRows.length > 0) {
    log('All datasets with mean_rows tables are clean — no base discrepancy risk.', 'green');
  }

  // =========================================================================
  // Save output
  // =========================================================================
  const auditTimestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const auditDir = path.join(process.cwd(), 'outputs', 'audits');
  await fs.mkdir(auditDir, { recursive: true });

  // JSON (full data)
  const jsonOutput = {
    audit: 'net-base-risk',
    timestamp: new Date().toISOString(),
    durationMs: duration,
    summary: {
      totalDatasets: results.length,
      withMeanRows: withMeanRows.length,
      clean: clean.length,
      atRisk: atRisk.length,
      errored: errored.length,
    },
    results: results.map(r => ({
      name: r.name,
      totalN: r.totalN,
      meanRowsTables: r.meanRowsTables,
      atRiskTables: r.atRiskTables,
      error: r.error || null,
    })),
  };

  const jsonPath = path.join(auditDir, `net-base-risk-${auditTimestamp}.json`);
  await fs.writeFile(jsonPath, JSON.stringify(jsonOutput, null, 2), 'utf-8');

  // Human-readable report
  const reportLines: string[] = [
    'NET Base Risk Audit Report',
    '='.repeat(70),
    `Date: ${new Date().toISOString()}`,
    `Duration: ${(duration / 1000).toFixed(1)}s`,
    '',
    'SUMMARY',
    '-'.repeat(40),
    `Total datasets:       ${results.length}`,
    `With mean_rows:       ${withMeanRows.length}`,
    `Clean (no risk):      ${clean.length}`,
    `AT RISK:              ${atRisk.length}`,
    `Errors:               ${errored.length}`,
    '',
  ];

  // Per-dataset details
  reportLines.push('DATASET DETAILS', '-'.repeat(40));
  for (const r of results) {
    if (r.error) {
      reportLines.push(`[ERROR] ${r.name}: ${r.error}`);
    } else if (r.meanRowsTables === 0) {
      reportLines.push(`[SKIP]  ${r.name}: No mean_rows tables`);
    } else if (r.atRiskTables.length === 0) {
      reportLines.push(`[OK]    ${r.name}: ${r.meanRowsTables} mean_rows tables, N=${r.totalN}`);
    } else {
      reportLines.push(`[RISK]  ${r.name}: ${r.atRiskTables.length} at-risk tables out of ${r.meanRowsTables}, N=${r.totalN}`);
      for (const table of r.atRiskTables) {
        reportLines.push(`          Table: ${table.tableId} (${table.questionId})`);
        for (const v of table.variables) {
          reportLines.push(`            ${v.variable}: ${v.nonNACount}/${table.totalN} non-NA (${v.pctMissing.toFixed(1)}% missing)`);
        }
      }
    }
  }

  if (atRisk.length > 0) {
    reportLines.push('');
    reportLines.push('INTERPRETATION');
    reportLines.push('-'.repeat(40));
    reportLines.push('AT-RISK tables have mean_rows variables where sum(!is.na(var)) < nrow(data).');
    reportLines.push('If a NET row is created from these components, the current R code would use');
    reportLines.push('the first component\'s non-NA count as the base instead of the full table base.');
    reportLines.push('This produces wrong base numbers (the S9/Tito\'s bug).');
  }

  const reportPath = path.join(auditDir, `net-base-risk-${auditTimestamp}.txt`);
  await fs.writeFile(reportPath, reportLines.join('\n'), 'utf-8');

  log('', 'reset');
  log(`Output saved:`, 'blue');
  log(`  ${path.relative(process.cwd(), jsonPath)}`, 'dim');
  log(`  ${path.relative(process.cwd(), reportPath)}`, 'dim');
  log(`Duration: ${(duration / 1000).toFixed(1)}s`, 'dim');
}

main().catch((error) => {
  console.error('Audit failed:', error);
  process.exit(1);
});
