import { redirect } from "next/navigation";
import { SidebarProvider, SidebarInset } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import { AppHeader } from "@/components/app-header";
import { ConvexClientProvider } from "@/app/ConvexClientProvider";
import { AuthProvider } from "@/providers/auth-provider";
import { getAuth } from "@/lib/auth";
import { syncAuthToConvex } from "@/lib/auth-sync";
import { getConvexClient } from "@/lib/convex";
import { api } from "../../../convex/_generated/api";
import type { Role } from "@/lib/permissions";

export default async function ProductLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const auth = await getAuth();

  // No auth means either not logged in or user has no org — redirect to error page
  if (!auth) {
    redirect("/auth/error?reason=no-org");
  }

  let convexOrgId: string | null = null;
  let convexUserId: string | null = null;
  let role: Role | null = null;

  try {
    const ids = await syncAuthToConvex(auth);
    convexOrgId = ids.orgId;
    convexUserId = ids.userId;

    // Fetch the user's role from their org membership
    const convex = getConvexClient();
    const membership = await convex.query(api.orgMemberships.getByUserAndOrg, {
      userId: ids.userId,
      orgId: ids.orgId,
    });
    role = (membership?.role as Role) ?? 'member';
  } catch (err) {
    console.warn('[Layout] Could not sync auth to Convex:', err);
  }

  return (
    <ConvexClientProvider>
      <AuthProvider
        convexOrgId={convexOrgId}
        convexUserId={convexUserId}
        email={auth.email}
        name={auth.name}
        role={role}
        isBypass={auth.isBypass}
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
