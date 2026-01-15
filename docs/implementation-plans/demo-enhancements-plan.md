# Demo Enhancements Plan

**Goal**: Improve the demo experience for Bob by showcasing the system's intelligent capabilities while being transparent about its current limitations.

**Branch**: `demo-011326`

---

## Overview

Three key enhancements to make the system more impressive and robust for demos:

| Phase | Enhancement | Status | Purpose |
|-------|-------------|--------|---------|
| 1 | Pipeline Parallelism | ✅ Complete | Faster processing (~14 min saved) |
| 2 | Human-in-the-Loop for Banner Review | ✅ Complete | Handle uncertainty gracefully, show intelligent flagging |
| 3 | AI-Recommended Cuts | ⏳ Deferred | Demonstrate AI's analytical capabilities |

---

## Phase 1: Pipeline Parallelism ✅ COMPLETE

**Status**: Implemented January 15, 2026

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

### Files Modified
- `src/lib/jobStore.ts` - Added `'parallel_processing'` stage
- `src/app/api/process-crosstab/route.ts` - Parallel execution with `executePathA`/`executePathB` helpers
- `scripts/test-pipeline.ts` - Mirrored parallel pattern for CLI testing

---

## Phase 2: Human-in-the-Loop for Banner Review

### Goal
When BannerAgent is uncertain about extraction, pause Path A (Banner → Crosstab) and ask the user to review/correct before proceeding. Meanwhile, Path B (Table → Verification) continues in parallel, maximizing efficiency.

### Prerequisites
- **Phase 1 should be implemented first** - parallelism enables Path B to continue while Path A waits for human review
- Without parallelism, the entire pipeline blocks on human review

### Current State (What Already Exists)

**BannerAgent schema already has these fields per column:**
```typescript
// src/agents/BannerAgent.ts - BannerColumnSchema
{
  name: string;
  original: string;           // Raw text from banner document
  adjusted: string;           // AI's R expression
  statLetter: string;
  confidence: number;         // 0-1 confidence score
  requiresInference: boolean; // True if AI had to guess/infer
  inferenceReason: string;    // Why inference was needed
  humanInLoopRequired: boolean; // True if confidence < 0.85
  uncertainties: string[];    // Specific things human should verify
}
```

**Validation UI exists but is disconnected:**
- `/validate` - queue listing page
- `/validate/[sessionId]` - detail page with column review
- Reads from `temp-outputs/` but pipeline writes to `outputs/`

### Trigger Conditions

After BannerAgent completes, check if human review is needed:

```typescript
// Check logic after BannerAgent extraction
function needsHumanReview(bannerResult: BannerProcessingResult): boolean {
  const columns = bannerResult.verbose.data.extractedStructure.bannerCuts
    .flatMap(group => group.columns);

  // Trigger review if ANY column meets these conditions:
  return columns.some(col =>
    col.humanInLoopRequired === true ||
    col.confidence < 0.85 ||
    col.requiresInference === true
  );
}
```

### What Gets Flagged for Review

| Condition | Example | Why It Needs Review |
|-----------|---------|---------------------|
| `confidence < 0.85` | OCR couldn't parse filter clearly | Expression might be wrong |
| `humanInLoopRequired: true` | Complex nested logic | AI explicitly flagged uncertainty |
| `requiresInference: true` | "Total" column created by AI | Wasn't in original document |
| `uncertainties.length > 0` | Ambiguous group boundary | AI lists specific concerns |

### Pipeline Status Model

Pipelines need a richer status model to reflect the full lifecycle:

```typescript
type PipelineStatus =
  | 'in_progress'      // Pipeline running (any agent active)
  | 'pending_review'   // Waiting for human to review banner
  | 'resuming'         // Human approved, completing remaining steps
  | 'success'          // All steps completed successfully
  | 'partial'          // Completed but with warnings (e.g., R failed)
  | 'error'            // Failed with error
  | 'cancelled';       // User cancelled mid-run
```

**Status transitions:**
```
in_progress → pending_review → resuming → success
     │              │             │
     │              │             └──→ partial
     │              │             └──→ error
     │              └──→ cancelled
     └──→ success (no review needed)
     └──→ error
     └──→ cancelled
```

### Early Pipeline Summary (Sidebar Visibility)

**Problem:** Currently `pipeline-summary.json` is only written at the end, so in-progress pipelines don't appear in sidebar.

**Solution:** Write an initial summary immediately after pipeline starts, then update it as stages complete:

```typescript
// Write immediately after DataMapProcessor completes
const initialSummary = {
  pipelineId,
  dataset: datasetName,
  timestamp: new Date().toISOString(),
  source: 'ui',
  status: 'in_progress',  // Will be updated as pipeline progresses
  currentStage: 'banner_agent',
  inputs: {
    datamap: dataMapFile.name,
    banner: bannerPlanFile.name,
    spss: dataFile.name,
    survey: surveyFile?.name || null
  },
  // outputs populated later when available
};
await fs.writeFile(path.join(outputDir, 'pipeline-summary.json'), JSON.stringify(initialSummary, null, 2));
```

**Update points:**
1. After DataMapProcessor → `status: "in_progress"`, `currentStage: "banner_agent"`
2. If review needed → `status: "pending_review"`, `currentStage: "banner_review"`
3. After human approves → `status: "resuming"`, `currentStage: "crosstab_agent"`
4. On completion → `status: "success"`, add `outputs` object, add `duration`
5. On error → `status: "error"`, add `error` message

### UX Considerations (To Be Designed)

**Toast vs Sidebar Interaction:**
When a pipeline is running, we show a toast with progress. But the pipeline also appears in the sidebar. Questions to resolve:

- If user clicks pipeline in sidebar, should toast dismiss?
- Should clicking sidebar item navigate to pipeline detail page?
- If pipeline needs review, should toast have "Review Now" action button?
- Should toast persist if user navigates away, or rely on sidebar for status?

**Proposed behavior (to be validated):**
1. Toast shows while on home page - quick status visibility
2. Clicking pipeline in sidebar → navigates to detail page, toast stays (can dismiss manually)
3. If `status: "pending_review"` → toast shows "Review Required" with action button to review page
4. Pipeline detail page shows full status regardless of toast

**Review-needed notification:**
- Toast: "Banner review required - 3 columns need attention" + [Review Now] button
- Sidebar: Pipeline shows with yellow "Pending Review" badge
- Clicking either goes to `/pipelines/[pipelineId]/review`

### State Persistence

When review is needed, write state to disk so it survives server restarts:

**File: `outputs/{dataset}/{pipelineId}/banner-review-state.json`**
```json
{
  "pipelineId": "pipeline-2026-01-13T...",
  "status": "awaiting_review",
  "createdAt": "2026-01-13T17:00:00.000Z",
  "bannerResult": { /* full BannerProcessingResult */ },
  "flaggedColumns": [
    {
      "groupName": "HCP Specialty",
      "columnName": "Cards",
      "original": "S2=1 OR S2a=1",
      "adjusted": "S2 == 1 | S2a == 1",
      "confidence": 0.82,
      "uncertainties": ["Unclear if S2a should be included"],
      "requiresInference": false,
      "humanInLoopRequired": true
    }
  ],
  "pathBStatus": "running" | "completed",  // Track parallel path
  "dataMapProcessed": true,
  "tableAgentComplete": false,
  "verificationComplete": false
}
```

**File: `outputs/{dataset}/{pipelineId}/validation-status.json`**
```json
{
  "status": "pending",
  "createdAt": "2026-01-13T17:00:00.000Z",
  "type": "banner_review",
  "pipelineId": "pipeline-2026-01-13T..."
}
```

### Job Store Updates

Add new stages to track review state:

```typescript
// src/lib/jobStore.ts
export type JobStage =
  | 'uploading'
  | 'parsing'
  | 'banner_agent'
  | 'banner_review_required'  // NEW: Waiting for human review
  | 'banner_review_complete'  // NEW: Human approved/edited
  | 'crosstab_agent'
  | 'table_agent'
  | 'verification_agent'
  | 'generating_r'
  | 'executing_r'
  | 'writing_outputs'
  | 'complete'
  | 'error';

// Extended job status for review
export interface JobStatus {
  // ... existing fields ...
  reviewRequired?: boolean;
  reviewUrl?: string;  // Link to review UI
  flaggedColumnCount?: number;
}
```

### Pipeline Flow with Parallelism + Review

```
DataMapProcessor (fast, deterministic)
        │
        ├─────────────────────────────────────────┐
        │                                         │
        ▼                                         ▼
   BannerAgent                              TableAgent
        │                                         │
        ▼                                         │
  Needs Review? ──YES──► PAUSE Path A             │
        │                    │                    │
        NO                   │                    ▼
        │                    │            VerificationAgent
        ▼                    │                    │
  CrosstabAgent              │                    │
        │                    │                    │
        │◄───── Human Reviews & Approves ─────────│
        │         (Path B may finish first)       │
        ▼                                         │
        └─────────────── CONVERGE ────────────────┘
                            │
                            ▼
                    R Script Generation
                            │
                            ▼
                      Excel Export
```

### Review UI Requirements

**Location:** New page at `/pipelines/[pipelineId]/review` or modal in pipeline detail

**What to show the user:**

1. **Header Context:**
   - Pipeline ID and dataset name
   - "X columns need your review"
   - Path B status: "Tables are being processed in parallel..."

2. **For each flagged column, show side-by-side:**
   ```
   ┌─────────────────────────────────────────────────────────────┐
   │ Group: HCP Specialty                                        │
   │ Column: Cards                                               │
   ├─────────────────────────────────────────────────────────────┤
   │ Original (from banner):     │ AI Generated (R syntax):     │
   │ "S2=1 OR S2a=1"             │ "S2 == 1 | S2a == 1"         │
   ├─────────────────────────────────────────────────────────────┤
   │ Confidence: 82%             │ ⚠️ Flagged for review        │
   ├─────────────────────────────────────────────────────────────┤
   │ AI's Concerns:                                              │
   │ • "Unclear if S2a should be included in this expression"   │
   ├─────────────────────────────────────────────────────────────┤
   │ Your Decision:                                              │
   │ ○ Approve as-is                                             │
   │ ○ Edit expression: [___________________________]            │
   │ ○ Skip this cut (exclude from output)                       │
   └─────────────────────────────────────────────────────────────┘
   ```

3. **Per-column independence:**
   - Each flagged column is self-contained with its own decision
   - User can mix actions: approve some, edit some, skip others
   - "Skip" means exclude cut from final output entirely (user doesn't have the answer or doesn't want this cut)
   - All decisions saved together with single "Save & Continue" button at bottom

4. **Actions (bottom of page):**
   - "Save & Continue" - apply all decisions (approvals, edits, skips), resume Path A
   - "Cancel Pipeline" - abort everything

5. **Progress indicator:**
   - Show that Path B is running/completed
   - "Tables ready, waiting for banner approval to generate final output"

### API Endpoints

**Update GET `/api/pipelines` (list route):**
- Handle new statuses: `in_progress`, `pending_review`, `resuming`
- Show pipelines with these statuses in sidebar (not just `success`)
- Add status badge/indicator to `PipelineListItem` type
- Consider filtering options (show all vs completed only)

**GET `/api/pipelines/[pipelineId]/review`**
- Returns banner-review-state.json contents
- Includes flagged columns with full context

**POST `/api/pipelines/[pipelineId]/review`**
- Body: `{ approved: boolean, edits: { groupName, columnName, newAdjusted }[] }`
- Writes human decisions to banner-review-state.json
- Updates status to "approved"
- Triggers Path A to resume (CrosstabAgent with corrected banner)

### Implementation Steps

1. **Update process-crosstab/route.ts:**
   - After BannerAgent, check `needsHumanReview()`
   - If true: write state files, update job to `banner_review_required`, DON'T call CrosstabAgent yet
   - Path B continues independently via Promise

2. **Create resume logic:**
   - New function `resumePathA(pipelineId, approvedBanner)`
   - Called by POST `/api/pipelines/[pipelineId]/review`
   - Picks up from CrosstabAgent with human-approved banner

3. **Update job polling:**
   - When stage is `banner_review_required`, include `reviewUrl` in status
   - Frontend shows "Review Required" with link to review UI

4. **Create Review UI:**
   - New page or component showing flagged columns
   - Side-by-side original vs AI output
   - Edit capability for expressions
   - Approve/Continue button

5. **Handle convergence:**
   - After human approves, Path A completes (CrosstabAgent)
   - Check if Path B is done
   - If both done, proceed to R script generation
   - If Path B still running, wait for it

### Edge Cases

- **User takes hours to review:** Path B completes and waits. State persisted to disk.
- **Server restarts during review:** State in banner-review-state.json, can resume.
- **User cancels:** Clean up both paths, mark pipeline as cancelled.
- **Path B fails while waiting:** Show error, but still allow banner review to complete for debugging.
- **All columns high confidence:** No review needed, Path A continues immediately.

### Success Criteria

- [ ] Low-confidence columns trigger review UI
- [ ] Path B continues while Path A waits
- [ ] Human can see original vs AI output clearly
- [ ] Human can edit expressions inline
- [ ] Pipeline resumes correctly after approval
- [ ] State survives server restart
- [ ] Review decision recorded in pipeline-summary.json

---

## Implementation Priority

For the Bob demo:

1. **Phase 1 (Parallelism)** - Implement first, enables Phase 2
2. **Phase 2 (Human-in-the-Loop)** - Most impressive for demo, shows system handles uncertainty gracefully

**Note:** AI-Recommended Cuts was considered for Phase 3 but removed from demo scope. It requires a new agent and doesn't directly support the demo goals. See `future-enhancements.md` for detailed exploration of this feature.

---

## Phase 2 Completion Notes ✅

**Implemented January 15, 2026**

### What Was Built

1. **Backend Infrastructure (Phase 2a)**
   - Early `pipeline-summary.json` creation for sidebar visibility
   - Review state persistence in `banner-review-state.json`
   - `getFlaggedColumns()` detection based on confidence < 0.85, `humanInLoopRequired`, or `requiresInference`
   - Review API endpoints: GET/POST `/api/pipelines/[pipelineId]/review`
   - Resume logic after human approval
   - Cancel endpoint: POST `/api/pipelines/[pipelineId]/cancel`

2. **Frontend UI (Phase 2b)**
   - Review page at `/pipelines/[pipelineId]/review`
   - Toast notification with "Review Now" action button
   - Sidebar status badges for `in_progress`, `pending_review`, `cancelled`
   - Pipeline detail page with status banners and centered layout

### Files Created/Modified
- `src/app/api/pipelines/[pipelineId]/review/route.ts` (NEW)
- `src/app/api/pipelines/[pipelineId]/cancel/route.ts` (NEW)
- `src/app/pipelines/[pipelineId]/review/page.tsx` (NEW)
- `src/app/api/process-crosstab/route.ts` - Early summary, review detection, state persistence
- `src/lib/jobStore.ts` - New stages and status fields
- `src/components/PipelineListCard.tsx` - Status icons and badges
- `src/app/pipelines/[pipelineId]/page.tsx` - Status banners, centered layout

---

## Known Issues & Next Steps

### 🐛 Bug: Cancel Pipeline Not Fully Working

**Issue:** Cancel pipeline endpoint exists but may not be properly stopping the running processes. The pipeline continues processing in the background even after cancellation.

**Root Cause (suspected):** The cancel endpoint updates `pipeline-summary.json` status to `cancelled`, but the actual Node.js promises executing the agents are not aborted.

**Fix Required:**
- Add AbortController pattern to agent execution
- Check for cancellation between pipeline stages
- Properly clean up when cancellation is detected

### 🧪 Testing: Human-in-the-Loop Needs Harder Test Cases

**Issue:** Current test banner documents are too clean/clear. BannerAgent extracts them with high confidence (>0.85), so the human review flow never triggers during demos.

**Solutions to explore:**
1. **Lower threshold temporarily** - Change confidence threshold from 0.85 to 0.95 for testing
2. **Create ambiguous test banner** - Design a banner document with:
   - Unclear filter expressions (e.g., "Doctors who treat X or Y")
   - Missing variable references
   - Ambiguous group boundaries
   - OCR-unfriendly formatting
3. **Force flag for demo** - Add a `?forceReview=true` query param that forces review regardless of confidence

### ⚡ Optimization: Staggered Agent Processing

**Issue:** Currently Path A and Path B start simultaneously after DataMapProcessor. This means all agents compete for API rate limits at once.

**Proposed Optimization:**
```
DataMapProcessor
    │
    ├─→ BannerAgent (starts immediately)
    │       │
    │       └─→ CrosstabAgent (after BannerAgent)
    │
    └─→ TableAgent (starts after 2-3 second delay)
            │
            └─→ VerificationAgent (after TableAgent)
```

**Benefits:**
- Smoother API usage, less rate limiting
- BannerAgent gets head start (it's the review bottleneck)
- Overall pipeline may complete faster due to fewer API throttles

**Implementation:**
- Add configurable delay before starting Path B
- Or start Path B after BannerAgent completes (still parallel with CrosstabAgent)

---

## Demo Readiness Checklist

- [x] Pipeline parallelism working
- [x] Human-in-the-loop UI complete
- [x] Sidebar shows in-progress pipelines
- [x] Cancel button updates status
- [ ] Cancel actually stops processing (bug)
- [ ] Human review flow tested end-to-end
- [ ] Staggered processing for API optimization
