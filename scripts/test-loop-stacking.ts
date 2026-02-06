/**
 * Integration test for Loop Stacking (LoopCollapser + R preamble generation)
 *
 * Runs against Tito's .sav to verify:
 * 1. ValidationRunner detects loops
 * 2. LoopCollapser produces correct collapsed datamap
 * 3. R stacking preamble is syntactically reasonable
 *
 * Usage: npx tsx scripts/test-loop-stacking.ts
 */

import '../src/lib/loadEnv';
import path from 'path';
import fs from 'fs';
import { validate } from '../src/lib/validation/ValidationRunner';
import { collapseLoopVariables } from '../src/lib/validation/LoopCollapser';
import { generateStackingPreamble, escapeRString, sanitizeVarName } from '../src/lib/r/RScriptGeneratorV2';

// =============================================================================
// Config
// =============================================================================

const TITOS_SAV = 'data/test-data/titos-growth-strategy/250800.sav';
const OUTPUT_DIR = 'outputs/_loop-stacking-test';

// =============================================================================
// Main
// =============================================================================

async function main() {
  const startTime = Date.now();
  console.log('=== Loop Stacking Integration Test ===\n');

  // Check that the .sav file exists
  if (!fs.existsSync(TITOS_SAV)) {
    console.error(`ERROR: Cannot find ${TITOS_SAV}`);
    console.error('Make sure the Tito\'s dataset is available.');
    process.exit(1);
  }

  // Create output directory
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const runDir = path.join(OUTPUT_DIR, `run-${timestamp}`);
  fs.mkdirSync(runDir, { recursive: true });

  // -------------------------------------------------------------------------
  // Step 1: Run Validation
  // -------------------------------------------------------------------------
  console.log('Step 1: Running ValidationRunner...');
  const validationResult = await validate({
    spssPath: TITOS_SAV,
    outputDir: runDir,
  });

  console.log(`  Format: ${validationResult.format}`);
  console.log(`  Can proceed: ${validationResult.canProceed}`);
  console.log(`  Errors: ${validationResult.errors.length}`);
  console.log(`  Warnings: ${validationResult.warnings.length}`);

  if (!validationResult.canProceed) {
    console.error('  Validation FAILED — cannot proceed');
    for (const e of validationResult.errors) {
      console.error(`    ${e.message}`);
    }
    process.exit(1);
  }

  if (!validationResult.loopDetection?.hasLoops) {
    console.error('  ERROR: No loops detected in Tito\'s data!');
    console.error('  This dataset should have loops. Check LoopDetector.');
    process.exit(1);
  }

  console.log(`  Loops detected: ${validationResult.loopDetection.loops.length} group(s)`);
  for (const loop of validationResult.loopDetection.loops) {
    console.log(`    ${loop.skeleton}: ${loop.diversity} bases x ${loop.iterations.length} iterations`);
    console.log(`      Iterations: [${loop.iterations.join(', ')}]`);
    console.log(`      Sample bases: ${loop.bases.slice(0, 5).join(', ')}${loop.bases.length > 5 ? '...' : ''}`);
  }

  // Fill rate info
  if (validationResult.fillRateResults.length > 0) {
    console.log('\n  Fill rate patterns:');
    for (const fr of validationResult.fillRateResults) {
      console.log(`    ${fr.loopGroup.skeleton}: ${fr.pattern}`);
      const rates = Object.entries(fr.fillRates)
        .map(([k, v]) => `_${k}: ${(v * 100).toFixed(0)}%`)
        .join(', ');
      console.log(`      ${rates}`);
    }
  }

  // -------------------------------------------------------------------------
  // Step 2: Run LoopCollapser
  // -------------------------------------------------------------------------
  console.log('\nStep 2: Running LoopCollapser...');
  const verboseDataMap = validationResult.processingResult!.verbose;
  const collapseResult = collapseLoopVariables(verboseDataMap, validationResult.loopDetection);

  console.log(`  Original variables: ${verboseDataMap.length}`);
  console.log(`  Collapsed variables: ${collapseResult.collapsedDataMap.length}`);
  console.log(`  Removed (iteration-specific): ${collapseResult.collapsedVariableNames.size}`);
  console.log(`  Loop groups: ${collapseResult.loopMappings.length}`);

  for (const mapping of collapseResult.loopMappings) {
    console.log(`\n  ${mapping.stackedFrameName}:`);
    console.log(`    Skeleton: ${mapping.skeleton}`);
    console.log(`    Iterations: [${mapping.iterations.join(', ')}]`);
    console.log(`    Variables: ${mapping.variables.length}`);
    // Show first 5 variable mappings
    for (const v of mapping.variables.slice(0, 5)) {
      const cols = Object.entries(v.iterationColumns)
        .map(([iter, col]) => `_${iter}=${col}`)
        .join(', ');
      console.log(`      ${v.baseName} (${v.label.slice(0, 40)}...) → {${cols}}`);
    }
    if (mapping.variables.length > 5) {
      console.log(`      ... and ${mapping.variables.length - 5} more`);
    }
  }

  // -------------------------------------------------------------------------
  // Step 3: Generate R Stacking Preamble
  // -------------------------------------------------------------------------
  console.log('\nStep 3: Generating R stacking preamble...');

  // Create mock cuts for the preamble
  const mockCuts = [
    { id: 'gender.male', name: 'Male', rExpression: 'gender == 1', statLetter: 'A', groupName: 'Gender', groupIndex: 0 },
    { id: 'gender.female', name: 'Female', rExpression: 'gender == 2', statLetter: 'B', groupName: 'Gender', groupIndex: 1 },
  ];

  const lines: string[] = [];
  generateStackingPreamble(lines, collapseResult.loopMappings, mockCuts);
  const preamble = lines.join('\n');

  console.log(`  Preamble size: ${preamble.length} characters, ${lines.length} lines`);

  // Save preamble for inspection
  const preamblePath = path.join(runDir, 'stacking-preamble.R');
  fs.writeFileSync(preamblePath, preamble, 'utf-8');
  console.log(`  Saved to: ${preamblePath}`);

  // Show first 30 lines
  console.log('\n  --- R Preamble Preview (first 30 lines) ---');
  for (const line of lines.slice(0, 30)) {
    console.log(`  ${line}`);
  }
  if (lines.length > 30) {
    console.log(`  ... (${lines.length - 30} more lines)`);
  }

  // -------------------------------------------------------------------------
  // Step 4: Verify baseNameToLoopIndex mapping
  // -------------------------------------------------------------------------
  console.log('\nStep 4: Verifying baseNameToLoopIndex...');
  const loopBaseCount = collapseResult.baseNameToLoopIndex.size;
  console.log(`  ${loopBaseCount} base names mapped to loop groups`);

  // Verify every collapsed variable has a mapping
  const collapsedLoopVars = collapseResult.collapsedDataMap.filter(
    v => collapseResult.baseNameToLoopIndex.has(v.column)
  );
  console.log(`  ${collapsedLoopVars.length} collapsed vars in datamap have loop mappings`);

  if (collapsedLoopVars.length !== loopBaseCount) {
    console.error(`  WARNING: Mismatch! ${loopBaseCount} mapped but ${collapsedLoopVars.length} in datamap`);
  }

  // -------------------------------------------------------------------------
  // Save full results
  // -------------------------------------------------------------------------
  const resultsPath = path.join(runDir, 'collapse-results.json');
  const serializableResult = {
    originalVarCount: verboseDataMap.length,
    collapsedVarCount: collapseResult.collapsedDataMap.length,
    removedCount: collapseResult.collapsedVariableNames.size,
    loopMappings: collapseResult.loopMappings,
    baseNameToLoopIndex: Object.fromEntries(collapseResult.baseNameToLoopIndex),
    collapsedDataMapPreview: collapseResult.collapsedDataMap.slice(0, 20).map(v => ({
      column: v.column,
      description: v.description?.slice(0, 60),
      valueType: v.valueType,
    })),
  };
  fs.writeFileSync(resultsPath, JSON.stringify(serializableResult, null, 2), 'utf-8');
  console.log(`\nResults saved to: ${resultsPath}`);

  // -------------------------------------------------------------------------
  // Summary
  // -------------------------------------------------------------------------
  const elapsed = Date.now() - startTime;
  console.log(`\n=== Done in ${elapsed}ms ===`);
  console.log(`Output: ${runDir}`);
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
