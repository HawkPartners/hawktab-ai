# Product Roadmap: Productization

## Overview

CrossTab AI is a crosstab automation pipeline that turns survey data files into publication-ready Excel crosstabs. The pipeline is **reliable** (15 datasets tested, R-based validation, HITL review) and **feature-complete** (output formats, stat testing, weights, themes, AI-generated banners, loop/stacked data). The UI foundation is in place (Next.js app shell with route groups, sidebar, providers, refactored API layer).

**This document tracks the remaining work: getting from localhost to a production URL that Antares can log into and use.**

**Target State**: Antares receives a URL, logs in, and uses the system end-to-end — upload files, configure their project, run the pipeline, review HITL decisions, download results.

**Philosophy**: Build against real cloud services from the start. Convex has dev environments, R2 has dev buckets, WorkOS has sandbox mode — no local abstractions that get thrown away.

> **Prior phases** (Reliability, Feature Completeness, UI Foundation) are complete and documented in git history. This document focuses exclusively on what's left to build.

---

### Status Summary (Feb 12, 2026)

| Sub-phase | Description | Status |
|-----------|-------------|--------|
| **UI Foundation** | Route groups, app shell, sidebar, providers, API refactor | Complete |
| **3.1** Cloud Infrastructure Setup | Convex, R2, WorkOS, Docker/Railway | Complete |
| **3.2** Pipeline Cloud Migration | Wire orchestrator to Convex/R2, new API routes, deprecate old | Complete |
| **3.3** New Project Experience | Multi-step wizard exposing all pipeline features in UI | Complete |
| **3.4** Dashboard, Detail, Roles & Cost | Real-time dashboard, project detail, role enforcement, cost tracking | Complete |
| **3.5a** Auth Completion | WorkOS production credentials, real login flow | Complete |
| **3.5b** Observability | Sentry, correlation IDs, structured logging | Complete |
| **3.5c** Security Audit | 19 findings across 4 severity tiers, all remediated | Complete |
| **3.5d** Deploy & Launch | Railway, DNS, landing page, smoke testing | Complete |
| **3.5e** Analytics | PostHog setup, key event tracking | Complete |
| **3.5f** Testing & Iteration | 6 items: review timeline fix, unique names, config audit, download filtering, deletion, stats display | Not Started |

---

## Phase 3: Productization

### UI Foundation — `COMPLETE`

Next.js app shell with `(marketing)/` and `(product)/` route groups, collapsible sidebar, header, breadcrumbs. Pages for dashboard, new project, project detail, HITL review, settings. API refactored — orchestrator, HITL manager, file handler extracted from monolithic route. Old `/pipelines/` URLs redirect to `/projects/`.

---

### 3.1 Cloud Infrastructure Setup — `COMPLETE`

**Goal**: Set up the cloud services that everything else builds on. No UI features — just the foundation.

**What was built**: Convex database (project: `crosstab-ai`, deployment: `fortunate-rat-800`) with schema for organizations, users, orgMemberships, projects, and runs. Cloudflare R2 for file storage (`{orgId}/{projectId}/{runId}/{filename}`). WorkOS for auth with `AUTH_BYPASS=true` for local dev. Dockerfile for Railway (Node.js + R + haven). Three roles defined: admin, member, external_partner. All dev environments running.

---

### 3.2 Pipeline Cloud Migration — `COMPLETE`

**Goal**: Wire the pipeline orchestrator and API routes to use Convex and R2 instead of in-memory state and filesystem scanning.

**What was built**: Orchestrator writes status updates to Convex `runs` table (replaces in-memory Map). Real-time Convex subscriptions replace polling throughout the UI. Files uploaded to R2 on intake, downloaded to temp dir for R execution, results uploaded back to R2. Downloads use signed URLs. API routes: `POST /api/projects/launch`, `POST /api/runs/:id/cancel`, `POST /api/runs/:id/review`, `GET|POST /api/runs/:id/feedback`, `GET /api/runs/:id/download/:filename`. All deprecated files and routes deleted. CLI scripts (`test-pipeline.ts`, `batch-pipeline.ts`) unchanged — they write to filesystem directly. Security: all queries filter by `orgId`, R2 keys scoped by org, Zod validation on all inputs.

---

### 3.3 New Project Experience — `COMPLETE`

**Goal**: Replace the flat upload form with a multi-step wizard that exposes all pipeline configuration options.

**What was built**: 4-step wizard — (1) Project Setup: name, research objectives, project type (Standard/Segmentation/MaxDiff) with conditional follow-ups, banner plan choice (upload vs. auto-generate), banner hints. (2A) Upload Files: conditional file slots based on Step 1 answers (.sav always required, survey always required, banner plan and message list conditional). (2B) Data Validation: automatic on .sav upload — stacked data detection (blocks progression), weight candidate detection (user confirms), loop detection (internal only), data quality checks. (3) Configuration: display mode, separate workbooks, color theme, stat testing thresholds, min base size, weight variable, stop-after-verification toggle. (4) Review & Launch: summary of all selections, read-only Statistical Assumptions section (unpooled z-test, Welch's t-test, loop stat testing defaults), launch button that creates Convex project + R2 uploads + starts pipeline.

---

### 3.4 Dashboard, Project Detail, Roles & Cost Tracking — `COMPLETE`

**Goal**: Build the surfaces that make this feel like a product, not a prototype. Real dashboard, project detail with progress timeline, role enforcement, cost tracking.

**What was built**: Dashboard with search input, status tabs (All/Active/Completed/Failed) with count badges, client-side filtering, role-gated New Project button, separate empty states. Pipeline progress timeline component mapping orchestrator stages to 6 user-friendly steps (including post-review stages: `applying_review`, `waiting_for_tables`, `generating_output`). Project detail page with PipelineTimeline replacing old Processing Banner, config summary card reading from `project.config`, role-gated cancel button. User menu in header with initials avatar, name/email/role display, Settings link (role-gated), sign out (hidden in AUTH_BYPASS mode). Settings page with 3 cards (Organization, Profile, Members) using Convex queries, gated for `external_partner`. Cost tracking persisted in `runs.result.costSummary` (internal only, not exposed in UI).

**Security hardening (audit pass)**: `canPerform(role, action)` permission utility with 4 actions. `requireConvexAuth()` now returns `role` from org membership. Role gates on launch route (`create_project`) and cancel route (`cancel_run`). Org ownership checks added to feedback and review routes (IDOR fix). Auth added to 6 legacy routes (`execute-r`, `delete-session`, `loop-detect`, `validation-queue`, `generate-tables`, `export-workbook`). Error responses gated on `NODE_ENV` to prevent detail leakage in production.

---

### 3.5 Deploy & Launch

Ship it. Antares gets a link.

---

#### 3.5a Auth Completion — `COMPLETE`

**Goal**: Real users can log in. Everything downstream depends on this.

**What was built**: `getAuth()` fetches org name from WorkOS via `organizations.getOrganization()` with 30-min in-memory cache; returns null for users without orgs. Auth error page (`/auth/error`) with reason-specific messages (`no-org`, `callback-failed`). Product layout redirects to error page instead of rendering broken dashboard. Callback route has `onError` handler redirecting to error page. `/api/health` and `/auth/error` added to unauthenticated paths. Marketing layout button changed to "Log In". Org slug derived from org name (not raw WorkOS ID) with fallback. `AuthenticationError` class added — all 13 API routes use `instanceof` check for consistent 401 responses (previously 9 routes returned 500 on auth failures). Tested with real WorkOS login, Convex sync verified (org name, slug, user, membership all correct), bypass mode regression-tested.

---

#### 3.5b Observability — `COMPLETE`

**Goal**: See errors from the very first production request. Know when things break before users tell you.

**What was built**: WideEvent class (canonical log line per pipeline run — stages, agent calls, costs, outcome). Sentry pipeline span helpers with `startInactiveSpan` for proper parent-child trace hierarchy. AgentMetricsCollector auto-enriches WideEvent + Sentry breadcrumbs on every agent call. Pipeline-scoped metrics via `AsyncLocalStorage` for concurrent run isolation. `beforeSend` data scrubbing on all three Sentry configs (server, edge, client) with recursive key redaction. `setSentryUser` sets opaque userId only (no email PII). Both `PipelineRunner.ts` (CLI) and `pipelineOrchestrator.ts` (web UI) instrumented at all exit paths. Sentry example pages deleted, DSN externalized to env vars.

---

#### 3.5c Security Audit — `COMPLETE`

**Goal**: Audit the complete system with real auth in place, before real users touch it. Fix findings before deploying.

**What was done**: Full multi-agent security audit (`security-audit` skill) followed by independent multi-agent validation. All findings remediated across 3 commits, 20+ files.

**Findings addressed (19 total)**:
- **CRITICAL (4)**: Next.js RCE (CVE-2025-55182, CVE-2025-66478) + React SSR vulnerability → upgraded to Next.js 15.5.12 + React 19.1.5. R code injection via `exec()` → replaced with `execFile()` + argument arrays across 5 files.
- **HIGH (8)**: Shell injection in R/validation paths → `execFile` migration. Auth bypass guard in production. Security headers (CSP, HSTS, X-Frame-Options). Rate limiting on all 13 API routes (in-memory sliding window, 4 tiers). Convex mutations converted to `internalMutation` with deploy key auth. `v.any()` replaced with typed validators for `config` and `intake` fields.
- **MEDIUM (7)**: R expression sanitization (`sanitizeRExpression` blocklist + character allowlist). Column name escaping for R string/backtick contexts. Path traversal hardened to allowlist regex on all session routes. `pipelineId` path validation. Prompt injection mitigation for user hint text (truncation, XML delimiters). Hardcoded Sentry DSN removed.
- **LOW (5)**: Per-file upload size limits (100MB .sav, 25MB docs, 10MB message lists). Info disclosure gated behind `NODE_ENV`. Dependency vulnerabilities resolved (`npm audit` clean).

**Audit artifacts**: `.security-audit/findings/audit-2026-02-12.md`

**Established patterns**: Documented in `CLAUDE.md` `<security_patterns>` section — all new code should follow these patterns from the ground up.

---

#### 3.5d Deploy & Launch — `COMPLETE`

**Goal**: Production deployment live. Antares gets a URL.

**What was built**: Railway deployment with Docker container (Node.js + R + haven + LibreOffice + GraphicsMagick + Ghostscript). Dockerfile hardened with build tools for R package compilation, `NEXT_PUBLIC_*` vars passed as build args. Convex production deployment, R2 production bucket, WorkOS production mode — all wired up. Health check endpoint at `/api/health`. Landing page with logo, "Crosstab AI" branding, login button routing through WorkOS hosted auth. BaseURL fix for WorkOS callback to prevent `0.0.0.0` redirects. Production hardening: temp file cleanup, R2 error handling, concurrency limiting. HITL review flow bug fixed (Convex mutation ordering race condition). Full end-to-end smoke test passed: real WorkOS login → file upload → pipeline run → HITL review → download.

**Level of Effort**: Medium

---

#### 3.5e Analytics — `COMPLETE`

**Goal**: Understand how users interact with the product.

**What was built**: PostHog integration via `posthog-js` (client-side) and `posthog-node` (server-side). Client initialized via `instrumentation-client.ts` (Next.js 15.3+ approach). Reverse proxy rewrites through `/ingest/*` to bypass ad blockers. User identification with opaque IDs only (no PII). Server-side client with graceful no-op fallback when API key is missing.

**14 events tracked across the full user journey**:
- **Acquisition**: `cta_clicked` (landing page hero + bottom CTA)
- **Onboarding**: `wizard_step_completed`, `file_uploaded`, `project_created`
- **Pipeline**: `project_launch_success`, `project_launch_error` (server-side), `pipeline_completed`, `pipeline_failed` (server-side)
- **Engagement**: `project_selected`, `review_decision_made`, `review_submitted`, `pipeline_cancelled`
- **Output**: `file_downloaded`, `feedback_submitted`

**PostHog dashboard**: Pre-built with project creation funnel, download breakdown, review decisions, feedback ratings, and pipeline success rate insights.

**Level of Effort**: Small

---

#### 3.5f Testing & Iteration — `NOT STARTED`

**Goal**: Fix bugs and polish UX issues found during initial Antares testing. Get the deployed product from "works" to "works well."

**Scope**: 6 issues identified, collapsed into 5 work items after investigation.

---

**1. Fix post-review timeline regression** — `HIGH PRIORITY`

**Bug**: After submitting a HITL review, the project page timeline "forgets" progress and appears to restart from step 1. Two symptoms, one root cause.

**Root cause**: The review API handler (`/api/runs/[runId]/review/route.ts`, line 152) sets `stage: 'filtering'` after review submission, but the `PipelineTimeline` component (`src/components/pipeline-timeline.tsx`) has no mapping for the `'filtering'` stage. The `getStepStatuses()` function can't find the current stage in any `TIMELINE_STEPS` entry, so `foundCurrent` stays false and the timeline falls back to showing the first step as active.

**Secondary issue**: When Path B (table generation) is still running at review time, the run is set to `stage: 'waiting_for_tables'` with progress stuck at 55%. Background completion via `waitAndCompletePipeline()` is fire-and-forget with no UI feedback.

**Fix**:
- Add `'filtering'` to the appropriate stage group in `TIMELINE_STEPS` (or replace with a mapped stage like `'applying_review'` in the review handler)
- Ensure ALL post-review stages (`filtering`, `splitting`, `verification`, `post_processing`) are mapped to timeline steps
- Verify the `router.push()` navigation after review submission is working (it exists at line 376 of review/page.tsx)

**Files**: `src/components/pipeline-timeline.tsx`, `src/app/api/runs/[runId]/review/route.ts`, `src/lib/api/pipelineOrchestrator.ts`

**Level of Effort**: Small

---

**2. Enforce unique project names per organization** — `MEDIUM PRIORITY`

**Bug**: Users can create multiple projects with the same name in the same org. No uniqueness check at any layer — not in the wizard, not in the API, not in Convex.

**Root cause**: The Convex `projects` table only indexes on `orgId` (no compound unique index on `orgId + name`). Neither the launch API route nor the Convex `create` mutation check for existing projects with the same name.

**Fix**:
- Add a pre-creation check in `/api/projects/launch/route.ts`: query projects by org, check for name collision, return 409 Conflict if found
- Add a defensive check in the Convex `projects.create` mutation (belt-and-suspenders)
- Return a user-friendly error in the wizard if the name is taken
- Optional: add compound unique index to schema later for database-level enforcement

**Files**: `src/app/api/projects/launch/route.ts`, `convex/projects.ts`, `convex/schema.ts`

**Level of Effort**: Small

---

**3. Audit configuration passthrough (display mode + separate workbooks)** — `MEDIUM PRIORITY`

**Bug**: User configured "Both (Percentages + Counts)" with "Separate workbooks" enabled, but only one workbook was produced.

**Investigation findings**: The full config pipeline IS wired correctly in code — wizard → `wizardToProjectConfig()` → launch API → orchestrator → `ExcelFormatter`. The `ExcelFormatter.formatJoeStyle()` method (lines 191-228) correctly handles all three cases: separate workbooks, two sheets in one workbook, and single-mode output.

**Suspected root cause**: Config may be lost during HITL review state save/restore. When the pipeline pauses for review, `wizardConfig` is saved to `crosstab-review-state.json` (orchestrator line 931). On resume, `reviewCompletion.ts` reads it back (line 699). If `wizardConfig` is missing or malformed in the saved state, defaults are used — which would explain the single-workbook behavior.

**Fix**:
- Add logging in `reviewCompletion.ts` at the point where `wizardConfig` is read from review state to confirm values
- Add logging in `ExcelFormatter` around the display mode decision (lines 191-228) to trace the actual config received
- Test the full flow: wizard → configure "Both + Separate" → run → HITL review → verify config survives round-trip
- If config IS being lost, fix the serialization/deserialization path in review state

**Files**: `src/lib/api/reviewCompletion.ts`, `src/lib/api/pipelineOrchestrator.ts`, `src/lib/excel/ExcelFormatter.ts`

**Level of Effort**: Small–Medium (diagnosis may reveal a simple serialization bug, or may require deeper tracing)

---

**4. Restrict downloadable files to crosstabs only** — `MEDIUM PRIORITY`

**Bug**: The download UI and API expose internal files (`tables.json`, `master.R`, `pipeline-summary.json`) that users don't need and shouldn't see. These leak implementation details — R script logic, internal data structures, pipeline costs.

**Current state**: Download API route (`/api/runs/[runId]/download/[filename]/route.ts`) has a 4-entry allowlist: `crosstabs.xlsx`, `tables.json`, `master.R`, `pipeline-summary.json`. The project detail page renders download buttons for the first three. `pipeline-summary.json` is API-accessible but not shown in UI.

**Fix**:
- Update `DOWNLOAD_FILES` in project detail page to only show `crosstabs.xlsx` (and second workbook if separate workbooks was configured)
- Update `FILENAME_TO_OUTPUT_PATH` allowlist in the download API to only permit Excel files (enforce at API level, not just UI)
- R2 upload list in `R2FileManager.ts` can stay as-is (internal files useful for debugging)
- Consider: add an admin-only "debug downloads" section for internal users

**Files**: `src/app/(product)/projects/[projectId]/page.tsx` (lines 125-129), `src/app/api/runs/[runId]/download/[filename]/route.ts` (lines 17-22)

**Level of Effort**: Small

---

**5. Project deletion and member management** — `LOWER PRIORITY`

**Feature request**: Users should be able to delete projects. Admins should be able to remove members.

**Current state**: Neither exists. No delete mutations in Convex, no delete API routes, no delete UI. The settings page shows members read-only. The permission system has `manage_members` action defined but nothing wired to it.

**What to build**:

*Project deletion:*
- Add soft-delete fields to projects schema (`isDeleted`, `deletedAt`)
- Add `deleteProject` internal mutation to `convex/projects.ts`
- Add delete API route with auth + org ownership + role check + `critical` rate limiting
- Add delete button to project detail page with confirmation dialog
- Cascade: delete associated runs, clean up R2 files (`{orgId}/{projectId}/*`)
- Update dashboard query to filter out deleted projects

*Member management (admin-only):*
- Add `remove` and `updateRole` mutations to `convex/orgMemberships.ts`
- Add API routes for member removal and role changes
- Add action buttons to the Members card on settings page
- Guard: cannot remove last admin, cannot remove yourself

*Account deletion*: Deferred — high complexity (WorkOS sync, data retention, GDPR implications). Not needed for MVP.

**Files**: `convex/projects.ts`, `convex/orgMemberships.ts`, `convex/schema.ts`, `src/app/(product)/projects/[projectId]/page.tsx`, `src/app/(product)/settings/page.tsx`, new API routes

**Level of Effort**: Medium

---

**6. Verify pipeline run statistics display in UI** — `MEDIUM PRIORITY`

**Issue**: Pipeline stats (duration, table count, cut count, banner group count) should be visible on the project page after a run completes. The backend collects `summary: { tables, cuts, bannerGroups, durationMs }` and persists it to Convex `runs.result.summary`. A Summary Statistics card exists in the project detail page (lines 470-499).

**What to verify**:
- Are the stats actually rendering in production after a completed run? (The data is stored, but is the UI reading it correctly?)
- Does the summary survive the HITL review flow? (Same concern as item 3 — does post-review completion persist the summary?)
- Is the duration accurate and human-readable? (Currently stored as `durationMs`, formatted as seconds)
- Are table/cut/banner group counts correct and meaningful to the user?

**Fix (if broken)**:
- Trace `runs.result.summary` from orchestrator completion through Convex to the UI component
- Ensure `completePipeline()` in `reviewCompletion.ts` also persists the summary (not just the main path)
- Format duration as "X min Y sec" instead of raw seconds for better readability

**Files**: `src/app/(product)/projects/[projectId]/page.tsx`, `src/lib/api/pipelineOrchestrator.ts`, `src/lib/api/reviewCompletion.ts`

**Level of Effort**: Small

---

### Ongoing Feedback Log

> Items below are raw feedback captured during testing. As issues are confirmed and scoped, they get promoted to numbered items above or filed as new work items.

*(No additional feedback yet — add items here as testing continues.)*

---

## MVP Complete

Completing Phase 3.5 (a through e) = MVP = The Product. Antares logs in, uploads files, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs.

Phase 3.5f is polish and bug fixes to ensure the MVP is solid for real users.

Future features, deferred items, and known gaps/limitations are documented in [`future-features.md`](./future-features.md).

---

*Created: January 22, 2026*
*Updated: February 12, 2026*
*Status: Phase 3 (Productization) in progress. 3.1–3.4, 3.5a–3.5e complete. 3.5f (Testing & Iteration) next.*
