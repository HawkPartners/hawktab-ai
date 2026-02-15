# Product Roadmap

Last updated: 2026-02-14

## Pre-Monday (Antares Demo MVP)

**Critical fixes and polish before showing to Antares:**

5. **Add Antares to WorkOS**
6. **Record demo and upload to YouTube**
7. **Schedule email to Antares with demo link and instructions on how to use the tool**
8. **Schedule a live demo with Antares (or discussion with how they've been using it)**

---

2. **CI/CD Pipeline Verification**
   - Test branch protection, quality gates, Claude PR review
   - Ensure staging → main promotion works correctly
   - **Priority:** Medium (hasn't been tested end-to-end yet)


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
