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

### Proposed State (Parallel where possible)
```
┌─ DataMapProcessor ─┐
│                    ├─→ CrosstabAgent → TableAgent → VerificationAgent → R → Excel
└─ BannerAgent ──────┘
```

### Key Observations
- **DataMapProcessor** and **BannerAgent** are independent - can run in parallel
- **CrosstabAgent** needs both outputs (datamap + banner) - must wait
- **TableAgent** needs datamap but NOT banner validation - potential parallelism?
- **VerificationAgent** needs TableAgent output - sequential dependency

### Implementation Approach
1. Use `Promise.all()` for DataMapProcessor + BannerAgent
2. Evaluate if TableAgent can start earlier (only needs datamap)
3. Update progress percentages to reflect parallel execution
4. Ensure error handling works correctly with parallel failures

### Expected Impact
- ~30-40% reduction in total pipeline time (BannerAgent is slow due to vision/OCR)
- Better demo experience - things happen faster

---

## Phase 2: Human-in-the-Loop for Banner Review

### Goal
When BannerAgent is uncertain about extraction, pause the pipeline and ask the user to review/correct before proceeding.

### Key Questions to Address

**1. When does flagging happen?**
- At the BannerAgent step, after extraction completes
- Check confidence scores on individual columns AND overall extraction
- Threshold: flag if any column has `confidence < 0.85` or `humanInLoopRequired: true`

**2. What gets flagged?**
- Columns with low confidence
- Columns where `requiresInference: true` (AI had to guess)
- Groups with ambiguous boundaries
- Filter expressions that couldn't be parsed cleanly

**3. How does the user interact?**
- Pipeline pauses after BannerAgent
- UI shows extracted banner with flagged items highlighted
- User can:
  - Approve as-is
  - Edit specific columns/expressions
  - Re-run BannerAgent with different settings
- Pipeline resumes with user-approved banner

**4. How does this affect downstream pipeline?**
- CrosstabAgent uses the user-approved banner (not raw extraction)
- All subsequent steps use the corrected data
- Pipeline summary notes that human review occurred

### Implementation Approach

1. **Add new job stage**: `banner_review_required`
2. **Create review UI**: Show extracted banner in editable format
3. **Store pending state**: Save banner extraction to allow editing
4. **Resume endpoint**: API to continue pipeline with approved/edited banner
5. **Track in summary**: Note human intervention in pipeline-summary.json

### Schema Changes
```typescript
// BannerAgent already has these fields:
confidence: number;
humanInLoopRequired: boolean;
uncertainties: string[];

// New job stages
type JobStage = ... | 'banner_review_required' | 'banner_review_complete';
```

### UI Flow
```
Upload Files → Start Pipeline → BannerAgent extracts
                                      ↓
                              confidence < threshold?
                                   ↓         ↓
                                  YES        NO
                                   ↓         ↓
                            Show Review UI   Continue
                                   ↓
                            User approves/edits
                                   ↓
                            Resume pipeline
```

---

## Phase 3: AI-Recommended Cuts

### Goal
Allow the AI to suggest additional cuts/banner columns based on the data it sees, demonstrating analytical capability.

### Use Cases
- AI notices a variable that would make a good cut (e.g., "Region" in the datamap)
- AI suggests combining or splitting existing cuts
- AI identifies potential issues with proposed cuts (e.g., low base sizes)

### Implementation Approach

1. **Prompt Engineering**: Update BannerAgent or CrosstabAgent prompt to include:
   - "Suggest additional cuts that might be valuable based on the datamap"
   - "Flag any proposed cuts that may have issues"

2. **Schema Changes**: Add optional `recommendations` field to agent output:
   ```typescript
   recommendations?: {
     suggestedCuts: Array<{
       variable: string;
       reason: string;
       confidence: number;
     }>;
     warnings: Array<{
       cutName: string;
       issue: string;
       suggestion: string;
     }>;
   }
   ```

3. **UI Display**: Show recommendations in a non-blocking way:
   - "AI suggests also cutting by Region (S3) - commonly used demographic"
   - "Warning: 'Tier 4' cut may have low base size (n < 30)"

### Where This Fits
- Could be part of BannerAgent (suggest cuts while extracting)
- Could be a separate "RecommendationAgent" that runs in parallel
- Could be part of CrosstabAgent (suggest while validating)

### Demo Value
- Shows AI is "thinking" about the data, not just executing
- Provides value-add beyond automation
- Honest about uncertainty (confidence scores, warnings)

---

## Implementation Priority

For the Bob demo, recommend this order:

1. **Phase 2 (Human-in-the-Loop)** - Most impressive for demo, shows system handles uncertainty gracefully
2. **Phase 1 (Parallelism)** - Quick win, makes demo faster
3. **Phase 3 (AI Recommendations)** - Nice to have, but more complex

---

## Open Questions

- [ ] What confidence threshold should trigger human review? (0.85? 0.90?)
- [ ] Should human review be optional or required when flagged?
- [ ] How long should we wait for human review before timing out?
- [ ] Should AI recommendations be shown proactively or only on request?
- [ ] Do we need to persist the "pending review" state across server restarts?

---

## Success Criteria

- [ ] Pipeline completes faster with parallelism
- [ ] Uncertain banners pause for review instead of producing bad output
- [ ] User can easily see and edit flagged items
- [ ] AI recommendations add visible value without being noisy
- [ ] Bob sees a system that's intelligent AND honest about its limitations
