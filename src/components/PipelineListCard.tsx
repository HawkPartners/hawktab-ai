'use client';

import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { CheckCircle, AlertCircle, Clock, Table, ChevronRight, Loader2, AlertTriangle, XCircle } from 'lucide-react';
import type { PipelineListItem } from '@/app/api/pipelines/route';

interface PipelineListCardProps {
  pipeline: PipelineListItem;
  onClick: (pipelineId: string) => void;
}

/**
 * Format timestamp to relative time (e.g., "2 hours ago")
 */
function formatRelativeTime(timestamp: string): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
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

/**
 * Get status icon based on pipeline status
 */
function StatusIcon({ status }: { status: string }) {
  switch (status) {
    case 'success':
      return <CheckCircle className="h-4 w-4 text-green-500" />;
    case 'partial':
      return <AlertCircle className="h-4 w-4 text-yellow-500" />;
    case 'error':
      return <AlertCircle className="h-4 w-4 text-red-500" />;
    case 'in_progress':
      return <Loader2 className="h-4 w-4 text-blue-500 animate-spin" />;
    case 'awaiting_tables':
      return <Loader2 className="h-4 w-4 text-purple-500 animate-spin" />;
    case 'pending_review':
      return <AlertTriangle className="h-4 w-4 text-yellow-500" />;
    case 'cancelled':
      return <XCircle className="h-4 w-4 text-gray-500" />;
    default:
      return <Clock className="h-4 w-4 text-muted-foreground" />;
  }
}

/**
 * Get status badge for pending_review status
 */
function StatusBadge({ status }: { status: string }) {
  if (status === 'pending_review') {
    return (
      <Badge variant="secondary" className="text-xs bg-yellow-500/20 text-yellow-700 dark:text-yellow-400">
        Review Required
      </Badge>
    );
  }
  if (status === 'in_progress') {
    return (
      <Badge variant="secondary" className="text-xs bg-blue-500/20 text-blue-700 dark:text-blue-400">
        Processing
      </Badge>
    );
  }
  if (status === 'awaiting_tables') {
    return (
      <Badge variant="secondary" className="text-xs bg-purple-500/20 text-purple-700 dark:text-purple-400">
        Completing...
      </Badge>
    );
  }
  if (status === 'cancelled') {
    return (
      <Badge variant="secondary" className="text-xs bg-gray-500/20 text-gray-700 dark:text-gray-400">
        Cancelled
      </Badge>
    );
  }
  return null;
}

export function PipelineListCard({ pipeline, onClick }: PipelineListCardProps) {
  const isActive = pipeline.status === 'in_progress' || pipeline.status === 'pending_review' || pipeline.status === 'awaiting_tables';
  const isCancelled = pipeline.status === 'cancelled';

  return (
    <Card
      className={`p-3 cursor-pointer hover:bg-muted/50 transition-colors ${
        pipeline.status === 'pending_review' ? 'border-yellow-500/50' : ''
      } ${pipeline.status === 'in_progress' ? 'border-blue-500/50' : ''} ${
        pipeline.status === 'awaiting_tables' ? 'border-purple-500/50' : ''
      } ${
        isCancelled ? 'opacity-60' : ''
      }`}
      onClick={() => onClick(pipeline.pipelineId)}
    >
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <StatusIcon status={pipeline.status} />
            <span className="font-medium text-sm truncate">
              {pipeline.dataset}
            </span>
          </div>
          <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
            <span>{formatRelativeTime(pipeline.timestamp)}</span>
            {!isActive && (
              <>
                <span className="text-muted-foreground/50">|</span>
                <span>{pipeline.duration}</span>
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
            {!isActive && !isCancelled && (
              <>
                <Badge variant="secondary" className="text-xs">
                  <Table className="h-3 w-3 mr-1" />
                  {pipeline.tables} tables
                </Badge>
                <Badge variant="outline" className="text-xs">
                  {pipeline.cuts} cuts
                </Badge>
              </>
            )}
          </div>
        </div>
        <ChevronRight className="h-4 w-4 text-muted-foreground flex-shrink-0 mt-1" />
      </div>
    </Card>
  );
}
