## Development Roadmap (Created August 8th, 2025)

This roadmap consolidates the active MVP plan and trims prior future-enhancement details into a focused, current view. Older exploratory plans live in `docs/archive/`.

### Current Phase
- **Goal**: Complete end-to-end crosstab generation suitable for a live demo.
- **Status**: Implementing R-based table generation and Excel export; producing real crosstabs end-to-end. Waiting on additional test datasets to expand validation.
- **Scope for this phase**:
  - Produce a Tables Plan and stable Cuts Spec from existing agents/artifacts.
  - Generate per-table R, execute reliably (Docker-backed), output CSVs, and compose an Excel workbook.
  - Include a deterministic or prompted Total column (reserve letter `T`).

### High-Level Flow
1) Upload → BannerAgent → DataMapProcessor (+ SPSS validation) → CrosstabAgent → `validation-status.json` (existing)
2) Build Tables Plan (data-map first) and derive Cuts Spec from validated outputs.
3) Generate per-table R scripts + `master.R`; execute via Docker `Rscript`.
4) Collect CSV results and compose a single-sheet Excel workbook (Node `exceljs` for formatting control).

### Minimal Data Contracts
- **CutsSpec**: `cuts: [{ id, name, rExpression }]` where `id` is a stable slug (e.g., `groupName.name`).
- **TablePlan**: `tables: [{ id, title, questionVar(s), tableType, nets?, base?, filters?, notes? }]`.
- **RScriptJob**: `{ dataFilePath, dataMapAgent, tablePlan, cutsSpec }`.
- **Outputs**: `r/scripts/<tableId>.R`, `r/master.R`, `r/manifest.json`, `results/*.csv`, `workbook.xlsx`.

### What’s Done
- Agents and validation system: BannerAgent, CrosstabAgent, validation UI, status/queue APIs, and session management.
- Tracing unification with flush-on-complete; consistent span structure.
- Upload/processing pipeline producing validated crosstab specs for downstream use.

### In Progress (Step 6)
- R script generation and execution for real tables, including:
  - Single, multi, and simple scale patterns (Top2/Mid3/Bot2 nets when applicable)
  - Pairwise percentage testing (90% threshold for demo) and lettering
  - Ensuring Total column `T` is always present

### Acceptance Criteria (for demo readiness)
- Given a successful CrosstabAgent run, the system produces:
  - `r/manifest.json`, `r/scripts/<tableId>.R`, and `r/master.R`
  - Executed CSV outputs in `results/` and a compiled Excel workbook
  - Total column present and lettered as `T`
  - Cuts in scripts exactly match validated `adjusted` expressions

### Next Steps (upon receiving more test data)
- Systematically test across diverse banners/data maps using the validation UI
- Refine prompts, R generation patterns, and deterministic fallbacks as needed
- Add minimal batch runner + QA checks (syntax, variable existence, basic stat sanity)
- Iterate workbook styling (column order, significance letter placement) and config

### Deferred/Backlog
- SurveyAgent-driven TablePlan enrichment
- Robust batch testing infrastructure and reporting
- Expanded statistical options and weights
- Production-readiness (auth, monitoring, CI/CD) after demo goals

Reference: Older detailed ideas and long-term enhancements were moved to `docs/archive/future-enhancements.md`.


