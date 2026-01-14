'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import FileUpload from '../components/FileUpload';
import { useValidationQueue } from '../hooks/useValidationQueue';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { PageHeader } from '@/components/PageHeader';
import { PipelineHistory } from '@/components/PipelineHistory';

const ACTIVE_JOB_KEY = 'crosstab-active-job';

export default function Home() {
  const [dataMapFile, setDataMapFile] = useState<File | null>(null);
  const [bannerPlanFile, setBannerPlanFile] = useState<File | null>(null);
  const [dataFile, setDataFile] = useState<File | null>(null);
  const [surveyFile, setSurveyFile] = useState<File | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [jobId, setJobId] = useState<string | null>(null);
  const [jobError, setJobError] = useState<string | null>(null);
  const router = useRouter();
  const { counts, refresh } = useValidationQueue();

  // Restore active job from localStorage on mount
  useEffect(() => {
    const savedJobId = localStorage.getItem(ACTIVE_JOB_KEY);
    if (savedJobId) {
      // Check if job is still active
      fetch(`/api/process-crosstab/status?jobId=${encodeURIComponent(savedJobId)}`)
        .then(res => res.json())
        .then(data => {
          if (data.stage && data.stage !== 'complete' && data.stage !== 'error') {
            // Job still running - restore state
            setJobId(savedJobId);
            setIsProcessing(true);
            toast.loading('Processing pipeline...', {
              id: 'pipeline-progress',
              description: `${data.message || 'Processing...'} (${data.percent || 0}%)`,
              duration: Infinity,
            });
          } else {
            // Job finished - clear storage
            localStorage.removeItem(ACTIVE_JOB_KEY);
          }
        })
        .catch(() => {
          // Error checking - clear storage
          localStorage.removeItem(ACTIVE_JOB_KEY);
        });
    }
  }, []);

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

    } catch (error) {
      console.error('Processing error:', error);
      setIsProcessing(false);
      toast.error('Processing failed', {
        id: 'pipeline-progress',
        description: error instanceof Error ? error.message : 'Unknown error occurred',
      });
    }
  };

  const handleCancel = () => {
    // Clear processing state
    setIsProcessing(false);
    setJobId(null);
    setJobError(null);
    localStorage.removeItem(ACTIVE_JOB_KEY);

    // Dismiss the toast
    toast.dismiss('pipeline-progress');

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
