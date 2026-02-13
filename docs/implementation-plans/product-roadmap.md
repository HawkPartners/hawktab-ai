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
- Make agent debugging easier — every agent's tool calls and scratchpad output should be captured in a single accessible location for post-run inspection (context graphs)

### Additional Feedback (from voice notes)

> Parsed from voice-to-text notes. Items that overlap with the Ongoing Feedback Log above are noted as "*(see above)*" rather than duplicated.

**Configuration & Project Settings**
- Audit how banner plan hints and research objectives are currently passed into the pipeline — confirm they're working as expected
- Confirm all configuration options Antares asked about are present and surfaced in the UI
- Hide configuration options that aren't actionable for users — reduce noise
- Allow Excel file regeneration without a full pipeline re-run (e.g., changing theme or toggling excluded tables)
- Professional naming scheme overall — project name as filename *(see above)*, but also project identifiers and labels throughout the UI

**Transparency & Interpretability**
- Add a page or section explaining the assumptions the pipeline made — in plain, non-technical language
- Explain how banner cuts are constructed and how to interpret them (especially for clients like Tito's where cuts may be less intuitive)
- Show base sizes per cut and how they change — consider making this interactive
- Include a subtle disclaimer (e.g., "validate base sizes as you see fit") — not heavy-handed, just present
- General principle: always surface what happened and why, written for non-technical readers

**Error Handling & Recovery**
- Classify pipeline failures: validation issue (our bug) vs. transient/hallucination error (rerunnable)
- Tailor error messages accordingly — if the failure is transient, offer a "Rerun pipeline" button in the UI
- If the failure is a real bug, show a clear error state without the rerun option

**Concurrency & Performance**
- Test whether multiple pipelines can run simultaneously for different projects
- Consider a "faster mode" that increases agent concurrency from 3 to 5 where applicable
- Add broader-level configuration for AI reasoning effort (not just per-agent in `.env`)

**Automated Testing & CI/CD**
- Build a dev-mode batch testing feature in the UI: a button that loads test datasets from R2 (or a `dev-test` folder) and runs them through the pipeline sequentially, simulating real user uploads
- Should skip HITL review and test the system under realistic load (as if 15 different users uploaded at different times)
- Consider concurrency of 5 for batch testing to stress-test the system and speed up test cycles
- Cost awareness: batch runs cost ~$28–30 each — also explore cheaper test methods that achieve similar coverage without full AI calls
- Playwright for automated UI/E2E testing — more feasible for a Next.js app than mobile
- Eventually build toward a CI/CD pipeline that includes these automated checks

**Security**
- Conduct another security audit after feature freeze — new API routes have been added since the last audit
- Research the risk profile specific to deployed web apps vs. mobile apps

**Developer Documentation**
- Revisit `CLAUDE.md` to reinforce: "follow established codebase patterns before defaulting to training-data conventions" — cover not just security but Convex patterns, API layer usage, etc.
- Document the three `.env` files (`.env.local`, `.env.dev`, `.env.prod`) and their purposes in both `README.md` and `CLAUDE.md`
- Document the deployment flow: `dev` branch (feature work) → `staging` branch (Railway auto-deploys, cloud testing) → `production`

**Feedback System**
- Verify end-to-end behavior when a user submits feedback — confirm it's captured, stored, and surfaced correctly

**Future Features**
- Revisit `future-features.md` to identify items that could realistically be tackled before the Antares deadline

**Already Captured Above**
- Duration display format on project detail page *(see Pipeline Progress & Status)*
- Icon/emoji cleanup for a more premium feel *(see UI Polish & Design System)*
- Project search functionality — confirmed working, no action needed

---

## MVP Complete

Completing Phase 3.5 (a through e) = MVP = The Product. Antares logs in, uploads files, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs.

Phase 3.5f is polish and bug fixes to ensure the MVP is solid for real users.

Future features, deferred items, and known gaps/limitations are documented in [`future-features.md`](./future-features.md).

---

*Created: January 22, 2026*
*Updated: February 13, 2026*
*Status: Phase 3 (Productization) in progress. 3.1–3.4, 3.5a–3.5e complete. 3.5f (Testing & Iteration) in progress — items 1, 6, 7, and 8 complete.*
