# Phase 3: Parser Reliability & Loop Detection
 
## Context
 
This plan captures the strategic thinking for Phase 3 of the reliability plan. The core realization: **we got distracted assuming datamap parsing wouldn't work long-term, but we haven't actually tested that assumption.**
 
The previous "per-variable agent" approach was a dead end—preprocessing went from instant to 1 hour. Parser enhancement is the path forward.
 
---
 
## The Question We're Answering
 
> Is there really so much variance between different CSV versions of datamaps? Or can we enhance our deterministic parser to handle them reliably?
 
If the answer is "yes, we can parse them," that's far better than agent-based preprocessing.
 
---
 
## Phase 3A: Data Preparation (Manual)
 
**You (Jason) will do this:**
 
1. **Convert all workbooks to CSV**
   - Go through `data/test-data/` folders
   - Export each `.xlsx` datamap to `.csv` format
   - Standardized structure: `{project}/datamap.csv`, `data.sav`, `survey.docx`
 
2. **Create Tito's folder**
   ```
   data/titos-future-growth/
   ├── datamap.csv           # Converted from workbook
   ├── data-weighted.sav     # Weighted data file
   ├── data-unweighted.sav   # Unweighted data file (if exists)
   └── survey.docx           # Survey document
   ```
 
3. **Organize for analysis**
   - All CSVs in consistent location
   - Ready for systematic comparison
 
---
 
## Phase 3B: Parser Analysis
 
**Goal**: Empirical analysis of datamap CSV variance across all datasets.
 
### Step 1: Catalog CSV Structures
 
Compare CSVs across datasets to answer:
 
| Question | What We Learn |
|----------|---------------|
| Are column headers consistent? | Do all CSVs use same header names or different conventions? |
| How are variables identified? | `[A4]` brackets vs `A4:` colons vs other patterns? |
| How are answer options formatted? | Indented? Comma-separated? Numbered? |
| How are value ranges expressed? | `Values: 0-100` vs `0 to 100` vs other? |
| How are parent-child relationships shown? | Indentation? Naming (`A4r1c1`)? Both? |
 
### Step 2: Identify Variance Patterns
 
Categorize what we find:
 
1. **Universal patterns** — Same across all CSVs (current parser handles these)
2. **Predictable variants** — Different syntax, same meaning (parser could handle with conditionals)
3. **Unpredictable variants** — Genuinely different formats (may need format detection or user hint)
 
### Step 3: Parser Enhancement Recommendations
 
Based on findings, determine:
- What patterns should the parser handle deterministically?
- What edge cases warrant a fallback (agent or user prompt)?
- What confidence thresholds trigger human review?
 
---
 
## Phase 3C: Loop Detection
 
**Goal**: Detect loop variables so we can tell the user to stack their data.
 
### The De-Scoped Approach
 
We do NOT need to:
- Auto-stack data programmatically
- Transform wide → long format ourselves
 
We DO need to:
- Detect if dataset has loop variables
- Tell user: "We detected loops. Please upload stacked data."
- Handle already-stacked data correctly
 
### Detection Layers (from reliability-plan.md)
 
| Layer | Check | What It Confirms |
|-------|-------|------------------|
| 1 | Variable name pattern (`_1`, `_2` suffix) | Candidates for loop |
| 2 | Both are parent questions (not answer options) | Not just multi-select rows |
| 3 | Answer options match between the two | Same question structure repeated |
| 4 | Data file: `_2` only answered by subset | Confirms loop behavior |
 
### Implementation Location
 
**File**: `src/lib/processors/DataMapProcessor.ts`
**Method**: Add `detectLoopVariables()` after `normalizeVariableTypes()`
 
```typescript
// Pseudocode
detectLoopVariables(variables: ProcessedDataMapVariable[]): LoopDetectionResult {
  // Layer 1: Find suffix patterns
  const candidates = findSuffixPatterns(variables); // _1/_2, _a/_b, etc.
 
  // Layer 2: Filter to parent questions only
  const parentPairs = candidates.filter(pair =>
    pair.first.level === 'parent' && pair.second.level === 'parent'
  );
 
  // Layer 3: Check answer options match
  const confirmedLoops = parentPairs.filter(pair =>
    answerOptionsMatch(pair.first, pair.second)
  );
 
  return {
    hasLoops: confirmedLoops.length > 0,
    loopVariables: confirmedLoops,
    confidence: calculateConfidence(confirmedLoops)
  };
}
```
 
### UI Integration
 
When loops detected:
```
⚠️ Loop Variables Detected
 
We found questions that repeat across loop iterations (e.g., A4_1, A4_2).
 
To process this survey correctly, please upload stacked data where each
loop iteration is a separate row.
 
[Continue Anyway] [Upload Stacked Data]
```
 
---
 
## Phase 3D: Survey Classification
 
**Goal**: Can we classify survey type from parsing alone?
 
### Classification Targets
 
| Type | Detection Signals |
|------|-------------------|
| **MaxDiff** | Variables named `MD*`, `maxdiff*`, or answer options with "Best"/"Worst" patterns |
| **Discrete Choice/Conjoint** | Variables named `DCM*`, `conjoint*`, `choice*`, utility score patterns |
| **ATU (Awareness/Trial/Usage)** | Standard A/T/U question sequences, brand awareness grids |
| **Standard Survey** | None of the above patterns |
 
### Why This Matters
 
Different survey types need different handling:
- MaxDiff needs message text (datamap often just says "Message 1")
- Conjoint has derived utility scores
- ATU has standard table structures
 
Classification helps us:
1. Set user expectations ("This looks like a MaxDiff survey...")
2. Pre-configure agent behavior
3. Flag when we're out of our depth
 
### Implementation
 
Add `classifySurveyType()` to DataMapProcessor:
 
```typescript
classifySurveyType(variables: ProcessedDataMapVariable[]): SurveyClassification {
  return {
    type: 'standard' | 'maxdiff' | 'conjoint' | 'atu',
    confidence: number,
    signals: string[] // What patterns triggered classification
  };
}
```
 
---
 
## Phase 3E: Confidence & Flagging
 
**Goal**: Know when to trust the parser vs. when to flag for review.
 
### Current State
 
`DataMapProcessor.validateProcessedData()` returns a confidence score, but it's not used to trigger any action.
 
### Enhanced Confidence
 
Add specific confidence dimensions:
 
| Dimension | What It Measures |
|-----------|------------------|
| **Structure confidence** | Did we parse brackets/values/options correctly? |
| **Parent confidence** | Are parent-child relationships clear? |
| **Type confidence** | Did we identify variable types correctly? |
| **Loop confidence** | If loops detected, how certain are we? |
| **Classification confidence** | How confident in survey type? |
 
### Flagging Thresholds
 
```typescript
if (confidence.overall < 0.7) {
  // Flag for human review before proceeding
  return { needsReview: true, reasons: [...] };
}
 
if (confidence.loops < 0.8 && loopsDetected) {
  // Ask user to confirm loop detection
  return { confirmLoops: true };
}
```
 
### Integration Point
 
This is a UI concern—pipeline produces confidence scores, UI decides what to surface.
 
---
 
## Success Criteria
 
### Parser Analysis (3B)
- [ ] All test-data CSVs cataloged
- [ ] Variance patterns documented
- [ ] Parser enhancement plan created (or "no changes needed" conclusion)
 
### Loop Detection (3C)
- [ ] `detectLoopVariables()` implemented
- [ ] Tito's dataset correctly identifies loops
- [ ] UI prompt designed (even if not implemented)
 
### Survey Classification (3D)
- [ ] `classifySurveyType()` implemented
- [ ] At least MaxDiff detection working
- [ ] Classification added to pipeline output
 
### Confidence (3E)
- [ ] Multi-dimensional confidence scores
- [ ] Clear thresholds defined
- [ ] Flagging logic in place
 
---
 
## What This Enables
 
After Phase 3:
- **Broader testing (Phase 4)** can proceed with confidence
- **UI improvements** know what to prompt for
- **Antares requirements** for loop/weight support are addressed (detection + user guidance)
 
---
 
## Key Insight
 
> We don't need to solve stacking. We need to detect it and tell the user.
 
This de-scopes the problem significantly. The user stacks their own data (they know how), we just need to recognize when it's needed and handle stacked data correctly once provided.
 
---
 
*Created: February 5, 2026*
*Status: Planning complete, ready for Phase 3A (data preparation)*