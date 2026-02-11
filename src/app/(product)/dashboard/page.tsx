'use client';

import { useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from 'convex/react';
import { Button } from '@/components/ui/button';
import { PlusCircle, Loader2 } from 'lucide-react';
import { PipelineListCard, type ProjectListItem } from '@/components/PipelineListCard';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import { useAuthContext } from '@/providers/auth-provider';
import { api } from '../../../../convex/_generated/api';
import type { Id } from '../../../../convex/_generated/dataModel';

export default function DashboardPage() {
  const router = useRouter();
  const { convexOrgId } = useAuthContext();

  const projects = useQuery(
    api.projects.listByOrg,
    convexOrgId ? { orgId: convexOrgId as Id<"organizations"> } : 'skip',
  );

  const runs = useQuery(
    api.runs.listByOrg,
    convexOrgId ? { orgId: convexOrgId as Id<"organizations"> } : 'skip',
  );

  // Join projects with their latest run to build the list
  const projectList: ProjectListItem[] = useMemo(() => {
    if (!projects || !runs) return [];

    // Group runs by project, taking the most recent (runs are already sorted desc)
    const latestRunByProject = new Map<string, (typeof runs)[number]>();
    for (const run of runs) {
      const pid = String(run.projectId);
      if (!latestRunByProject.has(pid)) {
        latestRunByProject.set(pid, run);
      }
    }

    return projects.map((project) => {
      const latestRun = latestRunByProject.get(String(project._id));
      const result = latestRun?.result as Record<string, unknown> | undefined;
      const summary = result?.summary as Record<string, number> | undefined;

      return {
        projectId: String(project._id),
        name: project.name,
        createdAt: project._creationTime,
        latestRunId: latestRun ? String(latestRun._id) : undefined,
        status: latestRun?.status || 'pending',
        tables: summary?.tables,
        cuts: summary?.cuts,
        durationMs: summary?.durationMs,
      };
    }).sort((a, b) => b.createdAt - a.createdAt);
  }, [projects, runs]);

  const isLoading = projects === undefined || runs === undefined;

  const handleSelect = (projectId: string) => {
    const project = projectList.find(p => p.projectId === projectId);
    if (project?.status === 'pending_review') {
      router.push(`/projects/${encodeURIComponent(projectId)}/review`);
    } else {
      router.push(`/projects/${encodeURIComponent(projectId)}`);
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
      ) : projectList.length === 0 ? (
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
          {projectList.map((project) => (
            <PipelineListCard
              key={project.projectId}
              pipeline={project}
              onClick={handleSelect}
            />
          ))}
        </div>
      )}
    </div>
  );
}
