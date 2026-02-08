# HawkTab AI — System Behavior Reference

How HawkTab AI makes decisions, what it handles, and what it doesn't.

---

## Unit of Analysis

**Non-loop tables:** One row per respondent. Bases = respondent counts.

**Loop tables (stacked data):** One row per entity (occasion, medication, brand, etc.). When a survey asks the same questions multiple times (e.g., "describe your first drinking occasion, then your second"), HawkTab stacks the data so each row represents one loop iteration. A respondent with 2 occasions produces 2 rows.

- **Total base on loop tables** = total entity count (e.g., 7,420 occasions), not respondent count
- **Banner bases on loop tables** = entity counts within the banner segment
- Respondent counts on loop tables are not currently reported

---

## Banner Cuts on Stacked Data

When loops are detected, each banner group is classified as one of two types:

**Respondent-anchored** (e.g., demographics, general attitudes): The cut describes the respondent, not the specific entity. On loop tables, it means "entities from respondents in this segment." The cut applies identically to every stacked row for a given respondent. No transformation is needed.

Example: "Location: Own Home" (`S9r1 == 1`) — the respondent drinks at home. Both of their occasion rows match.

**Entity-anchored** (e.g., needs state per occasion, assigned treatment per medication): The cut describes the specific loop iteration. It requires iteration-aware logic so that each stacked row is evaluated against the variable that corresponds to ITS iteration, not all iterations.

Example: "Connection/Belonging" needs state — occasion 1 uses S10a, occasion 2 uses S11a. On the stacked frame, an alias column selects the correct source per row.

**Default behavior:** HawkTab uses a combination of metadata scanning and AI classification to determine anchor type for each banner group. Entity-anchored groups get alias columns on the stacked frame; respondent-anchored groups are left unchanged.

---

## Statistical Testing

### Tests Used

| Data Type | Test | Notes |
|-----------|------|-------|
| Proportions (frequency tables) | Unpooled z-test | WinCross default. Compares two column proportions. |
| Means (mean_rows tables) | Welch's t-test | Robust to unequal variances. Uses summary statistics (n, mean, sd). |

### Default Configuration

| Setting | Default | Notes |
|---------|---------|-------|
| Confidence level | 90% (p < 0.10) | Single threshold. Dual thresholds (e.g., 95%/90%) are supported. |
| Minimum base size | None (0) | All cells are tested regardless of base size. |
| Comparison mode | Within-group + vs Total | Each column is compared to every other column in its banner group, plus compared to Total. |

### Stat Letter Assignment

Each banner column receives a letter (A, B, C, ...). When column A is statistically significantly higher than column B, "B" appears in column A's significance cell. This follows the industry-standard convention used by WinCross and SPSS.

### What We Don't Do (Stat Testing)

- **No minimum base suppression by default.** If a base has 5 respondents, it still gets tested. This matches WinCross behavior. A minimum base can be configured.
- **No overlap-aware testing on loop tables yet.** If a banner group's segments overlap (a stacked row can match multiple cuts), within-group stat letters may be invalid. The system will validate partition behavior on loop tables and suppress within-group letters when overlap is detected.
- **No clustered standard errors on loop tables.** Stacked rows from the same respondent are correlated, which can overstate significance. Standard tests treat them as independent. This is industry-standard behavior (WinCross, SPSS Tables, Q all do the same), but technically overstates the effective sample size. A future enhancement could add cluster-robust testing.
- **No weighted stat tests.** Weighting is not currently supported (see below).

---

## Table Types

HawkTab produces two types of tables:

**Frequency tables** — For categorical variables (single-select, multi-select, rankings, grids). Each row shows a count and percentage for one answer option. Rankings, grids, and multi-selects are all handled as frequency tables with appropriate row structures.

**Mean tables** — For numeric variables (scales, allocations, continuous measures). Each row shows mean, median, and standard deviation.

---

## Summary Rows (NETs, T2B, B2B)

HawkTab automatically adds summary rows based on question type:

| Question Type | Summary Rows Added |
|---------------|-------------------|
| 5-point agreement/satisfaction scales | Top 2 Box (4+5), Bottom 2 Box (1+2) |
| 7-point scales | Top 3 Box, Bottom 3 Box |
| 10-point scales | Top 2 Box (9+10), Bottom 2 Box (1+2) |
| Multi-select with natural groupings | NET rows rolling up related options |
| Aided/unaided awareness | Total Awareness NET |

NET rows are indented to show parent-child relationships. Their components are explicitly listed so the calculation is auditable.

---

## Missing Data (NA) Handling

- **Base calculation:** NAs are excluded. The base is the count of non-missing responses.
- **Percentages:** Calculated against the non-missing base. If base = 0, percentage = 0 (not NA).
- **Means:** Calculated on non-missing values only (`na.rm = TRUE`).
- **Tables with zero base:** Still appear in output with base = 0 and all values = 0. They are not hidden or excluded.

---

## Skip Logic and Table Filters

When a question has skip logic (e.g., "asked only of those who selected Brand X"), the system:

1. Extracts the rule from the survey document
2. Translates it to an R filter expression
3. Applies it as an `additionalFilter` on the table

**Effect:** The base for that table only includes respondents who qualified. The base text describes who was asked (e.g., "Those aware of Brand X"). If no filter applies, base text defaults to "All respondents."

**Zero-base behavior:** If a filter + banner cut combination produces zero qualifying respondents, the cell shows base = 0 and percentage = 0. The table is still generated.

---

## Weighting

**Not currently supported.** All counts, percentages, and means are calculated from raw, unweighted data. Survey weights in the .sav file are not applied.

This is a known gap. When implemented, weights will be applied to frequency counts, means, and statistical tests.

---

## Loop Detection

HawkTab automatically detects looped survey structures by analyzing variable naming patterns in the .sav file (e.g., `A2_1`, `A2_2` indicating 2 iterations of question A2).

**What triggers loop detection:**
- Variable families with `_1`, `_2`, `_3`... suffixes
- Consistent fill-rate patterns (dropout across iterations = real loop; uniform fill = wide format)

**What happens when loops are detected:**
- Loop variables are collapsed (e.g., `A2_1`/`A2_2` become `A2`)
- A stacked data frame is created (one row per entity)
- Loop tables automatically use the stacked frame
- Non-loop tables continue using the original respondent-level frame

**What we don't handle:**
- **Already-stacked data.** If the .sav file is pre-stacked (one row per entity already), the pipeline blocks with a warning rather than double-stacking.
- **Roster/value-to-row linking.** When you need to map an assigned value (e.g., "Treatment_1 = Fintepla") to a specific grid row (e.g., knowledge of that medication), HawkTab does not perform this linkage. This is a specialized feature beyond iteration gating.

---

## Excel Output Formats

| Format | Layout | Use Case |
|--------|--------|----------|
| **Joe** (default) | Horizontal — one row per answer, columns are value + sig pairs | Internal analysis, matches traditional crosstab layout |
| **Antares** | Vertical — three rows per answer (count, percent, sig stacked) | External client delivery |

Both formats include:
- Frozen panes for headers and label columns
- Banner group separators
- Stat letter annotations
- Base row at top of each table

---

## What HawkTab Determines Automatically vs What Requires Human Input

### Automatic (no human input needed)

- Table structure (which questions become tables, row definitions)
- Variable type classification (categorical, numeric, admin, etc.)
- Loop detection and stacking
- NET/T2B/B2B row insertion based on scale type
- Skip logic extraction from survey documents
- Banner cut translation to R expressions
- Statistical significance testing

### Requires Human-Provided Input

- **Banner plan** — provided as PDF/DOCX specifying banner groups and columns
- **Survey document** — provided as PDF/DOCX for skip logic extraction
- **Data file** — .sav (SPSS) format required

### May Require Human Review

- Complex skip logic with ambiguous phrasing
- Banner cuts where the system has low confidence in the R expression
- Entity-anchored banner groups where iteration mapping is uncertain
- Tables the system flags with `humanInLoopRequired` or `filterReviewRequired`
