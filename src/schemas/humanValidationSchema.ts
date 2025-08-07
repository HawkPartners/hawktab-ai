import { z } from 'zod';

// Simple validation status tracking
export const ValidationStatusSchema = z.object({
  sessionId: z.string(),
  status: z.enum(['pending', 'validated']),
  createdAt: z.string(),
  validatedAt: z.string().optional(),
});

// Banner validation feedback
export const BannerValidationSchema = z.object({
  original: z.any(), // BannerAgentOutput type
  humanEdits: z.record(z.any()).optional(),
  successRate: z.number().min(0).max(1),
  notes: z.string().optional(),
  modifiedAt: z.string().optional(),
});

// Column feedback for crosstab validation
export const ColumnFeedbackSchema = z.object({
  columnName: z.string(),
  groupName: z.string(),
  adjustedFieldCorrect: z.boolean(),
  confidenceRating: z.enum(['too_high', 'correct', 'too_low']),
  reasoningQuality: z.enum(['poor', 'good', 'excellent']),
  humanEdit: z.string().optional(),
  notes: z.string().optional(),
});

// Crosstab validation feedback
export const CrosstabValidationSchema = z.object({
  original: z.any(), // CrosstabAgentOutput type
  columnFeedback: z.array(ColumnFeedbackSchema),
  overallNotes: z.string().optional(),
});

// Complete validation session
export const ValidationSessionSchema = z.object({
  sessionId: z.string(),
  timestamp: z.string(),
  bannerValidation: BannerValidationSchema.optional(),
  crosstabValidation: CrosstabValidationSchema.optional(),
});

// Types for TypeScript usage
export type ValidationStatus = z.infer<typeof ValidationStatusSchema>;
export type BannerValidation = z.infer<typeof BannerValidationSchema>;
export type ColumnFeedback = z.infer<typeof ColumnFeedbackSchema>;
export type CrosstabValidation = z.infer<typeof CrosstabValidationSchema>;
export type ValidationSession = z.infer<typeof ValidationSessionSchema>;