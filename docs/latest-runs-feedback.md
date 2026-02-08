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
| 1 | Banner agent confidence penalty for low group count | Low | Prompt tweak | Agent behavior |
| 2 | Crosstab agent prompt overfitting + confidence penalty | Medium | Prompt refactor | Agent behavior |
| 3 | Location variable selection philosophy (binary flag vs assignment) | High | Architectural decision | Loop / stacking |
| 4 | Table formatting inconsistency across verification loops | Medium | Prompt + deterministic post-pass | Formatting |
| 5 | Missing S4 state-from-zip table | Low | New feature | Missing tables |
| 6 | Unnecessary NET on single-select questions (S6a) | Medium | Prompt fix (recurring) | Agent behavior |
| 7 | Mean outlier trimming discrepancy vs Joe (S8) | Low | Investigate + document | Documentation |
| 8 | ~~S9 NET base incorrectly filtered to 1993~~ | ~~High~~ | ~~Bug fix~~ | COMPLETE |
| 9 | Missing location distribution table (hidden variable gap) | Medium | Architecture | Missing tables |
| 10 | Verification agent creating non-base "base" text | Low | Prompt fix | Formatting |
| 11 | We report S11a/b/c, Joe doesn't (loop philosophy) | Conceptual | Design decision | Loop / stacking |
| 12 | ~~S11b/c base filtered to 68 (skip logic overzealous)~~ | ~~High~~ | ~~Investigation + fix~~ | COMPLETE |
| 13 | ~~Table sort order broken (C3 between A-series)~~ | ~~Medium~~ | ~~Deterministic fix~~ | COMPLETE |
| 14 | Inconsistent section label cleanup | Low | Deterministic post-pass | Formatting |
| 15 | Dual-base reporting for skip logic questions (A10) | Conceptual | Future enhancement | Product quality |
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
- Issue 6: NET suppression on single-select (recurring)
- Issue 4/14: Deterministic post-pass for formatting
- Issue 10: Base text vs question description
- Issues 1, 2: Banner and crosstab agent prompt tweaks

**Then document our assumptions:**
- Issue 3/11: Loop reporting philosophy — document the default, make it configurable
- Issue 7: Outlier trimming method → add to system-behavior-reference.md
- Surface loop/stacking assumptions in every output so users know what they're getting

---

### Tito's Future Growth — Detailed Issues

**Pipeline run:** `outputs/titos-growth-strategy/pipeline-2026-02-08T07-04-55-204Z/`

---

#### Issue 1: Banner Agent — Unnecessary Confidence Penalty for Low Group Count

**Severity:** Low | **Agent:** BannerAgent | **Priority:** Prompt tweak

**What happened:** The banner agent correctly extracted both groups (Needs State, Location) and all 19 columns. However, it self-penalized from ~0.95 to 0.88 because the prompt includes a heuristic that "typical banners have 4-10 groups," and this banner only has 2.

**Agent output:**
> "Confidence: 0.88 because group headers are visually distinct and filter expressions are clearly paired with names, but there are only 2 groups (typical banners have 4-10 groups) which reduces overall confidence slightly."

**The problem:** 2 groups is a perfectly valid banner plan. The agent shouldn't second-guess itself when it correctly identified everything. The group-count heuristic is causing unnecessary doubt.

**Action item:** Adjust the banner agent prompt to remove or soften the group-count skepticism. A banner with 2 groups that are cleanly extracted should score 0.95+, not 0.88.

---

#### Issue 2: Crosstab Agent — Prompt Overfitting and Confidence Penalty

**Severity:** Medium | **Agent:** CrosstabAgent | **Priority:** Prompt refactor

**What happened:** The crosstab agent correctly identified `hLOCATIONrX == 1` as the primary expression and provided all viable alternatives. But two problems surfaced:

1. **The prompt is too specific.** It literally lists each location in the guidance, which means the agent isn't truly generalizing — it's pattern-matching against hints we gave it. This won't scale to unseen datasets.

2. **The 3+ candidate confidence penalty (max 0.65) is too aggressive.** When there are multiple plausible variables, the agent should still be confident in its primary pick while clearly listing alternatives. A confidence of 0.65 triggers `humanReviewRequired: true` for every location column, which creates noise.

**Agent output (scratchpad):**
> "Applied consistent confidence penalty for multiple plausible candidates (3+ candidates → max 0.65)."

**Action items:**
- Strip the crosstab prompt of dataset-specific hints. Make it generalizable — the agent should reason from the datamap, not from pre-loaded answers.
- Soften the multi-candidate confidence penalty. Having alternatives is expected behavior, not a sign of failure. The agent should: pick the best one confidently, list alternatives clearly, and let the user confirm or override.
- Consider telling the agent: "When multiple candidates exist, present your best pick with confidence and list alternatives. The user will select, override, or provide a hint."

---

#### Issue 3: Location Variable Selection — Which Variable Is "Correct"?

**Severity:** High | **Agent:** CrosstabAgent | **Priority:** Philosophical / architectural decision

This is the core issue from the Tito's run. It's not a bug — the agent did a reasonable job — but it surfaces a fundamental question about how HawkTab should handle ambiguous variable mappings in looped/stacked data.

##### The setup

The banner plan says "Assigned S9_1" (meaning: respondents assigned to location 1 = "At your home"). But the data contains **5 families of location variables**, all plausible:

| Variable family | Example | Type | What it represents |
|---|---|---|---|
| `hLOCATIONrX` | `hLOCATIONr1 == 1` | Binary flag (0/1) | Did respondent select this location? (any loop) |
| `dLOCATIONrX` | `dLOCATIONr1 == 1` | Binary flag (0/1) | Appears identical to hLOCATIONrX (unknown why duplicated) |
| `hLOCATIONSrX` | `hLOCATIONSr1 == 1` | Binary flag (0/1) | Coded group flag (HOME/BAR/RESTAURANT/etc.) |
| `hLOCATION1` | `hLOCATION1 == 1` | Numeric (1-16, 99) | Which location was assigned in **loop 1** |
| `hLOCATION2` | `hLOCATION2 == 1` | Numeric (1-16, 99) | Which location was assigned in **loop 2** |

**The agent chose:** `hLOCATIONrX == 1` (binary flag — "anyone who selected this location in any loop")
**Joe used:** `hLOCATION1 == X` (assignment variable — "respondents assigned this location in loop 1 only")

##### The base-size discrepancy

| Location | HawkTab (hLOCATIONrX) | Joe (hLOCATION1) | Match? |
|---|---|---|---|
| Own Home | 3,018 | 3,018 | Yes |
| Others' Home | 681 | 426 | No — HawkTab higher |

"Own Home" matches because it's the most common assignment and most respondents had it in loop 1. "Others' Home" diverges because our binary-flag approach captures respondents who selected it in **either** loop, while Joe's approach only captures loop 1 assignments.

##### The philosophical question

Both approaches are defensible:

**Our approach (binary flag `hLOCATIONrX`):**
- More inclusive — captures all respondents who experienced that location across any loop
- More intuitive — "everyone who selected home" is a cleaner concept
- But groups can overlap (a respondent could be in both "Home" and "Bar" if assigned to different locations across loops)

**Joe's approach (assignment variable `hLOCATION1`):**
- Produces non-overlapping groups (each respondent assigned to exactly one location per loop)
- Standard for how loop-assignment banners are typically cut in market research
- But misses loop 2 assignments entirely — potentially under-counting

**Neither is wrong.** But we need a consistent philosophy.

##### Open questions

1. **Can the banner agent provide richer context to the crosstab agent?** Similar to how the skip logic agent provides hints, the banner agent could pass along: question structure (multi-select vs. single-select vs. assignment), whether the variable references a loop, and the original survey question text. This would help the crosstab agent disambiguate.

2. **Can the datamap help?** If we can detect that `hLOCATIONrX` is a binary flag while `hLOCATION1` is a numeric assignment variable, we could encode a preference: "for 'Assigned' cuts, prefer the assignment variable over binary flags."

3. **Does loop semantics resolve this?** If our stacked-data pipeline already handles loop assignment correctly, the choice of variable may produce the same result in the final output regardless. Need to verify.

4. **What should HawkTab's default be?** When the banner says "Assigned S9_X" and multiple variable families exist, should we default to:
   - The assignment variable (matches Joe, produces non-overlapping groups)?
   - The binary flag (more inclusive, simpler concept)?
   - Present both options to the user with a clear explanation?

##### Connected issue: Stat testing and overlap weighting

This variable-selection question is directly connected to how we handle stat testing for overlapping groups. If we go with the binary-flag approach (our current default), groups can overlap — and we need stat testing that accounts for that.

**What we already have:**
- Full stat testing infrastructure in `RScriptGeneratorV2.ts`: z-tests for proportions, Welch's t-tests for means, dual thresholds (95%/90%), within-group comparisons, and vs-Total comparisons
- Overlap detection in loop semantics validation: pairwise overlaps are detected and logged to `loop-semantics-validation.json`
- Stat letter assignment in `CutsSpec.ts`, output schema fields (`sig_higher_than`, `sig_vs_total`) in `verificationAgentSchema.ts`

**What we don't have:**
- **Overlap-aware stat testing**: When groups overlap (A-vs-B is invalid), we need A-vs-not-A (segment vs complement) comparisons. The roadmap mentions this but it's not implemented. Would require changes to `generateSignificanceTesting()` in `RScriptGeneratorV2.ts`.
- **Survey weighting**: The Tito's data has weight variables but we don't apply them. R's `svydesign` could handle this natively. Listed as high priority in roadmap after loop semantics.
- **Surfacing stat testing in output**: Need to verify stat testing is actually making it into the Excel output for these runs, not just computed silently.

**HawkTab's philosophy (proposed default):**

The most statistically rigorous output should be the default. Concretely:

1. **Include all the data.** Use the inclusive approach (binary flags) so analysts see the full picture. Don't pre-filter or under-count.
2. **Always provide stat testing.** Even when groups overlap, compute and display significance — vs-Total at minimum, and overlap-aware within-group where possible.
3. **Let analysts decide what to report.** An analyst can choose to ignore sig letters on overlapping groups, but they should have the option. Withholding data is worse than providing it with context.
4. **Make it configurable later.** The default is "maximum rigor." Users who want non-overlapping groups (Joe's approach) can switch to assignment-variable mode. But the default gives you everything.

This means: even if two location groups share respondents, the stat test says "this difference vs Total is significant" — that's real, useful information. The overlap doesn't invalidate the comparison against Total; it only complicates pairwise within-group comparisons (which is where A-vs-not-A matters).

**Implementation priority:** Not MVP-blocking. Stat testing infrastructure exists and works for non-overlapping groups. The overlap-aware extension (A-vs-not-A) and survey weighting are post-MVP enhancements. For now, memorializing this so we address it when we circle back to the reliability plan Part 3/4.

##### Reference: Crosstab agent output for "Own Home"

```json
{
  "name": "Own Home",
  "adjusted": "hLOCATIONr1 == 1",
  "confidence": 0.65,
  "reason": "Found hLOCATIONr1 ('HOME - HIDDEN: LOCATIONS') → Selected because its name and description directly correspond to an assignment of S9_1.",
  "alternatives": [
    { "expression": "dLOCATIONr1 == 1", "confidence": 0.6 },
    { "expression": "hLOCATIONSr1 == 1", "confidence": 0.6 },
    { "expression": "hLOCATION1 == 1", "confidence": 0.6 },
    { "expression": "hLOCATION2 == 1", "confidence": 0.6 }
  ],
  "humanReviewRequired": true
}
```

##### Reference: Variable families in the data

```
hLOCATIONSr1-r7    → Coded group flags (HOME, OTHER, RESTAURANT, BAR, HOTEL/MOTEL, etc.)
dLOCATIONr1-r16,r99 → Binary flags per individual location (appears same as hLOCATIONrX)
hLOCATIONr1-r16,r99 → Binary flags per individual location
hLOCATION1, hLOCATION2 → Numeric loop-assignment variables (which location in loop 1/2)
```

---

#### Issue 4: Table Formatting Consistency Across Verification Agent Loops

**Severity:** Medium | **Agent:** VerificationAgent + ExcelFormatter | **Priority:** Prompt + deterministic improvements

The verification agent runs in parallel loops, and each instance can produce slightly different formatting conventions. This creates inconsistency across tables in the same output. Comparing our S1 screener table to Joe's highlights several specific formatting gaps, but the broader issue is: how do we enforce consistent standards when multiple agent instances are formatting independently?

##### 4a. Context column / notes section

**Joe's approach:** Clean, standardized notes section:
> SCREENING SECTION
> S1. Do you, or is any family member, currently working in one of the following industries?
> (NOTES: Multiple answers accepted / Responses sorted in descending rank order)

**Our approach:** Cluttered context column with raw metadata:
> SCREENER
> S1. Do you, or is any family member, currently working in one of the following industries?
> (Select all that apply) (Options 1–3 were programmed to terminate the respondent)
> [s1]

**Issues:**
- `[s1]` should be capitalized (`S1`) and ideally italicized — this is the source ID, not raw code
- "Options 1–3 were programmed to terminate the respondent" is internal metadata, not analyst-facing notes
- Joe's notes ("Multiple answers accepted / Responses sorted in descending rank order") are useful analyst context — ours don't provide equivalent information
- Section label differs: "SCREENER" vs "SCREENING SECTION" (minor, but worth standardizing)

**Question:** Is this the verification agent's job (prompt-driven) or should it be deterministic in the Excel formatter? Probably a mix — the verification agent should produce clean, standardized metadata, and the formatter should enforce presentation rules (capitalization, italics).

##### 4b. Terminate rows: 0% vs dash

**Joe shows:** `-` (dash) for Advertising, Journalism, Marketing or Market Research — these are terminate options, so no qualified respondent could have selected them. Showing a dash means "not applicable."

**We show:** `0%` for the same rows — technically not wrong (0 respondents chose it), but misleading. It implies respondents could have chosen it and none did, when actually those options disqualified the respondent.

**The right behavior:** If the R script or table generator can distinguish between "0 respondents chose this" and "this option terminates/disqualifies," then terminate rows should show `-` or `N/A` instead of `0%`. This would also allow us to remove the "(TERMINATE)" label from each row label, which clutters the table.

**Implementation question:** Can the data tell us this? The survey metadata likely flags terminate options. If the skip logic agent or table generator already knows which options are terminators, we could pass that through and let the Excel formatter render dashes.

##### 4c. "(TERMINATE)" label clutter

If we implement 4b (dashes for terminate rows), we can remove the "(TERMINATE)" suffix from row labels like "Advertising (TERMINATE)." The dash already communicates that the option isn't applicable. This makes the table cleaner and more aligned with Joe's output.

##### 4d. NET rows on screener/terminate tables

**Our output** includes "Any listed industry (NET)" as the first row. **Joe's output** does not include a NET for this screener question.

**Question:** Is a NET meaningful on a screener table where most options are terminators? The NET here (12%) represents "anyone who selected a listed industry" — but that's essentially "anyone who didn't select 'None of the above.'" For screener tables specifically, the NET may add noise rather than insight. Worth considering whether the verification agent should suppress NETs for screener/terminate tables, or whether this is a user-configurable preference.

##### 4e. Row sort order

**Joe's output:** Rows sorted in descending rank order (highest % first): Food and Beverage (5%), Retail (5%), Finance (4%), Travel (1%), then terminators as dashes.

**Our output:** Rows in survey order: Advertising, Journalism, Marketing, Travel, Food and Beverage, Finance, Retail, None of the above.

**Note:** Joe's notes explicitly say "Responses sorted in descending rank order." This may be a client preference or a Joe convention. For now, survey order is a defensible default, but we should make sort order configurable. The verification agent could flag this as a formatting option.

##### Broader issue: Enforcing consistency across parallel verification loops

The specific formatting issues above are symptoms of a bigger structural challenge: the verification agent runs in parallel (3 concurrent via `pLimit`), and each instance reasons independently about formatting. This means:

- One instance might add "(TERMINATE)" labels, another might not
- Note sections can vary in style and content between tables
- NET inclusion logic can differ from table to table

**Potential approaches:**
1. **Pre-pass formatting rules:** Before the verification agent runs, establish a formatting spec (from the first table or from a dedicated formatting-rules step) that all instances must follow. Pass this spec into each parallel call.
2. **Post-pass normalization:** After all verification instances complete, run a deterministic formatting pass that enforces consistency (capitalization, note format, dash vs 0%, NET rules).
3. **Prompt standardization:** Add explicit formatting examples to the verification prompt showing exactly how notes, labels, and special rows should look. Include a "formatting reference" section that every instance sees.

The ideal is probably a combination: prompt gives the agent clear formatting standards, and a deterministic post-pass catches anything the agent missed.

---

#### Issue 5: Missing S4 (State from Zip Code) — Open-Text / Admin Variable Support

**Severity:** Low | **Component:** TableGenerator (deterministic) | **Priority:** Post-MVP

**What happened:** Our output is missing S4, which is a state variable derived from the respondent's zip code. This is likely because S4 is a text/open-ended or administrative variable, and our deterministic table generator pipeline doesn't generate tables for non-numeric variables.

**Why this is reasonable for now:** Open-text variables generally shouldn't produce crosstab tables — there's nothing to cross-tabulate. The pipeline is correct to skip them.

**The exception:** State-from-zip is the one type of open-text/admin variable that routinely appears in crosstabs. It's a standard demographic cut (e.g., "Region" or "State" derived from zip code). Joe includes it.

**Future solution:** Detect when a text variable represents a zip-to-state classification and handle it:
1. Recognize zip code / state variables (likely identifiable from variable name, label, or value patterns — e.g., 2-letter state codes, 5-digit zips)
2. Apply a zip-to-state (or zip-to-region) lookup on the backend
3. Generate the crosstab table as if it were a categorical variable

This is a straightforward lookup implementation — not architecturally complex. But it's clearly post-MVP since it requires a new variable classification pathway.

---

#### Issue 6: Unnecessary NET on Single-Select / 100%-Sum Questions (S6a)

**Severity:** Medium | **Agent:** VerificationAgent | **Priority:** Prompt fix (recurring issue)

**What happened:** Our S6a (family origin) output is correct data-wise — matches Joe's X6a. However, the verification agent added a "Family Origin (NET)" row that sums to 100%. This is a single-select question where responses are mutually exclusive and exhaustive — a NET is meaningless here because it will always be 100%.

**This is a known recurring issue.** We've previously tried to get the verification agent to stop adding unnecessary NETs, but it's still doing it. The agent continues to default to "add a NET" even when the question structure doesn't warrant one.

**When a NET is appropriate:** Multi-select questions, top-2-box / bottom-2-box summaries, grouped categories where the NET represents a meaningful subset.

**When a NET is not appropriate:** Single-select questions where all options sum to 100%, screener/terminate tables (see Issue 4d), any situation where the NET equals the base or 100% by definition.

**Action item:** Revisit the verification agent prompt to strengthen the "don't add unnecessary NETs" instruction. The current guidance isn't working — the agent needs a clearer rule, possibly with examples of when to suppress. Consider a deterministic post-check: if a NET row sums to exactly 100% of the base, flag or auto-remove it.

**Positive note:** The skip logic agent correctly identified S6a as a skip logic question, and the base size is accurate. The filtering pipeline is working well here — this is purely a verification agent formatting issue.

---

#### Issue 7: Mean Outlier Trimming — Discrepancy vs Joe on S8 (Investigation, Not a Bug)

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

**Documentation action:** Add an "Outlier Trimming" section to `docs/system-behavior-reference.md` explaining the method, threshold, and when it applies.

---

#### Issue 8: S9 NET Base Computation — COMPLETE

**Problem:** NET rows in `RScriptGeneratorV2.ts` used `sum(!is.na(first_component))` as the base, which filters the denominator to respondents with non-NA data in the first component variable. For S9 in Tito's, this produced a base of 4287 instead of 5098. An audit of all 25 test datasets found 24/25 affected (107 of 233 mean_rows tables had wrong bases).

**Fix (two changes in `src/lib/r/RScriptGeneratorV2.ts`):**
1. **NET base = `nrow(cut_data)`** (table base) instead of first-component non-NA count. Applied to both frequency NETs and mean NETs.
2. **Mean NET = mean of per-respondent row-sums** instead of sum-of-component-means. The old approach mixed different denominators when components had differential missingness.

**Also removed `dependsOn` and `noRuleQuestions`** from the skip logic schema — these were advisory fields that added output tokens without being used by any downstream code.

**Validation:** `scripts/audit-net-base-risk.ts` and `scripts/validate-net-base-fix.ts` confirm the fix across all test datasets. Tito's S9: base 4287 → 5098, mean 13.2 → 6.1.

---

#### Issue 9: Missing Location Distribution Table (Hidden Variable Gap)

**Severity:** Medium | **Component:** Pipeline architecture (TableGenerator + DataMapProcessor) | **Priority:** Post-MVP, worth capturing

**What happened:** Joe's output includes a frequency distribution table for S9 showing the percentage of respondents assigned to each location (At your home: 59%, At someone else's home: 8%, etc.). Our output doesn't have this table at all.

**Why we're missing it:** S9's location assignment is handled via hidden variables (hLOCATIONr1–r16, hLOCATION1/hLOCATION2, etc.). We currently exclude hidden variables from table generation to keep things simple and avoid cluttering output with internal coding variables. That's generally the right call — but in this case it backfires because the hidden variable IS the analytically meaningful table. Joe's table shows the distribution of location assignments, which is useful context for everything downstream.

**The challenge:** Even if we un-hid these variables, the system would need to know which hidden variables relate to which visible question. A standalone `hLOCATIONr1` table isn't useful without the context that it's the assignment variable for S9. So this isn't just "show hidden variables" — it's "relate hidden variables back to their parent question and present them as a coherent distribution table."

**Possible approaches (future):**
1. **Parent-variable linking in the datamap.** If DataMapProcessor can detect that `hLOCATIONr1–r16` are child variables of S9 (via naming patterns or metadata), we could auto-generate a distribution table.
2. **Verification agent awareness.** The verification agent could be told "these hidden variables exist and relate to S9" and decide whether a distribution table is warranted.
3. **Accept the gap for now.** This is a niche case (hidden assignment variables that produce meaningful tables). Document it as a known limitation.

**Current decision:** Not blocking. Capture for future work. The system correctly hides internal coding variables; this is an edge case where that heuristic misses something useful.

---

#### Issue 10: Verification Agent Creating Non-Base "Base" Text

**Severity:** Low | **Agent:** VerificationAgent | **Priority:** Prompt fix

**What happened:** The verification agent generated a base description for a table that reads like a question description rather than a base definition:

> Base: About the drink at the selected occasion/location (asked for each occasion/location)

This isn't a base — it's describing what the question is about. A proper base would be something like "All respondents" or "Those who reported 1+ alcoholic drinks." The text above is context/notes, not a filtering criterion.

**The problem:** The verification agent is conflating "what is this question about" with "who qualifies for this table." The base should always answer: "Which respondents are included in this table's denominator?" If the answer is "everyone," the base should say "All respondents" or "Total respondents."

**Action item:** Tighten the verification agent prompt to distinguish between:
- **Base text** = who is in the denominator (e.g., "All respondents," "Those aware of Brand X")
- **Notes/context** = what the question is about, how it was asked, programmer notes

The agent should never put descriptive context into the base field. If there's no skip logic filter, the base is "All respondents" (or "Total respondents" to match Joe's convention).

---

#### Issue 11: We Report S11a/S11b/S11c — Joe Doesn't (Loop Reporting Philosophy)

**Severity:** Conceptual | **Component:** Pipeline architecture | **Priority:** Post-MVP, configurable option

**What happened:** Our output includes tables for S11a, S11b, and S11c (the loop 2 versions of S10a/S10b/S10c). Joe's output doesn't — he only reports on loop 1 questions.

**This is a philosophical difference, not a bug.** Our pipeline reports on all loops by default because we detect loops and stack data. Joe only reports on loop 1, which is a deliberate simplification.

**Our approach is more defensible as a default.** If someone gives you a survey with two loops and you silently drop loop 2 data, that's a bigger surprise than including everything. The user's expectation when they don't specify anything is "give me all the data."

**Future enhancement:** Since we already do loop detection, we could give users the option:
- **Default:** Report on all loops (our current behavior)
- **Option:** "Report only on loop 1" — for users who want to match Joe's convention or want non-overlapping groups

This is purely conceptual — parking it here for the broader loop philosophy conversation. Prioritize tactical fixes first.

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

#### Issue 14: Inconsistent Section Label Cleanup ("OCCASION LOOP" / "SECTION A" Remnants)

**Severity:** Low | **Component:** Deterministic post-processing | **Priority:** Ties into Issue 4 (formatting consistency)

**What happened:** Some tables show "OCCASION LOOP" or "SECTION A: OCCASION LOOP" in the section header, while others have it cleaned up. The intent is to remove these section labels, but the cleanup is inconsistent.

**This connects to the broader Issue 4 theme:** formatting consistency across tables. The verification agent sometimes strips section labels and sometimes doesn't, because each parallel instance reasons independently.

**Action item:** This is a strong candidate for the **deterministic post-pass** discussed in Issue 4. After all verification agent instances complete, run a cleanup step that:
- Strips or normalizes section labels consistently (remove "SECTION A:", "OCCASION LOOP", etc.)
- Applies the same formatting rules to every table regardless of which agent instance produced it
- Handles capitalization, source ID formatting, and other presentational cleanup

This reinforces the pattern: use the agent for reasoning (NETs, base text, row structure), but use deterministic code for presentation rules that should never vary.

---

#### Issue 15: Dual-Base Reporting for Skip Logic Questions (A10 / "Joe's Nuance")

**Severity:** Conceptual | **Component:** Pipeline philosophy | **Priority:** Post-MVP enhancement

**What happened:** A10 ("How many people were with you?") has skip logic: "ASK IF A9 DOES NOT EQUAL 1" (i.e., only asked if the respondent was not alone). Our system correctly applies the filter — the base is "those who were not alone."

**What Joe does differently:** Joe, as a human analyst, recognizes that it's useful to report A10 **twice**:
1. With the skip logic filter applied (base = those not alone) — the "correct" analytical cut
2. With all respondents as the base — so you can see what percentage of *everyone* gave each answer, even though some were skipped

Both tables are valid and useful. The filtered version tells you "among people who were with others, here's the group size distribution." The unfiltered version tells you "out of everyone, what share had 2 people, 3 people, etc." — which implicitly also shows you the share who were alone (they'd be the missing base).

**Why this matters:** This is the kind of analyst judgment that separates "tabs that answer the question asked" from "tabs that tell a story." Joe's ability to do this is one of the reasons his output feels higher-quality — he's not just mechanically applying skip logic, he's thinking about what the reader needs.

**This is not a bug or a blocking issue.** Our system does the right thing by applying the skip logic. But it surfaces a future capability worth capturing:

**Possible future feature: "Also report unfiltered" flag.**
- When the verification agent (or a future review step) encounters a skip logic question, it could flag: "This table might also be useful with an all-respondents base."
- The system could then generate both versions, with clear base text distinguishing them.
- This would be opt-in or configurable — not every skip logic question benefits from dual reporting.

**For now:** Note as an aspiration. The current behavior (apply skip logic, report filtered base) is correct and defensible.

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


