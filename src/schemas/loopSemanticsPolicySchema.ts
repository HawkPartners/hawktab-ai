/**
 * Loop Semantics Policy Schema
 *
 * Defines the structured output of the LoopSemanticsPolicyAgent.
 * Each banner group is classified as respondent-anchored or entity-anchored,
 * with implementation details for alias columns on stacked frames.
 *
 * No undefined values — Azure OpenAI structured output requires all properties defined.
 */

import { z } from 'zod';

export const BannerGroupPolicySchema = z.object({
  /** Name matching the banner group from BannerAgent output */
  groupName: z.string(),

  /** How this banner group relates to the stacked entity */
  anchorType: z.enum(['respondent', 'entity']),

  /** Whether cuts in this group should be mutually exclusive on loop tables */
  shouldPartition: z.boolean(),

  /** How to handle within-group significance testing on loop tables */
  comparisonMode: z.enum(['suppress', 'complement']).default('suppress'),

  /** Which stacked frame this applies to (empty string if respondent-anchored) */
  stackedFrameName: z.string(),

  /** Implementation strategy for entity-anchored groups */
  implementation: z.object({
    /** "alias_column" for entity-anchored, "none" for respondent-anchored */
    strategy: z.enum(['alias_column', 'none']),

    /** Name for the derived column on stacked frame. Empty string if not used.
     *  Use ".hawktab_" prefix to avoid collisions with survey variables. */
    aliasName: z.string(),

    /** Iteration-to-variable mapping. Each entry maps one loop iteration to
     *  its source variable. Empty array if not used.
     *  e.g., [{ iteration: "1", variable: "S10a" }, { iteration: "2", variable: "S11a" }] */
    sourcesByIteration: z.array(z.object({
      iteration: z.string(),
      variable: z.string(),
    })),

    /** Brief explanation of the implementation choice */
    notes: z.string(),
  }),

  /** Agent confidence in this classification (0-1) */
  confidence: z.number(),

  /** Evidence supporting this classification */
  evidence: z.array(z.string()),
});

export const LoopSemanticsPolicySchema = z.object({
  /** Schema version for forward compatibility */
  policyVersion: z.string(),

  /** Per-banner-group semantic classifications */
  bannerGroups: z.array(BannerGroupPolicySchema),

  /** Warnings about edge cases or low confidence decisions */
  warnings: z.array(z.string()),

  /** Brief reasoning summary */
  reasoning: z.string(),
});

export type LoopSemanticsPolicy = z.infer<typeof LoopSemanticsPolicySchema>;
export type BannerGroupPolicy = z.infer<typeof BannerGroupPolicySchema>;
