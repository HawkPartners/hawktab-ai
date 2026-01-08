#!/usr/bin/env npx tsx
/**
 * @deprecated Use test-r-changes.ts instead.
 * This script is kept for backwards compatibility but test-r-changes.ts
 * provides a better workflow for testing R script changes.
 *
 * R Script Generator V2 Test Script
 *
 * Purpose: Test RScriptGeneratorV2 with TableAgent output.
 *
 * Usage:
 *   npx tsx scripts/test-r-script-v2.ts [input]
 *
 * Input can be:
 *   - Nothing: Uses latest table output from temp-outputs OR runs test-table-agent first
 *   - JSON file: Uses existing table output JSON
 *   - Folder: Looks for table-output-*.json in folder
 *
 * Examples:
 *   npx tsx scripts/test-r-script-v2.ts
 *   # Uses latest table output or runs TableAgent on practice files
 *
 *   npx tsx scripts/test-r-script-v2.ts temp-outputs/table-test-xxx/
 *   # Uses table output from specific folder
 *
 * Output:
 *   Saves master.R to the same directory as the table output
 */

import fs from 'fs/promises';
import path from 'path';
import { generateRScriptV2 } from '../src/lib/r/RScriptGeneratorV2';
import type { TableDefinition, TableAgentOutput } from '../src/schemas/tableAgentSchema';
import { toExtendedTable, type ExtendedTableDefinition } from '../src/schemas/verificationAgentSchema';
import type { CutDefinition } from '../src/lib/tables/CutsSpec';

// =============================================================================
// Configuration
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
// Input Resolution
// =============================================================================

async function findLatestTableOutput(): Promise<string | null> {
  const tempOutputsDir = path.join(process.cwd(), 'temp-outputs');

  try {
    const entries = await fs.readdir(tempOutputsDir, { withFileTypes: true });

    // Look for table-test-* or test-pipeline-* directories
    const testDirs = entries
      .filter(e => e.isDirectory() && (e.name.startsWith('table-test-') || e.name.startsWith('test-pipeline-')))
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
  } catch {
    // temp-outputs doesn't exist
  }

  return null;
}

async function resolveInput(inputArg?: string): Promise<string> {
  if (inputArg) {
    const absPath = path.isAbsolute(inputArg) ? inputArg : path.join(process.cwd(), inputArg);

    const stat = await fs.stat(absPath);
    if (stat.isDirectory()) {
      const files = await fs.readdir(absPath);
      const tableOutputFile = files.find(f => f.startsWith('table-output-') && f.endsWith('.json'));
      if (!tableOutputFile) {
        throw new Error(`No table-output-*.json found in ${inputArg}`);
      }
      return path.join(absPath, tableOutputFile);
    }

    return absPath;
  }

  // Try to find latest
  const latest = await findLatestTableOutput();
  if (latest) {
    return latest;
  }

  throw new Error('No table output found. Run test-table-agent.ts or test-pipeline.ts first.');
}

// =============================================================================
// Data Loading
// =============================================================================

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

  return data.results.flatMap(r => r.tables);
}

function createMockCuts(): CutDefinition[] {
  // Create realistic mock cuts for testing with stat testing fields
  return [
    { id: 'gender.male', name: 'Male', rExpression: 'S2 == 1', statLetter: 'A', groupName: 'Gender', groupIndex: 0 },
    { id: 'gender.female', name: 'Female', rExpression: 'S2 == 2', statLetter: 'B', groupName: 'Gender', groupIndex: 1 },
    { id: 'specialty.cardiology', name: 'Cardiology', rExpression: 'S6 == 1', statLetter: 'C', groupName: 'Specialty', groupIndex: 0 },
    { id: 'specialty.endocrinology', name: 'Endocrinology', rExpression: 'S6 == 2', statLetter: 'D', groupName: 'Specialty', groupIndex: 1 },
    { id: 'specialty.primary-care', name: 'Primary Care', rExpression: 'S6 == 3', statLetter: 'E', groupName: 'Specialty', groupIndex: 2 },
    { id: 'years.early', name: 'Years in Practice: <10', rExpression: 'S3 < 10', statLetter: 'F', groupName: 'Years', groupIndex: 0 },
    { id: 'years.mid', name: 'Years in Practice: 10-20', rExpression: 'S3 >= 10 & S3 <= 20', statLetter: 'G', groupName: 'Years', groupIndex: 1 },
    { id: 'years.senior', name: 'Years in Practice: >20', rExpression: 'S3 > 20', statLetter: 'H', groupName: 'Years', groupIndex: 2 },
  ];
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  log('', 'reset');
  log('='.repeat(60), 'magenta');
  log('  R Script Generator V2 - Test Script', 'bright');
  log('='.repeat(60), 'magenta');
  log('', 'reset');

  // Resolve input
  let inputPath: string;
  try {
    inputPath = await resolveInput(process.argv[2]);
  } catch (error) {
    log(`ERROR: ${error instanceof Error ? error.message : String(error)}`, 'red');
    log('', 'reset');
    log('Usage:', 'yellow');
    log('  npx tsx scripts/test-r-script-v2.ts                  # Use latest output', 'dim');
    log('  npx tsx scripts/test-r-script-v2.ts <folder>         # Find table output in folder', 'dim');
    log('  npx tsx scripts/test-r-script-v2.ts <file.json>      # Use specific file', 'dim');
    log('', 'reset');
    log('Run test-table-agent.ts or test-pipeline.ts first to generate table output.', 'yellow');
    process.exit(1);
  }

  log(`Input: ${inputPath}`, 'blue');

  // Load table output
  let tables: TableDefinition[];
  try {
    tables = await loadTableOutput(inputPath);
    log(`Loaded ${tables.length} table definitions`, 'green');
  } catch (error) {
    log(`ERROR loading table output: ${error instanceof Error ? error.message : String(error)}`, 'red');
    process.exit(1);
  }

  // Convert to ExtendedTableDefinition (required by RScriptGeneratorV2)
  const extendedTables: ExtendedTableDefinition[] = tables.map(t => toExtendedTable(t));

  // Count table types
  const typeCount: Record<string, number> = {};
  for (const table of extendedTables) {
    typeCount[table.tableType] = (typeCount[table.tableType] || 0) + 1;
  }
  log(`  Table types: ${JSON.stringify(typeCount)}`, 'dim');

  // Use mock cuts (in real usage, these come from CrosstabAgent)
  const cuts = createMockCuts();
  log(`Using ${cuts.length} mock cuts`, 'blue');

  // Generate R script
  log('', 'reset');
  log('Generating R script...', 'yellow');

  const sessionId = new Date().toISOString().replace(/[:.]/g, '-');
  const script = generateRScriptV2(
    { tables: extendedTables, cuts },
    { sessionId, outputDir: 'results' }
  );

  // Save R script
  const outputDir = path.dirname(inputPath);
  const scriptPath = path.join(outputDir, 'master.R');

  await fs.writeFile(scriptPath, script, 'utf-8');
  log(`R script saved: ${scriptPath}`, 'green');

  // Summary
  log('', 'reset');
  log('='.repeat(60), 'green');
  log('  Summary', 'bright');
  log('='.repeat(60), 'green');
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
}

main().catch(console.error);
