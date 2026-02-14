'use client';

import { useState, use } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from 'convex/react';
import posthog from 'posthog-js';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from 'sonner';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import { PipelineTimeline } from '@/components/pipeline-timeline';
import { useAuthContext } from '@/providers/auth-provider';
import { canPerform } from '@/lib/permissions';
import { formatDuration } from '@/lib/utils/formatDuration';
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
  Settings2,
  Trash2,
} from 'lucide-react';
import { ConfirmDestructiveDialog } from '@/components/confirm-destructive-dialog';
import { api } from '../../../../../convex/_generated/api';
import type { Id } from '../../../../../convex/_generated/dataModel';

function formatDate(timestampMs: number): string {
  const date = new Date(timestampMs);
  return date.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

function FileIcon({ filename }: { filename: string }) {
  const ext = filename.split('.').pop()?.toLowerCase();
  switch (ext) {
    case 'xlsx':
    case 'xls':
    case 'csv':
      return <FileSpreadsheet className="h-5 w-5 text-green-600" />;
    case 'pdf':
    case 'docx':
    case 'doc':
      return <FileText className="h-5 w-5 text-blue-600" />;
    case 'sav':
      return <File className="h-5 w-5 text-violet-600" />;
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
    case 'resuming':
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
    default:
      return (
        <Badge variant="secondary">
          <Clock className="h-3 w-3 mr-1" />
          Processing
        </Badge>
      );
  }
}

// Human-readable labels for crosstab Excel variants
const CROSSTAB_LABELS: Record<string, string> = {
  'results/crosstabs.xlsx': 'Crosstabs',
  'results/crosstabs-weighted.xlsx': 'Crosstabs (Weighted)',
  'results/crosstabs-unweighted.xlsx': 'Crosstabs (Unweighted)',
  'results/crosstabs-counts.xlsx': 'Crosstabs (Counts)',
  'results/crosstabs-weighted-counts.xlsx': 'Crosstabs (Weighted Counts)',
};

/** Extract the user-friendly download filename from an R2 output path */
function outputPathToFilename(outputPath: string): string {
  return outputPath.replace('results/', '');
}

/** Human-readable labels for input file fields */
const INPUT_FIELD_LABELS: Record<string, string> = {
  dataFile: 'Data File',
  dataMap: 'Data Map',
  bannerPlan: 'Banner Plan',
  survey: 'Survey Document',
  messageList: 'Message List',
};

// Config field display labels
const CONFIG_LABELS: Record<string, string> = {
  projectSubType: 'Project Type',
  bannerMode: 'Banner Mode',
  displayMode: 'Display Mode',
  separateWorkbooks: 'Separate Workbooks',
  theme: 'Excel Theme',
  weightVariable: 'Weight Variable',
  loopStatTestingMode: 'Loop Stat Testing',
  stopAfterVerification: 'Stop After Verification',
};

function formatConfigValue(key: string, config: Record<string, unknown>): string | null {
  if (key === 'statTesting') {
    const st = config.statTesting as { thresholds?: number[]; minBase?: number } | undefined;
    if (!st) return null;
    const thresholds = st.thresholds?.join(', ') ?? '90';
    const parts = [`${thresholds}% confidence`];
    if (st.minBase && st.minBase > 0) parts.push(`min base ${st.minBase}`);
    return parts.join(', ');
  }
  return null;
}

function ConfigValue({ value }: { value: unknown }) {
  if (value === null || value === undefined || value === '') {
    return <span className="text-muted-foreground">Not set</span>;
  }
  if (typeof value === 'boolean') {
    return <span>{value ? 'Yes' : 'No'}</span>;
  }
  return <span className="font-mono text-xs">{String(value)}</span>;
}

export default function ProjectDetailPage({
  params,
}: {
  params: Promise<{ projectId: string }>;
}) {
  const { projectId } = use(params);
  const router = useRouter();
  const { role, convexOrgId } = useAuthContext();
  const canCancel = canPerform(role, 'cancel_run');
  const canDelete = canPerform(role, 'delete_project');
  const [isCancelling, setIsCancelling] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [showFeedbackForm, setShowFeedbackForm] = useState(false);
  const [feedbackNotes, setFeedbackNotes] = useState('');
  const [feedbackRating, setFeedbackRating] = useState('0');
  const [tableIdInput, setTableIdInput] = useState('');
  const [tableIds, setTableIds] = useState<string[]>([]);
  const [isSubmittingFeedback, setIsSubmittingFeedback] = useState(false);

  // Convex subscriptions — real-time, no polling (org-scoped to prevent cross-tenant leakage)
  const project = useQuery(api.projects.get, convexOrgId
    ? { projectId: projectId as Id<"projects">, orgId: convexOrgId as Id<"organizations"> }
    : 'skip');
  const runs = useQuery(api.runs.getByProject, convexOrgId
    ? { projectId: projectId as Id<"projects">, orgId: convexOrgId as Id<"organizations"> }
    : 'skip');

  // Latest run (runs are sorted desc)
  const latestRun = runs?.[0];
  const runResult = latestRun?.result as Record<string, unknown> | undefined;
  const summary = runResult?.summary as Record<string, number> | undefined;
  const r2Files = runResult?.r2Files as { outputs?: Record<string, string> } | undefined;
  const hasR2Outputs = r2Files?.outputs && Object.keys(r2Files.outputs).length > 0;

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
    if (!latestRun || isSubmittingFeedback) return;
    const runIdStr = String(latestRun._id);

    setIsSubmittingFeedback(true);
    try {
      const res = await fetch(`/api/runs/${encodeURIComponent(runIdStr)}/feedback`, {
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

      // Track feedback submission
      posthog.capture('feedback_submitted', {
        project_id: projectId,
        run_id: runIdStr,
        rating: Number(feedbackRating) || 0,
        has_notes: feedbackNotes.trim().length > 0,
        table_ids_count: tableIds.length,
      });

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
    if (!latestRun) return;
    setIsCancelling(true);
    try {
      const res = await fetch(`/api/runs/${encodeURIComponent(String(latestRun._id))}/cancel`, {
        method: 'POST',
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || 'Failed to cancel pipeline');
      }

      // Track pipeline cancellation
      posthog.capture('pipeline_cancelled', {
        project_id: projectId,
        run_id: String(latestRun._id),
        previous_status: latestRun.status,
      });

      // Status update will come through Convex subscription
    } catch (err) {
      toast.error('Failed to cancel', {
        description: err instanceof Error ? err.message : 'Unknown error',
      });
      setIsCancelling(false);
    }
  };

  const handleDeleteProject = async () => {
    const res = await fetch(`/api/projects/${encodeURIComponent(projectId)}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const data = await res.json();
      toast.error('Failed to delete project', {
        description: data?.error || 'Unknown error',
      });
      throw new Error(data?.error || 'Failed to delete project');
    }
    posthog.capture('project_deleted', { project_id: projectId });
    toast.success('Project deleted');
    router.push('/dashboard');
  };

  // Loading state
  if (project === undefined || runs === undefined) {
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

  // Not found
  if (project === null) {
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
            <h1 className="text-3xl font-bold tracking-tight mb-2">Project Not Found</h1>
            <p className="text-muted-foreground">
              The requested project could not be found.
            </p>
            <Button variant="outline" size="sm" onClick={() => router.push('/dashboard')} className="mt-4">
              Back to Dashboard
            </Button>
          </div>
        </div>
      </div>
    );
  }

  const status = latestRun?.status || 'pending';
  const isActive = status === 'in_progress' || status === 'pending_review' || status === 'resuming';
  const hasOutputs = (summary?.tables ?? 0) > 0 || (summary?.cuts ?? 0) > 0;
  const feedbackAvailable = !isActive && (status === 'success' || status === 'partial');

  // Config for display
  const config = project.config as Record<string, unknown> | undefined;
  const configEntries: { key: string; label: string; value: unknown }[] = [];
  if (config) {
    // Standard fields from CONFIG_LABELS
    for (const [key, label] of Object.entries(CONFIG_LABELS)) {
      const value = config[key];
      if (value !== undefined && value !== null && value !== '' && value !== false) {
        configEntries.push({ key, label, value });
      }
    }
    // Special handling for statTesting (nested object)
    const statTestingStr = formatConfigValue('statTesting', config);
    if (statTestingStr) {
      configEntries.push({ key: 'statTesting', label: 'Stat Testing', value: statTestingStr });
    }
  }

  return (
    <div>
      <AppBreadcrumbs
        segments={[
          { label: 'Dashboard', href: '/dashboard' },
          { label: project.name },
        ]}
      />

      <div className="max-w-4xl mt-6">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-2xl font-bold tracking-tight mb-2">
            {project.name}
          </h1>
          <p className="text-muted-foreground text-sm">
            Created on {formatDate(project._creationTime)}
          </p>
        </div>

        {/* Status and Duration */}
        <div className="flex items-center gap-4 mb-8">
          <StatusBadge status={status} />
          {summary?.durationMs && (
            <Badge variant="outline">
              <Clock className="h-3 w-3 mr-1" />
              Duration: {formatDuration(summary.durationMs)}
            </Badge>
          )}
          {latestRun?.progress !== undefined && isActive && (
            <Badge variant="outline">
              {latestRun.progress}%
            </Badge>
          )}
        </div>

        {/* Pipeline Progress Timeline (replaces old Processing Banner) */}
        {(status === 'in_progress' || status === 'resuming' || status === 'pending_review') && (
          <Card className="mb-8">
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">Pipeline Progress</CardTitle>
                {(status === 'in_progress' || status === 'resuming') && canCancel && (
                  <Button
                    variant="outline"
                    size="sm"
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
                )}
                {status === 'pending_review' && (
                  <Button
                    size="sm"
                    onClick={() => router.push(`/projects/${encodeURIComponent(projectId)}/review`)}
                  >
                    <Play className="h-4 w-4 mr-2" />
                    Review Now
                  </Button>
                )}
              </div>
            </CardHeader>
            <CardContent>
              <PipelineTimeline
                stage={latestRun?.stage ?? undefined}
                status={status}
                message={latestRun?.message ?? undefined}
                progress={latestRun?.progress ?? undefined}
              />
            </CardContent>
          </Card>
        )}

        {/* Review Required Banner (if not showing timeline) */}
        {/* Timeline handles review state above, so this is only needed as a legacy fallback */}

        {/* Cancelled Banner */}
        {status === 'cancelled' && (
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

        {/* Error Banner */}
        {status === 'error' && (
          <Card className="mb-8 border-red-500/50 bg-red-500/5">
            <CardContent className="p-6">
              <div className="flex items-center gap-3">
                <AlertCircle className="h-5 w-5 text-red-500" />
                <div>
                  <p className="font-medium">Pipeline Error</p>
                  <p className="text-sm text-muted-foreground">
                    {latestRun?.error || 'An error occurred during processing.'}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Summary Stats */}
        {(hasOutputs || (!isActive && status !== 'cancelled' && status !== 'error')) && summary && (
          <Card className="mb-8">
            <CardHeader>
              <CardTitle className="text-lg">Summary Statistics</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="text-center p-3 bg-muted rounded-lg">
                  <Table className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{summary.tables ?? 0}</p>
                  <p className="text-xs text-muted-foreground">Tables</p>
                </div>
                <div className="text-center p-3 bg-muted rounded-lg">
                  <BarChart3 className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{summary.cuts ?? 0}</p>
                  <p className="text-xs text-muted-foreground">Cuts</p>
                </div>
                <div className="text-center p-3 bg-muted rounded-lg">
                  <Layers className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{summary.bannerGroups ?? 0}</p>
                  <p className="text-xs text-muted-foreground">Banner Groups</p>
                </div>
                <div className="text-center p-3 bg-muted rounded-lg">
                  <FileText className="h-5 w-5 mx-auto mb-1 text-primary" />
                  <p className="text-2xl font-bold">{(summary.durationMs ?? 0) > 0 ? formatDuration(summary.durationMs ?? 0) : '-'}</p>
                  <p className="text-xs text-muted-foreground">Duration</p>
                </div>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Output Files (R2-backed downloads) — crosstab Excel files only */}
        {hasR2Outputs && latestRun && (() => {
          // Dynamically detect which .xlsx files are available in R2 outputs
          const xlsxOutputs = Object.keys(r2Files?.outputs ?? {})
            .filter((path) => path.endsWith('.xlsx'))
            .sort(); // consistent ordering
          if (xlsxOutputs.length === 0) return null;

          const isSingleFile = xlsxOutputs.length === 1;

          return (
            <Card className="mb-8">
              <CardHeader>
                <CardTitle className="text-lg">Output Files</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {xlsxOutputs.map((outputPath, idx) => {
                    const filename = outputPathToFilename(outputPath);
                    const label = CROSSTAB_LABELS[outputPath] ?? filename;
                    const isPrimary = isSingleFile || idx === 0;

                    return (
                      <Card key={outputPath} className={isPrimary ? 'border-primary' : ''}>
                        <CardContent className="p-4">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                              <FileSpreadsheet className="h-5 w-5 text-green-600" />
                              <div>
                                <p className="font-medium text-sm">{label}</p>
                                <p className="text-xs text-muted-foreground">{filename}</p>
                              </div>
                            </div>
                            <a
                              href={`/api/runs/${encodeURIComponent(String(latestRun._id))}/download/${encodeURIComponent(filename)}`}
                              download={filename}
                              onClick={() => {
                                posthog.capture('file_downloaded', {
                                  project_id: projectId,
                                  run_id: String(latestRun._id),
                                  filename,
                                  is_primary: isPrimary,
                                });
                              }}
                            >
                              <Button variant={isPrimary ? 'default' : 'outline'} size="sm">
                                <Download className="h-4 w-4 mr-1" />
                                Download
                              </Button>
                            </a>
                          </div>
                        </CardContent>
                      </Card>
                    );
                  })}
                </div>
              </CardContent>
            </Card>
          );
        })()}

        {/* No outputs yet */}
        {!hasR2Outputs && (
          <Card className="mb-8">
            <CardHeader>
              <CardTitle className="text-lg">Output Files</CardTitle>
            </CardHeader>
            <CardContent>
              <p className="text-sm text-muted-foreground">
                {isActive ? 'Output files will appear here once processing completes.' : 'No output files available.'}
              </p>
            </CardContent>
          </Card>
        )}

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

        {/* Input Files — downloadable */}
        <Card className="mb-8">
          <CardHeader>
            <CardTitle className="text-lg">Input Files</CardTitle>
          </CardHeader>
          <CardContent>
            {project.intake ? (
              <div className="space-y-3">
                {(() => {
                  const intake = project.intake as Record<string, string | null>;
                  // Build list of input files with their field labels
                  const inputFiles = Object.entries(INPUT_FIELD_LABELS)
                    .map(([field, label]) => ({ field, label, filename: intake[field] }))
                    .filter((f): f is { field: string; label: string; filename: string } =>
                      typeof f.filename === 'string' && f.filename.length > 0,
                    );

                  if (inputFiles.length === 0) {
                    return <p className="text-sm text-muted-foreground">No input file information available.</p>;
                  }

                  return inputFiles.map(({ field, label, filename }) => (
                    <div key={field} className="flex items-center justify-between py-2 border-b last:border-b-0">
                      <div className="flex items-center gap-3">
                        <FileIcon filename={filename} />
                        <div>
                          <p className="text-sm font-medium">{label}</p>
                          <p className="text-xs text-muted-foreground">{filename}</p>
                        </div>
                      </div>
                      <a
                        href={`/api/projects/${encodeURIComponent(projectId)}/download/${encodeURIComponent(filename)}`}
                        download={filename}
                        onClick={() => {
                          posthog.capture('file_downloaded', {
                            project_id: projectId,
                            filename,
                            file_type: 'input',
                            input_field: field,
                          });
                        }}
                      >
                        <Button variant="outline" size="sm">
                          <Download className="h-4 w-4 mr-1" />
                          Download
                        </Button>
                      </a>
                    </div>
                  ));
                })()}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No input file information available.</p>
            )}
          </CardContent>
        </Card>

        {/* Config Summary */}
        {configEntries.length > 0 && (
          <Card className="mb-8">
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2">
                <Settings2 className="h-5 w-5 text-muted-foreground" />
                Configuration
              </CardTitle>
            </CardHeader>
            <CardContent>
              <dl className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-3 text-sm">
                {configEntries.map(({ key, label, value }) => (
                  <div key={key} className="flex justify-between sm:block">
                    <dt className="text-muted-foreground">{label}</dt>
                    <dd className="font-medium mt-0 sm:mt-0.5">
                      <ConfigValue value={value} />
                    </dd>
                  </div>
                ))}
              </dl>
            </CardContent>
          </Card>
        )}

        {/* Danger Zone (admin only) */}
        {canDelete && (
          <Card className="border-red-500/50">
            <CardHeader>
              <CardTitle className="text-lg flex items-center gap-2 text-red-500">
                <Trash2 className="h-5 w-5" />
                Danger Zone
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium">Delete this project</p>
                  <p className="text-xs text-muted-foreground">
                    Permanently removes this project, all its runs, and associated files. This action cannot be undone.
                  </p>
                </div>
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={() => setShowDeleteDialog(true)}
                >
                  Delete Project
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        <ConfirmDestructiveDialog
          open={showDeleteDialog}
          onOpenChange={setShowDeleteDialog}
          title="Delete project"
          description={`This will permanently delete "${project.name}" and all its runs and files. This action cannot be undone.`}
          confirmText={project.name}
          confirmLabel="Type the project name to confirm"
          destructiveLabel="Delete Project"
          onConfirm={handleDeleteProject}
        />
      </div>
    </div>
  );
}
