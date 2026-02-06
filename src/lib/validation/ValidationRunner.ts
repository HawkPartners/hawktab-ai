/**
 * ValidationRunner.ts
 *
 * Orchestrates 3 validation stages that run before the pipeline.
 * The .sav file is the single source of truth — no CSV datamaps needed.
 *
 * Stages:
 * 1. Read .sav - R+Haven: extract all column metadata, detect stacking
 * 2. Enrich - Convert to RawDataMapVariable[], parent inference, context, type normalization
 * 3. Loop Detection - Detect loops, check fill rates
 */

import path from 'path';
import { detectLoops } from './LoopDetector';
import { checkRAvailability, getDataFileStats, getColumnFillRates, convertToRawVariables } from './RDataReader';
import { classifyLoopFillRates } from './FillRateValidator';
import { DataMapProcessor } from '../processors/DataMapProcessor';
import { getPipelineEventBus } from '../events';
import type { ProcessingResult } from '../processors/DataMapProcessor';
import type {
  ValidationReport,
  ValidationError,
  ValidationWarning,
  LoopDetectionResult,
  DataFileStats,
  LoopFillRateResult,
  DataMapFormat,
} from './types';

// =============================================================================
// Stage Names
// =============================================================================

const STAGE_NAMES: Record<number, string> = {
  1: 'Read Data File',
  2: 'Enrich Variables',
  3: 'Loop Detection',
};

// =============================================================================
// ValidationRunner
// =============================================================================

export interface ValidationRunnerOptions {
  spssPath: string;   // Required — .sav is the source of truth
  outputDir: string;
}

export async function validate(options: ValidationRunnerOptions): Promise<ValidationReport> {
  const startTime = Date.now();
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];
  const eventBus = getPipelineEventBus();

  const format: DataMapFormat = 'sav';
  let processingResult: ProcessingResult | null = null;
  let loopDetection: LoopDetectionResult | null = null;
  let dataFileStats: DataFileStats | null = null;
  const fillRateResults: LoopFillRateResult[] = [];

  // =========================================================================
  // Stage 1: Read Data File (.sav via R + haven)
  // =========================================================================
  const stage1Start = Date.now();
  eventBus.emitValidationStageStart(1, STAGE_NAMES[1]);

  // R is a hard gate — no fallback
  const rAvailable = await checkRAvailability(options.outputDir);

  if (!rAvailable) {
    errors.push({
      stage: 1,
      stageName: STAGE_NAMES[1],
      severity: 'error',
      message: 'R is not available — cannot read .sav data file',
      details: 'Install R and the haven package: install.packages("haven")',
    });
    eventBus.emitValidationStageComplete(1, STAGE_NAMES[1], Date.now() - stage1Start);
    eventBus.emitValidationComplete(false, format, errors.length, warnings.length, Date.now() - startTime);
    return buildReport(false, format, errors, warnings, null, null, null, [], startTime);
  }

  try {
    dataFileStats = await getDataFileStats(options.spssPath, options.outputDir);
    console.log(`[Validation] Data file: ${dataFileStats.rowCount} rows, ${dataFileStats.columns.length} columns`);

    // Check for stacking indicator columns
    if (dataFileStats.stackingColumns.length > 0) {
      warnings.push({
        stage: 1,
        stageName: STAGE_NAMES[1],
        message: `Found stacking indicator columns: ${dataFileStats.stackingColumns.join(', ')}`,
        details: 'Data may be stacked. Pipeline expects wide format.',
      });
      eventBus.emitValidationWarning(
        1,
        `Stacking columns found: ${dataFileStats.stackingColumns.join(', ')}`
      );
    }
  } catch (err) {
    errors.push({
      stage: 1,
      stageName: STAGE_NAMES[1],
      severity: 'error',
      message: `Failed to read data file: ${err instanceof Error ? err.message : String(err)}`,
    });
    eventBus.emitValidationStageComplete(1, STAGE_NAMES[1], Date.now() - stage1Start);
    eventBus.emitValidationComplete(false, format, errors.length, warnings.length, Date.now() - startTime);
    return buildReport(false, format, errors, warnings, null, null, null, [], startTime);
  }

  eventBus.emitValidationStageComplete(1, STAGE_NAMES[1], Date.now() - stage1Start);

  // =========================================================================
  // Stage 2: Enrich Variables
  // =========================================================================
  const stage2Start = Date.now();
  eventBus.emitValidationStageStart(2, STAGE_NAMES[2]);

  try {
    // Convert .sav metadata → RawDataMapVariable[]
    const rawVariables = convertToRawVariables(dataFileStats);
    console.log(`[Validation] Converted ${rawVariables.length} variables from .sav`);

    // Enrich: parent inference → parent context → type normalization
    const processor = new DataMapProcessor();
    const enriched = processor.enrichVariables(rawVariables);

    const surveyVarCount = enriched.verbose.filter(
      (v) =>
        v.column !== 'record' &&
        v.column !== 'uuid' &&
        v.column !== 'date' &&
        v.column !== 'status'
    ).length;

    if (surveyVarCount === 0) {
      errors.push({
        stage: 2,
        stageName: STAGE_NAMES[2],
        severity: 'error',
        message: 'No survey variables found in data file',
      });
    } else {
      console.log(`[Validation] Enriched ${enriched.verbose.length} variables (${surveyVarCount} survey vars)`);
    }

    processingResult = {
      success: true,
      verbose: enriched.verbose,
      agent: enriched.agent,
      validationPassed: true,
      confidence: 1.0,
      errors: [],
      warnings: [],
    };

    // Save development outputs (verbose, crosstab-agent, table-agent JSONs)
    const savFilename = path.basename(options.spssPath, '.sav');
    await processor.saveDevelopmentOutputs(enriched, savFilename, options.outputDir);
  } catch (err) {
    errors.push({
      stage: 2,
      stageName: STAGE_NAMES[2],
      severity: 'error',
      message: `Variable enrichment failed: ${err instanceof Error ? err.message : String(err)}`,
    });
  }

  eventBus.emitValidationStageComplete(2, STAGE_NAMES[2], Date.now() - stage2Start);

  // If Stage 2 has blocking errors, stop
  if (errors.some((e) => e.stage === 2 && e.severity === 'error')) {
    eventBus.emitValidationComplete(false, format, errors.length, warnings.length, Date.now() - startTime);
    return buildReport(false, format, errors, warnings, processingResult, null, null, [], startTime);
  }

  // =========================================================================
  // Stage 3: Loop Detection
  // =========================================================================
  const stage3Start = Date.now();
  eventBus.emitValidationStageStart(3, STAGE_NAMES[3]);

  if (processingResult) {
    const variableNames = processingResult.verbose.map((v) => v.column);
    loopDetection = detectLoops(variableNames);

    if (loopDetection.hasLoops) {
      console.log(`[Validation] Detected ${loopDetection.loops.length} loop group(s)`);

      for (const loop of loopDetection.loops) {
        console.log(`  Loop: ${loop.skeleton}, ${loop.iterations.length} iterations, ${loop.diversity} unique bases`);

        warnings.push({
          stage: 3,
          stageName: STAGE_NAMES[3],
          message: `Loop detected: ${loop.iterations.length} iterations of ${loop.diversity} questions (pattern: ${loop.skeleton})`,
        });
        eventBus.emitValidationWarning(
          3,
          `Loop: ${loop.iterations.length} iterations x ${loop.diversity} questions`
        );
      }

      // Check fill rates
      try {
        for (const loop of loopDetection.loops) {
          const fillRates = await getColumnFillRates(
            options.spssPath,
            loop.variables,
            options.outputDir
          );
          const fillResult = classifyLoopFillRates(loop, fillRates);
          fillRateResults.push(fillResult);

          console.log(`  Fill pattern: ${fillResult.pattern} — ${fillResult.explanation}`);

          if (fillResult.pattern === 'likely_stacked') {
            warnings.push({
              stage: 3,
              stageName: STAGE_NAMES[3],
              message: `Loop data appears stacked: ${fillResult.explanation}`,
              details: 'Pipeline expects wide format. You may need to restructure the data.',
            });
            eventBus.emitValidationWarning(3, `Stacked data detected: ${fillResult.explanation}`);
          }
        }
      } catch (err) {
        warnings.push({
          stage: 3,
          stageName: STAGE_NAMES[3],
          message: `Fill rate analysis failed: ${err instanceof Error ? err.message : String(err)}`,
        });
      }
    } else {
      console.log('[Validation] No loop patterns detected');
    }
  }

  eventBus.emitValidationStageComplete(3, STAGE_NAMES[3], Date.now() - stage3Start);

  // =========================================================================
  // Final Report
  // =========================================================================
  const hasBlockingErrors = errors.some((e) => e.severity === 'error');
  const canProceed = !hasBlockingErrors;

  eventBus.emitValidationComplete(canProceed, format, errors.length, warnings.length, Date.now() - startTime);

  return buildReport(
    canProceed,
    format,
    errors,
    warnings,
    processingResult,
    loopDetection,
    dataFileStats,
    fillRateResults,
    startTime
  );
}

// =============================================================================
// Helpers
// =============================================================================

function buildReport(
  canProceed: boolean,
  format: DataMapFormat,
  errors: ValidationError[],
  warnings: ValidationWarning[],
  processingResult: ProcessingResult | null,
  loopDetection: LoopDetectionResult | null,
  dataFileStats: DataFileStats | null,
  fillRateResults: LoopFillRateResult[],
  startTime: number
): ValidationReport {
  return {
    canProceed,
    format,
    errors,
    warnings,
    processingResult,
    loopDetection,
    dataFileStats,
    fillRateResults,
    durationMs: Date.now() - startTime,
  };
}
