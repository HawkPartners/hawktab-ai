'use client';

import { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { PageHeader } from '@/components/PageHeader';
import {
  ArrowLeft,
  AlertTriangle,
  CheckCircle,
  Edit3,
  SkipForward,
  Loader2,
  Play,
  XCircle,
} from 'lucide-react';

interface FlaggedColumn {
  groupName: string;
  columnName: string;
  original: string;
  adjusted: string;
  confidence: number;
  uncertainties: string[];
  requiresInference: boolean;
  inferenceReason: string;
  humanInLoopRequired: boolean;
}

interface ReviewState {
  pipelineId: string;
  status: 'awaiting_review' | 'approved' | 'cancelled';
  createdAt: string;
  flaggedColumns: FlaggedColumn[];
  pathBStatus: 'running' | 'completed' | 'error';
  totalColumns: number;
  decisions: Array<{
    groupName: string;
    columnName: string;
    action: 'approve' | 'edit' | 'skip';
    editedValue?: string;
  }>;
}

interface ColumnDecision {
  action: 'approve' | 'edit' | 'skip';
  editedValue?: string;
}

function ConfidenceBadge({ confidence }: { confidence: number }) {
  const percent = Math.round(confidence * 100);
  let variant: 'default' | 'secondary' | 'destructive' = 'default';
  let colorClass = 'bg-green-500';

  if (percent < 70) {
    variant = 'destructive';
    colorClass = '';
  } else if (percent < 85) {
    variant = 'secondary';
    colorClass = 'bg-yellow-500';
  }

  return (
    <Badge variant={variant} className={colorClass}>
      {percent}% confident
    </Badge>
  );
}

function FlaggedColumnCard({
  column,
  decision,
  onDecisionChange,
}: {
  column: FlaggedColumn;
  decision: ColumnDecision;
  onDecisionChange: (decision: ColumnDecision) => void;
}) {
  const [editValue, setEditValue] = useState(column.adjusted);

  const handleActionChange = (action: 'approve' | 'edit' | 'skip') => {
    onDecisionChange({
      action,
      editedValue: action === 'edit' ? editValue : undefined,
    });
  };

  const handleEditValueChange = (value: string) => {
    setEditValue(value);
    if (decision.action === 'edit') {
      onDecisionChange({ action: 'edit', editedValue: value });
    }
  };

  return (
    <Card className="border-yellow-500/50">
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="text-base">{column.columnName}</CardTitle>
            <p className="text-sm text-muted-foreground">{column.groupName}</p>
          </div>
          <div className="flex items-center gap-2">
            <ConfidenceBadge confidence={column.confidence} />
            {column.requiresInference && (
              <Badge variant="outline" className="text-orange-600 border-orange-600">
                Inferred
              </Badge>
            )}
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Original vs AI Generated */}
        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Original (from banner)</Label>
            <div className="p-2 bg-muted rounded text-sm font-mono break-all">
              {column.original || <span className="text-muted-foreground italic">Empty</span>}
            </div>
          </div>
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">AI Generated (R syntax)</Label>
            <div className="p-2 bg-muted rounded text-sm font-mono break-all">
              {column.adjusted || <span className="text-muted-foreground italic">Empty</span>}
            </div>
          </div>
        </div>

        {/* AI Concerns */}
        {(column.uncertainties.length > 0 || column.inferenceReason) && (
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground flex items-center gap-1">
              <AlertTriangle className="h-3 w-3" />
              AI Concerns
            </Label>
            <ul className="text-sm text-yellow-600 dark:text-yellow-500 space-y-1">
              {column.uncertainties.map((u, i) => (
                <li key={i} className="flex items-start gap-1">
                  <span className="mt-1">•</span>
                  <span>{u}</span>
                </li>
              ))}
              {column.inferenceReason && (
                <li className="flex items-start gap-1">
                  <span className="mt-1">•</span>
                  <span>{column.inferenceReason}</span>
                </li>
              )}
            </ul>
          </div>
        )}

        {/* Decision */}
        <div className="space-y-3 pt-2 border-t">
          <Label className="text-sm font-medium">Your Decision</Label>
          <RadioGroup
            value={decision.action}
            onValueChange={(v) => handleActionChange(v as 'approve' | 'edit' | 'skip')}
            className="space-y-2"
          >
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="approve" id={`${column.groupName}-${column.columnName}-approve`} />
              <Label
                htmlFor={`${column.groupName}-${column.columnName}-approve`}
                className="flex items-center gap-2 cursor-pointer"
              >
                <CheckCircle className="h-4 w-4 text-green-500" />
                Approve as-is
              </Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="edit" id={`${column.groupName}-${column.columnName}-edit`} />
              <Label
                htmlFor={`${column.groupName}-${column.columnName}-edit`}
                className="flex items-center gap-2 cursor-pointer"
              >
                <Edit3 className="h-4 w-4 text-blue-500" />
                Edit expression
              </Label>
            </div>
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="skip" id={`${column.groupName}-${column.columnName}-skip`} />
              <Label
                htmlFor={`${column.groupName}-${column.columnName}-skip`}
                className="flex items-center gap-2 cursor-pointer"
              >
                <SkipForward className="h-4 w-4 text-gray-500" />
                Skip this cut
              </Label>
            </div>
          </RadioGroup>

          {/* Edit input */}
          {decision.action === 'edit' && (
            <div className="pl-6 space-y-1">
              <Label className="text-xs text-muted-foreground">Corrected R expression</Label>
              <Input
                value={editValue}
                onChange={(e) => handleEditValueChange(e.target.value)}
                placeholder="Enter corrected R expression..."
                className="font-mono text-sm"
              />
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export default function ReviewPage({
  params,
}: {
  params: Promise<{ pipelineId: string }>;
}) {
  const { pipelineId } = use(params);
  const [reviewState, setReviewState] = useState<ReviewState | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [decisions, setDecisions] = useState<Map<string, ColumnDecision>>(new Map());
  const router = useRouter();

  useEffect(() => {
    const fetchReviewState = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}/review`);
        if (!res.ok) {
          const errData = await res.json();
          throw new Error(errData.error || 'Failed to fetch review state');
        }
        const data = await res.json() as ReviewState;
        setReviewState(data);

        // Initialize decisions (default to approve)
        const initialDecisions = new Map<string, ColumnDecision>();
        for (const col of data.flaggedColumns) {
          const key = `${col.groupName}/${col.columnName}`;
          initialDecisions.set(key, { action: 'approve' });
        }
        setDecisions(initialDecisions);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setIsLoading(false);
      }
    };

    fetchReviewState();
  }, [pipelineId]);

  const handleDecisionChange = (groupName: string, columnName: string, decision: ColumnDecision) => {
    const key = `${groupName}/${columnName}`;
    setDecisions(new Map(decisions.set(key, decision)));
  };

  const handleSubmit = async () => {
    if (!reviewState) return;

    setIsSubmitting(true);
    try {
      const decisionsArray = reviewState.flaggedColumns.map((col) => {
        const key = `${col.groupName}/${col.columnName}`;
        const decision = decisions.get(key) || { action: 'approve' };
        return {
          groupName: col.groupName,
          columnName: col.columnName,
          action: decision.action,
          editedValue: decision.editedValue,
        };
      });

      const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}/review`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ decisions: decisionsArray }),
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || 'Failed to submit review');
      }

      await res.json();

      // Navigate to pipeline detail page
      router.push(`/pipelines/${encodeURIComponent(pipelineId)}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setIsSubmitting(false);
    }
  };

  const handleCancel = async () => {
    setIsSubmitting(true);
    try {
      const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}/cancel`, {
        method: 'POST',
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || 'Failed to cancel pipeline');
      }

      // Navigate to home
      router.push('/');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setIsSubmitting(false);
    }
  };

  if (isLoading) {
    return (
      <div className="py-12 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center justify-center py-20">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        </div>
      </div>
    );
  }

  if (error || !reviewState) {
    return (
      <div className="py-12 px-4">
        <div className="max-w-4xl mx-auto">
          <PageHeader
            title="Review Not Available"
            description={error || 'This pipeline does not require review or has already been reviewed.'}
            actions={
              <Button variant="outline" onClick={() => router.push('/')}>
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Home
              </Button>
            }
          />
        </div>
      </div>
    );
  }

  if (reviewState.status !== 'awaiting_review') {
    return (
      <div className="py-12 px-4">
        <div className="max-w-4xl mx-auto">
          <PageHeader
            title="Review Already Completed"
            description="This pipeline has already been reviewed."
            actions={
              <Button variant="outline" onClick={() => router.push(`/pipelines/${encodeURIComponent(pipelineId)}`)}>
                <ArrowLeft className="h-4 w-4 mr-2" />
                View Pipeline
              </Button>
            }
          />
        </div>
      </div>
    );
  }

  const approveCount = Array.from(decisions.values()).filter(d => d.action === 'approve').length;
  const editCount = Array.from(decisions.values()).filter(d => d.action === 'edit').length;
  const skipCount = Array.from(decisions.values()).filter(d => d.action === 'skip').length;

  return (
    <div className="py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <PageHeader
          title="Banner Review Required"
          description={`${reviewState.flaggedColumns.length} of ${reviewState.totalColumns} columns need your attention`}
          actions={
            <Button variant="outline" onClick={() => router.push('/')}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Home
            </Button>
          }
        />

        {/* Status */}
        <div className="flex items-center gap-4 mb-6">
          <Badge variant="secondary" className="bg-yellow-500/20 text-yellow-700 dark:text-yellow-400">
            <AlertTriangle className="h-3 w-3 mr-1" />
            Pending Review
          </Badge>
          <Badge variant="outline">
            {reviewState.pathBStatus === 'completed' ? (
              <>
                <CheckCircle className="h-3 w-3 mr-1 text-green-500" />
                Tables Ready
              </>
            ) : (
              <>
                <Loader2 className="h-3 w-3 mr-1 animate-spin" />
                Processing Tables...
              </>
            )}
          </Badge>
        </div>

        {/* Instructions */}
        <Card className="mb-6">
          <CardContent className="pt-6">
            <p className="text-sm text-muted-foreground">
              The AI has flagged some banner columns that may need your review. For each column below,
              you can approve the AI-generated R expression, edit it, or skip the cut entirely.
              Table processing continues in parallel.
            </p>
          </CardContent>
        </Card>

        {/* Flagged Columns */}
        <div className="space-y-4 mb-8">
          {reviewState.flaggedColumns.map((col) => {
            const key = `${col.groupName}/${col.columnName}`;
            const decision = decisions.get(key) || { action: 'approve' };
            return (
              <FlaggedColumnCard
                key={key}
                column={col}
                decision={decision}
                onDecisionChange={(d) => handleDecisionChange(col.groupName, col.columnName, d)}
              />
            );
          })}
        </div>

        {/* Summary and Actions */}
        <Card className="sticky bottom-4">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-4 text-sm">
                <span className="flex items-center gap-1">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  {approveCount} approve
                </span>
                <span className="flex items-center gap-1">
                  <Edit3 className="h-4 w-4 text-blue-500" />
                  {editCount} edit
                </span>
                <span className="flex items-center gap-1">
                  <SkipForward className="h-4 w-4 text-gray-500" />
                  {skipCount} skip
                </span>
              </div>
              <div className="flex items-center gap-2">
                <Button variant="outline" onClick={handleCancel} disabled={isSubmitting}>
                  <XCircle className="h-4 w-4 mr-2" />
                  Cancel Pipeline
                </Button>
                <Button onClick={handleSubmit} disabled={isSubmitting}>
                  {isSubmitting ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Resuming...
                    </>
                  ) : (
                    <>
                      <Play className="h-4 w-4 mr-2" />
                      Save & Continue
                    </>
                  )}
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
