# Demo Enhancements Plan

**Goal**: Improve the demo experience for Bob by showcasing the system's intelligent capabilities while being transparent about its current limitations.

**Branch**: `demo-011326`

---

## Overview

| Phase | Enhancement | Status | Purpose |
|-------|-------------|--------|---------|
| 1 | Pipeline Parallelism | ✅ Complete | Faster processing (~14 min saved) |
| 2 | Human-in-the-Loop Review | ⏳ In Progress | Handle uncertainty gracefully, show intelligent flagging |
| 3 | Path B Producer-Consumer | ✅ Complete | Overlap TableAgent + VerificationAgent (~30-40% faster) |

---

## Phase 1: Pipeline Parallelism ✅ COMPLETE

**Implemented**: January 15, 2026

### Architecture
```
                    ┌─→ BannerAgent → CrosstabAgent ─────────────┐
DataMapProcessor ───┤                                            ├─→ R → Excel
                    └─→ TableAgent → Survey → VerificationAgent ─┘
```

### Results
- **Time saved**: ~14 minutes per pipeline run
- Path A and Path B execute simultaneously via `Promise.allSettled`
- Progress tracking shows combined percentage (20-80% during parallel phase)

### Key Files
- `src/lib/jobStore.ts` - `'parallel_processing'` stage
- `src/app/api/process-crosstab/route.ts` - `executePathA`/`executePathB` helpers
- `scripts/test-pipeline.ts` - Mirrored parallel pattern for CLI

---

## Phase 2: Human-in-the-Loop Review ⏳ IN PROGRESS

**Status**: Core review UI and logic complete. Needs timing optimization (see below).

### What Triggers Review

| Condition | Example |
|-----------|---------|
| `confidence < 0.75` | Multiple candidate variables found |
| `expressionType` is `placeholder` | "TBD", "Joe to define" |
| `expressionType` is `conceptual_filter` | "IF TEACHER", "HIGH VOLUME" |
| `expressionType` is `from_list` | "Segment A from list" |
| `humanReviewRequired: true` | Agent explicitly flagged uncertainty |

### User Actions

| Action | Result |
|--------|--------|
| **Approve** | Use proposed R expression |
| **Select Alternative** | Use a different candidate mapping |
| **Provide Hint** | Re-run agent for that column with user context |
| **Edit Directly** | User provides exact R expression |
| **Skip** | Exclude cut from final output |

### Current Flow (Suboptimal)

```
DataMapProcessor
    │
    ├─→ Path A: Banner → Crosstab ──┐
    │                               ├──→ WAIT for both ──→ Review? ──→ PAUSE
    └─→ Path B: Table → Verify ─────┘
                                          ↑
                                          │
                                User waits here doing nothing
                                while Path B runs (~10+ min)
```

**Problem**: The current implementation waits for BOTH paths to complete before checking if review is needed. This wastes user time - they could be reviewing flagged columns while Path B runs.

### Target Flow (To Implement)

```
DataMapProcessor
    │
    ├─→ Path A: Banner → Crosstab ──→ Review needed? ──YES──→ Review UI immediately
    │                                       │                        │
    │                                       NO                 User reviews
    │                                       │                  (Path B continues)
    └─→ Path B: Table → Verify ─────────────┴────────────────────────┘
                                            │
                                            ▼
                                       R Script → Excel
```

**Goal**: Show review UI immediately when CrosstabAgent finishes. User reviews while Path B runs in parallel. When user submits, Path B is likely already done → fast generation.

### Implementation Requirements

1. **Decouple review check from Path B completion**
   - Start Path B without blocking on it
   - Await Path A completion
   - Check for flagged columns immediately after Path A
   - If review needed: show UI now, Path B continues in background

2. **Track Path B status independently**
   - Path B writes result to disk when complete (e.g., `path-b-result.json`)
   - Review state tracks `pathBStatus: 'running' | 'completed'`
   - Review handler waits for Path B only if still running when user submits

3. **Handle edge cases**
   - Path B fails while user is reviewing
   - User submits review before Path B completes
   - User provides hint (re-runs CrosstabAgent) - should not block on Path B

4. **Preserve existing behavior**
   - If no review needed, wait for Path B then continue to R script
   - Review UI functionality unchanged
   - CLI test script unaffected

### Key Files

**Backend:**
- `src/app/api/process-crosstab/route.ts` - Review gate after CrosstabAgent, writes `crosstab-review-state.json`
- `src/app/api/pipelines/[pipelineId]/review/route.ts` - GET/POST for review state and decisions
- `src/app/api/pipelines/[pipelineId]/cancel/route.ts` - Cancel with AbortController
- `src/lib/jobStore.ts` - `crosstab_review_required` stage
- `src/schemas/agentOutputSchema.ts` - `alternatives`, `uncertainties`, `humanReviewRequired`, `expressionType` fields
- `src/prompts/crosstab/production.ts` - `<human_review_support>` section

**Frontend:**
- `src/app/pipelines/[pipelineId]/review/page.tsx` - Review UI with all 5 actions
- `src/app/page.tsx` - Toast notification with "Review Now" action

### CLI Behavior

The test-pipeline script (`scripts/test-pipeline.ts`) calls agents directly and bypasses the review gate. It always runs to completion - the new fields are output but not acted upon.

---

## Phase 3: Path B Producer-Consumer Pipeline ✅ COMPLETE

**Implemented**: January 16, 2026

### Architecture

```
                    ┌───────────────────────────────────────────────────────┐
                    │                  PathBCoordinator                     │
                    │                                                       │
                    │  ┌─────────────┐         ┌─────────────────────┐     │
                    │  │ TableAgent  │ ──push──▶│     TableQueue      │     │
                    │  │  (producer) │         │  (async with signal) │     │
                    │  └─────────────┘         └──────────┬──────────┘     │
                    │                                     │ pull (blocks   │
                    │                                     │  if empty)     │
                    │                          ┌──────────▼──────────┐     │
                    │                          │  VerificationAgent   │     │
                    │                          │     (consumer)       │     │
                    │                          └─────────────────────┘     │
                    │                                                       │
                    │  Results aggregated when both complete               │
                    └───────────────────────────────────────────────────────┘
```

### Implementation

- **TableQueue**: Async producer-consumer queue (`src/lib/pipeline/TableQueue.ts`)
  - `push()` - producer adds tables as each question group completes
  - `pull()` - consumer gets next table (blocks if empty, returns null when done)
  - `markDone()` - producer signals completion

- **TableAgent streaming**: New `processQuestionGroupsWithCallback()` function
  - Emits tables via callback as each group completes
  - VerificationAgent starts processing immediately

- **Producer-Consumer coordination** in `executePathB()`
  - Survey markdown loaded upfront (needed for consumer from start)
  - Producer and consumer run in parallel via `Promise.all`
  - Rate limit retry with exponential backoff (2s, 4s, 8s)

### Results
- **Time reduction**: ~30-40% faster Path B execution
- TableAgent and VerificationAgent overlap execution
- Consumer starts as soon as first table is ready (maximum overlap)
- Graceful handling of rate limits and errors

### Key Files
- `src/lib/pipeline/TableQueue.ts` - **NEW** async queue utility
- `src/agents/TableAgent.ts` - Added `processQuestionGroupsWithCallback()`
- `src/app/api/process-crosstab/route.ts` - Updated `executePathB()` with producer-consumer

### CLI Behavior
The test-pipeline script (`scripts/test-pipeline.ts`) still uses the sequential batch API (`processDataMap` → `verifyAllTables`). The producer-consumer pattern only applies to the UI pipeline.

---

## Known Issues

### ✅ CrosstabAgent Schema Error (RESOLVED)

**Status**: Fixed - January 16, 2026

**Original Error**:
```
Invalid schema for response_format 'response': In context=('properties', 'columns', 'items'),
'required' is required to be supplied and to be an array including every key in properties.
Missing 'alternatives'.
```

**Root Cause**:
Azure OpenAI has stricter JSON Schema requirements than OpenAI - it requires ALL properties to be in the `required` array. When the Vercel AI SDK converts Zod to JSON Schema, fields with `.optional()` or `.default()` are NOT included in `required`.

**The Fix**:
Removed `.default()` from the human review fields, making them truly required:

```typescript
// Before (broken - .default() doesn't make fields required in JSON Schema):
alternatives: z.array(AlternativeSchema).default([])
uncertainties: z.array(z.string()).default([])
humanReviewRequired: z.boolean().default(false)
expressionType: ExpressionTypeSchema.default('direct_variable')

// After (works - fields are truly required):
alternatives: z.array(AlternativeSchema)
uncertainties: z.array(z.string())
humanReviewRequired: z.boolean()
expressionType: ExpressionTypeSchema
```

This works because:
1. The prompt already instructs the AI to output these fields for every column
2. Empty arrays `[]` and `false` are valid outputs when not applicable
3. Other agents (TableAgent, VerificationAgent) use the same pattern successfully

**Files Changed**:
- `src/schemas/agentOutputSchema.ts` - Removed `.default()` from human review fields

---

## Demo Readiness Checklist

- [x] Pipeline parallelism working (Path A || Path B)
- [x] Sidebar shows in-progress pipelines
- [x] Cancel button properly stops processing
- [x] Review UI with alternatives, hints, edits
- [x] **FIX: CrosstabAgent schema error** (resolved - removed `.default()` from schema)
- [ ] **Human-in-the-loop timing optimization** (show review immediately after CrosstabAgent, don't wait for Path B)
- [ ] Test with banner that triggers review (need low-confidence mappings)
- [x] **Path B pipelining** (TableAgent → VerificationAgent producer-consumer overlap)
