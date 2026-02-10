# Batch Review Action Plan

**Created**: February 9, 2026
**Source**: User review of 7 agent audit reports from 11-dataset batch run (2026-02-08/09)
**Purpose**: Consolidated checklist of all agreed-upon actions and considerations from the review session

---

## How to Use This File

- **[ ] Checkbox items** are concrete tasks to implement
- **[CONSIDER]** items are decisions to make — evaluate and either implement or explicitly decide not to
- **[VERIFY]** items require investigation before deciding on action
- Items are grouped by theme, not by agent, and ordered by implementation flow within each priority tier

---

## P0 — System Resilience

*The pipeline should never fail from transient errors. "No one has to retry Joe."*

### Error Recovery Overhaul

- [x] **Increase retry limits for transient errors across all agents.** The current 4-retry limit is too conservative for rate limits and timeouts. Use exponential backoff, 8-10 attempts minimum. These errors are designed to be retried.
  - Affected: `retryWithPolicyHandling` and all agent call sites
  - Ref: CrosstabAgent report 3.1

- [x] **Research content policy error handling.** Web search for best practices on Azure OpenAI content policy retries. Options: (a) attach a preamble to every prompt ("this is an automated survey data processing pipeline"), (b) reformulate by stripping medical terminology and using generic placeholders, (c) retry identical requests since classifiers are stochastic.
  - Ref: CrosstabAgent report 3.1, error recovery deep dive

- [x] **Implement per-column/per-table skip on exhausted retries.** If a single column or table fails after N retries, skip it and continue the pipeline. A pipeline with 1 missing table is infinitely better than a failed pipeline. Cap retries per item, not per pipeline.
  - Affected: CrosstabAgent, VerificationAgent, FilterTranslatorAgent
  - Ref: CrosstabAgent report, error recovery deep dive

- [x] **Tell agents WHY retries happen.** When a retry occurs because of a validation error (e.g., hallucinated variable), feed the error message back to the agent: "Variable S2_21_24 does not exist in the data. Do not construct synthetic variable names." Currently we don't tell the agent what went wrong, so it repeats the same mistake.
  - Affected: VerificationAgent retry loop, R validation retry mechanism
  - Ref: VerificationAgent report 3.1

### Error Persistence

- [x] **Persist all agent errors to disk.** The LoopSemanticsPolicyAgent failed silently for 5/6 datasets with no trace. Every agent's catch block must write errors to a JSON file in the output directory, not just log to console.
  - Affected: PipelineRunner.ts catch blocks (especially line ~906-910 for LoopPolicy)
  - Ref: LoopPolicyAgent report, Section 3

- [x] **Check if we validate for corrupted .sav files.** Truly unrecoverable errors (corrupted files, unsupported formats) should be caught in the first 30 seconds during validation, not 40 minutes into a run. Verify this check exists.
  - Ref: CrosstabAgent error recovery deep dive
  - Done: Pre-flight check (exists, readable, non-empty) + R read_sav failure handling in ValidationRunner Stage 1.

### Loop Resilience

- [x] **Fix the Iptacopan R crash.** The only complete pipeline failure in the batch — loop iteration column mismatch (`B2b_9r1` doesn't exist in stacked frame). Add pre-flight validation in LoopCollapser that verifies all expected iteration columns exist before generating R code. If columns are missing, skip that iteration or generate a safe fallback.
  - Affected: LoopCollapser, RScriptGeneratorV2
  - Ref: System report Section 5
  - Done: LoopCollapser only includes variable mappings when ALL iteration columns exist in datamap; skipped vars pass through; empty loop groups skipped.

- [x] **Add deterministic fallback for LoopSemanticsPolicyAgent failures.** If the agent fails, classify everything as respondent-anchored by default. The deterministic resolver already works across all 6 datasets. Entity-anchored only when deterministic evidence is unambiguous.
  - Ref: LoopPolicyAgent report, Claude's notes
  - Done: createRespondentAnchoredFallbackPolicy(); fallbackApplied/fallbackReason in schema + persisted JSON for UI surfacing.

- [ ] **Research and anticipate additional failure modes.** Deep web search for Azure rate limiting edge cases, context window overflow patterns, R execution edge cases. Proactively fix before they hit us.
  - Ref: System report, User Thoughts

---

## P0 — Context Reduction

*Feed agents what they need, not everything we have. This is the single highest-leverage optimization.*

### VerificationAgent Context (83% of pipeline cost)

- [ ] **Trim survey markdown to relevant section only.** Instead of sending the full survey to every verification call, send only the section containing the question being verified. The agent already receives per-table datamap context — the full survey is mostly noise.
  - Affected: VerificationAgent call site in PipelineRunner, context builder
  - Ref: VerificationAgent report, context reduction section

- [ ] **Verify we're not sending excess datamap variables.** We should already be showing per-variable context. Confirm we're not leaking the full datamap.
  - Ref: VerificationAgent report

### FilterTranslatorAgent Context (8.6% of pipeline cost)

- [ ] **Implement datamap pruning per rule.** The FilterTranslator has a 100:1 input-to-output token ratio — each call sends 60-70K tokens of datamap but produces 500-1000 tokens. Prune to: (1) variables mentioned in the rule's appliesTo, (2) variables in translationContext, (3) all h*/d* hidden/derived variables, (4) same-prefix variable families.
  - Create: `pruneDatamapForRule(rule, verboseDataMap)` function
  - This is more aggressive than CrosstabAgent pruning because the SkipLogicAgent already tells you exactly which variables matter.
  - Ref: FilterTranslator report 3.7, 4.3

### CrosstabAgent Context (2.7% of pipeline cost)

- [ ] **Pre-filter datamap before sending to CrosstabAgent.** Parse each column's `original` expression to extract referenced variable names. Include those + same-prefix families + all h*/d* variables + all screeners (S*). Less aggressive than FilterTranslator pruning since the agent could plausibly find a better variable than what the banner says.
  - Ref: CrosstabAgent report 4.5

---

## P0 — Skip Logic & Filter Translation Quality

*translationContext is the #1 lever for improving filter quality.*

### Strengthen translationContext

- [ ] **Clarify the distinction between `conditionDescription` and `translationContext` in the SkipLogicAgent prompt.** Even the product owner finds the difference confusing. Make it crystal clear:
  - `conditionDescription`: plain-text description of the condition — who sees this question and why
  - `translationContext`: everything the downstream FilterTranslatorAgent needs to translate this rule — answer option mappings, variable relationships, coding tables
  - Ref: SkipLogicAgent report 3.3, FilterTranslator report

- [ ] **Tell the SkipLogicAgent to be dramatically more verbose in both fields.** The FilterTranslator has zero survey context. The SkipLogicAgent should write as if the next agent has never seen the survey — because it hasn't. Write out answer options. Create mapping tables. Explain the intent, not just the variable name.
  - Specifically add prompt guidance: "The downstream agent has NO survey context. Over-provide. Write out answer option labels. Create parent-child mapping tables. Explain in a way that someone with no survey context could understand."
  - Ref: SkipLogicAgent report 3.1, FilterTranslator report 3.1

- [ ] **Require explicit code mappings for conditional response sets.** When a rule says "show Q20b options based on Q20a selection," the SkipLogicAgent MUST include the mapping: `Q20a=1 → Q20b codes [1,2,3]; Q20a=2 → Q20b codes [4,5,6]`. This is the #1 source of low-confidence filters.
  - Ref: FilterTranslator report 3.1, 4.1

- [ ] **Require row-to-variable mapping for row-level rules.** When a rule says "show rows where Q8 > 0," the agent MUST document which rows map to which variables if the survey provides that information.
  - Ref: SkipLogicAgent report 6.1.4

### Add Column-Level Rule Support

- [ ] **Add column-level guidance to the SkipLogicAgent prompt.** The schema only has `table-level` and `row-level`. Column-level visibility (e.g., "show donor-type columns where patient count > 0") gets misclassified as row-level. Add guidance: use ruleType "row-level" but note in conditionDescription that this is column-level logic, and include the column-to-condition mapping in translationContext.
  - Ref: SkipLogicAgent report 3.2 (GVHD misclassification)

### FilterTranslator Prompt Improvements

- [ ] **Reframe confidence 0.00 in FilterTranslator.** Confidence 0.00 should mean "I genuinely cannot figure out how to filter this population" — not "the variable name the SkipLogicAgent gave me doesn't exist." If the named variable doesn't exist but another achieves the same filtering, use it at confidence 0.70 and explain why.
  - Ref: FilterTranslator report 3.3

- [ ] **Add guidance on hidden variable disambiguation.** When a hidden variable has no labels (hREFERRER = 1 or 2, but which?), the agent should consider using a labeled survey variable instead — less minimal but auditable. Prompt the agent to weigh pros/cons: simple but opaque vs. longer but verifiable.
  - Ref: FilterTranslator report 3.2

- [ ] **Add column-to-row donor mapping guidance.** When grid columns correspond to categories from another question's rows and the counts differ, the agent cannot assume 1:1 mapping. Flag for review with confidence below 0.50 unless translationContext provides the explicit mapping.
  - Ref: FilterTranslator report 4.6

### Hidden Variable Value Labels

- [VERIFY] **Check if RDataReader extracts value labels for h* and d* variables.** If it does, the hREFERRER ambiguity resolves itself deterministically. If it doesn't, add this — it's low-hanging fruit.
  - Ref: FilterTranslator report 4.2

---

## P0 — Table Count Management

*Before tables reach the VerificationAgent, ensure only necessary tables proceed.*

- [ ] **Implement pre-verification table count gate.** After FilterApplicator but before VerificationAgent:
  - Below ~100 tables: pass all through, no intervention
  - Above 100 tables: deterministically identify and remove admin/metadata tables (IDs containing `_meta`, `_changes`, `_placeholder`, `_audit`, `_trailer`)
  - Above 100 tables: collapse unnecessary splits — if a split produces expressions where all split variables don't exist in the datamap, recombine using `splitFromTableId` traceability
  - Ref: VerificationAgent report, System report Rec #9

- [CONSIDER] **Switch to minimal model for large datasets.** When table count exceeds the threshold, swap VerificationAgent to minimal reasoning effort. Tables still get processed, just more cheaply. Alternative to dropping tables.
  - Ref: VerificationAgent report

- [VERIFY] **Investigate WHY UCB Caregiver ballooned from 64 to 262 tables.** The survey doesn't need 205 tables. Something in the split/generation pipeline is creating redundancy. Trace the table expansion to understand the root cause before building mitigations.
  - Ref: VerificationAgent report

### Pre-Verification Risk Assessment

- [ ] **Implement deterministic pre-flight risk assessment.** Runs after FilterApplicator, before VerificationAgent (~minute 10). Costs zero API calls — purely deterministic. Log to `pipeline-preflight.json`. For medium+ risk, display a warning with estimated cost/duration.
  - Signals: variable count, survey size, loop presence, skip rule count, table count pre/post split
  - Risk tiers: Low (<100 tables), Medium (100-150), High (>150), Critical (>200 or loop mismatch)
  - V1: warning only. Future: automatic mitigations.
  - Ref: System report, User-Proposed Enhancement

---

## P1 — Prompt Hygiene Sweep

*Every agent gets a fresh production prompt. Remove contradictions, align with schemas.*

- [ ] **Prompt rotation across all agents.** After this review: current production prompts become alternatives. Write fresh production prompts that align with current schemas, incorporate learnings from this review, and remove contradictions.
  - All 6 agents: BannerAgent, CrosstabAgent, SkipLogicAgent, FilterTranslatorAgent, VerificationAgent, LoopSemanticsPolicyAgent
  - Ref: CrosstabAgent report 3.6

- [ ] **Remove confidence scoring contradictions.** The CrosstabAgent prompt says "exact match = 0.95" but also "multiple candidates = max 0.75." These conflict when an exact match also has alternatives. Add clear precedence rules.
  - Ref: CrosstabAgent report 3.5, 4.7

- [ ] **Simplify confidence scoring across all agents.** Replace granular rubrics with fewer tiers and clearer boundaries. The distinction between 0.90 and 0.95, or 0.85 and 0.88, causes token-wasting deliberation without changing downstream behavior. "ONE penalty applies. Pick the LOWEST applicable tier and move on."
  - [CONSIDER] What granularity is actually useful? Per-column? Per-group? Per-extraction? Fewer tiers = less agent deliberation.
  - Ref: BannerAgent report 3.2, CrosstabAgent report 3.4/3.5/4.4

- [ ] **Require scratchpad usage in LoopSemanticsPolicyAgent prompt.** The model never invoked the scratchpad despite it being available. Add explicit instruction requiring scratchpad entries before output.
  - Ref: LoopPolicyAgent report

- [ ] **Add "Neutral is never a NET" rule to VerificationAgent prompt.** A NET must aggregate 2+ distinct answer values. A single scale point like "Neutral" or "Neither agree nor disagree" is a regular row, never a NET.
  - Ref: VerificationAgent report 3.4

- [ ] **Standardize 7-point scale box score rules in VerificationAgent prompt.** Default to T2B (top 2), M3B (middle 3), B2B (bottom 2) for 7-point scales. Only use T3B/B3B for scales wider than 7 points. Optionally show both: primary grouping (T2B/M3B/B2B) + secondary block below a category header break (T3B/B3B).
  - Ref: VerificationAgent report 3.11

- [ ] **Add binning best practices to VerificationAgent prompt.** Light guidance for consistency across similar variables within the same dataset. Not critical (regeneration is the real fix), but helps.
  - Ref: VerificationAgent report 3.10

- [ ] **Strengthen variable hallucination guard in VerificationAgent prompt.** Add: "You may ONLY reference variable names that appear in the datamap context provided. Do NOT construct, infer, or synthesize variable names."
  - Ref: VerificationAgent report 3.1

- [CONSIDER] **Write more aggressive/detailed prompts now that context inputs are being trimmed.** The freed-up context budget from survey/datamap reduction means we can write longer, more detailed system prompts. Test this: copy current prompts as alternatives, write verbose production prompts, compare quality.
  - Ref: VerificationAgent report, context reduction section

---

## P1 — Schema & Field Cleanup

*Remove dead weight from agent responsibilities. If the postpass handles it, don't ask the agent to do it.*

### Remove Dead Fields

- [ ] **Remove `statisticalLettersUsed` from `ExtractedBannerStructureSchema`.** Dead data — never consumed by any downstream agent or processor.
  - Ref: BannerAgent report 3.8

- [ ] **Remove `notes` section from BannerAgent output.** Extra bloat. Calculation guidance (T2B, M3B, B2B) is inherited by the VerificationAgent from coded variables. Not needed for MVP.
  - Affects downstream schema
  - Ref: BannerAgent report, notes section

- [CONSIDER] **Remove `changes` array from VerificationAgent schema.** Extra work for the agent with minimal value. Can detect changes deterministically by diffing input vs output. Frees agent intelligence for what actually matters.
  - Ref: VerificationAgent report 3.9

- [CONSIDER] **Remove `confidence` and `userSummary` from VerificationAgent schema (or make them deterministic).** Never populated across any dataset. If we want per-table confidence, compute it deterministically (postpass fixes applied? NET rows created? baseText populated?). `userSummary` belongs in the regeneration flow, not initial pipeline.
  - Ref: VerificationAgent report 1.5

### Clarify Field Semantics

- [ ] **Clarify `filterValue` vs `netComponents` for T2B/B2B rows.** T2B IS a NET — it should have NET components. The distinction isn't clear even to the product owner. Make the instructions explicit about what goes where. Either require `netComponents` on T2B/B2B rows, or infer them deterministically from `filterValue` in a postpass.
  - Ref: VerificationAgent report 3.6

### Postpass Offloading

- [CONSIDER] **Move indentation entirely to postpass.** The orphan indent reset accounts for 81.5% of all postpass fixes (1,001 out of 1,227). Rather than trying to teach the agent correct indentation, remove `indent` from agent responsibility entirely and let the deterministic postpass handle it. Eliminates an entire error class.
  - Ref: VerificationAgent report 3.2, 4.2

- [ ] **Add deterministic duplicate tableId resolution to postpass.** If duplicate tableIds occur, append `_2`, `_3` suffix. But first trace WHY duplicates are generated — this shouldn't happen.
  - [VERIFY] How does a duplicate tableId get generated? Trace the logic.
  - Ref: VerificationAgent report 3.5

- [ ] **Add deterministic recombination for useless splits.** If a FilterApplicator split produces expressions where all split variables don't exist in the datamap, recombine the parts back together using `splitFromTableId` traceability.
  - Ref: FilterTranslator report 3.4

---

## P1 — Agent Architecture

### BannerGenerateAgent Separation

- [ ] **Move BannerGenerateAgent to its own folder.** Create `src/prompts/bannerGenerate/` with `production.ts` and `alternative.ts`. The BannerAgent and BannerGenerateAgent are fundamentally different agents doing different jobs. The current coupling in `src/prompts/banner/` is confusing.
  - Ref: BannerAgent report

### Banner Routing

- [ ] **Add `filtersExist` flag to BannerAgent output.** When a banner document has group names but no filter expressions (like Leqvio-Seg-HCP), set `filtersExist: false`. The pipeline should route this to the BannerGenerateAgent or CrosstabAgent to figure out the actual expressions. This is a routing problem, not an extraction failure.
  - Ref: BannerAgent report 3.1

### LoopSemanticsPolicyAgent Optimization

- [CONSIDER] **Skip LoopSemanticsPolicyAgent when no entity signals exist.** If no banner cuts reference iteration-linked variables, the answer is always "all respondent-anchored." A deterministic pre-check could save the API call. Extends the existing gate (which already skips non-loop datasets) one step further.
  - Ref: LoopPolicyAgent report, P3

---

## P1 — Base Transparency

*Every table should tell the user who the base is.*

- [ ] **Ensure every table has a clear, human-readable base description.** Currently `baseText` is 36-77% missing depending on dataset. When populated, it sometimes contains raw filter expressions instead of readable descriptions. The base should always say "Respondents who [condition]" — never "Show Leqvio row when A3a > 0."
  - Affected: VerificationAgent prompt, possibly FilterTranslatorAgent output
  - Ref: SkipLogicAgent broader point, VerificationAgent report 1.5

- [ ] **Track applied filters through the system.** When skip logic filters are applied on top of the base filter, the table's base description should reflect ALL applied filters so the user knows exactly who they're looking at. "This is only respondents who [base condition] AND [skip logic condition]."
  - Ref: SkipLogicAgent report, broader point on bases

---

## P2 — Quality Improvements

### Survey Markdown Conversion

- [ ] **Audit survey markdown conversion for additional structure capture.** Look at the conversion and ask: what else should we preserve?
  - Highlighting
  - Complex grid structures
  - Section breaks / section headers
  - Bold/italic for instructions
  - Pipe logic (render distinctly — maybe a specific format/notation)
  - Termination criteria (visually distinct)
  - This benefits ALL agents, not just verification.
  - Ref: VerificationAgent report, survey markdown section

### SkipLogic Chunking

- [CONSIDER] **Take another pass at chunked mode prompt language.** The chunked mode was built quickly. Review the prompt for optimal guidance, especially around what the agent should do when it suspects a rule exists but the evidence is in another chunk.
  - Ref: SkipLogicAgent report, chunked mode

- [CONSIDER] **Cap maximum number of chunks instead of tuning threshold.** Maybe max 10 chunks is a better lever than adjusting the 40KB character threshold. Prevents extreme cases (CART had 16 chunks).
  - Ref: SkipLogicAgent report, chunked mode

- [CONSIDER] **Review deduplication behavior.** Dedup currently gets appended to the top of every run. Is this the right design? Worth flagging but may be inherent.
  - Ref: SkipLogicAgent report, chunked mode

### SkipLogic Architecture

- [CONSIDER] **Two-pass approach for skip logic.** Instead of one pass that extracts AND classifies rules, maybe: Pass 1 captures all rules the agent sees (everything — gates, column-level, row-level, table-level). Pass 2 classifies each one. The system deterministically decides which to apply. This might produce better coverage since the agent isn't filtering while extracting.
  - Ref: SkipLogicAgent report 3.2

- [CONSIDER] **Provide respondent counts per variable to SkipLogicAgent or FilterTranslator.** Actual R data (not just the survey) could help the agent understand whether filtering is already happening as expected. Maybe more of a FilterTranslatorAgent input than SkipLogicAgent.
  - Ref: SkipLogicAgent report, overall impression

### BannerGenerateAgent Role

- [CONSIDER] **Should BannerGenerateAgent give plain text guidance instead of R expressions?** Currently it produces concrete filter expressions (`Q3==1`, `S2 %in% c(1,2)`) — but that's the CrosstabAgent's job. Maybe it should describe what to cut in plain text and let the CrosstabAgent figure out the syntax. The two agents are bleeding into each other.
  - Ref: BannerAgent report 3.5

### SkipLogic Duplicate Rules

- [ ] **Improve duplicate rule detection in chunked mode.** The current overlapping-appliesTo threshold (70%) is fragile. Consider making the schema structure more conducive to deterministic deduplication — each field distinct enough that collisions are easily caught.
  - Ref: SkipLogicAgent report 3.6

---

## Post-Implementation

*Things to do after the above changes are implemented and a clean batch run is completed.*

- [ ] **Re-run the full batch with all fixes applied.** This is the validation step. Compare against the current batch results.

- [ ] **Re-evaluate LoopSemanticsPolicyAgent with clean data.** The current report is tainted by mid-run code changes. Need a clean run to assess actual performance.

- [ ] **A/B test production vs alternative prompts.** After the prompt rotation, run 3-4 representative datasets with each version and compare: R validation pass rate, postpass fix counts, table quality, cost.

- [ ] **Pull scratchpad themes into prompts.** After reviewing scratchpad traces from the clean batch run, identify recurring reasoning patterns and codify them as permanent prompt rules. This is how prompts improve over time.

---

## Decisions Log

*Track decisions made on [CONSIDER] items here.*

| Item | Decision | Date | Rationale |
|------|----------|------|-----------|
| | | | |

---

*This plan consolidates the User Thoughts from all 7 agent audit reports reviewed on February 9, 2026. Source reports are in `outputs/agent-reports/`.*
