#!/usr/bin/env npx tsx
/**
 * Pre-Verification Pipeline Test Script
 *
 * Purpose: End-to-end test through FilterApplicator, stopping BEFORE VerificationAgent.
 * Tests the full data path: .sav → DataMap → TableGenerator → SkipLogic → FilterTranslator → FilterApplicator
 *
 * Usage:
 *   npx tsx scripts/test-pre-verification.ts [dataset-folder]
 *
 * Examples:
 *   npx tsx scripts/test-pre-verification.ts
 *   # Uses default dataset (data/leqvio-monotherapy-demand-NOV217)
 *
 *   npx tsx scripts/test-pre-verification.ts data/stacked-data-example
 *   # Uses specified dataset folder
 *
 * Output:
 *   outputs/<dataset>/pre-verification-test-<timestamp>/
 *   - skiplogic/ (SkipLogicAgent outputs + scratchpad)
 *   - filtertranslator/ (FilterTranslatorAgent outputs + scratchpad)
 *   - tables-before-filter.json (tables from TableGenerator)
 *   - tables-after-filter.json (tables after FilterApplicator)
 *   - summary.json (full test summary)
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { extractSkipLogic } from '../src/agents/SkipLogicAgent';
import { translateSkipRules } from '../src/agents/FilterTranslatorAgent';
import { applyFilters } from '../src/lib/filters/FilterApplicator';
import { processSurvey } from '../src/lib/processors/SurveyProcessor';
import { validate } from '../src/lib/validation/ValidationRunner';
import { groupDataMap } from '../src/lib/tables/DataMapGrouper';
import { generateTables, convertToLegacyFormat } from '../src/lib/tables/TableGenerator';
import { toExtendedTable } from '../src/schemas/verificationAgentSchema';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';
import type { ExtendedTableDefinition } from '../src/schemas/verificationAgentSchema';

// =============================================================================
// Configuration
// =============================================================================

const DEFAULT_DATASET = 'data/leqvio-monotherapy-demand-NOV217';

const colors = {
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

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const startTime = Date.now();

  // Resolve dataset folder
  const datasetArg = process.argv[2] || DEFAULT_DATASET;
  const datasetFolder = path.isAbsolute(datasetArg)
    ? datasetArg
    : path.join(process.cwd(), datasetArg);
  const datasetName = path.basename(datasetFolder);

  log('='.repeat(70), 'magenta');
  log('  Pre-Verification Pipeline Test', 'bright');
  log('  (Everything up to FilterApplicator, before VerificationAgent)', 'dim');
  log('='.repeat(70), 'magenta');
  log(`Dataset: ${datasetName}`, 'blue');
  log('', 'reset');

  // Create output directory
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputDir = path.join(process.cwd(), 'outputs', datasetName, `pre-verification-test-${timestamp}`);
  await fs.mkdir(outputDir, { recursive: true });
  log(`Output: ${path.relative(process.cwd(), outputDir)}`, 'blue');
  log('', 'reset');

  // =========================================================================
  // Step 1: Load and validate .sav file → verbose datamap
  // =========================================================================
  log('Step 1: Loading .sav file → verbose datamap...', 'cyan');
  const step1Start = Date.now();

  const inputsDir = path.join(datasetFolder, 'inputs');
  const spssFiles = (await fs.readdir(inputsDir)).filter(f => f.endsWith('.sav'));
  if (spssFiles.length === 0) {
    log('  No .sav file found', 'red');
    process.exit(1);
  }
  const spssPath = path.join(inputsDir, spssFiles[0]);
  log(`  File: ${spssFiles[0]}`, 'dim');

  const validationResult = await validate({ spssPath, outputDir });
  const verboseDataMap = validationResult.processingResult!.verbose as VerboseDataMapType[];
  const step1Duration = Date.now() - step1Start;

  log(`  Loaded ${verboseDataMap.length} variables in ${(step1Duration / 1000).toFixed(1)}s`, 'green');
  log('', 'reset');

  // =========================================================================
  // Step 2: Find and process survey file
  // =========================================================================
  log('Step 2: Finding and processing survey...', 'cyan');
  const step2Start = Date.now();

  let surveyMarkdown: string | null = null;
  try {
    const files = await fs.readdir(inputsDir);
    const surveyFiles = files.filter(f =>
      (f.endsWith('.docx') || f.endsWith('.doc') || f.endsWith('.pdf')) &&
      f.toLowerCase().includes('survey')
    );
    let surveyFile: string | null = null;
    if (surveyFiles.length > 0) {
      surveyFile = path.join(inputsDir, surveyFiles[0]);
      log(`  Found: ${surveyFiles[0]}`, 'green');
    } else {
      const anyDoc = files.filter(f => f.endsWith('.docx') || f.endsWith('.doc'));
      if (anyDoc.length > 0) {
        surveyFile = path.join(inputsDir, anyDoc[0]);
        log(`  Found (fallback): ${anyDoc[0]}`, 'yellow');
      }
    }

    if (surveyFile) {
      const surveyResult = await processSurvey(surveyFile, outputDir);
      if (surveyResult.markdown) {
        surveyMarkdown = surveyResult.markdown;
        log(`  Processed: ${surveyMarkdown.length} characters`, 'green');
      } else {
        log(`  Survey processing failed: ${surveyResult.warnings.join(', ')}`, 'red');
      }
    } else {
      log('  No survey file found', 'yellow');
    }
  } catch {
    log(`  Could not read inputs directory: ${inputsDir}`, 'red');
  }

  const step2Duration = Date.now() - step2Start;
  log(`  Duration: ${(step2Duration / 1000).toFixed(1)}s`, 'dim');
  log('', 'reset');

  // =========================================================================
  // Step 3: TableGenerator → tables
  // =========================================================================
  log('Step 3: Running TableGenerator...', 'cyan');
  const step3Start = Date.now();

  const groups = groupDataMap(verboseDataMap);
  const generatedOutputs = generateTables(groups);
  const tableAgentResults = convertToLegacyFormat(generatedOutputs);

  // Convert to ExtendedTableDefinition[]
  const extendedTables: ExtendedTableDefinition[] = tableAgentResults.flatMap(group =>
    group.tables.map(t => toExtendedTable(t, group.questionId))
  );

  const step3Duration = Date.now() - step3Start;
  log(`  Groups: ${groups.length}`, 'green');
  log(`  Tables: ${extendedTables.length}`, 'green');
  log(`  Duration: ${(step3Duration / 1000).toFixed(1)}s`, 'dim');
  log('', 'reset');

  // Save tables before filtering
  await fs.writeFile(
    path.join(outputDir, 'tables-before-filter.json'),
    JSON.stringify(extendedTables, null, 2),
    'utf-8'
  );

  // =========================================================================
  // Step 4: SkipLogicAgent → FilterTranslatorAgent
  // =========================================================================
  let skipLogicRulesCount = 0;
  let filtersTranslated = 0;
  let skipLogicDuration = 0;
  let translatorDuration = 0;
  let filterResult: Awaited<ReturnType<typeof translateSkipRules>> | null = null;
  let skipLogicResult: Awaited<ReturnType<typeof extractSkipLogic>> | null = null;

  if (!surveyMarkdown) {
    log('Step 4: Skipped — no survey available for skip logic extraction', 'yellow');
    log('', 'reset');
  } else {
    log('Step 4a: Running SkipLogicAgent...', 'cyan');
    const step4aStart = Date.now();

    skipLogicResult = await extractSkipLogic(surveyMarkdown, { outputDir });
    skipLogicDuration = Date.now() - step4aStart;
    skipLogicRulesCount = skipLogicResult.metadata.rulesExtracted;

    log(`  Rules extracted: ${skipLogicRulesCount}`, 'green');
    log(`  Duration: ${(skipLogicDuration / 1000).toFixed(1)}s`, 'dim');
    log('', 'reset');

    // Print rules
    if (skipLogicResult.extraction.rules.length > 0) {
      log('  Extracted Rules:', 'blue');
      for (const rule of skipLogicResult.extraction.rules) {
        log(`    ${rule.ruleId}: [${rule.ruleType}] ${rule.plainTextRule}`, 'dim');
        log(`      Applies to: ${rule.appliesTo.join(', ')}`, 'dim');
      }
      log('', 'reset');

      // Step 4b: FilterTranslatorAgent
      log('Step 4b: Running FilterTranslatorAgent...', 'cyan');
      const step4bStart = Date.now();

      filterResult = await translateSkipRules(
        skipLogicResult.extraction.rules,
        verboseDataMap,
        { outputDir }
      );
      translatorDuration = Date.now() - step4bStart;
      filtersTranslated = filterResult.metadata.filtersTranslated;

      log(`  Filters translated: ${filtersTranslated}`, 'green');
      log(`  High confidence: ${filterResult.metadata.highConfidenceCount}`, 'green');
      log(`  Review required: ${filterResult.metadata.reviewRequiredCount}`, filterResult.metadata.reviewRequiredCount > 0 ? 'yellow' : 'green');
      log(`  Duration: ${(translatorDuration / 1000).toFixed(1)}s`, 'dim');
      log('', 'reset');

      // Print filters
      log('  Translated Filters:', 'blue');
      for (const filter of filterResult.translation.filters) {
        const expr = filter.action === 'filter'
          ? filter.filterExpression
          : `SPLIT: ${filter.splits.length} parts`;
        const review = filter.humanReviewRequired ? ' [REVIEW]' : '';
        log(`    ${filter.questionId}: ${expr} (confidence: ${filter.confidence.toFixed(2)})${review}`, 'dim');
      }
      log('', 'reset');
    } else {
      log('Step 4b: Skipped — no rules to translate', 'yellow');
      log('', 'reset');
    }
  }

  // =========================================================================
  // Step 5: FilterApplicator (deterministic)
  // =========================================================================
  log('Step 5: Running FilterApplicator...', 'cyan');
  const step5Start = Date.now();

  const validVariables = new Set<string>(verboseDataMap.map(v => v.column));
  let filteredTables = extendedTables;
  let filterSummary = {
    totalInputTables: extendedTables.length,
    totalOutputTables: extendedTables.length,
    passCount: extendedTables.length,
    filterCount: 0,
    splitCount: 0,
    reviewRequiredCount: 0,
  };

  if (filterResult && filterResult.translation.filters.length > 0) {
    const applicatorResult = applyFilters(
      extendedTables,
      filterResult.translation,
      validVariables,
    );
    filteredTables = applicatorResult.tables;
    filterSummary = applicatorResult.summary;

    log(`  Input:  ${filterSummary.totalInputTables} tables`, 'green');
    log(`  Output: ${filterSummary.totalOutputTables} tables`, 'green');
    log(`  Pass:   ${filterSummary.passCount}`, 'dim');
    log(`  Filter: ${filterSummary.filterCount}`, filterSummary.filterCount > 0 ? 'green' : 'dim');
    log(`  Split:  ${filterSummary.splitCount}`, filterSummary.splitCount > 0 ? 'green' : 'dim');
    log(`  Review: ${filterSummary.reviewRequiredCount}`, filterSummary.reviewRequiredCount > 0 ? 'yellow' : 'dim');
  } else {
    log(`  No filters to apply — all ${extendedTables.length} tables pass through unchanged`, 'dim');
  }

  const step5Duration = Date.now() - step5Start;
  log(`  Duration: ${step5Duration}ms`, 'dim');
  log('', 'reset');

  // Save tables after filtering
  await fs.writeFile(
    path.join(outputDir, 'tables-after-filter.json'),
    JSON.stringify(filteredTables, null, 2),
    'utf-8'
  );

  // =========================================================================
  // Print detailed table comparison
  // =========================================================================
  log('-'.repeat(70), 'magenta');
  log('  Table Details (what VerificationAgent would receive)', 'bright');
  log('-'.repeat(70), 'magenta');
  log('', 'reset');

  for (const table of filteredTables) {
    const hasFilter = table.additionalFilter && table.additionalFilter !== '';
    const isSplit = table.splitFromTableId && table.splitFromTableId !== '';
    const needsReview = table.filterReviewRequired;

    let status = 'PASS';
    let statusColor: keyof typeof colors = 'dim';
    if (isSplit) {
      status = 'SPLIT';
      statusColor = 'cyan';
    } else if (hasFilter) {
      status = 'FILTER';
      statusColor = 'green';
    }
    if (needsReview) {
      status += ' [REVIEW]';
      statusColor = 'yellow';
    }

    log(`  [${status}] ${table.tableId} (${table.questionId}) — ${table.rows.length} rows, type: ${table.tableType}`, statusColor);

    if (hasFilter) {
      log(`    Filter: ${table.additionalFilter}`, 'dim');
      if (table.baseText) {
        log(`    Base: ${table.baseText}`, 'dim');
      }
    }
    if (isSplit) {
      log(`    Split from: ${table.splitFromTableId}`, 'dim');
      if (table.tableSubtitle) {
        log(`    Subtitle: ${table.tableSubtitle}`, 'dim');
      }
    }
  }

  log('', 'reset');

  // =========================================================================
  // Save summary
  // =========================================================================
  const totalDuration = Date.now() - startTime;

  const summary = {
    dataset: datasetName,
    timestamp: new Date().toISOString(),
    duration: {
      totalMs: totalDuration,
      step1_datamap: step1Duration,
      step2_survey: step2Duration,
      step3_tableGenerator: step3Duration,
      step4a_skipLogic: skipLogicDuration,
      step4b_filterTranslator: translatorDuration,
      step5_filterApplicator: step5Duration,
    },
    datamap: {
      variables: verboseDataMap.length,
      groups: groups.length,
    },
    tables: {
      beforeFilter: extendedTables.length,
      afterFilter: filteredTables.length,
    },
    skipLogic: {
      surveyAvailable: !!surveyMarkdown,
      rulesExtracted: skipLogicRulesCount,
    },
    filterApplicator: filterSummary,
  };

  await fs.writeFile(
    path.join(outputDir, 'summary.json'),
    JSON.stringify(summary, null, 2),
    'utf-8'
  );

  // Final summary
  log('='.repeat(70), 'magenta');
  log('  Pre-Verification Test Complete', 'bright');
  log('='.repeat(70), 'magenta');
  log(`  Duration:      ${(totalDuration / 1000).toFixed(1)}s`, 'reset');
  log(`  Variables:     ${verboseDataMap.length}`, 'reset');
  log(`  Tables in:     ${extendedTables.length}`, 'reset');
  log(`  Tables out:    ${filteredTables.length}`, 'reset');
  log(`  Rules:         ${skipLogicRulesCount}`, 'reset');
  log(`  Filters:       ${filtersTranslated}`, 'reset');
  log(`  Output:        ${path.relative(process.cwd(), outputDir)}`, 'reset');
  log('', 'reset');
  log('  Next: Run full pipeline (hawktab run) to see VerificationAgent results', 'dim');
  log('', 'reset');
}

main().catch((error) => {
  console.error('Test failed:', error);
  process.exit(1);
});
