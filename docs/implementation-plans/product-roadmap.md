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
| **3.4** Dashboard, Detail, Roles & Cost | Real-time dashboard, project detail, role enforcement, cost tracking | Not Started |
| **3.5** Deploy & Launch | Railway deployment, DNS, landing page, Sentry | Not Started |

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

### 3.4 Dashboard, Project Detail, Roles & Cost Tracking — `NOT STARTED`

Build the surfaces that make this feel like a product, not a prototype. Focused on the four things that matter for launch: a real dashboard, a project detail page worth looking at, role enforcement so access is controlled, and cost tracking so we know what each run costs.

**Scope decisions**: Re-run support, debug bundles, and supportability tooling are useful but not blocking for the Antares pilot. They're documented under Deferred (Post-Launch) below.

---

#### Dashboard (`(product)/dashboard/`)

The first thing a user sees after login. Needs to feel real.

- Project list from Convex (real-time subscriptions, already wired)
- Columns: Project Name, Status, Tables, Created, Duration, Actions
- **Status filter**: tabs or dropdown (All / In Progress / Completed / Error)
- **Search**: by project name
- **Sort**: by date created (default: newest first), by status
- Empty state with "Create New Project" CTA
- Click project → project detail; click "Review" badge → review page

---

#### Enhanced Project Detail (`(product)/projects/[projectId]/`)

This page is where users spend time during and after a run. Two modes: **in-progress** (watching the pipeline) and **complete** (reviewing results).

**Pipeline progress timeline** (the biggest UX win in this phase):
- Visual stage-by-stage progress, replaces the current text status + percentage
  ```
  ✅ Files uploaded → ✅ Banner analyzed → ⏳ Table generation → ⬜ Verification → ⬜ Excel
  ```
- Driven by the `stage` field already written to Convex by the orchestrator
- Real-time updates via Convex subscription (no polling)
- Current stage shows elapsed time; completed stages show duration

**Results section** (when run completes):
- Summary cards: tables generated, banner cuts, banner groups, duration, AI cost
- Download buttons:
  - Primary: `crosstabs.xlsx`
  - Secondary: `tables.json`, `master.R` (collapsible, for power users)
  - If weighted: separate download for weighted/unweighted output
  - If separate workbooks: separate download per workbook
- Configuration summary: what settings were used for this run (display mode, theme, stat testing, weight variable) — read-only, so users can verify before sharing output

**Status-specific displays**:
- `in_progress`: progress timeline + cancel button
- `pending_review`: "Review Required" banner with link to review page
- `success`/`partial`: results section with downloads
- `error`: human-readable error message (parsed from `run.error`, not raw stack traces)
- `cancelled`: cancellation confirmation

**Action buttons** (contextual):
- Download (when complete)
- Review (when pending_review)
- Cancel (when in_progress)

---

#### Role Enforcement & Auth Polish

The role definitions and auth-sync are in place from 3.1. What's left is enforcement and the minimal UI surfaces for auth.

**Permission gates**:
- Check `orgMemberships.role` before allowing actions
- Admins: see all projects in the org, manage org settings, invite members
- Members: see own projects + shared projects, create projects
- External partners: same access as members (distinguished for labeling, not permissions)
- Gate on both API routes (server-side) and UI (hide/disable controls)

**Auth UI surfaces**:
- **User profile menu** in app header: current user name/email, current org, logout button
- **Org selector**: when a user belongs to multiple orgs, switcher in header (dropdown)
- **Settings page** (`(product)/settings/`):
  - Org info section (name — read-only for non-admins)
  - Member list: name, email, role, joined date
  - Invite member (admin only): email + role assignment
  - Role management (admin only): change member roles

> **Foundation already in place**: Convex schema has `orgMemberships` with `admin`/`member`/`external_partner` roles. Auth-sync preserves existing roles on login (doesn't overwrite). All Convex queries already filter by `orgId`. What's needed is the permission-checking utility and the UI surfaces.

---

#### Cost Tracking

`AgentMetricsCollector` already tracks per-call token usage and cost in memory. This phase persists it.

- Write to Convex `aiUsage` table at pipeline completion (per-agent breakdown: model, tokens in/out, cost, duration)
- Surface total AI cost on the project detail results cards (alongside tables, cuts, duration)
- No dedicated cost dashboard for MVP — query Convex directly for org-level spend if needed
- Schema: `aiUsage { runId, orgId, projectId, agent, model, inputTokens, outputTokens, cost, durationMs }`

---

**Deliverables**: Real-time dashboard with filtering/search, enhanced project detail with progress timeline and results, role enforcement + auth UI + settings page, cost tracking to Convex.

**Level of Effort**: Medium-High (dashboard filters + progress timeline component + project detail rebuild + permission utility + settings page + cost persistence)

---

### 3.5 Deploy & Launch — `NOT STARTED`

Ship it. Antares gets a link.

**Deployment**:
- Railway: Docker container (Node + R), environment variables, health check endpoint
- DNS: Point domain to Railway (or Vercel if we split UI later)
- Environment: Convex production deployment, R2 production bucket, WorkOS production mode

**Landing page** (`(marketing)/page.tsx` — already has placeholder):
- Logo + "CrossTab AI"
- Subhead: "Upload your .sav, configure your project, download publication-ready crosstabs."
- "Log In" button → WorkOS hosted login → redirect to dashboard
- Professional, clean, confident. Not a sales pitch.

**Observability**:
- Sentry for error monitoring (know when things break)
- Basic structured logging with correlation IDs (trace a job through all stages)
- PostHog for lightweight product analytics (project_created, job_completed, job_failed, download_completed) — optional for launch

**Security checklist**:
- [ ] All `(product)/` routes behind auth middleware
- [ ] All Convex queries filter by `orgId`
- [ ] R2 downloads use signed URLs
- [ ] File uploads validated server-side (types, sizes)
- [ ] API inputs validated with Zod
- [ ] CORS restricted to known origins
- [ ] All secrets in environment variables
- [ ] Rate limiting on expensive AI calls
- [ ] Data lifecycle: per-project delete, optional auto-expiration
- [ ] Security audit skill run before launch

**Reliability**:
- Retries with backoff on agent calls (already doing this)
- Graceful degradation (one table fails → continue with others, already doing this)
- Health check endpoint for monitoring
- Idempotent operations (re-running with same inputs is safe)

**Deliverables**: Production deployment live. Antares can log in and use the system. Sentry alerting active.

**Level of Effort**: Medium (deployment + DNS + landing page + Sentry + final testing)

---

## MVP Complete

Completing Phase 3.5 = MVP = The Product. Antares logs in, uploads files, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs.

Future features, deferred items, and known gaps/limitations are documented in [`future-features.md`](./future-features.md).

---

*Created: January 22, 2026*
*Updated: February 11, 2026*
*Status: Phase 3 (Productization) in progress. 3.1–3.3 complete. 3.4 next.*
