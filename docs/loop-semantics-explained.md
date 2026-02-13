# Loop Semantics: What It Is and Why We Built It

## The Problem in One Sentence

When survey data has loops (the same questions asked multiple times per respondent), stacking that data into one-row-per-entity creates a subtle bug where banner cuts can leak values across entities, silently inflating every number in the affected columns.

---

## Setup: What Looped Survey Data Looks Like

Take a survey about drinking occasions. Each respondent describes two occasions. In the SPSS file, this creates two kinds of variables:

**Obvious loop variables** (same question, suffixed by iteration):
- `A2_1` = "What did you drink on occasion 1?"
- `A2_2` = "What did you drink on occasion 2?"

**Non-obvious iteration-linked variables** (same question, different variable names):
- `S10a` = "What was the needs state for occasion 1?"
- `S11a` = "What was the needs state for occasion 2?"

Both pairs ask the same question per occasion. But the first pair follows a `_1`/`_2` naming pattern that's easy to detect. The second pair uses completely different variable names — nothing in the column name tells you they're iteration-linked.

---

## What Stacking Does

The pipeline detects the loop, collapses `A2_1`/`A2_2` into a single `A2` column, and stacks the data so each row represents one occasion instead of one respondent.

**Before stacking** (1 row per respondent):

| Respondent | A2_1 | A2_2 | S10a | S11a | Gender |
|---|---|---|---|---|---|
| R001 | Tito's | Margarita | 1 (Connection) | 5 (Indulgence) | Male |

**After stacking** (1 row per occasion):

| Respondent | .loop_iter | A2 | S10a | S11a | Gender |
|---|---|---|---|---|---|
| R001 | 1 | Tito's | 1 (Connection) | 5 (Indulgence) | Male |
| R001 | 2 | Margarita | 1 (Connection) | 5 (Indulgence) | Male |

`A2` was collapsed correctly — occasion 1's row gets "Tito's", occasion 2's row gets "Margarita."

But `S10a` and `S11a` were **not** recognized as loop variables. They got duplicated onto both rows. Both occasion rows carry both values. This is where the problem starts.

---

## Where It Breaks

The banner plan defines a "Connection/Belonging" cut: `(S10a == 1 | S11a == 1)`.

**On non-loop tables** (demographics, screener tables), this works fine. It means "respondents who had a Connection occasion." Each respondent is counted once.

**On stacked tables**, this expression is evaluated on every occasion row:

- **Occasion 1 row:** S10a = 1 (Connection). `S10a == 1` is TRUE. Match. **Correct** — this occasion was Connection.
- **Occasion 2 row:** S10a = 1 (Connection). `S10a == 1` is TRUE. Match. **Wrong** — this occasion was Indulgence (S11a = 5), but S10a leaked through from occasion 1.

Occasion 2 gets counted as Connection/Belonging even though it was Indulgence. The OR expression checks both occasions' values on every row, so any respondent who had Connection for *either* occasion gets *both* occasions counted.

**The scale of the error:**

| Metric | Before Fix | After Fix |
|---|---|---|
| Connection/Belonging base | 1,409 | 852 |
| Sum of all 8 needs state bases | 11,046 | 7,420 |
| Overlap between needs states | 48.9% | 0% |

Every percentage in every Needs State column on every stacked table was wrong. Not off by a rounding error — fundamentally wrong, with bases inflated by up to 65%.

---

## The Two Anchor Types

This is the core concept. Every banner group falls into one of two categories on stacked data:

### Respondent-Anchored

The cut describes **the person**, not the specific entity/occasion.

Examples: Gender, age, region, screener responses, location assignment flags.

These variables have a single value per respondent. On the stacked frame, every row for that respondent has the same value. The cut `Gender == 1` means "occasions from male respondents" — semantically correct, no transformation needed.

### Entity-Anchored

The cut describes **the specific entity/occasion**, but the variables are stored as separate columns (one per iteration) rather than as collapsed loop variables.

Examples: S10a (occasion 1's needs state) and S11a (occasion 2's needs state).

The raw cut `(S10a == 1 | S11a == 1)` is **wrong** on stacked data because it checks both occasions on every row. It needs to be transformed so each row only checks its own occasion's value.

### The Same Expression Means Different Things

This is the subtle part. The cut `(S10a == 1 | S11a == 1)` is **correct on non-loop tables** (it means "respondents who had Connection for either occasion") and **wrong on stacked tables** (it should mean "occasions that were specifically Connection").

The loop semantics system ensures each context gets the right treatment:
- Non-loop tables: use the raw expression as-is (respondent-level, OR is intentional)
- Stacked tables: transform via alias column (entity-level, select the right variable per iteration)

---

## How the Fix Works: Alias Columns

For entity-anchored groups, the R script creates an alias column on the stacked frame:

```r
stacked_loop_1 <- stacked_loop_1 %>% dplyr::mutate(
  `.hawktab_needs_state` = dplyr::case_when(
    .loop_iter == 1 ~ S10a,   # occasion 1 rows use S10a
    .loop_iter == 2 ~ S11a,   # occasion 2 rows use S11a
    TRUE ~ NA_real_
  )
)
```

Then stacked cuts are deterministically transformed:

| Original cut | Transformed cut |
|---|---|
| `(S10a == 1 \| S11a == 1)` | `.hawktab_needs_state == 1` |
| `(S10a == 2 \| S11a == 2)` | `.hawktab_needs_state == 2` |

Now each occasion row only evaluates **its own** needs state. Clean partition, zero overlaps, validated in R.

---

## The Three Detection Layers

### Layer 1: LoopCollapser (Fully Deterministic)

Finds variables with `_1`/`_2` suffix patterns (e.g., `A2_1`, `A2_2`). These get collapsed into a single column during stacking. Problem solved at the source — they never need alias columns.

**Catches:** ~70% of iteration-specific variables.

### Layer 2: DeterministicResolver (Fully Deterministic)

Scans metadata for iteration-linked variables that *don't* follow the suffix pattern. Uses four evidence tiers:

| Tier | Method | Example |
|---|---|---|
| A0 | Variable-name suffixes | `Treatment_1`, `Treatment_2` |
| A1 | Label/description tokens | Labels containing `${LOCATION1}` markers |
| A2 | Sibling detection | N variables with identical descriptions matching N iterations |
| A3 | Cascading | h-prefix/d-prefix variants of confirmed mappings |

For the drinking occasions example, it found S10a mapped to occasion 1 and S11a mapped to occasion 2 via label tokens in pagetime variable labels.

**Catches:** Another ~20% of cases. Provides the **mapping** (which variable belongs to which iteration).

### Layer 3: LoopSemanticsPolicyAgent (AI Reasoning)

Even with the mapping in hand, something still needs to make the **semantic decision**: is this banner group entity-anchored or respondent-anchored?

This is where it gets interesting. Consider:

- **S10a/S11a** (needs states): Two variables, OR'd together, each linked to a different occasion. On stacked tables, you need an alias column. **Entity-anchored.**
- **hLOCATIONr1, hLOCATIONr2, ... hLOCATIONr16**: Sixteen variables, one per location type, each a binary flag. The cut `hLOCATIONr1 == 1` means "respondent was assigned to Own Home." These are respondent-level assignment flags — same value on every stacked row. **Respondent-anchored.**

Both groups involve multiple variables. Both could superficially look like iteration patterns. The difference is semantic: S10a/S11a are the *same question for different iterations*, while hLOCATIONr* are *different questions about the same respondent*.

The agent reasons about this using:
- Deterministic resolver evidence (when available)
- Datamap descriptions (do they reference ordinal positions or distinct concepts?)
- Structural patterns (does the number of OR'd variables match the iteration count?)
- Variable independence (are these different concepts or the same concept repeated?)

---

## Why Not Fully Deterministic?

For most datasets, the deterministic layers (LoopCollapser + DeterministicResolver) handle everything. The agent adds value in edge cases:

1. **No naming convention:** Variables named `breakfast_mood` and `dinner_mood` for a meal-occasion loop. No suffix pattern, no label tokens. The only way to know they're parallel is reading the descriptions.

2. **Ambiguous patterns:** Two OR'd variables with two iterations — but the descriptions show they're distinct concepts (different channels) rather than the same question per iteration. The structural pattern suggests entity, but the semantics say respondent.

3. **Overriding false positives:** The deterministic resolver found a suffix match, but the datamap descriptions clearly show the variables are unrelated to loop iterations.

4. **Partial coverage:** The resolver mapped 2 of 3 iterations. Is this still entity-anchored, or should it fall back to respondent?

For the common case, you could skip the agent entirely. But for the 5-10% of edge cases where metadata alone is ambiguous, the semantic reasoning prevents silent misclassification — which, as the numbers above show, can inflate bases by 65% without any visible error.

---

## Key Files

| File | Purpose |
|---|---|
| `src/lib/validation/LoopCollapser.ts` | Detects loop variables with _1/_2 suffixes, builds stacking plan |
| `src/lib/validation/LoopContextResolver.ts` | Deterministic resolver for non-obvious iteration-linked variables |
| `src/agents/LoopSemanticsPolicyAgent.ts` | AI classification of banner groups as entity vs. respondent anchored |
| `src/prompts/loopSemantics/alternative.ts` | Agent prompt with examples and pitfall guidance |
| `src/lib/r/RScriptGeneratorV2.ts` | Generates alias columns and transforms stacked cuts |
| `src/lib/r/transformStackedCuts.ts` | Expression transformation helpers |
| `src/schemas/loopSemanticsPolicySchema.ts` | Policy output schema |
