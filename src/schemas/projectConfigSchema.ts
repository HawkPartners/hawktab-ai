/**
 * Project Config Schema
 *
 * Shape stored in Convex project.config and run.config.
 * This is the canonical server-side representation of all pipeline options.
 * The wizard form values are mapped to this shape before persisting.
 */

import { z } from 'zod';

export const ProjectConfigSchema = z.object({
  // Project identity
  projectSubType: z.enum(['standard', 'segmentation', 'maxdiff']).default('standard'),
  bannerMode: z.enum(['upload', 'auto_generate']).default('upload'),
  researchObjectives: z.string().optional(),
  bannerHints: z.string().optional(),

  // Display / Excel
  displayMode: z.enum(['frequency', 'counts', 'both']).default('frequency'),
  separateWorkbooks: z.boolean().default(false),
  theme: z.string().default('classic'),

  // Statistical testing
  statTesting: z.object({
    thresholds: z.array(z.number()).default([90]),
    minBase: z.number().default(0),
  }).default({ thresholds: [90], minBase: 0 }),

  // Weights
  weightVariable: z.string().optional(),

  // Loop handling
  loopStatTestingMode: z.enum(['suppress', 'complement']).optional(),

  // Pipeline control
  stopAfterVerification: z.boolean().default(false),
});

export type ProjectConfig = z.infer<typeof ProjectConfigSchema>;

/**
 * Convert wizard form values + any overrides into a ProjectConfig.
 * This is the boundary between the UI form and the server-side config.
 */
export function wizardToProjectConfig(wizard: {
  projectSubType?: string;
  bannerMode?: string;
  researchObjectives?: string;
  bannerHints?: string;
  displayMode?: string;
  separateWorkbooks?: boolean;
  theme?: string;
  statTestingThreshold?: number;
  minBaseSize?: number;
  weightVariable?: string;
  stopAfterVerification?: boolean;
  loopStatTestingMode?: 'suppress' | 'complement';
}): ProjectConfig {
  return ProjectConfigSchema.parse({
    projectSubType: wizard.projectSubType ?? 'standard',
    bannerMode: wizard.bannerMode ?? 'upload',
    researchObjectives: wizard.researchObjectives,
    bannerHints: wizard.bannerHints,
    displayMode: wizard.displayMode ?? 'frequency',
    separateWorkbooks: wizard.separateWorkbooks ?? false,
    theme: wizard.theme ?? 'classic',
    statTesting: {
      thresholds: [wizard.statTestingThreshold ?? 90],
      minBase: wizard.minBaseSize ?? 0,
    },
    weightVariable: wizard.weightVariable,
    loopStatTestingMode: wizard.loopStatTestingMode,
    stopAfterVerification: wizard.stopAfterVerification ?? false,
  });
}
