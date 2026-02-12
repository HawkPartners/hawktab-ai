'use client';

import type { WizardFormValues, DataValidationResult } from '@/schemas/wizardSchema';
import type { WizardFiles } from './StepUploadFiles';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import { ChevronDown, FileText, Settings, Beaker, Database } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useState } from 'react';
import { THEMES } from '@/lib/excel/themes';

interface StepReviewLaunchProps {
  values: WizardFormValues;
  files: WizardFiles;
  validationResult: DataValidationResult;
}

export function StepReviewLaunch({ values, files, validationResult }: StepReviewLaunchProps) {
  const [statsOpen, setStatsOpen] = useState(false);

  const themeName = THEMES[values.theme]?.displayName ?? values.theme;

  const displayModeLabel =
    values.displayMode === 'frequency'
      ? 'Percentages'
      : values.displayMode === 'counts'
        ? 'Counts'
        : 'Both (Percentages + Counts)';

  return (
    <div className="space-y-6 max-w-2xl mx-auto">
      {/* Project info */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Database className="h-4 w-4" />
            Project
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <SummaryRow label="Name" value={values.projectName} />
          <SummaryRow label="Type" value={capitalize(values.projectSubType)} />
          {values.projectSubType === 'segmentation' && values.segmentationHasAssignments && (
            <SummaryRow label="" value="Includes segment assignments" />
          )}
          {values.projectSubType === 'maxdiff' && (
            <>
              {values.maxdiffHasMessageList && (
                <SummaryRow label="" value="Message list provided" />
              )}
              {values.maxdiffHasAnchoredScores && (
                <SummaryRow label="" value="Anchored probability scores included" />
              )}
            </>
          )}
          <SummaryRow
            label="Banner"
            value={values.bannerMode === 'upload' ? 'Uploaded banner plan' : 'Auto-generated'}
          />
          {values.researchObjectives && (
            <SummaryRow label="Objectives" value={values.researchObjectives} truncate />
          )}
          {values.bannerHints && (
            <SummaryRow label="Banner hints" value={values.bannerHints} truncate />
          )}
        </CardContent>
      </Card>

      {/* Files */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <FileText className="h-4 w-4" />
            Files
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <FileRow label="Data file" file={files.dataFile} />
          <FileRow label="Survey" file={files.surveyDocument} />
          {values.bannerMode === 'upload' && (
            <FileRow label="Banner plan" file={files.bannerPlan} />
          )}
          {files.messageList && (
            <FileRow label="Message list" file={files.messageList} />
          )}
          {validationResult.status === 'success' && (
            <div className="flex gap-3 mt-2">
              <Badge variant="outline" className="font-mono text-xs">
                {validationResult.rowCount.toLocaleString()} respondents
              </Badge>
              <Badge variant="outline" className="font-mono text-xs">
                {validationResult.columnCount.toLocaleString()} variables
              </Badge>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Configuration */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center gap-2 text-base">
            <Settings className="h-4 w-4" />
            Configuration
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <SummaryRow label="Display mode" value={displayModeLabel} />
          {values.displayMode === 'both' && (
            <SummaryRow
              label="Workbooks"
              value={values.separateWorkbooks ? 'Separate files' : 'Single file, two sheets'}
            />
          )}
          <SummaryRow label="Theme" value={themeName} />
          <SummaryRow label="Significance" value={`${values.statTestingThreshold}%`} />
          <SummaryRow
            label="Min base"
            value={values.minBaseSize === 0 ? 'None' : String(values.minBaseSize)}
          />
          <SummaryRow
            label="Weight"
            value={values.weightVariable || 'Unweighted'}
            mono={!!values.weightVariable}
          />
          {values.stopAfterVerification && (
            <SummaryRow label="Mode" value="Stop after verification (no R/Excel)" />
          )}
        </CardContent>
      </Card>

      {/* Statistical Assumptions */}
      <Collapsible open={statsOpen} onOpenChange={setStatsOpen}>
        <Card>
          <CollapsibleTrigger className="w-full">
            <CardHeader className="pb-3">
              <CardTitle className="flex items-center gap-2 text-base">
                <Beaker className="h-4 w-4" />
                Statistical Assumptions
                <ChevronDown
                  className={cn('ml-auto h-4 w-4 transition-transform', statsOpen && 'rotate-180')}
                />
              </CardTitle>
            </CardHeader>
          </CollapsibleTrigger>
          <CollapsibleContent>
            <CardContent className="space-y-2 text-sm text-muted-foreground">
              <SummaryRow label="Proportion test" value="Unpooled z-test (column proportions)" />
              <SummaryRow label="Mean test" value="Welch's t-test (unequal variances)" />
              <SummaryRow label="Multiple comparison" value="Pairwise letters across banner columns" />
              <SummaryRow
                label="Loop stat testing"
                value="Entity-anchored groups suppress within-group comparisons"
              />
              <SummaryRow
                label="Confidence"
                value={`${values.statTestingThreshold}% (p < ${(1 - values.statTestingThreshold / 100).toFixed(2)})`}
              />
            </CardContent>
          </CollapsibleContent>
        </Card>
      </Collapsible>
    </div>
  );
}

function SummaryRow({
  label,
  value,
  mono,
  truncate,
}: {
  label: string;
  value: string;
  mono?: boolean;
  truncate?: boolean;
}) {
  return (
    <div className="flex items-start justify-between gap-4">
      <span className="text-sm text-muted-foreground shrink-0">{label}</span>
      <span
        className={cn(
          'text-sm text-right',
          mono && 'font-mono',
          truncate && 'truncate max-w-[300px]'
        )}
      >
        {value}
      </span>
    </div>
  );
}

function FileRow({ label, file }: { label: string; file: File | null }) {
  if (!file) return null;
  return (
    <div className="flex items-center justify-between gap-4">
      <span className="text-sm text-muted-foreground">{label}</span>
      <span className="text-sm font-mono truncate max-w-[250px]">{file.name}</span>
    </div>
  );
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}
