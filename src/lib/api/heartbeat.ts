/**
 * Heartbeat helper for pipeline liveness tracking.
 *
 * Sends periodic heartbeats to Convex so the reconciler cron can detect
 * stale runs (e.g., container died mid-pipeline) and mark them as errored.
 *
 * All heartbeat operations are non-fatal — failures are logged but never thrown.
 */
import { mutateInternal } from '@/lib/convex';
import { internal } from '../../../convex/_generated/api';
import type { Id } from '../../../convex/_generated/dataModel';

/**
 * Send a single heartbeat for a run. Non-fatal — warns on failure, never throws.
 */
export async function sendHeartbeat(runId: string): Promise<void> {
  try {
    await mutateInternal(internal.runs.heartbeat, {
      runId: runId as Id<"runs">,
    });
  } catch (err) {
    console.warn('[Heartbeat] Failed to send heartbeat:', err);
  }
}

/**
 * Start a periodic heartbeat interval for a run.
 * Sends an initial heartbeat immediately, then repeats every `intervalMs`.
 *
 * Returns a cleanup function that stops the interval.
 */
export function startHeartbeatInterval(
  runId: string,
  intervalMs = 30_000,
): () => void {
  // Fire initial heartbeat (non-blocking)
  sendHeartbeat(runId);

  const timer = setInterval(() => {
    sendHeartbeat(runId);
  }, intervalMs);

  return () => {
    clearInterval(timer);
  };
}
