## Core Modules

Where responsibilities live and how to extend.

- `src/lib/processors/DataMapProcessor.ts`: Normalize/derive structures from raw data map.
- `src/lib/processors/DataMapValidator.ts`: Consistency checks between data map and expected shapes.
- `src/lib/processors/SPSSReader.ts`: SPSS `.sav` reading helpers.
- `src/lib/tables/CutTable.ts`: Transform validated cuts into tabular/CSV forms.
- `src/lib/exporters/csv.ts`: CSV export utilities.
- `src/lib/storage.ts`: Paths, session folders, read/write utilities.
- `src/lib/jobStore.ts`: Job tracking and status for background work.
- `src/lib/tracing.ts`: Tracing setup; use `withTrace()` around major steps.
- `src/lib/contextBuilder.ts`: Build agent context from inputs/artifacts.
- `src/lib/utils.ts`, `src/lib/types.ts`, `src/lib/env.ts`: Shared utils, types, env config.

Extension tips:
- Add processing steps in processors; keep pure where possible.
- For new outputs, extend `storage.ts` path helpers to keep locations consistent.
- Wrap long-running operations with `withTrace()` for visibility.

### Module details

#### DataMapProcessor
- Steps: parse CSV (state machine) → infer parents → enrich context → validate (with DataMapValidator) → emit dual outputs.
- Dev mode writes `*-verbose-<ts>.json` and `*-agent-<ts>.json` into session folder.

#### DataMapValidator
- Scores variables on structural integrity, content completeness, relationship clarity.
- Optional SPSS validation via `SPSSReader` (column matching, value labels, summary).

#### SPSSReader
- Uses `sav-reader` to open `.sav` files and extract metadata, variables, labels.
- Provides `validateAgainstDataMap()` for match-rate and value-range checks.

#### CutTable + CSV Exporter
- `buildCutTable(validation, sessionId)` converts agent validation into a concise table JSON with stats.
- `exportCutTableToCSV(table)` flattens groups/columns to a CSV.

#### ContextBuilder
- Accepts banner extraction and data map file path, returns dual outputs and prepared agent schemas.
- `prepareAgentContext()` returns Zod-typed `dataMap` and `bannerPlan` for agents.

#### JobStore
- In-memory job map for status polling via `/api/process-crosstab/status`.

#### Tracing
- Configuration and console logging; full agent spans via `withTrace()` in agents.


