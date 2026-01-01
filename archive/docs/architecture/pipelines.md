## Pipelines

End-to-end flows with what gets written where.

### 1) Processing + Validation
Inputs:
- Banner plan (DOC/PDF → images), Data Map (CSV/Excel), SPSS `.sav`

Process:
1) `POST /api/process-crosstab` → orchestrates
2) BannerAgent parses banner → groups/cuts candidates
3) DataMap processing: normalize, validate (`DataMapProcessor`, `DataMapValidator`)
4) CrosstabAgent reconciles banner + data map → validated cuts/table info
5) Validation artifacts written for UI

Outputs (under `temp-outputs/output-<ts>/`):
- `inputs.json`
- `banner-bannerPlan-*.json`
- `dataMap-*.json`
- `crosstab-output-*.json`
- `validation-status.json`

### 2) R Generation + Execution + Workbook
Inputs:
- `r/manifest.json` (points to `.sav`, TablePlan, CutsSpec)
- TablePlan + CutsSpec derived from validated outputs

Process:
1) `POST /api/generate-r/[sessionId]` (or integrated in process step)
2) Generate `r/scripts/<tableId>.R` and `r/master.R`
3) Execute via Docker `Rscript r/master.R`
4) Collect `results/*.csv`
5) Compose Excel workbook (Node `exceljs`), applying letters/bases/total `T`

Outputs:
- `r/scripts/*.R`, `r/master.R`, `r/manifest.json`
- `results/*.csv`
- `workbook.xlsx`

### 3) Validation UI
Routes:
- `GET /api/validation-queue` → list sessions + status
- `GET/POST /api/validate/[sessionId]` → read/write validation
- `DELETE /api/delete-session/[sessionId]` → cleanup

Writes:
- `validation-status.json` updates under the session folder

### If a step fails, check
- API route handler in `src/app/api/**/route.ts`
- Agent logic in `src/agents/**`
- Storage paths and permissions in `src/lib/storage.ts`
- Tracing in `src/lib/tracing.ts` (ensure spans/flush)


