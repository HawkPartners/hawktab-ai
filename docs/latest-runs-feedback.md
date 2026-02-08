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
| 8 | S9 NET base incorrectly filtered to 1993 | High | Bug fix | Wrong numbers |
| 9 | Missing location distribution table (hidden variable gap) | Medium | Architecture | Missing tables |
| 10 | Verification agent creating non-base "base" text | Low | Prompt fix | Formatting |
| 11 | We report S11a/b/c, Joe doesn't (loop philosophy) | Conceptual | Design decision | Loop / stacking |
| 12 | S11b/c base filtered to 68 (skip logic overzealous) | High | Investigation + fix | Wrong numbers |
| 13 | Table sort order broken (C3 between A-series) | Medium | Deterministic fix | Formatting |
| 14 | Inconsistent section label cleanup | Low | Deterministic post-pass | Formatting |
| 15 | Dual-base reporting for skip logic questions (A10) | Conceptual | Future enhancement | Product quality |
| 16 | Loop variables not collapsed (A13a, A14a, A14b) | Medium | LoopDetector fix | Loop / stacking |
| 17 | Section C tables missing (C1, C2, C4 dropped) | High | Bug fix | Missing tables |
| WIN | Skip logic agent caught strikethrough text on A13 | — | — | Validation |

### Where to focus next

**Deterministic fixes first** (wrong numbers, missing tables, broken sorting):
- Issue 8: S9 NET base computation bug
- Issue 12: S11b/c base filtering investigation
- Issue 17: C1/C2/C4 tables being silently dropped
- Issue 16: LoopDetector diversity threshold for sparse patterns
- Issue 13: Table sort order

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

#### Issue 8: S9 Base Incorrectly Filtered to 1993 (Should Be 5098)

**Severity:** High | **Component:** TableGenerator (deterministic) | **Priority:** Bug fix

**What happened:** S9 (Location of Drinks) shows a base of 1993 in our output. Joe's shows 5098 (all respondents). S9 has no skip logic — everyone who passed S8 screening (i.e., all 5098 respondents) should qualify.

**Root cause — NOT the skip logic agent:** The skip logic agent correctly identified S9 as having no rule (it's in the `noRuleQuestions` array). The filter translator generated no filter for S9. The scratchpad explicitly notes: "S9: complex randomization and coding of ON/OFF-PREMISE; but S9 itself no show logic."

**The actual problem is in NET base computation.** The verification agent created two NETs:
- "On-premise locations (NET)" — components: S9r5 through S9r14, S9r16
- "Off-premise locations (NET)" — components: S9r1 through S9r4, S9r15

When the TableGenerator computed these NETs, it filtered the base to respondents who had 1+ drinks at any component location. So the on-premise NET base became 1993 (respondents with any on-premise drinks) instead of 5098 (all respondents). This is wrong — **the base should be all qualified respondents regardless of whether they reported drinks at those specific locations.**

A respondent who reported 0 on-premise drinks is still a valid respondent for S9. Their answer is "0 drinks at on-premise locations" — that's data, not missing data.

**Action item:** Fix the TableGenerator's NET base computation to preserve the table's base (all qualified respondents) rather than filtering by component availability. The NET percentage should be calculated against the full base.

##### Side note: Skip logic agent output structure

While investigating this, a broader observation surfaced about the skip logic agent's output:

1. **`noRuleQuestions` — is this needed?** If the agent only outputs rules for questions that have them, we can infer "no rule" from absence. Removing this output field reduces token usage and simplifies the schema.

2. **`dependsOn` — is this needed?** The agent outputs both `dependsOn` (e.g., "depends on S10a") and the actual rule/condition. The `dependsOn` is redundant because the condition description and `appliesTo` already encode the dependency. Removing it reduces output complexity and may reduce confusion — the agent has to reason about one less field per rule.

These aren't bugs, but reducing the skip logic agent's output surface area could improve reliability and reduce token cost, especially on complex surveys with many questions.

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

#### Issue 12: S11b/S11c Base Incorrectly Filtered to 68 (Skip Logic Overzealous)

**Severity:** High | **Agent:** SkipLogicAgent + FilterTranslator | **Priority:** Investigation + fix

**What happened:** S11b and S11c show a base of 68, with the base text: "Respondents who had drinks at two or more distinct locations in S9." This is drastically lower than expected — S11b should have a base closer to the S11a respondent pool (those assigned to location 2).

**The skip logic agent's extraction is technically correct.** The survey says:
> PN SHOW BELOW DISPLAY TEXT, S11A, S11B, S11C IF RESPONDENT HAD A DRINK AT 2+ LOCATIONS IN S9

So the agent correctly extracted: "Only ask S11a, S11b, S11c when respondent had drinks at 2+ locations in S9." That rule IS in the survey.

**But the resulting filter is likely wrong or over-applied.** A base of 68 out of 5098 means only ~1.3% of respondents qualify, which seems far too aggressive. Possible problems:

1. **Translation issue:** How was "2+ locations in S9" translated to an R expression? If it's counting non-zero S9 entries literally from the raw data, it might be applying the wrong threshold or counting the wrong variables.
2. **The rule applies to S11a/S11b/S11c together**, but S11b and S11c may have additional implicit filtering (S11b depends on S11a selection, S11c depends on S11b). The 68 could be a cascading filter effect.
3. **The "2+ locations" condition may interact badly with loop semantics.** In stacked data, each row represents one occasion — so "2+ locations" needs to be evaluated at the respondent level, not the row level.

**Needs deep investigation:** Look at:
- The filter translator output for this rule — what R expression was generated?
- Whether the R expression is evaluated correctly on stacked vs unstacked data
- Whether 68 is plausible (what % of respondents actually had drinks at 2+ locations?)

**Broader pattern — skip logic agent overzealousness:** This connects to the Issue 8 observation. The skip logic agent is extracting rules that are technically present in the survey text but may be:
- Redundant with system-level filtering (loop assignment already handles this)
- Too literally interpreted (programmer notes vs actual skip logic)
- Applied at the wrong data level (respondent-level rule applied to stacked rows)

**Prompt improvement ideas:**
- Tell the agent that hidden variables and loop assignments handle certain conditions automatically — the agent shouldn't re-derive filters that the system already enforces
- Be more conservative: when in doubt, don't filter. An unfiltered table with all respondents is less wrong than an over-filtered table missing valid data
- Consider whether the agent needs to understand the distinction between "programmer notes about survey flow" (handled at fielding time) vs "analytical skip logic" (needs a filter in the crosstab)

**Note on prioritization:** Per the user's guidance — address tactical issues (wrong bases, wrong filters) before the philosophical/conceptual ones (loop reporting, overlap weighting). The conceptual stuff can wait; broken filters produce wrong numbers.

---

#### Issue 13: Table Sort Order Broken (C3 Appearing Between A-Series Tables)

**Severity:** Medium | **Component:** TableGenerator or Excel formatter (deterministic) | **Priority:** Fix

**What happened:** Tables are not sorted correctly in the output. Tables like A7_1, A23, etc. are interspersed with C3, which should appear after all A-section tables. The expected order follows the survey structure: all S-series, then all A-series, then B-series, then C-series, etc.

**The problem:** The sorting logic likely does a naive alphanumeric sort or doesn't account for:
- Section prefixes (S, A, B, C) as primary sort keys
- Numeric suffixes with underscores (A7_1 should come before A8, not after A70)
- Loop variants (A7_1, A7_2 should be adjacent)

**Action item:** Implement a more robust table sort that:
1. Sorts by section prefix first (S < A < B < C < ...)
2. Then by question number (numeric, not string — so A2 < A10)
3. Then by loop suffix (_1, _2) or sub-question letter (a, b, c)

This is a deterministic fix — no agent involvement needed.

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

#### Issue 16: Loop Variables Not Collapsed — A13a, A14a, A14b Appear as Separate _1/_2 Tables

**Severity:** Medium | **Component:** LoopDetector (deterministic) | **Priority:** Investigate fix

**What happened:** A13a appears as two separate tables (A13a_1 and A13a_2) instead of being collapsed into a single stacked table. Same for A14a and A14b. Meanwhile, A5, A6, and other loop variables were correctly collapsed.

**Root cause: LoopDetector diversity threshold.**

The LoopDetector (`src/lib/validation/LoopDetector.ts`, line ~191) groups variables by skeleton pattern and requires `bestDiversity >= 3` (3+ unique base variables in the skeleton) to classify them as loop variables:

| Variable | Skeleton | Unique bases in skeleton | Passes? | Result |
|---|---|---|---|---|
| A5 | `A-N-_-N` | 12 (A1, A2, A3, A4, A5, A6, A8, A10, A11, A13, A15, A18) | Yes | Stacked into single `a5` table |
| A13a | `A-N-a-_-N` | 2 (A13a, A14a) | No | Split into `a13a_1`, `a13a_2` |
| A14b | `A-N-b-_-N` | 1 (A14b only) | No | Split into `a14b_1`, `a14b_2` |

The threshold exists to prevent false positives — you need enough repetition across iterations to confidently say "this is a loop." But it creates false negatives for sparsely populated skeleton patterns. A13a/A14a are clearly loop variables (they have _1 and _2 suffixes, same question asked per occasion), but they don't have enough "siblings" in their naming pattern to pass the diversity check.

**Additional inconsistency: A17_1 exists without A17_2.** This suggests either the source data has an unpaired loop variable, or one iteration was dropped/renamed. This compounds the inconsistency — some questions have both loops, some have only one, and some aren't recognized as loops at all.

**Possible fixes:**
1. **Cross-reference skeleton groups.** If `A-N-_-N` is already confirmed as a loop pattern with iterations {1, 2}, then variables in related skeletons (`A-N-a-_-N`, `A-N-b-_-N`) with the same iteration values could be "adopted" into the loop group. The reasoning: if A5 is loop {1,2} and A13a has _1/_2 suffixes, A13a is almost certainly part of the same loop.
2. **Lower the diversity threshold for related patterns.** If a sibling skeleton already passed, reduce the threshold for skeletons with similar prefixes (A-section, same iteration set).
3. **Manual override / post-detection fixup.** Allow the pipeline to flag "variables that look like loops but didn't pass the threshold" and let a downstream step (or user) confirm them.

**The unpaired A17_1 question** is separate — worth checking whether A17_2 exists in the raw .sav data but was excluded, or whether the survey genuinely only has one iteration for A17.

---

#### Issue 17: Section C Tables Missing — C1, C2, C4 Dropped from Output

**Severity:** High | **Component:** TableGenerator or VerificationAgent | **Priority:** Bug fix

**What happened:** Only C3 appears in the output. C1 (Marital Status), C2 (Education), and C4 (Urban/Rural) are all missing despite being valid categorical variables in the data.

**All four variables exist and are correctly classified:**

| Variable | Type | Description | In Output? |
|---|---|---|---|
| C1 | categorical_select | Marital Status (6 options) | No |
| C2 | categorical_select | Education (6 options) | No |
| C3 | binary_flag matrix | Employment Status (C3r1–C3r11, 11 rows) | Yes |
| C4 | categorical_select | Urban/Rural (3 options) | No |

**The pattern:** C3 is a multi-row matrix (11 binary flag sub-variables), while C1/C2/C4 are single-row categorical questions. Something in the pipeline is filtering out "flat" single-value demographics while keeping multi-row matrices.

**Where to investigate:**
1. **TableGenerator** — does the table generation logic skip variables that don't have child rows (i.e., no `r1`, `r2`, etc. sub-variables)? If it only generates tables for grouped/parent variables with children, single-row categoricals would be silently dropped.
2. **DataMap grouping** — does `groupDataMap()` fail to create a table entry for standalone categorical variables that don't have a parent-child structure?
3. **VerificationAgent** — does the agent receive C1/C2/C4 as input but exclude them during verification?

**Action item:** Trace C1 through the pipeline stage by stage — datamap → table generator → verification — and identify where it gets dropped. Single-row categorical variables are some of the most common demographic tables in market research; they absolutely need to produce tables.


