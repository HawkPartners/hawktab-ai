'use client';

import { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
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
  Lightbulb,
  ListOrdered,
} from 'lucide-react';

// Crosstab review interfaces
interface Alternative {
  expression: string;
  confidence: number;
  reason: string;
}

interface FlaggedCrosstabColumn {
  groupName: string;
  columnName: string;
  original: string;        // From banner document
  proposed: string;        // CrosstabAgent's R expression
  confidence: number;
  reason: string;          // Why this mapping was chosen
  alternatives: Alternative[];
  uncertainties: string[];
  expressionType?: string;
}

interface CrosstabReviewState {
  reviewType: 'crosstab' | 'banner';
  pipelineId: string;
  status: 'awaiting_review' | 'approved' | 'cancelled';
  createdAt: string;
  flaggedColumns: FlaggedCrosstabColumn[];
  pathBStatus: 'completed' | 'running' | 'error';
  totalColumns: number;
  decisions: CrosstabDecision[];
}

interface CrosstabDecision {
  action: 'approve' | 'select_alternative' | 'provide_hint' | 'edit' | 'skip';
  selectedAlternative?: number;
  hint?: string;
  editedExpression?: string;
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

function ExpressionTypeBadge({ type }: { type?: string }) {
  if (!type) return null;

  const labels: Record<string, { label: string; className: string }> = {
    direct_variable: { label: 'Direct', className: 'bg-green-100 text-green-800' },
    comparison: { label: 'Comparison', className: 'bg-blue-100 text-blue-800' },
    conceptual_filter: { label: 'Conceptual', className: 'bg-orange-100 text-orange-800' },
    from_list: { label: 'From List', className: 'bg-purple-100 text-purple-800' },
    placeholder: { label: 'Placeholder', className: 'bg-red-100 text-red-800' },
    total: { label: 'Total', className: 'bg-gray-100 text-gray-800' },
  };

  const config = labels[type] || { label: type, className: 'bg-gray-100 text-gray-800' };

  return (
    <Badge variant="outline" className={config.className}>
      {config.label}
    </Badge>
  );
}

function CrosstabColumnCard({
  column,
  decision,
  onDecisionChange,
}: {
  column: FlaggedCrosstabColumn;
  decision: CrosstabDecision;
  onDecisionChange: (decision: CrosstabDecision) => void;
}) {
  const [editValue, setEditValue] = useState(column.proposed);
  const [hintValue, setHintValue] = useState('');
  const [selectedAltIndex, setSelectedAltIndex] = useState<string>('0');

  const handleActionChange = (action: CrosstabDecision['action']) => {
    const newDecision: CrosstabDecision = { action };

    switch (action) {
      case 'edit':
        newDecision.editedExpression = editValue;
        break;
      case 'provide_hint':
        newDecision.hint = hintValue;
        break;
      case 'select_alternative':
        newDecision.selectedAlternative = parseInt(selectedAltIndex, 10);
        break;
    }

    onDecisionChange(newDecision);
  };

  const handleEditValueChange = (value: string) => {
    setEditValue(value);
    if (decision.action === 'edit') {
      onDecisionChange({ action: 'edit', editedExpression: value });
    }
  };

  const handleHintChange = (value: string) => {
    setHintValue(value);
    if (decision.action === 'provide_hint') {
      onDecisionChange({ action: 'provide_hint', hint: value });
    }
  };

  const handleAlternativeChange = (value: string) => {
    setSelectedAltIndex(value);
    if (decision.action === 'select_alternative') {
      onDecisionChange({ action: 'select_alternative', selectedAlternative: parseInt(value, 10) });
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
            <ExpressionTypeBadge type={column.expressionType} />
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Original Expression */}
        <div className="space-y-1">
          <Label className="text-xs text-muted-foreground">Original Expression (from banner)</Label>
          <div className="p-2 bg-muted rounded text-sm font-mono break-all">
            {column.original || <span className="text-muted-foreground italic">Empty</span>}
          </div>
        </div>

        {/* What AI Found */}
        <div className="space-y-1">
          <Label className="text-xs text-muted-foreground">What We Found</Label>
          <p className="text-sm text-muted-foreground">{column.reason}</p>
        </div>

        {/* Proposed R Expression */}
        <div className="space-y-1">
          <Label className="text-xs text-muted-foreground">Proposed R Expression</Label>
          <div className="p-2 bg-blue-50 dark:bg-blue-950 rounded text-sm font-mono break-all border border-blue-200 dark:border-blue-800">
            {column.proposed || <span className="text-muted-foreground italic">NA</span>}
          </div>
        </div>

        {/* Alternatives */}
        {column.alternatives && column.alternatives.length > 0 && (
          <div className="space-y-2">
            <Label className="text-xs text-muted-foreground flex items-center gap-1">
              <ListOrdered className="h-3 w-3" />
              Alternative Mappings Found ({column.alternatives.length})
            </Label>
            <div className="space-y-2">
              {column.alternatives.map((alt, i) => (
                <div key={i} className="p-2 bg-muted rounded border text-sm">
                  <div className="font-mono text-xs break-all">{alt.expression}</div>
                  <div className="text-xs text-muted-foreground mt-1">{alt.reason}</div>
                  <Badge variant="outline" className="mt-1 text-xs">
                    {Math.round(alt.confidence * 100)}% confident
                  </Badge>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* AI Concerns / Uncertainties */}
        {column.uncertainties && column.uncertainties.length > 0 && (
          <div className="p-3 rounded-md border border-yellow-500/50 bg-yellow-50 dark:bg-yellow-950">
            <div className="flex items-center gap-2 mb-2">
              <AlertTriangle className="h-4 w-4 text-yellow-600" />
              <span className="font-medium text-sm text-yellow-700 dark:text-yellow-400">AI Concerns</span>
            </div>
            <ul className="text-sm text-yellow-700 dark:text-yellow-400 space-y-1">
              {column.uncertainties.map((u, i) => (
                <li key={i} className="flex items-start gap-1">
                  <span className="mt-0.5">•</span>
                  <span>{u}</span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Decision */}
        <div className="space-y-3 pt-2 border-t">
          <Label className="text-sm font-medium">Your Decision</Label>
          <RadioGroup
            value={decision.action}
            onValueChange={(v) => handleActionChange(v as CrosstabDecision['action'])}
            className="space-y-2"
          >
            {/* Approve */}
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="approve" id={`${column.groupName}-${column.columnName}-approve`} />
              <Label
                htmlFor={`${column.groupName}-${column.columnName}-approve`}
                className="flex items-center gap-2 cursor-pointer"
              >
                <CheckCircle className="h-4 w-4 text-green-500" />
                Approve proposed mapping
              </Label>
            </div>

            {/* Select Alternative */}
            {column.alternatives && column.alternatives.length > 0 && (
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="select_alternative" id={`${column.groupName}-${column.columnName}-alt`} />
                <Label
                  htmlFor={`${column.groupName}-${column.columnName}-alt`}
                  className="flex items-center gap-2 cursor-pointer"
                >
                  <ListOrdered className="h-4 w-4 text-purple-500" />
                  Use alternative
                </Label>
              </div>
            )}

            {/* Provide Hint */}
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="provide_hint" id={`${column.groupName}-${column.columnName}-hint`} />
              <Label
                htmlFor={`${column.groupName}-${column.columnName}-hint`}
                className="flex items-center gap-2 cursor-pointer"
              >
                <Lightbulb className="h-4 w-4 text-yellow-500" />
                Provide a hint (re-run with context)
              </Label>
            </div>

            {/* Edit directly */}
            <div className="flex items-center space-x-2">
              <RadioGroupItem value="edit" id={`${column.groupName}-${column.columnName}-edit`} />
              <Label
                htmlFor={`${column.groupName}-${column.columnName}-edit`}
                className="flex items-center gap-2 cursor-pointer"
              >
                <Edit3 className="h-4 w-4 text-blue-500" />
                Edit expression directly
              </Label>
            </div>

            {/* Skip */}
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

          {/* Alternative selector */}
          {decision.action === 'select_alternative' && column.alternatives && column.alternatives.length > 0 && (
            <div className="pl-6 space-y-1">
              <Label className="text-xs text-muted-foreground">Select alternative</Label>
              <Select value={selectedAltIndex} onValueChange={handleAlternativeChange}>
                <SelectTrigger className="w-full">
                  <SelectValue placeholder="Choose an alternative" />
                </SelectTrigger>
                <SelectContent>
                  {column.alternatives.map((alt, i) => (
                    <SelectItem key={i} value={String(i)}>
                      <span className="font-mono text-xs">{alt.expression}</span>
                      <span className="text-xs text-muted-foreground ml-2">({Math.round(alt.confidence * 100)}%)</span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Hint input */}
          {decision.action === 'provide_hint' && (
            <div className="pl-6 space-y-1">
              <Label className="text-xs text-muted-foreground">Your hint (e.g., &ldquo;use variable Q5&rdquo;)</Label>
              <Input
                value={hintValue}
                onChange={(e) => handleHintChange(e.target.value)}
                placeholder="e.g., use variable Q5, not S2"
                className="text-sm"
              />
            </div>
          )}

          {/* Edit input */}
          {decision.action === 'edit' && (
            <div className="pl-6 space-y-1">
              <Label className="text-xs text-muted-foreground">Your R expression</Label>
              <Input
                value={editValue}
                onChange={(e) => handleEditValueChange(e.target.value)}
                placeholder="Enter R expression..."
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
  const [reviewState, setReviewState] = useState<CrosstabReviewState | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [decisions, setDecisions] = useState<Map<string, CrosstabDecision>>(new Map());
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
        const data = await res.json() as CrosstabReviewState;
        setReviewState(data);

        // Initialize decisions (default to approve)
        const initialDecisions = new Map<string, CrosstabDecision>();
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

  const handleDecisionChange = (groupName: string, columnName: string, decision: CrosstabDecision) => {
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
          selectedAlternative: decision.selectedAlternative,
          hint: decision.hint,
          editedExpression: decision.editedExpression,
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
  const altCount = Array.from(decisions.values()).filter(d => d.action === 'select_alternative').length;
  const hintCount = Array.from(decisions.values()).filter(d => d.action === 'provide_hint').length;
  const editCount = Array.from(decisions.values()).filter(d => d.action === 'edit').length;
  const skipCount = Array.from(decisions.values()).filter(d => d.action === 'skip').length;

  const reviewTitle = reviewState.reviewType === 'crosstab'
    ? 'Mapping Review Required'
    : 'Banner Review Required';

  return (
    <div className="py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <PageHeader
          title={reviewTitle}
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
              {reviewState.reviewType === 'crosstab' ? (
                <>
                  The AI has mapped your banner expressions to R syntax, but some mappings need verification.
                  For each column, you&apos;ll see what the AI found in the data map and its proposed R expression.
                  You can approve, select an alternative, provide a hint to re-run, edit directly, or skip.
                </>
              ) : (
                <>
                  The AI has flagged some banner columns that may need your review. For each column below,
                  you can approve the AI-generated R expression, edit it, or skip the cut entirely.
                </>
              )}
            </p>
          </CardContent>
        </Card>

        {/* Flagged Columns */}
        <div className="space-y-4 mb-8">
          {reviewState.flaggedColumns.map((col) => {
            const key = `${col.groupName}/${col.columnName}`;
            const decision = decisions.get(key) || { action: 'approve' };
            return (
              <CrosstabColumnCard
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
              <div className="flex items-center gap-3 text-sm flex-wrap">
                <span className="flex items-center gap-1">
                  <CheckCircle className="h-4 w-4 text-green-500" />
                  {approveCount}
                </span>
                {altCount > 0 && (
                  <span className="flex items-center gap-1">
                    <ListOrdered className="h-4 w-4 text-purple-500" />
                    {altCount}
                  </span>
                )}
                {hintCount > 0 && (
                  <span className="flex items-center gap-1">
                    <Lightbulb className="h-4 w-4 text-yellow-500" />
                    {hintCount}
                  </span>
                )}
                {editCount > 0 && (
                  <span className="flex items-center gap-1">
                    <Edit3 className="h-4 w-4 text-blue-500" />
                    {editCount}
                  </span>
                )}
                {skipCount > 0 && (
                  <span className="flex items-center gap-1">
                    <SkipForward className="h-4 w-4 text-gray-500" />
                    {skipCount}
                  </span>
                )}
              </div>
              <div className="flex items-center gap-2">
                <Button variant="outline" onClick={handleCancel} disabled={isSubmitting}>
                  <XCircle className="h-4 w-4 mr-2" />
                  Cancel
                </Button>
                <Button onClick={handleSubmit} disabled={isSubmitting}>
                  {isSubmitting ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Processing...
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
