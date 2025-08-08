'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { toast } from 'sonner';
import { Trash2, Eye, Clock, Upload } from 'lucide-react';
import { formatUtcDateTime } from '@/lib/utils';
import { StatusBadge } from '@/components/StatusBadge';

interface SessionSummary {
  sessionId: string;
  status: 'pending' | 'validated';
  createdAt: string;
  validatedAt?: string;
  files: {
    banner: boolean;
    dataMap: boolean;
    crosstab: boolean;
  };
  columnCount?: number;
  groupCount?: number;
}

interface ValidationQueueData {
  sessions: SessionSummary[];
  counts: {
    total: number;
    pending: number;
    validated: number;
  };
}

export default function ValidationQueue() {
  const [data, setData] = useState<ValidationQueueData | null>(null);
  const [filter, setFilter] = useState<'all' | 'pending' | 'validated'>('all');
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deletingSession, setDeletingSession] = useState<string | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [targetSessionId, setTargetSessionId] = useState<string | null>(null);
  const router = useRouter();

  const fetchSessions = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);

      const url = filter === 'all' 
        ? '/api/validation-queue' 
        : '/api/validation-queue';
        
      const response = await fetch(url, {
        method: filter === 'all' ? 'GET' : 'POST',
        headers: filter !== 'all' ? { 'Content-Type': 'application/json' } : {},
        body: filter !== 'all' ? JSON.stringify({ status: filter }) : undefined,
      });

      if (!response.ok) {
        throw new Error('Failed to fetch validation queue');
      }

      const result = await response.json();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setIsLoading(false);
    }
  }, [filter]);

  useEffect(() => {
    fetchSessions();
  }, [filter, fetchSessions]);

  const formatDate = (dateString: string) => formatUtcDateTime(dateString);

  const filteredSessions = data?.sessions.filter(session => {
    if (filter === 'all') return true;
    return session.status === filter;
  }) || [];

  // Delete session function
  const deleteSession = async (sessionId: string) => {
    try {
      setDeletingSession(sessionId);

      const response = await fetch(`/api/delete-session/${sessionId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to delete session');
      }

      // Refresh the list
      await fetchSessions();
      toast.success('Session deleted successfully!');
    } catch (err) {
      toast.error('Failed to delete session', {
        description: err instanceof Error ? err.message : 'Unknown error'
      });
    } finally {
      setDeletingSession(null);
      setDeleteDialogOpen(false);
      setTargetSessionId(null);
    }
  };

  return (
    <div className="py-8 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold">
              Validation Queue
            </h1>
            <p className="text-muted-foreground mt-2">
              Review and validate agent outputs from processing sessions
            </p>
          </div>
          
          <Button onClick={() => router.push('/')}>
            <Upload className="w-4 h-4 mr-2" />
            Back to Upload
          </Button>
        </div>

        {/* Stats and Filters */}
        <Card className="mb-6">
          <CardContent className="pt-6">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
              {/* Stats */}
              <div className="flex space-x-6 mb-4 sm:mb-0">
              <div className="text-center">
                <div className="text-2xl font-bold">
                  {data?.counts.total || 0}
                </div>
                <div className="text-sm text-muted-foreground">Total</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold">
                  {data?.counts.pending || 0}
                </div>
                <div className="text-sm text-muted-foreground">Pending</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold">
                  {data?.counts.validated || 0}
                </div>
                <div className="text-sm text-muted-foreground">Validated</div>
              </div>
            </div>

            {/* Filters as segmented control */}
            <Tabs value={filter} onValueChange={(v) => setFilter(v as 'all' | 'pending' | 'validated')}>
              <TabsList>
                <TabsTrigger value="all">
                  All {typeof data?.counts.total === 'number' ? `(${data.counts.total})` : ''}
                </TabsTrigger>
                <TabsTrigger value="pending">
                  Pending {typeof data?.counts.pending === 'number' ? `(${data.counts.pending})` : ''}
                </TabsTrigger>
                <TabsTrigger value="validated">
                  Validated {typeof data?.counts.validated === 'number' ? `(${data.counts.validated})` : ''}
                </TabsTrigger>
              </TabsList>
            </Tabs>
            </div>
          </CardContent>
        </Card>

        {/* Loading */}
        {isLoading && (
          <div className="text-center py-12">
            <div className="text-muted-foreground">Loading validation queue...</div>
          </div>
        )}

        {/* Error */}
        {error && (
          <div className="bg-destructive/10 border border-destructive text-destructive px-4 py-3 rounded mb-6">
            Error: {error}
          </div>
        )}

        {/* Sessions List */}
        {!isLoading && !error && (
          <div className="space-y-4">
            {filteredSessions.length === 0 ? (
              <Card>
                <CardContent className="text-center py-12">
                  <div className="text-muted-foreground mb-4">
                    {filter === 'all' 
                      ? 'No sessions found. Process some files to see validation items here.'
                      : `No ${filter} sessions found.`
                    }
                  </div>
                  {filter === 'all' && (
                    <Button onClick={() => router.push('/')}>
                      <Upload className="w-4 h-4 mr-2" />
                      Upload Files
                    </Button>
                  )}
                </CardContent>
              </Card>
            ) : (
              filteredSessions.map((session) => (
                <Card key={session.sessionId} className="hover:shadow-md transition-shadow">
                  <CardContent className="pt-6">
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <h3 className="font-medium">
                          {session.sessionId}
                        </h3>
                        <StatusBadge status={session.status} />
                      </div>
                      
                      <div className="text-sm text-muted-foreground mb-2">
                        Created: {formatDate(session.createdAt)}
                        {session.validatedAt && (
                          <span className="ml-4">Validated: {formatDate(session.validatedAt)}</span>
                        )}
                      </div>
                      
                      <div className="flex items-center space-x-4 text-sm text-muted-foreground">
                        <span>{session.groupCount || 0} groups</span>
                        <span>{session.columnCount || 0} columns</span>
                        <div className="flex items-center space-x-2">
                          <span>Files:</span>
                          <span>
                            Banner
                          </span>
                          <span>
                            DataMap
                          </span>
                          <span>
                            Crosstab
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex space-x-2">
                      {session.status === 'pending' && (
                        <Button
                          onClick={() => router.push(`/validate/${session.sessionId}`)}
                          variant="secondary"
                        >
                          <Clock className="w-4 h-4 mr-2" />
                          Validate
                        </Button>
                      )}
                      
                      {session.status === 'validated' && (
                        <Button
                          onClick={() => router.push(`/validate/${session.sessionId}`)}
                          variant="outline"
                        >
                          <Eye className="w-4 h-4 mr-2" />
                          View Results
                        </Button>
                      )}
                      
                      <Button
                        disabled={deletingSession === session.sessionId}
                        onClick={() => {
                          setTargetSessionId(session.sessionId);
                          setDeleteDialogOpen(true);
                        }}
                        variant="destructive"
                        size="sm"
                        title="Delete entire session folder"
                      >
                        <Trash2 className="w-4 h-4" />
                        {deletingSession === session.sessionId && '...'}
                      </Button>
                    </div>
                  </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        )}
      </div>
      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete session?</DialogTitle>
          </DialogHeader>
          <div className="text-sm text-muted-foreground">
            This will permanently delete all files for session
            {targetSessionId ? ` "${targetSessionId}"` : ''}. This action cannot be undone.
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
            <Button
              variant="destructive"
              onClick={() => targetSessionId && deleteSession(targetSessionId)}
              disabled={!targetSessionId || deletingSession === targetSessionId}
            >
              {deletingSession === targetSessionId ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}