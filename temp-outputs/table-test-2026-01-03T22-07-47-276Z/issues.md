# TableAgent Output Issues

Running list of issues identified during prompt iteration.

---

## Final Results - First Pass

| Reviewed | Wrong | Accuracy |
|----------|-------|----------|
| 41 | 11 | **73%** |

**Wrong**: S1, S2a, S7, S9, A2b, A5 (missing filterValue), A3a, A3b, A4a (context field discarded), A4, A4b (2D grid / missing column context)

---

## Impact Analysis

| Fix Type | Issues Addressed | Potential Accuracy |
|----------|------------------|-------------------|
| Current baseline | - | 73% (30/41) |
| + Prompt fix (filterValue) | S1, S2a, S7, S9, A2b, A5 | **88%** (36/41) |
| + Code fix (context field) | A3a, A3b, A4a | **95%** (39/41) |
| Remaining (display optimization) | A4, A4b | These are valid but suboptimal |

**Key insight**: Two targeted fixes (one prompt, one code) could take us from 73% → 95% accuracy.

---

## Priority Fixes

### HIGH - Prompt Fix
- **Issue**: filterValue empty for frequency tables with categorical_select
- **Fix**: Add explicit rule to prompt: "For frequency tables, ALWAYS populate filterValue with the numeric code from scaleLabels"
- **Impact**: 6 errors fixed

### HIGH - Code Fix
- **Issue**: Context field discarded in `groupDataMapByParent()` (TableAgent.ts lines 85, 92)
- **Fix**: Pass `context` field to each item so agent can extract row identifiers
- **Impact**: 3 errors fixed

### MEDIUM - Prompt Enhancement
- **Issue**: 2D/3D grid display optimization
- **Fix**: Add guidance for multi-dimensional grids: produce tables by product AND by value
- **Impact**: Better table structure for complex grids

---

## Watch Item 1: Binary Flags - Show Just 1 or Both 0 and 1?

**Question**: S5 (multi_select)

**Current behavior**: For binary_flag items, filterValue="1" only (selected)

**Concern**: Sometimes you might want to report BOTH:
- filterValue="1" → "Selected this option"
- filterValue="0" → "Did NOT select this option"

**Status**: Watch for this pattern in other questions. May need prompt guidance on when to show just selected (1) vs both states.

**For now**: Counting S5 as correct - showing just "1" is standard for multi-select.

---

## Design Consideration 1: Schema Redundancy

**Observed on**: S6 (mean_rows)

**Issues**:

1. **filterValue irrelevant for mean_rows**: Agent outputs `filterValue: ""` but it's never used for this table type. Should we:
   - Make filterValue truly optional (not required in schema)?
   - Or just ensure downstream doesn't flag blank as an error?

2. **stats redundant when tableType implies them**: If `tableType: "mean_rows"`, we KNOW stats = [mean, median, sd]. Having agent specify this is redundant.

   | tableType | Implied stats |
   |-----------|---------------|
   | frequency | count, percent |
   | mean_rows | mean, median, sd |
   | multi_select | count, percent |
   | grid_by_value | count, percent |

**Proposal**:
- Downstream system infers stats from tableType
- Agent only specifies stats if overriding defaults (rare)
- filterValue only required when tableType uses it (frequency, grid_by_value, multi_select)

**Action**: Review schema after iteration - simplify what agent must output.

---

## Design Consideration 2: Ranking Questions & Top-N Nets (A6)

**Observed on**: A6 (ranking question, 8 items ranked 1-4)

**Current output**: 4 separate tables (rank=1, rank=2, rank=3, rank=4) ✓ Correct

**What would also be useful**: Combined "Top N" tables

| Table | Logic | Use Case |
|-------|-------|----------|
| Ranked #1 | filterValue = "1" | Who picked this first? |
| Ranked #2 | filterValue = "2" | Who picked this second? |
| Ranked #3 | filterValue = "3" | Who picked this third? |
| **Top 2** | filterValue IN ("1", "2") | Was this in their top 2? |
| **Top 3** | filterValue IN ("1", "2", "3") | Was this in their top 3? |

**Current limitation**: No obvious way to express "Top N" nets in current schema. Would need:
- New filterValue syntax: `"1,2,3"` or `"<=3"`?
- New table type: `ranking_net`?
- Or: deterministic post-processing that adds net tables for ranking questions

**Options**:

1. **Prompt enhancement**: Tell model to think beyond "safe bet" - be proactive about what makes reporting easier. For ranking questions, suggest creating combined tables.

2. **Deterministic post-processing**: When we detect a ranking question (tableType = `ranking` or `grid_by_value` with rank-like values), automatically generate net tables downstream. Not everything has to be model-driven.

3. **Schema enhancement**: Add `filterOperator` field: `"="`, `"<="`, `"IN"` to express more complex filters.

**Recommendation**: Consider hybrid approach - model produces base tables, deterministic logic adds common nets (top 2, top 3) for ranking questions. Keeps model focused on structure decisions.

---

## Design Consideration 3: 3D Grid Logical Grouping (A8)

**Observed on**: A8 - 3D structure: 5 patient situations × 3 products × 5 rating values

**Survey structure** (from image):
```
                          | Repatha | Praluent | Leqvio |
a. With established CVD   |  1-5    |   1-5    |  1-5   |
b. No CV events, high-risk|  1-5    |   1-5    |  1-5   |
c. No CV events, low-med  |  1-5    |   1-5    |  1-5   |
d. Not compliant on statins|  1-5   |   1-5    |  1-5   |
e. Intolerant of statins  |  1-5    |   1-5    |  1-5   |
```

**What model produced**: 5 tables by rating value (grid_by_value)
- Table for rating=1: all 15 cells
- Table for rating=2: all 15 cells
- etc.

**What would be more useful**: Group by product or patient situation

| Grouping | Tables | Content |
|----------|--------|---------|
| By product | 3 tables | Repatha (all 5 situations as frequency), Praluent, Leqvio |
| By situation | 5 tables | Situation A (3 products as frequency), B, C, D, E |
| By product+situation | 15 tables | Repatha-SituationA (frequency 1-5), etc. |

**User preference**: "All Repathas in one table" - group by product, show patient situations as rows, values as frequency distribution.

**Root issue**: Model chose one valid flattening strategy (by value) but not the most intuitive one for reporting. With 3D data, there are multiple ways to slice:
- Dimension 1: Patient situations
- Dimension 2: Products
- Dimension 3: Rating values

**Prompt guidance needed**:
1. When you have a 3D grid (items × options × values), consider which dimension is most meaningful to group by
2. Products/brands are often the primary comparison dimension
3. Patient types/situations are often secondary
4. Rating values are usually shown as frequency distribution within a table, not as separate tables

**Note**: This may be too complex for prompt alone. Could benefit from:
- Survey context (seeing the visual structure)
- Explicit user preference input
- Multiple output options for user to choose from

**Also applies to A9**: Same pattern - 3 products × N category values. Model produced by-value tables (good), but should also produce by-product tables showing full distribution within each product.

**Emerging pattern**: When you have products × values, produce BOTH:
1. By-value tables (compare products within each response category)
2. By-product tables (show full distribution for each product)

**Philosophy**: We're trying to encode years of domain knowledge about crosstab structure into prompts. The challenge is capturing default preferences that a human analyst learns through experience.

---

## Issue 4: Context Field Discarded (A3a, A3b, A4a) - CODE BUG

**Status**: Major - requires code fix in TableAgent.ts

**Affected questions**: A3a, A3b, A4a (all have treatment names in `context` field)

**Example - A3a**: 10 sub-variables representing a 2D grid:
- 5 treatments (Leqvio, Praluent, Repatha, Zetia, Nexletol)
- 2 conditions each (In addition to statin, Without statin)

**Example - A4a**: 10 sub-variables (5 treatments × 2 columns):
- Treatment names in context: "A4ar1: Leqvio (inclisiran)", "A4ar2: Praluent (alirocumab)", etc.
- Columns: c1=with statin, c2=without statin
- All `description` fields are IDENTICAL: "NEXT 100 [res PatientHoverover2] with Uncontrolled LDL-C"
- Result: All 10 rows got the same useless label

**Agent even noticed the problem** (A4a reasoning):
> "the item labels in the input are identical; ensure final rendering shows the distinct treatment/condition labels if available"

But it couldn't fix it because the treatment names were never passed to it.

**What agent did**:
- Correctly chose `mean_rows`
- Used generic labels: "Treatment 1", "Treatment 2", etc.
- Missed that treatment names ARE in the `context` field

**The context field contains the treatment names**:
```
A3ar1c1 context: "A3ar1: Leqvio (inclisiran) - For each treatment..."
A3ar2c1 context: "A3ar2: Praluent (alirocumab) - For each treatment..."
```

**Root causes**:

1. **Context field not being extracted/used**: Each sub-variable has the treatment name in context, but agent used generic labels

2. **Agent didn't conceptualize the visual structure**: This is a grid survey question:
   ```
   VISUAL IN SURVEY:
                    | In addition to statin | Without statin |
   Leqvio           |  [___]%               |  [___]%        |
   Praluent         |  [___]%               |  [___]%        |
   Repatha          |  [___]%               |  [___]%        |
   ...
   ```

3. **Flattening decision unclear**: Two valid approaches to convert 2D → 1D:
   - **Option A**: One table, all 10 rows (current, but with proper labels)
   - **Option B**: 5 tables (one per treatment), each with 2 rows

**Prompt improvements needed**:

1. **Add scratchpad step**: "Visualize the survey structure - is this a grid? What are the rows/columns?"

2. **Emphasize context field**: "The `context` field often contains parent question text with row identifiers (e.g., treatment names). Extract these for labels."

3. **Grid flattening guidance**: When you have a 2D grid (items × conditions), consider:
   - One table with all items as rows (combine item + condition in label)
   - Multiple tables (one per item, conditions as rows within)
   - Multiple tables (one per condition, items as rows within)

**Input structure question**: Are we passing the full context field to the agent? Need to verify in `groupDataMapByParent()`.

**VERIFIED - BUG FOUND in TableAgent.ts lines 85, 92**:
```typescript
// Line 85 - only takes FIRST item's context as questionText
const questionText = items[0]?.context || parentId;

// Line 92 - context is DISCARDED, only description passed
label: item.description,  // "In addition to statin"
// item.context NOT passed! ← BUG
```

**Impact**: Agent never sees treatment names. They're in `context` but we don't pass it.

**Fix**: Add `context` field to each item in the grouped input so agent can extract row identifiers.

---

## Issue 5: 2D Grid Display Options (A4) - NEW ISSUE TYPE

**Status**: Partially wrong - structure correct, but not optimized for visual display

**Question**: A4 - 14 sub-variables representing a 2D grid:
- 7 treatments (Statin only, Leqvio, Praluent, Repatha, Zetia, Nexletol, Other)
- 2 columns each (c1 = LAST 100 patients, c2 = NEXT 100 patients)

**What agent did**:
- Correctly chose `mean_rows` ✓
- Correctly extracted treatment labels ✓ (because they were in `description`, not `context`)
- Combined all 14 rows into one table with "(c1)" and "(c2)" suffixes in labels

**Why labeling worked here vs A3a/A3b**:
- A3a/A3b: Treatment names were in `context` field (discarded by code bug)
- A4: Treatment names were in `description` field (passed through correctly)

**What would be better**: Multiple table output options for 2D grids:

| Option | Description | Use Case |
|--------|-------------|----------|
| Table 1 | All c1 rows only | "LAST 100 patients" standalone |
| Table 2 | All c2 rows only | "NEXT 100 patients" standalone |
| Table 3 | Per-treatment tables (c1, c2 as rows) | Direct comparison per treatment |
| Table 4 | Combined merged view | Side-by-side comparison (current output) |

**Visual structure for Option 4**:
```
                              | c1 (LAST)  | c2 (NEXT)  |
Statin only                   |   mean     |   mean     |
Leqvio (inclisiran)           |   mean     |   mean     |
Praluent (alirocumab)         |   mean     |   mean     |
...
```

**Key insight**: The current single-table approach doesn't convey the visual structure. For Excel output, we need:
1. Ability to merge cells or create visual groupings
2. Row metadata indicating "this row pairs with that row"
3. Or: generate multiple tables and let downstream decide how to display

**Implications for schema/prompt**:

1. **New output field?**: Consider `rowGroup` or `mergeWith` to indicate paired rows
2. **New table type?**: Could add `paired_comparison` or `before_after` type
3. **Multi-table generation**: Prompt should guide agent to consider producing multiple tables for 2D structures
4. **Existing types may suffice**: We have 6 table types - maybe prompt just needs better guidance on when to produce multiple tables

**Questions to resolve**:
1. Is generating multiple tables per question the right approach?
2. Should schema support "merged row" concept for visual display?
3. How does ExcelJS handle paired row structures?

**Note**: This is a display/UX optimization issue, not a correctness issue. The data would render correctly, just not optimally for visual comparison.

---

## Issue 6: Missing Column Header Context (A4b) - DATA GAP

**Status**: Structural limitation - datamap doesn't contain column headers

**Question**: A4b - 10 sub-variables (5 treatments × 2 columns)

**What's in the datamap**:
- `description`: "Next treatment allocation" (IDENTICAL for all 10)
- `context`: "A4br1: Leqvio (inclisiran) - For each treatment..." (has treatment name)

**What's ONLY in the survey document** (not in datamap):
- Column A (c1): "BEFORE any other lipid-lowering therapy (i.e., first line)"
- Column B (c2): "AFTER trying another lipid-lowering therapy"

**Visual from survey**:
```
                    | BEFORE any other    | AFTER trying another  |
                    | lipid-lowering      | lipid-lowering        |
                    | therapy (first line)| therapy               |
Leqvio              |  [___]%             |  [___]%               |
Praluent            |  [___]%             |  [___]%               |
Repatha             |  [___]%             |  [___]%               |
...
```

**Result**: Agent produced meaningless labels like "Next treatment allocation (A4br1c1)"

**Key insight**: Even fixing the context bug won't help here - the column meanings are ONLY in the survey document.

**Possible solutions**:

1. **Survey as additional context**: Pass survey document/images to agent for richer understanding
   - Pro: Agent could see column headers, question flow, visual structure
   - Con: More tokens, more complexity, not always available

2. **Prompt heuristic for unknown columns**: When columns have no semantic meaning in datamap:
   - Suggest separating by rows (treatments) as primary dimension
   - Rows typically indicate treatments/answer options (meaningful)
   - Columns often indicate conditions/scenarios (may need external context)

3. **Default guidance**: "When you have a rows × columns grid and only row labels are available, generate one table per row (treatment) showing columns as comparison points, OR generate separate tables by column with rows as items."

**Agent even acknowledged the problem** (reasoning):
> "item labels in the input are identical; if more descriptive labels exist (e.g., treatment names or scenarios), they should replace the generic labels for clarity"

**This reveals a deeper issue**: The datamap alone may not contain enough semantic information for optimal table design. Survey document context could be valuable.

---

## Trend Observation 1: filterValue Inconsistency on categorical_select

All three are `categorical_select` with similar structure:

| Question | Values | filterValue populated? |
|----------|--------|------------------------|
| S1 | [1,2,3] | ✗ No |
| S2a | [1,2,3] | ✗ No |
| S2b | [1,2,3,99] | ✓ Yes |

**Hypothesis**: Possibly the presence of "99" (Other code) or scaleLabels triggered correct behavior in S2b? Or just random. Need more data points to confirm pattern.

**Implication**: Prompt needs explicit rule: "For categorical_select → frequency, ALWAYS use scaleLabels to populate filterValue with the numeric code."

---

## Issue 1: Frequency vs Multi-Select Collapse

**Status**: Under Discussion

**Observation**: Are `frequency` and `multi_select` really different table types?

| Aspect | frequency | multi_select |
|--------|-----------|--------------|
| Input structure | 1 variable, values 1-N | N binary variables (0/1 each) |
| Output structure | Rows with count/% | Rows with count/% |
| What varies per row | filterValue (1, 2, 3...) | variable name (S5r1, S5r2...) |
| filterValue meaning | Which categorical value | Always "1" (selected) |

**From R's perspective**, both do the same thing:
- For each row: `count where variable == filterValue`

**Proposal**: Could unify into single type if we:
1. Always require `filterValue` in every row
2. Let `tableType` be semantic (for titles/display) not calculation logic

**Decision**: TBD - need to think through downstream implications

---

## Issue 2: S1 Output Structure Wrong (Inconsistent Hallucination)

**Status**: Bug - needs prompt heuristics

**Problem**: S1 is a single categorical question (values 1-3), but the output is malformed.

**Key observation**: S2b is the EXACT same pattern and worked correctly:
- S2b: categorical_select, values [1,2,3,99] → correct filterValues ✓
- S1: categorical_select, values [1,2,3] → empty filterValues ✗

This is an inconsistency/hallucination, not a structural issue.

```json
{
  "tableType": "frequency",
  "rows": [
    { "variable": "S1", "label": "...", "filterValue": "" },
    { "variable": "S1", "label": "...", "filterValue": "" },
    { "variable": "S1", "label": "...", "filterValue": "" }
  ]
}
```

All three rows have:
- Same variable "S1" ✓ (correct)
- Empty filterValue ✗ (wrong!)

**Expected**:
```json
{
  "tableType": "frequency",
  "rows": [
    { "variable": "S1", "label": "I would like to proceed and protect my identity", "filterValue": "1" },
    { "variable": "S1", "label": "I would like to proceed and give permission...", "filterValue": "2" },
    { "variable": "S1", "label": "I don't want to proceed", "filterValue": "3" }
  ]
}
```

**Root Cause**: Prompt says:
> "filterValue: For grid_by_value, use the value (e.g., "1", "2"). For all other table types, use empty string """

This is wrong. Frequency tables ALSO need filterValue to indicate which categorical value each row represents.

**Fix**: Add stronger heuristics to prompt:

1. `categorical_select` → most likely `frequency` table type
2. For frequency tables, ALWAYS populate:
   - `variable`: The column name (e.g., "S2b")
   - `label`: The human-readable label from scaleLabels
   - `filterValue`: The numeric code (e.g., "1", "2", "99")
3. One row per allowedValue, using scaleLabels for the label text

---

## Issue 3: questionId vs tableId Clarity

**Status**: Under Discussion

**Question**: Why have both `questionId` and `tableId`?

**Current behavior**:
- `questionId`: From datamap (e.g., "S1")
- `tableId`: Lowercase unique ID (e.g., "s1", "a1_value_1")

**When they differ**:
- Grid questions produce multiple tables per question: A1 → "a1_value_1", "a1_value_2"
- Simple questions: S1 → "s1" (just lowercase of questionId)

**Proposal**: Keep both, but clarify in prompt that:
- `tableId` must be unique across ALL tables (used as Excel sheet reference, etc.)
- For simple questions, `tableId` = lowercase of `questionId`
- For grid questions, append suffix to distinguish

---

*Created: January 3, 2026*
