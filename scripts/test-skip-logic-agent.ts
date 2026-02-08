#!/usr/bin/env npx tsx
/**
 * Skip Logic Agent Test Script
 *
 * Purpose: Run SkipLogicAgent + FilterTranslatorAgent in isolation.
 * Tests the skip logic extraction pipeline without running the full pipeline.
 *
 * Usage:
 *   npx tsx scripts/test-skip-logic-agent.ts [dataset-folder]
 *
 * Examples:
 *   npx tsx scripts/test-skip-logic-agent.ts
 *   # Uses default dataset (data/leqvio-monotherapy-demand-NOV217)
 *
 *   npx tsx scripts/test-skip-logic-agent.ts data/stacked-data-example
 *   # Uses specified dataset folder
 *
 * Output:
 *   outputs/<dataset>/skiplogic-test-<timestamp>/
 *   - skiplogic/ (SkipLogicAgent outputs + scratchpad)
 *   - filtertranslator/ (FilterTranslatorAgent outputs + scratchpad)
 *   - summary.json (test summary)
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { extractSkipLogic } from '../src/agents/SkipLogicAgent';
import { translateSkipRules } from '../src/agents/FilterTranslatorAgent';
import { processSurvey } from '../src/lib/processors/SurveyProcessor';
import { validate } from '../src/lib/validation/ValidationRunner';
import type { VerboseDataMapType } from '../src/schemas/processingSchemas';

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
  log('  Skip Logic Agent Test', 'bright');
  log('='.repeat(70), 'magenta');
  log(`Dataset: ${datasetName}`, 'blue');
  log('', 'reset');

  // Create output directory
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const outputDir = path.join(process.cwd(), 'outputs', datasetName, `skiplogic-test-${timestamp}`);
  await fs.mkdir(outputDir, { recursive: true });
  log(`Output: ${path.relative(process.cwd(), outputDir)}`, 'blue');
  log('', 'reset');

  // Step 1: Find survey file
  log('Step 1: Finding survey file...', 'cyan');
  const inputsDir = path.join(datasetFolder, 'inputs');
  let surveyFile: string | null = null;

  try {
    const files = await fs.readdir(inputsDir);
    const surveyFiles = files.filter(f =>
      (f.endsWith('.docx') || f.endsWith('.doc') || f.endsWith('.pdf')) &&
      f.toLowerCase().includes('survey')
    );
    if (surveyFiles.length > 0) {
      surveyFile = path.join(inputsDir, surveyFiles[0]);
      log(`  Found: ${surveyFiles[0]}`, 'green');
    } else {
      // Fallback: any docx/doc/pdf
      const anyDoc = files.filter(f => f.endsWith('.docx') || f.endsWith('.doc'));
      if (anyDoc.length > 0) {
        surveyFile = path.join(inputsDir, anyDoc[0]);
        log(`  Found (fallback): ${anyDoc[0]}`, 'yellow');
      }
    }
  } catch {
    log(`  Could not read inputs directory: ${inputsDir}`, 'red');
  }

  if (!surveyFile) {
    log('  No survey file found — cannot run skip logic extraction', 'red');
    process.exit(1);
  }

  // Step 2: Process survey
  log('Step 2: Processing survey...', 'cyan');
  const surveyResult = await processSurvey(surveyFile, outputDir);
  if (!surveyResult.markdown) {
    log(`  Survey processing failed: ${surveyResult.warnings.join(', ')}`, 'red');
    process.exit(1);
  }
  log(`  Survey: ${surveyResult.markdown.length} characters`, 'green');
  log('', 'reset');

  // Step 3: Load datamap (for FilterTranslatorAgent)
  log('Step 3: Loading datamap from .sav...', 'cyan');
  const spssFiles = (await fs.readdir(inputsDir)).filter(f => f.endsWith('.sav'));
  if (spssFiles.length === 0) {
    log('  No .sav file found', 'red');
    process.exit(1);
  }
  const spssPath = path.join(inputsDir, spssFiles[0]);
  const validationResult = await validate({ spssPath, outputDir });
  const verboseDataMap = validationResult.processingResult!.verbose as VerboseDataMapType[];
  log(`  Loaded ${verboseDataMap.length} variables`, 'green');
  log('', 'reset');

  // Step 4: Run SkipLogicAgent
  log('Step 4: Running SkipLogicAgent...', 'cyan');
  const skipLogicStart = Date.now();
  const skipLogicResult = await extractSkipLogic(surveyResult.markdown, { outputDir });
  const skipLogicDuration = Date.now() - skipLogicStart;

  log(`  Rules extracted: ${skipLogicResult.metadata.rulesExtracted}`, 'green');
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
  }

  // Step 5: Run FilterTranslatorAgent
  if (skipLogicResult.extraction.rules.length > 0) {
    log('Step 5: Running FilterTranslatorAgent...', 'cyan');
    const translatorStart = Date.now();
    const filterResult = await translateSkipRules(
      skipLogicResult.extraction.rules,
      verboseDataMap,
      { outputDir }
    );
    const translatorDuration = Date.now() - translatorStart;

    log(`  Filters translated: ${filterResult.metadata.filtersTranslated}`, 'green');
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

    // Save summary
    const summary = {
      dataset: datasetName,
      timestamp: new Date().toISOString(),
      duration: {
        total: Date.now() - startTime,
        skipLogic: skipLogicDuration,
        filterTranslator: translatorDuration,
      },
      skipLogic: {
        rulesExtracted: skipLogicResult.metadata.rulesExtracted,
        rulesByType: {
          tableLevel: skipLogicResult.extraction.rules.filter(r => r.ruleType === 'table-level').length,
          rowLevel: skipLogicResult.extraction.rules.filter(r => r.ruleType === 'row-level').length,
        },
      },
      filterTranslator: filterResult.metadata,
    };
    await fs.writeFile(
      path.join(outputDir, 'summary.json'),
      JSON.stringify(summary, null, 2),
      'utf-8'
    );
  } else {
    log('Step 5: Skipped — no rules to translate', 'yellow');
  }

  // Final summary
  const totalDuration = Date.now() - startTime;
  log('', 'reset');
  log('='.repeat(70), 'magenta');
  log('  Test Complete', 'bright');
  log('='.repeat(70), 'magenta');
  log(`  Duration: ${(totalDuration / 1000).toFixed(1)}s`, 'reset');
  log(`  Output:   ${path.relative(process.cwd(), outputDir)}`, 'reset');
  log('', 'reset');
}

main().catch((error) => {
  console.error('Test failed:', error);
  process.exit(1);
});
