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

  /** Which stacked frame this applies to (empty string if respondent-anchored) */
  stackedFrameName: z.string(),

  /** Implementation strategy for entity-anchored groups */
  implementation: z.object({
    /** "alias_column" for entity-anchored, "none" for respondent-anchored */
    strategy: z.enum(['alias_column', 'none']),

    /** Name for the derived column on stacked frame. Empty string if not used.
     *  Use ".hawktab_" prefix to avoid collisions with survey variables. */
    aliasName: z.string(),

    /** Map of iteration value -> source variable name.
     *  e.g., { "1": "S10a", "2": "S11a" }. Empty object if not used. */
    sourcesByIteration: z.record(z.string(), z.string()),

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

  /** Whether a human should review before trusting these results */
  humanReviewRequired: z.boolean(),

  /** Warnings about edge cases or low confidence decisions */
  warnings: z.array(z.string()),

  /** Brief reasoning summary */
  reasoning: z.string(),
});

export type LoopSemanticsPolicy = z.infer<typeof LoopSemanticsPolicySchema>;
export type BannerGroupPolicy = z.infer<typeof BannerGroupPolicySchema>;
