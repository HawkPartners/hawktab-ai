/**
 * Pipeline Types
 *
 * Shared type definitions for the pipeline runner.
 */

import type { ExcelFormat, DisplayMode } from '../excel/ExcelFormatter';
import type { StatTestingConfig } from '../env';

// =============================================================================
// File Discovery
// =============================================================================

export interface DatasetFiles {
  datamap: string | null;  // Optional — .sav is the source of truth
  banner: string | null;   // Optional — AI generates banner cuts when missing
  spss: string;
  survey: string | null;  // Optional - needed for VerificationAgent
  name: string;
}

// =============================================================================
// Pipeline Options
// =============================================================================

export interface PipelineOptions {
  /** Excel output format */
  format: ExcelFormat;
  /** Display mode (frequency, counts, both) */
  displayMode: DisplayMode;
  /** When displayMode='both', output two separate .xlsx files instead of two sheets in one */
  separateWorkbooks: boolean;
  /** Stop after VerificationAgent (skip R/Excel) */
  stopAfterVerification: boolean;
  /** Concurrency level for parallel agents */
  concurrency: number;
  /** Excel color theme */
  theme: string;
  /** Suppress console output (for UI mode) */
  quiet: boolean;
  /** Statistical testing configuration (overrides env defaults) */
  statTesting?: Partial<StatTestingConfig>;
  /** Research objectives for AI-generated banner (when no banner document) */
  researchObjectives?: string;
  /** Suggested cuts for AI-generated banner (treated as near-requirements) */
  cutSuggestions?: string;
  /** Project type hint for AI-generated banner */
  projectType?: 'atu' | 'segmentation' | 'demand' | 'concept_test' | 'tracking' | 'general';
}

export const DEFAULT_PIPELINE_OPTIONS: PipelineOptions = {
  format: 'joe',
  displayMode: 'frequency',
  separateWorkbooks: false,
  stopAfterVerification: false,
  concurrency: 3,
  theme: 'classic',
  quiet: false,
};

// =============================================================================
// Pipeline Results
// =============================================================================

export interface PipelineResult {
  success: boolean;
  dataset: string;
  outputDir: string;
  durationMs: number;
  tableCount: number;
  totalCostUsd: number;
  error?: string;
}
