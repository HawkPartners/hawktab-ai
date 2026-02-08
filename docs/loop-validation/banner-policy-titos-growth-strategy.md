# Banner Policy (Filled Example) — Tito’s Future Growth Strategy

**Goal:** fill out the banner policy decision table for this dataset so stacked-loop tables are statistically defensible and reproducible.

**Inputs used:**
- `outputs/titos-growth-strategy/pipeline-2026-02-07T13-38-58-276Z/banner/banner-output-raw.json`
- `outputs/titos-growth-strategy/pipeline-2026-02-07T13-38-58-276Z/crosstab/crosstab-output-raw.json`
- `outputs/titos-growth-strategy/pipeline-2026-02-07T13-38-58-276Z/loop-summary.json`

---

## Step 0 — Unit of analysis decision

- **Loop tables** (A1–A19 family, run on `stacked_loop_1`): **entity/occasion-level**
  - Base meaning: **occasions** (stacked rows with non-missing loop variables), not respondents.
- **Non-loop tables** (S* etc., run on `data`): **respondent-level**

---

## Step 1 — Loop/stack metadata (Tito’s)

- **Loop detected?** yes (`totalLoopGroups = 1`)
- **Stacked frame name**: `stacked_loop_1`
- **Iteration marker**: `.loop_iter`
- **Iteration set**: `{1, 2}`
- **Respondent id column**: unknown/not yet standardized in R script (needed only for distinct-respondent bases; not required for entity-level bases)
- **Weight column**: not used in this run

---

## Step 2 — Banner group decision table (Tito’s)

This dataset’s banner plan includes **two** banner groups:
- **Needs State** (8 columns)
- **Location** (11 columns)

### Decision table

| Banner group | Anchor type | Intended meaning on loop tables (plain English) | Where evaluated | Requires iteration mapping? | Requires roster linking? | Base type on loop tables | Should cuts partition? | Notes / examples |
|---|---|---|---|---|---|---|---|---|
| Total | N/A | “All occasions in this loop table” | `stacked_loop_1` | no | no | entity_count | N/A | Total base for A2 is 7420 occasions in the current output. |
| Needs State | **Entity-anchored** | “Classify each occasion into exactly one needs state” | `stacked_loop_1` | **yes** (`S10a` ↔ iter 1, `S11a` ↔ iter 2) | no | entity_count | **yes** | Current crosstab cut is respondent-style: `(S10a==1 | S11a==1)` etc. Correct for respondent-level “any occasion”, incorrect for occasion-level. |
| Location | **Entity-anchored** | “The specific location of the selected occasion” | `stacked_loop_1` | **yes** (location assignment is per iteration) | no | entity_count | **yes** | Current crosstab uses `S9r*` (multi-select “where did you drink any drinks”), which is respondent-level and will bleed across iterations. Prefer assignment vars (e.g., `hLOCATION1/hLOCATION2`) if present. |

---

## Step 3 — Required implementation behavior (derived)

### Needs State (entity-anchored)

**Current cut expressions (from CrosstabAgent output):**
- `Connection/Belonging`: `(S10a == 1 | S11a == 1)`
- … similarly for 2..8

**Entity-level interpretation requires iteration awareness**, so we must do one of:

1) **Alias column approach (recommended for clarity)**
- Create `needs_state_code` on `stacked_loop_1`:
  - if `.loop_iter == 1` → `needs_state_code = S10a`
  - if `.loop_iter == 2` → `needs_state_code = S11a`
- Then cuts are simple: `needs_state_code == 1`, `== 2`, … `== 8`

2) **Gated-expression approach**
- Transform each atomic comparison, e.g.:
  - `(S10a == 1)` becomes `(.loop_iter == 1 & S10a == 1)`
  - `(S11a == 1)` becomes `(.loop_iter == 2 & S11a == 1)`
- So `Connection/Belonging` becomes:
  - `(.loop_iter == 1 & S10a == 1) | (.loop_iter == 2 & S11a == 1)`

### Location (entity-anchored)

**Current crosstab expressions use `S9r* == 1`**, which represent “respondent selected this location at least once” (multi-select).

For occasion-level location, we need the “selected location for this iteration”.

**Preferred approach: alias column against assignment variables**
- If the dataset includes per-iteration location assignment variables (commonly `hLOCATION1` and `hLOCATION2`):
  - Create `assigned_location_code` on `stacked_loop_1`:
    - if `.loop_iter == 1` → `assigned_location_code = hLOCATION1`
    - if `.loop_iter == 2` → `assigned_location_code = hLOCATION2`
  - Then define location cuts as equality checks against `assigned_location_code`.

If assignment variables are not available, we must fall back to a resolver/agent approach and/or treat Location as respondent-anchored (explicitly changing the meaning), but that is a product decision.

---

## Step 4 — Minimum validation checks (Tito’s)

### Needs State (should partition occasions)
After implementing entity-anchored needs state:
- **Partition/base sum check**: sum of the 8 needs state bases ≈ Total base for loop tables (e.g., A2 Total `n = 7420`)
- **Overlap check**: an occasion row should match **at most 1** needs state (overlap ~0)

### Location (should partition occasions, if truly “assigned location”)
- **Partition/base sum check**: sum of location bases ≈ Total base for loop tables (e.g., A2 Total `n = 7420`)
- **Overlap check**: an occasion row should match **at most 1** location bucket

---

## Notes on “Joe-compatible” respondent-style interpretation (not the default here)

The current expressions like `(S10a == 1 | S11a == 1)` are coherent as **respondent-level** cuts:
- “Respondents who had at least one occasion in Connection/Belonging”

That is useful for respondent-profile tables, or for a future “canonical iteration / respondent-mode” output, but it should not be used as-is to classify stacked occasion rows.

