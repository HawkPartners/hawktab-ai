/**
 * Shared review completion logic.
 * Extracted from the old /api/pipelines/[pipelineId]/review route so that
 * both the new /api/runs/[runId]/review route and any future callers can
 * reuse it without duplication.
 *
 * After HITL review, completePipeline() runs the FULL remaining pipeline:
 * FilterApplicator → GridAutoSplitter → VerificationAgent → PostProcessor →
 * CutValidation + Retry → R Validation → LoopSemantics → R Script → R Exec → Excel
 */
import { promises as fs } from 'fs';
import * as path from 'path';
import { execFile } from 'child_process';
import { promisify } from 'util';
import { sanitizeRExpression } from '@/lib/r/sanitizeRExpression';
import { processGroup } from '@/agents/CrosstabAgent';
import type { CutValidationErrorContext } from '@/agents/CrosstabAgent';
import { verifyAllTablesParallel } from '@/agents/VerificationAgent';
import { runLoopSemanticsPolicyAgent, buildDatamapExcerpt } from '@/agents/LoopSemanticsPolicyAgent';
import { buildCutsSpec } from '@/lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '@/lib/tables/sortTables';
import { normalizePostPass } from '@/lib/tables/TablePostProcessor';
import { applyFilters } from '@/lib/filters/FilterApplicator';
import { generateRScriptV2WithValidation } from '@/lib/r/RScriptGeneratorV2';
import { validateAndFixTables } from '@/lib/r/ValidationOrchestrator';
import { validateCutExpressions } from '@/lib/r/CutExpressionValidator';
import { ExcelFormatter } from '@/lib/excel/ExcelFormatter';
import { persistSystemError } from '@/lib/errors/ErrorPersistence';
import { AgentMetricsCollector, runWithMetricsCollector, WideEvent } from '@/lib/observability';
import { extractStreamlinedData } from '@/lib/data/extractStreamlinedData';
import { formatDuration } from '@/lib/utils/formatDuration';
import { sendHeartbeat, startHeartbeatInterval } from './heartbeat';
import { toExtendedTable, type ExtendedTableDefinition, type TableWithLoopFrame } from '@/schemas/verificationAgentSchema';
import { createRespondentAnchoredFallbackPolicy, type LoopSemanticsPolicy } from '@/schemas/loopSemanticsPolicySchema';
import type { TableAgentOutput } from '@/schemas/tableAgentSchema';
import type { ValidationResultType, ValidatedGroupType } from '@/schemas/agentOutputSchema';
import type { VerboseDataMapType } from '@/schemas/processingSchemas';
import type { PipelineSummary, FlaggedCrosstabColumn, AgentDataMapItem, PathBResult, PathCResult, CrosstabReviewState } from './types';
import type { LoopGroupMapping } from '@/lib/validation/LoopCollapser';
import type { DeterministicResolverResult } from '@/lib/validation/LoopContextResolver';

const execFileAsync = promisify(execFile);

// -------------------------------------------------------------------------
// Types
// -------------------------------------------------------------------------

import type { CrosstabDecision } from '@/schemas/crosstabDecisionSchema';
export type { CrosstabDecision };


// -------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------

async function updatePipelineSummary(
  outputDir: string,
  updates: Partial<PipelineSummary>
): Promise<void> {
  const summaryPath = path.join(outputDir, 'pipeline-summary.json');
  try {
    const existing = JSON.parse(await fs.readFile(summaryPath, 'utf-8')) as PipelineSummary;
    const updated = { ...existing, ...updates };
    await fs.writeFile(summaryPath, JSON.stringify(updated, null, 2));
  } catch {
    console.warn('[ReviewCompletion] Could not update pipeline summary');
  }
}

async function updateReviewRunStatus(runId: string | undefined, updates: {
  status: string;
  stage?: string;
  progress?: number;
  message?: string;
}): Promise<void> {
  if (!runId) return;
  try {
    const { internal } = await import('../../../convex/_generated/api');
    const { mutateInternal } = await import('@/lib/convex');
    await mutateInternal(internal.runs.updateStatus, {
      runId: runId as import('../../../convex/_generated/dataModel').Id<"runs">,
      status: updates.status as "in_progress" | "pending_review" | "resuming" | "success" | "partial" | "error" | "cancelled",
      ...(updates.stage !== undefined && { stage: updates.stage }),
      ...(updates.progress !== undefined && { progress: updates.progress }),
      ...(updates.message !== undefined && { message: updates.message }),
    });
  } catch (err) {
    console.warn('[ReviewCompletion] Failed to update Convex status:', err);
  }
}

/**
 * Find a pipeline directory by pipelineId across all datasets.
 */
export async function findPipelineDir(pipelineId: string): Promise<{ path: string; dataset: string } | null> {
  // Validate pipelineId — only allow alphanumeric, hyphens, underscores, dots (no path separators)
  if (!/^[a-zA-Z0-9_.-]+$/.test(pipelineId)) {
    return null;
  }

  const outputsDir = path.join(process.cwd(), 'outputs');

  try {
    await fs.access(outputsDir);
  } catch {
    return null;
  }

  const datasetDirs = await fs.readdir(outputsDir);
  for (const dataset of datasetDirs) {
    const datasetPath = path.join(outputsDir, dataset);
    const stat = await fs.stat(datasetPath);
    if (!stat.isDirectory()) continue;

    const pipelinePath = path.join(datasetPath, pipelineId);
    try {
      const pipelineStat = await fs.stat(pipelinePath);
      if (pipelineStat.isDirectory()) {
        return { path: pipelinePath, dataset };
      }
    } catch {
      // Not in this dataset, continue
    }
  }

  return null;
}

// -------------------------------------------------------------------------
// Apply Decisions
// -------------------------------------------------------------------------

/**
 * Apply review decisions to crosstab result.
 * Returns modified ValidationResultType with user's decisions applied.
 */
export async function applyDecisions(
  crosstabResult: ValidationResultType,
  flaggedColumns: FlaggedCrosstabColumn[],
  decisions: CrosstabDecision[],
  agentDataMap: AgentDataMapItem[],
  outputDir: string
): Promise<ValidationResultType> {
  const decisionMap = new Map<string, CrosstabDecision>();
  for (const d of decisions) {
    decisionMap.set(`${d.groupName}::${d.columnName}`, d);
  }

  const flaggedMap = new Map<string, FlaggedCrosstabColumn>();
  for (const f of flaggedColumns) {
    flaggedMap.set(`${f.groupName}::${f.columnName}`, f);
  }

  const modifiedGroups: ValidatedGroupType[] = [];

  for (const group of crosstabResult.bannerCuts) {
    const modifiedColumns = [];

    for (const col of group.columns) {
      const key = `${group.groupName}::${col.name}`;
      const decision = decisionMap.get(key);
      const flagged = flaggedMap.get(key);

      if (decision?.action === 'skip') {
        console.log(`[Review] Skipping column: ${key}`);
        continue;
      }

      if (decision?.action === 'select_alternative' && decision.selectedAlternative !== undefined && flagged) {
        const alt = flagged.alternatives[decision.selectedAlternative];
        if (alt) {
          console.log(`[Review] Using alternative ${decision.selectedAlternative} for: ${key}`);
          modifiedColumns.push({
            ...col,
            adjusted: alt.expression,
            confidence: 1.0,
            reason: `User selected alternative: ${alt.userSummary}`,
            humanReviewRequired: false
          });
          continue;
        }
      }

      if (decision?.action === 'edit' && decision.editedExpression) {
        // Validate user-edited expression before allowing it into R execution
        const sanitizeResult = sanitizeRExpression(decision.editedExpression);
        if (!sanitizeResult.safe) {
          console.warn(`[Review] Rejected unsafe edited expression for ${key}: ${sanitizeResult.error}`);
          // Fall through to keep the original expression instead of using the unsafe one
        } else {
          console.log(`[Review] Using edited expression for: ${key}`);
          modifiedColumns.push({
            ...col,
            adjusted: decision.editedExpression,
            confidence: 1.0,
            reason: 'User edited expression directly',
            humanReviewRequired: false
          });
          continue;
        }
      }

      if (decision?.action === 'provide_hint' && decision.hint && flagged) {
        console.log(`[Review] Re-running with hint for: ${key}`);
        try {
          const rerunResult = await processGroup(
            agentDataMap,
            {
              groupName: group.groupName,
              columns: [{ name: col.name, original: flagged.original }]
            },
            { hint: decision.hint, outputDir }
          );

          if (rerunResult.columns.length > 0) {
            const rerunCol = rerunResult.columns[0];
            if (rerunCol.confidence > 0.9) {
              console.log(`[Review] Re-run successful with confidence ${rerunCol.confidence} - auto-approving`);
              modifiedColumns.push({
                ...rerunCol,
                confidence: 1.0,
                reasoning: `Re-run with hint "${decision.hint}": ${rerunCol.reasoning}`,
              });
            } else {
              console.log(`[Review] Re-run had confidence ${rerunCol.confidence} - using anyway`);
              modifiedColumns.push({
                ...rerunCol,
                reasoning: `Re-run with hint "${decision.hint}": ${rerunCol.reasoning}`,
              });
            }
            continue;
          }
        } catch (rerunError) {
          console.error(`[Review] Re-run failed for ${key}:`, rerunError);
          // Fall through to approve as-is
        }
      }

      // Default: approve as-is
      if (decision?.action === 'approve' || !decision) {
        modifiedColumns.push({
          ...col,
          confidence: decision ? 1.0 : col.confidence,
          humanReviewRequired: false
        });
      }
    }

    if (modifiedColumns.length > 0) {
      modifiedGroups.push({
        groupName: group.groupName,
        columns: modifiedColumns
      });
    }
  }

  return { bannerCuts: modifiedGroups };
}

// -------------------------------------------------------------------------
// Complete Pipeline (Full Post-Review Pipeline)
// -------------------------------------------------------------------------

export interface CompletePipelineResult {
  success: boolean;
  status: 'success' | 'partial' | 'error';
  message: string;
  outputDir: string;
  tableCount?: number;
  cutCount?: number;
  bannerGroups?: number;
  durationMs?: number;
}

/**
 * Complete the pipeline after review decisions are applied and Path B is ready.
 * Runs the FULL remaining pipeline: FilterApplicator → GridAutoSplitter →
 * VerificationAgent → PostProcessor → CutValidation → R Validation →
 * LoopSemantics → R Script → R Execution → Excel Export.
 */
export async function completePipeline(
  outputDir: string,
  pipelineId: string,
  modifiedCrosstabResult: ValidationResultType,
  pathBResult: PathBResult,
  reviewState: CrosstabReviewState,
  _decisions: CrosstabDecision[],
  runId?: string,
): Promise<CompletePipelineResult> {
  // For recovered dirs (outputs/_recovered/{runId}), fall back to pipelineId for observability
  const rawDatasetName = path.basename(path.dirname(outputDir));
  const datasetName = rawDatasetName === '_recovered' ? pipelineId : rawDatasetName;
  const metricsCollector = new AgentMetricsCollector();
  const wideEvent = new WideEvent({
    pipelineId,
    dataset: datasetName,
    userId: runId || pipelineId,
  });
  metricsCollector.bindWideEvent(wideEvent);

  return runWithMetricsCollector(metricsCollector, async () => {
  const stopHeartbeat = runId ? startHeartbeatInterval(runId) : () => {};
  try {
    const { tableAgentResults } = pathBResult;
    const verboseDataMap = reviewState.verboseDataMap as VerboseDataMapType[];
    const surveyMarkdown = reviewState.surveyMarkdown;
    const loopMappings: LoopGroupMapping[] = reviewState.loopMappings || [];
    const baseNameToLoopIndex = new Map<string, number>(
      Object.entries(reviewState.baseNameToLoopIndex || {}).map(([k, v]) => [k, v])
    );
    const deterministicFindings: DeterministicResolverResult | undefined = reviewState.deterministicFindings;
    const wizardConfig = reviewState.wizardConfig;
    console.log(`[ReviewCompletion] wizardConfig restored: present=${wizardConfig !== undefined}, displayMode=${wizardConfig?.displayMode ?? 'undefined'}, separateWorkbooks=${wizardConfig?.separateWorkbooks ?? 'undefined'}`);
    const loopStatTestingMode = reviewState.loopStatTestingMode;

    // Read Path C results from disk
    let pathCResult: PathCResult | null = reviewState.pathCResult;
    if (!pathCResult) {
      try {
        const pathCResultPath = path.join(outputDir, 'path-c-result.json');
        pathCResult = JSON.parse(await fs.readFile(pathCResultPath, 'utf-8'));
        console.log('[ReviewCompletion] Path C result loaded from disk');
      } catch {
        console.log('[ReviewCompletion] No Path C result found — continuing without filters');
      }
    }

    // -------------------------------------------------------------------------
    // Convert tableAgentResults → ExtendedTableDefinition[]
    // -------------------------------------------------------------------------
    let extendedTables: ExtendedTableDefinition[] = tableAgentResults.flatMap(group =>
      group.tables.map(t => toExtendedTable(t, group.questionId))
    );
    console.log(`[ReviewCompletion] ${extendedTables.length} tables from TableGenerator`);

    // -------------------------------------------------------------------------
    // FilterApplicator (apply Path C filters)
    // -------------------------------------------------------------------------
    if (pathCResult?.filterResult && pathCResult.filterResult.translation.filters.length > 0) {
      await updateReviewRunStatus(runId, { status: 'resuming', stage: 'filtering', progress: 55, message: 'Applying filters...' });
      console.log('[ReviewCompletion] Applying skip logic filters...');
      const validVariables = new Set<string>(verboseDataMap.map(v => v.column));
      const filterApplicatorResult = applyFilters(extendedTables, pathCResult.filterResult.translation, validVariables);
      const beforeCount = extendedTables.length;
      extendedTables = filterApplicatorResult.tables;
      console.log(`[ReviewCompletion] FilterApplicator: ${beforeCount} → ${extendedTables.length} tables`);
    }

    // -------------------------------------------------------------------------
    // GridAutoSplitter
    // -------------------------------------------------------------------------
    await updateReviewRunStatus(runId, { status: 'resuming', stage: 'splitting', progress: 57, message: 'Splitting oversized grids...' });
    console.log('[ReviewCompletion] Running GridAutoSplitter...');
    const { splitOversizedGrids } = await import('@/lib/tables/GridAutoSplitter');
    const gridSplitResult = splitOversizedGrids(extendedTables, { verboseDataMap });
    if (gridSplitResult.actions.length > 0) {
      extendedTables = gridSplitResult.tables;
      console.log(`[ReviewCompletion] GridAutoSplitter: split ${gridSplitResult.summary.tablesSplit} tables`);
      await fs.writeFile(
        path.join(outputDir, 'gridsplitter-report.json'),
        JSON.stringify({ actions: gridSplitResult.actions, summary: gridSplitResult.summary }, null, 2)
      );
    }

    // -------------------------------------------------------------------------
    // VerificationAgent
    // -------------------------------------------------------------------------
    await updateReviewRunStatus(runId, { status: 'resuming', stage: 'verification', progress: 58, message: 'Verifying tables...' });
    if (surveyMarkdown) {
      console.log('[ReviewCompletion] Running VerificationAgent (parallel, concurrency: 3)...');
      try {
        const verificationResult = await verifyAllTablesParallel(
          extendedTables,
          surveyMarkdown,
          verboseDataMap,
          { outputDir, concurrency: 3 }
        );
        extendedTables = verificationResult.tables;
        console.log(`[ReviewCompletion] VerificationAgent: ${verificationResult.tables.length} verified tables`);
      } catch (verifyError) {
        console.warn(`[ReviewCompletion] VerificationAgent failed — using unverified tables: ${verifyError instanceof Error ? verifyError.message : String(verifyError)}`);
        try {
          await persistSystemError({
            outputDir,
            dataset: path.basename(path.dirname(outputDir)),
            pipelineId,
            stageNumber: 7,
            stageName: 'VerificationAgent',
            severity: 'warning',
            actionTaken: 'continued',
            error: verifyError,
            meta: { action: 'verification_failed_passthrough' },
          });
        } catch { /* ignore persistence failure */ }
      }
    }

    // -------------------------------------------------------------------------
    // TablePostProcessor
    // -------------------------------------------------------------------------
    await updateReviewRunStatus(runId, { status: 'resuming', stage: 'post_processing', progress: 69, message: 'Running post-processor...' });
    console.log('[ReviewCompletion] Running TablePostProcessor...');
    const postPassResult = normalizePostPass(extendedTables);
    extendedTables = postPassResult.tables;
    console.log(`[ReviewCompletion] PostProcessor: ${postPassResult.stats.totalFixes} fixes`);

    const postpassDir = path.join(outputDir, 'postpass');
    await fs.mkdir(postpassDir, { recursive: true });
    await fs.writeFile(
      path.join(postpassDir, 'postpass-report.json'),
      JSON.stringify({ actions: postPassResult.actions, stats: postPassResult.stats }, null, 2)
    );

    // Sort tables
    const sortingMetadata = getSortingMetadata(extendedTables);
    const sortedTables = sortTables(extendedTables);
    console.log(`[ReviewCompletion] Sorted: ${sortedTables.length} tables (screeners: ${sortingMetadata.screenerCount})`);

    // -------------------------------------------------------------------------
    // Cut Expression Validation + Retry
    // -------------------------------------------------------------------------
    await updateReviewRunStatus(runId, { status: 'resuming', stage: 'validating_cuts', progress: 70, message: 'Validating cut expressions...' });
    console.log('[ReviewCompletion] Validating cut expressions...');
    let validatedCrosstabResult = modifiedCrosstabResult;

    // Copy SPSS file for validation
    const inputsDir = path.join(outputDir, 'inputs');
    try {
      const inputFiles = await fs.readdir(inputsDir);
      const spssFile = inputFiles.find(f => f.endsWith('.sav'));
      if (spssFile) {
        await fs.copyFile(path.join(inputsDir, spssFile), path.join(outputDir, 'dataFile.sav'));
      }
    } catch {
      console.warn('[ReviewCompletion] Could not copy SPSS file');
    }

    try {
      const MAX_CUT_RETRIES = 2;
      let cutReport = await validateCutExpressions(validatedCrosstabResult, outputDir, 'dataFile.sav');
      console.log(`[ReviewCompletion] Cut validation: ${cutReport.passed}/${cutReport.totalCuts} passed`);

      for (let retryAttempt = 1; retryAttempt <= MAX_CUT_RETRIES && cutReport.failed > 0; retryAttempt++) {
        console.log(`[ReviewCompletion] Cut retry ${retryAttempt}/${MAX_CUT_RETRIES}...`);
        const updatedBannerCuts = [...validatedCrosstabResult.bannerCuts];

        for (const [failedGroupName, failedCuts] of cutReport.failedByGroup) {
          const failedExpressions = failedCuts.map(f => {
            const varMatch = f.rExpression.match(/\b([A-Za-z][A-Za-z0-9_.]*)\b/);
            const primaryVar = varMatch?.[1] || '';
            const verbose = verboseDataMap.find(v => v.column === primaryVar);
            return {
              cutName: f.cutName,
              rExpression: f.rExpression,
              error: f.error || 'Unknown error',
              variableType: verbose?.normalizedType || undefined,
            };
          });

          const rValidationErrors: CutValidationErrorContext = {
            failedAttempt: retryAttempt,
            maxAttempts: MAX_CUT_RETRIES,
            failedExpressions,
          };

          const groupIdx = updatedBannerCuts.findIndex(g => g.groupName === failedGroupName);
          if (groupIdx === -1) continue;
          const group = updatedBannerCuts[groupIdx];

          try {
            const retryResult = await processGroup(
              reviewState.agentDataMap,
              { groupName: group.groupName, columns: group.columns.map(c => ({ name: c.name, original: c.name })) },
              { outputDir, rValidationErrors }
            );
            updatedBannerCuts[groupIdx] = retryResult;
          } catch (retryErr) {
            console.warn(`[ReviewCompletion] Cut retry failed for ${failedGroupName}:`, retryErr);
          }
        }

        validatedCrosstabResult = { bannerCuts: updatedBannerCuts };
        cutReport = await validateCutExpressions(validatedCrosstabResult, outputDir, 'dataFile.sav');
        console.log(`[ReviewCompletion] Cut re-validation: ${cutReport.passed}/${cutReport.totalCuts} passed`);
      }
    } catch (cutError) {
      console.warn('[ReviewCompletion] Cut validation infrastructure failed (non-fatal):', cutError);
      try {
        await persistSystemError({
          outputDir,
          dataset: path.basename(path.dirname(outputDir)),
          pipelineId,
          stageNumber: 8,
          stageName: 'CutValidation',
          severity: 'warning',
          actionTaken: 'continued',
          error: cutError,
          meta: { phase: 'cut_validation_infrastructure' },
        });
      } catch { /* ignore */ }
    }

    const cutsSpec = buildCutsSpec(validatedCrosstabResult);

    // -------------------------------------------------------------------------
    // R Validation (per-table)
    // -------------------------------------------------------------------------
    await updateReviewRunStatus(runId, { status: 'resuming', stage: 'validating_r', progress: 75, message: 'Validating R code per table...' });
    console.log('[ReviewCompletion] Validating R code per table...');

    // Tag tables with loopDataFrame
    let loopTableCount = 0;
    const tablesWithLoopFrame: TableWithLoopFrame[] = sortedTables.map(table => {
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
      console.log(`[ReviewCompletion] Tagged ${loopTableCount} tables with loopDataFrame`);
    }

    const { validTables, excludedTables: newlyExcluded, validationReport: rValidationReport } = await validateAndFixTables(
      tablesWithLoopFrame,
      cutsSpec.cuts,
      surveyMarkdown || '',
      verboseDataMap,
      {
        outputDir,
        maxRetries: 8,
        dataFilePath: 'dataFile.sav',
        verbose: true,
        loopMappings: loopMappings.length > 0 ? loopMappings : undefined,
      }
    );
    console.log(`[ReviewCompletion] R Validation: ${rValidationReport.passedFirstTime} passed, ${rValidationReport.fixedAfterRetry} fixed, ${rValidationReport.excluded} excluded`);

    const allTablesForR = [...validTables, ...newlyExcluded];

    // -------------------------------------------------------------------------
    // LoopSemanticsPolicyAgent (if loops)
    // -------------------------------------------------------------------------
    let loopSemanticsPolicy: LoopSemanticsPolicy | undefined;

    if (loopMappings.length > 0) {
      await updateReviewRunStatus(runId, { status: 'resuming', stage: 'loop_semantics', progress: 78, message: 'Classifying loop semantics...' });
      console.log('[ReviewCompletion] Running LoopSemanticsPolicyAgent...');
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
          loopMappings,
          outputDir,
        });
        console.log(`[ReviewCompletion] LoopSemantics: ${loopSemanticsPolicy.bannerGroups.length} groups classified`);
      } catch (lspError) {
        const fallbackReason = lspError instanceof Error ? lspError.message : String(lspError);
        console.warn(`[ReviewCompletion] LoopSemantics failed — using fallback: ${fallbackReason}`);
        loopSemanticsPolicy = createRespondentAnchoredFallbackPolicy(
          cutsSpec.groups.map(g => g.groupName),
          fallbackReason,
        );
        try {
          await persistSystemError({
            outputDir,
            dataset: path.basename(path.dirname(outputDir)),
            pipelineId,
            stageNumber: 8,
            stageName: 'LoopSemanticsPolicyAgent',
            severity: 'warning',
            actionTaken: 'continued',
            error: lspError,
            meta: { action: 'fallback_to_respondent_anchored' },
          });
        } catch { /* ignore */ }
      }
    }

    // -------------------------------------------------------------------------
    // R Script Generation
    // -------------------------------------------------------------------------
    await updateReviewRunStatus(runId, { status: 'resuming', stage: 'generating_r', progress: 80, message: 'Generating R script...' });
    const rDir = path.join(outputDir, 'r');
    await fs.mkdir(rDir, { recursive: true });

    const rScriptInput: import('@/lib/r/RScriptGeneratorV2').RScriptV2Input = {
      tables: allTablesForR,
      cuts: cutsSpec.cuts,
      cutGroups: cutsSpec.groups,
      loopStatTestingMode,
      ...(loopMappings.length > 0 && { loopMappings }),
      ...(loopSemanticsPolicy && { loopSemanticsPolicy }),
      ...(wizardConfig?.weightVariable && { weightVariable: wizardConfig.weightVariable }),
      ...(wizardConfig?.statTesting && {
        statTestingConfig: {
          thresholds: wizardConfig.statTesting.thresholds.map(t => (100 - t) / 100),
          proportionTest: 'unpooled_z' as const,
          meanTest: 'welch_t' as const,
          minBase: wizardConfig.statTesting.minBase,
        },
        significanceThresholds: wizardConfig.statTesting.thresholds.map(t => (100 - t) / 100),
      }),
    };

    const { script: masterScript, validation: validationReport } = generateRScriptV2WithValidation(
      rScriptInput,
      { sessionId: pipelineId, outputDir: 'results' }
    );

    const masterPath = path.join(rDir, 'master.R');
    await fs.writeFile(masterPath, masterScript, 'utf-8');
    console.log(`[ReviewCompletion] Generated R script (${Math.round(masterScript.length / 1024)} KB)`);

    if (validationReport.invalidTables > 0 || validationReport.warnings.length > 0) {
      await fs.writeFile(
        path.join(rDir, 'validation-report.json'),
        JSON.stringify(validationReport, null, 2)
      );
    }

    // -------------------------------------------------------------------------
    // R Execution
    // -------------------------------------------------------------------------
    await updateReviewRunStatus(runId, { status: 'resuming', stage: 'executing_r', progress: 85, message: 'Executing R script...' });
    const resultsDir = path.join(outputDir, 'results');
    await fs.mkdir(resultsDir, { recursive: true });

    let rCommand = 'Rscript';
    const rPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
    for (const rPath of rPaths) {
      try {
        await execFileAsync(rPath, ['--version'], { timeout: 1000 });
        rCommand = rPath;
        break;
      } catch {
        // Try next
      }
    }

    let rExecutionSuccess = false;
    let excelGenerated = false;

    try {
      await execFileAsync(
        rCommand,
        [masterPath],
        { cwd: outputDir, maxBuffer: 50 * 1024 * 1024, timeout: 120000 }
      );

      const resultFiles = await fs.readdir(resultsDir);
      const weightVariable = wizardConfig?.weightVariable;

      // Check for weighted dual-output first (tables-weighted.json + tables-unweighted.json)
      if (weightVariable && resultFiles.includes('tables-weighted.json') && resultFiles.includes('tables-unweighted.json')) {
        console.log('[ReviewCompletion] Found dual weighted/unweighted output');
        rExecutionSuccess = true;

        // Streamlined data from weighted output
        try {
          const wContent = await fs.readFile(path.join(resultsDir, 'tables-weighted.json'), 'utf-8');
          const streamlined = extractStreamlinedData(JSON.parse(wContent));
          await fs.writeFile(path.join(resultsDir, 'data-streamlined.json'), JSON.stringify(streamlined, null, 2), 'utf-8');
        } catch { /* non-fatal */ }

        // ---------------------------------------------------------------
        // Dual Excel Export (weighted + unweighted)
        // ---------------------------------------------------------------
        await updateReviewRunStatus(runId, { status: 'resuming', stage: 'writing_outputs', progress: 95, message: 'Generating weighted & unweighted Excel workbooks...' });
        try {
          if (wizardConfig?.theme) {
            const { setActiveTheme } = await import('@/lib/excel/styles');
            setActiveTheme(wizardConfig.theme);
          }
          const fmtOpts = {
            format: wizardConfig?.format ?? 'joe',
            displayMode: wizardConfig?.displayMode ?? 'frequency',
            separateWorkbooks: wizardConfig?.separateWorkbooks ?? false,
            hideExcludedTables: wizardConfig?.hideExcludedTables,
          };
          console.log('[ReviewCompletion] Dual-output fmtOpts:', JSON.stringify(fmtOpts));
          // Weighted workbook
          const wFormatter = new ExcelFormatter(fmtOpts);
          await wFormatter.formatFromFile(path.join(resultsDir, 'tables-weighted.json'));
          await wFormatter.saveToFile(path.join(resultsDir, 'crosstabs-weighted.xlsx'));
          if (wFormatter.hasSecondWorkbook()) {
            await wFormatter.saveSecondWorkbook(path.join(resultsDir, 'crosstabs-weighted-counts.xlsx'));
          }
          // Unweighted workbook
          const uwFormatter = new ExcelFormatter(fmtOpts);
          await uwFormatter.formatFromFile(path.join(resultsDir, 'tables-unweighted.json'));
          await uwFormatter.saveToFile(path.join(resultsDir, 'crosstabs-unweighted.xlsx'));
          if (uwFormatter.hasSecondWorkbook()) {
            await uwFormatter.saveSecondWorkbook(path.join(resultsDir, 'crosstabs-unweighted-counts.xlsx'));
          }
          excelGenerated = true;
          console.log('[ReviewCompletion] Generated dual Excel: crosstabs-weighted.xlsx + crosstabs-unweighted.xlsx');
        } catch (excelError) {
          console.error('[ReviewCompletion] Dual Excel generation failed:', excelError);
          try {
            await persistSystemError({
              outputDir,
              dataset: datasetName,
              pipelineId,
              stageNumber: 11,
              stageName: 'ExcelFormatter',
              severity: 'error',
              actionTaken: 'continued',
              error: excelError,
              meta: { phase: 'dual_excel_generation' },
            });
          } catch { /* ignore */ }
        }
      } else if (resultFiles.includes('tables.json')) {
        // Single-output path (non-weighted or weighted files missing)
        console.log('[ReviewCompletion] R execution successful');
        rExecutionSuccess = true;

        const tablesJsonPath = path.join(resultsDir, 'tables.json');

        // Extract streamlined data
        try {
          const tablesJsonContent = await fs.readFile(tablesJsonPath, 'utf-8');
          const tablesJsonData = JSON.parse(tablesJsonContent);
          const streamlinedData = extractStreamlinedData(tablesJsonData);
          await fs.writeFile(path.join(resultsDir, 'data-streamlined.json'), JSON.stringify(streamlinedData, null, 2), 'utf-8');
        } catch (err) {
          console.warn('[ReviewCompletion] Could not generate streamlined data:', err);
        }

        // ---------------------------------------------------------------
        // Excel Export
        // ---------------------------------------------------------------
        await updateReviewRunStatus(runId, { status: 'resuming', stage: 'writing_outputs', progress: 95, message: 'Generating Excel workbook...' });
        const excelPath = path.join(resultsDir, 'crosstabs.xlsx');
        try {
          if (wizardConfig?.theme) {
            const { setActiveTheme } = await import('@/lib/excel/styles');
            setActiveTheme(wizardConfig.theme);
          }
          const fmtOpts = {
            format: wizardConfig?.format ?? 'joe',
            displayMode: wizardConfig?.displayMode ?? 'frequency',
            separateWorkbooks: wizardConfig?.separateWorkbooks ?? false,
            hideExcludedTables: wizardConfig?.hideExcludedTables,
          };
          console.log('[ReviewCompletion] Single-output fmtOpts:', JSON.stringify(fmtOpts));
          const formatter = new ExcelFormatter(fmtOpts);
          await formatter.formatFromFile(tablesJsonPath);
          await formatter.saveToFile(excelPath);
          if (formatter.hasSecondWorkbook()) {
            await formatter.saveSecondWorkbook(path.join(resultsDir, 'crosstabs-counts.xlsx'));
            console.log('[ReviewCompletion] Generated crosstabs-counts.xlsx');
          }
          excelGenerated = true;
          console.log('[ReviewCompletion] Excel generated successfully');
        } catch (excelError) {
          console.error('[ReviewCompletion] Excel generation failed:', excelError);
          try {
            await persistSystemError({
              outputDir,
              dataset: datasetName,
              pipelineId,
              stageNumber: 11,
              stageName: 'ExcelFormatter',
              severity: 'error',
              actionTaken: 'continued',
              error: excelError,
              meta: { phase: 'excel_generation' },
            });
          } catch { /* ignore */ }
        }
      }
    } catch (rError) {
      const errorMsg = rError instanceof Error ? rError.message : String(rError);
      console.error('[ReviewCompletion] R execution failed:', errorMsg.substring(0, 200));
      try {
        await persistSystemError({
          outputDir,
          dataset: path.basename(path.dirname(outputDir)),
          pipelineId,
          stageNumber: 10,
          stageName: 'RExecution',
          severity: 'error',
          actionTaken: 'continued',
          error: rError,
          meta: { phase: 'r_script_execution' },
        });
      } catch { /* ignore */ }
    }

    // Cleanup temp SPSS
    try {
      await fs.unlink(path.join(outputDir, 'dataFile.sav'));
    } catch { /* May not exist */ }

    // Calculate duration
    const completionTime = new Date();
    let totalDurationMs = 0;
    try {
      const summaryPath = path.join(outputDir, 'pipeline-summary.json');
      const existingSummary = JSON.parse(await fs.readFile(summaryPath, 'utf-8')) as PipelineSummary;
      if (existingSummary.timestamp) {
        const startTime = new Date(existingSummary.timestamp).getTime();
        totalDurationMs = completionTime.getTime() - startTime;
      }
    } catch {
      console.warn('[ReviewCompletion] Could not read summary for duration calculation');
    }

    // Update pipeline summary
    const finalStatus = excelGenerated ? 'success' : (rExecutionSuccess ? 'partial' : 'error');
    await updatePipelineSummary(outputDir, {
      status: finalStatus,
      currentStage: undefined,
      duration: totalDurationMs > 0 ? {
        ms: totalDurationMs,
        formatted: formatDuration(totalDurationMs)
      } : undefined,
      review: {
        flaggedColumnCount: reviewState.flaggedColumns.length,
        reviewUrl: `/projects/${pipelineId}/review`,
      },
      outputs: {
        variables: verboseDataMap.length,
        tableGeneratorTables: tableAgentResults.flatMap((r: TableAgentOutput) => r.tables).length,
        verifiedTables: sortedTables.length,
        validatedTables: validTables.length,
        excludedTables: newlyExcluded.length,
        totalTablesInR: allTablesForR.length,
        cuts: cutsSpec.cuts.length,
        bannerGroups: modifiedCrosstabResult.bannerCuts.length,
        sorting: {
          screeners: sortingMetadata.screenerCount,
          main: sortingMetadata.mainCount,
          other: sortingMetadata.otherCount
        },
        rValidation: {
          passedFirstTime: rValidationReport.passedFirstTime,
          fixedAfterRetry: rValidationReport.fixedAfterRetry,
          excluded: rValidationReport.excluded,
          durationMs: rValidationReport.durationMs,
        }
      }
    });

    console.log(`[ReviewCompletion] Pipeline completed in ${formatDuration(totalDurationMs)}`);

    metricsCollector.unbindWideEvent();
    wideEvent.set('tableCount', allTablesForR.length);
    wideEvent.finish(finalStatus === 'success' ? 'success' : 'partial');

    return {
      success: true,
      status: finalStatus as 'success' | 'partial' | 'error',
      message: excelGenerated ? 'Pipeline completed successfully' : (rExecutionSuccess ? 'R complete but Excel failed' : 'R execution failed'),
      outputDir,
      tableCount: allTablesForR.length,
      cutCount: cutsSpec.cuts.length,
      bannerGroups: modifiedCrosstabResult.bannerCuts.length,
      durationMs: totalDurationMs,
    };
  } catch (error) {
    console.error('[ReviewCompletion] Background completion failed:', error);
    metricsCollector.unbindWideEvent();
    wideEvent.finish('error', error instanceof Error ? error.message : 'Background completion failed');
    try {
      await persistSystemError({
        outputDir,
        dataset: datasetName,
        pipelineId,
        stageNumber: 0,
        stageName: 'ReviewCompletion',
        severity: 'fatal',
        actionTaken: 'failed_pipeline',
        error,
        meta: { phase: 'complete_pipeline' },
      });
    } catch { /* ignore */ }
    await updatePipelineSummary(outputDir, {
      status: 'error',
      error: error instanceof Error ? error.message : 'Background completion failed'
    });

    return {
      success: false,
      status: 'error',
      message: error instanceof Error ? error.message : 'Background completion failed',
      outputDir,
    };
  } finally {
    stopHeartbeat();
  }
  }); // end runWithMetricsCollector
}

/**
 * Wait for Path B to complete (polling disk) and then finish the pipeline.
 */
export async function waitAndCompletePipeline(
  outputDir: string,
  pipelineId: string,
  modifiedCrosstabResult: ValidationResultType,
  reviewState: CrosstabReviewState,
  decisions: CrosstabDecision[],
  runId?: string,
): Promise<CompletePipelineResult> {
  const pathBResultPath = path.join(outputDir, 'path-b-result.json');
  const pathBStatusPath = path.join(outputDir, 'path-b-status.json');

  const maxWaitMs = 1800000; // 30 minutes
  const pollIntervalMs = 5000;
  const heartbeatIntervalMs = 30_000;
  const startTime = Date.now();
  let lastHeartbeatTime = 0;

  console.log(`[ReviewCompletion] Waiting for Path B to complete (up to 30 min)...`);

  while (Date.now() - startTime < maxWaitMs) {
    // Emit heartbeat every ~30s during polling (non-fatal)
    if (runId && Date.now() - lastHeartbeatTime >= heartbeatIntervalMs) {
      sendHeartbeat(runId);
      lastHeartbeatTime = Date.now();
    }

    try {
      const pathBResult = JSON.parse(await fs.readFile(pathBResultPath, 'utf-8'));
      console.log('[ReviewCompletion] Path B completed - starting pipeline completion');
      return await completePipeline(outputDir, pipelineId, modifiedCrosstabResult, pathBResult, reviewState, decisions, runId);
    } catch { /* not ready yet */ }

    try {
      const statusData = JSON.parse(await fs.readFile(pathBStatusPath, 'utf-8'));
      if (statusData.status === 'error') {
        console.error('[ReviewCompletion] Path B failed:', statusData.error);
        await updatePipelineSummary(outputDir, {
          status: 'error',
          error: `Table processing failed: ${statusData.error}`
        });
        return {
          success: false,
          status: 'error',
          message: `Table processing failed: ${statusData.error}`,
          outputDir,
        };
      }
    } catch { /* status file may not exist yet */ }

    await new Promise(r => setTimeout(r, pollIntervalMs));
  }

  // Timed out
  console.error('[ReviewCompletion] Timed out waiting for Path B (30 min)');
  await updatePipelineSummary(outputDir, {
    status: 'error',
    error: 'Timed out waiting for table processing to complete'
  });

  return {
    success: false,
    status: 'error',
    message: 'Timed out waiting for table processing to complete',
    outputDir,
  };
}
