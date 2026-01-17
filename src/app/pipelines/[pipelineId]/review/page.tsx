'use client';

import { useState, useEffect, use, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { PageHeader } from '@/components/PageHeader';
import {
  ArrowLeft,
  AlertTriangle,
  CheckCircle,
  SkipForward,
  Loader2,
  Play,
  XCircle,
  Lightbulb,
  ListOrdered,
  ChevronDown,
  ChevronRight,
} from 'lucide-react';

/**
 * Strip emoji characters from text for professional display
 */
function stripEmojis(text: string): string {
  return text
    .replace(/[\u{1F300}-\u{1F9FF}]/gu, '')
    .replace(/[\u{2600}-\u{26FF}]/gu, '')
    .replace(/[\u{2700}-\u{27BF}]/gu, '')
    .replace(/[\u{FE00}-\u{FE0F}]/gu, '')
    .replace(/[\u{1F000}-\u{1F02F}]/gu, '')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

// Crosstab review interfaces
interface Alternative {
  expression: string;
  confidence: number;
  reason: string;
}

interface FlaggedCrosstabColumn {
  groupName: string;
  columnName: string;
  original: string;
  proposed: string;
  confidence: number;
  reason: string;
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
  action: 'approve' | 'select_alternative' | 'provide_hint' | 'skip';
  selectedAlternative?: number;
  hint?: string;
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

function CrosstabColumnCard({
  column,
  decision,
  onDecisionChange,
}: {
  column: FlaggedCrosstabColumn;
  decision: CrosstabDecision;
  onDecisionChange: (decision: CrosstabDecision) => void;
}) {
  const [hintValue, setHintValue] = useState('');
  const [showConcerns, setShowConcerns] = useState(false);

  const handleActionChange = (action: CrosstabDecision['action']) => {
    const newDecision: CrosstabDecision = { action };

    switch (action) {
      case 'provide_hint':
        newDecision.hint = hintValue;
        break;
      case 'select_alternative':
        newDecision.selectedAlternative = 0;
        break;
    }

    onDecisionChange(newDecision);
  };

  const handleHintChange = (value: string) => {
    setHintValue(value);
    if (decision.action === 'provide_hint') {
      onDecisionChange({ action: 'provide_hint', hint: value });
    }
  };

  const handleSelectAlternative = (index: number) => {
    onDecisionChange({ action: 'select_alternative', selectedAlternative: index });
  };

  // Get the currently selected expression (either proposed or selected alternative)
  const getSelectedExpression = () => {
    if (decision.action === 'select_alternative' && decision.selectedAlternative !== undefined) {
      return column.alternatives[decision.selectedAlternative]?.expression || column.proposed;
    }
    return column.proposed;
  };

  return (
    <Card className="border-yellow-500/50">
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between">
          <CardTitle className="text-base">{column.columnName}</CardTitle>
          <ConfidenceBadge confidence={column.confidence} />
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Banner says vs AI suggests - simplified layout */}
        <div className="space-y-2">
          <div className="flex items-baseline gap-3">
            <Label className="text-xs text-muted-foreground w-24 shrink-0">Banner says:</Label>
            <div className="p-2 bg-muted rounded text-sm font-mono break-all flex-1">
              {column.original || <span className="text-muted-foreground italic">Empty</span>}
            </div>
          </div>
          <div className="flex items-baseline gap-3">
            <Label className="text-xs text-muted-foreground w-24 shrink-0">AI suggests:</Label>
            <div className="p-2 bg-blue-50 dark:bg-blue-950 rounded text-sm font-mono break-all flex-1 border border-blue-200 dark:border-blue-800">
              {decision.action === 'select_alternative' && decision.selectedAlternative !== undefined ? (
                <span className="text-purple-700 dark:text-purple-400">
                  {getSelectedExpression()}
                </span>
              ) : (
                column.proposed || <span className="text-muted-foreground italic">NA</span>
              )}
            </div>
          </div>
        </div>

        {/* Action buttons - horizontal layout */}
        <div className="flex flex-wrap gap-2 pt-2">
          <Button
            variant={decision.action === 'approve' ? 'default' : 'outline'}
            size="sm"
            onClick={() => handleActionChange('approve')}
          >
            Accept
          </Button>

          {column.alternatives && column.alternatives.length > 0 && (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button
                  variant={decision.action === 'select_alternative' ? 'secondary' : 'outline'}
                  size="sm"
                >
                  Pick alternative <ChevronDown className="ml-1 h-3 w-3" />
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="start" className="max-w-md">
                {column.alternatives.map((alt, i) => (
                  <DropdownMenuItem
                    key={i}
                    onClick={() => handleSelectAlternative(i)}
                    className="flex flex-col items-start gap-1 py-2"
                  >
                    <span className="font-mono text-xs break-all">{alt.expression}</span>
                    <span className="text-xs text-muted-foreground">
                      {Math.round(alt.confidence * 100)}% confident
                    </span>
                  </DropdownMenuItem>
                ))}
              </DropdownMenuContent>
            </DropdownMenu>
          )}

          <Button
            variant={decision.action === 'provide_hint' ? 'secondary' : 'outline'}
            size="sm"
            onClick={() => handleActionChange('provide_hint')}
          >
            Give hint
          </Button>

          <Button
            variant={decision.action === 'skip' ? 'secondary' : 'outline'}
            size="sm"
            onClick={() => handleActionChange('skip')}
          >
            Skip
          </Button>
        </div>

        {/* Hint input - shown when give hint is selected */}
        {decision.action === 'provide_hint' && (
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Your hint (e.g., &ldquo;use variable Q5&rdquo;)</Label>
            <Input
              value={hintValue}
              onChange={(e) => handleHintChange(e.target.value)}
              placeholder="e.g., use variable Q5, not S2"
              className="text-sm"
            />
          </div>
        )}

        {/* AI Concerns - collapsed by default */}
        {column.uncertainties && column.uncertainties.length > 0 && (
          <div className="pt-2">
            <button
              onClick={() => setShowConcerns(!showConcerns)}
              className="flex items-center gap-2 text-left text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              {showConcerns ? (
                <ChevronDown className="h-4 w-4" />
              ) : (
                <ChevronRight className="h-4 w-4" />
              )}
              <AlertTriangle className="h-4 w-4 text-yellow-600" />
              <span>
                {column.uncertainties.length} AI Concern{column.uncertainties.length !== 1 ? 's' : ''}
              </span>
            </button>
            {showConcerns && (
              <ul className="text-sm text-muted-foreground space-y-1 mt-2 ml-6">
                {column.uncertainties.map((u, i) => (
                  <li key={i} className="flex items-start gap-1">
                    <span className="mt-0.5">•</span>
                    <span>{stripEmojis(u)}</span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        )}
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

  // Group flagged columns by groupName
  const groupedColumns = useMemo(() => {
    if (!reviewState) return new Map<string, FlaggedCrosstabColumn[]>();
    const groups = new Map<string, FlaggedCrosstabColumn[]>();
    for (const col of reviewState.flaggedColumns) {
      const existing = groups.get(col.groupName) || [];
      existing.push(col);
      groups.set(col.groupName, existing);
    }
    return groups;
  }, [reviewState]);

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

  // Poll for Path B status updates while it's still running
  const pathBStatus = reviewState?.pathBStatus;
  useEffect(() => {
    if (!pathBStatus || pathBStatus !== 'running') return;

    const pollInterval = setInterval(async () => {
      try {
        const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}/review`);
        if (!res.ok) return;
        const data = await res.json() as CrosstabReviewState;

        if (data.pathBStatus !== pathBStatus) {
          setReviewState(prev => prev ? { ...prev, pathBStatus: data.pathBStatus } : null);
        }
      } catch {
        // Ignore polling errors
      }
    }, 3000);

    return () => clearInterval(pollInterval);
  }, [pipelineId, pathBStatus]);

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
  const skipCount = Array.from(decisions.values()).filter(d => d.action === 'skip').length;

  return (
    <div className="py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <PageHeader
          title="Quick Review Needed"
          description={`The AI wasn't certain about ${reviewState.flaggedColumns.length} matches. Please confirm or correct.`}
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
            ) : reviewState.pathBStatus === 'error' ? (
              <>
                <XCircle className="h-3 w-3 mr-1 text-red-500" />
                Table Processing Failed
              </>
            ) : (
              <>
                <Loader2 className="h-3 w-3 mr-1 animate-spin" />
                Processing Tables...
              </>
            )}
          </Badge>
        </div>

        {/* Flagged Columns - grouped by banner group */}
        <div className="space-y-6 mb-8">
          {Array.from(groupedColumns.entries()).map(([groupName, columns]) => (
            <div key={groupName}>
              <h3 className="text-lg font-semibold mb-3 px-1">{groupName}</h3>
              <div className="space-y-3">
                {columns.map((col) => {
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
            </div>
          ))}
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
                      {reviewState.pathBStatus === 'running' ? 'Waiting for tables...' : 'Processing...'}
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
