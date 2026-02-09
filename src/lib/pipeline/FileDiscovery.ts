/**
 * File Discovery
 *
 * Discovers required files in a dataset folder.
 */

import fs from 'fs/promises';
import path from 'path';
import type { DatasetFiles } from './types';

export const DEFAULT_DATASET = 'data/leqvio-monotherapy-demand-NOV217';

/**
 * Find required files in a dataset folder
 *
 * Supports nested structure:
 *   dataset-folder/
 *   ├── inputs/           # Input files go here
 *   ├── tabs/             # Reference output (Joe's tabs)
 *   └── golden-datasets/  # For evaluation framework
 */
export async function findDatasetFiles(folder: string): Promise<DatasetFiles> {
  const absFolder = path.isAbsolute(folder) ? folder : path.join(process.cwd(), folder);

  // Check for nested structure (inputs/ subfolder)
  let inputsFolder = absFolder;
  try {
    const subfolders = await fs.readdir(absFolder);
    if (subfolders.includes('inputs')) {
      inputsFolder = path.join(absFolder, 'inputs');
    }
  } catch {
    // Continue with absFolder
  }

  const files = await fs.readdir(inputsFolder);

  // Find datamap CSV (optional — .sav is the source of truth)
  const datamapFile = files.find(f =>
    f.toLowerCase().includes('datamap') && f.endsWith('.csv')
  );
  const datamap = datamapFile ? path.join(inputsFolder, datamapFile) : null;

  // Find banner plan (prefer 'adjusted' > 'clean' > original)
  let banner = files.find(f =>
    f.toLowerCase().includes('banner') &&
    f.toLowerCase().includes('adjusted') &&
    (f.endsWith('.docx') || f.endsWith('.pdf'))
  );
  if (!banner) {
    banner = files.find(f =>
      f.toLowerCase().includes('banner') &&
      f.toLowerCase().includes('clean') &&
      (f.endsWith('.docx') || f.endsWith('.pdf'))
    );
  }
  if (!banner) {
    banner = files.find(f =>
      f.toLowerCase().includes('banner') &&
      (f.endsWith('.docx') || f.endsWith('.pdf'))
    );
  }
  if (!banner) {
    throw new Error(`No banner plan found in ${folder}. Expected file containing "banner" with .docx or .pdf extension.`);
  }

  // Find SPSS file
  const spss = files.find(f => f.endsWith('.sav'));
  if (!spss) {
    throw new Error(`No SPSS file found in ${folder}. Expected .sav file.`);
  }

  // Find survey/questionnaire document (optional - for VerificationAgent)
  // Priority: 1) file with 'survey', 'questionnaire', or 'qre', 2) .docx that's not a banner plan
  let survey = files.find(f => {
    const lower = f.toLowerCase();
    return (lower.includes('survey') || lower.includes('questionnaire') || lower.includes('qre')) &&
      (f.endsWith('.docx') || f.endsWith('.pdf'));
  });
  if (!survey) {
    // Fall back to any .docx that's not a banner plan (likely the main survey document)
    survey = files.find(f =>
      f.endsWith('.docx') &&
      !f.toLowerCase().includes('banner')
    );
  }

  // Derive dataset name from folder (use the main folder, not inputs/)
  const name = path.basename(absFolder);

  return {
    datamap,
    banner: path.join(inputsFolder, banner),
    spss: path.join(inputsFolder, spss),
    survey: survey ? path.join(inputsFolder, survey) : null,
    name,
  };
}
