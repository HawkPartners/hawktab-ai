# Phase 1: Azure OpenAI Migration via Vercel AI SDK

## Implementation Plan

**Goal**: Migrate from OpenAI Agents SDK to Vercel AI SDK with Azure OpenAI provider for Hawk Partners compliance.

**Estimated Effort**: 2-3 days

**Branch**: `feature-azure-openai-migration` (current feature branch)

---

## Executive Summary

The current system uses `@openai/agents` which **does not support Azure OpenAI**. Hawk Partners requires Azure OpenAI for compliance (firm data cannot go to OpenAI directly). This migration switches to Vercel AI SDK (`ai` + `@ai-sdk/azure`) which has first-class Azure support.

### Key Changes

| Component | Current | Target |
|-----------|---------|--------|
| AI Framework | `@openai/agents ^0.0.15` | `ai ^6.0.5` + `@ai-sdk/azure ^3.0.2` |
| Zod Version | `^3.25.67` (locked) | `^3.25.76` or `^4.x` (unlocked) |
| API Key | `OPENAI_API_KEY` | `AZURE_API_KEY` + `AZURE_RESOURCE_NAME` |
| Model Selection | `getModel()` → `'gpt-4o'` | `azure('gpt-4o')` deployment reference |
| Tool Pattern | `parameters` property | `inputSchema` property |
| Structured Output | `outputType` property | `output: Output.object({ schema })` |
| Tracing | OpenAI Agents SDK built-in | Removed (Sentry planned for Phase 2) |

---

## Pre-Implementation Checklist

- [ ] Confirm Azure OpenAI resource exists at Hawk Partners
- [ ] Get Azure resource name (e.g., `hawkpartners-openai`)
- [ ] Get Azure API key
- [ ] Confirm deployment name (e.g., `gpt-4o`, `gpt-4-turbo`)
- [ ] Verify deployment supports vision (for BannerAgent)

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
  azureDeploymentName: string;

  // Keep existing fields for backward compatibility during transition
  reasoningModel: string;
  baseModel: string;
  openaiApiKey?: string;  // Make optional (deprecated)

  nodeEnv: 'development' | 'production';
  tracingDisabled: boolean;  // Keep but will be ignored
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
 * Required: AZURE_API_KEY, AZURE_RESOURCE_NAME, AZURE_DEPLOYMENT_NAME
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
    });
  }
  return azureProvider;
};

export const getEnvironmentConfig = (): EnvironmentConfig => {
  // Validate required Azure environment variables
  const azureApiKey = process.env.AZURE_API_KEY;
  const azureResourceName = process.env.AZURE_RESOURCE_NAME;
  const azureDeploymentName = process.env.AZURE_DEPLOYMENT_NAME || 'gpt-4o';

  if (!azureApiKey) {
    throw new Error('AZURE_API_KEY environment variable is required');
  }
  if (!azureResourceName) {
    throw new Error('AZURE_RESOURCE_NAME environment variable is required');
  }

  const nodeEnv = (process.env.NODE_ENV as 'development' | 'production') || 'development';

  return {
    azureApiKey,
    azureResourceName,
    azureDeploymentName,

    // Legacy fields (keep for compatibility during transition)
    reasoningModel: process.env.REASONING_MODEL || 'gpt-4o',
    baseModel: process.env.BASE_MODEL || 'gpt-4o',
    openaiApiKey: process.env.OPENAI_API_KEY,  // Optional, deprecated

    nodeEnv,
    tracingDisabled: true,  // No longer used (Sentry in Phase 2)
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
 * Get Azure model for AI SDK usage
 * Returns the configured Azure deployment
 */
export const getModel = () => {
  const config = getEnvironmentConfig();
  return azure(config.azureDeploymentName);
};

/**
 * Get model name string (for logging)
 */
export const getModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.azureDeploymentName}`;
};

export const getModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.baseModelTokens;
};

export const getModelConfig = () => {
  const config = getEnvironmentConfig();
  return {
    model: getModel(),
    modelName: getModelName(),
    tokenLimit: config.processingLimits.baseModelTokens,
    environment: config.nodeEnv,
  };
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

**File**: `.env.local` (update template)

```bash
# Azure OpenAI Configuration (Required)
AZURE_API_KEY=your-azure-api-key
AZURE_RESOURCE_NAME=your-resource-name
AZURE_DEPLOYMENT_NAME=gpt-4o

# Optional: Model settings
BASE_MODEL_TOKENS=128000

# Optional: Prompt versions
CROSSTAB_PROMPT_VERSION=production
BANNER_PROMPT_VERSION=production

# Optional: Processing limits
MAX_DATA_MAP_VARIABLES=1000
MAX_BANNER_COLUMNS=100

# Node environment
NODE_ENV=development
```

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
  parameters: z.object({
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
- No `name` property (inferred from object key when used)
- Uses `parameters` (same as before, AI SDK 5+ renamed to `inputSchema` but both work)
- `execute` function signature remains the same

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
import { getModel, getModelName, getModelTokenLimit, getPromptVersions } from '../lib/env';
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
      model: getModel(),
      system: systemPrompt,
      prompt: `Validate banner group "${group.groupName}" with ${group.columns.length} columns against the data map.`,
      tools: {
        scratchpad: scratchpadTool,
      },
      maxSteps: 25,  // Equivalent to maxTurns
      maxTokens: Math.min(getModelTokenLimit(), 10000),
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
  logEntry(`[CrosstabAgent] Using model: ${getModelName()}`);

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
  logEntry(`[CrosstabAgent] Using model: ${getModelName()}`);

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
        model: getModelName(),
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
6. **Model from function**: `getModel()` now returns Azure model instance, not string

---

### Step 5: Migrate BannerAgent

**File**: `src/agents/BannerAgent.ts`

The BannerAgent migration follows the same pattern as CrosstabAgent. Key differences:

```typescript
import { generateText, Output } from 'ai';
import { getModel, getModelName, getModelTokenLimit } from '../lib/env';

// For image handling with Azure OpenAI
export async function processBanner(images: ProcessedImage[]): Promise<BannerExtractionResult> {
  const systemPrompt = `${getBannerExtractionInstructions()}...`;

  // Build image content for multimodal input
  const imageMessages = images.map(img => ({
    type: 'image' as const,
    image: img.base64Data,  // Base64 encoded image
  }));

  const { output } = await generateText({
    model: getModel(),
    system: systemPrompt,
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: 'Analyze the banner plan images...' },
          ...imageMessages,
        ],
      },
    ],
    tools: {
      scratchpad: scratchpadTool,
    },
    maxSteps: 15,
    maxTokens: Math.min(getModelTokenLimit(), 32000),
    output: Output.object({
      schema: BannerExtractionResultSchema,
    }),
  });

  return output;
}
```

**Image handling note**: Azure OpenAI supports vision through the same deployment. Ensure the Azure deployment supports vision capabilities (GPT-4o, GPT-4 Turbo with Vision).

---

### Step 6: Update RScriptAgent (Minimal Changes)

**File**: `src/agents/RScriptAgent.ts`

The RScriptAgent primarily uses deterministic processing, not AI inference. Only the tracing imports need removal:

```diff
- import { withTrace, getGlobalTraceProvider } from '@openai/agents';

// Remove withTrace wrapper, keep processing logic
export async function generateRScript(sessionId: string, sessionDir: string): Promise<RScriptOutput> {
  console.log(`[RScriptAgent] Starting R script generation for session: ${sessionId}`);

-  const result = await withTrace(`R Script Generation - ${sessionId}`, async () => {
    const validation = await loadValidationOrCutTable(sessionDir);
    const dataMap = await loadAgentDataMap(sessionDir);
    // ... processing logic unchanged
-  });
+  const validation = await loadValidationOrCutTable(sessionDir);
+  const dataMap = await loadAgentDataMap(sessionDir);
+  // ... processing logic unchanged

-  await getGlobalTraceProvider().forceFlush();

  return result;
}
```

---

### Step 7: Update Agent Index Export

**File**: `src/agents/index.ts`

```typescript
// Agent exports
export { processGroup, processAllGroups, processAllGroupsParallel, validateAgentResult, isValidAgentResult } from './CrosstabAgent';
export { processBanner, type BannerExtractionResult } from './BannerAgent';
export { generateRScript, type RScriptOutput } from './RScriptAgent';

// Tool exports
export { scratchpadTool } from './tools/scratchpad';
```

---

### Step 8: Verify API Route Compatibility

**File**: `src/app/api/process-crosstab/route.ts`

The API route should work without changes since we're keeping the same function signatures. Verify:

1. `validateEnvironment()` is called and returns `{ valid: true }`
2. `processAllGroups()` is called with same parameters
3. Response structure unchanged

---

## Testing Plan

### Unit Tests

1. **Environment Configuration**
   ```typescript
   // Test Azure config loading
   process.env.AZURE_API_KEY = 'test-key';
   process.env.AZURE_RESOURCE_NAME = 'test-resource';
   process.env.AZURE_DEPLOYMENT_NAME = 'gpt-4o';

   const config = getEnvironmentConfig();
   expect(config.azureApiKey).toBe('test-key');
   expect(getModelName()).toBe('azure/gpt-4o');
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

| File | Action | Complexity |
|------|--------|------------|
| `package.json` | Update dependencies | Low |
| `src/lib/types.ts` | Add Azure config fields | Low |
| `src/lib/env.ts` | Complete rewrite | Medium |
| `src/agents/tools/scratchpad.ts` | Minor pattern change | Low |
| `src/agents/CrosstabAgent.ts` | Major rewrite | High |
| `src/agents/BannerAgent.ts` | Major rewrite | High |
| `src/agents/RScriptAgent.ts` | Remove tracing only | Low |
| `src/agents/index.ts` | Update exports | Low |
| `.env.local` | Add Azure credentials | Low |

**Total files modified**: 9
**Estimated time**: 2-3 days
**Risk level**: Medium (well-defined migration path)

---

## References

- [Vercel AI SDK Documentation](https://ai-sdk.dev/docs/introduction)
- [Azure OpenAI Provider](https://ai-sdk.dev/providers/ai-sdk-providers/azure)
- [Generating Structured Data](https://ai-sdk.dev/docs/ai-sdk-core/generating-structured-data)
- [Tool Definition Reference](https://ai-sdk.dev/docs/reference/ai-sdk-core/tool)
- [Building Agents Guide](https://vercel.com/kb/guide/how-to-build-ai-agents-with-vercel-and-the-ai-sdk)
- [OpenAI Agents SDK Zod Issue #187](https://github.com/openai/openai-agents-js/issues/187)

---

*Created: December 31, 2025*
*Status: Ready for Review*
