/**
 * useValidationQueue
 * Purpose: Fetch and expose counts for validation queue for dashboard widgets
 * Source: GET /api/validation-queue
 */
import { useState, useEffect, useCallback } from 'react';

interface ValidationCounts {
  total: number;
  pending: number;
  validated: number;
}

export function useValidationQueue() {
  const [counts, setCounts] = useState<ValidationCounts>({ total: 0, pending: 0, validated: 0 });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchCounts = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      const response = await fetch('/api/validation-queue');
      if (!response.ok) {
        throw new Error('Failed to fetch validation queue');
      }
      
      const data = await response.json();
      setCounts(data.counts || { total: 0, pending: 0, validated: 0 });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setCounts({ total: 0, pending: 0, validated: 0 });
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Fetch on mount
  useEffect(() => {
    fetchCounts();
  }, [fetchCounts]);

  // Refresh function for after processing
  const refresh = useCallback(() => {
    fetchCounts();
  }, [fetchCounts]);

  return {
    counts,
    isLoading,
    error,
    refresh
  };
}