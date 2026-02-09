/**
 * Theme Preview Generator
 *
 * Loads a tables.json from a recent pipeline run and generates one Excel
 * workbook per theme into outputs/theme-preview/. Open them side by side
 * in Excel to compare.
 *
 * Usage:
 *   npx tsx scripts/test-themes.ts [path-to-tables.json]
 *
 * If no path is given, uses the most recent Tito's pipeline output.
 */

import '../src/lib/loadEnv';
import { promises as fs } from 'fs';
import path from 'path';
import { ExcelFormatter, type TablesJson } from '../src/lib/excel/ExcelFormatter';
import { setActiveTheme } from '../src/lib/excel/styles';
import { getThemeNames, getTheme } from '../src/lib/excel/themes';

async function findDefaultTablesJson(): Promise<string> {
  // Look for the most recent pipeline output with tables.json
  const outputsDir = path.join(process.cwd(), 'outputs');
  const datasets = await fs.readdir(outputsDir);

  for (const dataset of datasets) {
    const datasetPath = path.join(outputsDir, dataset);
    const stat = await fs.stat(datasetPath);
    if (!stat.isDirectory()) continue;

    // Find pipeline folders, sorted most recent first
    const entries = await fs.readdir(datasetPath);
    const pipelineDirs = entries
      .filter(e => e.startsWith('pipeline-'))
      .sort()
      .reverse();

    for (const pipelineDir of pipelineDirs) {
      const tablesPath = path.join(datasetPath, pipelineDir, 'results', 'tables.json');
      try {
        await fs.access(tablesPath);
        return tablesPath;
      } catch {
        continue;
      }
    }
  }

  throw new Error('No tables.json found in outputs/. Run a pipeline first or provide a path.');
}

async function main() {
  // Resolve tables.json path
  const arg = process.argv[2];
  const tablesJsonPath = arg
    ? path.resolve(arg)
    : await findDefaultTablesJson();

  console.log(`Loading tables from: ${tablesJsonPath}`);

  const jsonContent = await fs.readFile(tablesJsonPath, 'utf-8');
  const tablesJson = JSON.parse(jsonContent) as TablesJson;

  const tableCount = Object.keys(tablesJson.tables).length;
  console.log(`Found ${tableCount} tables, ${tablesJson.metadata.bannerGroups.length} banner groups\n`);

  // Create output directory
  const previewDir = path.join(process.cwd(), 'outputs', 'theme-preview');
  await fs.mkdir(previewDir, { recursive: true });

  // Generate one Excel per theme
  const themes = getThemeNames();
  console.log(`Generating ${themes.length} themed workbooks...\n`);

  for (const themeName of themes) {
    const theme = getTheme(themeName);
    const outputPath = path.join(previewDir, `crosstabs-${themeName}.xlsx`);

    // Set theme before creating formatter
    setActiveTheme(themeName);

    const formatter = new ExcelFormatter({ format: 'joe', displayMode: 'frequency' });
    await formatter.formatFromJson(tablesJson);
    await formatter.saveToFile(outputPath);

    console.log(`  ${theme.displayName.padEnd(10)} → ${outputPath}`);
  }

  console.log(`\nDone! Open the files in outputs/theme-preview/ to compare.`);
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
