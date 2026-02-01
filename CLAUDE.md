# CLAUDE.md

Guidance for Claude Code when working in this repository.

---

## How We Work Together

Claude is my pair programmer. I'm a market research consultant, not super technical—so teamwork makes the dream work. I'm happy to let Claude take the lead on implementation, but we're collaborators.

**Philosophy**

- **We're replacing Joe's usefulness, not replicating his exact format.** Antares-style output is our MVP target—functional, readable crosstabs that the team can write reports from.
- **Production quality for internal tools**: 80 people will use this with real client data. Type-safe, validated, observable.
- **Iterate based on evidence**: Review outputs, compare to Joe's tabs, make targeted fixes.

---

## Context: Antares Partnership Opportunity

We recently spoke with Antares (our fielding partner). Key quote from Bob:

> "This is actually very intriguing. I've not seen anybody kind of going down this road... commercially speaking. I haven't seen any of the normal players out there working on this technology or approach."

**Deadline**: We need to send Antares an updated version by **February 16th** (Monday). This means finishing the reliability plan and product roadmap by February 15th. This could be our big break—build quickly, but reliably and accurately.

See `docs/antares-hawktabai-discussion-transcript-012226.txt` for the full conversation.

---

## When Problems Snowball

When an implementation becomes harder than expected—when one fix leads to another fix, which leads to another—**pause, explain to the user, and wait for input**.

Signs to stop and discuss:
- A "simple" change is touching many files
- You're creating workarounds for workarounds
- The solution feels more complex than the problem

When this happens:
1. **Stop executing** - Don't keep trying fixes
2. Explain what you were trying to do
3. Explain what went wrong / why it's harder than expected
4. Ask if the user has context or a simpler approach
5. **Wait for the user's response** before continuing

The user often has domain knowledge or sees simpler paths. Investigation and collaboration beats solo heroics on hard problems.

---

## Current Focus: Reliability Plan

**Active Document**: `docs/implementation-plans/reliability-plan.md`

We're making HawkTab AI reliably produce publication-quality crosstabs that match Joe's output (the reference standard).

| Part | Description | Status |
|------|-------------|--------|
| 1 | Stable System for Testing | Complete |
| 2 | Leqvio Testing (iteration loop) | In Progress - Iteration 1 |
| 3 | Loop/Stacked Data Support (Tito's) | Not started |
| 4 | Strategic Broader Testing | Not started |

**Primary Test Data**: `data/leqvio-monotherapy-demand-NOV217/`
**Reference Output**: `tabs/leqvio-monotherapy-demand-tabs-joe.xlsx`

**Recent Win**: Built BaseFilterAgent to handle skip/show logic. Tables now have correct bases (different brands get different bases when show logic applies per-row). Numbers match Joe's output exactly.

---

## Pipeline Architecture

```
User Uploads → BannerAgent → CrosstabAgent → TableGenerator → VerificationAgent → BaseFilterAgent → R Validation → R Script → Excel
                   ↓              ↓              ↓                  ↓                    ↓               ↓             ↓          ↓
              Banner PDF      DataMap        DataMap            Survey Doc          Survey Doc      Catch errors   tables.json  .xlsx
              → Cuts          → Variables    → Tables           → Enhanced          → Base filters   before R run   (calculated)
```

### The Four AI Agents

| Agent | Purpose | Key Outputs |
|-------|---------|-------------|
| **BannerAgent** | Extract banner structure from PDF/DOCX | Banner groups, columns, stat letters |
| **CrosstabAgent** | Validate expressions, generate R syntax | CutDefinitions with R expressions |
| **VerificationAgent** | Enhance tables using survey document | ExtendedTableDefinitions (NETs, T2B, labels) |
| **BaseFilterAgent** | Detect skip/show logic, apply base filters | additionalFilter, table splits for different bases |

### TableGenerator (Deterministic)

The TableGenerator is **not an AI agent**—it's deterministic code that builds table definitions from the datamap. It uses `normalizedType` to decide table structure (frequency vs mean_rows). Located at `src/lib/tables/TableGenerator.ts`.

### Provenance Tracking

Each table tracks who last modified it:
- `sourceTableId` — Points back to TableGenerator's tableId (VerificationAgent sets when splitting)
- `splitFromTableId` — Points back to VerificationAgent's tableId (BaseFilterAgent sets when splitting)
- `lastModifiedBy` — Which agent last made meaningful changes ('VerificationAgent' or 'BaseFilterAgent')

### Two Interaction Modes

The pipeline can be run two ways:

| Mode | Entry Point | Use Case |
|------|-------------|----------|
| **CLI** | `npx tsx scripts/test-pipeline.ts` | Development, testing, iteration |
| **UI** | `http://localhost:3000` | User-facing uploads, future production |

The CLI is our primary development interface. UI behavior should mirror CLI pipeline behavior—when we update the pipeline, we may need to sync changes to the UI.

**Most recent run**: Pipeline outputs are saved to `outputs/<dataset>/pipeline-<timestamp>/`. The most recent run is always the latest timestamp folder.

### Cost & Time Tracking

Every agent records its token usage and duration via `recordAgentMetrics()` from `src/lib/observability.ts`. At the end of a pipeline run, `getPipelineCostSummary()` returns total cost and per-agent breakdown.

**When adding new agents or systems**: Always integrate with the metrics collector so costs appear in the pipeline summary. See existing agents for the pattern:

```typescript
import { recordAgentMetrics } from '../lib/observability';

// After generateText call:
recordAgentMetrics(
  'AgentName',
  getModelName(),
  { input: usage?.inputTokens || 0, output: usage?.outputTokens || 0 },
  durationMs
);
```

### Prompt Paths (A/B)

Some agents have multiple prompt versions for experimentation:

| Agent | Path A (production.ts) | Path B (alternative.ts) |
|-------|------------------------|-------------------------|
| VerificationAgent | Conservative, fewer changes | More aggressive table enhancement |
| BaseFilterAgent | Production prompt | (none currently) |

Select via environment variable or in code. This allows prompt iteration without losing working versions.

### Per-Agent Configuration

Each agent has independent environment variables:
```bash
# Model and reasoning effort per agent
CROSSTAB_MODEL=gpt-5-mini
CROSSTAB_REASONING_EFFORT=medium    # none|minimal|low|medium|high|xhigh

TABLE_MODEL=gpt-5-mini
TABLE_REASONING_EFFORT=high

VERIFICATION_MODEL=gpt-5-mini
VERIFICATION_REASONING_EFFORT=high

BANNER_MODEL=gpt-5-nano
BANNER_REASONING_EFFORT=medium
```

Getters in `src/lib/env.ts`: `getCrosstabModel()`, `getTableModel()`, `getVerificationModel()`, `getBannerModel()`

---

## Test Scripts

All scripts use `data/leqvio-monotherapy-demand-NOV217/` by default (with nested `inputs/` subfolder support).

```bash
# Full pipeline (10 steps: DataMap → Banner → Crosstab → Table → Verification → BaseFilter → R Validation → R Script → Excel)
npx tsx scripts/test-pipeline.ts

# Individual components
npx tsx scripts/test-table-agent.ts           # TableAgent only
npx tsx scripts/test-verification-agent.ts   # VerificationAgent only
npx tsx scripts/test-r-script-v2.ts           # R script from existing output
npx tsx scripts/export-excel.ts               # Excel from existing tables.json
```

**IMPORTANT**: The full pipeline takes 45-60 minutes to run. **Do not run it yourself**—let the user run it. Other scripts are quick and fine to run.

**Output Location**: `outputs/leqvio-monotherapy-demand-NOV217/pipeline-<timestamp>/`
- `r/master.R` - Generated R script
- `results/tables.json` - Calculated tables with significance
- `results/crosstabs.xlsx` - Formatted Excel workbook
- `scratchpad-*.md` - Agent reasoning traces (check these to understand agent decisions)
- `basefilter/` - BaseFilterAgent outputs and scratchpad
- `verification/` - VerificationAgent outputs
- `pipeline-summary.json` - Timing, cost, and metadata

---

## Directory Structure

```
hawktab-ai/
├── src/
│   ├── agents/                    # AI agents (4 total)
│   │   ├── BannerAgent.ts
│   │   ├── CrosstabAgent.ts
│   │   ├── VerificationAgent.ts
│   │   └── BaseFilterAgent.ts
│   ├── lib/tables/
│   │   └── TableGenerator.ts      # Deterministic table builder (not an AI agent)
│   ├── schemas/                   # Zod type definitions
│   │   ├── tableAgentSchema.ts        # TableDefinition
│   │   ├── verificationAgentSchema.ts # ExtendedTableDefinition
│   │   └── baseFilterAgentSchema.ts   # NEW: BaseFilterAgent I/O
│   ├── lib/
│   │   ├── env.ts                 # Per-agent model getters
│   │   ├── processors/            # DataMapProcessor, SurveyProcessor
│   │   ├── r/RScriptGeneratorV2.ts
│   │   ├── r/ValidationOrchestrator.ts # R validation + retry
│   │   ├── excel/                 # ExcelFormatter, table renderers
│   │   └── tables/CutsSpec.ts
│   └── prompts/                   # Agent prompt templates
│       └── basefilter/            # NEW: BaseFilterAgent prompts
├── scripts/                       # CLI test scripts
├── data/
│   ├── leqvio-monotherapy-demand-NOV217/  # Primary test dataset
│   │   ├── inputs/                # Input files (datamap, data.sav, etc.)
│   │   └── tabs/                  # Reference output (Joe's tabs)
│   └── test-data/                 # Additional test datasets
├── outputs/                       # Pipeline outputs (persisted)
├── docs/
│   ├── implementation-plans/
│   │   └── reliability-plan.md    # CURRENT WORK
│   └── antares-hawktabai-discussion-transcript-012226.txt
└── temp-outputs/                  # Dev outputs (git-ignored)
```

---

## Key Schemas

**TableDefinition** (`tableAgentSchema.ts`):
- Basic table structure from TableAgent
- Fields: `tableId`, `title`, `tableType`, `rows[]`, `hints[]`

**ExtendedTableDefinition** (`verificationAgentSchema.ts`):
- Enhanced table from VerificationAgent and BaseFilterAgent
- Key fields: `isNet`, `netComponents`, `indent`, `isDerived`, `exclude`, `sourceTableId`
- BaseFilterAgent fields: `additionalFilter`, `filterReviewRequired`, `splitFromTableId`
- Provenance: `lastModifiedBy` ('VerificationAgent' | 'BaseFilterAgent')

**Conversion**: `toExtendedTable(table)` converts TableDefinition → ExtendedTableDefinition

---

## Prompt Iteration Best Practices

When tuning agent prompts:

1. **Change one thing at a time** - Isolate variables to understand what works
2. **Use scratchpad traces** - Check `scratchpad-*.md` files to see agent reasoning
3. **Test on specific cases first** - Before full pipeline, test on the problematic table
4. **Document what changed and why** - Future you will thank present you
5. **Compare before/after outputs** - Save outputs before changing prompts

### Prompt File Locations
- `src/prompts/tableAgentPrompt.ts`
- `src/prompts/verificationAgentPrompt.ts`
- `src/prompts/crosstabAgentPrompt.ts`
- `src/prompts/bannerAgentPrompt.ts`

### Reasoning Effort Tuning
- Start with `medium`, increase to `high` or `xhigh` for complex decisions
- `high` is good for VerificationAgent (needs to understand survey context)
- `medium` is usually sufficient for CrosstabAgent (pattern matching)

---

## Review Process

We review outputs manually by comparing to Joe's tabs. No automated golden dataset comparison—human judgment is the standard.

**When reviewing pipeline output:**
1. Open `results/crosstabs.xlsx`
2. Go through tables top-to-bottom
3. For weird tables, note the `[tableId]` from the context column
4. Check `basefilter/scratchpad-*.md` and `verification/scratchpad-*.md` to see agent reasoning
5. Use `lastModifiedBy` field in JSON to know which agent to adjust

**Tracking issues:**
- Create `feedback.md` in the pipeline output folder
- Reference specific tableIds for traceability

---

## Development Commands

```bash
# Quality (run before EVERY commit)
npm run lint && npx tsc --noEmit

# Development
npm run dev                    # Start with Turbopack

# Full pipeline test
npx tsx scripts/test-pipeline.ts

# Quick verification test (uses latest pipeline output)
npx tsx scripts/test-verification-agent.ts
```

---

## Code Patterns

### Agent Call Pattern
```typescript
import { generateText, Output } from 'ai';
import { getVerificationModel, getVerificationReasoningEffort } from '@/lib/env';

const { output } = await generateText({
  model: getVerificationModel(),
  system: instructions,
  prompt: userPrompt,
  tools: { scratchpad },
  output: Output.object({ schema: VerificationAgentOutputSchema }),
  providerOptions: {
    openai: {
      reasoningEffort: getVerificationReasoningEffort(),
    },
  },
});
```

### Schema-First Development
Always define Zod schemas before implementation:
```typescript
// 1. Define schema
const MyOutputSchema = z.object({
  tables: z.array(ExtendedTableDefinitionSchema),
  confidence: z.number(),
});

// 2. Use in agent call
output: Output.object({ schema: MyOutputSchema })

// 3. Type is inferred
type MyOutput = z.infer<typeof MyOutputSchema>;
```

---

## Quick Reference

| Task | Command/Location |
|------|------------------|
| Run full pipeline | `npx tsx scripts/test-pipeline.ts` (let user run this - takes 45-60 min) |
| Check agent reasoning | `outputs/*/scratchpad-*.md`, `outputs/*/basefilter/scratchpad-*.md` |
| Compare to Joe's output | `data/leqvio-monotherapy-demand-NOV217/tabs/leqvio-monotherapy-demand-tabs-joe.xlsx` |
| Tune VerificationAgent | `src/prompts/verification/alternative.ts` |
| Tune BaseFilterAgent | `src/prompts/basefilter/production.ts` |
| Adjust reasoning effort | `.env.local` → `*_REASONING_EFFORT` |
| Current work | `docs/implementation-plans/reliability-plan.md` |
| Antares context | `docs/antares-hawktabai-discussion-transcript-012226.txt` |

---

## Philosophy

**We're replacing Joe's usefulness, not replicating his exact format.** Antares-style output is our MVP target—functional, readable crosstabs that the team can write reports from.

**Production quality for internal tools**: 80 people will use this with real client data. Type-safe, validated, observable.

**Iterate based on evidence**: Use the evaluation framework to track improvements, not gut feelings.
