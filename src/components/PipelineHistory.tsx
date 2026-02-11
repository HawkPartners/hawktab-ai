/**
 * @deprecated This component is no longer used. The AppSidebar "Recent Projects"
 * section and the Dashboard page (PipelineListCard grid) replaced this slide-out
 * sheet in the Phase A route group restructure.
 *
 * Safe to delete once confirmed no external references remain.
 * Last known import locations: none (verified Feb 11, 2026).
 */
'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { History, Loader2 } from 'lucide-react';
import { PipelineListCard } from './PipelineListCard';
import type { PipelineListItem } from '@/app/api/pipelines/route';

export function PipelineHistory() {
  const [pipelines, setPipelines] = useState<PipelineListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState(false);
  const router = useRouter();

  const fetchPipelines = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/pipelines');
      if (!res.ok) throw new Error('Failed to fetch pipelines');
      const data = await res.json();
      setPipelines(data.pipelines || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setIsLoading(false);
    }
  };

  // Fetch pipelines when sheet opens
  useEffect(() => {
    if (isOpen) {
      fetchPipelines();
    }
  }, [isOpen]);

  const handleSelect = (pipelineId: string) => {
    setIsOpen(false);
    // Find the pipeline to check its status
    const pipeline = pipelines.find(p => p.pipelineId === pipelineId);
    if (pipeline?.status === 'pending_review') {
      router.push(`/projects/${encodeURIComponent(pipelineId)}/review`);
    } else {
      router.push(`/projects/${encodeURIComponent(pipelineId)}`);
    }
  };

  return (
    <Sheet open={isOpen} onOpenChange={setIsOpen}>
      <SheetTrigger asChild>
        <Button variant="outline" size="icon" title="Pipeline History">
          <History className="h-4 w-4" />
        </Button>
      </SheetTrigger>
      <SheetContent side="left" className="w-80 sm:w-96">
        <SheetHeader>
          <SheetTitle>Pipeline History</SheetTitle>
        </SheetHeader>
        <div className="mt-4 space-y-3 overflow-y-auto max-h-[calc(100vh-120px)]">
          {isLoading ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="h-6 w-6 animate-spin text-muted-foreground" />
            </div>
          ) : error ? (
            <div className="text-center py-8">
              <p className="text-sm text-destructive">{error}</p>
              <Button variant="outline" size="sm" onClick={fetchPipelines} className="mt-2">
                Retry
              </Button>
            </div>
          ) : pipelines.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-sm text-muted-foreground">No pipeline runs yet</p>
              <p className="text-xs text-muted-foreground mt-1">
                Upload files and generate crosstabs to see history here.
              </p>
            </div>
          ) : (
            pipelines.map((pipeline) => (
              <PipelineListCard
                key={pipeline.pipelineId}
                pipeline={pipeline}
                onClick={handleSelect}
              />
            ))
          )}
        </div>
      </SheetContent>
    </Sheet>
  );
}
