"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import {
  LayoutDashboard,
  PlusCircle,
  Settings,
  Loader2,
  CheckCircle,
  AlertCircle,
  AlertTriangle,
  XCircle,
  Clock,
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuBadge,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
} from "@/components/ui/sidebar";
import type { PipelineListItem } from "@/app/api/pipelines/route";

function StatusIcon({ status }: { status: string }) {
  switch (status) {
    case "success":
      return <CheckCircle className="h-3 w-3 text-green-500" />;
    case "partial":
      return <AlertCircle className="h-3 w-3 text-yellow-500" />;
    case "error":
      return <AlertCircle className="h-3 w-3 text-red-500" />;
    case "in_progress":
    case "awaiting_tables":
      return <Loader2 className="h-3 w-3 text-blue-500 animate-spin" />;
    case "pending_review":
      return <AlertTriangle className="h-3 w-3 text-yellow-500" />;
    case "cancelled":
      return <XCircle className="h-3 w-3 text-gray-500" />;
    default:
      return <Clock className="h-3 w-3 text-muted-foreground" />;
  }
}

function formatRelativeTime(timestamp: string): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMinutes = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMinutes / 60);
  const diffDays = Math.floor(diffHours / 24);

  if (diffDays > 0) return diffDays === 1 ? "1d ago" : `${diffDays}d ago`;
  if (diffHours > 0) return diffHours === 1 ? "1h ago" : `${diffHours}h ago`;
  if (diffMinutes > 0)
    return diffMinutes === 1 ? "1m ago" : `${diffMinutes}m ago`;
  return "Just now";
}

export function AppSidebar() {
  const router = useRouter();
  const pathname = usePathname();
  const [pipelines, setPipelines] = useState<PipelineListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    const fetchPipelines = async () => {
      try {
        const res = await fetch("/api/pipelines");
        if (!res.ok) return;
        const data = await res.json();
        if (!cancelled) {
          setPipelines((data.pipelines || []).slice(0, 5));
          setIsLoading(false);
        }
      } catch {
        if (!cancelled) setIsLoading(false);
      }
    };

    fetchPipelines();
    // Refresh every 10 seconds for active pipelines
    const interval = setInterval(fetchPipelines, 10000);
    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, []);

  const handlePipelineClick = (pipeline: PipelineListItem) => {
    if (pipeline.status === "pending_review") {
      router.push(`/projects/${encodeURIComponent(pipeline.pipelineId)}/review`);
    } else {
      router.push(`/projects/${encodeURIComponent(pipeline.pipelineId)}`);
    }
  };

  return (
    <Sidebar>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              size="lg"
              onClick={() => router.push("/dashboard")}
              className="cursor-pointer"
            >
              <div className="flex aspect-square size-8 items-center justify-center rounded-lg bg-primary text-primary-foreground text-sm font-bold">
                CT
              </div>
              <div className="flex flex-col gap-0.5 leading-none">
                <span className="font-semibold">CrossTab AI</span>
                <span className="text-xs text-muted-foreground">
                  Hawk Partners
                </span>
              </div>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>

      <SidebarContent>
        {/* Nav */}
        <SidebarGroup>
          <SidebarGroupLabel>Navigation</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              <SidebarMenuItem>
                <SidebarMenuButton
                  isActive={pathname === "/dashboard"}
                  onClick={() => router.push("/dashboard")}
                  className="cursor-pointer"
                >
                  <LayoutDashboard className="h-4 w-4" />
                  <span>Dashboard</span>
                </SidebarMenuButton>
              </SidebarMenuItem>
              <SidebarMenuItem>
                <SidebarMenuButton
                  isActive={pathname === "/projects/new"}
                  onClick={() => router.push("/projects/new")}
                  className="cursor-pointer"
                >
                  <PlusCircle className="h-4 w-4" />
                  <span>New Project</span>
                </SidebarMenuButton>
              </SidebarMenuItem>
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>

        {/* Recent Projects */}
        <SidebarGroup>
          <SidebarGroupLabel>Recent Projects</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {isLoading ? (
                <SidebarMenuItem>
                  <SidebarMenuButton disabled>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    <span className="text-muted-foreground">Loading...</span>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ) : pipelines.length === 0 ? (
                <SidebarMenuItem>
                  <SidebarMenuButton disabled>
                    <span className="text-muted-foreground text-xs">
                      No projects yet
                    </span>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ) : (
                pipelines.map((pipeline) => (
                  <SidebarMenuItem key={pipeline.pipelineId}>
                    <SidebarMenuButton
                      onClick={() => handlePipelineClick(pipeline)}
                      className="cursor-pointer"
                      isActive={pathname?.includes(pipeline.pipelineId)}
                    >
                      <StatusIcon status={pipeline.status} />
                      <span className="truncate">{pipeline.dataset}</span>
                    </SidebarMenuButton>
                    <SidebarMenuBadge>
                      {formatRelativeTime(pipeline.timestamp)}
                    </SidebarMenuBadge>
                  </SidebarMenuItem>
                ))
              )}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton
              isActive={pathname === "/settings"}
              onClick={() => router.push("/settings")}
              className="cursor-pointer"
            >
              <Settings className="h-4 w-4" />
              <span>Settings</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>

      <SidebarRail />
    </Sidebar>
  );
}
