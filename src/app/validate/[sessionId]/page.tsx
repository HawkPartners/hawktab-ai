'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import type { ValidationSession, ColumnFeedback } from '../../../schemas/humanValidationSchema';

interface ValidationPageProps {
  params: Promise<{
    sessionId: string;
  }>;
}

interface SessionData {
  sessionId: string;
  status: {
    status: 'pending' | 'validated';
    createdAt: string;
    validatedAt?: string;
  };
  data: {
    banner: Array<{
      groupName: string;
      columns: Array<{
        name: string;
        original: string;
      }>;
    }> | null;
    dataMap: Array<{
      Column: string;
      Description: string;
      Answer_Options?: string;
    }>;
    crosstab: {
      bannerCuts: Array<{
        groupName: string;
        columns: Array<{
          name: string;
          adjusted: string;
          confidence: number;
          reason: string;
        }>;
      }>;
    };
  };
  existingValidation?: unknown;
}

export default function ValidationSession({ params }: ValidationPageProps) {
  const [sessionData, setSessionData] = useState<SessionData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'banner' | 'crosstab'>('crosstab');
  const [isSaving, setIsSaving] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const router = useRouter();

  // Validation state
  const [columnFeedback, setColumnFeedback] = useState<ColumnFeedback[]>([]);
  const [bannerNotes, setBannerNotes] = useState<string>('');
  const [crosstabNotes, setCrosstabNotes] = useState<string>('');

  useEffect(() => {
    const fetchSessionData = async () => {
      try {
        setIsLoading(true);
        setError(null);

        const { sessionId } = await params;
        const response = await fetch(`/api/validate/${sessionId}`);
        if (!response.ok) {
          if (response.status === 404) {
            throw new Error('Session not found');
          }
          throw new Error('Failed to load session data');
        }

        const data = await response.json();
        setSessionData(data);
        
        // Initialize column feedback for all columns
        if (data.data.crosstab) {
          const allColumns: ColumnFeedback[] = [];
          data.data.crosstab.bannerCuts.forEach((group: { groupName: string; columns: { name: string }[] }) => {
            group.columns.forEach((column: { name: string }) => {
              allColumns.push({
                columnName: column.name,
                groupName: group.groupName,
                adjustedFieldCorrect: true, // Default to correct
                confidenceRating: 'correct',
                reasoningQuality: 'good',
                humanEdit: '',
                notes: ''
              });
            });
          });
          setColumnFeedback(allColumns);
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error');
      } finally {
        setIsLoading(false);
      }
    };

    fetchSessionData();
  }, [params]);

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  // Update column feedback
  const updateColumnFeedback = useCallback((columnName: string, groupName: string, updates: Partial<ColumnFeedback>) => {
    setColumnFeedback(prev => 
      prev.map(item => 
        item.columnName === columnName && item.groupName === groupName 
          ? { ...item, ...updates }
          : item
      )
    );
  }, []);

  // Save validation
  const saveValidation = useCallback(async () => {
    if (!sessionData) return;

    try {
      setIsSaving(true);

      const validationData: ValidationSession = {
        sessionId: sessionData.sessionId,
        timestamp: new Date().toISOString(),
        bannerValidation: {
          original: sessionData.data.banner,
          notes: bannerNotes,
          successRate: 1.0 // TODO: Calculate based on edits
        },
        crosstabValidation: {
          original: sessionData.data.crosstab,
          columnFeedback,
          overallNotes: crosstabNotes
        }
      };

      const response = await fetch(`/api/validate/${sessionData.sessionId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(validationData),
      });

      if (!response.ok) {
        throw new Error('Failed to save validation');
      }

      alert('Validation saved successfully!');
      router.push('/validate');
    } catch (err) {
      alert(`Error saving validation: ${err instanceof Error ? err.message : 'Unknown error'}`);
    } finally {
      setIsSaving(false);
    }
  }, [sessionData, columnFeedback, bannerNotes, crosstabNotes, router]);

  // Delete session
  const deleteSession = useCallback(async () => {
    if (!sessionData) return;

    const confirmDelete = confirm(
      `Are you sure you want to delete this entire session?\n\n` +
      `Session: ${sessionData.sessionId}\n\n` +
      `This will permanently delete:\n` +
      `• All agent outputs (banner, crosstab, data map)\n` +
      `• Any saved validation results\n` +
      `• The entire session folder\n\n` +
      `This action cannot be undone!`
    );

    if (!confirmDelete) return;

    try {
      setIsDeleting(true);

      const response = await fetch(`/api/delete-session/${sessionData.sessionId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to delete session');
      }

      alert('Session deleted successfully!');
      router.push('/validate');
    } catch (err) {
      alert(`Error deleting session: ${err instanceof Error ? err.message : 'Unknown error'}`);
    } finally {
      setIsDeleting(false);
    }
  }, [sessionData, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="text-center py-12">
            <div className="text-gray-600 dark:text-gray-400">Loading validation session...</div>
          </div>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="bg-red-100 dark:bg-red-900 border border-red-400 text-red-700 dark:text-red-300 px-4 py-3 rounded">
            Error: {error}
          </div>
          <div className="mt-4">
            <button
              onClick={() => router.push('/validate')}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
            >
              Back to Queue
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!sessionData) return null;

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex justify-between items-center mb-6">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-2">
              Validation Session: {sessionData.sessionId}
            </h1>
            <div className="text-sm text-gray-600 dark:text-gray-400">
              Created: {formatDate(sessionData.status.createdAt)}
              {sessionData.status.validatedAt && (
                <span className="ml-4">Validated: {formatDate(sessionData.status.validatedAt)}</span>
              )}
              <span className={`ml-4 px-2 py-1 rounded text-xs font-medium ${
                sessionData.status.status === 'pending'
                  ? 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300'
                  : 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
              }`}>
                {sessionData.status.status}
              </span>
            </div>
          </div>
          
          <div className="flex space-x-3">
            <button
              disabled={isDeleting}
              onClick={deleteSession}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                isDeleting
                  ? 'bg-gray-400 cursor-not-allowed text-white'
                  : 'bg-red-600 hover:bg-red-700 text-white'
              }`}
            >
              {isDeleting ? 'Deleting...' : '🗑️ Delete Session'}
            </button>
            
            <button
              onClick={() => router.push('/validate')}
              className="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium transition-colors"
            >
              Back to Queue
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="bg-white dark:bg-gray-800 rounded-t-lg">
          <div className="border-b border-gray-200 dark:border-gray-700">
            <nav className="-mb-px flex space-x-8 px-6">
              <button
                onClick={() => setActiveTab('crosstab')}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'crosstab'
                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                }`}
              >
                Crosstab Validation
                {sessionData.data.crosstab && (
                  <span className="ml-2 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 py-1 px-2 rounded-full text-xs">
                    {sessionData.data.crosstab.bannerCuts.reduce((total, group) => total + group.columns.length, 0)} columns
                  </span>
                )}
              </button>
              
              <button
                onClick={() => setActiveTab('banner')}
                className={`py-4 px-1 border-b-2 font-medium text-sm ${
                  activeTab === 'banner'
                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                }`}
              >
                Banner Validation
                {sessionData.data.banner && (
                  <span className="ml-2 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 py-1 px-2 rounded-full text-xs">
                    {sessionData.data.banner.length} groups
                  </span>
                )}
              </button>
            </nav>
          </div>
        </div>

        {/* Tab Content */}
        <div className="bg-white dark:bg-gray-800 rounded-b-lg p-6">
          {activeTab === 'crosstab' && sessionData.data.crosstab && (
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Data Map Panel */}
              <div className="lg:col-span-1">
                <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
                  Data Map Reference
                  <span className="text-sm font-normal text-gray-500 dark:text-gray-400 ml-2">
                    ({sessionData.data.dataMap?.length || 0} variables)
                  </span>
                </h3>
                <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 max-h-96 overflow-y-auto">
                  <div className="space-y-2">
                    {sessionData.data.dataMap?.map((item, index) => (
                      <div key={index} className="text-sm border-b border-gray-200 dark:border-gray-600 pb-2 last:border-b-0">
                        <div className="font-mono font-medium text-blue-600 dark:text-blue-400">
                          {item.Column}
                        </div>
                        <div className="text-gray-600 dark:text-gray-300 ml-4">
                          {item.Description}
                        </div>
                        {item.Answer_Options && (
                          <div className="text-gray-500 dark:text-gray-400 ml-4 text-xs">
                            {item.Answer_Options}
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Crosstab Validation Panel */}
              <div className="lg:col-span-1">
                <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
                  Agent Output Validation
                </h3>
                <div className="space-y-4 max-h-96 overflow-y-auto">
                  {sessionData.data.crosstab.bannerCuts.map((group, groupIndex) => (
                    <div key={groupIndex} className="border border-gray-200 dark:border-gray-600 rounded-lg p-4">
                      <h4 className="font-medium text-gray-900 dark:text-gray-100 mb-3">
                        Group: {group.groupName}
                      </h4>
                      <div className="space-y-4">
                        {group.columns.map((column, colIndex) => {
                          const feedback = columnFeedback.find(
                            f => f.columnName === column.name && f.groupName === group.groupName
                          );
                          
                          return (
                            <div key={colIndex} className="bg-gray-50 dark:bg-gray-700 rounded p-4">
                              <div className="font-medium text-gray-900 dark:text-gray-100 mb-2">
                                {column.name}
                              </div>
                              
                              {/* Agent's Output */}
                              <div className="text-sm space-y-1 mb-3 p-2 bg-gray-100 dark:bg-gray-600 rounded">
                                <div className="text-gray-600 dark:text-gray-300">
                                  <span className="font-medium">Adjusted:</span> 
                                  <code className="ml-2 bg-gray-200 dark:bg-gray-500 px-1 rounded text-xs">
                                    {column.adjusted}
                                  </code>
                                </div>
                                <div className="text-gray-600 dark:text-gray-300">
                                  <span className="font-medium">Confidence:</span>
                                  <span className={`ml-2 px-2 py-1 rounded-full text-xs ${
                                    column.confidence >= 0.8 
                                      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                                      : column.confidence >= 0.5 
                                        ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
                                        : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
                                  }`}>
                                    {(column.confidence * 100).toFixed(0)}%
                                  </span>
                                </div>
                                <div className="text-gray-600 dark:text-gray-300 text-xs">
                                  <span className="font-medium">Reason:</span> {column.reason}
                                </div>
                              </div>

                              {/* Validation Controls */}
                              {feedback && (
                                <div className="space-y-3 border-t pt-3">
                                  {/* Correct/Incorrect */}
                                  <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                      Mapping Correct?
                                    </label>
                                    <div className="flex space-x-4">
                                      <label className="flex items-center">
                                        <input
                                          type="radio"
                                          checked={feedback.adjustedFieldCorrect}
                                          onChange={() => updateColumnFeedback(column.name, group.groupName, { adjustedFieldCorrect: true })}
                                          className="mr-2"
                                        />
                                        ✅ Correct
                                      </label>
                                      <label className="flex items-center">
                                        <input
                                          type="radio"
                                          checked={!feedback.adjustedFieldCorrect}
                                          onChange={() => updateColumnFeedback(column.name, group.groupName, { adjustedFieldCorrect: false })}
                                          className="mr-2"
                                        />
                                        ❌ Incorrect
                                      </label>
                                    </div>
                                  </div>

                                  {/* Confidence Rating */}
                                  <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                      Agent&apos;s Confidence Rating
                                    </label>
                                    <select
                                      value={feedback.confidenceRating}
                                      onChange={(e) => updateColumnFeedback(column.name, group.groupName, { confidenceRating: e.target.value as 'too_high' | 'correct' | 'too_low' })}
                                      className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 text-sm"
                                    >
                                      <option value="too_high">Too High</option>
                                      <option value="correct">Correct</option>
                                      <option value="too_low">Too Low</option>
                                    </select>
                                  </div>

                                  {/* Reasoning Quality */}
                                  <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                      Reasoning Quality
                                    </label>
                                    <select
                                      value={feedback.reasoningQuality}
                                      onChange={(e) => updateColumnFeedback(column.name, group.groupName, { reasoningQuality: e.target.value as 'poor' | 'good' | 'excellent' })}
                                      className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 text-sm"
                                    >
                                      <option value="poor">Poor</option>
                                      <option value="good">Good</option>
                                      <option value="excellent">Excellent</option>
                                    </select>
                                  </div>

                                  {/* Human Edit */}
                                  <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                      Corrected R Syntax (if needed)
                                    </label>
                                    <input
                                      type="text"
                                      value={feedback.humanEdit || ''}
                                      onChange={(e) => updateColumnFeedback(column.name, group.groupName, { humanEdit: e.target.value })}
                                      placeholder="Enter corrected R syntax..."
                                      className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 text-sm font-mono"
                                    />
                                  </div>

                                  {/* Notes */}
                                  <div>
                                    <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                      Notes
                                    </label>
                                    <textarea
                                      value={feedback.notes || ''}
                                      onChange={(e) => updateColumnFeedback(column.name, group.groupName, { notes: e.target.value })}
                                      placeholder="Add notes about this mapping..."
                                      rows={2}
                                      className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 text-sm"
                                    />
                                  </div>
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  ))}
                </div>

                {/* Overall Crosstab Notes */}
                <div className="mt-4">
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Overall Crosstab Validation Notes
                  </label>
                  <textarea
                    value={crosstabNotes}
                    onChange={(e) => setCrosstabNotes(e.target.value)}
                    placeholder="Add overall notes about the crosstab validation..."
                    rows={3}
                    className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 text-sm"
                  />
                </div>
              </div>
            </div>
          )}

          {activeTab === 'banner' && sessionData.data.banner && (
            <div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
                Banner Agent Output
              </h3>
              <div className="space-y-4">
                {sessionData.data.banner.map((group, groupIndex) => (
                  <div key={groupIndex} className="border border-gray-200 dark:border-gray-600 rounded-lg p-4">
                    <h4 className="font-medium text-gray-900 dark:text-gray-100 mb-3">
                      Group: {group.groupName}
                    </h4>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      {group.columns.map((column, colIndex) => (
                        <div key={colIndex} className="bg-gray-50 dark:bg-gray-700 rounded p-3">
                          <div className="font-medium text-gray-900 dark:text-gray-100 mb-1">
                            {column.name}
                          </div>
                          <div className="text-sm text-gray-600 dark:text-gray-300">
                            <code className="bg-gray-200 dark:bg-gray-600 px-1 rounded text-xs">
                              {column.original}
                            </code>
                          </div>
                          <div className="mt-2 text-xs text-gray-500 dark:text-gray-400">
                            ✓ Banner extraction looks correct
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>

              {/* Banner Notes */}
              <div className="mt-6">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Banner Validation Notes
                </label>
                <textarea
                  value={bannerNotes}
                  onChange={(e) => setBannerNotes(e.target.value)}
                  placeholder="Add notes about the banner extraction quality, group organization, or any issues found..."
                  rows={4}
                  className="w-full p-2 border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 text-sm"
                />
              </div>
            </div>
          )}

          {/* Validation Actions */}
          <div className="mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
            <div className="mb-4 p-4 bg-blue-50 dark:bg-blue-900 rounded-lg">
              <h4 className="font-medium text-blue-900 dark:text-blue-100 mb-2">
                💾 Save Validation Session
              </h4>
              <p className="text-sm text-blue-700 dark:text-blue-300">
                This will save your validation for <strong>both Banner and Crosstab tabs</strong> as one complete validation session. 
                All feedback, ratings, edits, and notes will be preserved.
              </p>
            </div>
            
            <div className="flex space-x-4">
              <button
                disabled={isSaving}
                onClick={saveValidation}
                className={`px-6 py-2 rounded-lg font-medium transition-colors ${
                  isSaving
                    ? 'bg-gray-400 cursor-not-allowed text-white'
                    : 'bg-green-600 hover:bg-green-700 text-white'
                }`}
              >
                {isSaving ? 'Saving...' : 'Save Complete Validation'}
              </button>
              
              <button
                className="px-6 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded-lg font-medium transition-colors"
                onClick={() => router.push('/validate')}
              >
                Back to Queue
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}