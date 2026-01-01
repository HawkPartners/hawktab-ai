## Agents

Terse, contract-focused reference for each agent.

### BannerAgent (`src/agents/BannerAgent.ts`)
- Purpose: Parse banner document into logical groups and candidate cuts.
- Inputs: Banner DOC/PDF (converted to images), optional prompt variant (see `src/prompts/banner/**`).
- Outputs: `banner-bannerPlan-*.json` with groups, names, and candidate expressions; scratchpad for reasoning when enabled.
- Knobs: Prompt version (e.g., alternative vs production), scratchpad tool toggle.

### CrosstabAgent (`src/agents/CrosstabAgent.ts`)
- Purpose: Reconcile banner candidates with data map; produce validated cuts and columns with confidence and reasons.
- Inputs: BannerAgent output, processed data map (`DataMapProcessor`/`DataMapValidator`).
- Outputs: `crosstab-output-*.json`; updated `validation-status.json` scaffolding.
- Knobs: Prompt variants in `src/prompts/crosstab/**`; thresholds for confidence/human-review.

### RScriptAgent (`src/agents/RScriptAgent.ts`)
- Purpose: Generate per-table R code and master runner from TablePlan + CutsSpec.
- Inputs: TablePlan, CutsSpec, `.sav` path; data map slice for labels.
- Outputs: `r/scripts/<tableId>.R`, `r/master.R`, `r/manifest.json`.
- Execution: via `/api/generate-r/[sessionId]` or integrated orchestrator.
- Invariants: Total column letter `T`; cuts use validated `adjusted` R expressions; basic sig testing (90% demo).

### Prompts
- Banner: `src/prompts/banner/{index.ts, production.ts, alternative.ts}`
- Crosstab: `src/prompts/crosstab/{index.ts, production.ts, alternative.ts}`
- R: `src/prompts/index.ts` (entry) and any R-specific prompt additions when present


