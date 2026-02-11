import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';

const ACTIVE_JOB_KEY = 'crosstab-active-job';
const ACTIVE_PIPELINE_KEY = 'crosstab-active-pipeline';

interface UseJobPollingCallbacks {
  setJobId: (id: string | null) => void;
  setIsProcessing: (v: boolean) => void;
  setJobError: (err: string | null) => void;
  refresh: () => void;
}

export function useJobPolling(
  jobId: string | null,
  jobError: string | null,
  callbacks: UseJobPollingCallbacks,
) {
  const router = useRouter();
  const callbacksRef = useRef(callbacks);
  callbacksRef.current = callbacks;

  useEffect(() => {
    if (!jobId) return;
    let cancelled = false;

    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/process-crosstab/status?jobId=${encodeURIComponent(jobId)}`);
        if (!res.ok) return;
        const data = await res.json();
        if (cancelled) return;

        const { setJobId, setIsProcessing, setJobError, refresh } = callbacksRef.current;

        if (data.stage === 'cancelled') {
          clearInterval(interval);
          setIsProcessing(false);
          setJobId(null);
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          refresh();
          toast.info('Pipeline cancelled', {
            id: 'pipeline-progress',
            description: 'The processing was stopped.',
          });
          return;
        }

        if (data.stage === 'banner_review_required' || data.stage === 'crosstab_review_required') {
          clearInterval(interval);
          setIsProcessing(false);
          setJobId(null);
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          refresh();

          const reviewUrl = data.reviewUrl || `/projects/${encodeURIComponent(data.pipelineId)}/review`;
          const reviewType = data.stage === 'crosstab_review_required' ? 'Mapping Review' : 'Review';
          toast.warning(`${reviewType} Required`, {
            id: 'pipeline-progress',
            description: `${data.flaggedColumnCount || 'Some'} columns need your attention`,
            action: {
              label: 'Review Now',
              onClick: () => router.push(reviewUrl),
            },
            duration: 30000,
          });
          return;
        }

        const percent = Math.max(1, Math.min(100, Number(data.percent) || 0));
        toast.loading('Processing pipeline...', {
          id: 'pipeline-progress',
          description: `${data.message || 'Processing...'} (${percent}%)`,
          duration: Infinity,
        });

        if (data.error) setJobError(String(data.error));

        if (data.stage === 'complete' || data.stage === 'error') {
          clearInterval(interval);
          setIsProcessing(false);
          setJobId(null);
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);

          const doneOk = data.stage === 'complete' && !data.error;
          if (doneOk) {
            refresh();
            const pipelineId = data.pipelineId;
            toast.success('Pipeline complete!', {
              id: 'pipeline-progress',
              description: data.message || 'Your crosstabs have been generated.',
              action: pipelineId
                ? { label: 'View Details', onClick: () => router.push(`/projects/${encodeURIComponent(pipelineId)}`) }
                : { label: 'View History', onClick: () => {} },
            });
          } else {
            toast.error('Processing failed', {
              id: 'pipeline-progress',
              description: data.error || jobError || 'Unknown error',
            });
          }
        }
      } catch {
        // ignore transient errors
      }
    }, 1500);

    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [jobId, router, jobError]);
}
