# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Core Philosophy: Internal Tool, Production Quality

**This is an internal tool for Hawk Partners, but "internal" doesn't mean sloppy.**

80 people will use this. It handles real client data. Code quality matters:

1. **Production-ready from day one**: Code should work reliably, not just in happy-path scenarios
2. **Security is not optional**: Firm data requires Azure OpenAI, proper auth, no PII leaks
3. **Observable and debuggable**: Errors are logged, traced, and actionable (Sentry)
4. **Type-safe and validated**: Runtime validation at system boundaries, TypeScript throughout
5. **Deployable immediately**: No "we'll fix that later" shortcuts that block deployment

**The goal**: Hawk Partners team can use this to replace outsourcing crosstab generation. If it works well, we may pilot with Bob's fielding company.

---

## Project Overview

HawkTab AI replaces Hawk Partners' current crosstab outsourcing workflow. Instead of sending files to Joe or fielding partners and waiting days, the team generates tabs directly.

**Primary Goal**: 80-person team can log in, upload survey materials, get accurate crosstabs.

**Key Documents**:
- `docs/architecture-refactor-prd.md` - Complete architecture plan and roadmap
- `README.md` - Project overview and getting started
- `docs/audits/security-audit-prompt.md` - Security review checklist

---

## Security-First Development

Security is a first-class concern at every stage of development. Follow these principles:

### Before Writing Code
- Consider: What data does this feature handle? Is it sensitive?
- Consider: Who should have access to this? How is that enforced?
- Consider: What happens if input is malicious or malformed?

### While Writing Code
- **Validate all inputs** at system boundaries (API routes, user inputs, file uploads)
- **Never log sensitive data** (API keys, user PII, financial data)
- **Use parameterized queries** - never string concatenation for data access
- **Sanitize outputs** - especially anything rendered in UI
- **Fail securely** - errors should not leak internal details

### After Writing Code
- Run `npm run lint` and `npx tsc --noEmit` before committing
- Consider: Did I introduce any OWASP Top 10 vulnerabilities?
- Document any security-relevant decisions in commit messages

### Weekly Security Audits
Security audits are conducted weekly using the prompt in `docs/audits/security-audit-prompt.md`. Every new feature should be auditable.

---

## Target Architecture Stack

Migrating to this stack (see `docs/architecture-refactor-prd.md`):

| Layer | Technology | Why |
|-------|------------|-----|
| **AI** | Vercel AI SDK + Azure OpenAI | Azure required for compliance (firm data) |
| **Database** | Convex | 80 people need shared access, TypeScript-native |
| **Auth** | WorkOS AuthKit | Free for team, SSO available if we productize |
| **File Storage** | Cloudflare R2 | S3-compatible, generous free tier |
| **Error Monitoring** | Sentry | Know when things break |
| **Analytics** | PostHog (basic) | Usage tracking, low effort to add |

---

## Development Commands

```bash
# Development (with Turbopack hot reload)
npm run dev

# Production build and start
npm run build
npm run start

# Code quality (run before EVERY commit)
npm run lint              # ESLint checks
npx tsc --noEmit          # TypeScript type checking
```

---

## Current Architecture (Azure OpenAI - Phase 1 Complete)

### Three-Phase Processing Pipeline
The system operates in a structured workflow:
- **Phase 5**: Data processing with dual output strategy (banner PDF→images→JSON, data map CSV→enhanced JSON)
- **Phase 6**: CrossTab Agent validation using group-by-group processing strategy
- **Phase 7**: API integration with single endpoint handling complete workflow

### Agent-First Implementation
Uses **Vercel AI SDK + Azure OpenAI** (Phase 1 migration complete):
- **One agent, multiple calls**: Process banner groups individually for better focus
- **Context-first strategy**: Full JSON data structures injected into agent instructions
- **Structured outputs**: Uses Zod schemas with `Output.object({ schema })` pattern
- **Task-based model selection**: `getReasoningModel()` for complex validation, `getBaseModel()` for vision tasks

### Dual Output Strategy
Every processor generates two formats:
- **Verbose**: Complete metadata for debugging and tracing (`*-verbose-*.json`)
- **Agent**: Simplified structure optimized for agent processing (`*-agent-*.json`)

---

## Critical Technical Requirements

### Zod Version
```json
{
  "zod": "^3.25.76"  // Upgraded after Phase 1 migration (was locked to 3.25.67 for OpenAI Agents SDK)
}
```

### Task-Based Model Selection
Models are chosen based on task requirements, not environment:
- **Reasoning model** (`getReasoningModel()`): o4-mini for complex validation (CrosstabAgent)
- **Base model** (`getBaseModel()`): gpt-5-nano for vision/extraction (BannerAgent)
- Configuration in `src/lib/env.ts`

### Vercel AI SDK Patterns (Current)
```typescript
// Current pattern (Vercel AI SDK + Azure OpenAI)
import { generateText, Output, tool } from 'ai';
import { getReasoningModel } from '@/lib/env';

// Tool definition
const scratchpadTool = tool({
  description: 'Reasoning transparency tool',
  inputSchema: z.object({ action: z.string(), content: z.string() }),
  execute: async ({ action, content }) => { /* implementation */ }
});

// Agent call with structured output
const { output } = await generateText({
  model: getReasoningModel(),  // Task-based selection
  system: instructions,
  prompt: userPrompt,
  tools: { scratchpad: scratchpadTool },
  output: Output.object({ schema: MySchema }),
});
```

---

## Directory Structure

```
hawktab-ai/
├── src/
│   ├── agents/           # AI agent implementations
│   ├── app/              # Next.js app router
│   │   └── api/          # API endpoints
│   ├── components/       # React components
│   ├── guardrails/       # Input/output validation
│   ├── lib/              # Core utilities
│   │   ├── processors/   # Data processing pipeline
│   │   ├── r/            # R script generation
│   │   └── tables/       # Table definitions
│   ├── prompts/          # AI prompt templates
│   └── schemas/          # Zod type definitions
├── convex/               # Convex backend (future)
├── docs/                 # Documentation
├── data/                 # Test data files
└── temp-outputs/         # Development outputs (git-ignored)
```

### Key Files
- **`/src/agents/`**: BannerAgent, CrosstabAgent, TableAgent
- **`/src/lib/r/RScriptGeneratorV2.ts`**: JSON-output R script generator
- **`/src/lib/processors/`**: DataMapProcessor, BannerProcessor
- **`/src/schemas/`**: Zod-first type definitions (tableAgentSchema, processingSchemas)
- **`/scripts/`**: CLI test scripts (test-pipeline, test-table-agent, test-r-script-v2)

---

## API Endpoints

### Current (Pre-Refactor)
`/api/process-crosstab` handles the complete workflow:
1. File upload validation with guardrails
2. Phase 5: Document processing and dual output generation
3. Phase 6: CrossTab Agent validation with confidence scoring
4. Comprehensive response with metrics and next steps

### Data Flow
```
Files Upload → Guardrails → Phase 5 Processing → Context Builder → CrossTab Agent → Validated Results
     ↓              ↓             ↓                    ↓              ↓            ↓
  Validation    File Safety   Dual Outputs      Agent Context   Group Processing  R Syntax
```

---

## Key Implementation Details

### Group-by-Group Processing
CrossTab Agent processes banner groups individually:
- Creates separate agent instance per group with injected context
- Uses scratchpad tool for reasoning transparency
- Combines results with confidence scoring
- Handles failures gracefully with fallback responses

### Confidence-Based Validation
Agent generates confidence scores (0.0-1.0) based on variable mapping quality:
- **0.95-1.0**: Direct variable matches (`S2=1` → `S2 == 1`)
- **0.85-0.94**: Complex logic with multiple variables
- **0.70-0.84**: Conceptual matches (`IF HCP` → healthcare professional variables)
- **Below 0.70**: Requires manual review

### Development vs Production Behavior
- **Development**: Saves verbose outputs to `temp-outputs/`, uses reasoning models, detailed logging
- **Production**: Minimal logging, uses base models, no file outputs
- Environment detection: `process.env.NODE_ENV`

---

## Schema-First Development

All data structures defined with Zod schemas before implementation:
- **DataMapSchema**: Enhanced CSV processing with parent relationships and context enrichment
- **BannerPlanSchema**: PDF/DOC extraction results with banner cuts and columns
- **ValidationResultSchema**: Agent outputs with R syntax and confidence scores

---

## Code Quality Standards

### Before Every Commit
```bash
npm run lint              # Must pass
npx tsc --noEmit          # Must pass
```

### Pull Request Requirements
- TypeScript strict mode enforced
- No `any` types without justification
- All API inputs validated with Zod
- Error handling for all async operations
- Security implications documented if relevant

### What NOT to Do
- Don't skip type checking to "ship faster"
- Don't log API keys, tokens, or PII
- Don't use `eval()` or dynamic code execution
- Don't trust client-side input without server validation
- Don't commit `.env` files or secrets

---

## Current Implementation Status

**Phase 1 Complete (Azure OpenAI Migration)**:
- Migrated from OpenAI Agents SDK to Vercel AI SDK
- Using Azure OpenAI (compliance requirement satisfied)
- Task-based model selection: o4-mini (reasoning), gpt-5-nano (vision)

**TableAgent Architecture (In Progress)**:
- **TableAgent**: AI-based table structure decisions (replaces regex-based TablePlan)
- **RScriptGeneratorV2**: JSON output with `frequency` and `mean_rows` table types
- Correct base sizing: `base_n = sum(!is.na(cut_data[[variable]]))`
- Steps 0-5 complete, Step 6 (ExcelJS) next

**Current Work** (see `docs/implementation-plans/table-agent-architecture.md`):
1. Step 5.5: Verify R significance testing
2. Step 6: ExcelJS Formatter (Antares-style output)
3. Step 7: Excel Cleanup Agent (optional - uses survey document)

**After TableAgent**: Return to `docs/implementation-plans/pre-phase-2-testing-plan.md`

---

## Useful Commands

```bash
# Development
npm run dev                    # Start with Turbopack

# Quality
npm run lint                   # ESLint
npx tsc --noEmit              # Type check

# Pipeline Testing (uses data/test-data/practice-files/)
npx tsx scripts/test-pipeline.ts      # Full pipeline test
npx tsx scripts/test-table-agent.ts   # TableAgent only
npx tsx scripts/test-r-script-v2.ts   # R script from existing output

# Git
git status                     # Check changes
git diff                       # Review changes before commit
```

---

## References

**Implementation Plans**:
- `docs/implementation-plans/table-agent-architecture.md` - Current work (Steps 5.5-7)
- `docs/implementation-plans/pre-phase-2-testing-plan.md` - Testing milestones
- `docs/architecture-refactor-prd.md` - Overall architecture

**Security**:
- `docs/audits/security-audit-prompt.md` - Security review checklist

**External Docs**:
- [Vercel AI SDK](https://ai-sdk.dev/docs/introduction)
- [Convex Docs](https://docs.convex.dev/)
- [WorkOS AuthKit](https://workos.com/docs/user-management)
