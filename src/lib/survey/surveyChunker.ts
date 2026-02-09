/**
 * Survey Chunker — deterministic utilities for splitting large survey markdown
 * into chunks that fit within AI model context windows.
 *
 * Used by SkipLogicAgent to process surveys that exceed the single-pass token limit.
 * All functions are pure and testable — no AI calls.
 */

import type { SkipRule } from '../../schemas/skipLogicSchema';

// =============================================================================
// Types
// =============================================================================

export interface SurveySegment {
  /** The question ID that starts this segment (empty string for preamble) */
  questionId: string;
  /** Full text content of this segment */
  text: string;
  /** Character count of this segment */
  charCount: number;
  /** Section header this segment belongs to (if any) */
  sectionHeader: string;
}

export interface ChunkingMetadata {
  /** Total number of chunks produced */
  totalChunks: number;
  /** Character counts per chunk */
  chunkCharCounts: number[];
  /** Number of segments per chunk */
  segmentsPerChunk: number[];
  /** Number of overlap segments used */
  overlapSegments: number;
  /** Character budget used */
  charBudget: number;
  /** Whether the survey was below threshold (single-pass) */
  wasSinglePass: boolean;
}

// =============================================================================
// Configuration
// =============================================================================

/** Default character budget per chunk (~10K tokens at ~4 chars/token) */
const DEFAULT_CHAR_BUDGET = 40_000;

/** Default number of overlap segments between chunks */
const DEFAULT_OVERLAP_SEGMENTS = 2;

/**
 * Regex to detect question ID boundaries in survey markdown.
 * Matches patterns like: S1, Q3, A5, S10b, Q12a, etc.
 * Allows optional markdown heading prefix (# or ## or ###).
 * Must be at the start of a line (with optional whitespace).
 */
const QUESTION_ID_PATTERN = /^\s*(?:#{1,3}\s+)?([A-Z][A-Za-z]*\d+[a-z]?)[\s.:\)]/m;

/**
 * Regex to detect section headers in survey markdown.
 * Matches: # Section A, ## Part 2, ### Demographics, etc.
 */
const SECTION_HEADER_PATTERN = /^#{1,3}\s+(.+)$/m;

// =============================================================================
// Core Functions
// =============================================================================

/**
 * Parse survey markdown into segments at question boundaries.
 *
 * Each segment contains everything from one question ID to the next.
 * Section headers stay attached to the first question in that section.
 * Preamble before the first question is its own segment.
 */
export function segmentSurvey(markdown: string): SurveySegment[] {
  const lines = markdown.split('\n');
  const segments: SurveySegment[] = [];

  let currentQuestionId = '';
  let currentSectionHeader = '';
  let currentLines: string[] = [];

  const flushSegment = () => {
    if (currentLines.length > 0) {
      const text = currentLines.join('\n');
      segments.push({
        questionId: currentQuestionId,
        text,
        charCount: text.length,
        sectionHeader: currentSectionHeader,
      });
      currentLines = [];
    }
  };

  for (const line of lines) {
    // Check if this line starts a new question
    const questionMatch = line.match(QUESTION_ID_PATTERN);

    if (questionMatch) {
      // Flush previous segment
      flushSegment();
      currentQuestionId = questionMatch[1];

      // Check if there was a section header in the recent lines
      // (we keep it attached to this first question in the section)
    }

    // Detect section headers for metadata
    const sectionMatch = line.match(SECTION_HEADER_PATTERN);
    if (sectionMatch) {
      // Only update section header if we haven't started collecting lines for a question yet
      // OR if this appears to be a true section break (not a question-level heading)
      const headerText = sectionMatch[1].trim();
      const isQuestionHeading = QUESTION_ID_PATTERN.test(headerText);
      if (!isQuestionHeading) {
        currentSectionHeader = headerText;
      }
    }

    currentLines.push(line);
  }

  // Flush remaining lines
  flushSegment();

  return segments;
}

/**
 * Group segments into chunks that fit within a character budget.
 *
 * - Segments are packed greedily into chunks
 * - A single oversized segment gets its own chunk
 * - Overlap: last N segments of each chunk repeat at the start of the next
 *   to catch cross-boundary skip logic
 *
 * @param segments - Survey segments from segmentSurvey()
 * @param charBudget - Maximum characters per chunk (default 40000)
 * @param overlapSegments - Number of segments to overlap between chunks (default 2)
 * @returns Array of chunk text strings
 */
export function groupSegmentsIntoChunks(
  segments: SurveySegment[],
  charBudget: number = DEFAULT_CHAR_BUDGET,
  overlapSegments: number = DEFAULT_OVERLAP_SEGMENTS
): string[] {
  if (segments.length === 0) return [];

  const chunks: string[] = [];
  let currentChunkSegments: SurveySegment[] = [];
  let currentCharCount = 0;

  const flushChunk = () => {
    if (currentChunkSegments.length > 0) {
      chunks.push(currentChunkSegments.map(s => s.text).join('\n'));
    }
  };

  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i];

    // If adding this segment would exceed budget AND we have at least one segment
    if (currentCharCount + segment.charCount > charBudget && currentChunkSegments.length > 0) {
      flushChunk();

      // Start next chunk with overlap from current chunk
      const overlapStart = Math.max(0, currentChunkSegments.length - overlapSegments);
      const overlapSegs = currentChunkSegments.slice(overlapStart);

      currentChunkSegments = [...overlapSegs];
      currentCharCount = overlapSegs.reduce((sum, s) => sum + s.charCount, 0);
    }

    currentChunkSegments.push(segment);
    currentCharCount += segment.charCount;
  }

  // Flush final chunk
  flushChunk();

  return chunks;
}

/**
 * Build a compact survey outline showing all question IDs with brief descriptions.
 * Provides "peripheral vision" of the full survey to each chunk.
 *
 * @param markdown - Full survey markdown
 * @returns Compact outline string (~1-2K tokens for a 100-question survey)
 */
export function buildSurveyOutline(markdown: string): string {
  const lines = markdown.split('\n');
  const entries: string[] = [];
  let currentSection = '';

  for (const line of lines) {
    // Detect section headers
    const sectionMatch = line.match(SECTION_HEADER_PATTERN);
    if (sectionMatch) {
      const headerText = sectionMatch[1].trim();
      const isQuestionHeading = QUESTION_ID_PATTERN.test(headerText);
      if (!isQuestionHeading && headerText !== currentSection) {
        currentSection = headerText;
        entries.push(`\n## ${currentSection}`);
      }
    }

    // Detect question IDs
    const questionMatch = line.match(QUESTION_ID_PATTERN);
    if (questionMatch) {
      const questionId = questionMatch[1];
      // Get first ~80 chars of the line as description
      const description = line.trim().substring(0, 80).replace(/\s+/g, ' ');
      entries.push(`- ${questionId}: ${description}`);
    }
  }

  if (entries.length === 0) {
    return '(No question IDs detected in survey)';
  }

  return entries.join('\n');
}

/**
 * Format accumulated rules as a compact summary for inclusion in chunk prompts.
 * Each rule takes ~50-100 tokens, keeping overhead manageable.
 *
 * @param rules - Rules extracted from previous chunks
 * @returns Formatted summary string
 */
export function formatAccumulatedRules(rules: SkipRule[]): string {
  if (rules.length === 0) return '(No rules extracted yet)';

  return rules.map(rule => {
    const appliesTo = rule.appliesTo.join(', ');
    return `- [${rule.ruleId}] ${rule.ruleType} → ${appliesTo}: ${rule.conditionDescription}`;
  }).join('\n');
}

/**
 * Deduplicate rules that may have been extracted from overlapping chunk regions.
 *
 * Strategy:
 * - Group by ruleType + overlapping appliesTo sets
 * - Merge near-duplicates (same target questions, similar conditions)
 * - Conservative: when in doubt, keep both rules
 *
 * @param rules - All rules from all chunks
 * @returns Deduplicated rules
 */
export function deduplicateRules(rules: SkipRule[]): SkipRule[] {
  if (rules.length <= 1) return rules;

  const deduplicated: SkipRule[] = [];
  const seen = new Set<string>();

  for (const rule of rules) {
    // Create a fingerprint based on ruleType + sorted appliesTo + normalized condition
    const appliesToKey = [...rule.appliesTo].sort().join(',');
    const conditionKey = rule.conditionDescription.toLowerCase().replace(/\s+/g, ' ').trim();
    const fingerprint = `${rule.ruleType}|${appliesToKey}|${conditionKey}`;

    if (seen.has(fingerprint)) {
      continue; // Exact duplicate
    }

    // Check for near-duplicates: same ruleType and significant appliesTo overlap
    let isDuplicate = false;
    for (const existing of deduplicated) {
      if (existing.ruleType !== rule.ruleType) continue;

      const existingSet = new Set(existing.appliesTo);
      const ruleSet = new Set(rule.appliesTo);
      const intersection = rule.appliesTo.filter(q => existingSet.has(q));

      // If >70% overlap in appliesTo AND conditions look similar, merge
      const overlapRatio = intersection.length / Math.max(existingSet.size, ruleSet.size);
      if (overlapRatio > 0.7) {
        const existingCondNorm = existing.conditionDescription.toLowerCase().replace(/\s+/g, ' ').trim();
        const ruleCondNorm = conditionKey;

        // Simple similarity: one contains the other, or they share significant substring
        if (existingCondNorm.includes(ruleCondNorm) || ruleCondNorm.includes(existingCondNorm)) {
          // Merge: take the union of appliesTo, keep the longer condition description
          const mergedAppliesTo = [...new Set([...existing.appliesTo, ...rule.appliesTo])];
          existing.appliesTo = mergedAppliesTo;
          if (rule.conditionDescription.length > existing.conditionDescription.length) {
            existing.conditionDescription = rule.conditionDescription;
            existing.surveyText = rule.surveyText;
          }
          if (rule.translationContext && rule.translationContext.length > (existing.translationContext || '').length) {
            existing.translationContext = rule.translationContext;
          }
          isDuplicate = true;
          break;
        }
      }
    }

    if (!isDuplicate) {
      seen.add(fingerprint);
      deduplicated.push({ ...rule });
    }
  }

  return deduplicated;
}

/**
 * Get survey stats for logging and threshold decisions.
 */
export function getSurveyStats(markdown: string): {
  charCount: number;
  estimatedTokens: number;
  lineCount: number;
} {
  return {
    charCount: markdown.length,
    estimatedTokens: Math.ceil(markdown.length / 4),
    lineCount: markdown.split('\n').length,
  };
}

/**
 * Convenience function: segment survey then group into chunks.
 *
 * @param markdown - Full survey markdown
 * @param charBudget - Character budget per chunk
 * @param overlapSegments - Number of overlap segments
 * @returns Object with chunks array and metadata
 */
export function segmentSurveyIntoChunks(
  markdown: string,
  charBudget: number = DEFAULT_CHAR_BUDGET,
  overlapSegments: number = DEFAULT_OVERLAP_SEGMENTS
): { chunks: string[]; metadata: ChunkingMetadata } {
  const segments = segmentSurvey(markdown);

  // Fallback: if no question boundaries detected, return the full text as one chunk
  if (segments.length <= 1) {
    console.warn('[surveyChunker] No question boundaries detected — falling back to single chunk');
    return {
      chunks: [markdown],
      metadata: {
        totalChunks: 1,
        chunkCharCounts: [markdown.length],
        segmentsPerChunk: [segments.length],
        overlapSegments: 0,
        charBudget,
        wasSinglePass: true,
      },
    };
  }

  const chunks = groupSegmentsIntoChunks(segments, charBudget, overlapSegments);

  // Build metadata by counting segments per chunk
  // (approximate — overlap makes exact counting complex, but this is for logging)
  const chunkCharCounts = chunks.map(c => c.length);
  const segmentsPerChunk = chunks.map(chunk => {
    // Count question IDs in chunk as a proxy for segments
    const matches = chunk.match(new RegExp(QUESTION_ID_PATTERN.source, 'gm'));
    return matches ? matches.length : 1;
  });

  return {
    chunks,
    metadata: {
      totalChunks: chunks.length,
      chunkCharCounts,
      segmentsPerChunk,
      overlapSegments,
      charBudget,
      wasSinglePass: false,
    },
  };
}
