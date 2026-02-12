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

---

**3. Audit configuration passthrough (display mode + separate workbooks)** — `MEDIUM PRIORITY`

**Bug**: User configured "Both (Percentages + Counts)" with "Separate workbooks" enabled, but only one workbook was produced.

**Investigation findings**: The full config pipeline IS wired correctly in code — wizard → `wizardToProjectConfig()` → launch API → orchestrator → `ExcelFormatter`. The `ExcelFormatter.formatJoeStyle()` method (lines 191-228) correctly handles all three cases: separate workbooks, two sheets in one workbook, and single-mode output.

**Suspected root cause**: Config may be lost during HITL review state save/restore. When the pipeline pauses for review, `wizardConfig` is saved to `crosstab-review-state.json` (orchestrator line 931). On resume, `reviewCompletion.ts` reads it back (line 699). If `wizardConfig` is missing or malformed in the saved state, defaults are used — which would explain the single-workbook behavior. THOUGH CONDUCT YOUR OWN INVESTIGATION AND CONFIRM THE ROOT CAUSE.

**Fix**:
- Add logging in `reviewCompletion.ts` at the point where `wizardConfig` is read from review state to confirm values
- Add logging in `ExcelFormatter` around the display mode decision (lines 191-228) to trace the actual config received
- Test the full flow: wizard → configure "Both + Separate" → run → HITL review → verify config survives round-trip
- If config IS being lost, fix the serialization/deserialization path in review state

**Files**: `src/lib/api/reviewCompletion.ts`, `src/lib/api/pipelineOrchestrator.ts`, `src/lib/excel/ExcelFormatter.ts`

**Level of Effort**: Small–Medium (diagnosis may reveal a simple serialization bug, or may require deeper tracing)

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
