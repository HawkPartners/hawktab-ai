# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HawkTab AI is a sophisticated Next.js application that automates market research crosstab generation using OpenAI's Agents JS SDK. It processes data maps (CSV), banner plans (PDF/DOC), and SPSS files through an intelligent agent-driven pipeline to generate R syntax for statistical analysis.

## Development Commands

```bash
# Development (with Turbopack hot reload)
npm run dev

# Production build and start  
npm run build
npm run start

# Code quality
npm run lint              # ESLint checks - run before commits
npx tsc --noEmit          # TypeScript type checking - run before commits
```

## Critical Architecture Patterns

### Three-Phase Processing Pipeline
The system operates in a structured workflow:
- **Phase 5**: Data processing with dual output strategy (banner PDF→images→JSON, data map CSV→enhanced JSON)
- **Phase 6**: CrossTab Agent validation using group-by-group processing strategy  
- **Phase 7**: API integration with single endpoint handling complete workflow

### Agent-First Implementation
Uses OpenAI Agents JS SDK with **context injection** rather than tool-heavy approaches:
- **One agent, multiple calls**: Process banner groups individually for better focus
- **Context-first strategy**: Full JSON data structures injected into agent instructions
- **Structured outputs**: Uses Zod schemas with `outputType` property (NOT `outputSchema`)

### Dual Output Strategy
Every processor generates two formats:
- **Verbose**: Complete metadata for debugging and tracing (`*-verbose-*.json`)  
- **Agent**: Simplified structure optimized for agent processing (`*-agent-*.json`)

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

### OpenAI Agents SDK Patterns
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

## Architecture Overview

### Core Directories
- **`/src/agents/`**: CrossTab Agent implementation with tools (scratchpad for transparency)
- **`/src/schemas/`**: Zod-first schema definitions for type safety
- **`/src/lib/processors/`**: Data processing pipeline (BannerProcessor, DataMapProcessor)
- **`/src/guardrails/`**: Input validation and safety checks
- **`/src/lib/`**: Utilities (env config, tracing, context builder, storage)
- **`/temp-outputs/`**: Development outputs (verbose + agent JSON files)
- **`/docs/`**: Architecture documentation and implementation roadmap

### Single API Endpoint
`/api/process-crosstab` handles the complete workflow:
1. File upload validation with guardrails
2. Phase 5: Document processing and dual output generation  
3. Phase 6: CrossTab Agent validation with confidence scoring
4. Comprehensive response with metrics and next steps

### Data Flow Architecture
```
Files Upload → Guardrails → Phase 5 Processing → Context Builder → CrossTab Agent → Validated Results
     ↓              ↓             ↓                    ↓              ↓            ↓
  Validation    File Safety   Dual Outputs      Agent Context   Group Processing  R Syntax
```

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

## Schema-First Development

All data structures defined with Zod schemas before implementation:
- **DataMapSchema**: Enhanced CSV processing with parent relationships and context enrichment
- **BannerPlanSchema**: PDF/DOC extraction results with banner cuts and columns  
- **ValidationResultSchema**: Agent outputs with R syntax and confidence scores

## Tracing and Observability

Comprehensive tracing implemented in `src/lib/tracing.ts`:
- Agent execution logging with session IDs
- Development console output with timing metrics
- Configurable external provider support
- Processing stage tracking throughout pipeline

## Current Implementation Status

**Phases 5-7 Complete (Ready for Testing)**:
- ✅ Sophisticated data processing (192 variables, 130 parent relationships, 99% SPSS match)
- ✅ CrossTab Agent with enhanced validation (19 columns across 6 groups)
- ✅ Complete API integration with comprehensive error handling
- ✅ Tracing, guardrails, and type safety fully operational

Test the complete workflow with `npm run dev` and file uploads to `/api/process-crosstab`.