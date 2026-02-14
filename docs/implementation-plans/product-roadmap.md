# Product Roadmap

Last updated: 2026-02-14

## Pre-Monday (Antares Demo MVP)

**Critical fixes and polish before showing to Antares:**

1. **Data validation feedback improvements**
   - Better visual feedback during validation - show what's being analyzed and why
   - Replace generic "analyzing your data" with specific status: "Detecting loop structures...", "Validating variable formats...", etc.
   - Clear loading indicators

2. **Sidebar UI bug fix**
   - Long project titles overlap timestamps ("just now", "2 minutes ago")
   - Implement proper text truncation with ellipsis

3. **Cost tracking and logging (admin/owner view)**
   - Dashboard showing per-project costs
   - Track API usage, agent costs, storage costs
   - Owner-level visibility (not just per-user)

4. **General logging improvements**
   - Capture more detailed logs for debugging
   - Link agent decisions together (context graphs)
   - Make it easier to trace issues through the pipeline

---

## Post-Monday, Pre-Antares Meeting (By Wednesday)

**Important but not blocking the initial demo:**

1. **MaxDiff/Message Testing Support**
   - Update intake form: "Does this survey include messages?"
   - Support message CSV upload (enforce format) or text box entry (like environment variables)
   - Parse messages and integrate into datamap
   - VerificationAgent uses actual message text in labels
   - **Priority:** High (needed for broader Antares use cases)

2. **CI/CD Pipeline Verification**
   - Test branch protection, quality gates, Claude PR review
   - Ensure staging → main promotion works correctly
   - **Priority:** Medium (hasn't been tested end-to-end yet)

---

## Pre-Antares Meeting (Later This Month)

**Improvements to make before the formal presentation:**

1. **Loop Semantics Deep Dive Prep**
   - Document: What is a loop? How are they defined?
   - Explain: Why loop variables may differ from actual loop structure
   - Philosophy: How do we prevent double-counting?
   - Be ready to explain entity-anchored vs respondent-anchored decisions
   - **Why:** Antares will ask technical questions about our approach

2. **Enhanced HITL Review Experience**
   - Make HITL more prominent (not a warning, but an important checkpoint)
   - Show semantic interpretation: "This cut means..." in plain language
   - For loop datasets: Ask user "Iteration-linked or Respondent-level?"
   - Display alternatives with explanation of how interpretations differ
   - Let user override loop policy classifications per group
   - **Why:** User should guide semantic decisions, not just pick syntax

---

## Post-MVP (Deprioritized)

**Important but not urgent:**

1. **Visual cut discovery feedback**
   - Show users what cuts were discovered during processing
   - Display base sizes and how they were calculated
   - **Priority:** Low (nice-to-have for transparency)

2. **Configurable post-run settings**
   - Allow users to change entity/respondent classification after run completes
   - Regenerate crosstabs with different loop policy without re-running full pipeline
   - **Example:** "Location was classified as entity-anchored, but I want respondent-anchored"
   - **Priority:** Medium (saves time on iterative analysis)

3. **Remove HawkPartners branding**
   - Purge all references to "HawkPartners" from codebase
   - Fully rebrand as standalone "Crosstab AI" product
   - **Priority:** Low (post-commercialization concern)

4. **Input file cleanup**
   - Stop saving input files locally
   - All processing done in cloud (R2 storage only)
   - Purge local copies after upload
   - **Priority:** Medium (security and storage efficiency)

5. **CrosstabAgent Loop Awareness**
   - Pass loop context to CrosstabAgent
   - Agent notes when variable naming suggests iteration-linkage
   - Generate alternatives with semantic context (respondent vs entity versions)
   - **Status:** Under consideration (need to decide on approach)

---

## Notes

- Dates are fluid and will be adjusted based on progress
- Focus is on organization and prioritization, not strict deadlines
- Pre-Monday items are critical for demo quality
- HITL enhancements are key to product differentiation
