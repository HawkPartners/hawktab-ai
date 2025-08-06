// Context builder implementation for dual output strategy
// Reference: Architecture doc "Context Builder Implementation"

import { DataMapType } from '../schemas/dataMapSchema';
import { BannerPlanInputType, BannerGroupType } from '../schemas/bannerPlanSchema';

// Verbose data map structure (from raw CSV processing)
export interface VerboseDataMap {
  Level: string;
  ParentQ: string;
  Column: string;
  Description: string;
  Value_Type: string;
  Answer_Options: string;
  Context: string;
}

// Simplified agent data map (only essential fields)
export interface AgentDataMap {
  Column: string;
  Description: string;
  Answer_Options: string;
}

// Verbose banner group structure (from banner-part1-result JSON)
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
    uncertainties: unknown[];
  }>;
}

// Simplified agent banner group (only essential fields)
export interface AgentBannerGroup {
  groupName: string;
  columns: Array<{
    name: string;
    original: string;
  }>;
}

// Full verbose banner structure
export interface VerboseBannerPlan {
  success: boolean;
  data: {
    success: boolean;
    extractionType: string;
    timestamp: string;
    extractedStructure: {
      bannerCuts: VerboseBannerGroup[];
      notes: unknown[];
      processingMetadata: unknown;
    };
    errors: unknown;
    warnings: unknown;
  };
  timestamp: string;
}

// Dual output generation result
export interface DualOutputResult {
  verboseBanner: VerboseBannerPlan;
  verboseDataMap: VerboseDataMap[];
  agentBanner: AgentBannerGroup[];
  agentDataMap: AgentDataMap[];
}

// Generate both versions during Phase 1 parsing
export const generateDualOutputs = (rawBanner: unknown, rawDataMap: VerboseDataMap[]): DualOutputResult => {
  // Type assertion needed for parsing unknown banner data
  const bannerData = rawBanner as VerboseBannerPlan;
  const verboseDataMap = rawDataMap;
  
  // Simplified versions for agent processing
  const agentBanner: AgentBannerGroup[] = bannerData.data?.extractedStructure?.bannerCuts?.map((group) => ({
    groupName: group.groupName,
    columns: group.columns?.map((col) => ({
      name: col.name,
      original: col.original
    })) || []
  })) || [];
  
  const agentDataMap: AgentDataMap[] = rawDataMap.map(item => ({
    Column: item.Column,
    Description: item.Description,
    Answer_Options: item.Answer_Options
  }));
  
  return {
    verboseBanner: bannerData,
    verboseDataMap,
    agentBanner,
    agentDataMap
  };
};

// Convert agent data map to schema type
export const convertToDataMapSchema = (agentDataMap: AgentDataMap[]): DataMapType => {
  return agentDataMap.map(item => ({
    Column: item.Column,
    Description: item.Description,
    Answer_Options: item.Answer_Options
  }));
};

// Convert agent banner to schema type
export const convertToBannerPlanSchema = (agentBanner: AgentBannerGroup[]): BannerPlanInputType => {
  return {
    bannerCuts: agentBanner.map(group => ({
      groupName: group.groupName,
      columns: group.columns.map(col => ({
        name: col.name,
        original: col.original
      }))
    }))
  };
};

// Helper functions for context preparation
export const prepareAgentContext = (dualOutput: DualOutputResult) => {
  const dataMapSchema = convertToDataMapSchema(dualOutput.agentDataMap);
  const bannerPlanSchema = convertToBannerPlanSchema(dualOutput.agentBanner);
  
  return {
    dataMap: dataMapSchema,
    bannerPlan: bannerPlanSchema,
    metadata: {
      dataMapVariables: dualOutput.agentDataMap.length,
      bannerGroups: dualOutput.agentBanner.length,
      totalColumns: dualOutput.agentBanner.reduce((total, group) => total + group.columns.length, 0)
    }
  };
};

// Create focused context for single group processing
export const createGroupContext = (dataMap: DataMapType, group: BannerGroupType) => {
  return {
    dataMap,
    bannerPlan: {
      bannerCuts: [group]
    },
    metadata: {
      groupName: group.groupName,
      columnsToProcess: group.columns.length,
      dataMapVariables: dataMap.length
    }
  };
};

// Validate context against token limits
export const validateContextSize = (context: unknown, tokenLimit: number): { valid: boolean; estimatedTokens: number } => {
  // Rough estimation: 1 token per 4 characters
  const contextString = JSON.stringify(context);
  const estimatedTokens = Math.ceil(contextString.length / 4);
  
  return {
    valid: estimatedTokens <= tokenLimit * 0.8, // Use 80% of limit for safety
    estimatedTokens
  };
};