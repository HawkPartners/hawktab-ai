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
import { extractSkipLogic } from '../../agents/SkipLogicAgent';
import { translateSkipRules } from '../../agents/FilterTranslatorAgent';
import { applyFilters } from '../filters/FilterApplicator';
import { processSurvey } from '../processors/SurveyProcessor';
import { generateRScriptV2WithValidation } from '../r/RScriptGeneratorV2';
import { validateAndFixTables } from '../r/ValidationOrchestrator';
import { buildCutsSpec } from '../tables/CutsSpec';
import { sortTables, getSortingMetadata } from '../tables/sortTables';
import { normalizePostPass } from '../tables/TablePostProcessor';
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
import type { ExtendedTableDefinition, TableWithLoopFrame } from '../../schemas/verificationAgentSchema';
import { validate as runValidation } from '../validation/ValidationRunner';
import { collapseLoopVariables } from '../validation/LoopCollapser';
import type { LoopGroupMapping } from '../validation/LoopCollapser';
import { resolveIterationLinkedVariables } from '../validation/LoopContextResolver';
import type { DeterministicResolverResult } from '../validation/LoopContextResolver';
import { runLoopSemanticsPolicyAgent, buildDatamapExcerpt } from '../../agents/LoopSemanticsPolicyAgent';
import type { LoopSemanticsPolicy } from '../../schemas/loopSemanticsPolicySchema';

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
  const totalSteps = stopAfterVerification ? 5 : 11;

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
  log(`  Banner:          ${promptVersions.bannerPromptVersion}`, 'dim');
  log(`  Crosstab:        ${promptVersions.crosstabPromptVersion}`, 'dim');
  log(`  Verification:    ${promptVersions.verificationPromptVersion}`, 'dim');
  log(`  SkipLogic:       ${promptVersions.skipLogicPromptVersion}`, 'dim');
  log(`  FilterTranslator: ${promptVersions.filterTranslatorPromptVersion}`, 'dim');
  log(`  LoopSemantics:   ${promptVersions.loopSemanticsPromptVersion}`, 'dim');
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

    // Log non-loop warnings (loop info is logged separately below in the collapse step)
    for (const w of validationResult.warnings) {
      if (!w.message.startsWith('Loop detected:')) {
        log(`  Warning: ${w.message}`, 'yellow');
      }
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
    let collapsedVariableNames: Set<string> = new Set();
    let deterministicFindings: DeterministicResolverResult | undefined;
    if (validationResult.loopDetection?.hasLoops) {
      // Block ONLY on strong evidence of already-stacked (long) input.
      // Fill-rate heuristics alone are not sufficient: wide data can legitimately
      // have empty later iterations (unused/placeholder columns, strong dropout, etc.).
      const stackingColumns = validationResult.dataFileStats?.stackingColumns ?? [];
      const likelyStackedResults = validationResult.fillRateResults.filter(fr => fr.pattern === 'likely_stacked');
      const likelyStackedAnchors = likelyStackedResults.filter(fr => fr.loopGroup.diversity >= 3);

      const shouldBlockForStackedInput =
        (stackingColumns.length > 0 && likelyStackedAnchors.length > 0) ||
        likelyStackedAnchors.length >= 2;

      if (shouldBlockForStackedInput) {
        const details = [
          stackingColumns.length > 0 ? `stacking columns: ${stackingColumns.join(', ')}` : '',
          likelyStackedAnchors.length > 0 ? `loop patterns: ${likelyStackedAnchors.map(r => r.loopGroup.skeleton).join(', ')}` : '',
        ].filter(Boolean).join(' | ');

        const msg = 'Data appears to be already stacked. Please upload the original wide-format data.';
        log(`  ${msg}`, 'red');
        if (details) log(`    ${details}`, 'dim');
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

      // If we saw any stacked-like signal but not enough to block, keep it as a warning and proceed.
      if (likelyStackedResults.length > 0) {
        const skeletons = [...new Set(likelyStackedResults.map(r => r.loopGroup.skeleton))];
        log(
          `  Warning: stacked-like loop fill pattern detected (${skeletons.length} group(s)); continuing (not blocking)`,
          'yellow'
        );
        log(`    ${skeletons.join(', ')}`, 'dim');
      }

      const collapseResult = collapseLoopVariables(
        verboseDataMap,
        validationResult.loopDetection,
      );
      verboseDataMap = collapseResult.collapsedDataMap as VerboseDataMapType[];
      loopMappings = collapseResult.loopMappings;
      baseNameToLoopIndex = collapseResult.baseNameToLoopIndex;
      collapsedVariableNames = collapseResult.collapsedVariableNames;

      log(`  Loops detected: ${loopMappings.length} groups, ${collapseResult.collapsedVariableNames.size} iteration vars collapsed → ${loopMappings.reduce((s, m) => s + m.variables.length, 0)} base vars`, 'green');
      for (const m of loopMappings) {
        log(`    ${m.stackedFrameName}: ${m.variables.length} vars x ${m.iterations.length} iterations (${m.skeleton})`, 'dim');
      }

      // Save loop summary to output directory for debugging
      const loopSummary = {
        totalLoopGroups: loopMappings.length,
        totalIterationVars: collapseResult.collapsedVariableNames.size,
        totalBaseVars: loopMappings.reduce((s, m) => s + m.variables.length, 0),
        fillRateResults: validationResult.fillRateResults.map(fr => ({
          skeleton: fr.loopGroup.skeleton,
          pattern: fr.pattern,
          explanation: fr.explanation,
          fillRates: fr.fillRates,
        })),
        groups: loopMappings.map(m => ({
          stackedFrameName: m.stackedFrameName,
          skeleton: m.skeleton,
          iterations: m.iterations,
          variableCount: m.variables.length,
          variables: m.variables.map(v => ({
            baseName: v.baseName,
            label: v.label,
            iterationColumns: v.iterationColumns,
          })),
        })),
      };
      await fs.writeFile(
        path.join(outputDir, 'loop-summary.json'),
        JSON.stringify(loopSummary, null, 2),
        'utf-8'
      );
      log(`  Loop summary saved to loop-summary.json`, 'dim');

      // Run deterministic resolver for iteration-linked variables
      deterministicFindings = resolveIterationLinkedVariables(
        verboseDataMap,
        loopMappings,
        collapsedVariableNames,
      );
      log(`  Deterministic resolver: found ${deterministicFindings.iterationLinkedVariables.length} iteration-linked variables`, 'cyan');

      // Save deterministic findings
      const loopPolicyDir = path.join(outputDir, 'loop-policy');
      await fs.mkdir(loopPolicyDir, { recursive: true });
      await fs.writeFile(
        path.join(loopPolicyDir, 'deterministic-resolver.json'),
        JSON.stringify(deterministicFindings, null, 2),
        'utf-8',
      );
    }

    log(`  Effective datamap: ${verboseDataMap.length} variables`, 'green');
    log(`  Duration: ${Date.now() - stepStart1}ms`, 'dim');
    eventBus.emitStageComplete(1, STAGE_NAMES[1], Date.now() - stepStart1);
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Pre-parallel: Survey processing
    // -------------------------------------------------------------------------
    let surveyMarkdown: string | null = null;
    if (files.survey) {
      log(`Processing survey: ${path.basename(files.survey)}`, 'cyan');
      const surveyResult = await processSurvey(files.survey, outputDir);
      surveyMarkdown = surveyResult.markdown;
      if (surveyMarkdown) {
        log(`  Survey: ${surveyMarkdown.length} characters`, 'green');
      } else {
        log(`  Survey processing failed: ${surveyResult.warnings.join(', ')}`, 'yellow');
      }
    }
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Steps 2-5: Parallel Path Execution
    // -------------------------------------------------------------------------
    log('', 'reset');
    logStep(2, totalSteps, 'Starting parallel paths...');
    log(`  Path A: BannerAgent → CrosstabAgent`, 'dim');
    log(`  Path B: TableGenerator → tables + distribution stats`, 'dim');
    log(`  Path C: SkipLogicAgent → FilterTranslatorAgent → filters`, 'dim');
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

    // Path B: TableGenerator → tables + distribution stats (VerificationAgent moved to sequential)
    const pathBPromise = (async () => {
      const pathBStart = Date.now();
      log(`  [Path B] Starting TableGenerator...`, 'cyan');
      eventBus.emitStageStart(4, STAGE_NAMES[4]);

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

      log(`  [Path B] Complete in ${((Date.now() - pathBStart) / 1000).toFixed(1)}s`, 'dim');

      return { tableAgentResults };
    })();

    // Path C: SkipLogicAgent → FilterTranslatorAgent (NEW)
    const pathCPromise = (async () => {
      if (!surveyMarkdown) {
        log(`  [Path C] No survey — skipping skip logic extraction`, 'yellow');
        return { skipLogicResult: null, filterResult: null };
      }

      const pathCStart = Date.now();
      log(`  [Path C] Starting SkipLogicAgent...`, 'cyan');
      eventBus.emitStageStart(5, STAGE_NAMES[5]);

      try {
        const skipLogicResult = await extractSkipLogic(surveyMarkdown, { outputDir });
        log(`  [Path C] SkipLogicAgent: ${skipLogicResult.metadata.rulesExtracted} rules`, 'green');
        eventBus.emitStageComplete(5, STAGE_NAMES[5], Date.now() - pathCStart);

        // FilterTranslatorAgent (chained after SkipLogicAgent)
        if (skipLogicResult.extraction.rules.length > 0) {
          log(`  [Path C] Starting FilterTranslatorAgent...`, 'cyan');

          const filterResult = await translateSkipRules(
            skipLogicResult.extraction.rules,
            verboseDataMap,
            { outputDir }
          );

          log(`  [Path C] FilterTranslatorAgent: ${filterResult.metadata.filtersTranslated} filters (${filterResult.metadata.highConfidenceCount} high confidence)`, 'green');
          log(`  [Path C] Complete in ${((Date.now() - pathCStart) / 1000).toFixed(1)}s`, 'dim');

          return { skipLogicResult, filterResult };
        } else {
          log(`  [Path C] No rules to translate`, 'dim');
          return { skipLogicResult, filterResult: null };
        }
      } catch (pathCError) {
        const errorMsg = pathCError instanceof Error ? pathCError.message : String(pathCError);
        log(`  [Path C] Skip logic extraction failed: ${errorMsg}`, 'yellow');
        eventBus.emitStageFailed(5, STAGE_NAMES[5], errorMsg);
        return { skipLogicResult: null, filterResult: null };
      }
    })();

    // Wait for all three paths
    const [pathAResult, pathBResult, pathCResult] = await Promise.allSettled([pathAPromise, pathBPromise, pathCPromise]);

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
      throw new Error(`Path B (TableGenerator) failed: ${errorMsg}`);
    }
    // Path C failure is graceful — tables pass through without filters

    // Extract results
    const { crosstabResult, groupCount, columnCount } = pathAResult.value;
    const { tableAgentResults } = pathBResult.value;
    const tableAgentTables = tableAgentResults.flatMap(r => r.tables);

    // Path C results (may be null if failed or no survey)
    const pathCValue = pathCResult.status === 'fulfilled' ? pathCResult.value : { skipLogicResult: null, filterResult: null };
    const { skipLogicResult, filterResult } = pathCValue;

    log(`  Path A: ${groupCount} groups, ${columnCount} columns, ${crosstabResult.result.bannerCuts.length} validated`, 'dim');
    log(`  Path B: ${tableAgentTables.length} table definitions`, 'dim');
    if (skipLogicResult) {
      log(`  Path C: ${skipLogicResult.metadata.rulesExtracted} rules → ${filterResult?.metadata.filtersTranslated || 0} filters`, 'dim');
    } else {
      log(`  Path C: skipped (no survey or failed)`, 'dim');
    }
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Sequential: Convert tables → FilterApplicator → VerificationAgent
    // -------------------------------------------------------------------------

    // Convert TableGenerator output to ExtendedTableDefinition[]
    const { toExtendedTable } = await import('../../schemas/verificationAgentSchema');
    let extendedTables: ExtendedTableDefinition[] = tableAgentResults.flatMap(group =>
      group.tables.map(t => toExtendedTable(t, group.questionId))
    );

    // Save TableGenerator output (pre-filter, pre-verification) for debugging
    try {
      const tableGenDir = path.join(outputDir, 'tablegenerator');
      await fs.mkdir(tableGenDir, { recursive: true });
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      await fs.writeFile(
        path.join(tableGenDir, `tablegenerator-output-${timestamp}.json`),
        JSON.stringify({
          tables: extendedTables,
          summary: {
            totalTables: extendedTables.length,
            tableIds: extendedTables.map(t => t.tableId),
          },
        }, null, 2),
        'utf-8'
      );
      log(`  TableGenerator output saved: ${extendedTables.length} tables`, 'dim');
    } catch (saveError) {
      log(`  Failed to save TableGenerator output: ${saveError instanceof Error ? saveError.message : String(saveError)}`, 'yellow');
    }

    // Step 6: FilterApplicator (deterministic, instant)
    logStep(6, totalSteps, 'Applying pre-computed filters...');
    const stepStart6 = Date.now();
    eventBus.emitStageStart(6, STAGE_NAMES[6]);

    const validVariables = new Set<string>(verboseDataMap.map(v => v.column));

    if (filterResult && filterResult.translation.filters.length > 0) {
      const filterApplicatorResult = applyFilters(
        extendedTables,
        filterResult.translation,
        validVariables,
      );

      extendedTables = filterApplicatorResult.tables;
      log(`  Filtered: ${filterApplicatorResult.summary.totalInputTables} → ${filterApplicatorResult.summary.totalOutputTables} tables`, 'green');
      log(`    Pass: ${filterApplicatorResult.summary.passCount}, Filter: ${filterApplicatorResult.summary.filterCount}, Split: ${filterApplicatorResult.summary.splitCount}`, 'dim');
      if (filterApplicatorResult.summary.reviewRequiredCount > 0) {
        log(`    Review required: ${filterApplicatorResult.summary.reviewRequiredCount}`, 'yellow');
      }
    } else {
      log(`  No filters to apply — tables pass through unchanged`, 'dim');
    }

    eventBus.emitStageComplete(6, STAGE_NAMES[6], Date.now() - stepStart6);
    log(`  Duration: ${Date.now() - stepStart6}ms`, 'dim');
    log('', 'reset');

    // Step 7: VerificationAgent (now sequential, sees pre-filtered tables)
    let verifiedTables: ExtendedTableDefinition[];
    logStep(7, totalSteps, 'Running VerificationAgent...');
    const stepStart7 = Date.now();
    eventBus.emitStageStart(7, STAGE_NAMES[7]);

    if (surveyMarkdown) {
      try {
        const verificationResult = await verifyAllTablesParallel(
          extendedTables,
          surveyMarkdown,
          verboseDataMap,
          { outputDir, concurrency }
        );
        verifiedTables = verificationResult.tables;

        log(`  VerificationAgent: ${verifiedTables.length} tables (${verificationResult.metadata.tablesModified} modified)`, 'green');
        eventBus.emitStageComplete(7, STAGE_NAMES[7], Date.now() - stepStart7);
      } catch (verifyError) {
        log(`  VerificationAgent failed: ${verifyError instanceof Error ? verifyError.message : String(verifyError)}`, 'yellow');
        eventBus.emitStageFailed(7, STAGE_NAMES[7], verifyError instanceof Error ? verifyError.message : String(verifyError));
        verifiedTables = extendedTables;
      }
    } else {
      log(`  No survey — using filtered TableGenerator output directly`, 'yellow');
      verifiedTables = extendedTables;
      eventBus.emitStageComplete(7, STAGE_NAMES[7], 0);

      // Create verification folder with passthrough output
      const verificationDir = path.join(outputDir, 'verification');
      await fs.mkdir(verificationDir, { recursive: true });
      await fs.writeFile(
        path.join(verificationDir, 'verification-output-raw.json'),
        JSON.stringify({ tables: verifiedTables }, null, 2),
        'utf-8'
      );
    }

    log(`  Duration: ${Date.now() - stepStart7}ms`, 'dim');
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Post-pass: deterministic formatting normalization
    // -------------------------------------------------------------------------
    log('Running TablePostProcessor...', 'cyan');
    const postPassResult = normalizePostPass(verifiedTables);
    verifiedTables = postPassResult.tables;

    if (postPassResult.stats.totalFixes > 0 || postPassResult.stats.totalWarnings > 0) {
      log(`  Fixes: ${postPassResult.stats.totalFixes}, Warnings: ${postPassResult.stats.totalWarnings}`, 'green');
    } else {
      log(`  No issues found`, 'dim');
    }

    // Log individual actions
    for (const action of postPassResult.actions) {
      const color = action.severity === 'fix' ? 'dim' : 'yellow';
      log(`  [${action.severity}] ${action.tableId}: ${action.rule} — ${action.detail}`, color);
    }

    // Save postpass report
    try {
      const postpassDir = path.join(outputDir, 'postpass');
      await fs.mkdir(postpassDir, { recursive: true });
      await fs.writeFile(
        path.join(postpassDir, 'postpass-report.json'),
        JSON.stringify({
          stats: postPassResult.stats,
          actions: postPassResult.actions,
        }, null, 2),
        'utf-8'
      );
    } catch (postpassSaveError) {
      log(`  Failed to save postpass report: ${postpassSaveError instanceof Error ? postpassSaveError.message : String(postpassSaveError)}`, 'yellow');
    }

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

    // Use sortedTables as our filtered output (filters were already applied before verification)
    const filteredTables = sortedTables;

    // Attach loopDataFrame to each table (infrastructure-only field, not set by agents)
    let loopTableCount = 0;
    const tablesWithLoopFrame: TableWithLoopFrame[] = filteredTables.map(table => {
      let loopDataFrame = '';
      if (loopMappings.length > 0) {
        for (const row of table.rows) {
          const loopIdx = baseNameToLoopIndex.get(row.variable);
          if (loopIdx !== undefined) {
            loopDataFrame = loopMappings[loopIdx].stackedFrameName;
            loopTableCount++;
            break;
          }
        }
      }
      return { ...table, loopDataFrame };
    });
    if (loopTableCount > 0) {
      log(`  Tagged ${loopTableCount} tables with loop data frames`, 'green');
    }

    // -------------------------------------------------------------------------
    // Step 8: R Validation with Retry
    // -------------------------------------------------------------------------
    logStep(8, totalSteps, 'Validating R code per table...');
    const stepStart8 = Date.now();
    eventBus.emitStageStart(8, STAGE_NAMES[8]);

    const cutsSpec = buildCutsSpec(crosstabResult.result);

    // Run per-table R validation with retry loop
    const { validTables, excludedTables: newlyExcluded, validationReport: rValidationReport } = await validateAndFixTables(
      tablesWithLoopFrame,
      cutsSpec.cuts,
      surveyMarkdown || '',
      verboseDataMap,
      {
        outputDir,
        maxRetries: 3,
        dataFilePath: 'dataFile.sav',
        verbose: !quiet,
        loopMappings: loopMappings.length > 0 ? loopMappings : undefined,
      }
    );

    // Calculate pre-excluded vs failed-validation counts
    const preExcludedCount = tablesWithLoopFrame.filter(t => t.exclude).length;
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
    eventBus.emitStageComplete(8, STAGE_NAMES[8], Date.now() - stepStart8);
    log(`  Duration: ${Date.now() - stepStart8}ms`, 'dim');
    log('', 'reset');

    // Combine valid + excluded tables for R script generation
    const allTablesForR = [...validTables, ...newlyExcluded];
    log(`  Tables for R script: ${validTables.length} valid + ${newlyExcluded.length} excluded = ${allTablesForR.length} total`, 'dim');

    // -------------------------------------------------------------------------
    // Step 8.5: Loop Semantics Policy (if loops detected)
    // -------------------------------------------------------------------------
    let loopSemanticsPolicy: LoopSemanticsPolicy | undefined;

    if (loopMappings.length > 0) {
      log('Running LoopSemanticsPolicyAgent...', 'cyan');
      const stepStartLSP = Date.now();

      try {
        loopSemanticsPolicy = await runLoopSemanticsPolicyAgent({
          loopSummary: loopMappings.map(m => ({
            stackedFrameName: m.stackedFrameName,
            iterations: m.iterations,
            variableCount: m.variables.length,
            skeleton: m.skeleton,
          })),
          bannerGroups: cutsSpec.groups.map(g => ({
            groupName: g.groupName,
            columns: g.cuts.map(c => ({ name: c.name, original: c.name })),
          })),
          cuts: cutsSpec.cuts.map(c => ({
            name: c.name,
            groupName: c.groupName,
            rExpression: c.rExpression,
          })),
          deterministicFindings: deterministicFindings || { iterationLinkedVariables: [], evidenceSummary: '' },
          datamapExcerpt: buildDatamapExcerpt(verboseDataMap, cutsSpec.cuts, deterministicFindings),
          outputDir,
        });

        // Save policy artifact
        const loopPolicyDir = path.join(outputDir, 'loop-policy');
        await fs.mkdir(loopPolicyDir, { recursive: true });
        await fs.writeFile(
          path.join(loopPolicyDir, 'loop-semantics-policy.json'),
          JSON.stringify(loopSemanticsPolicy, null, 2),
          'utf-8',
        );

        const entityGroups = loopSemanticsPolicy.bannerGroups.filter(g => g.anchorType === 'entity');
        log(`  LoopSemanticsPolicyAgent: ${entityGroups.length} entity-anchored, ${loopSemanticsPolicy.bannerGroups.length - entityGroups.length} respondent-anchored`, 'green');
        if (loopSemanticsPolicy.humanReviewRequired) {
          log(`  WARNING: Human review required — see loop-policy/loop-semantics-policy.json`, 'yellow');
        }
      } catch (error) {
        const errMsg = error instanceof Error ? error.message : String(error);
        log(`  LoopSemanticsPolicyAgent failed: ${errMsg}`, 'yellow');
        log(`  Proceeding without loop semantics policy (stacked cuts will use original expressions)`, 'yellow');
      }

      log(`  Duration: ${Date.now() - stepStartLSP}ms`, 'dim');
      log('', 'reset');
    }

    // -------------------------------------------------------------------------
    // Step 9: RScriptGeneratorV2
    // -------------------------------------------------------------------------
    logStep(9, totalSteps, 'Generating R script...');
    const stepStart9 = Date.now();
    eventBus.emitStageStart(9, STAGE_NAMES[9]);
    const rDir = path.join(outputDir, 'r');
    await fs.mkdir(rDir, { recursive: true });

    const { script: masterScript, validation: staticValidationReport } = generateRScriptV2WithValidation(
      {
        tables: allTablesForR,
        cuts: cutsSpec.cuts,
        statTestingConfig: effectiveStatConfig,
        significanceThresholds: effectiveStatConfig.thresholds,
        loopMappings: loopMappings.length > 0 ? loopMappings : undefined,
        loopSemanticsPolicy,
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
    eventBus.emitStageComplete(9, STAGE_NAMES[9], Date.now() - stepStart9);
    log(`  Duration: ${Date.now() - stepStart9}ms`, 'dim');
    log('', 'reset');

    // -------------------------------------------------------------------------
    // Step 10: R Execution
    // -------------------------------------------------------------------------
    logStep(10, totalSteps, 'Executing R script...');
    const stepStart10 = Date.now();
    eventBus.emitStageStart(10, STAGE_NAMES[10]);

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

      eventBus.emitStageComplete(10, STAGE_NAMES[10], Date.now() - stepStart10);
      log(`  Duration: ${Date.now() - stepStart10}ms`, 'dim');

      // -------------------------------------------------------------------------
      // Step 11: Excel Export
      // -------------------------------------------------------------------------
      logStep(11, totalSteps, 'Generating Excel workbook...');
      const stepStart11 = Date.now();
      eventBus.emitStageStart(11, STAGE_NAMES[11]);

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
        eventBus.emitStageComplete(11, STAGE_NAMES[11], Date.now() - stepStart11);
        log(`  Duration: ${Date.now() - stepStart11}ms`, 'dim');
      } catch (excelError) {
        log(`  Excel generation failed: ${excelError instanceof Error ? excelError.message : String(excelError)}`, 'red');
        eventBus.emitStageFailed(11, STAGE_NAMES[11], excelError instanceof Error ? excelError.message : String(excelError));
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
        eventBus.emitStageFailed(10, STAGE_NAMES[10], 'R not installed');
      } else {
        log(`  R execution failed:`, 'red');
        eventBus.emitStageFailed(10, STAGE_NAMES[10], errorMsg.substring(0, 200));
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
