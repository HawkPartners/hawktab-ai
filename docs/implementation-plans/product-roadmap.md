# Product Roadmap: Reliability → Production

## Overview

This document outlines the path from HawkTab AI's current state (reliable local pipeline) to a production product that external parties like Antares could use.

**Current State**: Pipeline working end-to-end locally. Reliability validation in progress.

**Target State**: Cloud-hosted service with multi-tenant support, configurable output options, and self-service UI.

**Philosophy**: Ship incrementally. Each phase delivers usable value while building toward the full vision.

---

### Implementation Status Summary (Feb 9, 2026)

| Item | Status | Notes |
|------|--------|-------|
| **Phase 1.1** Stable System | Complete | R validation, retry logic, per-table isolation |
| **Phase 1.2** Leqvio Dataset | Complete | 3 edge cases documented |
| **Phase 1.3** Loop/Stacked Data | Complete | Full deterministic resolver + semantics agent |
| **Phase 1.4** Broader Testing | In Progress | 11 datasets, batch runner operational |
| **Phase 1.5** ~~Pre-Flight Confidence~~ | Reorganized | Intake questions → 3.1; predictive scoring → Long-term Vision |
| **Phase 2.1** Output Formats | Complete | frequency, counts, both (same workbook or separate) |
| **Phase 2.4** Stat Testing Config | Complete | Env vars, pipeline summary, `--show-defaults` |
| **Phase 2.4b** Loop-Aware Stat Testing | Not Started | Suppress (default) or vs-complement for entity-anchored groups |
| **Phase 2.4c** Variable Persistence | Deferred | Moved to Long-term Vision |
| **Phase 2.4d** Dual-Mode Loop Prompt | Deferred | Moved to Long-term Vision |
| **Phase 2.5** Upfront Context | Consolidated | Merged into 3.1 (Project Intake Questions) |
| **Phase 2.5a** Input Flexibility | Complete | PDF/DOCX for survey + banner; .sav for data |
| **Phase 2.5b** AI-Generated Banner | Complete | BannerAgent generate-cuts prompt + HITL gate |
| **Phase 2.6** Weight Detection | Not Started | Detection + HITL + separate weighted/unweighted workbooks |
| **Phase 2.7** ~~Survey Classification~~ | Consolidated | Classification → 3.1 intake; confidence scoring → Long-term Vision |
| **Phase 2.8** HITL Review Overhaul | Partial | Agent output simplification + user-facing review with base sizes |
| **Phase 2.9** Table ID Visibility | Complete | IDs render, excluded sheet works. Interactive control → Long-term Vision |
| **Phase 2.10** Output Feedback | Complete | Feedback form on results page, stored as feedback.json, history badge |
| **Phase 2.11** Excel Themes | Complete | 6 themes: classic, coastal, blush, tropical, bold, earth. `--theme` CLI flag. |
| **Phase 2.12** ~~Browser Review~~ | Deferred | Consolidated into Long-term Vision → Interactive Table Review |
| **Phase 3.1** Local UI | Partial (~40%) | Basic pipeline UI; no enterprise structure |
| **Phase 3.2** Cloud Deployment | Not Started | No Convex/R2/Railway/Sentry/PostHog |
| **Phase 3.3** Auth (WorkOS) | Not Started | Zero authentication |
| **Phase 3.4** Cost Tracking | Partial (~30%) | Metrics collected, not persisted |
| **Phase 3.5** Logging | Minimal (~20%) | Basic tracing scaffold only |

**Also verified as implemented (not separate roadmap items):**
- TablePostProcessor: 8 deterministic rules (exceeds the 7 specified)
- Provenance tracking: `sourceTableId`, `splitFromTableId`, `lastModifiedBy` all in schemas
- SkipLogicAgent + FilterTranslatorAgent: Fully functional
- LoopDetector + LoopContextResolver + LoopCollapser: Fully functional
- Batch pipeline runner with cross-dataset analytics

---

## Phase 1: Reliability (Current)

*See `reliability-plan.md` for details*

| Part | Description | Status |
|------|-------------|--------|
| 1 | Stable System for Testing (R validation, bug fixes, retry logic) | Complete |
| 2 | Finalize Leqvio Dataset (golden datasets, 3x consistency runs) | Complete |
| 3 | Loop/Stacked Data + Weights (Tito's dataset) | Complete |
| 4 | Strategic Broader Testing (5 datasets across survey types) | In Progress |

**Exit Criteria**: 5 datasets producing consistent output across 3 runs each, output quality acceptable for report writing.

### ~~1.5 Pipeline Confidence Pre-Flight~~ — `REORGANIZED`

> **Decision (Feb 8, 2026):** This item originally combined two different ideas that have been separated:
>
> 1. **Intake questions** (asking users about project type, missing files, etc.) — moved to **3.1** as part of the New Project Flow. This is a UI/UX concern that belongs in the upload experience, not a pipeline pre-check.
>
> 2. **Predictive confidence scoring** (can the pipeline handle this dataset?) — moved to **Long-term Vision**. We don't yet have enough failure data across datasets to build a reliable predictor. Most pipeline failures come from AI agent behavior, not data characteristics — and you can't predict agent success without running the agents. Premature confidence tiers would either give false assurance (green on a dataset that fails) or meaningless noise (yellow on everything). Revisit after 50+ dataset runs with documented failure modes.
>
> The basic sanity checks that already exist (validation catches corrupt data, loop detection flags structural issues) continue to run as part of the pipeline. No new work needed in Phase 1.

---

## Phase 2: Feature Completeness

Features needed before external users can rely on the system for real projects.

### 2.1 Output Format Options — `COMPLETE`

**Percents Only / Frequencies Only**

Bob asked: "Is it possible to add in an option to say I only want percents or frequencies?"

| Option | What It Shows |
|--------|---------------|
| Both (default) | Count and percentage in each cell |
| Percents only | Just percentages |
| Frequencies only | Just counts |

**Current State**: All options implemented.

- `--display=frequency` — percentages only (default)
- `--display=counts` — raw counts only
- `--display=both` — two sheets in one workbook (Percentages + Counts)
- `--display=both --separate-workbooks` — two separate .xlsx files: `crosstabs.xlsx` (percentages) + `crosstabs-counts.xlsx` (counts). Each workbook gets its own TOC and Excluded Tables sheet.

---

---

### 2.4 Stat Testing Configuration — `COMPLETE`

**Current State**: Fully implemented.

- **Environment variables**: `STAT_THRESHOLDS`, `STAT_PROPORTION_TEST`, `STAT_MEAN_TEST`, `STAT_MIN_BASE`
- **Supports**: Dual thresholds (uppercase/lowercase letter notation), unpooled/pooled z-tests, Welch/Student t-tests, minimum base size
- **Validated on startup**, formatted for display, stored in `pipeline-summary.json`
- **All defaults** flow from a single config source: `getStatTestingConfig()` in `src/lib/env.ts`
- **`--show-defaults`** CLI flag displays current configuration without running pipeline

---

### 2.4b Loop-Aware Stat Testing — `NOT STARTED`

**Problem**: When entity-anchored banner groups exist on stacked/loop data, within-group pairwise stat testing (A-vs-B) can be invalid if groups overlap. Today, the system validates partition correctness and reports overlaps in `loop-semantics-validation.json`, but `generateSignificanceTesting()` doesn't consult this — stat letters are generated regardless.

**What to implement (two modes, default = suppress):**

| Mode | Behavior | When to use |
|------|----------|-------------|
| **Suppress** (default) | Skip within-group stat letters entirely for entity-anchored groups on stacked data. Still show vs-Total comparison. | Safe default. No invalid letters. |
| **vs-Complement** (optional) | Instead of A-vs-B, compute A-vs-not-A for each cut. Always statistically valid regardless of overlap. | User wants significance testing on loop tables and understands the tradeoff. |

**Implementation approach:**

1. **Schema** — Add `comparisonMode: 'suppress' | 'complement'` to `BannerGroupPolicySchema` in `loopSemanticsPolicySchema.ts`. Default: `'suppress'`.

2. **R script generation** — In `generateSignificanceTesting()` (`RScriptGeneratorV2.ts`):
   - Pass the loop semantics policy into the function (currently it receives nothing)
   - For each group, check if it's entity-anchored with `shouldPartition=true`
   - If `suppress`: skip the within-group comparison loop for that group
   - If `complement`: generate R code that computes complement mask (`!cut_mask`) and tests cut proportions/means against the complement set using the same z-test/t-test logic

3. **Config** — Expose as a pipeline option. In the UI, only show this toggle when loops are detected. Default to suppress.

**Level of Effort**: Medium (R script generation changes + schema addition + config wiring)

---

### ~~2.4c Crosstab Agent Variable Selection Persistence~~ — `DEFERRED`

> Moved to Long-term Vision. Not blocking for MVP — hidden variable hints and HITL provide sufficient reliability for now.

---

### ~~2.4d Dual-Mode Loop Semantics Prompt~~ — `DEFERRED`

> Moved to Long-term Vision. Single prompt works well when deterministic evidence exists. Revisit if batch testing reveals failures on low-evidence datasets.

---

### ~~2.5 Upfront Context Capture~~ — `CONSOLIDATED`

> Merged into 3.1 (Project Intake Questions in the New Project Flow). All context capture happens through the UI upload experience.

---

### 2.5a Input Format Flexibility — `COMPLETE`

| Input Type | Accepted Formats | Notes |
|------------|------------------|-------|
| Survey | PDF, DOCX | BannerAgent converts via LibreOffice headless + pdf2pic |
| Banner Plan | PDF, DOCX | Same conversion pipeline as survey |
| Data File | SPSS (.sav) only | Source of truth for variables and values |

**Not supported (by design):** Excel banner plans, TXT files for survey or banner. These are edge cases not worth the preprocessing complexity. If a client has an Excel banner plan, they can export it to PDF first.

Question numbering flexibility (Q_S2, S2, QS2, etc.) is handled by AI pattern matching — no special work needed.

---

### 2.5b AI-Generated Banner from Research Objectives — `COMPLETE`

When no banner plan is provided — or the user explicitly chooses "AI generate cuts" — the system generates a suggested banner from the datamap and optional research objectives.

**Why It Matters**: Many projects don't have formal banner plans. Internally, we have datasets we can't test because the pipeline expects a banner plan. Externally, Antares mentioned clients who send plans with "just words" or no spec at all. This feature unblocks both scenarios and is a commercial differentiator — no other tool generates banner groups from data + objectives.

**User Flow** (UI context for future 3.1, but the logic is pipeline-level):

1. User completes intake form (project type, research objectives — if provided)
2. At the banner plan step, user has three options:
   - **Upload a banner plan** → existing BannerAgent flow (no change)
   - **Provide optional cut suggestions** → text hints like "cut by specialty tier and region" that steer the agent
   - **Skip / let AI generate** → system generates cuts from datamap + objectives
3. If generating: BannerAgent (generate mode) proposes 3-5 banner groups
4. **HITL gate**: User reviews proposed groups before pipeline continues — "Here's what we'd cut by. Add, remove, or modify." This is mandatory for generated banners (unlike parsed banners where the user already made the decisions).
5. User confirms → output feeds into CrosstabAgent as normal

**Architecture**:

The BannerAgent handles both paths. Same agent, different prompt. The output schema (`BannerGroup[]`) is unchanged — downstream pipeline doesn't know or care whether groups were parsed from a PDF or generated from data.

```
src/prompts/banner/
├── with-plan.ts          # Current: parse provided banner plan
├── generate-cuts.ts      # New: generate cuts from datamap + objectives
└── shared/               # Common output format instructions, best practices
```

This follows a broader pattern we'll adopt as agents handle more scenarios: **scenario-based prompts** rather than just production/alternative tuning variants. Each prompt is optimized for a specific input situation.

**Key input for generation is the datamap, not the survey.** The .sav-derived datamap has everything needed: variable names, labels, value labels, category counts, `nUnique`. The survey PDF is supplemental context (question wording helps understand intent), but the datamap is the engine.

**What the generate-cuts prompt reasons about:**

| Signal | Source | How It's Used |
|--------|--------|---------------|
| Demographics | Datamap variable names + labels (age, gender, region) | Almost always included as cuts |
| Project type | Intake form (segmentation, ATU, MaxDiff, etc.) | Informs which variables matter (e.g., segment variable for segmentation studies) |
| Research objectives | User-provided text (optional) | Prioritizes variables relevant to what the user is trying to learn |
| Cut suggestions | User-provided hints (optional) | Direct steering — "cut by specialty tier" |
| Variable suitability | Datamap `nUnique`, value labels | Categorical variables with 2-8 categories make good cuts; 50-category variables don't |
| Sample size | Datamap or quick R query | Cuts need sufficient n per cell to be meaningful |

**What "good" generated cuts look like:**

- **Group 1**: Total (always)
- **Groups 2-4**: Demographics — the "usual suspects" that almost every study cuts by
- **Group 5**: Study-specific — driven by research objectives or project type (e.g., segment assignments, awareness tiers, usage levels)
- Each group has 2-6 cuts with clear labels and stat testing letters

**Pipeline branching logic:**

```
if (bannerPlanProvided) {
  // Existing flow — parse banner plan PDF/DOCX
  BannerAgent(prompt: 'with-plan', input: bannerPlan + survey)
} else {
  // New flow — generate cuts from data
  BannerAgent(prompt: 'generate-cuts', input: datamap + objectives + cutSuggestions)
  → HITL gate (user reviews/edits proposed groups)
}
→ CrosstabAgent (unchanged — receives BannerGroup[] either way)
```

**Why this is more feasible than originally scoped:**

- Output format is unchanged — no downstream pipeline changes
- BannerAgent already handles structured output with the right schema
- Datamap already contains everything needed (variables, labels, types, category counts)
- HITL pattern already exists for crosstab cuts — we add a similar gate earlier
- The prompt engineering is the main work, not plumbing

**What's genuinely hard:** The current BannerAgent prompt is optimized for *parsing* — reading a document and extracting structure. The generate-cuts prompt is a different cognitive task — *designing* banner groups from raw data. The prompt will need real iteration. But the infrastructure (agent call, schema, pipeline integration) is straightforward.

**Level of Effort**: Medium (prompt engineering + pipeline branching + HITL gate. No new schemas, no new agents, no downstream changes.)

---

### 2.6 Weight Detection & Application — `NOT STARTED`

**Problem**: Most commercial survey data arrives pre-weighted. The fielding partner (Antares, Dynata, etc.) runs RIM weighting or raking on the completed data to match demographic targets and adds a weight column to the .sav file before delivery. This is a respondent-level attribute — each person gets one weight value (typically 0.3–3.0, centered around 1.0). Currently the pipeline ignores weights entirely. For weighted studies, this means all output is technically valid but analytically incomplete — clients expect weighted results when they've paid for weighted data.

**Detection**:

Scan the datamap for weight variable candidates. Signals:

| Signal | What to Look For |
|--------|-----------------|
| Variable name | `weight`, `wt`, `wgt`, `WT_FINAL`, `WEIGHT_VAR`, and common variations (case-insensitive) |
| Data characteristics | Numeric, no value labels, values clustered around 1.0, no zeros or negatives |
| SPSS metadata | Some .sav files tag the weight variable explicitly — haven may expose this |

Detection should run early (during datamap processing) and flag candidates for user confirmation.

**User Confirmation (HITL)**:

This must surface to the user — never silently apply weights. The UI (or CLI for now) presents:

```
We found a possible weight variable: "wt" (mean: 1.02, range: 0.31–2.87)

○ Yes, apply weights using "wt"
○ No, run unweighted
○ That's not a weight variable — it's [user can explain]
```

If multiple candidates are found, let the user pick which one. If none are found, skip — unweighted is the default.

**Output — Separate Workbooks for Weighted vs. Unweighted**:

When weights are applied, produce two complete workbooks:

| Workbook | Contents |
|----------|----------|
| `crosstabs-weighted.xlsx` | All tables with weighted calculations. Base row shows weighted n. TOC + Excluded Tables sheet. |
| `crosstabs-unweighted.xlsx` | Same tables, unweighted. Base row shows raw n. TOC + Excluded Tables sheet. |

Both workbooks have their own TOC and Excluded Tables sheet (same pattern as `--display=both --separate-workbooks`). The TOC should note whether the workbook contains weighted or unweighted results.

This is simpler than collapsing weighted and unweighted into one workbook (which Joe sometimes does but inconsistently). Two workbooks is clean, unambiguous, and reuses the separate-workbooks pattern we already have for display modes.

**R Script Changes**:

- Weighted workbook: Use R's `survey` package — `svydesign()` for design specification, `svytable()` / `svymean()` / `svyciprop()` for weighted calculations, weighted significance testing
- Unweighted workbook: Current R script (no changes)
- Both scripts generated from the same `tables.json` — only the calculation layer differs
- If the data is later stacked for loop tables, the weight variable carries forward to each stacked row (respondent's weight applies to all their occasions)

**Pipeline Integration**:

```
DataMap extraction
  → Weight detection (scan for candidates)
  → HITL confirmation (user picks weight variable or declines)
  → Pipeline continues with weightVariable in config
  → R script generation: if weightVariable, generate both weighted + unweighted scripts
  → Excel generation: two workbooks (or one if unweighted)
```

**Level of Effort**: Medium (detection heuristics are straightforward; R `survey` package handles the math; Excel output reuses separate-workbooks pattern. Main work is R script generation for weighted calculations + testing.)

---

### ~~2.7 Survey Classification & Confidence Scoring~~ — `CONSOLIDATED`

> **Decision (Feb 8, 2026):** This item combined two ideas that are already covered elsewhere:
>
> 1. **Survey classification** (detecting project type to prompt for missing context) — covered in **3.1** as part of Project Intake Questions. The user selects their project type during intake, and the system asks conditional follow-ups per type (Segmentation → segment assignments, MaxDiff → message list, Conjoint → choice task definitions). Asking the user is simpler and more reliable than auto-detecting from variable names.
>
> 2. **Multi-dimensional confidence scoring** (assessing pipeline readiness across dimensions like structure, parent-child, variable types) — covered in **Long-term Vision → Predictive Confidence Scoring**. Same conclusion applies: we don't yet have enough failure data to build a reliable predictor. Revisit after 50+ dataset runs.

---

### 2.8 HITL Review Overhaul (Agent Output + User Experience) — `PARTIAL`

> **Implementation Status (Feb 2026):** HITL review UI exists at `/pipelines/[pipelineId]/review/` showing alternatives with confidence scores. Has state management for per-column decisions and visual feedback. Missing: base sizes, plain-language summaries, agent output simplification, actionable review flow.

**Problem**: The current HITL flow surfaces raw agent output — confidence decimals, R expressions, developer-facing reasoning. This works for debugging but is wrong for users. A non-technical person reviewing cuts doesn't care that `hLOCATIONr1` has 0.75 confidence vs `dLOCATIONr1` at 0.65. They want: "We found multiple variables for 'Own Home.' Here are your options, ranked. Option 1 has 156 respondents, Option 2 has 23."

This item has two sides: simplifying what agents produce, and improving what users see.

---

**Part A: Agent Output Simplification**

Audit agent output schemas across the pipeline and ask: is this field necessary? Is it redundant? Could it be derived deterministically? Agents should produce what only agents can produce — don't make them do work that code can do better.

| Current | Problem | Fix |
|---------|---------|-----|
| Per-alternative `confidence` scores (0.75, 0.65, 0.60) | Granularity is false precision. Users don't know what 0.65 vs 0.60 means. | **Rank alternatives by preference** (1st, 2nd, 3rd). Agent picks its recommendation (#1) and orders the rest. No decimals. |
| `humanReviewRequired` flag set by agent per-column | Agent decides when to escalate — inconsistent, non-auditable. | **Derive deterministically.** Agent outputs a single group-level confidence score. Pipeline applies a threshold (e.g., <0.8 → review). Consistent, tunable, no agent discretion. |
| Per-column confidence + per-alternative confidence + group-level confidence | Confidence at every level is redundant. | **One confidence score per group.** If any column in the group is uncertain, the group gets flagged. Simpler schema, same outcome. |
| `reason` and `uncertainties` written in developer language | "Found hLOCATIONr1 (HOME - HIDDEN: LOCATIONS) → selected because it is a direct 0/1 flag corresponding to Assigned S9_1" is not user-facing. | **Separate internal reasoning from user-facing summary.** Agent produces both: (1) detailed reasoning for debugging/scratchpad, (2) plain-language summary for the user written as if speaking to a non-technical research manager. |
| `expressionType` field | Internal classification. User doesn't need to see this. | **Keep in schema for pipeline use, don't surface in HITL UI.** |

**The principle:** Agents output a recommendation with a confidence level and plain-language reasoning. Everything else (whether to escalate, base sizes, ranking presentation) is handled deterministically by the pipeline.

---

**Part B: HITL Review Experience**

What the user sees when a banner group needs review:

1. **Group-level summary** — "We need your input on the **Location** group. We found variables that could work but want to confirm."

2. **For each cut in the group**, show:
   - Cut name from the banner plan (e.g., "Own Home")
   - Our recommendation — plain-language description of what variable we chose and why
   - Sample size (n=156) — **deterministically calculated via R query**, not AI-generated
   - Ranked alternatives if they exist — each with plain-language description and sample size
   - If n=0 on any option → flag it ("This variable has no matching respondents — likely wrong mapping")
   - If n<30 on recommended option → warning ("Low sample size — significance testing may be unreliable")

3. **User actions per cut**:
   - Accept recommendation (default)
   - Pick an alternative
   - Flag for manual handling ("I'll fix this in the Excel myself")

4. **User actions per group**:
   - Accept all recommendations
   - Review individually

**Base size calculation**: Run a quick R query against the .sav file for each proposed expression and its alternatives. This happens once when HITL review is triggered — lightweight and deterministic. Users often know roughly how many respondents should be in a segment ("we expected ~150 Tier 1 HCPs"), so sample size is the single most useful signal for confirming whether a mapping is correct.

---

**What this replaces in the schema:**

```
Before (per-column):
  confidence: 0.75
  reason: "Found hLOCATIONr1 (HOME - HIDDEN: LOCATIONS)..."
  alternatives: [{ expression, confidence: 0.65, reason }]
  uncertainties: ["Multiple variables encode..."]
  humanReviewRequired: true

After (per-column):
  rank: 1                           # Agent's preference order
  userSummary: "We chose the binary  # Plain language for the user
    location flag (156 respondents).
    There are similar variables in
    the data — see alternatives."
  alternatives: [{ expression,       # Ranked by preference, no confidence decimals
    rank: 2, userSummary }]
  baseSize: 156                      # Deterministic (R query, not AI)

After (per-group):
  confidence: 0.72                   # Single score for the group
  reviewRequired: true               # Derived: confidence < threshold
```

**Scope**: This audit applies primarily to the CrosstabAgent (banner cut mappings), which is where HITL review happens today. The same principles (simplify output, separate internal/user-facing language, derive what you can deterministically) should inform future schema changes across other agents.

**Level of Effort**: Medium (schema changes + prompt updates for plain-language output + R query for base sizes + HITL UI refresh). The UI component belongs in 3.1 but the schema and prompt work is Phase 2.

---

### 2.9 Table ID Visibility — `COMPLETE`

> **Implementation Status (Feb 2026):** Table IDs render in Excel output (`[tableId]` in context column). Excluded Tables sheet exists with full rendering. Tables have `excluded` and `excludeReason` schema fields. This is sufficient for MVP.

Table IDs in the Excel output are already useful — users can reference specific tables when giving feedback. The interactive include/exclude control and regeneration functionality that was originally scoped here has been moved to **Long-term Vision → Interactive Table Review** as part of a larger consolidated vision (former 2.9, 2.10, 2.12).

No additional work needed for MVP.

---

### 2.10 Output Feedback Collection — `COMPLETE`

> **Implementation Status (Feb 2026):** Feedback collection fully implemented. Users can submit feedback on completed pipeline runs via a "Leave Feedback" form on the results page (`/pipelines/[pipelineId]`). Feedback stored as `feedback.json` in pipeline output folder. Includes: free-text notes, optional quality rating (1-5), optional table ID tags. Pipeline history shows a "Feedback" badge when feedback exists. API endpoints: `GET/POST /api/pipelines/[pipelineId]/feedback`. Schema: `pipelineFeedbackSchema.ts`.

> *Replaces former "Table Feedback & Regeneration." Per-table regeneration moved to Long-term Vision → Interactive Table Review.*

**Problem**: When a user reviews their crosstab output and finds issues — wrong table structures, missing NETs, tables that should be excluded — there's no structured way to capture that feedback. Currently it's ad-hoc (Slack messages, emails, notes in a doc).

**What's Needed**: A lightweight feedback mechanism per pipeline run. Not per-table regeneration (that's Long-term Vision), just a way for users to say "here's what was wrong with this output."

**Implementation**:
- After a pipeline run completes, the user can submit feedback on the output as a whole
- Stored as `feedback.json` in the pipeline output folder (or in the project record once we have Convex)
- Simple structured format: free-text notes, optional table IDs referenced, overall quality rating
- This is for *us to learn from* — helps prioritize agent/prompt improvements based on real user pain points
- In the UI (3.1): a "Leave Feedback" button on the results page. Textarea + optional table ID tags.

**What this is NOT**:
- Not per-table regeneration (that's the Interactive Table Review vision)
- Not real-time — feedback is collected after the fact, not acted on during the run
- Not blocking anything downstream — just a feedback collection mechanism

**Level of Effort**: Low (JSON storage + simple UI form)

---

### 2.11 Excel Color Themes — `COMPLETE`

**Current State**: Fully implemented. 6 color themes available via `--theme` CLI flag.

| Theme | Description |
|-------|-------------|
| `classic` (default) | Original blue/green/yellow/peach/purple/teal palette |
| `coastal` | Sky blue, sand, warm orange, slate, taupe |
| `blush` | Soft pinks, peach, mauve, lavender, coral |
| `tropical` | Teal, pink, indigo, amber, cream |
| `bold` | Navy, cream, gold, red, olive |
| `earth` | Brown, yellow, mint green, olive, red |

**Architecture**: `src/lib/excel/themes.ts` defines `ThemePalette` interface with semantic color roles (header, context, base, label, 6 banner group A/B shade pairs, sig letter color). `setActiveTheme()` in `styles.ts` mutates `FILLS` and `FONTS` in place — zero renderer changes needed. Accent colors are lightened via formula to produce cell-appropriate pastel backgrounds.

**CLI**: `--theme=coastal` (or any theme name). Default: `classic`. Works in both `test-pipeline.ts` and `batch-pipeline.ts`.

**Phase 3**: UI dropdown in project settings.

**Preview script**: `npx tsx scripts/test-themes.ts [tables.json]` generates one Excel per theme in `outputs/theme-preview/`.

---

### ~~2.12 Interactive Browser Review~~ — `DEFERRED`

> **Decision (Feb 8, 2026):** Consolidated with former 2.9 (include/exclude control) and 2.10 (per-table regeneration) into **Long-term Vision → Interactive Table Review**. The full interactive review experience — browser rendering, per-table toggles, targeted regeneration — is a compelling post-MVP feature but not needed for initial delivery. See Long-term Vision for the fleshed-out plan.

---

## Phase 3: Productization

Taking the reliable, feature-rich CLI and bringing it to a self-service UI that external parties like Antares can use.

### 3.1 Local UI Overhaul (Cloud-Ready) — `PARTIAL (~40%)`

> **Implementation Status (Feb 2026):** Basic Next.js app works: file upload UI, pipeline history, job progress polling with toast notifications, job cancellation, HITL review page for crosstab cuts. Missing: No `(marketing)/` or `(product)/` route groups, no dashboard/project list, no new project wizard, no organization structure. `StorageProvider` not abstracted (hardcoded `/tmp/hawktab-ai/`). `JobStore` is in-memory only (Map, no persistence across restarts). Not cloud-ready.

**Goal**: Build the complete web experience locally, but architected so deployment to cloud is just configuration changes—not rewrites.

**Reference**: Discuss.io for organization/project structure (not styling). The functionality pattern—organizations, projects, roles—is what enterprise clients expect.

**What's Needed**:

1. **Marketing Pages** (`(marketing)/` route group):
   - Landing page with value proposition
   - Login button (routes directly to dashboard—no custom auth pages, WorkOS handles this)
   - Simple, bold, professional aesthetic

2. **Product Pages** (`(product)/` route group):
   - **Dashboard**: Project list with columns (Project Name, Private/Public, Team, Date Created, Your Role, Status)
   - **New Project Flow**: File upload (SPSS, datamap, survey, banner plan), configuration options
     - *Note*: Data file upload should include helper text or tooltip clarifying "qualified respondents only"—the system assumes terminated/disqualified respondents are already filtered out.
   - **Project Intake Questions** *(consolidates former 1.5 and 2.5)*: After file upload, ask qualifying questions based on project type. Not every survey type needs extra context, but some do:
     - "What type of project is this?" → Segmentation, MaxDiff, ATU, Conjoint, Standard, etc.
     - **Segmentation**: "Does your data file have the segment assignments?" If no → warn that segment banner cuts won't work.
     - **MaxDiff with message testing**: "Can you upload the message list?" (so we can link questions to actual message text, not just "Message 1"). "Does your data file have the anchored probability scores?" If no → warn that MaxDiff utility results won't be available.
     - **Conjoint/DCM**: "Can you upload your choice task definitions?" Needed to interpret utility scores and choice shares.
     - **General**: Set expectations about what the system can and can't do for this project type, before burning 45 minutes of pipeline time.
     - Context captured here gets injected into agent prompts (e.g., VerificationAgent knows this is a MaxDiff study and can label tables appropriately).
     - This is about giving the pipeline the context it needs to succeed, not about predicting success. Start with the 2-3 project types that require extra files or context. Expand as we encounter more.
   - **HITL Review**: Uncertain variable mappings with base sizes (from 2.8)
   - **Job Progress**: Real-time status updates
   - **Results**: Download Excel, view table list, include/exclude toggles (from 2.9), feedback per table (from 2.10)

3. **Organization Structure Foundation**:
   - UI assumes organization context (like "HawkPartners" in Discuss.io header)
   - Roles: Admin, Member, External Partner
   - Projects belong to organizations
   - This is the data model foundation—auth enforcement comes in 3.3

4. **Route Structure**:
```
/app
├── (marketing)/           # Public pages
│   ├── page.tsx           # Landing page at /
│   └── layout.tsx         # Marketing layout (no sidebar)
│
├── (product)/             # Logged-in experience
│   ├── dashboard/         # Project list
│   ├── projects/[id]/     # Single project view
│   ├── projects/new/      # New project wizard
│   └── layout.tsx         # Product layout (sidebar, org header)
```

**Cloud-Ready Architecture** (critical for smooth 3.2 transition):

| Concern | Local Implementation | Cloud Swap |
|---------|---------------------|------------|
| File storage | Abstract `StorageProvider` interface → local disk | Swap to R2 |
| Job state | Abstract `JobStore` interface → JSON files or SQLite | Swap to Convex |
| File downloads | Serve from local `/temp-outputs/` | Signed R2 URLs |
| Real-time updates | Polling local endpoint | Convex subscriptions |

**Don't do this**:
- Hardcode file paths like `/temp-outputs/project-123/`
- Store job state in memory only
- Assume single-user, single-job execution

**Do this instead**:
- Use `storageProvider.upload(file)` / `storageProvider.download(key)`
- Use `jobStore.getStatus(jobId)` / `jobStore.updateStatus(jobId, status)`
- Design for concurrent jobs from day one (even if we test with one)

**Design Principles**:
- Bold yet professional (not generic SaaS slop)
- Enterprise-focused from day one
- Placeholders for future features are fine
- Assume logged-in state for now (auth comes later)

**Audit First**: Before building, audit current CLI features and map each to a UI component.

**Level of Effort**: High (full UI build with proper abstractions)

---

### 3.2 Cloud Deployment — `NOT STARTED`

**Current**: Runs locally via CLI and local Next.js dev server

**Target**: Cloud-hosted service that Antares can rely on—not just functional, but reliable and secure.

**Core Infrastructure**:

| Component | Service | Why |
|-----------|---------|-----|
| UI Hosting | Vercel | Easy Next.js deployment, edge functions |
| Database | Convex | Real-time subscriptions, TypeScript-native |
| File Storage | Cloudflare R2 | S3-compatible, no egress fees |
| R Execution | Railway (Docker) | Supports long-running processes |
| Error Monitoring | Sentry | Know when things break |
| Analytics | PostHog | Usage tracking (minimal) |

**Job Management** (pipeline runs 30-60 mins with 4 agents):

1. **Job Queue**:
   - User submits job → Create job record in Convex (status: `queued`)
   - Background worker picks up job → status: `running`
   - Track progress: `banner_complete`, `crosstab_complete`, `table_complete`, `verification_complete`, `r_running`, `excel_generating`
   - On completion → status: `completed`, store result URLs
   - On failure → status: `failed`, store error details

2. **Concurrent Jobs**:
   - Each job is isolated (own file namespace, own R session)
   - Don't assume single-user—Antares might run 3 projects at once
   - Railway can scale horizontally if needed

3. **HITL Pause/Resume**:
   - When HITL is needed → status: `awaiting_review`, store pending decisions
   - User can close browser, come back later
   - On review submission → resume pipeline from checkpoint

**Caching & Performance**:

| What to Cache | Where | Why |
|---------------|-------|-----|
| Parsed datamap | Convex or R2 | Don't re-parse on HITL resume |
| Banner output | Convex | Reuse if user re-runs with same banner |
| R script (pre-execution) | R2 | Debug/audit trail |
| Intermediate agent outputs | R2 | Resume from checkpoint on failure |

Redis is likely overkill for MVP—Convex handles real-time well. Consider Redis later if we need:
- Rate limiting at scale
- Session caching across edge functions
- Sub-second cache invalidation

**Security Fundamentals**:

- **File uploads**: Validate file types server-side (not just client), scan for malicious content, size limits
- **API routes**: All `/api/` routes behind auth middleware (after 3.3)
- **Signed URLs**: R2 downloads use time-limited signed URLs, not public buckets
- **Input validation**: Zod schemas on all API inputs
- **CORS**: Restrict to known origins
- **Rate limiting**: Prevent abuse (especially on expensive AI calls)
- **Secrets**: All API keys in environment variables, never in client code

**Reliability Patterns**:

- **Retries with backoff**: Agent calls can fail—retry 3x with exponential backoff
- **Graceful degradation**: If one table fails R validation, continue with others (already doing this)
- **Health checks**: Endpoint for monitoring (Vercel cron or external)
- **Idempotent operations**: Re-running a job with same inputs should be safe

**Deployment Checklist**:
- [ ] Swap `StorageProvider` to R2 implementation
- [ ] Swap `JobStore` to Convex implementation
- [ ] Configure Railway R container with HTTP endpoint
- [ ] Set up Sentry error tracking
- [ ] Configure environment variables in Vercel
- [ ] Test full pipeline in staging before production
- [ ] Set up basic monitoring/alerting

**Level of Effort**: High (1-2 weeks for reliable deployment, not just "it works")

---

### 3.3 Multi-Tenant & Auth (WorkOS Integration) — `NOT STARTED`

**Context**: At this point, we have a cloud-deployed app with proper abstractions (3.1) and reliable infrastructure (3.2). Now we layer on authentication and organization management to make it ready for external users like Antares.

**Why WorkOS AuthKit**:
- Free for 1M MAUs (plenty of headroom)
- Handles login/signup UI—we don't build auth pages
- SSO/SAML available when enterprise clients need it
- Organization management built-in

**What WorkOS Provides**:
- User authentication (email, Google, SSO)
- Organization creation and management
- User ↔ Organization membership
- Role assignment (Admin, Member)
- Hosted login/signup pages (redirect flow)

**What We Build on Top**:

1. **Auth Middleware**:
   - Protect all `(product)/` routes
   - Validate WorkOS session token
   - Inject `userId` and `orgId` into request context

2. **Convex Schema Extensions**:
   - `users` table (synced from WorkOS on first login)
   - `organizations` table (synced from WorkOS)
   - `projects` table already has `orgId` foreign key (from 3.1)
   - `orgMemberships` for role lookups

3. **Role-Based Access**:
   | Role | Can Do |
   |------|--------|
   | Admin | Create projects, invite members, manage org settings, view all projects |
   | Member | Create projects, view own projects, view shared projects |
   | External Partner | View projects explicitly shared with them, download results |

4. **Invite Flow**:
   - Admin invites user by email → WorkOS sends invite
   - User signs up/logs in → Automatically added to org
   - For external partners: invite with limited role

5. **Organization Switcher** (if user belongs to multiple orgs):
   - Dropdown in header (like Discuss.io "HawkPartners" selector)
   - Context switches all data to selected org

**Integration Points**:
- Login button → `WorkOS.redirectToLogin()`
- Callback route → Validate token, create session, redirect to dashboard
- Logout → Clear session, redirect to marketing page
- API routes → Check `req.auth.orgId` matches resource ownership

**Security Enforcement**:
- All file access scoped to org: `r2.get(orgId/projectId/file.xlsx)`
- All Convex queries filter by `orgId`
- No cross-org data leakage possible by design

**Level of Effort**: Medium (WorkOS does heavy lifting, we wire it up and enforce scoping)

---

### 3.4 Cost Tracking — `PARTIAL (~30%)`

> **Implementation Status (Feb 2026):** `AgentMetricsCollector` tracks token usage per agent call. `CostCalculator` uses LiteLLM pricing for cost estimation. Cost summary printed to console after pipeline completion. Missing: No database persistence (metrics are lost when process ends). No per-org aggregation, no dashboard, no historical tracking. Needs a database (Convex) to be useful.

**Goal**: Track AI costs so we can price the product appropriately. This is for us, not exposed to users.

**What to Track**:
- Token usage per agent call (BannerAgent, CrosstabAgent, TableAgent, VerificationAgent)
- Token usage for regenerations (2.10)
- Store in Convex: `aiUsage` table with `jobId`, `orgId`, `operation`, `tokens`, `timestamp`

**Pricing**: After Antares trial period (2-4 weeks), review actual usage and set pricing. Ballpark: ~$300/project or ~$3,000/month. Revisit once we have real data.

**No dashboard for MVP**. Query Convex directly or export to spreadsheet. Build a dashboard later if needed.

**Level of Effort**: Low (just log the data)

---

### 3.5 Logging and Observability — `MINIMAL (~20%)`

> **Implementation Status (Feb 2026):** Basic tracing config exists (`src/lib/tracing.ts`) with `TRACING_ENABLED` env var. Pipeline event bus emits internal events. Agent metrics record duration. Missing: No Sentry integration, no structured logging with levels, no correlation IDs, no PostHog analytics. Logging is ad-hoc `console.log` throughout.

**Goal**: When something breaks for Antares, we can debug it.

**Structured Logging** (see `logging-implementation-plan.md` for details):
- Centralized logger with log levels (error, warn, info, debug)
- Correlation IDs to trace a job through all stages
- Sentry for error alerting

**Product Analytics** (lightweight for MVP):
- Track key events: `project_created`, `job_completed`, `job_failed`, `download_completed`
- PostHog JS SDK in frontend
- Enough to understand usage patterns; expand later based on what questions we have

**Level of Effort**: Low-Medium (logging foundation + basic event tracking)

---

## MVP Complete

**Completing Phase 3 = MVP = The Product.**

At this point, HawkTab AI is a fully functional, cloud-hosted service that external parties like Antares can use to generate publication-quality crosstabs.

Some items in Phase 2 and 3 may be deferred or simplified depending on what we learn during implementation. The goal is a reliable, usable product—not feature completeness for its own sake.

---

## Long-term Vision

Bob's observation from the Antares conversation: *"I've not seen anybody kind of going down this road... commercially speaking."*

What makes HawkTab unique is the **validated data foundation**. Every crosstab run produces artifacts that already executed successfully—verified variables, working R expressions, human-approved cuts. This foundation could eventually support follow-up queries and conversational exploration without the hallucination problems that plague other AI-on-data tools.

But that only matters if the core system is reliable. That's what we're focused on now.

### Configurable Assumptions & Regeneration

HawkTab makes defensible statistical assumptions when generating crosstabs — particularly for looped/stacked data. These assumptions are specific choices from a finite set of valid approaches:

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
- Assumptions surfaced in plain language (Methodology sheet — see 2.4b context)
- A mapping of each assumption to its alternatives (schema-driven, not free-form)
- A regeneration path that re-runs R script generation + execution without re-running the full pipeline
- The resume script (`test-loop-semantics-resume.ts`) is already a prototype of this pattern

**Why this matters commercially:** No other tool in this space surfaces its assumptions, let alone lets you change them. WinCross, SPSS Tables, and Q all make implicit choices that users can't inspect or override. Making assumptions explicit and configurable is a differentiator that builds trust with sophisticated research buyers.

This is a long-term feature — the foundation (correct defaults + validation proof) comes first.

---

### Predictive Confidence Scoring (Pre-Flight)

*Moved from former Phase 1.5.*

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

**When to revisit:** After Part 4 broader testing is complete and we have failure data across 20+ datasets with diverse characteristics. If clear patterns emerge (e.g., "datasets with no deterministic resolver evidence fail 80% of the time"), then a predictor becomes viable.

---

### Variable Selection Persistence

*Moved from Phase 2.4c.*

The crosstab agent's variable selection is non-deterministic — same dataset can produce different variable mappings across runs. Once a user confirms a mapping via HITL or accepts a successful run's output, lock those selections as project-level overrides so future re-runs don't re-roll the dice.

**What gets saved:** Banner group name → variable mappings, confirmation source ("user_confirmed" or "accepted_from_run_N"). Stored as `confirmed-cuts.json` in the project folder. The crosstab agent prompt includes a "locked selections" section — variables in this list are not re-evaluated.

**Why it matters:** Eliminates "it worked last time but not this time." First step toward accumulating project-level knowledge across runs.

**Level of Effort:** Low (JSON persistence + prompt section, no architectural changes)

---

### Interactive Table Review

*Consolidated from former Phase 2.9 (include/exclude control), 2.10 (table feedback & regeneration), and 2.12 (interactive browser review).*

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

### Dual-Mode Loop Semantics Prompt

*Moved from Phase 2.4d.*

The Loop Semantics Policy Agent uses a single prompt regardless of how much deterministic evidence is available. When the resolver finds strong evidence, the prompt works well. When there's none, the LLM must infer from cut patterns and datamap descriptions alone — harder and less reliable.

**Solution:** Two prompt variants selected automatically based on `deterministicFindings.iterationLinkedVariables.length`. High-evidence prompt anchors on resolver data. Low-evidence prompt adds pattern-matching guidance for OR expressions, emphasizes datamap descriptions, lowers confidence thresholds for `humanReviewRequired`, and includes more few-shot examples.

**Level of Effort:** Low (second prompt file in `src/prompts/loopSemantics/alternative.ts` + selection logic in agent)

**When to revisit:** If batch testing reveals classification failures on datasets where the deterministic resolver finds nothing.

---

## Known Gaps & Limitations

Documented as of February 2026. These are areas where the system has known limitations — some with mitigation paths already identified, others that may define the boundary of what HawkTab can handle. Even where solutions exist, it's important to be aware of these when communicating capabilities externally or testing against new datasets.

### Loop Semantics

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No deterministic evidence** — SPSS file has no label tokens, suffix patterns, or sibling descriptions. LLM must infer entirely from cut patterns and datamap context. | Medium | Dual-mode prompt (2.4d). Long-term: predictive confidence scoring (see Long-term Vision). | Identified, not implemented |
| **Irregular parallel variable naming** — Occasion 1 uses Q5a, occasion 2 uses Q7b, occasion 3 uses Q12. No naming relationship. Resolver can't match. | Medium | LLM prompt must handle this from datamap descriptions. Few-shot examples for irregular naming. Some surveys may be unfixable without user hints. | Partially mitigated by LLM |
| **Complex expression transformation** — `transformCutForAlias` handles `==`, `%in%`, and OR patterns. Expressions with `&` conditions, nested logic, or negations could break transformation. | Low-Medium | Expand transformer for common compound patterns. Flag untransformable expressions for human review. | Common cases handled |
| **Multiple independent loop groups** — Dataset with both an occasion loop AND a brand loop. Architecturally supported but never tested. | Low | Schema and pipeline support N loop groups. Needs integration testing with a real multi-loop dataset. | Untested |
| **Nested loops** — A brand loop inside an occasion loop. Not handled. | Low | Not supported. Validation already detects loops; nested loop detection could be added as a basic sanity check. | Not supported |
| **Weighted stacked data** — Weights exist in the data but aren't applied during stacking or computation. | High | Next priority after loop semantics. R's `svydesign` handles weighted calculations natively. | Not implemented |
| **No clustered standard errors** — Stacked rows from the same respondent are correlated, which overstates significance. Standard tests treat them as independent. This is industry-standard behavior (WinCross, SPSS Tables, Q all do the same). | Low | Accept as industry-standard limitation. Future differentiator if implemented. Would require respondent ID column in stacked frame + cluster-robust R functions. | Known limitation, not planned |
| **No within-group stat letter suppression for entity-anchored groups** — `generateSignificanceTesting()` doesn't consult the loop semantics policy. Within-group pairwise comparisons run for all groups regardless of overlap. Validation detects overlaps but doesn't act on them. | Medium | Implement 2.4b (suppress or vs-complement testing for entity-anchored groups). | Not implemented |

### Crosstab Agent

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **Non-deterministic variable selection** — Same dataset can produce different variable mappings across runs. | Medium | Hidden variable hints help steer. Variable selection persistence (2.4c) locks in confirmed choices. HITL for low-confidence cuts. | Partially mitigated |
| **Hidden variable conventions vary by platform** — h-prefix and d-prefix patterns are Decipher/FocusVision conventions. Other platforms (Qualtrics, SurveyMonkey, Confirmit) use different naming. | Low-Medium | Expand hint patterns as we encounter new platforms. The datamap description is platform-agnostic and usually contains enough signal. | Platform-specific hints added |

### General Pipeline

| Gap | Severity | Mitigation | Status |
|-----|----------|------------|--------|
| **No pre-flight confidence assessment** — Pipeline runs for 45+ minutes before discovering it can't handle a dataset reliably. | Medium-High | Long-term: predictive confidence scoring (see Long-term Vision). Requires failure data across 50+ datasets before a predictor is viable. Near-term: project intake questions (3.1) set expectations upfront. | Deferred to Long-term Vision |
| **No methodology documentation in output** — Users receive numbers without explanation of how they were computed. Assumptions are implicit. | Medium | Methodology sheet in Excel (Configurable Assumptions vision). Policy agent + validation results provide the content. | Planned |
| **No project-level knowledge accumulation** — Each pipeline run starts fresh. Confirmed variable mappings, user preferences, and past decisions aren't carried forward. | Low-Medium | Variable selection persistence (2.4c) is the first step. Longer-term: project-level config that accumulates across runs. | Identified |
| **Hidden assignment variables don't produce distribution tables** — When a question's answers are stored as hidden variables (e.g., `hLOCATIONr1–r16` for S9), the pipeline correctly hides them but misses the distribution table that shows assignment frequency. Requires parent-variable linking in DataMapProcessor or verification agent awareness. | Low | Accept gap for now. Future: detect when hidden variable families relate to a visible question and auto-generate distribution tables. | Known limitation |
| **No dual-base reporting for skip logic questions** — When a question has skip logic, only the filtered base is reported. An experienced analyst might also report the same table with an all-respondents base for context (e.g., "what share of everyone had 2+ people present" vs "among those not alone, group size distribution"). Current behavior is correct; this is a future quality-of-life enhancement. | Low | Future: optional "also report unfiltered" flag on skip logic tables, generating both versions with clear base text. | Known limitation |
| **`deriveBaseParent()` doesn't collapse parent references for loop variables** — In LoopCollapser.ts, when a collapsed variable's parent is itself a loop variable being collapsed, `deriveBaseParent()` returns the uncollapsed parent name (e.g., `A7_1` instead of `A7`). DataMapGrouper then uses this uncollapsed parent as the `questionId`, causing loop variables like A7 to appear with inconsistent naming (e.g., `a7_1` instead of `a7`). Non-loop parents like A4 are unaffected. | Low | Fix `deriveBaseParent()` to check if the derived parent is in the collapse map and resolve it to the collapsed form. Straightforward code fix. | Known limitation |
| **No Excel or TXT input support** — Survey and banner plan inputs only accept PDF and DOCX. Excel banner plans (sometimes sent by clients) and TXT files are not supported. Users must export/convert to PDF or DOCX before uploading. | Low | Could add Excel parsing + structure detection for banner plans if demand warrants it. TXT is unlikely to be needed. | By design |

---

*Created: January 22, 2026*
*Updated: February 8, 2026*
*Status: Planning — Implementation status audit completed Feb 8, 2026*
