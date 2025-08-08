## Step 6: Deterministic Tables + R Generation (MVP)

### Current status and immediate fixes
- Use the verbose data map as the single source of truth (no duplicate/compat fields).
- Derive the agent data map by pruning the verbose JSON; no remapping, no duplicates.
- Build the TablePlan from the verbose data map (it contains `Level`/`Value_Type`/`Context`).
- Keep enhanced parsing and small-range synthesis.
- Ensure `r/manifest.json` and `r/master.R` include tables again by sourcing TablePlan from verbose.

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
- Source: verbose data map (canonical keys only).
- Include variables where `Answer_Options` parse to value=label pairs.
- Exclude admin/meta fields: `record`, `uuid`, `id`, `start`, `end`, `date`, `time`.
- If `Answer_Options` empty, use `Value_Type` small ranges to synthesize.
- Exclude very large value lists (> 30) for MVP.
- Table type: `single`. Title = `Description`. Question var = `Column`.

### Data contracts
- Verbose data map (canonical): `{ Level, Column, Description, Value_Type, Answer_Options, ParentQ?, Context? }[]`
- Agent data map (pruned): `{ Column, Description, Answer_Options, ParentQuestion?, Context? }[]`
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
- Verbose data map emits only canonical keys (no duplicates). Agent is derived by pruning verbose.
- `table-plan.json` produced from verbose data map using rules above.
- `cuts-spec.json` produced from validated crosstab.
- `r/master.R` generates per-table CSVs for all included variables with all cuts and Total.
- `workbook.xlsx` aggregates all results.
- `r-validation.json` shows zero blocking syntax issues for included tables.

### Preflight and non-blocking execution
- Generate `r/preflight.R` (or inline preflight section) that evaluates each cut and table var safely via `tryCatch`.
- Write `r/preflight.json` summarizing validity and any error messages.
- Skip invalid cuts/tables when generating tables; wrap runtime operations in `tryCatch` so a single failure never blocks the run.
- Record skipped items and reasons in `r-validation.json` (and optionally `r/warnings.json`).

---

## Selection Plan v2 (Parent/Sub-aware)

Goal: reduce missing tables by prioritizing top-level questions and smartly including sub-questions.

### Data normalization first (fix duplicates)
- Deduplicate fields in verbose data map; canonicalize to:
  - `Level` ("parent" | "sub"), `Column`, `Description`, `Answer_Options`, `Value_Type`, `ParentQ?`, `Context?`
- Map synonyms/duplicates to canonical keys (e.g., `Column`/`column`, `Description`/`description`).
- Clean encoding artifacts (e.g., smart quotes → ASCII: `don’t` → `don't`).

### Parent-level inclusion rules
1) Include rows where `Level == 'parent'`.
2) Exclude admin/meta by name (existing rules: `record`, `uuid`, `_id`, `id`, `start`, `end`, `date`, `time`).
3) Answer options parsing:
   - Accept separators: comma, semicolon, pipe, or newline.
   - Accept pair delimiters: `=`, `:`, or ` - ` (value on left, label on right).
   - Trim/normalize whitespace; ignore empty tokens.
4) If `Answer_Options` missing but `Value_Type` looks like `Values: a-b` with small range (≤ 12), synthesize numeric levels a..b with labels equal to value.
5) Cap very large lists at 30 (up from 20) for MVP.

### Sub-level inclusion rules
1) Include rows where `Level == 'sub'` AND `ParentQ` present.
2) If `Value_Type` indicates binary (e.g., `Values: 0-1` or `Values: 1-2`), treat each sub-row as its own table with derived levels:
   - Binary levels: `{0:'No', 1:'Yes'}` (or `{1:'Yes', 2:'No'}` if 1–2 coding). Label = `Description`; `Context` holds parent question text for title.
3) If parent has explicit `Answer_Options` that enumerate the sub-items, prefer building a single parent table using parent levels. Otherwise, default to per sub-row tables (rule 2).
4) Exclude sub-rows that look admin/meta by name.

### TablePlan construction order
1) Emit all Parent tables first (stable, clearer titles).
2) Then emit Sub tables not already covered by a Parent with explicit levels.
3) Titles:
   - Parent: use parent `Description`.
   - Sub: use `Context` (parent description) as title; set column label from sub `Description`.

### R generation impact
- Parent tables: same as now; pass explicit `levels` when parsed or synthesized.
- Sub tables: pass binary `levels` when derived; otherwise `NULL` (let R factor from data).
- No change to cuts.

### Future upgrades
- When both Parent and Sub exist, support a combined multi-select table from sub-rows (nets) in a later phase.
- Add heuristics for Likert scales (auto-detect `Values: 1–5`) and label them.


