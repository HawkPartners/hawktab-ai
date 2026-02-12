// This file configures the initialization of Sentry on the server.
// The config you add here will be used whenever the server handles a request.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";
import { scrubSentryEvent } from "@/lib/observability/sentry-scrub";

const isProd = process.env.NODE_ENV === "production";

Sentry.init({
  dsn: process.env.SENTRY_DSN ||
    "https://f21898a3ccc3ebab43828e154c4ad6f9@o4510871214751744.ingest.us.sentry.io/4510871216062464",

  environment: process.env.NODE_ENV || "development",

  // Sample 100% in dev, 20% in production
  tracesSampleRate: isProd ? 0.2 : 1.0,

  // Enable logs to be sent to Sentry
  enableLogs: true,

  // Only send PII in development
  sendDefaultPii: !isProd,

  // Pipeline cancellation is not an error
  ignoreErrors: ["AbortError"],

  // Strip sensitive data before sending
  beforeSend: scrubSentryEvent,
});
