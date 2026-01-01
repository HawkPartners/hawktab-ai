# Phase 2: Team Access (Auth + Database + Storage + Monitoring)

## Implementation Plan

**Goal**: Enable 80-person Hawk Partners team to log in, create projects, upload files, and track processing status with persistent storage and error visibility.

**Deliverable**: Authenticated multi-user application with shared database, cloud file storage, and production error monitoring.

---

## Executive Summary

Phase 1 established Azure OpenAI connectivity. Phase 2 adds the infrastructure for team access:

| Component | Technology | What It Replaces |
|-----------|------------|------------------|
| Authentication | WorkOS AuthKit | No auth (public access) |
| Database | Convex | Filesystem (`temp-outputs/`) |
| Job Tracking | Convex real-time queries | In-memory `Map<jobId, JobStatus>` |
| File Storage | Cloudflare R2 via Convex component | Local filesystem |
| R Execution | Railway Docker container | Local R installation |
| Error Monitoring | Sentry | Console logging |
| Analytics | PostHog (minimal) | None |

**Key Architectural Shift**: Convex provides real-time subscriptions, eliminating the current polling pattern. When a job status changes, all connected clients receive updates automatically.

---

## Pre-Implementation Checklist

### Accounts & Credentials

- [x] **Convex**: Create account at [convex.dev](https://convex.dev) (free tier sufficient) (hawktab-ai)
- [x] **WorkOS**: Account auto-provisioned by Convex CLI (no separate signup needed)
- [x] **Cloudflare**: Create account, create R2 bucket, generate API token with R2 permissions (hawktab-ai; no token yet)
- [x] **Railway**: Create account at [railway.app](https://railway.app) (Hobby plan ~$5/month) (30-day free trial, will pay when needed)
- [x] **Sentry**: Create account and project at [sentry.io](https://sentry.io) (free tier: 5K errors/month) (javascript-nextjs)
- [x] **PostHog**: Create account at [posthog.com](https://posthog.com) (free tier: 1M events/month) (hawktab-ai)

### Local Environment

- [x] Node.js 18+ installed (v20.18.0)
- [x] Convex CLI: `npm install -g convex`
- [x] Docker installed (for local R service testing)
- [x] R installed and in PATH (for local development without Docker)

---

## Step-by-Step Implementation

### Step 1: Initialize Convex + WorkOS AuthKit

**Why together**: [Convex's AuthKit integration](https://docs.convex.dev/auth/authkit/) auto-provisions WorkOS credentials when you initialize. No manual JWT configuration required.

**Commands**:
```bash
# Initialize Convex in existing project
npx convex init

# Install dependencies
npm install convex @convex-dev/workos @workos-inc/authkit-nextjs
```

**Create `convex/auth.config.ts`**:
```typescript
const clientId = process.env.WORKOS_CLIENT_ID;

export default {
  providers: [
    {
      type: "customJwt",
      issuer: "https://api.workos.com/",
      algorithm: "RS256",
      applicationID: clientId,
      jwks: `https://api.workos.com/sso/jwks/${clientId}`,
    },
    {
      type: "customJwt",
      issuer: `https://api.workos.com/user_management/${clientId}`,
      algorithm: "RS256",
      jwks: `https://api.workos.com/sso/jwks/${clientId}`,
    },
  ],
};
```

**Environment Variables** (`.env.local`):
```bash
# Convex
NEXT_PUBLIC_CONVEX_URL=https://your-project.convex.cloud

# WorkOS (get from WorkOS dashboard after Convex provisions)
WORKOS_CLIENT_ID=client_xxx
WORKOS_API_KEY=sk_test_xxx
WORKOS_COOKIE_PASSWORD=<32+ char random string>
NEXT_PUBLIC_WORKOS_REDIRECT_URI=http://localhost:3000/callback
```

**Run Convex dev server** to sync config:
```bash
npx convex dev
```

---

### Step 2: Create Convex Schema

**File**: `convex/schema.ts`

```typescript
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // User profiles (synced from WorkOS)
  users: defineTable({
    workosId: v.string(),
    email: v.string(),
    name: v.optional(v.string()),
    createdAt: v.number(),
  })
    .index("by_workos_id", ["workosId"])
    .index("by_email", ["email"]),

  // Projects (replaces temp-outputs/output-* folders)
  projects: defineTable({
    userId: v.id("users"),
    name: v.string(),
    status: v.union(
      v.literal("uploading"),
      v.literal("processing"),
      v.literal("pending_validation"),
      v.literal("validated"),
      v.literal("error")
    ),
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_status", ["userId", "status"]),

  // Jobs (replaces in-memory jobStore.ts)
  jobs: defineTable({
    projectId: v.id("projects"),
    stage: v.union(
      v.literal("uploading"),
      v.literal("parsing"),
      v.literal("banner_agent"),
      v.literal("crosstab_agent"),
      v.literal("generating_r"),
      v.literal("executing_r"),
      v.literal("writing_outputs"),
      v.literal("complete"),
      v.literal("error")
    ),
    percent: v.number(),
    message: v.string(),
    error: v.optional(v.string()),
    createdAt: v.number(),
    updatedAt: v.number(),
  }).index("by_project", ["projectId"]),

  // Files (references to R2 storage)
  files: defineTable({
    projectId: v.id("projects"),
    type: v.union(
      v.literal("dataMap"),
      v.literal("bannerPlan"),
      v.literal("dataFile"),
      v.literal("output")
    ),
    filename: v.string(),
    r2Key: v.string(),
    contentType: v.string(),
    size: v.number(),
    createdAt: v.number(),
  }).index("by_project", ["projectId"]),

  // Validation results (replaces validation-status.json)
  validationResults: defineTable({
    projectId: v.id("projects"),
    bannerCuts: v.array(
      v.object({
        groupName: v.string(),
        columns: v.array(
          v.object({
            name: v.string(),
            adjusted: v.string(),
            confidence: v.number(),
            reason: v.string(),
          })
        ),
      })
    ),
    humanEdits: v.optional(v.any()),
    validatedAt: v.optional(v.number()),
  }).index("by_project", ["projectId"]),
});
```

---

### Step 3: Create Convex Functions

**File**: `convex/projects.ts`

```typescript
import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

// Get current user's projects
export const list = query({
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) return [];

    const user = await ctx.db
      .query("users")
      .withIndex("by_workos_id", (q) => q.eq("workosId", identity.subject))
      .first();

    if (!user) return [];

    return ctx.db
      .query("projects")
      .withIndex("by_user", (q) => q.eq("userId", user._id))
      .order("desc")
      .collect();
  },
});

// Create new project
export const create = mutation({
  args: { name: v.string() },
  handler: async (ctx, { name }) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Unauthenticated");

    // Get or create user
    let user = await ctx.db
      .query("users")
      .withIndex("by_workos_id", (q) => q.eq("workosId", identity.subject))
      .first();

    if (!user) {
      const userId = await ctx.db.insert("users", {
        workosId: identity.subject,
        email: identity.email!,
        name: identity.name,
        createdAt: Date.now(),
      });
      user = await ctx.db.get(userId);
    }

    const projectId = await ctx.db.insert("projects", {
      userId: user!._id,
      name,
      status: "uploading",
      createdAt: Date.now(),
      updatedAt: Date.now(),
    });

    return projectId;
  },
});

// Update project status
export const updateStatus = mutation({
  args: {
    projectId: v.id("projects"),
    status: v.union(
      v.literal("uploading"),
      v.literal("processing"),
      v.literal("pending_validation"),
      v.literal("validated"),
      v.literal("error")
    ),
  },
  handler: async (ctx, { projectId, status }) => {
    await ctx.db.patch(projectId, { status, updatedAt: Date.now() });
  },
});
```

**File**: `convex/jobs.ts`

```typescript
import { v } from "convex/values";
import { mutation, query } from "./_generated/server";

// Get job status (real-time subscription replaces polling)
export const getByProject = query({
  args: { projectId: v.id("projects") },
  handler: async (ctx, { projectId }) => {
    return ctx.db
      .query("jobs")
      .withIndex("by_project", (q) => q.eq("projectId", projectId))
      .order("desc")
      .first();
  },
});

// Create job
export const create = mutation({
  args: { projectId: v.id("projects") },
  handler: async (ctx, { projectId }) => {
    return ctx.db.insert("jobs", {
      projectId,
      stage: "uploading",
      percent: 0,
      message: "Starting...",
      createdAt: Date.now(),
      updatedAt: Date.now(),
    });
  },
});

// Update job progress
export const update = mutation({
  args: {
    jobId: v.id("jobs"),
    stage: v.optional(v.string()),
    percent: v.optional(v.number()),
    message: v.optional(v.string()),
    error: v.optional(v.string()),
  },
  handler: async (ctx, { jobId, ...updates }) => {
    await ctx.db.patch(jobId, { ...updates, updatedAt: Date.now() });
  },
});
```

---

### Step 4: Set Up R2 File Storage

**Install Convex R2 component**:
```bash
npm install @convex-dev/r2
```

**Create `convex/convex.config.ts`**:
```typescript
import { defineApp } from "convex/server";
import r2 from "@convex-dev/r2/convex.config.js";

const app = defineApp();
app.use(r2);
export default app;
```

**Set R2 environment variables** (via Convex dashboard or CLI):
```bash
npx convex env set R2_TOKEN <your-api-token>
npx convex env set R2_ACCESS_KEY_ID <your-access-key-id>
npx convex env set R2_SECRET_ACCESS_KEY <your-secret-access-key>
npx convex env set R2_ENDPOINT https://<account-id>.r2.cloudflarestorage.com
npx convex env set R2_BUCKET hawktab-files
```

**Create `convex/files.ts`**:
```typescript
import { R2 } from "@convex-dev/r2";
import { components } from "./_generated/api";
import { v } from "convex/values";
import { mutation } from "./_generated/server";

export const r2 = new R2(components.r2);

// Export upload URL generator for client
export const { generateUploadUrl } = r2.clientApi({
  checkUpload: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Unauthenticated");
  },
  onUpload: async (ctx, bucket, key) => {
    console.log(`[R2] File uploaded: ${key}`);
  },
});

// Save file reference after upload
export const saveFileReference = mutation({
  args: {
    projectId: v.id("projects"),
    type: v.union(
      v.literal("dataMap"),
      v.literal("bannerPlan"),
      v.literal("dataFile"),
      v.literal("output")
    ),
    filename: v.string(),
    r2Key: v.string(),
    contentType: v.string(),
    size: v.number(),
  },
  handler: async (ctx, args) => {
    return ctx.db.insert("files", {
      ...args,
      createdAt: Date.now(),
    });
  },
});

// Get download URL
export const getDownloadUrl = mutation({
  args: { r2Key: v.string() },
  handler: async (ctx, { r2Key }) => {
    return r2.getUrl(ctx, r2Key);
  },
});
```

---

### Step 5: Set Up Auth Middleware & Providers

**Create `src/middleware.ts`**:
```typescript
import { authkitMiddleware } from "@workos-inc/authkit-nextjs";

export default authkitMiddleware({
  middlewareAuth: {
    enabled: true,
    unauthenticatedPaths: ["/", "/sign-in", "/sign-up"],
  },
});

export const config = {
  matcher: [
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

**Create `src/components/providers/ConvexProvider.tsx`**:
```typescript
"use client";

import { ConvexReactClient } from "convex/react";
import { ConvexProviderWithAuth } from "convex/react";
import {
  AuthKitProvider,
  useAuth,
} from "@workos-inc/authkit-nextjs/components";
import { ReactNode, useCallback, useMemo } from "react";

const convex = new ConvexReactClient(process.env.NEXT_PUBLIC_CONVEX_URL!);

function useAuthFromAuthKit() {
  const { user, isLoading, getAccessToken } = useAuth();

  const fetchAccessToken = useCallback(async () => {
    try {
      return await getAccessToken();
    } catch {
      return null;
    }
  }, [getAccessToken]);

  return useMemo(
    () => ({
      isLoading,
      isAuthenticated: !!user,
      fetchAccessToken,
    }),
    [isLoading, user, fetchAccessToken]
  );
}

export function ConvexProvider({ children }: { children: ReactNode }) {
  return (
    <AuthKitProvider>
      <ConvexProviderWithAuth client={convex} useAuth={useAuthFromAuthKit}>
        {children}
      </ConvexProviderWithAuth>
    </AuthKitProvider>
  );
}
```

**Create auth route handlers**:

`src/app/callback/route.ts`:
```typescript
import { handleAuth } from "@workos-inc/authkit-nextjs";
export const GET = handleAuth();
```

`src/app/sign-in/route.ts`:
```typescript
import { signIn } from "@workos-inc/authkit-nextjs";
export const GET = signIn;
```

`src/app/sign-out/route.ts`:
```typescript
import { signOut } from "@workos-inc/authkit-nextjs";
export const GET = signOut;
```

**Update `src/app/layout.tsx`**:
```typescript
import { ConvexProvider } from "@/components/providers/ConvexProvider";
// ... existing imports

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={`${geistSans.variable} ${geistMono.variable} antialiased`}>
        <ConvexProvider>
          <ThemeProvider>
            {/* existing layout */}
          </ThemeProvider>
        </ConvexProvider>
      </body>
    </html>
  );
}
```

---

### Step 6: Set Up Sentry Error Monitoring

**Run the Sentry wizard**:
```bash
npx @sentry/wizard@latest -i nextjs
```

The wizard creates:
- `instrumentation-client.ts` - Client-side initialization
- `sentry.server.config.ts` - Server-side initialization
- `sentry.edge.config.ts` - Edge runtime initialization
- `instrumentation.ts` - Next.js instrumentation hook
- `app/global-error.tsx` - Error boundary for App Router
- `.env.sentry-build-plugin` - Auth token for source maps

**Manual adjustments for `instrumentation-client.ts`**:
```typescript
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,

  // Performance: 100% in dev, 10% in production
  tracesSampleRate: process.env.NODE_ENV === "production" ? 0.1 : 1.0,

  // Session replay for debugging
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  // Ignore known non-issues
  ignoreErrors: [
    "ResizeObserver loop limit exceeded",
    "Non-Error promise rejection",
  ],
});
```

**Update `instrumentation.ts`** for Next.js 15:
```typescript
import * as Sentry from "@sentry/nextjs";

export async function register() {
  if (process.env.NEXT_RUNTIME === "nodejs") {
    await import("./sentry.server.config");
  }
  if (process.env.NEXT_RUNTIME === "edge") {
    await import("./sentry.edge.config");
  }
}

// Capture Server Component and middleware errors (Next.js 15+)
export const onRequestError = Sentry.captureRequestError;
```

**Environment Variables**:
```bash
NEXT_PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx
SENTRY_AUTH_TOKEN=sntrys_xxx  # For source map uploads in CI
```

---

### Step 7: Set Up PostHog (Minimal Usage Tracking)

**Install**:
```bash
npm install posthog-js
```

**Create `src/components/providers/PostHogProvider.tsx`**:
```typescript
"use client";

import posthog from "posthog-js";
import { PostHogProvider as PHProvider } from "posthog-js/react";
import { useEffect } from "react";

export function PostHogProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    if (typeof window !== "undefined" && process.env.NEXT_PUBLIC_POSTHOG_KEY) {
      posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY, {
        api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || "https://us.i.posthog.com",
        defaults: "2025-11-30", // Auto pageview/pageleave tracking
        capture_pageview: "history_change",
      });
    }
  }, []);

  return <PHProvider client={posthog}>{children}</PHProvider>;
}
```

**Track key events** (7 essential events for usage visibility):
```typescript
import posthog from "posthog-js";

// Project lifecycle
posthog.capture("project_created", { userId });
posthog.capture("files_uploaded", { projectId, fileTypes: ["dataMap", "bannerPlan", "dataFile"] });

// Processing pipeline
posthog.capture("processing_started", { projectId });
posthog.capture("processing_completed", { projectId, durationMs, columnCount, groupCount });
posthog.capture("processing_failed", { projectId, errorType });

// Validation & export
posthog.capture("validation_completed", { projectId });
posthog.capture("export_downloaded", { projectId, format: "xlsx" });
```

**Environment Variables**:
```bash
NEXT_PUBLIC_POSTHOG_KEY=phc_xxx
NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com
```

---

### Step 8: Migrate API Routes

The key migration is replacing filesystem operations with Convex mutations. Here's the pattern:

**Before** (`src/app/api/validation-queue/route.ts`):
```typescript
// Reads temp-outputs/ directory, no user scoping
const dirContents = await fs.readdir(tempOutputsDir);
const sessionDirs = dirContents.filter(name => name.startsWith('output-'));
```

**After** (use Convex query in client component):
```typescript
"use client";
import { useQuery } from "convex/react";
import { api } from "@/convex/_generated/api";

export function ValidationQueue() {
  // Real-time subscription - no polling needed
  const projects = useQuery(api.projects.list);

  if (!projects) return <Loading />;

  return (
    <div>
      {projects.map(project => (
        <ProjectCard key={project._id} project={project} />
      ))}
    </div>
  );
}
```

**Job status polling eliminated**:
```typescript
// Before: Client polls every 1.2 seconds
const checkStatus = async () => {
  const res = await fetch(`/api/process-crosstab/status?jobId=${jobId}`);
  // ...
};

// After: Real-time subscription
const job = useQuery(api.jobs.getByProject, { projectId });
// UI updates automatically when job changes
```

**Files to update**:
| File | Change |
|------|--------|
| `src/app/api/process-crosstab/route.ts` | Create project/job in Convex, upload to R2 |
| `src/app/api/validation-queue/route.ts` | Replace with client-side Convex query |
| `src/app/api/validate/[sessionId]/route.ts` | Query/mutate Convex instead of filesystem |
| `src/lib/jobStore.ts` | Delete (replaced by Convex) |
| `src/lib/storage.ts` | Update to use R2 for production, keep local for dev |

---

### Step 9: Deploy to Vercel

**Connect repository**:
1. Push code to GitHub
2. Import project in Vercel dashboard
3. Vercel auto-detects Next.js

**Configure environment variables in Vercel**:
```
# Convex
NEXT_PUBLIC_CONVEX_URL=https://your-project.convex.cloud

# WorkOS
WORKOS_CLIENT_ID=client_xxx
WORKOS_API_KEY=sk_live_xxx  # Production key
WORKOS_COOKIE_PASSWORD=<production-secret>
NEXT_PUBLIC_WORKOS_REDIRECT_URI=https://your-app.vercel.app/callback

# Sentry
NEXT_PUBLIC_SENTRY_DSN=https://xxx@sentry.io/xxx
SENTRY_AUTH_TOKEN=sntrys_xxx

# PostHog (optional)
NEXT_PUBLIC_POSTHOG_KEY=phc_xxx
NEXT_PUBLIC_POSTHOG_HOST=https://us.i.posthog.com

# Azure OpenAI (from Phase 1)
AZURE_API_KEY=xxx
AZURE_RESOURCE_NAME=crosstab-ai
AZURE_API_VERSION=2025-01-01-preview
REASONING_MODEL=o4-mini
BASE_MODEL=gpt-5-nano
```

**Update WorkOS redirect URI** in WorkOS dashboard to include production URL.

**Deploy Convex to production**:
```bash
npx convex deploy
```

---

### Step 10: Deploy R Execution Service (Railway)

Vercel serverless functions don't have R installed. We deploy a separate Docker container on Railway that exposes an HTTP endpoint for R script execution.

**Create `r-service/Dockerfile`**:
```dockerfile
FROM r-base:4.3.0

# Install R packages
RUN R -e "install.packages(c('haven', 'dplyr', 'tidyr', 'plumber', 'jsonlite'), repos='https://cran.rstudio.com/')"

# Copy API code
COPY api.R /app/api.R

WORKDIR /app
EXPOSE 8000

CMD ["R", "-e", "plumber::plumb('api.R')$run(host='0.0.0.0', port=8000)"]
```

**Create `r-service/api.R`**:
```r
library(plumber)
library(haven)
library(dplyr)
library(jsonlite)

#* Health check
#* @get /health
function() {
  list(status = "ok", timestamp = Sys.time())
}

#* Execute R script for crosstab generation
#* @post /execute
#* @param data_url URL to download SPSS file from R2
#* @param script R script content to execute
function(req, data_url, script) {
  tryCatch({
    # Create temp directory for this execution
    temp_dir <- tempfile()
    dir.create(temp_dir)
    on.exit(unlink(temp_dir, recursive = TRUE))

    # Download SPSS file from R2
    data_path <- file.path(temp_dir, "data.sav")
    download.file(data_url, data_path, mode = "wb", quiet = TRUE)

    # Load data
    data <- read_sav(data_path)

    # Execute the provided script in an environment with data available
    env <- new.env()
    env$data <- data
    env$temp_dir <- temp_dir

    result <- eval(parse(text = script), envir = env)

    # Return results
    list(
      success = TRUE,
      result = result
    )
  }, error = function(e) {
    list(
      success = FALSE,
      error = conditionMessage(e)
    )
  })
}
```

**Deploy to Railway**:
1. Create new project in Railway dashboard
2. Connect GitHub repo (or use `railway up` CLI)
3. Railway auto-detects Dockerfile and deploys
4. Note the service URL (e.g., `https://hawktab-r.up.railway.app`)

**Add environment variable to Vercel**:
```bash
R_SERVICE_URL=https://hawktab-r.up.railway.app
```

**Update R script execution in Next.js** (`src/lib/r/executor.ts`):
```typescript
export async function executeRScript(
  script: string,
  dataFileUrl: string
): Promise<{ success: boolean; result?: unknown; error?: string }> {
  const response = await fetch(`${process.env.R_SERVICE_URL}/execute`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      script,
      data_url: dataFileUrl,
    }),
  });

  return response.json();
}
```

**Local development**: Run R service locally with Docker:
```bash
cd r-service
docker build -t hawktab-r .
docker run -p 8000:8000 hawktab-r
```

Or continue using local R installation by checking environment:
```typescript
const useLocalR = process.env.NODE_ENV === "development" && !process.env.R_SERVICE_URL;
```

---

### Step 11: Document Processing Dependencies (Serverless-Compatible)

The BannerAgent converts DOC/DOCX files to images for AI vision processing. The current implementation uses `pdf2pic`, which requires GraphicsMagick and Ghostscript—native binaries unavailable in Vercel serverless.

**Dependency Analysis**:

| Package | Purpose | Serverless Compatible? |
|---------|---------|------------------------|
| mammoth | DOC/DOCX → text extraction | ✅ Pure JS |
| pdf-lib | Create PDF from text | ✅ Pure JS |
| **pdf2pic** | PDF → images | ❌ Requires GraphicsMagick |
| sharp | Image optimization | ✅ Ships pre-built binaries |

**Solution**: Replace `pdf2pic` with `pdf-to-img` (wrapper around Mozilla's PDF.js with `@napi-rs/canvas`). This is pure JS with pre-built Rust binaries—same deployment model as `sharp`.

**Pre-Implementation Test** (run before full migration):
```bash
# Install test dependency
npm install pdf-to-img

# Create test script: test-pdf-conversion.ts
```

```typescript
// test-pdf-conversion.ts
import { pdf } from 'pdf-to-img';
import fs from 'fs/promises';
import path from 'path';

async function testConversion() {
  // Use an existing banner plan PDF from your test data
  const pdfPath = 'data/banner-plan.pdf'; // adjust to your test file

  const document = await pdf(pdfPath, { scale: 2.0 });
  let pageNum = 1;

  for await (const image of document) {
    const outPath = `temp-outputs/test-page-${pageNum}.png`;
    await fs.writeFile(outPath, image);
    console.log(`✅ Page ${pageNum} saved: ${outPath}`);
    pageNum++;
  }

  console.log(`\n🎯 Conversion complete. Check temp-outputs/ and verify image quality.`);
  console.log(`   Compare with current pdf2pic output for the same file.`);
}

testConversion().catch(console.error);
```

```bash
# Run the test
npx tsx test-pdf-conversion.ts

# Visual check: Do the images look good enough for AI vision extraction?
# If yes, proceed with migration. If no, fall back to Railway Docker approach.
```

**Migration** (after successful test):
```bash
# Remove old dependency
npm uninstall pdf2pic

# Install replacement
npm install pdf-to-img
```

**Update `src/agents/BannerAgent.ts`**:
```typescript
// Before
import pdf2pic from 'pdf2pic';

// After
import { pdf } from 'pdf-to-img';

// Update convertPDFToImages method:
private async convertPDFToImages(pdfPath: string): Promise<ProcessedImage[]> {
  const document = await pdf(pdfPath, { scale: 2.0 }); // scale 2.0 ≈ 144 DPI
  const processedImages: ProcessedImage[] = [];
  let pageNum = 1;

  for await (const image of document) {
    // image is already a Buffer (PNG format)
    const optimized = await sharp(image)
      .resize(BANNER_CONFIG.maxImageResolution, BANNER_CONFIG.maxImageResolution, {
        fit: 'inside',
        withoutEnlargement: true
      })
      .png({ quality: 90 })
      .toBuffer();

    const metadata = await sharp(optimized).metadata();

    processedImages.push({
      pageNumber: pageNum,
      base64: optimized.toString('base64'),
      width: metadata.width || 0,
      height: metadata.height || 0,
      format: 'png'
    });
    pageNum++;
  }

  return processedImages;
}
```

**Fallback**: If `pdf-to-img` quality is insufficient for complex banner plans, add GraphicsMagick/Ghostscript to the Railway R service Docker container and expose a `/convert-pdf` endpoint.

---

## Future Off-Ramps

If compliance requirements change, the architecture supports migration:

| Current | Alternative | Migration Path |
|---------|-------------|----------------|
| Cloudflare R2 | Azure Blob Storage | Update `convex/files.ts` to use Azure SDK |
| Railway (R service) | Azure Container Apps | Same Docker image, different host |
| Convex | Supabase/Postgres | Export data, update queries to SQL |

These are documented here for future reference but not currently planned.

---

## Testing Plan

### Unit Tests
- [ ] Convex schema validates correctly
- [ ] Auth middleware blocks unauthenticated requests
- [ ] R2 upload/download works
- [ ] R service health check responds
- [ ] `pdf-to-img` produces readable images from banner plan PDFs

### Integration Tests
- [ ] Full upload → process → validate flow with auth
- [ ] Job status updates propagate in real-time
- [ ] Files accessible after page refresh
- [ ] R script execution via Railway service works end-to-end

### Regression Tests
- [ ] Existing crosstab processing still works
- [ ] R script generation produces valid output
- [ ] Excel export functions correctly

---

## Post-Implementation Verification

- [ ] `npm run dev` starts without errors
- [ ] `npx convex dev` syncs successfully
- [ ] Login/logout works via WorkOS
- [ ] Projects are user-scoped (User A can't see User B's projects)
- [ ] File uploads go to R2, not local filesystem
- [ ] Job progress updates without polling
- [ ] R service executes scripts and returns results
- [ ] Document processing works without GraphicsMagick (pdf-to-img)
- [ ] Errors appear in Sentry dashboard
- [ ] Usage events appear in PostHog dashboard

---

## Migration Summary

| Step | Files | Packages | Complexity |
|------|-------|----------|------------|
| 1. Convex + WorkOS init | `convex/auth.config.ts` | `convex`, `@convex-dev/workos`, `@workos-inc/authkit-nextjs` | Medium |
| 2. Schema | `convex/schema.ts` | - | Low |
| 3. Functions | `convex/projects.ts`, `convex/jobs.ts` | - | Medium |
| 4. R2 Storage | `convex/convex.config.ts`, `convex/files.ts` | `@convex-dev/r2` | Medium |
| 5. Auth Middleware | `src/middleware.ts`, `src/components/providers/`, auth routes | - | Medium |
| 6. Sentry | Multiple config files (wizard-generated) | `@sentry/nextjs` | Low |
| 7. PostHog | `src/components/providers/PostHogProvider.tsx` | `posthog-js` | Low |
| 8. API Migration | Update existing API routes | - | High |
| 9. Deploy (Vercel) | Environment variables | - | Low |
| 10. R Service (Railway) | `r-service/Dockerfile`, `r-service/api.R`, `src/lib/r/executor.ts` | - | Medium |
| 11. Document Processing | `src/agents/BannerAgent.ts` | `pdf-to-img` (replaces `pdf2pic`) | Low |

---

## References

### Convex
- [Convex + WorkOS AuthKit](https://docs.convex.dev/auth/authkit/)
- [Convex Schema Design](https://docs.convex.dev/database/schemas)
- [Convex R2 Component](https://github.com/get-convex/r2)
- [Convex File Storage](https://docs.convex.dev/file-storage)

### WorkOS
- [AuthKit for Next.js](https://workos.com/docs/authkit/nextjs)
- [Convex AuthKit Blog Post](https://workos.com/blog/convex-authkit)
- [Template Repository](https://github.com/workos/template-convex-nextjs-authkit)

### Sentry
- [Next.js Manual Setup](https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/)
- [Next.js Guide](https://docs.sentry.io/platforms/javascript/guides/nextjs/)

### Cloudflare R2
- [Presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/)
- [Next.js Upload Guide](https://www.buildwithmatija.com/blog/how-to-upload-files-to-cloudflare-r2-nextjs)

### PostHog
- [Next.js Integration](https://posthog.com/docs/libraries/next-js)
- [App Router Tutorial](https://posthog.com/tutorials/nextjs-app-directory-analytics)

### Railway & R
- [Railway Documentation](https://docs.railway.app/)
- [Plumber R Package](https://www.rplumber.io/)
- [R Docker Images](https://hub.docker.com/_/r-base)

### Document Processing
- [pdf-to-img npm](https://www.npmjs.com/package/pdf-to-img) - Serverless-compatible PDF to image conversion
- [pdfjs-dist](https://www.npmjs.com/package/pdfjs-dist) - Mozilla PDF.js (underlying library)

---

## Changelog

| Date | Change |
|------|--------|
| 2026-01-01 | Initial plan created based on Phase 1 template and technology research |
| 2026-01-01 | **Decisions finalized**: R2 confirmed for storage, Railway for R execution, PostHog reframed as "minimal" (not optional). Added Step 10 for Railway R service. Added Future Off-Ramps section documenting Azure migration path if needed. |
| 2026-01-01 | **Step 11 added**: Document processing dependencies. Replace `pdf2pic` (requires GraphicsMagick) with `pdf-to-img` (serverless-compatible). Includes pre-implementation test script and fallback to Railway Docker if needed. |

---

*Created: January 1, 2026*
*Last Updated: January 1, 2026*
*Status: Ready for Implementation (includes document processing solution)*
