'use client';

import { useQuery } from 'convex/react';
import { api } from '../../convex/_generated/api';
import type { Id } from '../../convex/_generated/dataModel';

/**
 * Subscribe to a Convex run's real-time state.
 * Returns the full run document (or undefined/null).
 * Pass null runId to skip the subscription.
 */
export function useRunStatus(runId: string | null) {
  return useQuery(
    api.runs.get,
    runId ? { runId: runId as Id<"runs"> } : "skip"
  );
}
