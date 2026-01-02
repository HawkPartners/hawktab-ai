# Phase 2: Reliability Improvements

> **STATUS: DEFERRED**
>
> This plan is deferred until we test the core pipeline with a cleaner banner plan. The issues that motivated Phase 2 (impossible logic like `S2=1 AND S2a=1`) arose from a poorly-formatted banner plan. Before implementing validation agents and human review infrastructure, we need to confirm what issues persist even with clean, well-structured inputs.
>
> **Next Step**: Re-run the existing pipeline with a manually cleaned banner plan to identify which problems are input quality issues vs. actual pipeline limitations.

---

## Updated Approach: Two Human Review Points

When we return to this plan, the human-in-the-loop design should be restructured around **two review points** rather than one at the end:

### Review Point 1: After BannerValidateAgent (Before CrosstabAgent)

**Purpose**: Validate the extracted banner plan in language the user understands.

- Show the banner plan structure as extracted
- If BannerValidateAgent flags issues, present them in plain language:
  - *"We see S2=1 AND S2a=1 in your banner, but according to the survey, S2a only shows when S2≠1. These can't both be true. Did you mean S2=1 OR S2a=1 to capture Cardiologists and Cardiologists in PPAs?"*
- User confirms the suggested fix OR provides correction in their own words
- Corrections route back to adjust that group before proceeding

**Why here**: Users can validate "S2=1 OR S2a=1 for Cardiologists" - this is their language. They cannot validate `S2 == 1 | S2a == 1` - that's R code.

### Review Point 2: After DataValidator (Before R Execution)

**Purpose**: Confirm sample sizes look reasonable.

- Show base sizes per cut (n=77 for Cardiologists, n=0 for Midwest)
- Flag anomalies (zero-count, unexpectedly low)
- Likely a quick confirmation since logic was already validated at Review Point 1
- User can mark cuts to skip if base size is unacceptable

**Why here**: Users know what base sizes to expect. This catches data issues vs. logic issues.

### Why This Is Better Than Single End-of-Pipeline Review

| Review Point | User Sees | Can They Validate? |
|--------------|-----------|-------------------|
| After BannerValidateAgent | Plain language expressions | ✅ Yes |
| After DataValidator | Sample counts | ✅ Yes |
| After R execution (current plan) | R syntax + results | ❌ No - can only skip |

Putting substantive review at the end, after everything is in R code, means users can only toggle "skip" - they can't actually fix anything.

---

**When we implement this**, the structure below (Parts 2a, 2b, 2c) will need to be reorganized:
- Part 2a (BannerValidateAgent) stays mostly the same
- Part 2b (DataValidator) stays mostly the same
- Part 2c (Human Review) becomes two components: Review Point 1 UI and Review Point 2 UI

For now, the detailed implementation below represents the original single-review-point design.

---

## Overview

Phase 2 focuses on end-to-end reliability for the crosstab generation workflow. It consists of three parts:

| Part | Component | Description |
|------|-----------|-------------|
| **2a** | BannerValidateAgent | Semantic validation of banner cuts against survey skip logic |
| **2b** | DataValidator | Sample count validation before R execution |
| **2c** | Human Review Enhancement | Show sample counts, toggle valid/invalid, skip cuts |

**Branch**: `feature/phase-2-reliability`

---

## What Phase 2 Delivers

By the end of Phase 2, the system will:

1. **Catch impossible logic early** - BannerValidateAgent fixes `S2=1 AND S2a=1` → `S2=1 OR S2a=1` before CrosstabAgent
2. **Show sample counts before R execution** - DataValidator runs cuts against actual data
3. **Let humans validate by sample size** - "Does n=77 for Cardiologists look right?"
4. **Skip broken cuts** - Human marks cuts as invalid → skipped in final output

**What Phase 2 does NOT include**:
- Human editing of expressions (if a cut is broken, skip it or re-upload)
- Table formatting (Top 2 Box, etc.) - deferred to later phase

---

## Current vs. Proposed Flow

### Current Flow (Problems)
```
BannerAgent → CrosstabAgent → R Script → Errors found at execution
     ↓              ↓              ↓
  Extract:      Validate:       Execute:
  "S2=1 AND     "S2 exists?     "n=0 for this cut!"
   S2a=1"        S2a exists?"    (discovered too late)
                (syntax only)
```

### Proposed Flow (Reliability)
```
BannerAgent → BannerValidateAgent → CrosstabAgent → DataValidator → Human Review → R Script
     ↓              ↓                     ↓              ↓              ↓
  Extract:     Validate + Fix:       Generate R:    Get counts:    Show counts:
  "S2=1 AND    "Can't be true →      "S2 == 1 |    {"Cards": 234,  Cards: n=234 ✓
   S2a=1"       use S2=1 OR S2a=1"    S2a == 1"     "Midwest": 0}  Midwest: n=0 ❌
               (semantic check)                                     → Skip invalid
```

---

# Part 2a: BannerValidateAgent

## Goal

Add semantic validation of banner cuts using the survey document as context, catching impossible logic before it reaches CrosstabAgent.

## What It Does

| Input | Output |
|-------|--------|
| BannerAgent output (raw expressions) | Validated expressions with fixes applied |
| Survey document (text) | Flags for issues found |

**Example**:
- Input: `"S2=1 AND S2a=1"`
- Survey shows: "S2a: ASK IF S2≠1"
- Output: `validatedExpression: "S2=1 OR S2a=1"`, flag: `impossible_logic`

CrosstabAgent receives `validatedExpression` and processes the fixed version.

---

## Pre-Implementation Checklist

- [ ] Obtain survey document for test survey (DOC or PDF)
- [ ] Verify mammoth extracts survey text adequately (spot check)
- [ ] Review current BannerAgent output structure
- [ ] Identify known issues in current output (e.g., `S2=1 AND S2a=1`)

---

## Step-by-Step Implementation

### Step 2a.1: Create Survey Text Extraction Utility

**File**: `src/lib/processors/SurveyProcessor.ts`

**Purpose**: Extract text from survey document for BannerValidateAgent context.

**Key Insight**: We already use `mammoth.extractRawText()` in BannerAgent. Reuse it directly.

```typescript
/**
 * SurveyProcessor
 * Purpose: Extract text from survey document for BannerValidateAgent context
 * Input: Survey document (DOC/DOCX/PDF)
 * Output: Plain text content
 */

import mammoth from 'mammoth';
import fs from 'fs/promises';
import path from 'path';

export interface SurveyProcessingResult {
  success: boolean;
  text: string;
  questionCount: number;
  errors: string[];
  warnings: string[];
}

export async function extractSurveyText(filePath: string): Promise<SurveyProcessingResult> {
  const ext = path.extname(filePath).toLowerCase();

  try {
    let text: string;

    if (ext === '.doc' || ext === '.docx') {
      const result = await mammoth.extractRawText({ path: filePath });
      text = result.value;
    } else if (ext === '.pdf') {
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

    // Estimate question count
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

---

### Step 2a.2: Create BannerValidateAgent

**File**: `src/agents/BannerValidateAgent.ts`

**Purpose**: Validate banner cuts semantically, output `validatedExpression` for CrosstabAgent.

```typescript
/**
 * BannerValidateAgent
 * Purpose: Validate banner cuts against survey skip logic, provide fixes
 * Input: Banner agent output + Survey document text
 * Output: Banner groups with validatedExpression (what CrosstabAgent uses)
 */

import { generateText, Output, stepCountIs } from 'ai';
import { z } from 'zod';
import { getReasoningModel, getReasoningModelName, getReasoningModelTokenLimit, getPromptVersions } from '../lib/env';
import { scratchpadTool } from './tools/scratchpad';
import { getBannerValidatePrompt } from '../prompts';
import fs from 'fs/promises';
import path from 'path';

// Input schema (from BannerAgent)
export interface BannerColumnInput {
  name: string;
  original: string;
}

export interface BannerGroupInput {
  groupName: string;
  columns: BannerColumnInput[];
}

// Output schema
const ValidatedColumnSchema = z.object({
  name: z.string(),
  original: z.string(),
  validatedExpression: z.string().describe('The expression CrosstabAgent should use - either original (if valid) or the fix'),
  validation: z.object({
    flag: z.boolean().describe('True if the original expression had an issue'),
    issue: z.enum(['none', 'impossible_logic', 'ambiguous_expression', 'other']),
    reason: z.string().describe('Explanation of the issue, empty if none'),
    confidence: z.number().min(0).max(1)
  })
});

const ValidatedGroupSchema = z.object({
  groupName: z.string(),
  columns: z.array(ValidatedColumnSchema)
});

export type ValidatedColumn = z.infer<typeof ValidatedColumnSchema>;
export type ValidatedGroup = z.infer<typeof ValidatedGroupSchema>;

// Process single banner group
export async function validateGroup(
  surveyText: string,
  group: BannerGroupInput
): Promise<ValidatedGroup> {
  console.log(`[BannerValidateAgent] Validating group: ${group.groupName} (${group.columns.length} columns)`);

  try {
    const promptVersions = getPromptVersions();
    const systemPrompt = `
${getBannerValidatePrompt(promptVersions.bannerValidatePromptVersion || 'production')}

SURVEY DOCUMENT:
${surveyText}

BANNER GROUP TO VALIDATE:
Group: "${group.groupName}"
${JSON.stringify(group, null, 2)}

Begin validation now.
`;

    const { output } = await generateText({
      model: getReasoningModel(),
      system: systemPrompt,
      prompt: `Validate banner group "${group.groupName}" with ${group.columns.length} columns against the survey document.`,
      tools: { scratchpad: scratchpadTool },
      stopWhen: stepCountIs(25),
      maxOutputTokens: Math.min(getReasoningModelTokenLimit(), 10000),
      output: Output.object({ schema: ValidatedGroupSchema }),
    });

    if (!output || !output.columns) {
      throw new Error(`Invalid response for group ${group.groupName}`);
    }

    const issueCount = output.columns.filter(c => c.validation.flag).length;
    console.log(`[BannerValidateAgent] Group ${group.groupName} validated - ${issueCount} issues found`);

    return output;

  } catch (error) {
    console.error(`[BannerValidateAgent] Error validating group ${group.groupName}:`, error);

    // Passthrough on error
    return {
      groupName: group.groupName,
      columns: group.columns.map(col => ({
        name: col.name,
        original: col.original,
        validatedExpression: col.original,
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

  if (outputFolder) {
    await saveValidationOutputs(results, outputFolder, processingLog);
  }

  return { result: results, processingLog };
}

// Convert to format CrosstabAgent expects
export function toAgentFormat(validatedGroups: ValidatedGroup[]): BannerGroupInput[] {
  return validatedGroups.map(group => ({
    groupName: group.groupName,
    columns: group.columns.map(col => ({
      name: col.name,
      original: col.validatedExpression  // CrosstabAgent uses the validated expression
    }))
  }));
}

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

---

### Step 2a.3: Create BannerValidateAgent Prompt

**File**: `src/prompts/banner-validate/production.ts`

```typescript
export const BANNER_VALIDATE_INSTRUCTIONS_PRODUCTION = `
You are a BannerValidateAgent that validates banner plan expressions against survey skip logic.

YOUR TASK:
Review banner cut expressions and determine if they are semantically valid given the survey structure. If invalid, provide a fixed expression in "validatedExpression".

OUTPUT RULES:
- If VALID: validatedExpression = original
- If INVALID but fixable: validatedExpression = your fix
- If INVALID and unfixable: validatedExpression = original (let CrosstabAgent try)

ISSUE TYPES:

1. IMPOSSIBLE LOGIC (issue: "impossible_logic")
   - "S2=1 AND S2a=1" when S2a only shows if S2≠1
   - AND conditions that are mutually exclusive
   - FIX: Usually change AND to OR

2. AMBIGUOUS EXPRESSIONS (issue: "ambiguous_expression")
   - "IF HCP" - what variable defines HCP?
   - Conceptual terms without clear variable mapping
   - FIX: Map to specific variable if identifiable

3. OTHER (issue: "other")
   - Anything else that seems wrong

VALIDATION OUTPUT:
For each column provide:
- name: (copy from input)
- original: (copy from input)
- validatedExpression: THE EXPRESSION CROSSTABAGENT SHOULD USE
- validation.flag: true if there's ANY issue
- validation.issue: "none" | "impossible_logic" | "ambiguous_expression" | "other"
- validation.reason: explanation (empty if no issue)
- validation.confidence: 0.0-1.0

EXAMPLES:

Example 1 - Impossible Logic:
Input: { name: "Cards", original: "S2=1 AND S2a=1" }
Survey: "S2a: ASK IF S2≠1"
Output: {
  name: "Cards",
  original: "S2=1 AND S2a=1",
  validatedExpression: "S2=1 OR S2a=1",
  validation: { flag: true, issue: "impossible_logic", reason: "S2a only shows when S2≠1", confidence: 0.95 }
}

Example 2 - Valid Expression:
Input: { name: "PCPs", original: "S2=2" }
Output: {
  name: "PCPs",
  original: "S2=2",
  validatedExpression: "S2=2",
  validation: { flag: false, issue: "none", reason: "", confidence: 0.95 }
}

IMPORTANT:
- ALWAYS provide validatedExpression
- CrosstabAgent will use validatedExpression, not original
`;
```

---

### Step 2a.4: Update Prompt Index

**File**: `src/prompts/index.ts`

```typescript
export { BANNER_VALIDATE_INSTRUCTIONS_PRODUCTION } from './banner-validate/production';

export const getBannerValidatePrompt = (version: string): string => {
  switch (version) {
    case 'production':
    default:
      return BANNER_VALIDATE_INSTRUCTIONS_PRODUCTION;
  }
};
```

---

### Step 2a.5: Update Environment Configuration

**File**: `src/lib/env.ts`

```typescript
promptVersions: {
  crosstabPromptVersion: process.env.CROSSTAB_PROMPT_VERSION || 'production',
  bannerPromptVersion: process.env.BANNER_PROMPT_VERSION || 'production',
  bannerValidatePromptVersion: process.env.BANNER_VALIDATE_PROMPT_VERSION || 'production',
},
```

---

### Step 2a.6: Install pdf-parse

```bash
npm install pdf-parse
npm install --save-dev @types/pdf-parse
```

---

## Part 2a Files Summary

| File | Action |
|------|--------|
| `src/lib/processors/SurveyProcessor.ts` | Create |
| `src/agents/BannerValidateAgent.ts` | Create |
| `src/prompts/banner-validate/production.ts` | Create |
| `src/prompts/index.ts` | Modify |
| `src/lib/env.ts` | Modify |

---

# Part 2b: DataValidator

## Goal

Validate that banner cuts produce respondents BEFORE R execution, so humans can see sample sizes.

## What It Does

| Input | Output |
|-------|--------|
| R expressions from CrosstabAgent | Sample counts per cut |
| SPSS data file | Status flags (ok, low, zero, error) |

**Example**:
```json
{
  "results": [
    { "name": "Cardiologists", "n": 77, "status": "ok" },
    { "name": "Lipidologists", "n": 23, "status": "low" },
    { "name": "Midwest", "n": 0, "status": "zero" }
  ]
}
```

---

## Step-by-Step Implementation

### Step 2b.1: Create DataValidator R Script Generator

**File**: `src/lib/r/DataValidatorGenerator.ts`

```typescript
/**
 * DataValidatorGenerator
 * Purpose: Generate R script that validates cuts by counting respondents
 */

export interface CutForValidation {
  id: string;
  name: string;
  groupName: string;
  rExpression: string;
}

export interface DataValidatorConfig {
  dataFilePath: string;
  cuts: CutForValidation[];
  outputPath: string;
}

export function generateDataValidatorScript(config: DataValidatorConfig): string {
  const { dataFilePath, cuts, outputPath } = config;

  const cutDefinitions = cuts.map(cut => {
    const safeExpression = cut.rExpression.replace(/"/g, '\\"');
    return `  list(id = "${cut.id}", name = "${cut.name}", groupName = "${cut.groupName}", expr = "${safeExpression}")`;
  }).join(',\n');

  return `
# DataValidator Script
# Purpose: Validate cuts by counting respondents

library(haven)
library(jsonlite)

data <- read_sav("${dataFilePath}")
total_n <- nrow(data)

cuts_to_validate <- list(
${cutDefinitions}
)

results <- lapply(cuts_to_validate, function(cut) {
  tryCatch({
    mask <- with(data, eval(parse(text = cut$expr)))
    n <- sum(mask, na.rm = TRUE)

    list(
      id = cut$id,
      name = cut$name,
      groupName = cut$groupName,
      n = n,
      percent = round(n / total_n * 100, 1),
      status = ifelse(n == 0, "zero", ifelse(n < 30, "low", "ok")),
      error = NULL
    )
  }, error = function(e) {
    list(
      id = cut$id,
      name = cut$name,
      groupName = cut$groupName,
      n = NA,
      percent = NA,
      status = "error",
      error = e$message
    )
  })
})

output <- list(
  timestamp = Sys.time(),
  totalRespondents = total_n,
  cutsValidated = length(results),
  results = results,
  summary = list(
    ok = sum(sapply(results, function(r) r$status == "ok")),
    low = sum(sapply(results, function(r) r$status == "low")),
    zero = sum(sapply(results, function(r) r$status == "zero")),
    error = sum(sapply(results, function(r) r$status == "error"))
  )
)

writeLines(toJSON(output, auto_unbox = TRUE, pretty = TRUE), "${outputPath}")
`;
}
```

---

### Step 2b.2: Create DataValidator Executor

**File**: `src/lib/validators/DataValidator.ts`

```typescript
/**
 * DataValidator
 * Purpose: Execute DataValidator R script and return results
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import fs from 'fs/promises';
import path from 'path';
import { generateDataValidatorScript, CutForValidation } from '../r/DataValidatorGenerator';

const execAsync = promisify(exec);

export interface CutValidationResult {
  id: string;
  name: string;
  groupName: string;
  n: number | null;
  percent: number | null;
  status: 'ok' | 'low' | 'zero' | 'error';
  error: string | null;
}

export interface DataValidationResult {
  success: boolean;
  timestamp: string;
  totalRespondents: number;
  cutsValidated: number;
  results: CutValidationResult[];
  summary: {
    ok: number;
    low: number;
    zero: number;
    error: number;
  };
  errors: string[];
}

export interface CrosstabColumn {
  name: string;
  adjusted: string;
}

export interface CrosstabGroup {
  groupName: string;
  columns: CrosstabColumn[];
}

export function extractCutsForValidation(crosstabGroups: CrosstabGroup[]): CutForValidation[] {
  const cuts: CutForValidation[] = [];

  for (const group of crosstabGroups) {
    for (const col of group.columns) {
      cuts.push({
        id: `${group.groupName}_${col.name}`.toLowerCase().replace(/\s+/g, '_'),
        name: col.name,
        groupName: group.groupName,
        rExpression: col.adjusted
      });
    }
  }

  return cuts;
}

export async function validateData(
  crosstabGroups: CrosstabGroup[],
  dataFilePath: string,
  sessionFolder: string
): Promise<DataValidationResult> {
  const outputDir = path.join(process.cwd(), 'temp-outputs', sessionFolder);
  const scriptPath = path.join(outputDir, 'data-validator.R');
  const outputPath = path.join(outputDir, 'data-validation-results.json');

  console.log(`[DataValidator] Starting validation for ${crosstabGroups.length} groups`);

  try {
    await fs.mkdir(outputDir, { recursive: true });

    const cuts = extractCutsForValidation(crosstabGroups);
    console.log(`[DataValidator] Validating ${cuts.length} cuts`);

    const script = generateDataValidatorScript({
      dataFilePath,
      cuts,
      outputPath
    });

    await fs.writeFile(scriptPath, script, 'utf-8');

    const { stdout, stderr } = await execAsync(`Rscript "${scriptPath}"`, {
      timeout: 60000,
      cwd: outputDir
    });

    if (stderr && !stderr.includes('Loading required package')) {
      console.warn(`[DataValidator] R stderr: ${stderr}`);
    }

    const resultsJson = await fs.readFile(outputPath, 'utf-8');
    const results = JSON.parse(resultsJson);

    console.log(`[DataValidator] Complete - ${results.summary.zero} zero-count cuts`);

    return {
      success: true,
      timestamp: results.timestamp,
      totalRespondents: results.totalRespondents,
      cutsValidated: results.cutsValidated,
      results: results.results,
      summary: results.summary,
      errors: []
    };

  } catch (error) {
    console.error('[DataValidator] Validation failed:', error);

    return {
      success: false,
      timestamp: new Date().toISOString(),
      totalRespondents: 0,
      cutsValidated: 0,
      results: [],
      summary: { ok: 0, low: 0, zero: 0, error: 0 },
      errors: [error instanceof Error ? error.message : 'Unknown error']
    };
  }
}
```

---

### Step 2b.3: Integrate DataValidator into Pipeline

**File**: `src/app/api/process-crosstab/route.ts`

Add after CrosstabAgent:

```typescript
// After CrosstabAgent processing...

updateJob(jobId, {
  stage: 'data_validation',
  percent: 70,
  message: 'Validating sample counts...'
});

const dataValidationResult = await validateData(
  crosstabResult.bannerCuts,
  path.join(sessionDir, 'dataFile.sav'),
  sessionId
);

console.log(`[API] DataValidator: ${dataValidationResult.summary.zero} zero-count, ${dataValidationResult.summary.low} low-count`);
```

---

## Part 2b Files Summary

| File | Action |
|------|--------|
| `src/lib/r/DataValidatorGenerator.ts` | Create |
| `src/lib/validators/DataValidator.ts` | Create |
| `src/app/api/process-crosstab/route.ts` | Modify |

---

# Part 2c: Human Review Enhancement

## Goal

Show sample counts so humans can validate cuts are plausible. Allow them to mark cuts as invalid (skip in output).

## What It Does

**Shows**:
- Groups and columns mirroring the Banner Plan
- Sample sizes per cut (n=77, n=0, etc.)
- Visual flags for zero-count (❌) and low-count (⚠️)

**Allows**:
- Toggle cuts valid/invalid
- Invalid cuts are skipped in R output
- Skip Review button to proceed with defaults

**Does NOT include**:
- Human editing of expressions
- R expressions (users can't validate those)
- AI confidence scores (not useful to humans)

## Design Principles

### 1. Mirror the Banner Plan Structure

```
Group: Specialty
├── Cardiologists     n=77   ✓  [Valid]
├── Lipidologists     n=23   ⚠️  [Valid]
├── Endocrinologists  n=45   ✓  [Valid]
└── PCPs              n=234  ✓  [Valid]

Group: Region
├── Northeast         n=112  ✓  [Valid]
├── Southeast         n=98   ✓  [Valid]
├── Midwest           n=0    ❌  [Invalid]  ← defaults to invalid
└── West              n=189  ✓  [Valid]
```

### 2. Sample Counts Are the Validation Signal

Humans can validate: "Does n=77 for Cardiologists make sense?"

Humans cannot validate: "Is `S2 == 1 | S2a == 1` correct?"

### 3. Invalid = Skip

If a cut is marked invalid:
- It is excluded from the final R script
- No output for that cut in the crosstabs
- User can re-upload with a fixed banner plan if needed

### 4. Skip Review = Proceed with Defaults

"Skip Review" at the top level means:
- Accept all cuts with n>0 as valid
- Accept all cuts with n=0 as invalid (skip them)
- Proceed to R generation

---

## Step-by-Step Implementation

### Step 2c.1: Create Human Review Schema

**File**: `src/schemas/humanReviewSchema.ts`

```typescript
import { z } from 'zod';

export const ReviewCutSchema = z.object({
  id: z.string(),
  name: z.string(),
  groupName: z.string(),
  n: z.number().nullable(),
  percent: z.number().nullable(),
  status: z.enum(['ok', 'low', 'zero', 'error']),
  isValid: z.boolean()  // Human's decision: include in output or skip
});

export const ReviewGroupSchema = z.object({
  groupName: z.string(),
  groupTotal: z.number().nullable(),
  cuts: z.array(ReviewCutSchema)
});

export const HumanReviewSchema = z.object({
  sessionId: z.string(),
  reviewedAt: z.string().optional(),
  groups: z.array(ReviewGroupSchema),
  summary: z.object({
    totalCuts: z.number(),
    validCuts: z.number(),
    invalidCuts: z.number(),
    zeroCuts: z.number(),
    lowCuts: z.number()
  }),
  notes: z.string().optional(),
  status: z.enum(['pending', 'reviewed', 'skipped'])
});

export type ReviewCut = z.infer<typeof ReviewCutSchema>;
export type ReviewGroup = z.infer<typeof ReviewGroupSchema>;
export type HumanReview = z.infer<typeof HumanReviewSchema>;
```

---

### Step 2c.2: Create Review Data Builder

**File**: `src/lib/review/buildReviewData.ts`

```typescript
/**
 * buildReviewData
 * Purpose: Transform DataValidator results into human review structure
 */

import { DataValidationResult, CutValidationResult } from '../validators/DataValidator';
import { HumanReview, ReviewGroup, ReviewCut } from '../../schemas/humanReviewSchema';

export function buildReviewData(
  sessionId: string,
  validationResult: DataValidationResult
): HumanReview {
  const groupsMap = new Map<string, CutValidationResult[]>();

  for (const result of validationResult.results) {
    const existing = groupsMap.get(result.groupName) || [];
    existing.push(result);
    groupsMap.set(result.groupName, existing);
  }

  const groups: ReviewGroup[] = [];

  for (const [groupName, cuts] of groupsMap) {
    const groupTotal = cuts.reduce((sum, cut) => sum + (cut.n ?? 0), 0);

    const reviewCuts: ReviewCut[] = cuts.map(cut => ({
      id: cut.id,
      name: cut.name,
      groupName: cut.groupName,
      n: cut.n,
      percent: cut.percent,
      status: cut.status,
      // Default: valid unless n=0
      isValid: cut.status !== 'zero'
    }));

    groups.push({ groupName, groupTotal, cuts: reviewCuts });
  }

  const allCuts = groups.flatMap(g => g.cuts);

  return {
    sessionId,
    groups,
    summary: {
      totalCuts: allCuts.length,
      validCuts: allCuts.filter(c => c.isValid).length,
      invalidCuts: allCuts.filter(c => !c.isValid).length,
      zeroCuts: allCuts.filter(c => c.status === 'zero').length,
      lowCuts: allCuts.filter(c => c.status === 'low').length
    },
    status: 'pending'
  };
}
```

---

### Step 2c.3: Update Review UI Component

**File**: `src/app/validate/[sessionId]/page.tsx`

```tsx
interface ReviewUIProps {
  reviewData: HumanReview;
  onSave: (review: HumanReview) => Promise<void>;
  onSkip: () => Promise<void>;
}

function ReviewUI({ reviewData, onSave, onSkip }: ReviewUIProps) {
  const [groups, setGroups] = useState(reviewData.groups);
  const [notes, setNotes] = useState('');

  const toggleCutValid = (groupName: string, cutId: string) => {
    setGroups(prev => prev.map(group => {
      if (group.groupName !== groupName) return group;
      return {
        ...group,
        cuts: group.cuts.map(cut => {
          if (cut.id !== cutId) return cut;
          return { ...cut, isValid: !cut.isValid };
        })
      };
    }));
  };

  return (
    <div className="review-container">
      <div className="review-header">
        <h1>Review Sample Sizes</h1>
        <div className="summary">
          <span>{reviewData.summary.totalCuts} cuts</span>
          {reviewData.summary.zeroCuts > 0 && (
            <span className="error">{reviewData.summary.zeroCuts} zero-count (will be skipped)</span>
          )}
          {reviewData.summary.lowCuts > 0 && (
            <span className="warning">{reviewData.summary.lowCuts} low-count (n&lt;30)</span>
          )}
        </div>
      </div>

      {groups.map(group => (
        <div key={group.groupName} className="review-group">
          <div className="group-header">
            <h2>{group.groupName}</h2>
            <span className="group-total">n={group.groupTotal}</span>
          </div>

          <div className="cuts-list">
            {group.cuts.map(cut => (
              <div key={cut.id} className={`cut-row ${cut.status}`}>
                <span className="cut-name">{cut.name}</span>
                <span className="cut-n">
                  n={cut.n ?? '?'}
                  {cut.status === 'zero' && ' ❌'}
                  {cut.status === 'low' && ' ⚠️'}
                  {cut.status === 'ok' && ' ✓'}
                </span>
                <button
                  className={`valid-toggle ${cut.isValid ? 'valid' : 'invalid'}`}
                  onClick={() => toggleCutValid(group.groupName, cut.id)}
                >
                  {cut.isValid ? 'Valid' : 'Skip'}
                </button>
              </div>
            ))}
          </div>
        </div>
      ))}

      <textarea
        placeholder="Add notes (optional)"
        value={notes}
        onChange={e => setNotes(e.target.value)}
      />

      <div className="actions">
        <button className="skip-btn" onClick={onSkip}>
          Skip Review (use defaults)
        </button>
        <button
          className="save-btn primary"
          onClick={() => onSave({ ...reviewData, groups, notes, status: 'reviewed' })}
        >
          Save & Continue
        </button>
      </div>
    </div>
  );
}
```

---

### Step 2c.4: Update R Script Generator to Skip Invalid Cuts

**File**: `src/lib/r/RScriptGenerator.ts`

```typescript
function buildCutsFromReview(
  crosstabGroups: CrosstabGroup[],
  humanReview?: HumanReview
): CutDefinition[] {
  const cuts: CutDefinition[] = [];

  for (const group of crosstabGroups) {
    for (const col of group.columns) {
      // Find human review for this cut
      const reviewCut = humanReview?.groups
        .find(g => g.groupName === group.groupName)
        ?.cuts
        .find(c => c.name === col.name);

      // Skip if human marked as invalid
      if (reviewCut && !reviewCut.isValid) {
        console.log(`[RScriptGenerator] Skipping invalid cut: ${col.name}`);
        continue;
      }

      cuts.push({
        id: `${group.groupName}_${col.name}`.toLowerCase().replace(/\s+/g, '_'),
        name: col.name,
        groupName: group.groupName,
        rExpression: col.adjusted
      });
    }
  }

  return cuts;
}
```

---

### Step 2c.5: Update Validation API

**File**: `src/app/api/validate/[sessionId]/route.ts`

```typescript
// POST handler for saving review
export async function POST(request: NextRequest, { params }: { params: { sessionId: string } }) {
  const { sessionId } = params;
  const humanReview: HumanReview = await request.json();

  // Save review
  await fs.writeFile(
    path.join(sessionDir, 'human-review.json'),
    JSON.stringify(humanReview, null, 2)
  );

  // Update validation status
  await fs.writeFile(
    path.join(sessionDir, 'validation-status.json'),
    JSON.stringify({
      status: humanReview.status,
      reviewedAt: new Date().toISOString(),
      validCuts: humanReview.summary.validCuts,
      skippedCuts: humanReview.summary.invalidCuts
    }, null, 2)
  );

  // Proceed to R generation
  // R generator will read human-review.json and skip invalid cuts

  return NextResponse.json({ success: true });
}
```

---

## Part 2c Files Summary

| File | Action |
|------|--------|
| `src/schemas/humanReviewSchema.ts` | Create |
| `src/lib/review/buildReviewData.ts` | Create |
| `src/app/validate/[sessionId]/page.tsx` | Modify |
| `src/lib/r/RScriptGenerator.ts` | Modify |
| `src/app/api/validate/[sessionId]/route.ts` | Modify |

---

# Complete Data Flow

```
Upload: Banner PDF + Data Map CSV + SPSS + Survey Doc (4 files)
                            ↓
┌───────────────────────────────────────────────────────────────────────┐
│ BannerAgent (existing)                                                 │
│   Extracts banner structure from PDF/DOC                               │
│   Output: Groups with columns and original expressions                 │
└───────────────────────────────────────────────────────────────────────┘
                            ↓
┌───────────────────────────────────────────────────────────────────────┐
│ Part 2a: BannerValidateAgent (NEW)                                     │
│   Validates expressions against survey skip logic                      │
│   Fixes impossible logic: "S2=1 AND S2a=1" → "S2=1 OR S2a=1"          │
│   Output: validatedExpression for each column                          │
└───────────────────────────────────────────────────────────────────────┘
                            ↓
┌───────────────────────────────────────────────────────────────────────┐
│ CrosstabAgent (existing)                                               │
│   Converts expressions to R syntax                                     │
│   Uses validatedExpression (doesn't know about validation)             │
│   Output: R expressions with confidence scores                         │
└───────────────────────────────────────────────────────────────────────┘
                            ↓
┌───────────────────────────────────────────────────────────────────────┐
│ Part 2b: DataValidator (NEW)                                           │
│   Runs R script to count respondents per cut                          │
│   Output: {"Cardiologists": 77, "Midwest": 0, ...}                    │
│   Flags: ok (n≥30), low (n<30), zero (n=0), error                     │
└───────────────────────────────────────────────────────────────────────┘
                            ↓
┌───────────────────────────────────────────────────────────────────────┐
│ Part 2c: Human Review (ENHANCED)                                       │
│   Shows: Groups → Columns → Sample sizes                               │
│   User toggles: Valid (include) or Invalid (skip)                     │
│   n=0 defaults to Invalid                                              │
│   Can skip review entirely (use defaults)                             │
└───────────────────────────────────────────────────────────────────────┘
                            ↓
┌───────────────────────────────────────────────────────────────────────┐
│ R Script Generator (existing, MODIFIED)                                │
│   Reads human review, skips invalid cuts                               │
│   Output: Final R script with only valid cuts                          │
└───────────────────────────────────────────────────────────────────────┘
                            ↓
                    Final Crosstabs
```

---

# Testing Plan

## Part 2a Tests

- [ ] Survey text extraction (DOC, DOCX, PDF)
- [ ] `S2=1 AND S2a=1` flagged as `impossible_logic`
- [ ] `validatedExpression` contains the fix
- [ ] Valid expressions pass unchanged
- [ ] `toAgentFormat()` correctly swaps fields

## Part 2b Tests

- [ ] DataValidator R script generates correctly
- [ ] Counts are accurate against known SPSS data
- [ ] Zero-count cuts have `status: "zero"`
- [ ] Low-count cuts (n<30) have `status: "low"`
- [ ] R errors are caught and reported

## Part 2c Tests

- [ ] Review UI shows groups and sample sizes
- [ ] Zero-count cuts default to Invalid
- [ ] Toggle changes `isValid` state
- [ ] Skip Review proceeds with defaults
- [ ] R Generator skips invalid cuts
- [ ] Final R output excludes skipped cuts

---

# Success Criteria

- [ ] `S2=1 AND S2a=1` is flagged and fixed before R execution
- [ ] Sample counts are visible in human review
- [ ] Zero-count cuts are flagged and default to skip
- [ ] Human can mark any cut as invalid (skipped in R output)
- [ ] Human can skip review entirely (uses defaults)
- [ ] Final R output only includes valid cuts

---

# Changelog

| Date | Change |
|------|--------|
| 2026-01-02 | Initial plan - Part 2a (BannerValidateAgent) |
| 2026-01-02 | Added Part 2b (DataValidator) and Part 2c (Human Review) |
| 2026-01-02 | Restructured as Phase 2a/2b/2c |
| 2026-01-02 | Removed human edit feature - v1 is toggle valid/invalid only |
| 2026-01-02 | **DEFERRED** - Plan paused until core pipeline tested with cleaner banner plan |
| 2026-01-02 | Added two-review-point framework (Review Point 1 after BannerValidateAgent, Review Point 2 after DataValidator) |

---

*Created: January 2, 2026*
*Last Updated: January 2, 2026*
*Status: Deferred - Testing core pipeline with clean inputs first*
