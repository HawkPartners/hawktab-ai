'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import FileUpload from '../components/FileUpload';
import LoadingModal, { ProcessingStep, type JobProgress } from '../components/LoadingModal';
import { useValidationQueue } from '../hooks/useValidationQueue';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { PageHeader } from '@/components/PageHeader';

export default function Home() {
  const [dataMapFile, setDataMapFile] = useState<File | null>(null);
  const [bannerPlanFile, setBannerPlanFile] = useState<File | null>(null);
  const [dataFile, setDataFile] = useState<File | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [processingStep, setProcessingStep] = useState<ProcessingStep | undefined>();
  const [jobId, setJobId] = useState<string | null>(null);
  const [jobProgress, setJobProgress] = useState<JobProgress | undefined>();
  const [, setJobStage] = useState<string | null>(null);
  const [jobError, setJobError] = useState<string | null>(null);
  const [jobStartTs, setJobStartTs] = useState<number | null>(null);
  const router = useRouter();
  const { counts, refresh } = useValidationQueue();

  const allFilesUploaded = dataMapFile && bannerPlanFile && dataFile;

  const handleSubmit = async () => {
    if (!allFilesUploaded) return;
    
    setIsProcessing(true);
    setProcessingStep({ step: 'initial', message: 'Processing your files...' });
    
    try {
      const formData = new FormData();
      formData.append('dataMap', dataMapFile!);
      formData.append('bannerPlan', bannerPlanFile!);
      formData.append('dataFile', dataFile!);
      
      // Call our single API endpoint for complete processing (returns early with jobId)
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
        setIsProcessing(true);
        setJobStartTs(Date.now());
      }
      
      // Handle successful processing
      console.log('Processing completed:', result);
      
      // Clear uploaded files to reset UI
      setDataMapFile(null);
      setBannerPlanFile(null);
      setDataFile(null);
      
      // Refresh validation counts
      refresh();
      
      // Show success with validation link
      toast.success('Processing completed successfully!', {
        description: 'Your files have been processed and are ready for validation.',
        action: {
          label: 'View Queue',
          onClick: () => router.push('/validate')
        }
      });
      
    } catch (error) {
      console.error('Processing error:', error);
      toast.error('Processing failed', {
        description: error instanceof Error ? error.message : 'Unknown error occurred'
      });
    } finally {
      // Do not close the modal here; let job status control it
    }
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
        setJobStage(String(data.stage || ''));
        setJobProgress({ percent: Math.max(1, Math.min(100, Number(data.percent) || 0)), message: data.message || 'Processing...' });
        if (data.error) setJobError(String(data.error));
        if (data.stage === 'complete' || data.stage === 'error') {
          clearInterval(interval);
          const close = () => {
            setIsProcessing(false);
            setJobId(null);
            setJobProgress(undefined);
            setJobStage(null);
            const doneOk = data.stage === 'complete' && !data.error;
            if (doneOk) {
              // Clear uploaded files, refresh counts, toast success with link
              setDataMapFile(null);
              setBannerPlanFile(null);
              setDataFile(null);
              refresh();
              toast.success('Processing completed successfully!', {
                description: 'Your files have been processed and are ready for validation.',
                action: { label: 'View Queue', onClick: () => router.push('/validate') },
              });
            } else {
              toast.error('Processing failed', { description: data.error || jobError || 'Unknown error' });
            }
          };
          // Ensure minimum visible time to avoid flicker
          const minMs = 800;
          const elapsed = jobStartTs ? Date.now() - jobStartTs : minMs;
          if (elapsed < minMs) setTimeout(close, minMs - elapsed);
          else close();
        }
      } catch {
        // ignore transient errors
      }
    }, 1200);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [jobId, router, refresh, jobError, jobStartTs]);

  return (
    <div className="py-12 px-4">
      <div className="max-w-6xl mx-auto">
        <PageHeader
          title="HawkTab AI - Crosstab Generator"
          description="Upload your data files to generate automated crosstabs. Provide a data map, banner plan, and your raw data to get started."
          actions={
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
          }
        />

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
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
        </div>

        <div className="text-center">
          <Button
            onClick={handleSubmit}
            disabled={!allFilesUploaded || isProcessing}
            size="lg"
            className="px-8"
          >
            {isProcessing ? 'Processing...' : 'Generate Crosstabs'}
          </Button>
          
          {!allFilesUploaded && (
            <p className="text-sm text-muted-foreground mt-2">
              Please upload all three files to continue
            </p>
          )}
        </div>
      </div>

      <LoadingModal isOpen={isProcessing} currentStep={processingStep} jobProgress={jobProgress} />
    </div>
  );
}
