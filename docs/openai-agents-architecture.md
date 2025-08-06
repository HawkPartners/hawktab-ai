# OpenAI Agents JS SDK - Architecture & Implementation Guide

## Overview

This document outlines our implementation strategy for the OpenAI Agents JS SDK in the HawkTab AI crosstab generation system. The system automates the complex process of validating market research banner plans against data maps to generate crosstabs - essentially replacing manual analyst work with intelligent agent orchestration.

## Core Concepts

The OpenAI Agents JS SDK is built around four fundamental concepts that we will maximize in our implementation:

### 1. **Agents**
- **Definition**: LLMs configured with instructions, guardrails, and structured outputs
- **Purpose**: Single intelligent orchestrator that validates banner expressions against data maps
- **Implementation**: One CrosstabOrchestrator agent with full context visibility

### 2. **Structured Outputs** 
- **Definition**: Zod schemas that enforce consistent, type-safe agent responses
- **Purpose**: Guarantee output format and enable automatic validation
- **Implementation**: Strict schemas for validation results with confidence scores

### 3. **Guardrails**
- **Definition**: Input/output validation mechanisms that run in parallel to ensure safety and integrity
- **Purpose**: Prevent malicious usage, validate data formats, and ensure output quality
- **Implementation**: 
  - Input guardrails: File type/size validation, content safety checks
  - Output guardrails: Data integrity verification, format compliance

### 4. **Tracing**
- **Definition**: Built-in observability for debugging and production monitoring
- **Purpose**: Track agent performance, token usage, and decision patterns
- **Implementation**: Comprehensive tracing with external provider integration

## Workflow Architecture

### Phase 1: Automatic Pre-Processing (No Agent Required)
**Note: This phase is already implemented - existing code will be integrated**

1. **File Upload & Storage**
   - User uploads three files: Data Map (.csv/.xlsx), Banner Plan (.pdf/.doc), Data File (.sav/.spss)
   - Files stored in temporary directory for processing

2. **Automatic Parsing Pipeline**
   ```
   Banner Plan → PDF conversion → Image extraction → LLM parsing → 2 JSON outputs
   Data Map CSV → Parser → 2 JSON outputs  
   SAV file → Variable extraction → Validation against data map
   ```

3. **Dual Output Strategy (New Approach)**
   Each parser creates **two versions** of the JSON:
   
   **Verbose/Original Version** (for validation & traceability):
   - Full structure like `banner-part1-result-20250806_141904.json`
   - All metadata: statLetter, confidence, crossRefStatus, etc.
   - Complete processing metadata and timestamps
   - Used for system validation and audit trails
   
   **Simplified/Agent Version** (for AI processing):
   - Minimal structure with only essential fields
   - Banner: only `groupName`, `name`, `original`
   - Data Map: only `Column`, `Description`, `Answer_Options`
   - Optimized for context injection and token efficiency

4. **Validation & Error Handling**
   - Verify all variables in SAV match data map
   - Flag discrepancies with acceptable threshold  
   - Stop process if critical errors detected
   - **Output**: Four files ready for Phase 2

### Phase 2: Group-by-Group Agent Processing

We process banner groups **individually** to maximize focus and minimize context complexity.

#### Group-Focused Processing Strategy

Instead of passing the entire banner plan, we loop through each group and process separately:

```typescript
// Process each banner group individually
async function processAllGroups(dataMapAgent: any[], bannerGroupsVerbose: any[]) {
  const results = [];
  
  for (const group of bannerGroupsVerbose) {
    // Create focused context for just this group
    const result = await processGroup(dataMapAgent, group);
    results.push(result);
  }
  
  return combineResults(results);
}

// Single group processing with focused context
async function processGroup(dataMapAgent: any[], bannerGroup: any) {
  const agent = new Agent({
    name: 'GroupValidator',
    model: process.env.OPENAI_MODEL || 'gpt-4o',
    outputType: GroupValidationSchema,
    instructions: `
      You are validating ONE banner group against a data map.
      Focus only on the group provided - do not consider other groups.
      
      CURRENT GROUP: "${bannerGroup.groupName}"
      COLUMNS TO PROCESS: ${bannerGroup.columns.length}
      
      VARIABLE PATTERNS:
      - Variables: S2, S2a, A3r1, B5r2
      - Filters: S2=1 (S2 is variable, =1 is filter)  
      - Complex: S2=1 AND S2a=1 (variables are S2, S2a)
      - Conceptual: "IF HCP" needs interpretation
      
      R SYNTAX:
      - Equality: S2 == 1
      - Logic: & (AND), | (OR)  
      - Multiple values: S2 %in% c(1,2,3)
      
      For each column in this group:
      1. Extract variables from "original"
      2. Validate against data map  
      3. Generate R syntax in "adjusted"
      4. Rate confidence 0-1
      5. Explain reasoning
      
      DATA MAP (${dataMapAgent.length} variables):
      ${JSON.stringify(dataMapAgent, null, 2)}
      
      GROUP TO VALIDATE:
      ${JSON.stringify(bannerGroup, null, 2)}
    `
  });
  
  return await run(agent, `Validate group: ${bannerGroup.groupName}`);
}
```

#### Schema for Single Group Processing

```typescript
// Focused schema for individual group processing
const GroupValidationSchema = z.object({
  groupName: z.string(),
  columns: z.array(z.object({
    name: z.string(),
    adjusted: z.string().describe('R syntax expression'),
    confidence: z.number().min(0).max(1),
    reason: z.string()
  }))
});
```

#### Benefits of Group-by-Group Processing

1. **Smaller Context Windows** - Each agent call processes 2-5 columns vs 20+ columns
2. **Better Focus** - Agent concentrates on one logical group at a time
3. **Easier Debugging** - Can isolate issues to specific groups
4. **Parallel Processing** - Groups can be processed concurrently if needed
5. **Reduced Token Usage** - Smaller context per call
6. **Better Reliability** - Less chance of the model getting confused across groups

#### Context-First Architecture

**No tools needed** - we inject full context directly:
1. Load entire parsed JSON structures into agent instructions
2. Use dynamic instruction enhancement with the data
3. Let the model see relationships holistically

```typescript
// Dynamic context injection
const enhancedInstructions = `
  ${baseInstructions}
  
  DATA MAP (${dataMap.length} variables):
  ${JSON.stringify(dataMapSimplified, null, 2)}
  
  BANNER PLAN TO VALIDATE:
  ${JSON.stringify(bannerPlanSimplified, null, 2)}
`;
```

## Recommended Architecture

### Simplified Directory Structure
```
src/
├── agents/
│   ├── CrosstabOrchestrator.ts # Single orchestrator for validation
│   └── index.ts                # Agent exports
├── processors/
│   ├── bannerParser.ts        # Existing banner plan parser
│   ├── dataMapParser.ts       # Existing data map parser
│   ├── spssValidator.ts       # Existing SPSS validation
│   └── index.ts               
├── schemas/
│   ├── dataMapSchema.ts       # Data map structure definitions
│   ├── bannerPlanSchema.ts    # Banner plan structure definitions
│   └── validationSchema.ts    # Agent output schema
├── guardrails/
│   ├── inputValidation.ts     # Validate file formats/sizes
│   └── outputValidation.ts    # Ensure mapping completeness
├── api/
│   └── process-crosstab/
│       └── route.ts           # Single API endpoint
├── lib/
│   ├── tracing.ts             # Tracing configuration
│   ├── types.ts               # TypeScript definitions
│   └── contextBuilder.ts      # Dynamic context injection
└── docs/
    └── openai-agents-architecture.md  # This document
```

## Data Schemas

### Simplified Input Schemas

Based on our analysis, we streamline the JSON structures to only include essential fields:

#### Data Map Schema (Input to Agent)
```typescript
// schemas/dataMapSchema.ts
const DataMapSchema = z.array(z.object({
  Column: z.string(),           // Variable name: "S2", "S2a", "A3r1"
  Description: z.string(),      // Question text
  Answer_Options: z.string()    // "1=Cardiologist,2=Internal Medicine"
}));

// Remove: Level, ParentQ, Value_Type, Context - not needed for validation
```

#### Banner Plan Schema (Input to Agent)
```typescript
// schemas/bannerPlanSchema.ts  
const BannerPlanInputSchema = z.object({
  bannerCuts: z.array(z.object({
    groupName: z.string(),
    columns: z.array(z.object({
      name: z.string(),         // "Cards", "PCPs", "HCP"
      original: z.string()      // "S2=1 AND S2a=1", "IF HCP"
    }))
  }))
});

// Remove: adjusted, statLetter, confidence, crossRefStatus, etc.
// Agent only needs name + original to do its work
```

### Agent Output Schema

```typescript
// schemas/validationSchema.ts
const ValidationResultSchema = z.object({
  bannerCuts: z.array(z.object({
    groupName: z.string(),
    columns: z.array(z.object({
      name: z.string(),
      adjusted: z.string().describe('R syntax expression'),
      confidence: z.number().min(0).max(1),
      reason: z.string()
    }))
  }))
});

// Clean, minimal output focused on validation results
```

## Validation Strategy

### Expression Validation Approach

The agent processes banner expressions using intelligent pattern recognition:

1. **Direct Variable Matching**
   - Expression: `S2=1 AND S2a=1`
   - Parse variables: `[S2, S2a]`
   - Verify both exist in data map
   - Generate R syntax: `(S2 == 1 & S2a == 1)`
   - High confidence: 0.95+

2. **Conceptual Matching**
   - Expression: `IF HCP`
   - No direct variable found
   - Model understands: Healthcare Professional
   - Map to S2b (primary role) values 1,2,3 (Physician, NP, PA)
   - Generate: `S2b %in% c(1,2,3)`
   - Medium confidence: 0.70-0.85

3. **Complex Interpretation**
   - Expression: `Joe to find the right cutoff`
   - Model recognizes incomplete specification
   - Suggests placeholder or requests clarification
   - Low confidence: 0.30-0.50

## Production Implementation

### Installation & Setup
```bash
npm install @openai/agents 'zod@3.25.67'
```

**⚠️ CRITICAL DEPENDENCY WARNING:**
The OpenAI Agents SDK currently **does not work with zod@3.25.68 and above**. You MUST install zod@3.25.67 (or any older version) explicitly. This is a known compatibility issue that OpenAI is working to resolve.

### Environment Configuration
```env
# Required
OPENAI_API_KEY=your_api_key_here

# Model Configuration
OPENAI_MODEL=gpt-4o                          # Default model for agents
OPENAI_FALLBACK_MODEL=gpt-4o-mini           # Fallback for cost optimization

# Tracing
OPENAI_AGENTS_DISABLE_TRACING=false         # Enable built-in tracing
TRACE_EXTERNAL_PROVIDER=agentops             # Optional: external provider

# Processing Limits
MAX_DATA_MAP_VARIABLES=1000                  # Prevent oversized contexts
MAX_BANNER_COLUMNS=100                       # Safety limit for processing
```

### Zod Integration Best Practices & Known Issues

#### Critical Compatibility Requirements
1. **Zod Version Lock**: Must use zod@3.25.67 or earlier
2. **Property Name**: Use `outputType` (not `outputSchema`) for structured outputs
3. **Type Safety**: May require manual type assertions due to known SDK typing issues
4. **Schema Limitations**: Keep nesting under 5 levels, avoid complex unions with discriminators

#### Working Agent Implementation
```typescript
// agents/CrosstabOrchestrator.ts
import { z } from 'zod';
import { Agent, run } from '@openai/agents';
import { ValidationResultSchema } from '../schemas/validationSchema';

export const createCrosstabOrchestrator = (dataMap: any[], bannerPlan: any) => {
  const agent = new Agent({
    name: 'CrosstabOrchestrator',
    model: process.env.OPENAI_MODEL || 'gpt-4o',
    outputType: ValidationResultSchema,  // Use 'outputType', not 'outputSchema'
    instructions: `
      You are validating banner plan expressions against a data map.
      
      VARIABLE PATTERNS:
      - Variables: S2, S2a, A3r1, B5r2
      - Filters: S2=1 (S2 is variable, =1 is filter)
      - Complex: S2=1 AND S2a=1 (variables are S2, S2a)
      - Conceptual: "IF HCP" needs interpretation
      
      R SYNTAX:
      - Equality: S2 == 1
      - Logic: & (AND), | (OR)
      - Multiple values: S2 %in% c(1,2,3)
      - Grouping: (S2 == 1 & S2a == 1)
      
      WORKFLOW:
      Process each group sequentially. For each column:
      1. Extract variables from "original" 
      2. Validate against data map
      3. Generate R syntax in "adjusted"
      4. Rate confidence 0-1
      5. Explain in "reason"
      
      Always suggest something, even if uncertain.
      
      DATA MAP (${dataMap.length} variables):
      ${JSON.stringify(dataMap, null, 2)}
      
      BANNER PLAN:
      ${JSON.stringify(bannerPlan, null, 2)}
    `,
    guardrails: []  // Add guardrails as needed
  });
  
  return agent;
};

// Usage with proper type handling
export async function validateBannerPlan(dataMap: any[], bannerPlan: any) {
  const agent = createCrosstabOrchestrator(dataMap, bannerPlan);
  const result = await run(agent, 'Validate the banner plan');
  
  // Type assertion may be needed due to SDK typing issues
  return result.finalOutput as z.infer<typeof ValidationResultSchema>;
}
```

#### Robust Schema Definition
```typescript
// schemas/validationSchema.ts - Keep schemas simple to avoid SDK issues
import { z } from 'zod';

export const ValidationResultSchema = z.object({
  bannerCuts: z.array(z.object({
    groupName: z.string(),
    columns: z.array(z.object({
      name: z.string(),
      adjusted: z.string().describe('R syntax expression'),
      confidence: z.number().min(0).max(1),
      reason: z.string()
    }))
  }))
});

// Avoid:
// - Unions with discriminators (oneOf issues)
// - Default values in schemas 
// - Nesting deeper than 5 levels
// - Complex optional chains
```

### Dual Output File Strategy

Phase 1 generates **four files** for Phase 2:

```
temp/
├── banner-plan-verbose.json      # Full metadata from existing parser
├── banner-plan-agent.json        # Simplified for agent context  
├── data-map-verbose.json         # Full structure with all fields
└── data-map-agent.json           # Only Column, Description, Answer_Options
```

### Context Builder Implementation
```typescript
// lib/contextBuilder.ts  
export interface VerboseDataMap {
  Level: string;
  ParentQ: string;
  Column: string;
  Description: string;
  Value_Type: string;
  Answer_Options: string;
  Context: string;
}

export interface AgentDataMap {
  Column: string;
  Description: string;
  Answer_Options: string;
}

export interface VerboseBannerGroup {
  groupName: string;
  columns: Array<{
    name: string;
    original: string;
    adjusted: string;
    statLetter: string;
    confidence: number;
    requiresInference: boolean;
    crossRefStatus: string;
    inferenceReason: string;
    humanInLoopRequired: boolean;
    aiRecommended: boolean;
    uncertainties: any[];
  }>;
}

export interface AgentBannerGroup {
  groupName: string;
  columns: Array<{
    name: string;
    original: string;
  }>;
}

// Generate both versions during Phase 1 parsing
export const generateDualOutputs = (rawBanner: any, rawDataMap: VerboseDataMap[]) => {
  // Verbose versions (keep everything)
  const verboseBanner = rawBanner; // Full structure as-is
  const verboseDataMap = rawDataMap; // Full structure as-is
  
  // Simplified versions for agent processing
  const agentBanner: AgentBannerGroup[] = rawBanner.data?.extractedStructure?.bannerCuts?.map((group: any) => ({
    groupName: group.groupName,
    columns: group.columns?.map((col: any) => ({
      name: col.name,
      original: col.original
    }))
  })) || [];
  
  const agentDataMap: AgentDataMap[] = rawDataMap.map(item => ({
    Column: item.Column,
    Description: item.Description,
    Answer_Options: item.Answer_Options
  }));
  
  return {
    verboseBanner,
    verboseDataMap,
    agentBanner,
    agentDataMap
  };
};
```

## Implementation Principles & SDK-Specific Considerations

### 1. **Trust Model Intelligence**
- Load full JSON structures into context rather than fragmented tools
- Let the model see relationships between data holistically
- Minimize tool calls by providing comprehensive context upfront

### 2. **Simplicity Over Complexity**
- Single orchestrator agent instead of multiple handoffs
- No tools needed - pure context-first approach
- Direct context injection over complex state management

### 3. **SDK Compatibility Management**
```typescript
// Proper SDK usage with compatibility considerations
import { z } from 'zod';  // Must be @3.25.67
import { Agent, run } from '@openai/agents';

// Use outputType, not outputSchema
const agent = new Agent({
  outputType: ValidationResultSchema,  // ✅ Correct
  // outputSchema: ValidationResultSchema,  // ❌ Wrong property name
});

// Handle potential typing issues
const result = await run(agent, input);
const typedOutput = result.finalOutput as z.infer<typeof ValidationResultSchema>;
```

### 4. **Intelligent Validation with SDK Constraints**
- Model understands context like "IF HCP" → healthcare professional
- Handles complex expressions: "S2=1 AND S2a=1"
- Suggests corrections when variables don't match exactly
- **Keep schemas simple** to avoid SDK JSON schema generation issues
- **Avoid complex unions** that cause oneOf validation errors

## Common Pitfalls & Solutions

### Issue 1: Type Safety Problems
**Problem**: SDK may return `any` type even with Zod schemas
**Solution**: Use type assertions: `result.finalOutput as z.infer<typeof Schema>`

### Issue 2: JSON Schema Generation Failures
**Problem**: Complex schemas with unions or defaults cause 400 errors
**Solution**: Keep schemas flat, avoid discriminated unions and default values

### Issue 3: Model Provider Incompatibility
**Problem**: Some providers don't support structured outputs
**Solution**: Use OpenAI models (gpt-4o, gpt-4o-mini) that fully support the features

### Issue 4: Nested Schema Depth
**Problem**: Schemas with >5 levels of nesting fail validation
**Solution**: Flatten data structures, avoid deeply nested objects

## Best Practices

### 1. **Guardrails-First Development**
- Implement input validation before agent processing
- Run guardrails in parallel for performance optimization
- Use fast/cheap models for guardrail checks
- Implement comprehensive output validation

### 2. **Comprehensive Observability**
- Enable tracing by default
- Use `withTrace()` for complex multi-step workflows
- Create custom spans for detailed operation tracking
- Integrate with external monitoring (AgentOps, Keywords AI)

### 3. **Robust Error Handling**
- Graceful agent failures with proper user feedback
- Retry mechanisms for transient failures
- Clear error messages for validation failures
- Fallback strategies for agent handoff failures

### 4. **Tool Design Patterns**
- Convert existing functions to agent tools
- Use Zod schemas for automatic validation
- Design tools for single responsibility
- Ensure tools are idempotent where possible

### 5. **Performance Optimization**
- Leverage parallel execution where possible
- Use appropriate model sizes for different tasks
- Implement caching for repeated operations
- Monitor token usage and costs

## Security Considerations

### Data Handling
- Never log sensitive data in traces
- Use `RunConfig.traceIncludeSensitiveData: false` for sensitive operations
- Implement proper file sanitization in guardrails
- Validate all user inputs before processing

### Agent Safety
- Implement comprehensive input guardrails
- Validate all tool outputs before handoffs
- Use output guardrails to prevent data leakage
- Monitor for unusual agent behavior patterns

## Integration with Next.js

### API Route Implementation
```typescript
// api/agents/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { run } from '@openai/agents';
import { triageAgent } from '../../agents';

export async function POST(request: NextRequest) {
  try {
    const { files, instructions } = await request.json();
    
    const result = await run(triageAgent, {
      files,
      instructions
    });
    
    return NextResponse.json(result);
  } catch (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
```

### Client Integration
- Use streaming responses for long-running operations
- Implement proper loading states
- Handle agent errors gracefully
- Provide progress feedback to users

## Monitoring & Debugging

### Development
- Use built-in trace visualization
- Monitor agent handoff patterns
- Debug tool execution flows
- Validate guardrail effectiveness

### Production
- Export traces to external providers
- Monitor performance metrics
- Track error rates and patterns
- Analyze cost and token usage


## Integration Points

### With Existing Code
The architecture assumes Phase 1 (file parsing/validation) uses existing code:
- Banner plan → JSON parser (existing)
- Data map → JSON parser (existing)  
- SPSS validation (existing)
- These feed into the agent as pre-processed JSON

### API Flow
```
Upload → Pre-processing → Agent Validation → Output
         (existing code)   (new agent)       (crosstabs)
```

## Implementation Steps
1. **Set up schemas** - Create simple, flat Zod schemas avoiding known issues
2. **Integrate existing parsers** - Connect banner/data map parsers with context builders  
3. **Implement CrosstabAgent** - Single agent with `outputType` (not `outputSchema`)
4. **Configure environment** - Set up reasoning and base model variables
5. **Add type assertions** - Handle potential SDK typing issues
6. **Test with real data** - Use provided JSON examples, validate structured outputs
7. **Add API endpoint** - Single route for the complete workflow
8. **Monitor for SDK updates** - Watch for Zod compatibility fixes

## Implementation Scope & Next Steps

### Current Focus: Cross-Reference Validation Only

**What This Implementation Covers:**
- Banner plan parsing and group-by-group processing
- Variable extraction and data map validation
- Confidence scoring and mapping status assessment
- Structured output ready for downstream processing

**What This Implementation Does NOT Cover:**
- Post-orchestrator JSON format conversion (verbose output regeneration)
- R script generation from validated mappings
- Crosstab execution and output formatting
- Advanced statistical processing

**Rationale for Limited Scope:**
By focusing exclusively on the cross-referencing phase, we can:
1. **Debug more effectively** - Validate core mapping intelligence before building scaffolding
2. **Test systematically** - Verify agent performance on real banner/data map pairs
3. **Iterate rapidly** - Refine system prompts and confidence scoring without complexity
4. **Validate approach** - Confirm this architecture works before expanding scope

Once cross-reference validation is working reliably, we'll extend to handle the full pipeline from validated mappings to executable R scripts.

### Enhanced Tool Suite

**Minimal Tools Approach** - Most processing via context injection:

```typescript
// Enhanced scratchpad tool for reasoning models
scratchpad(action: 'add' | 'review', content: string)

// Usage examples:
scratchpad('add', 'Working on group: Specialty. Found S2=1 AND S2a=1, parsing variables...')
scratchpad('review', 'Summary: 5/5 columns mapped successfully, all direct matches, high confidence')
```

**Tool Rationale**: Essential for reasoning models since detailed tracing logs may not be available. Provides audit trail for complex mapping decisions and step-by-step reasoning.

## Summary

This streamlined architecture maximizes the four core SDK concepts:
- **Agents**: Single CrosstabAgent with full context visibility
- **Structured Outputs**: Zod-enforced schemas for consistent results  
- **Guardrails**: Input/output validation for safety and quality
- **Tracing**: Built-in observability with environment configuration

The approach trusts model intelligence with simplified JSON schemas while maintaining production-ready robustness through structured outputs and comprehensive observability.