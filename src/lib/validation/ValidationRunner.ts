/**
 * ValidationRunner.ts
 *
 * Orchestrates 5 validation stages that run before the pipeline.
 * Catches problems early and produces a ProcessingResult that the pipeline reuses.
 *
 * Stages:
 * 1. File Validation - Files exist, parseable, detect format
 * 2. DataMap Parsing - Route to parser, extract variables
 * 3. Data File - R+Haven: rows/columns, stacking columns
 * 4. Cross-Reference - DataMap ↔ Data column match
 * 5. Loop Detection - Detect loops, check fill rates
 */

import fs from 'fs/promises';

import { detectDataMapFormat } from './FormatDetector';
import { parseSPSSVariableInfo } from './SPSSVariableInfoParser';
import { parseSPSSValuesOnly } from './SPSSValuesOnlyParser';
import { hasStructuralSuffix } from './spss-utils';
import { detectLoops } from './LoopDetector';
import { checkRAvailability, getDataFileStats, getColumnFillRates } from './RDataReader';
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
  1: 'File Validation',
  2: 'DataMap Parsing',
  3: 'Data File Analysis',
  4: 'Cross-Reference',
  5: 'Loop Detection',
};

// =============================================================================
// ValidationRunner
// =============================================================================

export interface ValidationRunnerOptions {
  dataMapPath: string;
  spssPath?: string;
  outputDir: string;
}

export async function validate(options: ValidationRunnerOptions): Promise<ValidationReport> {
  const startTime = Date.now();
  const errors: ValidationError[] = [];
  const warnings: ValidationWarning[] = [];
  const eventBus = getPipelineEventBus();

  let format: DataMapFormat = 'unknown';
  let processingResult: ProcessingResult | null = null;
  let loopDetection: LoopDetectionResult | null = null;
  let dataFileStats: DataFileStats | null = null;
  const fillRateResults: LoopFillRateResult[] = [];

  // =========================================================================
  // Stage 1: File Validation
  // =========================================================================
  const stage1Start = Date.now();
  eventBus.emitValidationStageStart(1, STAGE_NAMES[1]);

  try {
    // Check datamap exists and is readable
    await fs.access(options.dataMapPath);
    const content = await fs.readFile(options.dataMapPath, 'utf-8');

    if (!content.trim()) {
      errors.push({
        stage: 1,
        stageName: STAGE_NAMES[1],
        severity: 'error',
        message: 'DataMap file is empty',
      });
    } else {
      // Detect format
      const detection = detectDataMapFormat(content);
      format = detection.format;

      if (format === 'unknown') {
        errors.push({
          stage: 1,
          stageName: STAGE_NAMES[1],
          severity: 'error',
          message: 'Unknown DataMap format',
          details: `Signals: ${detection.signals.join('; ')}`,
        });
      } else if (format === 'spss_values_only') {
        // Supported but limited — no descriptions, no print format metadata.
        // Missing variables will be supplemented from .sav in Stage 4.
        console.log(`[Validation] Format detected: ${format} (confidence: ${detection.confidence.toFixed(2)})`);
        warnings.push({
          stage: 1,
          stageName: STAGE_NAMES[1],
          message: 'SPSS Values Only format — variable descriptions and open-ended variables unavailable from CSV',
          details: 'Missing variables will be supplemented from the data file. For full metadata, re-export from SPSS using DISPLAY DICTIONARY.',
        });
      } else {
        console.log(`[Validation] Format detected: ${format} (confidence: ${detection.confidence.toFixed(2)})`);
      }
    }
  } catch (err) {
    errors.push({
      stage: 1,
      stageName: STAGE_NAMES[1],
      severity: 'error',
      message: `Cannot read DataMap file: ${err instanceof Error ? err.message : String(err)}`,
    });
  }

  eventBus.emitValidationStageComplete(1, STAGE_NAMES[1], Date.now() - stage1Start);

  // If Stage 1 has blocking errors, stop
  if (errors.some((e) => e.severity === 'error')) {
    eventBus.emitValidationComplete(false, format, errors.length, warnings.length, Date.now() - startTime);
    return buildReport(false, format, errors, warnings, null, null, null, [], startTime);
  }

  // =========================================================================
  // Stage 2: DataMap Parsing
  // =========================================================================
  const stage2Start = Date.now();
  eventBus.emitValidationStageStart(2, STAGE_NAMES[2]);

  try {
    const processor = new DataMapProcessor();

    if (format === 'antares') {
      // Use existing Antares pipeline (parse + enrich)
      processingResult = await processor.processDataMap(
        options.dataMapPath,
        options.spssPath,
        options.outputDir
      );
    } else if (format === 'spss_variable_info') {
      // Parse SPSS Variable Info → RawDataMapVariable[]
      const content = await fs.readFile(options.dataMapPath, 'utf-8');
      const rawVariables = parseSPSSVariableInfo(content);
      console.log(`[Validation] SPSS Variable Info parser extracted ${rawVariables.length} variables`);

      // Feed into enrichment pipeline
      processingResult = await processor.processFromRawVariables(
        rawVariables,
        options.dataMapPath,
        options.spssPath,
        options.outputDir
      );
    } else if (format === 'spss_values_only') {
      // Parse SPSS Values Only → RawDataMapVariable[] (only coded variables)
      const content = await fs.readFile(options.dataMapPath, 'utf-8');
      const rawVariables = parseSPSSValuesOnly(content);
      console.log(`[Validation] SPSS Values Only parser extracted ${rawVariables.length} variables (coded only)`);

      // Feed into enrichment pipeline
      processingResult = await processor.processFromRawVariables(
        rawVariables,
        options.dataMapPath,
        options.spssPath,
        options.outputDir
      );
    }

    if (!processingResult || !processingResult.success) {
      errors.push({
        stage: 2,
        stageName: STAGE_NAMES[2],
        severity: 'error',
        message: 'DataMap parsing failed',
        details: processingResult?.errors?.join('; ') || 'Unknown error',
      });
    } else {
      const surveyVarCount = processingResult.verbose.filter(
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
          message: 'No survey variables found in DataMap',
        });
      } else {
        console.log(`[Validation] Parsed ${processingResult.verbose.length} variables (${surveyVarCount} survey vars)`);
      }
    }
  } catch (err) {
    errors.push({
      stage: 2,
      stageName: STAGE_NAMES[2],
      severity: 'error',
      message: `DataMap parsing error: ${err instanceof Error ? err.message : String(err)}`,
    });
  }

  eventBus.emitValidationStageComplete(2, STAGE_NAMES[2], Date.now() - stage2Start);

  // If Stage 2 has blocking errors, stop
  if (errors.some((e) => e.stage === 2 && e.severity === 'error')) {
    eventBus.emitValidationComplete(false, format, errors.length, warnings.length, Date.now() - startTime);
    return buildReport(false, format, errors, warnings, processingResult, null, null, [], startTime);
  }

  // =========================================================================
  // Stage 3: Data File Analysis (requires R)
  // =========================================================================
  const stage3Start = Date.now();
  eventBus.emitValidationStageStart(3, STAGE_NAMES[3]);

  if (options.spssPath) {
    // Check R availability
    const rAvailable = await checkRAvailability(options.outputDir);

    if (!rAvailable) {
      warnings.push({
        stage: 3,
        stageName: STAGE_NAMES[3],
        message: 'R is not available — skipping data file analysis',
        details: 'Install R and the haven package for full validation',
      });
      eventBus.emitValidationWarning(3, 'R not available — skipping data file analysis');
    } else {
      try {
        dataFileStats = await getDataFileStats(options.spssPath, options.outputDir);
        console.log(`[Validation] Data file: ${dataFileStats.rowCount} rows, ${dataFileStats.columns.length} columns`);

        // Check for stacking indicator columns
        if (dataFileStats.stackingColumns.length > 0) {
          warnings.push({
            stage: 3,
            stageName: STAGE_NAMES[3],
            message: `Found stacking indicator columns: ${dataFileStats.stackingColumns.join(', ')}`,
            details: 'Data may be stacked. Pipeline expects wide format.',
          });
          eventBus.emitValidationWarning(
            3,
            `Stacking columns found: ${dataFileStats.stackingColumns.join(', ')}`
          );
        }
      } catch (err) {
        warnings.push({
          stage: 3,
          stageName: STAGE_NAMES[3],
          message: `Data file analysis failed: ${err instanceof Error ? err.message : String(err)}`,
        });
      }
    }
  } else {
    warnings.push({
      stage: 3,
      stageName: STAGE_NAMES[3],
      message: 'No SPSS file provided — skipping data file analysis',
    });
  }

  eventBus.emitValidationStageComplete(3, STAGE_NAMES[3], Date.now() - stage3Start);

  // =========================================================================
  // Stage 4: Cross-Reference (DataMap ↔ Data columns)
  // =========================================================================
  const stage4Start = Date.now();
  eventBus.emitValidationStageStart(4, STAGE_NAMES[4]);

  if (processingResult && dataFileStats) {
    const dataMapColumns = new Set(processingResult.verbose.map((v) => v.column));
    const dataColumns = new Set(dataFileStats.columns);

    const inBoth = [...dataMapColumns].filter((c) => dataColumns.has(c));
    const matchRate = inBoth.length / dataMapColumns.size;

    console.log(`[Validation] Column match: ${inBoth.length}/${dataMapColumns.size} (${(matchRate * 100).toFixed(0)}%)`);

    if (matchRate < 0.5) {
      errors.push({
        stage: 4,
        stageName: STAGE_NAMES[4],
        severity: 'error',
        message: `Low column match rate: ${(matchRate * 100).toFixed(0)}% (${inBoth.length}/${dataMapColumns.size})`,
        details: 'DataMap and data file may not correspond to the same survey.',
      });
    } else if (matchRate < 0.8) {
      warnings.push({
        stage: 4,
        stageName: STAGE_NAMES[4],
        message: `Column match rate: ${(matchRate * 100).toFixed(0)}% — some variables may be missing from data`,
      });
    }

    // Supplement: add columns from .sav that aren't in the datamap
    const inDataOnly = [...dataColumns].filter((c) => !dataMapColumns.has(c));
    if (inDataOnly.length > 0) {
      console.log(`[Validation] Supplementing ${inDataOnly.length} variables from data file`);
      for (const col of inDataOnly) {
        const level = hasStructuralSuffix(col) ? 'sub' as const : 'parent' as const;
        processingResult.verbose.push({
          level,
          column: col,
          description: '',
          valueType: '',
          answerOptions: 'NA',
          parentQuestion: 'NA',
          context: '',
        });
        processingResult.agent.push({
          Column: col,
          Description: '',
          Answer_Options: '',
        });
      }
    }
  } else {
    // Skip if we don't have both pieces
    if (!dataFileStats) {
      console.log('[Validation] Skipping cross-reference (no data file stats)');
    }
  }

  eventBus.emitValidationStageComplete(4, STAGE_NAMES[4], Date.now() - stage4Start);

  // =========================================================================
  // Stage 5: Loop Detection
  // =========================================================================
  const stage5Start = Date.now();
  eventBus.emitValidationStageStart(5, STAGE_NAMES[5]);

  if (processingResult) {
    const variableNames = processingResult.verbose.map((v) => v.column);
    loopDetection = detectLoops(variableNames);

    if (loopDetection.hasLoops) {
      console.log(`[Validation] Detected ${loopDetection.loops.length} loop group(s)`);

      for (const loop of loopDetection.loops) {
        console.log(`  Loop: ${loop.skeleton}, ${loop.iterations.length} iterations, ${loop.diversity} unique bases`);

        warnings.push({
          stage: 5,
          stageName: STAGE_NAMES[5],
          message: `Loop detected: ${loop.iterations.length} iterations of ${loop.diversity} questions (pattern: ${loop.skeleton})`,
        });
        eventBus.emitValidationWarning(
          5,
          `Loop: ${loop.iterations.length} iterations x ${loop.diversity} questions`
        );
      }

      // Check fill rates if R and data are available
      if (dataFileStats && options.spssPath) {
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
                stage: 5,
                stageName: STAGE_NAMES[5],
                message: `Loop data appears stacked: ${fillResult.explanation}`,
                details: 'Pipeline expects wide format. You may need to restructure the data.',
              });
              eventBus.emitValidationWarning(5, `Stacked data detected: ${fillResult.explanation}`);
            }
          }
        } catch (err) {
          warnings.push({
            stage: 5,
            stageName: STAGE_NAMES[5],
            message: `Fill rate analysis failed: ${err instanceof Error ? err.message : String(err)}`,
          });
        }
      }
    } else {
      console.log('[Validation] No loop patterns detected');
    }
  }

  eventBus.emitValidationStageComplete(5, STAGE_NAMES[5], Date.now() - stage5Start);

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
