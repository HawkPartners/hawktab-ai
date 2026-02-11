'use client';

import { createContext, useContext, useCallback, useRef, useEffect, useState, type ReactNode } from 'react';

export interface PipelineStatusData {
  stage: string;
  percent: number;
  message: string;
  error?: string;
  pipelineId?: string;
}

interface PipelineStatusContextValue {
  subscribe: (pipelineId: string) => void;
  unsubscribe: (pipelineId: string) => void;
  getStatus: (pipelineId: string) => PipelineStatusData | null;
}

const PipelineStatusContext = createContext<PipelineStatusContextValue | null>(null);

const POLL_INTERVAL = 5000;

export function PipelineStatusProvider({ children }: { children: ReactNode }) {
  const subscriptionsRef = useRef(new Set<string>());
  const [statusMap, setStatusMap] = useState<Map<string, PipelineStatusData>>(new Map());
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const pollStatuses = useCallback(async () => {
    const ids = Array.from(subscriptionsRef.current);
    if (ids.length === 0) return;

    for (const pipelineId of ids) {
      try {
        const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}`);
        if (!res.ok) continue;
        const data = await res.json();
        setStatusMap(prev => {
          const next = new Map(prev);
          next.set(pipelineId, {
            stage: data.currentStage || data.status || 'unknown',
            percent: data.outputs ? 100 : 0,
            message: data.status || '',
            error: data.error,
            pipelineId,
          });
          return next;
        });
      } catch {
        // Ignore transient errors
      }
    }
  }, []);

  // Start/stop polling based on active subscriptions
  useEffect(() => {
    if (subscriptionsRef.current.size > 0 && !intervalRef.current) {
      pollStatuses();
      intervalRef.current = setInterval(pollStatuses, POLL_INTERVAL);
    }
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [pollStatuses]);

  const subscribe = useCallback((pipelineId: string) => {
    subscriptionsRef.current.add(pipelineId);
    if (!intervalRef.current) {
      pollStatuses();
      intervalRef.current = setInterval(pollStatuses, POLL_INTERVAL);
    }
  }, [pollStatuses]);

  const unsubscribe = useCallback((pipelineId: string) => {
    subscriptionsRef.current.delete(pipelineId);
    if (subscriptionsRef.current.size === 0 && intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }
  }, []);

  const getStatus = useCallback((pipelineId: string): PipelineStatusData | null => {
    return statusMap.get(pipelineId) ?? null;
  }, [statusMap]);

  return (
    <PipelineStatusContext.Provider value={{ subscribe, unsubscribe, getStatus }}>
      {children}
    </PipelineStatusContext.Provider>
  );
}

export function usePipelineStatus() {
  const ctx = useContext(PipelineStatusContext);
  if (!ctx) throw new Error('usePipelineStatus must be used within a PipelineStatusProvider');
  return ctx;
}
