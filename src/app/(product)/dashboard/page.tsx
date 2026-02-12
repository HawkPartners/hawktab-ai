'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from 'convex/react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { PlusCircle, Loader2, Search } from 'lucide-react';
import { PipelineListCard, type ProjectListItem } from '@/components/PipelineListCard';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import { useAuthContext } from '@/providers/auth-provider';
import { canPerform } from '@/lib/permissions';
import { api } from '../../../../convex/_generated/api';
import type { Id } from '../../../../convex/_generated/dataModel';

type StatusFilter = 'all' | 'active' | 'completed' | 'failed';

function getStatusBucket(status: string): StatusFilter {
  switch (status) {
    case 'in_progress':
    case 'resuming':
    case 'pending_review':
      return 'active';
    case 'success':
    case 'partial':
      return 'completed';
    case 'error':
    case 'cancelled':
      return 'failed';
    default:
      return 'active';
  }
}

export default function DashboardPage() {
  const router = useRouter();
  const { convexOrgId, role } = useAuthContext();
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');

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

  // Count by bucket
  const counts = useMemo(() => {
    const c = { all: 0, active: 0, completed: 0, failed: 0 };
    for (const p of projectList) {
      c.all++;
      c[getStatusBucket(p.status)]++;
    }
    return c;
  }, [projectList]);

  // Filter by status tab and search query
  const filteredList = useMemo(() => {
    return projectList.filter((p) => {
      if (statusFilter !== 'all' && getStatusBucket(p.status) !== statusFilter) {
        return false;
      }
      if (searchQuery) {
        return p.name.toLowerCase().includes(searchQuery.toLowerCase());
      }
      return true;
    });
  }, [projectList, statusFilter, searchQuery]);

  const isLoading = projects === undefined || runs === undefined;

  const handleSelect = (projectId: string) => {
    const project = projectList.find(p => p.projectId === projectId);
    if (project?.status === 'pending_review') {
      router.push(`/projects/${encodeURIComponent(projectId)}/review`);
    } else {
      router.push(`/projects/${encodeURIComponent(projectId)}`);
    }
  };

  const canCreate = canPerform(role, 'create_project');

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
        {canCreate && (
          <Button onClick={() => router.push('/projects/new')}>
            <PlusCircle className="h-4 w-4 mr-2" />
            New Project
          </Button>
        )}
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
          {canCreate && (
            <Button onClick={() => router.push('/projects/new')}>
              <PlusCircle className="h-4 w-4 mr-2" />
              New Project
            </Button>
          )}
        </div>
      ) : (
        <>
          {/* Search + Tabs */}
          <div className="space-y-4 mb-6">
            <div className="relative max-w-sm">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search projects..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
            </div>
            <Tabs value={statusFilter} onValueChange={(v) => setStatusFilter(v as StatusFilter)}>
              <TabsList>
                <TabsTrigger value="all">
                  All{counts.all > 0 && <span className="ml-1.5 text-xs text-muted-foreground">{counts.all}</span>}
                </TabsTrigger>
                <TabsTrigger value="active">
                  Active{counts.active > 0 && <span className="ml-1.5 text-xs text-muted-foreground">{counts.active}</span>}
                </TabsTrigger>
                <TabsTrigger value="completed">
                  Completed{counts.completed > 0 && <span className="ml-1.5 text-xs text-muted-foreground">{counts.completed}</span>}
                </TabsTrigger>
                <TabsTrigger value="failed">
                  Failed{counts.failed > 0 && <span className="ml-1.5 text-xs text-muted-foreground">{counts.failed}</span>}
                </TabsTrigger>
              </TabsList>
            </Tabs>
          </div>

          {/* Filtered project list */}
          {filteredList.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-muted-foreground text-sm">
                {searchQuery
                  ? `No projects matching "${searchQuery}"`
                  : `No ${statusFilter} projects`}
              </p>
            </div>
          ) : (
            <div className="space-y-3 max-w-2xl">
              {filteredList.map((project) => (
                <PipelineListCard
                  key={project.projectId}
                  pipeline={project}
                  onClick={handleSelect}
                />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
