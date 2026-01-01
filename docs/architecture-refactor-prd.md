# HawkTab AI: Architecture & Development Roadmap

## Executive Summary

HawkTab AI automates market research crosstab generation for Hawk Partners' 80-person team, replacing the current outsourcing workflow (sending files to Joe or fielding partners).

**Core Thesis**: The MVP works, but reliability issues stem from architectural limitations. By addressing AI provider compliance (Azure OpenAI), data source integration (Decipher API), and validation rigor, we achieve production reliability.

**Target Outcome**: Team members upload survey materials and receive accurate, statistically-tested crosstabs.

---

## Current Status

| Phase | Status | Description |
|-------|--------|-------------|
| **Phase 1: Azure OpenAI** | **Complete** | Migrated to Vercel AI SDK + Azure OpenAI |
| **Phase 2: Decipher + Reliability** | Not Started | API integration, agent flow improvements |
| **Phase 3: Team Access** | Not Started | Auth, database, file storage, deployment |

**What's Working Now**:
- Processes 192+ variables with 130+ parent relationships
- 99% SPSS variable match rate
- Group-by-group agent processing with confidence scoring
- Azure OpenAI compliance (firm data stays in Azure)

---

## Phase Overview

### Phase 1: Azure OpenAI Migration
**Status**: Complete

Migrated from OpenAI Agents SDK to Vercel AI SDK with Azure OpenAI provider for Hawk Partners compliance.

**Key Changes**:
- `@openai/agents` → `ai` + `@ai-sdk/azure`
- Task-based model selection: `getReasoningModel()` (o4-mini) and `getBaseModel()` (gpt-5-nano)
- Tracing replaced with structured logging (Sentry in Phase 3)

**Details**: See `docs/implementation-plans/phase-1-implementation-plan.md`

---

### Phase 2: Decipher API + Agent Flow Improvements
**Status**: Not Started | **Priority**: High

This phase addresses the core reliability issues by:
1. **Decipher API Integration** - Get skip logic from the source instead of inferring from CSV
2. **Agent Flow Improvements** - Add validation agents to catch errors before R execution

#### Why Decipher First?

The current system parses CSV data maps using a state machine that infers parent-child relationships and skip logic. This is inherently fragile. Decipher already has all this information—the data map CSV comes from Decipher in the first place.

**What Decipher API Provides**:
| Capability | How It Helps |
|------------|--------------|
| Survey structure export | Complete questionnaire with all questions, options, routing |
| Skip logic / conditions | `cond` attributes show exactly who sees each question |
| Variable metadata | All variable names, types, allowed values from source |
| Data export | Pull response data directly, no SPSS upload needed |

#### Agent Flow Improvements

The current two-agent system (BannerAgent → CrosstabAgent) validates syntax but not semantics. The improved flow adds validation steps:

```
Current:  Banner PDF → BannerAgent → CrosstabAgent → R Script → Errors Found Too Late
                                         ↓
Proposed: Banner PDF → BannerExtractAgent → BannerValidateAgent → CrosstabAgent → DataValidator → Human Review → R Script
                              ↓                    ↓                                    ↓
                         Extract structure    Check skip logic                    Check sample counts
                                              "Can S2=1 AND S2a=1 ever be true?"  "Does this cut have n>0?"
```

**New Components**:

| Component | Type | Purpose |
|-----------|------|---------|
| **BannerValidateAgent** | AI Agent | Validates banner cuts against skip logic before variable matching |
| **DataValidator** | Code (not AI) | Runs sample queries to verify cuts produce results |
| **Human Review UI** | UI Component | Shows confidence scores AND sample counts for review |

**Details**: See `docs/architecture/agent-flow-overview.md` for flow diagrams and `docs/implementation-plans/phase-2-decipher-plan.md` (to be created)

---

### Phase 3: Team Access
**Status**: Not Started | **Priority**: After Phase 2

Enables the 80-person team to use the tool with proper authentication, persistent storage, and error visibility.

| Component | Technology | What It Replaces |
|-----------|------------|------------------|
| Authentication | WorkOS AuthKit | No auth (public access) |
| Database | Convex | Filesystem (`temp-outputs/`) |
| File Storage | Cloudflare R2 | Local filesystem |
| R Execution | Railway Docker | Local R installation |
| Error Monitoring | Sentry | Console logging |
| Analytics | PostHog (minimal) | None |

**Why Phase 3 After Phase 2?**
- Phase 2 improvements can be tested locally with existing file-based flow
- Phase 3 infrastructure is well-understood (service integration, not novel development)
- Decipher integration is the core technical risk—tackle it first

**Details**: See `docs/implementation-plans/phase-3-team-access-plan.md`

---

## Success Criteria

### Internal Launch Checkpoint (After Phase 3)
- [ ] Hawk Partners team can log in and generate crosstabs
- [ ] Output quality matches or exceeds Joe's/fielding partner's tabs
- [ ] Uses Azure OpenAI (compliance)
- [ ] Projects are separated per-user
- [ ] Errors visible in Sentry

### Reliability Criteria (Phase 2)
- [ ] Zero-count cuts detected BEFORE R execution
- [ ] Skip logic violations flagged with suggested fixes
- [ ] Sample counts shown in human review UI
- [ ] Confidence scores calibrated (AND logic = lower confidence)

---

## Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **AI SDK** | Vercel AI SDK | Azure OpenAI required for compliance; OpenAI SDK doesn't support Azure |
| **Database** | Convex | First-class WorkOS integration, TypeScript-native, real-time subscriptions |
| **Authentication** | WorkOS AuthKit | Free for 80 users, Convex integration, SSO available later |
| **File Storage** | Cloudflare R2 | S3-compatible, generous free tier, no egress fees |
| **R Execution** | Railway Docker | Vercel serverless doesn't have R; Railway is simple Docker hosting |
| **Error Monitoring** | Sentry | Industry standard, Next.js SDK with source maps |
| **Analytics** | PostHog (basic) | Low effort, free tier, defer advanced features |
| **Survey Source** | Decipher API | Skip logic from source; CSV parsing is fragile |

---

## Document Structure

```
docs/
├── architecture-refactor-prd.md          # This file - high-level roadmap
├── architecture/
│   └── agent-flow-overview.md            # Detailed agent flow diagrams (Phase 2 design)
└── implementation-plans/
    ├── phase-1-implementation-plan.md    # Azure OpenAI migration (COMPLETE)
    ├── phase-2-decipher-plan.md          # Decipher + reliability (to be created)
    └── phase-3-team-access-plan.md       # Auth + database + deploy
```

---

## References

### Phase 1 (Complete)
- [Vercel AI SDK Documentation](https://ai-sdk.dev/docs/introduction)
- [Azure OpenAI Provider](https://ai-sdk.dev/providers/ai-sdk-providers/azure)

### Phase 2 (Decipher + Reliability)
- [Decipher API Documentation](https://docs.developer.focusvision.com/docs/decipher/api)
- [Decipher Python Library](https://pypi.org/project/decipher/)
- [Skip Logic Documentation](https://decipher.zendesk.com/hc/en-us/articles/360010277353-Adding-Condition-Skip-Logic)

### Phase 3 (Team Access)
- [Convex + WorkOS AuthKit](https://docs.convex.dev/auth/authkit/)
- [Sentry Next.js](https://docs.sentry.io/platforms/javascript/guides/nextjs/)
- [PostHog Next.js](https://posthog.com/docs/libraries/next-js)
- [Cloudflare R2](https://developers.cloudflare.com/r2/)

---

*Created: December 31, 2025*
*Last Updated: January 1, 2026*
*Status: Phase 1 Complete, Phase 2 Ready to Start*
