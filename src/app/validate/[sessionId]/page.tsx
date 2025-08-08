'use client';

import { useState, useEffect, useCallback } from 'react';
import { useParams, useRouter } from 'next/navigation';
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
import { Switch } from '@/components/ui/switch';
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
  
} from 'lucide-react';
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { formatUtcDateTime } from '@/lib/utils';

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

export default function ValidationSession() {
  const [sessionData, setSessionData] = useState<SessionData | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'banner' | 'crosstab'>('crosstab');
  const [isSaving, setIsSaving] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const router = useRouter();
  const params = useParams<{ sessionId: string }>();

  // Validation state
  const [columnFeedback, setColumnFeedback] = useState<ColumnFeedback[]>([]);
  const [bannerNotes, setBannerNotes] = useState<string>('');
  const [crosstabNotes, setCrosstabNotes] = useState<string>('');
  const [selectedGroup, setSelectedGroup] = useState<string | null>(null);
  const [bannerChecks, setBannerChecks] = useState<Record<string, boolean>>({});

  useEffect(() => {
    const fetchSessionData = async () => {
      try {
        setIsLoading(true);
        setError(null);

        const sessionId = params.sessionId;
        const response = await fetch(`/api/validate/${sessionId}`);
        if (!response.ok) {
          if (response.status === 404) {
            throw new Error('Session not found');
          }
          throw new Error('Failed to load session data');
        }

        const data = await response.json();
        setSessionData(data);
        if (data?.data?.crosstab?.bannerCuts?.length) {
          setSelectedGroup(data.data.crosstab.bannerCuts[0].groupName);
        }
        if (data?.data?.banner) {
          const initial: Record<string, boolean> = {};
          data.data.banner.forEach((g: { groupName: string; columns: { name: string }[] }) => {
            g.columns.forEach((c: { name: string }) => {
              initial[`${g.groupName}::${c.name}`] = false;
            });
          });
          setBannerChecks(initial);
        }
        
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

  const formatDate = (dateString: string) => formatUtcDateTime(dateString);

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

      const bannerTotal = Object.keys(bannerChecks).length;
      const bannerTrue = Object.values(bannerChecks).filter(Boolean).length;
      const bannerSuccessRate = bannerTotal > 0 ? bannerTrue / bannerTotal : 0;

      const validationData: ValidationSession = {
        sessionId: sessionData.sessionId,
        timestamp: new Date().toISOString(),
        bannerValidation: {
          original: sessionData.data.banner,
          humanEdits: bannerChecks,
          notes: bannerNotes,
          successRate: bannerSuccessRate,
          modifiedAt: new Date().toISOString()
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
  }, [sessionData, columnFeedback, bannerNotes, bannerChecks, crosstabNotes, router]);

  // Delete session
  const deleteSession = useCallback(async () => {
    if (!sessionData) return;

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
      setDeleteDialogOpen(false);
    }
  }, [sessionData, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background py-8 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="text-center py-12">
            <div className="text-muted-foreground">Loading validation session...</div>
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
                  onClick={() => setDeleteDialogOpen(true)}
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
                        <TableHeader className="sticky top-0 bg-background z-10">
                          <TableRow>
                            <TableHead>Variable</TableHead>
                            <TableHead>Description</TableHead>
                            <TableHead>Options</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {sessionData.data.dataMap?.map((item, index) => (
                            <TableRow key={index} className="odd:bg-muted/30">
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

                {/* Crosstab Validation Panel (simplified) */}
                <Card className="lg:col-span-1">
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <BarChart3 className="w-5 h-5" />
                      Agent Output Validation
                    </CardTitle>
                    {sessionData.data.crosstab && (
                      <div className="mt-2">
                        <Label className="text-sm mr-2">Group</Label>
                        <Select value={selectedGroup ?? undefined} onValueChange={(v) => setSelectedGroup(v)}>
                          <SelectTrigger>
                            <SelectValue placeholder="Choose a group" />
                          </SelectTrigger>
                          <SelectContent>
                            {sessionData.data.crosstab.bannerCuts.map((g) => (
                              <SelectItem key={g.groupName} value={g.groupName}>{g.groupName}</SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </div>
                    )}
                  </CardHeader>
                  <CardContent>
                    {!selectedGroup || !sessionData.data.crosstab?.bannerCuts.find((g) => g.groupName === selectedGroup)?.columns.length ? (
                      <div className="text-sm text-muted-foreground py-10 text-center">
                        Select a group to review its columns.
                      </div>
                    ) : (
                      <div className="max-h-96 overflow-y-auto">
                      <Table>
                        <TableHeader className="sticky top-0 bg-background z-10">
                          <TableRow>
                            <TableHead>Column</TableHead>
                            <TableHead>Adjusted</TableHead>
                            <TableHead>Confidence</TableHead>
                            <TableHead>Correct?</TableHead>
                            <TableHead>Confidence Rating</TableHead>
                            <TableHead>Reasoning</TableHead>
                            <TableHead>Human Edit</TableHead>
                            <TableHead>Notes</TableHead>
                          </TableRow>
                        </TableHeader>
                        <TableBody>
                          {sessionData.data.crosstab && selectedGroup && (
                            sessionData.data.crosstab.bannerCuts
                              .find((g) => g.groupName === selectedGroup)?.columns
                              .map((column) => {
                                const feedback = columnFeedback.find(
                                  (f) => f.columnName === column.name && f.groupName === selectedGroup
                                );
                                if (!feedback) return null;
                                return (
                                  <TableRow key={column.name} className="odd:bg-muted/30 align-top">
                                    <TableCell className="font-medium">{column.name}</TableCell>
                                    <TableCell>
                                      <code className="bg-muted px-2 py-1 rounded text-xs font-mono text-primary">
                                        {column.adjusted}
                                      </code>
                                    </TableCell>
                                    <TableCell className="text-xs text-muted-foreground">{(column.confidence * 100).toFixed(0)}%</TableCell>
                                    <TableCell>
                                      <RadioGroup
                                        value={feedback.adjustedFieldCorrect ? 'correct' : 'incorrect'}
                                        onValueChange={(value) =>
                                          updateColumnFeedback(column.name, selectedGroup, {
                                            adjustedFieldCorrect: value === 'correct',
                                          })
                                        }
                                      >
                                        <div className="flex items-center gap-3">
                                          <div className="flex items-center gap-1.5">
                                            <RadioGroupItem value="correct" id={`${selectedGroup}-${column.name}-correct`} />
                                            <Label htmlFor={`${selectedGroup}-${column.name}-correct`} className="text-xs">Yes</Label>
                                          </div>
                                          <div className="flex items-center gap-1.5">
                                            <RadioGroupItem value="incorrect" id={`${selectedGroup}-${column.name}-incorrect`} />
                                            <Label htmlFor={`${selectedGroup}-${column.name}-incorrect`} className="text-xs">No</Label>
                                          </div>
                                        </div>
                                      </RadioGroup>
                                    </TableCell>
                                    <TableCell>
                                      <Select
                                        value={feedback.confidenceRating}
                                        onValueChange={(value: 'too_high' | 'correct' | 'too_low') =>
                                          updateColumnFeedback(column.name, selectedGroup, { confidenceRating: value })
                                        }
                                      >
                                        <SelectTrigger>
                                          <SelectValue placeholder="Rate" />
                                        </SelectTrigger>
                                        <SelectContent>
                                          <SelectItem value="too_high">Too High</SelectItem>
                                          <SelectItem value="correct">Correct</SelectItem>
                                          <SelectItem value="too_low">Too Low</SelectItem>
                                        </SelectContent>
                                      </Select>
                                    </TableCell>
                                    <TableCell>
                                      <Select
                                        value={feedback.reasoningQuality}
                                        onValueChange={(value: 'poor' | 'good' | 'excellent') =>
                                          updateColumnFeedback(column.name, selectedGroup, { reasoningQuality: value })
                                        }
                                      >
                                        <SelectTrigger>
                                          <SelectValue placeholder="Rate" />
                                        </SelectTrigger>
                                        <SelectContent>
                                          <SelectItem value="poor">Poor</SelectItem>
                                          <SelectItem value="good">Good</SelectItem>
                                          <SelectItem value="excellent">Excellent</SelectItem>
                                        </SelectContent>
                                      </Select>
                                    </TableCell>
                                    <TableCell>
                                      <Input
                                        value={feedback.humanEdit || ''}
                                        onChange={(e) => updateColumnFeedback(column.name, selectedGroup, { humanEdit: e.target.value })}
                                        placeholder="R syntax..."
                                        className="font-mono"
                                      />
                                    </TableCell>
                                    <TableCell>
                                      <Textarea
                                        value={feedback.notes || ''}
                                        onChange={(e) => updateColumnFeedback(column.name, selectedGroup, { notes: e.target.value })}
                                        placeholder="Notes..."
                                        rows={2}
                                      />
                                    </TableCell>
                                  </TableRow>
                                );
                              })
                          )}
                        </TableBody>
                      </Table>
                    </div>
                    )}
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
                                    <div className="mt-3 flex items-center gap-2 text-xs">
                                      <Switch
                                        id={`banner-${group.groupName}-${column.name}`}
                                        checked={bannerChecks[`${group.groupName}::${column.name}`] || false}
                                        onCheckedChange={(checked) =>
                                          setBannerChecks((prev) => ({ ...prev, [`${group.groupName}::${column.name}`]: checked }))
                                        }
                                      />
                                      <Label htmlFor={`banner-${group.groupName}-${column.name}`}>Looks correct</Label>
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
      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete session?</DialogTitle>
          </DialogHeader>
          <div className="text-sm text-muted-foreground">
            This will permanently delete all files for session
            {sessionData ? ` "${sessionData.sessionId}"` : ''}. This action cannot be undone.
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
            <Button
              variant="destructive"
              onClick={deleteSession}
              disabled={isDeleting}
            >
              {isDeleting ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

// Delete Confirmation Dialog Wrapper rendered at root of this file would require a portal; we can embed in main return above,
// but to keep changes minimal we render it conditionally right after the main container.
