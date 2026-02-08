# Banner Policy Decision Table (Template)

**Purpose:** make banner behavior on loop/stacked tables explicit and testable.  
**Use:** copy this into a dataset-specific doc (or fill inline) before implementing any stacked-frame semantics changes.

---

## Step 0 — Choose the unit of analysis (per table family)

### Default (recommended for loop questions)
- **Loop tables** (tables whose rows come from loop variables like `A2_1/A2_2 → A2`): **entity/occasion-level**
  - Interpretation: “each stacked row is one entity/occasion/assignment”
  - Base meaning: counts of **entities/occasions**, not respondents

### Optional future mode (Joe-compatible)
- **Canonical iteration**: pick one iteration per respondent (often iteration 1) and keep everything respondent-based.

---

## Step 1 — Identify the stacked frame(s)

Fill these in for the dataset:

- **Loop detected?**: yes / no
- **Stacked frame name(s)**: e.g., `stacked_loop_1`
- **Iteration marker column**: e.g., `.loop_iter`
- **Iteration set** (do not assume `1..N`): e.g., `{1,2}` or `{11..18}`
- **Respondent id column** (if available in R frame): `__________`
- **Weight column** (if applicable): `__________`

---

## Step 2 — Banner group decision table

For each banner group (each column group in the output), decide what it *means* on **loop tables**.

### Definitions (pick one per banner group)

- **Respondent-anchored**: describes the respondent (gender, age, region, screener outcomes).
  - On loop tables: “occasions contributed by respondents in this segment”.
- **Entity-anchored**: describes the loop entity/occasion itself (needs state per occasion, location of the drink occasion, assigned medication for this iteration).
  - Must be iteration-aware on stacked frames.
- **Roster-linked** (separate class): requires mapping a selected value to a grid/roster row (e.g., assigned medication → the matching `B3rK` row).
  - Not solved by `.loop_iter` gating alone.

### Table to fill

| Banner group | Anchor type | Intended meaning on loop tables (plain English) | Where evaluated | Requires iteration mapping? | Requires roster linking? | Base type on loop tables | Should cuts partition? | Notes / examples |
|---|---|---|---|---|---|---|---|---|
| Total | N/A | All entities/occasions in this table | stacked frame | no | no | entity count | N/A | |
| Demographics | Respondent-anchored | “occasions from male respondents” etc. | respondent frame or stacked w/ respondent-id logic | no | no | entity count | no | |
| Needs State | Entity-anchored | “occasions classified as Connection/Belonging” | stacked frame | **yes** (wide gates like `S10a/S11a`) | no | entity count | **yes** (usually) | |
| Location | Entity-anchored *(often)* | “occasions that happened at Own Home” | stacked frame | maybe | maybe | entity count | depends | |
| Assigned Product / Treatment | Entity-anchored | “iteration’s assigned item” | stacked frame | yes (wide `Treatment_1/2`) | sometimes | entity count | yes | |

**Where evaluated** options:
- `data` (respondent frame)
- `stacked_loop_*` (entity frame)
- “mixed” (respondent filter applied, then entity table computed)

**Base type on loop tables** options:
- `entity_count` (default for entity/occasion-level loop tables)
- `respondent_count` (only if explicitly doing canonical iteration or distinct-respondent bases)

**Should cuts partition?**
- `yes`: cuts are intended to be mutually exclusive and sum to Total (e.g., “Needs State” often should)
- `no`: overlaps are expected (e.g., multi-select segments)
- `unknown`: decide later; if unknown, do not write “must sum” validations

---

## Step 3 — Required implementation behavior (derived from the table)

For each banner group:

### If **Respondent-anchored**
We must ensure we are not accidentally interpreting counts as respondents when they’re actually entities:
- The cut can be evaluated on respondent data, but when applied to loop tables the base is still **entities from those respondents** unless we intentionally compute distinct respondent bases.

### If **Entity-anchored**
We must ensure cuts are **iteration-aware** on the stacked frame. Two acceptable patterns:
- **Gated expressions:** wrap iteration-linked variables with `(.loop_iter == k & ...)`
- **Alias columns:** create per-row alias variables on stacked frame (e.g., `needs_state_raw`) and cut against the alias

### If **Roster-linked**
Do not try to “patch” with `.loop_iter`. This needs a separate, explicit roster-linking feature (value-label matching / lookup).

---

## Step 4 — Minimum validation checks (fast, deterministic)

For each entity-anchored banner group on a loop table:

- **Partition check** (only if “Should cuts partition? = yes”):
  - Sum of banner bases equals Total base (or equals Total within tolerance if NA handling differs)
  - Overlap between cuts is ~0 (mutual exclusivity)

- **Sanity check**:
  - No banner base exceeds Total base
  - No cut produces a base larger than a logically related super-cut

For respondent-anchored banners on loop tables:
- Ensure documentation / base text is clear that bases are **entities**, not respondents (unless canonical iteration mode).

---

## Optional: dataset-specific filled example (recommended)

After filling the table, add 2–4 concrete examples like:
- “Needs State: Connection/Belonging must partition occasions; current broken behavior: overlaps and inflated bases.”
- “Demographics: ‘Male’ column is interpreted as ‘occasions from male respondents’.”

