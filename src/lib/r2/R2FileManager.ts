/**
 * Pipeline-aware R2 file operations.
 * Wraps the low-level r2.ts primitives with org/project-scoped key patterns
 * and selective output uploading.
 */
import { uploadFile, downloadFile, deleteFile, getSignedDownloadUrl, buildKey } from './r2';
import { promises as fs } from 'fs';
import * as path from 'path';

// Which output files to upload to R2 (primary deliverables + metadata)
// Includes weighted/unweighted variants and separate-workbook counts files
const OUTPUT_FILES_TO_UPLOAD = [
  'results/crosstabs.xlsx',
  'results/crosstabs-weighted.xlsx',
  'results/crosstabs-unweighted.xlsx',
  'results/crosstabs-counts.xlsx',
  'results/crosstabs-weighted-counts.xlsx',
  'results/tables.json',
  'results/tables-weighted.json',
  'results/tables-unweighted.json',
  'r/master.R',
  'pipeline-summary.json',
];

export interface R2FileManifest {
  inputs: Record<string, string>;   // originalFilename → R2 key
  outputs: Record<string, string>;  // relativePath → R2 key
}

/**
 * Upload an input file to R2.
 * Key pattern: {orgId}/{projectId}/inputs/{filename}
 */
export async function uploadInputFile(
  orgId: string,
  projectId: string,
  fileBuffer: Buffer,
  filename: string,
  contentType?: string,
): Promise<string> {
  const key = buildKey(orgId, projectId, 'inputs', filename);
  await uploadFile(key, fileBuffer, contentType);
  return key;
}

/**
 * Upload selected pipeline output files to R2.
 * Key pattern: {orgId}/{projectId}/runs/{runId}/outputs/{relativePath}
 * Only uploads files from OUTPUT_FILES_TO_UPLOAD that exist.
 */
export async function uploadPipelineOutputs(
  orgId: string,
  projectId: string,
  runId: string,
  localOutputDir: string,
): Promise<R2FileManifest> {
  const manifest: R2FileManifest = { inputs: {}, outputs: {} };

  const uploadPromises = OUTPUT_FILES_TO_UPLOAD.map(async (relativePath) => {
    const localPath = path.join(localOutputDir, relativePath);
    try {
      const buffer = await fs.readFile(localPath);
      const key = buildKey(orgId, projectId, `runs/${runId}/outputs`, relativePath.replace(/\//g, '_'));
      const contentType = getContentType(relativePath);
      await uploadFile(key, buffer, contentType);
      manifest.outputs[relativePath] = key;
      console.log(`[R2] Uploaded ${relativePath} → ${key}`);
    } catch {
      // File doesn't exist or upload failed — skip silently
      console.warn(`[R2] Skipped ${relativePath} (not found or upload failed)`);
    }
  });

  await Promise.all(uploadPromises);
  return manifest;
}

/**
 * Get a presigned download URL for an R2 key.
 * Optionally sets Content-Disposition so the browser saves with a friendly filename.
 */
export async function getDownloadUrl(
  key: string,
  expiresInSeconds: number = 3600,
  responseContentDisposition?: string,
): Promise<string> {
  return getSignedDownloadUrl(key, expiresInSeconds, responseContentDisposition);
}

/**
 * Download a file from R2 to a local path.
 * Creates parent directories as needed.
 */
export async function downloadToTemp(
  key: string,
  localPath: string,
): Promise<void> {
  const buffer = await downloadFile(key);
  await fs.mkdir(path.dirname(localPath), { recursive: true });
  await fs.writeFile(localPath, buffer);
}

// -------------------------------------------------------------------------
// Review State Persistence (HITL R2 backup)
// -------------------------------------------------------------------------

/** R2 keys for review state files, stored in Convex run.result.reviewR2Keys */
export interface ReviewR2Keys {
  reviewState?: string;      // crosstab-review-state.json
  pipelineSummary?: string;  // pipeline-summary.json
  pathBResult?: string;      // path-b-result.json
  pathCResult?: string;      // path-c-result.json
  spssInput?: string;        // original SPSS file (already in R2 from upload)
}

/**
 * Upload a single review file to R2.
 * Key pattern: {orgId}/{projectId}/runs/{runId}/review/{filename}
 * Returns the R2 key on success.
 */
export async function uploadReviewFile(
  orgId: string,
  projectId: string,
  runId: string,
  localFilePath: string,
  filename: string,
): Promise<string> {
  const buffer = await fs.readFile(localFilePath);
  const key = buildKey(orgId, projectId, `runs/${runId}/review`, filename);
  const contentType = getContentType(filename);
  await uploadFile(key, buffer, contentType);
  console.log(`[R2] Uploaded review file: ${filename} → ${key}`);
  return key;
}

/**
 * Download all review files from R2 into a local directory.
 * SPSS goes into {localDir}/inputs/, JSON files go into root.
 * Returns map of logical name → local path for downloaded files.
 */
export async function downloadReviewFiles(
  reviewR2Keys: ReviewR2Keys,
  localOutputDir: string,
): Promise<Record<string, string>> {
  await fs.mkdir(localOutputDir, { recursive: true });
  const downloaded: Record<string, string> = {};

  const jsonFiles: Array<{ key: keyof ReviewR2Keys; filename: string }> = [
    { key: 'reviewState', filename: 'crosstab-review-state.json' },
    { key: 'pipelineSummary', filename: 'pipeline-summary.json' },
    { key: 'pathBResult', filename: 'path-b-result.json' },
    { key: 'pathCResult', filename: 'path-c-result.json' },
  ];

  for (const { key, filename } of jsonFiles) {
    const r2Key = reviewR2Keys[key];
    if (!r2Key) continue;
    try {
      const localPath = path.join(localOutputDir, filename);
      await downloadToTemp(r2Key, localPath);
      downloaded[key] = localPath;
      console.log(`[R2] Downloaded review file: ${filename}`);
    } catch (err) {
      console.warn(`[R2] Failed to download review file ${filename}:`, err);
    }
  }

  // SPSS goes into inputs/ subdirectory
  if (reviewR2Keys.spssInput) {
    try {
      const inputsDir = path.join(localOutputDir, 'inputs');
      await fs.mkdir(inputsDir, { recursive: true });
      // Extract original filename from R2 key (last segment)
      const spssFilename = reviewR2Keys.spssInput.split('/').pop() || 'dataFile.sav';
      const localPath = path.join(inputsDir, spssFilename);
      await downloadToTemp(reviewR2Keys.spssInput, localPath);
      downloaded['spssInput'] = localPath;
      console.log(`[R2] Downloaded SPSS file: ${spssFilename}`);
    } catch (err) {
      console.warn('[R2] Failed to download SPSS file:', err);
    }
  }

  return downloaded;
}

/**
 * Delete review files from R2 after pipeline completion.
 * Skips spssInput key (shared with initial input upload).
 * Non-fatal — errors are logged but not thrown.
 */
export async function deleteReviewFiles(reviewR2Keys: ReviewR2Keys): Promise<void> {
  // Auto-enumerate all keys except spssInput (shared with initial input upload)
  const keysToDelete: string[] = [];
  for (const [field, value] of Object.entries(reviewR2Keys)) {
    if (field === 'spssInput') continue; // shared — do not delete
    if (typeof value === 'string' && value) keysToDelete.push(value);
  }

  for (const key of keysToDelete) {
    try {
      await deleteFile(key);
      console.log(`[R2] Deleted review file: ${key}`);
    } catch (err) {
      console.warn(`[R2] Failed to delete review file ${key}:`, err);
    }
  }
}

function getContentType(filename: string): string {
  const ext = path.extname(filename).toLowerCase();
  switch (ext) {
    case '.xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case '.json': return 'application/json';
    case '.r': return 'text/plain';
    default: return 'application/octet-stream';
  }
}
