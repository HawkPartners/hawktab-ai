# Looping / Stacking Gap Analysis (Current System)

**Status:** working notes (intended to clarify scope before implementation)  
**Goal:** explain what’s correct today, what breaks, why it breaks, and how to diagnose it quickly.

---

## TL;DR (5th-grader version)

When a survey has a loop, we make a new dataset where **each person becomes multiple rows** (one per loop iteration).

That’s fine, but it creates 3 different kinds of problems:

1. **Double-counting people** (respondent-level stuff gets counted once per loop-row)  
2. **Wrong “which loop” assignment** (a “loop-related” variable wasn’t recognized as looped, so it gets copied to every loop-row)  
3. **“Pick the right row” problems** (you need to match “assigned item” to a grid row — this is not solved by loop stacking)

These are different problems and need different fixes.

---

## A note on loop validation: fill-rate heuristics can be too blunt

Separately from stacking semantics, our validation layer uses **fill rates** (e.g., compare `_1` vs `_2`) to guess whether data is already stacked.

That’s a useful signal, but it can be **too blunt**:
- Some “true wide” loop designs have legitimately low fill on later iterations because only a minority of respondents have iteration 2+ (real dropout / “up to N” designs).
- That can look similar to “already stacked” if we use only a single threshold.

**Practical takeaway:** fill-rate should be treated as a *warning signal*, not a single definitive test. It’s best paired with at least one other cross-check (e.g., expected-dropout patterns across many loop bases, presence of explicit stacked markers, or user confirmation).

---

## What stacking is (in our system)

We start with `data` (one row per respondent).

For each detected loop group, we create a stacked frame like `stacked_loop_1`:
- row 1..N = “iteration 1 view” of each respondent (loop vars renamed to base names)
- row N+1..2N = “iteration 2 view” of each respondent
- etc.

We add `.loop_iter` so each stacked row knows which iteration it represents.

**Key detail:** only variables recognized as loop variables get swapped/renamed (e.g., `A2_1/A2_2 → A2`).  
Everything else (non-loop columns) gets duplicated across every stacked row.

---

## Are we confident the **Total** column is correct?

### For loop tables (occasion/entity-level tables)
**Mostly yes**, if we agree the loop tables are supposed to be **entity-level** (one stacked row = one entity/occasion/assignment).

Example (Tito’s):
- Table `a2` Total base shows `n = 7420`, which is consistent with “number of non-missing loop answers across all stacked rows”.

### Important caveat: Joe may be doing a different analysis choice
Joe sometimes appears to show “first loop only” (or “one record per respondent”) for certain loop questions.

That is not necessarily a bug in stacking — it can be a **product decision**:
- **Occasion-level**: count every occasion (stacked rows) → totals like 7420 make sense
- **Respondent-level**: count each respondent once → totals closer to respondent N make sense

So “Total is correct” is only meaningful relative to the chosen unit-of-analysis.

---

## Gap 1 — Respondent-level variables on stacked frames (base inflation)

### What it is
Respondent-level variables (age, gender, screener items, etc.) exist once per person.
But on the stacked dataset, they appear on every stacked row for that person.

If we apply respondent-level cuts to stacked frames and then compute base as `nrow()`, we can count the same person multiple times.

### What it looks like
- Bases that look ~2× (or ~N×) what you expect when a banner cut is respondent-level
- “Male/Female” columns on loop tables that look inflated vs a respondent-level run

### Why it happens (simple)
We copied the person row twice, so we’re counting the copies.

### What fixes usually look like
Pick one:
- Evaluate respondent-level cuts on the respondent frame (`data`) and then join/filter stacked rows appropriately
- Or compute base using distinct respondent IDs (if available)
- Or intentionally define “respondent-level banners on loop tables” to mean “apply to every stacked row” (but then accept the interpretation)

---

## Gap 2 — Iteration-linked “wide” variables that are NOT loop variables (mis-assigned to loop rows)

This is the core “S10a/S11a” class.

### What it is
Some surveys store iteration-specific “gate” variables as separate columns (wide format), but they don’t follow the loop-variable naming scheme we detect (e.g., no `_1/_2` suffix).

When we stack, those columns get duplicated across every stacked row, even though they semantically belong to only one iteration.

### Two common subtypes

#### Subtype 2a: iteration is explicit in the column name (easy deterministic)
Example (UCB):
- `Treatment_1` and `Treatment_2` are clearly “medication 1 vs medication 2”
- They’re not in loop variables, but they can be mapped deterministically:
  - `Treatment_1 → .loop_iter == 1`
  - `Treatment_2 → .loop_iter == 2`

This can be fixed without an LLM.

#### Subtype 2b: iteration is NOT obvious in the column name (hard)
Example (Tito’s):
- `S10a` and `S11a` have identical question text but represent different occasions
- Neither name includes `_1/_2`
- A correct stacked cut must be gated by `.loop_iter`, e.g.:
  - `(.loop_iter == 1 & S10a == 1) | (.loop_iter == 2 & S11a == 1)`

This often requires extra evidence:
- survey structure (“first occasion” vs “second occasion” sections)
- platform tokens in labels (`LOCATION1` / `LOCATION2`) when present
- or an LLM fallback when deterministic evidence is insufficient

### What it looks like
- Banner cuts on loop tables that don’t partition correctly
- Bases that are too large or overlapping in ways that don’t make sense (“an occasion row matches multiple mutually exclusive states”)

### Why it happens (simple)
We stacked the loop answers correctly, but we didn’t teach the system that some non-loop columns are “iteration-specific”.

### What fixes usually look like
Pick one:
- **Gate cut expressions** on stacked frames using `.loop_iter` (transform expressions at R generation time)
- Or create **per-row alias columns** on stacked frames (e.g., `needs_state_raw = if iter 1 then S10a else S11a`) and write simpler cuts

Both require building an “iteration-linked variable mapping”.

---

## Gap 3 — Roster/value-to-row linking (not solved by `.loop_iter`)

### What it is
Sometimes a respondent is assigned an item (e.g., `Treatment_1` = “Fintepla”), and there’s also a grid/roster with rows for many items (e.g., `B3r1..B3r33` = knowledge ratings per medication).

If you want “knowledge rating for the assigned treatment”, you must map:
- value in `Treatment_1/2` → the correct `B3rK` row

That’s not “which loop iteration” — it’s “which roster row corresponds to a selected value”.

### What it looks like
- Analysts want a banner like “Assigned medication = Fintepla” *and* a dependent metric that is stored in a roster row-per-medication
- A naïve stacked fix (just gating by `.loop_iter`) still can’t pick the right `B3rK`

### Why it happens (simple)
The data is encoded in two different shapes:
- assignment variable = a single coded value
- grid variable = many columns, one per row item

You need “value-label matching / lookup”, not `.loop_iter` gating.

### Why this matters for scope
This is a real requirement in market research outputs, but it’s a **separate feature area** from loop stacking + banner cuts.
We should not bundle it into the “LoopContext” solution unless we explicitly decide to.

---

## Smaller but real issues (implementation bugs / polish)

These are not the big conceptual gaps above, but they can cause incorrectness or confusion:
- **Duplicate Total cut in stacked frames** (and one uses wrong length in the R code)
- **Stat-letter computation referencing wrong object for stacked frames**
- **Value-label conflicts across iterations when stacking** (one label “wins” silently unless we warn)

These should be fixed regardless of the bigger architectural decision.

---

## Quick diagnosis checklist (what am I looking at?)

### If bases look ~N× too big on loop tables…
Most likely: **Gap 1 (respondent-level on stacked frame)**.

### If a banner cut seems to “bleed” across iterations (like it applies to both rows for a person)…
Most likely: **Gap 2 (iteration-linked wide var not treated as iteration-linked)**.

### If the thing you want depends on “assigned item” AND a grid row-per-item…
Most likely: **Gap 3 (roster/value-to-row linking)**.

---

## What decisions we need (product/analytics)

Before implementing fixes, we should explicitly decide:
- For loop questions, are we producing **occasion/entity-level** outputs, **respondent-level** outputs, or both?
- For banners on loop tables, which banner groups should be:
  - respondent-level (apply to all stacked rows), vs
  - entity-level (must be iteration-aware / alias-based)

Once these are decided, the engineering work becomes much more deterministic and testable.

---

## Optional output mode: “canonical iteration” (Joe-compatible)

Some analysts intentionally produce respondent-based outputs even when a loop exists by selecting a single “canonical” iteration per respondent (often iteration 1).

This is coherent and common, but it is a **different product mode** than entity-level stacking:
- canonical iteration mode answers “what do respondents look like?” (one record per person)
- entity-level stacking answers “what do loop entities look like?” (one record per iteration)

We should treat this as an explicit mode choice (not an accidental side effect), because it changes bases, interpretation, and statistical testing assumptions.

