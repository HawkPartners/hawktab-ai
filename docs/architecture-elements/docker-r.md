## R generation & Docker

Flow:
- Generate `r/scripts/<tableId>.R` + `r/master.R`.
- Run inside Docker with `Rscript`.
- Emit `results/*.csv`; Node composes Excel.

R packages:
- `haven`, `dplyr`, `tidyr`, `stringr`, `readr`, `DescTools` (tests), optional `openxlsx`.

Where:
- Agent: `src/agents/RScriptAgent.ts`.
- Future helpers under `src/lib/r/*` (generator, executor, manifest writer).


