import { requireAuth, type AuthContext } from "./auth";
import { syncAuthToConvex, type ConvexIds } from "./auth-sync";

export interface ConvexAuthContext extends AuthContext {
  convexOrgId: ConvexIds["orgId"];
  convexUserId: ConvexIds["userId"];
}

/**
 * Single-call helper for API routes: gets WorkOS auth + resolves Convex IDs.
 * Throws if not authenticated.
 */
export async function requireConvexAuth(): Promise<ConvexAuthContext> {
  const auth = await requireAuth();
  const ids = await syncAuthToConvex(auth);
  return {
    ...auth,
    convexOrgId: ids.orgId,
    convexUserId: ids.userId,
  };
}
