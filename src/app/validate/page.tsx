'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import { toast } from 'sonner';
import { Trash2, Eye, Clock, CheckCircle, Upload } from 'lucide-react';

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

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  const filteredSessions = data?.sessions.filter(session => {
    if (filter === 'all') return true;
    return session.status === filter;
  }) || [];

  // Delete session function
  const deleteSession = async (sessionId: string) => {
    const confirmDelete = confirm(
      `Are you sure you want to delete session "${sessionId}"?\n\n` +
      `This will permanently delete all files in this session folder.\n` +
      `This action cannot be undone!`
    );

    if (!confirmDelete) return;

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
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100">
              Validation Queue
            </h1>
            <p className="text-gray-600 dark:text-gray-400 mt-2">
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
                <div className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                  {data?.counts.total || 0}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">Total</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-orange-600">
                  {data?.counts.pending || 0}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">Pending</div>
              </div>
              <div className="text-center">
                <div className="text-2xl font-bold text-green-600">
                  {data?.counts.validated || 0}
                </div>
                <div className="text-sm text-gray-600 dark:text-gray-400">Validated</div>
              </div>
            </div>

            {/* Filter Buttons */}
            <div className="flex space-x-2">
              {(['all', 'pending', 'validated'] as const).map((filterOption) => (
                <Button
                  key={filterOption}
                  onClick={() => setFilter(filterOption)}
                  variant={filter === filterOption ? "default" : "outline"}
                  size="sm"
                >
                  {filterOption.charAt(0).toUpperCase() + filterOption.slice(1)}
                </Button>
              ))}
            </div>
            </div>
          </CardContent>
        </Card>

        {/* Loading */}
        {isLoading && (
          <div className="text-center py-12">
            <div className="text-gray-600 dark:text-gray-400">Loading validation queue...</div>
          </div>
        )}

        {/* Error */}
        {error && (
          <div className="bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded mb-6">
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
                        <h3 className="font-medium text-gray-900 dark:text-gray-100">
                          {session.sessionId}
                        </h3>
                        <Badge variant={session.status === 'pending' ? 'secondary' : 'default'}>
                          {session.status === 'pending' ? (
                            <><Clock className="w-3 h-3 mr-1" />{session.status}</>
                          ) : (
                            <><CheckCircle className="w-3 h-3 mr-1" />{session.status}</>
                          )}
                        </Badge>
                      </div>
                      
                      <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
                        Created: {formatDate(session.createdAt)}
                        {session.validatedAt && (
                          <span className="ml-4">Validated: {formatDate(session.validatedAt)}</span>
                        )}
                      </div>
                      
                      <div className="flex items-center space-x-4 text-sm text-gray-500">
                        <span>{session.groupCount || 0} groups</span>
                        <span>{session.columnCount || 0} columns</span>
                        <div className="flex items-center space-x-2">
                          <span>Files:</span>
                          <span className={session.files.banner ? 'text-green-600' : 'text-red-600'}>
                            Banner
                          </span>
                          <span className={session.files.dataMap ? 'text-green-600' : 'text-red-600'}>
                            DataMap
                          </span>
                          <span className={session.files.crosstab ? 'text-green-600' : 'text-red-600'}>
                            Crosstab
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex space-x-2">
                      {session.status === 'pending' && (
                        <Button
                          onClick={() => router.push(`/validate/${session.sessionId}`)}
                          className="bg-orange-600 hover:bg-orange-700"
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
                        onClick={() => deleteSession(session.sessionId)}
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
    </div>
  );
}