# Phase 1: Azure OpenAI Migration via Vercel AI SDK

## Implementation Plan

**Goal**: Migrate from OpenAI Agents SDK to Vercel AI SDK with Azure OpenAI provider for Hawk Partners compliance.

**Branch**: `feature-azure-openai-migration` (current feature branch)

**Testing Strategy**: Complete migration on feature branch → thorough testing → merge to development → additional testing → merge to production

---

## Executive Summary

The current system uses `@openai/agents` which **does not support Azure OpenAI**. Hawk Partners requires Azure OpenAI for compliance (firm data cannot go to OpenAI directly). This migration switches to Vercel AI SDK (`ai` + `@ai-sdk/azure`) which has first-class Azure support.

### Key Changes

| Component | Current | Target |
|-----------|---------|--------|
| AI Framework | `@openai/agents ^0.0.15` | `ai ^6.0.5` + `@ai-sdk/azure ^3.0.2` |
| Zod Version | `^3.25.67` (locked) | `^3.25.76` or `^4.x` (unlocked) |
| API Key | `OPENAI_API_KEY` | `AZURE_API_KEY` + `AZURE_RESOURCE_NAME` |
| Model Selection | `getModel()` → model name string (env-based) | `getReasoningModel()` / `getBaseModel()` → task-based Azure model instances |
| Tool Pattern | `tool({ name, parameters, execute })` | `tool({ inputSchema, execute })` (name inferred from object key) |
| Structured Output | `outputType` property on Agent | `output: Output.object({ schema })` in generateText |
| Agent Pattern | `new Agent({...})` + `run(agent, prompt)` | Direct `generateText({...})` call |
| Token Config | `modelSettings: { maxTokens }` nested | `maxTokens` at top level of generateText |
| Tracing | `withTrace()` + `getGlobalTraceProvider()` | Console logging with structured format (Sentry Phase 2) |
| Image Format | `{ type: 'input_image', image: 'data:...' }` | `{ type: 'image', image: Buffer.from(base64, 'base64') }` |

---

## Pre-Implementation Checklist

- [x] Confirm Azure OpenAI resource exists at Hawk Partners ✓
- [x] Get Azure resource name ✓
- [x] Get Azure API key ✓
- [x] Confirm deployment names:
  - Reasoning model: `o4-mini`
  - Base model: `gpt-5-nano`
- [x] Verify base model supports vision (for BannerAgent) - gpt-5-nano is multimodal ✓

---

## Implementation Approach

### Discovery-First Pattern

Before modifying each file, **always run discovery** to understand the current state:

```bash
# Before each step, discover all usages of what you're changing:
grep -r "@openai/agents" src/          # Find all OpenAI Agents SDK imports
grep -r "withTrace" src/                # Find all tracing usages
grep -r "getGlobalTraceProvider" src/   # Find trace flush calls
grep -r "OPENAI_API_KEY" src/           # Find OpenAI API key references
grep -r "input_image" src/              # Find image format usages
```

### Cleanup Verification

After each step, verify the cleanup is complete:

```bash
npm run lint                            # Must pass
npx tsc --noEmit                        # Must pass - no type errors
grep -r "@openai/agents" src/           # Should return NO results after Step 1
```

### Tracing Replacement Strategy

The OpenAI Agents SDK provides built-in tracing via `withTrace()` and `getGlobalTraceProvider()`. We are **not just removing tracing**—we are replacing it with structured console logging that:

1. **Maintains observability**: All agent operations are logged with timestamps, durations, and context
2. **Prepares for Sentry**: Log format matches what Sentry will capture in Phase 2
3. **Includes processing logs**: Every agent call records to a `processingLog` array that's saved with outputs

The replacement pattern:

```typescript
// BEFORE: OpenAI Agents SDK tracing
const result = await withTrace('Operation Name', async () => {
  // ... processing
});
await getGlobalTraceProvider().forceFlush();

// AFTER: Structured logging (Sentry-ready)
const startTime = Date.now();
console.log(`[AgentName] Starting: Operation Name`);
// ... processing
const duration = Date.now() - startTime;
console.log(`[AgentName] Completed: Operation Name (${duration}ms)`);
```

---

## Step-by-Step Implementation

### Step 1: Update Dependencies

**File**: `package.json`

```bash
# Remove OpenAI Agents SDK
npm uninstall @openai/agents

# Install Vercel AI SDK + Azure provider
npm install ai @ai-sdk/azure

# Upgrade Zod (required by @ai-sdk/azure)
npm install zod@^3.25.76
```

**Expected package.json changes**:

```diff
  "dependencies": {
-   "@openai/agents": "^0.0.15",
+   "ai": "^6.0.5",
+   "@ai-sdk/azure": "^3.0.2",
    // ...
-   "zod": "^3.25.67"
+   "zod": "^3.25.76"
  }
```

**Why Zod upgrade is safe**: The `^3.25.67` lock was specifically for OpenAI Agents SDK compatibility (see [GitHub Issue #187](https://github.com/openai/openai-agents-js/issues/187)). Once we remove `@openai/agents`, the constraint no longer applies. The `@ai-sdk/azure` package requires `zod: ^3.25.76 || ^4.1.8`.

---

### Step 2: Update Environment Configuration

**File**: `src/lib/types.ts`

Add Azure-specific fields to `EnvironmentConfig`:

```typescript
export interface EnvironmentConfig {
  // Azure OpenAI (new)
  azureApiKey: string;
  azureResourceName: string;
  azureApiVersion: string;  // e.g., '2024-10-21' for Azure AI Foundry

  // Model configuration (Azure deployment names)
  reasoningModel: string;  // e.g., 'o4-mini'
  baseModel: string;       // e.g., 'gpt-5-nano' (must support vision)

  // Deprecated
  openaiApiKey?: string;  // Optional, deprecated

  nodeEnv: 'development' | 'production';
  tracingEnabled: boolean;  // Renamed from tracingDisabled
  promptVersions: {
    crosstabPromptVersion: string;
    bannerPromptVersion: string;
  };
  processingLimits: {
    maxDataMapVariables: number;
    maxBannerColumns: number;
    reasoningModelTokens: number;
    baseModelTokens: number;
  };
}
```

**File**: `src/lib/env.ts`

Complete rewrite:

```typescript
/**
 * Environment configuration
 * Purpose: Resolve Azure OpenAI model, token limits, prompt versions, and validation
 * Required: AZURE_API_KEY, AZURE_RESOURCE_NAME, REASONING_MODEL, BASE_MODEL
 * Optional: NODE_ENV, prompt versions, token/limit overrides
 */

import { azure, createAzure } from '@ai-sdk/azure';
import { EnvironmentConfig } from './types';

// Create Azure provider instance (cached)
let azureProvider: ReturnType<typeof createAzure> | null = null;

export const getAzureProvider = () => {
  if (!azureProvider) {
    const config = getEnvironmentConfig();
    azureProvider = createAzure({
      resourceName: config.azureResourceName,
      apiKey: config.azureApiKey,
      // Use explicit API version for Azure AI Foundry compatibility
      apiVersion: config.azureApiVersion,
      // Use deployment-based URLs (standard Azure OpenAI format)
      // URL format: https://{resourceName}.openai.azure.com/openai/deployments/{deploymentId}/...?api-version={apiVersion}
      useDeploymentBasedUrls: true,
    });
  }
  return azureProvider;
};

export const getEnvironmentConfig = (): EnvironmentConfig => {
  // Validate required Azure environment variables
  const azureApiKey = process.env.AZURE_API_KEY;
  const azureResourceName = process.env.AZURE_RESOURCE_NAME;

  if (!azureApiKey) {
    throw new Error('AZURE_API_KEY environment variable is required');
  }
  if (!azureResourceName) {
    throw new Error('AZURE_RESOURCE_NAME environment variable is required');
  }

  // Azure API version (for Azure AI Foundry compatibility)
  // See: https://learn.microsoft.com/en-us/azure/ai-services/openai/api-version-lifecycle
  const azureApiVersion = process.env.AZURE_API_VERSION || '2025-01-01-preview';

  // Model configuration (Azure deployment names)
  const reasoningModel = process.env.REASONING_MODEL || 'o4-mini';
  const baseModel = process.env.BASE_MODEL || 'gpt-5-nano';

  const nodeEnv = (process.env.NODE_ENV as 'development' | 'production') || 'development';

  return {
    azureApiKey,
    azureResourceName,
    azureApiVersion,

    // Model configuration
    reasoningModel,
    baseModel,

    // Deprecated
    openaiApiKey: process.env.OPENAI_API_KEY,  // Optional, deprecated

    nodeEnv,
    tracingEnabled: process.env.TRACING_ENABLED !== 'false',  // Default: enabled
    promptVersions: {
      crosstabPromptVersion: process.env.CROSSTAB_PROMPT_VERSION || 'production',
      bannerPromptVersion: process.env.BANNER_PROMPT_VERSION || 'production',
    },
    processingLimits: {
      maxDataMapVariables: parseInt(process.env.MAX_DATA_MAP_VARIABLES || '1000'),
      maxBannerColumns: parseInt(process.env.MAX_BANNER_COLUMNS || '100'),
      reasoningModelTokens: parseInt(process.env.REASONING_MODEL_TOKENS || '100000'),
      baseModelTokens: parseInt(process.env.BASE_MODEL_TOKENS || '128000'),
    },
  };
};

/**
 * Task-based model selection
 * Models are chosen based on task requirements, not environment:
 * - Reasoning model (o4-mini): Complex validation tasks (CrosstabAgent)
 * - Base model (gpt-5-nano): Vision/extraction tasks (BannerAgent)
 */

/**
 * Get reasoning model for complex validation tasks
 * Used by: CrosstabAgent (requires deep reasoning for R syntax generation)
 */
export const getReasoningModel = () => {
  const config = getEnvironmentConfig();
  return azure(config.reasoningModel);
};

/**
 * Get base model for vision/extraction tasks
 * Used by: BannerAgent (requires vision capability, simpler reasoning)
 */
export const getBaseModel = () => {
  const config = getEnvironmentConfig();
  return azure(config.baseModel);
};

/**
 * Get model name string (for logging)
 */
export const getReasoningModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.reasoningModel}`;
};

export const getBaseModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.baseModel}`;
};

export const getReasoningModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.reasoningModelTokens;
};

export const getBaseModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.baseModelTokens;
};

export const getPromptVersions = () => {
  const config = getEnvironmentConfig();
  return config.promptVersions;
};

export const validateEnvironment = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = [];

  try {
    const config = getEnvironmentConfig();

    // Azure API key format is flexible (not sk-* like OpenAI)
    if (config.azureApiKey.length < 10) {
      errors.push('AZURE_API_KEY appears too short');
    }

    // Validate resource name format
    if (!/^[a-zA-Z0-9-]+$/.test(config.azureResourceName)) {
      errors.push('AZURE_RESOURCE_NAME should only contain alphanumeric characters and hyphens');
    }

    // Validate processing limits
    if (config.processingLimits.maxDataMapVariables < 1) {
      errors.push('MAX_DATA_MAP_VARIABLES must be greater than 0');
    }

    if (config.processingLimits.maxBannerColumns < 1) {
      errors.push('MAX_BANNER_COLUMNS must be greater than 0');
    }

    if (config.processingLimits.baseModelTokens < 1000) {
      errors.push('BASE_MODEL_TOKENS must be at least 1000');
    }

  } catch (error) {
    errors.push(error instanceof Error ? error.message : 'Unknown environment error');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};
```

**File**: `.env.local` (update your local config)

```bash
# Azure OpenAI Configuration (Required)
AZURE_API_KEY=your-azure-api-key
AZURE_RESOURCE_NAME=crosstab-ai
# API version for Azure AI Foundry (must match your deployment's target URI)
# See: https://learn.microsoft.com/en-us/azure/ai-services/openai/api-version-lifecycle
AZURE_API_VERSION=2025-01-01-preview

# Model Configuration (Task-based, not environment-based)
# These are Azure deployment names (from your Azure AI Foundry deployments)
REASONING_MODEL=o4-mini
BASE_MODEL=gpt-5-nano
REASONING_MODEL_TOKENS=100000
BASE_MODEL_TOKENS=128000

# Optional: Prompt versions
CROSSTAB_PROMPT_VERSION=production
BANNER_PROMPT_VERSION=production

# Optional: Processing limits
MAX_DATA_MAP_VARIABLES=1000
MAX_BANNER_COLUMNS=100

# Optional: Tracing (default: enabled)
TRACING_ENABLED=true

# Node environment
NODE_ENV=development
```

**File**: `.env.example` (create or update for team reference)

```bash
# Azure OpenAI Configuration (Required)
# Get these from Azure Portal > Your OpenAI Resource
AZURE_API_KEY=
AZURE_RESOURCE_NAME=
# API version for Azure AI Foundry (must match your deployment's target URI)
# See: https://learn.microsoft.com/en-us/azure/ai-services/openai/api-version-lifecycle
AZURE_API_VERSION=2025-01-01-preview

# Model Configuration (Required, Task-based)
# These are Azure deployment names (from your Azure AI Foundry deployments)
REASONING_MODEL=o4-mini
BASE_MODEL=gpt-5-nano
REASONING_MODEL_TOKENS=100000
BASE_MODEL_TOKENS=128000

# Optional settings with defaults shown
CROSSTAB_PROMPT_VERSION=production
BANNER_PROMPT_VERSION=production
MAX_DATA_MAP_VARIABLES=1000
MAX_BANNER_COLUMNS=100
TRACING_ENABLED=true
NODE_ENV=development
```

**Remove from .env files** (no longer used):
- `OPENAI_API_KEY`
- `OPENAI_AGENTS_DISABLE_TRACING`
- `AZURE_DEPLOYMENT_NAME` (replaced by REASONING_MODEL and BASE_MODEL)

---

### Step 3: Migrate Scratchpad Tool

**File**: `src/agents/tools/scratchpad.ts`

```typescript
/**
 * Scratchpad tool for reasoning transparency
 * Provides enhanced thinking space for complex variable validation tasks
 */

import { tool } from 'ai';
import { z } from 'zod';

// Scratchpad tool using Vercel AI SDK pattern
export const scratchpadTool = tool({
  description: 'Enhanced thinking space for reasoning models to show validation steps and reasoning. Use this to document your analysis process.',
  inputSchema: z.object({
    action: z.enum(['add', 'review']).describe('Action to perform: add new thoughts or review current analysis'),
    content: z.string().describe('Content to add or review in the thinking space')
  }),
  execute: async ({ action, content }) => {
    // Log for debugging
    console.log(`[CrossTab Agent Scratchpad] ${action}: ${content}`);

    switch (action) {
      case 'add':
        return `[Thinking] Added: ${content}`;
      case 'review':
        return `[Review] ${content}`;
      default:
        return `[Scratchpad] Unknown action: ${action}`;
    }
  }
});

// Type export for use in agent definitions
export type ScratchpadTool = typeof scratchpadTool;
```

**Key differences from OpenAI Agents SDK**:
- Import from `'ai'` instead of `'@openai/agents'`
- No `name` property (tool name is inferred from the object key when passed to `generateText`)
- **`parameters` renamed to `inputSchema`** - this is required by AI SDK v6 (see [AI SDK Tools Documentation](https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling))
- `execute` function receives validated input and returns the tool result

---

### Step 4: Migrate CrosstabAgent

**File**: `src/agents/CrosstabAgent.ts`

```typescript
/**
 * CrosstabAgent
 * Purpose: Validate banner groups against data map; emit adjusted R expressions + confidence
 * Reads: agent banner groups + processed data map
 * Writes (dev): temp-outputs/output-<ts>/crosstab-output-<ts>.json (with processing info)
 * Invariants: group-by-group validation; uses scratchpad
 */

import { generateText, Output } from 'ai';
import { ValidationResultSchema, ValidatedGroupSchema, combineValidationResults, type ValidationResultType, type ValidatedGroupType } from '../schemas/agentOutputSchema';
import { DataMapType } from '../schemas/dataMapSchema';
import { BannerGroupType, BannerPlanInputType } from '../schemas/bannerPlanSchema';
import { getReasoningModel, getReasoningModelName, getReasoningModelTokenLimit, getPromptVersions } from '../lib/env';
import { scratchpadTool } from './tools/scratchpad';
import { getCrosstabPrompt } from '../prompts';
import fs from 'fs/promises';
import path from 'path';

// Get modular validation instructions based on environment variable
const getCrosstabValidationInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getCrosstabPrompt(promptVersions.crosstabPromptVersion);
};

// Process single banner group using Vercel AI SDK
export async function processGroup(dataMap: DataMapType, group: BannerGroupType): Promise<ValidatedGroupType> {
  console.log(`[CrosstabAgent] Processing group: ${group.groupName} (${group.columns.length} columns)`);

  try {
    // Build system prompt with context injection
    const systemPrompt = `
${getCrosstabValidationInstructions()}

CURRENT CONTEXT DATA:

DATA MAP (${dataMap.length} variables):
${JSON.stringify(dataMap, null, 2)}

BANNER GROUP TO VALIDATE:
Group: "${group.groupName}"
${JSON.stringify(group, null, 2)}

PROCESSING REQUIREMENTS:
- Validate all ${group.columns.length} columns in this group
- Generate R syntax for each column's "original" expression
- Provide confidence scores and detailed reasoning
- Use scratchpad to show your validation process

Begin validation now.
`;

    // Use generateText with structured output
    const { output } = await generateText({
      model: getReasoningModel(),  // Task-based: reasoning model for complex validation
      system: systemPrompt,
      prompt: `Validate banner group "${group.groupName}" with ${group.columns.length} columns against the data map.`,
      tools: {
        scratchpad: scratchpadTool,
      },
      maxSteps: 25,  // Equivalent to maxTurns
      maxTokens: Math.min(getReasoningModelTokenLimit(), 10000),
      output: Output.object({
        schema: ValidatedGroupSchema,
      }),
    });

    if (!output || !output.columns) {
      throw new Error(`Invalid agent response for group ${group.groupName}`);
    }

    console.log(`[CrosstabAgent] Group ${group.groupName} processed successfully - ${output.columns.length} columns validated`);

    return output;

  } catch (error) {
    console.error(`[CrosstabAgent] Error processing group ${group.groupName}:`, error);

    // Check if it's a max steps error
    const isMaxStepsError = error instanceof Error &&
      (error.message.includes('Max steps') || error.message.includes('maximum'));
    const errorType = isMaxStepsError
      ? 'Max steps exceeded - consider simplifying expressions'
      : 'Processing error';

    // Return fallback result with low confidence
    return {
      groupName: group.groupName,
      columns: group.columns.map(col => ({
        name: col.name,
        adjusted: `# Error: ${errorType} for "${col.original}"`,
        confidence: 0.0,
        reason: `${errorType}: ${error instanceof Error ? error.message : 'Unknown error'}. Manual review required.`
      }))
    };
  }
}

// Process all banner groups using group-by-group strategy
export async function processAllGroups(
  dataMap: DataMapType,
  bannerPlan: BannerPlanInputType,
  outputFolder?: string,
  onProgress?: (completedGroups: number, totalGroups: number) => void
): Promise<{ result: ValidationResultType; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  logEntry(`[CrosstabAgent] Starting group-by-group processing: ${bannerPlan.bannerCuts.length} groups`);
  logEntry(`[CrosstabAgent] Using model: ${getReasoningModelName()}`);

  const results: ValidatedGroupType[] = [];

  // Process each group individually (group-by-group approach)
  for (let i = 0; i < bannerPlan.bannerCuts.length; i++) {
    const group = bannerPlan.bannerCuts[i];
    const groupStartTime = Date.now();

    logEntry(`[CrosstabAgent] Processing group ${i + 1}/${bannerPlan.bannerCuts.length}: "${group.groupName}" (${group.columns.length} columns)`);

    const groupResult = await processGroup(dataMap, group);
    results.push(groupResult);

    const groupDuration = Date.now() - groupStartTime;
    const avgConfidence = groupResult.columns.reduce((sum, col) => sum + col.confidence, 0) / groupResult.columns.length;

    logEntry(`[CrosstabAgent] Group "${group.groupName}" completed in ${groupDuration}ms - Avg confidence: ${avgConfidence.toFixed(2)}`);
    try { onProgress?.(i + 1, bannerPlan.bannerCuts.length); } catch {}
  }

  const combinedResult = combineValidationResults(results);

  // Save outputs with processing log
  if (outputFolder) {
    await saveDevelopmentOutputs(combinedResult, outputFolder, processingLog);
  }

  logEntry(`[CrosstabAgent] All ${results.length} groups processed successfully - Total columns: ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)}`);

  return { result: combinedResult, processingLog };
}

// Parallel processing option (for future optimization)
export async function processAllGroupsParallel(
  dataMap: DataMapType,
  bannerPlan: BannerPlanInputType
): Promise<{ result: ValidationResultType; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  logEntry(`[CrosstabAgent] Starting parallel processing: ${bannerPlan.bannerCuts.length} groups`);
  logEntry(`[CrosstabAgent] Using model: ${getReasoningModelName()}`);

  try {
    logEntry(`[CrosstabAgent] Starting parallel group processing`);
    const groupPromises = bannerPlan.bannerCuts.map((group, index) => {
      logEntry(`[CrosstabAgent] Queuing group ${index + 1}: "${group.groupName}"`);
      return processGroup(dataMap, group);
    });

    const results = await Promise.all(groupPromises);
    const combinedResult = combineValidationResults(results);

    logEntry(`[CrosstabAgent] Parallel processing completed - ${results.length} groups, ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)} total columns`);

    return { result: combinedResult, processingLog };

  } catch (error) {
    logEntry(`[CrosstabAgent] Parallel processing failed, falling back to sequential: ${error instanceof Error ? error.message : 'Unknown error'}`);

    // Fall back to sequential processing
    const results: ValidatedGroupType[] = [];

    for (const group of bannerPlan.bannerCuts) {
      logEntry(`[CrosstabAgent] Sequential fallback processing: "${group.groupName}"`);
      const groupResult = await processGroup(dataMap, group);
      results.push(groupResult);
    }

    logEntry(`[CrosstabAgent] Sequential fallback completed`);
    return { result: combineValidationResults(results), processingLog };
  }
}

// Validation helpers
export const validateAgentResult = (result: unknown): ValidationResultType => {
  return ValidationResultSchema.parse(result);
};

export const isValidAgentResult = (result: unknown): result is ValidationResultType => {
  return ValidationResultSchema.safeParse(result).success;
};

// Save development outputs
async function saveDevelopmentOutputs(
  result: ValidationResultType,
  outputFolder: string,
  processingLog?: string[]
): Promise<void> {
  try {
    const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolder);
    await fs.mkdir(outputDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `crosstab-output-${timestamp}.json`;
    const filePath = path.join(outputDir, filename);

    // Enhanced output with processing information
    const enhancedOutput = {
      ...result,
      processingInfo: {
        timestamp: new Date().toISOString(),
        processingMode: 'group-by-group',
        aiProvider: 'azure-openai',
        model: getReasoningModelName(),
        totalGroups: result.bannerCuts.length,
        totalColumns: result.bannerCuts.reduce((total, group) => total + group.columns.length, 0),
        averageConfidence: result.bannerCuts.length > 0
          ? result.bannerCuts
              .flatMap(group => group.columns)
              .reduce((sum, col) => sum + col.confidence, 0)
            / result.bannerCuts.flatMap(group => group.columns).length
          : 0,
        processingLog: processingLog || []
      }
    };

    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');
    console.log(`[CrosstabAgent] Development output saved: ${filename}`);
  } catch (error) {
    console.error('[CrosstabAgent] Failed to save development outputs:', error);
  }
}
```

**Key migration changes**:

1. **No Agent class**: Vercel AI SDK uses `generateText()` directly with tools
2. **Structured output**: Uses `output: Output.object({ schema })` instead of `outputType`
3. **Tools as object**: Tools passed as `{ scratchpad: scratchpadTool }` not array
4. **maxSteps**: Replaces `maxTurns` for multi-step tool calling
5. **No tracing**: Removed `withTrace()` and `getGlobalTraceProvider()` (Sentry in Phase 2)
6. **Task-based model**: `getReasoningModel()` returns Azure reasoning model instance (o4-mini) for complex validation

---

### Step 5: Migrate BannerAgent

**File**: `src/agents/BannerAgent.ts`

**Discovery**: BannerAgent is a **500+ line class** with multiple methods. Run discovery first:

```bash
grep -n "import.*@openai/agents" src/agents/BannerAgent.ts    # Find SDK imports
grep -n "new Agent" src/agents/BannerAgent.ts                  # Find Agent instantiation
grep -n "run(" src/agents/BannerAgent.ts                       # Find run() calls
grep -n "input_image" src/agents/BannerAgent.ts                # Find image format
grep -n "maxTurns" src/agents/BannerAgent.ts                   # Find turn limits
```

**What Changes**:

1. **Imports**: Replace `@openai/agents` with `ai` imports
2. **`createBannerAgent()` function**: Remove entirely (no Agent class in Vercel AI SDK)
3. **`extractBannerStructureWithAgent()` method**: Rewrite to use `generateText()` directly
4. **Image format**: Change from data URL to Buffer format
5. **Class structure**: Keep the class, only modify the agent-related methods

**Import Changes**:

```diff
- import { Agent, run } from '@openai/agents';
+ import { generateText, Output } from 'ai';
```

**Key Method Migration** - `extractBannerStructureWithAgent()`:

```typescript
// The method signature stays the same
private async extractBannerStructureWithAgent(images: ProcessedImage[]): Promise<BannerExtractionResult> {
  console.log(`[BannerAgent] Starting agent-based extraction with ${images.length} images`);

  try {
    const systemPrompt = `
${getBannerExtractionPrompt()}

IMAGES TO ANALYZE:
You have ${images.length} image(s) of the banner plan document to analyze.

PROCESSING REQUIREMENTS:
- Use your scratchpad to think through the group identification process
- Identify visual separators, merged headers, and logical groupings
- Create separate bannerCuts entries for each logical group
- Show your reasoning for group boundaries in the scratchpad
- Extract all columns with exact filter expressions

Begin analysis now.
`;

    // CRITICAL: Image format is different in Vercel AI SDK
    // OpenAI Agents SDK: { type: 'input_image', image: 'data:image/png;base64,...' }
    // Vercel AI SDK: { type: 'image', image: Buffer.from(base64, 'base64') }
    const { output } = await generateText({
      model: getBaseModel(),  // Task-based: base model for vision/extraction tasks
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Analyze the banner plan images and extract column specifications with proper group separation.' },
            ...images.map(img => ({
              type: 'image' as const,
              image: Buffer.from(img.base64, 'base64'),
              mimeType: `image/${img.format}` as const,
            })),
          ],
        },
      ],
      tools: {
        scratchpad: scratchpadTool,
      },
      maxSteps: 15,  // Replaces maxTurns
      maxTokens: Math.min(getBaseModelTokenLimit(), 32000),  // Top-level, not in modelSettings
      output: Output.object({
        schema: BannerExtractionResultSchema,
      }),
    });

    if (!output || !output.extractedStructure) {
      throw new Error('Invalid agent response structure');
    }

    console.log(`[BannerAgent] Agent extracted ${output.extractedStructure.bannerCuts.length} groups`);

    return output;

  } catch (error) {
    console.error('[BannerAgent] Agent extraction failed:', error);
    // ... existing error handling stays the same
  }
}
```

**Methods That Stay Unchanged** (no OpenAI SDK dependencies):
- `processDocument()` - main entry point, orchestrates other methods
- `ensurePDF()` - DOC/DOCX to PDF conversion
- `convertDocToPDF()` - uses mammoth + pdf-lib
- `convertPDFToImages()` - uses pdf2pic + sharp
- `generateDualOutputs()` - pure data transformation
- `calculateConfidence()` - pure calculation
- `createFailureResult()` - pure data construction
- `saveDevelopmentOutputs()` - file I/O only

**Remove Entirely**:
- `createBannerAgent()` function - no longer needed

**Image handling note**: Azure OpenAI vision requires a multimodal deployment. BannerAgent always uses the base model (gpt-5-nano) regardless of environment because it's a vision/extraction task. The reasoning model (o4-mini) is reserved for CrosstabAgent's complex validation tasks.

---

### Step 6: Update RScriptAgent (Tracing Replacement)

**File**: `src/agents/RScriptAgent.ts`

**Discovery**: The RScriptAgent wraps its **entire `generate()` method** in `withTrace()`. Run discovery:

```bash
grep -n "withTrace" src/agents/RScriptAgent.ts      # Find trace wrapper location
grep -n "getGlobalTraceProvider" src/agents/RScriptAgent.ts  # Find flush call
grep -n "import.*@openai/agents" src/agents/RScriptAgent.ts  # Find import
```

**Current Structure** (important to understand):
```typescript
async generate(sessionId: string): Promise<RScriptOutput> {
  const sessionDir = path.join(process.cwd(), 'temp-outputs', sessionId);

  // THE ENTIRE METHOD BODY is wrapped in withTrace:
  const result = await withTrace(`R Script Generation - ${sessionId}`, async () => {
    const validation = await loadValidationOrCutTable(sessionDir);
    const dataMap = await loadAgentDataMap(sessionDir);
    const known = new Set(getVariableNames(dataMap));
    const { script, columns, groups } = buildRScript(sessionId, validation);
    // ... 30+ lines of processing logic
    return RScriptOutputSchema.parse(output);
  });

  try {
    await getGlobalTraceProvider().forceFlush();
  } catch {
    // ignore trace flush errors
  }

  return result;
}
```

**What Changes**:

1. **Remove import**: Delete `import { withTrace, getGlobalTraceProvider } from '@openai/agents';`
2. **Unwrap `withTrace()`**: Move all the processing logic out of the callback
3. **Replace with structured logging**: Add timing logs to maintain observability
4. **Remove `forceFlush()`**: No longer needed

**Migration Pattern**:

```typescript
// BEFORE
const result = await withTrace(`R Script Generation - ${sessionId}`, async () => {
  // ... processing
});
await getGlobalTraceProvider().forceFlush();
return result;

// AFTER
const startTime = Date.now();
console.log(`[RScriptAgent] Starting R Script Generation for session: ${sessionId}`);

// ... same processing logic, now at top level of method
const validation = await loadValidationOrCutTable(sessionDir);
const dataMap = await loadAgentDataMap(sessionDir);
// etc.

const duration = Date.now() - startTime;
console.log(`[RScriptAgent] R Script Generation completed (${duration}ms) - ${groups} groups, ${columns} columns`);

return RScriptOutputSchema.parse(output);
```

**Note**: The `generateMasterFromManifest()` method does NOT use tracing—it's pure deterministic logic and requires no changes.

---

### Step 7: Update Tracing Module

**File**: `src/lib/tracing.ts`

**Current Issue**: References `OPENAI_AGENTS_DISABLE_TRACING` environment variable which becomes meaningless.

**Update to generic naming**:

```typescript
/**
 * Tracing helpers
 * Purpose: Structured logging for observability (Sentry integration in Phase 2)
 */

export interface TracingConfig {
  enabled: boolean;
  externalProvider?: string;
  includeSensitiveData: boolean;
}

export const getTracingConfig = (): TracingConfig => {
  return {
    // Changed from OPENAI_AGENTS_DISABLE_TRACING to generic TRACING_ENABLED
    enabled: process.env.TRACING_ENABLED !== 'false',
    externalProvider: process.env.TRACE_EXTERNAL_PROVIDER,
    includeSensitiveData: false,
  };
};

// ... rest of file stays the same
```

**Environment Variable Change**:
- Old: `OPENAI_AGENTS_DISABLE_TRACING=true` (disable)
- New: `TRACING_ENABLED=false` (disable) or `TRACING_ENABLED=true` (enable, default)

---

### Step 8: Update Agent Index Export

**File**: `src/agents/index.ts`

**Discovery**: Check current exports and what's missing:

```bash
cat src/agents/index.ts                           # See current exports
grep -r "from.*BannerAgent" src/                  # Find BannerAgent import patterns
```

**Current Issue**: BannerAgent class is imported directly in API route, not through index.

**Updated exports** (keep BannerAgent as class export for compatibility):

```typescript
// CrossTab Agent exports
export {
  createCrosstabAgent,  // Keep if still used
  processGroup,
  processAllGroups,
  processAllGroupsParallel,
  validateAgentResult,
  isValidAgentResult
} from './CrosstabAgent';

// Banner Agent exports (class-based)
export { BannerAgent } from './BannerAgent';
export type { BannerProcessingResult, ProcessedImage } from './BannerAgent';

// R Script Agent exports
export { RScriptAgent } from './RScriptAgent';
export type { RScriptOutput, RScriptIssue } from './RScriptAgent';

// Tool exports
export { scratchpadTool } from './tools/scratchpad';

// Remove deprecated exports
// - createCrosstabAgent if not used externally (check with grep first)
```

---

### Step 9: Verify API Route Compatibility

**File**: `src/app/api/process-crosstab/route.ts`

**Discovery**: Check what the API route imports and uses:

```bash
grep -n "validateEnvironment" src/app/api/process-crosstab/route.ts
grep -n "OPENAI" src/app/api/process-crosstab/route.ts
grep -n "processAllGroups" src/app/api/process-crosstab/route.ts
```

**What to Verify**:

1. **`validateEnvironment()` changes**: The function now validates Azure credentials, not OpenAI. The error messages will change (no more "must start with sk-" check).

2. **Import paths unchanged**: If using index exports, no changes needed. If importing directly, paths stay same.

3. **Function signatures unchanged**: `processAllGroups()` keeps same signature.

**Potential Issue** (already addressed in Step 2):
```typescript
// OLD validation in env.ts:
if (!config.openaiApiKey.startsWith('sk-')) {
  errors.push('OPENAI_API_KEY must start with "sk-"');
}

// NEW validation in env.ts:
if (config.azureApiKey.length < 10) {
  errors.push('AZURE_API_KEY appears too short');
}
```

This is handled in the `env.ts` rewrite, but verify the API route doesn't have any additional OpenAI-specific checks.

---

## Testing Plan

### Unit Tests

1. **Environment Configuration**
   ```typescript
   // Test Azure config loading
   process.env.AZURE_API_KEY = 'test-key';
   process.env.AZURE_RESOURCE_NAME = 'test-resource';
   process.env.REASONING_MODEL = 'o4-mini';
   process.env.BASE_MODEL = 'gpt-5-nano';

   const config = getEnvironmentConfig();
   expect(config.azureApiKey).toBe('test-key');
   expect(config.reasoningModel).toBe('o4-mini');
   expect(config.baseModel).toBe('gpt-5-nano');

   // Task-based model selection (not environment-based)
   expect(getReasoningModelName()).toBe('azure/o4-mini');  // For CrosstabAgent
   expect(getBaseModelName()).toBe('azure/gpt-5-nano');    // For BannerAgent
   ```

2. **Tool Definition**
   ```typescript
   // Verify scratchpad tool works
   const result = await scratchpadTool.execute({ action: 'add', content: 'test' });
   expect(result).toContain('[Thinking]');
   ```

### Integration Tests

1. **Single Group Processing**
   ```bash
   # Test with minimal data map and single banner group
   curl -X POST http://localhost:3000/api/process-crosstab \
     -F "dataMap=@test-data/minimal-datamap.csv" \
     -F "bannerPlan=@test-data/minimal-banner.pdf" \
     -F "dataFile=@test-data/minimal-data.sav"
   ```

2. **Full Pipeline Test**
   - Use existing test project from `data/` folder
   - Compare output to previous OpenAI Agents SDK output
   - Verify confidence scores are in expected ranges
   - Verify R syntax is valid

### Regression Tests

1. All 6 banner groups process successfully
2. 192+ variables are handled
3. Output JSON schema matches `ValidationResultSchema`
4. R scripts generate and execute correctly

---

## Rollback Plan

If issues arise, rollback is straightforward:

```bash
# Restore original dependencies
git checkout package.json package-lock.json
npm install

# Restore original source files
git checkout src/agents/ src/lib/env.ts src/lib/types.ts
```

Keep `.env.local` backup with original `OPENAI_API_KEY` configuration.

---

## Post-Migration Verification

### Checklist

- [ ] `npm run dev` starts without errors
- [ ] `npm run build` completes successfully
- [ ] `npm run lint` passes
- [ ] `npx tsc --noEmit` passes (no type errors)
- [ ] Environment validation passes with Azure credentials
- [ ] Single banner group processes successfully
- [ ] Full pipeline produces valid crosstab output
- [ ] R scripts generate correctly
- [ ] Output quality matches previous system

### Success Criteria

1. **Functional**: System produces same quality output as OpenAI Agents SDK version
2. **Compliance**: All AI calls go through Azure OpenAI (verify in Azure portal)
3. **Performance**: Processing time within 20% of previous implementation
4. **Reliability**: No increase in error rate

---

## Migration Summary

| File | Action | Complexity | Step |
|------|--------|------------|------|
| `package.json` | Remove @openai/agents, add ai + @ai-sdk/azure | Low | 1 |
| `src/lib/types.ts` | Add Azure config fields to EnvironmentConfig | Low | 2 |
| `src/lib/env.ts` | Complete rewrite for Azure provider | Medium | 2 |
| `src/lib/tracing.ts` | Update env var name (TRACING_ENABLED) | Low | 7 |
| `src/agents/tools/scratchpad.ts` | Change import, rename `parameters` to `inputSchema` | Low | 3 |
| `src/agents/CrosstabAgent.ts` | Replace Agent+run with generateText, remove withTrace | High | 4 |
| `src/agents/BannerAgent.ts` | Replace Agent+run with generateText, update image format | High | 5 |
| `src/agents/RScriptAgent.ts` | Remove withTrace wrapper, add structured logging | Medium | 6 |
| `src/agents/index.ts` | Add BannerAgent and RScriptAgent exports | Low | 8 |
| `.env.local` | Replace OPENAI_API_KEY with Azure vars | Low | 2 |
| `.env.example` | Create/update with Azure vars for team reference | Low | 2 |

**Total files modified**: 11
**Risk level**: Medium (well-defined migration path, feature branch allows thorough testing)

### Verification After Each Step

```bash
# After EVERY step, run these checks:
npm run lint                   # Must pass
npx tsc --noEmit              # Must pass - no type errors

# After Step 1 (dependencies):
grep -r "@openai/agents" src/  # Should still find imports (not yet migrated)

# After ALL steps complete:
grep -r "@openai/agents" src/  # Should return ZERO results
grep -r "withTrace" src/       # Should return ZERO results
grep -r "getGlobalTraceProvider" src/  # Should return ZERO results
npm run build                  # Must succeed
```

---

## References

- [Vercel AI SDK Documentation](https://ai-sdk.dev/docs/introduction)
- [Azure OpenAI Provider](https://ai-sdk.dev/providers/ai-sdk-providers/azure)
- [Tools and Tool Calling](https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling) - **Primary reference for tool `inputSchema` pattern**
- [Generating Structured Data](https://ai-sdk.dev/docs/ai-sdk-core/generating-structured-data)
- [Tool Definition Reference](https://ai-sdk.dev/docs/reference/ai-sdk-core/tool)
- [Building Agents Guide](https://vercel.com/kb/guide/how-to-build-ai-agents-with-vercel-and-the-ai-sdk)
- [OpenAI Agents SDK Zod Issue #187](https://github.com/openai/openai-agents-js/issues/187)

---

## Changelog

| Date | Change |
|------|--------|
| 2025-12-31 | Initial plan created |
| 2025-12-31 | Updated with comprehensive gap analysis: BannerAgent full migration details, tracing replacement strategy, discovery-first pattern, verification steps, .env.example |
| 2025-12-31 | Updated model configuration to use actual Azure deployments: o4-mini (reasoning) and gpt-5-nano (base/vision). Pre-implementation checklist completed. |
| 2025-12-31 | **Breaking change**: Switched from environment-based to task-based model selection. `getModel()` replaced with `getReasoningModel()` (CrosstabAgent) and `getBaseModel()` (BannerAgent). Models are now chosen based on task requirements, not NODE_ENV. Updated Steps 2, 4, 5, and Testing Plan. |
| 2025-12-31 | Added `AZURE_API_VERSION` configuration (default: `2025-01-01-preview`) and `useDeploymentBasedUrls: true` for Azure AI Foundry compatibility. This ensures the SDK constructs URLs matching the standard Azure OpenAI deployment format. |
| 2026-01-01 | **Correction**: Fixed tool definition pattern in Step 3. AI SDK v6 requires `inputSchema` (not `parameters`). Updated Key Changes table, Step 3 code example, and Migration Summary. Verified against [AI SDK Tools Documentation](https://ai-sdk.dev/docs/ai-sdk-core/tools-and-tool-calling). |

---

*Created: December 31, 2025*
*Last Updated: January 1, 2026*
*Status: Ready for Implementation*
