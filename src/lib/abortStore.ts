/**
 * In-memory AbortController store for pipeline runs.
 * AbortControllers are not serializable, so they stay in-memory
 * while the rest of job state lives in Convex.
 */

const controllers = new Map<string, AbortController>();

/**
 * Create a new AbortController for a run and return its signal.
 */
export function createAbortController(runId: string): AbortSignal {
  const controller = new AbortController();
  controllers.set(runId, controller);
  return controller.signal;
}

/**
 * Get the AbortSignal for a run, if one exists.
 */
export function getAbortSignal(runId: string): AbortSignal | undefined {
  return controllers.get(runId)?.signal;
}

/**
 * Abort a run. Returns true if the controller was found and aborted.
 */
export function abortRun(runId: string): boolean {
  const controller = controllers.get(runId);
  if (!controller) return false;
  controller.abort();
  return true;
}

/**
 * Clean up the AbortController for a completed run.
 */
export function cleanupAbort(runId: string): void {
  controllers.delete(runId);
}
