'use client';

import { useState, useEffect, use } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  ArrowLeft,
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
} from 'lucide-react';
import type { PipelineDetails, FileInfo } from '@/app/api/pipelines/[pipelineId]/route';

/**
 * Format date for display (e.g., "Monday, January 12, 2026")
 */
function formatDate(timestamp: string): string {
  const date = new Date(timestamp);
  return date.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

/**
 * Format file size for display
 */
function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

/**
 * Get file icon based on filename
 */
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

/**
 * Status badge component
 */
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
          <Loader2 className="h-3 w-3 mr-1 animate-spin" />
          Processing
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

/**
 * File card component for downloads
 */
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

export default function PipelineDetailPage({
  params,
}: {
  params: Promise<{ pipelineId: string }>;
}) {
  const { pipelineId } = use(params);
  const [details, setDetails] = useState<PipelineDetails | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

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

  if (error || !details) {
    return (
      <div className="py-12 px-4">
        <div className="max-w-4xl mx-auto">
          <div className="text-center">
            <Button variant="outline" size="sm" onClick={() => router.push('/')} className="mb-6">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Back to Home
            </Button>
            <h1 className="text-3xl font-bold tracking-tight mb-2">Pipeline Not Found</h1>
            <p className="text-muted-foreground">
              {error || 'The requested pipeline could not be found.'}
            </p>
          </div>
        </div>
      </div>
    );
  }

  // Filter files by type
  const outputFiles = details.files.filter((f) => f.type === 'output');
  const inputFiles = details.files.filter((f) => f.type === 'input');

  // Check if pipeline is still active
  const isActive = details.status === 'in_progress' || details.status === 'pending_review';
  const hasOutputs = details.outputs.tables > 0 || details.outputs.cuts > 0;

  return (
    <div className="py-12 px-4">
      <div className="max-w-4xl mx-auto">
        {/* Centered Header */}
        <div className="text-center mb-8">
          <Button variant="outline" size="sm" onClick={() => router.push('/')} className="mb-6">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Home
          </Button>
          <h1 className="text-3xl font-bold tracking-tight mb-2">
            Pipeline: {details.dataset}
          </h1>
          <p className="text-muted-foreground">
            Run on {formatDate(details.timestamp)}
          </p>
        </div>

        {/* Status and Duration - Centered */}
        <div className="flex items-center justify-center gap-4 mb-8">
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
                <Button onClick={() => router.push(details.review!.reviewUrl)}>
                  <Play className="h-4 w-4 mr-2" />
                  Review Now
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Processing Banner for in_progress */}
        {details.status === 'in_progress' && (
          <Card className="mb-8 border-blue-500/50 bg-blue-500/5">
            <CardContent className="p-6">
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

        {/* Summary Stats - only show if we have data or pipeline is complete (and not cancelled) */}
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
