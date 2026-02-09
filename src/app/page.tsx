'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import FileUpload from '../components/FileUpload';
import { useValidationQueue } from '../hooks/useValidationQueue';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { toast } from 'sonner';
import { PageHeader } from '@/components/PageHeader';
import { PipelineHistory } from '@/components/PipelineHistory';

const ACTIVE_JOB_KEY = 'crosstab-active-job';
const ACTIVE_PIPELINE_KEY = 'crosstab-active-pipeline';

export default function Home() {
  const [dataMapFile, setDataMapFile] = useState<File | null>(null);
  const [bannerPlanFile, setBannerPlanFile] = useState<File | null>(null);
  const [dataFile, setDataFile] = useState<File | null>(null);
  const [surveyFile, setSurveyFile] = useState<File | null>(null);
  const [loopDetection, setLoopDetection] = useState<{ hasLoops: boolean; loopCount: number } | null>(null);
  const [isDetectingLoops, setIsDetectingLoops] = useState(false);
  const [loopStatTestingMode, setLoopStatTestingMode] = useState<'suppress' | 'complement'>('suppress');
  const [isProcessing, setIsProcessing] = useState(false);
  const [jobId, setJobId] = useState<string | null>(null);
  const [jobError, setJobError] = useState<string | null>(null);
  const router = useRouter();
  const { counts, refresh } = useValidationQueue();

  // Detect loop presence when data file changes
  useEffect(() => {
    let cancelled = false;

    const detectLoops = async () => {
      if (!dataFile) {
        setLoopDetection(null);
        setIsDetectingLoops(false);
        setLoopStatTestingMode('suppress');
        return;
      }

      const lowerName = dataFile.name.toLowerCase();
      if (!lowerName.endsWith('.sav')) {
        setLoopDetection(null);
        setIsDetectingLoops(false);
        setLoopStatTestingMode('suppress');
        return;
      }

      setIsDetectingLoops(true);
      try {
        const fd = new FormData();
        fd.append('dataFile', dataFile);
        const res = await fetch('/api/loop-detect', { method: 'POST', body: fd });
        if (!res.ok) throw new Error('Loop detection failed');
        const data = await res.json();
        if (cancelled) return;
        setLoopDetection({ hasLoops: !!data.hasLoops, loopCount: Number(data.loopCount) || 0 });
        if (!data.hasLoops) {
          setLoopStatTestingMode('suppress');
        }
      } catch {
        if (!cancelled) {
          setLoopDetection({ hasLoops: false, loopCount: 0 });
          setLoopStatTestingMode('suppress');
        }
      } finally {
        if (!cancelled) setIsDetectingLoops(false);
      }
    };

    detectLoops();
    return () => {
      cancelled = true;
    };
  }, [dataFile]);

  // Restore active job from localStorage on mount
  useEffect(() => {
    const savedJobId = localStorage.getItem(ACTIVE_JOB_KEY);
    const savedPipelineId = localStorage.getItem(ACTIVE_PIPELINE_KEY);

    const recoverFromDiskState = async (pipelineId: string) => {
      try {
        const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}`);
        if (!res.ok) {
          // Pipeline not found - clear storage
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          return;
        }

        const data = await res.json();
        const terminalStatuses = ['success', 'error', 'cancelled', 'partial'];

        if (terminalStatuses.includes(data.status)) {
          // Pipeline finished - clear storage
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          return;
        }

        if (data.status === 'pending_review' && data.review?.reviewUrl) {
          // Redirect to review page
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
          // Pipeline still running - show processing state
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

        // Unknown status - clear storage
        localStorage.removeItem(ACTIVE_JOB_KEY);
        localStorage.removeItem(ACTIVE_PIPELINE_KEY);
      } catch {
        // Error checking disk state - clear storage
        localStorage.removeItem(ACTIVE_JOB_KEY);
        localStorage.removeItem(ACTIVE_PIPELINE_KEY);
      }
    };

    if (savedJobId) {
      // Check if job is still active in memory
      fetch(`/api/process-crosstab/status?jobId=${encodeURIComponent(savedJobId)}`)
        .then(res => res.json())
        .then(data => {
          // Check for terminal states (complete, error, cancelled)
          const terminalStages = ['complete', 'error', 'cancelled'];
          if (data.stage && !terminalStages.includes(data.stage)) {
            // Job still running in memory - restore state
            setJobId(savedJobId);
            setIsProcessing(true);
            toast.loading('Processing pipeline...', {
              id: 'pipeline-progress',
              description: `${data.message || 'Processing...'} (${data.percent || 0}%)`,
              duration: Infinity,
            });
          } else {
            // Job finished or cancelled - clear storage
            localStorage.removeItem(ACTIVE_JOB_KEY);
            localStorage.removeItem(ACTIVE_PIPELINE_KEY);
          }
        })
        .catch(() => {
          // Job not in memory - try to recover from disk state
          if (savedPipelineId) {
            recoverFromDiskState(savedPipelineId);
          } else {
            localStorage.removeItem(ACTIVE_JOB_KEY);
          }
        });
    } else if (savedPipelineId) {
      // No jobId but have pipelineId - check disk state
      recoverFromDiskState(savedPipelineId);
    }
  }, [router]);

  // Required files check (survey is optional)
  const requiredFilesUploaded = dataMapFile && bannerPlanFile && dataFile;

  const handleSubmit = async () => {
    if (!requiredFilesUploaded) return;

    setIsProcessing(true);
    setJobError(null);

    // Clear uploaded files immediately so UI shows empty state
    const submittedFiles = {
      dataMap: dataMapFile!,
      bannerPlan: bannerPlanFile!,
      dataFile: dataFile!,
      survey: surveyFile,
    };
    setDataMapFile(null);
    setBannerPlanFile(null);
    setDataFile(null);
    setSurveyFile(null);

    // Show initial toast
    toast.loading('Processing pipeline...', {
      id: 'pipeline-progress',
      description: 'Starting...',
      duration: Infinity,
    });

    try {
      const formData = new FormData();
      formData.append('dataMap', submittedFiles.dataMap);
      formData.append('bannerPlan', submittedFiles.bannerPlan);
      formData.append('dataFile', submittedFiles.dataFile);
      if (submittedFiles.survey) {
        formData.append('surveyDocument', submittedFiles.survey);
      }
      if (loopDetection?.hasLoops) {
        formData.append('loopStatTestingMode', loopStatTestingMode);
      }

      // Call our API endpoint for complete processing (returns early with jobId)
      const response = await fetch('/api/process-crosstab', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Processing failed');
      }

      const result = await response.json();
      if (result.jobId) {
        setJobId(result.jobId);
        localStorage.setItem(ACTIVE_JOB_KEY, result.jobId);
      }
      if (result.pipelineId) {
        localStorage.setItem(ACTIVE_PIPELINE_KEY, result.pipelineId);
      }

    } catch (error) {
      console.error('Processing error:', error);
      setIsProcessing(false);
      toast.error('Processing failed', {
        id: 'pipeline-progress',
        description: error instanceof Error ? error.message : 'Unknown error occurred',
      });
    }
  };

  const handleCancel = async () => {
    if (!jobId) {
      // No job to cancel, just clear UI state
      setIsProcessing(false);
      toast.dismiss('pipeline-progress');
      return;
    }

    // Show cancelling state
    toast.loading('Cancelling pipeline...', {
      id: 'pipeline-progress',
      description: 'Stopping processing...',
      duration: Infinity,
    });

    try {
      // First, get the pipelineId from job status
      const statusRes = await fetch(`/api/process-crosstab/status?jobId=${encodeURIComponent(jobId)}`);
      if (statusRes.ok) {
        const statusData = await statusRes.json();
        const pipelineId = statusData.pipelineId;

        if (pipelineId) {
          // Call the cancel API to actually stop the pipeline
          const cancelRes = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}/cancel`, {
            method: 'POST',
          });

          if (cancelRes.ok) {
            const cancelData = await cancelRes.json();
            console.log('[Cancel] Pipeline cancelled:', cancelData);
          } else {
            console.warn('[Cancel] Cancel API returned error:', await cancelRes.text());
          }
        }
      }
    } catch (error) {
      console.error('[Cancel] Error cancelling pipeline:', error);
    }

    // Clear processing state regardless of API success
    setIsProcessing(false);
    setJobId(null);
    setJobError(null);
    localStorage.removeItem(ACTIVE_JOB_KEY);
    localStorage.removeItem(ACTIVE_PIPELINE_KEY);

    // Dismiss the toast
    toast.dismiss('pipeline-progress');

    // Refresh pipeline history to show cancelled status
    refresh();

    // Show cancellation confirmation
    toast.info('Pipeline cancelled', {
      description: 'The processing has been stopped.',
    });
  };

  // Poll job progress when jobId is set
  React.useEffect(() => {
    if (!jobId) return;
    let cancelled = false;
    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/process-crosstab/status?jobId=${encodeURIComponent(jobId)}`);
        if (!res.ok) return;
        const data = await res.json();
        if (cancelled) return;

        // Check if cancelled (either by user or detected from server)
        if (data.stage === 'cancelled') {
          clearInterval(interval);
          setIsProcessing(false);
          setJobId(null);
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);

          // Refresh pipeline history
          refresh();

          toast.info('Pipeline cancelled', {
            id: 'pipeline-progress',
            description: 'The processing was stopped.',
          });
          return;
        }

        // Check if review is required (both banner and crosstab review stages)
        if (data.stage === 'banner_review_required' || data.stage === 'crosstab_review_required') {
          clearInterval(interval);
          setIsProcessing(false);
          setJobId(null);
          localStorage.removeItem(ACTIVE_JOB_KEY);
          localStorage.removeItem(ACTIVE_PIPELINE_KEY);

          // Refresh pipeline history
          refresh();

          const reviewUrl = data.reviewUrl || `/pipelines/${encodeURIComponent(data.pipelineId)}/review`;
          const reviewType = data.stage === 'crosstab_review_required' ? 'Mapping Review' : 'Review';
          toast.warning(`${reviewType} Required`, {
            id: 'pipeline-progress',
            description: `${data.flaggedColumnCount || 'Some'} columns need your attention`,
            action: {
              label: 'Review Now',
              onClick: () => router.push(reviewUrl),
            },
            duration: 30000, // Show for 30 seconds
          });
          return;
        }

        // Update toast with progress
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
            // Refresh pipeline history counts
            refresh();

            // Show success toast with action to view pipeline
            const pipelineId = data.pipelineId;
            toast.success('Pipeline complete!', {
              id: 'pipeline-progress',
              description: data.message || 'Your crosstabs have been generated.',
              action: pipelineId
                ? { label: 'View Details', onClick: () => router.push(`/pipelines/${encodeURIComponent(pipelineId)}`) }
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
  }, [jobId, router, refresh, jobError]);

  return (
    <div className="py-12 px-4">
      <div className="max-w-6xl mx-auto">
        <PageHeader
          title="CrossTab AI - Crosstab Generator"
          description="Upload your data files to generate automated crosstabs. Provide a data map, banner plan, and your raw data to get started."
          actions={
            <div className="flex items-center gap-2">
              <PipelineHistory />
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

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <FileUpload
            title="Data Map"
            description="Upload your data mapping file"
            acceptedTypes=".csv,.xlsx"
            fileExtensions={['.csv', '.xlsx']}
            onFileSelect={setDataMapFile}
            selectedFile={dataMapFile}
          />

          <FileUpload
            title="Banner Plan"
            description="Upload your banner plan document"
            acceptedTypes=".doc,.docx,.pdf"
            fileExtensions={['.doc', '.docx', '.pdf']}
            onFileSelect={setBannerPlanFile}
            selectedFile={bannerPlanFile}
          />

          <FileUpload
            title="Data File"
            description="Upload your SPSS data file"
            acceptedTypes=".sav,.spss"
            fileExtensions={['.sav', '.spss']}
            onFileSelect={setDataFile}
            selectedFile={dataFile}
          />

          <FileUpload
            title="Survey Document"
            description="Upload questionnaire for enhanced table labels"
            acceptedTypes=".doc,.docx"
            fileExtensions={['.doc', '.docx']}
            onFileSelect={setSurveyFile}
            selectedFile={surveyFile}
            optional
          />
        </div>

        {dataFile && (
          <div className="mb-8 flex justify-center">
            <div className="w-full max-w-2xl rounded-lg border border-muted p-4">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <p className="text-sm font-medium">Loop stat testing</p>
                  <p className="text-xs text-muted-foreground">
                    {isDetectingLoops
                      ? 'Detecting loops in data file...'
                      : loopDetection?.hasLoops
                        ? `Loops detected (${loopDetection.loopCount})`
                        : 'No loops detected'}
                  </p>
                </div>
                {loopDetection?.hasLoops && (
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-muted-foreground">Suppress</span>
                    <Switch
                      checked={loopStatTestingMode === 'complement'}
                      onCheckedChange={(checked) => setLoopStatTestingMode(checked ? 'complement' : 'suppress')}
                      aria-label="Toggle complement testing for loop tables"
                    />
                    <span className="text-xs text-muted-foreground">Complement</span>
                  </div>
                )}
              </div>
              {loopDetection?.hasLoops && (
                <p className="mt-2 text-xs text-muted-foreground">
                  Complement compares each cut vs not-A. Suppress disables within-group letters for entity-anchored loop groups.
                </p>
              )}
            </div>
          </div>
        )}

        <div className="text-center">
          {isProcessing ? (
            <div className="flex flex-col items-center gap-4">
              <p className="text-sm text-muted-foreground">
                Pipeline is running in the background. You can navigate away or cancel below.
              </p>
              <Button
                onClick={handleCancel}
                variant="outline"
                size="lg"
                className="px-8"
              >
                Cancel Pipeline
              </Button>
            </div>
          ) : (
            <>
              <Button
                onClick={handleSubmit}
                disabled={!requiredFilesUploaded}
                size="lg"
                className="px-8"
              >
                Generate Crosstabs
              </Button>

              {!requiredFilesUploaded && (
                <p className="text-sm text-muted-foreground mt-2">
                  Please upload the required files to continue
                </p>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
