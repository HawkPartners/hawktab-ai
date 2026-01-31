# BaseFilterAgent Implementation Plan

**Status**: Design complete, not started
**Created**: 2026-01-31
**Related**: `docs/implementation-plans/verification-agent-improvements.md` (System 4)

---

## Why This Agent Exists

### The Problem

Our current pipeline calculates table bases using `cut filter + non-NA values`. This works for most questions, but fails when questions have **row-level skip logic** that creates more restrictive filters.

**Example (A3a):**
- Survey says: "ONLY SHOW THERAPY WHERE A3>0"
- Leqvio row should only include respondents where `A3r2 > 0` (n=135)
- We include everyone shown the question (n=141)
- Result: 6 respondents with meaningless data pollute the base

### Why a Dedicated Agent

1. **VerificationAgent is overloaded** - Already handles table design, NETs, labels, exclusions
2. **Survey conventions vary** - Can't rely on parsing "ONLY SHOW X WHERE Y" patterns
3. **Requires intelligence** - Need to reason about survey context, variable relationships
4. **Focused scope = better results** - Single responsibility, can optimize independently

### Trade-offs Acknowledged

- **Adds time**: Another agent call in the pipeline
- **Adds cost**: More API calls (mitigated by low reasoning effort + parallelization)
- **Worth it**: This is table-stakes for production quality; any human analyst does this intuitively

---

## Mission

> Determine if each table requires additional base filtering beyond the standard cut + non-NA logic. Output a filter expression that gets ANDed with existing cuts. Flag uncertain cases for human review.

**What it does:**
- Reviews each table's survey context and skip logic
- Identifies when additional filtering is needed
- Outputs R expressions to tighten the base filter

**What it does NOT do:**
- Restructure tables (VerificationAgent's job)
- Validate R expressions (separate validation step)
- Make table design decisions

---

## Pipeline Position

```
DataMap → Banner → Crosstab → Table → Verification → BaseFilter → R Script → Excel
                                              │              │
                                              │              ↓
                                              │      Adds additionalFilter
                                              │      to each table
                                              │              │
                                              ↓              ↓
                                        Table design    R script uses
                                        is finalized    filter in calc
```

**Runs after**: VerificationAgent (tables are finalized)
**Runs before**: R Script Generator (needs filter expressions)
**Could also run after**: R Script validation (to have even more context)

---

## How It Works

### Input (per table)

```typescript
interface BaseFilterAgentInput {
  table: ExtendedTableDefinition;     // The finalized table
  datamapContext: DatamapVariable[];  // All variables BEFORE this questionId
  surveyExcerpt: string;              // Question text + skip logic instructions
}
```

**Why "variables before"**: Skip logic inherently references prior questions. This is conservative and mirrors how surveys work.

### Output (per table)

```typescript
interface BaseFilterAgentOutput {
  tableId: string;
  additionalFilter: string | null;    // R expression, e.g., "A3r2 > 0"
  filterReason: string;               // Plain English, e.g., "Only those who prescribed Leqvio"
  confidence: number;                 // 0.0 - 1.0
  humanReviewRequired: boolean;
  reasoning: string;                  // Brief explanation of decision
}
```

### Execution Strategy

- **Model**: gpt-5-mini (same as other agents)
- **Reasoning effort**: Low or medium (focused task)
- **Parallelization**: 3 agents, each handles ~1/3 of tables
- **Batching**: Could batch multiple tables per call to reduce overhead

---

## Schema Changes

### ExtendedTableDefinition (verificationAgentSchema.ts)

Add new fields:

```typescript
// Base filter fields (populated by BaseFilterAgent)
additionalFilter?: string;      // R expression to AND with cuts
filterReason?: string;          // Plain English explanation
filterConfidence?: number;      // 0.0 - 1.0
filterReviewRequired?: boolean; // Flag for human review
```

### New Schema File (baseFilterAgentSchema.ts)

```typescript
import { z } from 'zod';

export const BaseFilterResultSchema = z.object({
  tableId: z.string(),
  additionalFilter: z.string().nullable(),
  filterReason: z.string(),
  confidence: z.number().min(0).max(1),
  humanReviewRequired: z.boolean(),
  reasoning: z.string(),
});

export const BaseFilterAgentOutputSchema = z.object({
  results: z.array(BaseFilterResultSchema),
});

export type BaseFilterResult = z.infer<typeof BaseFilterResultSchema>;
export type BaseFilterAgentOutput = z.infer<typeof BaseFilterAgentOutputSchema>;
```

---

## Code Changes Required

### New Files

| File | Purpose |
|------|---------|
| `src/agents/BaseFilterAgent.ts` | Agent implementation |
| `src/schemas/baseFilterAgentSchema.ts` | Zod schemas |
| `src/prompts/baseFilterAgentPrompt.ts` | Prompt template |

### Modified Files

| File | Change |
|------|--------|
| `src/schemas/verificationAgentSchema.ts` | Add filter fields to ExtendedTableDefinition |
| `src/lib/r/RScriptGeneratorV2.ts` | Apply additionalFilter when calculating tables |
| `scripts/test-pipeline.ts` | Add BaseFilterAgent step |
| `src/lib/excel/ExcelFormatter.ts` | Optionally render filterReason in base text |

---

## R Script Integration

When a table has `additionalFilter`, the R script applies it:

```r
for (cut_name in names(cuts)) {
  cut_data <- apply_cut(data, cuts[[cut_name]])

  # NEW: Apply table-specific additional filter
  if (!is.null(table$additionalFilter) && nchar(table$additionalFilter) > 0) {
    additional_mask <- with(cut_data, eval(parse(text = table$additionalFilter)))
    additional_mask[is.na(additional_mask)] <- FALSE
    table_data <- cut_data[additional_mask, ]
  } else {
    table_data <- cut_data
  }

  # Calculate statistics on table_data (not cut_data)
  base_n <- nrow(table_data)
  # ... rest of calculation
}
```

**Key principle**: The filter is ANDed with the cut. Respondents must:
1. Pass the cut filter (e.g., Total, or Email Channel)
2. AND pass the additional filter (e.g., A3r2 > 0)

---

## Human Review Integration

Similar to banner cuts, uncertain cases should be flagged:

```typescript
if (result.confidence < 0.7 || result.humanReviewRequired) {
  // Add to review queue
  reviewItems.push({
    type: 'base_filter',
    tableId: result.tableId,
    proposedFilter: result.additionalFilter,
    reason: result.filterReason,
    confidence: result.confidence,
    agentReasoning: result.reasoning,
  });
}
```

**Review UI considerations:**
- Show the table context
- Show the proposed filter and reasoning
- Allow approve / reject / modify
- Store decisions for future learning

---

## Open Questions for Implementation

### Pipeline Questions

1. **Exact timing**: After VerificationAgent or after R validation?
   - After verification: Has table definitions, can run sooner
   - After R validation: Has validated data, knows what variables exist

2. **Batching strategy**: How many tables per agent call?
   - Too few = many API calls = slow
   - Too many = large context = potential quality issues
   - Suggestion: 10-15 tables per batch

3. **Parallel execution**: How to orchestrate 3 parallel agents?
   - Split tables into 3 groups
   - Run concurrently
   - Merge results

### Schema Questions

4. **Where to store results?**
   - Option A: Add fields to ExtendedTableDefinition (inline)
   - Option B: Separate file (base-filters.json)
   - Recommendation: Inline for simplicity

5. **How to handle "no filter needed"?**
   - `additionalFilter: null` or `additionalFilter: ""`
   - Recommendation: `null` for clarity

### Rendering Questions

6. **Should filterReason appear in Excel?**
   - Could append to baseText: "Total (Those who prescribed Leqvio)"
   - Or keep separate for debugging
   - Recommendation: Enhance baseText for user clarity

7. **How to surface low-confidence filters?**
   - Visual indicator in Excel?
   - Separate review report?
   - Recommendation: Review report, don't clutter Excel

### Validation Questions

8. **How to validate filter expressions?**
   - Check variable names exist in datamap
   - Test expression doesn't error in R
   - Warn if filter excludes all respondents

9. **What if filter creates empty base?**
   - Could happen if filter is wrong or data is sparse
   - Need graceful handling (warning, not crash)

---

## Example Scenarios

### Scenario 1: A3a Leqvio (Clear Skip Logic)

**Survey excerpt:**
> A3a. For each treatment, approximately what % received therapy in addition to a statin vs. without a statin?
> ONLY SHOW THERAPY WHERE A3>0

**Datamap context:**
- A3r2: Leqvio patient count (0-100)
- A3ar1c1: Leqvio % in addition to statin
- A3ar1c2: Leqvio % without statin

**Agent output:**
```json
{
  "tableId": "a3a_leqvio",
  "additionalFilter": "A3r2 > 0",
  "filterReason": "Only those who prescribed Leqvio (A3>0 per survey skip logic)",
  "confidence": 0.95,
  "humanReviewRequired": false,
  "reasoning": "Survey explicitly states 'ONLY SHOW THERAPY WHERE A3>0'. A3r2 is the Leqvio patient count variable. Filter to respondents with at least one Leqvio patient."
}
```

### Scenario 2: Standard Question (No Additional Filter)

**Survey excerpt:**
> S5. What is your primary practice setting?

**Agent output:**
```json
{
  "tableId": "s5",
  "additionalFilter": null,
  "filterReason": "Asked to all respondents",
  "confidence": 0.99,
  "humanReviewRequired": false,
  "reasoning": "No skip logic indicated. Question appears to be asked to all qualified respondents."
}
```

### Scenario 3: Ambiguous Case (Low Confidence)

**Survey excerpt:**
> B7. How satisfied are you with [BRAND]?
> (No explicit skip logic visible)

**Datamap context:**
- B1r1-B1r5: Brand awareness (Yes/No)
- B7r1-B7r5: Brand satisfaction (1-5 scale)

**Agent output:**
```json
{
  "tableId": "b7_brand_a",
  "additionalFilter": "B1r1 == 1",
  "filterReason": "Likely only asked to those aware of Brand A",
  "confidence": 0.6,
  "humanReviewRequired": true,
  "reasoning": "No explicit skip logic, but satisfaction questions typically filter to those aware of the brand. B1r1 appears to be Brand A awareness. Flagging for human review due to uncertainty."
}
```

---

## Success Criteria

1. **A3a base sizes match Joe's** - 135, 126, 177 for Leqvio, Praluent, Repatha
2. **No false positives** - Don't add filters where none are needed
3. **High confidence on clear cases** - >0.9 when skip logic is explicit
4. **Appropriate flagging** - Uncertain cases go to human review
5. **Pipeline time acceptable** - <30 seconds added for typical survey

---

## Future Enhancements

1. **Learning from corrections** - Store human review decisions, use for few-shot examples
2. **Pre-computation validation** - Run R to verify base sizes match expectations
3. **Cross-survey patterns** - Identify common skip logic patterns across projects
4. **Automatic VerificationAgent feedback** - If BaseFilterAgent sees row-level skip logic on a combined table, flag that VerificationAgent should have split it
