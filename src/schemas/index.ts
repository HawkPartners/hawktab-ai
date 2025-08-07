// Schema exports and compilation test
// This file serves as both an export hub and compilation verification

// Data Map Schema exports
export {
  DataMapSchema,
  DataMapItemSchema,
  validateDataMap,
  isValidDataMap,
  findVariable,
  getVariableNames,
  searchByDescription
} from './dataMapSchema';

export type {
  DataMapType,
  DataMapItemType
} from './dataMapSchema';

// Banner Plan Schema exports
export {
  BannerPlanInputSchema,
  BannerGroupSchema,
  BannerColumnSchema,
  validateBannerPlan,
  isValidBannerPlan,
  validateBannerGroup,
  getBannerGroups,
  getGroupByName,
  getTotalColumns,
  getColumnsByGroup,
  createSingleGroupBanner
} from './bannerPlanSchema';

export type {
  BannerPlanInputType,
  BannerGroupType,
  BannerColumnType
} from './bannerPlanSchema';

// Agent Output Schema exports
export {
  ValidationResultSchema,
  ValidatedGroupSchema,
  ValidatedColumnSchema,
  validateResult,
  isValidResult,
  validateGroup,
  getValidatedGroups,
  calculateAverageConfidence,
  getHighConfidenceColumns,
  getLowConfidenceColumns,
  combineValidationResults,
  createValidationResult
} from './agentOutputSchema';

export type {
  ValidationResultType,
  ValidatedGroupType,
  ValidatedColumnType
} from './agentOutputSchema';

// Human Validation Schema exports
export {
  ValidationStatusSchema,
  BannerValidationSchema,
  ColumnFeedbackSchema,
  CrosstabValidationSchema,
  ValidationSessionSchema
} from './humanValidationSchema';

export type {
  ValidationStatus,
  BannerValidation,
  ColumnFeedback,
  CrosstabValidation,
  ValidationSession
} from './humanValidationSchema';

// Schema compilation test - this will fail to compile if any schemas are invalid
import { z } from 'zod';
import { DataMapSchema } from './dataMapSchema';
import { BannerPlanInputSchema, BannerGroupSchema } from './bannerPlanSchema';
import { ValidationResultSchema } from './agentOutputSchema';

// Test that all schemas are valid Zod schemas
const _schemaTest = {
  dataMapIsSchema: DataMapSchema instanceof z.ZodType,
  bannerPlanIsSchema: BannerPlanInputSchema instanceof z.ZodType,
  bannerGroupIsSchema: BannerGroupSchema instanceof z.ZodType,
  validationResultIsSchema: ValidationResultSchema instanceof z.ZodType,
};

// Export test result for verification
export const schemaCompilationTest = _schemaTest;