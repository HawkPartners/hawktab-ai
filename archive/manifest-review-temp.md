## Manifest Review — Temporary Notes

Audience: internal. Purpose: capture corrections needed in `r/manifest.json` and note recurring patterns for heuristics.

### Issues by question

- S6
  - Expected: range of whole numbers 3–35 (not a positive-value=1 flag).

- S8
  - Expected: percentage range 0–100 for each option; row total should equal 100.
  - Not a positive-value=1 field.

- S10
  - Expected: range of whole numbers 0–50.

- S11
  - Expected: range of whole numbers 0–10.

- S12
  - Expected: range of whole numbers per option.
  - Upper bound depends on S11: max(S12) = max(S11).

- A1
  - Expected: per-row single selection; allowed values {1, 2} where 1 and 2 represent different options.
  - Not a positive-value=1 field.

- A3
  - Expected: range of whole numbers.

- A3A
  - Expected: range of whole numbers; represents a sum per row (column totals by row).

- A3B
  - Expected: range of whole numbers.

- A4
  - Expected: range of whole numbers.
  - A4A and A4B: same expectation (ranges of whole numbers).

- A8
  - Expected: ordinal scale 1–5 (not a positive-value=1 field).

- A9
  - Expected: ordinal scale 1–4.

- B1
  - Expected: percentage range 0–100 (insurance coverage); likely per-option percentages.

- B3, B4
  - Missing from manifest.
  - B3: select (categorical choice).
  - B4: range (numeric).

### Meta learnings (heuristics to encode)

- Value-type classification
  - Distinguish binary flags (positive-value=1) from scales, counts, and percentages.
  - Detect ordinal scales via answer option patterns (e.g., 1–5 Likert, 1–4 agreement).

- Percentage distributions
  - If options imply shares (e.g., S8, B1), each option should be 0–100 with optional row-sum=100 constraint.

- Integer ranges
  - Many items are whole-number ranges (S6, S10, S11, S12, A3/A3A/A3B, A4/A4A/A4B). Default to non-negative integers unless metadata states otherwise; cap based on hints (labels, related questions).

- Dependent bounds
  - Allow a question's valid range to depend on another (e.g., S12 upper bound equals max of S11).

- Row-level single-choice matrices
  - For grid questions like A1, enforce per-row allowed set (e.g., {1, 2}) rather than treating as boolean.

- Coverage completeness
  - Ensure all questions present in the data map are represented in the manifest (B3/B4 surfaced as gaps).

These notes should guide updates to `TablePlan`/`CutsSpec` building rules and validation checks so value types and constraints reflect the underlying question intent.


