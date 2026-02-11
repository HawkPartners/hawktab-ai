/**
 * Manages temporary directories for pipeline runs.
 * Provides create/get/cleanup lifecycle for run-scoped temp dirs.
 */
import { promises as fs } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

const TEMP_BASE = join(tmpdir(), 'hawktab-ai', 'runs');

/**
 * Create a temp directory for a pipeline run.
 * Pattern: /tmp/hawktab-ai/runs/{runId}/
 */
export async function createRunTempDir(runId: string): Promise<string> {
  const dir = join(TEMP_BASE, runId);
  await fs.mkdir(dir, { recursive: true });
  return dir;
}

/**
 * Get the temp directory path for a run (does not create it).
 */
export function getTempDir(runId: string): string {
  return join(TEMP_BASE, runId);
}

/**
 * Check if a run's temp directory exists.
 */
export async function tempDirExists(runId: string): Promise<boolean> {
  try {
    const stat = await fs.stat(join(TEMP_BASE, runId));
    return stat.isDirectory();
  } catch {
    return false;
  }
}

/**
 * Delete a run's temp directory and all contents.
 */
export async function cleanupRunTempDir(runId: string): Promise<void> {
  try {
    await fs.rm(join(TEMP_BASE, runId), { recursive: true, force: true });
  } catch {
    // Ignore cleanup errors
  }
}

/**
 * Remove temp directories older than maxAgeMs (default 24 hours).
 */
export async function cleanupStaleTempDirs(maxAgeMs: number = 24 * 60 * 60 * 1000): Promise<number> {
  let cleaned = 0;
  try {
    const entries = await fs.readdir(TEMP_BASE, { withFileTypes: true });
    const now = Date.now();

    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      try {
        const stat = await fs.stat(join(TEMP_BASE, entry.name));
        if (now - stat.mtimeMs > maxAgeMs) {
          await fs.rm(join(TEMP_BASE, entry.name), { recursive: true, force: true });
          cleaned++;
        }
      } catch {
        // Skip entries we can't stat
      }
    }
  } catch {
    // TEMP_BASE may not exist yet
  }
  return cleaned;
}
