#!/usr/bin/env npx tsx
/**
 * Test R Script Changes
 *
 * Purpose: Test changes to RScriptGeneratorV2 without running the full pipeline.
 * Uses existing pipeline outputs and generates new results to a separate folder.
 *
 * Usage:
 *   npx tsx scripts/test-r-changes.ts [source-folder]
 *
 * Input:
 *   - Nothing: Uses latest test-pipeline-* folder in temp-outputs
 *   - Folder path: Uses specified pipeline output folder
 *
 * Output:
 *   Creates a new timestamped folder:
 *   temp-outputs/test-r-changes-<timestamp>/
 *   ├── source-folder.txt    # Reference to source pipeline folder
 *   ├── r/
 *   │   └── master.R         # Generated R script
 *   └── results/
 *       ├── tables.json      # R output
 *       └── crosstabs-changes.xlsx   # Excel output (different name for side-by-side comparison)
 */

import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';
import { generateRScriptV2 } from '../src/lib/r/RScriptGeneratorV2';
import type { ExtendedTableDefinition } from '../src/schemas/verificationAgentSchema';
import type { CutDefinition, CutGroup } from '../src/lib/tables/CutsSpec';
import { formatTablesFileToBuffer } from '../src/lib/excel/ExcelFormatter';

// =============================================================================
// Console Colors
// =============================================================================

const colors = {
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

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// =============================================================================
// Find Source Folder
// =============================================================================

async function findLatestPipelineFolder(): Promise<string | null> {
  const tempOutputsDir = path.join(process.cwd(), 'temp-outputs');

  try {
    const entries = await fs.readdir(tempOutputsDir, { withFileTypes: true });

    const pipelineDirs = entries
      .filter(e => e.isDirectory() && e.name.startsWith('test-pipeline-'))
      .map(e => e.name)
      .sort()
      .reverse();

    if (pipelineDirs.length > 0) {
      return path.join(tempOutputsDir, pipelineDirs[0]);
    }
  } catch {
    // Directory doesn't exist
  }

  return null;
}

async function findFileByPattern(dir: string, pattern: string): Promise<string | null> {
  const files = await fs.readdir(dir);
  const match = files.find(f => f.includes(pattern) && f.endsWith('.json'));
  return match ? path.join(dir, match) : null;
}

// =============================================================================
// Load Data
// =============================================================================

interface CrosstabOutput {
  bannerCuts: Array<{
    groupName: string;
    columns: Array<{
      name: string;
      adjusted: string;
      confidence: number;
      reason: string;
    }>;
  }>;
}

interface VerifiedTableOutput {
  tables: ExtendedTableDefinition[];
}

function loadCutsFromCrosstabOutput(data: CrosstabOutput): { cuts: CutDefinition[]; cutGroups: CutGroup[] } {
  const cuts: CutDefinition[] = [];
  const cutGroups: CutGroup[] = [];

  let letterIndex = 0;
  const getNextLetter = () => String.fromCharCode(65 + letterIndex++);

  for (const group of data.bannerCuts || []) {
    const groupCutDefs: CutDefinition[] = [];

    for (const col of group.columns || []) {
      if (col.name && col.adjusted) {
        const cutDef: CutDefinition = {
          id: col.name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, ''),
          name: col.name,
          rExpression: col.adjusted,
          statLetter: getNextLetter(),
          groupName: group.groupName,
          groupIndex: cuts.length,
        };
        cuts.push(cutDef);
        groupCutDefs.push(cutDef);
      }
    }

    if (groupCutDefs.length > 0) {
      cutGroups.push({
        groupName: group.groupName,
        cuts: groupCutDefs,
      });
    }
  }

  return { cuts, cutGroups };
}

// =============================================================================
// Run R Script
// =============================================================================

async function runRScript(scriptPath: string, workingDir: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const rscriptPaths = [
      '/opt/homebrew/bin/Rscript',
      '/usr/local/bin/Rscript',
      '/usr/bin/Rscript',
      'Rscript',
    ];

    let rscriptPath = 'Rscript';
    for (const p of rscriptPaths) {
      try {
        require('child_process').execSync(`${p} --version`, { stdio: 'ignore' });
        rscriptPath = p;
        break;
      } catch {
        // Try next
      }
    }

    log(`  Running: ${rscriptPath} ${path.basename(scriptPath)}`, 'dim');

    const proc = spawn(rscriptPath, [scriptPath], {
      cwd: workingDir,
    });

    let stdout = '';
    let stderr = '';

    proc.stdout.on('data', (data) => {
      stdout += data.toString();
      process.stdout.write(data);
    });

    proc.stderr.on('data', (data) => {
      stderr += data.toString();
      // Only print actual errors, not package loading messages
      const msg = data.toString();
      if (!msg.includes('Attaching package') && !msg.includes('masked from')) {
        process.stderr.write(data);
      }
    });

    proc.on('close', (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`R script failed with code ${code}`));
      }
    });

    proc.on('error', (err) => {
      reject(err);
    });
  });
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);

  log('');
  log('======================================================================', 'magenta');
  log('  Test R Script Changes', 'bright');
  log('======================================================================', 'magenta');
  log('');

  // 1. Find source folder
  let sourceFolder = process.argv[2];

  if (!sourceFolder) {
    sourceFolder = await findLatestPipelineFolder() ?? '';
    if (!sourceFolder) {
      log('No test-pipeline-* folder found in temp-outputs/', 'red');
      log('Run test-pipeline.ts first to generate pipeline outputs.', 'dim');
      process.exit(1);
    }
  } else {
    if (!path.isAbsolute(sourceFolder)) {
      sourceFolder = path.join(process.cwd(), sourceFolder);
    }
  }

  try {
    await fs.access(sourceFolder);
  } catch {
    log(`Source folder not found: ${sourceFolder}`, 'red');
    process.exit(1);
  }

  log(`Source: ${path.basename(sourceFolder)}`, 'blue');

  // 2. Create output folder
  const outputFolder = path.join(process.cwd(), 'temp-outputs', `test-r-changes-${timestamp}`);
  const rDir = path.join(outputFolder, 'r');
  const resultsDir = path.join(outputFolder, 'results');

  await fs.mkdir(rDir, { recursive: true });
  await fs.mkdir(resultsDir, { recursive: true });

  log(`Output: ${path.basename(outputFolder)}`, 'blue');
  log('');

  // 3. Find required files
  log('[1/5] Finding source files...', 'cyan');

  const verifiedTablesFile = await findFileByPattern(sourceFolder, 'verified-table-output');
  const crosstabFile = await findFileByPattern(sourceFolder, 'crosstab-output');

  const sourceFiles = await fs.readdir(sourceFolder);
  const spssFileName = sourceFiles.find(f => f.endsWith('.sav'));
  const spssSourcePath = spssFileName ? path.join(sourceFolder, spssFileName) : null;

  if (!verifiedTablesFile) {
    log('  Missing: verified-table-output-*.json', 'red');
    process.exit(1);
  }
  if (!crosstabFile) {
    log('  Missing: crosstab-output-*.json', 'red');
    process.exit(1);
  }
  if (!spssSourcePath) {
    log('  Missing: *.sav file', 'red');
    process.exit(1);
  }

  log(`  Tables: ${path.basename(verifiedTablesFile)}`, 'dim');
  log(`  Cuts: ${path.basename(crosstabFile)}`, 'dim');
  log(`  SPSS: ${path.basename(spssSourcePath)}`, 'dim');

  // 4. Load data
  log('');
  log('[2/5] Loading data...', 'cyan');

  const verifiedData: VerifiedTableOutput = JSON.parse(await fs.readFile(verifiedTablesFile, 'utf-8'));
  const crosstabData: CrosstabOutput = JSON.parse(await fs.readFile(crosstabFile, 'utf-8'));

  const tables = verifiedData.tables;
  const { cuts, cutGroups } = loadCutsFromCrosstabOutput(crosstabData);

  log(`  Loaded ${tables.length} tables`, 'green');
  log(`  Loaded ${cuts.length} cuts in ${cutGroups.length} groups`, 'green');

  // 5. Copy SPSS file to output folder
  const spssDestPath = path.join(outputFolder, 'dataFile.sav');
  await fs.copyFile(spssSourcePath, spssDestPath);
  log(`  Copied SPSS data to output folder`, 'dim');

  // 6. Generate R script
  log('');
  log('[3/5] Generating R script...', 'cyan');

  const rScript = generateRScriptV2({
    tables,
    cuts,
    cutGroups,
    dataFilePath: spssDestPath,
    significanceLevel: 0.10,
    bannerGroups: cutGroups.map(g => ({
      groupName: g.groupName,
      columns: g.cuts.map(c => ({ name: c.name, statLetter: c.statLetter })),
    })),
  });

  const rScriptPath = path.join(rDir, 'master.R');
  await fs.writeFile(rScriptPath, rScript);
  log(`  Saved: r/master.R (${Math.round(rScript.length / 1024)} KB)`, 'green');

  // Save source reference
  await fs.writeFile(
    path.join(outputFolder, 'source-folder.txt'),
    `Source: ${sourceFolder}\nTimestamp: ${new Date().toISOString()}\n`
  );

  // 7. Run R script
  log('');
  log('[4/5] Running R script...', 'cyan');

  try {
    await runRScript(rScriptPath, outputFolder);
    log('  R script completed', 'green');
  } catch (err) {
    log(`  R script failed: ${err}`, 'red');
    process.exit(1);
  }

  // Verify tables.json was created
  const tablesJsonPath = path.join(resultsDir, 'tables.json');
  try {
    await fs.access(tablesJsonPath);
  } catch {
    log('  Missing: results/tables.json (R script may have failed)', 'red');
    process.exit(1);
  }

  // 8. Generate Excel
  log('');
  log('[5/5] Generating Excel...', 'cyan');

  try {
    const excelBuffer = await formatTablesFileToBuffer(tablesJsonPath);
    const excelPath = path.join(resultsDir, 'crosstabs-changes.xlsx');
    await fs.writeFile(excelPath, excelBuffer);
    log(`  Saved: results/crosstabs-changes.xlsx`, 'green');
  } catch (err) {
    log(`  Excel generation failed: ${err}`, 'red');
    process.exit(1);
  }

  // Summary
  log('');
  log('======================================================================', 'green');
  log('  Complete!', 'bright');
  log('======================================================================', 'green');
  log('');
  log(`Output folder: temp-outputs/${path.basename(outputFolder)}`, 'blue');
  log('');
  log('Files:', 'yellow');
  log('  r/master.R                  - Generated R script (with current code)', 'dim');
  log('  results/tables.json         - R calculations', 'dim');
  log('  results/crosstabs-changes.xlsx - Excel workbook', 'dim');
  log('');
  log('Compare with original:', 'yellow');
  log(`  Original: ${path.basename(sourceFolder)}/results/`, 'dim');
  log(`  New:      ${path.basename(outputFolder)}/results/`, 'dim');
  log('');
}

main().catch((err) => {
  log(`Error: ${err.message}`, 'red');
  console.error(err);
  process.exit(1);
});
