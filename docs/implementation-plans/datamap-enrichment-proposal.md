# DataMap Enrichment Proposal

## The Question

> Can we extract MORE information RELIABLY from datamaps to help downstream systems?

**Answer**: Yes. We can add three new classification dimensions with high reliability.

---

## Current State

The DataMapProcessor currently extracts:
- Variable name and description ✓
- Level (parent/sub) ✓
- Answer options (when present) ✓
- Value ranges ✓
- Parent-child relationships ✓
- `normalizedType` (8 granular types) - **overcomplicated**

What's missing:
- Research type classification
- Variable source (list vs survey vs admin)
- Simplified, actionable typing

---

## Proposed Enhancements

### 1. Research Type Detection

**Why it matters**: Different research types need different handling. MaxDiff has utility scores. DCM has choice tasks. Message testing needs actual message text.

**Detection signals** (tested against 25 datamaps):

| Research Type | Detection Patterns | Confidence |
|--------------|-------------------|------------|
| **MaxDiff** | Variables with `maxdiff`, `md_`; descriptions with "best/worst", "most/least appealing" | High |
| **DCM/Conjoint** | Variables with `dcm`, `conjoint`, `choice`; "utility" in descriptions | High |
| **Message Testing** | "message N" patterns; "appeal" + "message" | Medium |
| **Segmentation** | "segment" or "cluster" in variables | High |
| **ATU** | "awareness" + "trial/usage"; "ever heard/used" | Medium |
| **Standard** | None of the above | Default |

**Implementation**:
```typescript
interface ResearchTypeClassification {
  type: 'standard' | 'maxdiff' | 'dcm' | 'message_testing' | 'segmentation' | 'atu';
  confidence: number;
  signals: string[];  // What triggered classification
}
```

**Downstream benefit**:
- UI can prompt for missing context ("This looks like MaxDiff - please provide message text")
- Agent prompts can be specialized per research type
- We know when we're out of our depth

---

### 2. Variable Source Classification

**Why it matters**: Not everything in a datamap is a survey question. Some came from the sample list. Some are system metadata. Downstream systems need to know what to process vs ignore.

**Four sources** (mutually exclusive):

| Source | What It Is | How to Detect | Crosstab Role |
|--------|-----------|---------------|---------------|
| **admin** | System infrastructure | `record`, `uuid`, `date`, `status`, `pagetime*`, `qtime` | Exclude |
| **list** | Sample/client data | `npi*`, `ims_*`, `aaid`, `*tier*`, `*list*`, "captured variable" | Banner cuts only |
| **quality** | Fraud/quality control | `rd_*`, `speeder*`, `trap_*`, "research defender" | Filter, then exclude |
| **survey** | Respondent answers | Everything else | Full processing |

**Implementation**:
```typescript
interface VariableSource {
  source: 'admin' | 'list' | 'quality' | 'survey';
  confidence: number;
}
```

**Downstream benefit**:
- TableGenerator skips admin/quality variables
- BannerAgent knows which variables are valid for cuts
- Excel output doesn't include garbage tables

---

### 3. Simplified Type Classification

**Current problem**: We have 8 `normalizedType` values that overlap and confuse:
- `numeric_range` vs `ordinal_scale` - both can be scales
- `categorical_select` vs `matrix_single_choice` - same thing
- `admin` is a source, not a type

**Proposed simplification** (5 types):

| Type | What It Means | How to Detect | Table Treatment |
|------|--------------|---------------|-----------------|
| **categorical** | Discrete options with labels | Has answer options OR range ≤50 | Show percentages per option |
| **numeric** | Continuous values | `Open numeric` OR range >50 (age, patient counts) | Show mean |
| **binary** | 0/1 checkbox | `Values: 0-1` with Unchecked/Checked | Show % checked |
| **text** | Open-ended text | `Open text response` | Exclude or appendix |
| **derived** | Computed/hidden | Starts with `h` + uppercase, or "hidden" in desc | Depends on use |

**Key insight**: "Ordinal", "ranking", "scale" are all just `categorical` - they have discrete options. The statistical treatment (mean vs percentage) depends on the research question, not the data structure.

**Implementation**:
```typescript
type SimplifiedType = 'categorical' | 'numeric' | 'binary' | 'text' | 'derived';
```

**Downstream benefit**:
- TableGenerator knows whether to show means or percentages
- Less confusion in agent prompts
- Cleaner schema

---

## Reliability Assessment

| Enhancement | Detection Accuracy | False Positive Risk | Recommendation |
|-------------|-------------------|--------------------|-----------------|
| Research type | ~85% | Low (worst case = "standard") | **Ship it** |
| Variable source | ~95% | Very low | **Ship it** |
| Simplified types | ~98% | Very low | **Ship it** |

All three are deterministic pattern matching - no AI needed. They fail gracefully to safe defaults.

---

## What We CAN'T Reliably Detect

| Thing | Why It's Hard | Workaround |
|-------|--------------|------------|
| Skip logic | Requires survey programming doc | Ask user or infer from data |
| Piped text | `[pipe:X]` references | Leave as-is, let VerificationAgent handle |
| Question intent | "Is this a key metric?" | Needs human judgment |
| MaxDiff messages | Datamap says "Message 1" not actual text | Require user upload |
| Brand names | May be codes in datamap | Survey doc or user input |

---

## Implementation Plan

### Phase 1: Add Classifications (No Breaking Changes)

Add new optional fields to `ProcessedDataMapVariable`:

```typescript
interface ProcessedDataMapVariable {
  // ... existing fields ...

  // NEW: Source classification
  variableSource?: 'admin' | 'list' | 'quality' | 'survey';
  sourceConfidence?: number;

  // NEW: Simplified type (replaces normalizedType eventually)
  simpleType?: 'categorical' | 'numeric' | 'binary' | 'text' | 'derived';
}

// NEW: Survey-level classification
interface DataMapMetadata {
  researchType: 'standard' | 'maxdiff' | 'dcm' | 'message_testing' | 'segmentation' | 'atu';
  researchTypeConfidence: number;
  researchTypeSignals: string[];

  // Stats
  totalVariables: number;
  surveyVariables: number;
  listVariables: number;
  adminVariables: number;
}
```

### Phase 2: Use in TableGenerator

```typescript
// Skip non-survey variables
const surveyVars = variables.filter(v => v.variableSource === 'survey');

// Determine table type
if (variable.simpleType === 'numeric') {
  // Generate mean row
} else if (variable.simpleType === 'binary') {
  // Generate single percentage row
} else {
  // Generate percentage per answer option
}
```

### Phase 3: UI Integration

Show research type in pipeline UI:
```
📊 Detected Research Type: MaxDiff (3 signals)
   - Found "best/worst" patterns
   - Found "most appealing" in descriptions

⚠️ MaxDiff surveys typically need message text.
   Would you like to upload a message list?
```

---

## Summary

| What | Adds | Effort | Impact |
|------|------|--------|--------|
| Format detection | Routes to correct parser | Medium | Critical (81% of files) |
| Research type | Survey-level classification | Low | High (sets expectations) |
| Variable source | Filter admin/list/quality | Low | High (cleaner output) |
| Simplified types | Cleaner downstream logic | Low | Medium (less confusion) |

**Recommended order**:
1. Format detection (unblocks 81% of files)
2. Variable source (immediate cleanup benefit)
3. Simplified types (cleaner code)
4. Research type (better UX)

---

*Created: February 5, 2026*
