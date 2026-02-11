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
| **3.1** Cloud Infrastructure Setup | Convex, R2, WorkOS, Docker/Railway | Not Started |
| **3.2** Pipeline Cloud Migration | Wire orchestrator to Convex/R2, new API routes, deprecate old | Not Started |
| **3.3** New Project Experience | Multi-step wizard exposing all pipeline features in UI | Not Started |
| **3.4** Dashboard & Supportability | Real-time dashboard, debug bundles, error visibility | Not Started |
| **3.5** Deploy & Launch | Railway deployment, DNS, landing page, Sentry | Not Started |

---

## Phase 3: Productization

### Current State (UI Foundation — Complete)

The UI foundation is in place. Route groups, app shell, and API refactoring were completed as Phase A of the UI overhaul (see `ui-overhaul-plan.md`).

**What exists now:**
- Next.js app with `(marketing)/` and `(product)/` route groups
- App shell: collapsible sidebar with navigation + recent projects, header with branding, breadcrumbs on all pages
- Pages: dashboard (project list), new project (upload form), project detail (status + downloads), HITL review (crosstab cut validation), settings (placeholder)
- Providers: `ProjectProvider` (active project/job tracking), `PipelineStatusProvider` (subscription-based polling)
- Hooks: `useJobPolling`, `useJobRecovery`, `useLoopDetection`, `useValidationQueue`
- API refactored: `process-crosstab/route.ts` down from 1,312 → 137 lines, extracted to `pipelineOrchestrator.ts`, `hitlManager.ts`, `fileHandler.ts`
- Old `/pipelines/[pipelineId]` URLs redirect to `/projects/[projectId]`

**What's missing:**
- No auth (anyone can access everything)
- No cloud hosting (runs on `localhost:3000`)
- No persistent job tracking (in-memory Map, lost on restart)
- No project configuration wizard (upload form is flat, doesn't expose pipeline features like themes, stat testing, weights)
- No multi-tenancy (no org-scoping)

---

### 3.1 Cloud Infrastructure Setup — `COMPLETE`

Set up the cloud services that everything else builds on. No UI features — just the foundation.

> **Status**: Complete. Convex deployed (project: `crosstab-ai`, deployment: `fortunate-rat-800`), schema + indexes live, dev data seeded. R2 bucket configured. WorkOS env vars set with `AUTH_BYPASS=true`. Health check passing.

| Service | Purpose | Why This One |
|---------|---------|--------------|
| **Convex** | Database + real-time subscriptions | TypeScript-native, `npx convex dev` for local dev, real-time built-in (replaces polling) |
| **Cloudflare R2** | File storage (uploads, pipeline outputs) | S3-compatible, no egress fees, dev/prod buckets |
| **WorkOS** | Auth + org management | Free for 1M MAUs, hosted login UI, SSO/SAML when needed, org management built-in |
| **Railway** | Docker container for pipeline execution | Supports long-running processes, Node + R in one container |

**Convex schema** (core tables):

| Table | Key Fields | Purpose |
|-------|------------|---------|
| `organizations` | `orgId`, `name`, `slug` | Multi-tenancy scoping (synced from WorkOS) |
| `users` | `userId`, `email`, `name` | User records (synced from WorkOS on first login) |
| `orgMemberships` | `userId`, `orgId`, `role` | Who belongs to which org, with what permissions |
| `projects` | `projectId`, `orgId`, `name`, `projectType`, `config`, `intake`, `fileKeys` | Project records — the user-facing container |
| `runs` | `runId`, `projectId`, `orgId`, `status`, `stage`, `progress`, `config`, `result`, `error` | Pipeline execution records — replaces in-memory jobStore |

**Auth (WorkOS)**:
- `@workos-inc/authkit-nextjs` for session management
- `src/middleware.ts` protecting `(product)/` routes and `/api/*`
- Hosted login UI — we don't build auth pages, WorkOS handles it
- `AUTH_BYPASS=true` env var for local development (hardcoded dev user/org)
- Org selector in AppHeader when user belongs to multiple orgs

**Roles**:

| Role | Can Do |
|------|--------|
| Admin | Create projects, invite members, manage org settings, view all projects |
| Member | Create projects, view own projects, view shared projects |
| External Partner | View projects explicitly shared with them, download results |

**R2 file organization**: `{orgId}/{projectId}/{runId}/{filename}` — scoped for multi-tenancy by construction.

**Docker container** (Railway):
- Base image with Node.js + R + haven package
- Same codebase as local dev — just different environment variables pointing at cloud services
- Pipeline runs in-process (same as today, not a separate worker — simplest architecture for MVP)

**Deliverables**: Convex project with schema + dev environment running. R2 bucket created. WorkOS sandbox configured. Dockerfile that builds and runs locally. All services accessible from `npm run dev`.

**Level of Effort**: Medium (setup + schema design + WorkOS wiring + Docker)

---

### 3.2 Pipeline Cloud Migration — `NOT STARTED`

Wire the pipeline orchestrator and API routes to use Convex and R2 instead of in-memory state and filesystem scanning.

**What changes:**

1. **Job tracking → Convex** (replaces in-memory `Map<string, JobStatus>`):
   - `pipelineOrchestrator.ts` writes status updates to Convex `runs` table instead of calling `updateJob()`
   - Status polling replaced by Convex real-time subscriptions (no more `setInterval` every 5s)
   - Jobs survive server restarts — Convex is the source of truth
   - Cancellation: set `cancelRequested: true` in Convex + in-memory AbortController for the running process

2. **File storage → R2**:
   - Uploaded files stored in R2 at `{orgId}/{projectId}/inputs/{filename}`
   - Pipeline downloads files from R2 to local temp dir for R execution (R needs filesystem paths)
   - Pipeline outputs (Excel, tables.json, R script) uploaded back to R2 after completion
   - Downloads use signed R2 URLs (time-limited, org-scoped)

3. **Project/run metadata → Convex** (replaces `pipeline-summary.json` filesystem scanning):
   - `GET /api/pipelines` (filesystem scan) → Convex query on `runs` table filtered by `orgId`
   - Project detail, HITL review state, feedback — all in Convex

4. **New API routes** (alongside old, which get `@deprecated` markers):

| New Route | Replaces | Purpose |
|-----------|----------|---------|
| `POST /api/projects` | — | Create project record in Convex |
| `POST /api/projects/:id/files` | Part of `process-crosstab` | Upload files to R2 |
| `POST /api/projects/:id/runs` | `POST /api/process-crosstab` | Start pipeline run |
| `GET /api/runs/:id` | `GET /api/process-crosstab/status` | Get run status (Convex query) |
| `POST /api/runs/:id/cancel` | `POST /api/pipelines/:id/cancel` | Cancel run |
| `GET/POST /api/runs/:id/review` | `GET/POST /api/pipelines/:id/review` | HITL review |

5. **Old routes deprecated** (not removed — UI still uses them until 3.3/3.4 rebuild):
   - Every old route gets `@deprecated` JSDoc pointing to its replacement
   - Extract duplicated `findPipelineDir()` into shared utility while we're touching these files

6. **CLI unchanged**: `test-pipeline.ts` and `batch-pipeline.ts` write directly to filesystem — they don't go through the API layer and don't need to change.

**R execution constraint**: R needs local filesystem paths. The pipeline downloads input files from R2 to a temp directory, runs R against local files, then uploads results back to R2. This is handled in the orchestrator — the API routes never touch the filesystem.

**Security**:
- All Convex queries filter by `orgId` — no cross-org data leakage
- R2 keys scoped by `orgId/projectId` — org isolation by construction
- File uploads validated server-side (types, sizes)
- Signed URLs for downloads (time-limited)
- Input validation with Zod on all API routes

**Deliverables**: Pipeline runs against Convex + R2. Jobs persist across restarts. Old routes deprecated with clear markers. New routes functional. UI still works via old routes (migration in next phases).

**Level of Effort**: High (orchestrator refactor + new routes + R2 integration + Convex mutations)

---

### 3.3 New Project Experience — `NOT STARTED`

Replace the flat upload form with a multi-step wizard that exposes all pipeline configuration options. This is where every pipeline feature gets a UI surface.

**Wizard flow**: `Step 1: Upload Files → Step 2: Project Setup → Step 3: Configuration → Step 4: Review & Launch`

**Step 1 — Upload Files**:
- Data file (.sav) — required. Helper text: "Qualified respondents only."
- Survey document (PDF, DOCX) — required
- Banner plan (PDF, DOCX) — optional (if not provided, Step 2 activates AI-generated banner flow)
- On .sav upload: trigger loop detection + weight candidate detection

**Step 2 — Project Setup**:
- Project name (auto-suggested from data file)
- Project type select: Standard, ATU, Segmentation, MaxDiff, Demand, Concept Test, Tracking
- Conditional questions per type:
  - **Segmentation**: "Does your data include segment assignments?"
  - **MaxDiff**: "Upload message list?" + "Anchored probability scores?"
  - **Conjoint/DCM**: "Upload choice task definitions?"
- If no banner plan: research objectives text area + cut suggestions text area → AI-generated banner flow

**Step 3 — Configuration** (all pipeline features):

| Setting | Control | Default |
|---------|---------|---------|
| Display mode | Radio: Percentages / Counts / Both | Percentages |
| Separate workbooks | Toggle (visible when Both) | Off |
| Color theme | Theme picker with 6 swatches | Classic |
| Stat testing thresholds | Numeric input(s) | 90% |
| Min base size | Number input | 0 |
| Proportion test | Select | Unpooled z-test |
| Mean test | Select | Welch's t-test |
| Weight variable | Select from detected candidates | Off |
| Loop stat testing | Radio: Suppress / Complement (visible when loops detected) | Suppress |
| Stop after verification | Toggle (advanced, collapsed) | Off |

**Step 4 — Review & Launch**:
- Summary of all selections
- "Launch Pipeline" → creates project in Convex, uploads files to R2, starts run

**Variable selection persistence** (deterministic re-runs):
- When a user confirms cut mappings via HITL or accepts a successful run, lock those selections in Convex
- On re-run, CrosstabAgent prompt includes "locked selections" — these variables are not re-evaluated
- Eliminates "it worked last time but not this time"

**API changes**: `POST /api/projects/:id/runs` accepts all configuration options. The orchestrator passes them to `PipelineRunner.runPipeline()` — same function the CLI calls. No pipeline logic changes needed.

**Deliverables**: 4-step wizard. All pipeline features exposed. Project type intake questions. AI banner flow. Variable selection persistence. Writes to Convex + R2.

**Level of Effort**: High (multi-step wizard + all config surfaces + API extensions)

---

### 3.4 Dashboard, Results & Supportability — `NOT STARTED`

Build the project management experience — where users see their projects, track progress, and download results.

**Dashboard** (`(product)/dashboard/`):
- Project list from Convex (real-time — no polling, Convex subscriptions)
- Columns: Project Name, Status, Tables, Created, Duration, Actions
- Sort, filter by status, search by name
- Empty state with "Create New Project" CTA

**Enhanced Project Detail** (`(product)/projects/[projectId]/`):
- Status bar with pipeline stage + action buttons (Download, Review, Re-run, Cancel)
- Pipeline progress timeline (visual stage-by-stage, replaces toast-based polling):
  ```
  ✅ Files uploaded → ✅ Banner analyzed → ⏳ Table generation → ⬜ Verification → ⬜ Excel
  ```
- Results section: summary cards (tables, cuts, groups, duration, cost), download buttons
- Configuration summary (what settings were used)
- If weighted: separate download buttons for weighted/unweighted
- If separate workbooks: separate download buttons

**Re-run support**:
- Pre-populate wizard Step 3 with previous run's settings
- Allow swapping data file (interim → final workflow)
- Re-uses persisted cut mappings for deterministic results
- Previous runs visible in "Run History" section

**Supportability** (when things break for Antares):
- **Debug bundle**: single zip per run containing pipeline-summary.json, errors.ndjson, scratchpad files, R script, event log
- **Error visibility**: agent/pipeline errors surfaced on project detail page in plain language, not buried in disappeared toasts
- **"Download Debug Bundle"** button on project detail page

**Cost tracking persistence** (folded in here — not a separate phase):
- `AgentMetricsCollector` already tracks per-call costs
- Write to Convex `aiUsage` table at pipeline completion
- No dashboard for MVP — query Convex directly

**Deliverables**: Real-time dashboard, enhanced results page, progress timeline, re-run, debug bundles, error visibility, cost persistence.

**Level of Effort**: High (dashboard + results rebuild + progress timeline + debug bundle + cost persistence)

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

**Completing Phase 3.5 = MVP = The Product.**

At this point, CrossTab AI is a cloud-hosted, authenticated service. Antares logs in, uploads their .sav + banner plan, configures their project, runs the pipeline, reviews HITL decisions, and downloads publication-ready crosstabs — without touching a terminal or asking us for help.

The path from here to MVP is: infrastructure (3.1) → migration (3.2) → wizard (3.3) → dashboard (3.4) → deploy (3.5). Each phase is independently testable. Detailed implementation plans are created per-phase before building.

---

## Long-term Vision

---

### Post-MVP: Message Testing & MaxDiff — `DEFERRED`

**Goal**: Support message testing surveys (and MaxDiff studies with utility scores) by allowing users to upload message lists that get integrated into the datamap.

**Why deferred**: Requires intake form updates, file parsing logic, and datamap enrichment infrastructure. Important feature but not blocking the Antares pilot.

**What's needed**:
- Intake question: "Does this survey include messages?" → upload message list
- Message file parsing (Excel preferred, Word supported)
- Datamap enrichment: link message text to question variables
- Agent awareness: VerificationAgent uses actual message text in table labels

**Level of Effort**: Medium. Prioritize post-MVP based on Antares feedback.

---

Bob's observation from the Antares conversation: *"I've not seen anybody kind of going down this road... commercially speaking."*

What makes CrossTab unique is the **validated data foundation**. Every crosstab run produces artifacts that already executed successfully—verified variables, working R expressions, human-approved cuts. This foundation could eventually support follow-up queries and conversational exploration without the hallucination problems that plague other AI-on-data tools.

But that only matters if the core system is reliable. That's what we're focused on now.

### Configurable Assumptions & Regeneration

CrossTab makes defensible statistical assumptions when generating crosstabs — particularly for looped/stacked data. These assumptions are specific choices from a finite set of valid approaches:

**Example: Needs State on stacked occasion tables**

The system defaults to entity-anchored aliasing — each occasion is evaluated against its own needs state variable, producing a clean partition (852 C/B occasions, not the inflated 1,409 from naive OR logic). But there are other defensible approaches:

| Approach | What it does | When you'd want it |
|----------|-------------|-------------------|
| **Entity-anchored alias** (our default) | Each occasion checks only its own needs state | You want occasion-level precision — "what happens during C/B occasions" |
| **First-iteration only** (Joe's approach) | Only use S10a (occasion 1) for all cuts | You want simplicity and are okay losing occasion 2 data |
| **Respondent-level OR** (naive approach) | `(S10a == 1 \| S11a == 1)` on stacked frame | You want "all occasions from respondents who had ANY C/B occasion" — different question, still valid if intentional |

None of these are wrong in absolute terms. They answer different questions. The problem is when the system silently uses one approach and the user assumes another.

**The vision:** Users receive crosstabs generated with our defaults (which we believe are the most statistically precise). Alongside the output, a Methodology sheet documents every assumption. If a user disagrees with an assumption, they can select an alternative from the finite set of defensible options and regenerate. The system re-runs R with the new configuration — no re-running agents, just swapping the alias/cut strategy.

**What this requires:**
- Assumptions surfaced in plain language (Methodology sheet)
- A mapping of each assumption to its alternatives (schema-driven, not free-form)
- A regeneration path that re-runs R script generation + execution without re-running the full pipeline
- The resume script (`test-loop-semantics-resume.ts`) is already a prototype of this pattern

**Why this matters commercially:** No other tool in this space surfaces its assumptions, let alone lets you change them. WinCross, SPSS Tables, and Q all make implicit choices that users can't inspect or override. Making assumptions explicit and configurable is a differentiator that builds trust with sophisticated research buyers.

This is a long-term feature — the foundation (correct defaults + validation proof) comes first.

---

### Predictive Confidence Scoring (Pre-Flight)

The idea: before running the full pipeline (45+ minutes), assess whether the system can handle a given dataset and flag issues upfront. A three-tier assessment (green/yellow/red) that tells users "we're confident," "proceed with caution," or "we can't handle this reliably."

**Why it's long-term, not now:** Most pipeline failures come from AI agent behavior (BannerAgent misreading a format, CrosstabAgent picking wrong variables, VerificationAgent making bad table decisions) — not from data characteristics we can measure upfront. You can't predict whether an agent will succeed on *this specific* banner plan without running it. Building a predictor now would produce either false assurance or meaningless noise.

**What's needed to make this real:**
- 50+ dataset runs with documented failure modes and root causes
- Enough signal to correlate data characteristics (variable complexity, naming patterns, loop structure) with actual pipeline outcomes
- Statistical evidence that pre-flight signals actually predict success/failure

**Signals that could eventually feed this** (all exist today but aren't predictive yet):
- Loop detection: iteration counts, fill rates, variable family completeness
- Deterministic resolver: evidence strength for iteration-linked variables
- Data map quality: percentage of variables with value labels, description completeness
- Variable count and complexity: hidden/admin variable ratios, naming consistency

**When to revisit:** After we have failure data across 20+ datasets with diverse characteristics. If clear patterns emerge (e.g., "datasets with no deterministic resolver evidence fail 80% of the time"), then a predictor becomes viable.

---

### Variable Selection Persistence — `IN PHASE 3.3`

The crosstab agent's variable selection is non-deterministic — same dataset can produce different variable mappings across runs. Once a user confirms a mapping via HITL or accepts a successful run's output, lock those selections as project-level overrides so future re-runs don't re-roll the dice.

**What gets saved:** Banner group name → variable mappings, confirmation source ("user_confirmed" or "accepted_from_run_N"). Stored as `confirmed-cuts.json` in the project folder. The crosstab agent prompt includes a "locked selections" section — variables in this list are not re-evaluated.

**Why it matters:** Eliminates "it worked last time but not this time." First step toward accumulating project-level knowledge across runs.

**Level of Effort:** Low (JSON persistence + prompt section, no architectural changes)

---

### Interactive Table Review

**The vision:** After a pipeline run completes, the user opens an interactive review in the browser — not a static Excel file. They see every table rendered as HTML, can toggle tables on/off, leave feedback on specific tables, request targeted regeneration, and only generate the final Excel when they're satisfied with the output.

This is the post-MVP experience that replaces the current workflow of: download Excel → review in Excel → note issues → request full re-run.

**Why it matters:** Users like Antares are used to working in Q, where they can iterate on individual tables. Giving them a static Excel with no way to adjust without re-running the full 45-minute pipeline is friction. This feature closes the gap — not by replicating Q, but by giving users control over the output they already have.

**The full workflow:**

1. **Pipeline completes** → user gets a notification (email, in-app, or browser tab)
2. **Open interactive review** (`/projects/[id]/review`) — tables rendered in a scrollable browser view
   - Collapsible sections by question group
   - Each table shows its table ID, base sizes, and a visual that closely matches the Excel styling
   - Tables already have `tableId`, `excluded`, `excludeReason` in the schema — this is the data model
3. **Per-table actions:**
   - **Include/Exclude toggle** — instant visual feedback. Excluded tables dim or move to a separate "Excluded" section. Tables on the excluded list can be pulled back in. No backend call until the user commits.
   - **Feedback note** — free-text per table: "Show top 3 box instead of top 2" or "Combine these rows into a single NET." Stored as metadata on the table.
   - **Request regeneration** — for tables with feedback, trigger a targeted re-run through the VerificationAgent with the feedback appended to context. Agent produces an updated table with the same table ID. Only that table is re-processed — not the full pipeline.
4. **Review summary** — before generating, show a summary: "12 tables included, 3 excluded, 2 regenerated with feedback."
5. **"Generate Final Excel"** — applies all include/exclude decisions and regenerated tables, produces the final workbook for download.

**What makes this feasible (foundations already exist):**

| Foundation | Status | What It Enables |
|-----------|--------|-----------------|
| `tables.json` with full table data | Done | Render tables in browser from structured data |
| Table IDs in Excel output | Done | Users can reference specific tables |
| `excluded` / `excludeReason` schema fields | Done | Toggle tables between included/excluded |
| VerificationAgent | Done | Re-run individual tables with feedback context |
| HITL review UI (cut validation) | Done | State management pattern, collapsible sections |
| ExcelJS for workbook generation | Done | Potentially render Excel-like views in browser |

**What needs building:**

| Component | Effort | Notes |
|-----------|--------|-------|
| Table preview component (HTML rendering of `tables.json`) | Medium | Style to approximate Excel output. Doesn't need to be pixel-perfect. |
| Per-table state management (include/exclude/feedback) | Low | Pattern exists in HITL review. Local state until "Generate" clicked. |
| Targeted regeneration (VerificationAgent re-invocation) | Medium | Re-run one table with feedback appended. Splice updated table back into `tables.json`. |
| Excel regeneration from modified `tables.json` | Low | ExcelFormatter already takes `tables.json` as input. Just pass the modified version. |
| Route: `/projects/[id]/review` | Low | New page in `(product)/` route group. |

**Constraints on targeted regeneration:**
- Feedback is scoped to what the VerificationAgent can control: row labels, NETs, derived rows, exclusions, groupings
- Can't change underlying data or banner structure — that requires a full re-run
- This is constrained editing, not free-form data exploration

**When to build:** After MVP delivery and initial Antares feedback. This is the kind of feature that's best informed by real usage — what do users actually want to change after seeing output? Build it once we have that signal.

---

### Dual-Mode Loop Semantics Prompt

The Loop Semantics Policy Agent uses a single prompt regardless of how much deterministic evidence is available. When the resolver finds strong evidence, the prompt works well. When there's none, the LLM must infer from cut patterns and datamap descriptions alone — harder and less reliable.

**Solution:** Two prompt variants selected automatically based on `deterministicFindings.iterationLinkedVariables.length`. High-evidence prompt anchors on resolver data. Low-evidence prompt adds pattern-matching guidance for OR expressions, emphasizes datamap descriptions, lowers confidence thresholds for `humanReviewRequired`, and includes more few-shot examples.

**Level of Effort:** Low (second prompt file in `src/prompts/loopSemantics/alternative.ts` + selection logic in agent)

**When to revisit:** If batch testing reveals classification failures on datasets where the deterministic resolver finds nothing.

---

## Known Gaps & Limitations

Documented as of February 2026. These are areas where the system has known limitations — some with mitigation paths already identified, others that may define the boundary of what CrossTab can handle. Even where solutions exist, it's important to be aware of these when communicating capabilities externally or testing against new datasets.

### Loop Semantics

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No deterministic evidence** — SPSS file has no label tokens, suffix patterns, or sibling descriptions. LLM must infer entirely from cut patterns and datamap context. | Medium | Dual-mode prompt (see Long-term Vision). Long-term: predictive confidence scoring. | Identified, not implemented |
| **Irregular parallel variable naming** — Occasion 1 uses Q5a, occasion 2 uses Q7b, occasion 3 uses Q12. No naming relationship. Resolver can't match. | Medium | LLM prompt must handle this from datamap descriptions. Few-shot examples for irregular naming. Some surveys may be unfixable without user hints. | Partially mitigated by LLM |
| **Complex expression transformation** — `transformCutForAlias` handles `==`, `%in%`, and OR patterns. Expressions with `&` conditions, nested logic, or negations could break transformation. | Low-Medium | Expand transformer for common compound patterns. Flag untransformable expressions for human review. | Common cases handled |
| **Multiple independent loop groups** — Dataset with both an occasion loop AND a brand loop. Architecturally supported but never tested. | Low | Schema and pipeline support N loop groups. Needs integration testing with a real multi-loop dataset. | Untested |
| **Nested loops** — A brand loop inside an occasion loop. Not handled. | Low | Not supported. Validation already detects loops; nested loop detection could be added as a basic sanity check. | Not supported |
| **Weighted stacked data** — Weights exist in the data but aren't applied during stacking or computation. | ~~High~~ | Implemented. Weight column carries through `bind_rows` in stacked frames. Manual weighted formulas with effective n for sig testing. | Complete |
| **No clustered standard errors** — Stacked rows from the same respondent are correlated, which overstates significance. Standard tests treat them as independent. This is industry-standard behavior (WinCross, SPSS Tables, Q all do the same). | Low | Accept as industry-standard limitation. Future differentiator if implemented. Would require respondent ID column in stacked frame + cluster-robust R functions. | Known limitation, not planned |
| **No within-group stat letter suppression for entity-anchored groups** — `generateSignificanceTesting()` didn't consult the loop semantics policy. Within-group pairwise comparisons ran for all groups regardless of overlap. Validation detected overlaps but didn't act on them. | Medium | Implemented — suppress or vs-complement testing for entity-anchored groups. | Complete |

### Crosstab Agent

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **Non-deterministic variable selection** — Same dataset can produce different variable mappings across runs. | Medium | Hidden variable hints help steer. Variable selection persistence (Phase 3.3) locks in confirmed choices. HITL for low-confidence cuts. | Partially mitigated |
| **Hidden variable conventions vary by platform** — h-prefix and d-prefix patterns are Decipher/FocusVision conventions. Other platforms (Qualtrics, SurveyMonkey, Confirmit) use different naming. | Low-Medium | Expand hint patterns as we encounter new platforms. The datamap description is platform-agnostic and usually contains enough signal. | Platform-specific hints added |
| **Overlapping banner cuts (non-loop)** — If a user provides overlapping respondent-anchored cuts, pairwise A-vs-B letters still run even when overlap makes comparisons questionable. | Medium | Consider optional suppression or complement testing for overlapping groups if demand warrants it. | Known limitation |

### General Pipeline

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No pre-flight confidence assessment** — Pipeline runs for 45+ minutes before discovering it can't handle a dataset reliably. | Medium-High | Long-term: predictive confidence scoring (see Long-term Vision). Requires failure data across 50+ datasets before a predictor is viable. Near-term: project intake questions (3.3) set expectations upfront. | Deferred to Long-term Vision |
| **No methodology documentation in output** — Users receive numbers without explanation of how they were computed. Assumptions are implicit. | Medium | Methodology sheet in Excel (Configurable Assumptions vision). Policy agent + validation results provide the content. | Planned |
| **No project-level knowledge accumulation** — Each pipeline run starts fresh. Confirmed variable mappings, user preferences, and past decisions aren't carried forward. | Low-Medium | Variable selection persistence (Phase 3.3) is the first step. Longer-term: project-level config that accumulates across runs. | Identified |
| **Hidden assignment variables don't produce distribution tables** — When a question's answers are stored as hidden variables (e.g., `hLOCATIONr1–r16` for S9), the pipeline correctly hides them but misses the distribution table that shows assignment frequency. Requires parent-variable linking in DataMapProcessor or verification agent awareness. | Low | Accept gap for now. Future: detect when hidden variable families relate to a visible question and auto-generate distribution tables. | Known limitation |
| **No dual-base reporting for skip logic questions** — When a question has skip logic, only the filtered base is reported. An experienced analyst might also report the same table with an all-respondents base for context (e.g., "what share of everyone had 2+ people present" vs "among those not alone, group size distribution"). Current behavior is correct; this is a future quality-of-life enhancement. | Low | Future: optional "also report unfiltered" flag on skip logic tables, generating both versions with clear base text. | Known limitation |
| **`deriveBaseParent()` doesn't collapse parent references for loop variables** — In LoopCollapser.ts, when a collapsed variable's parent is itself a loop variable being collapsed, `deriveBaseParent()` returns the uncollapsed parent name (e.g., `A7_1` instead of `A7`). DataMapGrouper then uses this uncollapsed parent as the `questionId`, causing loop variables like A7 to appear with inconsistent naming (e.g., `a7_1` instead of `a7`). Non-loop parents like A4 are unaffected. | Low | Fix `deriveBaseParent()` to check if the derived parent is in the collapse map and resolve it to the collapsed form. Straightforward code fix. | Known limitation |
| **No Excel or TXT input support** — Survey and banner plan inputs only accept PDF and DOCX. Excel banner plans (sometimes sent by clients) and TXT files are not supported. Users must export/convert to PDF or DOCX before uploading. | Low | Could add Excel parsing + structure detection for banner plans if demand warrants it. TXT is unlikely to be needed. | By design |

---

*Created: January 22, 2026*
*Updated: February 11, 2026*
*Status: Reliability, features, and UI foundation complete. Phase 3 (Productization) in progress — cloud-first approach.*
