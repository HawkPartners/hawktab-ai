/**
 * Pipeline-aware R2 file operations.
 * Wraps the low-level r2.ts primitives with org/project-scoped key patterns
 * and selective output uploading.
 */
import { uploadFile, downloadFile, getSignedDownloadUrl, buildKey } from './r2';
import { promises as fs } from 'fs';
import * as path from 'path';

// Which output files to upload to R2 (primary deliverables + metadata)
const OUTPUT_FILES_TO_UPLOAD = [
  'results/crosstabs.xlsx',
  'results/tables.json',
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
 */
export async function getDownloadUrl(
  key: string,
  expiresInSeconds: number = 3600,
): Promise<string> {
  return getSignedDownloadUrl(key, expiresInSeconds);
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

function getContentType(filename: string): string {
  const ext = path.extname(filename).toLowerCase();
  switch (ext) {
    case '.xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case '.json': return 'application/json';
    case '.r': return 'text/plain';
    default: return 'application/octet-stream';
  }
}
