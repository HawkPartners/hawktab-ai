# HawkTab AI: Architecture & Development PRD

## Executive Summary

HawkTab AI is a market research crosstab automation system that processes survey data through an AI-powered pipeline. The primary goal is to replace Hawk Partners' current outsourcing workflow (sending files to Joe or fielding partners) with an internal tool that the entire 80-person team can use.

**Core Thesis**: The system works, but reliability issues stem from architectural limitations rather than fundamental flaws. By addressing data source integration (Decipher API), AI provider compliance (Azure OpenAI via Vercel AI SDK), persistence (shared access for the team), and validation rigor, we can achieve the reliability required for internal production use.

**Target Outcome**: Hawk Partners team members can upload their survey materials and receive accurate, statistically-tested crosstabs—replacing the current outsourcing workflow with faster turnaround and consistent quality.

---

## Scope & Expectations

### Primary Goal
Build a working crosstab automation tool for Hawk Partners' 80-person team, replacing current outsourcing to external vendors (Joe, fielding partners).

### Secondary Goal
Pilot with Bob's fielding company to validate external interest.

### What This Is NOT (Yet)
- A SaaS product competing with Displayr ($3,219/user/year makes them expensive, but they're established)
- A multi-tenant enterprise platform for arbitrary customers
- Something we're selling externally

The architecture is designed so we *could* productize later if the Hawk Partners pilot succeeds and Bob's pilot shows external demand. But that's Phase 3+ thinking.

### Success Criteria (Internal Launch)
- Hawk Partners team can log in and generate crosstabs
- Output quality matches or exceeds current outsourced tabs
- Uses Azure OpenAI (compliance requirement)
- Errors are visible and debuggable (Sentry)
- Projects are separated per-user/per-team (lesson learned from Fathom AI issues)

---

## Table of Contents

1. [Current State & Problem Analysis](#current-state--problem-analysis)
2. [Strategic Vision](#strategic-vision)
3. [Architecture Recommendations](#architecture-recommendations)
   - [Decipher API Integration](#1-decipherforsta-api-integration)
   - [Vercel AI SDK Migration](#2-vercel-ai-sdk-migration)
   - [Enterprise Authentication (WorkOS)](#3-enterprise-authentication-workos)
   - [Database Layer (Convex)](#4-database-layer)
   - [Async Job Processing](#5-async-job-processing)
   - [Observability (PostHog + Sentry)](#6-observability-posthog--sentry)
4. [Validation & Reliability System](#validation--reliability-system)
5. [Agent Architecture](#agent-architecture)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Testing Protocol](#testing-protocol)
8. [Technical References](#appendix-technical-references)

---

## Current State & Problem Analysis

### What the MVP Successfully Demonstrates

The current system operates through a three-phase pipeline:

1. **Phase 5 (Data Processing)**: Banner PDF/DOC extraction + Data Map CSV processing with dual output strategy (verbose/agent JSON)
2. **Phase 6 (Agent Validation)**: CrossTab Agent validation with group-by-group processing and confidence scoring
3. **Phase 7 (R Generation)**: R script generation, execution, and CSV/Excel export

**Current Capabilities**:
- Successfully processes 192+ variables with 130+ parent relationships
- Handles complex banner logic (specialty cuts, role-based filtering, sub-groups)
- Generates statistical summaries (N, Mean, Median, SD) across all banner cuts
- 99% SPSS variable match rate with confidence-based validation

### Core Issues Identified

| Issue | Root Cause | Evidence | Business Impact |
|-------|-----------|----------|-----------------|
| **AND vs OR logic errors** | Agent interprets banner expressions literally without understanding survey skip logic | `S2=1 AND S2a=1` produces 0 matches; S2a has 166 NAs, only 14 responses | Tables with 0% in cells that should have data |
| **Missing respondents** | NA values not captured by cuts; conditional variables combined incorrectly | HCP + NP/PA = 162, but Total = 180; `table(data$S2b)` shows 18 NAs | Totals don't sum correctly across cuts |
| **Zero-count cuts** | Sample composition not validated against cuts | Cards and Nephs produce 0 matches; `table(data$S2)` shows no value 3 for Nephs | Entire columns with 0% values |
| **Overconfident validation** | Agent validates syntax but not semantic correctness against actual data | Agent assigns 0.90 confidence to filters that produce 0 results | Users trust high confidence scores that produce wrong results |
| **OpenAI lock-in** | Built on OpenAI Agents SDK exclusively | Can't use Claude, Gemini, Azure OpenAI, or Bedrock | Can't offer enterprise customers Azure/Bedrock options |
| **No persistence** | File-based temp-outputs folder | No database, no user accounts | No history, no multi-user, no async job handling |
| **Fragile data map parsing** | State machine parsing of CSV relies on format consistency | Different data map formats break the system | Requires consistent input format |

### Why These Issues Matter

For InterRest Enterprises, reliability is non-negotiable. Market research deliverables go to clients who make business decisions based on the data. A crosstab showing 0% Cardiologists when there should be 106 destroys trust and creates rework.

---

## Strategic Vision

### What We're Building

A **production-ready crosstab automation platform** that:

1. **Integrates directly with survey platforms** (Decipher/Forsta) to eliminate parsing ambiguity
2. **Supports multiple AI providers** for enterprise flexibility and cost optimization
3. **Validates results against actual data** before presenting to users
4. **Persists project history** for collaboration, audit trails, and iterative refinement
5. **Processes asynchronously** so long R executions don't block the UI
6. **Self-heals** where agents can fix issues automatically rather than failing

### Success Criteria

- **Accuracy**: Generated crosstabs match manually-created reference tables 100%
- **Reliability**: System handles edge cases gracefully, never produces silently wrong results
- **Flexibility**: Customers can use their preferred AI provider (OpenAI, Azure, Anthropic, Bedrock)
- **Scalability**: Support multiple concurrent users and projects
- **Transparency**: Clear confidence scores and validation warnings for human review

---

## Architecture Recommendations

### 1. Decipher/Forsta API Integration

**Priority**: High | **Effort**: 3-5 days | **Impact**: Very High

> **This is the core technical risk.** Everything else in this document (Vercel AI SDK, Convex, WorkOS, etc.) is relatively straightforward service integration. The Decipher API integration is where the real development work happens—parsing survey structure, extracting skip logic, and making it work reliably with our validation system. Budget the most time here.

#### Why This Is a Game Changer

Currently, the system parses CSV data maps using a state machine that tries to infer:
- Parent-child relationships between variables
- Skip logic (which questions are conditional)
- Variable types and allowed values

This is inherently fragile. Different data map formats, encoding issues, or unusual structures break the parsing.

**Decipher already has all this information**. The data map CSV comes from Decipher in the first place. By going to the source, we get:

- **Explicit skip logic**: "ASK IF S2=6 OR 7" is stored in the survey structure
- **Complete variable definitions**: Including variables like S2b that might not be in a minimal data map
- **Question types and routing**: The survey XML contains the full questionnaire structure
- **Consistency**: API responses are structured, not freeform CSVs

#### Decipher API Capabilities

Based on [Forsta API Documentation](https://docs.developer.focusvision.com/docs/decipher/api):

| Capability | How It Helps |
|------------|--------------|
| **Survey structure export** | Get complete questionnaire with all questions, options, routing |
| **Skip logic / conditions** | `cond` attributes show exactly who sees each question |
| **Variable metadata** | All variable names, types, allowed values from source |
| **Data export** | Pull response data directly, no SPSS upload needed |
| **Python library** | [decipher package on PyPI](https://pypi.org/project/decipher/) simplifies integration |

#### Implementation Approach

**Step 1: Connection Setup**
```typescript
// User settings or project setup
interface DecipherConnection {
  apiKey: string;          // Stored encrypted in database
  baseUrl: string;         // e.g., "https://v2.decipherinc.com/api/v1/"
  defaultSurveyPath?: string;
}
```

**Step 2: Survey Import**
```typescript
// Replace CSV upload with Decipher fetch
async function importFromDecipher(surveyPath: string): Promise<{
  variables: Variable[];      // Complete variable definitions
  skipLogic: SkipRule[];      // Explicit routing conditions
  questions: Question[];      // Full questionnaire structure
  responseData?: Buffer;      // Optional: pull data directly
}> {
  // Use Decipher REST API to fetch survey structure
  // Parse XML/JSON response into structured data
}
```

**Step 3: Skip Logic Validation**
```typescript
// When validating banner cuts, check skip logic
function validateCutAgainstSkipLogic(
  cut: BannerCut,
  skipLogic: SkipRule[]
): ValidationResult {
  // Example: "S2=1 AND S2a=1"
  // Skip logic says S2a only asked if S2 IN (6,7)
  // Return warning: "S2a is conditional on S2=6,7; AND with S2=1 will match 0 records"
}
```

#### Fallback Strategy

Keep CSV upload as fallback for:
- Users without Decipher access
- Surveys from other platforms (Qualtrics, SurveyMonkey)
- Legacy projects

The system should support both paths:
1. **Decipher integration** (preferred, higher reliability)
2. **Manual upload** (fallback, current behavior with improvements)

---

### 2. Vercel AI SDK Migration

**Priority**: High | **Effort**: 2-3 days | **Impact**: High

#### Why This Is Required (Not Optional)

**Hawk Partners requires Azure OpenAI.** Sending firm data to OpenAI directly would raise compliance questions. Azure OpenAI is already approved.

The [OpenAI Agents SDK](https://openai.github.io/openai-agents-js/) locks you into OpenAI's direct API—it doesn't support Azure OpenAI. The Vercel AI SDK solves this:

| Requirement | Solution |
|-------------|----------|
| **Azure OpenAI compliance** | `@ai-sdk/azure` provider works out of the box |
| **Same code, different provider** | Switch providers via environment variable |
| **TypeScript-native** | Built for Next.js with Zod schema support |

#### Vercel AI SDK Benefits

Based on [AI SDK documentation](https://ai-sdk.dev/docs/introduction):

| Feature | Why It Matters |
|---------|----------------|
| **Azure OpenAI support** | Primary reason—compliance requirement |
| **Agent abstraction** | Define reusable agents with tools, structured outputs |
| **Type-safe streaming** | Built for React/Next.js with TypeScript throughout |
| **20M+ monthly downloads** | Battle-tested, low risk |
| **Future flexibility** | *If* we ever need Anthropic or others, it's one line change |

#### Migration Path

**Current Pattern (OpenAI Agents SDK)**:
```typescript
import { Agent, run } from '@openai/agents';

const agent = new Agent({
  name: 'CrosstabAgent',
  model: 'gpt-4o',
  instructions: '...',
  outputType: ValidatedGroupSchema,
  tools: [scratchpadTool]
});

const result = await run(agent, prompt);
```

**New Pattern (Vercel AI SDK 6)**:
```typescript
import { Agent } from 'ai';
import { azure } from '@ai-sdk/azure';

const crosstabAgent = new Agent({
  model: azure('gpt-4o'),  // Uses Azure OpenAI
  system: '...',
  tools: {
    scratchpad: { /* tool definition */ },
    validateCut: { /* tool definition */ }
  },
  structuredOutput: ValidatedGroupSchema
});

const result = await crosstabAgent.run(prompt);
```

#### Configuration

```typescript
// Simple Azure OpenAI configuration
import { azure } from '@ai-sdk/azure';

// Environment variables (already approved at Hawk Partners):
// AZURE_OPENAI_API_KEY
// AZURE_OPENAI_ENDPOINT
// AZURE_OPENAI_DEPLOYMENT_NAME

export function getModel() {
  return azure('gpt-4o');
}

// Future: If we ever need to switch providers for external customers,
// it's a one-line change to use openai() or anthropic() instead.
```

---

### 3. Team Authentication (WorkOS)

**Priority**: High | **Effort**: 1-2 days | **Impact**: High

#### Why We Need Auth

80 people at Hawk Partners need to log in and access their projects. We need:
- User accounts (who is this?)
- Project separation (my projects vs your projects)
- Basic access control (not everyone sees everything)

#### Why WorkOS AuthKit

| Need | WorkOS AuthKit |
|------|----------------|
| **80 users login** | Free up to 1M MAU |
| **Email/password** | Built-in |
| **Works with Convex** | First-class integration, zero JWT config |
| **Future SSO** | Available if we ever need it for external customers |

**Alternative Considered**: NextAuth with Azure AD. Would also work since Hawk Partners uses Azure. WorkOS is slightly more setup but more flexible if we productize later.

#### Cost

| Feature | Cost |
|---------|------|
| **AuthKit (User Management)** | Free up to 1M MAU |
| **Enterprise SSO** | $125/connection/month (only if external customers need it) |

For Hawk Partners internal use: **$0/month**.

#### WorkOS + Convex Integration

WorkOS is an **officially supported auth provider** in Convex with first-class integration:

```typescript
// Setup with single command
// npm create convex@latest -- -t react-vite-authkit

// Automatic provider setup
import { ConvexProviderWithAuthKit } from "@convex-dev/workos-authkit/react";

export function App() {
  return (
    <ConvexProviderWithAuthKit client={convex}>
      <YourApp />
    </ConvexProviderWithAuthKit>
  );
}

// Access auth in any Convex function
export const getProjects = query({
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Unauthenticated");

    const orgId = identity.orgId; // From WorkOS
    return ctx.db.query("projects")
      .withIndex("by_org", q => q.eq("orgId", orgId))
      .collect();
  },
});
```

**Developer Experience Benefits**:
- Auto-provisioned WorkOS dev environment per Convex deployment
- No manual JWT configuration required
- Organizations/roles sync automatically

#### Implementation Steps

1. **Create Convex + AuthKit project**: `npm create convex@latest -- -t react-vite-authkit`
2. **Configure WorkOS dashboard**: Email/password, basic branding
3. **Done** - Enterprise SSO/SCIM available later if needed for external customers

---

### 4. Database Layer (Convex)

**Priority**: High | **Effort**: 1-2 days | **Impact**: High

#### Why We Need Persistence

Current file-based approach (`temp-outputs/`) doesn't work for a team:

| Current Limitation | What 80 People Need |
|--------------------|---------------------|
| Files on one laptop | Everyone accesses their projects |
| No user accounts | Know who created what |
| No project history | Previous runs saved, not lost |
| No async jobs | Long R execution doesn't block UI |

This is the lesson from Fathom AI: projects need to be properly separated per-user.

#### Decision: Convex

[Convex](https://www.convex.dev/) is chosen because:
- **WorkOS integration** is first-class (one command setup)
- **TypeScript everywhere** - schema lives in codebase, Claude can see/modify it
- **Real-time by default** - job status updates UI automatically

**Trade-offs Accepted**:
- File storage requires Cloudflare R2 (addressed below)
- No self-hosting (not a Hawk Partners requirement)

*Supabase was considered and would also work, but Convex's WorkOS integration and TypeScript-native approach won out.*

#### Schema
```typescript
// convex/schema.ts - lives in your codebase, AI sees it
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  projects: defineTable({
    orgId: v.string(),
    name: v.string(),
    status: v.union(v.literal("draft"), v.literal("processing"), v.literal("complete")),
    createdAt: v.number(),
  }).index("by_org", ["orgId"]),

  jobs: defineTable({
    projectId: v.id("projects"),
    type: v.string(),
    status: v.string(),
    result: v.optional(v.any()),
  }).index("by_project", ["projectId"]),

  validationResults: defineTable({
    jobId: v.id("jobs"),
    cuts: v.array(v.object({
      name: v.string(),
      count: v.number(),
      confidence: v.number(),
      issues: v.array(v.string()),
    })),
    warnings: v.array(v.string()),
  }).index("by_job", ["jobId"]),
});
```

#### File Storage (Cloudflare R2)

Since Convex doesn't have built-in file storage, use **Cloudflare R2** (S3-compatible, generous free tier):

```typescript
// convex/files.ts
import { v } from "convex/values";

export const getUploadUrl = mutation({
  args: { projectId: v.id("projects"), filename: v.string(), contentType: v.string() },
  handler: async (ctx, { projectId, filename, contentType }) => {
    // Generate presigned URL for R2 upload
    const key = `${projectId}/${Date.now()}-${filename}`;
    const uploadUrl = await generateR2PresignedUrl(key, contentType);

    // Store file reference in Convex
    await ctx.db.insert("files", {
      projectId,
      filename,
      storageKey: key,
      contentType,
      uploadedAt: Date.now(),
    });

    return { uploadUrl, key };
  },
});
```

---

### 5. Async Job Processing

**Priority**: Medium | **Effort**: 1-2 days | **Impact**: Medium

#### Why Async Matters

R script execution can take 30+ seconds for complex crosstabs. Currently:
1. User uploads files
2. API processes synchronously
3. User waits with spinner
4. Timeout risk for long jobs

#### Proposed Flow

```
User Upload → Create Job → Return Job ID → Background Processing → Webhook/Poll for Status
```

#### Implementation Options

**Option A: Convex Built-in**
```typescript
// convex/jobs.ts
export const processProject = internalMutation({
  args: { projectId: v.id("projects") },
  handler: async (ctx, { projectId }) => {
    // Long-running processing here
    // Updates automatically sync to UI via real-time
  }
});
```

**Option B: Supabase Edge Functions + Queue**
```typescript
// supabase/functions/process-crosstab/index.ts
Deno.serve(async (req) => {
  const { projectId } = await req.json();
  // Process in background
  // Update job status in database
});
```

**Option C: External Queue (Inngest, Trigger.dev)**
```typescript
import { inngest } from "./client";

export const processCrosstab = inngest.createFunction(
  { id: "process-crosstab" },
  { event: "crosstab/process" },
  async ({ event, step }) => {
    await step.run("validate-cuts", async () => { /* ... */ });
    await step.run("generate-r", async () => { /* ... */ });
    await step.run("execute-r", async () => { /* ... */ });
  }
);
```

**Recommendation**: Use Convex's built-in job processing. Real-time subscriptions mean the UI automatically reflects job status changes without polling.

---

### 6. Observability (Sentry + PostHog)

**Priority**: High | **Effort**: 0.5 days | **Impact**: High

Two tools, minimal setup, essential visibility.

#### Sentry: Error Monitoring (Required)

[Sentry](https://sentry.io/) provides error tracking, performance monitoring, and session replay.

**Why Sentry**:
- **Industry standard**: Battle-tested error tracking
- **Next.js integration**: First-class SDK with source maps
- **Session replay**: See exactly what happened before errors
- **Performance monitoring**: Track slow API routes

**Setup**:

```bash
npx @sentry/wizard@latest -i nextjs
```

This creates:
- `sentry.client.config.ts` - Browser error tracking
- `sentry.server.config.ts` - Server error tracking
- `sentry.edge.config.ts` - Edge runtime tracking
- `instrumentation.ts` - Next.js instrumentation hook

**Configuration**:

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs';

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  environment: process.env.NODE_ENV,

  // Performance monitoring
  tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.1 : 1.0,

  // Session replay for debugging
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0, // Always capture on error

  // Ignore known non-issues
  ignoreErrors: [
    'ResizeObserver loop limit exceeded',
    'Non-Error promise rejection',
  ],
});
```

**Custom Error Context**:

```typescript
// Add context to errors for better debugging
Sentry.setContext('project', {
  projectId,
  orgId,
  phase: 'validation',
});

Sentry.setUser({
  id: userId,
  email: userEmail,
});
```

#### PostHog: Basic Usage Tracking (Optional but Low Effort)

[PostHog](https://posthog.com/) is free for 1M events/month. Add basic tracking to understand usage:

```typescript
// Just the essentials for an internal tool
posthog.capture('crosstab_generated', { projectId, success: true });
posthog.capture('crosstab_failed', { projectId, error: errorMessage });
```

**What to defer**: Feature flags, A/B testing, full funnel analytics. These are for when we have external customers to optimize for.

#### Setup Summary

| Tool | Effort | Command |
|------|--------|---------|
| **Sentry** | 30 min | `npx @sentry/wizard@latest -i nextjs` |
| **PostHog** | 30 min | `npm install posthog-js` + basic init |

---

## Validation & Reliability System

This section details the multi-layer validation approach to ensure accurate results.

### Layer 1: Prompt Calibration

**Goal**: Make confidence scores reflect actual uncertainty.

**Current Problem** (in `src/prompts/crosstab/production.ts`):
```
CONFIDENCE SCORING SCALE:
- 0.85-0.94: Multiple direct variables with logic (S2=1 AND S2a=1)
```

This gives 0.90 to `S2=1 AND S2a=1` even though AND logic with conditional variables is risky.

**Required Prompt Additions**:

```markdown
CONFIDENCE REDUCTION TRIGGERS:
- AND logic combining variables: reduce by 0.10-0.15
  (variables may have incompatible skip patterns or different respondent bases)
- Conditional variable indicators in question text:
  - "In what type of..." suggests conditional/follow-up question
  - "Of those who..." indicates filtered base
  - Variable only has values for subset of respondents
- Specialty + office type combinations:
  - When combining "what you are" (S2) with "where you work" (S2a)
  - Consider whether OR logic was intended instead of AND
  - Flag for human review if uncertain

SEMANTIC INTERPRETATION GUIDANCE:
- When banner says "S2=1 AND S2a=1" for a category like "Cards":
  - S2=1 likely means "is a Cardiologist"
  - S2a=1 likely means "works in a Cardiologist's office"
  - These may be mutually exclusive populations (physicians vs NP/PAs)
  - Consider: should this be OR (anyone in cardiology) rather than AND?
  - If uncertain, use OR and lower confidence to 0.70-0.75
```

**Implementation**: Update `src/prompts/crosstab/production.ts`

---

### Layer 2: Diagnostic Logging in R

**Goal**: Surface issues immediately in R output for human review.

**Current Gap**: R script runs silently; zero-count cuts not flagged.

**Required R Additions** (in `RScriptGenerator.ts`):

```r
# After defining cuts, add diagnostic section:
print("=== CUT DIAGNOSTICS ===")
cut_diagnostics <- data.frame(
  Cut = character(),
  N = integer(),
  Pct_of_Total = numeric(),
  NA_Count = integer(),
  stringsAsFactors = FALSE
)

total_n <- sum(cuts[["Total"]], na.rm = TRUE)

for (cut_name in names(cuts)) {
  n <- sum(cuts[[cut_name]], na.rm = TRUE)
  na_count <- sum(is.na(cuts[[cut_name]]))
  pct <- round(100 * n / total_n, 1)

  cut_diagnostics <- rbind(cut_diagnostics, data.frame(
    Cut = cut_name,
    N = n,
    Pct_of_Total = pct,
    NA_Count = na_count,
    stringsAsFactors = FALSE
  ))

  # Flag potential issues
  if (n == 0) {
    print(paste("WARNING: Cut", cut_name, "has ZERO matches"))
  }
  if (na_count > total_n * 0.1) {
    print(paste("WARNING: Cut", cut_name, "has", na_count, "NAs (",
                round(100*na_count/nrow(data),1), "%)"))
  }
}

# Check related cuts sum correctly
specialty_sum <- sum(cuts[["Cards"]], na.rm=TRUE) +
                 sum(cuts[["PCPs"]], na.rm=TRUE) +
                 sum(cuts[["Nephs"]], na.rm=TRUE) +
                 sum(cuts[["Endos"]], na.rm=TRUE) +
                 sum(cuts[["Lipids"]], na.rm=TRUE)

if (specialty_sum != total_n && specialty_sum > 0) {
  print(paste("WARNING: Specialty cuts sum to", specialty_sum,
              "but Total is", total_n, "- missing", total_n - specialty_sum))
}

write.csv(cut_diagnostics, "results/CUT_DIAGNOSTICS.csv", row.names = FALSE)
print("=== END DIAGNOSTICS ===")
```

**Output**: `results/CUT_DIAGNOSTICS.csv` with all cut counts for easy review.

---

### Layer 3: Pre-Execution Validation

**Goal**: Catch zero-count and sum-mismatch issues before finalizing output.

**Workflow Change**:
```
Current:  Agent Output → R Generation → Execute → Results (issues discovered too late)

Proposed: Agent Output → Quick Count Query → Validate → Flag Issues → R Generation
                                              ↓
                                    Auto-lower confidence
                                    Add validation warnings
```

**Implementation** (new file `src/lib/validation/CutValidator.ts`):

```typescript
interface CutValidationResult {
  cut: string;
  count: number;
  issues: ValidationIssue[];
  adjustedConfidence?: number;
}

interface ValidationIssue {
  type: 'zero_matches' | 'sum_mismatch' | 'high_na_rate' | 'logic_warning';
  message: string;
  suggestion?: string;
}

async function validateCuts(
  cuts: CutSpec[],
  spssPath: string,
  originalConfidences: Map<string, number>
): Promise<CutValidationResult[]> {

  // Run quick R script to get counts
  const counts = await runCountQuery(cuts, spssPath);
  const results: CutValidationResult[] = [];

  for (const cut of cuts) {
    const issues: ValidationIssue[] = [];
    let adjustedConfidence = originalConfidences.get(cut.name) || 0.5;

    // Check for zero matches
    if (counts[cut.name] === 0) {
      issues.push({
        type: 'zero_matches',
        message: `Cut "${cut.name}" matches 0 respondents`,
        suggestion: 'Check if AND should be OR, or verify variable values exist in data'
      });
      adjustedConfidence = Math.min(adjustedConfidence, 0.30);
    }

    // Check for high NA rate
    const naRate = counts[`${cut.name}_na`] / counts['Total'];
    if (naRate > 0.1) {
      issues.push({
        type: 'high_na_rate',
        message: `Cut "${cut.name}" has ${(naRate * 100).toFixed(1)}% NA values`,
        suggestion: 'Variable may be conditional or have missing data'
      });
      adjustedConfidence = Math.min(adjustedConfidence, 0.70);
    }

    results.push({
      cut: cut.name,
      count: counts[cut.name],
      issues,
      adjustedConfidence
    });
  }

  return results;
}
```

**Output Schema Addition** to `crosstab-output.json`:
```json
{
  "bannerCuts": [...],
  "validationResults": {
    "totalIssues": 3,
    "zeroCountCuts": ["Cards", "Nephs"],
    "sumMismatches": [{
      "group": "Role",
      "cuts": ["HCP", "NP/PA"],
      "expected": 180,
      "actual": 162,
      "missing": 18
    }],
    "confidenceAdjustments": {
      "Cards": { "original": 0.90, "adjusted": 0.30, "reason": "zero_matches" },
      "HCP": { "original": 0.97, "adjusted": 0.70, "reason": "sum_mismatch" }
    }
  }
}
```

---

### Layer 4: Skip Logic Validation (with Decipher)

**Goal**: Cross-reference cuts against explicit skip logic from survey platform.

When Decipher integration is available:
- Pull skip logic conditions for each variable
- Before validating `S2=1 AND S2a=1`, check if S2a is conditional
- If skip logic shows `S2a ASK IF S2 IN (6,7)`, warn that combining with S2=1 will produce 0 matches
- Suggest: "Consider using OR instead of AND, or use S2=1 alone for Cardiologists"

---

### Layer 5: Human Review Interface (Future)

**Goal**: Surface validation issues prominently for human correction.

**UI Elements**:
- Red flag on cuts with zero matches
- Yellow warning on cuts with sum mismatches
- Expandable "Validation Details" panel showing diagnostics
- "Suggest Fix" button that proposes alternative R syntax
- Confidence meter with color coding (green > 0.85, yellow 0.60-0.85, red < 0.60)

---

### Validation Data Contracts

```typescript
type CutDiagnostic = {
  name: string;
  count: number;
  percentOfTotal: number;
  naCount: number;
  issues: string[];
}

type ValidationWarning = {
  type: 'zero_matches' | 'sum_mismatch' | 'high_na' | 'confidence_adjusted';
  cuts: string[];
  message: string;
  suggestion?: string;
  originalConfidence?: number;
  adjustedConfidence?: number;
}
```

---

## Agent Architecture

### Overview

The system uses specialized agents for different tasks. The key innovation is **self-healing capabilities** where agents can fix issues automatically rather than failing.

### Agent 1: Banner Agent

**Purpose**: Extract banner structure from PDF/DOC files.

**Input**: Banner plan document (PDF/DOC/DOCX)
**Output**: Structured banner groups with columns, cuts, stat letters

**Process**:
1. Convert PDF to images (300 DPI, PNG format)
2. Send images to vision-capable AI model
3. Extract banner groups, columns, and statistical letters
4. Validate against Zod schema

### Agent 2: Survey Agent

**Purpose**: Create comprehensive survey JSON structure from questionnaire.

**Input**: Survey document (from Decipher API or PDF via Docling)
**Output**: Complete survey JSON with questions, options, routing, skip logic

**Survey JSON Structure**:
```typescript
interface SurveyJSON {
  questions: {
    number: string;
    text: string;
    type: 'single' | 'multi' | 'scale' | 'numeric' | 'open';
    options?: { value: number | string; label: string }[];
    skipLogic?: { condition: string; action: string };
    validRange?: { min: number; max: number };
    terminalCriteria?: string;
  }[];
  variables: {
    name: string;
    questionNumber: string;
    type: string;
    allowedValues: (number | string)[];
  }[];
}
```

### Agent 3: CrossTab Agent (Validation)

**Purpose**: Validate banner expressions against data map and generate R syntax.

**Input**: Banner groups + data map + survey JSON
**Output**: Validated cuts with R expressions and confidence scores

**Key Behaviors**:
- Process groups individually (group-by-group strategy)
- Use scratchpad tool for transparent reasoning
- Lower confidence for risky patterns (AND logic, conditional variables)
- Provide detailed reasoning for every decision

### Agent 4: R Script Agent (Orchestration)

**Purpose**: Orchestrate R script generation with validation and self-healing.

**Tools Available**:

**Tool 1: Verify Cuts**
- Validate banner plan cuts against actual SPSS data
- Run expressions to verify they produce valid subsets
- Return success/failure with specific issues
- Agent fixes invalid cuts based on available variables

**Tool 2: Create Tables**
- Transform survey JSON into R-ready table definitions
- Map question types to appropriate statistical treatments
- Include all metadata (ranges, scales, etc.)

**Tool 3: Validate Tables**
- Cross-check table definitions with Survey Agent
- Verify against original survey document
- Flag missing questions or misaligned mappings

**Tool 4: Create Crosstabs**
- Combine verified cuts and validated tables
- Generate R syntax with proper statistical calculations
- Include error handling within R script

**Orchestration Flow**:
1. R Script Agent receives all validated inputs
2. Runs Verify Cuts → fixes issues if found
3. Runs Create Tables → transforms survey to tables
4. Runs Validate Tables → confirms with Survey Agent
5. Runs Create Crosstabs → generates final R script
6. Each step includes validation and self-correction

---

## Implementation Roadmap

> **Note**: No time estimates. This is an internal project worked on when time permits. Focus is on completing each phase well, not speed.

### Phase 1: Azure OpenAI Migration (Compliance Unblock)

**Goal**: Switch to Azure OpenAI so we can use firm data.

| Task | Command/Notes |
|------|---------------|
| Install Vercel AI SDK + Azure provider | `npm install ai @ai-sdk/azure` |
| Migrate BannerAgent to AI SDK | Use `azure('gpt-4o')` |
| Migrate CrosstabAgent to AI SDK | Use `azure('gpt-4o')` |
| Update environment configuration | `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT` |
| Test with real Hawk Partners project | Verify output matches current system |

**Deliverable**: System works with Azure OpenAI. Compliance satisfied.

### Phase 2: Team Access (Deploy + Auth + Storage)

**Goal**: Multiple people at Hawk Partners can use the tool.

| Task | Command/Notes |
|------|---------------|
| Initialize Convex + WorkOS AuthKit | `npm create convex@latest -- -t react-vite-authkit` |
| Set up Sentry error monitoring | `npx @sentry/wizard@latest -i nextjs` |
| Create Convex schema (projects, jobs, files) | See schema in Database section |
| Set up Cloudflare R2 for file storage | `npm install @aws-sdk/client-s3` |
| Deploy to Vercel | Connect repo, configure env vars |
| Add basic PostHog tracking | `npm install posthog-js` (optional, low effort) |

**Deliverable**: Hawk Partners team can log in, create projects, upload files, and track status.

### Phase 3: Decipher API Integration (Core Technical Work)

**Goal**: Get skip logic from the source instead of inferring from CSV.

> **This is the hardest part.** Everything else is service integration. This is real development.

| Task | Notes |
|------|-------|
| Verify Decipher API access | Get API key, test connection |
| Research survey structure endpoint | What data is available? |
| Build survey structure fetcher | Parse XML response |
| Extract skip logic / conditions | `cond` attributes → validation rules |
| Integrate into validation pipeline | Replace CSV inference with API data |
| Keep CSV as fallback | Not all surveys may be in Decipher |

**Deliverable**: System uses Decipher skip logic for validation. Major accuracy improvement.

### Phase 4: Reliability & Validation

**Goal**: Surface issues before users see them.

| Task | Notes |
|------|-------|
| Update prompts for calibrated confidence | Lower scores for AND logic, conditional variables |
| Add CUT_DIAGNOSTICS.csv generation | R script outputs counts per cut |
| Implement pre-execution count validation | Catch zero-count cuts before final output |
| Add validationWarnings to output schema | Surface issues in API response |
| Create validation summary UI | Users see warnings prominently |

**Deliverable**: System flags potential issues before users trust bad results.

---

## Checkpoint: Hawk Partners Internal Launch

**Before proceeding to Phase 5+, validate:**

- [ ] Hawk Partners team can log in and generate crosstabs
- [ ] Output quality matches or exceeds Joe's/fielding partner's tabs
- [ ] System uses Azure OpenAI (compliance)
- [ ] Projects are separated per-user (Fathom AI lesson)
- [ ] Errors are visible in Sentry

**Decision point**: Is this working well enough for Hawk Partners? If yes, consider Bob pilot.

---

### Phase 5: Bob Pilot (External Validation)

**Goal**: Validate external interest with fielding partner.

| Task | Notes |
|------|-------|
| Demo to Bob | Show working system |
| Get feedback on workflow | What's missing for their use case? |
| Address critical gaps | If any |
| Pilot with 1-2 of their projects | Real-world validation |

**Decision point**: Is there external demand? What would Bob pay for this?

### Phase 6: Output Quality (Beautiful Tabs)

**Goal**: Match or exceed Joe's output quality.

| Task | Notes |
|------|-------|
| Template generation system (ExcelJS) | Define output format |
| CSV to template mapping | Populate template from R output |
| Statistical testing (90% confidence) | Add stat letters |
| Excel formatting and styling | Make it beautiful |

**Deliverable**: Professional Excel output that looks as good as Joe's.

### Phase 7: Testing & Validation

**Goal**: 100% accuracy on test projects.

| Task | Notes |
|------|-------|
| Test Project 1 end-to-end | Compare to Joe's reference |
| Fix edge cases | Iterate until 100% |
| Test Projects 2-10 | Expand coverage |
| Regression testing | Don't break previous projects |

**Deliverable**: Reliable system that handles Hawk Partners' project diversity.

---

## Testing Protocol

### Project-by-Project Validation

1. **Test Project 1**:
   - Run end-to-end
   - Compare outputs to Joe's reference crosstabs
   - Fix all edge cases
   - Achieve 100% accuracy

2. **Test Project 2**:
   - Run end-to-end
   - Fix new edge cases
   - Verify Project 1 still works

3. **Continue through all 10 projects**:
   - Each project may introduce new edge cases
   - Always regression test previous projects
   - Document all fixes and patterns learned

### Demo Readiness Criteria

**MVP Demo** (after Project 1 validated):
- Show complete end-to-end workflow
- Demonstrate one fully working project
- Note remaining projects in progress

**Production Ready** (after all 10 validated):
- All projects work with 100% reliability
- Edge cases documented and handled
- Performance optimized

### Validation Acceptance Criteria

1. Prompt includes confidence reduction triggers for AND logic
2. R script generates `CUT_DIAGNOSTICS.csv` with counts per cut
3. R script prints warnings for zero-count cuts
4. `crosstab-output.json` includes `validationWarnings` array
5. All 10 test projects produce 100% accurate crosstabs

---

## Decision Log

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| **AI SDK** | OpenAI Agents SDK, Vercel AI SDK, LangChain | Vercel AI SDK | **Azure OpenAI required** for Hawk Partners compliance. Vercel AI SDK supports Azure, OpenAI SDK doesn't. |
| **Database** | Supabase, Convex, PlanetScale | **Convex** | First-class WorkOS integration, TypeScript everywhere, 80 people need shared access |
| **Authentication** | Clerk, Auth0, NextAuth + Azure AD, WorkOS | **WorkOS AuthKit** | Free for 80 users, Convex integration, SSO available if we productize later |
| **File Storage** | Supabase Storage, AWS S3, Cloudflare R2 | **Cloudflare R2** | S3-compatible, generous free tier, no egress fees |
| **Error Monitoring** | Sentry, Bugsnag, Datadog | **Sentry** | Essential for debugging, industry standard |
| **Product Analytics** | PostHog, Mixpanel, Amplitude, None | **PostHog (basic)** | Low effort to add, free tier, defer advanced features |
| **Survey source** | CSV parsing, Decipher API, Qualtrics API | Decipher API primary, CSV fallback | Decipher has skip logic we need |
| **Job queue** | Inngest, Trigger.dev, Convex built-in | **Convex built-in** | Simpler architecture, real-time updates |

---

## Open Questions

1. ~~**Convex vs Supabase**: Need to prototype both.~~ **RESOLVED: Convex** - WorkOS integration + TypeScript-native.

2. **Decipher API access**: Need to verify Hawk Partners has API access. What's the authentication flow?

3. ~~**Multi-survey platform support**: Support Qualtrics, SurveyMonkey?~~ **DEFERRED**: Focus on Decipher for Hawk Partners. Revisit if Bob pilot shows demand.

4. ~~**Self-hosting requirements**: Enterprise on-premise needs?~~ **NOT A REQUIREMENT**: Hawk Partners doesn't need this.

5. ~~**Pricing model**: How to price per crosstab?~~ **DEFERRED**: Internal tool first. Pricing if we productize.

6. **R Execution Environment**: Where does R run?
   - Current: Local R installation
   - For deployment: Likely Docker container on Vercel/Railway
   - Decision needed before Phase 2 deployment

---

## Appendix: Technical References

### Vercel AI SDK
- [Documentation](https://ai-sdk.dev/docs/introduction)
- [AI SDK 6 Release](https://vercel.com/blog/ai-sdk-6)
- [Building Agents Guide](https://vercel.com/kb/guide/how-to-build-ai-agents-with-vercel-and-the-ai-sdk)
- [OpenAI Agents SDK Adapter](https://openai.github.io/openai-agents-js/extensions/ai-sdk/)

### Decipher/Forsta API
- [API Documentation](https://docs.developer.focusvision.com/docs/decipher/api)
- [Python Library](https://pypi.org/project/decipher/)
- [Skip Logic Documentation](https://decipher.zendesk.com/hc/en-us/articles/360010277353-Adding-Condition-Skip-Logic)

### Convex (Database)
- [Convex Documentation](https://docs.convex.dev/home)
- [Convex Schemas](https://docs.convex.dev/database/schemas)
- [Convex Authentication](https://docs.convex.dev/auth)
- [Convex & WorkOS AuthKit](https://docs.convex.dev/auth/authkit/)
- [Convex vs Supabase Comparison](https://makersden.io/blog/convex-vs-supabase-2025)

### WorkOS (Authentication)
- [WorkOS Documentation](https://workos.com/docs)
- [WorkOS AuthKit](https://workos.com/docs/user-management)
- [WorkOS + Convex Integration](https://workos.com/blog/convex-typescript-workos-auth)
- [Convex AuthKit Component](https://github.com/get-convex/workos-authkit)
- [Next.js + Convex + AuthKit Template](https://github.com/workos/template-convex-nextjs-authkit)
- [WorkOS Pricing](https://workos.com/pricing)

### PostHog (Analytics)
- [PostHog Documentation](https://posthog.com/docs)
- [PostHog Next.js Integration](https://posthog.com/docs/libraries/next-js)
- [PostHog Feature Flags](https://posthog.com/docs/feature-flags)
- [PostHog + Vercel Guide](https://vercel.com/kb/guide/posthog-nextjs-vercel-feature-flags-analytics)

### Sentry (Error Monitoring)
- [Sentry Next.js SDK](https://docs.sentry.io/platforms/javascript/guides/nextjs/)
- [Sentry Manual Setup](https://docs.sentry.io/platforms/javascript/guides/nextjs/manual-setup/)
- [Sentry Session Replay](https://docs.sentry.io/product/session-replay/)

### Cloudflare R2 (File Storage)
- [R2 Documentation](https://developers.cloudflare.com/r2/)
- [R2 Presigned URLs](https://developers.cloudflare.com/r2/api/s3/presigned-urls/)
- [Using R2 with AWS SDK](https://developers.cloudflare.com/r2/api/s3/api/)

---

*Created: December 31, 2025*
*Updated: December 31, 2025*
*Status: Hawk Partners Internal Tool (potential productization after validation)*
