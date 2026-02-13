# Loop Detection: What It Does and When Stacking Applies

## The Problem in One Sentence

Survey data files often contain repeated question blocks (loops) encoded as wide-format columns with naming patterns like `Q5_1, Q5_2, Q5_3`. The pipeline needs to detect these, stack them into one-row-per-entity format for analysis, and — critically — avoid stacking patterns that *look* like loops but aren't.

---

## What the Loop Detector Does

The loop detector (`src/lib/validation/LoopDetector.ts`) identifies groups of columns that follow a repeated naming pattern. It works in three steps:

### Step 1: Tokenization

Each column name is split into typed tokens:

| Column | Tokens |
|--------|--------|
| `Q5_1` | `[alpha:Q, numeric:5, sep:_, numeric:1]` |
| `D1_2r3` | `[alpha:D, numeric:1, sep:_, numeric:2, alpha:r, numeric:3]` |

### Step 2: Skeleton Extraction

Tokens are generalized into a skeleton pattern by replacing specific values with type markers:

| Column | Skeleton |
|--------|----------|
| `Q5_1`, `Q5_2`, `Q5_3` | `A-N-_-N` |
| `D1_2r3`, `D1_15r1` | `A-N-_-N-A-N` |

Columns sharing the same skeleton are grouped together.

### Step 3: Iterator Detection & Diversity Analysis

For each skeleton group, the detector identifies which numeric position varies (the "iterator") and calculates:

- **Iterations**: Unique values at the iterator position (e.g., `['1', '2', '3']` for 3 iterations)
- **Bases**: Unique question stems after removing the iterator (e.g., `Q5` is the base of `Q5_1`)
- **Diversity**: Number of unique bases — how many distinct questions exist per iteration

A group with 30 iterations and 3 bases means 3 questions were each asked 30 times.

---

## When Stacking Is Needed vs Not

### True Loops (Stack These)

A true loop repeats the same questions for a variable number of entities per respondent. Example: "Describe up to 3 drinking occasions" creates `A2_1, A2_2, A2_3` (what you drank on occasion 1, 2, 3).

**Key characteristics:**
- Respondents may not complete all iterations (dropout)
- Each iteration represents a different entity (occasion, product, brand)
- Analysis needs one-row-per-entity to compute per-entity statistics
- Not stacking would lose the entity-level detail

### Fixed Grids (Do NOT Stack These)

A fixed grid repeats the same questions across a fixed stimulus list where every respondent answers every item. Example: "Rate each of these 30 messages on 3 dimensions" creates `D1_1r1...D1_30r3`.

**Key characteristics:**
- Every respondent answers every iteration (near-100% fill rates)
- Each iteration represents a distinct stimulus (message, concept, product)
- Each stimulus should produce its own table in the output
- Stacking would inflate bases (N=200 becomes N=6,000) and collapse 30 distinct per-stimulus tables into 1 aggregate table

### The Consequence of Getting It Wrong

| Scenario | What happens |
|----------|-------------|
| True loop not stacked | Can't compute per-entity statistics. Tables show respondent-level aggregates that mask entity-level patterns. |
| Fixed grid stacked | Base inflation (N multiplied by iteration count), information loss (distinct stimuli merged), invalid stat testing. |

---

## The Three Fill Rate Patterns (Plus `fixed_grid`)

After detecting loop groups structurally, the **FillRateValidator** (`src/lib/validation/FillRateValidator.ts`) examines the actual data to classify each group's fill rate pattern. It reads per-column fill rates from the .sav file via R and classifies them into one of four patterns:

### `fixed_grid`

All iterations have high, uniform fill rates — every respondent answered every iteration. This is the signature of a fixed stimulus grid, not a true loop.

**Rules (either triggers classification):**
1. All iteration fill rates >= 95% AND >= 8 iterations
2. Diversity/iteration ratio < 0.5 AND all iteration fill rates >= 95%

Rule 1 catches the common case: many iterations with uniformly high fill. A true loop with 8+ iterations would show dropout.

Rule 2 catches grids with fewer iterations but a characteristic shape: few questions spread across many iterations (e.g., 3 questions x 10 iterations = ratio 0.3).

**Action:** The pipeline does NOT stack these groups. Their variables remain in the datamap as regular wide-format columns, and each stimulus gets its own table.

### `valid_wide`

All iterations have similar fill rates (within 30% of each other), but don't meet the `fixed_grid` thresholds. The data is valid wide format — the loop structure is real and can be stacked.

### `expected_dropout`

Fill rates decrease monotonically across iterations. This is the classic true-loop pattern: most respondents complete iteration 1, fewer complete iteration 2, even fewer complete iteration 3. Stacking is appropriate.

### `likely_stacked`

Iteration 1 has data, all other iterations are nearly empty. This suggests the data has already been stacked (long format) before upload. The pipeline blocks or warns depending on the strength of the signal.

### `uncertain`

Pattern doesn't match any of the above. Could be noise, unusual data, or too few iterations to classify. The pipeline proceeds with stacking but logs the uncertainty.

---

## How `fixed_grid` Rules Were Validated

The two rules were validated against 15 datasets:

| Dataset | Loop Groups | Classification | Correct? |
|---------|-------------|---------------|----------|
| Tito's (real loop: drinking occasions) | 2 groups | `expected_dropout` | Yes — true loop, stacking needed |
| Caplyta (fixed grid: 30-message rating) | 1 group | `fixed_grid` (Rule 1) | Yes — false positive eliminated |
| 13 other datasets | Various | No regressions | Yes |

**Why these thresholds:**
- 95% fill rate: True loops almost always show dropout. 95%+ across all iterations is a strong signal of a fixed grid.
- 8 iterations: With fewer iterations, high fill rates could be a short true loop where dropout hasn't kicked in. 8+ iterations with uniform high fill is very unlikely for a real loop.
- 0.5 diversity/iteration ratio: A grid typically has few questions per stimulus (e.g., 3 rating dimensions) but many stimuli (iterations). A ratio < 0.5 means there are at least 2x more iterations than unique questions — grid territory.

---

## Key Files

| File | Purpose |
|------|---------|
| `src/lib/validation/LoopDetector.ts` | Tokenization, skeleton extraction, loop group detection |
| `src/lib/validation/FillRateValidator.ts` | Fill rate classification (`fixed_grid`, `valid_wide`, `expected_dropout`, `likely_stacked`) |
| `src/lib/validation/ValidationRunner.ts` | Orchestrates detection + fill rate analysis, produces warnings |
| `src/lib/validation/types.ts` | Type definitions (`LoopGroup`, `LoopDataPattern`, `LoopFillRateResult`) |
| `src/lib/validation/LoopCollapser.ts` | Collapses detected loop variables into base columns for stacking |
| `src/lib/pipeline/PipelineRunner.ts` | Filters out `fixed_grid` groups before stacking, passes clean loop set to collapser |
| `src/lib/validation/RDataReader.ts` | Reads per-column fill rates from .sav via R + haven |

---

## Known Edge Cases & Future Work

### Small Fixed Grids (3-7 Iterations)

The current rules require either >= 8 iterations or a diversity/iteration ratio < 0.5. A small fixed grid with 5 iterations and 5 questions (ratio = 1.0) won't trigger either rule and may be stacked incorrectly.

**Mitigation:** These are rare in practice. Most fixed grids have many more stimuli than questions. If this becomes an issue, potential solutions include:
- Agent-based disambiguation: Use an LLM to read the variable labels and determine whether the iterations represent entities (stack) or stimuli (don't stack)
- User hint in the wizard: "Does this survey include a fixed rating grid?" with a toggle to override

### Grids with Intentional Missing Data

If a grid allows respondents to skip some stimuli (e.g., "rate only the messages you saw"), fill rates will drop below 95%, and the group won't be classified as `fixed_grid`. It may fall through to `valid_wide` or `expected_dropout` and get stacked.

**Mitigation:** This is hard to distinguish from true loops without reading the survey instrument. Could be addressed by combining fill rate analysis with variable label inspection.

### Multiple Loop Types in One Dataset

A dataset could have both true loops AND fixed grids. The current implementation handles this correctly — each loop group is classified independently, and only `fixed_grid` groups are excluded from stacking.
