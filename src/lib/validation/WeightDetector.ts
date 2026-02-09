/**
 * WeightDetector.ts
 *
 * Detects candidate weight variables from .sav metadata.
 * Uses heuristic scoring based on name patterns, data statistics,
 * and structural indicators.
 *
 * Scoring signals:
 *   +0.40  name matches weight patterns (wt, weight, wgt, rim, etc.)
 *   +0.15  no value labels (weight vars are continuous)
 *   +0.10  rClass is "numeric"
 *   +0.15  mean within 0.15 of 1.0
 *   +0.10  observedMin > 0
 *   +0.10  range plausible (min >= 0.1, max <= 5.0)
 *   -0.30  has structural suffix (r1, c1, etc. — it's a sub-variable)
 *
 * Threshold: score >= 0.5
 */

import type { DataFileStats, WeightCandidate, WeightDetectionResult } from './types';
import { hasStructuralSuffix } from './RDataReader';

// Weight variable name patterns
const WEIGHT_NAME_PATTERN = /^(wt|weight|wgt|w_|rim)/i;
const WEIGHT_SUFFIX_PATTERN = /_wt$/i;
const WEIGHT_CONTAINS_PATTERN = /weight/i;

const SCORE_THRESHOLD = 0.5;

/**
 * Detect candidate weight variables from data file stats.
 */
export function detectWeightCandidates(stats: DataFileStats): WeightDetectionResult {
  const candidates: WeightCandidate[] = [];

  for (const col of stats.columns) {
    const meta = stats.variableMetadata[col];
    if (!meta) continue;

    // Skip text columns entirely
    if (meta.rClass === 'character' || meta.format?.startsWith('A')) continue;

    // Skip columns with no numeric data
    if (meta.observedMean === null || meta.observedMean === undefined) continue;

    let score = 0;
    const signals: string[] = [];

    // Name matching
    if (WEIGHT_NAME_PATTERN.test(col) || WEIGHT_SUFFIX_PATTERN.test(col) || WEIGHT_CONTAINS_PATTERN.test(col)) {
      score += 0.40;
      signals.push('name matches weight pattern');
    }

    // No value labels (weight vars are continuous, not categorical)
    if (!meta.valueLabels || meta.valueLabels.length === 0) {
      score += 0.15;
      signals.push('no value labels (continuous)');
    }

    // Numeric class
    if (meta.rClass === 'numeric') {
      score += 0.10;
      signals.push('numeric class');
    }

    // Mean near 1.0 (weights are typically normalized to mean=1)
    if (Math.abs(meta.observedMean - 1.0) <= 0.15) {
      score += 0.15;
      signals.push(`mean ≈ 1.0 (${meta.observedMean.toFixed(3)})`);
    }

    // All values positive
    if (meta.observedMin !== null && meta.observedMin > 0) {
      score += 0.10;
      signals.push('all values positive');
    }

    // Plausible range for weights
    if (meta.observedMin !== null && meta.observedMax !== null &&
        meta.observedMin >= 0.1 && meta.observedMax <= 5.0) {
      score += 0.10;
      signals.push(`plausible range (${meta.observedMin.toFixed(2)}-${meta.observedMax.toFixed(2)})`);
    }

    // Structural suffix penalty (sub-variables like S9r1 are not weights)
    if (hasStructuralSuffix(col)) {
      score -= 0.30;
      signals.push('structural suffix detected (penalty)');
    }

    if (score >= SCORE_THRESHOLD) {
      candidates.push({
        column: col,
        label: meta.label || '',
        score,
        signals,
        mean: meta.observedMean,
        sd: meta.observedSd ?? 0,
        min: meta.observedMin ?? 0,
        max: meta.observedMax ?? 0,
      });
    }
  }

  // Sort by score descending
  candidates.sort((a, b) => b.score - a.score);

  return {
    candidates,
    bestCandidate: candidates.length > 0 ? candidates[0] : null,
  };
}
