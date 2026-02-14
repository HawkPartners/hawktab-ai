import type { FlaggedCrosstabColumn } from './types';
import type { ValidationResultType } from '@/schemas/agentOutputSchema';
import type { BannerProcessingResult } from '@/agents/BannerAgent';
import { shouldFlagForReview, getReviewThresholds } from '@/lib/review';

/**
 * Check CrosstabAgent output for columns that need human review.
 * Returns columns with low confidence, explicit flags, expression types that always need review,
 * or columns with alternatives (indicating agent uncertainty).
 */
export function getFlaggedCrosstabColumns(
  crosstabResult: ValidationResultType,
  bannerResult: BannerProcessingResult
): FlaggedCrosstabColumn[] {
  const flagged: FlaggedCrosstabColumn[] = [];
  const thresholds = getReviewThresholds();

  // Build a lookup for original expressions from banner
  const originalLookup = new Map<string, string>();
  const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
  if (extractedStructure?.bannerCuts) {
    for (const group of extractedStructure.bannerCuts) {
      for (const col of group.columns) {
        const key = `${group.groupName}::${col.name}`;
        originalLookup.set(key, col.original);
      }
    }
  }

  for (const group of crosstabResult.bannerCuts) {
    for (const col of group.columns) {
      // Flag for review if:
      // 1. Low confidence, wrong expression type, or
      // 2. Column has alternatives (agent provided multiple options)
      const hasAlternatives = col.alternatives && col.alternatives.length > 0;
      const needsReview = shouldFlagForReview(col.confidence, thresholds.crosstab, col.expressionType) || hasAlternatives;

      if (needsReview) {
        const lookupKey = `${group.groupName}::${col.name}`;
        flagged.push({
          groupName: group.groupName,
          columnName: col.name,
          original: originalLookup.get(lookupKey) || col.name,
          proposed: col.adjusted,
          confidence: col.confidence,
          reasoning: col.reasoning,
          userSummary: col.userSummary,
          alternatives: col.alternatives || [],
          uncertainties: col.uncertainties || [],
          expressionType: col.expressionType,
        });
      }
    }
  }

  return flagged;
}
