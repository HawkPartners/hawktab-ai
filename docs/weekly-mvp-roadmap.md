## HawkTab AI — Weekly MVP Roadmap (Thurs demo)

Audience: internal. Goal: show end-to-end MVP by Thursday with a human-blocking validation gate, robust TablePlan, R execution, and stitched outputs. After demo, begin survey-driven enhancements (Docling) and ExcelJS exploration.

### Immediate scope (by Thursday)

- **Blocking validation workflow**
  - Enforce that processing stops at validation; R generation/execution only allowed after manual approval in UI.
  - Edits:
    - `src/app/api/process-crosstab/route.ts`: remove/guard the R manifest/master generation at the end; always write `validation-status.json` = `pending`.
    - `src/app/api/generate-r/[sessionId]/route.ts`: before building manifest, read `validation-status.json` and require `status === 'validated'` (return 409 otherwise).
    - `src/app/validate/[sessionId]/page.tsx`: on Save, redirect back to queue; optionally show a "Generate R" CTA if save succeeds.
    - `src/app/validate/page.tsx`: add per-row actions — "Open", and after validated, show "Generate R".
  - Acceptance:
    - Processing completes and shows in `/validate` as Pending.
    - R generation blocked until session is marked Validated via UI.
    - After validation, clicking Generate R succeeds and writes `r/manifest.json`, `r/master.R`, `r/preflight.json`, and `results/*.csv`.

- **Finalize TablePlan robustness**
  - Strengthen `buildTablePlanFromDataMap()` heuristics in `src/lib/tables/TablePlan.ts`:
    - Improve `parseAnswerOptions()` to handle quotes, parentheses, unicode dashes, and patterns like `1 = Yes; 2 = No; 98 = DK; 99 = Refused`.
    - Exclude admin/meta and "other/specify" subs; cap very large level sets; keep numeric-range tables without explicit levels.
    - Better `positiveValue` inference for multi-sub items (prefer labeled Yes/Selected/Agree; fallback to 1).
  - Acceptance:
    - With a typical verbose data map, generated `tablePlan.tables.length` matches expected count; spot-check includes parents and grouped subs correctly; no crash on malformed options.

- **Generate and run R from TablePlan + CutsSpec**
  - Use existing deterministic path:
    - `CutsSpec` from validated crosstab (`adjusted` expressions).
    - `TablePlan` from verbose data map.
    - `RScriptAgent.generateMasterFromManifest()` to emit `r/master.R` that writes `results/*.csv`.
  - Acceptance:
    - Running `GET /api/generate-r/[sessionId]` after validation produces CSVs for all tables with all cuts and `Total`.

- **Stitch results (single-sheet workbook, stacked tables)**
  - Minimal composition: read `results/*.csv` and build one Excel workbook with a single worksheet using `exceljs`.
  - Layout rules:
    - All tables stacked vertically on the same sheet, with a 1–2 row gap between tables.
    - A title row per table (table id and title), followed by the table grid.
    - Cuts appear as consistent columns across all tables (aligned header set: Levels/Items, Cuts..., Percents...).
  - New endpoint: `GET /api/export-workbook/[sessionId]` → `workbook.xlsx`.
  - Acceptance:
    - Endpoint streams an `.xlsx` that opens in Excel; a single worksheet contains all tables stacked; cuts columns align across tables; percents included.

- **Prompt tweaks (segments/tiers/priority accounts)**
  - Add small, explicit rubric to crosstab prompt (`src/prompts/crosstab/production.ts`) to recognize segments/tiers/priority account vocab and map to candidate variables; require lowered confidence when multiple plausible mappings.
  - Add env knob `CROSSTAB_PROMPT_VERSION=production` (default) with new guidance.
  - Acceptance:
    - For sample banner, agent chooses correct variables or clearly lowers confidence with alternatives listed.

### Day-by-day plan

- **Mon**
  - Implement blocking gate: API guards + UI buttons/flows; remove auto-R generation in process route.
  - Smoke test: upload → Pending in queue → cannot generate R until validated.

- **Tue**
  - TablePlan improvements in `TablePlan.ts` and edges in parser; add unit tests for `parseAnswerOptions()` and range synthesis.
  - Wire `GET /api/export-workbook/[sessionId]` skeleton.

- **Wed**
  - Finish workbook composition with `exceljs`; verify CSV → XLSX fidelity; stack all tables into a single worksheet with gaps and aligned cut columns; basic styling.
  - Prompt tweaks for segments/tiers/priority accounts; re-run sample and validate in UI.

- **Thu (AM)**
  - Dry run full flow end-to-end; collect artifacts in `temp-outputs/<session>`; finalize demo script.

### Near-term (post-demo)

- **Add Survey as 4th upload + old projects consolidation**
  - UI: `src/app/page.tsx` add `survey` file input; API: `/api/process-crosstab` accept and store `survey.*`.
  - Folder layout per project: `survey.(pdf/docx)`, `bannerPlan.(pdf/docx)`, `dataMap.(xlsx/csv)`, `dataFile.sav`.
  - Acceptance: upload validates presence of all four; stored under the session folder.

- **Leverage IBM Docling for survey parsing**
  - Use IBM Docling (open-source document-to-structured toolkit) to parse survey instruments (sections, questions, options, skip/termination logic).
  - New module `src/lib/surveys/DoclingSurveyParser.ts`: extract question ids, routes/skips, terminations.
  - Extend data contracts to include survey logic in verbose data map (e.g., `Skip_If`, `Term_If`).
  - Acceptance: for a sample survey, emit a JSON with question flow and attach logic to related variables.

- **QA using survey logic**
  - Validator checks: verify that data distributions align with term/skip logic (ranges consistent post-termination). Emit warnings in validation UI.

- **ExcelJS exploration (reading XLSX instead of CSV)**
  - Evaluate reading `.xlsx` for data map ingestion to preserve merged cells/grouping; detect merged cells via `exceljs` API and map to `parentQuestion`/grouping.
  - Prototype path: optional XLSX ingestion in `DataMapProcessor` that uses formatting cues (merged cells) to group subs.
  - Acceptance: for a formatted XLSX data map, parent/sub grouping matches visual merges without manual hints.

### Risks and mitigations

- Agent ambiguity on segments/tiers: mitigate by prompt rubric and lowering confidence with alternatives.
- Large level sets: cap or omit explicit levels; rely on R to infer and still produce counts.
- R runtime env: ensure Docker/R installed and path correct; add preflight JSON with warnings for any invalid cuts/vars.

### Quick commands (dev)

```bash
# Type check
npx tsc --noEmit

# Trigger processing (UI)
# Upload 3 files → see /validate queue

# After validation (UI) → Generate R via /api/generate-r/<sessionId>

# Export workbook
open http://localhost:3000/api/export-workbook/<sessionId>
```


