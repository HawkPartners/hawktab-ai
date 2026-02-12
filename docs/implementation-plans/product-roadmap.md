# Product Roadmap: Productization

## Overview

CrossTab AI is a crosstab automation pipeline that turns survey data files into publication-ready Excel crosstabs. The pipeline is **reliable** (15 datasets tested, R-based validation, HITL review) and **feature-complete** (output formats, stat testing, weights, themes, AI-generated banners, loop/stacked data). The UI foundation is in place (Next.js app shell with route groups, sidebar, providers, refactored API layer).

**This document tracks the remaining work: getting from localhost to a production URL that Antares can log into and use.**


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

#### 3.5f Testing & Iteration — `IN PROGRESS`

**Goal**: Fix bugs and polish UX issues found during initial Antares testing. Get the deployed product from "works" to "works well."

**Scope**: 8 work items. Items 1, 6, 7, and 8 complete. Items 7–8 added from post-review infrastructure audit.

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

**5. Project deletion and member management** — `COMPLETE`

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

**8. Detect and recover stale `resuming` runs** — `COMPLETE`

**Problem**: After review submission, the pipeline completion runs as a fire-and-forget promise in the API route handler. If the container dies during this work (deploy, OOM, health check timeout), the promise vanishes silently. The Convex status remains `resuming` forever — there's no timeout, no heartbeat, and no reconciliation mechanism. The user sees a pipeline stuck in progress with no way to recover.

**Fix applied**:
- Added `lastHeartbeat` timestamp field to Convex `runs` table, set at run creation and updated every 30s during active processing via `src/lib/api/heartbeat.ts`
- Heartbeat integrated into both `pipelineOrchestrator.ts` (initial pipeline) and `reviewCompletion.ts` (post-review completion) with proper `try/finally` cleanup across all 21+ exit paths
- Convex cron (`convex/crons.ts`) runs every 5 minutes, calling `reconcileStaleRuns` which marks stale runs as `error`: `resuming` after 15 min, `in_progress` after 90 min, `pending_review` after 48 hours
- Error message surfaces in existing UI error banner — no UI changes needed
- Post-implementation audit (5 parallel agents) found 7 hardening items, all remediated: threshold tuning, shared `ACTIVE_STATUSES` constant, heartbeat gap coverage after R2 upload, recursive `setTimeout` replacing `setInterval`, `pending_review` expiry, terminal status in route catch, consecutive-failure logging with escalation

**Files**: `convex/schema.ts`, `convex/runs.ts`, `convex/crons.ts`, `src/lib/api/heartbeat.ts`, `src/lib/api/pipelineOrchestrator.ts`, `src/lib/api/reviewCompletion.ts`, `src/app/api/runs/[runId]/review/route.ts`

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
*Status: Phase 3 (Productization) in progress. 3.1–3.4, 3.5a–3.5e complete. 3.5f (Testing & Iteration) in progress — items 1, 6, 7, and 8 complete.*
