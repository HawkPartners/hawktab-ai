'use client';

import { Check } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

const STEPS = [
  { number: 1, label: 'Project Setup' },
  { number: 2, label: 'Upload & Validate' },
  { number: 3, label: 'Configure' },
  { number: 4, label: 'Review & Launch' },
] as const;

interface WizardShellProps {
  currentStep: number;
  children: React.ReactNode;
  onBack: () => void;
  onNext: () => void;
  nextDisabled?: boolean;
  nextLabel?: string;
  showBack?: boolean;
  isSubmitting?: boolean;
}

export function WizardShell({
  currentStep,
  children,
  onBack,
  onNext,
  nextDisabled = false,
  nextLabel,
  showBack = true,
  isSubmitting = false,
}: WizardShellProps) {
  return (
    <div className="flex flex-col gap-8">
      {/* Step indicator */}
      <nav aria-label="Wizard steps" className="flex items-center justify-center gap-2">
        {STEPS.map((step, i) => {
          const isActive = step.number === currentStep;
          const isComplete = step.number < currentStep;
          const isUpcoming = step.number > currentStep;

          return (
            <div key={step.number} className="flex items-center gap-2">
              {i > 0 && (
                <div
                  className={cn(
                    'h-px w-8 sm:w-12',
                    isComplete ? 'bg-ct-emerald' : 'bg-border'
                  )}
                />
              )}
              <div className="flex items-center gap-2">
                <div
                  className={cn(
                    'flex h-8 w-8 items-center justify-center rounded-full text-sm font-medium transition-colors',
                    isComplete && 'bg-ct-emerald/20 text-ct-emerald',
                    isActive && 'bg-ct-blue/20 text-ct-blue ring-2 ring-ct-blue/50',
                    isUpcoming && 'bg-muted text-muted-foreground'
                  )}
                >
                  {isComplete ? <Check className="h-4 w-4" /> : step.number}
                </div>
                <span
                  className={cn(
                    'hidden text-sm sm:inline',
                    isActive && 'font-medium text-foreground',
                    isComplete && 'text-ct-emerald',
                    isUpcoming && 'text-muted-foreground'
                  )}
                >
                  {step.label}
                </span>
              </div>
            </div>
          );
        })}
      </nav>

      {/* Step content */}
      <div className="min-h-[400px]">{children}</div>

      {/* Navigation footer */}
      <div className="flex items-center justify-between border-t pt-6">
        <div>
          {showBack && currentStep > 1 && (
            <Button variant="outline" onClick={onBack} disabled={isSubmitting}>
              Back
            </Button>
          )}
        </div>
        <Button
          onClick={onNext}
          disabled={nextDisabled || isSubmitting}
        >
          {isSubmitting ? 'Launching...' : nextLabel ?? (currentStep === 4 ? 'Launch Pipeline' : 'Next')}
        </Button>
      </div>
    </div>
  );
}
