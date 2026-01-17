# Demo Enhancements Plan

**Goal**: Improve the demo experience for Bob by showcasing the system's intelligent capabilities while being transparent about its current limitations.

**Branch**: `demo-011326`

---

## Overview

| Phase | Enhancement | Status | Purpose |
|-------|-------------|--------|---------|
| 1 | Pipeline Parallelism | ✅ Complete | Faster processing (~14 min saved) |
| 2 | Human-in-the-Loop Review | ✅ Complete | Handle uncertainty gracefully, show intelligent flagging |
| 3 | Path B Producer-Consumer | ✅ Complete | Overlap TableAgent + VerificationAgent (~30-40% faster) |
| 4 | Reliability & Polish | ✅ Complete | UI polish, refresh resilience, timeout handling |
| 4.5 | Content Policy Retry | ✅ Complete | Auto-retry on Azure content moderation errors |
| 4.6 | Duration Tracking Fix | ✅ Complete | Show actual duration for review-flow pipelines |
| 5 | Review UI Redesign | 🔲 Planned | Cleaner, modern review experience |

---

## Phase 1: Pipeline Parallelism ✅ COMPLETE

**Implemented**: January 15, 2026

Path A (Banner → Crosstab) and Path B (Table → Verify) execute simultaneously, saving ~14 minutes per run.

```
                    ┌─→ BannerAgent → CrosstabAgent ─────────────┐
DataMapProcessor ───┤                                            ├─→ R → Excel
                    └─→ TableAgent → Survey → VerificationAgent ─┘
```

---

## Phase 2: Human-in-the-Loop Review ✅ COMPLETE

**Implemented**: January 16, 2026

### What It Does
- Flags columns needing human review (low confidence, placeholders, conceptual filters)
- Shows review UI **immediately** after CrosstabAgent finishes (doesn't wait for Path B)
- User can approve, select alternative, provide hint to re-run, edit directly, or skip
- Path B continues in background while user reviews
- "Waiting for tables..." indicator shown until Path B completes

### Architecture
```
Path A ─→ CrosstabAgent ─→ Review needed? ─YES─→ Review UI (immediate)
                                │                      │
                                NO               User reviews
                                │            (Path B continues)
Path B ─→ (fire-and-forget) ────┴──────────────────────┘
                                │
                                ▼
                           R Script → Excel
```

### Key Files
- `src/app/api/process-crosstab/route.ts` - Fire-and-forget Path B, immediate review check
- `src/app/api/pipelines/[pipelineId]/review/route.ts` - Waits for Path B on submit if needed
- `src/app/pipelines/[pipelineId]/review/page.tsx` - Polls Path B status, shows progress
- `path-b-status.json` / `path-b-result.json` - Track Path B completion on disk

---

## Phase 3: Path B Producer-Consumer ✅ COMPLETE

**Implemented**: January 16, 2026

TableAgent emits tables as each question group completes; VerificationAgent processes them immediately without waiting for all tables. ~30-40% faster Path B execution.

```
TableAgent (producer) ──push──▶ TableQueue ──pull──▶ VerificationAgent (consumer)
```

### Key Files
- `src/lib/pipeline/TableQueue.ts` - Async producer-consumer queue
- `src/agents/TableAgent.ts` - `processQuestionGroupsWithCallback()`

---

## Phase 4: Reliability & Polish ✅ COMPLETE

**Implemented**: January 17, 2026

### What Was Implemented

#### 1. Review UI Polish
- **Stripped emojis** from AI reasoning display (professional appearance)
- **Collapsed AI Concerns** by default with expandable toggle ("N AI Concerns")
- **Truncated long reasoning** with "Show more" button (120 char limit)
- **Truncated alternative reasons** (80 char limit)

#### 2. Pipeline Page Cleanup
- **Single processing indicator** - Removed spinner from StatusBadge when `in_progress`
- **Added cancel button** to processing banner
- **Added `awaiting_tables` status** with "Completing..." banner

#### 3. Refresh Resilience
- **Store pipelineId** in localStorage alongside jobId
- **Disk-based recovery** - When job not in memory, check `/api/pipelines/{id}` for disk state
- **State recovery** handles `in_progress`, `pending_review`, terminal states
- **Shows "Processing..."** without percentage when recovering from disk

#### 4. Review Submission Timeout
- **Async completion** - If Path B still running, save decisions and return immediately
- **Fire-and-forget background completion** waits for Path B then generates R/Excel
- **New status**: `awaiting_tables` shows "Review saved. Waiting for tables..."
- **30 min background timeout** with proper error handling

### Key Files Modified
- `src/app/pipelines/[pipelineId]/review/page.tsx` - UI polish
- `src/app/pipelines/[pipelineId]/page.tsx` - Cancel button, new status
- `src/app/page.tsx` - Refresh resilience
- `src/app/api/pipelines/[pipelineId]/review/route.ts` - Async completion
- `src/app/api/pipelines/[pipelineId]/route.ts` - Added `awaiting_tables` status

### Not Implemented (Future)
- Mobile responsiveness improvements

### Phase 4.5: Content Policy Retry (Added Jan 17)
Added shared retry utility (`src/lib/retryWithPolicyHandling.ts`) that all 4 agents now use:
- 3 retries with 2s delay for Azure content policy errors
- Respects abort signals for cancellation
- Fallback behavior preserved (zero-confidence for CrosstabAgent/TableAgent, passthrough for VerificationAgent, structured failure for BannerAgent)

### Phase 4.6: Duration Tracking Fix (Added Jan 17)
Fixed duration showing as "Unknown" for pipelines that go through review flow:
- `completePipeline()` now reads original `timestamp` from pipeline summary
- Calculates total duration from pipeline start to completion
- Includes `duration: { ms, formatted }` in final summary update
- Pipeline page now shows actual duration like "34m 12s" instead of "Unknown"

---

## Phase 5: Review UI Redesign ✅ COMPLETE

**Goal**: Streamline the review UI to feel cleaner and more modern. Reduce visual noise, improve user guidance, and group related items.

### Design Principles

1. **Reframe from "Here's what AI did" to "Help us confirm"**
   - Current: Shows AI's internal reasoning process
   - New: Focus on what the user needs to decide

2. **Reduce visual noise**
   - Remove colored icons from action buttons
   - Remove Expression Type badges ("Direct", "From List")
   - Simplify to essential information only

3. **Group columns by banner group**
   - Columns from the same banner group should be visually grouped
   - Makes it easier to review related cuts together

### Card Redesign

**Current card has ~7 sections:**
- Column name + group name
- Confidence badge + Expression Type badge
- Original Expression
- "What We Found" (verbose AI reasoning)
- Proposed R Expression
- Alternatives list
- AI Concerns (collapsible)
- 5 radio buttons with colored icons

**Proposed simplified card:**
```
┌─────────────────────────────────────────────────────────────────┐
│ APP                                        [Low confidence]     │
│ ─────────────────────────────────────────────────────────────── │
│ Banner says: "S2a=1"                                            │
│ AI suggests: S2b %in% c(2,3)                                    │
│                                                                 │
│ [Accept] [Pick alternative ▼] [Give hint] [Skip]                │
└─────────────────────────────────────────────────────────────────┘
```

### Actions (4 buttons, all visible)

| Action | Description |
|--------|-------------|
| **Accept** | Approve the AI's proposed mapping |
| **Pick alternative** | Dropdown to select from alternatives (only shown if alternatives exist) |
| **Give hint** | Expands to text input for re-run context |
| **Skip** | Exclude this cut from output |

### Visual Grouping

```
┌─ Demographics ───────────────────────────────────────────────────┐
│                                                                  │
│  ┌─ APP ─────────────────────────────────────────────────────┐  │
│  │ Banner: "S2a=1"  →  AI: S2b %in% c(2,3)                   │  │
│  │ [Accept] [Pick alternative ▼] [Give hint] [Skip]          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─ Specialty ───────────────────────────────────────────────┐  │
│  │ Banner: "S2=6,7"  →  AI: S2 %in% c(6,7)                   │  │
│  │ [Accept] [Pick alternative ▼] [Give hint] [Skip]          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### What to Remove

- Expression Type badges ("Direct", "From List", etc.)
- "What We Found" section (verbose AI reasoning)
- AI Concerns section (or fold into optional "Why?" link)
- Colored icons next to each action button
- Multiple badge styles (simplify to just confidence)

### What to Keep

- Confidence indicator (color-coded)
- Original expression from banner
- Proposed R expression
- All 4 actions: Accept, Pick alternative, Give hint, Skip
- Alternatives dropdown (when available)

### Header Improvement

**Current:**
> "Mapping Review Required"
> "5 of 18 columns need your attention"

**Proposed:**
> "Quick Review Needed"
> "The AI wasn't certain about 5 matches. Please confirm or correct."

### Key Files to Modify
- `src/app/pipelines/[pipelineId]/review/page.tsx` - Main review UI

---

## Known Issues (Resolved)

<details>
<summary>✅ CrosstabAgent Schema Error (Fixed Jan 16)</summary>

Azure OpenAI requires ALL properties in `required` array. Fixed by removing `.default()` from human review fields in `src/schemas/agentOutputSchema.ts`.
</details>

<details>
<summary>✅ LibreOffice Headless Conversion (Fixed Jan 16)</summary>

LibreOffice headless mode failed silently due to profile conflicts. Fixed by adding `-env:UserInstallation` flag for isolated profile per conversion in `src/agents/BannerAgent.ts`.
</details>

---

## Demo Readiness Checklist

- [x] Pipeline parallelism (Path A || Path B)
- [x] Sidebar shows in-progress pipelines
- [x] Cancel button properly stops processing
- [x] Review UI with alternatives, hints, edits
- [x] Review timing optimization (immediate after Path A)
- [x] Path B producer-consumer overlap
- [x] Tested with banner that triggers review
- [x] Review UI polish (no emojis, collapsed concerns)
- [x] Refresh resilience (picks up where you left off)
- [x] Pipeline page cancel button
- [x] Review submission timeout handling
- [x] Auto-retry for content policy errors (all agents)
- [x] Duration tracking for review-flow pipelines
- [x] Review UI redesign (Phase 5)
  - [x] Simplified card layout (banner → AI suggestion → actions)
  - [x] Group columns by banner group
  - [x] Remove verbose AI reasoning
  - [x] Remove Expression Type badges
  - [x] 4-button action bar (Accept, Pick alternative, Give hint, Skip)
