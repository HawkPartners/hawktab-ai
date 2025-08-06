'use client';

import { useState } from 'react';
import FileUpload from '../components/FileUpload';
import LoadingModal from '../components/LoadingModal';

export default function Home() {
  const [dataMapFile, setDataMapFile] = useState<File | null>(null);
  const [bannerPlanFile, setBannerPlanFile] = useState<File | null>(null);
  const [dataFile, setDataFile] = useState<File | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const allFilesUploaded = dataMapFile && bannerPlanFile && dataFile;

  const handleSubmit = async () => {
    if (!allFilesUploaded) return;
    
    setIsProcessing(true);
    
    try {
      const formData = new FormData();
      formData.append('dataMap', dataMapFile);
      formData.append('bannerPlan', bannerPlanFile);
      formData.append('dataFile', dataFile);
      
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
      
      // For now, log the result. In future phases we'll show results UI
      alert('Processing completed successfully! Check console for results.');
      
    } catch (error) {
      console.error('Processing error:', error);
      alert(`Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-12 px-4">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-12">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-4">
            HawkTab AI - Crosstab Generator
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
            Upload your data files to generate automated crosstabs. Provide a data map, banner plan, and your raw data to get started.
          </p>
        </div>

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
          <button
            onClick={handleSubmit}
            disabled={!allFilesUploaded || isProcessing}
            className={`
              px-8 py-3 rounded-lg font-medium transition-colors
              ${allFilesUploaded && !isProcessing
                ? 'bg-blue-600 hover:bg-blue-700 text-white'
                : 'bg-gray-300 dark:bg-gray-700 text-gray-500 dark:text-gray-400 cursor-not-allowed'
              }
            `}
          >
            {isProcessing ? 'Processing...' : 'Generate Crosstabs'}
          </button>
          
          {!allFilesUploaded && (
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
              Please upload all three files to continue
            </p>
          )}
        </div>
      </div>

      <LoadingModal isOpen={isProcessing} />
    </div>
  );
}
