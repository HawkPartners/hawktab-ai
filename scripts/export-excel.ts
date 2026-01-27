/**
 * Export Excel from tables.json
 *
 * Usage: npx tsx scripts/export-excel.ts [dataset] [pipelineId]
 *
 * Examples:
 *   npx tsx scripts/export-excel.ts
 *     -> Uses most recent pipeline from first dataset in outputs/
 *
 *   npx tsx scripts/export-excel.ts leqvio-monotherapy-demand-NOV217
 *     -> Uses most recent pipeline from that dataset
 *
 *   npx tsx scripts/export-excel.ts leqvio-monotherapy-demand-NOV217 pipeline-2026-01-27T18-17-10-020Z
 *     -> Uses specific pipeline
 */

import { promises as fs } from 'fs';
import path from 'path';
import { ExcelFormatter } from '../src/lib/excel/ExcelFormatter';

const OUTPUTS_DIR = path.join(process.cwd(), 'outputs');

/**
 * Find all dataset folders in outputs/
 */
async function findDatasets(): Promise<string[]> {
  try {
    const entries = await fs.readdir(OUTPUTS_DIR, { withFileTypes: true });
    return entries
      .filter(e => e.isDirectory() && !e.name.startsWith('.'))
      .map(e => e.name)
      .sort();
  } catch {
    return [];
  }
}

/**
 * Find most recent pipeline folder within a dataset
 */
async function findMostRecentPipeline(dataset: string): Promise<string | null> {
  const datasetPath = path.join(OUTPUTS_DIR, dataset);

  try {
    const entries = await fs.readdir(datasetPath, { withFileTypes: true });
    const pipelines = entries
      .filter(e => e.isDirectory() && e.name.startsWith('pipeline-'))
      .map(e => e.name)
      .sort()
      .reverse();

    return pipelines[0] || null;
  } catch {
    return null;
  }
}

/**
 * Find next available output filename (increments to avoid overwriting)
 */
async function findNextOutputPath(resultsDir: string, baseName: string): Promise<string> {
  const ext = '.xlsx';

  // Check existing files to find next number
  try {
    const entries = await fs.readdir(resultsDir);
    const existing = entries.filter(e => e.startsWith(baseName) && e.endsWith(ext));

    if (existing.length === 0) {
      return path.join(resultsDir, `${baseName}${ext}`);
    }

    // Find highest number
    let maxNum = 0;
    for (const file of existing) {
      // Match patterns like "crosstabs.xlsx", "crosstabs-1.xlsx", "crosstabs-2.xlsx"
      const match = file.match(new RegExp(`^${baseName}(?:-(\\d+))?\\.xlsx$`));
      if (match) {
        const num = match[1] ? parseInt(match[1], 10) : 0;
        maxNum = Math.max(maxNum, num);
      }
    }

    return path.join(resultsDir, `${baseName}-${maxNum + 1}${ext}`);
  } catch {
    return path.join(resultsDir, `${baseName}${ext}`);
  }
}

async function main() {
  let dataset = process.argv[2];
  let pipelineId = process.argv[3];

  // Find dataset if not provided
  if (!dataset) {
    const datasets = await findDatasets();
    if (datasets.length === 0) {
      console.error('No datasets found in outputs/');
      process.exit(1);
    }
    dataset = datasets[0];
    console.log(`Using dataset: ${dataset}`);
  }

  // Find pipeline if not provided
  if (!pipelineId) {
    const foundPipeline = await findMostRecentPipeline(dataset);
    if (!foundPipeline) {
      console.error(`No pipeline folders found in outputs/${dataset}/`);
      process.exit(1);
    }
    pipelineId = foundPipeline;
    console.log(`Using most recent pipeline: ${pipelineId}`);
  }

  const pipelinePath = path.join(OUTPUTS_DIR, dataset, pipelineId);
  const resultsDir = path.join(pipelinePath, 'results');
  const tablesJsonPath = path.join(resultsDir, 'tables.json');

  // Check if tables.json exists
  try {
    await fs.access(tablesJsonPath);
  } catch {
    console.error(`tables.json not found at: ${tablesJsonPath}`);
    process.exit(1);
  }

  // Find next available output filename
  const outputPath = await findNextOutputPath(resultsDir, 'crosstabs');

  console.log(`\nReading: ${tablesJsonPath}`);
  console.log(`Output:  ${outputPath}`);

  // Format to Excel (Joe format by default)
  const formatter = new ExcelFormatter({ format: 'joe' });
  await formatter.formatFromFile(tablesJsonPath);
  await formatter.saveToFile(outputPath);

  console.log(`\nExcel exported to: ${outputPath}`);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
