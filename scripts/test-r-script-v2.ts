#!/usr/bin/env npx tsx
/**
 * R Script Generator V2 Test Script
 *
 * Purpose: Test RScriptGeneratorV2 with TableAgent output to verify R script generation.
 *
 * Usage:
 *   npx tsx scripts/test-r-script-v2.ts [table-output-path]
 *
 * Examples:
 *   npx tsx scripts/test-r-script-v2.ts
 *   # Uses latest table output from temp-outputs
 *
 *   npx tsx scripts/test-r-script-v2.ts temp-outputs/table-test-xxx/table-output-xxx.json
 *   # Uses specified table output file
 *
 * Output:
 *   Saves master.R to the same directory as the table output (or a new test folder)
 */

import fs from 'fs/promises';
import path from 'path';
import { generateRScriptV2 } from '../src/lib/r/RScriptGeneratorV2';
import type { TableDefinition, TableAgentOutput } from '../src/schemas/tableAgentSchema';
import type { CutDefinition } from '../src/lib/tables/CutsSpec';

// ANSI colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
};

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function findLatestTableOutput(): Promise<string | null> {
  const tempOutputsDir = path.join(process.cwd(), 'temp-outputs');

  try {
    const entries = await fs.readdir(tempOutputsDir, { withFileTypes: true });
    const testDirs = entries
      .filter(e => e.isDirectory() && e.name.startsWith('table-test-'))
      .map(e => e.name)
      .sort()
      .reverse(); // Most recent first

    for (const dir of testDirs) {
      const dirPath = path.join(tempOutputsDir, dir);
      const files = await fs.readdir(dirPath);

      const tableOutputFile = files.find(f =>
        f.startsWith('table-output-') && f.endsWith('.json')
      );

      if (tableOutputFile) {
        return path.join(dirPath, tableOutputFile);
      }
    }
  } catch (error) {
    // temp-outputs doesn't exist
  }

  return null;
}

interface TableOutputFile {
  results: TableAgentOutput[];
  processingInfo?: {
    timestamp: string;
    model: string;
    totalQuestionGroups: number;
    totalTablesGenerated: number;
  };
}

async function loadTableOutput(filePath: string): Promise<TableDefinition[]> {
  const content = await fs.readFile(filePath, 'utf-8');
  const data: TableOutputFile = JSON.parse(content);

  // Flatten all tables from all results
  const tables = data.results.flatMap(r => r.tables);
  return tables;
}

function createMockCuts(): CutDefinition[] {
  // Create realistic mock cuts for testing
  // These simulate what CrosstabAgent would produce
  return [
    { id: 'gender.male', name: 'Male', rExpression: 'S2 == 1' },
    { id: 'gender.female', name: 'Female', rExpression: 'S2 == 2' },
    { id: 'specialty.cardiology', name: 'Cardiology', rExpression: 'S6 == 1' },
    { id: 'specialty.endocrinology', name: 'Endocrinology', rExpression: 'S6 == 2' },
    { id: 'specialty.primary-care', name: 'Primary Care', rExpression: 'S6 == 3' },
    { id: 'years.early', name: 'Years in Practice: <10', rExpression: 'S3 < 10' },
    { id: 'years.mid', name: 'Years in Practice: 10-20', rExpression: 'S3 >= 10 & S3 <= 20' },
    { id: 'years.senior', name: 'Years in Practice: >20', rExpression: 'S3 > 20' },
  ];
}

async function main() {
  log('', 'reset');
  log('='.repeat(70), 'cyan');
  log('  R Script Generator V2 - Test Script', 'bright');
  log('='.repeat(70), 'cyan');
  log('', 'reset');

  // Find or use provided table output
  const inputPath = process.argv[2] || await findLatestTableOutput();

  if (!inputPath) {
    log('ERROR: No table output file found.', 'red');
    log('Run test-table-agent.ts first, or provide a path:', 'yellow');
    log('  npx tsx scripts/test-r-script-v2.ts <path-to-table-output.json>', 'dim');
    process.exit(1);
  }

  log(`Input: ${inputPath}`, 'blue');

  // Load table output
  let tables: TableDefinition[];
  try {
    tables = await loadTableOutput(inputPath);
    log(`Loaded ${tables.length} table definitions`, 'green');
  } catch (error) {
    log(`ERROR loading table output: ${error}`, 'red');
    process.exit(1);
  }

  // Count table types
  const typeCount: Record<string, number> = {};
  for (const table of tables) {
    typeCount[table.tableType] = (typeCount[table.tableType] || 0) + 1;
  }
  log(`  Table types: ${JSON.stringify(typeCount)}`, 'dim');

  // Create mock cuts (in real usage, these come from CrosstabAgent)
  const cuts = createMockCuts();
  log(`Using ${cuts.length} mock cuts`, 'blue');

  // Generate R script
  log('', 'reset');
  log('Generating R script...', 'yellow');

  const sessionId = new Date().toISOString().replace(/[:.]/g, '-');
  const script = generateRScriptV2(
    { tables, cuts },
    { sessionId, outputDir: 'results' }
  );

  // Save R script
  const outputDir = path.dirname(inputPath);
  const scriptPath = path.join(outputDir, 'master.R');

  await fs.writeFile(scriptPath, script, 'utf-8');
  log(`R script saved: ${scriptPath}`, 'green');

  // Print summary
  log('', 'reset');
  log('='.repeat(70), 'cyan');
  log('  Summary', 'bright');
  log('='.repeat(70), 'cyan');
  log(`  Tables: ${tables.length}`, 'reset');
  log(`  Cuts: ${cuts.length + 1} (including Total)`, 'reset');
  log(`  Script size: ${Math.round(script.length / 1024)} KB`, 'reset');
  log(`  Script lines: ${script.split('\n').length}`, 'reset');
  log('', 'reset');
  log('To run the R script:', 'yellow');
  log(`  cd "${outputDir}"`, 'dim');
  log('  # Copy dataFile.sav to this directory', 'dim');
  log('  Rscript master.R', 'dim');
  log('', 'reset');

  // Show first few lines of script
  log('First 30 lines of generated script:', 'blue');
  log('-'.repeat(70), 'dim');
  const previewLines = script.split('\n').slice(0, 30);
  for (const line of previewLines) {
    console.log(colors.dim + line + colors.reset);
  }
  log('-'.repeat(70), 'dim');
  log(`... (${script.split('\n').length - 30} more lines)`, 'dim');
}

main().catch(console.error);
