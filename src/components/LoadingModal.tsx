'use client';

import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog';
import { Progress } from '@/components/ui/progress';

export interface ProcessingStep {
  step: 'initial' | 'banner' | 'crosstab' | 'complete';
  message: string;
}

interface LoadingModalProps {
  isOpen: boolean;
  currentStep?: ProcessingStep;
}

const STEP_PROGRESS = {
  initial: 33,
  banner: 66,
  crosstab: 100,
  complete: 100
};

const STEP_MESSAGES = {
  initial: 'Processing your files...',
  banner: 'Creating banner plan...',
  crosstab: 'Generating crosstabs...',
  complete: 'Almost done...'
};

export default function LoadingModal({ isOpen, currentStep }: LoadingModalProps) {
  const step = currentStep?.step || 'initial';
  const message = currentStep?.message || STEP_MESSAGES[step];
  const progress = STEP_PROGRESS[step];

  return (
    <Dialog open={isOpen}>
      <DialogContent className="max-w-md" showCloseButton={false}>
        <DialogTitle className="text-lg font-medium text-center mb-4">
          Processing Files
        </DialogTitle>
        <div className="text-center py-4">
          <p className="text-sm text-muted-foreground mb-6">
            {message}
          </p>

          <Progress value={progress} className="mb-4" />
          
          <p className="text-xs text-muted-foreground">
            {progress}% complete
          </p>
        </div>
      </DialogContent>
    </Dialog>
  );
}