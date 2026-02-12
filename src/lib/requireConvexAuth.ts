import { requireAuth, type AuthContext } from "./auth";
import { syncAuthToConvex, type ConvexIds } from "./auth-sync";
import { getConvexClient } from "./convex";
import { api } from "../../convex/_generated/api";
import type { Role } from "./permissions";

export interface ConvexAuthContext extends AuthContext {
  convexOrgId: ConvexIds["orgId"];
  convexUserId: ConvexIds["userId"];
  role: Role;
}

/**
 * Single-call helper for API routes: gets WorkOS auth + resolves Convex IDs + role.
 * Throws if not authenticated.
 */
export async function requireConvexAuth(): Promise<ConvexAuthContext> {
  const auth = await requireAuth();
  const ids = await syncAuthToConvex(auth);

  // Fetch role from org membership
  const convex = getConvexClient();
  const membership = await convex.query(api.orgMemberships.getByUserAndOrg, {
    userId: ids.userId,
    orgId: ids.orgId,
  });
  const role = (membership?.role as Role) ?? 'member';

  return {
    ...auth,
    convexOrgId: ids.orgId,
    convexUserId: ids.userId,
    role,
  };
}
