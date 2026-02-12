# Product Roadmap: Productization

## Overview

CrossTab AI is a crosstab automation pipeline that turns survey data files into publication-ready Excel crosstabs. The pipeline is **reliable** (15 datasets tested, R-based validation, HITL review) and **feature-complete** (output formats, stat testing, weights, themes, AI-generated banners, loop/stacked data). The UI foundation is in place (Next.js app shell with route groups, sidebar, providers, refactored API layer).

**This document tracks the remaining work: getting from localhost to a production URL that Antares can log into and use.**

**Target State**: Antares receives a URL, logs in, and uses the system end-to-end — upload files, configure their project, run the pipeline, review HITL decisions, download results.

**Philosophy**: Build against real cloud services from the start. Convex has dev environments, R2 has dev buckets, WorkOS has sandbox mode — no local abstractions that get thrown away.

> **Prior phases** (Reliability, Feature Completeness, UI Foundation) are complete and documented in git history. This document focuses exclusively on what's left to build.

---

### Status Summary (Feb 11, 2026)

| Sub-phase | Description | Status |
|-----------|-------------|--------|
| **UI Foundation** | Route groups, app shell, sidebar, providers, API refactor | Complete |
| **3.1** Cloud Infrastructure Setup | Convex, R2, WorkOS, Docker/Railway | Complete |
| **3.2** Pipeline Cloud Migration | Wire orchestrator to Convex/R2, new API routes, deprecate old | Complete |
| **3.3** New Project Experience | Multi-step wizard exposing all pipeline features in UI | Complete |
| **3.4** Dashboard, Detail, Roles & Cost | Real-time dashboard, project detail, role enforcement, cost tracking | Complete |
| **3.5a** Auth Completion | WorkOS production credentials, real login flow | Not Started |
| **3.5b** Observability | Sentry, correlation IDs, structured logging | Not Started |
| **3.5c** Security Audit | Full audit with real auth in place, fix findings | Not Started |
| **3.5d** Deploy & Launch | Railway, DNS, landing page, smoke testing | Not Started |
| **3.5e** Analytics | PostHog setup, key event tracking | Not Started |

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

#### 3.5a Auth Completion — `NOT STARTED`

**Goal**: Real users can log in. Everything downstream depends on this.

WorkOS auth is fully scaffolded (`middleware.ts`, `auth.ts`, `auth-sync.ts`) with `AUTH_BYPASS=true` for local dev. This step provisions production credentials and validates the real login flow.

- Provision WorkOS production environment (API key, client ID, redirect URI)
- Test real login → callback → `syncAuthToConvex()` flow with a live user
- Verify role assignment and org membership propagation
- Confirm `AUTH_BYPASS=false` works correctly in production config

**Level of Effort**: Small

---

#### 3.5b Observability — `NOT STARTED`

**Goal**: See errors from the very first production request. Know when things break before users tell you.

- Add `@sentry/nextjs` — unhandled error capture, source maps, error boundaries
- Correlation IDs: generate per-request UUID, propagate through pipeline stages and agent calls (build on existing `src/lib/tracing.ts` scaffolding)
- Structured logging with Sentry as the sink (breadcrumbs + context per pipeline run)
- Alerting: Sentry notifications for unhandled exceptions and pipeline failures

**Level of Effort**: Small–Medium

---

#### 3.5c Security Audit — `NOT STARTED`

**Goal**: Audit the complete system with real auth in place, before real users touch it. Fix findings before deploying.

Phase 3.4 hardening pass (RBAC via `canPerform()`, IDOR fixes on feedback/review routes, error detail gating, auth on legacy routes) provides a solid baseline. This is the full audit pass.

- Run comprehensive security audit (auth, authorization, injection, secrets, crypto)
- Review all API routes for proper auth gates and input validation
- Verify R2 key scoping and Convex query org-filtering
- Check for leaked secrets, hardcoded credentials, exposed env vars
- Fix any findings

**Level of Effort**: Medium

---

#### 3.5d Deploy & Launch — `NOT STARTED`

**Goal**: Production deployment live. Antares gets a URL.

**Deployment**:
- Railway: Docker container (Node + R), environment variables, health check endpoint
- DNS: Point domain to Railway
- Environment: Convex production deployment, R2 production bucket, WorkOS production mode

**Landing page** (`(marketing)/page.tsx` — already has placeholder):
- Logo + "Crosstab AI"
- Subhead: "Upload your .sav, configure your project, download publication-ready crosstabs."
- "Log In" button → WorkOS hosted login → redirect to dashboard
- Professional, clean, confident. Not a sales pitch.

**Smoke testing**: End-to-end test with real WorkOS login, file upload, pipeline run, download.

**Level of Effort**: Medium

---

#### 3.5e Analytics — `NOT STARTED`

**Goal**: Understand how users interact with the product.

- Add PostHog (`posthog-js` client-side, `@posthog/node` server-side)
- Initialize in root layout with environment-based API key
- Track key events: `project_created`, `pipeline_completed`, `pipeline_failed`, `download_completed`
- Basic session recording (optional, PostHog supports this out of the box)

**Level of Effort**: Small

---

## MVP Complete

Completing Phase 3.5 (a through e) = MVP = The Product. Antares logs in, uploads files, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs.

Future features, deferred items, and known gaps/limitations are documented in [`future-features.md`](./future-features.md).

---

*Created: January 22, 2026*
*Updated: February 11, 2026*
*Status: Phase 3 (Productization) in progress. 3.1–3.4 complete. 3.5a–3.5e next.*
