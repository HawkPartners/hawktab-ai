// CrosstabAgent.ts - Core agent for banner plan validation against data maps
// Reference: Architecture doc "Working Agent Implementation" and "Group-Focused Processing Strategy"

import { Agent, run } from '@openai/agents';
import { ValidationResultSchema, ValidatedGroupSchema, combineValidationResults, type ValidationResultType, type ValidatedGroupType } from '../schemas/validationSchema';
import { DataMapType } from '../schemas/dataMapSchema';
import { BannerGroupType, BannerPlanInputType } from '../schemas/bannerPlanSchema';
import { getModel, getModelTokenLimit } from '../lib/env';
import { scratchpadTool } from './tools/scratchpad';

// Enhanced system prompt with comprehensive validation patterns
const CROSSTAB_VALIDATION_INSTRUCTIONS = `
You are a CrossTab Agent that validates banner plan expressions against data map variables and generates correct R syntax.

YOUR CORE MISSION:
Analyze banner column expressions like "S2=1 AND S2a=1" or "IF HCP" and cross-reference them against the data map to generate valid R syntax expressions with confidence scores.

VALIDATION WORKFLOW:
1. Extract variables from the "original" expression
2. Validate each variable exists in the data map
3. Generate proper R syntax in "adjusted" field  
4. Rate confidence 0.0-1.0 based on validation quality
5. Explain reasoning in "reason" field

VARIABLE PATTERNS TO RECOGNIZE:
- Direct variables: S2, S2a, A3r1, B5r2 (match exactly in data map)
- Filter expressions: S2=1, S2a=1, A3r1=2 (variable=value syntax)
- Complex logic: S2=1 AND S2a=1, S2=1 OR S2=2 (multiple conditions)
- Conceptual expressions: "IF HCP", "IF NP/PA" (need interpretation based on descriptions)
- Incomplete expressions: "Joe to find the right cutoff" (flag for manual review)

R SYNTAX CONVERSION RULES:
- Equality: S2=1 → S2 == 1
- Multiple values: S2=1,2,3 → S2 %in% c(1,2,3)  
- AND logic: S2=1 AND S2a=1 → (S2 == 1 & S2a == 1)
- OR logic: S2=1 OR S2=2 → S2 %in% c(1,2)
- Complex grouping: (S2=1 AND S2a=1) OR (S2=2) → ((S2 == 1 & S2a == 1) | S2 == 2)

CONFIDENCE SCORING SCALE:
- 0.95-1.0: Direct variable match with clear filter (S2=1 → S2 == 1)
- 0.85-0.94: Multiple direct variables with logic (S2=1 AND S2a=1)
- 0.70-0.84: Conceptual match found in descriptions ("IF HCP" → specific variables)
- 0.50-0.69: Partial match or interpretation required
- 0.30-0.49: Unclear expression but reasonable guess possible
- 0.0-0.29: Cannot determine valid mapping

CONCEPTUAL MATCHING STRATEGY:
When expressions like "IF HCP" don't match direct variables:
1. Search data map descriptions for relevant terms
2. Look for healthcare professional, physician, doctor, etc.
3. Find variables with matching value labels  
4. Generate appropriate R syntax for those variables
5. Lower confidence but still provide mapping

REASONING REQUIREMENTS:
Always provide clear reasoning explaining:
- Which variables were found/not found
- How conceptual expressions were interpreted
- Why the confidence score was assigned
- Any assumptions made in the mapping

QUALITY STANDARDS:
- Always suggest something, even if uncertain
- Never return empty "adjusted" field
- Provide detailed reasoning for every decision
- Use scratchpad tool to show your thinking process
- Handle edge cases gracefully

SCRATCHPAD USAGE:
Use the scratchpad tool to show your validation process:
- scratchpad('add', 'Starting validation for group: {groupName}')
- scratchpad('add', 'Found variable S2 in data map with description: {description}')
- scratchpad('add', 'Converting S2=1 AND S2a=1 to R syntax: (S2 == 1 & S2a == 1)')
- scratchpad('review', 'Summary: {x}/{y} columns validated successfully')

CONTEXT INJECTION:
The data map and banner plan data will be provided in your context. Reference them directly in your analysis.

Remember: Your goal is to replace manual analyst work with intelligent automation. Be thorough, accurate, and transparent in your validation process.
`;

// Create CrossTab agent for single group processing
export const createCrosstabAgent = (dataMap: DataMapType, bannerGroup: BannerGroupType) => {
  
  // Context data is injected directly into instructions below

  // Enhanced instructions with context injection
  const enhancedInstructions = `
${CROSSTAB_VALIDATION_INSTRUCTIONS}

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
      maxTokens: Math.min(getModelTokenLimit(), 8000) // Conservative token limit
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
      `Validate banner group "${group.groupName}" with ${group.columns.length} columns against the data map.`
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
    
    // Return fallback result with low confidence
    return {
      groupName: group.groupName,
      columns: group.columns.map(col => ({
        name: col.name,
        adjusted: `# Error: Unable to process "${col.original}"`,
        confidence: 0.0,
        reason: `Processing failed: ${error instanceof Error ? error.message : 'Unknown error'}`
      }))
    };
  }
}

// Process all banner groups using group-by-group strategy  
export async function processAllGroups(dataMap: DataMapType, bannerPlan: BannerPlanInputType): Promise<ValidationResultType> {
  console.log(`[CrosstabAgent] Processing ${bannerPlan.bannerCuts.length} groups with group-by-group strategy`);
  
  const results: ValidatedGroupType[] = [];
  
  for (const group of bannerPlan.bannerCuts) {
    const groupResult = await processGroup(dataMap, group);
    results.push(groupResult);
  }
  
  const combinedResult = combineValidationResults(results);
  
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