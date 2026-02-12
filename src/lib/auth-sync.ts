import { mutateInternal } from "./convex";
import { internal } from "../../convex/_generated/api";
import type { AuthContext } from "./auth";
import type { Id } from "../../convex/_generated/dataModel";

export interface ConvexIds {
  orgId: Id<"organizations">;
  userId: Id<"users">;
}

// In-memory cache keyed by workosUserId → { orgId, userId, expiresAt }
const authCache = new Map<string, { ids: ConvexIds; expiresAt: number }>();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Sync a WorkOS user and org into Convex.
 * Idempotent — safe to call on every login/request.
 * Returns Convex IDs for the org and user.
 * Results are cached for 5 minutes per workosUserId.
 */
export async function syncAuthToConvex(auth: AuthContext): Promise<ConvexIds> {
  // Check cache first
  const cached = authCache.get(auth.userId);
  if (cached && cached.expiresAt > Date.now()) {
    return cached.ids;
  }

  // Upsert the organization
  const orgId = await mutateInternal(internal.organizations.upsert, {
    workosOrgId: auth.orgId,
    name: auth.orgName || (auth.isBypass ? "Hawk Partners Dev" : "Unknown Org"),
    slug: auth.isBypass
      ? "hawk-partners-dev"
      : (auth.orgName
          ? auth.orgName.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
          : "")
        || auth.orgId,
  });

  // Upsert the user
  const userId = await mutateInternal(internal.users.upsert, {
    workosUserId: auth.userId,
    email: auth.email,
    name: auth.name,
  });

  // Upsert the membership — no role passed, so existing roles are preserved.
  // New users default to "member". Roles are managed via admin UI or direct Convex mutation.
  await mutateInternal(internal.orgMemberships.upsert, {
    userId,
    orgId,
  });

  const ids: ConvexIds = { orgId, userId };

  // Cache the result
  authCache.set(auth.userId, {
    ids,
    expiresAt: Date.now() + CACHE_TTL_MS,
  });

  return ids;
}
