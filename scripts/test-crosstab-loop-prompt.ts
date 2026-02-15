/**
 * Test script to verify loop-aware prompting in CrosstabAgent
 * Usage: npx tsx scripts/test-crosstab-loop-prompt.ts
 */

import '../src/lib/loadEnv';
import { buildLoopAwarePrompt } from '../src/prompts/crosstab/alternative';
import { getCrosstabPrompt } from '../src/prompts';
import { getPromptVersions } from '../src/lib/env';

console.log('\n========================================');
console.log('CrosstabAgent Loop Prompt Test');
console.log('========================================\n');

// Get the current prompt version
const promptVersions = getPromptVersions();
console.log(`Prompt version: ${promptVersions.crosstabPromptVersion}`);

// Get base instructions
const baseInstructions = getCrosstabPrompt(promptVersions.crosstabPromptVersion);
console.log(`\nBase instructions length: ${baseInstructions.length} chars`);

// Test 1: No loops (loopCount = 0)
console.log('\n--- Test 1: No Loops (loopCount = 0) ---');
const noLoopPrompt = buildLoopAwarePrompt(baseInstructions, 0);
const hasLoopGuidance1 = noLoopPrompt.includes('<loop_survey_context>');
console.log(`Loop guidance appended: ${hasLoopGuidance1 ? 'YES ✓' : 'NO ✗'}`);
console.log(`Prompt length: ${noLoopPrompt.length} chars (should equal base)`);
console.log(`Match: ${noLoopPrompt.length === baseInstructions.length ? 'PASS ✓' : 'FAIL ✗'}`);

// Test 2: With loops (loopCount = 2)
console.log('\n--- Test 2: With Loops (loopCount = 2) ---');
const loopPrompt = buildLoopAwarePrompt(baseInstructions, 2);
const hasLoopGuidance2 = loopPrompt.includes('<loop_survey_context>');
console.log(`Loop guidance appended: ${hasLoopGuidance2 ? 'YES ✓' : 'NO ✗'}`);
console.log(`Prompt length: ${loopPrompt.length} chars (should be > base)`);
console.log(`Increased by: ${loopPrompt.length - baseInstructions.length} chars`);
console.log(`Match: ${loopPrompt.length > baseInstructions.length ? 'PASS ✓' : 'FAIL ✗'}`);

if (hasLoopGuidance2) {
  // Extract and display the loop guidance section
  const startIdx = loopPrompt.indexOf('<loop_survey_context>');
  const endIdx = loopPrompt.indexOf('</loop_survey_context>') + '</loop_survey_context>'.length;
  const loopGuidance = loopPrompt.substring(startIdx, endIdx);

  console.log('\n--- Extracted Loop Guidance ---');
  console.log(loopGuidance);

  // Verify it mentions "2 loop iteration(s)"
  const mentions2Iterations = loopGuidance.includes('2 loop iteration');
  console.log(`\nCorrectly mentions "2 loop iteration(s)": ${mentions2Iterations ? 'YES ✓' : 'NO ✗'}`);
}

// Test 3: Import test - verify function is exported
console.log('\n--- Test 3: Function Export ---');
console.log(`buildLoopAwarePrompt is a function: ${typeof buildLoopAwarePrompt === 'function' ? 'YES ✓' : 'NO ✗'}`);

// Summary
console.log('\n========================================');
console.log('Test Summary');
console.log('========================================');
console.log(`Test 1 (No loops): ${!hasLoopGuidance1 && noLoopPrompt.length === baseInstructions.length ? 'PASS ✓' : 'FAIL ✗'}`);
console.log(`Test 2 (With loops): ${hasLoopGuidance2 && loopPrompt.length > baseInstructions.length ? 'PASS ✓' : 'FAIL ✗'}`);
console.log(`Test 3 (Export): ${typeof buildLoopAwarePrompt === 'function' ? 'PASS ✓' : 'FAIL ✗'}`);
console.log('========================================\n');
