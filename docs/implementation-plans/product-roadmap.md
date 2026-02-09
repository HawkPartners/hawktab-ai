# Product Roadmap: Reliability → Production

## Overview

This document outlines the path from HawkTab AI's current state (reliable local pipeline) to a production product that external parties like Antares could use.

**Current State**: Pipeline working end-to-end locally. Reliability validation in progress.

**Target State**: Cloud-hosted service with multi-tenant support, configurable output options, and self-service UI.

**Philosophy**: Ship incrementally. Each phase delivers usable value while building toward the full vision.

---

## Phase 1: Reliability (Current)

*See `reliability-plan.md` for details*

| Part | Description | Status |
|------|-------------|--------|
| 1 | Stable System for Testing (R validation, bug fixes, retry logic) | Complete |
| 2 | Finalize Leqvio Dataset (golden datasets, 3x consistency runs) | In Progress |
| 3 | Loop/Stacked Data + Weights (Tito's dataset) | Not Started |
| 4 | Strategic Broader Testing (5 datasets across survey types) | Not Started |

**Exit Criteria**: 5 datasets producing consistent output across 3 runs each, output quality acceptable for report writing.

### 1.5 Pipeline Confidence Pre-Flight (Reject Early)

**Priority: High — candidate for Phase 1 or early Phase 2.**

Before burning 45+ minutes of pipeline time, the system should assess its own confidence in producing accurate output for a given dataset and flag issues upfront.

**Why this matters:** It's a trust-building feature, not a limitation. Most AI products confidently produce garbage. A system that says "I can't do this reliably" is one users will trust when it says "I can."

**Signals already available:**
- Loop detection: iteration counts, fill rates, variable family completeness
- Deterministic resolver: how many iteration-linked variables found, confidence scores
- Data map quality: percentage of variables with value labels, description completeness
- Variable count and complexity: number of hidden/admin variables, naming consistency

**Three-tier output:**
| Tier | Signal | User message |
|------|--------|--------------|
| Green | Strong deterministic evidence, clean loop detection, high fill rates | "This dataset looks good. Proceeding with high confidence." |
| Yellow | Partial evidence, some ambiguous variables, mixed naming patterns | "We can process this, but some banner cuts may need your review." |
| Red | No deterministic evidence for loops, irregular naming, nested loops detected | "This dataset has characteristics we can't handle reliably. Here's what we found: [specifics]." |

**Implementation:** Aggregation function that runs after validation + loop detection + deterministic resolver (all fast, pre-agent steps). Returns a confidence assessment before any LLM calls. The yellow tier proceeds but sets `humanReviewRequired` on the policy agent. The red tier halts with an explanation.

**Level of Effort**: Low-Medium (signals exist, just need aggregation logic and UX)

---

## Phase 2: Feature Completeness

**NOTE**: Can we render the full decimal values for the percents and frequencies? So instead of showing 11% show 10.5678%?

Features needed before external users can rely on the system for real projects.

### 2.1 Output Format Options

**Percents Only / Frequencies Only**

Bob asked: "Is it possible to add in an option to say I only want percents or frequencies?"

| Option | What It Shows |
|--------|---------------|
| Both (default) | Count and percentage in each cell |
| Percents only | Just percentages |
| Frequencies only | Just counts |

**Current State**: The system already supports all three options. Currently defaults to placing both in the same worksheet.

**Remaining Work**: Add option for separate workbooks when user wants percents AND frequencies but in different files:
- Default: Single workbook with both (current behavior)
- Optional: Two workbooks when explicitly requested
  - Workbook 1: TOC → Percents sheet → Excluded tables
  - Workbook 2: TOC → Frequencies sheet → Excluded tables

**Level of Effort**: Low (config option + ExcelFormatter logic for separate workbook generation)

---

---

### 2.4 Stat Testing Configuration

**Current State**: The R script generator supports dual significance thresholds (e.g., 95%/90% with uppercase/lowercase letters) and single threshold mode. However, these values are not exposed through the CLI and are effectively hardcoded in test scripts.

**What's Needed for MVP**:

1. **CLI flag for custom configuration**: `--sig-config` flag on pipeline script that opens interactive prompts:
   - How many confidence levels? (1 or 2)
   - Confidence level(s) (90%, 95%, 99%)
   - Minimum base size for sig testing (default: none, or e.g., n < 30 → suppress letters)
   - Test method (unpooled z-test is current default)
   - Small base handling (suppress letters vs show with warning)

2. **CLI command for defaults**: `--show-defaults` to display current configuration without running pipeline

3. **Capture in pipeline summary**: Store all stat testing assumptions in `pipeline-summary.json` so output is self-documenting

4. **Remove hardcoded values**: Ensure defaults flow from a single config source, not scattered across files

```typescript
sigTestConfig: {
  thresholds: number[];           // [0.05, 0.10] for dual, [0.10] for single
  minBase: number | null;         // null = no minimum
  method: "unpooled_z" | "pooled_z" | "t_test";
  smallBaseHandling: "suppress" | "show_warning" | "show_anyway";
}
```

**Level of Effort**: Medium (CLI integration + config consolidation)

---

### 2.4b Advanced Stat Testing for Loop Tables

**Context**: When loop/stacked data is present, standard within-group stat testing can be invalid for two reasons: (1) banner groups may overlap on the stacked frame, and (2) multiple rows per respondent creates within-respondent correlation.

Phase 1-2 of the loop semantics implementation (`loop-semantics-implementation-plan.md`) handles the immediate problem: detecting overlap and suppressing invalid within-group stat letters. The items below are future enhancements that go beyond suppression to provide alternative valid testing.

**vs-Complement Testing**

For overlapping banner groups on loop tables, instead of comparing A-vs-B (invalid when groups overlap), compute A-vs-not-A (segment vs complement). This is always statistically valid regardless of overlap. Requires changes to `generateSignificanceTesting()` in `RScriptGeneratorV2.ts` to support a second comparison mode alongside the existing within-group mode.

**Clustered Inference**

Loop tables have within-respondent correlation — the same person contributes 2+ stacked rows. Standard stat tests assume every row is independent, which overstates the effective sample size and makes differences look more significant than they are. Clustered standard errors account for this by grouping rows by respondent and adjusting confidence intervals. This requires:
- Stacked frame includes a stable respondent ID column
- R stat testing functions support a cluster-robust mode
- Most MR tools (WinCross, SPSS Tables, Q) don't do this — they treat stacked rows as independent. So this is a future differentiator, not a current correctness gap vs industry standard.

**Level of Effort**: Medium-High (new R stat functions, testing infrastructure changes)

---

### 2.4c Crosstab Agent Variable Selection Persistence

**Problem:** The crosstab agent's variable selection is non-deterministic. On two runs of the same dataset, it might pick `hLOCATIONr1` (correct) one time and `S9r1` (wrong) the next. The hidden variable hint helps steer it, but doesn't guarantee consistency.

**Solution: Lock in confirmed selections.**

Once a user confirms a variable mapping via HITL — or once a run succeeds and the user accepts the output — save those selections as project-level overrides. Future re-runs of the same dataset load the confirmed mappings instead of re-rolling the dice.

**What gets saved:**
- Banner group name → variable mappings (e.g., "Own Home" → `hLOCATIONr1 == 1`)
- Confirmation source: "user_confirmed" or "accepted_from_run_N"
- The crosstab agent receives these as hard constraints, not hints

**Implementation:** JSON artifact in the project folder (`confirmed-cuts.json`). The crosstab agent prompt includes a "locked selections" section — variables in this list are not re-evaluated. Only unmapped or low-confidence cuts go through the full matching process.

**Why this matters:** Eliminates the "it worked last time but not this time" problem. Builds toward the broader pattern of accumulating project-level knowledge across runs.

**Level of Effort**: Low (JSON persistence + prompt section, no architectural changes)

---

### 2.4d Dual-Mode Loop Semantics Prompt

**Context:** The Loop Semantics Policy Agent currently uses a single prompt regardless of how much deterministic evidence is available. When the resolver finds strong evidence (label tokens, suffix patterns), the prompt works well — the LLM has structured data to anchor on. When there's no deterministic evidence, the LLM has to work from cut patterns and datamap descriptions alone, which is harder and less reliable.

**Solution: Two prompt variants, selected automatically.**

| Mode | Trigger | Prompt focus |
|------|---------|-------------|
| **High-evidence** | Deterministic resolver found iteration-linked variables | "Here's what the resolver found. Use this as primary evidence. Classify accordingly." |
| **Low-evidence** | Resolver found nothing (empty result) | "We have no metadata evidence. You must infer from cut expression patterns, datamap descriptions, and variable naming. Be extra cautious. Flag uncertainty aggressively." |

The low-evidence prompt would include:
- More explicit pattern-matching guidance for OR expressions
- Stronger emphasis on datamap description analysis
- Lower confidence thresholds for triggering `humanReviewRequired`
- Additional few-shot examples showing ambiguous cases

**Selection logic:** If `deterministicFindings.iterationLinkedVariables.length === 0`, use low-evidence prompt. Otherwise, use high-evidence prompt.

**Level of Effort**: Low (second prompt file + selection logic in agent)

---

### 2.5a Input Format Flexibility

Normalize inputs before they hit the pipeline agents.

| Input Type | Accepted Formats | Notes |
|------------|------------------|-------|
| Survey | PDF, DOCX, TXT | Anything we can convert to PDF for processing |
| Banner Plan | PDF, DOCX, TXT, Excel | Excel needs format detection + preprocessing |
| Data File | SPSS (.sav) only | Keep simple for MVP |
| Data Map | CSV only | Standard export from SPSS |

**Implementation**:
- Add format detection on upload
- Preprocessing step to normalize each input type before pipeline
- Excel banner plans: detect structure, convert to intermediate format
- Question numbering flexibility (Q_S2, S2, QS2, etc.) handled by AI pattern matching—no special work needed

**Level of Effort**: Low-Medium (mostly preprocessing logic, pipeline unchanged)

---

### 2.5b AI-Generated Banner from Research Objectives (defer to after MVP delivery)

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

### 2.8 Sample Size Review (HITL Enhancement)

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

### 2.9 Table ID Visibility + Include/Exclude Control

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

### 2.10 Table Feedback & Regeneration

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

### 2.11 Excel Color Themes

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

### 2.12 Interactive Browser Review (defer to after MVP delivery)

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

### 3.1 Local UI Overhaul (Cloud-Ready)

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

### 3.2 Cloud Deployment

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

### 3.3 Multi-Tenant & Auth (WorkOS Integration)

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

### 3.4 Cost Tracking

**Goal**: Track AI costs so we can price the product appropriately. This is for us, not exposed to users.

**What to Track**:
- Token usage per agent call (BannerAgent, CrosstabAgent, TableAgent, VerificationAgent)
- Token usage for regenerations (2.10)
- Store in Convex: `aiUsage` table with `jobId`, `orgId`, `operation`, `tokens`, `timestamp`

**Pricing**: After Antares trial period (2-4 weeks), review actual usage and set pricing. Ballpark: ~$300/project or ~$3,000/month. Revisit once we have real data.

**No dashboard for MVP**. Query Convex directly or export to spreadsheet. Build a dashboard later if needed.

**Level of Effort**: Low (just log the data)

---

### 3.5 Logging and Observability

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

## Known Gaps & Limitations

Documented as of February 2026. These are areas where the system has known limitations — some with mitigation paths already identified, others that may define the boundary of what HawkTab can handle. Even where solutions exist, it's important to be aware of these when communicating capabilities externally or testing against new datasets.

### Loop Semantics

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No deterministic evidence** — SPSS file has no label tokens, suffix patterns, or sibling descriptions. LLM must infer entirely from cut patterns and datamap context. | Medium | Dual-mode prompt (2.4d). Pre-flight confidence check (1.5). If confidence is too low, reject early. | Identified, not implemented |
| **Irregular parallel variable naming** — Occasion 1 uses Q5a, occasion 2 uses Q7b, occasion 3 uses Q12. No naming relationship. Resolver can't match. | Medium | LLM prompt must handle this from datamap descriptions. Few-shot examples for irregular naming. Some surveys may be unfixable without user hints. | Partially mitigated by LLM |
| **Complex expression transformation** — `transformCutForAlias` handles `==`, `%in%`, and OR patterns. Expressions with `&` conditions, nested logic, or negations could break transformation. | Low-Medium | Expand transformer for common compound patterns. Flag untransformable expressions for human review. | Common cases handled |
| **Multiple independent loop groups** — Dataset with both an occasion loop AND a brand loop. Architecturally supported but never tested. | Low | Schema and pipeline support N loop groups. Needs integration testing with a real multi-loop dataset. | Untested |
| **Nested loops** — A brand loop inside an occasion loop. Not handled. | Low | Not supported. Pre-flight check (1.5) should detect and flag this as a red-tier limitation. | Not supported |
| **Weighted stacked data** — Weights exist in the data but aren't applied during stacking or computation. | High | Next priority after loop semantics. R's `svydesign` handles weighted calculations natively. | Not implemented |

### Crosstab Agent

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **Non-deterministic variable selection** — Same dataset can produce different variable mappings across runs. | Medium | Hidden variable hints help steer. Variable selection persistence (2.4c) locks in confirmed choices. HITL for low-confidence cuts. | Partially mitigated |
| **Hidden variable conventions vary by platform** — h-prefix and d-prefix patterns are Decipher/FocusVision conventions. Other platforms (Qualtrics, SurveyMonkey, Confirmit) use different naming. | Low-Medium | Expand hint patterns as we encounter new platforms. The datamap description is platform-agnostic and usually contains enough signal. | Platform-specific hints added |

### General Pipeline

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No pre-flight confidence assessment** — Pipeline runs for 45+ minutes before discovering it can't handle a dataset reliably. | Medium-High | Pre-flight check (1.5) using signals from validation, loop detection, and resolver. Three-tier go/no-go. | Identified, not implemented |
| **No methodology documentation in output** — Users receive numbers without explanation of how they were computed. Assumptions are implicit. | Medium | Methodology sheet in Excel (Configurable Assumptions vision). Policy agent + validation results provide the content. | Planned |
| **No project-level knowledge accumulation** — Each pipeline run starts fresh. Confirmed variable mappings, user preferences, and past decisions aren't carried forward. | Low-Medium | Variable selection persistence (2.4c) is the first step. Longer-term: project-level config that accumulates across runs. | Identified |
| **Hidden assignment variables don't produce distribution tables** — When a question's answers are stored as hidden variables (e.g., `hLOCATIONr1–r16` for S9), the pipeline correctly hides them but misses the distribution table that shows assignment frequency. Requires parent-variable linking in DataMapProcessor or verification agent awareness. | Low | Accept gap for now. Future: detect when hidden variable families relate to a visible question and auto-generate distribution tables. | Known limitation |
| **No dual-base reporting for skip logic questions** — When a question has skip logic, only the filtered base is reported. An experienced analyst might also report the same table with an all-respondents base for context (e.g., "what share of everyone had 2+ people present" vs "among those not alone, group size distribution"). Current behavior is correct; this is a future quality-of-life enhancement. | Low | Future: optional "also report unfiltered" flag on skip logic tables, generating both versions with clear base text. | Known limitation |
| **`deriveBaseParent()` doesn't collapse parent references for loop variables** — In LoopCollapser.ts, when a collapsed variable's parent is itself a loop variable being collapsed, `deriveBaseParent()` returns the uncollapsed parent name (e.g., `A7_1` instead of `A7`). DataMapGrouper then uses this uncollapsed parent as the `questionId`, causing loop variables like A7 to appear with inconsistent naming (e.g., `a7_1` instead of `a7`). Non-loop parents like A4 are unaffected. | Low | Fix `deriveBaseParent()` to check if the derived parent is in the collapse map and resolve it to the collapsed form. Straightforward code fix. | Known limitation |

---

*Created: January 22, 2026*
*Updated: February 8, 2026*
*Status: Planning*
