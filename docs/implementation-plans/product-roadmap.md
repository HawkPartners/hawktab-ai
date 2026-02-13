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

### Ongoing Feedback Log

> Items below are feedback captured during testing, organized by area. As issues are confirmed and scoped, they get promoted to numbered items above or filed as new work items.

**Navigation & Routing**
- "Save & Continue" on the review page auto-routes to the project page instead of staying in flow (timeline issue is fixed, routing issue remains)

**Pipeline Progress & Status**
- Need a loading indicator when a pipeline run starts (spinning circle or progress bar so users don't think the app is stuck)
- Pipeline percentage is inaccurate (sits at 50% for a long time before jumping)
- Human-readable duration (e.g., "15 min 21 sec" instead of "921 seconds") — works on project list view but not on the individual project page

**Notifications**
- Email notification when pipeline completes or fails

**UI Polish & Design System**
- Strip overuse of non-clean icons; follow the design system and think B2B
- Loop detection info is too verbose — just show that a loop was detected and data will be stacked (consider showing stacking details at end of pipeline or only if the user can act on it)

**Output & Downloads**
- Use the project name as the crosstab filename, appended by date and other necessary info
- Add configuration to hide excluded tables from the Excel file (default: show them)

**HITL Review**
- Given that agents provide confidence scores, how should we determine the number of HITL reviews? (e.g., threshold-based: low confidence = more reviews)

**Developer Experience**
- Make agent debugging easier — every agent's tool calls and scratchpad output should be captured in a single accessible location for post-run inspection

---

## MVP Complete

Completing Phase 3.5 (a through e) = MVP = The Product. Antares logs in, uploads files, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs.

Phase 3.5f is polish and bug fixes to ensure the MVP is solid for real users.

Future features, deferred items, and known gaps/limitations are documented in [`future-features.md`](./future-features.md).

---

*Created: January 22, 2026*
*Updated: February 13, 2026*
*Status: Phase 3 (Productization) in progress. 3.1–3.4, 3.5a–3.5e complete. 3.5f (Testing & Iteration) in progress — items 1, 6, 7, and 8 complete.*
