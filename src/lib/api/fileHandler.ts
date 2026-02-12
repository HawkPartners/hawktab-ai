import { runAllGuardrails } from '@/guardrails/inputValidation';
import { saveUploadedFile } from '@/lib/storage';
import { uploadInputFile } from '@/lib/r2/R2FileManager';
import type { SavedFilePaths, ParsedWizardFiles, SavedWizardPaths } from './types';

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
 * If r2Scope is provided, also uploads to R2 in parallel.
 * Throws if any file save fails.
 */
export async function saveFilesToStorage(
  data: ParsedUploadData,
  sessionId: string,
  r2Scope?: { orgId: string; projectId: string },
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

  const result: SavedFilePaths = {
    dataMapPath: fileResults[0].filePath!,
    bannerPlanPath: fileResults[1].filePath!,
    spssPath: fileResults[2].filePath!,
    surveyPath: surveyFile ? fileResults[3]?.filePath ?? null : null,
  };

  // Upload to R2 in parallel (non-blocking — don't fail pipeline on R2 errors)
  if (r2Scope) {
    try {
      const r2Promises: Promise<string>[] = [
        uploadInputToR2(dataMapFile, r2Scope.orgId, r2Scope.projectId),
        uploadInputToR2(bannerPlanFile, r2Scope.orgId, r2Scope.projectId),
        uploadInputToR2(dataFile, r2Scope.orgId, r2Scope.projectId),
      ];
      if (surveyFile) {
        r2Promises.push(uploadInputToR2(surveyFile, r2Scope.orgId, r2Scope.projectId));
      }

      const r2Keys = await Promise.all(r2Promises);
      result.r2Keys = {
        dataMap: r2Keys[0],
        bannerPlan: r2Keys[1],
        spss: r2Keys[2],
        survey: surveyFile ? r2Keys[3] ?? null : null,
      };
      console.log('[R2] Input files uploaded successfully');
    } catch (err) {
      console.warn('[R2] Input upload failed (non-fatal):', err);
    }
  }

  return result;
}

async function uploadInputToR2(file: File, orgId: string, projectId: string): Promise<string> {
  const buffer = Buffer.from(await file.arrayBuffer());
  return uploadInputFile(orgId, projectId, buffer, file.name);
}

// =============================================================================
// Wizard-specific file handling (Phase 3.3)
// =============================================================================

/**
 * Parse wizard FormData into typed file objects.
 * The wizard does NOT require a datamap (the .sav IS the datamap).
 * Returns null if required files are missing.
 */
export function parseWizardFormData(formData: FormData): ParsedWizardFiles | null {
  const dataFile = formData.get('dataFile') as File | null;
  const surveyFile = formData.get('surveyDocument') as File | null;
  const bannerPlanFile = formData.get('bannerPlan') as File | null;
  const messageListFile = formData.get('messageList') as File | null;

  if (!dataFile || !surveyFile) return null;

  return { dataFile, surveyFile, bannerPlanFile, messageListFile };
}

/**
 * Save wizard files to temporary storage and return paths.
 * If r2Scope is provided, also uploads to R2 in parallel.
 */
export async function saveWizardFilesToStorage(
  data: ParsedWizardFiles,
  sessionId: string,
  r2Scope?: { orgId: string; projectId: string },
): Promise<SavedWizardPaths> {
  const { dataFile, surveyFile, bannerPlanFile, messageListFile } = data;

  const fileSavePromises = [
    saveUploadedFile(dataFile, sessionId, `dataFile.${dataFile.name.split('.').pop()}`),
    saveUploadedFile(surveyFile, sessionId, `survey.${surveyFile.name.split('.').pop()}`),
  ];

  if (bannerPlanFile) {
    fileSavePromises.push(
      saveUploadedFile(bannerPlanFile, sessionId, `bannerPlan.${bannerPlanFile.name.split('.').pop()}`)
    );
  }
  if (messageListFile) {
    fileSavePromises.push(
      saveUploadedFile(messageListFile, sessionId, `messageList.${messageListFile.name.split('.').pop()}`)
    );
  }

  const fileResults = await Promise.all(fileSavePromises);

  const failedSaves = fileResults.filter(r => !r.success);
  if (failedSaves.length > 0) {
    throw new Error(`Failed to save uploaded files: ${failedSaves.map(r => r.error).join(', ')}`);
  }

  let nextIdx = 2; // 0 = dataFile, 1 = survey
  const result: SavedWizardPaths = {
    spssPath: fileResults[0].filePath!,
    surveyPath: fileResults[1].filePath!,
    bannerPlanPath: bannerPlanFile ? fileResults[nextIdx++]?.filePath ?? null : null,
    messageListPath: messageListFile ? fileResults[nextIdx++]?.filePath ?? null : null,
  };

  // Upload to R2 in parallel (non-blocking)
  if (r2Scope) {
    try {
      const r2Promises: Promise<string>[] = [
        uploadInputToR2(dataFile, r2Scope.orgId, r2Scope.projectId),
        uploadInputToR2(surveyFile, r2Scope.orgId, r2Scope.projectId),
      ];
      if (bannerPlanFile) {
        r2Promises.push(uploadInputToR2(bannerPlanFile, r2Scope.orgId, r2Scope.projectId));
      }
      if (messageListFile) {
        r2Promises.push(uploadInputToR2(messageListFile, r2Scope.orgId, r2Scope.projectId));
      }

      const r2Keys = await Promise.all(r2Promises);
      let r2Idx = 2;
      result.r2Keys = {
        spss: r2Keys[0],
        survey: r2Keys[1],
        bannerPlan: bannerPlanFile ? r2Keys[r2Idx++] ?? null : null,
        messageList: messageListFile ? r2Keys[r2Idx++] ?? null : null,
      };
      console.log('[R2] Wizard input files uploaded successfully');
    } catch (err) {
      console.warn('[R2] Wizard input upload failed (non-fatal):', err);
    }
  }

  return result;
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
