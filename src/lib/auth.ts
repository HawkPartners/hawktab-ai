import { withAuth } from "@workos-inc/authkit-nextjs";

export interface AuthContext {
  userId: string;
  email: string;
  name: string;
  orgId: string;
  orgName: string;
  isBypass: boolean;
}

const DEV_USER: AuthContext = {
  userId: "dev_user_001",
  email: "jason@hawkpartners.com",
  name: "Jason (Dev)",
  orgId: "dev_org_001",
  orgName: "Hawk Partners Dev",
  isBypass: true,
};

/**
 * Get the current authenticated user context.
 * In AUTH_BYPASS mode, returns a hardcoded dev user.
 * Returns null if not authenticated.
 */
export async function getAuth(): Promise<AuthContext | null> {
  if (process.env.AUTH_BYPASS === "true") {
    return DEV_USER;
  }

  try {
    const auth = await withAuth();
    if (!auth.user) return null;

    const { user } = auth;
    // orgId comes from the user's organization membership
    const orgId = auth.organizationId ?? "";
    return {
      userId: user.id,
      email: user.email ?? "",
      name: [user.firstName, user.lastName].filter(Boolean).join(" ") || user.email || "Unknown",
      orgId,
      orgName: "", // Populated by auth-sync from Convex
      isBypass: false,
    };
  } catch {
    return null;
  }
}

/**
 * Require authentication. Throws if not authenticated.
 */
export async function requireAuth(): Promise<AuthContext> {
  const auth = await getAuth();
  if (!auth) {
    throw new Error("Authentication required");
  }
  return auth;
}
