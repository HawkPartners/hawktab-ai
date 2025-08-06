'use client';

interface LoadingModalProps {
  isOpen: boolean;
  progress?: string;
}

export default function LoadingModal({ isOpen, progress = 'Validating your uploaded files...' }: LoadingModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 backdrop-blur-sm">
      <div className="bg-white dark:bg-gray-900 rounded-lg p-8 max-w-md w-full mx-4 shadow-xl">
        <div className="text-center">
          <div className="flex justify-center mb-6">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
          
          <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-2">
            Validating Files
          </h3>
          
          <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
            {progress}
          </p>
          
          <div className="space-y-2 text-xs text-gray-500 dark:text-gray-400 text-left">
            <div className="flex items-center">
              <div className="w-2 h-2 bg-blue-500 rounded-full mr-2 animate-pulse"></div>
              <span>Validating data map</span>
            </div>
            <div className="flex items-center">
              <div className="w-2 h-2 bg-blue-500 rounded-full mr-2 animate-pulse"></div>
              <span>Validating banner plan</span>
            </div>
            <div className="flex items-center">
              <div className="w-2 h-2 bg-blue-500 rounded-full mr-2 animate-pulse"></div>
              <span>Validating data file</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}