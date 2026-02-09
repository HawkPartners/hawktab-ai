# Product Roadmap: Reliability → Production

## Overview

This document outlines the path from HawkTab AI's current state (reliable local pipeline) to a production product that external parties like Antares could use.

**Current State**: Pipeline working end-to-end locally. Reliability validation in progress.

**Target State**: Cloud-hosted service with multi-tenant support, configurable output options, and self-service UI.

**Philosophy**: Ship incrementally. Each phase delivers usable value while building toward the full vision.

---

### Implementation Status Summary (Feb 8, 2026)

| Item | Status | Notes |
|------|--------|-------|
| **Phase 1.1** Stable System | Complete | R validation, retry logic, per-table isolation |
| **Phase 1.2** Leqvio Dataset | Complete | 3 edge cases documented |
| **Phase 1.3** Loop/Stacked Data | Complete | Full deterministic resolver + semantics agent |
| **Phase 1.4** Broader Testing | In Progress | 11 datasets, batch runner operational |
| **Phase 1.5** ~~Pre-Flight Confidence~~ | Reorganized | Intake questions → 3.1; predictive scoring → Long-term Vision |
| **Phase 2.1** Output Formats | Complete | frequency, counts, both (same workbook or separate) |
| **Phase 2.4** Stat Testing Config | Complete | Env vars, pipeline summary, `--show-defaults` |
| **Phase 2.4b** Loop-Aware Stat Testing | Not Started | Suppress (default) or vs-complement for entity-anchored groups |
| **Phase 2.4c** Variable Persistence | Deferred | Moved to Long-term Vision |
| **Phase 2.4d** Dual-Mode Loop Prompt | Deferred | Moved to Long-term Vision |
| **Phase 2.5** Upfront Context | Consolidated | Merged into 3.1 (Project Intake Questions) |
| **Phase 2.5a** Input Flexibility | Complete | PDF/DOCX for survey + banner; .sav for data |
| **Phase 2.5b** AI-Generated Banner | Not Started | Deferred post-MVP |
| **Phase 2.6** Weight Detection | Not Started | No detection, no R integration |
| **Phase 2.7** Survey Classification | Not Started | No type detection or confidence scoring |
| **Phase 2.8** Sample Size in HITL | Partial | HITL UI exists; base sizes missing |
| **Phase 2.9** Table ID + Exclude | Partial | IDs render, excluded sheet works; no regeneration control |
| **Phase 2.10** Table Feedback | Not Started | No per-table feedback or regeneration |
| **Phase 2.11** Excel Themes | Not Started | Single hardcoded palette |
| **Phase 2.12** Browser Review | Partial (foundation) | Crosstab review UI exists; table review missing |
| **Phase 3.1** Local UI | Partial (~40%) | Basic pipeline UI; no enterprise structure |
| **Phase 3.2** Cloud Deployment | Not Started | No Convex/R2/Railway/Sentry/PostHog |
| **Phase 3.3** Auth (WorkOS) | Not Started | Zero authentication |
| **Phase 3.4** Cost Tracking | Partial (~30%) | Metrics collected, not persisted |
| **Phase 3.5** Logging | Minimal (~20%) | Basic tracing scaffold only |

**Also verified as implemented (not separate roadmap items):**
- TablePostProcessor: 8 deterministic rules (exceeds the 7 specified)
- Provenance tracking: `sourceTableId`, `splitFromTableId`, `lastModifiedBy` all in schemas
- SkipLogicAgent + FilterTranslatorAgent: Fully functional
- LoopDetector + LoopContextResolver + LoopCollapser: Fully functional
- Batch pipeline runner with cross-dataset analytics

---

## Phase 1: Reliability (Current)

*See `reliability-plan.md` for details*

| Part | Description | Status |
|------|-------------|--------|
| 1 | Stable System for Testing (R validation, bug fixes, retry logic) | Complete |
| 2 | Finalize Leqvio Dataset (golden datasets, 3x consistency runs) | Complete |
| 3 | Loop/Stacked Data + Weights (Tito's dataset) | Complete |
| 4 | Strategic Broader Testing (5 datasets across survey types) | In Progress |

**Exit Criteria**: 5 datasets producing consistent output across 3 runs each, output quality acceptable for report writing.

### ~~1.5 Pipeline Confidence Pre-Flight~~ — `REORGANIZED`

> **Decision (Feb 8, 2026):** This item originally combined two different ideas that have been separated:
>
> 1. **Intake questions** (asking users about project type, missing files, etc.) — moved to **3.1** as part of the New Project Flow. This is a UI/UX concern that belongs in the upload experience, not a pipeline pre-check.
>
> 2. **Predictive confidence scoring** (can the pipeline handle this dataset?) — moved to **Long-term Vision**. We don't yet have enough failure data across datasets to build a reliable predictor. Most pipeline failures come from AI agent behavior, not data characteristics — and you can't predict agent success without running the agents. Premature confidence tiers would either give false assurance (green on a dataset that fails) or meaningless noise (yellow on everything). Revisit after 50+ dataset runs with documented failure modes.
>
> The basic sanity checks that already exist (validation catches corrupt data, loop detection flags structural issues) continue to run as part of the pipeline. No new work needed in Phase 1.

---

## Phase 2: Feature Completeness

Features needed before external users can rely on the system for real projects.

### 2.1 Output Format Options — `COMPLETE`

**Percents Only / Frequencies Only**

Bob asked: "Is it possible to add in an option to say I only want percents or frequencies?"

| Option | What It Shows |
|--------|---------------|
| Both (default) | Count and percentage in each cell |
| Percents only | Just percentages |
| Frequencies only | Just counts |

**Current State**: All options implemented.

- `--display=frequency` — percentages only (default)
- `--display=counts` — raw counts only
- `--display=both` — two sheets in one workbook (Percentages + Counts)
- `--display=both --separate-workbooks` — two separate .xlsx files: `crosstabs.xlsx` (percentages) + `crosstabs-counts.xlsx` (counts). Each workbook gets its own TOC and Excluded Tables sheet.

---

---

### 2.4 Stat Testing Configuration — `COMPLETE`

**Current State**: Fully implemented.

- **Environment variables**: `STAT_THRESHOLDS`, `STAT_PROPORTION_TEST`, `STAT_MEAN_TEST`, `STAT_MIN_BASE`
- **Supports**: Dual thresholds (uppercase/lowercase letter notation), unpooled/pooled z-tests, Welch/Student t-tests, minimum base size
- **Validated on startup**, formatted for display, stored in `pipeline-summary.json`
- **All defaults** flow from a single config source: `getStatTestingConfig()` in `src/lib/env.ts`
- **`--show-defaults`** CLI flag displays current configuration without running pipeline

---

### 2.4b Loop-Aware Stat Testing — `NOT STARTED`

**Problem**: When entity-anchored banner groups exist on stacked/loop data, within-group pairwise stat testing (A-vs-B) can be invalid if groups overlap. Today, the system validates partition correctness and reports overlaps in `loop-semantics-validation.json`, but `generateSignificanceTesting()` doesn't consult this — stat letters are generated regardless.

**What to implement (two modes, default = suppress):**

| Mode | Behavior | When to use |
|------|----------|-------------|
| **Suppress** (default) | Skip within-group stat letters entirely for entity-anchored groups on stacked data. Still show vs-Total comparison. | Safe default. No invalid letters. |
| **vs-Complement** (optional) | Instead of A-vs-B, compute A-vs-not-A for each cut. Always statistically valid regardless of overlap. | User wants significance testing on loop tables and understands the tradeoff. |

**Implementation approach:**

1. **Schema** — Add `comparisonMode: 'suppress' | 'complement'` to `BannerGroupPolicySchema` in `loopSemanticsPolicySchema.ts`. Default: `'suppress'`.

2. **R script generation** — In `generateSignificanceTesting()` (`RScriptGeneratorV2.ts`):
   - Pass the loop semantics policy into the function (currently it receives nothing)
   - For each group, check if it's entity-anchored with `shouldPartition=true`
   - If `suppress`: skip the within-group comparison loop for that group
   - If `complement`: generate R code that computes complement mask (`!cut_mask`) and tests cut proportions/means against the complement set using the same z-test/t-test logic

3. **Config** — Expose as a pipeline option. In the UI, only show this toggle when loops are detected. Default to suppress.

**Level of Effort**: Medium (R script generation changes + schema addition + config wiring)

---

### ~~2.4c Crosstab Agent Variable Selection Persistence~~ — `DEFERRED`

> Moved to Long-term Vision. Not blocking for MVP — hidden variable hints and HITL provide sufficient reliability for now.

---

### ~~2.4d Dual-Mode Loop Semantics Prompt~~ — `DEFERRED`

> Moved to Long-term Vision. Single prompt works well when deterministic evidence exists. Revisit if batch testing reveals failures on low-evidence datasets.

---

### ~~2.5 Upfront Context Capture~~ — `CONSOLIDATED`

> Merged into 3.1 (Project Intake Questions in the New Project Flow). All context capture happens through the UI upload experience.

---

### 2.5a Input Format Flexibility — `COMPLETE`

| Input Type | Accepted Formats | Notes |
|------------|------------------|-------|
| Survey | PDF, DOCX | BannerAgent converts via LibreOffice headless + pdf2pic |
| Banner Plan | PDF, DOCX | Same conversion pipeline as survey |
| Data File | SPSS (.sav) only | Source of truth for variables and values |

**Not supported (by design):** Excel banner plans, TXT files for survey or banner. These are edge cases not worth the preprocessing complexity. If a client has an Excel banner plan, they can export it to PDF first.

Question numbering flexibility (Q_S2, S2, QS2, etc.) is handled by AI pattern matching — no special work needed.

---

### 2.5b AI-Generated Banner from Research Objectives (defer to after MVP delivery) — `NOT STARTED`

When no banner plan is provided—or user explicitly chooses "AI generate cuts"—the system generates a suggested banner.

**Why It Matters**: Antares mentioned clients who send banner plans with "just words" or no spec at all. This feature handles that case and could be a differentiator.

> **Note**: This feature isn't blocking for initial Antares access. The core value is reliable tabs from their existing workflow (banner plan provided). We can tell them: "We heard this in our conversation and have a plan to implement it, but we wanted to get this in your hands as soon as possible." Ship it as a fast-follow after MVP delivery.

**Flow**:
1. **Prompt for research objectives** (optional but recommended):
   - CLI: `--objectives "Compare specialty tiers, focus on PCSK9i adoption"` or interactive prompt
   - What are you trying to learn? Key subgroups of interest?
   - For testing: default objectives per dataset

2. **Analyze data map for cut candidates**:
   - Demographics (age, gender, region, specialty)
   - Segments/tiers (common cut patterns)
   - Key variables mentioned in objectives

3. **Apply best practices**:
   - What makes a useful banner cut (sufficient n, meaningful segmentation)
   - Typical group structures (Total, then demographic cuts, then behavioral cuts)

4. **Generate suggested banner groups**:
   - Ranked by relevance to research objectives
   - Include stat testing letters

5. **HITL confirmation**:
   - Show suggested banner to user before proceeding
   - Allow edits/removals before pipeline continues

**Implementation Options**:
- Mode of existing BannerAgent (different prompt path when no banner provided)
- Separate "BannerInferenceAgent" that runs when banner input is missing

**Level of Effort**: Medium-High (new agent logic, HITL integration, research objectives capture)

---

### 2.6 Weight Detection & Application — `NOT STARTED`

*Moved from Reliability Plan Part 5.*

**Problem**: Many surveys include weight variables to adjust for sampling imbalances. Currently the pipeline ignores weights — all calculations are unweighted. This produces technically correct but analytically incomplete output for weighted studies.

**Detection**: Look for common weight column names in the data file (`weight`, `wt`, `wgt`, and variations).

**User Confirmation**:
```
We found a possible weight variable: "wt"
Apply weights to calculations?

[Yes, apply weights]  [No, unweighted]  [That's not a weight]
```

**Output**:
- Two base rows: Unweighted base (n), Weighted base (weighted n)
- All percentages/means calculated with weights
- R's `svydesign` handles weighted calculations natively

**Level of Effort**: Medium (heuristic detection + R script changes + Excel formatting for dual base rows)

---

### 2.7 Survey Classification & Confidence Scoring — `NOT STARTED`

*Moved from Reliability Plan Part 6.*

**Problem**: Different research methodologies need different handling. A MaxDiff survey needs actual message text. A conjoint has choice tasks and derived utilities. An ATU has expected table structures. Without detecting the type, agents operate generically and may miss methodology-specific requirements.

**Survey Classification**:

If we can detect the type, we can set user expectations, prompt for missing context, pre-configure agent behavior, and flag when we're out of our depth.

| Type | Detection Signals | Why It Matters |
|------|-------------------|----------------|
| **MaxDiff** | Variables named `MD*`, `maxdiff*`; "best/worst" or "most/least appealing" in descriptions | Needs message text; has utility scores |
| **Conjoint/DCM** | Variables named `DCM*`, `conjoint*`, `choice*`; utility score patterns | Has choice tasks and derived utilities |
| **ATU** | "awareness" + "trial/usage" patterns; "ever heard/used" | Standard table structures expected |
| **Message Testing** | "message N" patterns; "appeal" + "message" | Needs actual message content |
| **Segmentation** | "segment" or "cluster" in variables | May have derived segment assignments |
| **Standard** | None of the above | Default handling |

**Multi-Dimensional Confidence Scoring**:

Instead of a single confidence score, track confidence across dimensions:

| Dimension | What It Measures | When Low Score Matters |
|-----------|------------------|------------------------|
| **Structure** | Did we parse brackets/values/options correctly? | Parser may have failed |
| **Parent-Child** | Are relationships between variables clear? | Context enrichment issues |
| **Variable Types** | Did we identify types correctly? | Wrong table treatment |
| **Loop Detection** | If loops detected, how certain? | May ask for wrong format |
| **Survey Classification** | How confident in methodology type? | May miss required context |

**Integration**: Ties into Project Intake Questions (3.1). Low classification confidence triggers user prompts; high confidence enables auto-configuration.

**Level of Effort**: Medium-High (detection logic + confidence aggregation + UI integration)

---

### 2.8 Sample Size Review (HITL Enhancement) — `PARTIAL`

> **Implementation Status (Feb 2026):** HITL review UI exists at `/pipelines/[pipelineId]/review/` showing alternatives with confidence scores. Missing: `baseSize` field not in `AlternativeSchema`, no R query to calculate n counts during HITL, no zero-count/low-count flagging.

**Current State**: When the AI is uncertain about a cut, HITL shows the user:
- Proposed R expression
- Alternative expressions with confidence scores
- Reason for uncertainty

**What's Missing**: Base sizes. The user has no idea if a proposed cut has 20 respondents or 200.

**What's Needed**:
1. **Add base sizes to HITL alternatives**: For each proposed cut and alternative, show the n count
   - Requires running a quick R query against the data file during HITL
   - User sees: "Tier 1 (n=156)" vs "Tier 1 - Alternative (n=23)"
   - Helps user identify correct mapping: "We expected ~150 Tier 1 HCPs, so the first one is right"

2. **Flag problematic base sizes**:
   - Zero-count cuts (n=0) → likely wrong mapping
   - Low-count cuts (n<30) → warning for sig testing limitations

3. **Schema update**: Add `baseSize` field to `AlternativeSchema`

**Why It Matters**: Users often know roughly how many respondents should be in a segment. Showing base sizes turns HITL from "trust the AI's confidence score" into "verify against what I know about my data."

**Level of Effort**: Medium (R query integration + schema/UI updates)

---

### 2.9 Table ID Visibility + Include/Exclude Control — `PARTIAL`

> **Implementation Status (Feb 2026):** Table IDs render in Excel output (`[tableId]` in context column). Excluded Tables sheet exists with full rendering. Tables have `excluded` and `excludeReason` schema fields. Missing: No CLI command or API to accept include/exclude lists and regenerate. No user-facing control to pull tables back from excluded.

**Problem**: Users currently can't control which tables appear in the final output. Some tables are auto-excluded by the system, but users can't bring them back. Some included tables might not be wanted.

**What's Needed**:

1. **Show table ID in Excel output**:
   - Add table ID to Column A, near the top of each table (under section name or in parentheses next to it)
   - Users can reference these IDs when requesting changes
   - Example: "S5_summary" or "A3a_t2b_derived"

2. **Include/Exclude functionality**:
   - Given a list of table IDs, regenerate Excel with those changes
   - Tables on "Excluded Tables" sheet can be pulled back into main output
   - Tables in main output can be moved to excluded

**User Actions** (per table):
- **Keep** (default) — table stays where it is
- **Exclude** — move to excluded sheet
- **Include** — pull back from excluded sheet into main output

**Phase 2**: CLI flags or config file to specify include/exclude lists
**Phase 3**: UI with toggles per table

**Level of Effort**: Low-Medium (Excel formatting + regeneration logic)

---

### 2.10 Table Feedback & Regeneration — `NOT STARTED`

**Problem**: Users may like a table but want it formatted differently—different derived rows, different groupings, etc. Currently they'd have to manually edit the Excel or request a full re-run.

**What's Needed**:

1. **Feedback mechanism**:
   - User provides table ID + feedback text
   - Example: "T5a — show top 3 box instead of top 2" or "A3a_summary — combine PCSK9i rows into single NET"

2. **Targeted regeneration**:
   - System reruns that specific table through VerificationAgent with feedback appended to context
   - Agent generates updated table with same table ID
   - Slot updated table back into full output (same position)

3. **Constraints**:
   - Feedback is scoped to what VerificationAgent can do (row labels, NETs, derived rows, exclusions)
   - Can't change the underlying data or banner structure
   - This is constrained editing, not free-form exploration

**Why It Matters**: Foundation for future conversational exploration features. Users get a preview of "ask for changes, get updated output" while staying grounded in validated artifacts.

**Phase 2**: CLI command: `--regenerate-table T5a --feedback "Show top 3 box"`
**Phase 3**: UI with feedback input per table

**Level of Effort**: Medium (VerificationAgent re-invocation + output splicing)

---

### 2.11 Excel Color Themes — `NOT STARTED`

> **Implementation Status (Feb 2026):** Colors are hardcoded in `src/lib/excel/styles.ts` without semantic role abstraction. Only one palette (Joe style + Antares colors). No `themes.ts`, no `--theme` CLI flag, no theme configuration.

**Problem**: We have effectively one styling look-and-feel. Users may want flexibility in workbook color palette while preserving readability and visual hierarchy.

**What's Needed**:

1. **Map current colors to semantic roles**:
   - Header row fill
   - Alternating row fill (zebra striping)
   - Banner column separation
   - NET/Total row emphasis
   - Derived row styling
   - Stat letter highlighting

2. **Define 4+ curated palettes**:
   | Theme | Description |
   |-------|-------------|
   | Classic (default) | Current blue-gray palette |
   | Minimal | Light grays, subtle contrast |
   | High Contrast | Bold colors for presentations |
   | Print-Friendly | Optimized for black-and-white printing |

3. **CLI configuration**:
   - `--theme classic` (default)
   - `--theme minimal`
   - Show available themes: `hawktab themes`

4. **Implementation**:
   - Create `src/lib/excel/themes.ts` with semantic color mapping
   - ExcelFormatter reads theme config and applies colors
   - Each palette plugs into same semantic roles

**Phase 2**: CLI flag for theme selection
**Phase 3**: UI dropdown in project settings

**Level of Effort**: Low (color mapping + config flag, no structural changes)

---

### 2.12 Interactive Browser Review (defer to after MVP delivery) — `PARTIAL (foundation only)`

> **Implementation Status (Feb 2026):** HITL review page exists for crosstab cut validation (`/pipelines/[pipelineId]/review/`). Has state management for per-column decisions, visual feedback, collapsible sections. Missing: No table preview component (rendering `tables.json` as HTML), no per-table include/exclude toggles, no per-table feedback notes, no "Generate Final Excel" button.

**Problem**: Current review workflow is inefficient:
- Reviewer looks at static Excel output
- Decides which tables to exclude/keep
- Has to regenerate full workbook to see changes

**Why It Matters**: This friction slows down iteration. Reviewers want to see changes live before committing to final output.

> **Note**: This feature isn't blocking for initial Antares access. The core value is reliable tabs from their existing workflow. We can tell them: "We have a plan to add interactive review, but we wanted to get this in your hands as soon as possible." Ship as a fast-follow after MVP delivery.

**Desired Workflow**:

1. After pipeline runs, open preview **in browser** (not Excel)
2. See all tables rendered in a scrollable list
3. Toggle tables on/off (exclude/include) with instant visual feedback
4. Add feedback notes to specific tables
5. See changes **live** without regeneration
6. Click "Generate Final Excel" when satisfied

**Implementation**:

1. **Table preview component**:
   - Render `tables.json` as HTML tables
   - Style to match Excel output (close enough for review purposes)
   - Collapsible sections by question/table group

2. **State management**:
   - Track include/exclude toggles in local state
   - Track feedback notes per table
   - No backend changes until "Generate" clicked

3. **Regeneration on demand**:
   - When user clicks "Generate Final Excel", apply exclusions and feedback
   - Call existing regeneration logic (2.9, 2.10)
   - Provide updated Excel for download

4. **Route structure**:
   ```
   /projects/[id]/review     # Interactive review page
   /projects/[id]/results    # Final download page (existing)
   ```

**Phase 3**: Ship after core UI is stable. Requires 2.9 (include/exclude) and 2.10 (feedback) as foundations.

**Level of Effort**: Medium-High (new UI component, state management, integration with existing regeneration)

---

## Phase 3: Productization

Taking the reliable, feature-rich CLI and bringing it to a self-service UI that external parties like Antares can use.

### 3.1 Local UI Overhaul (Cloud-Ready) — `PARTIAL (~40%)`

> **Implementation Status (Feb 2026):** Basic Next.js app works: file upload UI, pipeline history, job progress polling with toast notifications, job cancellation, HITL review page for crosstab cuts. Missing: No `(marketing)/` or `(product)/` route groups, no dashboard/project list, no new project wizard, no organization structure. `StorageProvider` not abstracted (hardcoded `/tmp/hawktab-ai/`). `JobStore` is in-memory only (Map, no persistence across restarts). Not cloud-ready.

**Goal**: Build the complete web experience locally, but architected so deployment to cloud is just configuration changes—not rewrites.

**Reference**: Discuss.io for organization/project structure (not styling). The functionality pattern—organizations, projects, roles—is what enterprise clients expect.

**What's Needed**:

1. **Marketing Pages** (`(marketing)/` route group):
   - Landing page with value proposition
   - Login button (routes directly to dashboard—no custom auth pages, WorkOS handles this)
   - Simple, bold, professional aesthetic

2. **Product Pages** (`(product)/` route group):
   - **Dashboard**: Project list with columns (Project Name, Private/Public, Team, Date Created, Your Role, Status)
   - **New Project Flow**: File upload (SPSS, datamap, survey, banner plan), configuration options
     - *Note*: Data file upload should include helper text or tooltip clarifying "qualified respondents only"—the system assumes terminated/disqualified respondents are already filtered out.
   - **Project Intake Questions** *(consolidates former 1.5 and 2.5)*: After file upload, ask qualifying questions based on project type. Not every survey type needs extra context, but some do:
     - "What type of project is this?" → Segmentation, MaxDiff, ATU, Conjoint, Standard, etc.
     - **Segmentation**: "Does your data file have the segment assignments?" If no → warn that segment banner cuts won't work.
     - **MaxDiff with message testing**: "Can you upload the message list?" (so we can link questions to actual message text, not just "Message 1"). "Does your data file have the anchored probability scores?" If no → warn that MaxDiff utility results won't be available.
     - **Conjoint/DCM**: "Can you upload your choice task definitions?" Needed to interpret utility scores and choice shares.
     - **General**: Set expectations about what the system can and can't do for this project type, before burning 45 minutes of pipeline time.
     - Context captured here gets injected into agent prompts (e.g., VerificationAgent knows this is a MaxDiff study and can label tables appropriately).
     - This is about giving the pipeline the context it needs to succeed, not about predicting success. Start with the 2-3 project types that require extra files or context. Expand as we encounter more.
   - **HITL Review**: Uncertain variable mappings with base sizes (from 2.8)
   - **Job Progress**: Real-time status updates
   - **Results**: Download Excel, view table list, include/exclude toggles (from 2.9), feedback per table (from 2.10)

3. **Organization Structure Foundation**:
   - UI assumes organization context (like "HawkPartners" in Discuss.io header)
   - Roles: Admin, Member, External Partner
   - Projects belong to organizations
   - This is the data model foundation—auth enforcement comes in 3.3

4. **Route Structure**:
```
/app
├── (marketing)/           # Public pages
│   ├── page.tsx           # Landing page at /
│   └── layout.tsx         # Marketing layout (no sidebar)
│
├── (product)/             # Logged-in experience
│   ├── dashboard/         # Project list
│   ├── projects/[id]/     # Single project view
│   ├── projects/new/      # New project wizard
│   └── layout.tsx         # Product layout (sidebar, org header)
```

**Cloud-Ready Architecture** (critical for smooth 3.2 transition):

| Concern | Local Implementation | Cloud Swap |
|---------|---------------------|------------|
| File storage | Abstract `StorageProvider` interface → local disk | Swap to R2 |
| Job state | Abstract `JobStore` interface → JSON files or SQLite | Swap to Convex |
| File downloads | Serve from local `/temp-outputs/` | Signed R2 URLs |
| Real-time updates | Polling local endpoint | Convex subscriptions |

**Don't do this**:
- Hardcode file paths like `/temp-outputs/project-123/`
- Store job state in memory only
- Assume single-user, single-job execution

**Do this instead**:
- Use `storageProvider.upload(file)` / `storageProvider.download(key)`
- Use `jobStore.getStatus(jobId)` / `jobStore.updateStatus(jobId, status)`
- Design for concurrent jobs from day one (even if we test with one)

**Design Principles**:
- Bold yet professional (not generic SaaS slop)
- Enterprise-focused from day one
- Placeholders for future features are fine
- Assume logged-in state for now (auth comes later)

**Audit First**: Before building, audit current CLI features and map each to a UI component.

**Level of Effort**: High (full UI build with proper abstractions)

---

### 3.2 Cloud Deployment — `NOT STARTED`

**Current**: Runs locally via CLI and local Next.js dev server

**Target**: Cloud-hosted service that Antares can rely on—not just functional, but reliable and secure.

**Core Infrastructure**:

| Component | Service | Why |
|-----------|---------|-----|
| UI Hosting | Vercel | Easy Next.js deployment, edge functions |
| Database | Convex | Real-time subscriptions, TypeScript-native |
| File Storage | Cloudflare R2 | S3-compatible, no egress fees |
| R Execution | Railway (Docker) | Supports long-running processes |
| Error Monitoring | Sentry | Know when things break |
| Analytics | PostHog | Usage tracking (minimal) |

**Job Management** (pipeline runs 30-60 mins with 4 agents):

1. **Job Queue**:
   - User submits job → Create job record in Convex (status: `queued`)
   - Background worker picks up job → status: `running`
   - Track progress: `banner_complete`, `crosstab_complete`, `table_complete`, `verification_complete`, `r_running`, `excel_generating`
   - On completion → status: `completed`, store result URLs
   - On failure → status: `failed`, store error details

2. **Concurrent Jobs**:
   - Each job is isolated (own file namespace, own R session)
   - Don't assume single-user—Antares might run 3 projects at once
   - Railway can scale horizontally if needed

3. **HITL Pause/Resume**:
   - When HITL is needed → status: `awaiting_review`, store pending decisions
   - User can close browser, come back later
   - On review submission → resume pipeline from checkpoint

**Caching & Performance**:

| What to Cache | Where | Why |
|---------------|-------|-----|
| Parsed datamap | Convex or R2 | Don't re-parse on HITL resume |
| Banner output | Convex | Reuse if user re-runs with same banner |
| R script (pre-execution) | R2 | Debug/audit trail |
| Intermediate agent outputs | R2 | Resume from checkpoint on failure |

Redis is likely overkill for MVP—Convex handles real-time well. Consider Redis later if we need:
- Rate limiting at scale
- Session caching across edge functions
- Sub-second cache invalidation

**Security Fundamentals**:

- **File uploads**: Validate file types server-side (not just client), scan for malicious content, size limits
- **API routes**: All `/api/` routes behind auth middleware (after 3.3)
- **Signed URLs**: R2 downloads use time-limited signed URLs, not public buckets
- **Input validation**: Zod schemas on all API inputs
- **CORS**: Restrict to known origins
- **Rate limiting**: Prevent abuse (especially on expensive AI calls)
- **Secrets**: All API keys in environment variables, never in client code

**Reliability Patterns**:

- **Retries with backoff**: Agent calls can fail—retry 3x with exponential backoff
- **Graceful degradation**: If one table fails R validation, continue with others (already doing this)
- **Health checks**: Endpoint for monitoring (Vercel cron or external)
- **Idempotent operations**: Re-running a job with same inputs should be safe

**Deployment Checklist**:
- [ ] Swap `StorageProvider` to R2 implementation
- [ ] Swap `JobStore` to Convex implementation
- [ ] Configure Railway R container with HTTP endpoint
- [ ] Set up Sentry error tracking
- [ ] Configure environment variables in Vercel
- [ ] Test full pipeline in staging before production
- [ ] Set up basic monitoring/alerting

**Level of Effort**: High (1-2 weeks for reliable deployment, not just "it works")

---

### 3.3 Multi-Tenant & Auth (WorkOS Integration) — `NOT STARTED`

**Context**: At this point, we have a cloud-deployed app with proper abstractions (3.1) and reliable infrastructure (3.2). Now we layer on authentication and organization management to make it ready for external users like Antares.

**Why WorkOS AuthKit**:
- Free for 1M MAUs (plenty of headroom)
- Handles login/signup UI—we don't build auth pages
- SSO/SAML available when enterprise clients need it
- Organization management built-in

**What WorkOS Provides**:
- User authentication (email, Google, SSO)
- Organization creation and management
- User ↔ Organization membership
- Role assignment (Admin, Member)
- Hosted login/signup pages (redirect flow)

**What We Build on Top**:

1. **Auth Middleware**:
   - Protect all `(product)/` routes
   - Validate WorkOS session token
   - Inject `userId` and `orgId` into request context

2. **Convex Schema Extensions**:
   - `users` table (synced from WorkOS on first login)
   - `organizations` table (synced from WorkOS)
   - `projects` table already has `orgId` foreign key (from 3.1)
   - `orgMemberships` for role lookups

3. **Role-Based Access**:
   | Role | Can Do |
   |------|--------|
   | Admin | Create projects, invite members, manage org settings, view all projects |
   | Member | Create projects, view own projects, view shared projects |
   | External Partner | View projects explicitly shared with them, download results |

4. **Invite Flow**:
   - Admin invites user by email → WorkOS sends invite
   - User signs up/logs in → Automatically added to org
   - For external partners: invite with limited role

5. **Organization Switcher** (if user belongs to multiple orgs):
   - Dropdown in header (like Discuss.io "HawkPartners" selector)
   - Context switches all data to selected org

**Integration Points**:
- Login button → `WorkOS.redirectToLogin()`
- Callback route → Validate token, create session, redirect to dashboard
- Logout → Clear session, redirect to marketing page
- API routes → Check `req.auth.orgId` matches resource ownership

**Security Enforcement**:
- All file access scoped to org: `r2.get(orgId/projectId/file.xlsx)`
- All Convex queries filter by `orgId`
- No cross-org data leakage possible by design

**Level of Effort**: Medium (WorkOS does heavy lifting, we wire it up and enforce scoping)

---

### 3.4 Cost Tracking — `PARTIAL (~30%)`

> **Implementation Status (Feb 2026):** `AgentMetricsCollector` tracks token usage per agent call. `CostCalculator` uses LiteLLM pricing for cost estimation. Cost summary printed to console after pipeline completion. Missing: No database persistence (metrics are lost when process ends). No per-org aggregation, no dashboard, no historical tracking. Needs a database (Convex) to be useful.

**Goal**: Track AI costs so we can price the product appropriately. This is for us, not exposed to users.

**What to Track**:
- Token usage per agent call (BannerAgent, CrosstabAgent, TableAgent, VerificationAgent)
- Token usage for regenerations (2.10)
- Store in Convex: `aiUsage` table with `jobId`, `orgId`, `operation`, `tokens`, `timestamp`

**Pricing**: After Antares trial period (2-4 weeks), review actual usage and set pricing. Ballpark: ~$300/project or ~$3,000/month. Revisit once we have real data.

**No dashboard for MVP**. Query Convex directly or export to spreadsheet. Build a dashboard later if needed.

**Level of Effort**: Low (just log the data)

---

### 3.5 Logging and Observability — `MINIMAL (~20%)`

> **Implementation Status (Feb 2026):** Basic tracing config exists (`src/lib/tracing.ts`) with `TRACING_ENABLED` env var. Pipeline event bus emits internal events. Agent metrics record duration. Missing: No Sentry integration, no structured logging with levels, no correlation IDs, no PostHog analytics. Logging is ad-hoc `console.log` throughout.

**Goal**: When something breaks for Antares, we can debug it.

**Structured Logging** (see `logging-implementation-plan.md` for details):
- Centralized logger with log levels (error, warn, info, debug)
- Correlation IDs to trace a job through all stages
- Sentry for error alerting

**Product Analytics** (lightweight for MVP):
- Track key events: `project_created`, `job_completed`, `job_failed`, `download_completed`
- PostHog JS SDK in frontend
- Enough to understand usage patterns; expand later based on what questions we have

**Level of Effort**: Low-Medium (logging foundation + basic event tracking)

---

## MVP Complete

**Completing Phase 3 = MVP = The Product.**

At this point, HawkTab AI is a fully functional, cloud-hosted service that external parties like Antares can use to generate publication-quality crosstabs.

Some items in Phase 2 and 3 may be deferred or simplified depending on what we learn during implementation. The goal is a reliable, usable product—not feature completeness for its own sake.

---

## Long-term Vision

Bob's observation from the Antares conversation: *"I've not seen anybody kind of going down this road... commercially speaking."*

What makes HawkTab unique is the **validated data foundation**. Every crosstab run produces artifacts that already executed successfully—verified variables, working R expressions, human-approved cuts. This foundation could eventually support follow-up queries and conversational exploration without the hallucination problems that plague other AI-on-data tools.

But that only matters if the core system is reliable. That's what we're focused on now.

### Configurable Assumptions & Regeneration

HawkTab makes defensible statistical assumptions when generating crosstabs — particularly for looped/stacked data. These assumptions are specific choices from a finite set of valid approaches:

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
- Assumptions surfaced in plain language (Methodology sheet — see 2.4b context)
- A mapping of each assumption to its alternatives (schema-driven, not free-form)
- A regeneration path that re-runs R script generation + execution without re-running the full pipeline
- The resume script (`test-loop-semantics-resume.ts`) is already a prototype of this pattern

**Why this matters commercially:** No other tool in this space surfaces its assumptions, let alone lets you change them. WinCross, SPSS Tables, and Q all make implicit choices that users can't inspect or override. Making assumptions explicit and configurable is a differentiator that builds trust with sophisticated research buyers.

This is a long-term feature — the foundation (correct defaults + validation proof) comes first.

---

### Predictive Confidence Scoring (Pre-Flight)

*Moved from former Phase 1.5.*

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

**When to revisit:** After Part 4 broader testing is complete and we have failure data across 20+ datasets with diverse characteristics. If clear patterns emerge (e.g., "datasets with no deterministic resolver evidence fail 80% of the time"), then a predictor becomes viable.

---

### Variable Selection Persistence

*Moved from Phase 2.4c.*

The crosstab agent's variable selection is non-deterministic — same dataset can produce different variable mappings across runs. Once a user confirms a mapping via HITL or accepts a successful run's output, lock those selections as project-level overrides so future re-runs don't re-roll the dice.

**What gets saved:** Banner group name → variable mappings, confirmation source ("user_confirmed" or "accepted_from_run_N"). Stored as `confirmed-cuts.json` in the project folder. The crosstab agent prompt includes a "locked selections" section — variables in this list are not re-evaluated.

**Why it matters:** Eliminates "it worked last time but not this time." First step toward accumulating project-level knowledge across runs.

**Level of Effort:** Low (JSON persistence + prompt section, no architectural changes)

---

### Dual-Mode Loop Semantics Prompt

*Moved from Phase 2.4d.*

The Loop Semantics Policy Agent uses a single prompt regardless of how much deterministic evidence is available. When the resolver finds strong evidence, the prompt works well. When there's none, the LLM must infer from cut patterns and datamap descriptions alone — harder and less reliable.

**Solution:** Two prompt variants selected automatically based on `deterministicFindings.iterationLinkedVariables.length`. High-evidence prompt anchors on resolver data. Low-evidence prompt adds pattern-matching guidance for OR expressions, emphasizes datamap descriptions, lowers confidence thresholds for `humanReviewRequired`, and includes more few-shot examples.

**Level of Effort:** Low (second prompt file in `src/prompts/loopSemantics/alternative.ts` + selection logic in agent)

**When to revisit:** If batch testing reveals classification failures on datasets where the deterministic resolver finds nothing.

---

## Known Gaps & Limitations

Documented as of February 2026. These are areas where the system has known limitations — some with mitigation paths already identified, others that may define the boundary of what HawkTab can handle. Even where solutions exist, it's important to be aware of these when communicating capabilities externally or testing against new datasets.

### Loop Semantics

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No deterministic evidence** — SPSS file has no label tokens, suffix patterns, or sibling descriptions. LLM must infer entirely from cut patterns and datamap context. | Medium | Dual-mode prompt (2.4d). Long-term: predictive confidence scoring (see Long-term Vision). | Identified, not implemented |
| **Irregular parallel variable naming** — Occasion 1 uses Q5a, occasion 2 uses Q7b, occasion 3 uses Q12. No naming relationship. Resolver can't match. | Medium | LLM prompt must handle this from datamap descriptions. Few-shot examples for irregular naming. Some surveys may be unfixable without user hints. | Partially mitigated by LLM |
| **Complex expression transformation** — `transformCutForAlias` handles `==`, `%in%`, and OR patterns. Expressions with `&` conditions, nested logic, or negations could break transformation. | Low-Medium | Expand transformer for common compound patterns. Flag untransformable expressions for human review. | Common cases handled |
| **Multiple independent loop groups** — Dataset with both an occasion loop AND a brand loop. Architecturally supported but never tested. | Low | Schema and pipeline support N loop groups. Needs integration testing with a real multi-loop dataset. | Untested |
| **Nested loops** — A brand loop inside an occasion loop. Not handled. | Low | Not supported. Validation already detects loops; nested loop detection could be added as a basic sanity check. | Not supported |
| **Weighted stacked data** — Weights exist in the data but aren't applied during stacking or computation. | High | Next priority after loop semantics. R's `svydesign` handles weighted calculations natively. | Not implemented |
| **No clustered standard errors** — Stacked rows from the same respondent are correlated, which overstates significance. Standard tests treat them as independent. This is industry-standard behavior (WinCross, SPSS Tables, Q all do the same). | Low | Accept as industry-standard limitation. Future differentiator if implemented. Would require respondent ID column in stacked frame + cluster-robust R functions. | Known limitation, not planned |
| **No within-group stat letter suppression for entity-anchored groups** — `generateSignificanceTesting()` doesn't consult the loop semantics policy. Within-group pairwise comparisons run for all groups regardless of overlap. Validation detects overlaps but doesn't act on them. | Medium | Implement 2.4b (suppress or vs-complement testing for entity-anchored groups). | Not implemented |

### Crosstab Agent

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **Non-deterministic variable selection** — Same dataset can produce different variable mappings across runs. | Medium | Hidden variable hints help steer. Variable selection persistence (2.4c) locks in confirmed choices. HITL for low-confidence cuts. | Partially mitigated |
| **Hidden variable conventions vary by platform** — h-prefix and d-prefix patterns are Decipher/FocusVision conventions. Other platforms (Qualtrics, SurveyMonkey, Confirmit) use different naming. | Low-Medium | Expand hint patterns as we encounter new platforms. The datamap description is platform-agnostic and usually contains enough signal. | Platform-specific hints added |

### General Pipeline

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No pre-flight confidence assessment** — Pipeline runs for 45+ minutes before discovering it can't handle a dataset reliably. | Medium-High | Long-term: predictive confidence scoring (see Long-term Vision). Requires failure data across 50+ datasets before a predictor is viable. Near-term: project intake questions (3.1) set expectations upfront. | Deferred to Long-term Vision |
| **No methodology documentation in output** — Users receive numbers without explanation of how they were computed. Assumptions are implicit. | Medium | Methodology sheet in Excel (Configurable Assumptions vision). Policy agent + validation results provide the content. | Planned |
| **No project-level knowledge accumulation** — Each pipeline run starts fresh. Confirmed variable mappings, user preferences, and past decisions aren't carried forward. | Low-Medium | Variable selection persistence (2.4c) is the first step. Longer-term: project-level config that accumulates across runs. | Identified |
| **Hidden assignment variables don't produce distribution tables** — When a question's answers are stored as hidden variables (e.g., `hLOCATIONr1–r16` for S9), the pipeline correctly hides them but misses the distribution table that shows assignment frequency. Requires parent-variable linking in DataMapProcessor or verification agent awareness. | Low | Accept gap for now. Future: detect when hidden variable families relate to a visible question and auto-generate distribution tables. | Known limitation |
| **No dual-base reporting for skip logic questions** — When a question has skip logic, only the filtered base is reported. An experienced analyst might also report the same table with an all-respondents base for context (e.g., "what share of everyone had 2+ people present" vs "among those not alone, group size distribution"). Current behavior is correct; this is a future quality-of-life enhancement. | Low | Future: optional "also report unfiltered" flag on skip logic tables, generating both versions with clear base text. | Known limitation |
| **`deriveBaseParent()` doesn't collapse parent references for loop variables** — In LoopCollapser.ts, when a collapsed variable's parent is itself a loop variable being collapsed, `deriveBaseParent()` returns the uncollapsed parent name (e.g., `A7_1` instead of `A7`). DataMapGrouper then uses this uncollapsed parent as the `questionId`, causing loop variables like A7 to appear with inconsistent naming (e.g., `a7_1` instead of `a7`). Non-loop parents like A4 are unaffected. | Low | Fix `deriveBaseParent()` to check if the derived parent is in the collapse map and resolve it to the collapsed form. Straightforward code fix. | Known limitation |
| **No Excel or TXT input support** — Survey and banner plan inputs only accept PDF and DOCX. Excel banner plans (sometimes sent by clients) and TXT files are not supported. Users must export/convert to PDF or DOCX before uploading. | Low | Could add Excel parsing + structure detection for banner plans if demand warrants it. TXT is unlikely to be needed. | By design |

---

*Created: January 22, 2026*
*Updated: February 8, 2026*
*Status: Planning — Implementation status audit completed Feb 8, 2026*
