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
| 1-3b | Bug capture, VerificationAgent, Significance testing, SPSS validation | Complete |
| 4 | Evaluation Framework (golden datasets) | In Progress |
| 5 | Primary dataset iteration (leqvio) | Not Started |
| 6 | Loop/Stacked data support (Tito's) | Not Started |
| 7 | Strategic broader testing (5 datasets by failure mode) | Not Started |

**Exit Criteria**: 5 datasets passing across failure mode categories, documented accuracy metrics.

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

**Implementation**: Add `outputFormat` parameter to pipeline config. Adjust ExcelFormatter to render based on setting.

**Level of Effort**: Low (1-2 hours)

---

### 2.2 Weighting Support

The Tito's dataset has weights. Many production surveys use weighted data.

**What's Needed**:
- Detect weight variable in SPSS file (usually named `weight`, `wt`, or similar)
- Apply weights in R script calculations (`weighted.mean()`, weighted frequencies)
- Show weighted N in output alongside unweighted N
- Adjust significance testing for weighted data (effective sample size)

**Implementation**:
- Add weight detection to DataMapProcessor
- Update RScriptGeneratorV2 to use weighted calculations when weight variable present
- Update Excel output to show both weighted and unweighted bases

**Level of Effort**: Medium (half day to full day)

---

### 2.3 Multi-Sheet Workbooks

Current output is a single sheet. Production users often want:
- One sheet per banner group
- Separate sheet for table of contents
- Separate sheet for methodology/notes

**Implementation**:
- ExcelFormatter already uses ExcelJS which supports multiple sheets
- Add config option: `sheetStrategy: "single" | "per-banner-group" | "per-table"`
- Generate TOC sheet with hyperlinks to tables

**Level of Effort**: Medium (half day)

---

### 2.4 Stat Testing Configuration

Current: 90% confidence, unpooled z-test, no minimum base.

Users may need:
- Different confidence levels (95%, 99%)
- Minimum base size for sig testing (e.g., n < 30 → no letters)
- Different test methods (pooled vs unpooled, t-test for small samples)
- Suppress letters vs show with warning

**Implementation**:
- Add `sigTestConfig` object to pipeline config
- Pass config to RScriptGeneratorV2
- Make R script parameterized based on config

```typescript
sigTestConfig: {
  confidenceLevel: 0.90 | 0.95 | 0.99,
  minBase: number | null,  // null = no minimum
  method: "unpooled_z" | "pooled_z" | "t_test",
  smallBaseHandling: "suppress" | "show_warning" | "show_anyway"
}
```

**Level of Effort**: Medium (half day)

---

### 2.5 Input Format Flexibility

From the Antares conversation:
- PDF survey documents (currently Word only)
- Excel banner plans (currently Word only)
- Various questionnaire numbering formats (Q_S2, S2, QS2, etc.)

**PDF Survey Support**:
- Already using document parsing; PDF support may work with minimal changes
- Test with PDF versions of existing surveys
- May need pdf-parse or similar library

**Excel Banner Plans**:
- Parse Excel into same intermediate structure as Word
- Actually easier than Word - columns/rows are explicit
- Could potentially skip BannerAgent entirely for well-structured Excel plans

**Questionnaire Format Robustness**:
- Current architecture already handles this via AI pattern matching
- Validation: test with surveys using different numbering conventions
- May need prompt refinements based on failure cases

**Level of Effort**: Low-Medium (PDF: 2-4 hours, Excel: 2-4 hours, Format robustness: part of broader testing)

---

### 2.6 Question Text in Table Outputs

**Current State**: Tables have `questionId` (e.g., "S5") but not the full question text. The question text is available in the DataMap output but isn't being propagated to final table definitions.

**What's Needed**:
- Add `questionText` field to `ExtendedTableDefinition` schema
- Ensure question text flows from DataMap → TableAgent → VerificationAgent → final output
- Display question text when rendering tables (Excel, UI) to provide context
- This helps users understand what question the table represents
- May also help VerificationAgent find the right section in the survey document

**Why It Matters**:
- Users need context when reviewing tables (especially when question IDs are cryptic)
- Future AI agents (like VerificationAgent) can use question text to better locate relevant sections in survey documents
- Improves overall output quality and usability

**Implementation**:
- Question text is already available in DataMapProcessor output (`questionText` field)
- TableAgent already receives this in context
- Need to ensure it's included in `ExtendedTableDefinitionSchema` (currently missing)
- Can likely be deterministically added rather than requiring VerificationAgent to extract it
- Update ExcelFormatter to display question text above table title

**Level of Effort**: Low (1-2 hours) - mostly schema updates and ensuring data flows through pipeline

---

### 2.7 Banner Inference (Future Enhancement)

Raina's comment: "If they don't have to spec out a banner, they can just say, generally, like, I want to look at specialty, tiers, and whatever, and then it would just do it."

**Concept**: Generate suggested banner from survey + datamap without explicit banner plan.

**Implementation Sketch**:
1. Analyze datamap for common cut variables (demographics, segments, tiers)
2. Rank by likely usefulness (sample distribution, typical cut patterns)
3. Generate suggested banner groups
4. Present to user for approval/modification via HITL

**Level of Effort**: High (this is a significant feature, defer to later phase)

**Note**: This is a differentiator but not required for initial production use.

---

### 2.8 Sample Size Review (HITL Enhancement)

After R calculates base sizes, show sample counts to user before final output:
- Display base n per cut across all banner groups
- Flag zero-count (n=0) and low-count (n<30) cuts
- User can mark cuts to exclude from final output or acknowledge warnings

**Why It Matters**: Catches data issues before they appear in final deliverables. Users see exactly what sample sizes they're working with.

**Level of Effort**: Medium (integrate with existing HITL flow)

---

### 2.9 Demo Table at Top

Joe's tabs include a summary "demo table" at the very top:
- Takes all banner cuts and displays them as ROWS instead of columns
- Shows distribution/breakdown for each cut
- Gives quick high-level overview of sample composition
- Appears before all other tables

**Implementation**: Derived table generated in R using bannerGroups metadata. Similar pattern to T2B/B2B derived tables.

**Level of Effort**: Medium (new table type, but follows existing patterns)

---

## Phase 3: Productization

What's needed to run as a service others can use.

### 3.1 Cloud Deployment

**Current**: Runs locally via CLI (`npx tsx scripts/test-pipeline.ts`)

**Target**: Cloud-hosted API that accepts inputs and returns outputs

**Components Needed**:
- API layer (Next.js API routes or separate service)
- File upload handling (S3 or similar)
- Job queue for async processing (pipeline takes 30-60 mins)
- Result storage and retrieval
- Authentication/authorization

**Architecture Options**:

| Option | Pros | Cons |
|--------|------|------|
| **Vercel + AWS** | Easy Next.js deploy, managed infra | Function timeouts for long jobs |
| **AWS Lambda + Step Functions** | Handles long-running jobs, scalable | More complex setup |
| **Railway/Render** | Simple deployment, supports long processes | Less enterprise-ready |
| **Self-hosted (EC2/Docker)** | Full control | Ops burden |

**Recommendation**: Start with Vercel for UI + AWS Lambda/Step Functions for pipeline execution. Job queue via SQS.

**Level of Effort**: High (1-2 weeks for basic deployment, more for production hardening)

---

### 3.2 Multi-Tenant Support

**What's Needed**:
- User accounts and authentication
- Project/job isolation
- Usage tracking and quotas
- Audit logging

**Implementation**:
- Auth: Clerk, Auth0, or NextAuth
- Database: Postgres for user/project metadata
- File storage: S3 with user-scoped prefixes
- Job tracking: Database records with status updates

**Level of Effort**: Medium-High (3-5 days for basic multi-tenancy)

---

### 3.3 Self-Service UI

**Current**: Developer runs CLI commands

**Target**: Web UI where users can:
1. Upload files (SPSS, datamap, survey, banner plan)
2. Configure options (output format, sig testing, etc.)
3. Review HITL prompts (uncertain variable mappings)
4. Monitor job progress
5. Download results

**Implementation**:
- Build on existing Next.js app structure
- File upload with drag-and-drop
- Real-time job status (WebSocket or polling)
- HITL review interface (already prototyped)
- Results download page

**Level of Effort**: High (1-2 weeks for functional UI)

---

### 3.4 Cost Management

Running AI models costs money. For external users:
- Track token usage per job
- Estimate costs before running
- Usage-based billing or credit system
- Cost optimization (model selection, caching)

**Implementation**:
- Log token counts from each agent call
- Store in database per job/user
- Dashboard for usage visibility
- Optional: tiered pricing

**Level of Effort**: Medium (2-3 days for tracking, more for billing integration)

---

### 3.5 Marketing Site Architecture

**Current Approach (Monorepo)**:
Keep everything in one Next.js repo, organized with route groups:

```
/app
├── (marketing)/           # Marketing pages
│   ├── page.tsx           # Landing page at /
│   ├── pricing/page.tsx   # /pricing
│   └── layout.tsx         # Marketing layout (no auth)
│
├── (product)/             # The actual app
│   ├── dashboard/         # /dashboard
│   ├── projects/          # /projects
│   └── layout.tsx         # Product layout (auth, sidebar)
```

This keeps things simple while we're iterating on reliability and core features.

**Future Approach (Split When Commercializing)**:

When ready for external users (Antares, etc.), split into separate projects:

| Domain | What It Serves | Where It Lives |
|--------|----------------|----------------|
| `hawktab.ai` | Marketing site (landing, pricing, docs) | Separate repo or Webflow/Framer |
| `app.hawktab.ai` | The product | This repo |

**Why Split Eventually**:
- **Deployment risk**: Marketing changes shouldn't risk breaking the production app
- **Change velocity**: Marketing iterates fast (copy, pricing, testimonials); app needs stability
- **Who edits**: Marketing person can update landing page without touching code
- **Blast radius**: Bug in marketing doesn't take down the product

**Migration Workflow**:
1. Create new marketing site (new repo, or Webflow/Framer)
2. Migrate content from `(marketing)` folder
3. Configure DNS: `hawktab.ai` → marketing, `app.hawktab.ai` → product
4. Delete `(marketing)` folder from this repo
5. Cross-link between sites (marketing "Get Started" → app, app "Home" → marketing)

**Level of Effort**: Low now (just folder organization), Medium later (migration + DNS)

---

### 3.6 Logging and Observability

Replace scattered `console.*` calls with structured, context-rich logging.

**What's Needed**:
- Wide events for pipeline operations (each agent call, R execution, etc.)
- Environment-aware log levels (verbose in dev, errors only in prod)
- Correlation IDs to trace a job through all stages
- Error monitoring integration (Sentry)

**Implementation**:
- Use structured logging library (pino or similar)
- Add context to each log (jobId, userId, stage)
- Sentry for error alerting and stack traces
- PostHog for usage analytics (minimal)

**Level of Effort**: Medium (2-3 days for full implementation)

---

## Phase 4: Enterprise Features (Future)

Features for larger deployments:

- **SSO/SAML**: Enterprise authentication
- **Role-based access**: Admin, user, viewer roles
- **API access**: Programmatic access for integrations
- **White-labeling**: Custom branding for resellers
- **On-premise deployment**: For data-sensitive clients
- **Batch processing**: Run multiple projects in parallel
- **Template management**: Save and reuse banner/table configurations
- **Version history**: Track changes to outputs over time

---

## Long-term Vision: Beyond Tabs

### The Market Reality

From the Antares conversation (January 2026):

> **Bob**: "I think the industry will never go away from full tables just because that's who and what we are."

Traditional crosstabs aren't going anywhere. But tools like Displayr and Q are adding AI features for exploration—not just tab production. The industry is shifting toward wanting both: reliable tabs AND the ability to ask follow-up questions.

### The Opportunity

Once the pipeline is rock-solid reliable, we have something valuable: a **validated data foundation**.

Every crosstab run produces artifacts:
- Validated data map (variables verified against real data)
- Approved banner (cuts that work, human-validated via HITL)
- Survey context (question text, scale meanings)
- Proven R expressions (code that actually executed)

These artifacts aren't just byproducts—they're the foundation for follow-up queries.

### First: Feedback-Driven Regeneration
Before adding exploration, add a feedback capability where a user can flag a table as unhelpful and specify a replacement. The system regenerates the output with those updates, within constrained rules. This provides an entry-level workflow toward exploration while still grounded in validated artifacts.

### The Vision: Constrained but Conversational

After tabs are delivered, users could interact via chat:

> "Show me Q5 by region"
> "Break out the top 3 brands by tier"
> "What if we combined Tier 1 and 2?"

The agent doesn't start from scratch. It uses the validated artifacts:
- Already knows the table formats from the initial run
- Already has working R expressions for each cut
- Just needs to recombine existing pieces or add new variables
- Calls the existing pipeline tools (R script generator, significance testing)
- Surfaces base sizes via HITL before finalizing

**The constraint is invisible to the user.** They experience "I ask questions, I get accurate tables." But architecturally, the AI is grounded in artifacts that already executed successfully—it can't hallucinate variables that don't exist.

### Why This Is More Reliable Than Alternatives

Standard AI-on-data failure mode:
1. User asks question
2. AI interprets data structure (often wrong)
3. AI generates code (often wrong)
4. Output looks plausible but is subtly incorrect

HawkTab inverts this:
1. Validation happens once, with human-in-the-loop
2. AI is constrained to artifacts that already worked
3. Follow-up queries inherit the validated foundation
4. Errors fail to execute rather than producing plausible-looking wrong answers

### When to Build This

After:
1. Reliability plan is complete
2. External users (Antares, others) are using the product successfully
3. Clear product-market fit for crosstabs

Then prototype the conversational interface. Test whether "constrained but comprehensive" feels right to users.

---

## Prioritized Roadmap

### Near-Term (Complete Reliability)
1. Finish Part 4: Evaluation Framework
2. Part 5: Primary dataset iteration
3. Part 6: Loop/Stacked data support
4. Part 7: Strategic broader testing

### Short-Term (Feature Completeness)
1. Percents/Frequencies toggle (easy win)
2. Question text in table outputs (quick context improvement)
3. Weighting support (needed for Tito's anyway)
4. Multi-sheet workbooks
5. Stat testing configuration
6. PDF + Excel input support
7. Demo table at top (sample composition overview)
8. Sample size review in HITL flow

### Medium-Term (Productization MVP)
1. Cloud deployment (API + job queue)
2. Basic authentication (WorkOS AuthKit)
3. Simple web UI for upload/download
4. HITL review interface (polish existing)
5. Marketing site architecture (route groups now, prepare for split)
6. Logging and observability (Sentry + structured logs)

### Longer-Term (Production Ready)
1. Multi-tenant support
2. Usage tracking and billing
3. Full self-service UI
4. Split marketing site to separate project (Webflow/Framer or dedicated repo)
5. Banner inference (AI-generated cuts from survey + datamap)
6. Enterprise features as needed

### Future (Post Product-Market Fit)
1. Conversational interface for follow-up queries
2. Chat-based agent using validated artifacts from initial tabs

---

## Technology Stack (Decided)

Based on research and account setup, the following stack is planned:

| Component | Technology | Why |
|-----------|------------|-----|
| **Authentication** | WorkOS AuthKit | Free for 1M MAUs, SSO/SAML available for enterprise later |
| **Database** | Convex | Real-time subscriptions, TypeScript-native, serverless |
| **File Storage** | Cloudflare R2 | S3-compatible, no egress fees |
| **R Execution** | Railway Docker | Vercel serverless doesn't have R; Railway supports long processes |
| **Error Monitoring** | Sentry | Know when things break, stack traces |
| **Analytics** | PostHog | Usage tracking (minimal) |
| **Hosting** | Vercel | Easy Next.js deployment for UI layer |

**Key Architectural Decisions**:
- **Real-time updates**: Convex provides subscriptions - when job status changes, all clients update automatically (no polling)
- **Project-based isolation**: Each crosstab job is a distinct project with its own files and outputs
- **Remote R execution**: Railway Docker container exposes HTTP endpoint for R scripts

**Accounts Created**:
- Convex: hawktab-ai
- Cloudflare R2: hawktab-ai bucket
- Railway: account ready
- Sentry: javascript-nextjs project
- PostHog: hawktab-ai

---

## Validation from Antares Conversation

| What They Asked | Does System Handle It? | Notes |
|-----------------|------------------------|-------|
| Different questionnaire formats | Yes | AI pattern matching |
| Banner plans with "just words" | Yes | HITL for uncertain mappings |
| Percents only / frequencies only | Not yet | Easy to add |
| Stacked/loop data | Not yet | Part 6 of reliability plan |
| Different stat testing | Partially | Need configuration options |
| Various input file types | Partially | Need PDF + Excel support |

**Bob's quote**: "I've not seen anybody kind of going down this road... commercially speaking."

This validates that the approach is novel and worth pursuing.

---

## Success Metrics

### Reliability Phase
- 5 datasets passing across failure mode categories
- Documented accuracy metrics (strict vs practical)
- <5% error rate on tested scenarios

### Feature Completeness
- All output format options working
- Weighting produces correct results vs manual calculation
- Multi-sheet workbooks render correctly

### Productization
- Average job completion time <45 minutes
- 99% uptime for API
- User can complete full workflow without developer assistance

### Production Ready
- External users (Antares) successfully running projects
- Positive feedback on output quality
- Cost per job within acceptable range

---

*Created: January 22, 2026*
*Updated: January 24, 2026 (consolidated from future-enhancements.md)*
*Status: Planning*
