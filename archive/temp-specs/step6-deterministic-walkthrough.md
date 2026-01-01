## Deterministic R Generation — Walkthrough (MVP)

### Why deterministic (now)
- Stability/repeatability: same input → same tables, no prompt drift.
- Testability: easy to unit test builders and R output.
- Cost/latency: fast, no model calls for bulk table creation.
- Leverages already-validated R expressions from CrosstabAgent.
- LLM remains optional for later (nets, complex recodes).

### End-to-end steps
1) Inputs available under `temp-outputs/<sessionId>/`:
   - `dataMap-agent-*.json` (variables + answer options)
   - `crosstab-output-*.json` (validated cuts with `adjusted` R)
   - `dataFile.sav`
2) Build TablePlan deterministically from `dataMap-agent-*.json`:
   - Include vars with parsable `Answer_Options` (value=label pairs)
   - Exclude admin/meta fields and very large value lists (e.g., >20)
3) Build CutsSpec from `crosstab-output-*.json`:
   - One cut per column; `rExpression = adjusted`
4) Build R manifest: data path + TablePlan + CutsSpec
5) Generate `r/master.R` that loops tables×cuts, writes `results/*.csv`
6) Optionally compose `workbook.xlsx` from all CSVs

### Example artifacts (trimmed)

CutsSpec (from validated crosstab):
```json
{
  "cuts": [
    { "id": "role.hcp", "name": "HCP", "rExpression": "S2b == 1" },
    { "id": "role.np-pa", "name": "NP/PA", "rExpression": "S2b %in% c(2,3)" },
    { "id": "tiers.tier-1", "name": "Tier 1", "rExpression": "qLIST_TIER == 1" },
    { "id": "total.total", "name": "Total", "rExpression": "status == 3" }
  ]
}
```

TablePlan (from data map):
```json
{
  "tables": [
    {
      "id": "S2",
      "title": "Primary Specialty",
      "questionVar": "S2",
      "tableType": "single",
      "levels": [
        { "value": 1, "label": "Cardiologist" },
        { "value": 2, "label": "Internal Medicine / PCP" },
        { "value": 3, "label": "Nephrologist" }
      ]
    },
    {
      "id": "S2b",
      "title": "Primary Role",
      "questionVar": "S2b",
      "tableType": "single",
      "levels": [
        { "value": 1, "label": "Physician" },
        { "value": 2, "label": "Nurse Practitioner" },
        { "value": 3, "label": "Physician Assistant" }
      ]
    }
  ]
}
```

R Manifest (input to generator):
```json
{
  "dataFilePath": "temp-outputs/<sessionId>/dataFile.sav",
  "tablePlan": { /* as above */ },
  "cutsSpec": { /* as above */ }
}
```

### `r/master.R` shape (illustrative)
```r
library(haven)
data <- read_sav('temp-outputs/<sessionId>/dataFile.sav')

# Define cuts (from CutsSpec)
cut_role_hcp   <- with(data, S2b == 1)
cut_role_np_pa <- with(data, S2b %in% c(2,3))
cut_tiers_1    <- with(data, qLIST_TIER == 1)
cut_total      <- with(data, status == 3)

cuts <- list(
  HCP = cut_role_hcp,
  `NP/PA` = cut_role_np_pa,
  `Tier 1` = cut_tiers_1,
  Total = cut_total
)

write_table <- function(var_name, levels, table_id) {
  # factor with declared levels if provided
  v <- data[[var_name]]
  if (!is.null(levels)) {
    v <- factor(v, levels = levels$value, labels = levels$label)
  }

  # build counts per cut
  count_list <- lapply(cuts, function(idx) {
    tab <- table(v[idx], useNA = 'no')
    as.integer(tab[levels(v)])
  })
  counts <- do.call(cbind, count_list)
  colnames(counts) <- names(cuts)
  rownames(counts) <- levels(v)

  # column percents
  col_totals <- colSums(counts)
  perc <- sweep(counts, 2, ifelse(col_totals == 0, 1, col_totals), '/') * 100

  # combine and write
  out <- data.frame(Level = rownames(counts), counts, perc, check.names = FALSE)
  dir.create('temp-outputs/<sessionId>/results', recursive = TRUE, showWarnings = FALSE)
  write.csv(out, sprintf('temp-outputs/<sessionId>/results/%s.csv', table_id), row.names = FALSE)
}

# Loop tables (pseudo; actual list comes from TablePlan)
write_table('S2',  data.frame(value=c(1,2,3), label=c('Cardiologist','Internal Medicine / PCP','Nephrologist')), 'S2')
write_table('S2b', data.frame(value=c(1,2,3), label=c('Physician','Nurse Practitioner','Physician Assistant')), 'S2b')
```

Notes:
- Named args use `=` (e.g., `na.rm = TRUE`) inside functions when needed.
- Comparisons use `==`, `&`, `|` in cuts (already validated upstream).

### Optional LLM path (later)
- An agent can compose `master.R` from the Manifest instead of deterministic generation.
- Keep current validators; if LLM output fails checks, fall back to deterministic.

### Acceptance (MVP)
- Deterministic `table-plan.json` and `cuts-spec.json` built.
- `r/master.R` generates per-table CSVs for all included variables with all cuts + Total.
- `workbook.xlsx` assembled from `results/*.csv`.

