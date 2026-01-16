# Demo Enhancements Plan

**Goal**: Improve the demo experience for Bob by showcasing the system's intelligent capabilities while being transparent about its current limitations.

**Branch**: `demo-011326`

---

## Overview

| Phase | Enhancement | Status | Purpose |
|-------|-------------|--------|---------|
| 1 | Pipeline Parallelism | ✅ Complete | Faster processing (~14 min saved) |
| 2 | Human-in-the-Loop Review | ⏳ In Progress | Handle uncertainty gracefully, show intelligent flagging |
| 3 | Staggered Agent Processing | ⏳ Not Started | Optimize API usage, reduce rate limiting |

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

## Phase 3: Path B Pipeline Parallelism ⏳ NOT STARTED

### Problem

Path B currently runs **sequentially**: TableAgent processes ALL question groups first, then VerificationAgent processes ALL tables after. This means VerificationAgent sits idle while TableAgent works, and vice versa.

**Current Flow (Sequential):**
```
TableAgent:        [Q1][Q2][Q3][Q4][Q5][Q6]...
                                              VerificationAgent: [T1][T2][T3][T4][T5]...
Total time: TableAgent duration + VerificationAgent duration
```

### Proposed Solution

**Producer-Consumer Pipeline**: TableAgent emits tables as it completes each question group. VerificationAgent picks them up and processes them concurrently.

**Proposed Flow (Pipelined):**
```
TableAgent:        [Q1][Q2][Q3][Q4][Q5][Q6]...
VerificationAgent:     [T1][T2][T3][T4][T5]...
Total time: ~max(TableAgent, VerificationAgent) + small overlap
```

### Benefits
- VerificationAgent starts working as soon as first tables are ready
- Overlapped execution reduces total pipeline time
- No rate limiting concerns (not adding more concurrent API calls, just reordering)

### Current Code Patterns

**TableAgent** (`src/agents/TableAgent.ts`):
- `groupDataMapByParent()` - Groups variables into question groups
- `processAllGroups()` - Processes groups (appears to be sequential loop)
- Returns `TableAgentOutput[]` - all results batched at the end

**VerificationAgent** (`src/agents/VerificationAgent.ts`):
- `verifyAllTables()` - Takes all tables, processes one at a time in loop
- Each table is independent (no cross-table dependencies)
- Already has `onProgress` callback pattern

**Orchestration** (`src/app/api/process-crosstab/route.ts`):
- `executePathB()` calls TableAgent, waits, then calls VerificationAgent

### Implementation Outline

*Detailed design to be completed in plan mode. High-level approach:*

1. **Streaming/Callback Pattern**: TableAgent emits tables via callback as each group completes
2. **Concurrent Queue**: VerificationAgent consumes from a queue, processing as tables arrive
3. **Coordination**: Wait for both to complete before proceeding to R script generation

### Key Questions for Plan Mode
- Should TableAgent process groups in parallel internally, or keep sequential?
- How to handle errors mid-stream (one group fails)?
- Does VerificationAgent need any context from other tables?
- Best pattern: async generators, event emitters, or simple callbacks?

### Files Likely to Modify
- `src/agents/TableAgent.ts` - Add streaming/callback emission
- `src/agents/VerificationAgent.ts` - Accept streaming input or queue
- `src/app/api/process-crosstab/route.ts` - Coordinate producer-consumer in `executePathB`

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
- [ ] Path B pipelining (TableAgent → VerificationAgent overlap)
