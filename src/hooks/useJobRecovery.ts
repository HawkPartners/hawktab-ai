import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';

const ACTIVE_JOB_KEY = 'crosstab-active-job';
const ACTIVE_PIPELINE_KEY = 'crosstab-active-pipeline';

interface UseJobRecoveryCallbacks {
  setJobId: (id: string | null) => void;
  setIsProcessing: (v: boolean) => void;
}

export function useJobRecovery({ setJobId, setIsProcessing }: UseJobRecoveryCallbacks) {
  const router = useRouter();

  useEffect(() => {
    const savedJobId = localStorage.getItem(ACTIVE_JOB_KEY);
    const savedPipelineId = localStorage.getItem(ACTIVE_PIPELINE_KEY);

    const recoverFromDiskState = async (pipelineId: string) => {
      try {
        const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}`);
        if (!res.ok) {
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          return;
        }

        const data = await res.json();
        const terminalStatuses = ['success', 'error', 'cancelled', 'partial'];

        if (terminalStatuses.includes(data.status)) {
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          return;
        }

        if (data.status === 'pending_review' && data.review?.reviewUrl) {
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          toast.warning('Review Required', {
            description: `${data.review.flaggedColumnCount || 'Some'} columns need your attention`,
            action: {
              label: 'Review Now',
              onClick: () => router.push(data.review.reviewUrl),
            },
            duration: 30000,
          });
          return;
        }

        if (data.status === 'in_progress' || data.status === 'awaiting_tables') {
          setIsProcessing(true);
          toast.loading('Processing pipeline...', {
            id: 'pipeline-progress',
            description: data.status === 'awaiting_tables'
              ? 'Completing pipeline...'
              : 'Processing crosstabs...',
            duration: Infinity,
          });
          return;
        }

        localStorage.removeItem(ACTIVE_JOB_KEY);
        localStorage.removeItem(ACTIVE_PIPELINE_KEY);
      } catch {
        localStorage.removeItem(ACTIVE_JOB_KEY);
        localStorage.removeItem(ACTIVE_PIPELINE_KEY);
      }
    };

    if (savedJobId) {
      fetch(`/api/process-crosstab/status?jobId=${encodeURIComponent(savedJobId)}`)
        .then(res => res.json())
        .then(data => {
          const terminalStages = ['complete', 'error', 'cancelled'];
          if (data.stage && !terminalStages.includes(data.stage)) {
            setJobId(savedJobId);
            setIsProcessing(true);
            toast.loading('Processing pipeline...', {
              id: 'pipeline-progress',
              description: `${data.message || 'Processing...'} (${data.percent || 0}%)`,
              duration: Infinity,
            });
          } else {
            localStorage.removeItem(ACTIVE_JOB_KEY);
            localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          }
        })
        .catch(() => {
          if (savedPipelineId) {
            recoverFromDiskState(savedPipelineId);
          } else {
            localStorage.removeItem(ACTIVE_JOB_KEY);
          }
        });
    } else if (savedPipelineId) {
      recoverFromDiskState(savedPipelineId);
    }
  }, [router, setJobId, setIsProcessing]);
}
