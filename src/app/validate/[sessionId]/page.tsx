'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import type { ValidationSession, ColumnFeedback } from '../../../schemas/humanValidationSchema';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { RadioGroup, RadioGroupItem } from '@/components/ui/radio-group';
import { Label } from '@/components/ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { 
  ArrowLeft, 
  Trash2, 
  CheckCircle, 
  Clock, 
  Eye, 
  FileText, 
  BarChart3,
  AlertCircle,
  ThumbsUp,
  ThumbsDown
} from 'lucide-react';

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
                adjustedFieldCorrect: false, // Default to needs review
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

      toast.success('Validation saved successfully!');
      router.push('/validate');
    } catch (err) {
      toast.error('Failed to save validation', {
        description: err instanceof Error ? err.message : 'Unknown error'
      });
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

      toast.success('Session deleted successfully!');
      router.push('/validate');
    } catch (err) {
      toast.error('Failed to delete session', {
        description: err instanceof Error ? err.message : 'Unknown error'
      });
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
      <div className="min-h-screen bg-background py-8 px-4">
        <div className="max-w-6xl mx-auto">
          <Card className="border-destructive">
            <CardHeader>
              <CardTitle className="flex items-center text-destructive">
                <AlertCircle className="w-5 h-5 mr-2" />
                Error Loading Session
              </CardTitle>
              <CardDescription>{error}</CardDescription>
            </CardHeader>
            <CardContent>
              <Button onClick={() => router.push('/validate')}>
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back to Queue
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  if (!sessionData) return null;

  return (
    <div className="min-h-screen bg-background py-8 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <Card className="mb-6">
          <CardHeader>
            <div className="flex justify-between items-start">
              <div>
                <CardTitle className="text-2xl mb-2">
                  Validation Session: {sessionData.sessionId}
                </CardTitle>
                <CardDescription className="flex items-center gap-4">
                  <span>Created: {formatDate(sessionData.status.createdAt)}</span>
                  {sessionData.status.validatedAt && (
                    <span>Validated: {formatDate(sessionData.status.validatedAt)}</span>
                  )}
                  <Badge variant="outline">
                    {sessionData.status.status === 'pending' ? (
                      <><Clock className="w-3 h-3 mr-1" />{sessionData.status.status}</>
                    ) : (
                      <><CheckCircle className="w-3 h-3 mr-1" />{sessionData.status.status}</>
                    )}
                  </Badge>
                </CardDescription>
              </div>
              
              <div className="flex space-x-2">
                <Button
                  disabled={isDeleting}
                  onClick={deleteSession}
                  variant="destructive"
                >
                  <Trash2 className="w-4 h-4 mr-2" />
                  {isDeleting ? 'Deleting...' : 'Delete Session'}
                </Button>
                
                <Button
                  onClick={() => router.push('/validate')}
                  variant="outline"
                >
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back to Queue
                </Button>
              </div>
            </div>
          </CardHeader>
        </Card>

        {/* Tab Navigation */}
        <Tabs value={activeTab} onValueChange={(value) => setActiveTab(value as 'banner' | 'crosstab')} className="w-full">
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="crosstab" className="flex items-center gap-2">
              <BarChart3 className="w-4 h-4" />
              Crosstab Validation
              {sessionData.data.crosstab && (
                <Badge variant="outline" className="ml-2">
                  {sessionData.data.crosstab.bannerCuts.reduce((total, group) => total + group.columns.length, 0)} columns
                </Badge>
              )}
            </TabsTrigger>
            <TabsTrigger value="banner" className="flex items-center gap-2">
              <FileText className="w-4 h-4" />
              Banner Validation
              {sessionData.data.banner && (
                <Badge variant="outline" className="ml-2">
                  {sessionData.data.banner.length} groups
                </Badge>
              )}
            </TabsTrigger>
          </TabsList>

          <TabsContent value="crosstab" className="mt-6">
            {sessionData.data.crosstab && (
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Data Map Panel */}
                <Card className="lg:col-span-1">
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <FileText className="w-5 h-5" />
                      Data Map Reference
                    </CardTitle>
                    <CardDescription>
                      {sessionData.data.dataMap?.length || 0} variables available
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="max-h-96 overflow-y-auto">
                      <Table>
                        <TableHeader>
                          <TableRow>
                            <TableHead>Variable</TableHead>
                            <TableHead>Description</TableHead>
                            <TableHead>Options</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {sessionData.data.dataMap?.map((item, index) => (
                            <TableRow key={index}>
                              <TableCell>
                                <code className="bg-muted px-2 py-1 rounded text-sm font-mono text-primary">
                                  {item.Column}
                                </code>
                              </TableCell>
                              <TableCell className="text-sm">
                                {item.Description}
                              </TableCell>
                              <TableCell className="text-xs text-muted-foreground">
                                {item.Answer_Options || '-'}
                              </TableCell>
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </div>
                  </CardContent>
                </Card>

                {/* Crosstab Validation Panel */}
                <Card className="lg:col-span-1">
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <BarChart3 className="w-5 h-5" />
                      Agent Output Validation
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4 max-h-96 overflow-y-auto">
                      {sessionData.data.crosstab.bannerCuts.map((group, groupIndex) => (
                        <Card key={groupIndex}>
                          <CardHeader className="pb-3">
                            <CardTitle className="text-base">
                              Group: {group.groupName}
                            </CardTitle>
                          </CardHeader>
                          <CardContent>
                            <div className="space-y-4">
                        {group.columns.map((column, colIndex) => {
                          const feedback = columnFeedback.find(
                            f => f.columnName === column.name && f.groupName === group.groupName
                          );
                          
                          return (
                            <Card key={colIndex} className="bg-muted/30">
                              <CardHeader className="pb-3">
                                <CardTitle className="text-base">{column.name}</CardTitle>
                              </CardHeader>
                              <CardContent className="space-y-4">
                                {/* Agent Output */}
                                <div className="bg-muted p-3 rounded-lg space-y-2">
                                  <div className="flex items-center justify-between">
                                    <span className="text-sm font-medium">Adjusted:</span>
                                    <code className="bg-background px-2 py-1 rounded text-xs font-mono text-primary">
                                      {column.adjusted}
                                    </code>
                                  </div>
                                  <div className="flex items-center justify-between">
                                    <span className="text-sm font-medium">Confidence:</span>
                                    <Badge variant="outline" className={
                                      column.confidence >= 0.8 
                                        ? 'border-green-500 text-green-700'
                                        : column.confidence >= 0.5 
                                          ? 'border-amber-500 text-amber-700'
                                          : 'border-red-500 text-red-700'
                                    }>
                                      {(column.confidence * 100).toFixed(0)}%
                                    </Badge>
                                  </div>
                                  <div>
                                    <span className="text-sm font-medium">Reason:</span>
                                    <p className="text-xs text-muted-foreground mt-1">{column.reason}</p>
                                  </div>
                                </div>

                                {/* Validation Controls */}
                                {feedback && (
                                  <div className="space-y-4 pt-3">
                                    <Separator />
                                    {/* Correct/Incorrect */}
                                    <div className="space-y-2">
                                      <Label className="text-sm font-medium">Mapping Correct?</Label>
                                      <RadioGroup
                                        value={feedback.adjustedFieldCorrect ? "correct" : "incorrect"}
                                        onValueChange={(value) => 
                                          updateColumnFeedback(column.name, group.groupName, { 
                                            adjustedFieldCorrect: value === "correct" 
                                          })
                                        }
                                      >
                                        <div className="flex items-center space-x-2">
                                          <RadioGroupItem value="correct" id={`${group.groupName}-${column.name}-correct`} />
                                          <Label htmlFor={`${group.groupName}-${column.name}-correct`} className="flex items-center gap-1">
                                            <ThumbsUp className="w-4 h-4 text-muted-foreground" />
                                            Correct
                                          </Label>
                                        </div>
                                        <div className="flex items-center space-x-2">
                                          <RadioGroupItem value="incorrect" id={`${group.groupName}-${column.name}-incorrect`} />
                                          <Label htmlFor={`${group.groupName}-${column.name}-incorrect`} className="flex items-center gap-1">
                                            <ThumbsDown className="w-4 h-4 text-muted-foreground" />
                                            Incorrect
                                          </Label>
                                        </div>
                                      </RadioGroup>
                                    </div>

                                    {/* Confidence Rating */}
                                    <div className="space-y-2">
                                      <Label className="text-sm font-medium">Agent&apos;s Confidence Rating</Label>
                                      <Select
                                        value={feedback.confidenceRating}
                                        onValueChange={(value: 'too_high' | 'correct' | 'too_low') =>
                                          updateColumnFeedback(column.name, group.groupName, { confidenceRating: value })
                                        }
                                      >
                                        <SelectTrigger>
                                          <SelectValue placeholder="Rate confidence" />
                                        </SelectTrigger>
                                        <SelectContent>
                                          <SelectItem value="too_high">Too High</SelectItem>
                                          <SelectItem value="correct">Correct</SelectItem>
                                          <SelectItem value="too_low">Too Low</SelectItem>
                                        </SelectContent>
                                      </Select>
                                    </div>

                                    {/* Reasoning Quality */}
                                    <div className="space-y-2">
                                      <Label className="text-sm font-medium">Reasoning Quality</Label>
                                      <Select
                                        value={feedback.reasoningQuality}
                                        onValueChange={(value: 'poor' | 'good' | 'excellent') =>
                                          updateColumnFeedback(column.name, group.groupName, { reasoningQuality: value })
                                        }
                                      >
                                        <SelectTrigger>
                                          <SelectValue placeholder="Rate reasoning" />
                                        </SelectTrigger>
                                        <SelectContent>
                                          <SelectItem value="poor">Poor</SelectItem>
                                          <SelectItem value="good">Good</SelectItem>
                                          <SelectItem value="excellent">Excellent</SelectItem>
                                        </SelectContent>
                                      </Select>
                                    </div>

                                    {/* Human Edit */}
                                    <div className="space-y-2">
                                      <Label className="text-sm font-medium">Corrected R Syntax (if needed)</Label>
                                      <Input
                                        value={feedback.humanEdit || ''}
                                        onChange={(e) => updateColumnFeedback(column.name, group.groupName, { humanEdit: e.target.value })}
                                        placeholder="Enter corrected R syntax..."
                                        className="font-mono"
                                      />
                                    </div>

                                    {/* Notes */}
                                    <div className="space-y-2">
                                      <Label className="text-sm font-medium">Notes</Label>
                                      <Textarea
                                        value={feedback.notes || ''}
                                        onChange={(e) => updateColumnFeedback(column.name, group.groupName, { notes: e.target.value })}
                                        placeholder="Add notes about this mapping..."
                                        rows={3}
                                      />
                                    </div>
                                  </div>
                                )}
                              </CardContent>
                            </Card>
                          );
                        })}
                            </div>
                          </CardContent>
                        </Card>
                      ))}
                    </div>
                  </CardContent>
                </Card>
                
                {/* Overall Crosstab Notes */}
                <Card className="lg:col-span-2">
                  <CardHeader>
                    <CardTitle className="text-base">Overall Crosstab Validation Notes</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <Textarea
                      value={crosstabNotes}
                      onChange={(e) => setCrosstabNotes(e.target.value)}
                      placeholder="Add overall notes about the crosstab validation..."
                      rows={4}
                    />
                  </CardContent>
                </Card>
              </div>
            )}
          </TabsContent>

          <TabsContent value="banner" className="mt-6">
            {sessionData.data.banner && (
              <div className="space-y-6">
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <FileText className="w-5 h-5" />
                      Banner Agent Output
                    </CardTitle>
                    <CardDescription>
                      Extracted banner groups and columns from the document
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      {sessionData.data.banner.map((group, groupIndex) => (
                        <Card key={groupIndex}>
                          <CardHeader className="pb-3">
                            <CardTitle className="text-base">Group: {group.groupName}</CardTitle>
                          </CardHeader>
                          <CardContent>
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                              {group.columns.map((column, colIndex) => (
                                <Card key={colIndex} className="bg-muted/30">
                                  <CardContent className="p-4">
                                    <div className="font-medium mb-2">{column.name}</div>
                                    <code className="bg-background px-2 py-1 rounded text-xs font-mono text-primary">
                                      {column.original}
                                    </code>
                                    <div className="mt-2 flex items-center text-xs text-muted-foreground">
                                      <CheckCircle className="w-3 h-3 mr-1" />
                                      Banner extraction looks correct
                                    </div>
                                  </CardContent>
                                </Card>
                              ))}
                            </div>
                          </CardContent>
                        </Card>
                      ))}
                    </div>
                  </CardContent>
                </Card>

                {/* Banner Notes */}
                <Card>
                  <CardHeader>
                    <CardTitle className="text-base">Banner Validation Notes</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <Textarea
                      value={bannerNotes}
                      onChange={(e) => setBannerNotes(e.target.value)}
                      placeholder="Add notes about the banner extraction quality, group organization, or any issues found..."
                      rows={4}
                    />
                  </CardContent>
                </Card>
              </div>
            )}
          </TabsContent>

          {/* Validation Actions */}
          <Card className="mt-6">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Eye className="w-5 h-5" />
                Save Validation Session
              </CardTitle>
              <CardDescription>
                This will save your validation for <strong>both Banner and Crosstab tabs</strong> as one complete validation session. 
                All feedback, ratings, edits, and notes will be preserved.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="flex space-x-3">
                <Button
                  disabled={isSaving}
                  onClick={saveValidation}
                  className="bg-green-600 hover:bg-green-700"
                >
                  <CheckCircle className="w-4 h-4 mr-2" />
                  {isSaving ? 'Saving...' : 'Save Complete Validation'}
                </Button>
                
                <Button
                  variant="outline"
                  onClick={() => router.push('/validate')}
                >
                  <ArrowLeft className="w-4 h-4 mr-2" />
                  Back to Queue
                </Button>
              </div>
            </CardContent>
          </Card>
        </Tabs>
      </div>
    </div>
  );
}