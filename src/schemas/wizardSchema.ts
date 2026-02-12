/**
 * Wizard Form Schema
 *
 * Zod schema for the 4-step New Project wizard.
 * Used for client-side form validation (React Hook Form) and
 * server-side request validation.
 */

import { z } from 'zod';

// =============================================================================
// Enums / Literals
// =============================================================================

export const ProjectSubTypes = ['standard', 'segmentation', 'maxdiff'] as const;
export type ProjectSubType = (typeof ProjectSubTypes)[number];

export const BannerModes = ['upload', 'auto_generate'] as const;
export type BannerMode = (typeof BannerModes)[number];

export const DisplayModes = ['frequency', 'counts', 'both'] as const;
export type DisplayMode = (typeof DisplayModes)[number];

// =============================================================================
// Wizard Form Schema (client-side, all 4 steps)
// =============================================================================

/**
 * Form schema for the wizard.
 * NOTE: Defaults are NOT set here (they cause input/output type mismatch with zodResolver).
 * Instead, provide defaults via useForm({ defaultValues }) in the page component.
 */
export const WizardFormSchema = z.object({
  // --- Step 1: Project Setup ---
  projectName: z.string().min(1, 'Project name is required'),
  researchObjectives: z.string().optional(),
  projectSubType: z.enum(ProjectSubTypes),
  segmentationHasAssignments: z.boolean().optional(),
  maxdiffHasMessageList: z.boolean().optional(),
  maxdiffHasAnchoredScores: z.boolean().optional(),
  bannerMode: z.enum(BannerModes),
  bannerHints: z.string().optional(),

  // --- Step 3: Configuration ---
  displayMode: z.enum(DisplayModes),
  separateWorkbooks: z.boolean(),
  theme: z.string(),
  statTestingThreshold: z.number().min(50).max(99),
  minBaseSize: z.number().min(0),
  weightVariable: z.string().optional(),
  stopAfterVerification: z.boolean(),
});

export type WizardFormValues = z.infer<typeof WizardFormSchema>;

// =============================================================================
// Per-step validation schemas (subset of fields validated at each step)
// =============================================================================

export const Step1Schema = WizardFormSchema.pick({
  projectName: true,
  researchObjectives: true,
  projectSubType: true,
  segmentationHasAssignments: true,
  maxdiffHasMessageList: true,
  maxdiffHasAnchoredScores: true,
  bannerMode: true,
  bannerHints: true,
});

export const Step3Schema = WizardFormSchema.pick({
  displayMode: true,
  separateWorkbooks: true,
  theme: true,
  statTestingThreshold: true,
  minBaseSize: true,
  weightVariable: true,
  stopAfterVerification: true,
});

// =============================================================================
// Data Validation Result (returned by /api/validate-data, consumed by Step 2B)
// =============================================================================

export interface DataValidationResult {
  status: 'idle' | 'validating' | 'success' | 'error';
  rowCount: number;
  columnCount: number;
  weightCandidates: {
    column: string;
    label: string;
    score: number;
    mean: number;
  }[];
  isStacked: boolean;
  stackedWarning: string | null;
  errors: { message: string; severity: 'error' | 'warning' }[];
  canProceed: boolean;
}

export const INITIAL_VALIDATION: DataValidationResult = {
  status: 'idle',
  rowCount: 0,
  columnCount: 0,
  weightCandidates: [],
  isStacked: false,
  stackedWarning: null,
  errors: [],
  canProceed: false,
};
