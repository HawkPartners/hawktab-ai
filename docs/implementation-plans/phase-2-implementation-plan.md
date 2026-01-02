# Phase 2: Reliability Improvements (BannerValidateAgent)

## Implementation Plan

**Goal**: Add semantic validation of banner cuts using the survey document as context, catching impossible logic before it reaches CrosstabAgent.

**Branch**: `feature-banner-validate-agent`

**Testing Strategy**: Implement on feature branch → test with current survey → verify catches known issues → merge to development

---

## Executive Summary

The current system validates **syntax** (does the variable exist?) but not **semantics** (can this expression ever be true?). This leads to cuts like `S2=1 AND S2a=1` passing validation even when the survey structure makes them impossible.

**The Fix**: Insert a BannerValidateAgent between BannerAgent and CrosstabAgent that uses the survey document to validate expressions semantically.

### What This Phase Delivers

| Component | Description |
|-----------|-------------|
| **BannerValidateAgent** | New agent that validates banner cuts against survey logic |
| **Survey Text Extraction** | DOC/DOCX/PDF → text (reuses existing mammoth code) |
| **Validation + Auto-Fix** | Flags issues AND provides `validatedExpression` for CrosstabAgent |
| **Group-by-Group Processing** | Same pattern as CrosstabAgent for focus |

### What This Phase Does NOT Include (Part 2 - Deferred)

| Deferred Item | Why Deferred | Future Approach |
|---------------|--------------|-----------------|
| Decipher API Integration | Not needed for Joe replacement; we have the survey doc | Phase 2b or later |
| Table Formatting (Top 2 Box) | Need to understand requirements better | Likely TableFormatAgent (LLM-based) |
| DataValidator (sample counts) | BannerValidateAgent catches issues earlier | Consider if still needed after Part 1 |

**Note on Deferred Work**: The table formatting problem (showing Top 2 Box, Bottom 2 Box instead of generic Mean/Median/SD) will require understanding survey structure to know how to display each question. This is a good use case for an LLM-based "TableFormatAgent" rather than deterministic parsing—the current process uses human judgment, and LLMs are good at mimicking humans. We're already faster and cheaper than the $2,000/3-day current workflow; reliability is the win we need, not more optimization.

---

## Current Flow vs. Proposed Flow

### Current Flow
```
BannerAgent → CrosstabAgent → R Script
     ↓              ↓
Extracts:       Validates:
"S2=1 AND       "Does S2 exist? ✓
 S2a=1"          Does S2a exist? ✓"
                 (syntax only)
```

### Proposed Flow
```
BannerAgent → BannerValidateAgent → CrosstabAgent → R Script
     ↓              ↓                      ↓
Extracts:      Validates + Fixes:       Validates:
"S2=1 AND      "Can't be true →        "Generate R syntax
 S2a=1"         use S2=1 OR S2a=1"      for validatedExpression"
                (semantic check)
```

**Key Design Decision**: BannerValidateAgent outputs `validatedExpression` which CrosstabAgent uses directly. CrosstabAgent doesn't need to know about validation metadata—it just converts the expression to R syntax.

---

## Pre-Implementation Checklist

- [ ] Obtain survey document for test survey (DOC or PDF)
- [ ] Verify mammoth extracts survey text adequately (spot check)
- [ ] Review current BannerAgent output structure
- [ ] Identify known issues in current output (e.g., `S2=1 AND S2a=1`)

---

## Step-by-Step Implementation

### Step 1: Create Survey Text Extraction Utility

**File**: `src/lib/processors/SurveyProcessor.ts`

**Purpose**: Extract text from survey document for BannerValidateAgent context.

**Key Insight**: We already use `mammoth.extractRawText()` in BannerAgent for DOC→PDF conversion. We can reuse this directly—no PDF conversion needed since we just want text.

```typescript
/**
 * SurveyProcessor
 * Purpose: Extract text from survey document for BannerValidateAgent context
 * Input: Survey document (DOC/DOCX/PDF)
 * Output: Plain text content
 *
 * NOTE: Reuses mammoth (already in BannerAgent) for DOC/DOCX extraction
 */

import mammoth from 'mammoth';
import fs from 'fs/promises';
import path from 'path';

export interface SurveyProcessingResult {
  success: boolean;
  text: string;
  questionCount: number;  // Estimated from Q/S pattern matching
  errors: string[];
  warnings: string[];
}

export async function extractSurveyText(filePath: string): Promise<SurveyProcessingResult> {
  const ext = path.extname(filePath).toLowerCase();

  try {
    let text: string;

    if (ext === '.doc' || ext === '.docx') {
      // Same approach as BannerAgent.convertDocToPDF() line 262
      const result = await mammoth.extractRawText({ path: filePath });
      text = result.value;
    } else if (ext === '.pdf') {
      // PDF text extraction
      const pdfParse = await import('pdf-parse');
      const buffer = await fs.readFile(filePath);
      const data = await pdfParse.default(buffer);
      text = data.text;
    } else {
      throw new Error(`Unsupported survey format: ${ext}. Use DOC, DOCX, or PDF.`);
    }

    if (!text.trim()) {
      return {
        success: false,
        text: '',
        questionCount: 0,
        errors: ['No text content found in survey document'],
        warnings: []
      };
    }

    // Estimate question count (look for Q1, S1, A3, etc. patterns)
    const questionPattern = /\b[QSAB]\d+[a-z]?\b/gi;
    const matches = text.match(questionPattern) || [];
    const uniqueQuestions = new Set(matches.map(m => m.toUpperCase()));

    console.log(`[SurveyProcessor] Extracted ${text.length} chars, ~${uniqueQuestions.size} questions`);

    return {
      success: true,
      text,
      questionCount: uniqueQuestions.size,
      errors: [],
      warnings: text.length < 1000 ? ['Survey text seems short - verify extraction quality'] : []
    };

  } catch (error) {
    return {
      success: false,
      text: '',
      questionCount: 0,
      errors: [error instanceof Error ? error.message : 'Unknown extraction error'],
      warnings: []
    };
  }
}
```

**Why no PDF conversion?**
- BannerAgent converts DOC→PDF→Images because it needs vision
- BannerValidateAgent only needs text
- `mammoth.extractRawText()` gives us text directly
- Simpler, faster, no intermediate files

---

### Step 2: Create BannerValidateAgent

**File**: `src/agents/BannerValidateAgent.ts`

**Purpose**: Validate banner cuts semantically using survey context, output `validatedExpression` for CrosstabAgent.

```typescript
/**
 * BannerValidateAgent
 * Purpose: Validate banner cuts against survey skip logic, provide fixes
 * Input: Banner agent output + Survey document text
 * Output: Banner groups with validatedExpression (what CrosstabAgent uses)
 * Invariants: group-by-group processing; outputs validatedExpression for downstream
 */

import { generateText, Output, stepCountIs } from 'ai';
import { z } from 'zod';
import { getReasoningModel, getReasoningModelName, getReasoningModelTokenLimit, getPromptVersions } from '../lib/env';
import { scratchpadTool } from './tools/scratchpad';
import { getBannerValidatePrompt } from '../prompts';
import fs from 'fs/promises';
import path from 'path';

// Input schema (what we receive from BannerAgent)
export interface BannerColumnInput {
  name: string;
  original: string;
}

export interface BannerGroupInput {
  groupName: string;
  columns: BannerColumnInput[];
}

// Output schema (what we pass to CrosstabAgent)
const ValidatedColumnSchema = z.object({
  name: z.string(),
  original: z.string(),
  // THE KEY FIELD: What CrosstabAgent will use
  validatedExpression: z.string().describe('The expression CrosstabAgent should use - either original (if valid) or the fix'),
  // Validation metadata (for logging/human review, CrosstabAgent ignores these)
  validation: z.object({
    flag: z.boolean().describe('True if the original expression had an issue'),
    issue: z.enum(['none', 'impossible_logic', 'ambiguous_expression', 'other']),
    reason: z.string().describe('Explanation of the issue, empty if none'),
    confidence: z.number().min(0).max(1).describe('Confidence in the validation assessment')
  })
});

const ValidatedGroupSchema = z.object({
  groupName: z.string(),
  columns: z.array(ValidatedColumnSchema)
});

export type ValidatedColumn = z.infer<typeof ValidatedColumnSchema>;
export type ValidatedGroup = z.infer<typeof ValidatedGroupSchema>;

// Get prompt from modular prompt system
const getBannerValidationPrompt = (): string => {
  const promptVersions = getPromptVersions();
  return getBannerValidatePrompt(promptVersions.bannerValidatePromptVersion || 'production');
};

// Process single banner group
export async function validateGroup(
  surveyText: string,
  group: BannerGroupInput
): Promise<ValidatedGroup> {
  console.log(`[BannerValidateAgent] Validating group: ${group.groupName} (${group.columns.length} columns)`);

  try {
    const systemPrompt = `
${getBannerValidationPrompt()}

SURVEY DOCUMENT:
${surveyText}

BANNER GROUP TO VALIDATE:
Group: "${group.groupName}"
${JSON.stringify(group, null, 2)}

VALIDATION REQUIREMENTS:
- Check each column's "original" expression against the survey structure
- Set "validatedExpression" to the fix if there's an issue, otherwise copy "original"
- Identify impossible logic (AND when should be OR, skip logic conflicts)
- Flag ambiguous expressions that need clarification
- Use scratchpad to show your reasoning

Begin validation now.
`;

    const { output } = await generateText({
      model: getReasoningModel(),
      system: systemPrompt,
      prompt: `Validate banner group "${group.groupName}" with ${group.columns.length} columns against the survey document.`,
      tools: {
        scratchpad: scratchpadTool,
      },
      stopWhen: stepCountIs(25),
      maxOutputTokens: Math.min(getReasoningModelTokenLimit(), 10000),
      output: Output.object({
        schema: ValidatedGroupSchema,
      }),
    });

    if (!output || !output.columns) {
      throw new Error(`Invalid response for group ${group.groupName}`);
    }

    const issueCount = output.columns.filter(c => c.validation.flag).length;
    console.log(`[BannerValidateAgent] Group ${group.groupName} validated - ${issueCount} issues found`);

    return output;

  } catch (error) {
    console.error(`[BannerValidateAgent] Error validating group ${group.groupName}:`, error);

    // Return input with passthrough (no validation applied)
    return {
      groupName: group.groupName,
      columns: group.columns.map(col => ({
        name: col.name,
        original: col.original,
        validatedExpression: col.original,  // Pass through unchanged
        validation: {
          flag: false,
          issue: 'other' as const,
          reason: `Validation error: ${error instanceof Error ? error.message : 'Unknown'}`,
          confidence: 0.0
        }
      }))
    };
  }
}

// Process all banner groups
export async function validateAllGroups(
  surveyText: string,
  bannerGroups: BannerGroupInput[],
  outputFolder?: string,
  onProgress?: (completed: number, total: number) => void
): Promise<{ result: ValidatedGroup[]; processingLog: string[] }> {
  const processingLog: string[] = [];
  const logEntry = (message: string) => {
    console.log(message);
    processingLog.push(`${new Date().toISOString()}: ${message}`);
  };

  logEntry(`[BannerValidateAgent] Starting validation: ${bannerGroups.length} groups`);
  logEntry(`[BannerValidateAgent] Using model: ${getReasoningModelName()}`);
  logEntry(`[BannerValidateAgent] Survey context: ${surveyText.length} characters`);

  const results: ValidatedGroup[] = [];

  for (let i = 0; i < bannerGroups.length; i++) {
    const group = bannerGroups[i];
    const startTime = Date.now();

    logEntry(`[BannerValidateAgent] Validating group ${i + 1}/${bannerGroups.length}: "${group.groupName}"`);

    const validatedGroup = await validateGroup(surveyText, group);
    results.push(validatedGroup);

    const duration = Date.now() - startTime;
    const issueCount = validatedGroup.columns.filter(c => c.validation.flag).length;

    logEntry(`[BannerValidateAgent] Group "${group.groupName}" completed in ${duration}ms - ${issueCount} issues found`);

    try { onProgress?.(i + 1, bannerGroups.length); } catch {}
  }

  // Save outputs
  if (outputFolder) {
    await saveValidationOutputs(results, outputFolder, processingLog);
  }

  const totalIssues = results.reduce((sum, g) => sum + g.columns.filter(c => c.validation.flag).length, 0);
  logEntry(`[BannerValidateAgent] All groups validated - ${totalIssues} total issues found`);

  return { result: results, processingLog };
}

// Convert validated output to format CrosstabAgent expects
// CrosstabAgent just needs {groupName, columns: [{name, original}]}
// We give it validatedExpression as "original" so it processes the fixed version
export function toAgentFormat(validatedGroups: ValidatedGroup[]): BannerGroupInput[] {
  return validatedGroups.map(group => ({
    groupName: group.groupName,
    columns: group.columns.map(col => ({
      name: col.name,
      original: col.validatedExpression  // KEY: CrosstabAgent uses the validated expression
    }))
  }));
}

// Save development outputs
async function saveValidationOutputs(
  result: ValidatedGroup[],
  outputFolder: string,
  processingLog: string[]
): Promise<void> {
  try {
    const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolder);
    await fs.mkdir(outputDir, { recursive: true });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filename = `banner-validated-${timestamp}.json`;
    const filePath = path.join(outputDir, filename);

    const output = {
      validatedGroups: result,
      processingInfo: {
        timestamp: new Date().toISOString(),
        totalGroups: result.length,
        totalColumns: result.reduce((sum, g) => sum + g.columns.length, 0),
        totalIssues: result.reduce((sum, g) => sum + g.columns.filter(c => c.validation.flag).length, 0),
        issuesByType: {
          impossible_logic: result.flatMap(g => g.columns).filter(c => c.validation.issue === 'impossible_logic').length,
          ambiguous_expression: result.flatMap(g => g.columns).filter(c => c.validation.issue === 'ambiguous_expression').length,
          other: result.flatMap(g => g.columns).filter(c => c.validation.issue === 'other').length
        },
        processingLog
      }
    };

    await fs.writeFile(filePath, JSON.stringify(output, null, 2), 'utf-8');
    console.log(`[BannerValidateAgent] Output saved: ${filename}`);
  } catch (error) {
    console.error('[BannerValidateAgent] Failed to save outputs:', error);
  }
}
```

**Key Design Decisions:**

1. **`validatedExpression` is the key field** - CrosstabAgent uses this, ignoring validation metadata
2. **`toAgentFormat()` helper** - Converts validated output to the format CrosstabAgent expects
3. **3 issue types only**: `impossible_logic`, `ambiguous_expression`, `other`
4. **Passthrough on error** - If validation fails, we pass the original through unchanged

---

### Step 3: Create BannerValidateAgent Prompt

**File**: `src/prompts/banner-validate/production.ts`

```typescript
export const BANNER_VALIDATE_INSTRUCTIONS_PRODUCTION = `
You are a BannerValidateAgent that validates banner plan expressions against survey skip logic.

YOUR CORE MISSION:
Review banner cut expressions (like "S2=1 AND S2a=1") and determine if they are semantically valid given the survey structure. If invalid, provide a fixed expression in "validatedExpression".

OUTPUT RULES:
- If the expression is VALID: set validatedExpression = original
- If the expression is INVALID but fixable: set validatedExpression = your fix
- If the expression is INVALID and unfixable: set validatedExpression = original (let CrosstabAgent try)

WHAT YOU'RE CHECKING FOR:

1. IMPOSSIBLE LOGIC (issue: "impossible_logic")
   - "S2=1 AND S2a=1" when S2a only shows if S2≠1
   - Sub-question combinations that violate skip logic
   - AND conditions that are mutually exclusive
   - FIX: Usually change AND to OR, or remove conflicting condition

2. AMBIGUOUS EXPRESSIONS (issue: "ambiguous_expression")
   - "IF HCP" - what variable defines HCP?
   - "Higher" / "Lower" - higher/lower than what?
   - Conceptual terms without clear variable mapping
   - FIX: Map to specific variable if you can identify it from survey

3. OTHER (issue: "other")
   - Anything else that seems wrong but doesn't fit above
   - When uncertain, flag it and explain

HOW TO USE THE SURVEY DOCUMENT:
The survey document shows:
- Question IDs (S1, S2, Q3, etc.)
- Skip logic / routing ("ASK IF S2=1", "SHOW IF S2≠1")
- Question text and answer options
- Which questions are sub-questions of others

Look for patterns like:
- "ASK IF..." or "SHOW IF..." → skip logic that determines who sees the question
- Questions labeled "S2a" under "S2" → sub-question relationship
- "[HIDDEN]" or "[COMPUTED]" → derived variables

VALIDATION OUTPUT STRUCTURE:
For each column, you MUST provide:
- name: (copy from input)
- original: (copy from input)
- validatedExpression: THE EXPRESSION CROSSTABAGENT SHOULD USE
- validation.flag: true if there's ANY issue
- validation.issue: "none" | "impossible_logic" | "ambiguous_expression" | "other"
- validation.reason: explanation (empty string if no issue)
- validation.confidence: 0.0-1.0

CONFIDENCE SCORING:
- 0.95-1.0: Clear evidence in survey (skip logic explicitly shown)
- 0.80-0.94: Strong inference from survey structure
- 0.60-0.79: Reasonable assumption, survey context unclear
- 0.40-0.59: Uncertain, multiple interpretations possible
- 0.0-0.39: Guessing, very little survey context

EXAMPLES:

Example 1 - Impossible Logic (WITH FIX):
Input: { name: "Cards", original: "S2=1 AND S2a=1" }
Survey shows: "S2a: ASK IF S2≠1"
Output: {
  name: "Cards",
  original: "S2=1 AND S2a=1",
  validatedExpression: "S2=1 OR S2a=1",
  validation: {
    flag: true,
    issue: "impossible_logic",
    reason: "S2a only appears when S2≠1, so S2=1 AND S2a=1 can never be true. Changed AND to OR.",
    confidence: 0.95
  }
}

Example 2 - Ambiguous Expression (WITH FIX):
Input: { name: "HCP", original: "IF HCP" }
Survey shows: S1 asks "Are you a physician (HCP)?" with 1=Yes, 2=No
Output: {
  name: "HCP",
  original: "IF HCP",
  validatedExpression: "S1=1",
  validation: {
    flag: true,
    issue: "ambiguous_expression",
    reason: "HCP maps to S1=1 based on survey question 'Are you a physician (HCP)?'",
    confidence: 0.85
  }
}

Example 3 - Valid Expression (NO CHANGE):
Input: { name: "PCPs", original: "S2=2" }
Survey shows: S2 has option 2 = "Primary Care Physician"
Output: {
  name: "PCPs",
  original: "S2=2",
  validatedExpression: "S2=2",
  validation: {
    flag: false,
    issue: "none",
    reason: "",
    confidence: 0.95
  }
}

SCRATCHPAD USAGE:
Use the scratchpad to:
- Note which survey questions you found relevant
- Document skip logic you identified
- Show your reasoning for fixes

Limit to 3-5 scratchpad calls per group.

IMPORTANT:
- ALWAYS provide validatedExpression (never leave it empty)
- If you can't fix it, set validatedExpression = original
- CrosstabAgent will use validatedExpression, not original
- Better to flag something questionable than miss an issue
`;
```

---

### Step 4: Update Prompt Index

**File**: `src/prompts/index.ts`

Add the new prompt export:

```typescript
// Add to existing exports
export { BANNER_VALIDATE_INSTRUCTIONS_PRODUCTION } from './banner-validate/production';

// Add getter function
export const getBannerValidatePrompt = (version: string): string => {
  switch (version) {
    case 'production':
    default:
      return BANNER_VALIDATE_INSTRUCTIONS_PRODUCTION;
  }
};
```

---

### Step 5: Update Environment Configuration

**File**: `src/lib/types.ts`

Add banner validate prompt version:

```typescript
export interface EnvironmentConfig {
  // ... existing fields ...
  promptVersions: {
    crosstabPromptVersion: string;
    bannerPromptVersion: string;
    bannerValidatePromptVersion: string;  // NEW
  };
}
```

**File**: `src/lib/env.ts`

Update prompt versions:

```typescript
promptVersions: {
  crosstabPromptVersion: process.env.CROSSTAB_PROMPT_VERSION || 'production',
  bannerPromptVersion: process.env.BANNER_PROMPT_VERSION || 'production',
  bannerValidatePromptVersion: process.env.BANNER_VALIDATE_PROMPT_VERSION || 'production',
},
```

---

### Step 6: Update API Route

**File**: `src/app/api/process-crosstab/route.ts`

**Changes:**
1. Survey file is now **required** (not optional)
2. Insert BannerValidateAgent between BannerAgent and CrosstabAgent
3. Use `toAgentFormat()` to convert for CrosstabAgent

```typescript
// Form data now requires 4 files
const formData = await request.formData();
const dataMapFile = formData.get('dataMap') as File;
const bannerPlanFile = formData.get('bannerPlan') as File;
const dataFile = formData.get('dataFile') as File;
const surveyFile = formData.get('survey') as File;  // NOW REQUIRED

// Validate all files present
if (!dataMapFile || !bannerPlanFile || !dataFile || !surveyFile) {
  return NextResponse.json(
    { error: 'Missing required files. Need: dataMap, bannerPlan, dataFile, survey' },
    { status: 400 }
  );
}

// ... existing BannerAgent processing ...

// NEW: Step 3b - Survey Validation
updateJob(jobId, {
  stage: 'banner_validate',
  percent: 35,
  message: 'Validating banner cuts against survey...'
});

// Save and extract survey text
const surveyExt = surveyFile.name.split('.').pop() || 'docx';
const surveyPath = path.join(sessionDir, `survey.${surveyExt}`);
await saveUploadedFile(surveyFile, sessionId, `survey.${surveyExt}`);

const surveyResult = await extractSurveyText(surveyPath);
if (!surveyResult.success) {
  throw new Error(`Survey extraction failed: ${surveyResult.errors.join(', ')}`);
}

// Run BannerValidateAgent
const { result: validatedGroups, processingLog: validationLog } = await validateAllGroups(
  surveyResult.text,
  bannerResult.agent,
  sessionId,
  (completed, total) => {
    updateJob(jobId, {
      percent: 35 + Math.round((completed / total) * 15),
      message: `Validating group ${completed}/${total}...`
    });
  }
);

// Log issues found
const totalIssues = validatedGroups.reduce((sum, g) =>
  sum + g.columns.filter(c => c.validation.flag).length, 0);
console.log(`[API] BannerValidateAgent found ${totalIssues} issues`);

// Convert to format CrosstabAgent expects (uses validatedExpression)
const agentBannerGroups = toAgentFormat(validatedGroups);

// Continue to CrosstabAgent with validated groups
// CrosstabAgent sees validatedExpression as "original"
const { result: crosstabResult } = await processAllGroups(
  dataMapResult.agent,
  { bannerCuts: agentBannerGroups },  // Uses validated expressions
  sessionId,
  // ... progress callback
);
```

---

### Step 7: Update Agent Index

**File**: `src/agents/index.ts`

Add new exports:

```typescript
// BannerValidateAgent exports
export {
  validateGroup,
  validateAllGroups,
  toAgentFormat,
  type ValidatedColumn,
  type ValidatedGroup,
  type BannerColumnInput,
  type BannerGroupInput
} from './BannerValidateAgent';

// SurveyProcessor export
export { extractSurveyText, type SurveyProcessingResult } from '../lib/processors/SurveyProcessor';
```

---

### Step 8: Install pdf-parse (for PDF survey support)

```bash
npm install pdf-parse
npm install --save-dev @types/pdf-parse
```

Note: `mammoth` is already installed (used by BannerAgent).

---

## Data Flow Summary

```
Input Files:
  - dataMap.csv
  - bannerPlan.doc
  - dataFile.sav
  - survey.doc (NEW, REQUIRED)

Pipeline:
  1. BannerAgent
     Input: bannerPlan.doc → images
     Output: [{groupName, columns: [{name, original}]}]

  2. BannerValidateAgent (NEW)
     Input: BannerAgent output + survey.doc → text
     Output: [{groupName, columns: [{name, original, validatedExpression, validation}]}]

  3. toAgentFormat() (NEW)
     Input: BannerValidateAgent output
     Output: [{groupName, columns: [{name, original: validatedExpression}]}]
     (Swaps validatedExpression into "original" field for CrosstabAgent)

  4. CrosstabAgent
     Input: toAgentFormat output + dataMap
     Output: [{groupName, columns: [{name, adjusted (R syntax), confidence, reason}]}]
     (Processes validatedExpression, unaware validation happened)

  5. R Script Generation
     (unchanged)
```

---

## Testing Plan

### Unit Tests

1. **Survey Text Extraction**
   - DOC extraction produces readable text
   - PDF extraction produces readable text
   - Question pattern detection works

2. **BannerValidateAgent**
   - Known impossible logic is flagged (`S2=1 AND S2a=1`)
   - `validatedExpression` contains the fix
   - Valid expressions pass unchanged
   - `toAgentFormat()` correctly swaps fields

### Integration Tests

1. **Full Pipeline with Survey**
   - Upload all 4 required files
   - Verify BannerValidateAgent runs
   - Verify validation output saved to temp-outputs
   - Verify CrosstabAgent receives validated expressions
   - Verify final R output uses fixed expressions

### Manual Testing Checklist

- [ ] Process current survey with known `S2=1 AND S2a=1` issue
- [ ] Verify issue is flagged with `impossible_logic`
- [ ] Verify `validatedExpression` is `S2=1 OR S2a=1` (or similar fix)
- [ ] Verify CrosstabAgent produces correct R syntax for the fix
- [ ] Verify final R output has non-zero base sizes

---

## Files to Create/Modify

| File | Action | Complexity |
|------|--------|------------|
| `src/lib/processors/SurveyProcessor.ts` | Create | Low |
| `src/agents/BannerValidateAgent.ts` | Create | Medium |
| `src/prompts/banner-validate/production.ts` | Create | Low |
| `src/prompts/index.ts` | Modify | Low |
| `src/lib/types.ts` | Modify | Low |
| `src/lib/env.ts` | Modify | Low |
| `src/app/api/process-crosstab/route.ts` | Modify | Medium |
| `src/agents/index.ts` | Modify | Low |

**Total new files**: 3
**Total modified files**: 5

---

## Rollback Plan

If issues arise, the change is isolated:

1. In API route, skip BannerValidateAgent and use `bannerResult.agent` directly
2. BannerValidateAgent files can remain (unused)
3. Survey file can be made optional again

```typescript
// Quick rollback in API route:
const agentBannerGroups = bannerResult.agent;  // Skip validation
```

---

## Success Criteria

- [ ] `S2=1 AND S2a=1` is flagged as `impossible_logic`
- [ ] `validatedExpression` contains a reasonable fix
- [ ] CrosstabAgent generates R syntax for the fixed expression
- [ ] Final R output produces non-zero base sizes
- [ ] Processing time increase is acceptable (target: <30s per group)
- [ ] Survey document (DOC or PDF) extracts cleanly

---

## Part 2: Table Formatting (Deferred)

### The Problem

Current R output for questions without explicit levels shows generic stats:
```r
# Metrics: N, Mean, Median, SD
```

Hawk Partners wants research-standard output:
- **Top 2 Box** (% answering 4 or 5 on 1-5 scale)
- **Bottom 2 Box** (% answering 1 or 2)
- Individual level breakdowns where appropriate

### Why It's Deferred

1. **Requirements unclear**: Need to understand exactly what formatting rules apply to which question types
2. **LLM is the right tool**: Determining "this is a 5-point Likert scale, show T2B/B2B" requires human-like judgment
3. **Survey context needed**: Same survey document would inform this, so Part 1 enables Part 2
4. **Part 1 is higher priority**: Catching impossible cuts is more urgent than formatting

### Approach for Part 2 (When Ready)

**TableFormatAgent** (LLM-based):
- Reads survey + data map
- For each question, determines:
  - Question type (Likert scale, multi-select, binary, numeric, etc.)
  - Appropriate display format (T2B/B2B, individual levels, mean only, etc.)
  - Scale anchors if applicable
- Outputs formatting spec that R script generator uses

**Why not deterministic parsing?**
- Current process uses human judgment ("this looks like a 5-point scale")
- LLMs are good at mimicking human judgment
- We're already faster/cheaper than $2,000/3-day baseline
- Reliability > optimization at this stage

### When to Revisit

After Part 1 is working:
1. Get examples of desired output formatting from actual Hawk Partners tabs
2. Document question type → display format mapping rules
3. Build TableFormatAgent with survey + data map context

---

## Changelog

| Date | Change |
|------|--------|
| 2026-01-02 | Initial plan created - Part 1 focus (BannerValidateAgent) |
| 2026-01-02 | Updated: `validatedExpression` approach, 3 issue types, survey required, reuse mammoth for text extraction |

---

*Created: January 2, 2026*
*Last Updated: January 2, 2026*
*Status: Ready for Implementation*
