## Data Map Optimization — MVP Plan (Phased Checklist)

Audience: internal. Goal: enrich parsing and typing from raw data map CSV into a richer `verbose` data map that drives banner validation and deterministic tables without brittleness. Use this as a product spec with checklists per phase.

References
- Raw CSV: `temp-reference/datamap_raw-datamap.csv`
- Current parser: `src/lib/processors/DataMapProcessor.ts`
- Verbose schema: `src/schemas/processingSchemas.ts`
- Table plan builder: `src/lib/tables/TablePlan.ts`
- R manifest + generator: `src/lib/r/Manifest.ts`, `src/agents/RScriptAgent.ts`
- Issue list: `docs/manifest-review-temp.md`

### Phase 0 — Baseline and artifacts
- [x] Re-run a full processing flow and capture outputs under a new session for comparison.
- [x] Save current `*-verbose-*.json` and `r/manifest.json` as baseline.
- [x] Note concrete mismatches listed in `docs/manifest-review-temp.md` (S6, S8, S10–S12, A1, A3/A4, A8, A9, B1, B3/B4).

### Phase 1 — Schema: normalized typing (non-breaking)
- [x] Extend `VerboseDataMapSchema` with optional fields:
  - `normalizedType`, `rangeMin`, `rangeMax`, `rangeStep`, `allowedValues`, `scaleLabels`, `rowSumConstraint`, `dependentOn`, `dependentRule`.
- [x] Add inline doc comments describing each new field to guide downstream use.

Code citation (schema)
```1:48:src/schemas/processingSchemas.ts
export const VerboseDataMapSchema = z.object({
  level: z.enum(['parent', 'sub']),
  column: z.string(),
  description: z.string(),
  valueType: z.string(),
  answerOptions: z.string(),
  parentQuestion: z.string(),
  context: z.string().optional(),
  confidence: z.number().min(0).max(1).optional(),
  normalizedType: z.enum([...]).optional(),
  rangeMin: z.number().optional(),
  rangeMax: z.number().optional(),
  // ...
});
```

### Phase 2 — Parse-time enrichment (CSV → richer raw)
- [x] In `DataMapProcessor`, parse `Values: A-B` into numeric `rangeMin/rangeMax` on the in-memory structure before dual outputs.
- [x] Detect group patterns:
  - [x] Matrix single-choice (parent `Values: 1-2` + exactly two option labels + sub-rows) → mark group.
  - [x] "Of those …" sequences (e.g., S12 after S11) → set `dependentOn`, `dependentRule='upperBoundEquals(S11)'`.
- [x] Preserve parent question full text in `context` for all subs when available.

Code citation (hook to enrich)
```145:175:src/lib/processors/DataMapProcessor.ts
private handleValuesLine(valuesText: string, context: ParsingContext): void {
  context.currentValueType = valuesText.trim();
  context.state = ParsingState.IN_VALUES;
}
```

### Phase 3 — Post-parse classification (heuristics)
- [x] Implement `classifyVariable(v, groupContext)` and run after parsing/parent inference:
  - [x] `numeric_range` when `Values: A-B` with no discrete options.
  - [x] `percentage_per_option` when `Values: 0-100` with sibling subs; set `rowSumConstraint=true` on parent.
  - [x] `ordinal_scale` when options map to Likert 1–5 or 1–4; populate `allowedValues` + `scaleLabels`.
  - [x] `matrix_single_choice` for A1-like grids; set `allowedValues=[1,2]` at sub level and carry labels at parent.
  - [x] `binary_flag` only for 0/1 Checked/Unchecked.
  - [x] Set dependencies (S12 depends on S11) as detected in Phase 2.
- [x] Write back normalized fields to verbose map in `generateDualOutputs`.

### Phase 4 — TablePlan: consume normalized typing
- [x] Extend table definitions to handle numeric/scale/matrix metadata:
  - [x] Numeric metrics: mean, median, sd.
  - [x] Bucket spec: count, edges (optional).
  - [x] Scale levels and labels; allowed values for matrices.
- [x] Prefer `normalizedType` instead of inferring `positiveValue` for multi-sub items.

Code citation (table plan area)
```1:28:src/lib/tables/TablePlan.ts
export type SingleTableDefinition = {
  id: string;
  title: string;
  questionVar: string;
  tableType: 'single';
  levels?: TableLevel[];
};
```

### Phase 5 — R preflight: empirical stats and bucketing
- [x] Implement a preflight step in the R generation flow to compute per-variable stats into `r/preflight.json`:
  - [x] `empiricalMin`, `empiricalMax`, `mean`, `median`, `sd`, quantiles.
  - [x] For percentage groups: `rowSumMean`, `rowSumStd` per parent.
- [x] Bucket strategy:
  - [x] Default 10 equal-width bins over [empiricalMin, empiricalMax].
  - [x] If unique values ≤ 6, use unique-value bins.
  - [x] For percentages, clamp to [0,100] but prefer empirical span for readability.
- [x] `master.R` consumes bucket edges from preflight where present; fallback to declared bounds.

Pseudo outline
```r
# preflight.R (invoked before master generation)
stats <- list()
for (v in numeric_vars) {
  x <- na.omit(df[[v]])
  stats[[v]] <- list(
    empiricalMin=min(x), empiricalMax=max(x),
    mean=mean(x), median=median(x), sd=sd(x),
    q=as.list(quantile(x, c(.1,.25,.5,.75,.9), na.rm=TRUE))
  )
}
write(jsonlite::toJSON(stats, auto_unbox=TRUE, pretty=TRUE), "r/preflight.json")
```

### Phase 6 — Validation hooks
- [x] If `rowSumConstraint=true`, compute row-sum stats and flag deviations > 2 points in `r-validation.json`.
- [x] Surface warnings in UI later (optional for MVP).

### Phase 7 — Acceptance tests
- [ ] Using `temp-reference/datamap_raw-datamap.csv`, verify normalized typing:
  - [ ] S6, S10, S11 → `numeric_range` with bounds.
  - [ ] S12 → `numeric_range` + dependency on S11.
  - [ ] S8, A3/A4 families, B1 → `percentage_per_option` + row-sum check.
  - [ ] A8 (1–5), A9 (1–4) → `ordinal_scale` with labels.
  - [ ] A1 → `matrix_single_choice` with `allowedValues=[1,2]`.
  - [ ] B3 present as select; B4 as range.
- [ ] TablePlan includes metrics and bucket specs for numeric/percentage questions.
- [ ] R outputs include bucketed distributions + mean/median/sd; `r-validation.json` contains row-sum diagnostics where applicable.

### Notes on declared vs empirical ranges
- Declared (e.g., 0–100) conveys intent; empirical stats from preflight should determine bin edges for readability. Persist declared bounds in metadata but prefer empirical for binning.



