# Column-Level Rule Support

**Status:** Planned (not yet started)
**Priority:** P1 — Affects 2/11 test datasets (CAR-T Segmentation, GVHD), likely more in production
**Linked from:** `batch-review-action-plan.md` → "Add Column-Level Rule Support"

---

## Problem Statement

Surveys use three independent dimensions of visibility within a question:

1. **Table-level**: WHO sees the question at all (e.g., "ASK IF Q3 == 1")
2. **Row-level**: WHICH ROWS each respondent sees (e.g., "SHOW PRODUCT WHERE Q8 > 0")
3. **Column-level**: WHICH COLUMNS each respondent sees in a grid (e.g., "IF 0 DO NOT SHOW COLUMN")

Our schema and FilterApplicator currently support only table-level and row-level. Column-level rules get misclassified, producing incorrect output.

### Real-World Example (CAR-T Segmentation, Question A6)

A6 is a multi-column grid: 9 treatment rows x 2 line-of-therapy columns.

| | 2nd line | 3rd and later line |
|---|---|---|
| Monjuvi | A6r1c1 | A6r1c2 |
| Polivy | A6r2c1 | A6r2c2 |
| ... | ... | ... |

The survey says: **"PIPE S16_R3+R4 — IF 0 DO NOT SHOW COLUMN"** on the "3rd and later line" column. Meaning: if the respondent has zero patients in 3rd/4th+ line therapy, hide that entire column — but still show the rest of the grid.

**What happens today:**
1. SkipLogicAgent extracts the rule, classifies it as `table-level` with `appliesTo: ["A6"]`
2. FilterTranslator generates correct R expression `(S16r3c1 + S16r4c1) > 0`
3. FilterApplicator stamps this filter on the **entire** `a6` table (all 18 rows, both columns)
4. VerificationAgent later splits the already-filtered table into `a6_2nd` and `a6_3plus`
5. **Result:** Both sub-tables inherit the filter. Respondents with S16_R3+R4 = 0 lose the ENTIRE A6 question instead of just the 3rd+ column.

### Why Existing Mechanisms Can't Express This

- **Table-level (`action: "filter"`)**: Stamps the filter on the whole table — no way to target specific columns/variables within it.
- **Row-level (`action: "split"`)**: Splits by rows (variable groups), each with their own filter. Could theoretically work, but: (a) semantically confusing, (b) the empty-expression guard on line 131 of FilterApplicator drops unfiltered groups, and (c) the VerificationAgent's dimensional split logic would conflict since it expects to handle column splitting itself.

---

## Pipeline Flow Context

Understanding the order of operations is critical:

```
TableGenerator → SkipLogic → FilterTranslator → FilterApplicator → Verification → PostProcessor
```

- **TableGenerator** creates ONE table per question (`a6` with all 18 rows)
- **FilterApplicator** applies filters BEFORE VerificationAgent sees the tables
- **VerificationAgent** splits multi-column grids into sub-tables AFTER filtering

This means column-level filtering must happen at the FilterApplicator stage, before the VerificationAgent does its dimensional splits. If we get it right, the VerificationAgent receives pre-split tables and doesn't need to handle column logic at all.

---

## Solution: Add `column-level` as a Third Rule Dimension

### Design Principles

1. **Three independent visibility dimensions**: table-level, column-level, row-level — composable in any combination
2. **Application order**: table gate first, then column split, then row split within each column table
3. **Each layer inherits from the previous**: column splits inherit the table-level filter; row splits inherit both
4. **Deterministic splitting**: The FilterApplicator handles all structural changes; VerificationAgent enriches but doesn't restructure

### Schema Changes

#### 1. SkipRule — Add `column-level` to ruleType enum

```typescript
// In src/schemas/skipLogicSchema.ts

ruleType: z.enum(['table-level', 'row-level', 'column-level']),
```

No other changes to SkipRule. The `conditionDescription` and `translationContext` fields carry the column-specific details (which column, what the column label is, what the condition is).

#### 2. TableFilter — Add `column-split` action and ColumnSplitDefinition

```typescript
// New schema: ColumnSplitDefinition
export const ColumnSplitDefinitionSchema = z.object({
  /** Variables that belong to this column group */
  columnVariables: z.array(z.string()),

  /** R filter expression for this column group (empty string "" if no filter — column always shown) */
  filterExpression: z.string(),

  /** Human-readable base text for this column group */
  baseText: z.string(),

  /** Label for the column group (e.g., "2nd line", "3rd and later line") */
  splitLabel: z.string(),
});

export type ColumnSplitDefinition = z.infer<typeof ColumnSplitDefinitionSchema>;
```

```typescript
// Updated TableFilter
export const TableFilterSchema = z.object({
  ruleId: z.string(),
  questionId: z.string(),

  // Add 'column-split' to the action enum
  action: z.enum(['filter', 'split', 'column-split']),

  filterExpression: z.string(),
  baseText: z.string(),

  // Existing row-level splits
  splits: z.array(SplitDefinitionSchema),

  // NEW: column-level splits (empty array if not column-split)
  columnSplits: z.array(ColumnSplitDefinitionSchema),

  alternatives: z.array(FilterAlternativeSchema),
  confidence: z.number().min(0).max(1),
  reasoning: z.string(),
});
```

**Key difference from row-level splits**: Column splits explicitly allow empty `filterExpression` to represent "always shown" column groups. This is necessary because in a 2-column grid, one column might always be visible while only the other has a condition.

#### 3. FilterApplicatorResult — Add columnSplitCount

```typescript
export interface FilterApplicatorResult {
  tables: ExtendedTableDefinition[];
  summary: {
    totalInputTables: number;
    totalOutputTables: number;
    passCount: number;
    filterCount: number;
    splitCount: number;
    columnSplitCount: number;  // NEW
    reviewRequiredCount: number;
  };
}
```

### FilterApplicator Changes

Add a new case in the main loop for column-level splits. The updated logic flow:

```
For each table:
  1. No filters → pass through
  2. Table-level only → stamp additionalFilter + baseText
  3. Column-split only → create one table per column group, each with its own filter
  4. Row-split only → create one table per row group (existing behavior)
  5. Table-level + column-split → each column table inherits the table-level filter via &
  6. Table-level + row-split → each row table inherits the table-level filter via & (existing)
  7. Column-split + row-split → first split by columns, then split each column table by rows
  8. All three → table gate & column split & row split (full composition)
```

#### Column-Split Implementation (Case 3)

```typescript
// Pseudocode for the column-split case in FilterApplicator

if (columnSplitFilters.length > 0 && rowLevelFilters.length === 0) {
  for (const colFilter of columnSplitFilters) {
    for (const colSplit of colFilter.columnSplits) {
      // Find matching rows by variable name
      const matchingRows = table.rows.filter(row =>
        colSplit.columnVariables.includes(row.variable)
      );

      if (matchingRows.length === 0) continue;

      // Build filter: table-level (if any) & column-level (if any)
      let combinedExpression = tableLevelExpression;
      if (colSplit.filterExpression.trim() !== '') {
        combinedExpression = combinedExpression
          ? `(${combinedExpression}) & (${colSplit.filterExpression})`
          : colSplit.filterExpression;
      }

      const splitTableId = `${table.tableId}_${colSplit.splitLabel
        .toLowerCase().replace(/[^a-z0-9]+/g, '_')}`;

      outputTables.push({
        ...table,
        tableId: splitTableId,
        rows: matchingRows,
        // Only set additionalFilter if there IS a filter
        ...(combinedExpression ? { additionalFilter: combinedExpression } : {}),
        baseText: colSplit.baseText || table.baseText,
        splitFromTableId: table.tableId,
        tableSubtitle: colSplit.splitLabel || table.tableSubtitle,
        filterReviewRequired: hasReviewRequired,
        lastModifiedBy: 'FilterApplicator',
      });
    }
  }
  columnSplitCount++;
  continue;
}
```

**Critical difference from row-level splits**: Empty `filterExpression` does NOT skip the column group — it creates the table with no additional filter. This is how "always shown" columns work.

#### Composition with Row-Level Splits (Case 7)

When both column-split and row-split apply to the same question:

1. First split by columns → creates N column tables
2. For each column table, apply row-level splits → creates M row tables per column table
3. Result: N x M tables (in theory), though in practice most combinations won't have both

This is the most complex case but follows naturally: column splits produce intermediate tables, then row splits operate on those intermediate tables just as they would on the original.

### Prompt Changes

#### SkipLogicAgent (alternative prompt)

Add a third classification with guidance on identifying column-level patterns:

```
RULE TYPE CLASSIFICATION:

- table-level: WHO sees the entire question
  Pattern: "ASK IF...", "SKIP IF...", "[ASK Q3 == 1 ONLY]"

- column-level: WHICH COLUMNS each respondent sees within a grid/matrix question
  Pattern: "IF 0 DO NOT SHOW COLUMN", "SHOW [column] WHERE...",
           "PIPE [variable] — IF 0 HIDE", conditional column headers in grids
  Note: This applies to multi-column grids where different columns have
  independent visibility conditions. Each column may be gated by a different
  variable or condition.

- row-level: WHICH ROWS/ITEMS each respondent sees within the question
  Pattern: "SHOW EACH WHERE...", "ONLY SHOW ITEMS SELECTED IN Q3",
           conditional response options based on prior answers
```

In `translationContext`, the SkipLogicAgent should describe:
- Which column is gated (by label, position, or description)
- What the gating condition is
- Whether OTHER columns of the same grid are always shown or have their own conditions
- The relationship between columns (e.g., "column 1 = 2nd line therapy, column 2 = 3rd+ line therapy")

#### FilterTranslator (alternative prompt)

Add guidance for translating `column-level` rules:

```
COLUMN-LEVEL RULES (ruleType: "column-level"):

These rules control which columns of a multi-column grid are shown.
Your job: identify which variables belong to each column group, and
produce a column-split with appropriate filters.

Steps:
1. Read the translationContext to understand which column is gated
2. Examine the datamap for the question's variables — look for
   column patterns (e.g., r[row]c[col], _C1/_C2, _col1/_col2)
3. Group variables by column index
4. Create columnSplits: one per column group, each with its own
   filterExpression (or empty string if that column is always shown)

Output: action = "column-split", columnSplits = [...]
```

### VerificationAgent Impact

Minimal. If the FilterApplicator correctly splits a multi-column grid before the VerificationAgent sees it, the VerificationAgent receives pre-split tables and enriches them normally. It won't need its "TOOL 3: DIMENSIONAL SPLITS FOR GRIDS" logic for these tables since they're already split.

The VerificationAgent may still do dimensional splits on tables that DON'T have column-level skip logic. This is fine — the two mechanisms don't conflict.

---

## Composition Matrix

All combinations of the three rule types on a single question:

| Table-level | Column-level | Row-level | Behavior |
|---|---|---|---|
| - | - | - | Pass through unchanged |
| Yes | - | - | Stamp filter on table |
| - | Yes | - | Split into column groups, each with own filter |
| - | - | Yes | Split into row groups, each with own filter |
| Yes | Yes | - | Split into column groups, each inherits table filter via & |
| Yes | - | Yes | Split into row groups, each inherits table filter via & (existing) |
| - | Yes | Yes | Split by columns first, then split each column table by rows |
| Yes | Yes | Yes | Table gate & column split & row split (full composition) |

---

## Implementation Order

1. **Schema**: Add `column-level` to ruleType enum, add `ColumnSplitDefinitionSchema`, add `column-split` to action enum, add `columnSplits` to TableFilter
2. **FilterApplicator**: Add column-split case (case 3 above), add column+row composition (case 7), update summary counters
3. **SkipLogicAgent prompt**: Add column-level classification guidance and translationContext requirements
4. **FilterTranslator prompt**: Add column-split translation guidance with variable grouping instructions
5. **Testing**: Run CAR-T and GVHD datasets to verify column-level rules are correctly extracted, translated, and applied

---

## Files Modified

| File | Change |
|------|--------|
| `src/schemas/skipLogicSchema.ts` | Add `column-level` to ruleType, `ColumnSplitDefinitionSchema`, `column-split` action, `columnSplits` field |
| `src/lib/filters/FilterApplicator.ts` | New column-split case, column+row composition, updated summary |
| `src/prompts/skiplogic/alternative.ts` | Column-level classification guidance |
| `src/prompts/filtertranslator/alternative.ts` | Column-split translation guidance |

---

## Risks and Considerations

- **Azure structured output**: The new `columnSplits` array must default to `[]` (not undefined) per our Azure constraint. This is consistent with how `splits` already works.
- **Prompt hygiene**: All examples in the prompts must be abstract/generic — no CAR-T or GVHD variable names.
- **VerificationAgent conflict**: If the VerificationAgent sees a pre-split table and tries to re-split it, we'd get unnecessary fragmentation. The VerificationAgent's dimensional split guidance should note: "If a table was already split by FilterApplicator (check `splitFromTableId`), do not re-split along the same dimension."
- **Variable naming patterns**: The FilterTranslator needs to identify column groups from variable names. Most SPSS naming follows `QrXcY` (row X, column Y) patterns, but not all. The translationContext from the SkipLogicAgent should describe the column structure in words so the FilterTranslator can match even with non-standard naming.

---

## Datasets Affected

| Dataset | Question | Column Rule | Current Behavior |
|---|---|---|---|
| CAR-T Segmentation | A6 | "3rd+ line" column hidden when S16_R3+R4 = 0 | Entire A6 filtered (wrong) |
| GVHD | A7 | Donor-type columns shown where A1 > 0 | Misclassified as row-level |

Additional datasets may have similar patterns that were not flagged because the misclassification produced plausible (but incorrect) output.
