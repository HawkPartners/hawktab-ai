/**
 * Pipeline Runner
 *
 * Core pipeline execution logic shared between CLI and test scripts.
 */

import fs from 'fs/promises';
import path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';

// Processors and agents
import { BannerAgent } from '../../agents/BannerAgent';
import { processAllGroups as processCrosstabGroups } from '../../agents/CrosstabAgent';
import { groupDataMap } from '../tables/DataMapGrouper';
import { generateTables, convertToLegacyFormat, getGeneratorStats } from '../tables/TableGenerator';
import { verifyAllTablesParallel } from '../../agents/VerificationAgent';
import { analyzeAllTableBasesParallel } from '../../agents/BaseFilterAgent';
import { summarizeBaseFilterResults } from '../../schemas/baseFilterAgentSchema';
import { processSurvey } from '../processors/SurveyProcessor';
import { generateRScriptV2WithValidation } from '../r/RScriptGeneratorV2';
import { validateAndFixTables } from '../r/ValidationOrchestrator';
import { buildCutsSpec } from '../tables/CutsSpec';
import { sortTables, getSortingMetadata } from '../tables/sortTables';
import { ExcelFormatter } from '../excel/ExcelFormatter';
import { extractStreamlinedData } from '../data/extractStreamlinedData';
import { getPromptVersions, getStatTestingConfig, formatStatTestingConfig } from '../env';
import type { StatTestingConfig } from '../env';
import { resetMetricsCollector, getPipelineCostSummary, getMetricsCollector } from '../observability';
import { getPipelineEventBus, STAGE_NAMES } from '../events';

import { findDatasetFiles, DEFAULT_DATASET } from './FileDiscovery';
import type { PipelineOptions, PipelineResult, DatasetFiles } from './types';
import { DEFAULT_PIPELINE_OPTIONS } from './types';
import type { VerboseDataMapType } from '../../schemas/processingSchemas';
import type { ExtendedTableDefinition } from '../../schemas/verificationAgentSchema';
import { validate as runValidation } from '../validation/ValidationRunner';
import { collapseLoopVariables } from '../validation/LoopCollapser';
import type { LoopGroupMapping } from '../validation/LoopCollapser';

const execAsync = promisify(exec);

// =============================================================================
// Logger
// =============================================================================

interface Logger {
  log: (message: string, color?: string) => void;
  logStep: (step: number, total: number, message: string) => void;
}

const COLORS = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
  magenta: '\x1b[35m',
};

function createLogger(quiet: boolean): Logger {
  if (quiet) {
    return {
      log: () => {},
      logStep: () => {},
    };
  }

  return {
    log: (message: string, color: string = 'reset') => {
      const colorCode = COLORS[color as keyof typeof COLORS] || COLORS.reset;
      console.log(`${colorCode}${message}${COLORS.reset}`);
    },
    logStep: (step: number, total: number, message: string) => {
      console.log(`${COLORS.cyan}[${step}/${total}] ${message}${COLORS.reset}`);
    },
  };
}

// =============================================================================
// Pipeline Runner
// =============================================================================

export async function runPipeline(
  datasetFolder: string = DEFAULT_DATASET,
  options: Partial<PipelineOptions> = {}
): Promise<PipelineResult> {
  const opts: PipelineOptions = { ...DEFAULT_PIPELINE_OPTIONS, ...options };
  const { format, displayMode, stopAfterVerification, concurrency, quiet, statTesting } = opts;

  // Build effective stat testing config (CLI overrides -> env defaults)
  const envStatConfig = getStatTestingConfig();
  const effectiveStatConfig: StatTestingConfig = {
    thresholds: statTesting?.thresholds ?? envStatConfig.thresholds,
    proportionTest: statTesting?.proportionTest ?? envStatConfig.proportionTest,
    meanTest: statTesting?.meanTest ?? envStatConfig.meanTest,
    minBase: statTesting?.minBase ?? envStatConfig.minBase,
  };

  const logger = createLogger(quiet);
  const { log, logStep } = logger;

  const startTime = Date.now();
  const totalSteps = stopAfterVerification ? 5 : 10;

  // Reset metrics collector for this pipeline run
  resetMetricsCollector();

  // Get event bus for CLI events
  const eventBus = getPipelineEventBus();

  log('', 'reset');
  log('='.repeat(70), 'magenta');
  log('  HawkTab AI - Pipeline', 'bright');
  log('='.repeat(70), 'magenta');
  log('', 'reset');

  // Discover files
  log(`Dataset folder: ${datasetFolder}`, 'blue');
  let files: DatasetFiles;
  try {
    files = await findDatasetFiles(datasetFolder);
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    eventBus.emitPipelineFailed(datasetFolder, errorMsg);
    return {
      success: false,
      dataset: datasetFolder,
      outputDir: '',
      durationMs: Date.now() - startTime,
      tableCount: 0,
      totalCostUsd: 0,
      error: errorMsg,
    };
  }

  log(`  Datamap: ${files.datamap ? path.basename(files.datamap) : '(not used — .sav is source of truth)'}`, 'dim');
  log(`  Banner:  ${path.basename(files.banner)}`, 'dim');
  log(`  SPSS:    ${path.basename(files.spss)}`, 'dim');
  log(`  Survey:  ${files.survey ? path.basename(files.survey) : '(not found - VerificationAgent will use passthrough)'}`, 'dim');
  log('', 'reset');

  // Get prompt versions for logging
  const promptVersions = getPromptVersions();
  log('Prompt Versions:', 'blue');
  log(`  Banner:        ${promptVersions.bannerPromptVersion}`, 'dim');
  log(`  Crosstab:      ${promptVersions.crosstabPromptVersion}`, 'dim');
  log(`  Table:         ${promptVersions.tablePromptVersion}`, 'dim');
  log(`  Verification:  ${promptVersions.verificationPromptVersion}`, 'dim');
  log('', 'reset');

  // Log stat testing configuration
  log('Stat Testing Configuration:', 'blue');
  log(`  ${formatStatTestingConfig(effectiveStatConfig).split('\n').join('\n  ')}`, 'dim');
  log('', 'reset');

  // Create output folder: outputs/<dataset>/pipeline-<timestamp>/
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputFolder = `pipeline-${timestamp}`;
  const outputDir = path.join(process.cwd(), 'outputs', files.name, outputFolder);
  await fs.mkdir(outputDir, { recursive: true });
  log(`Output folder: outputs/${files.name}/${outputFolder}`, 'blue');
  log('', 'reset');

  // Copy SPSS file to output folder (needed for R)
  const spssDestPath = path.join(outputDir, 'dataFile.sav');
  await fs.copyFile(files.spss, spssDestPath);

  // Emit pipeline:start event
  eventBus.emitPipelineStart(files.name, totalSteps, outputDir);

  try {
    // -------------------------------------------------------------------------
    // Pre-Step: Validation
    // -------------------------------------------------------------------------
    log('Running pre-pipeline validation...', 'cyan');
    const validationStart = Date.now();

    const validationResult = await runValidation({
      spssPath: files.spss,
      outputDir,
    });

    const validationDuration = Date.now() - validationStart;
    log(`  Format: ${validationResult.format}`, 'dim');
    log(`  Errors: ${validationResult.errors.length}, Warnings: ${validationResult.warnings.length}`, 'dim');

    if (validationResult.loopDetection?.hasLoops) {
      for (const loop of validationResult.loopDetection.loops) {
        log(`  Loop: ${loop.iterations.length} iterations x ${loop.diversity} questions`, 'yellow');
      }
    }

    for (const w of validationResult.warnings) {
      log(`  Warning: ${w.message}`, 'yellow');
    }

    if (!validationResult.canProceed) {
      log('', 'reset');
      log('Validation FAILED — pipeline cannot proceed:', 'red');
      for (const e of validationResult.errors) {
        log(`  [Stage ${e.stage}] ${e.message}`, 'red');
        if (e.details) log(`    ${e.details}`, 'dim');
      }
      eventBus.emitPipelineFailed(files.name, 'Validation failed: ' + validationResult.errors.map(e => e.message).join('; '));
      return {
        success: false,
        dataset: files.name,
        outputDir,
        durationMs: Date.now() - startTime,
        tableCount: 0,
        totalCostUsd: 0,
        error: 'Validation failed: ' + validationResult.errors.map(e => e.message).join('; '),
      };
    }

    log(`  Validation passed in ${validationDuration}ms`, 'green');
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Step 1: Variable data (from validation)
    // -------------------------------------------------------------------------
    logStep(1, totalSteps, 'Loading variable data from .sav...');
    const stepStart1 = Date.now();
    eventBus.emitStageStart(1, STAGE_NAMES[1]);

    const dataMapResult = validationResult.processingResult!;
    let verboseDataMap = dataMapResult.verbose as VerboseDataMapType[];
    log(`  ${verboseDataMap.length} variables from .sav`, 'green');

    // Collapse loop variables if loops detected
    let loopMappings: LoopGroupMapping[] = [];
    let baseNameToLoopIndex: Map<string, number> = new Map();
    if (validationResult.loopDetection?.hasLoops) {
      // Block if data appears already stacked
      const hasStackedPattern = validationResult.fillRateResults.some(
        fr => fr.pattern === 'likely_stacked'
      );
      if (hasStackedPattern) {
        const msg = 'Data appears to be already stacked. Please upload the original wide-format data.';
        log(`  ${msg}`, 'red');
        eventBus.emitPipelineFailed(files.name, msg);
        return {
          success: false,
          dataset: files.name,
          outputDir,
          durationMs: Date.now() - startTime,
          tableCount: 0,
          totalCostUsd: 0,
          error: msg,
        };
      }

      const collapseResult = collapseLoopVariables(
        verboseDataMap,
        validationResult.loopDetection,
      );
      verboseDataMap = collapseResult.collapsedDataMap as VerboseDataMapType[];
      loopMappings = collapseResult.loopMappings;
      baseNameToLoopIndex = collapseResult.baseNameToLoopIndex;

      log(`  Collapsed loops: ${collapseResult.collapsedVariableNames.size} iteration vars → ${loopMappings.reduce((s, m) => s + m.variables.length, 0)} base vars`, 'green');
      for (const m of loopMappings) {
        log(`    ${m.stackedFrameName}: ${m.variables.length} vars x ${m.iterations.length} iterations (${m.skeleton})`, 'dim');
      }
    }

    log(`  Effective datamap: ${verboseDataMap.length} variables`, 'green');
    log(`  Duration: ${Date.now() - stepStart1}ms`, 'dim');
    eventBus.emitStageComplete(1, STAGE_NAMES[1], Date.now() - stepStart1);
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Steps 2-5: Parallel Path Execution
    // -------------------------------------------------------------------------
    log('', 'reset');
    logStep(2, totalSteps, 'Starting parallel paths...');
    log(`  Path A: BannerAgent → CrosstabAgent`, 'dim');
    log(`  Path B: TableGenerator → VerificationAgent`, 'dim');
    log('', 'reset');

    const parallelStartTime = Date.now();

    // Build simple data structures for CrosstabAgent
    const agentDataMap = dataMapResult.agent.map(v => ({
      Column: v.Column,
      Description: v.Description,
      Answer_Options: v.Answer_Options,
    }));

    // Path A: BannerAgent → CrosstabAgent
    const pathAPromise = (async () => {
      const pathAStart = Date.now();
      log(`  [Path A] Starting BannerAgent...`, 'cyan');
      eventBus.emitStageStart(2, STAGE_NAMES[2]);

      const bannerAgent = new BannerAgent();
      const bannerResult = await bannerAgent.processDocument(files.banner, outputDir);

      if (!bannerResult.success) {
        log(`  [Path A] WARNING: Banner extraction had issues`, 'yellow');
      }

      const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
      const groupCount = extractedStructure?.bannerCuts?.length || 0;
      const columnCount = (extractedStructure?.processingMetadata as { totalColumns?: number })?.totalColumns || 0;

      if (groupCount === 0) {
        throw new Error('Banner extraction failed - 0 groups extracted');
      }

      log(`  [Path A] BannerAgent: ${groupCount} groups, ${columnCount} columns`, 'green');
      eventBus.emitStageComplete(2, STAGE_NAMES[2], Date.now() - pathAStart);
      log(`  [Path A] Starting CrosstabAgent...`, 'cyan');
      const crosstabStart = Date.now();
      eventBus.emitStageStart(3, STAGE_NAMES[3]);

      const agentBanner = bannerResult.agent || [];
      const crosstabResult = await processCrosstabGroups(
        agentDataMap,
        { bannerCuts: agentBanner.map(g => ({ groupName: g.groupName, columns: g.columns })) },
        outputDir
      );

      log(`  [Path A] CrosstabAgent: ${crosstabResult.result.bannerCuts.length} groups validated`, 'green');
      eventBus.emitStageComplete(3, STAGE_NAMES[3], Date.now() - crosstabStart);
      log(`  [Path A] Complete in ${((Date.now() - pathAStart) / 1000).toFixed(1)}s`, 'dim');

      return { bannerResult, crosstabResult, agentBanner, groupCount, columnCount };
    })();

    // Path B: TableGenerator → Survey → VerificationAgent (Parallel)
    const pathBPromise = (async () => {
      const pathBStart = Date.now();
      log(`  [Path B] Starting TableGenerator...`, 'cyan');
      eventBus.emitStageStart(4, STAGE_NAMES[4]);

      // Replace TableAgent (LLM) with TableGenerator (deterministic)
      const groups = groupDataMap(verboseDataMap);
      const generatedOutputs = generateTables(groups);
      let tableAgentResults = convertToLegacyFormat(generatedOutputs);
      const tableAgentTables = tableAgentResults.flatMap(r => r.tables);
      const stats = getGeneratorStats(generatedOutputs);
      log(`  [Path B] TableGenerator: ${tableAgentTables.length} tables (${stats.tableTypeDistribution['frequency'] || 0} freq, ${stats.tableTypeDistribution['mean_rows'] || 0} mean) in ${stats.totalRows} rows`, 'green');
      eventBus.emitStageComplete(4, STAGE_NAMES[4], Date.now() - pathBStart);

      // Calculate distribution stats for mean_rows tables (Theme D: D1/D2)
      log(`  [Path B] Calculating distribution stats...`, 'cyan');
      try {
        const { enrichTableResultsWithStats } = await import('../stats/DistributionCalculator');
        tableAgentResults = await enrichTableResultsWithStats(
          tableAgentResults,
          files.spss,
          outputDir
        );
        const enrichedMeanRowsTables = tableAgentResults.flatMap(r => r.tables).filter(t => t.meta?.distribution);
        if (enrichedMeanRowsTables.length > 0) {
          log(`  [Path B] Distribution stats: ${enrichedMeanRowsTables.length} tables enriched`, 'green');
        }
      } catch (distError) {
        log(`  [Path B] Distribution stats skipped: ${distError instanceof Error ? distError.message : String(distError)}`, 'yellow');
      }

      // Survey processing
      let surveyMarkdown: string | null = null;
      if (files.survey) {
        log(`  [Path B] Processing survey: ${path.basename(files.survey)}`, 'cyan');
        const surveyResult = await processSurvey(files.survey, outputDir);
        surveyMarkdown = surveyResult.markdown;
        if (surveyMarkdown) {
          log(`  [Path B] Survey: ${surveyMarkdown.length} characters`, 'green');
        } else {
          log(`  [Path B] Survey processing failed: ${surveyResult.warnings.join(', ')}`, 'yellow');
        }
      }

      // VerificationAgent (Parallel)
      let verifiedTables: ExtendedTableDefinition[];
      const { toExtendedTable } = await import('../../schemas/verificationAgentSchema');

      if (surveyMarkdown) {
        log(`  [Path B] Starting VerificationAgent (parallel, concurrency: ${concurrency})...`, 'cyan');
        const verificationStart = Date.now();
        eventBus.emitStageStart(5, STAGE_NAMES[5]);
        try {
          const verificationResult = await verifyAllTablesParallel(
            tableAgentResults,
            surveyMarkdown,
            verboseDataMap,
            { outputDir, concurrency }
          );
          verifiedTables = verificationResult.tables;
          log(`  [Path B] VerificationAgent: ${verifiedTables.length} tables (${verificationResult.metadata.tablesModified} modified)`, 'green');
          eventBus.emitStageComplete(5, STAGE_NAMES[5], Date.now() - verificationStart);
        } catch (verifyError) {
          log(`  [Path B] VerificationAgent failed: ${verifyError instanceof Error ? verifyError.message : String(verifyError)}`, 'yellow');
          eventBus.emitStageFailed(5, STAGE_NAMES[5], verifyError instanceof Error ? verifyError.message : String(verifyError));
          verifiedTables = tableAgentResults.flatMap(group =>
            group.tables.map(t => toExtendedTable(t, group.questionId))
          );
        }
      } else {
        log(`  [Path B] No survey - using TableGenerator output directly`, 'yellow');
        eventBus.emitStageStart(5, STAGE_NAMES[5]);
        verifiedTables = tableAgentResults.flatMap(group =>
          group.tables.map(t => toExtendedTable(t, group.questionId))
        );
        eventBus.emitStageComplete(5, STAGE_NAMES[5], 0);

        // Create verification folder with passthrough output
        const verificationDir = path.join(outputDir, 'verification');
        await fs.mkdir(verificationDir, { recursive: true });
        await fs.writeFile(
          path.join(verificationDir, 'verification-output-raw.json'),
          JSON.stringify({ tables: verifiedTables }, null, 2),
          'utf-8'
        );
      }

      log(`  [Path B] Complete in ${((Date.now() - pathBStart) / 1000).toFixed(1)}s`, 'dim');

      return { tableAgentResults, verifiedTables, surveyMarkdown };
    })();

    // Wait for both paths
    const [pathAResult, pathBResult] = await Promise.allSettled([pathAPromise, pathBPromise]);

    const parallelDuration = Date.now() - parallelStartTime;
    log('', 'reset');
    log(`Parallel paths completed in ${(parallelDuration / 1000).toFixed(1)}s`, 'green');

    // Check results
    if (pathAResult.status === 'rejected') {
      const errorMsg = pathAResult.reason instanceof Error ? pathAResult.reason.message : String(pathAResult.reason);
      throw new Error(`Path A (Banner/Crosstab) failed: ${errorMsg}`);
    }
    if (pathBResult.status === 'rejected') {
      const errorMsg = pathBResult.reason instanceof Error ? pathBResult.reason.message : String(pathBResult.reason);
      throw new Error(`Path B (Table/Verification) failed: ${errorMsg}`);
    }

    // Extract results
    const { crosstabResult, groupCount, columnCount } = pathAResult.value;
    const { tableAgentResults, verifiedTables, surveyMarkdown } = pathBResult.value;
    const tableAgentTables = tableAgentResults.flatMap(r => r.tables);

    log(`  Path A: ${groupCount} groups, ${columnCount} columns, ${crosstabResult.result.bannerCuts.length} validated`, 'dim');
    log(`  Path B: ${tableAgentTables.length} table definitions, ${verifiedTables.length} verified`, 'dim');
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Early exit if --stop-after-verification flag
    // -------------------------------------------------------------------------
    if (stopAfterVerification) {
      log('', 'reset');
      log('--stop-after-verification flag set, skipping R script and Excel generation', 'yellow');
      log('', 'reset');

      const costSummary = await getPipelineCostSummary();
      log(costSummary, 'magenta');

      const totalDuration = Date.now() - startTime;
      const costMetrics = await getMetricsCollector().getSummary();

      eventBus.emitPipelineComplete(
        files.name,
        totalDuration,
        costMetrics.totals.estimatedCostUsd,
        verifiedTables.length,
        outputDir
      );

      return {
        success: true,
        dataset: files.name,
        outputDir,
        durationMs: totalDuration,
        tableCount: verifiedTables.length,
        totalCostUsd: costMetrics.totals.estimatedCostUsd,
      };
    }

    // -------------------------------------------------------------------------
    // Sort tables for logical Excel output order
    // -------------------------------------------------------------------------
    log('Sorting tables...', 'cyan');
    const sortingMetadata = getSortingMetadata(verifiedTables);
    const sortedTables = sortTables(verifiedTables);
    log(`  Screeners: ${sortingMetadata.screenerCount}, Main: ${sortingMetadata.mainCount}, Other: ${sortingMetadata.otherCount}`, 'dim');
    log(`  Sorted ${sortedTables.length} tables`, 'green');
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Step 6: BaseFilterAgent - Detect skip/show logic
    // -------------------------------------------------------------------------
    logStep(6, totalSteps, 'Analyzing table bases for skip logic...');
    const stepStart6 = Date.now();
    eventBus.emitStageStart(6, STAGE_NAMES[6]);

    let filteredTables: ExtendedTableDefinition[];
    if (surveyMarkdown) {
      const baseFilterResult = await analyzeAllTableBasesParallel(
        sortedTables,
        surveyMarkdown,
        verboseDataMap,
        { outputDir, concurrency }
      );

      // Flatten results (each input table may become 1+ output tables)
      filteredTables = baseFilterResult.results.flatMap(r => r.tables);
      const baseFilterSummary = summarizeBaseFilterResults(baseFilterResult.results);

      log(`  Analyzed ${sortedTables.length} tables:`, 'green');
      log(`    Pass: ${baseFilterSummary.passCount}`, 'dim');
      if (baseFilterSummary.filterCount > 0) {
        log(`    Filter: ${baseFilterSummary.filterCount}`, 'yellow');
      }
      if (baseFilterSummary.splitCount > 0) {
        log(`    Split: ${baseFilterSummary.splitCount}`, 'yellow');
      }
      if (baseFilterSummary.reviewRequiredCount > 0) {
        log(`    Review required: ${baseFilterSummary.reviewRequiredCount}`, 'yellow');
      }
      log(`  Output: ${filteredTables.length} tables`, 'green');
    } else {
      log(`  No survey - skipping base filter analysis`, 'yellow');
      filteredTables = sortedTables;
    }
    eventBus.emitStageComplete(6, STAGE_NAMES[6], Date.now() - stepStart6);
    log(`  Duration: ${Date.now() - stepStart6}ms`, 'dim');
    log('', 'reset');

    // Tag tables with loop data frame (if loops detected)
    if (loopMappings.length > 0) {
      let loopTableCount = 0;
      for (const table of filteredTables) {
        // Check if any row variable is a loop base name
        for (const row of table.rows) {
          const loopIdx = baseNameToLoopIndex.get(row.variable);
          if (loopIdx !== undefined) {
            table.loopDataFrame = loopMappings[loopIdx].stackedFrameName;
            loopTableCount++;
            break;
          }
        }
      }
      if (loopTableCount > 0) {
        log(`  Tagged ${loopTableCount} tables with loop data frames`, 'green');
      }
    }

    // -------------------------------------------------------------------------
    // Step 7: R Validation with Retry
    // -------------------------------------------------------------------------
    logStep(7, totalSteps, 'Validating R code per table...');
    const stepStart7 = Date.now();
    eventBus.emitStageStart(7, STAGE_NAMES[7]);

    const cutsSpec = buildCutsSpec(crosstabResult.result);

    // Run per-table R validation with retry loop
    const { validTables, excludedTables: newlyExcluded, validationReport: rValidationReport } = await validateAndFixTables(
      filteredTables,
      cutsSpec.cuts,
      surveyMarkdown || '',
      verboseDataMap,
      {
        outputDir,
        maxRetries: 3,
        dataFilePath: 'dataFile.sav',
        verbose: !quiet,
      }
    );

    // Calculate pre-excluded vs failed-validation counts
    const preExcludedCount = filteredTables.filter(t => t.exclude).length;
    const failedValidationCount = rValidationReport.excluded - preExcludedCount;

    log(`  Passed first time: ${rValidationReport.passedFirstTime}`, 'green');
    if (rValidationReport.fixedAfterRetry > 0) {
      log(`  Fixed after retry: ${rValidationReport.fixedAfterRetry}`, 'yellow');
    }
    if (preExcludedCount > 0) {
      log(`  Pre-excluded (by VerificationAgent): ${preExcludedCount}`, 'dim');
    }
    if (failedValidationCount > 0) {
      log(`  Failed R validation: ${failedValidationCount}`, 'red');
    }
    eventBus.emitStageComplete(7, STAGE_NAMES[7], Date.now() - stepStart7);
    log(`  Duration: ${Date.now() - stepStart7}ms`, 'dim');
    log('', 'reset');

    // Combine valid + excluded tables for R script generation
    const allTablesForR = [...validTables, ...newlyExcluded];
    log(`  Tables for R script: ${validTables.length} valid + ${newlyExcluded.length} excluded = ${allTablesForR.length} total`, 'dim');

    // -------------------------------------------------------------------------
    // Step 8: RScriptGeneratorV2
    // -------------------------------------------------------------------------
    logStep(8, totalSteps, 'Generating R script...');
    const stepStart8 = Date.now();
    eventBus.emitStageStart(8, STAGE_NAMES[8]);
    const rDir = path.join(outputDir, 'r');
    await fs.mkdir(rDir, { recursive: true });

    const { script: masterScript, validation: staticValidationReport } = generateRScriptV2WithValidation(
      {
        tables: allTablesForR,
        cuts: cutsSpec.cuts,
        statTestingConfig: effectiveStatConfig,
        significanceThresholds: effectiveStatConfig.thresholds,
        loopMappings: loopMappings.length > 0 ? loopMappings : undefined,
      },
      { sessionId: outputFolder, outputDir: 'results' }
    );

    const masterPath = path.join(rDir, 'master.R');
    await fs.writeFile(masterPath, masterScript, 'utf-8');

    if (staticValidationReport.invalidTables > 0 || staticValidationReport.warnings.length > 0) {
      const staticValidationPath = path.join(rDir, 'static-validation-report.json');
      await fs.writeFile(staticValidationPath, JSON.stringify(staticValidationReport, null, 2), 'utf-8');
      log(`  ⚠️  Static validation issues: ${staticValidationReport.invalidTables} invalid, ${staticValidationReport.warnings.length} warnings`, 'yellow');
    }

    log(`  Generated R script (${Math.round(masterScript.length / 1024)} KB)`, 'green');
    log(`  Tables in script: ${allTablesForR.length} (${validTables.length} valid, ${newlyExcluded.length} excluded)`, 'green');
    eventBus.emitStageComplete(8, STAGE_NAMES[8], Date.now() - stepStart8);
    log(`  Duration: ${Date.now() - stepStart8}ms`, 'dim');
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Step 9: R Execution
    // -------------------------------------------------------------------------
    logStep(9, totalSteps, 'Executing R script...');
    const stepStart9 = Date.now();
    eventBus.emitStageStart(9, STAGE_NAMES[9]);

    const resultsDir = path.join(outputDir, 'results');
    await fs.mkdir(resultsDir, { recursive: true });

    // Find R
    let rCommand = 'Rscript';
    const rPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
    for (const rPath of rPaths) {
      try {
        await execAsync(`${rPath} --version`, { timeout: 1000 });
        rCommand = rPath;
        break;
      } catch {
        // Try next
      }
    }

    const saveRLog = async (stdout: string, stderr: string, success: boolean) => {
      const rLogPath = path.join(rDir, 'execution.log');
      const logContent = [
        `R Execution Log`,
        `===============`,
        `Timestamp: ${new Date().toISOString()}`,
        `Status: ${success ? 'SUCCESS' : 'FAILED'}`,
        ``,
        `--- STDOUT ---`,
        stdout || '(empty)',
        ``,
        `--- STDERR ---`,
        stderr || '(empty)',
      ].join('\n');
      await fs.writeFile(rLogPath, logContent, 'utf-8');
      return rLogPath;
    };

    try {
      const { stdout, stderr } = await execAsync(
        `cd "${outputDir}" && ${rCommand} "${masterPath}"`,
        { maxBuffer: 10 * 1024 * 1024, timeout: 120000 }
      );

      const logPath = await saveRLog(stdout, stderr, true);
      log(`  R log saved to: ${path.relative(outputDir, logPath)}`, 'dim');

      const resultFiles = await fs.readdir(resultsDir);
      const jsonFile = resultFiles.find(f => f === 'tables.json');

      if (jsonFile) {
        const jsonPath = path.join(resultsDir, jsonFile);
        const jsonContent = await fs.readFile(jsonPath, 'utf-8');
        const jsonData = JSON.parse(jsonContent);
        const tableCount = Object.keys(jsonData.tables || {}).length;

        log(`  Generated tables.json with ${tableCount} tables`, 'green');

        const streamlinedData = extractStreamlinedData(jsonData);
        const streamlinedPath = path.join(resultsDir, 'data-streamlined.json');
        await fs.writeFile(streamlinedPath, JSON.stringify(streamlinedData, null, 2), 'utf-8');
        log(`  Generated data-streamlined.json`, 'green');
      } else {
        log(`  WARNING: No tables.json generated`, 'yellow');
      }

      eventBus.emitStageComplete(9, STAGE_NAMES[9], Date.now() - stepStart9);
      log(`  Duration: ${Date.now() - stepStart9}ms`, 'dim');

      // -------------------------------------------------------------------------
      // Step 10: Excel Export
      // -------------------------------------------------------------------------
      logStep(10, totalSteps, 'Generating Excel workbook...');
      const stepStart10 = Date.now();
      eventBus.emitStageStart(10, STAGE_NAMES[10]);

      const tablesJsonPath = path.join(resultsDir, 'tables.json');
      const excelPath = path.join(resultsDir, 'crosstabs.xlsx');

      try {
        const formatter = new ExcelFormatter({
          format,
          displayMode,
        });
        await formatter.formatFromFile(tablesJsonPath);
        await formatter.saveToFile(excelPath);

        log(`  Generated crosstabs.xlsx (format: ${format}, display: ${displayMode})`, 'green');
        eventBus.emitStageComplete(10, STAGE_NAMES[10], Date.now() - stepStart10);
        log(`  Duration: ${Date.now() - stepStart10}ms`, 'dim');
      } catch (excelError) {
        log(`  Excel generation failed: ${excelError instanceof Error ? excelError.message : String(excelError)}`, 'red');
        eventBus.emitStageFailed(10, STAGE_NAMES[10], excelError instanceof Error ? excelError.message : String(excelError));
      }

    } catch (rError) {
      const execError = rError as { stdout?: string; stderr?: string; message?: string };
      const stdout = execError.stdout || '';
      const stderr = execError.stderr || '';
      const errorMsg = execError.message || String(rError);

      try {
        await saveRLog(stdout, stderr, false);
      } catch {
        // Ignore log save errors
      }

      if (errorMsg.includes('command not found') && !errorMsg.includes('Error in')) {
        log(`  R not installed - script saved for manual execution`, 'yellow');
        eventBus.emitStageFailed(9, STAGE_NAMES[9], 'R not installed');
      } else {
        log(`  R execution failed:`, 'red');
        eventBus.emitStageFailed(9, STAGE_NAMES[9], errorMsg.substring(0, 200));
        if (stderr) {
          const stderrTail = stderr.length > 500 ? '...' + stderr.slice(-500) : stderr;
          log(`  ${stderrTail}`, 'dim');
        } else {
          log(`  ${errorMsg.substring(0, 500)}`, 'dim');
        }
      }
    }
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Summary
    // -------------------------------------------------------------------------
    const totalDuration = Date.now() - startTime;

    const costSummary = await getPipelineCostSummary();
    log(costSummary, 'magenta');

    log('', 'reset');
    log('='.repeat(70), 'magenta');
    log('  Pipeline Complete', 'bright');
    log('='.repeat(70), 'magenta');
    log(`  Dataset:     ${files.name}`, 'reset');
    log(`  Variables:   ${verboseDataMap.length}`, 'reset');
    log(`  Tables:      ${allTablesForR.length} total (${validTables.length} valid, ${newlyExcluded.length} excluded)`, 'reset');
    log(`  Cuts:        ${cutsSpec.cuts.length} (including Total)`, 'reset');
    log(`  Duration:    ${(totalDuration / 1000).toFixed(1)}s`, 'reset');
    log(`  Output:      outputs/${files.name}/${outputFolder}/`, 'reset');
    log('', 'reset');

    const costMetrics = await getMetricsCollector().getSummary();

    // Write summary file
    const summary = {
      dataset: files.name,
      timestamp: new Date().toISOString(),
      duration: { ms: totalDuration, formatted: `${(totalDuration / 1000).toFixed(1)}s` },
      promptVersions: {
        banner: promptVersions.bannerPromptVersion,
        crosstab: promptVersions.crosstabPromptVersion,
        table: promptVersions.tablePromptVersion,
        verification: promptVersions.verificationPromptVersion,
      },
      statTesting: {
        thresholds: effectiveStatConfig.thresholds,
        confidenceLevels: effectiveStatConfig.thresholds.map(t => Math.round((1 - t) * 100)),
        proportionTest: effectiveStatConfig.proportionTest,
        meanTest: effectiveStatConfig.meanTest,
        minBase: effectiveStatConfig.minBase,
        dualThresholdMode: effectiveStatConfig.thresholds.length >= 2 &&
          effectiveStatConfig.thresholds[0] !== effectiveStatConfig.thresholds[1],
      },
      inputs: {
        datamap: files.datamap ? path.basename(files.datamap) : null,
        banner: path.basename(files.banner),
        spss: path.basename(files.spss),
        survey: files.survey ? path.basename(files.survey) : null,
      },
      outputs: {
        variables: verboseDataMap.length,
        tableGeneratorTables: tableAgentTables.length,
        verifiedTables: sortedTables.length,
        validatedTables: validTables.length,
        excludedTables: newlyExcluded.length,
        totalTablesInR: allTablesForR.length,
        cuts: cutsSpec.cuts.length + 1,
        bannerGroups: groupCount,
        sorting: sortingMetadata,
        rValidation: rValidationReport,
      },
      costs: {
        byAgent: costMetrics.byAgent,
        totals: costMetrics.totals,
      },
    };
    await fs.writeFile(
      path.join(outputDir, 'pipeline-summary.json'),
      JSON.stringify(summary, null, 2)
    );

    // Emit pipeline:complete event
    eventBus.emitPipelineComplete(
      files.name,
      totalDuration,
      costMetrics.totals.estimatedCostUsd,
      allTablesForR.length,
      outputDir
    );

    // -------------------------------------------------------------------------
    // Cleanup temporary files
    // -------------------------------------------------------------------------
    log('Cleaning up temporary files...', 'dim');
    const filesToCleanup: string[] = [];

    const spssPathToDelete = path.join(outputDir, 'dataFile.sav');
    try {
      await fs.unlink(spssPathToDelete);
      filesToCleanup.push('dataFile.sav');
    } catch { /* File may not exist */ }

    const bannerImagesDir = path.join(outputDir, 'banner-images');
    try {
      await fs.rm(bannerImagesDir, { recursive: true });
      filesToCleanup.push('banner-images/');
    } catch { /* Folder may not exist */ }

    try {
      const allFiles = await fs.readdir(outputDir);
      for (const file of allFiles) {
        if (file.endsWith('.html')) {
          await fs.unlink(path.join(outputDir, file));
          filesToCleanup.push(file);
        }
        if (file.endsWith('.png') && file.includes('_html_')) {
          await fs.unlink(path.join(outputDir, file));
          filesToCleanup.push(file);
        }
      }
    } catch { /* Ignore cleanup errors */ }

    if (filesToCleanup.length > 0) {
      log(`  Removed: ${filesToCleanup.join(', ')}`, 'dim');
    }

    log('Output files:', 'blue');
    const outputFiles = await fs.readdir(outputDir);
    for (const f of outputFiles) {
      log(`  ${f}`, 'dim');
    }

    return {
      success: true,
      dataset: files.name,
      outputDir,
      durationMs: totalDuration,
      tableCount: allTablesForR.length,
      totalCostUsd: costMetrics.totals.estimatedCostUsd,
    };

  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);
    log(`ERROR: ${errorMsg}`, 'red');
    eventBus.emitPipelineFailed(files.name, errorMsg);

    return {
      success: false,
      dataset: files.name,
      outputDir,
      durationMs: Date.now() - startTime,
      tableCount: 0,
      totalCostUsd: 0,
      error: errorMsg,
    };
  }
}
