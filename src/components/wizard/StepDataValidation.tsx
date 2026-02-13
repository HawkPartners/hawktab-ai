'use client';

import type { DataValidationResult } from '@/schemas/wizardSchema';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { AlertTriangle, CheckCircle, XCircle, Database, Scale, Repeat } from 'lucide-react';
import { useState } from 'react';

interface StepDataValidationProps {
  validationResult: DataValidationResult;
  /** Called when user confirms a weight candidate — sets form.weightVariable */
  onWeightConfirm?: (column: string) => void;
  /** Called when user denies all weight candidates — clears form.weightVariable */
  onWeightDeny?: () => void;
}

export function StepDataValidation({
  validationResult: v,
  onWeightConfirm,
  onWeightDeny,
}: StepDataValidationProps) {
  // Track whether the user has made a decision about weight
  const [weightDecision, setWeightDecision] = useState<'confirmed' | 'denied' | null>(null);

  if (v.status === 'idle') return null;

  if (v.status === 'validating') {
    return (
      <div aria-live="polite" aria-busy="true">
        <Card className="border-ct-blue/30">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Database className="h-4 w-4 animate-pulse text-ct-blue" />
              Analyzing your data file...
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Skeleton className="h-4 w-3/4" />
            <Skeleton className="h-4 w-1/2" />
            <Skeleton className="h-4 w-2/3" />
          </CardContent>
        </Card>
      </div>
    );
  }

  if (v.status === 'error') {
    return (
      <div aria-live="polite">
        <Card className="border-ct-red/40">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base text-ct-red">
              <XCircle className="h-4 w-4" />
              Validation Error
            </CardTitle>
          </CardHeader>
          <CardContent>
            {v.errors.map((err, i) => (
              <p key={i} className="text-sm text-ct-red">{err.message}</p>
            ))}
          </CardContent>
        </Card>
      </div>
    );
  }

  // Success state
  const warnings = v.errors.filter((e) => e.severity === 'warning');
  const errors = v.errors.filter((e) => e.severity === 'error');

  return (
    <div className="space-y-4" aria-live="polite">
      {/* Stacked data warning */}
      {v.isStacked && (
        <Card className="border-ct-red/40 bg-ct-red-dim/10">
          <CardContent className="flex items-start gap-3 p-4">
            <XCircle className="h-5 w-5 text-ct-red mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium text-ct-red">Stacked data detected</p>
              <p className="text-sm text-muted-foreground mt-1">
                {v.stackedWarning || 'This data appears to be in stacked (long) format. The pipeline requires wide format with one row per respondent.'}
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Success summary */}
      {!v.isStacked && v.canProceed && (
        <Card className="border-ct-emerald/40">
          <CardContent className="flex items-start gap-3 p-4">
            <CheckCircle className="h-5 w-5 text-ct-emerald mt-0.5 shrink-0" />
            <div className="flex-1">
              <p className="text-sm font-medium text-ct-emerald">Data file validated</p>
              <div className="flex gap-4 mt-2">
                <Badge variant="outline" className="font-mono text-xs">
                  {v.rowCount.toLocaleString()} respondents
                </Badge>
                <Badge variant="outline" className="font-mono text-xs">
                  {v.columnCount.toLocaleString()} variables
                </Badge>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Weight candidates with confirm/deny */}
      {v.weightCandidates.length > 0 && (
        <Card>
          <CardContent className="flex items-start gap-3 p-4">
            <Scale className="h-5 w-5 text-ct-amber mt-0.5 shrink-0" />
            <div className="flex-1">
              <p className="text-sm font-medium">Weight variable detected</p>
              <p className="text-sm text-muted-foreground mt-1">
                Found{' '}
                <span className="font-mono text-foreground">
                  {v.weightCandidates[0].column}
                </span>
                {v.weightCandidates[0].label && (
                  <> ({v.weightCandidates[0].label})</>
                )}
                {' '}— mean {v.weightCandidates[0].mean.toFixed(3)}.
              </p>
              {v.weightCandidates.length > 1 && (
                <p className="text-xs text-muted-foreground mt-1">
                  {v.weightCandidates.length - 1} other candidate{v.weightCandidates.length > 2 ? 's' : ''} detected.
                </p>
              )}

              {/* Confirm/Deny buttons */}
              {weightDecision === null && (onWeightConfirm || onWeightDeny) && (
                <div className="flex gap-2 mt-3">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="text-ct-emerald border-ct-emerald/30 hover:bg-ct-emerald/10"
                    onClick={() => {
                      setWeightDecision('confirmed');
                      onWeightConfirm?.(v.weightCandidates[0].column);
                    }}
                  >
                    <CheckCircle className="h-3.5 w-3.5 mr-1.5" />
                    Yes, use this weight
                  </Button>
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="text-muted-foreground"
                    onClick={() => {
                      setWeightDecision('denied');
                      onWeightDeny?.();
                    }}
                  >
                    No, run unweighted
                  </Button>
                </div>
              )}

              {/* Decision feedback */}
              {weightDecision === 'confirmed' && (
                <p className="text-xs text-ct-emerald mt-2">
                  Weight confirmed. You can adjust this in the next step.
                </p>
              )}
              {weightDecision === 'denied' && (
                <p className="text-xs text-muted-foreground mt-2">
                  Running unweighted. You can change this in the next step.
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Loop detection — informational, not a warning */}
      {v.loopSummary?.hasLoops && (
        <Card className="border-ct-blue/30">
          <CardContent className="flex items-start gap-3 p-4">
            <Repeat className="h-5 w-5 text-ct-blue mt-0.5 shrink-0" />
            <div>
              <p className="text-sm font-medium">Looped data detected</p>
              <p className="text-sm text-muted-foreground mt-1">
                Found {v.loopSummary.loopCount} loop{v.loopSummary.loopCount > 1 ? ' groups' : ' group'} in your data.
                Data will be stacked automatically for accurate crosstab analysis.
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Errors */}
      {errors.length > 0 && (
        <Card className="border-ct-red/30">
          <CardContent className="space-y-2 p-4">
            {errors.map((err, i) => (
              <div key={i} className="flex items-start gap-2">
                <XCircle className="h-4 w-4 text-ct-red mt-0.5 shrink-0" />
                <p className="text-sm">{err.message}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Warnings */}
      {warnings.length > 0 && (
        <Card className="border-ct-amber/30">
          <CardContent className="space-y-2 p-4">
            {warnings.map((warn, i) => (
              <div key={i} className="flex items-start gap-2">
                <AlertTriangle className="h-4 w-4 text-ct-amber mt-0.5 shrink-0" />
                <p className="text-sm text-muted-foreground">{warn.message}</p>
              </div>
            ))}
          </CardContent>
        </Card>
      )}
    </div>
  );
}
