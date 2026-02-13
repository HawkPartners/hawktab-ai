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

> Items below are raw feedback captured during testing. As issues are confirmed and scoped, they get promoted to numbered items above or filed as new work items.

 - still bit auto-routing from review page to product page when i press "Save & Continue" Now the timeline issue is fixed but the auto-routing issue is still present
 - human readable time instead of 921 seconds; shows properly on project view but not in the project specific page
 - strip the overuse of non clean icons; follow the design system and think B2B
 - we show too much information after a loop is shown; we only need to show that loop was detected and we will stack the data for you (maybe show what was stacked (but only if users changing it has impact and/or maybe we show it at the end of the pipeline)
 need loading indicator for once someone starts a pipeline run; maybe a spinning circle or a progress bar (so they dont think the app is stuck)
 - ensure pipeline percentage shown is actually accurate (it sits at 50% for a long time)
 add notifcation through email when pipeline is complete (or failed)
 - given any agents provide confidennce how many hitl reviews should we have?
 - use the project name as the crosstab file name, appended by date and other necessary information
 - add configuration to not show excluded tabe=les as a sheet in the excel file (default to show)
 - make debugging scratchpad easier and just debug agen =t behavior (every agent call tool calls cratch pod output should be captured somewhere so we can better debug)

---

## MVP Complete

Completing Phase 3.5 (a through e) = MVP = The Product. Antares logs in, uploads files, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs.

Phase 3.5f is polish and bug fixes to ensure the MVP is solid for real users.

Future features, deferred items, and known gaps/limitations are documented in [`future-features.md`](./future-features.md).

---

*Created: January 22, 2026*
*Updated: February 12, 2026*
*Status: Phase 3 (Productization) in progress. 3.1–3.4, 3.5a–3.5e complete. 3.5f (Testing & Iteration) in progress — items 1, 6, 7, and 8 complete.*
