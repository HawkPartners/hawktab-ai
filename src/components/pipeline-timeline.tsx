'use client';

import { CheckCircle, Circle, Loader2, XCircle } from 'lucide-react';
import { cn } from '@/lib/utils';

type StepStatus = 'completed' | 'active' | 'pending' | 'error';

interface TimelineStep {
  id: string;
  label: string;
  description: string;
  /** Orchestrator stage strings that map to this step */
  stages: string[];
}

const TIMELINE_STEPS: TimelineStep[] = [
  {
    id: 'parsing',
    label: 'Parsing Data',
    description: 'Extracting variables, labels, and structure from SPSS file',
    stages: ['uploading', 'parsing'],
  },
  {
    id: 'analyzing',
    label: 'Analyzing & Building Tables',
    description: 'Banner extraction, crosstab generation, skip logic, and verification',
    stages: ['parallel_processing', 'waiting_for_tables'],
  },
  {
    id: 'review',
    label: 'Review',
    description: 'Some banner columns require your review',
    stages: ['crosstab_review_required', 'applying_review'],
  },
  {
    id: 'validating',
    label: 'Validating',
    description: 'Validating R expressions and fixing errors',
    stages: ['validating_r'],
  },
  {
    id: 'running',
    label: 'Running Analysis',
    description: 'Generating and executing R scripts',
    stages: ['generating_r', 'executing_r', 'generating_output'],
  },
  {
    id: 'output',
    label: 'Generating Excel',
    description: 'Building the final crosstab workbook',
    stages: ['writing_outputs'],
  },
];

function getStepStatuses(
  currentStage: string | undefined,
  runStatus: string,
): Map<string, StepStatus> {
  const result = new Map<string, StepStatus>();

  // Terminal statuses
  if (runStatus === 'success' || runStatus === 'partial') {
    for (const step of TIMELINE_STEPS) {
      result.set(step.id, 'completed');
    }
    return result;
  }

  if (runStatus === 'error') {
    let foundCurrent = false;
    for (const step of TIMELINE_STEPS) {
      if (step.stages.includes(currentStage ?? '')) {
        result.set(step.id, 'error');
        foundCurrent = true;
      } else if (!foundCurrent) {
        result.set(step.id, 'completed');
      } else {
        result.set(step.id, 'pending');
      }
    }
    // If no stage matched, mark last active step as error
    if (!foundCurrent) {
      const stepIds = TIMELINE_STEPS.map(s => s.id);
      result.set(stepIds[stepIds.length - 1], 'error');
    }
    return result;
  }

  if (runStatus === 'cancelled') {
    let foundCurrent = false;
    for (const step of TIMELINE_STEPS) {
      if (step.stages.includes(currentStage ?? '')) {
        result.set(step.id, 'pending');
        foundCurrent = true;
      } else if (!foundCurrent) {
        result.set(step.id, 'completed');
      } else {
        result.set(step.id, 'pending');
      }
    }
    if (!foundCurrent) {
      for (const step of TIMELINE_STEPS) {
        result.set(step.id, 'pending');
      }
    }
    return result;
  }

  // In progress — find which step is current
  let foundCurrent = false;
  for (const step of TIMELINE_STEPS) {
    if (step.stages.includes(currentStage ?? '')) {
      result.set(step.id, 'active');
      foundCurrent = true;
    } else if (!foundCurrent) {
      result.set(step.id, 'completed');
    } else {
      result.set(step.id, 'pending');
    }
  }

  // If no match (early stage), mark first as active
  if (!foundCurrent) {
    result.clear();
    for (let i = 0; i < TIMELINE_STEPS.length; i++) {
      result.set(TIMELINE_STEPS[i].id, i === 0 ? 'active' : 'pending');
    }
  }

  return result;
}

function StepIcon({ status }: { status: StepStatus }) {
  switch (status) {
    case 'completed':
      return <CheckCircle className="h-5 w-5 text-ct-emerald" />;
    case 'active':
      return <Loader2 className="h-5 w-5 text-ct-blue animate-spin" />;
    case 'error':
      return <XCircle className="h-5 w-5 text-ct-red" />;
    case 'pending':
    default:
      return <Circle className="h-5 w-5 text-muted-foreground/40" />;
  }
}

interface PipelineTimelineProps {
  stage: string | undefined;
  status: string;
  message?: string;
  progress?: number;
  /** If true, hides the "Review" step (only show it for pipelines that paused there) */
  hideReview?: boolean;
}

export function PipelineTimeline({
  stage,
  status,
  message,
  progress,
  hideReview = true,
}: PipelineTimelineProps) {
  const stepStatuses = getStepStatuses(stage, status);

  // Only show the review step if the pipeline paused there or is currently there
  const showReview = !hideReview || stage === 'crosstab_review_required' || status === 'pending_review';
  const visibleSteps = TIMELINE_STEPS.filter(
    (s) => s.id !== 'review' || showReview,
  );

  return (
    <div className="relative">
      {visibleSteps.map((step, index) => {
        const stepStatus = stepStatuses.get(step.id) ?? 'pending';
        const isLast = index === visibleSteps.length - 1;

        return (
          <div key={step.id} className="relative flex gap-4">
            {/* Vertical line connector */}
            {!isLast && (
              <div
                className={cn(
                  'absolute left-[9px] top-7 w-px h-[calc(100%-12px)]',
                  stepStatus === 'completed'
                    ? 'bg-ct-emerald/40'
                    : 'bg-border',
                )}
              />
            )}

            {/* Icon */}
            <div className="relative z-10 flex-shrink-0 mt-0.5">
              <StepIcon status={stepStatus} />
            </div>

            {/* Content */}
            <div className={cn('pb-6', isLast && 'pb-0')}>
              <p
                className={cn(
                  'text-sm font-medium',
                  stepStatus === 'active' && 'text-ct-blue',
                  stepStatus === 'completed' && 'text-foreground',
                  stepStatus === 'error' && 'text-ct-red',
                  stepStatus === 'pending' && 'text-muted-foreground',
                )}
              >
                {step.label}
              </p>
              <p className="text-xs text-muted-foreground mt-0.5">
                {stepStatus === 'active' && message
                  ? message
                  : step.description}
              </p>
              {stepStatus === 'active' && progress !== undefined && progress > 0 && (
                <div className="mt-2 flex items-center gap-2">
                  <div className="h-1.5 flex-1 max-w-[200px] rounded-full bg-muted overflow-hidden">
                    <div
                      className="h-full rounded-full bg-ct-blue transition-all duration-500"
                      style={{ width: `${Math.min(progress, 100)}%` }}
                    />
                  </div>
                  <span className="text-xs text-muted-foreground font-mono">
                    {progress}%
                  </span>
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
