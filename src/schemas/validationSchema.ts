import { z } from 'zod';

// Agent output schema - kept simple to avoid SDK issues
// This is the structured output the CrosstabAgent will return
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

export type ValidationResultType = z.infer<typeof ValidationResultSchema>;

// Individual validated group schema
export const ValidatedGroupSchema = z.object({
  groupName: z.string(),
  columns: z.array(z.object({
    name: z.string(),
    adjusted: z.string().describe('R syntax expression'),
    confidence: z.number().min(0).max(1),
    reason: z.string()
  }))
});

export type ValidatedGroupType = z.infer<typeof ValidatedGroupSchema>;

// Individual validated column schema
export const ValidatedColumnSchema = z.object({
  name: z.string(),
  adjusted: z.string().describe('R syntax expression'),
  confidence: z.number().min(0).max(1),
  reason: z.string()
});

export type ValidatedColumnType = z.infer<typeof ValidatedColumnSchema>;

// Schema validation utilities
export const validateResult = (data: unknown): ValidationResultType => {
  return ValidationResultSchema.parse(data);
};

export const isValidResult = (data: unknown): data is ValidationResultType => {
  return ValidationResultSchema.safeParse(data).success;
};

export const validateGroup = (data: unknown): ValidatedGroupType => {
  return ValidatedGroupSchema.parse(data);
};

// Helper functions for validation result processing
export const getValidatedGroups = (result: ValidationResultType): ValidatedGroupType[] => {
  return result.bannerCuts;
};

export const getGroupByName = (result: ValidationResultType, groupName: string): ValidatedGroupType | undefined => {
  return result.bannerCuts.find(group => group.groupName === groupName);
};

export const calculateAverageConfidence = (result: ValidationResultType): number => {
  const allColumns = result.bannerCuts.flatMap(group => group.columns);
  if (allColumns.length === 0) return 0;
  
  const totalConfidence = allColumns.reduce((sum, column) => sum + column.confidence, 0);
  return totalConfidence / allColumns.length;
};

export const getHighConfidenceColumns = (result: ValidationResultType, threshold = 0.8): ValidatedColumnType[] => {
  return result.bannerCuts
    .flatMap(group => group.columns)
    .filter(column => column.confidence >= threshold);
};

export const getLowConfidenceColumns = (result: ValidationResultType, threshold = 0.5): ValidatedColumnType[] => {
  return result.bannerCuts
    .flatMap(group => group.columns)
    .filter(column => column.confidence < threshold);
};

export const getTotalColumns = (result: ValidationResultType): number => {
  return result.bannerCuts.reduce((total, group) => total + group.columns.length, 0);
};

// Combine multiple validation results (for group-by-group processing)
export const combineValidationResults = (results: ValidatedGroupType[]): ValidationResultType => {
  return {
    bannerCuts: results
  };
};

// Create validation result from single group
export const createValidationResult = (group: ValidatedGroupType): ValidationResultType => {
  return {
    bannerCuts: [group]
  };
};