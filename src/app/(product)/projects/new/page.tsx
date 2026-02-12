'use client';

import { useState, useCallback, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { toast } from 'sonner';
import posthog from 'posthog-js';

import { WizardFormSchema, Step1Schema, Step3Schema, type WizardFormValues } from '@/schemas/wizardSchema';
import { wizardToProjectConfig } from '@/schemas/projectConfigSchema';
import { useDataValidation } from '@/hooks/useDataValidation';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import { PageHeader } from '@/components/PageHeader';
import { Form } from '@/components/ui/form';
import { WizardShell } from '@/components/wizard/WizardShell';
import { StepProjectSetup } from '@/components/wizard/StepProjectSetup';
import { StepUploadFiles, type WizardFiles } from '@/components/wizard/StepUploadFiles';
import { StepConfiguration } from '@/components/wizard/StepConfiguration';
import { StepReviewLaunch } from '@/components/wizard/StepReviewLaunch';

export default function NewProjectPage() {
  const router = useRouter();
  const [currentStep, setCurrentStep] = useState(1);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // File state (separate from form — File objects aren't serializable via Zod)
  const [files, setFiles] = useState<WizardFiles>({
    dataFile: null,
    surveyDocument: null,
    bannerPlan: null,
    messageList: null,
  });

  const form = useForm<WizardFormValues>({
    resolver: zodResolver(WizardFormSchema),
    defaultValues: {
      projectName: '',
      researchObjectives: '',
      projectSubType: 'standard',
      segmentationHasAssignments: false,
      maxdiffHasMessageList: false,
      maxdiffHasAnchoredScores: false,
      bannerMode: 'upload',
      bannerHints: '',
      displayMode: 'frequency',
      separateWorkbooks: false,
      theme: 'classic',
      statTestingThreshold: 90,
      minBaseSize: 0,
      weightVariable: undefined,
      stopAfterVerification: false,
    },
  });

  // Data validation — auto-triggers when dataFile changes
  const validationResult = useDataValidation(files.dataFile);

  // Pre-select best weight candidate when validation succeeds
  const handleFileChange = useCallback(<K extends keyof WizardFiles>(key: K, file: WizardFiles[K]) => {
    setFiles((prev) => ({ ...prev, [key]: file }));

    // Track file upload event
    if (file) {
      const fileObj = file as File;
      posthog.capture('file_uploaded', {
        file_type: key,
        file_name: fileObj.name,
        file_size_bytes: fileObj.size,
        file_extension: fileObj.name.split('.').pop()?.toLowerCase(),
      });
    }
  }, []);

  // Auto-select best weight candidate when validation succeeds
  useEffect(() => {
    if (
      validationResult.status === 'success' &&
      validationResult.weightCandidates.length > 0 &&
      form.getValues('weightVariable') === undefined
    ) {
      form.setValue('weightVariable', validationResult.weightCandidates[0].column);
    }
  }, [validationResult.status, validationResult.weightCandidates, form]);

  const bannerMode = form.watch('bannerMode');
  const projectSubType = form.watch('projectSubType');
  const maxdiffHasMessageList = form.watch('maxdiffHasMessageList');

  // Clear stale files when options change
  useEffect(() => {
    if (bannerMode !== 'upload' && files.bannerPlan) {
      setFiles((prev) => ({ ...prev, bannerPlan: null }));
    }
  }, [bannerMode, files.bannerPlan]);

  useEffect(() => {
    if (projectSubType !== 'maxdiff' && files.messageList) {
      setFiles((prev) => ({ ...prev, messageList: null }));
    }
  }, [projectSubType, files.messageList]);

  // Per-step validation
  const validateCurrentStep = async (): Promise<boolean> => {
    switch (currentStep) {
      case 1: {
        const values = form.getValues();
        const result = Step1Schema.safeParse(values);
        if (!result.success) {
          // Trigger RHF validation to show errors
          await form.trigger(['projectName', 'projectSubType', 'bannerMode']);
          return false;
        }
        // MaxDiff hard blocker: anchored scores must be appended
        if (values.projectSubType === 'maxdiff' && !values.maxdiffHasAnchoredScores) {
          toast.error('Anchored probability scores are required for MaxDiff projects', {
            description: 'Have your simulator analyst append these scores to the .sav file before proceeding.',
          });
          return false;
        }
        return true;
      }
      case 2: {
        // Validate required files are present
        if (!files.dataFile) {
          toast.error('Data file is required');
          return false;
        }
        if (!files.surveyDocument) {
          toast.error('Survey document is required');
          return false;
        }
        if (bannerMode === 'upload' && !files.bannerPlan) {
          toast.error('Banner plan is required (or switch to auto-generate)');
          return false;
        }
        // Validate data validation has passed
        if (validationResult.status === 'validating') {
          toast.error('Please wait for data validation to complete');
          return false;
        }
        if (validationResult.status === 'error') {
          toast.error('Data validation failed — please check your data file');
          return false;
        }
        if (validationResult.isStacked) {
          toast.error('Stacked data detected — pipeline requires wide format');
          return false;
        }
        if (!validationResult.canProceed) {
          toast.error('Data validation has blocking errors');
          return false;
        }
        return true;
      }
      case 3: {
        const values = form.getValues();
        const result = Step3Schema.safeParse(values);
        if (!result.success) {
          await form.trigger([
            'displayMode', 'separateWorkbooks', 'theme',
            'statTestingThreshold', 'minBaseSize', 'weightVariable',
            'stopAfterVerification',
          ]);
          return false;
        }
        return true;
      }
      case 4:
        return true; // Review step — always valid
      default:
        return true;
    }
  };

  const handleNext = async () => {
    const valid = await validateCurrentStep();
    if (!valid) return;

    if (currentStep === 4) {
      // Launch
      await handleLaunch();
    } else {
      // Track wizard step completion
      posthog.capture('wizard_step_completed', {
        step_number: currentStep,
        step_name: ['project_setup', 'upload_files', 'configuration', 'review'][currentStep - 1],
      });

      setCurrentStep((prev) => Math.min(prev + 1, 4));
      window.scrollTo({ top: 0, behavior: 'smooth' });
    }
  };

  const handleBack = () => {
    setCurrentStep((prev) => Math.max(prev - 1, 1));
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleLaunch = async () => {
    setIsSubmitting(true);

    try {
      const values = form.getValues();
      const formData = new FormData();

      // Files
      formData.append('dataFile', files.dataFile!);
      formData.append('surveyDocument', files.surveyDocument!);
      if (files.bannerPlan && values.bannerMode === 'upload') {
        formData.append('bannerPlan', files.bannerPlan);
      }
      if (files.messageList) {
        formData.append('messageList', files.messageList);
      }

      // Config as JSON — use shared mapping function
      formData.append('config', JSON.stringify(wizardToProjectConfig(values)));
      formData.append('projectName', values.projectName);

      const response = await fetch('/api/projects/launch', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Launch failed' }));
        throw new Error(errorData.error || 'Launch failed');
      }

      const result = await response.json();

      // Track successful project creation
      posthog.capture('project_created', {
        project_id: result.projectId,
        project_name: values.projectName,
        project_type: values.projectSubType,
        banner_mode: values.bannerMode,
        has_weight_variable: !!values.weightVariable,
        display_mode: values.displayMode,
        theme: values.theme,
      });

      toast.success('Pipeline started', {
        description: 'Tracking progress on the project page.',
      });

      router.push(`/projects/${encodeURIComponent(result.projectId)}`);
    } catch (error) {
      console.error('Launch error:', error);
      toast.error('Launch failed', {
        description: error instanceof Error ? error.message : 'Unknown error',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  // Compute next-disabled based on step
  const getNextDisabled = (): boolean => {
    if (isSubmitting) return true;
    switch (currentStep) {
      case 2:
        return (
          !files.dataFile ||
          !files.surveyDocument ||
          (bannerMode === 'upload' && !files.bannerPlan) ||
          validationResult.status === 'validating' ||
          validationResult.status === 'error' ||
          validationResult.isStacked ||
          !validationResult.canProceed
        );
      default:
        return false;
    }
  };

  return (
    <div>
      <AppBreadcrumbs segments={[{ label: 'Dashboard', href: '/dashboard' }, { label: 'New Project' }]} />

      <div className="max-w-4xl mt-6">
        <PageHeader
          title="New Project"
          description="Set up your crosstab project in a few steps. Upload data, configure options, and launch."
        />

        <Form {...form}>
          <form onSubmit={(e) => e.preventDefault()}>
            <WizardShell
              currentStep={currentStep}
              onBack={handleBack}
              onNext={handleNext}
              nextDisabled={getNextDisabled()}
              isSubmitting={isSubmitting}
            >
              {currentStep === 1 && <StepProjectSetup />}
              {currentStep === 2 && (
                <StepUploadFiles
                  files={files}
                  onFileChange={handleFileChange}
                  bannerMode={bannerMode}
                  projectSubType={projectSubType}
                  maxdiffHasMessageList={maxdiffHasMessageList}
                  validationResult={validationResult}
                  onWeightConfirm={(col) => form.setValue('weightVariable', col)}
                  onWeightDeny={() => form.setValue('weightVariable', undefined)}
                />
              )}
              {currentStep === 3 && (
                <StepConfiguration validationResult={validationResult} />
              )}
              {currentStep === 4 && (
                <StepReviewLaunch
                  values={form.getValues()}
                  files={files}
                  validationResult={validationResult}
                />
              )}
            </WizardShell>
          </form>
        </Form>
      </div>
    </div>
  );
}
