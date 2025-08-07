// CrosstabAgent.ts - Core agent for banner plan validation against data maps
// Reference: Architecture doc "Working Agent Implementation" and "Group-Focused Processing Strategy"

import { Agent, run, withTrace, getGlobalTraceProvider } from '@openai/agents';
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

// Process all banner groups using group-by-group strategy with unified tracing
export async function processAllGroups(
  dataMap: DataMapType, 
  bannerPlan: BannerPlanInputType, 
  outputFolder?: string
): Promise<{ result: ValidationResultType; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };
  
  logEntry(`[CrosstabAgent] Starting group-by-group processing: ${bannerPlan.bannerCuts.length} groups`);
  
  // Wrap entire workflow in a single trace (trace ID not accessible to user code)
  const traceName = `CrossTab Validation - ${bannerPlan.bannerCuts.length} groups`;
  
  const result = await withTrace(traceName, async () => {
    logEntry(`[CrosstabAgent] 🔗 Created unified trace: "${traceName}"`);
    
    const results: ValidatedGroupType[] = [];
    
    // Process each group individually (this is the group-by-group approach)
    for (let i = 0; i < bannerPlan.bannerCuts.length; i++) {
      const group = bannerPlan.bannerCuts[i];
      const groupStartTime = Date.now();
      
      logEntry(`[CrosstabAgent] 📋 Processing group ${i + 1}/${bannerPlan.bannerCuts.length}: "${group.groupName}" (${group.columns.length} columns)`);
      
      // This calls createCrosstabAgent with ONLY this single group
      const groupResult = await processGroup(dataMap, group);
      results.push(groupResult);
      
      const groupDuration = Date.now() - groupStartTime;
      const avgConfidence = groupResult.columns.reduce((sum, col) => sum + col.confidence, 0) / groupResult.columns.length;
      
      logEntry(`[CrosstabAgent] ✅ Group "${group.groupName}" completed in ${groupDuration}ms - Avg confidence: ${avgConfidence.toFixed(2)}`);
    }
    
    const combinedResult = combineValidationResults(results);
    
    // Save development outputs with processing log
    if (process.env.NODE_ENV === 'development' && outputFolder) {
      await saveDevelopmentOutputsWithTrace(combinedResult, outputFolder, undefined, processingLog);
    }
    
    logEntry(`[CrosstabAgent] 🎉 All ${results.length} groups processed successfully - Total columns: ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)}`);
    
    return combinedResult;
  });
  
  // Force flush to ensure traces are sent to OpenAI dashboard
  try {
    await getGlobalTraceProvider().forceFlush();
    logEntry('[CrosstabAgent] 📤 Traces flushed to OpenAI dashboard - Check https://platform.openai.com/traces');
  } catch (error) {
    logEntry(`[CrosstabAgent] ❌ Failed to flush traces: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
  
  return { result, processingLog };
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
  
  // Wrap parallel processing in a single trace
  const traceName = `CrossTab Parallel Validation - ${bannerPlan.bannerCuts.length} groups`;
  
  const result = await withTrace(traceName, async () => {
    logEntry(`[CrosstabAgent] 🔗 Created parallel trace: "${traceName}"`);
    
    try {
      logEntry(`[CrosstabAgent] ⚡ Starting parallel group processing`);
      const groupPromises = bannerPlan.bannerCuts.map((group, index) => {
        logEntry(`[CrosstabAgent] 📋 Queuing group ${index + 1}: "${group.groupName}"`);
        return processGroup(dataMap, group);
      });
      
      const results = await Promise.all(groupPromises);
      const combinedResult = combineValidationResults(results);
      
      logEntry(`[CrosstabAgent] ✅ Parallel processing completed - ${results.length} groups, ${combinedResult.bannerCuts.reduce((total, group) => total + group.columns.length, 0)} total columns`);
      
      return combinedResult;
      
    } catch (error) {
      logEntry(`[CrosstabAgent] ❌ Parallel processing failed, falling back to sequential: ${error instanceof Error ? error.message : 'Unknown error'}`);
      
      // Fall back to sequential processing but within the same trace
      const results: ValidatedGroupType[] = [];
      
      for (const group of bannerPlan.bannerCuts) {
        logEntry(`[CrosstabAgent] 📋 Sequential fallback processing: "${group.groupName}"`);
        const groupResult = await processGroup(dataMap, group);
        results.push(groupResult);
      }
      
      logEntry(`[CrosstabAgent] ✅ Sequential fallback completed`);
      return combineValidationResults(results);
    }
  });
  
  // Force flush traces
  try {
    await getGlobalTraceProvider().forceFlush();
    logEntry('[CrosstabAgent] 📤 Parallel traces flushed to OpenAI dashboard - Check https://platform.openai.com/traces');
  } catch (error) {
    logEntry(`[CrosstabAgent] ❌ Failed to flush parallel traces: ${error instanceof Error ? error.message : 'Unknown error'}`);
  }
  
  return { result, processingLog };
}

// Validation helpers
export const validateAgentResult = (result: unknown): ValidationResultType => {
  return ValidationResultSchema.parse(result);
};

export const isValidAgentResult = (result: unknown): result is ValidationResultType => {
  return ValidationResultSchema.safeParse(result).success;
};

// Save development outputs with enhanced processing information
async function saveDevelopmentOutputsWithTrace(
  result: ValidationResultType, 
  outputFolder: string, 
  _traceId?: string, // Keep parameter for backward compatibility but unused
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
        totalGroups: result.bannerCuts.length,
        totalColumns: result.bannerCuts.reduce((total, group) => total + group.columns.length, 0),
        averageConfidence: result.bannerCuts.length > 0 
          ? result.bannerCuts
              .flatMap(group => group.columns)
              .reduce((sum, col) => sum + col.confidence, 0) 
            / result.bannerCuts.flatMap(group => group.columns).length
          : 0,
        tracingEnabled: process.env.OPENAI_AGENTS_DISABLE_TRACING !== 'true',
        tracesDashboard: 'https://platform.openai.com/traces',
        processingLog: processingLog || []
      }
    };

    await fs.writeFile(filePath, JSON.stringify(enhancedOutput, null, 2), 'utf-8');
    console.log(`[CrosstabAgent] 💾 Enhanced development output saved: ${filename}`);
    console.log(`[CrosstabAgent] 📊 Processing info included - check OpenAI traces dashboard for detailed trace`);
  } catch (error) {
    console.error('[CrosstabAgent] ❌ Failed to save enhanced development outputs:', error);
  }
}

// Legacy function for backward compatibility  
async function _saveDevelopmentOutputs(result: ValidationResultType, outputFolder: string): Promise<void> {
  await saveDevelopmentOutputsWithTrace(result, outputFolder);
}