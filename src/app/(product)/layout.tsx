import { SidebarProvider, SidebarInset } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import { AppHeader } from "@/components/app-header";
import { ProjectProvider } from "@/providers/project-provider";
import { PipelineStatusProvider } from "@/providers/pipeline-status-provider";

export default function ProductLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ProjectProvider>
      <PipelineStatusProvider>
        <SidebarProvider defaultOpen>
          <AppSidebar />
          <SidebarInset>
            <AppHeader />
            <main className="flex-1 p-6">{children}</main>
          </SidebarInset>
        </SidebarProvider>
      </PipelineStatusProvider>
    </ProjectProvider>
  );
}
