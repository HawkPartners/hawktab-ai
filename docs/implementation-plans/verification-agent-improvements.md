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

**Status**: Not started
**Type**: Prompt guidance

**Problem**: Model sometimes includes the question number (Q8, S11), sometimes doesn't. Inconsistent.

**Options**:
- A) Always include: "S8. Approximately what percentage of your professional time..."
- B) Never include: "Approximately what percentage of your professional time..." (system prepends Q# systematically)

**Decision needed**: Which approach?

---

### Gap 3: Plain English baseText

**Status**: Not started
**Type**: Prompt guidance

**Problem**: baseText field sometimes uses variable codes like "S2=1" instead of human-readable text like "Current Leqvio users".

**Fix**: Strengthen prompt guidance - baseText must ALWAYS be plain English that a reader would understand without seeing the datamap.

---

### Gap 4: Flat Table Anti-Pattern (A8 Issue)

**Status**: Not started
**Type**: Prompt guidance (strengthen existing)

**Problem**: A8 shows all scale values × all brands in one flat table (75 rows). The prompt mentions the "EVERYTHING TABLE" anti-pattern but it's not landing.

**The rule**: You should NEVER have a table that shows each scale value for each brand in a flat structure. This is the canonical example of what NOT to do.

**Correct approach for Brand × Scale grids**:
- Comparison tables: Pick ONE metric (T2B, B2B, or MB), show all brands
- Detail tables: Pick ONE brand, show full scale with rollups
- Never: All brands × all scale values in one table

**Fix**: Add much stronger, more specific guidance with explicit examples of wrong vs right.

---

### Gap 5: Comparison Tables = ONE Metric

**Status**: Not started
**Type**: Prompt guidance

**Problem**: Agent creates tables with Leqvio-T2B, Leqvio-MB, Leqvio-B2B, Repatha-T2B, Repatha-MB, Repatha-B2B all as rows in the same table. This misses the point of a comparison table.

**The rule**: A comparison table answers "How do items compare on a SPECIFIC metric?" It should show ONE metric (e.g., T2B) across all items. If you want to show multiple metrics, create separate comparison tables for each.

**Fix**: Add explicit rule to prompt.

---

### Gap 6: Indentation Semantics Still Broken (A9 Issue)

**Status**: Not started
**Type**: Prompt guidance (strengthen existing)

**Problem**: A9 has "No issues" indented under "Experienced issues (NET)" when "No issues" (value 1) is explicitly NOT part of that NET (values 2,3).

**Current state**: The prompt has an `<indentation_semantics>` section that explains this, but it's not working.

**Possible fixes**:
- Add a validation example showing the A9 error specifically
- Make the rule even more explicit: "BEFORE indenting a row, CHECK: is this row's filterValue contained in the NET's filterValue? If not, DO NOT indent."
- Add to anti-patterns section

---

### Gap 7: Don't Over-Convert mean_rows to Frequency

**Status**: Not started
**Type**: Prompt guidance

**Problem**: Too many mean_rows tables get converted to frequency distributions when it's not analytically useful.

**When frequency distributions ARE useful**:
- When the distribution shape is analytically interesting (bimodal, skewed, etc.)
- When specific thresholds matter ("What % have 10+ years experience?")
- When the analyst needs to segment by ranges

**When they're NOT useful**:
- When the mean is the primary insight and distribution adds noise
- When creating them mechanically for every numeric variable

**Fix**: Add guidance on when to create binned distributions vs when to leave as mean_rows.

---

### Gap 8: Each Table Tells a Unique Story

**Status**: Not started
**Type**: Prompt guidance

**Problem**: Tables repeat similar information in slightly different ways. Multiple tables from the same question don't each add unique insight.

**The principle**: Every table should answer ONE clear question. Before creating a derived table, ask: "What question does this table answer that the other tables don't?"

**Fix**: Add explicit "unique story" principle + scratchpad reflection step.

---

### Gap 9: Logical Row Ordering Within Tables

**Status**: Not started
**Type**: Prompt guidance

**Problem**: If showing "in addition to statin" vs "without statin" options, they should be grouped together logically, not interleaved.

**The principle**: Row ordering should follow logical groupings. Related items together.

**Fix**: Add brief guidance on row ordering.

---

### Gap 10: Judgment on Splits vs NETs

**Status**: Not started
**Type**: Prompt guidance

**Problem**: B1 - Is a separate "Medicare" table useful when an overview table with a Medicare NET would work?

**The question**: When does splitting into separate tables add value vs just using NETs in the overview?

**Guidance needed**: Don't split just because you can. Ask: "Does this split provide insight the overview with NETs doesn't provide?" If not, keep it in the overview.

---

### Gap 11: More Aggressive Exclusion (Terminate Criteria)

**Status**: Not started
**Type**: Prompt guidance (strengthen existing)

**Problem**: Tables where TERMINATE criteria mean most answer options have 0% aren't being excluded. If only one answer continues and the rest terminate, the table shows 100% for that option = no variance = exclude.

**Current state**: The prompt mentions this but it's not emphasized enough.

**Fix**: Strengthen guidance on recognizing terminate patterns → exclude.

---

### Gap 12: 100% NET Tables

**Status**: Not started
**Type**: Prompt guidance (strengthen existing)

**Problem**: "Any of the above (NET)" tables created when they're 100%. No variance = no insight = don't create.

**Current state**: Already in prompt but still happening.

**Fix**: Reinforce with specific example in anti-patterns.

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

## Priority Order

1. **Gap 1 (tableSubtitle)** - Enables proper table differentiation, blocks other improvements
2. **Gap 4 (Flat table anti-pattern)** - A8 is the canonical bad example
3. **Gap 5 (Comparison = ONE metric)** - Related to Gap 4
4. **Gap 6 (Indentation)** - Structural correctness issue
5. **Gap 3 (Plain English baseText)** - Quick win
6. **Gap 2 (Question text consistency)** - Needs decision on approach
7. Gaps 7-12 - Judgment refinements

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
