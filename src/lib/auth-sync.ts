import { getConvexClient } from "./convex";
import { anyApi } from "convex/server";
import type { AuthContext } from "./auth";

// Use anyApi until Convex codegen runs (npx convex dev).
// After that, switch to: import { api } from "../../convex/_generated/api";
const api = anyApi;

/**
 * Sync a WorkOS user and org into Convex.
 * Idempotent — safe to call on every login/request.
 * In bypass mode, creates the hardcoded dev records.
 */
export async function syncAuthToConvex(auth: AuthContext): Promise<void> {
  const convex = getConvexClient();

  // Upsert the organization
  const orgId = await convex.mutation(api.organizations.upsert, {
    workosOrgId: auth.orgId,
    name: auth.orgName || (auth.isBypass ? "Hawk Partners Dev" : "Unknown Org"),
    slug: auth.isBypass ? "hawk-partners-dev" : auth.orgId,
  });

  // Upsert the user
  const userId = await convex.mutation(api.users.upsert, {
    workosUserId: auth.userId,
    email: auth.email,
    name: auth.name,
  });

  // Upsert the membership
  await convex.mutation(api.orgMemberships.upsert, {
    userId,
    orgId,
    role: "admin",
  });
}
