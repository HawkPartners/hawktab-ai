import { runAllGuardrails } from '@/guardrails/inputValidation';
import { saveUploadedFile } from '@/lib/storage';
import type { SavedFilePaths } from './types';

export interface ParsedUploadData {
  dataMapFile: File;
  bannerPlanFile: File;
  dataFile: File;
  surveyFile: File | null;
  loopStatTestingMode: 'suppress' | 'complement' | undefined;
}

/**
 * Parse upload form data into typed file objects.
 * Returns null if required files are missing.
 */
export function parseUploadFormData(formData: FormData): ParsedUploadData | null {
  const dataMapFile = formData.get('dataMap') as File | null;
  const bannerPlanFile = formData.get('bannerPlan') as File | null;
  const dataFile = formData.get('dataFile') as File | null;
  const surveyFile = formData.get('surveyDocument') as File | null;
  const loopStatTestingRaw = formData.get('loopStatTestingMode');
  const loopStatTestingMode =
    loopStatTestingRaw === 'suppress' || loopStatTestingRaw === 'complement'
      ? loopStatTestingRaw
      : undefined;

  if (!dataMapFile || !bannerPlanFile || !dataFile) return null;

  return { dataMapFile, bannerPlanFile, dataFile, surveyFile, loopStatTestingMode };
}

/**
 * Run input guardrails on uploaded files.
 */
export async function validateUploadedFiles(files: {
  dataMap: File;
  bannerPlan: File;
  dataFile: File;
}): Promise<{ success: boolean; errors: string[]; warnings: string[] }> {
  return runAllGuardrails(files);
}

/**
 * Save uploaded files to temporary storage and return paths.
 * Throws if any file save fails.
 */
export async function saveFilesToStorage(
  data: ParsedUploadData,
  sessionId: string
): Promise<SavedFilePaths> {
  const { dataMapFile, bannerPlanFile, dataFile, surveyFile } = data;

  const fileSavePromises = [
    saveUploadedFile(dataMapFile, sessionId, `dataMap.${dataMapFile.name.split('.').pop()}`),
    saveUploadedFile(bannerPlanFile, sessionId, `bannerPlan.${bannerPlanFile.name.split('.').pop()}`),
    saveUploadedFile(dataFile, sessionId, `dataFile.${dataFile.name.split('.').pop()}`),
  ];

  if (surveyFile) {
    fileSavePromises.push(
      saveUploadedFile(surveyFile, sessionId, `survey.${surveyFile.name.split('.').pop()}`)
    );
  }

  const fileResults = await Promise.all(fileSavePromises);

  const failedSaves = fileResults.filter(r => !r.success);
  if (failedSaves.length > 0) {
    throw new Error(`Failed to save uploaded files: ${failedSaves.map(r => r.error).join(', ')}`);
  }

  return {
    dataMapPath: fileResults[0].filePath!,
    bannerPlanPath: fileResults[1].filePath!,
    spssPath: fileResults[2].filePath!,
    surveyPath: surveyFile ? fileResults[3]?.filePath ?? null : null,
  };
}

/**
 * Sanitize dataset name for use in file paths.
 */
export function sanitizeDatasetName(filename: string): string {
  return filename
    .replace(/\.(sav|csv|xlsx?)$/i, '')
    .replace(/[^a-zA-Z0-9-_]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase();
}
