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


### RScriptGenerator
_Issues with R code generation (wrong filter values, incorrect variable references)_


### R Calculations
_Issues with the calculated values (wrong base n, percentage errors, significance testing)_

- **A3a / A3b allocation questions**: These appear to be allocation questions where values should sum to 100%, but some don't. Needs detailed review to verify data accuracy.


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


### Labels / Text
_Truncated labels, encoding issues, missing titles_


---

## Notes

Initial rough pass - need detailed cell-by-cell comparison for data accuracy verification.

