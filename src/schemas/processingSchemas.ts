/**
 * Processing Schemas - Types for Data Map Processing
 * 
 * Defines types used by DataMapProcessor and DataMapValidator
 * Ensures compatibility with existing schemas while adding processing-specific types
 */

import { z } from 'zod';

// ===== RAW PROCESSING TYPES =====

export const RawDataMapVariableSchema = z.object({
  level: z.enum(['parent', 'sub']),
  column: z.string(),
  description: z.string(),
  valueType: z.string(),
  answerOptions: z.string(),
  parentQuestion: z.string(),
  context: z.string().optional()
});

export const ProcessedDataMapVariableSchema = RawDataMapVariableSchema.extend({
  context: z.string().optional(),
  confidence: z.number().min(0).max(1).optional()
});

// ===== VERBOSE OUTPUT SCHEMA =====

export const VerboseDataMapSchema = z.object({
  level: z.enum(['parent', 'sub']),
  column: z.string(),
  description: z.string(),
  valueType: z.string(),
  answerOptions: z.string(),
  parentQuestion: z.string(),
  context: z.string().optional(),
  confidence: z.number().min(0).max(1).optional()
});

// ===== AGENT OUTPUT SCHEMA =====

export const AgentDataMapSchema = z.object({
  Column: z.string(),
  Description: z.string(),
  Answer_Options: z.string(),
  ParentQuestion: z.string().optional(),
  Context: z.string().optional()
});

// ===== PROCESSING RESULT SCHEMA =====

export const ProcessingResultSchema = z.object({
  success: z.boolean(),
  verbose: z.array(VerboseDataMapSchema),
  agent: z.array(AgentDataMapSchema),
  validationPassed: z.boolean(),
  confidence: z.number().min(0).max(1),
  errors: z.array(z.string()),
  warnings: z.array(z.string())
});

// ===== VALIDATION SCHEMAS =====

export const ConfidenceFactorsSchema = z.object({
  structuralIntegrity: z.number().min(0).max(40),
  contentCompleteness: z.number().min(0).max(30),
  relationshipClarity: z.number().min(0).max(30)
});

export const SPSSValidationResultSchema = z.object({
  passed: z.boolean(),
  confidence: z.number().min(0).max(1),
  columnMatches: z.object({
    inBoth: z.number(),
    onlyInDataMap: z.number(),
    onlyInSPSS: z.number()
  }),
  missingColumns: z.array(z.string()).optional(),
  extraColumns: z.array(z.string()).optional()
});

export const SPSSInfoSchema = z.object({
  variables: z.array(z.string()),
  metadata: z.object({
    totalVariables: z.number(),
    fileName: z.string()
  })
});

// ===== TYPE EXPORTS =====

export type RawDataMapVariableType = z.infer<typeof RawDataMapVariableSchema>;
export type ProcessedDataMapVariableType = z.infer<typeof ProcessedDataMapVariableSchema>;
export type VerboseDataMapType = z.infer<typeof VerboseDataMapSchema>;
export type AgentDataMapType = z.infer<typeof AgentDataMapSchema>;
export type ProcessingResultType = z.infer<typeof ProcessingResultSchema>;
export type ConfidenceFactorsType = z.infer<typeof ConfidenceFactorsSchema>;
export type SPSSValidationResultType = z.infer<typeof SPSSValidationResultSchema>;
export type SPSSInfoType = z.infer<typeof SPSSInfoSchema>;

// ===== VALIDATION HELPERS =====

export const validateProcessingResult = (data: unknown): ProcessingResultType => {
  return ProcessingResultSchema.parse(data);
};

export const validateAgentDataMap = (data: unknown): AgentDataMapType[] => {
  return z.array(AgentDataMapSchema).parse(data);
};

export const validateVerboseDataMap = (data: unknown): VerboseDataMapType[] => {
  return z.array(VerboseDataMapSchema).parse(data);
};

// ===== CONSTANTS =====

export const PROCESSING_CONSTANTS = {
  CONFIDENCE_THRESHOLD: 0.75,
  SPSS_MATCH_THRESHOLD: 0.8,
  MAX_PARENT_QUESTION_LENGTH: 3,
  CONFIDENCE_WEIGHTS: {
    structuralIntegrity: 40,
    contentCompleteness: 30,
    relationshipClarity: 30
  }
} as const;

export const CONFIDENCE_LEVELS = {
  EXCELLENT: { min: 0.9, label: 'Excellent Parse' },
  GOOD: { min: 0.75, label: 'Good Confidence' },
  MEDIUM: { min: 0.6, label: 'Medium Confidence' },
  LOW: { min: 0.4, label: 'Low Confidence' },
  FAILED: { min: 0, label: 'Failed Parse' }
} as const;