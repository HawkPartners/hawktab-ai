/**
 * Export Excel from tables.json
 *
 * Usage: npx tsx scripts/export-excel.ts [sessionId]
 *
 * If no sessionId provided, uses the most recent test-pipeline-* folder
 */

import { promises as fs } from 'fs';
import path from 'path';
import { ExcelFormatter } from '../src/lib/excel/ExcelFormatter';

async function findMostRecentSession(): Promise<string | null> {
  const tempOutputs = path.join(process.cwd(), 'temp-outputs');

  try {
    const entries = await fs.readdir(tempOutputs, { withFileTypes: true });
    const sessions = entries
      .filter(e => e.isDirectory() && e.name.startsWith('test-pipeline-'))
      .map(e => e.name)
      .sort()
      .reverse();

    return sessions[0] || null;
  } catch {
    return null;
  }
}

async function main() {
  let sessionId = process.argv[2];

  if (!sessionId) {
    const foundSession = await findMostRecentSession();
    if (!foundSession) {
      console.error('No sessionId provided and no test-pipeline sessions found');
      process.exit(1);
    }
    sessionId = foundSession;
    console.log(`Using most recent session: ${sessionId}`);
  }

  const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);
  const tablesJsonPath = path.join(sessionPath, 'results', 'tables.json');
  const outputPath = path.join(sessionPath, 'results', 'crosstabs.xlsx');

  // Check if tables.json exists
  try {
    await fs.access(tablesJsonPath);
  } catch {
    console.error(`tables.json not found at: ${tablesJsonPath}`);
    process.exit(1);
  }

  console.log(`Reading: ${tablesJsonPath}`);

  // Format to Excel
  const formatter = new ExcelFormatter();
  await formatter.formatFromFile(tablesJsonPath);
  await formatter.saveToFile(outputPath);

  console.log(`\nExcel exported to: ${outputPath}`);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
