// CrosstabAgent.ts - Core agent for banner plan validation against data maps
// Reference: Architecture doc "Working Agent Implementation" and "Group-Focused Processing Strategy"

import { Agent, run } from '@openai/agents';
import { ValidationResultSchema, ValidatedGroupSchema, combineValidationResults, type ValidationResultType, type ValidatedGroupType } from '../schemas/validationSchema';
import { DataMapType } from '../schemas/dataMapSchema';
import { BannerGroupType, BannerPlanInputType } from '../schemas/bannerPlanSchema';
import { getModel, getModelTokenLimit, getPromptVersions } from '../lib/env';
import { scratchpadTool } from './tools/scratchpad';
import { getCrosstabPrompt } from '../prompts';
import fs from 'fs/promises';
import path from 'path';

// Get modular validation instructions based on environment variable
const getCrosstabValidationInstructions = (): string => {
  const promptVersions = getPromptVersions();
  return getCrosstabPrompt(promptVersions.crosstabPromptVersion);
};

// Create CrossTab agent for single group processing
export const createCrosstabAgent = (dataMap: DataMapType, bannerGroup: BannerGroupType) => {
  
  // Context data is injected directly into instructions below

  // Enhanced instructions with context injection
  const enhancedInstructions = `
${getCrosstabValidationInstructions()}

CURRENT CONTEXT DATA:

DATA MAP (${dataMap.length} variables):
${JSON.stringify(dataMap, null, 2)}

BANNER GROUP TO VALIDATE:
Group: "${bannerGroup.groupName}"
${JSON.stringify(bannerGroup, null, 2)}

PROCESSING REQUIREMENTS:
- Validate all ${bannerGroup.columns.length} columns in this group
- Generate R syntax for each column's "original" expression
- Provide confidence scores and detailed reasoning
- Use scratchpad to show your validation process

Begin validation now.
`;

  const agent = new Agent({
    name: 'CrosstabAgent',
    instructions: enhancedInstructions,
    model: getModel(),
    outputType: ValidatedGroupSchema, // Use outputType, not outputSchema
    tools: [scratchpadTool],
    modelSettings: {
      // temperature: 0.1, // Low temperature for consistent validation—reasoning models don't have temperature
      maxTokens: Math.min(getModelTokenLimit(), 10000) // Increased token limit to reduce truncation-related retries
    }
  });

  return agent;
};

// Process single banner group
export async function processGroup(dataMap: DataMapType, group: BannerGroupType): Promise<ValidatedGroupType> {
  console.log(`[CrosstabAgent] Processing group: ${group.groupName} (${group.columns.length} columns)`);
  
  try {
    const agent = createCrosstabAgent(dataMap, group);
    
    const result = await run(
      agent, 
      `Validate banner group "${group.groupName}" with ${group.columns.length} columns against the data map.`,
      {
        maxTurns: 25, // Increased from default 10 to handle complex groups with many scratchpad interactions
      }
    );
    
    // Handle potential type assertion issues from SDK
    const validatedGroup = result.finalOutput as unknown as ValidatedGroupType;
    
    if (!validatedGroup || !validatedGroup.columns) {
      throw new Error(`Invalid agent response for group ${group.groupName}`);
    }
    
    console.log(`[CrosstabAgent] Group ${group.groupName} processed successfully - ${validatedGroup.columns.length} columns validated`);
    
    return validatedGroup;
    
  } catch (error) {
    console.error(`[CrosstabAgent] Error processing group ${group.groupName}:`, error);
    
    // Check if it's a max turns error specifically
    const isMaxTurnsError = error instanceof Error && error.message.includes('Max turns');
    const errorType = isMaxTurnsError ? 'Max turns exceeded - consider simplifying expressions' : 'Processing error';
    
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
export async function processAllGroups(dataMap: DataMapType, bannerPlan: BannerPlanInputType, outputFolder?: string): Promise<ValidationResultType> {
  console.log(`[CrosstabAgent] Processing ${bannerPlan.bannerCuts.length} groups with group-by-group strategy`);
  
  const results: ValidatedGroupType[] = [];
  
  for (const group of bannerPlan.bannerCuts) {
    const groupResult = await processGroup(dataMap, group);
    results.push(groupResult);
  }
  
  const combinedResult = combineValidationResults(results);
  
  // Save development outputs if in development mode
  if (process.env.NODE_ENV === 'development' && outputFolder) {
    await saveDevelopmentOutputs(combinedResult, outputFolder);
  }
  
  console.log(`[CrosstabAgent] All groups processed - ${results.length} groups, ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)} total columns`);
  
  return combinedResult;
}

// Parallel processing option (for future optimization)
export async function processAllGroupsParallel(dataMap: DataMapType, bannerPlan: BannerPlanInputType): Promise<ValidationResultType> {
  console.log(`[CrosstabAgent] Processing ${bannerPlan.bannerCuts.length} groups with parallel strategy`);
  
  try {
    const groupPromises = bannerPlan.bannerCuts.map(group => processGroup(dataMap, group));
    const results = await Promise.all(groupPromises);
    
    const combinedResult = combineValidationResults(results);
    
    console.log(`[CrosstabAgent] All groups processed in parallel - ${results.length} groups, ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)} total columns`);
    
    return combinedResult;
    
  } catch (error) {
    console.error('[CrosstabAgent] Parallel processing failed, falling back to sequential:', error);
    return await processAllGroups(dataMap, bannerPlan);
  }
}

// Validation helpers
export const validateAgentResult = (result: unknown): ValidationResultType => {
  return ValidationResultSchema.parse(result);
};

export const isValidAgentResult = (result: unknown): result is ValidationResultType => {
  return ValidationResultSchema.safeParse(result).success;
};

// Save development outputs for CrossTab agent results
async function saveDevelopmentOutputs(result: ValidationResultType, outputFolder: string): Promise<void> {
  try {
    const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolder);
    await fs.mkdir(outputDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `crosstab-output-${timestamp}.json`;
    const filePath = path.join(outputDir, filename);

    await fs.writeFile(filePath, JSON.stringify(result, null, 2), 'utf-8');
    console.log(`[CrosstabAgent] Development output saved: ${filename}`);
  } catch (error) {
    console.error('[CrosstabAgent] Failed to save development outputs:', error);
  }
}