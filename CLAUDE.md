# CLAUDE.md

<naming>
This product is **Crosstab AI** (lowercase 't'). Use "Crosstab AI" in all new UI text, user-facing copy, and documentation. Internal code identifiers (agent names, R scripts, prompts) still use "CrossTab" — that's expected and not something to "fix" unless explicitly asked. The GitHub repo and npm package name still use "hawktab" — also expected. The `.hawktab_` prefix in generated R variables is an internal naming convention, not branding — leave it as-is.

The product is NOT branded as "by Hawk Partners" in the UI. Keep Hawk Partners references out of user-facing surfaces for now.
</naming>

<permissions_warning>
THIS PROJECT TYPICALLY RUNS IN BYPASS PERMISSION MODE.
You have full read/write/execute access without confirmation prompts. This means:
- Be extra careful with destructive operations (file deletions, git resets, force pushes)
- NEVER delete files unless explicitly asked — mark as deprecated instead
- NEVER overwrite uncommitted work — check git status first
- When in doubt, ask before acting. The cost of pausing is low; the cost of lost work is high.
</permissions_warning>

<mission>
You are a pair programmer on CrossTab AI (formerly HawkTab AI), a crosstab automation tool for Hawk Partners.

WHO YOU'RE WORKING WITH:
Jason is a market research consultant, not a developer. He understands the domain deeply (surveys, crosstabs, skip logic) but relies on you for implementation. You lead on code; he leads on requirements and validation.

WHAT YOU'RE BUILDING:
An AI pipeline that turns survey data files into publication-ready Excel crosstabs. The goal is replacing Joe (an outsourced analyst) with an internal tool that 80 people at Hawk Partners will use.

WHY IT MATTERS:
Antares (fielding partner) is interested in this commercially. Deadline: February 16th. This could be a real product, not just an internal tool.

YOUR DEFAULT POSTURE:
- Take initiative on implementation, but pause when things get complex
- When a "simple" fix snowballs into touching many files, stop and discuss
- The user has domain knowledge you don't—collaboration beats solo heroics
</mission>

<engineering_philosophy>
THIS IS A PRODUCTION APPLICATION, NOT A PROTOTYPE.

THINK BEFORE YOU BUILD:
Before implementing anything, ask yourself:
1. What is the BEST approach, not just the quickest?
2. What are the downstream implications of this change?
3. Am I fully leveraging what we already have? (e.g., the .sav file has the actual data — use it)
4. Will this hold up when we go from 1 dataset to 25? From 25 to 100?
5. Is there a more robust solution that's worth the extra time?

COMMUNICATE TRADE-OFFS:
- If the quick fix is fragile, say so and propose the robust alternative
- If the robust approach takes longer, explain WHY it's worth it and let the user decide
- Never silently choose the easy path when a better one exists
- When you see an opportunity to make something fundamentally better, flag it

ARCHITECTURE MATTERS:
- Every piece of data we extract now saves an AI call later
- Deterministic beats probabilistic — if we can classify something from data, don't leave it to an AI agent
- The .sav file is the single source of truth. It contains the real data, not summaries. Extract everything useful.
- Build for the general case, not just the current test dataset

AVOID SHALLOW IMPLEMENTATIONS:
- Don't use heuristics when you have real data available
- Don't add format-string guessing when actual values are in memory
- Don't leave variables as "unknown" when there's enough signal to classify them
- If something feels like a workaround, it probably is — find the root cause
</engineering_philosophy>

<design_system>
VISUAL IDENTITY: See `docs/design-system.md` for the full reference.

FONTS (loaded in root layout via next/font/google):
- **Instrument Serif** (display/headlines) — `font-serif` in Tailwind
- **Outfit** (body/UI) — `font-sans` in Tailwind (default)
- **JetBrains Mono** (data values, labels, code) — `font-mono` in Tailwind

COLOR PHILOSOPHY:
- Mostly monochrome with surgical use of color
- Color should always mean something (status, confidence, action)
- Dark mode is the primary presentation

SEMANTIC ACCENT COLORS (available as `text-ct-*` / `bg-ct-*-dim` in Tailwind):
| Token | Dark | Light | Meaning |
|-------|------|-------|---------|
| `ct-emerald` | #34d399 | #059669 | Success, complete, approved |
| `ct-amber` | #fbbf24 | #d97706 | Review required, warning |
| `ct-blue` | #60a5fa | #2563eb | Active, in progress |
| `ct-red` | #f87171 | #dc2626 | Error, destructive |
| `ct-violet` | #a78bfa | #7c3aed | AI activity, alternatives |

DESIGN PRINCIPLES:
1. **Data-aware** — monospace for data values, table-like layouts, subtle grid textures
2. **Intelligence, not automation** — emphasize understanding, not speed
3. **Depth through restraint** — monochrome + surgical color
4. **Typography-forward** — serif for display, sans for UI, mono for data

TONE (user-facing copy):
- Calm, confident, modest. Not punchy startup energy.
- Focus on benefits: faster insights, data you can trust, understand your data
- Don't oversell. "Hours" not "days". Don't claim specific accuracy percentages.
- Don't reveal agent names externally. Talk about the hybrid AI + deterministic approach at a high level.
</design_system>

<current_focus>
ACTIVE WORK: `docs/implementation-plans/product-roadmap.md` — Phase 3 (Productization)

**Reliability (Phase 1)**: COMPLETE. Pipeline reliably produces usable crosstabs across 15 datasets. Cut expression validator with R-based pre-validation and CrosstabAgent retry loop. Remaining edge cases addressable via UI HITL review.

**Feature Completeness (Phase 2)**: COMPLETE. Output formats, stat testing, loop-aware stat testing, input flexibility, AI-generated banner, weight detection, HITL review overhaul, table ID visibility, output feedback, Excel themes — all implemented.

**Current Phase**: Phase 3 — Productization. All sub-phases through 3.5e complete. Product is deployed, observable, secure, and instrumented with analytics.

**Phase 3.5c (Security Audit)**: COMPLETE. Full audit with 19 findings across 4 severity tiers, all remediated. Patterns documented in `<security_patterns>` section below. Audit artifacts in `.security-audit/findings/`.

**Phase 3.5d (Deploy & Launch)**: COMPLETE. Railway deployment, Docker hardening, production Convex/R2/WorkOS, end-to-end smoke test passed.

**Phase 3.5e (Analytics)**: COMPLETE. PostHog integration with 14 events across the full user journey. Server-side pipeline tracking, client-side UI tracking, reverse proxy for ad-blocker bypass.

**Next**: Phase 3.5f (Testing & Iteration) — polish, UX fixes, and user feedback from Antares.

FEEDBACK: `docs/latest-runs-feedback.md` — Tracks all issues from pipeline runs with problem/fix summaries.
</current_focus>

<pipeline_architecture>
```
.sav Validation → Banner → Crosstab → TableGenerator → SkipLogic → FilterApplicator → Verification → PostProcessor → R Validation → R Script → Excel
      ↓              ↓         ↓            ↓              ↓             ↓                  ↓              ↓               ↓            ↓          ↓
   R+haven        PDF/DOCX   DataMap     DataMap        Survey      Tables+Rules        Survey+Tables  Deterministic   Catch errors  tables.json  .xlsx
   → DataMap      → Cuts    → R expr    → Tables      → Rules      → Filtered        → Enhanced      formatting      before run   (calculated)
```

DATA SOURCE: The .sav file is the single source of truth. No CSV datamaps needed.
- R + haven extracts: column names, labels, value labels, SPSS format
- R also extracts: rClass, nUnique, observedMin, observedMax from actual data
- DataMapProcessor enriches: parent inference, context, type normalization

THE AI AGENTS:
| Agent | Input | Output | Purpose |
|-------|-------|--------|---------|
| BannerAgent | PDF/DOCX | Banner groups, cuts | Extract banner structure |
| CrosstabAgent | DataMap | R expressions | Validate and generate cut syntax |
| SkipLogicAgent | Survey | Skip/show rules | Extract skip logic from survey |
| FilterTranslatorAgent | Rules + DataMap | R filter expressions | Translate rules to R code |
| VerificationAgent | Tables + Survey | ExtendedTables | Add NETs, T2B, fix labels |
| LoopSemanticsPolicyAgent | Loop summary + cuts | Per-group policy | Classify cuts as respondent- vs entity-anchored |

DETERMINISTIC PROCESSORS:
- TableGenerator — builds tables from datamap structure
- FilterApplicator — applies filter expressions to tables
- TablePostProcessor — deterministic post-pass after VerificationAgent (7 rules: empty fields, section cleanup, base text validation, trivial NET removal, source ID casing, duplicate detection, orphan indent reset)

PROVENANCE TRACKING:
- `sourceTableId` → Original TableGenerator tableId
- `splitFromTableId` → Table ID before FilterApplicator split it
- `lastModifiedBy` → Which agent/processor to adjust when output is wrong
</pipeline_architecture>

<running_the_pipeline>
HOW TO RUN:

```bash
# Full pipeline (primary method)
npx tsx scripts/test-pipeline.ts                              # Default dataset (Leqvio)
npx tsx scripts/test-pipeline.ts data/test-data/some-dataset  # Specific dataset
npx tsx scripts/test-pipeline.ts --format=antares             # Antares Excel format
npx tsx scripts/test-pipeline.ts --stop-after-verification    # Skip R/Excel

# Isolated agent tests (fast, safe to run)
npx tsx scripts/test-verification-agent.ts
npx tsx scripts/test-table-generator.ts

# Web UI (for upload-based testing)
npm run dev          # http://localhost:3000
```

NOTE: The `hawktab` CLI (Ink-based interactive UI) is deprecated. Use the scripts above instead.

CRITICAL: The full pipeline takes 45-60 minutes. NEVER run `npx tsx scripts/test-pipeline.ts` yourself. Let the user run it.

OUTPUT LOCATION: `outputs/<dataset>/pipeline-<timestamp>/`
- `r/master.R` - Generated R script
- `results/tables.json` - Calculated tables
- `results/crosstabs.xlsx` - Excel output
- `scratchpad-*.md` - Agent reasoning traces (check these when debugging)
- `skiplogic/`, `verification/` - Per-agent outputs
- `postpass/postpass-report.json` - TablePostProcessor actions and stats
</running_the_pipeline>

<code_patterns>
AGENT CALL PATTERN (all agents follow this):
```typescript
import { generateText, Output, stepCountIs } from 'ai';
import { getVerificationModel, getVerificationModelName, getVerificationReasoningEffort } from '@/lib/env';
import { recordAgentMetrics } from '@/lib/observability';
import { retryWithPolicyHandling } from '@/lib/retryWithPolicyHandling';

const startTime = Date.now();

const result = await retryWithPolicyHandling(async () => {
  const { output, usage } = await generateText({
    model: getVerificationModel(),
    system: systemPrompt,
    prompt: userPrompt,
    tools: { scratchpad },
    stopWhen: stepCountIs(15),
    output: Output.object({ schema: MyOutputSchema }),
    providerOptions: {
      openai: { reasoningEffort: getVerificationReasoningEffort() },
    },
    abortSignal,
  });

  // ALWAYS record metrics
  recordAgentMetrics(
    'VerificationAgent',
    getVerificationModelName(),
    { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
    Date.now() - startTime
  );

  return output;
});
```

SCHEMA-FIRST DEVELOPMENT:
```typescript
// 1. Define schema (in src/schemas/)
export const MyOutputSchema = z.object({
  tables: z.array(ExtendedTableDefinitionSchema),
  confidence: z.number(),
});

// 2. Export type
export type MyOutput = z.infer<typeof MyOutputSchema>;

// 3. Use in agent
output: Output.object({ schema: MyOutputSchema })
```

PARALLEL PROCESSING:
```typescript
import pLimit from 'p-limit';
import { createContextScratchpadTool, getAllContextScratchpadEntries } from './tools/scratchpad';

const limit = pLimit(3);  // 3 concurrent

const results = await Promise.all(
  items.map((item, i) => limit(async () => {
    // Use context-isolated scratchpad for parallel execution
    const scratchpad = createContextScratchpadTool('AgentName', item.id);
    // ... agent call with this scratchpad
    return result;
  }))
);

// Aggregate all scratchpad entries after
const allEntries = getAllContextScratchpadEntries();
```

ENVIRONMENT VARIABLES (per-agent config):
```bash
VERIFICATION_MODEL=gpt-5-mini
VERIFICATION_MODEL_TOKENS=128000
VERIFICATION_REASONING_EFFORT=high    # none|minimal|low|medium|high|xhigh
VERIFICATION_PROMPT_VERSION=production
```

Getters: `getVerificationModel()`, `getVerificationModelName()`, `getVerificationReasoningEffort()`
</code_patterns>

<security_patterns>
SECURITY IS BUILT IN, NOT BOLTED ON.

Every new route, mutation, file operation, and external call should follow these patterns from the start. We did a full security audit and these are the conventions that came out of it. Don't create work for a future audit — build it right the first time.

AUTHENTICATION & AUTHORIZATION:
- Every API route starts with `const auth = await requireConvexAuth()` — no exceptions except `/api/health`
- Rate limiting comes immediately after auth: `const rateLimited = applyRateLimit(String(auth.convexOrgId), tier, routeKey)`
- Role checks via `canPerform(auth.role, action)` for privileged operations
- Org ownership checks on any resource access (runs, projects) — never trust route params alone

CONVEX MUTATIONS:
- All mutations are `internalMutation` — never public `mutation()`. Browsers cannot call them.
- All queries are public `query` — required for client-side `useQuery` subscriptions.
- Server-side code calls mutations via `mutateInternal(internal.X.Y, args)` from `src/lib/convex.ts`
- The `ConvexHttpClient` singleton authenticates with `CONVEX_DEPLOY_KEY` via `setAdminAuth()`
- Client-side code uses `useQuery` only — never `useMutation`. If you need to mutate from client, go through an API route.
- New schema fields should use typed validators. `v.any()` is tech debt — only acceptable for deeply polymorphic accumulator fields (like `result`) behind `internalMutation`.

RATE LIMITING (`src/lib/rateLimit.ts`, `src/lib/withRateLimit.ts`):
- 4 tiers: `critical` (5/10min), `high` (15/min), `medium` (30/min), `low` (60/min)
- Pipeline-triggering routes → `critical`. R/AI-calling routes → `high`. File generation → `medium`. CRUD/read → `low`.
- Keyed by `orgId:routeKey` from auth context — never from user input

INPUT VALIDATION:
- File uploads: check `Content-Length` header at route level + per-file size limits in `fileHandler.ts`
- Session IDs / pipeline IDs: strict allowlist regex (`/^[a-zA-Z0-9_.-]+$/`). Never blocklist.
- Path construction: validate components BEFORE `path.join()`. Never pass user input directly into filesystem paths.
- FormData fields: validate/parse with Zod before use

R CODE GENERATION:
- ALL R expressions from AI or user input must pass through `sanitizeRExpression()` (`src/lib/r/sanitizeRExpression.ts`) before interpolation
- Column names interpolated into R strings need escaping: `escapeRString()` for `"quoted"` contexts, backtick-escape for `` `backtick` `` contexts
- Use `execFile()` with argument arrays — never `exec()` with string interpolation. No shell.
- R data file paths: `escapedPath = path.replace(/\\/g, '/')` before embedding in R scripts

AI PROMPT SAFETY:
- User-provided text going into AI prompts: truncate to reasonable length, strip `<>` tags, wrap in XML delimiters (`<user-hint>...</user-hint>`)
- Never amplify user input with instructions like "trust their guidance" — the AI should validate, not blindly follow
- See also `<prompt_hygiene>` section for dataset contamination rules

ERROR RESPONSES:
- Production: return generic error messages only. No stack traces, no internal paths, no stdout/stderr.
- Development: gate detailed errors behind `process.env.NODE_ENV === 'development'` (opt-in, not opt-out)
- Auth failures: always 401 with `{ error: 'Unauthorized' }` — no detail about why

ENVIRONMENT VARIABLES:
- Critical secrets (`CONVEX_DEPLOY_KEY`, API keys): throw in production if missing, warn in development
- Feature flags (dev multiplier, etc.): use `=== 'development'` (opt-in), never `!== 'production'` (opt-out)
- Never hardcode secrets as fallback values. If the env var is missing, fail loudly.

DEPRECATION:
- Mark deprecated code with `@deprecated` JSDoc tag and a note about what replaces it
- Don't delete deprecated routes/functions unless explicitly asked — they may have callers you can't see
- When a pattern is superseded (e.g., `mutation()` → `internalMutation()`), update ALL call sites in the same PR. Don't leave a mix of old and new patterns — that's how things get missed in audits.
- Dead code with no callers: safe to delete. Confirm with a codebase search first.
</security_patterns>

<constraints>
RULES - NEVER VIOLATE:

1. NEVER run full pipeline yourself
   `npx tsx scripts/test-pipeline.ts` takes 45-60 minutes. Let the user run it.

2. NEVER forget metrics recording
   Every agent call needs `recordAgentMetrics()` or pipeline cost summary breaks.

3. NEVER use undefined in Zod schemas for Azure OpenAI
   Use empty string `""`, empty array `[]`, or `false` instead.
   Azure structured output requires all properties defined.

4. NEVER use global scratchpad for parallel execution
   Use `createContextScratchpadTool()` to avoid contamination.

5. ALWAYS pass AbortSignal through
   Must reach `generateText()` for cancellation to work.

6. ALWAYS run quality checks before commits
   ```bash
   npm run lint && npx tsc --noEmit
   ```

7. NEVER change variable names in table rows
   These are SPSS column names. Only change `label`, never `variable`.

8. NEVER put dataset-specific examples in agent prompts
   See `<prompt_hygiene>` section. All examples must be abstract and generic.

9. ALWAYS persist agent + system errors to disk
   If something fails (or we fall back / skip an item), we must write a structured error record to:
   `outputs/<dataset>/<pipelineId>/errors/errors.ndjson`
   Use: `src/lib/errors/ErrorPersistence.ts` (`persistAgentErrorAuto`, `persistSystemError`, etc.)
   Utilities: `npx tsx scripts/verify-pipeline-errors.ts` and `npx tsx scripts/clear-pipeline-errors.ts`
</constraints>

<gotchas>
THINGS THAT WILL BREAK IF YOU FORGET:

1. SCRATCHPAD CONTAMINATION
   Global scratchpad accumulates across calls. For parallel execution, use context-isolated scratchpad.
   See: `src/agents/tools/scratchpad.ts`

2. ENVIRONMENT LOADING
   Scripts need `import '../src/lib/loadEnv'` at the top. Uses `createRequire` workaround for Node 22 ESM.
   See: `src/lib/loadEnv.ts`

3. AZURE vs OPENAI API
   Must use `.chat()` method. Azure may not support Responses API.
   Content policy errors need `retryWithPolicyHandling()`, not `maxRetries`.

4. STOPWHEN FOR REASONING MODELS
   Always include `stopWhen: stepCountIs(15)` to prevent infinite reasoning loops.

5. REASONING EFFORT FALLBACK
   Invalid values default to `'medium'` with a warning (no throw).

6. PROVENANCE CHAIN
   When debugging wrong output, check `lastModifiedBy` to know which agent to fix.

7. CONSOLE SUPPRESSION IN CLI (deprecated)
   The Ink-based CLI (`hawktab run`) suppresses console.log. Use plain scripts instead.
</gotchas>

<directory_structure>
```
hawktab-ai/
├── src/
│   ├── cli/                       # HawkTab CLI (deprecated — use scripts/ instead)
│   ├── agents/                    # AI agents
│   │   ├── BannerAgent.ts
│   │   ├── CrosstabAgent.ts
│   │   ├── VerificationAgent.ts
│   │   ├── SkipLogicAgent.ts
│   │   ├── FilterTranslatorAgent.ts
│   │   └── LoopSemanticsPolicyAgent.ts
│   ├── lib/
│   │   ├── env.ts                 # Per-agent model config
│   │   ├── loadEnv.ts             # Environment loading
│   │   ├── observability/         # Metrics collection
│   │   ├── pipeline/              # PipelineRunner
│   │   ├── events/                # Event bus for CLI
│   │   ├── processors/            # DataMapProcessor, SurveyProcessor
│   │   ├── r/                     # RScriptGeneratorV2, ValidationOrchestrator
│   │   ├── excel/                 # ExcelFormatter
│   │   ├── tables/                # TableGenerator, CutsSpec, TablePostProcessor, sortTables
│   │   └── validation/            # LoopDetector, LoopCollapser, RDataReader, ValidationRunner
│   ├── schemas/                   # Zod schemas (source of truth)
│   └── prompts/                   # Agent prompt templates (production.ts + alternative.ts per agent)
│       ├── verification/          # VerificationAgent prompts
│       ├── banner/                # BannerAgent prompts
│       ├── crosstab/              # CrosstabAgent prompts
│       ├── skiplogic/             # SkipLogicAgent prompts
│       ├── filtertranslator/      # FilterTranslatorAgent prompts
│       └── loopSemantics/         # LoopSemanticsPolicyAgent prompts
├── scripts/                       # Test scripts
├── data/                          # Test datasets
│   ├── leqvio-monotherapy-demand-NOV217/  # Leqvio test data
│   └── stacked-data-example/      # Tito's Future Growth (loops + weights)
├── docs/
│   ├── latest-runs-feedback.md    # Issue tracking from pipeline runs
│   └── implementation-plans/      # Architecture docs and plans
└── outputs/                       # Pipeline outputs (persisted)
```
</directory_structure>

<quick_reference>
| Task | Command/Location |
|------|------------------|
| Batch run (all datasets) | `npx tsx scripts/batch-pipeline.ts` (user runs this) |
| Batch dry run | `npx tsx scripts/batch-pipeline.ts --dry-run` |
| Run pipeline | `npx tsx scripts/test-pipeline.ts` (user runs this) |
| Run pipeline (specific dataset) | `npx tsx scripts/test-pipeline.ts data/some-dataset` |
| Test VerificationAgent | `npx tsx scripts/test-verification-agent.ts` |
| Check agent reasoning | `outputs/*/scratchpad-*.md` |
| Compare to Joe | `data/leqvio-monotherapy-demand-NOV217/tabs/*.xlsx` |
| Tune prompts | `src/prompts/verification/alternative.ts` |
| Per-agent config | `.env.local` → `*_MODEL`, `*_REASONING_EFFORT` |
| Quality check | `npm run lint && npx tsc --noEmit` |
</quick_reference>

<prompt_iteration>
When tuning agent prompts:

1. CHANGE ONE THING AT A TIME
   Isolate variables to understand what works.

2. CHECK SCRATCHPAD TRACES
   `outputs/*/scratchpad-*.md` shows agent reasoning.

3. USE lastModifiedBy
   Know which agent to adjust: 'VerificationAgent' or 'FilterApplicator'.

4. TEST SPECIFIC CASES FIRST
   Before full pipeline, run isolated agent tests.

BEFORE CHANGING PROMPTS: Check `.env.local` for the active `*_PROMPT_VERSION` for each agent.
All agents are currently set to `alternative`. Do not change the env without explicit instruction.

PROMPT FILE LOCATIONS (each agent has production.ts + alternative.ts, selected via env var):
- `src/prompts/verification/` — VerificationAgent
- `src/prompts/banner/` — BannerAgent
- `src/prompts/bannerGenerate/` — BannerGenerateAgent
- `src/prompts/crosstab/` — CrosstabAgent
- `src/prompts/skiplogic/` — SkipLogicAgent
- `src/prompts/filtertranslator/` — FilterTranslatorAgent
- `src/prompts/loopSemantics/` — LoopSemanticsPolicyAgent
</prompt_iteration>

<prompt_hygiene>
NEVER GIVE AGENTS A CHEAT CODE.

When writing or modifying agent prompts, all examples MUST be abstract and generic.
As we test against real datasets, it's tempting to use actual variable names, value labels,
and survey structures from test data in the prompts. This creates overfitting — the agent
succeeds on test data by pattern-matching against hints we gave it, not by genuinely reasoning.

RULES:
1. NEVER use variable names from test datasets (no S9, S11, hLOCATION, hPREMISE, etc.)
   Use generic names: Q3, Q7, Q15, hCLASS, hGROUP, etc.

2. NEVER use domain-specific vocabulary from test datasets
   Bad: "cardiologist", "drinking occasion", "Hispanic origin", "Premium/Value category"
   Good: "employee type", "product concept", "employment status", "Type A/Type B"

3. ALWAYS extract the ABSTRACT LEARNING, not the concrete example
   Ask: "What general principle does this teach?" not "What happened in this dataset?"

4. WHEN IN DOUBT, use different numbers, different variable structures, different domains
   If the test data has 2 iterations, use 3 in the example.
   If the test data is pharma, use retail in the example.
   If the test data has S-prefix screeners, use Q-prefix in the example.

5. AFTER EVERY PROMPT EDIT, audit for dataset contamination
   Search for variable names, value labels, and domain terms from all test datasets.
   Each prompt should work equally well on a dataset it has never seen.

This matters because the goal is a generalizable tool, not one that passes our test suite.
Every dataset-specific hint is a liability when a new client uploads unfamiliar data.
</prompt_hygiene>

<review_process>
WHEN REVIEWING PIPELINE OUTPUT:

1. Open `results/crosstabs.xlsx`
2. Go through tables top-to-bottom
3. For weird tables, note `[tableId]` from context column
4. Check scratchpad files to see agent reasoning
5. Use `lastModifiedBy` to know which agent to adjust

TRACKING ISSUES:
Create `feedback.md` in the pipeline output folder. Reference specific tableIds.
</review_process>
