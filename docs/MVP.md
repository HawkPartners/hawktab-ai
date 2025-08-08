## MVP: Tables Plan + R Script Generation Pipeline

Goal: Extend current pipeline to produce an executable crosstab package (table plan + reusable cuts + R scripts) and deliver an Excel workbook. Keep scope minimal but demo-robust: we will execute scripts (Docker-backed) and include basic significance testing.

### Scope (MVP)
- Generate a Tables Plan from existing inputs (DataMap-first; SurveyAgent optional).
- Convert validated banner cuts (from current CrosstabAgent) into a reusable Cuts Spec.
- Generate per-table R via an LLM R Script Agent (template-guided) plus deterministic fallback.
- Execute R scripts in a container; export an Excel workbook (single sheet acceptable for MVP) mirroring vendor-style crosstabs.

### High-Level Flow (Phase after current processing)
1) Existing: Upload → BannerAgent → DataMapProcessor (+ SPSS validate) → CrosstabAgent → validation-status.json.
2) New (MVP):
   - Build Tables Plan (DataMap-first; SurveyAgent optional later).
   - Derive Cuts Spec from CrosstabAgent output.
   - Ensure Total column:
     - Primary: instruct BannerAgent to always include a "Total (qualified respondents)" column (reserve stat letter `T`).
     - Fallback: deterministically append Total in merge step prior to CrosstabAgent.
   - Generate R scripts (one per table) + master script; write to `temp-outputs/output-<ts>/r/`.
   - Execute R inside Docker to produce CSVs → `temp-outputs/output-<ts>/results/`.
   - Build an Excel workbook from results (either in R via `openxlsx` or Node via `exceljs`).

### Data Contracts (proposed minimal types)
- CutsSpec (from `ValidationResultType`):
  - cuts: [{ id, name, rExpression }] where id is stable slug (e.g., groupName.name).
- TablePlan:
  - tables: [{
      id, title, questionVar(s), tableType: 'single'|'multi'|'scale',
      nets?: [{ id, title, rExpression }],
      base?: 'unweighted'|'weighted' (placeholder),
      filters?: string[] (cut ids),
      notes?: string
    }]
- RScriptJob:
  - dataFilePath (SPSS), dataMapAgent (for labels), tablePlan, cutsSpec.
- Outputs:
  - r/scripts/<tableId>.R, r/master.R, r/manifest.json, results/*.csv (optional).

### Component Design
1) Tables Plan Builder (deterministic-first)
   - Input: `agentDataMap` from `DataMapProcessor` (Column, Description, Answer_Options).
   - Strategy: Enumerate candidate tables from data map rows that represent survey questions (exclude admin/record vars via heuristics + allowlist/denylist patterns).
   - Type inference:
     - single: categorical with finite Answer_Options
     - multi: columns that share a base with r/c suffix patterns (e.g., A3r1..A3rN)
     - scale: Answer_Options imply ordered scale (e.g., 1–5/1–7)
   - Nets (MVP): simple templates for scales (Top2, Mid3, Bot2) and allow table-level nets array. No replacement; additive.
   - Heuristics informed by sample verbose data map (e.g., `record`, `uuid`, `date`, `status` excluded; include `S*`, `Q*`, etc.).

2) Cuts Spec Builder
   - Input: `ValidationResultType` from CrosstabAgent.
   - Map each column to `id=nameSlug`, `rExpression=adjusted`.
   - Ensure uniqueness via `groupName.name` slug; de-dup as needed.

3) R Script Generator (Agent with validation)
   - Agent: "R Script Agent" generates an R function/script per table from `TablePlan + CutsSpec + DataMap` using structured output (code + metadata). Model: small/mini to keep cost low.
   - Validation: schema check, static lint, dry-run compile, and basic unit probe against a tiny sampled frame. If validation fails, the agent retries; no deterministic fallback in MVP.
   - Libraries: `haven` (read_sav), `dplyr`, `tidyr`, `stringr`, `readr`, `DescTools` (or inline tests), `openxlsx` (if writing workbook from R).
   - Patterns (MVP):
     - Load SAV once in master.R.
     - Frequency (single): by-cut proportions with base Ns.
     - Multi: treat response-set columns; compute proportions by cut.
     - Scale nets: compute derived categories per template (Top2/Mid3/Bot2), retain raw categories.
     - Significance testing: pooled-overlap z-test for percentages across columns; t-test for means where applicable; emit letter flags (A, B, C…; reserve `T` for Total).
   - Output per table: CSVs; optionally write Excel directly. If CSVs, Node composes workbook.

4) Cutoff discovery (agent-driven)
   - Some banner expressions intentionally defer to analysis (e.g., "S11 > cutoff" or notes like "Joe to find the right cutoff").
   - The R Script Agent must detect placeholders (e.g., tokens like `cutoff`, `THRESH`, `TO_FIND`) and choose a cutoff based on the actual data distribution (examples: median, quantile, maximizing separation, or business rule supplied in prompt/env).
   - The selected cutoff value is recorded in the table’s metadata and reflected in the emitted R code; a note is added to the manifest for auditability.

5) Execution (required for demo)
   - Use Docker to run R consistently (feature flag to skip in CI if needed).
   - `Rscript` master orchestrates per-table scripts; collect CSVs and/or write Excel workbook.

### Excel generation: R vs Node
- In R (openxlsx):
  - Pros: Keep all computation and formatting in one environment; straightforward to write sheets, styles, and formulas post-analysis.
  - Cons: Styling logic lives in R; JS team may prefer Node control for UI/export consistency.
- In Node (exceljs):
  - Pros: Compose workbook from CSVs on the server that already runs Next.js; easy to apply house styles; no R package coupling for formatting.
  - Cons: Two-step flow (R → CSV → Node → XLSX); significance letters and footers must be carried through cleanly.

Final recommendation: Keep analytics in R on .sav via haven::read_sav; render Excel in Node with exceljs using CSV + a JSON TableRenderSpec. This maximizes long‑term layout control while letting the agent focus on analysis.

### Integration Points
- New module(s):
  - `src/lib/r/`:
    - `tablePlan.ts` (builders, heuristics)
    - `cutsSpec.ts` (from validation)
    - `rGenerator.ts` (script builders, manifest writer)
    - `executor.ts` (optional Rscript spawn)
- API: extend `/api/process-crosstab` background flow after CrosstabAgent or provide a new endpoint `/api/generate-r` consuming a session’s artifacts. For demo, extend existing flow behind a feature flag.
- Outputs: write under session folder alongside existing dev artifacts.

### Prompts/Agents
- SurveyAgent (DOC/PDF → images) mirroring BannerAgent to enrich TablePlan when available:
  - Output: list of questions with types, options, recommended nets, and table relevance.
  - Mode selection:
    - MVP: DataMap-first only (fast, stable).
    - Next: Hybrid (DataMap baseline + SurveyAgent refinements, resolve conflicts with simple rules).
 - R Script Agent (new): LLM generates R per table with guardrails (schema, static checks, dry-run compile, unit probe on sample frame). No deterministic fallback in MVP; rely on retries.

### Acceptance Criteria (minimal)
- Given a successful CrosstabAgent run, the system produces:
  - `r/manifest.json` with { tablePlan, cutsSpec, dataFile }.
  - `r/scripts/<tableId>.R` for each table and `r/master.R` that sources/executes them.
  - Executed outputs: CSVs in `results/` and a compiled Excel workbook.
  - Total column present with letter `T` and used in testing.
  - Cuts used in scripts exactly match validated `adjusted` R expressions.
  - Pairwise significance letters present per row (90% threshold MVP), logic documented.
  - Table styling placement for significance letters is TBD (e.g., right of each column vs footers); capture as config for later.
  - No blocking on SurveyAgent; DataMap-first plan works end-to-end.

### Open Questions
- Weighting/base: MVP confirmed unweighted.
- Total column: MVP confirmed required. Primary via BannerAgent prompt; fallback during merge.
- Output format: Excel workbook confirmed.
- R env: Dockerized execution confirmed for demo robustness.
- Multi-response detection rules: confirm naming conventions to infer sets reliably.
 - Significance placement style: right-of-column vs under-table is TBD; treat as configurable rendering concern.

### Risks/Assumptions
- Assumes SPSS variable names match DataMap (`DataMapValidator` helps, but mismatches may exist).
- Deterministic R builder limits formatting vs agent-produced code but is reliable for demo.
- SurveyAgent deferred to avoid scope creep; can be added without breaking contracts.

### Phased Plan
1) Cuts & Tables foundation — COMPLETED ✅
   - Implement `cutsSpec.ts` to transform CrosstabAgent output → stable cut ids and `adjusted` expressions.
   - Implement `tablePlan.ts` heuristics to enumerate tables from agent data map; include nets templates.
   - Write `r/manifest.json` with pointers: dataFile (.sav), cutsSpec, tablePlan.

2) R Script Agent with validation — COMPLETED ✅
   - Define agent schema: input (table + cuts + data map slice) → output { rCode, metadata }.
   - Add validators: schema check, static lint, dry-run compile on a tiny sampled frame.
   - Generate `r/scripts/<tableId>.R` and `r/master.R` (loads .sav once, sources per-table scripts).

3) Executable pipeline & workbook rendering
   - Add Dockerfile and executor to run `Rscript r/master.R` inside container.
   - Emit CSVs to `results/` and a JSON `TableRenderSpec` per table (placement of sig letters TBD but supported).
   - Build Excel workbook in Node with exceljs from CSV + TableRenderSpec (apply letters, bases, Total `T`).

4) Enhancements (post-demo)
   - SurveyAgent to refine TablePlan and nets; hybrid with DataMap heuristics.
   - Styling presets/themes for exceljs; config for sig-letter placement.
   - Additional stat options (95%/99%), totals/weights, multi-sheet outputs.