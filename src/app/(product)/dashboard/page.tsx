'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { PlusCircle, Loader2 } from 'lucide-react';
import { PipelineListCard } from '@/components/PipelineListCard';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import type { PipelineListItem } from '@/app/api/pipelines/route';

export default function DashboardPage() {
  const [pipelines, setPipelines] = useState<PipelineListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;
    const fetchPipelines = async () => {
      try {
        const res = await fetch('/api/pipelines');
        if (!res.ok) throw new Error('Failed to fetch pipelines');
        const data = await res.json();
        if (!cancelled) {
          setPipelines(data.pipelines || []);
          setIsLoading(false);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Unknown error');
          setIsLoading(false);
        }
      }
    };

    fetchPipelines();
    const interval = setInterval(fetchPipelines, 10000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  const handleSelect = (pipelineId: string) => {
    const pipeline = pipelines.find(p => p.pipelineId === pipelineId);
    if (pipeline?.status === 'pending_review') {
      router.push(`/projects/${encodeURIComponent(pipelineId)}/review`);
    } else {
      router.push(`/projects/${encodeURIComponent(pipelineId)}`);
    }
  };

  return (
    <div>
      <AppBreadcrumbs segments={[{ label: 'Dashboard' }]} />

      <div className="flex items-center justify-between mt-6 mb-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Projects</h1>
          <p className="text-sm text-muted-foreground">
            Your crosstab pipeline runs
          </p>
        </div>
        <Button onClick={() => router.push('/projects/new')}>
          <PlusCircle className="h-4 w-4 mr-2" />
          New Project
        </Button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : error ? (
        <div className="text-center py-20">
          <p className="text-sm text-destructive">{error}</p>
        </div>
      ) : pipelines.length === 0 ? (
        <div className="text-center py-20">
          <p className="text-muted-foreground mb-4">
            No projects yet. Upload your first dataset to get started.
          </p>
          <Button onClick={() => router.push('/projects/new')}>
            <PlusCircle className="h-4 w-4 mr-2" />
            New Project
          </Button>
        </div>
      ) : (
        <div className="space-y-3 max-w-2xl">
          {pipelines.map((pipeline) => (
            <PipelineListCard
              key={pipeline.pipelineId}
              pipeline={pipeline}
              onClick={handleSelect}
            />
          ))}
        </div>
      )}
    </div>
  );
}
