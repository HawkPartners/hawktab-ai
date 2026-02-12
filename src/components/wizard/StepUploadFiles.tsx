'use client';

import FileUpload from '@/components/FileUpload';
import type { BannerMode, ProjectSubType } from '@/schemas/wizardSchema';
import { StepDataValidation } from './StepDataValidation';
import type { DataValidationResult } from '@/schemas/wizardSchema';

export interface WizardFiles {
  dataFile: File | null;
  surveyDocument: File | null;
  bannerPlan: File | null;
  messageList: File | null;
}

interface StepUploadFilesProps {
  files: WizardFiles;
  onFileChange: <K extends keyof WizardFiles>(key: K, file: WizardFiles[K]) => void;
  bannerMode: BannerMode;
  projectSubType: ProjectSubType;
  maxdiffHasMessageList?: boolean;
  validationResult: DataValidationResult;
  onWeightConfirm?: (column: string) => void;
  onWeightDeny?: () => void;
}

export function StepUploadFiles({
  files,
  onFileChange,
  bannerMode,
  projectSubType,
  maxdiffHasMessageList,
  validationResult,
  onWeightConfirm,
  onWeightDeny,
}: StepUploadFilesProps) {
  const showBannerUpload = bannerMode === 'upload';
  const showMessageList = projectSubType === 'maxdiff' && maxdiffHasMessageList;

  return (
    <div className="space-y-8 max-w-3xl mx-auto">
      {/* File uploads */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <FileUpload
          title="Data File"
          description="SPSS data file — qualified respondents, wide format"
          acceptedTypes=".sav,.spss"
          fileExtensions={['.sav', '.spss']}
          onFileSelect={(file) => onFileChange('dataFile', file)}
          selectedFile={files.dataFile}
        />

        <FileUpload
          title="Survey Document"
          description="Questionnaire used for enhanced table labels"
          acceptedTypes=".pdf,.doc,.docx"
          fileExtensions={['.pdf', '.doc', '.docx']}
          onFileSelect={(file) => onFileChange('surveyDocument', file)}
          selectedFile={files.surveyDocument}
        />

        {showBannerUpload && (
          <FileUpload
            title="Banner Plan"
            description="Banner plan document defining your cuts"
            acceptedTypes=".pdf,.doc,.docx"
            fileExtensions={['.pdf', '.doc', '.docx']}
            onFileSelect={(file) => onFileChange('bannerPlan', file)}
            selectedFile={files.bannerPlan}
          />
        )}

        {showMessageList && (
          <FileUpload
            title="Message List"
            description="Excel file mapping MaxDiff item codes to descriptions"
            acceptedTypes=".xlsx,.xls,.csv"
            fileExtensions={['.xlsx', '.xls', '.csv']}
            onFileSelect={(file) => onFileChange('messageList', file)}
            selectedFile={files.messageList}
            optional
          />
        )}
      </div>

      {/* Data validation (2B) — appears once .sav is uploaded */}
      {files.dataFile && (
        <StepDataValidation
          validationResult={validationResult}
          onWeightConfirm={onWeightConfirm}
          onWeightDeny={onWeightDeny}
        />
      )}
    </div>
  );
}
