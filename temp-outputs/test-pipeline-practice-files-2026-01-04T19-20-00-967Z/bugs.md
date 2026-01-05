# Bug Tracker - practice-files
Generated: 2026-01-04T19:20:00.967Z
Session: test-pipeline-practice-files-2026-01-04T19-20-00-967Z

Compare against: Joe's tabs / Antares output

---

## Data Accuracy Issues
Issues where our numbers don't match the reference tabs.

### BannerAgent
_Issues with banner extraction (missing columns, wrong group names, incorrect structure)_


### CrosstabAgent
_Issues with R expression generation (wrong filter logic, incorrect variable mappings)_


### TableAgent
_Issues with table structure decisions (wrong tableType, missing rows, incorrect grouping)_

- **Separate tables per treatment**: Joe produces separate tables for each treatment (e.g., for A1), but TableAgent combines them. OK for now, but future improvement to be more judicious about when to split vs combine.

- **Multi-dimensional scale questions**: Questions with 5-scale that have BOTH treatment columns AND multiple rows per treatment - TableAgent may not be breaking these up appropriately. See A8r1 as example.

- **NET/Roll-up rows**: Joe creates "NET" or roll-up rows that combine related answer options. Example: S2b "What is your primary role?" shows:
  - Physician (single row)
  - APP (Total) ← rolled-up NET combining non-physicians
    - Nurse Practitioner (indented, component)
    - Physician's Assistant (indented, component)
  TableAgent should learn to identify when roll-ups are appropriate and generate both the NET total and individual components. This is a prompting/examples improvement.


### RScriptGenerator
_Issues with R code generation (wrong filter values, incorrect variable references)_


### R Calculations
_Issues with the calculated values (wrong base n, percentage errors, significance testing)_

- **A3a / A3b allocation questions**: These appear to be allocation questions where values should sum to 100%, but some don't. Needs detailed review to verify data accuracy.

- **Significance testing discrepancy (S8 example)**: Our significance letters differ from Joe's even when base sizes and data values are identical. Example: S8 "Percentage of professional time" - Tiers columns show different significance patterns.
  - Not a confidence level issue (both appear to be 90%)
  - Same base n, same means
  - Need to verify: pooled vs unpooled variance, one-tailed vs two-tailed, small sample handling, comparison group definitions
  - **Action**: Ask Joe for his default significance testing settings/parameters

- **0% vs N/A distinction**: Currently showing 0% for segments where question wasn't asked (Base n = 0). Should show dash/N/A instead. Two scenarios:
  - **Base n = 0**: Question not asked of this segment (e.g., S2a not asked of PCPs/Physicians) → should show "-" not "0%"
  - **Base n > 0, count = 0**: Question asked but no one selected this option → legitimately 0%

  R code needs to differentiate these cases. When base_n = 0 for a cut, all values for that cut should be NA/dash, not 0%.


### Derived Tables (T2B/B2B, Top 3)
_Issues with hint-derived tables (wrong scale values, incorrect aggregation)_

- **T2B/B2B dimensionality collapse**: For multi-row scale questions (e.g., one row per treatment, each with 5-scale), the T2B/B2B derivation collapses ALL values for the variable regardless of treatment row. Loses the row-level dimensionality. Example: A8r1 main table vs A8r1 T2B/B2B - the collapsed version doesn't match what it should be.

- **Top 3 Combined appears after EVERY ranking table**: Currently shows the combined version after each individual ranking table (A6 #1, A6 #2, A6 #3 each followed by Top 3 Combined). Should only show ONCE at the end, not repeated.

- **Ranking alternative display**: Joe sometimes shows a single table with ALL rankings for each answer option (rank 1, 2, 3, etc. as columns) instead of separate tables per rank. Both valid, but room for interpretation on which to use.


---

## Formatting / UX Issues
Issues that don't affect data accuracy but impact usability.

### ExcelJS Formatter
_Styling, borders, colors, column widths, merged cells_

- **Table ordering**: Tables need to be reordered: Screener questions (S1, S2, etc.) first, then main questions (A1, A2, B1, etc.) in alphanumeric order, then admin/miscellaneous tables at end. Currently appears to be in processing order, not logical survey order.

- **Column width / text wrapping**: Ensure columns auto-resize appropriately so text doesn't overflow outside column boundaries. Consider wrapping cells past a certain character threshold.

- **Percentages stored as text**: Excel shows warning "Number stored as text" for percentage values. Need to ensure ExcelJS writes percentages as actual numbers (not strings) to avoid distracting warnings when partners open the file. Base sizes appear fine, issue is specifically with percentage cells.


### Labels / Text
_Truncated labels, encoding issues, missing titles_


---

## Feature Enhancements

### Step 7: Excel Cleanup Agent (Survey-Aware Validator)
The final agent in the pipeline that actually sees the survey document structure. Use cases:
- **Hide low-value tables**: When 100% of responses are one option (e.g., S4 "Board Certified" at 100%), Joe might hide this table entirely since it's not informative
- **Terminate handling**: Questions with "Terminate" options - how to display/hide these
- **Skip logic validation**: Cross-reference tables against survey skip logic to validate which segments should see which questions
- **Table relevance scoring**: Flag tables that may not add value to the final deliverable

This agent is uniquely positioned because every prior agent only sees what it needs for its function. The cleanup agent sees everything - survey structure, all generated tables, skip logic - and makes final presentation decisions.

### Bucketing for Numeric Questions
For single-row mean questions (like S6 "Years in clinical practice"), Joe shows:
- Mean/Median/Std Dev (we already calculate this)
- **PLUS** bucketed frequency distribution: "3-9 years", "10-15 years", "16-25 years", etc.
- **PLUS** NET roll-ups: "15 Years or Less Time (Total)", "More Than 15 Years (Total)"

**The coordination problem**:
- **R can easily bucket** using `cut()` - but doesn't know the semantic labels ("years", appropriate bucket names)
- **TableAgent could suggest buckets** by reading question text - but doesn't know the data's min/max range

**Possible approaches** (TBD):
1. TableAgent suggests bucket strategy + labels based on question context, R implements with actual data
2. R generates buckets with generic labels, Step 7 cleanup agent improves labels using survey doc
3. DataMapProcessor extracts value ranges from SPSS metadata, passes to TableAgent for bucket planning
4. Hybrid: R detects data range, passes back to an agent for label generation

This only applies to `mean_rows` tables with single numeric variables. Not solved yet - documenting as future enhancement.

### Demo Table at Top
Joe's tabs include a summary "demo table" at the very top that provides a sample profile overview:
- Takes all banner cuts and displays them as ROWS instead of columns
- Shows distribution/breakdown for each cut across the banner columns
- Gives quick high-level overview of your sample since banner cuts are typically key demographic/segmentation variables
- Should appear before all other tables

Implementation: Likely a derived table generated in R (similar to T2B/B2B approach) or could be generated by TableAgent. Uses the bannerGroups metadata to know which cuts to include.

---

## Notes

Initial rough pass - need detailed cell-by-cell comparison for data accuracy verification.

**Key observation**: Data accuracy looks good overall. Many of the issues noted are formatting/presentation improvements (Joe's style) rather than data correctness problems. Need to balance:
- **Must have**: Accurate data, correct calculations, proper significance testing
- **Nice to have**: Joe's advanced formatting (NETs, roll-ups, indentation, demo table)

The data matching Joe's numbers is the primary win. Formatting polish is secondary and can be iteratively improved.

