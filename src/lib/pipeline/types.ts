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
  datamap: string;
  banner: string;
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
  /** Stop after VerificationAgent (skip R/Excel) */
  stopAfterVerification: boolean;
  /** Concurrency level for parallel agents */
  concurrency: number;
  /** Suppress console output (for UI mode) */
  quiet: boolean;
  /** Statistical testing configuration (overrides env defaults) */
  statTesting?: Partial<StatTestingConfig>;
}

export const DEFAULT_PIPELINE_OPTIONS: PipelineOptions = {
  format: 'joe',
  displayMode: 'frequency',
  stopAfterVerification: false,
  concurrency: 3,
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
