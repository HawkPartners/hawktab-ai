# Consolidated Pipeline Findings & Fixes

**Dataset:** Tito's Future Growth Strategy (stacked data, 5,098 respondents, 2 loop iterations)
**Runs Analyzed:** 7 pipeline runs (Feb 7, 2026)
**Sources:** User feedback + 4 agent consistency analyses, validated against source code

---

## How to read this document

Each fix is labeled with a priority and category. They're not in strict execution order — read through all of them, then we can sequence together.

- **P0** = Must fix before broader testing (affects correctness)
- **P1** = Should fix for reliability (affects consistency across runs)
- **P2** = Nice to have (affects polish/observability)
- **CODE** = Fix in source code (deterministic)
- **PROMPT** = Fix in agent prompt (probabilistic, needs testing)
- **ARCH** = Architectural decision needed

---

## P0-1: Base Size Inflation from Stacked Data [CODE/ARCH]

**The problem:** The stacked frame has 10,196 rows (5,098 respondents x 2 loop iterations). When respondent-level variables (like `S6`, `hAge`) are used as banner cuts on the stacked frame, they match BOTH rows per respondent, inflating base sizes by ~2x.

**Validated:** Confirmed. `RScriptGeneratorV2.ts` uses `table.loopDataFrame || 'data'` to pick the frame (line 920) but there's no logic anywhere to distinguish respondent-level filters from occasion-level filters, and no `distinct(respondentId)` or `loop_iteration == 1` guard for non-loop questions on stacked frames.

**This is likely the #1 reason our totals are bigger than Joe's.**

**Fix options (need to decide which):**
1. For non-loop tables running on stacked frames, add `loop_iteration == 1` filter so each respondent counted once
2. Use `n_distinct(respondentId)` for base size calculation instead of `nrow()`
3. Separate respondent-level tables from occasion-level tables entirely (different data frames)

**Where to fix:** `RScriptGeneratorV2.ts` (table generation functions) and/or `PipelineRunner.ts` (frame assignment logic)

---

## P0-2: FilterTranslator Variable Family Inconsistency [PROMPT]

**The problem:** The FilterTranslator produces wildly different R expressions for the same skip logic rule across runs. The A6 on-premise filter used 5 different variable families across 6 runs: `dLOCATIONr*`, `hLOCATIONr*`, `hPREMISE*`, and combinations.

**Validated:** Confirmed no premise/location guidance exists in prompts. The datamap has multiple variable families that could represent "on-premise" and the agent has zero guidance on which to prefer.

**Root cause:** The datamap doesn't document which `hPREMISE` value means on-premise vs off-premise, and there are overlapping variable families (`hPREMISE`, `hLOCATION`, `dLOCATION`, `S9r`) that the agent chooses between randomly.

**Fix:**
1. Add explicit variable preference rules to FilterTranslator prompt: "For on/off-premise conditions, prefer `hPREMISE` variables. `hPREMISE1` = Location 1, `hPREMISE2` = Location 2. Value 1 = on-premise, value 2 = off-premise." (Verify the actual coding from the .sav first.)
2. Consider passing the CrosstabAgent's variable mapping as context so FilterTranslator knows which variable families were already chosen for banner cuts
3. Add post-translation validation that checks all referenced variables actually exist in the datamap

**Where to fix:** `src/prompts/filtertranslator/` prompt files

---

## P0-3: R Identifier Sanitization [CODE]

**The problem:** In the `06-52` run, the pipeline died with an R parse error because `loopDataFrame` was set to a human-readable string like `"Location 1 / Location 2"` instead of a valid R identifier, which got inserted directly into generated R code.

**Validated:** Confirmed. `RValidationGenerator.ts:222` and `RScriptGeneratorV2.ts:920` both use `table.loopDataFrame` directly as an R variable name with no sanitization.

**This was fixed for the successful run** (loop groups merged into `stacked_loop_1`), but there's no safety net — if a future dataset produces a non-R-safe `loopDataFrame` name, it'll break again.

**Fix:** Add validation in `RScriptGeneratorV2.ts` and `RValidationGenerator.ts` that `loopDataFrame` is a valid R identifier (alphanumeric + underscore, starts with letter/dot). If not, sanitize it or throw a clear error.

---

## P1-1: Verification Agent Reasoning Effort [CONFIG]

**The problem:** At `low` reasoning effort, the VerificationAgent misses intuitive analytical additions that a human analyst would make. Examples:
- S9 (multi-select location question): No NET for "any location > 0" or frequency distribution
- S8/S9: No penetration percentage view
- Scratchpad depth varies 30x (1.5KB to 46KB) — sometimes thorough, sometimes superficial

**Validated:** Multiple reports agree. Interestingly, scratchpad depth does NOT correlate with output quality — the run with NO verification scratchpad produced better NETs than the 46KB run. But `low` consistently misses the "what would a researcher want to see" intuition.

**Fix:** Bump `VERIFICATION_REASONING_EFFORT` from `low` to `medium` in `.env.local`. Keep all other agents at `low` since BannerAgent and CrosstabAgent are stable there.

**Cost impact:** Verification is already 65-83% of total pipeline cost ($0.45 of $0.67). Medium will increase this, but correctness > cost at this stage.

---

## P1-2: Scratchpad Contamination Across Parallel Paths [CODE]

**The problem:** When the pipeline runs Path A (Banner/Crosstab), Path B (TableGenerator), and Path C (SkipLogic/Filter) in parallel, the global scratchpad buffer mixes entries across agents. `getAndClearScratchpadEntries()` drains ALL entries regardless of agent, so one path's clear can wipe another path's entries.

**Validated:** Confirmed in code. `scratchpad.ts:12` has a single global `scratchpadEntries` array. `getAndClearScratchpadEntries()` (line 80-88) returns everything and clears everything. The `read` action (line 35) correctly filters by agent name, but the drain is global.

**Note:** Context-isolated scratchpads (`createContextScratchpadTool`) already exist for Verification's parallel per-table calls. The issue is the top-level agents (Banner, SkipLogic, Crosstab) still use the global buffer and run in parallel.

**Fix:** Change `getAndClearScratchpadEntries()` to accept an `agentName` parameter and only drain entries for that agent. Or switch all top-level agents to use context-isolated scratchpads too.

**Where to fix:** `src/agents/tools/scratchpad.ts`, then update callers in `PipelineRunner.ts`

---

## P1-3: CrosstabAgent Location Group Ambiguity [PROMPT]

**The problem:** The banner says "Assigned S9_1" which is ambiguous. The CrosstabAgent oscillated between `S9rN == 1` (checkbox binary — "anyone who checked location N") and `hLOCATION1 == N` (hidden assignment — "respondent assigned to location N as primary"). These produce different respondent subsets.

**Validated:** 60/40 split across 5 runs.

**Fix options:**
1. Add deterministic rule to CrosstabAgent prompt: "When 'Assigned' prefix appears alongside hidden h-prefix variables in the datamap, prefer the hidden assignment variable (`hLOCATION`)"
2. Clarify the banner input format so the ambiguity doesn't exist (better long-term)

**Where to fix:** `src/prompts/crosstabAgentPrompt.ts`

---

## P1-4: Strikethrough / Visual Formatting Blindness [CODE/ARCH]

**The problem:** The survey has values 4 and 5 crossed out in the A4/A13 condition, but ALL runs include them. The AI cannot detect strikethrough formatting because the survey text is converted to plain text before the agent sees it.

**Validated:** Confirmed in user feedback. This is a fundamental limitation — no amount of prompting will fix it if the formatting information is stripped before the agent sees it.

**Fix (two-part):**
1. **DOCX preprocessor** (preferred): When converting survey DOCX to text, preserve formatting as inline tokens: `~~strikethrough~~`, `[HIGHLIGHT: text]`, `[COMMENT: text]`. This is deterministic and reliable.
2. **Prompt instruction**: Tell SkipLogicAgent: "Text marked with `~~strikethrough~~` has been removed from the instrument. Exclude struck-through values from all rule conditions."

**Where to fix:** Survey processing code (wherever DOCX is converted to text), then SkipLogic prompt

---

## P1-5: SkipLogic Row-Level Rule Inconsistency [PROMPT]

**The problem:** Row-level display logic (like S10b: "show responses based on S10a selection") is extracted in some runs but missed in others. When missed, FilterTranslator can't translate what doesn't exist. Also, A16-A19 get lumped into one coarse rule when they have distinct conditions.

**Validated:** Consistent finding across all reports. Tracks with reasoning effort — `minimal` misses row-level rules more often than `low`.

**Fix:**
1. Update SkipLogic prompt to explicitly treat "PN:" (programming note) patterns as first-class output: "Response-option filtering (e.g., 'show responses based on X selection') is a row-level rule. Always extract these."
2. Enforce rule granularity: "Create one rule per question when conditions differ, even if they share a parent gate. Use parent/child structure if needed."
3. Consider bumping SkipLogic reasoning to `medium` (it already runs once per pipeline, so cost is minimal)

**Where to fix:** `src/prompts/skiplogic/` prompt files

---

## P1-6: Verification Agent NET/Split Inconsistency [PROMPT]

**The problem:** The VerificationAgent's NET creation and table splitting strategy varies dramatically across runs:
- S9: Sometimes adds On-Premise/Off-Premise NETs, sometimes doesn't
- A22 (brand-attribute grid): Three completely different split strategies across runs (by attribute, by brand column, by attribute with different prefix)
- Naming inconsistency: `_bins` vs `_binned` vs `_dist_bins`

**Fix:**
1. Add explicit prompt rules for NET creation: "For multi-select questions, always add a 'Any selected (NET)' row excluding 'None'. For count/mean questions where means are low, add a frequency distribution or 'any > 0' NET."
2. Add deterministic split rules for grids: Standardize whether matrix questions split by row vs column vs not at all
3. Define a naming convention for derived tables in the prompt and enforce it

**Longer term:** Move the easy, repeatable enrichment decisions out of the LLM entirely (deterministic NETs for multi-select, standard T2B/B2B for scales). Let Verification focus on judgment calls.

**Where to fix:** `src/prompts/verification/production.ts`

---

## P1-7: Value Label Conflicts in Stacked Data [CODE]

**The problem:** R execution log shows `A18` has conflicting value labels between loop iterations (label for value 4 differs between `..1$A18` and `..2$A18`). When stacking, one label wins arbitrarily, which can cause subtle inconsistencies.

**Validated:** Seen in R execution.log for the successful run.

**Fix:** In the R stacking code, add explicit conflict resolution: either prefer the first iteration's labels (document this), or log a warning that surfaces in the pipeline summary.

**Where to fix:** `RScriptGeneratorV2.ts` stacking logic

---

## P2-1: _HEADER_ Duplication Warnings [CODE]

**The problem:** Static validation reports duplicate `_CAT_:_HEADER_` combinations in tables like `s10b`. This happens because multiple category header rows all use `variable: "_CAT_", filterValue: "_HEADER_"`.

**Validated:** Confirmed in code — `_HEADER_` is the sentinel value for category headers that don't produce data rows. Multiple headers in one table create duplicate key warnings.

**Fix:** Either make the validation aware that `_HEADER_` rows are exempt from uniqueness checks, or give each header a unique suffix (`_HEADER_1`, `_HEADER_2`).

**Where to fix:** Static validation logic in `RValidationGenerator.ts` or `RScriptGeneratorV2.ts`

---

## P2-2: CrosstabAgent Alternatives Not Emitted [PROMPT]

**The problem:** The CrosstabAgent's scratchpad discusses alternative variable mappings (e.g., `hLOCATION` as an alternative to `S9r`), but the output has empty `alternatives` arrays. The reasoning mentions them, the structured output drops them.

**Fix:** Add prompt instruction: "If you consider alternative variable families during reasoning, you MUST include them in the `alternatives` array. If alternatives exist, set `humanReviewRequired: true`."

**Where to fix:** `src/prompts/crosstabAgentPrompt.ts`

---

## P2-3: FilterTranslator Confidence Threshold [CODE]

**The problem:** Low-confidence filters (0.4) are sometimes NOT flagged for human review. There's no enforced threshold.

**Fix:** Add a post-processing check: if any filter has confidence < 0.7, force `humanReviewRequired: true` regardless of what the agent said.

**Where to fix:** FilterTranslator output processing in `PipelineRunner.ts` or the agent wrapper

---

## P2-4: Occasion-Level vs Respondent-Level Decision [ARCH]

**The problem:** Related to P0-1. The stacked data produces occasion-level tables (one row per drink occasion). Joe may be producing respondent-level tables. These are both valid but produce different numbers.

**Decision needed:** Do we want occasion-level tables, respondent-level tables, or both? This affects how banner cuts work on stacked data and what "Total" means.

---

## What's Working Well (don't touch)

These areas are stable and don't need changes:

- **BannerAgent**: 100% consistent output across all runs. Keep at `low` reasoning.
- **CrosstabAgent Needs State group**: Identical expressions every run (`S10a == 1 | S11a == 1` etc.)
- **Simple filter translations**: `S6 == 1`, `A4 %in% c(...)` are always correct
- **T2B/B2B for scale questions**: Consistently added for 5-point scales (A11, A23)
- **R validation pass rate**: 63/63 in the successful run, 0 retries needed
- **Loop group merging**: The architectural decision to merge all loop groups into `stacked_loop_1` was correct and eliminated cross-frame variable errors
- **Label cleaning**: Survey text to clean labels works reliably
- **Pipeline cost trajectory**: Down from $0.98 to $0.67 (32% reduction) across runs

---

## Agent Reliability Ranking

| Agent | Rating | Notes |
|-------|--------|-------|
| BannerAgent | Excellent | No changes needed |
| CrosstabAgent | Good | Location group ambiguity is the only issue |
| SkipLogicAgent | Fair | Row-level rules + strikethrough are the gaps |
| VerificationAgent | Needs Work | Most variable, most impactful, most expensive |
| FilterTranslatorAgent | Poor | Least deterministic, needs the most prompt work |
