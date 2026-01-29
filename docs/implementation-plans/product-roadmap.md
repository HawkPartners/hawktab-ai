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

---

## Phase 2: Feature Completeness

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

### 2.5b AI-Generated Banner from Research Objectives

When no banner plan is provided—or user explicitly chooses "AI generate cuts"—the system generates a suggested banner.

**Why It Matters**: Antares mentioned clients who send banner plans with "just words" or no spec at all. This feature handles that case and could be a differentiator.

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

### 3.4 Cost Management (Internal)

**Goal**: Understand our cost structure so we can price the product appropriately. This is for us, not exposed to users.

**Part 1: AI Cost Tracking**

Track token usage for every AI operation:

| Operation | When It Happens | Track |
|-----------|-----------------|-------|
| BannerAgent | Every job | tokens, model, duration |
| CrosstabAgent | Every job | tokens, model, duration |
| TableAgent | Every job | tokens, model, duration |
| VerificationAgent | Every job | tokens, model, duration |
| AI-Generated Banner (2.5b) | When no banner provided | tokens, model |
| Table Regeneration (2.10) | User feedback | tokens per regeneration |

Store in Convex: `aiUsage` table with `jobId`, `orgId`, `operation`, `tokens`, `cost`, `timestamp`

**Part 2: Service Cost Tracking**

| Service | Current Tier | Paid Tier Threshold | Projected Cost |
|---------|--------------|---------------------|----------------|
| Vercel | Free/Pro | Bandwidth, functions | ~$20/mo |
| Convex | Free | 1M function calls | ~$25/mo |
| Cloudflare R2 | Free | 10GB storage, 10M reads | ~$5/mo |
| Railway | Free tier | Compute hours | ~$20/mo |
| WorkOS | Free (1M MAU) | Enterprise SSO | $0 for now |
| Sentry | Free | 5K errors/mo | $0 for now |
| OpenAI/Azure | Pay-per-token | N/A | Variable |

**Part 3: Pricing Model**

Based on cost analysis, define pricing (ballpark):
- **Per-project pricing**: ~$300/project (covers AI + infrastructure)
- **Monthly subscription**: ~$3,000/month unlimited (for heavy users)
- **Enterprise**: Custom pricing with SLA

Revisit after tracking real usage patterns.

**Part 4: Internal Dashboard**

Simple admin page showing:
- Total AI spend this month (by operation type)
- Service costs (from billing APIs where available)
- Cost per job (average, min, max)
- Projected monthly burn rate

**Level of Effort**: Medium (tracking infrastructure + simple dashboard)

---

### 3.5 Logging and Observability

**Detailed Plan**: See `logging-implementation-plan.md` for full technical specification.

**Part 1: Structured Logging**

Replace 134 scattered `console.*` calls with structured, context-rich logging:

- **Logger foundation**: Centralized `src/lib/logger.ts` with log levels (error, warn, info, debug, trace)
- **Wide events**: Single rich event per pipeline run capturing all context
- **Correlation IDs**: Trace any job through all agents/phases via `sessionId`
- **Environment-aware**: Verbose in dev, structured JSON in production

**Implementation Order** (from logging plan):
1. Create logger foundation
2. Migrate console.* calls (start with main API route, then agents)
3. Implement wide event pattern
4. Integrate Sentry for error alerting

**Part 2: Product Analytics (PostHog)**

Track user behavior to understand how the product is used:

| Event | What It Tells Us |
|-------|------------------|
| `project_created` | How often are users creating projects? |
| `hitl_decision_made` | Are users overriding AI suggestions? Which ones? |
| `table_excluded` | Which tables do users not want? |
| `table_regenerated` | How often is feedback needed? What kind? |
| `banner_auto_generated` | Is the no-spec feature being used? |
| `download_completed` | Are users getting to the end of the flow? |
| `job_failed` | Where are failures happening? |

**Key Questions to Answer**:
- What % of HITL suggestions do users accept vs override?
- What's the average number of regenerations per project?
- Which tables are most commonly excluded?
- What's the drop-off rate at each pipeline stage?

**Implementation**:
- PostHog JS SDK in frontend
- Server-side events for pipeline operations
- Dashboard with key metrics

**Level of Effort**: Medium (logging migration 2-3 days, analytics 1-2 days)

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

---

*Created: January 22, 2026*
*Updated: January 29, 2026*
*Status: Planning*
