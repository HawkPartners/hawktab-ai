'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { CheckCircle, AlertCircle, Clock, Table, ChevronRight, Loader2, AlertTriangle, XCircle } from 'lucide-react';

/**
 * Shape for project list items backed by Convex data.
 * Replaces the old PipelineListItem that came from filesystem scanning.
 */
export interface ProjectListItem {
  projectId: string;
  name: string;
  createdAt: number;       // Unix ms (_creationTime)
  latestRunId?: string;
  status: string;
  tables?: number;
  cuts?: number;
  durationMs?: number;
  hasFeedback?: boolean;
}

interface PipelineListCardProps {
  pipeline: ProjectListItem;
  onClick: (projectId: string) => void;
}

function formatRelativeTime(timestampMs: number): string {
  const now = Date.now();
  const diffMs = now - timestampMs;
  const diffSeconds = Math.floor(diffMs / 1000);
  const diffMinutes = Math.floor(diffSeconds / 60);
  const diffHours = Math.floor(diffMinutes / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffDays > 0) {
    return diffDays === 1 ? '1 day ago' : `${diffDays} days ago`;
  }
  if (diffHours > 0) {
    return diffHours === 1 ? '1 hour ago' : `${diffHours} hours ago`;
  }
  if (diffMinutes > 0) {
    return diffMinutes === 1 ? '1 minute ago' : `${diffMinutes} minutes ago`;
  }
  return 'Just now';
}

function formatDurationMs(ms: number): string {
  const seconds = Math.floor(ms / 1000);
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const remainingSecs = seconds % 60;
  return `${minutes}m ${remainingSecs}s`;
}

function StatusIcon({ status }: { status: string }) {
  switch (status) {
    case 'success':
      return <CheckCircle className="h-4 w-4 text-ct-emerald" />;
    case 'partial':
      return <AlertCircle className="h-4 w-4 text-ct-amber" />;
    case 'error':
      return <AlertCircle className="h-4 w-4 text-ct-red" />;
    case 'in_progress':
    case 'resuming':
      return <Loader2 className="h-4 w-4 text-ct-blue animate-spin" />;
    case 'pending_review':
      return <AlertTriangle className="h-4 w-4 text-ct-amber" />;
    case 'cancelled':
      return <XCircle className="h-4 w-4 text-muted-foreground" />;
    default:
      return <Clock className="h-4 w-4 text-muted-foreground" />;
  }
}

function StatusBadge({ status }: { status: string }) {
  if (status === 'pending_review') {
    return (
      <Badge variant="secondary" className="text-xs bg-ct-amber-dim text-ct-amber">
        Review Required
      </Badge>
    );
  }
  if (status === 'in_progress' || status === 'resuming') {
    return (
      <Badge variant="secondary" className="text-xs bg-ct-blue-dim text-ct-blue">
        Processing
      </Badge>
    );
  }
  if (status === 'cancelled') {
    return (
      <Badge variant="secondary" className="text-xs">
        Cancelled
      </Badge>
    );
  }
  return null;
}

export function PipelineListCard({ pipeline, onClick }: PipelineListCardProps) {
  const isActive = pipeline.status === 'in_progress' || pipeline.status === 'pending_review' || pipeline.status === 'resuming';
  const isCancelled = pipeline.status === 'cancelled';

  return (
    <Card
      className={`p-3 cursor-pointer hover:bg-muted/50 transition-colors ${
        pipeline.status === 'pending_review' ? 'border-yellow-500/50' : ''
      } ${pipeline.status === 'in_progress' || pipeline.status === 'resuming' ? 'border-blue-500/50' : ''} ${
        isCancelled ? 'opacity-60' : ''
      }`}
      onClick={() => onClick(pipeline.projectId)}
    >
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <StatusIcon status={pipeline.status} />
            <span className="font-medium text-sm truncate">
              {pipeline.name}
            </span>
          </div>
          <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
            <span>{formatRelativeTime(pipeline.createdAt)}</span>
            {!isActive && pipeline.durationMs && (
              <>
                <span className="text-muted-foreground/50">|</span>
                <span>{formatDurationMs(pipeline.durationMs)}</span>
              </>
            )}
          </div>
          <div className="flex items-center gap-2 mt-2 flex-wrap">
            <StatusBadge status={pipeline.status} />
            {pipeline.hasFeedback && (
              <Badge variant="outline" className="text-xs">
                Feedback
              </Badge>
            )}
            {!isActive && !isCancelled && pipeline.tables !== undefined && (
              <>
                <Badge variant="secondary" className="text-xs">
                  <Table className="h-3 w-3 mr-1" />
                  {pipeline.tables} tables
                </Badge>
                {pipeline.cuts !== undefined && (
                  <Badge variant="outline" className="text-xs">
                    {pipeline.cuts} cuts
                  </Badge>
                )}
              </>
            )}
          </div>
        </div>
        <ChevronRight className="h-4 w-4 text-muted-foreground flex-shrink-0 mt-1" />
      </div>
    </Card>
  );
}
