import { ConvexHttpClient } from "convex/browser";

let client: ConvexHttpClient | null = null;

/**
 * Server-side ConvexHttpClient singleton.
 * Use in API routes and server components.
 */
export function getConvexClient(): ConvexHttpClient {
  const url = process.env.CONVEX_URL;
  if (!url) {
    throw new Error(
      "CONVEX_URL is not set. Create a Convex project and add CONVEX_URL to .env.local"
    );
  }

  if (!client) {
    client = new ConvexHttpClient(url);
  }

  return client;
}
