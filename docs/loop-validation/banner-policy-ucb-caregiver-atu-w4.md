# Banner Policy (Filled Example) — UCB Caregiver ATU (Wave 4)

**Goal:** fill out the banner policy decision table for UCB W4 so loop/stacked tables remain statistically defensible.

**Inputs used:**
- Loop detection output: `outputs/_validation-test/run-2026-02-06T03-35-32/ucb-w4/loop-variables.json`
- Verbose datamap: `outputs/_validation-test/run-2026-02-06T03-35-32/ucb-w4/UCB Caregiver ATU W4 Data 8.16-verbose-2026-02-06T03-36-06-079Z.json`
- Banner screenshot (provided): `assets/image-976d678e-696b-43d2-8585-9cda8ca3dc89.png`

---

## Step 0 — Unit of analysis decision

### Loop tables (Section C medication loop)
- The loop variables detected are the **C-section** variables with an iterator position corresponding to medication 1 vs medication 2 (e.g., `C1_1r*` and `C1_2r*`).
- **Default** for these loop tables should be **entity-level**:
  - one stacked row = one assigned medication context (medication #1 or #2)
  - base meaning on loop tables = **medication-rows**, not respondents

### Non-loop tables
- Respondent-level (one row per caregiver/respondent).

---

## Step 1 — Loop/stack metadata (UCB W4)

- **Loop detected?** yes
- **Loop iterations** (from `loop-variables.json`): `{1, 2}`
- **Looped table families**: C-section (e.g., `C1_*`, `C2_*`, `C1a_*`, …)
- **Iteration marker (planned)**: `.loop_iter` on stacked frames (same convention as Tito’s)
- **Respondent id column**: not specified here (needed only if we decide to compute distinct-respondent bases on loop tables)

---

## Step 2 — Banner group decision table (based on provided banner screenshot)

The screenshot expresses rules using short-hand like `A2=7` or `A3_7=1`. In the actual data, these map to specific **row/column** variables:

- **Condition**:
  - “Dravet Syndrome” → `S3r3 == 1`
  - “Lennox-Gastaut Syndrome (LGS)” → `S3r4 == 1`
- **Fintepla awareness**:
  - “Aware of Fintepla” → `A2r7 == 1`
  - “Unaware of Fintepla” → `A2r7 == 0`
- **Experience with meds** (A3 grid; column `c1` = current, `c2` = former):
  - Fintepla current → `A3r7c1 == 1`
  - Fintepla former → `A3r7c2 == 1` and `A3r7c1 == 0`
  - Fintepla ever used → `A3r7c1 == 1 OR A3r7c2 == 1`
  - Fintepla never → `A3r7c1 == 0 AND A3r7c2 == 0`
  - Epidiolex current → `A3r5c1 == 1` (row 5)
  - XCOPRI current → `A3r16c1 == 1` (row 16)
- **Knowledge of Fintepla**:
  - “Highly knowledgeable” → `B3r7 > 4`
  - “Aware, little to no knowledge” → `B3r7 < 4 AND A2r7 == 1`
- **Age of patient**:
  - Pediatric → `S10 < 18`
  - Adult → `S10 >= 18`
- **Seizure control**:
  - Under control → `A6 > 4`
  - Not under control → `A6 <= 4`

### Decision table

| Banner group | Anchor type | Intended meaning on **C-loop tables** (plain English) | Where evaluated | Requires iteration mapping? | Requires roster linking? | Base type on loop tables | Should cuts partition? | Notes |
|---|---|---|---|---|---|---|---|---|
| Condition | Respondent-anchored | “Medication-rows from respondents whose patient has Dravet/LGS” | `data` (respondent) then applied to loop tables | no | no | entity_count | **unknown** | S3 is multi-select rows (`S3r*`). Dravet vs LGS may or may not overlap; don’t assume partition. |
| Fintepla awareness | Respondent-anchored | “Medication-rows from respondents aware/unaware of Fintepla” | respondent | no | no | entity_count | **yes** (aware vs unaware) | Uses `A2r7` binary. |
| Experience with Fintepla | Respondent-anchored | “Medication-rows from respondents who are current/former/never users of Fintepla” | respondent | no | no | entity_count | **partially** | “Current/Former/Never” can partition; “Ever used” overlaps by design (union of current+former). |
| Experience with Epidiolex | Respondent-anchored | same pattern as above | respondent | no | no | entity_count | partially | Uses row-specific A3 variables (row 5). |
| Experience with XCOPRI | Respondent-anchored | same pattern as above | respondent | no | no | entity_count | partially | Uses row-specific A3 variables (row 16). |
| Knowledge of Fintepla | Respondent-anchored | “Medication-rows from respondents with high/low knowledge of Fintepla” | respondent | no | no | entity_count | no | Does not partition (there are mid knowledge levels). |
| Age of patient | Respondent-anchored | “Medication-rows from pediatric vs adult patients” | respondent | no | no | entity_count | **yes** | Two-way split based on `S10`. |
| Seizure control | Respondent-anchored | “Medication-rows from under vs not under control” | respondent | no | no | entity_count | **yes** | Two-way split based on `A6`. |

---

## Important: what this banner screenshot is *not* doing (and why it matters)

These cuts are **respondent segments** about *specific named medications* (Fintepla/Epidiolex/XCOPRI). They do **not** mean:
> “the assigned medication (Treatment_1/2) for this loop iteration is Fintepla”

If we want an **entity-anchored** banner like “Assigned medication = Fintepla” on C-loop tables, we need to use the iteration-linked wide variables:
- `Treatment_1` and `Treatment_2` (these exist in the UCB datamap)

That would be **Gap 2a** style mapping (deterministic):
- if `.loop_iter == 1` → assigned treatment = `Treatment_1`
- if `.loop_iter == 2` → assigned treatment = `Treatment_2`

---

## Optional (future): “knowledge of the assigned medication” is roster-linked

If the business question becomes:
> “knowledge of the assigned medication (for this loop iteration)”

…then we must link:
- assigned treatment code (`Treatment_1/2`) → the matching medication row in the B3 roster (`B3rK`)

That is **roster/value-to-row linking** (Gap 3) and is not solved by `.loop_iter` gating alone.

---

## Step 4 — Minimum validation checks (UCB W4)

Because these are respondent-anchored cuts applied to entity-level loop tables:
- **Do not** expect bases to equal “respondent count” unless we implement a canonical-iteration/respondent mode.
- Do expect:
  - no banner base exceeds Total base for a loop table
  - awareness (aware+unaware) partitions Total (within NA handling)
  - age and seizure-control two-way splits partition Total (within NA handling)

