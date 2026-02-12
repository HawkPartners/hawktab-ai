import { NextResponse } from "next/server";

/**
 * Production health check endpoint.
 * No auth required — used by Railway for deployment health monitoring.
 *
 * Always returns 200 if the app is running (Railway needs this to pass).
 * Service statuses are informational — check them for debugging, not gating.
 */
export async function GET() {
  const checks: Record<string, "healthy" | "degraded" | "unavailable"> = {};

  // Check Convex connectivity
  try {
    const convexUrl = process.env.CONVEX_URL;
    if (convexUrl) {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 3000);
      const res = await fetch(convexUrl, {
        method: "HEAD",
        signal: controller.signal,
      });
      clearTimeout(timeout);
      checks.database = res.ok || res.status === 405 ? "healthy" : "degraded";
    } else {
      checks.database = "unavailable";
    }
  } catch {
    checks.database = "unavailable";
  }

  // Check critical environment variables are present (not their values)
  const criticalVars = [
    "AZURE_API_KEY",
    "CONVEX_URL",
    "CONVEX_DEPLOY_KEY",
    "R2_ACCOUNT_ID",
    "R2_ACCESS_KEY_ID",
    "R2_SECRET_ACCESS_KEY",
    "R2_BUCKET_NAME",
  ];
  const missingVars = criticalVars.filter((v) => !process.env[v]);
  checks.environment = missingVars.length === 0 ? "healthy" : "degraded";

  // Check auth configuration
  const hasAuth =
    process.env.AUTH_BYPASS === "true" ||
    (process.env.WORKOS_CLIENT_ID && process.env.WORKOS_API_KEY);
  checks.auth = hasAuth ? "healthy" : "unavailable";

  // Derive overall status (informational only — always return 200)
  const hasUnavailable = Object.values(checks).includes("unavailable");
  const hasDegraded = Object.values(checks).includes("degraded");
  const overallStatus = hasUnavailable
    ? "degraded"
    : hasDegraded
      ? "degraded"
      : "ok";

  return NextResponse.json({
    status: overallStatus,
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version ?? "0.1.0",
    checks,
  });
}
