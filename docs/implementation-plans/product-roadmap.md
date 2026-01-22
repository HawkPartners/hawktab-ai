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

### 2.6 Banner Inference (Future Enhancement)

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

## Prioritized Roadmap

### Near-Term (Complete Reliability)
1. Finish Part 4: Evaluation Framework
2. Part 5: Primary dataset iteration
3. Part 6: Loop/Stacked data support
4. Part 7: Strategic broader testing

### Short-Term (Feature Completeness)
1. Percents/Frequencies toggle (easy win)
2. Weighting support (needed for Tito's anyway)
3. Multi-sheet workbooks
4. Stat testing configuration
5. PDF + Excel input support

### Medium-Term (Productization MVP)
1. Cloud deployment (API + job queue)
2. Basic authentication
3. Simple web UI for upload/download
4. HITL review interface (polish existing)

### Longer-Term (Production Ready)
1. Multi-tenant support
2. Usage tracking and billing
3. Full self-service UI
4. Enterprise features as needed

---

## Key Decisions to Make

| Decision | Options | Recommendation |
|----------|---------|----------------|
| **Hosting platform** | Vercel, AWS, Railway, Self-hosted | Start with Vercel + AWS Lambda |
| **Auth provider** | Clerk, Auth0, NextAuth, Custom | Clerk (fastest to integrate) |
| **Database** | Postgres, PlanetScale, Supabase | Supabase (Postgres + auth + storage) |
| **Job queue** | AWS SQS, Redis/BullMQ, Inngest | Inngest (serverless-friendly) |
| **File storage** | S3, Cloudflare R2, Supabase Storage | S3 (most mature) |

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
*Status: Planning*
