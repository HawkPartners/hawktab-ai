'use client';

import { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from 'sonner';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import {
  Download,
  CheckCircle,
  AlertCircle,
  Clock,
  FileSpreadsheet,
  FileText,
  File,
  Loader2,
  Table,
  BarChart3,
  Layers,
  AlertTriangle,
  Play,
  XCircle,
  MessageSquare,
  X,
} from 'lucide-react';
import type { PipelineDetails, FileInfo } from '@/app/api/pipelines/[pipelineId]/route';

function formatDate(timestamp: string): string {
  const date = new Date(timestamp);
  return date.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

function formatDateTime(timestamp: string): string {
  const date = new Date(timestamp);
  return date.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function FileIcon({ filename }: { filename: string }) {
  const ext = filename.split('.').pop()?.toLowerCase();
  switch (ext) {
    case 'xlsx':
    case 'xls':
    case 'csv':
      return <FileSpreadsheet className="h-5 w-5 text-green-600" />;
    case 'json':
      return <FileText className="h-5 w-5 text-blue-600" />;
    case 'r':
      return <FileText className="h-5 w-5 text-purple-600" />;
    case 'md':
      return <FileText className="h-5 w-5 text-gray-600" />;
    default:
      return <File className="h-5 w-5 text-gray-500" />;
  }
}

function StatusBadge({ status }: { status: string }) {
  switch (status) {
    case 'success':
      return (
        <Badge variant="default" className="bg-green-500">
          <CheckCircle className="h-3 w-3 mr-1" />
          Success
        </Badge>
      );
    case 'partial':
      return (
        <Badge variant="default" className="bg-yellow-500">
          <AlertCircle className="h-3 w-3 mr-1" />
          Partial
        </Badge>
      );
    case 'error':
      return (
        <Badge variant="destructive">
          <AlertCircle className="h-3 w-3 mr-1" />
          Error
        </Badge>
      );
    case 'in_progress':
      return (
        <Badge variant="secondary" className="bg-blue-500/20 text-blue-700 dark:text-blue-400">
          <Clock className="h-3 w-3 mr-1" />
          In Progress
        </Badge>
      );
    case 'pending_review':
      return (
        <Badge variant="secondary" className="bg-yellow-500/20 text-yellow-700 dark:text-yellow-400">
          <AlertTriangle className="h-3 w-3 mr-1" />
          Review Required
        </Badge>
      );
    case 'cancelled':
      return (
        <Badge variant="secondary" className="bg-gray-500/20 text-gray-700 dark:text-gray-400">
          <AlertCircle className="h-3 w-3 mr-1" />
          Cancelled
        </Badge>
      );
    case 'awaiting_tables':
      return (
        <Badge variant="secondary" className="bg-purple-500/20 text-purple-700 dark:text-purple-400">
          <Clock className="h-3 w-3 mr-1" />
          Completing...
        </Badge>
      );
    default:
      return (
        <Badge variant="secondary">
          <Clock className="h-3 w-3 mr-1" />
          Processing
        </Badge>
      );
  }
}

function FileCard({ file, pipelineId }: { file: FileInfo; pipelineId: string }) {
  const isPrimaryOutput = file.name === 'crosstabs.xlsx';

  return (
    <Card className={`${isPrimaryOutput ? 'border-primary' : ''}`}>
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <FileIcon filename={file.name} />
            <div>
              <p className="font-medium text-sm">{file.name}</p>
              <p className="text-xs text-muted-foreground">{formatFileSize(file.size)}</p>
            </div>
          </div>
          <a
            href={`/api/pipelines/${encodeURIComponent(pipelineId)}/files/${encodeURIComponent(file.path)}`}
            download={file.name}
          >
            <Button variant={isPrimaryOutput ? 'default' : 'outline'} size="sm">
              <Download className="h-4 w-4 mr-1" />
              Download
            </Button>
          </a>
        </div>
        {isPrimaryOutput && (
          <Badge variant="secondary" className="mt-2 text-xs">
            Primary Output
          </Badge>
        )}
      </CardContent>
    </Card>
  );
}

export default function ProjectDetailPage({
  params,
}: {
  params: Promise<{ projectId: string }>;
}) {
  const { projectId } = use(params);
  const pipelineId = projectId;
  const [details, setDetails] = useState<PipelineDetails | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isCancelling, setIsCancelling] = useState(false);
  const [showFeedbackForm, setShowFeedbackForm] = useState(false);
  const [feedbackNotes, setFeedbackNotes] = useState('');
  const [feedbackRating, setFeedbackRating] = useState('0');
  const [tableIdInput, setTableIdInput] = useState('');
  const [tableIds, setTableIds] = useState<string[]>([]);
  const [isSubmittingFeedback, setIsSubmittingFeedback] = useState(false);
  const router = useRouter();

  const addTableIdsFromInput = () => {
    const raw = tableIdInput.trim();
    if (!raw) return;
    const parsed = raw
      .split(/[\n,\t ]+/g)
      .map(s => s.trim())
      .filter(Boolean);

    const next = new Set<string>(tableIds);
    for (const id of parsed) next.add(id);
    setTableIds(Array.from(next));
    setTableIdInput('');
  };

  const removeTableId = (id: string) => {
    setTableIds(tableIds.filter(t => t !== id));
  };

  const submitFeedback = async () => {
    if (!details) return;
    if (isSubmittingFeedback) return;

    setIsSubmittingFeedback(true);
    try {
      const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}/feedback`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          rating: Number(feedbackRating) || 0,
          notes: feedbackNotes,
          tableIds,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data?.error || 'Failed to submit feedback');
      }

      toast.success('Feedback submitted', {
        description: 'Thanks — this helps us improve the pipeline.',
      });

      if (data?.summary) {
        setDetails(prev => prev ? { ...prev, feedback: data.summary } : prev);
      }

      setFeedbackNotes('');
      setFeedbackRating('0');
      setTableIds([]);
      setTableIdInput('');
    } catch (err) {
      toast.error('Failed to submit feedback', {
        description: err instanceof Error ? err.message : 'Unknown error',
      });
    } finally {
      setIsSubmittingFeedback(false);
    }
  };

  const handleCancel = async () => {
    setIsCancelling(true);
    try {
      const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}/cancel`, {
        method: 'POST',
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || 'Failed to cancel pipeline');
      }

      router.push('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
      setIsCancelling(false);
    }
  };

  // Initial fetch
  useEffect(() => {
    const fetchDetails = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}`);
        if (!res.ok) {
          const errData = await res.json();
          throw new Error(errData.error || 'Failed to fetch pipeline details');
        }
        const data = await res.json();
        setDetails(data);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setIsLoading(false);
      }
    };

    fetchDetails();
  }, [pipelineId]);

  // Poll for updates when status is active
  const currentStatus = details?.status;
  useEffect(() => {
    const activeStatuses = ['in_progress', 'pending_review', 'awaiting_tables'];
    if (!currentStatus || !activeStatuses.includes(currentStatus)) {
      return;
    }

    const pollDetails = async () => {
      try {
        const res = await fetch(`/api/pipelines/${encodeURIComponent(pipelineId)}`);
        if (res.ok) {
          const data = await res.json();
          setDetails(data);
        }
      } catch {
        // Ignore polling errors
      }
    };

    const pollInterval = setInterval(pollDetails, 3000);

    return () => clearInterval(pollInterval);
  }, [pipelineId, currentStatus]);

  if (isLoading) {
    return (
      <div className="py-12">
        <div className="max-w-4xl mx-auto">
          <div className="flex items-center justify-center py-20">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        </div>
      </div>
    );
  }

  if (error || !details) {
    return (
      <div className="py-12">
        <div className="max-w-4xl mx-auto">
          <AppBreadcrumbs
            segments={[
              { label: 'Dashboard', href: '/dashboard' },
              { label: 'Not Found' },
            ]}
          />
          <div className="text-center mt-8">
            <h1 className="text-3xl font-bold tracking-tight mb-2">Pipeline Not Found</h1>
            <p className="text-muted-foreground">
              {error || 'The requested pipeline could not be found.'}
            </p>
            <Button variant="outline" size="sm" onClick={() => router.push('/dashboard')} className="mt-4">
              Back to Dashboard
            </Button>
          </div>
        </div>
      </div>
    );
  }

  const outputFiles = details.files.filter((f) => f.type === 'output');
  const inputFiles = details.files.filter((f) => f.type === 'input');
  const isActive = details.status === 'in_progress' || details.status === 'pending_review' || details.status === 'awaiting_tables';
  const hasOutputs = details.outputs.tables > 0 || details.outputs.cuts > 0;
  const feedbackAvailable = !isActive;

  return (
    <div>
      <AppBreadcrumbs
        segments={[
          { label: 'Dashboard', href: '/dashboard' },
          { label: details.dataset },
        ]}
      />

      <div className="max-w-4xl mt-6">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold tracking-tight mb-2">
            {details.dataset}
          </h1>
          <p className="text-muted-foreground text-sm">
            Run on {formatDate(details.timestamp)}
          </p>
        </div>

        {/* Status and Duration */}
        <div className="flex items-center gap-4 mb-8">
          <StatusBadge status={details.status} />
          <Badge variant="outline">
            <Clock className="h-3 w-3 mr-1" />
            {isActive ? details.duration.formatted : `Duration: ${details.duration.formatted}`}
          </Badge>
        </div>

        {/* Review Required Banner */}
        {details.status === 'pending_review' && details.review && (
          <Card className="mb-8 border-yellow-500/50 bg-yellow-500/5">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <AlertTriangle className="h-5 w-5 text-yellow-500" />
                  <div>
                    <p className="font-medium">Human Review Required</p>
                    <p className="text-sm text-muted-foreground">
                      {details.review.flaggedColumnCount} banner column{details.review.flaggedColumnCount !== 1 ? 's' : ''} need your attention before processing can continue.
                    </p>
                  </div>
                </div>
                <Button onClick={() => router.push(`/projects/${encodeURIComponent(pipelineId)}/review`)}>
                  <Play className="h-4 w-4 mr-2" />
                  Review Now
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Processing Banner */}
        {details.status === 'in_progress' && (
          <Card className="mb-8 border-blue-500/50 bg-blue-500/5">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <Loader2 className="h-5 w-5 text-blue-500 animate-spin" />
                  <div>
                    <p className="font-medium">Processing Crosstabs</p>
                    <p className="text-sm text-muted-foreground">
                      {details.currentStage
                        ? `Currently: ${details.currentStage.replace(/_/g, ' ')}`
                        : 'Your crosstabs are being generated. This may take several minutes.'}
                    </p>
                  </div>
                </div>
                <Button
                  variant="outline"
                  onClick={handleCancel}
                  disabled={isCancelling}
                >
                  {isCancelling ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Cancelling...
                    </>
                  ) : (
                    <>
                      <XCircle className="h-4 w-4 mr-2" />
                      Cancel
                    </>
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Cancelled Banner */}
        {details.status === 'cancelled' && (
          <Card className="mb-8 border-gray-500/50 bg-gray-500/5">
            <CardContent className="p-6">
              <div className="flex items-center gap-3">
                <AlertCircle className="h-5 w-5 text-gray-500" />
                <div>
                  <p className="font-medium">Pipeline Cancelled</p>
                  <p className="text-sm text-muted-foreground">
                    This pipeline was cancelled and did not complete processing.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Awaiting Tables Banner */}
        {details.status === 'awaiting_tables' && (
          <Card className="mb-8 border-purple-500/50 bg-purple-500/5">
            <CardContent className="p-6">
              <div className="flex items-center gap-3">
                <Loader2 className="h-5 w-5 text-purple-500 animate-spin" />
                <div>
                  <p className="font-medium">Completing Pipeline</p>
                  <p className="text-sm text-muted-foreground">
                    Your review has been saved. Waiting for table data to finish processing before generating final output.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Summary Stats */}
        {(hasOutputs || (!isActive && details.status !== 'cancelled')) && (
          <Card className="mb-8">
            <CardHeader>
              <CardTitle className="text-lg">Summary Statistics</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="text-center p-3 bg-muted rounded-lg">
                  <Table className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{details.outputs.tables}</p>
                  <p className="text-xs text-muted-foreground">Tables</p>
                </div>
                <div className="text-center p-3 bg-muted rounded-lg">
                  <BarChart3 className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{details.outputs.cuts}</p>
                  <p className="text-xs text-muted-foreground">Cuts</p>
                </div>
                <div className="text-center p-3 bg-muted rounded-lg">
                  <Layers className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{details.outputs.bannerGroups}</p>
                  <p className="text-xs text-muted-foreground">Banner Groups</p>
                </div>
                <div className="text-center p-3 bg-muted rounded-lg">
                  <FileText className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{details.outputs.variables}</p>
                  <p className="text-xs text-muted-foreground">Variables</p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Output Files */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="text-lg">Output Files</CardTitle>
          </CardHeader>
          <CardContent>
            {outputFiles.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {outputFiles.map((file) => (
                  <FileCard key={file.path} file={file} pipelineId={pipelineId} />
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                {isActive ? 'Output files will appear here once processing completes.' : 'No output files available'}
              </p>
            )}
          </CardContent>
        </Card>

        {/* Output Feedback */}
        <Card className="mb-8">
          <CardHeader>
            <div className="flex items-start justify-between gap-4">
              <div>
                <CardTitle className="text-lg flex items-center gap-2">
                  <MessageSquare className="h-5 w-5 text-primary" />
                  Output Feedback
                </CardTitle>
                <p className="text-sm text-muted-foreground mt-1">
                  Tell us what was wrong or missing in this output. This does not re-run anything; it&apos;s for improving future runs.
                </p>
              </div>
              <Button
                variant={showFeedbackForm ? 'outline' : 'default'}
                onClick={() => setShowFeedbackForm(v => !v)}
                disabled={!feedbackAvailable}
              >
                {showFeedbackForm ? 'Hide' : 'Leave Feedback'}
              </Button>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {!feedbackAvailable && (
              <p className="text-sm text-muted-foreground">
                Feedback becomes available once the pipeline completes.
              </p>
            )}

            {details.feedback?.hasFeedback && (
              <div className="flex flex-wrap items-center gap-2 text-sm">
                <Badge variant="secondary">
                  {details.feedback.entryCount} entr{details.feedback.entryCount === 1 ? 'y' : 'ies'}
                </Badge>
                {details.feedback.lastSubmittedAt && (
                  <span className="text-muted-foreground">
                    Last submitted {formatDateTime(details.feedback.lastSubmittedAt)}
                  </span>
                )}
              </div>
            )}

            {showFeedbackForm && (
              <div className="space-y-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label>Overall quality (optional)</Label>
                    <Select value={feedbackRating} onValueChange={setFeedbackRating} disabled={!feedbackAvailable || isSubmittingFeedback}>
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder="Not sure" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="0">Not sure</SelectItem>
                        <SelectItem value="1">1 - Very poor</SelectItem>
                        <SelectItem value="2">2 - Poor</SelectItem>
                        <SelectItem value="3">3 - OK</SelectItem>
                        <SelectItem value="4">4 - Good</SelectItem>
                        <SelectItem value="5">5 - Great</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-2">
                    <Label>Table IDs (optional)</Label>
                    <div className="flex gap-2">
                      <Input
                        value={tableIdInput}
                        onChange={(e) => setTableIdInput(e.target.value)}
                        placeholder="Paste one or more table IDs"
                        disabled={!feedbackAvailable || isSubmittingFeedback}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault();
                            addTableIdsFromInput();
                          }
                        }}
                      />
                      <Button
                        type="button"
                        variant="outline"
                        onClick={addTableIdsFromInput}
                        disabled={!feedbackAvailable || isSubmittingFeedback || tableIdInput.trim().length === 0}
                      >
                        Add
                      </Button>
                    </div>
                    {tableIds.length > 0 && (
                      <div className="flex flex-wrap gap-2 pt-1">
                        {tableIds.map((id) => (
                          <Badge key={id} variant="secondary" className="flex items-center gap-1">
                            <span>{id}</span>
                            <button
                              type="button"
                              className="ml-1 opacity-70 hover:opacity-100"
                              onClick={() => removeTableId(id)}
                              aria-label={`Remove ${id}`}
                              disabled={!feedbackAvailable || isSubmittingFeedback}
                            >
                              <X className="h-3 w-3" />
                            </button>
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Notes</Label>
                  <Textarea
                    value={feedbackNotes}
                    onChange={(e) => setFeedbackNotes(e.target.value)}
                    placeholder="e.g., missing NETs, wrong table structure, tables that should be excluded, bad labels..."
                    disabled={!feedbackAvailable || isSubmittingFeedback}
                  />
                </div>

                <div className="flex items-center justify-end gap-2">
                  <Button
                    variant="outline"
                    onClick={() => setShowFeedbackForm(false)}
                    disabled={isSubmittingFeedback}
                  >
                    Close
                  </Button>
                  <Button
                    onClick={submitFeedback}
                    disabled={!feedbackAvailable || isSubmittingFeedback}
                  >
                    {isSubmittingFeedback ? (
                      <>
                        <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                        Submitting...
                      </>
                    ) : (
                      'Submit Feedback'
                    )}
                  </Button>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Input Files */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Input Files</CardTitle>
          </CardHeader>
          <CardContent>
            {inputFiles.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {inputFiles.map((file) => (
                  <FileCard key={file.path} file={file} pipelineId={pipelineId} />
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">
                No input files available. Input files from: {details.inputs.datamap}, {details.inputs.banner}, {details.inputs.spss}
                {details.inputs.survey && `, ${details.inputs.survey}`}
              </p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
