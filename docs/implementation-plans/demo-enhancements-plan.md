# Demo Enhancements Plan

**Goal**: Improve the demo experience for Bob by showcasing the system's intelligent capabilities while being transparent about its current limitations.

**Branch**: `demo-011326`

---

## Overview

Three key enhancements to make the system more impressive and robust for demos:

| Phase | Enhancement | Purpose |
|-------|-------------|---------|
| 1 | Pipeline Parallelism | Faster processing, better UX |
| 2 | Human-in-the-Loop for Banner Review | Handle uncertainty gracefully, show intelligent flagging |
| 3 | AI-Recommended Cuts | Demonstrate AI's analytical capabilities |

---

## Phase 1: Pipeline Parallelism

### Current State (Sequential)
```
DataMapProcessor → BannerAgent → CrosstabAgent → TableAgent → VerificationAgent → R → Excel
```

### Proposed State (Parallel paths after DataMapProcessor)
```
                    ┌─→ BannerAgent → CrosstabAgent ─────────────┐
DataMapProcessor ───┤                                            ├─→ R → Excel
                    └─→ TableAgent → VerificationAgent ──────────┘
```

### Key Observations
- **DataMapProcessor** is deterministic and fast - run first, needed by all paths
- **Path A (Banner → Crosstab)**: Extracts cuts, validates expressions
- **Path B (Table → Verification)**: Decides table structure, enhances with survey
- **Convergence**: R script generation needs both cuts (from CrosstabAgent) AND tables (from VerificationAgent)

### Dependencies Analysis
| Agent | Needs | Doesn't Need |
|-------|-------|--------------|
| BannerAgent | Banner file | DataMap |
| CrosstabAgent | DataMap + Banner output | Tables |
| TableAgent | DataMap (verbose) | Banner, Cuts |
| VerificationAgent | TableAgent output, Survey | Banner, Cuts |
| R Script | Cuts + Tables | - |

### Implementation Approach
1. Run DataMapProcessor first (fast, deterministic)
2. Use `Promise.all()` for the two parallel paths:
   - Path A: `BannerAgent → CrosstabAgent`
   - Path B: `TableAgent → VerificationAgent`
3. Wait for both paths to complete
4. Converge: R script generation uses outputs from both paths
5. Update progress percentages to reflect parallel execution
6. Handle errors from either path gracefully

### Code Sketch
```typescript
// Step 1: DataMapProcessor (must be first)
const dataMapResult = await dataMapProcessor.processDataMap(...);

// Step 2: Parallel paths
const [pathAResult, pathBResult] = await Promise.all([
  // Path A: Banner → Crosstab
  (async () => {
    const bannerResult = await bannerAgent.processDocument(...);
    const crosstabResult = await processCrosstabGroups(...);
    return { banner: bannerResult, crosstab: crosstabResult };
  })(),

  // Path B: Table → Verification
  (async () => {
    const tableResult = await processTableAgent(...);
    const verifiedTables = await verifyAllTables(...);
    return { tables: verifiedTables };
  })(),
]);

// Step 3: Converge - R script needs both
const cutsSpec = buildCutsSpec(pathAResult.crosstab);
const rScript = generateRScriptV2({ tables: pathBResult.tables, cuts: cutsSpec.cuts });
```

### Expected Impact
- BannerAgent + CrosstabAgent: ~2-3 minutes (vision/OCR heavy)
- TableAgent + VerificationAgent: ~5-10 minutes (LLM calls per question)
- **Time saved**: Path A and Path B run simultaneously instead of sequentially
- **Estimated reduction**: 2-3 minutes off total time, helping stay under 1 hour

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
