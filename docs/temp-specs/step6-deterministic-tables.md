## Step 6: Deterministic Tables + R Generation (MVP)

### Scope (now)
- Build TablePlan deterministically from `dataMap-agent-*.json` (single-variable tables only).
- Build CutsSpec from `crosstab-output-*.json` (use `adjusted` expressions).
- Generate one `r/master.R` to loop all tables x cuts; write `results/*.csv`.
- Compose `workbook.xlsx` from results (basic formatting, includes Total).
- No sig testing, no nets, no T2B/recodes.

### Skipped now (and how to handle later)
- Open-ends / free text:
  - Now: skip.
  - Later: detect by empty `Answer_Options` or description cues; add separate qualitative pipeline and sheets.
- No parsable options (numeric-only or unlabeled):
  - Now: skip.
  - Later: add heuristics (binning small cardinality), or LLM-proposed categories with human confirm.
- Complex nets/recodes:
  - Now: skip.
  - Later: extend TablePlan with `nets` and transform in R before tabulation.
- Significance/lettering beyond Total:
  - Now: skip.
  - Later: add R post-processing and Excel styling once base flow is stable.

### Deterministic selection rules (TablePlan)
- Include variables where `Answer_Options` parse to value=label pairs (e.g., `1=Label,2=Label`).
- Exclude admin/meta fields by name (case-insensitive): `record`, `uuid`, `id`, `start`, `end`, `date`, `time`.
- Exclude empty `Answer_Options`.
- Exclude very large value lists (> 20) for MVP.
- Table type: `single`. Title = `Description`. Question var = `Column`.

### Data contracts
- TablePlan: `{ tables: [{ id, title, questionVar, tableType: 'single', levels?: [{ value, label }] }] }`
- CutsSpec: `{ cuts: [{ id, name, rExpression }] }`

### R generation (default deterministic path)
- Inputs: `.sav` path, TablePlan, CutsSpec.
- Steps inside `r/master.R`:
  - `library(haven)`; `data <- read_sav('temp-outputs/<sessionId>/dataFile.sav')`.
  - For each cut: `cut_<id> <- with(data, <rExpression>)`.
  - For each table var:
    - If levels provided, coerce factor with explicit levels.
    - Compute counts and column percents for each cut and Total.
    - Write `results/<tableId>.csv`.

### Optional LLM-assisted path (later, behind a flag)
- Agent composes R code from a manifest context; validate with guardrails.
- Use when plans are large or custom recodes/nets are needed; fall back to deterministic on failure.

### APIs and artifacts
- New/updated routes:
  - `GET /api/generate-table-plan/[sessionId]` -> `table-plan.json`.
  - `GET /api/generate-r/[sessionId]` -> `r/master.R`, `r/manifest.json`, `r-validation.json`.
  - `POST /api/execute-r/[sessionId]` -> run R; write `results/*.csv`.
  - `GET /api/export-workbook/[sessionId]` -> `workbook.xlsx` from results.

### Acceptance criteria
- `table-plan.json` produced from data map using rules above.
- `cuts-spec.json` produced from validated crosstab.
- `r/master.R` generates per-table CSVs for all included variables with all cuts and Total.
- `workbook.xlsx` aggregates all results.
- `r-validation.json` shows zero blocking syntax issues for included tables.


