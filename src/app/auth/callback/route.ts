import { handleAuth } from "@workos-inc/authkit-nextjs";

export const GET = handleAuth({
  returnPathname: "/dashboard",
  onError: ({ error }) => {
    console.error("[Auth Callback] Error during authentication:", error);
    return new Response(null, {
      status: 302,
      headers: { Location: "/auth/error?reason=callback-failed" },
    });
  },
});
