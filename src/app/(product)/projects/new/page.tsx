'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useValidationQueue } from '@/hooks/useValidationQueue';
import { useLoopDetection } from '@/hooks/useLoopDetection';
import { useRunProgress } from '@/hooks/useRunProgress';
import { UploadForm, type UploadedFiles } from '@/components/upload-form';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { PageHeader } from '@/components/PageHeader';
import { toast } from 'sonner';

export default function NewProjectPage() {
  const [dataFile, setDataFile] = useState<File | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [runId, setRunId] = useState<string | null>(null);
  const [, setRunError] = useState<string | null>(null);
  const router = useRouter();
  const { counts, refresh } = useValidationQueue();
  const { loopDetection, isDetectingLoops, loopStatTestingMode, setLoopStatTestingMode } = useLoopDetection(dataFile);

  useRunProgress(runId, { setRunId, setIsProcessing, setRunError: setRunError, refresh });

  const handleSubmit = useCallback(async (files: UploadedFiles) => {
    setIsProcessing(true);
    setRunError(null);

    toast.loading('Processing pipeline...', {
      id: 'pipeline-progress',
      description: 'Starting...',
      duration: Infinity,
    });

    try {
      const formData = new FormData();
      formData.append('dataMap', files.dataMap);
      formData.append('bannerPlan', files.bannerPlan);
      formData.append('dataFile', files.dataFile);
      if (files.survey) {
        formData.append('surveyDocument', files.survey);
      }
      if (loopDetection?.hasLoops) {
        formData.append('loopStatTestingMode', loopStatTestingMode);
      }

      const response = await fetch('/api/process-crosstab', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Processing failed');
      }

      const result = await response.json();
      if (result.runId) {
        setRunId(result.runId);
      }
    } catch (error) {
      console.error('Processing error:', error);
      setIsProcessing(false);
      toast.error('Processing failed', {
        id: 'pipeline-progress',
        description: error instanceof Error ? error.message : 'Unknown error occurred',
      });
    }
  }, [loopDetection, loopStatTestingMode]);

  const handleCancel = useCallback(async () => {
    if (!runId) {
      setIsProcessing(false);
      toast.dismiss('pipeline-progress');
      return;
    }

    toast.loading('Cancelling pipeline...', {
      id: 'pipeline-progress',
      description: 'Stopping processing...',
      duration: Infinity,
    });

    try {
      await fetch(`/api/runs/${encodeURIComponent(runId)}/cancel`, { method: 'POST' });
    } catch (error) {
      console.error('[Cancel] Error cancelling pipeline:', error);
    }

    setIsProcessing(false);
    setRunId(null);
    setRunError(null);
    toast.dismiss('pipeline-progress');
    refresh();
    toast.info('Pipeline cancelled', { description: 'The processing has been stopped.' });
  }, [runId, refresh]);

  return (
    <div>
      <AppBreadcrumbs segments={[{ label: 'Dashboard', href: '/dashboard' }, { label: 'New Project' }]} />

      <div className="max-w-6xl mt-6">
        <PageHeader
          title="New Project"
          description="Upload your data files to generate automated crosstabs. Provide a data map, banner plan, and your raw data to get started."
          actions={
            <div className="flex items-center gap-2">
              <div className="relative">
                <Button
                  onClick={() => router.push('/validate')}
                  variant="secondary"
                >
                  Validation Queue
                </Button>
                {counts.pending > 0 && (
                  <Badge variant="destructive" className="absolute -top-2 -right-2 h-5 w-5 p-0 flex items-center justify-center text-xs">
                    {counts.pending}
                  </Badge>
                )}
              </div>
            </div>
          }
        />

        <UploadForm
          isProcessing={isProcessing}
          loopDetection={loopDetection}
          isDetectingLoops={isDetectingLoops}
          loopStatTestingMode={loopStatTestingMode}
          onLoopStatTestingModeChange={setLoopStatTestingMode}
          onSubmit={handleSubmit}
          onCancel={handleCancel}
          onDataFileChange={setDataFile}
        />
      </div>
    </div>
  );
}
