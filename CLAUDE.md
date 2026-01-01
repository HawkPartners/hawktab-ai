# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Core Philosophy: Enterprise-Grade MVP

**MVP does not mean "demo that only works on my machine."**

Every line of code should be written as if it will be deployed to an enterprise customer tomorrow. This means:

1. **Production-ready from day one**: Code should work reliably, not just in happy-path scenarios
2. **Security is not optional**: Every feature considers security implications before implementation
3. **Observable and debuggable**: Errors are logged, traced, and actionable
4. **Type-safe and validated**: Runtime validation at system boundaries, TypeScript throughout
5. **Deployable immediately**: No "we'll fix that later" shortcuts that block deployment

**The goal**: When showing this to a market research firm (or any enterprise), they can start using it that day—not "after we clean things up."

---

## Project Overview

HawkTab AI is a market research crosstab automation platform that processes survey data through an AI-powered pipeline. It integrates with survey platforms (Decipher/Forsta), validates banner expressions against actual data, and generates statistically-tested crosstabs.

**Key Documents**:
- `architecture-refactor-prd.md` - Complete architecture plan, decisions, and roadmap (single source of truth)
- `README.md` - Project overview and getting started
- `docs/security-audit-prompt.md` - Weekly security review checklist

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
Security audits are conducted weekly using the prompt in `docs/security-audit-prompt.md`. Every new feature should be auditable.

---

## Target Architecture Stack

The project is migrating to this enterprise-grade stack (see `architecture-refactor-prd.md`):

| Layer | Technology | Why |
|-------|------------|-----|
| **Database** | Convex | TypeScript-native, real-time, WorkOS integration |
| **Auth** | WorkOS AuthKit | Enterprise SSO/SCIM, free to 1M MAU |
| **AI** | Vercel AI SDK | Multi-provider (OpenAI, Anthropic, Azure) |
| **File Storage** | Cloudflare R2 | S3-compatible, no egress fees |
| **Error Monitoring** | Sentry | Industry standard, session replay |
| **Analytics** | PostHog | Product analytics, feature flags |

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

## Current Architecture (Pre-Refactor)

### Three-Phase Processing Pipeline
The system operates in a structured workflow:
- **Phase 5**: Data processing with dual output strategy (banner PDF→images→JSON, data map CSV→enhanced JSON)
- **Phase 6**: CrossTab Agent validation using group-by-group processing strategy
- **Phase 7**: API integration with single endpoint handling complete workflow

### Agent-First Implementation
Currently uses OpenAI Agents JS SDK with **context injection** rather than tool-heavy approaches:
- **One agent, multiple calls**: Process banner groups individually for better focus
- **Context-first strategy**: Full JSON data structures injected into agent instructions
- **Structured outputs**: Uses Zod schemas with `outputType` property (NOT `outputSchema`)

### Dual Output Strategy
Every processor generates two formats:
- **Verbose**: Complete metadata for debugging and tracing (`*-verbose-*.json`)
- **Agent**: Simplified structure optimized for agent processing (`*-agent-*.json`)

---

## Critical Technical Requirements

### Zod Version Lock
```json
{
  "zod": "3.25.67"  // EXACTLY this version - SDK breaks with 3.25.68+
}
```

### Environment-Based Model Selection
- **Development**: Uses reasoning models (`REASONING_MODEL=o1-preview`)
- **Production**: Uses base models (`BASE_MODEL=gpt-4o`)
- Environment switching handled automatically in `src/lib/env.ts`

### OpenAI Agents SDK Patterns (Current)
```typescript
// Correct pattern for tools
import { tool } from '@openai/agents';
export const myTool = tool({
  name: 'tool_name',
  parameters: z.object({ /* zod schema */ }),
  async execute() { /* implementation */ }
});

// Correct pattern for agents
const agent = new Agent({
  name: 'AgentName',
  instructions: enhancedInstructions,
  model: getModel(),
  outputType: MySchema,  // NOT outputSchema
  tools: [myTool]
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
- **`/src/agents/`**: CrossTab Agent implementation with tools (scratchpad for transparency)
- **`/src/schemas/`**: Zod-first schema definitions for type safety
- **`/src/lib/processors/`**: Data processing pipeline (BannerProcessor, DataMapProcessor)
- **`/src/guardrails/`**: Input validation and safety checks
- **`/src/lib/`**: Utilities (env config, tracing, context builder, storage)

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

**Phases 5-7 Complete (Ready for Architecture Refactor)**:
- Successfully processes 192+ variables with 130 parent relationships
- 99% accuracy in SPSS variable matching
- Handles complex expressions with intelligent inference
- Provides graduated confidence scores for human review
- Processes 19 columns across 6 banner groups

**Next**: Execute architecture refactor per `architecture-refactor-prd.md`

---

## Useful Commands

```bash
# Development
npm run dev                    # Start with Turbopack

# Quality
npm run lint                   # ESLint
npx tsc --noEmit              # Type check

# R Script Testing
Rscript r/master.R            # Run generated R script

# Git
git status                     # Check changes
git diff                       # Review changes before commit
```

---

## References

- `architecture-refactor-prd.md` - Complete architecture plan
- `docs/security-audit-prompt.md` - Security review checklist
- [Convex Docs](https://docs.convex.dev/)
- [WorkOS AuthKit](https://workos.com/docs/user-management)
- [Vercel AI SDK](https://ai-sdk.dev/docs/introduction)
- [Sentry Next.js](https://docs.sentry.io/platforms/javascript/guides/nextjs/)
- [PostHog Next.js](https://posthog.com/docs/libraries/next-js)
