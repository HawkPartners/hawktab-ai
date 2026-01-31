# BaseFilterAgent Implementation Plan

**Status**: Ready for implementation
**Created**: 2026-01-31
**Updated**: 2026-01-31

---

## The Problem

Our pipeline calculates table bases using `cut filter + non-NA values`. This works for most questions, but fails when questions have **row-level skip logic** that creates different bases for different rows.

**Example pattern:**
- Survey has a grid question: "For each product you use, rate X"
- Show logic: "ONLY SHOW PRODUCT WHERE [usage count] > 0"
- Product A row should only include respondents where usage_A > 0 (n=135)
- Product B row should only include respondents where usage_B > 0 (n=126)
- Product C row should only include respondents where usage_C > 0 (n=177)
- We currently include everyone shown the question (n=141 for all)
- Result: Incorrect base sizes and meaningless data included

**Key insight:** When rows have different bases, they cannot coexist in the same table—our system shows one base per table. These must be split.

---

## The Solution: BaseFilterAgent

A dedicated agent that runs after VerificationAgent to ensure every table has an accurate base.

### What It Does

1. **Reviews each table** for skip/show logic in the survey context
2. **Determines the correct base** for the table (or each row if they differ)
3. **Outputs corrected tables** with:
   - `additionalFilter`: R expression to AND with the cut filter
   - `baseText`: Plain English description of who is included
4. **Splits tables** when different rows have different bases

### What It Does NOT Do

- Make analytical decisions (that's VerificationAgent's job)
- Change labels, NETs, or enrichments
- Decide what's "interesting"—only what's accurate

---

## Pipeline Position

```
VerificationAgent → BaseFilterAgent → R Script Generator → Excel
       ↓                   ↓
  Table design       Base accuracy
  (analytical)       (correctness)
```

**Runs after**: VerificationAgent (tables are finalized analytically)
**Runs before**: R Script Generator (needs filter expressions)

**Note**: Table count may change after BaseFilterAgent (splits). Downstream uses BaseFilterAgent's output.

---

## Agent Output

For each input table, BaseFilterAgent outputs one or more tables:

| Scenario | Input | Output |
|----------|-------|--------|
| No filter needed | 1 table | Same table with `additionalFilter: ""`, `baseText` set |
| Filter needed | 1 table | Same table with `additionalFilter: "A3r2 > 0"`, `baseText` set |
| Split needed | 1 table | N tables, each with appropriate filter and baseText |

The agent outputs **complete `ExtendedTableDefinition` objects**—not hints or mappings. This keeps the architecture simple and consistent with how VerificationAgent works.

### Output Schema

```typescript
interface BaseFilterAgentOutput {
  tables: ExtendedTableDefinition[];  // 1 if pass/filter, N if split
  originalTableId: string;
  action: 'pass' | 'filter' | 'split';
  confidence: number;
  humanReviewRequired: boolean;
  reasoning: string;
}
```

### Split Mechanics

When splitting, the agent:
1. Copies the original table structure (inherits all VerificationAgent work)
2. Subsets rows for each split
3. Sets `tableId`, `tableSubtitle`, `additionalFilter`, `baseText` appropriately
4. Sets `splitFromTableId` to reference the original

This is mechanical, not analytical—the agent isn't reconsidering the table design, just ensuring base accuracy.

---

## baseText Ownership Change

**Before**: VerificationAgent was responsible for `baseText`
**After**: BaseFilterAgent owns `baseText` entirely

**Rationale**: BaseFilterAgent is reasoning about "who should be in this table's base"—that's exactly what baseText describes. Consolidating this responsibility makes both agents' jobs cleaner.

**VerificationAgent change**: Remove `baseText` from its output requirements. It can output empty string; BaseFilterAgent will set the correct value.

---

## R Script Generator Integration

The integration is straightforward. Currently at line 780:

```r
cut_data <- apply_cut(data, cuts[[cut_name]])
# ... calculations use cut_data
```

With `additionalFilter`, insert after the cut application:

```r
cut_data <- apply_cut(data, cuts[[cut_name]])

# Apply additional table-level filter if specified
if (!is.null(table$additionalFilter) && nchar(table$additionalFilter) > 0) {
  additional_mask <- with(cut_data, eval(parse(text = table$additionalFilter)))
  additional_mask[is.na(additional_mask)] <- FALSE
  cut_data <- cut_data[additional_mask, ]
}

# ... rest of calculations use filtered cut_data
```

This is a simple AND operation—respondents must pass both the cut filter AND the additional filter.

**Confirmation needed during implementation**: Verify this pattern works correctly with significance testing (the comparison groups should also use the filtered data).

---

## Validation Retry Flow

**Important edge case**: The R validation retry loop must preserve BaseFilterAgent's work.

### Current Flow (without BaseFilterAgent)

```
VerificationAgent → R Validation → if error → retry VerificationAgent → validate again
```

### New Flow (with BaseFilterAgent)

```
VerificationAgent → BaseFilterAgent → R Validation
                                        ↓ (if error)
                         retry VerificationAgent (NOT BaseFilterAgent)
                                        ↓
                         re-apply additionalFilter from BaseFilterAgent
                                        ↓
                         validate again
```

### Why This Matters

When a table fails R validation:
1. `ValidationOrchestrator` converts the table back to `TableDefinition` and re-runs VerificationAgent
2. VerificationAgent outputs a fresh `ExtendedTableDefinition`
3. **Problem**: The `additionalFilter` from BaseFilterAgent would be lost

### Solution

The validation retry loop must:
1. Store the `additionalFilter` and `baseText` before retrying
2. After VerificationAgent returns the fixed table, re-apply the stored filter metadata
3. Only then validate the table again

**Implementation approach**: In `ValidationOrchestrator.ts`, when retrying a table:
```typescript
// Before retry: preserve BaseFilterAgent's work
const preservedFilter = originalTable.additionalFilter;
const preservedBaseText = originalTable.baseText;
const preservedSplitFromTableId = originalTable.splitFromTableId;

// After VerificationAgent retry returns:
const fixedTable = result.tables[0];
fixedTable.additionalFilter = preservedFilter;
fixedTable.baseText = preservedBaseText;
fixedTable.splitFromTableId = preservedSplitFromTableId;
```

**Key principle**: BaseFilterAgent's decisions are correctness-based and should persist. The retry loop only fixes R script errors (labels, variable names, etc.), not base filter logic.

---

## VerificationAgent Prompt Update

Add guidance to VerificationAgent to be aware of row-level skip logic:

> When you see skip/show logic suggesting different rows might have different bases (e.g., "ONLY SHOW BRAND WHERE [prior question] > 0"), consider splitting those rows into separate tables. Each table should have a consistent base. If you're uncertain, downstream processing will handle it, but proactive splitting is preferred when the pattern is clear.

This helps the two agents work together—VerificationAgent can catch obvious cases, BaseFilterAgent ensures nothing slips through.

---

## Schema Changes

### ExtendedTableDefinition (verificationAgentSchema.ts)

Add fields:

```typescript
additionalFilter: z.string(),      // R expression, empty if none
filterConfidence: z.number().optional(),
filterReviewRequired: z.boolean().optional(),
splitFromTableId: z.string(),      // Original tableId if split, empty otherwise
```

**Change**: `baseText` remains in schema but VerificationAgent outputs empty string. BaseFilterAgent populates it.

### New Schema File (baseFilterAgentSchema.ts)

```typescript
export const BaseFilterResultSchema = z.object({
  tables: z.array(ExtendedTableDefinitionSchema),
  originalTableId: z.string(),
  action: z.enum(['pass', 'filter', 'split']),
  confidence: z.number().min(0).max(1),
  humanReviewRequired: z.boolean(),
  reasoning: z.string(),
});
```

---

## Files to Create/Modify

### New Files

| File | Purpose |
|------|---------|
| `src/agents/BaseFilterAgent.ts` | Agent implementation |
| `src/schemas/baseFilterAgentSchema.ts` | Zod schemas |
| `src/prompts/baseFilterAgentPrompt.ts` | Prompt template |

### Modified Files

| File | Change |
|------|--------|
| `src/schemas/verificationAgentSchema.ts` | Add filter fields, note baseText change |
| `src/lib/r/RScriptGeneratorV2.ts` | Apply additionalFilter after cut |
| `src/lib/r/ValidationOrchestrator.ts` | Preserve additionalFilter during retry loop |
| `scripts/test-pipeline.ts` | Add BaseFilterAgent step |
| `src/prompts/verification/alternative.ts` | Add skip logic awareness guidance |

---

## Validation

Before passing to R Script Generator:

1. **Filter syntax valid** — additionalFilter parses as R expression
2. **Variables exist** — All variables in filter exist in datamap
3. **Filter not too restrictive** — Warn if >90% excluded (likely error)
4. **Split coverage** — Sum of split table rows = original row count
5. **No empty tables** — Each split has at least one row

---

## Example Scenarios

These examples are illustrative patterns. The actual prompts should use abstract examples appropriate to the domain.

### Pass (No Additional Filter)

**Pattern**: Question asked to all qualified respondents, no skip logic
**Input**: Demographics question (e.g., years of experience)
**Output**: Same table, `additionalFilter: ""`, `baseText: "All respondents"`

### Filter (Same Base, Additional Constraint)

**Pattern**: Follow-up question that requires a prior answer
**Input**: Satisfaction with Product X, survey says "ASK IF Q3 = 1" (users of Product X)
**Output**: Same table, `additionalFilter: "Q3 == 1"`, `baseText: "Users of Product X"`

### Split (Different Bases Per Row)

**Pattern**: Grid question where each row has different show logic based on prior responses
**Input**: "For each product you use, rate satisfaction" where row visibility depends on usage (Q2r1 > 0 for row 1, Q2r2 > 0 for row 2, etc.)
**Output**: N tables (one per product), each with:
- Subset of rows for that product
- `additionalFilter: "Q2rN > 0"` (the relevant usage variable)
- `baseText: "Those who use [Product Name]"`

---

## Success Criteria

1. **Base sizes match reference output** — Tables with skip logic have correct base counts
2. **No false positives** — Don't add unnecessary filters to tables without skip logic
3. **baseText is accurate** — Reflects who is actually in the table
4. **Pipeline completes** — No R script errors from filter expressions
5. **Graceful uncertainty** — Ambiguous cases flagged for human review

---

## Prompt Guidelines

The BaseFilterAgent prompt should:

1. **Be abstract, not example-specific** — Use generic patterns (product grids, follow-up questions) rather than specific survey scenarios
2. **Focus on pattern recognition** — Teach the agent to recognize skip logic patterns ("ASK IF", "ONLY SHOW WHERE", "IF [X] > 0")
3. **Emphasize the mission** — Base accuracy, not analytical decisions
4. **Keep it concise** — ~100-150 lines; this is a focused task

Similarly, the VerificationAgent prompt update should:
1. Use abstract examples when explaining skip logic awareness
2. Not reference specific survey questions or variable names from any particular dataset
