// Enhanced Context Builder - Uses DataMapProcessor for sophisticated processing
// Reference: Architecture doc "Context Builder Implementation"

import { DataMapType } from '../schemas/dataMapSchema';
import { BannerPlanInputType, BannerGroupType } from '../schemas/bannerPlanSchema';
import { DataMapProcessor } from './processors/DataMapProcessor';
import { VerboseDataMapType, AgentDataMapType } from '../schemas/processingSchemas';

// Use types from processing schemas for consistency
export type VerboseDataMap = VerboseDataMapType;
export type AgentDataMap = AgentDataMapType;

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

// Enhanced dual output generation result
export interface DualOutputResult {
  verboseBanner: VerboseBannerPlan;
  verboseDataMap: VerboseDataMap[];
  agentBanner: AgentBannerGroup[];
  agentDataMap: AgentDataMap[];
  processing: {
    success: boolean;
    validationPassed: boolean;
    confidence: number;
    errors: string[];
    warnings: string[];
  };
}

// Enhanced dual output generation using sophisticated DataMapProcessor
export const generateDualOutputs = async (rawBanner: unknown, dataMapFilePath: string, spssFilePath?: string): Promise<DualOutputResult> => {
  console.log(`[ContextBuilder] Starting enhanced dual output generation`);
  
  // Process banner data (keep existing logic for now)
  const bannerData = rawBanner as VerboseBannerPlan;
  const agentBanner: AgentBannerGroup[] = bannerData.data?.extractedStructure?.bannerCuts?.map((group) => ({
    groupName: group.groupName,
    columns: group.columns?.map((col) => ({
      name: col.name,
      original: col.original
    })) || []
  })) || [];

  // Use sophisticated DataMapProcessor for data map processing
  console.log(`[ContextBuilder] Processing data map with state machine: ${dataMapFilePath}`);
  if (spssFilePath) {
    console.log(`[ContextBuilder] SPSS validation will use: ${spssFilePath}`);
  }
  
  const dataMapProcessor = new DataMapProcessor();
  const processingResult = await dataMapProcessor.processDataMap(dataMapFilePath, spssFilePath);
  
  console.log(`[ContextBuilder] Data map processing completed - Success: ${processingResult.success}, Confidence: ${processingResult.confidence.toFixed(2)}`);
  
  return {
    verboseBanner: bannerData,
    verboseDataMap: processingResult.verbose,
    agentBanner,
    agentDataMap: processingResult.agent,
    processing: {
      success: processingResult.success,
      validationPassed: processingResult.validationPassed,
      confidence: processingResult.confidence,
      errors: processingResult.errors,
      warnings: processingResult.warnings
    }
  };
};

// Backward compatibility - simple version for basic field mapping
export const generateBasicDualOutputs = (rawBanner: unknown, rawDataMap: VerboseDataMap[]): Omit<DualOutputResult, 'processing'> => {
  console.log(`[ContextBuilder] Using basic dual output generation (backward compatibility)`);
  
  const bannerData = rawBanner as VerboseBannerPlan;
  const verboseDataMap = rawDataMap;
  
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
    Answer_Options: item.Answer_Options,
    ParentQuestion: item.ParentQ !== 'NA' ? item.ParentQ : undefined,
    Context: item.Context || undefined
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