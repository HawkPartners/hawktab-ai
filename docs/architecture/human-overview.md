## System Overview (Human)

Audience: you, the "vibe coder". Skimmable map of what the app does, where to find things, and what to tweak.

### What this app does
- Processes a banner plan and data map to generate validated crosstab specs.
- Builds a Tables Plan and Cuts Spec, generates R scripts, executes them, and composes an Excel workbook for demo-ready crosstabs.
- Provides a validation UI to review and adjust agent outputs.

### Key directories
- `src/agents/`: Agents orchestrating reasoning (e.g., `BannerAgent.ts`, `CrosstabAgent.ts`, `RScriptAgent.ts`).
- `src/prompts/**`: Prompt variants for agents.
- `src/app/api/**`: HTTP routes for processing, validation, queue, R generation, etc.
- `src/lib/**`: Core logic (processors, storage, exporters, tables, tracing, utils).
- `src/components/**` and `src/app/validate/**`: UI and validation experience.
- `temp-outputs/output-<timestamp>/`: All run artifacts (inputs.json, r/ files, CSVs, workbook, validation JSON).
- `docs/**`: Roadmaps, architecture, and references.

### Typical flow (happy path)
1) Upload banner/data → `POST /api/process-crosstab` kicks off processing.
2) Agents run: BannerAgent → DataMap processing/validation → CrosstabAgent.
3) Validation artifacts saved under `temp-outputs/output-<ts>/validation-status.json`.
4) R generation executes (either as part of process or via `POST /api/generate-r/[sessionId]`).
5) CSVs written to `results/`, Excel workbook composed.

You can check progress via `GET /api/process-crosstab/status` and browse `temp-outputs/output-<ts>/`.

### Where to tweak common things
- Agent behavior: `src/agents/*.ts`, prompts in `src/prompts/**`. For Banner prompt version, adjust prompt files or env.
- Data map rules: `src/lib/processors/DataMapProcessor.ts`, `DataMapValidator.ts`.
- SPSS loading: `src/lib/processors/SPSSReader.ts`.
- Cuts/Table building: `src/lib/tables/CutTable.ts` and planned `src/lib/r/tablePlan.ts`, `cutsSpec.ts` (see roadmap).
- R generation/execution: `src/agents/RScriptAgent.ts` (and `src/lib/r/*` when present), plus `/api/generate-r/[sessionId]`.
- Excel composition: Node side under `src/lib/exporters/csv.ts` today; workbook composition logic to live alongside R outputs.
- Validation UI: `src/app/validate/**`, types in `src/schemas/**`.

### Outputs you’ll see
- `inputs.json`: snapshot of inputs/context per run.
- `banner-*.json`, `dataMap-*.json`, `crosstab-output-*.json`: agent artifacts.
- `validation-status.json`: persisted validation record for UI.
- `r/manifest.json`, `r/scripts/*.R`, `results/*.csv`, `workbook.xlsx` (as implemented).

### Quick troubleshooting
- No outputs? Check server logs and `GET /api/process-crosstab/status`.
- Path mismatches? Confirm `src/lib/storage.ts` and session id wiring.
- Agent weirdness? Flip prompt variant in `src/prompts/**` and re-run.
- Excel issues? Inspect `results/*.csv` first; if good, look at workbook composition.


