import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { authkitMiddleware } from "@workos-inc/authkit-nextjs";

const workosMiddleware = authkitMiddleware({
  middlewareAuth: {
    enabled: true,
    unauthenticatedPaths: ["/", "/auth/callback"],
  },
});

export function middleware(request: NextRequest) {
  // AUTH_BYPASS mode: skip all auth checks
  if (process.env.AUTH_BYPASS === "true") {
    return NextResponse.next();
  }

  // Delegate to WorkOS AuthKit middleware
  return workosMiddleware(request, {} as never);
}

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/projects/:path*",
    "/settings/:path*",
    "/api/:path*",
    /*
     * Exclude:
     * - / (marketing)
     * - /auth/callback (WorkOS callback)
     * - _next/static, _next/image
     * - favicon.ico
     */
  ],
};
