import { SidebarProvider, SidebarInset } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import { AppHeader } from "@/components/app-header";
import { ConvexClientProvider } from "@/app/ConvexClientProvider";
import { AuthProvider } from "@/providers/auth-provider";
import { getAuth } from "@/lib/auth";
import { syncAuthToConvex } from "@/lib/auth-sync";

export default async function ProductLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const auth = await getAuth();
  let convexOrgId: string | null = null;
  let convexUserId: string | null = null;

  if (auth) {
    try {
      const ids = await syncAuthToConvex(auth);
      convexOrgId = ids.orgId;
      convexUserId = ids.userId;
    } catch (err) {
      console.warn('[Layout] Could not sync auth to Convex:', err);
    }
  }

  return (
    <ConvexClientProvider>
      <AuthProvider
        convexOrgId={convexOrgId as Parameters<typeof AuthProvider>[0]["convexOrgId"]}
        convexUserId={convexUserId as Parameters<typeof AuthProvider>[0]["convexUserId"]}
        email={auth?.email}
        name={auth?.name}
      >
        <SidebarProvider defaultOpen>
          <AppSidebar />
          <SidebarInset>
            <AppHeader />
            <main className="flex-1 p-6">{children}</main>
          </SidebarInset>
        </SidebarProvider>
      </AuthProvider>
    </ConvexClientProvider>
  );
}
