# Pipeline Configuration Reference

A complete inventory of every configuration option in the HawkTab AI pipeline. Use this to know what the UI needs to surface, what stays internal, and what's hardcoded.

*Created: February 8, 2026*

---

## User-Facing Configuration (UI should expose these)

These are the settings an end user (like someone at Antares) would reasonably want to control.

### Output Format

| Setting | Current Access | Options | Default | What It Does |
|---------|---------------|---------|---------|-------------|
| Excel layout | `--format` CLI flag | `joe`, ~~`antares`~~ (deprecated) | `joe` | Joe format: horizontal (1 row per answer, value+sig column pairs). Antares format is deprecated and will be removed. |
| Display mode | `--display` CLI flag | `frequency`, `counts`, `both` | `frequency` | `frequency` = percentages only. `counts` = raw counts only. `both` = two sheets in one workbook (Percentages + Counts). |
| Separate workbooks | `--separate-workbooks` CLI flag | Boolean | `false` | When `--display=both`, output two separate .xlsx files (`crosstabs.xlsx` for percentages, `crosstabs-counts.xlsx` for counts) instead of two sheets in one workbook. Each file gets its own TOC and Excluded Tables sheet. |
| Color theme | `--theme` CLI flag | `classic`, `coastal`, `blush`, `tropical`, `bold`, `earth` | `classic` | Color palette for the Excel workbook. Each theme provides a different set of banner group colors, header/label/context fills, and row alternation shading. All themes preserve the same layout and structure — only colors change. Defined in `src/lib/excel/themes.ts`. |

### Statistical Testing

| Setting | Current Access | Options | Default | What It Does |
|---------|---------------|---------|---------|-------------|
| Confidence levels | `STAT_THRESHOLDS` env var | Comma-separated decimals (e.g., `0.05,0.10`) | `0.10` | Single threshold = one letter notation. Dual = uppercase for stricter, lowercase for lenient (e.g., A at 95%, a at 90%). |
| Proportion test | `STAT_PROPORTION_TEST` env var | `unpooled_z`, `pooled_z` | `unpooled_z` | How proportions are compared. Unpooled = WinCross standard (assumes unequal variances). Pooled = assumes equal variances. |
| Mean test | `STAT_MEAN_TEST` env var | `welch_t`, `student_t` | `welch_t` | How means are compared. Welch = more robust (unequal variances). Student = classical (equal variances). |
| Minimum base size | `STAT_MIN_BASE` env var | Integer >= 0 | `0` (no minimum) | Base size below which stat testing is suppressed. 0 = test everything regardless of n. |

### Pipeline Scope

| Setting | Current Access | Options | Default | What It Does |
|---------|---------------|---------|---------|-------------|
| Dataset folder | Positional CLI arg | File path | Leqvio dataset | Which dataset to process. |
| Stop early | `--stop-after-verification` flag | Boolean | `false` | Skip R execution and Excel generation. Useful for reviewing agent output before committing to the full run. |
| Show defaults | `--show-defaults` flag | Boolean | — | Print current pipeline configuration (output format, stat testing, etc.) and exit without running. |

---

## Internal Configuration (developer-only, don't expose in UI)

These tune the system's behavior but aren't meaningful to end users. Keep in `.env.local`.

### Per-Agent Model Selection

Each of the 6 agents has its own model, token limit, reasoning effort, and prompt version. Users don't need to know about this — it's how we tune quality vs cost vs speed.

| Agent | Model Var | Default Model | Token Limit Var | Default Tokens | Reasoning Var | Default |
|-------|-----------|---------------|-----------------|----------------|---------------|---------|
| CrosstabAgent | `CROSSTAB_MODEL` | `o4-mini` | `CROSSTAB_MODEL_TOKENS` | `100000` | `CROSSTAB_REASONING_EFFORT` | `medium` |
| BannerAgent | `BANNER_MODEL` | `gpt-5-nano` | `BANNER_MODEL_TOKENS` | `128000` | `BANNER_REASONING_EFFORT` | `medium` |
| VerificationAgent | `VERIFICATION_MODEL` | `gpt-5-mini` | `VERIFICATION_MODEL_TOKENS` | `128000` | `VERIFICATION_REASONING_EFFORT` | `medium` |
| SkipLogicAgent | `SKIPLOGIC_MODEL` | (inherits Verification) | `SKIPLOGIC_MODEL_TOKENS` | `128000` | `SKIPLOGIC_REASONING_EFFORT` | `medium` |
| FilterTranslatorAgent | `FILTERTRANSLATOR_MODEL` | (inherits Crosstab) | `FILTERTRANSLATOR_MODEL_TOKENS` | `100000` | `FILTERTRANSLATOR_REASONING_EFFORT` | `medium` |
| LoopSemanticsPolicyAgent | `LOOP_SEMANTICS_MODEL` | (inherits Verification) | `LOOP_SEMANTICS_MODEL_TOKENS` | `128000` | `LOOP_SEMANTICS_REASONING_EFFORT` | `medium` |

**Prompt versions** (per agent): `*_PROMPT_VERSION` env var. Values: `production`, `alternative`. Controls which prompt file is loaded from `src/prompts/<agent>/`.

**Reasoning effort values**: `none`, `minimal`, `low`, `medium`, `high`, `xhigh`. Invalid values fall back to `medium` with a console warning.

### Processing Limits

| Setting | Env Var | Default | What It Does |
|---------|---------|---------|-------------|
| Max datamap variables | `MAX_DATA_MAP_VARIABLES` | `1000` | Cap on variables extracted from .sav file. |
| Max banner columns | `MAX_BANNER_COLUMNS` | `100` | Cap on banner columns processed. |
| Agent concurrency | `--concurrency` CLI / `PipelineOptions.concurrency` | `3` | Parallel agent slots. Higher = faster but more API calls at once. |

### Azure OpenAI Credentials

| Setting | Env Var | Required |
|---------|---------|----------|
| API key | `AZURE_API_KEY` | Yes |
| Resource name | `AZURE_RESOURCE_NAME` | Yes |
| API version | `AZURE_API_VERSION` | No (default: `2025-01-01-preview`) |

### General

| Setting | Env Var | Default | What It Does |
|---------|---------|---------|-------------|
| Tracing | `TRACING_ENABLED` | `true` | Enable/disable distributed tracing scaffold. |
| Environment | `NODE_ENV` | `development` | Standard Node.js environment flag. |

---

## Hardcoded Values (implicit config, not currently changeable)

These are baked into the code. If we ever need to make them configurable, they'd need to be extracted.

### Agent Step Limits

Controls how many reasoning steps an agent can take before being forced to produce output (`stopWhen: stepCountIs(N)`).

| Agent | Step Limit | Location |
|-------|-----------|----------|
| CrosstabAgent | 25 | `src/agents/CrosstabAgent.ts` |
| SkipLogicAgent (initial) | 25 | `src/agents/SkipLogicAgent.ts` |
| SkipLogicAgent (retry) | 15 | `src/agents/SkipLogicAgent.ts` |
| BannerAgent | 15 | `src/agents/BannerAgent.ts` |
| VerificationAgent | 15 | `src/agents/VerificationAgent.ts` |
| FilterTranslatorAgent | 15 | `src/agents/FilterTranslatorAgent.ts` |
| LoopSemanticsPolicyAgent | 15 | `src/agents/LoopSemanticsPolicyAgent.ts` |

### Retry & Timeout Configuration

| Setting | Value | Location |
|---------|-------|----------|
| Max retry attempts (policy/transient errors) | 3 | `src/lib/retryWithPolicyHandling.ts` |
| Base retry delay | 2000ms | `src/lib/retryWithPolicyHandling.ts` |
| Rate limit retry delay | 15000ms | `src/lib/retryWithPolicyHandling.ts` |
| Backoff strategy | Linear (1x, 2x, 3x) | `src/lib/retryWithPolicyHandling.ts` |
| R script execution timeout | 300,000ms (5 min) | `src/lib/r/ValidationOrchestrator.ts` |
| R version check timeout | 1,000ms | `src/lib/r/ValidationOrchestrator.ts` |
| LibreOffice conversion timeout | 30,000ms | `src/agents/BannerAgent.ts` |
| Max output tokens (all agents) | 100,000 | All agent files |
| Max R validation retries per table | 3 | `src/lib/r/ValidationOrchestrator.ts` |

### File Discovery Patterns

How `batch-pipeline.ts` and `FileDiscovery.ts` identify input files:

| File Type | Detection | Format | Required |
|-----------|-----------|--------|----------|
| Data file | `*.sav` extension | SPSS | Yes |
| Banner plan | Filename contains `banner` | `.docx` or `.pdf` | Yes |
| Survey | Filename contains `survey`, `questionnaire`, `qre`, or `qnr` | `.docx` or `.pdf` | Yes |
| Datamap | (legacy) | CSV | No (.sav is source of truth) |

Office temp files (`~$` prefix) are automatically filtered out.

---

## Legacy / Deprecated Variables

Still supported for backward compatibility but should not be used in new config.

| Deprecated Var | Maps To | Notes |
|----------------|---------|-------|
| `REASONING_MODEL` | `CROSSTAB_MODEL` | Old naming convention |
| `BASE_MODEL` | `BANNER_MODEL` | Old naming convention |
| `REASONING_MODEL_TOKENS` | `CROSSTAB_MODEL_TOKENS` | Old naming convention |
| `BASE_MODEL_TOKENS` | `BANNER_MODEL_TOKENS` | Old naming convention |
| `TABLE_MODEL` | (unused) | Removed |
| `TABLE_AGENT_ONLY` | (unused) | Removed |
| `DATAMAP_FORMAT` | (unused) | .sav is now source of truth |

---

## UI Planning Notes

**Must expose to users:**
- Display mode (percents / counts / both)
- Separate workbooks toggle (when display mode is "both")
- Stat testing: confidence levels, min base size
- Stat testing: test method (proportion + mean) — though most users will want the defaults

**Probably don't expose:**
- Model selection, reasoning effort, prompt versions (internal tuning)
- Concurrency, token limits, step limits (performance tuning)
- Processing limits (safety guardrails)
- Retry/timeout config (infrastructure)

**Gray area (decide later):**
- Stop-after-verification — useful for power users who want to review before R runs
- Stat testing method (unpooled_z vs pooled_z) — most MR people won't change this, but some will want to

**Not yet configurable but should be (future roadmap items):**
- Weight variable selection (2.6)
- Table include/exclude lists (2.9)
- Per-table feedback/regeneration (2.10)

**Recently implemented:**
- Excel color theme (2.11) — `--theme` flag, 6 palettes available
