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

#### 3.5e Analytics — `NOT STARTED`

**Goal**: Understand how users interact with the product.

- Add PostHog (`posthog-js` client-side, `@posthog/node` server-side)
- Initialize in root layout with environment-based API key
- Track key events: `project_created`, `pipeline_completed`, `pipeline_failed`, `download_completed`
- Basic session recording (optional, PostHog supports this out of the box)

**Level of Effort**: Small

---

#### 3.5f Testing & Iteration — `NOT STARTED`

## MVP Complete

Completing Phase 3.5 (a through e) = MVP = The Product. Antares logs in, uploads files, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs.

Future features, deferred items, and known gaps/limitations are documented in [`future-features.md`](./future-features.md).

---

*Created: January 22, 2026*
*Updated: February 12, 2026*
*Status: Phase 3 (Productization) in progress. 3.1–3.4, 3.5a–3.5d complete. 3.5e (Analytics) next.*
