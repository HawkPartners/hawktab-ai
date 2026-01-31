# Verification Agent Improvements

**Status**: In Progress
**Last Updated**: 2026-01-31
**Context**: Review of `outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-01-30T23-51-44-742Z/`

---

## Summary

The alternative prompt (`src/prompts/verification/alternative.ts`) has been restructured with mission framing, rendering mindset, and anti-patterns. What remains are specific behavioral gaps and system changes needed to complete the improvements.

---

## Remaining Gaps

### Gap 1: tableSubtitle Field (Schema + Prompt + Excel)

**Status**: Not started
**Type**: Schema change + Prompt guidance + Excel formatter

**Problem**: When the agent creates multiple tables from the same question (e.g., A1 for Leqvio vs A1 for Repatha), there's no way to clearly differentiate them. The agent tries to cram this into `questionText` which doesn't work well.

**What Joe does**: In the context column, Joe uses a subtitle line that describes WHAT this specific table is showing:
- S8 Table 1: "Mean Percentage of Professional Time on Activities" (summary view)
- S8 Table 2: "Professional Time Treating/Managing Patients" (detail view for one activity)
- S11 Table #1: "Number of Patients with Elevated LDL-C" (raw count distribution)
- S11 Table #2: "Special Calculated Percent of Patients with Elevated LDL-C Among Total Patients Treated at Practice" (derived metric)

**For brand splits**: Instead of labeling every row as "Leqvio - Highly Likely", the table has `tableSubtitle: "Leqvio"` with clean row labels "Highly Likely", "Somewhat Likely", etc.

**Implementation**:
1. Add `tableSubtitle` field to ExtendedTableDefinition schema
2. Add prompt guidance on when/how to use it (derived tables, brand splits, different analytical views)
3. Update Excel formatter to render subtitle in context column between section and question text

**Why this matters**: Cleaner row labels + clear table differentiation in the context column.

---

### Gap 2: Question Text Consistency

**Status**: Decision made, not implemented
**Type**: Prompt guidance + System rendering

**Problem**: Model sometimes includes the question number (Q8, S11), sometimes doesn't. Inconsistent.

**Decision**: Option B - Model outputs ONLY the question text, stripped of any question number prefix.

**Prompt change**: Tell the model to always strip the question number and output only the verbatim question text. Example: "Approximately what percentage of your professional time..." (not "S8. Approximately what percentage...")

**System change**: Excel formatter prepends `questionId + ". "` to questionText when rendering. This ensures consistent formatting like "S8. Approximately what percentage..." in the final output.

---

### Gap 3: Plain English for User-Facing Fields

**Status**: Decision made, not implemented
**Type**: Prompt guidance

**Problem**: baseText and userNote fields sometimes use variable codes like "S2=1" instead of human-readable text.

**The rule**: The reader doesn't know what "S2=1" means. The model must translate variable codes into what they represent in the survey context: "Gen Z", "Women", "NP/PAs", "Current Leqvio users", etc.

**Affected fields**:
- `baseText` - Who was asked this question
- `userNote` - Additional context for the analyst

**Prompt change**: Emphasize that ALL user-facing text fields must be plain English. No variable codes, no filter expressions. If you're describing a filter condition, translate it to what it means in human terms.

**System note**: Same rule applies to any user-facing output we render.

---

### Gap 4: Flat Table Anti-Pattern (A8 Issue)

**Status**: ✅ Already addressed in prompt

The alternative prompt already covers this with:
- "THE EVERYTHING TABLE" anti-pattern (lines 313-315)
- "One 60-row table showing all brands × all scale values? That's where you've lost the analyst." (line 42)
- Comparison vs Detail view framework (lines 207-240)

The remaining issue is Gap 5 (ONE metric per comparison table).

---

### Gap 5: Comparison Tables = ONE Metric

**Status**: Decision made, not implemented
**Type**: Prompt guidance

**Problem**: Agent creates tables with Leqvio-T2B, Leqvio-MB, Leqvio-B2B, Repatha-T2B, Repatha-MB, Repatha-B2B all as rows in the same table. This crowds the table and defeats the purpose of a comparison view.

**The rule**: A comparison table shows ONE metric/rollup across all items. This keeps it scannable.

**Wrong**:
```
Leqvio - T2B      45%
Leqvio - MB       30%
Leqvio - B2B      25%
Repatha - T2B     42%
Repatha - MB      28%
Repatha - B2B     30%
```

**Right** (three separate tables):
```
Table: "T2B Comparison"     Table: "MB Comparison"      Table: "B2B Comparison"
Leqvio    45%               Leqvio    30%               Leqvio    25%
Repatha   42%               Repatha   28%               Repatha   30%
Praluent  38%               Praluent  35%               Praluent  27%
```

**Prompt change**: Add explicit rule to the COMPARISON VIEWS section - one metric per comparison table.

---

### Gap 6: Indentation Semantics (A9 Issue)

**Status**: ✅ Already addressed in prompt

The alternative prompt covers this thoroughly:
- Clear rule: "A row with indent: 1 must have its filterValue INCLUDED in the NET row above it" (line 284)
- Wrong example showing exactly the A9 pattern (lines 295-301)
- Corrected version showing proper structure (lines 303-307)
- Listed as anti-pattern #3: "INVERTED INDENTATION" (line 321)

---

### Gap 7: Don't Over-Convert mean_rows to Frequency

**Status**: ✅ Already addressed in prompt

The prompt uses judgment language, not "always convert":
- "Consider binned distribution **if spread is analytically interesting**" (line 115)
- "WHEN TO USE: mean_rows questions where **the distribution shape is analytically interesting**" (line 266)

---

### Gap 8: Each Table Tells a Unique Story

**Status**: ✅ Already addressed in prompt

The prompt covers this through multiple mechanisms:
- "Each table should tell a clear story and be immediately understandable" (line 10)
- "You don't need every possible view. Consider what questions the analyst will actually ask." (line 261)
- Anti-pattern #5: "REDUNDANT NETS" (line 329)
- "does this enrichment really add value?" (line 338)

---

### Gap 9: Logical Row Ordering Within Tables

**Status**: Decision made, not implemented
**Type**: Prompt guidance

**Problem**: Row ordering from the flat table sometimes creates confusing output, especially for grid patterns.

**The nuance**:
- **Default**: Keep the order from the flat table—it usually makes sense
- **Exception**: Grid patterns (rXcY) may need reordering when the flat order jumps between dimensions

**Example of confusing flat order**:
```
r1c1 - Brand A, Situation 1
r1c2 - Brand A, Situation 2
r2c1 - Brand B, Situation 1
r2c2 - Brand B, Situation 2
```
This interleaves situations, making it hard to compare brands within a situation.

**Better grouping** (group by one dimension):
```
r1c1 - Brand A, Situation 1
r2c1 - Brand B, Situation 1
r1c2 - Brand A, Situation 2
r2c2 - Brand B, Situation 2
```
Now all Situation 1 items are together, then all Situation 2.

**Prompt change**: Add guidance that the model CAN reorder rows in a constrained manner. Default is to preserve flat table order, but for grids, group by one dimension so related items appear together.

**Future consideration - Category headers for visual grouping**:

Joe's output shows indentation used for visual grouping, not just NETs:
```
Over 5 years ago          ← category header (no data value)
  None (0)         1%     ← indented for visual grouping
  Any (1+)        99%
  25 or more      68%
Within the last 3-5 years ← another category header
  None (0)         -
  Any (1+)       100%
  25 or more      55%
```

"Over 5 years ago" isn't a NET—it's a visual category label that groups the rows below it. This is different from our current system where `indent: 1` means "component of the NET above."

**Note**: Need to verify if our system supports category header rows (indent: 0, no filterValue, purely for visual organization). If not, this capability should be added, then prompt updated to allow the model to create category headers for visual grouping when it improves readability.

---

### Gap 10: Judgment on Splits vs NETs

**Status**: ✅ Addressed implicitly

The prompt's emphasis on judicious thinking and "does this add value?" covers this. The model is taught to ask whether each derived table earns its place, which applies to split vs NET decisions.

---

### Gap 11: More Aggressive Exclusion (Terminate Criteria)

**Status**: Decision made, not implemented
**Type**: Prompt guidance

**Problem**: Model isn't recognizing when terminate criteria make a table uninformative.

**The logic to teach**:
- If terminate criteria mean only ONE answer is possible → table shows 100% for that option → likely exclude
- But apply judgment—it's not a hard rule

**Nuances**:
- Terminate might constrain the RANGE but still leave meaningful variation (e.g., "must be 5+" but distribution of 5-20 is still interesting)
- Terminate might affect one brand but not others
- Terminate might eliminate one answer but leave 5 valid options with real variance

**Prompt change**: Add guidance that the model should be mindful of terminate criteria when assessing whether a table adds value. If terminate logic means effectively one answer, consider excluding. But recognize the nuance—constrained range ≠ no variance.

---

### Gap 12: 100% NET Tables

**Status**: ✅ Already addressed in prompt

Covered in multiple places:
- "Screener where everyone qualified (100% one answer)? → Exclude" (line 123)
- Anti-pattern #5 "REDUNDANT NETS" + "100% = no variance = no insight" (lines 329-331)
- Terminate logic → 100% → exclude (line 370)
- "Screeners with 100% pass rate → Exclude" (line 596)

---

## System Changes Needed

### System 1: tableSubtitle Schema Field

**Status**: Not started

Add `tableSubtitle?: string` to ExtendedTableDefinition schema. This field holds the descriptive subtitle that differentiates tables from the same question.

---

### System 2: Full Table ID in Excel Context Column

**Status**: Not started

Add the full tableId at the bottom of the context column in Excel output for reference/debugging.

---

### System 3: Auto-Size Row Height in Excel

**Status**: Not started

Excel formatter should auto-size row heights so wrapped text displays properly.

---

### System 4: Investigate A3a R Script Issue

**Status**: Not started

A3a brands don't add up to 100% - possible R script calculation error. Needs investigation.

---

## Appendix: Example Tables from Joe

### S8 - Two views of same question

**Table 1** (Summary):
- Section: SCREENING SECTION
- Subtitle: "Mean Percentage of Professional Time on Activities"
- Question: S8. Approximately what percentage of your professional time is spent performing each of these activities?
- Rows: Each activity with mean %

**Table 2** (Detail):
- Section: SCREENING SECTION
- Subtitle: "Professional Time Treating/Managing Patients"
- Question: S8. Approximately what percentage of your professional time is spent performing each of these activities?
- Rows: Binned distribution for one specific activity

### S11 - Two analytical cuts

**Table #1**:
- Subtitle: "Number of Patients with Elevated LDL-C"
- Rows: Count bins (20-74, 75-149, 150-249, etc.)

**Table #2**:
- Subtitle: "Special Calculated Percent of Patients with Elevated LDL-C Among Total Patients Treated at Practice"
- Rows: Percentage bins (Less than 25%, 25%-49%, etc.)

Same question, different analytical lens, clearly differentiated by subtitle.
