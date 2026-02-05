/**
 * Validation Types
 *
 * Shared interfaces for the validation layer that runs before the pipeline.
 */

// =============================================================================
// Format Detection
// =============================================================================

export type DataMapFormat = 'antares' | 'spss_variable_info' | 'spss_values_only' | 'unknown';

export interface FormatDetectionResult {
  format: DataMapFormat;
  confidence: number;
  signals: string[];
}

// =============================================================================
// Loop Detection
// =============================================================================

export interface Token {
  type: 'alpha' | 'numeric' | 'separator';
  value: string;
}

export interface LoopGroup {
  /** Skeleton pattern shared by all variables in this group (e.g., 'A-N-_-N') */
  skeleton: string;
  /** Index of the iterator position in the token array */
  iteratorPosition: number;
  /** Unique iterator values found (e.g., ['1', '2', '3']) */
  iterations: string[];
  /** Base variable names (unique question stems without the iterator) */
  bases: string[];
  /** All variable names belonging to this loop group */
  variables: string[];
  /** Number of unique bases per iteration value (diversity metric) */
  diversity: number;
}

export interface LoopDetectionResult {
  /** Whether any loops were detected */
  hasLoops: boolean;
  /** Detected loop groups */
  loops: LoopGroup[];
  /** Variables not part of any detected loop */
  nonLoopVariables: string[];
}

// =============================================================================
// Data File Stats
// =============================================================================

export interface DataFileStats {
  /** Number of rows in the data file */
  rowCount: number;
  /** All column names */
  columns: string[];
  /** Columns that look like stacking indicators (LOOP, ITERATION, etc.) */
  stackingColumns: string[];
}

// =============================================================================
// Fill Rate Validation
// =============================================================================

export type LoopDataPattern = 'valid_wide' | 'likely_stacked' | 'expected_dropout' | 'uncertain';

export interface LoopFillRateResult {
  /** The loop group being validated */
  loopGroup: LoopGroup;
  /** Fill rates per iteration: { '1': 0.95, '2': 0.82, ... } */
  fillRates: Record<string, number>;
  /** Detected data pattern */
  pattern: LoopDataPattern;
  /** Human-readable explanation */
  explanation: string;
}

// =============================================================================
// Validation Report
// =============================================================================

export type ValidationSeverity = 'error' | 'warning' | 'info';

export interface ValidationError {
  stage: number;
  stageName: string;
  severity: ValidationSeverity;
  message: string;
  details?: string;
}

export interface ValidationWarning {
  stage: number;
  stageName: string;
  message: string;
  details?: string;
}

export interface ValidationReport {
  /** Whether the pipeline can proceed */
  canProceed: boolean;
  /** Detected datamap format */
  format: DataMapFormat;
  /** Blocking errors */
  errors: ValidationError[];
  /** Non-blocking warnings */
  warnings: ValidationWarning[];
  /** The parsed ProcessingResult (if validation passes, reuse in pipeline) */
  processingResult: import('../processors/DataMapProcessor').ProcessingResult | null;
  /** Loop detection results (if any) */
  loopDetection: LoopDetectionResult | null;
  /** Data file stats (if R available) */
  dataFileStats: DataFileStats | null;
  /** Fill rate results for detected loops */
  fillRateResults: LoopFillRateResult[];
  /** Duration in ms */
  durationMs: number;
}
