# Batch Review Action Plan

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

- [x] **Research and anticipate additional failure modes.** Deep web search for Azure rate limiting edge cases, context window overflow patterns, R execution edge cases. Proactively fix before they hit us.
  - Ref: System report, User Thoughts
  - Done: Deep dive completed 2026-02-10. Audited full codebase error handling + web research on Azure OpenAI, R/haven, and JSON serialization edge cases. Findings below.

### Anticipated Failure Modes (from deep dive research)

*Proactive hardening from Azure OpenAI, R execution, and data serialization research. Items ordered by likelihood of hitting us.*

#### R Execution & Data Integrity

- [x] **Add timeout to RDataReader spawn.** `src/lib/validation/RDataReader.ts:55` uses raw `spawn()` with no timeout. If R hangs on a corrupted/huge .sav file, the pipeline blocks indefinitely. Every other R execution has a timeout; this one doesn't.
  - Fix: Add `setTimeout` + `proc.kill('SIGTERM')` with 60s cap, then `SIGKILL` after 5s grace.
  - Affected: `RDataReader.ts` `executeRScript()` function
  - Done: 60s SIGTERM → 5s grace → SIGKILL. `timedOut` flag for clear error message.

- [x] **Sanitize NaN/Inf before JSON serialization.** `write_json()` in `RScriptGeneratorV2.ts:2080-2086` uses default `na = "null"`, which silently converts NaN (0/0 from zero-respondent cells), Inf (division by zero), and -Inf to `null` — indistinguishable from legitimate missing data (NA). An all-NaN column can be dropped entirely by jsonlite (known bug, jsonlite issue #223).
  - Fix: Add R sanitization pass before `write_json()`: replace NaN/Inf with 0, log a warning with the affected table/cut. This preserves the data while flagging the anomaly.
  - Affected: `RScriptGeneratorV2.ts` output section
  - Done: `sanitize_for_json()` recursive R helper + `round_half_up()` NaN/Inf guard. Called before every `write_json()`.

- [x] **Detect SIGKILL in R error messages.** When macOS kills R for memory pressure, `error.signal === 'SIGKILL'` but stderr is empty. Current error persistence logs "R script failed (code null):" with no useful info.
  - Fix: Check `error.signal` in R execution catch blocks. If `SIGKILL`, log "R process killed by OS (likely out of memory)." If `SIGSEGV`, log "R process crashed (segfault in native code — possibly corrupted .sav or haven bug)."
  - Affected: `PipelineRunner.ts` R execution, `ValidationOrchestrator.ts`
  - Done: `describeProcessSignal()` helper in both files. Maps SIGKILL/SIGSEGV/SIGTERM/SIGABRT to descriptions. Enriches logs + persisted error meta.

- [x] **Detect R validation crash orphaning tables.** When the entire R validation script crashes (not individual tables), the result is `{}`. The retry loop in `ValidationOrchestrator.ts` only iterates over entries in `initialResults`, so tables not in the results aren't marked as failed — they silently disappear from the pipeline.
  - Fix: After R validation, compare table count in results vs expected tables. If results have fewer tables than expected, log a warning with the missing table IDs and treat them as failed (eligible for retry).
  - Affected: `ValidationOrchestrator.ts` post-validation check
  - Done: Compares returned vs expected table IDs. Missing tables pushed to `failedTables` → flow into retry loop. Persists warning with crash type (full vs partial).

- [x] **Add encoding resilience for .sav files.** SPSS files created on Windows use Windows-1252 encoding. Haven 2.4+ has stricter iconv validation that can crash on encoding mismatches. International surveys and files from older SPSS versions are especially vulnerable. When encoding doesn't crash, garbled labels (accented letters, em-dashes, curly quotes) flow through silently.
  - Fix: Wrap `read_sav()` in a tryCatch that retries with `encoding = "latin1"` on encoding errors. Log a warning when fallback encoding is used. Not perfect (mixed-encoding files remain unsolvable), but catches the most common case.
  - Affected: `RDataReader.ts` R script template, `RScriptGeneratorV2.ts` data loading section
  - Done: All 5 `read_sav()` call sites wrapped (RDataReader×2, RScriptGeneratorV2, RValidationGenerator×2, DistributionCalculator).

- [x] **Add weight variable sanity checks.** Current R code handles NA weights (`weight_vec[is.na(weight_vec)] <- 1.0`) but does not check for negative weights (produce nonsensical results without warning), zero weights (produce NaN in weighted mean), or extreme weights (>10x median, which amplify individual responses disproportionately). Rare in well-run surveys, but possible with corrupted weight variables or calibration failures.
  - Affected: `RScriptGeneratorV2.ts` weight handling section
  - Done: Negative weights → set to 0 with warning. Zero weights → warn only. Extreme (>10x median) → warn only with count and max.

#### Azure OpenAI API

- [x] **Add circuit breaker for cascading API failures.** If Azure is down, every agent exhausts all 10 retries independently. With 50+ tables in VerificationAgent alone, that's 500 failed API calls before the pipeline gives up. For overnight batch runs, this wastes hours.
  - Fix: Add a shared failure counter in `retryWithPolicyHandling.ts`. If 3 consecutive calls across the pipeline fail with the same error classification (e.g., `rate_limit` or `transient`), emit a circuit-breaker event. PipelineRunner catches this and aborts early with a clear message: "Azure OpenAI appears unavailable — aborting after N consecutive failures."
  - Affected: `retryWithPolicyHandling.ts` (shared state), `PipelineRunner.ts` (catch + abort)
  - Done: `CircuitBreaker` singleton in `src/lib/CircuitBreaker.ts`. Tracks consecutive failures by classification. Trips after 3 consecutive rate_limit/transient errors → aborts pipeline signal. Any success resets counter.

- [x] **Log 429 response bodies for debugging.** Azure returns three distinct 429 types — quota exceeded, regional capacity, and transient scaling — each requiring different backoff. We currently classify all as `rate_limit`. The response body contains the distinguishing text but we don't persist it.
  - Fix: When a 429 is caught, persist the response body (or at least the error message) in the error log. Not changing retry behavior now, but this gives us the data to tune backoff later if overnight runs start failing.
  - Affected: `retryWithPolicyHandling.ts` `onRetryWithContext` callback
  - Done: `summarizeErrorForRetry` now returns `{ summary, responseBody? }`. 429 bodies logged via `console.warn` and exposed on `RetryContext.lastResponseBody` and `RetryResult.lastResponseBody`.

- [x] **Check `finish_reason` for output truncation.** Azure defaults `max_tokens` to 4,096 for GPT-4o. If output exceeds this, JSON is silently truncated. The AI SDK catches this as `JSONParseError` (retryable), but all retries fail identically if the model consistently generates too much. Also: with reasoning models, `max_completion_tokens` is shared between reasoning and visible output — high reasoning effort can starve the actual response.
  - Fix: After each `generateText()` call, check for `finish_reason === "length"`. If detected, log distinctly ("Output truncated — model generated more tokens than max_tokens allows") and consider auto-increasing `max_tokens` on retry. This distinguishes "model output too big" from "model returned bad JSON."
  - Affected: All agent call sites, potentially `retryWithPolicyHandling.ts`
  - Note: Azure's Responses API rate limit headers are confirmed broken (return -1 and 0) — do NOT add header parsing.
  - Done: Tracks `consecutiveOutputValidationErrors` in retry loop. `possibleTruncation` hint (true when >=2 consecutive) on `RetryContext`. VerificationAgent + CrosstabAgent escalate `maxOutputTokens` to full model limit when truncation detected.

- [x] **Add pipeline-level AbortSignal + timeout.** All 7 agents have AbortSignal plumbing, but PipelineRunner never creates or passes one. No way to abort a running pipeline (short of killing the process), and no overall pipeline timeout. A single hung `generateText()` call blocks indefinitely.
  - Fix: Create an `AbortController` in PipelineRunner with a configurable overall timeout (default: 90 minutes). Pass the signal to all agent calls. On timeout, persist the error and save whatever partial output exists.
  - Affected: `PipelineRunner.ts` `runPipeline()`, all agent call sites
  - Done: `PipelineOptions.abortSignal` + `timeoutMs` (default 90 min). PipelineRunner creates AbortController, links external signal, sets timeout. Signal threaded to all 7 agent call sites. Cleanup on all 6 exit paths.

- [x] **Add Azure deployment health check at pipeline start.** A simple test API call (e.g., "respond with OK") before starting a 45-minute run could catch deployment issues, misconfigured API keys, or quota exhaustion in the first 5 seconds. Currently the pipeline discovers these 10-15 minutes in, after BannerAgent and survey processing.
  - Affected: `PipelineRunner.ts` pre-flight section
  - Done: `src/lib/pipeline/HealthCheck.ts` deduplicates 7 agents → unique deployments, probes each with `generateText({ maxRetries: 0 })`. 15s timeout. Fails fast before file discovery. `SKIP_HEALTH_CHECK=true` to bypass.

#### Batch Pipeline

- [x] **Add per-dataset timeout to batch pipeline.** If one dataset hangs (R OOM on a huge .sav, stuck API call), the entire overnight batch stalls. No mechanism to timeout a single dataset and proceed to the next.
  - Fix: Wrap each `runPipeline()` call in a `Promise.race` with a configurable timeout (default: 95 minutes). On timeout, abort the pipeline, record the error, and continue to the next dataset.
  - Affected: `scripts/batch-pipeline.ts`
  - Done: `--timeout=N` flag (default 95 min). Creates AbortController per dataset, passes to `runPipeline()` via `abortSignal`. `Promise.race` with timeout promise as safety net (PipelineRunner's 90-min timeout fires first normally).

- [x] **Add fail-fast logic to batch pipeline.** If Azure quota is exhausted, all 11 datasets fail identically — wasting the entire run time. No "abort if N consecutive datasets fail" logic.
  - Fix: If 3 consecutive datasets fail with the same error pattern (e.g., all rate-limited), abort the batch early with a summary of what happened. Still generate the batch summary for completed datasets.
  - Affected: `scripts/batch-pipeline.ts`
  - Done: `--fail-fast=N` flag (default 3). `FailFastTracker` with `classifyBatchError()` pattern matching (rate_limit, timeout, circuit_breaker, policy, transient, health_check, unknown). Any success resets counter.

- [x] **[CONSIDER → IMPLEMENTED] Add batch resume capability.** If a batch run is interrupted (machine restarts, Ctrl+C), the entire batch must be re-run from scratch. A simple `--resume` flag that skips datasets with existing output directories (checking for `pipeline-summary.json`) would save hours on partial failures.
  - Affected: `scripts/batch-pipeline.ts`
  - Done: `--resume` flag. `checkResume()` scans `outputs/<name>/pipeline-*/pipeline-summary.json`, validates JSON parse (dataset + timestamp fields required). Skipped datasets show as `SKIP` in summary with data from existing output.

- [x] **[CONSIDER → IMPLEMENTED] Add SIGINT handler for graceful shutdown.** Pressing Ctrl+C during a pipeline run could leave R subprocesses orphaned and output directories incomplete. A handler that catches SIGINT, kills child processes, and writes partial results would be cleaner.
  - Affected: `scripts/batch-pipeline.ts`
  - Done: SIGINT/SIGTERM handlers. First signal aborts current dataset's AbortController + sets `shuttingDown` flag (loop breaks at next iteration). Second signal force-exits. Partial batch summary generated for completed datasets. Handlers cleaned up after loop.

#### Known Non-Issues (researched, already covered or not actionable)

- **Content policy false positives**: Already handled via `RESEARCH_DATA_PREAMBLE`, `sanitizeForAzureContentFilter`, and policy-safe prompt variants. Pharma terminology is the main trigger — our existing mitigations are solid.
- **Token counting accuracy**: tiktoken underestimates by 10-30% vs actual Azure consumption (tool schemas, chat formatting, structured output schema all consume hidden tokens). Our 60% guardrail in `inputValidation.ts` provides sufficient margin. No tokenizer dependency needed.
- **`Retry-After` headers**: Microsoft confirmed these are broken on the Responses API (return -1 and 0). Our fixed exponential backoff with jitter is the correct approach. Do NOT add header parsing.
- **Azure API version**: Pinned to `2025-01-01-preview`. Structured output requires `2024-08-01-preview` or later — we're safe.
- **Haven tagged NA values**: Default `user_na = FALSE` safely converts SPSS user-defined missing values to R `NA`. Our `as.vector(col)` in RDataReader strips haven attributes. Safe as long as nobody adds `user_na = TRUE`.
- **Azure structured output schema limits**: 100 max properties, 5 levels nesting, `additionalProperties: false` required. Our Zod schemas comply. Azure enforces stricter validation than direct OpenAI — schemas that work on `api.openai.com` may fail on Azure.

---

## P0 — Context Reduction

*Feed agents what they need, not everything we have. This is the single highest-leverage optimization.*

### VerificationAgent Context (83% of pipeline cost)

- [REJECTED] **Trim survey markdown to relevant section only.** Instead of sending the full survey to every verification call, send only the section containing the question being verified. The agent already receives per-table datamap context — the full survey is mostly noise.
  - Affected: VerificationAgent call site in PipelineRunner, context builder
  - Ref: VerificationAgent report, context reduction section

- [REJECTED] **Verify we're not sending excess datamap variables.** We should already be showing per-variable context. Confirm we're not leaking the full datamap.
  - Ref: VerificationAgent report

### FilterTranslatorAgent Context (8.6% of pipeline cost)

- [REJECTED] **Implement datamap pruning per rule.** The FilterTranslator has a 100:1 input-to-output token ratio — each call sends 60-70K tokens of datamap but produces 500-1000 tokens. Prune to: (1) variables mentioned in the rule's appliesTo, (2) variables in translationContext, (3) all h*/d* hidden/derived variables, (4) same-prefix variable families.
  - Create: `pruneDatamapForRule(rule, verboseDataMap)` function
  - This is more aggressive than CrosstabAgent pruning because the SkipLogicAgent already tells you exactly which variables matter.
  - Ref: FilterTranslator report 3.7, 4.3

### CrosstabAgent Context (2.7% of pipeline cost)

- [REJECTED] **Pre-filter datamap before sending to CrosstabAgent.** Parse each column's `original` expression to extract referenced variable names. Include those + same-prefix families + all h*/d* variables + all screeners (S*). Less aggressive than FilterTranslator pruning since the agent could plausibly find a better variable than what the banner says.
  - Ref: CrosstabAgent report 4.5

### Fine-Line Context Optimization Blueprint (Audit — 2026-02-10)

*Goal: reduce token load without removing context that drives correct decisions.*

#### Current Context Audit (what is happening now)

- **VerificationAgent:** per-table datamap excerpt is already narrow, but we still pass **full survey markdown** to every table call (`verifyAllTablesParallel` → `verifyTable`). This is the biggest context inefficiency in the pipeline.
- **FilterTranslatorAgent:** per-rule processing is good, but each rule call gets the **entire datamap** via `formatFullDatamapContext(verboseDataMap)`. This is often 100:1 input-to-output token ratio.
- **CrosstabAgent:** processes one banner group at a time (good), but each group still receives the full `agentDataMap`.
- **SkipLogicAgent:** already has robust chunking + overlap + global outline. This is the strongest existing pattern and should be treated as the reference architecture.
- **LoopSemanticsPolicyAgent:** already uses focused `datamapExcerpt`; this is also a good reference pattern for scoped context delivery.

#### Recommended Context Contract (3 layers)

For each agent call, send context in 3 explicit layers:

1) **Core context (required):** directly referenced entities only  
2) **Neighbor context (limited):** related siblings/parents/children likely needed for disambiguation  
3) **Global skeleton (tiny):** compact outline for orientation, not full payload  

This preserves useful peripheral context while removing long-tail noise.

#### Agent-Specific Strategy

- **VerificationAgent (most aggressive trimming)**
  - **Core:** table JSON + table variable datamap entries (already done).
  - **Neighbor:** NET component variables + same-question variable siblings if available.
  - **Global skeleton:** compact survey outline (question IDs + short headings).
  - **Survey text payload:** replace full survey with **question-local section** (target question, nearby instructions, adjacent question boundary context).
  - **Escalation trigger:** if question cannot be located, repeated retries on the same table, or low-confidence/fallback behavior, re-run that table with expanded survey window (or full survey as last resort).
  - **Implementation note:** reuse existing `extractQuestionSection()` + `surveyChunker` utilities; do not invent a separate parsing stack.

- **FilterTranslatorAgent (balanced trimming)**
  - **Core seeds:** `rule.appliesTo`, variables explicitly mentioned in `translationContext`, and any variables parsed from rule text.
  - **Neighbor expansion:** same-prefix family variables, parent/child siblings, and all relevant hidden/admin variants (`h*`, `d*`) tied to seeded families.
  - **Always include:** compact typed index of all variable names (`column -> normalizedType`) so agent can verify candidates exist even when full labels are omitted.
  - **Escalation trigger:** unresolved mapping, low confidence, or deterministic validation failures (invalid variables) after retry.
  - **Fallback path:** widen only to affected families first; full datamap only as terminal fallback.

- **CrosstabAgent (conservative trimming)**
  - **Core:** variables directly referenced by group column `original` expressions.
  - **Neighbor:** screeners + same-prefix family + h/d variants.
  - **Global skeleton:** compact variable index.
  - Keep less aggressive than FilterTranslator because Crosstab still benefits from discovering better candidate mappings than banner text alone.

#### Safety Rails (must-have to protect quality)

- **Deterministic expansion ladder:** local → family-level → full context. Never jump straight to full unless retries indicate true ambiguity.
- **Context telemetry per call:** log char/token size of each context layer and whether escalation occurred.
- **Outcome tagging:** store whether final successful output required expanded context; use this to tune pruning rules with real evidence.
- **No silent regressions:** gate rollout behind env flags per agent and compare against current baseline in batch runs.

#### Rollout Order

1. **VerificationAgent survey windowing first** (largest cost lever, lowest semantic risk)  
2. **FilterTranslator datamap pruning + typed global index**  
3. **Crosstab moderate datamap pruning**  
4. Promote defaults only after batch comparison shows cost reduction with no quality regression

---

## P0 — Skip Logic & Filter Translation Quality

*translationContext is the #1 lever for improving filter quality.*

### Strengthen translationContext

- [x] **Clarify the distinction between `conditionDescription` and `translationContext` in the SkipLogicAgent prompt.** Even the product owner finds the difference confusing. Make it crystal clear:
  - `conditionDescription`: plain-text description of the condition — who sees this question and why
  - `translationContext`: everything the downstream FilterTranslatorAgent needs to translate this rule — answer option mappings, variable relationships, coding tables
  - Ref: SkipLogicAgent report 3.3, FilterTranslator report
  - **Done:** Replaced `<translation_context_guidance>` section in alternative prompt with sharp field distinction and role-based framing.

- [x] **Tell the SkipLogicAgent to be dramatically more verbose in both fields.** The FilterTranslator has zero survey context. The SkipLogicAgent should write as if the next agent has never seen the survey — because it hasn't. Write out answer options. Create mapping tables. Explain the intent, not just the variable name.
  - Specifically add prompt guidance: "The downstream agent has NO survey context. Over-provide. Write out answer option labels. Create parent-child mapping tables. Explain in a way that someone with no survey context could understand."
  - Ref: SkipLogicAgent report 3.1, FilterTranslator report 3.1
  - **Done:** Added 6-category "write for a blind downstream agent" verbosity guidance with concrete Not/Yes examples for each category.


### Add Column-Level Rule Support

**Full implementation plan:** [`column-level-rule-support.md`](./column-level-rule-support.md)

- [x] **Add `column-level` as a third rule type across the skip logic pipeline.** The schema only has `table-level` and `row-level`. Column-level visibility (e.g., "show donor-type columns where patient count > 0") gets misclassified. The fix adds `column-level` to the ruleType enum, a new `column-split` action with `ColumnSplitDefinition` schema, a new FilterApplicator code path for column splits, and prompt guidance for both SkipLogicAgent and FilterTranslator. See linked plan for full schema changes, composition matrix, and implementation order.
  - Ref: SkipLogicAgent report 3.2 (GVHD misclassification)
  - Affected datasets: CAR-T Segmentation (A6), GVHD (A7)
  - Done: Schema (ruleType enum, ColumnSplitDefinitionSchema, column-split action, columnSplits field with .default([])), FilterApplicator (layered NxM composition), FilterTranslatorAgent (columnSplits validation), SkipLogicAgent (version-aware chunked mode), alternative prompts for both SkipLogic and FilterTranslator with column-level guidance + examples, observability updates.

### FilterTranslator Prompt Improvements

- [x] **Reframe confidence 0.00 in FilterTranslator.** Confidence 0.00 should mean "I genuinely cannot figure out how to filter this population" — not "the variable name the SkipLogicAgent gave me doesn't exist." If the named variable doesn't exist but another achieves the same filtering, use it at confidence 0.70 and explain why.
  - Ref: FilterTranslator report 3.3
  - Done: Reframed mission (expect imprecise inputs from SkipLogicAgent), expanded variable mapping with 6-step search process, reframed confidence scoring ("no plausible variable exists" not "named variable missing"), rewrote Example 3 to show search-then-fallback, updated constraint #1 and task_context.

- [x] **Add guidance on hidden variable disambiguation.** When a hidden variable has no labels (hREFERRER = 1 or 2, but which?), the agent should consider using a labeled survey variable instead — less minimal but auditable. Prompt the agent to weigh pros/cons: simple but opaque vs. longer but verifiable.
  - Ref: FilterTranslator report 3.2
  - Done: Added verifiability caveat to hidden_variable_resolution step 3. When opacity creates genuine ambiguity, prefer a longer but verifiable expression using labeled survey variables. Present the opaque option as an alternative.

- [x] **Add column-to-row donor mapping guidance.** When grid columns correspond to categories from another question's rows and the counts differ, the agent cannot assume 1:1 mapping. Flag for review with confidence below 0.50 unless translationContext provides the explicit mapping.
  - Ref: FilterTranslator report 4.6
  - Done: Existing variable_mapping safety rule ("If you cannot confidently map *all* relevant rowVariables, prefer returning splits: [] and set confidence below 0.50") and constraint #2 ("Don't assume patterns — verify each variable exists individually") already cover this behavior.

### Hidden Variable Value Labels

- [x] **RDataReader already extracts value labels for h\* and d\* variables** — the raw `answerOptions` string was present (e.g., `"1=INTERNAL REFERRER,2=COMMUNITY REFERRER"`). However, `DataMapProcessor.normalizeVariableTypes()` returned early for admin variables before parsing `answerOptions` into structured `scaleLabels` and `allowedValues` arrays. Fixed: admin variables now get `scaleLabels` and `allowedValues` populated before the early return, so FilterTranslator can resolve h\*/d\* values deterministically.
  - Ref: FilterTranslator report 4.2
  - Fix: `src/lib/processors/DataMapProcessor.ts` — parse value labels before admin early-return

---

## P0 — Table Count Management

*Before tables reach the VerificationAgent, ensure only necessary tables proceed.*

### Table Explosion

- [x] **Implement pre-verification table count gate.** After FilterApplicator but before VerificationAgent:
  - Below ~100 tables: pass all through, no intervention
  - Above 100 tables: deterministically identify and remove admin/metadata tables (IDs containing `_meta`, `_changes`, `_placeholder`, `_audit`, `_trailer`)
  - Above 100 tables: collapse unnecessary splits — if a split produces expressions where all split variables don't exist in the datamap, recombine using `splitFromTableId` traceability
  - Ref: VerificationAgent report, System report Rec #9
  - Done: GridAutoSplitter (`src/lib/tables/GridAutoSplitter.ts`). Splits oversized grid tables (>140 rows, configurable via `GRID_SPLIT_THRESHOLD`) into one sub-table per unique variable. Runs post-FilterApplicator, pre-VerificationAgent. Full provenance chain, filter field preservation, subtitle generation from datamap. Admin/metadata removal and split collapsing deferred — GridAutoSplitter addresses the root cause (oversized grids overwhelming VerificationAgent).

- [REJECTED] **Switch to minimal model for large datasets.** When table count exceeds the threshold, swap VerificationAgent to minimal reasoning effort. Tables still get processed, just more cheaply. Alternative to dropping tables.
  - Ref: VerificationAgent report

- [x] **Investigate WHY UCB Caregiver ballooned from 64 to 262 tables.** The survey doesn't need 205 tables. Something in the split/generation pipeline is creating redundancy. Trace the table expansion to understand the root cause before building mitigations.
  - Ref: VerificationAgent report

### Pre-Verification Risk Assessment

- [REJECTED] **Implement deterministic pre-flight risk assessment.** Runs after FilterApplicator, before VerificationAgent (~minute 10). Costs zero API calls — purely deterministic. Log to `pipeline-preflight.json`. For medium+ risk, display a warning with estimated cost/duration.
  - Signals: variable count, survey size, loop presence, skip rule count, table count pre/post split
  - Risk tiers: Low (<100 tables), Medium (100-150), High (>150), Critical (>200 or loop mismatch)
  - V1: warning only. Future: automatic mitigations.
  - Ref: System report, User-Proposed Enhancement

---

## P1 — Prompt Hygiene Sweep

*Every agent gets a fresh production prompt. Remove contradictions, align with schemas.*

- [ ] **Prompt rotation across all agents.** After this review: current production prompts become alternatives. Write fresh production prompts that align with current schemas, incorporate learnings from this review, and remove contradictions.
  - All 6 agents: BannerAgent, CrosstabAgent, SkipLogicAgent, FilterTranslatorAgent, VerificationAgent, LoopSemanticsPolicyAgent, BannerGenerate
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

- [REJECTED] **Write more aggressive/detailed prompts now that context inputs are being trimmed.** The freed-up context budget from survey/datamap reduction means we can write longer, more detailed system prompts. Test this: copy current prompts as alternatives, write verbose production prompts, compare quality.
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

- [ ] **Remove `changes` array from VerificationAgent schema.** Extra work for the agent with minimal value. Can detect changes deterministically by diffing input vs output. Frees agent intelligence for what actually matters.
  - Ref: VerificationAgent report 3.9

- [ ] **Remove `confidence` and `userSummary` from VerificationAgent schema (or make them deterministic).** Never populated across any dataset. If we want per-table confidence, compute it deterministically (postpass fixes applied? NET rows created? baseText populated?). `userSummary` belongs in the regeneration flow, not initial pipeline.
  - Ref: VerificationAgent report 1.5

### Clarify Field Semantics

- [ ] **Clarify `filterValue` vs `netComponents` for T2B/B2B rows.** T2B IS a NET — it should have NET components. The distinction isn't clear even to the product owner. Make the instructions explicit about what goes where. Either require `netComponents` on T2B/B2B rows, or infer them deterministically from `filterValue` in a postpass.
  - Ref: VerificationAgent report 3.6

### Postpass Offloading

- [REJECTED] **Move indentation entirely to postpass.** The orphan indent reset accounts for 81.5% of all postpass fixes (1,001 out of 1,227). Rather than trying to teach the agent correct indentation, remove `indent` from agent responsibility entirely and let the deterministic postpass handle it. Eliminates an entire error class.
  - Ref: VerificationAgent report 3.2, 4.2

- [REJECTED] **Add deterministic duplicate tableId resolution to postpass.** If duplicate tableIds occur, append `_2`, `_3` suffix. But first trace WHY duplicates are generated — this shouldn't happen.
  - [REJECTED] How does a duplicate tableId get generated? Trace the logic.
  - Ref: VerificationAgent report 3.5

- [REJECTED] **Add deterministic recombination for useless splits.** If a FilterApplicator split produces expressions where all split variables don't exist in the datamap, recombine the parts back together using `splitFromTableId` traceability.
  - Ref: FilterTranslator report 3.4

---

## P1 — Agent Architecture

### BannerGenerateAgent Separation

- [x] **Move BannerGenerateAgent to its own folder.** Create `src/prompts/bannerGenerate/` with `production.ts` and `alternative.ts`. The BannerAgent and BannerGenerateAgent are fundamentally different agents doing different jobs. The current coupling in `src/prompts/banner/` is confusing.
  - Ref: BannerAgent report
  - Done: Created `src/prompts/bannerGenerate/` with `production.ts` + `index.ts` (standard pattern with `BANNER_GENERATE_PROMPT_VERSION` env var). Removed `generate-cuts.ts` from `src/prompts/banner/`. Updated barrel exports in `src/prompts/index.ts`. BannerGenerateAgent imports unchanged (uses barrel).

### Banner Routing

- [x] **Add `filtersExist` flag to BannerAgent output.** When a banner document has group names but no filter expressions (like Leqvio-Seg-HCP), set `filtersExist: false`. The pipeline should route this to the BannerGenerateAgent or CrosstabAgent to figure out the actual expressions. This is a routing problem, not an extraction failure.
  - Ref: BannerAgent report 3.1

### LoopSemanticsPolicyAgent Optimization

- [REJECTED] **Skip LoopSemanticsPolicyAgent when no entity signals exist.** If no banner cuts reference iteration-linked variables, the answer is always "all respondent-anchored." A deterministic pre-check could save the API call. Extends the existing gate (which already skips non-loop datasets) one step further.
  - Ref: LoopPolicyAgent report, P3

---

## P1 — Base Transparency

*Every table should tell the user who the base is.*

- [x] **Ensure every table has a clear, human-readable base description.** Currently `baseText` is 36-77% missing depending on dataset. When populated, it sometimes contains raw filter expressions instead of readable descriptions. The base should always say "Respondents who [condition]" — never "Show Leqvio row when A3a > 0."
  - Affected: VerificationAgent prompt, possibly FilterTranslatorAgent output
  - Ref: SkipLogicAgent broader point, VerificationAgent report 1.5

- [x] **Track applied filters through the system.** When skip logic filters are applied on top of the base filter, the table's base description should reflect ALL applied filters so the user knows exactly who they're looking at. "This is only respondents who [base condition] AND [skip logic condition]."
  - Ref: SkipLogicAgent report, broader point on bases

---

## P2 — Quality Improvements

### Survey Markdown Conversion

- [X] **Audit survey markdown conversion for additional structure capture.** Look at the conversion and ask: what else should we preserve?
  - Highlighting
  - Complex grid structures
  - Section breaks / section headers
  - Bold/italic for instructions
  - Pipe logic (render distinctly — maybe a specific format/notation)
  - Termination criteria (visually distinct)
  - This benefits ALL agents, not just verification.
  - Ref: VerificationAgent report, survey markdown section

### SkipLogic Chunking

- [x] **Take another pass at chunked mode prompt language.** The chunked mode was built quickly. Review the prompt for optimal guidance, especially around what the agent should do when it suspects a rule exists but the evidence is in another chunk.
  - Ref: SkipLogicAgent report, chunked mode
  - Done: Replaced 4-step generic protocol with structured 4-step (Chunk Survey Map → Systematic Walkthrough → Cross-Chunk Awareness → Final Review). Enriched survey outline with [SKIP:] and [BASE:] annotations. Bumped stepCount 15→20.

- [x] **Cap maximum number of chunks instead of tuning threshold.** Maybe max 10 chunks is a better lever than adjusting the 40KB character threshold. Prevents extreme cases (CART had 16 chunks).
  - Ref: SkipLogicAgent report, chunked mode
  - Done: Added `SKIPLOGIC_MAX_CHUNKS` env var (default 10). Computes effective chunk size to stay within cap.

- [x] **Review deduplication behavior.** Dedup currently gets appended to the top of every run. Is this the right design? Worth flagging but may be inherent.
  - Ref: SkipLogicAgent report, chunked mode
  - Done: Added Layer 0 (identical ruleId) and Layer 1.5 (same ruleType + identical appliesTo). Both log when they fire.

### SkipLogic Architecture

- [REJECTED] **Two-pass approach for skip logic.** Instead of one pass that extracts AND classifies rules, maybe: Pass 1 captures all rules the agent sees (everything — gates, column-level, row-level, table-level). Pass 2 classifies each one. The system deterministically decides which to apply. This might produce better coverage since the agent isn't filtering while extracting.
  - Ref: SkipLogicAgent report 3.2

- [REJECTED] **Provide respondent counts per variable to SkipLogicAgent or FilterTranslator.** Actual R data (not just the survey) could help the agent understand whether filtering is already happening as expected. Maybe more of a FilterTranslatorAgent input than SkipLogicAgent.
  - Ref: SkipLogicAgent report, overall impression

### BannerGenerateAgent Role

- [REJECTED] **Should BannerGenerateAgent give plain text guidance instead of R expressions?** Currently it produces concrete filter expressions (`Q3==1`, `S2 %in% c(1,2)`) — but that's the CrosstabAgent's job. Maybe it should describe what to cut in plain text and let the CrosstabAgent figure out the syntax. The two agents are bleeding into each other.
  - Ref: BannerAgent report 3.5

### SkipLogic Duplicate Rules

- [x] **Improve duplicate rule detection in chunked mode.** The current overlapping-appliesTo threshold (70%) is fragile. Consider making the schema structure more conducive to deterministic deduplication — each field distinct enough that collisions are easily caught.
  - Ref: SkipLogicAgent report 3.6
  - Done: Added Layer 0 (identical ruleId) and Layer 1.5 (same ruleType + identical appliesTo set) before the existing 70% overlap check. Catches both the A7 and A9 duplicate cases from CART.

---

*This plan consolidates the User Thoughts from all 7 agent audit reports reviewed on February 9, 2026. Source reports are in `outputs/agent-reports/`.*
