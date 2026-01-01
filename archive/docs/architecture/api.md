## API Reference (Concise)

Format: METHOD PATH — purpose | reads | writes

- POST `/api/process-crosstab` — Run processing pipeline | Reads upload/session inputs | Writes session folder artifacts
- GET `/api/process-crosstab/status` — Pipeline status | Reads job store | —
- GET `/api/generate-r/[sessionId]` — Generate R and validation | Reads session artifacts (`dataFile.sav`, crosstab or cut-table) | Writes `r-script.R`, `r-validation.json`
- GET `/api/validate/[sessionId]` — Read validation | Reads `validation-status.json` | —
- POST `/api/validate/[sessionId]` — Save validation | Reads body | Writes `validation-status.json`
- GET `/api/validation-queue` — List sessions | Reads session dirs | —
- DELETE `/api/delete-session/[sessionId]` — Remove session | — | Deletes session folder
- GET `/api/generate-tables/[sessionId]` — Emit cut tables | Reads crosstab output | Writes `cut-tables.json`, `cut-tables.csv`

See `src/app/api/**/route.ts` for handler details.


