# Future Features & Known Limitations

Items deferred from the product roadmap. These are not blocking for the Antares pilot — they're documented here so nothing gets lost.

*Moved from `product-roadmap.md` on February 11, 2026.*

---

## Deferred from Phase 3.4 (Post-Launch)

These are useful but not blocking for the Antares pilot. Pulled from the original 3.4 scope.

| Item | Why Deferred | When to Build |
|------|-------------|---------------|
| **Re-run support** (pre-populate wizard, swap files, run history) | Antares can create new projects for now. UX design needs real usage data to get right. | After pilot feedback — when users ask "can I re-run with different settings?" |
| **Debug bundles** (single zip of all pipeline artifacts) | We can pull these manually from R2 during the pilot. Nice-to-have, not blocking. | When support volume makes manual pulling painful |
| **Enhanced error visibility** (plain-language error translation) | Basic error messages from `run.error` are in scope in 3.4. Full translation layer (agent error codes → user copy) is a polish pass. | After we see what errors Antares actually hits |
| **Variable selection persistence** (lock confirmed mappings across re-runs) | Only matters when re-runs exist. | Alongside re-run support |

---

## Post-MVP: Message Testing & MaxDiff

**Goal**: Support message testing surveys (and MaxDiff studies with utility scores) by allowing users to upload message lists that get integrated into the datamap.

**Why deferred**: Requires intake form updates, file parsing logic, and datamap enrichment infrastructure. Important feature but not blocking the Antares pilot.

**What's needed**:
- Intake question: "Does this survey include messages?" → upload message list
- Message file parsing (Excel preferred, Word supported)
- Datamap enrichment: link message text to question variables
- Agent awareness: VerificationAgent uses actual message text in table labels

**Level of Effort**: Medium. Prioritize post-MVP based on Antares feedback.

---

- Fully implement resend; currently we have it implemented in code but i dont want to buy a domain so can't use it yet.

---

### Smart Data Validation by Project Type

The wizard currently asks users to self-report project-type details (segment assignments, anchored scores, message list). Post-MVP, the validate-data step should **auto-detect** these from the .sav itself, reducing user burden and catching mismatches before the pipeline runs.

**Segmentation auto-detection**:
- Scan for likely segment assignment variables (e.g., single categorical column with a small number of mutually exclusive groups, named with segment/cluster/group patterns)
- If found: pre-select as a banner cut candidate, confirm with user
- If not found: surface the same soft info alert ("segments won't be part of cuts") but based on data evidence, not user self-report

**MaxDiff auto-detection**:
- Detect anchored probability index (API) score variables — continuous 0–1 range columns appended at the end of the .sav, often with "anchor" or "API" in labels
- If not found and user said MaxDiff: hard blocker with clear message ("have your simulator analyst append these scores")
- Detect raw MaxDiff choice variables (best/worst columns) to confirm the data is actually MaxDiff
- If message list not uploaded: attempt to extract item labels from variable labels in the .sav (fallback)

**General .sav integrity checks** (extend current ValidationRunner):
- File corruption detection (haven parse failures, unexpected EOF)
- Zero-row or zero-column files
- Excessive missing data (>90% missing across most variables)
- Duplicate respondent IDs
- Mixed data types in columns that should be uniform

These checks would run as part of the existing `/api/validate-data` endpoint. The infrastructure is in place (ValidationRunner + validate-data route) — it's the detection heuristics that need building.

---

## Configurable Assumptions & Regeneration

Bob's observation from the Antares conversation: *"I've not seen anybody kind of going down this road... commercially speaking."*

What makes CrossTab unique is the **validated data foundation**. Every crosstab run produces artifacts that already executed successfully—verified variables, working R expressions, human-approved cuts. This foundation could eventually support follow-up queries and conversational exploration without the hallucination problems that plague other AI-on-data tools.

But that only matters if the core system is reliable. That's what we're focused on now.

CrossTab makes defensible statistical assumptions when generating crosstabs — particularly for looped/stacked data. These assumptions are specific choices from a finite set of valid approaches:

**Example: Needs State on stacked occasion tables**

The system defaults to entity-anchored aliasing — each occasion is evaluated against its own needs state variable, producing a clean partition (852 C/B occasions, not the inflated 1,409 from naive OR logic). But there are other defensible approaches:

| Approach | What it does | When you'd want it |
|----------|-------------|-------------------|
| **Entity-anchored alias** (our default) | Each occasion checks only its own needs state | You want occasion-level precision — "what happens during C/B occasions" |
| **First-iteration only** (Joe's approach) | Only use S10a (occasion 1) for all cuts | You want simplicity and are okay losing occasion 2 data |
| **Respondent-level OR** (naive approach) | `(S10a == 1 \| S11a == 1)` on stacked frame | You want "all occasions from respondents who had ANY C/B occasion" — different question, still valid if intentional |

None of these are wrong in absolute terms. They answer different questions. The problem is when the system silently uses one approach and the user assumes another.

**The vision:** Users receive crosstabs generated with our defaults (which we believe are the most statistically precise). Alongside the output, a Methodology sheet documents every assumption. If a user disagrees with an assumption, they can select an alternative from the finite set of defensible options and regenerate. The system re-runs R with the new configuration — no re-running agents, just swapping the alias/cut strategy.

**What this requires:**
- Assumptions surfaced in plain language (Methodology sheet)
- A mapping of each assumption to its alternatives (schema-driven, not free-form)
- A regeneration path that re-runs R script generation + execution without re-running the full pipeline
- The resume script (`test-loop-semantics-resume.ts`) is already a prototype of this pattern

**Why this matters commercially:** No other tool in this space surfaces its assumptions, let alone lets you change them. WinCross, SPSS Tables, and Q all make implicit choices that users can't inspect or override. Making assumptions explicit and configurable is a differentiator that builds trust with sophisticated research buyers.

This is a long-term feature — the foundation (correct defaults + validation proof) comes first.

---

## Predictive Confidence Scoring (Pre-Flight)

The idea: before running the full pipeline (45+ minutes), assess whether the system can handle a given dataset and flag issues upfront. A three-tier assessment (green/yellow/red) that tells users "we're confident," "proceed with caution," or "we can't handle this reliably."

**Why it's long-term, not now:** Most pipeline failures come from AI agent behavior (BannerAgent misreading a format, CrosstabAgent picking wrong variables, VerificationAgent making bad table decisions) — not from data characteristics we can measure upfront. You can't predict whether an agent will succeed on *this specific* banner plan without running it. Building a predictor now would produce either false assurance or meaningless noise.

**What's needed to make this real:**
- 50+ dataset runs with documented failure modes and root causes
- Enough signal to correlate data characteristics (variable complexity, naming patterns, loop structure) with actual pipeline outcomes
- Statistical evidence that pre-flight signals actually predict success/failure

**Signals that could eventually feed this** (all exist today but aren't predictive yet):
- Loop detection: iteration counts, fill rates, variable family completeness
- Deterministic resolver: evidence strength for iteration-linked variables
- Data map quality: percentage of variables with value labels, description completeness
- Variable count and complexity: hidden/admin variable ratios, naming consistency

**When to revisit:** After we have failure data across 20+ datasets with diverse characteristics. If clear patterns emerge (e.g., "datasets with no deterministic resolver evidence fail 80% of the time"), then a predictor becomes viable.

---

## Variable Selection Persistence

The crosstab agent's variable selection is non-deterministic — same dataset can produce different variable mappings across runs. Once a user confirms a mapping via HITL or accepts a successful run's output, lock those selections as project-level overrides so future re-runs don't re-roll the dice.

**What gets saved:** Banner group name → variable mappings, confirmation source ("user_confirmed" or "accepted_from_run_N"). Stored in Convex on the project record. The crosstab agent prompt includes a "locked selections" section — variables in this list are not re-evaluated.

**Why it matters:** Eliminates "it worked last time but not this time." First step toward accumulating project-level knowledge across runs.

**Why deferred:** Only matters when re-runs exist, and re-runs are a Phase 3.4 feature. No point building plumbing with no UI to exercise it. Pull forward when we build re-run support.

**Level of Effort:** Low (Convex persistence + prompt section, no architectural changes)

---

## Interactive Table Review

**The vision:** After a pipeline run completes, the user opens an interactive review in the browser — not a static Excel file. They see every table rendered as HTML, can toggle tables on/off, leave feedback on specific tables, request targeted regeneration, and only generate the final Excel when they're satisfied with the output.

This is the post-MVP experience that replaces the current workflow of: download Excel → review in Excel → note issues → request full re-run.

**Why it matters:** Users like Antares are used to working in Q, where they can iterate on individual tables. Giving them a static Excel with no way to adjust without re-running the full 45-minute pipeline is friction. This feature closes the gap — not by replicating Q, but by giving users control over the output they already have.

**The full workflow:**

1. **Pipeline completes** → user gets a notification (email, in-app, or browser tab)
2. **Open interactive review** (`/projects/[id]/review`) — tables rendered in a scrollable browser view
   - Collapsible sections by question group
   - Each table shows its table ID, base sizes, and a visual that closely matches the Excel styling
   - Tables already have `tableId`, `excluded`, `excludeReason` in the schema — this is the data model
3. **Per-table actions:**
   - **Include/Exclude toggle** — instant visual feedback. Excluded tables dim or move to a separate "Excluded" section. Tables on the excluded list can be pulled back in. No backend call until the user commits.
   - **Feedback note** — free-text per table: "Show top 3 box instead of top 2" or "Combine these rows into a single NET." Stored as metadata on the table.
   - **Request regeneration** — for tables with feedback, trigger a targeted re-run through the VerificationAgent with the feedback appended to context. Agent produces an updated table with the same table ID. Only that table is re-processed — not the full pipeline.
4. **Review summary** — before generating, show a summary: "12 tables included, 3 excluded, 2 regenerated with feedback."
5. **"Generate Final Excel"** — applies all include/exclude decisions and regenerated tables, produces the final workbook for download.

**What makes this feasible (foundations already exist):**

| Foundation | Status | What It Enables |
|-----------|--------|-----------------|
| `tables.json` with full table data | Done | Render tables in browser from structured data |
| Table IDs in Excel output | Done | Users can reference specific tables |
| `excluded` / `excludeReason` schema fields | Done | Toggle tables between included/excluded |
| VerificationAgent | Done | Re-run individual tables with feedback context |
| HITL review UI (cut validation) | Done | State management pattern, collapsible sections |
| ExcelJS for workbook generation | Done | Potentially render Excel-like views in browser |

**What needs building:**

| Component | Effort | Notes |
|-----------|--------|-------|
| Table preview component (HTML rendering of `tables.json`) | Medium | Style to approximate Excel output. Doesn't need to be pixel-perfect. |
| Per-table state management (include/exclude/feedback) | Low | Pattern exists in HITL review. Local state until "Generate" clicked. |
| Targeted regeneration (VerificationAgent re-invocation) | Medium | Re-run one table with feedback appended. Splice updated table back into `tables.json`. |
| Excel regeneration from modified `tables.json` | Low | ExcelFormatter already takes `tables.json` as input. Just pass the modified version. |
| Route: `/projects/[id]/review` | Low | New page in `(product)/` route group. |

**Constraints on targeted regeneration:**
- Feedback is scoped to what the VerificationAgent can control: row labels, NETs, derived rows, exclusions, groupings
- Can't change underlying data or banner structure — that requires a full re-run
- This is constrained editing, not free-form data exploration

**When to build:** After MVP delivery and initial Antares feedback. This is the kind of feature that's best informed by real usage — what do users actually want to change after seeing output? Build it once we have that signal.

---

## Dual-Mode Loop Semantics Prompt

The Loop Semantics Policy Agent uses a single prompt regardless of how much deterministic evidence is available. When the resolver finds strong evidence, the prompt works well. When there's none, the LLM must infer from cut patterns and datamap descriptions alone — harder and less reliable.

**Solution:** Two prompt variants selected automatically based on `deterministicFindings.iterationLinkedVariables.length`. High-evidence prompt anchors on resolver data. Low-evidence prompt adds pattern-matching guidance for OR expressions, emphasizes datamap descriptions, lowers confidence thresholds for `humanReviewRequired`, and includes more few-shot examples.

**Level of Effort:** Low (second prompt file in `src/prompts/loopSemantics/alternative.ts` + selection logic in agent)

**When to revisit:** If batch testing reveals classification failures on datasets where the deterministic resolver finds nothing.

---

**Error Handling & Recovery**
- Classify pipeline failures: validation issue (our bug) vs. transient/hallucination error (rerunnable)
- Tailor error messages accordingly — if the failure is transient, offer a "Rerun pipeline" button in the UI
- If the failure is a real bug, show a clear error state without the rerun option

## Known Gaps & Limitations

Documented as of February 2026. These are areas where the system has known limitations — some with mitigation paths already identified, others that may define the boundary of what CrossTab can handle. Even where solutions exist, it's important to be aware of these when communicating capabilities externally or testing against new datasets.

### Loop Semantics

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No deterministic evidence** — SPSS file has no label tokens, suffix patterns, or sibling descriptions. LLM must infer entirely from cut patterns and datamap context. | Medium | Dual-mode prompt (see above). Long-term: predictive confidence scoring. | Identified, not implemented |
| **Irregular parallel variable naming** — Occasion 1 uses Q5a, occasion 2 uses Q7b, occasion 3 uses Q12. No naming relationship. Resolver can't match. | Medium | LLM prompt must handle this from datamap descriptions. Few-shot examples for irregular naming. Some surveys may be unfixable without user hints. | Partially mitigated by LLM |
| **Complex expression transformation** — `transformCutForAlias` handles `==`, `%in%`, and OR patterns. Expressions with `&` conditions, nested logic, or negations could break transformation. | Low-Medium | Expand transformer for common compound patterns. Flag untransformable expressions for human review. | Common cases handled |
| **Multiple independent loop groups** — Dataset with both an occasion loop AND a brand loop. Architecturally supported but never tested. | Low | Schema and pipeline support N loop groups. Needs integration testing with a real multi-loop dataset. | Untested |
| **Nested loops** — A brand loop inside an occasion loop. Not handled. | Low | Not supported. Validation already detects loops; nested loop detection could be added as a basic sanity check. | Not supported |
| **Weighted stacked data** — Weights exist in the data but aren't applied during stacking or computation. | ~~High~~ | Implemented. Weight column carries through `bind_rows` in stacked frames. Manual weighted formulas with effective n for sig testing. | Complete |
| **No clustered standard errors** — Stacked rows from the same respondent are correlated, which overstates significance. Standard tests treat them as independent. This is industry-standard behavior (WinCross, SPSS Tables, Q all do the same). | Low | Accept as industry-standard limitation. Future differentiator if implemented. Would require respondent ID column in stacked frame + cluster-robust R functions. | Known limitation, not planned |
| **No within-group stat letter suppression for entity-anchored groups** — `generateSignificanceTesting()` didn't consult the loop semantics policy. Within-group pairwise comparisons ran for all groups regardless of overlap. Validation detected overlaps but didn't act on them. | Medium | Implemented — suppress or vs-complement testing for entity-anchored groups. | Complete |

### Loop Detection

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **Small fixed grids (3-7 iterations)** — The `fixed_grid` classifier requires >= 8 iterations or diversity/iteration ratio < 0.5. A small grid with e.g. 5 stimuli x 5 questions (ratio 1.0) won't trigger either rule and may be incorrectly stacked. | Low | Rare in practice. Could be addressed with agent-based label inspection or a user hint in the wizard. See `docs/loop-detection-explained.md` for details. | Known limitation |

### Crosstab Agent

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **Non-deterministic variable selection** — Same dataset can produce different variable mappings across runs. | Medium | Hidden variable hints help steer. Variable selection persistence (deferred) locks in confirmed choices. HITL for low-confidence cuts. | Partially mitigated |
| **Hidden variable conventions vary by platform** — h-prefix and d-prefix patterns are Decipher/FocusVision conventions. Other platforms (Qualtrics, SurveyMonkey, Confirmit) use different naming. | Low-Medium | Expand hint patterns as we encounter new platforms. The datamap description is platform-agnostic and usually contains enough signal. | Platform-specific hints added |
| **Overlapping banner cuts (non-loop)** — If a user provides overlapping respondent-anchored cuts, pairwise A-vs-B letters still run even when overlap makes comparisons questionable. | Medium | Consider optional suppression or complement testing for overlapping groups if demand warrants it. | Known limitation |

### General Pipeline

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No pre-flight confidence assessment** — Pipeline runs for 45+ minutes before discovering it can't handle a dataset reliably. | Medium-High | Long-term: predictive confidence scoring. Requires failure data across 50+ datasets before a predictor is viable. Near-term: project intake questions (3.3) set expectations upfront. | Deferred |
| **No methodology documentation in output** — Users receive numbers without explanation of how they were computed. Assumptions are implicit. | Medium | Methodology sheet in Excel (Configurable Assumptions vision). Policy agent + validation results provide the content. | Planned |
| **No project-level knowledge accumulation** — Each pipeline run starts fresh. Confirmed variable mappings, user preferences, and past decisions aren't carried forward. | Low-Medium | Variable selection persistence is the first step. Longer-term: project-level config that accumulates across runs. | Identified |
| **Hidden assignment variables don't produce distribution tables** — When a question's answers are stored as hidden variables (e.g., `hLOCATIONr1–r16` for S9), the pipeline correctly hides them but misses the distribution table that shows assignment frequency. Requires parent-variable linking in DataMapProcessor or verification agent awareness. | Low | Accept gap for now. Future: detect when hidden variable families relate to a visible question and auto-generate distribution tables. | Known limitation |
| **No dual-base reporting for skip logic questions** — When a question has skip logic, only the filtered base is reported. An experienced analyst might also report the same table with an all-respondents base for context (e.g., "what share of everyone had 2+ people present" vs "among those not alone, group size distribution"). Current behavior is correct; this is a future quality-of-life enhancement. | Low | Future: optional "also report unfiltered" flag on skip logic tables, generating both versions with clear base text. | Known limitation |
| **`deriveBaseParent()` doesn't collapse parent references for loop variables** — In LoopCollapser.ts, when a collapsed variable's parent is itself a loop variable being collapsed, `deriveBaseParent()` returns the uncollapsed parent name (e.g., `A7_1` instead of `A7`). DataMapGrouper then uses this uncollapsed parent as the `questionId`, causing loop variables like A7 to appear with inconsistent naming (e.g., `a7_1` instead of `a7`). Non-loop parents like A4 are unaffected. | Low | Fix `deriveBaseParent()` to check if the derived parent is in the collapse map and resolve it to the collapsed form. Straightforward code fix. | Known limitation |
| **No Excel or TXT input support** — Survey and banner plan inputs only accept PDF and DOCX. Excel banner plans (sometimes sent by clients) and TXT files are not supported. Users must export/convert to PDF or DOCX before uploading. | Low | Could add Excel parsing + structure detection for banner plans if demand warrants it. TXT is unlikely to be needed. | By design |

---

*Extracted from product-roadmap.md on February 11, 2026*
