# CLAUDE.md

Guidance for Claude Code when working in this repository.

---

## How We Work Together

Claude is my pair programmer. I'm a market research consultant, not super technical—so teamwork makes the dream work. I'm happy to let Claude take the lead on implementation, but we're collaborators.

**Philosophy**

- **We're replacing Joe's usefulness, not replicating his exact format.** Antares-style output is our MVP target—functional, readable crosstabs that the team can write reports from.
- **Production quality for internal tools**: 80 people will use this with real client data. Type-safe, validated, observable.
- **Iterate based on evidence**: Use the evaluation framework to track improvements, not gut feelings.

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
| 1 | Bug Capture | Complete |
| 2 | VerificationAgent | Complete |
| 3 | Significance Testing (unpooled z-test) | Complete |
| 3b | SPSS Validation Clarity | Complete |
| 4 | Evaluation Framework (golden dataset) | Not started |
| 5 | Iteration on practice-files | Not started |
| 6 | Broader Testing (23 datasets) | Not started |

**Test Data**: `data/test-data/practice-files/`
**Reference Output**: `leqvio-demand-tabs-joe.xlsx`

---

## Pipeline Architecture

```
User Uploads → BannerAgent → CrosstabAgent → TableAgent → VerificationAgent → R Script → Excel
                   ↓              ↓              ↓              ↓                ↓          ↓
              Banner PDF      DataMap        Questions      Survey Doc       tables.json  .xlsx
              → Cuts          → Variables    → Tables       → Enhanced        (calculated)
```

### The Four Agents

| Agent | Purpose | Key Outputs |
|-------|---------|-------------|
| **BannerAgent** | Extract banner structure from PDF/DOCX | Banner groups, columns, stat letters |
| **CrosstabAgent** | Validate expressions, generate R syntax | CutDefinitions with R expressions |
| **TableAgent** | Decide table structure per variable | TableDefinitions (frequency/mean_rows) |
| **VerificationAgent** | Enhance tables using survey document | ExtendedTableDefinitions (NETs, T2B, labels) |

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

All scripts use `data/test-data/practice-files/` by default.

```bash
# Full pipeline (8 steps: DataMap → Banner → Crosstab → Table → Verification → R → Excel)
npx tsx scripts/test-pipeline.ts

# Individual components
npx tsx scripts/test-table-agent.ts           # TableAgent only
npx tsx scripts/test-verification-agent.ts   # VerificationAgent only
npx tsx scripts/test-r-script-v2.ts           # R script from existing output
npx tsx scripts/export-excel.ts               # Excel from existing tables.json
```

**Output Location**: `temp-outputs/test-pipeline-<dataset>-<timestamp>/`
- `r/master.R` - Generated R script
- `results/tables.json` - Calculated tables with significance
- `results/crosstabs.xlsx` - Formatted Excel workbook
- `scratchpad-*.md` - Agent reasoning traces
- `pipeline-summary.json` - Timing and metadata

---

## Directory Structure

```
hawktab-ai/
├── src/
│   ├── agents/                    # AI agents
│   │   ├── BannerAgent.ts
│   │   ├── CrosstabAgent.ts
│   │   ├── TableAgent.ts
│   │   └── VerificationAgent.ts
│   ├── schemas/                   # Zod type definitions
│   │   ├── tableAgentSchema.ts        # TableDefinition
│   │   └── verificationAgentSchema.ts # ExtendedTableDefinition
│   ├── lib/
│   │   ├── env.ts                 # Per-agent model getters
│   │   ├── processors/            # DataMapProcessor, SurveyProcessor
│   │   ├── r/RScriptGeneratorV2.ts
│   │   ├── excel/                 # ExcelFormatter, table renderers
│   │   └── tables/CutsSpec.ts
│   └── prompts/                   # Agent prompt templates
├── scripts/                       # CLI test scripts
├── data/test-data/                # 23 test datasets
│   └── practice-files/            # Primary test dataset
├── docs/implementation-plans/
│   ├── reliability-plan.md        # CURRENT WORK
│   └── significance-testing-plan.md
└── temp-outputs/                  # Dev outputs (git-ignored)
```

---

## Key Schemas

**TableDefinition** (`tableAgentSchema.ts`):
- Basic table structure from TableAgent
- Fields: `tableId`, `title`, `tableType`, `rows[]`, `hints[]`

**ExtendedTableDefinition** (`verificationAgentSchema.ts`):
- Enhanced table from VerificationAgent
- Adds: `isNet`, `netComponents`, `indent`, `isDerived`, `exclude`, `excludeReason`, `sourceTableId`

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

## Evaluation Framework (Part 4)

When we build the evaluation framework:

### Golden Dataset Structure
```
data/test-data/practice-files/
├── golden/
│   ├── tables-expected.json           # What TableAgent should produce
│   ├── verified-tables-expected.json  # What VerificationAgent should produce
│   └── annotations.json               # Human verdicts on differences
└── runs/
    └── YYYY-MM-DD/
        ├── comparison-report.json     # Auto-generated diff
        └── human-review.json          # Annotations for this run
```

### Evaluation Workflow
1. **Run pipeline** → Produces actual output
2. **Compare to golden** → Generates diff report (strict comparison)
3. **Human annotation** → Mark each difference as "wrong" or "acceptable"
4. **Track metrics** → Strict accuracy vs practical accuracy over time

### Metrics
- **Strict accuracy**: Exact match to golden dataset
- **Practical accuracy**: Excludes "acceptable" differences
- **Truly wrong rate**: Differences marked as actual bugs

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
| Run full pipeline | `npx tsx scripts/test-pipeline.ts` |
| Check agent reasoning | `temp-outputs/*/scratchpad-*.md` |
| Compare to Joe's output | `data/test-data/practice-files/leqvio-demand-tabs-joe.xlsx` |
| Tune agent prompt | `src/prompts/*AgentPrompt.ts` |
| Adjust reasoning effort | `.env.local` → `*_REASONING_EFFORT` |
| Current work | `docs/implementation-plans/reliability-plan.md` |
| Report bugs | `temp-outputs/*/bugs.md` |

---

## Philosophy

**We're replacing Joe's usefulness, not replicating his exact format.** Antares-style output is our MVP target—functional, readable crosstabs that the team can write reports from.

**Production quality for internal tools**: 80 people will use this with real client data. Type-safe, validated, observable.

**Iterate based on evidence**: Use the evaluation framework to track improvements, not gut feelings.
