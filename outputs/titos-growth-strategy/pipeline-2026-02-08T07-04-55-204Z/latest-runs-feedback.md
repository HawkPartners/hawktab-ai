# Latest Runs Feedback

## 2026-02-08 — Tito's Future Growth

### What we learned

The Tito's dataset is our first real test of looped/stacked data, and it exposed issues across every layer of the pipeline. The good news: the core data is mostly correct — means match, the banner agent extracted the plan cleanly, and the skip logic agent showed genuine document comprehension (catching strikethrough text, correctly identifying no-rule questions). The system works. But the edges are rough, and the issues cluster into a few themes.

**The loop question is the big one.** Our pipeline defaults to reporting all loops (inclusive approach), while Joe only reports loop 1. Neither is wrong, but they produce different base sizes and different stories. We need a documented, defensible default — and right now we don't have one. Every output should clearly state our assumptions about how looped data is handled so users aren't surprised. Related: the LoopDetector's diversity threshold misses some obvious loop variables (A13a, A14a, A14b) because they're in sparse skeleton patterns. This is a deterministic fix that should be prioritized.

**Tables are being silently dropped.** Single-row categorical demographics (C1, C2, C4) don't produce tables at all — the pipeline only generates tables for multi-row matrices. State-from-zip (S4) is also absent. These are standard crosstab tables that users will expect to see.

**The verification agent needs guardrails, not just prompts.** Running in parallel loops means each instance reasons independently, producing inconsistent formatting: unnecessary NETs on single-select questions, section labels that appear on some tables but not others, base text that describes the question instead of the denominator, and varied note styles. We've tried prompt fixes for some of these before (especially the NET issue) and they haven't stuck. The pattern suggests we need a **deterministic post-processing pass** that enforces formatting rules after all agent instances finish — agent does the thinking, code enforces the presentation.

**Skip logic is mostly right, but the NET base computation is wrong.** The skip logic agent correctly identified no-rule questions and caught nuanced conditions. But the TableGenerator's NET base computation filters the denominator to respondents who have data in the NET's components (S9 on-premise NET base = 1993 instead of 5098). This is a real bug that produces wrong numbers.

**The crosstab agent prompt needs to generalize.** It's overfitted to specific datasets (literally lists locations in the guidance) and the multi-candidate confidence penalty is too aggressive. When multiple variable families exist, the agent should pick confidently and list alternatives — not penalize itself to 0.65 and flag everything for human review.

### Issue summary

| # | Issue | Severity | Type | Category |
|---|---|---|---|---|
| 1 | ~~Banner agent confidence penalty for low group count~~ | ~~Low~~ | ~~Prompt + code fix~~ | COMPLETE |
| 2 | ~~Crosstab agent prompt overfitting + confidence penalty~~ | ~~Medium~~ | ~~Prompt refactor~~ | COMPLETE |
| 3 | ~~Location variable selection philosophy (binary flag vs assignment)~~ | ~~High~~ | ~~Architectural decision~~ | COMPLETE (documented in system-behavior-reference.md) |
| 4 | ~~Table formatting: deterministic post-pass + sub-issues~~ | ~~Medium~~ | ~~Prompt + deterministic post-pass~~ | COMPLETE |
| 5 | ~~Missing S4 state-from-zip table~~ | ~~Low~~ | ~~New feature~~ | COMPLETE |
| 6 | ~~Unnecessary NET on single-select questions (S6a)~~ | ~~Medium~~ | ~~Prompt rule + post-pass~~ | COMPLETE |
| 7 | ~~Mean outlier trimming discrepancy vs Joe (S8)~~ | ~~Low~~ | ~~Investigate + document~~ | COMPLETE |
| 8 | ~~S9 NET base incorrectly filtered to 1993~~ | ~~High~~ | ~~Bug fix~~ | COMPLETE |
| 9 | ~~Missing location distribution table (hidden variable gap)~~ | ~~Medium~~ | ~~Architecture~~ | DEFERRED (moved to product roadmap) |
| 10 | ~~Verification agent creating non-base "base" text~~ | ~~Low~~ | ~~Prompt rule + post-pass warning~~ | COMPLETE |
| 11 | ~~We report S11a/b/c, Joe doesn't (loop philosophy)~~ | ~~Conceptual~~ | ~~Design decision~~ | COMPLETE (documented in system-behavior-reference.md) |
| 12 | ~~S11b/c base filtered to 68 (skip logic overzealous)~~ | ~~High~~ | ~~Investigation + fix~~ | COMPLETE |
| 13 | ~~Table sort order broken (C3 between A-series)~~ | ~~Medium~~ | ~~Deterministic fix~~ | COMPLETE |
| 14 | ~~Inconsistent section label cleanup~~ | ~~Low~~ | ~~Deterministic post-pass~~ | COMPLETE |
| 15 | ~~Dual-base reporting for skip logic questions (A10)~~ | ~~Conceptual~~ | ~~Future enhancement~~ | DEFERRED (moved to product roadmap) |
| 16 | ~~Loop variables not collapsed (A13a, A14a, A14b)~~ | ~~Medium~~ | ~~LoopDetector fix~~ | COMPLETE |
| 17 | ~~Section C tables missing (C1, C2, C4 dropped)~~ | ~~High~~ | ~~Bug fix~~ | COMPLETE |
| WIN | Skip logic agent caught strikethrough text on A13 | — | — | Validation |

### Where to focus next

**Deterministic fixes first** (wrong numbers, missing tables, broken sorting):
- ~~Issue 8: S9 NET base computation bug~~ COMPLETE
- ~~Issue 12: S11b/c base filtering investigation~~ COMPLETE
- ~~Issue 17: C1/C2/C4 tables being silently dropped~~ COMPLETE
- ~~Issue 16: LoopDetector diversity threshold for sparse patterns~~ COMPLETE
- ~~Issue 13: Table sort order~~ COMPLETE

**Then prompt/formatting consistency:**
- ~~Issue 6: NET suppression on single-select (recurring)~~ COMPLETE
- ~~Issue 14: Deterministic post-pass for formatting~~ COMPLETE
- ~~Issue 10: Base text vs question description~~ COMPLETE
- ~~Issues 1, 2: Banner and crosstab agent prompt tweaks~~ COMPLETE
- ~~Issue 4: All sub-issues resolved (4b: dash for zero-count rows, 4c: routing label cleanup)~~ COMPLETE

**Then document our assumptions:**
- ~~Issue 3/11: Loop reporting philosophy~~ COMPLETE — documented in system-behavior-reference.md
- ~~Issue 7: Outlier trimming method~~ COMPLETE — documented in system-behavior-reference.md
- Surface loop/stacking assumptions in every output so users know what they're getting (future: Methodology sheet)

---

### Tito's Future Growth — Detailed Issues

**Pipeline run:** `outputs/titos-growth-strategy/pipeline-2026-02-08T07-04-55-204Z/`

---

#### Issue 1: Banner Agent — Confidence Penalty for Low Group Count — COMPLETE

**Problem:** The banner agent self-penalized from ~0.95 to 0.88 for a valid 2-group banner because the prompt heuristic said "typical banners have 4-10 groups." 2 groups is perfectly valid.

**Fix (two changes):**
1. **Prompt** (`src/prompts/banner/alternative.ts`): Changed "Typical range: 4-10 groups" → "2-10 groups". Removed confidence penalty for low group count — 2-3 groups are valid for simpler studies.
2. **Code** (`src/agents/BannerAgent.ts`): Rewrote `calculateConfidence()` — 2+ groups now get a +0.15 bonus (was neutral). 1 group gets a -0.15 penalty (was no penalty). Effect: 2-group, 19-column banner → 0.95 (was 0.88).

---

#### Issue 2: Crosstab Agent — Prompt Overfitting and Confidence Penalty — COMPLETE

**Problem:** The crosstab prompt was overfitted to specific datasets (listed locations in guidance) and the 3+ candidate confidence penalty (max 0.65) was too aggressive, triggering `humanReviewRequired` on every location column.

**Fix (`src/prompts/crosstab/production.ts`):**
1. **Decontaminated** all dataset-specific references (12 edits: S2→Q3, Physician→Teacher, location-specific examples → generic market research terms).
2. **Softened confidence penalties**: 3+ candidates → max 0.75 (was 0.65). 2 candidates with clearly different relevance → max 0.85. Added "Having alternatives is EXPECTED, not a sign of failure" framing.
3. **Generalized hidden variable hints**: Removed dataset-specific variable names, described `h`/`d` prefix patterns generically.

---

#### Issue 3: Location Variable Selection — COMPLETE

**Resolution:** Documented in `docs/system-behavior-reference.md` under "Loop Reporting Philosophy — Decision 2: Inclusive banner groups." HawkTab defaults to the inclusive approach (binary flags, groups can overlap). This produces different base sizes than a first-loop-only assignment approach — neither is wrong, they answer different questions. Will be configurable in the future. See system behavior reference for the full rationale and comparison table.

---

#### Issue 4: Table Formatting Consistency — COMPLETE

**Severity:** Medium | **Agent:** VerificationAgent + ExcelFormatter

**The core structural issue is resolved.** The deterministic post-pass (`src/lib/tables/TablePostProcessor.ts`) now runs after all verification agent instances finish, enforcing 7 formatting rules consistently across every table. The verification prompt also received a two-pass internal protocol (Pass A: classify + plan, Pass B: self-audit before emitting JSON) to improve per-instance consistency.

**What the post-pass handles:** empty field normalization, section label cleanup (Issue 14), base text validation (Issue 10), trivial NET removal (Issue 6), source ID casing, duplicate row detection, orphan indent reset. Pipeline integration saves `postpass/postpass-report.json` with all actions.

**All sub-issues resolved:**

##### 4b. Terminate rows: 0% vs dash — COMPLETE
Terminate options showed `0%` instead of `-` (dash). Fixed in Excel formatters (both Joe and Antares styles): pre-scan detects rows with count=0 across ALL banner cuts, then renders `-` instead of `0%`/`0`. No new data flow needed — the R output already contains the signal. Files: `joeStyleFrequency.ts`, `frequencyTable.ts`.

##### 4c. "(TERMINATE)" label clutter — COMPLETE
Verification agent was appending survey routing instructions like "(TERMINATE)", "(CONTINUE TO S4)" to row labels. Fixed with: (1) prompt rule in A2 CHECK LABELS telling the agent to strip all routing instructions from labels, and (2) deterministic post-pass Rule 8 (`stripRoutingInstructions`) as backup — regex strips parenthesized routing patterns from any label the agent misses.


---

#### Issue 5: Missing S4 (State from Zip Code) — COMPLETE

**Problem:** State/region tables were missing because geographic hidden variables (`hSTATE`, `hRegion4`, `hRegion9`) were classified as `admin` due to the `h` prefix and excluded from table generation. The raw zip code (`S4`) is correctly excluded as `text_open`, but the SPSS file already contains pre-computed state and region variables with full value labels — no zip-to-state conversion needed.

**Fix (two changes):**
1. **`src/lib/processors/DataMapProcessor.ts`**: Added `isGeographicDemographic()` method that detects hidden variables with geographic keywords (state, region, division, census, metro, dma) AND real value labels. These get rescued from `admin` classification and flow through to normal type detection as `categorical_select`.
2. **`src/prompts/verification/alternative.ts`**: Added note in A1 LOCATE IN SURVEY that some tables come from derived/hidden variables not in the survey — keep them, use data labels, don't exclude.

---

#### Issue 6: Unnecessary NET on Single-Select / 100%-Sum Questions — COMPLETE

**Problem:** The verification agent added a "Family Origin (NET)" row to a single-select question where all options sum to 100% — a meaningless NET. This was a recurring issue that prompt-only fixes hadn't resolved.

**Fix (two layers):**
1. **Prompt** (`src/prompts/verification/alternative.ts`): Promoted guideline 9 from "AVOID TRIVIAL NETs" to "NEVER ADD ALL-OPTION NETs TO SINGLE-SELECT QUESTIONS" — a RULE with a mechanical test: "If your NET's filterValue would cover ALL non-NET filterValues for that variable, do NOT create it." Added explicit WRONG example.
2. **Deterministic backup** (`src/lib/tables/TablePostProcessor.ts`): `checkTrivialNets` rule auto-removes same-variable NETs that cover all non-NET options, with orphaned indent cleanup. This catches any cases the prompt misses.

---

#### Issue 7: Mean Outlier Trimming — Discrepancy vs Joe on S8 — COMPLETE

**Severity:** Low | **Component:** RScriptGeneratorV2 (deterministic) | **Priority:** Investigate + document

**What happened:** On S8, our mean matches Joe's (6.1 vs 6.10 — same value, just formatting). But the "mean minus outliers" diverges: Joe shows 5.4, we show 5.0.

**This is not necessarily wrong.** The discrepancy is likely because we use a different outlier trimming method or threshold than Joe.

**Our current approach:**
- **Method:** IQR (Interquartile Range) — Tukey fences
- **Threshold:** 1.5x IQR (hardcoded in `RScriptGeneratorV2.ts`, lines 897-914)
- **Rule:** Values below Q1 - 1.5×IQR or above Q3 + 1.5×IQR are excluded
- **Minimum sample:** Requires 4+ valid values
- **Not configurable** — no environment variable, no per-dataset override

**What Joe likely does:** Unknown. Could be a different IQR multiplier (e.g., 2.0x or 3.0x, which would trim fewer values and produce a higher trimmed mean), a percentile-based trim (e.g., exclude top/bottom 5%), or a fixed standard-deviation cutoff. The higher trimmed mean (5.4 vs 5.0) suggests Joe trims fewer outliers than we do.

**What to do:**
1. **Investigate Joe's method** — check if Joe's tabs or documentation specify his outlier approach. This is a question for the Hawk team or Joe directly.
2. **Document our method** — regardless of what Joe does, our approach should be clearly documented in `docs/system-behavior-reference.md` so users understand what "mean minus outliers" means in HawkTab output. Currently this section is missing from the reference doc.
3. **Consider making it configurable** — not MVP-blocking, but a future enhancement. The 1.5x IQR multiplier could be exposed as a config option (e.g., `OUTLIER_IQR_MULTIPLIER=1.5` in `.env.local`).

**Key principle:** Whatever method we choose, it should be documented and defensible. Users should be able to point to our system behavior reference and say "HawkTab uses 1.5x IQR Tukey fences for outlier trimming" — and that's a perfectly standard, well-known statistical method.

**Resolution:** Added "Outlier Trimming (Mean Minus Outliers)" section to `docs/system-behavior-reference.md` documenting the 1.5× IQR Tukey fence method, minimum sample requirement (4 values), and the known discrepancy explanation. The untrimmed mean is always reported alongside for comparison. If Joe's method is later identified, we can make the multiplier configurable — but our default is standard and defensible.

---

#### Issue 8: S9 NET Base Computation — COMPLETE

**Problem:** NET rows in `RScriptGeneratorV2.ts` used `sum(!is.na(first_component))` as the base, which filters the denominator to respondents with non-NA data in the first component variable. For S9 in Tito's, this produced a base of 4287 instead of 5098. An audit of all 25 test datasets found 24/25 affected (107 of 233 mean_rows tables had wrong bases).

**Fix (two changes in `src/lib/r/RScriptGeneratorV2.ts`):**
1. **NET base = `nrow(cut_data)`** (table base) instead of first-component non-NA count. Applied to both frequency NETs and mean NETs.
2. **Mean NET = mean of per-respondent row-sums** instead of sum-of-component-means. The old approach mixed different denominators when components had differential missingness.

**Also removed `dependsOn` and `noRuleQuestions`** from the skip logic schema — these were advisory fields that added output tokens without being used by any downstream code.

**Validation:** `scripts/audit-net-base-risk.ts` and `scripts/validate-net-base-fix.ts` confirm the fix across all test datasets. Tito's S9: base 4287 → 5098, mean 13.2 → 6.1.

---

#### Issue 10: Verification Agent Creating Non-Base "Base" Text — COMPLETE

**Problem:** The verification agent put question descriptions (e.g., "About the drink at the selected occasion/location") in the baseText field instead of audience descriptions. Base text should answer "who was asked?" not "what was asked?"

**Fix (two layers):**
1. **Prompt** (`src/prompts/verification/alternative.ts`): Replaced base text guidance with three explicit rules: RULE 1 (plain English only), RULE 2 (must describe WHO not WHAT, with WRONG/RIGHT examples), RULE 3 (when in doubt, leave empty). Added concrete test: "If you can't express it as '[Group of people] who [met some condition]', use empty string."
2. **Deterministic warning** (`src/lib/tables/TablePostProcessor.ts`): `validateBaseText` heuristic flags patterns like "About...", "Awareness of...", "Satisfaction with..." — warns but does not auto-fix since it requires semantic judgment.

---

#### Issue 11: We Report S11a/S11b/S11c — Joe Doesn't — COMPLETE

**Resolution:** Documented in `docs/system-behavior-reference.md` under "Loop Reporting Philosophy — Decision 1: Report all loops." HawkTab reports tables for all loop iterations by default. Joe reports loop 1 only. Neither is wrong — our approach prioritizes completeness. Will be configurable in the future.

---

#### Issue 12: S11b/S11c Base Incorrectly Filtered to 68 — COMPLETE

**Problem:** S11b/c showed a base of 68 instead of ~2,322. The SkipLogicAgent created a `rule_s11_if_multiple_locations` filter (`(S9r1 > 0) + ... >= 2`) for S11a/b/c, but this is a loop-inherent condition — respondents in the Location 2 loop already had 2+ locations by definition. The filter was redundant and produced wrong results in stacked data. S11a was accidentally protected by the `noRuleQuestions` mechanism, but S11b was not.

**Fix (two changes):**
1. **SkipLogicAgent step count: 15 → 25** (`src/agents/SkipLogicAgent.ts`). The agent was cramming analysis into 2 giant scratchpad entries, leading to rushed reasoning and contradictory output. More turns allow systematic one-entry-per-question analysis.
2. **Prompt updates** (`src/prompts/skiplogic/production.ts`): Added explicit guidance that loop-gating conditions (e.g., "show Q if respondent has 2+ loop items") are loop-inherent and should NOT become rules. Added Example 9b showing the exact pattern. Updated scratchpad protocol to encourage methodical per-question entries and contradiction-checking before final output.

---

#### Issue 13: Table Sort Order Broken (C3 Appearing Between A-Series Tables) — COMPLETE

**Problem:** The `parseQuestionId()` regex in `sortTables.ts` — `/^([A-Za-z]+)(\d+)([A-Za-z]?)$/` — failed on any questionId with underscores (`A7_1`, `A13a_1`) or multi-character suffixes (`A3DK`). Failed matches fell into `category: 'other'` and sorted to the bottom, causing C3 to appear between A-series tables and loop variants to scatter unpredictably.

**Fix (one file: `src/lib/tables/sortTables.ts`):**
1. **Expanded regex** to `([A-Za-z]*)(?:_(\d+))?$` — `[A-Za-z]*` allows multi-char suffixes (DK), `(?:_(\d+))?` captures loop iteration numbers.
2. **Added `loopIteration` to `ParsedQuestion`** — sort step 5: base question (no loop) first, then `_1`, `_2`, etc.
3. **Added `isDerived` sorting** — step 6: non-derived tables before T2B/binned/brand-split variants.
4. **Added `extractQuestionIdFromTableId()`** helper for derived table proximity sorting.
5. **Updated `sortTables()` and `getSortingMetadata()`** to pass `isDerived` and `sourceTableId` from table definitions.

Now `A7_1` → (A, 7, "", loop=1), `A13a_1` → (A, 13, "a", loop=1) instead of "other". Unstructured names (`US_State`, `Region`) still correctly fall to "other".

---

#### Issue 14: Inconsistent Section Label Cleanup — COMPLETE

**Problem:** Section labels like "SECTION A: OCCASION LOOP" appeared inconsistently across tables because each parallel verification agent instance handled cleanup differently.

**Fix** (`src/lib/tables/TablePostProcessor.ts`): `cleanSurveySection` rule strips "SECTION X:" prefixes (with or without number/letter), forces ALL CAPS, and trims whitespace — applied deterministically to every table after all agent instances finish.

---

#### WIN: Skip Logic Agent Correctly Handled Strikethrough Text on A13

The skip logic for A13 in the survey shows: "ASK IF A4 = 4, 5, 7-13" — but options 4 and 5 are visually struck through in the survey document, indicating they were removed from the condition after the initial draft.

**The skip logic agent correctly recognized the strikethrough** and only applied the filter for A4 values 7–13, excluding 4 and 5. The resulting base text reads: "Respondents whose A4 (type of drink) is one of: 7, 8, 9, 10, 11, 12, or 13."

**Why this is a significant win:** Survey documents frequently contain revision artifacts — strikethroughs, tracked changes, editor notes. A naive system would parse "4, 5, 7-13" literally and include the struck-through values. The agent demonstrated genuine document comprehension by distinguishing active text from deleted text, which directly impacts data correctness. This is the kind of subtle, high-stakes detail that matters for producing accurate tabs.

---

#### Issue 16: Loop Variables Not Collapsed — A13a, A14a, A14b — COMPLETE

**Problem:** Skeleton groups like `A-N-a-_-N` (A13a, A14a — 4 members, diversity 2) and `A-N-b-_-N` (A14b — 2 members) failed the LoopDetector's strict thresholds (diversity >= 3, members >= 3) even though they share the same iteration values (`['1','2']`) and separator (`_`) as the certified anchor skeleton `A-N-_-N` (24+ members, diversity 12). Each skeleton group was evaluated in isolation with no way to see it belonged to the same loop.

**Fix (one file: `src/lib/validation/LoopDetector.ts`):**
1. **Extracted `analyzeSkeletonGroup()` helper** — separates analysis (finding best iterator position, diversity, iterations, separator type) from threshold decisions, so both passes can reuse it.
2. **Two-pass "Anchor & Satellite" detection:**
   - **Pass 1 (unchanged thresholds):** diversity >= 3 → certified "anchor." Registers an adoption key (sorted iterations + separator type) in an `anchorMap`.
   - **Pass 2 (satellite sweep):** Rejected groups with >= 2 members and >= 2 iterations are adopted if their adoption key matches a certified anchor (same iteration values + same separator).
3. **Lowered minimum members from 3 to 2 for analysis** (not acceptance). Pass 1 strict thresholds still gate anchor acceptance. Pass 2 can consider 2-member groups for satellite adoption.

No changes needed downstream — `LoopCollapser.mergeLoopGroups()` already merges groups with identical iteration values, so satellites automatically merge with their anchors.

---

#### Issue 17: Section C Tables Missing — C1, C2, C4 Dropped from Output — COMPLETE

**Problem:** C1, C2, C4 (standalone categorical demographics) were silently dropped while C3 (multi-row binary_flag matrix) was included. Root cause: `hasStructuralSuffix()` in `RDataReader.ts` used regex `/c\d+$/i` to detect grid column suffixes (like `A5c1`), but it matched standalone question codes `C1`, `C2`, `C4`. This misclassified them as `level: "sub"` with `parentQuestion: "NA"`, and the DataMapGrouper silently skipped orphaned subs.

**Fix (three changes):**
1. **`src/lib/validation/RDataReader.ts`**: Changed `/c\d+$/i` to `/[a-z0-9]c\d+$/i` — requires a preceding character, so `A5c1` still matches but standalone `C1` does not.
2. **`src/lib/processors/DataMapProcessor.ts`**: Safety net — `inferParentFromSubVariable` now uses `/(?<=[a-z0-9])c\d+$/i` so it won't strip a standalone question code to empty.
3. **`src/lib/pipeline/PipelineRunner.ts`**: Added TableGenerator output saving to `tablegenerator/` directory for pipeline debugging visibility.


