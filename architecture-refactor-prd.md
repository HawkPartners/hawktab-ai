# HawkTab AI: Architecture & Development PRD

## Executive Summary

HawkTab AI is a market research crosstab automation system that processes survey data through an AI-powered pipeline. While the current MVP demonstrates the concept successfully, strategic architectural changes are needed to transform it into a reliable, scalable product suitable for enterprise deployment.

**Core Thesis**: The system works, but reliability issues stem from architectural limitations rather than fundamental flaws. By addressing data source integration (Decipher API), AI provider flexibility (Vercel AI SDK), persistence (database layer), and validation rigor, we can achieve the reliability required for production use.

**Target Outcome**: A system where market researchers can upload their survey materials and receive accurate, statistically-tested crosstabs with minimal manual intervention.

---

## Table of Contents

1. [Current State & Problem Analysis](#current-state--problem-analysis)
2. [Strategic Vision](#strategic-vision)
3. [Architecture Recommendations](#architecture-recommendations)
   - [Decipher API Integration](#1-decipherforsta-api-integration)
   - [Vercel AI SDK Migration](#2-vercel-ai-sdk-migration)
   - [Database Layer](#3-database-layer)
   - [Async Job Processing](#4-async-job-processing)
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

#### Why Switch from OpenAI Agents SDK

The [OpenAI Agents SDK](https://openai.github.io/openai-agents-js/) is excellent but locks you into OpenAI:

| Limitation | Business Impact |
|------------|-----------------|
| Only OpenAI models | Enterprise customers may require Azure OpenAI for compliance |
| Vendor lock-in | No negotiating leverage, no cost optimization across providers |
| Limited model selection | Can't use Claude for reasoning tasks, Gemini for cost savings |

#### Vercel AI SDK Advantages

Based on [AI SDK documentation](https://ai-sdk.dev/docs/introduction) and [AI SDK 6 release](https://vercel.com/blog/ai-sdk-6):

| Feature | Benefit |
|---------|---------|
| **Multi-provider** | OpenAI, Anthropic, Google, Azure, Bedrock from one API |
| **Agent abstraction** | Define reusable agents with tools, structured outputs |
| **Type-safe streaming** | Built for React/Next.js with TypeScript throughout |
| **20M+ monthly downloads** | Battle-tested, Fortune 500 adoption |
| **Unified structured outputs** | Zod schemas work across all providers |

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
import { openai } from '@ai-sdk/openai';
import { anthropic } from '@ai-sdk/anthropic';

const crosstabAgent = new Agent({
  model: openai('gpt-4o'), // or anthropic('claude-sonnet-4-20250514')
  system: '...',
  tools: {
    scratchpad: { /* tool definition */ },
    validateCut: { /* tool definition */ }
  },
  structuredOutput: ValidatedGroupSchema
});

const result = await crosstabAgent.run(prompt);
```

#### Provider Selection Strategy

```typescript
// Environment-based or user-selected provider
function getModelForTask(task: 'vision' | 'reasoning' | 'validation') {
  const provider = process.env.AI_PROVIDER || 'openai';

  const models = {
    openai: {
      vision: openai('gpt-4o'),
      reasoning: openai('o1-preview'),
      validation: openai('gpt-4o')
    },
    anthropic: {
      vision: anthropic('claude-sonnet-4-20250514'),
      reasoning: anthropic('claude-sonnet-4-20250514'),
      validation: anthropic('claude-haiku-4-20250514')
    },
    azure: {
      vision: azure('gpt-4o'),
      reasoning: azure('gpt-4o'),
      validation: azure('gpt-4o')
    }
  };

  return models[provider][task];
}
```

#### Enterprise Benefits

- **Azure OpenAI**: For customers requiring data residency or compliance
- **Amazon Bedrock**: For AWS-native enterprises
- **Anthropic Claude**: Often better at reasoning tasks
- **Cost optimization**: Use cheaper models for simple tasks, expensive for complex

---

### 3. Database Layer

**Priority**: High | **Effort**: 1-2 days | **Impact**: High

#### Why We Need Persistence

Current file-based approach (`temp-outputs/`) has critical limitations:

| Limitation | Impact |
|------------|--------|
| No user accounts | Can't track who created what |
| No project history | Previous runs are lost |
| No collaboration | Can't share projects across team |
| No async jobs | Long R execution blocks everything |
| No audit trail | Can't debug issues after the fact |

#### Decision: Supabase vs Convex

This is an open decision requiring evaluation. Both are excellent options with different philosophies.

##### Supabase

[Supabase](https://supabase.com/) is an open-source Firebase alternative built on PostgreSQL.

**Strengths for HawkTab**:
- **PostgreSQL**: Market research data is inherently tabular; SQL is natural fit
- **Open source**: Enterprise customers can self-host for compliance
- **File storage**: Built-in for PDFs, SPSS files, outputs
- **Row-level security**: Multi-tenant out of the box
- **92K GitHub stars**: Massive community, lots of resources
- **Edge functions**: Serverless compute for R execution

**Potential Schema**:
```sql
-- Organizations and users
organizations (id, name, settings_json)
users (id, org_id, email, role)

-- Projects
projects (id, org_id, name, status, created_at)
project_files (id, project_id, type, storage_path, metadata_json)

-- Processing
jobs (id, project_id, type, status, started_at, completed_at, error)
validation_results (id, job_id, cuts_json, warnings_json, confidence_scores)

-- Outputs
crosstab_results (id, project_id, table_name, storage_path)

-- Integrations
decipher_connections (id, org_id, api_key_encrypted, base_url)
```

##### Convex

[Convex](https://www.convex.dev/) is a reactive backend where queries are TypeScript running in the database.

**Strengths for HawkTab**:
- **TypeScript everywhere**: Schema, queries, mutations all in TS - same codebase as frontend
- **AI-friendly**: [Designed for LLM code generation](https://docs.convex.dev/home) - "your favorite AI tools are pre-equipped to generate high quality code"
- **Real-time by default**: UI updates automatically when data changes
- **Simpler mental model**: No ORM, no SQL, just functions
- **Built-in AI features**: RAG components, vector search

**TypeScript Schema Example**:
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

##### Comparison Matrix

| Factor | Supabase | Convex |
|--------|----------|--------|
| **Data model** | SQL (relational) | Document (NoSQL) |
| **Schema location** | Database (separate from code) | Codebase (TypeScript) |
| **AI code generation** | Good (standard SQL) | Excellent (TypeScript, designed for it) |
| **Real-time** | Requires setup | Automatic |
| **Self-hosting** | Yes (open source) | No |
| **File storage** | Built-in | External (S3, etc.) |
| **Learning curve** | Low (familiar SQL) | Medium (new paradigm) |
| **Community size** | 92K stars | 8K stars |

##### Evaluation Approach

**Prototype both** before deciding:
1. Build simple project CRUD with Convex - evaluate AI code generation quality
2. Build same with Supabase - compare developer experience
3. Consider enterprise requirements (self-hosting needs)

**Current leaning**: Convex for faster development velocity with AI assistance, but keep Supabase as option if enterprise customers require self-hosting.

---

### 4. Async Job Processing

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

**Recommendation**: Start with database-native solution (Convex or Supabase), evaluate external queue if needed for more complex workflows.

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

### Phase 0: Data Preparation (Pre-Development)

**Goal**: Organize test data for validation.

| Task | Details |
|------|---------|
| Organize Antares test data | Create folder structure for 10 test projects |
| Each project folder contains | Data map (CSV), SPSS file (.sav), Banner plan (PDF/DOC), Questionnaire |
| Analyze data map format | Determine if current parsing handles Antares format |
| Verify Decipher access | Confirm API access for test projects |

### Phase 1: Foundation (Week 1-2)

**Goal**: Establish core infrastructure without breaking existing functionality.

| Task | Effort | Dependencies |
|------|--------|--------------|
| Set up database (Convex or Supabase) | 1 day | Decision on which |
| Create basic schema (projects, jobs, files) | 0.5 day | Database setup |
| Migrate file storage to database/object store | 1 day | Schema |
| Add basic auth (Clerk or Supabase Auth) | 0.5 day | Database |
| Implement async job processing | 1 day | Database |

**Deliverable**: Users can create projects, upload files, and track processing status.

### Phase 2: AI Layer Migration (Week 2-3)

**Goal**: Switch from OpenAI Agents SDK to Vercel AI SDK.

| Task | Effort | Dependencies |
|------|--------|--------------|
| Install Vercel AI SDK and providers | 0.5 day | None |
| Migrate BannerAgent to AI SDK | 1 day | AI SDK setup |
| Migrate CrosstabAgent to AI SDK | 1 day | AI SDK setup |
| Add provider selection (OpenAI/Anthropic/Azure) | 0.5 day | Migration |
| Update environment configuration | 0.5 day | Provider selection |
| Test with multiple providers | 1 day | All above |

**Deliverable**: System works with any supported AI provider.

### Phase 3: Reliability Improvements (Week 3-4)

**Goal**: Implement validation layers for accurate results.

| Task | Effort | Dependencies |
|------|--------|--------------|
| Update prompts for lower confidence on AND logic | 0.5 day | None |
| Add CUT_DIAGNOSTICS.csv generation to R | 0.5 day | None |
| Implement pre-execution count validation | 1 day | None |
| Add validationWarnings to output schema | 0.5 day | Count validation |
| Create validation summary UI component | 1 day | Warnings schema |
| Implement Survey Agent | 2 days | AI SDK |

**Deliverable**: System surfaces potential issues before users see final results.

### Phase 4: Decipher Integration (Week 4-5)

**Goal**: Enable direct survey platform integration.

| Task | Effort | Dependencies |
|------|--------|--------------|
| Research Decipher API authentication | 0.5 day | API access |
| Implement connection settings UI | 0.5 day | Auth research |
| Build survey structure fetcher | 1 day | Connection |
| Parse skip logic from survey XML | 1 day | Fetcher |
| Integrate skip logic into validation | 1 day | Parser |
| Add Decipher as data source option | 0.5 day | All above |

**Deliverable**: Users can connect Decipher account and import surveys directly.

### Phase 5: R Script Agent & Tools (Week 5-6)

**Goal**: Implement orchestration agent with self-healing.

| Task | Effort | Dependencies |
|------|--------|--------------|
| Implement Verify Cuts tool | 1 day | Phase 3 validation |
| Implement Create Tables tool | 1 day | Survey Agent |
| Implement Validate Tables tool | 0.5 day | Survey Agent |
| Implement Create Crosstabs tool | 1 day | All tools |
| Build R Script Agent orchestration | 1 day | All tools |
| Test self-healing capabilities | 1 day | Orchestration |

**Deliverable**: Agent-orchestrated R generation with automatic error correction.

### Phase 6: Statistical Enhancement & Polish (Week 6-7)

**Goal**: Production-ready output quality.

| Task | Effort | Dependencies |
|------|--------|--------------|
| Template generation system (ExcelJS) | 1 day | Phase 5 |
| CSV to template mapping | 1 day | Template |
| Statistical testing (90% confidence) | 2 days | Mapping |
| Excel formatting and styling | 1 day | Stats |

**Deliverable**: Professional Excel output with statistical testing.

### Phase 7: Testing & Validation (Week 7-8)

**Goal**: 100% accuracy on all test projects.

| Task | Effort | Dependencies |
|------|--------|--------------|
| Test Project 1 end-to-end | 1 day | All above |
| Compare to Joe's reference crosstabs | 0.5 day | Project 1 |
| Fix edge cases | Variable | Testing |
| Test Projects 2-10 | 3 days | Project 1 works |
| Regression testing | 1 day | All projects |
| Performance optimization | 1 day | Testing complete |

**Deliverable**: System handles all test projects with 100% accuracy.

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
| **AI SDK** | OpenAI Agents SDK, Vercel AI SDK, LangChain | Vercel AI SDK | Multi-provider, TypeScript-native, production-proven |
| **Database** | Supabase, Convex, PlanetScale | TBD (evaluate both) | Need to prototype for AI code generation experience |
| **Survey source** | CSV parsing, Decipher API, Qualtrics API | Decipher API primary, CSV fallback | Decipher has skip logic we need |
| **Job queue** | Built-in (Convex/Supabase), Inngest, Trigger.dev | Start with built-in | Simpler, evaluate external if needed |

---

## Open Questions

1. **Convex vs Supabase**: Need to prototype both to evaluate AI code generation quality and developer experience.

2. **Decipher API access**: Do all Antares projects have Decipher access? What's the authentication flow?

3. **Multi-survey platform support**: Should we also support Qualtrics, SurveyMonkey APIs eventually?

4. **Self-hosting requirements**: Do any enterprise customers require on-premise deployment?

5. **Pricing model**: How does AI provider choice affect cost per crosstab?

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

### Database Options
- [Convex Documentation](https://docs.convex.dev/home)
- [Convex Schemas](https://docs.convex.dev/database/schemas)
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase vs Convex Comparison](https://makersden.io/blog/convex-vs-supabase-2025)

---

*Created: December 31, 2025*
*Status: Single Source of Truth for HawkTab AI Development*
