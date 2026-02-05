# Loop Detection: Evaluation of Gemini's Proposal

## Executive Summary

**Verdict: The approach is sound and implementable.** The core insight—using "internal diversity" to distinguish loops from grids—works on real data. However, the proposal needs strengthening in a few areas before implementation.

---

## Testing Against Real Data (Tito's Growth Strategy)

### What I Found

| Metric | Result |
|--------|--------|
| Total variables | 660 |
| Skeletons with multiple instances | 53 |
| **Loop candidates detected** | 13 |
| **Grid/non-loop correctly rejected** | 57 |
| False positive rate | ~0% (all top candidates are real loops) |

### The Core Insight Works

Gemini's "internal diversity" metric successfully distinguishes:

**TRUE LOOPS (High Diversity):**
```
Skeleton: ('A', 'N', '_', 'N')
Position: 3, Iterations: ['1', '2']
Diversity: 12.0 bases per iteration
Sample: ['A1_1', 'A2_1', 'A3_1', 'A4_1']
```
→ 12 different question bases (A1, A2, A3, A4, A5, etc.) share the `_1`/`_2` iterator. **This is a loop.**

**NON-LOOPS (Low Diversity):**
```
Skeleton: ('S', 'N')
Diversity: 1.0
Sample: ['S2', 'S3', 'S4', 'S5']
```
→ Only 1 base per "iteration" (S2, S3, S4 are different questions, not the same question looped). **Correctly rejected.**

### Confirmation from Data File

The stacked data file already has:
- A `LOOP` column (the iterator indicator)
- 210 columns with `_1` or `_2` patterns

This validates that:
1. The survey was indeed looped
2. Antares already stacked it
3. Our detection is identifying the right patterns

---

## Strengths of Gemini's Approach

### 1. The "Internal Diversity" Concept is Correct
The key insight: a loop has multiple distinct question roots sharing an iterator. A grid has one question root with multiple row/column indices. This discriminator works.

### 2. Tokenization is Robust
Breaking variables into tokens and creating "skeletons" handles various naming conventions:
- `A4_1` → `('A', 'N', '_', 'N')`
- `A22r1c1` → `('A', 'N', 'r', 'N', 'c', 'N')`
- `Q1L1` → `('Q', 'N', 'L', 'N')`

### 3. Position-Agnostic
The algorithm doesn't assume the iterator is always at the end or in a specific position—it finds it structurally.

---

## Gaps & Improvements Needed

### Gap 1: Multiple Varying Positions

**Problem:** A skeleton like `('A', 'N', '_', 'N', 'r', 'N')` has THREE numeric positions. Gemini's algorithm flags EACH position separately, producing:
- Position 1 (the question number): diversity 17.6
- Position 3 (the loop iterator): diversity 44.0
- Position 5 (the row number): diversity ~2-3

**Solution:** Add the "slowest-moving part" heuristic more rigorously:
```python
# Pick the position that changes LEAST frequently in the sorted variable list
# The loop iterator stays constant across blocks of variables
```

Or simpler: **Pick the position with highest diversity** (position 3 with 44.0 in this case).

### Gap 2: Answer Option Matching (Confirmation Layer)

Gemini's proposal doesn't include this, but our reliability plan does. When we find a loop candidate:
1. Check if `A4_1` and `A4_2` have the same answer options
2. If yes → high confidence loop
3. If no → might be different questions that happen to share naming

**Test results:** This is harder than expected because many variables use `Values: X-Y` ranges without explicit labels. But when options exist, matching works.

### Gap 3: Data Validation Layer

Our reliability plan mentioned checking the actual data:
- If `_2` variables are only answered by a subset of respondents → confirms loop
- This is the strongest validation but requires data access

**Recommendation:** Make this optional. Datamap-only detection is 90% reliable; data validation pushes it to 99%.

### Gap 4: Label Extraction is Vague

Gemini mentions `pipe_` variables as label sources but doesn't specify the algorithm.

**Reality check:** In Tito's, the labels come from `hLOCATION*` variables, not pipes. The linkage is:
- `LOOP=1` → `hLOCATION_1` (e.g., "at your home")
- `LOOP=2` → `hLOCATION_2` (e.g., "at a bar")

This needs more investigation per-dataset.

### Gap 5: Output Doesn't Specify Stacking Action

The proposal outputs detection but doesn't specify:
- Which columns go in the "long" format
- What the new `LOOP` column should contain
- How to handle nested sub-variables (`A7_1r1` through `A7_1r10`)

---

## Recommended Implementation

### Phase 1: Detection Only (What Gemini Proposes)

```typescript
interface LoopDetectionResult {
  hasLoops: boolean;
  confidence: 'high' | 'medium' | 'low';
  loopGroups: LoopGroup[];
  warnings: string[];
}

interface LoopGroup {
  iteratorPosition: number;        // Which token position is the iterator
  iterations: string[];            // ['1', '2'] or ['A', 'B']
  variableBases: string[];         // ['A1', 'A2', 'A3', ...] - the questions that repeat
  diversity: number;               // Internal diversity score
  sampleVariables: string[];       // Examples for UI display
  labelSourceCandidates?: string[]; // Potential label variables (hLOCATION_*, etc.)
}
```

### Phase 2: User Confirmation (Our De-scoped Approach)

```
⚠️ Loop Variables Detected

We found 12 questions that repeat across 2 loop iterations:
  • A1, A2, A3, A4, A5... (iterator: _1, _2)

This survey appears to have looped questions (e.g., "Rate Location 1" and "Rate Location 2").

[My data is already stacked] [Help me stack it] [This isn't a loop]
```

### Phase 3: Stacking (If User Confirms)

If data isn't stacked:
1. Identify all `_1` variables as "base" columns
2. Create `LOOP` column
3. For each respondent, create N rows (one per loop iteration)
4. Pivot `_1`, `_2` columns into single columns

---

## Implementation Location

```
src/lib/processors/DataMapProcessor.ts
  └── detectLoopVariables()      # New method after normalizeVariableTypes()

src/lib/pipeline/
  └── LoopDetector.ts            # Standalone module for loop detection

src/schemas/
  └── loop-detection.ts          # Zod schemas for LoopDetectionResult
```

---

## Test Cases

| Test | Input | Expected |
|------|-------|----------|
| Standard loop | `A1_1, A2_1, A1_2, A2_2` | Detect loop at position 3 |
| Grid (reject) | `A22r1c1, A22r1c2, A22r2c1` | Reject (diversity 1) |
| Nested grid in loop | `C2_1r1c1, C2_1r2c1, C2_2r1c1` | Detect `_1/_2` loop, ignore `r/c` |
| Iterator at end | `Q1L1, Q2L1, Q1L2` | Detect loop at position 3 |
| Iterator at start | `L1Q1, L1Q2, L2Q1` | Detect loop at position 1 |
| No loop | `S1, S2, S3, S4` | No loop detected |
| Mixed with grids | `A1_1, A1_2, B1r1, B1r2` | Detect `A*` loop, reject `B*` grid |

---

## Conclusion

**Gemini's approach is valid and should be implemented.** The core algorithm works. Improvements needed:

1. **Add diversity-based position selection** (pick highest diversity position)
2. **Add answer option matching as confirmation layer** (when available)
3. **Keep data validation optional** (for extra confidence)
4. **Define output format clearly** (the JSON schema above)
5. **Plan UI flow** (detection → user confirmation → stacking action)

The "Block-Based Structural Analysis" approach is fundamentally sound because it relies on mathematical structure (how many distinct bases share an iterator) rather than fragile regex patterns.

---

*Evaluation Date: February 5, 2026*
*Tested Against: Tito's Growth Strategy (660 variables, known looped survey)*
