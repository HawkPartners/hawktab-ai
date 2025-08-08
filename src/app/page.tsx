'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import FileUpload from '../components/FileUpload';
import LoadingModal, { ProcessingStep } from '../components/LoadingModal';
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
      
      // Simulate progress through stages (in real app, this would come from server events)
      setTimeout(() => {
        setProcessingStep({ step: 'banner', message: 'Creating banner plan...' });
      }, 2000);
      
      setTimeout(() => {
        setProcessingStep({ step: 'crosstab', message: 'Generating crosstabs...' });
      }, 4000);
      
      // Call our single API endpoint for complete processing
      const response = await fetch('/api/process-crosstab', {
        method: 'POST',
        body: formData,
      });
      
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Processing failed');
      }
      
      const result = await response.json();
      
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
      setIsProcessing(false);
      setProcessingStep(undefined);
    }
  };

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
                variant={counts.pending > 0 ? "default" : "secondary"}
                className={counts.pending > 0 ? "bg-orange-500 hover:bg-orange-600" : ""}
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

      <LoadingModal isOpen={isProcessing} currentStep={processingStep} />
    </div>
  );
}
