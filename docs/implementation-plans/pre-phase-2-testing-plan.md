# Pre-Phase II: Testing & Validation Plan

## Overview

Before implementing Phase II reliability features, we need to prove the core pipeline works across multiple datasets with clean inputs. This document tracks that validation process.

**Philosophy**: Prove clean input → correct output before optimizing for messy inputs.

---

## Current Status

| Milestone | Status | Description |
|-----------|--------|-------------|
| 1. Single Clean Banner → Correct Base Sizes | ✅ **COMPLETE** | Leqvio Demand practice files |
| 2. Table Formatting & Stitching | 🔄 **IN PROGRESS** | DataMapProcessor fixed; ready for table formatting |
| 3. Validate Against Actual Reports | Not Started | Can we write the same report? |
| 4. Clean Banner Plans Across All Test Data | Not Started | 23 datasets to test |
| 5. Non-Clean Banner Testing | Not Started | Document failure modes |

---

## Milestone 1: Single Clean Banner → Correct Base Sizes ✅

**Date Completed**: January 2, 2026

**What we did**:
- Created `data/practice-files/leqvio-demand-bannerplan-clean.docx` with explicit variable references
- Updated BannerAgent prompt (pattern-based, no cheating language)
- Updated CrosstabAgent prompt (cleaner expression type handling)
- Fixed Calculations/Rows being incorrectly treated as a group

**Results**:
- All base sizes match expected values
- Groups extracted correctly (Specialty, Role, Volume, Tiers, Segments, Priority Accounts)
- R expressions generated correctly
- Zero discrepancies with Joe's expected output

**Key Learning**: With clean, explicit input, the pipeline produces correct output.

---

## Milestone 2: Table Formatting & Stitching (IN PROGRESS)

**Goal**: Make output look like what Joe or a fielding partner produces.

**Requirements**:
- [ ] Tables stitched together into a single workbook
- [ ] Proper column headers and row labels
- [ ] Significance testing (stat letters)
- [ ] Standard calculations: Top 2 Box (T2B), Bottom 2 Box (B2B), Means
- [ ] Proper formatting (percentages, decimal places, etc.)

**Success Criteria**: Output Excel file is indistinguishable from Joe's tabs in structure and formatting.

### Progress Notes

**January 3, 2026 - DataMapProcessor Optimization (Prerequisite)**

Started work on table formatting but discovered DataMapProcessor wasn't classifying variable types correctly. TablePlan relies on `normalizedType` to determine table structure, so this was a blocker.

**Issues found and fixed** (see `temp-outputs/output-2026-01-03T10-14-25-915Z/bugs-*.md`):
- Bug 0: BannerAgent sometimes only produced 1 group → prompting fix
- Bug 1: Binary 0-1 items misclassified as `numeric_range` → now `binary_flag`
- Bug 2: Scale items (1-5) misclassified → now `categorical_select` via threshold
- Bug 3: Open text/numeric response lines were being dropped by parser → fixed
- Bug 4: Small ranges (1-2, 1-53) misclassified → now `categorical_select`

**Additional improvements**:
- Added scratchpad trace output (`scratchpad-banner-*.md`, `scratchpad-crosstab-*.md`) for debugging agent reasoning
- Added bug tracker template auto-generation for each run

**Status**: DataMapProcessor now correctly classifies variable types. Ready to resume table formatting work.

---

## Milestone 3: Validate Against Actual Reports

**Goal**: Confirm AI tabs support the same analysis as Joe's tabs.

**Process**:
1. Take a report we wrote using Joe's Leqvio Demand tabs
2. Regenerate tabs using HawkTab AI
3. Verify all data points in the report can be found in AI tabs
4. Confirm numbers match exactly

**Success Criteria**: We can write the exact same report from AI-generated tabs.

---

## Milestone 4: Clean Banner Plans Across All Test Data

**Goal**: Prove clean input → correct output across diverse datasets.

**Test Data Available** (23 datasets in `data/test-data/`):
- CART-Segmentation-Data_7.22.24_v2
- Cambridge-Savings-Bank-W1_4.9.24
- Cambridge-Savings-Bank-W2_4.1.25
- GVHD-Data_12.27.22
- Iptacopan-Data_2.23.24
- Leqvio-Demand-W1_3.13.23
- Leqvio-Demand-W2_8.16.24 v2
- Leqvio-Demand-W3_5.16.25
- Leqvio-Segmentation-Data-HCP-W1_7.11.23
- Leqvio-Segmentation-Data-HCP-W2_2.21.2025
- Leqvio-Segmentation-Patients-Data_7.7.23
- Meningitis-Vax-Data_10.14.22
- Onc-CE-W2-Data_5.10.20
- Onc-CE-W3-Data_5.13.21
- Onc-CE-W4-Data_3.11.22
- Onc-CE-W5-Data_2.7.23
- Onc-CE-W6-Data_3.18.24
- Spravato_4.23.25
- UCB-Caregiver-ATU-W1-Data_1.11.23
- UCB-Caregiver-ATU-W2-Data_9.1.23
- UCB-Caregiver-ATU-W4-Data_8.16.24
- UCB-Caregiver-ATU-W5-Data_1.7.25
- UCB-Caregiver-ATU-W6-Data_1.23.24

**Process for each dataset**:
1. Create clean banner plan with explicit variable references
2. Run through HawkTab AI
3. Compare output tabs with actual tabs used in reports
4. Document any issues (fix if clean input issue, note if data-specific)

**Success Criteria**: All 23 datasets produce correct tabs with clean banner plans.

---

## Milestone 5: Non-Clean Banner Testing

**Goal**: Document failure modes when input is messy/ambiguous.

**Process**:
1. Take original (non-clean) banner plans
2. Run through HawkTab AI
3. Document each failure:
   - What was the ambiguous input?
   - What did the system do?
   - What should it have done?
   - What context would have helped?

**Output**: Updated `docs/reliability-gaps.md` with comprehensive failure mode catalog.

**This directly informs Phase II implementation** - we'll know exactly what problems to solve.

---

## What This Proves

After completing all milestones:

1. **Clean Input → Correct Output**: Definitively proven across 23+ datasets
2. **Output Quality**: Matches Joe's tabs in format and content
3. **Report Validity**: Can write real reports from AI tabs
4. **Failure Mode Catalog**: Know exactly where messy inputs break

**At this point, we can demonstrate**:
> "If you give HawkTab AI a clean banner plan, you get the same tabs Joe produces."

This is sufficient to:
- Show stakeholders the system works
- Train partners to provide clean inputs
- Identify which Phase II features matter most

---

## Relationship to Phase II

Phase II (BannerValidateAgent, DataValidator, Human Review) addresses:
- What happens when input ISN'T clean
- How to catch errors before R execution
- How to surface issues in human-understandable language

**We don't implement Phase II until**:
1. Pre-Phase II milestones complete
2. Failure modes documented from Milestone 5
3. Phase II plan updated based on actual (not theoretical) issues

---

*Created: January 2, 2026*
*Last Updated: January 3, 2026*
