# HawkTab CLI Guide

> **DEPRECATED**: The interactive CLI (`hawktab`) is deprecated. Use plain scripts instead:
> ```bash
> npx tsx scripts/test-pipeline.ts                              # Default dataset
> npx tsx scripts/test-pipeline.ts data/test-data/some-dataset  # Specific dataset
> npx tsx scripts/test-pipeline.ts --format=antares             # With options
> ```

A guide to using the HawkTab command-line interface (kept for reference).

## Quick Start

```bash
# Open the interactive menu
hawktab

# Run the full pipeline
hawktab run

# Show help
hawktab help
```

## The Main Menu

When you run `hawktab` with no arguments, you'll see the interactive menu:

```
┌──────────────────────────────────────────────────────────────────────┐
│ HawkTab AI                                                           │
└──────────────────────────────────────────────────────────────────────┘

  ▶ [1] Run Pipeline           Run full crosstab pipeline
    [2] Run Script             Execute test/utility scripts
    [3] Browse History         Explore previous pipeline runs
    [4] Settings               View model configuration
    [q] Quit

  Dataset: leqvio-monotherapy-demand-NOV217
  Last Run: 2026-02-01 05:49 (45m 49s, $1.45, 124 tables)
```

**Navigation:**
- `j` / `k` or arrow keys: Move selection up/down
- `Enter`: Select the highlighted option
- `1`, `2`, `3`, `4`: Quick-select menu items
- `q`: Quit

---

## [1] Run Pipeline

Runs the full crosstab automation pipeline on the current dataset.

**What it does:**
1. Parses datamap CSV
2. Extracts banner structure from PDF/DOCX
3. Generates table definitions
4. Enhances tables with survey context (VerificationAgent)
5. Extracts skip logic and applies filters (SkipLogicAgent + FilterApplicator)
6. Validates R syntax
7. Executes R script to calculate statistics
8. Generates Excel output

**Output location:** `outputs/<dataset>/pipeline-<timestamp>/`

**During execution**, you'll see:
- Stage-by-stage progress with status indicators
- Running cost estimate
- Elapsed time
- Table count

**Keyboard shortcuts during pipeline:**
- `j` / `k`: Select stage
- `Enter`: Drill into parallel agent slots
- `Esc`: Go back up
- `q`: Quit (pipeline keeps running in background)

### Command-line options

```bash
# Run with Antares format
hawktab run --format=antares

# Show both counts and percentages
hawktab run --display=both

# Run without the UI (plain console output)
hawktab run --no-ui

# Use specific dataset
hawktab run data/my-dataset-folder

# Configure stat testing
hawktab run --stat-thresholds=0.05,0.10 --stat-min-base=30
```

---

## [2] Run Script

Browse and execute test scripts from the `scripts/` directory.

```
┌──────────────────────────────────────────────────────────────────────┐
│ Script Runner                                                        │
└──────────────────────────────────────────────────────────────────────┘

    compare-to-golden.ts       FAST   Compare to reference output
    test-table-generator.ts    FAST   Deterministic table gen (<1s)
    test-verification-agent.ts        VerificationAgent isolation
    test-r-regenerate.ts               Regenerate R script from existing tables
  ▶ test-pipeline.ts           LONG   Full pipeline (45-60 min)
```

**Categories:**
- **FAST** (green): Quick scripts, run immediately
- **LONG** (red): Time-consuming scripts, require confirmation
- Normal: Everything else

**Keyboard shortcuts:**
- `j` / `k`: Select script
- `Enter`: Run selected script
- `Esc`: Back to menu
- `q`: Quit

**For long scripts**, you'll see a confirmation dialog:

```
┌─────────────────────────────────────────────────────────────┐
│ Warning: Long-Running Script                                │
│                                                             │
│ test-pipeline.ts may take 45-60 minutes to complete.        │
│                                                             │
│ Are you sure you want to run it? [y] yes  [n] no            │
└─────────────────────────────────────────────────────────────┘
```

---

## [3] Browse History

Explore previous pipeline runs and their artifacts.

```
┌──────────────────────────────────────────────────────────────────────┐
│ Pipeline History  │  leqvio-monotherapy-demand-NOV217                │
└──────────────────────────────────────────────────────────────────────┘

  ▶ 2026-02-01 05:49   45m 49s   $1.45   124 tables  ✓ completed
    2026-01-31 22:15   52m 12s   $1.62   118 tables  ✓ completed
    2026-01-30 18:45    8m 04s   $0.23    42 tables  ✗ failed
```

**Keyboard shortcuts:**
- `j` / `k`: Select run
- `Enter`: View run details
- `Esc`: Back to menu
- `q`: Quit

### Run Details

After selecting a run, you can browse its artifacts:

```
┌──────────────────────────────────────────────────────────────────────┐
│ Run Details  │  Run: 2026-02-01 05:49                                │
└──────────────────────────────────────────────────────────────────────┘

  ▶ 📁 results/              crosstabs.xlsx, tables.json
    📁 verification/         scratchpad (verified tables)
    📁 basefilter/           scratchpad (filtered tables)
    📁 banner/               scratchpad (banner groups)
    📁 r/                    master.R, execution.log
    📄 pipeline-summary.json Run summary and costs
    📄 feedback.md           User feedback notes
```

**Keyboard shortcuts:**
- `j` / `k`: Select artifact
- `Enter`: View file contents (or list directory)
- `o`: Open in Finder
- `Esc`: Back to runs list

### File Viewer

When viewing a file, you can scroll through its contents:

```
Lines 1-20 of 150
┌─────────────────────────────────────────────────────────────────────┐
│ {                                                                   │
│   "dataset": "leqvio-monotherapy-demand-NOV217",                    │
│   "timestamp": "2026-02-01T06:35:02.948Z",                          │
│   ...                                                               │
└─────────────────────────────────────────────────────────────────────┘
```

**Keyboard shortcuts:**
- `j` / `k`: Scroll line by line
- `Ctrl+u` / `Ctrl+d`: Page up/down
- `Esc`: Back to artifacts

---

## [4] Settings

View the current model configuration (read-only).

```
┌──────────────────────────────────────────────────────────────────────┐
│ Settings  │  Model Configuration (Read-only)                         │
└──────────────────────────────────────────────────────────────────────┘

  Agent Models

  BannerAgent
    Model: gpt-5-nano  |  Tokens: 128,000
    Reasoning: medium  |  Prompt: production

  CrosstabAgent
    Model: o4-mini  |  Tokens: 100,000
    Reasoning: high  |  Prompt: production

  VerificationAgent
    Model: gpt-5-mini  |  Tokens: 128,000
    Reasoning: high  |  Prompt: alternative

  Testing Configuration

  Statistical Testing
    Confidence: 90% (p < 0.10)
    Proportion Test: Unpooled z-test
    Mean Test: Welch's t-test
    Min Base: None

─────────────────────────────────────────────────────────────────────
To change settings, edit .env.local or set environment variables
```

**To change settings**, edit `.env.local`:

```bash
# Model configuration
VERIFICATION_MODEL=gpt-5-mini
VERIFICATION_REASONING_EFFORT=high
VERIFICATION_PROMPT_VERSION=alternative

# Stat testing
STAT_THRESHOLDS=0.05,0.10
STAT_MIN_BASE=30
```

---

## Common Workflows

### Run the pipeline and review results

1. `hawktab` → Select **[1] Run Pipeline**
2. Wait for completion (watch the progress)
3. Press `q` to return to menu
4. Select **[3] Browse History**
5. Select the latest run
6. Navigate to `results/` and press `o` to open in Finder
7. Review `crosstabs.xlsx`

### Debug a failed table

1. Go to **Browse History**
2. Select the run
3. Open `verification/` or `basefilter/` scratchpad
4. Search for the table ID to see agent reasoning

### Test a specific agent in isolation

1. `hawktab` → Select **[2] Run Script**
2. Select `test-verification-agent.ts` or similar
3. Review output

### Check current configuration

1. `hawktab` → Select **[4] Settings**
2. Review model assignments and prompt versions

---

## Output Directory Structure

Each pipeline run creates:

```
outputs/<dataset>/pipeline-<timestamp>/
├── results/
│   ├── crosstabs.xlsx      # Final Excel output
│   └── tables.json         # Calculated table data
├── verification/
│   ├── scratchpad.md       # Agent reasoning trace
│   └── tables.json         # Verified tables
├── basefilter/
│   ├── scratchpad.md       # Agent reasoning trace
│   └── tables.json         # Filtered tables
├── banner/
│   └── scratchpad.md       # Banner extraction trace
├── crosstab/
│   └── scratchpad.md       # Cut validation trace
├── r/
│   ├── master.R            # Generated R script
│   └── execution.log       # R execution output
├── validation/
│   └── ...                 # R validation outputs
├── pipeline-summary.json   # Costs, timing, stats
└── feedback.md             # Your review notes
```

---

## Environment Variables

Key settings you can configure in `.env.local`:

| Variable | Description | Default |
|----------|-------------|---------|
| `VERIFICATION_MODEL` | Model for VerificationAgent | `gpt-5-mini` |
| `VERIFICATION_REASONING_EFFORT` | Reasoning depth | `medium` |
| `VERIFICATION_PROMPT_VERSION` | Prompt version | `production` |
| `STAT_THRESHOLDS` | Significance levels | `0.10` |
| `STAT_MIN_BASE` | Min base for testing | `0` |

See `src/lib/env.ts` for the complete list.

---

## Troubleshooting

### "Raw mode is not supported"
The CLI requires an interactive terminal. Don't pipe input to it.

### Pipeline seems stuck
Check the stage detail view - drill into parallel agents to see individual table progress.

### High costs
Check **Settings** to see which models are configured. Consider using cheaper models for testing.

### Tables don't match Joe's output
1. Check `verification/scratchpad.md` for agent reasoning
2. Look at `lastModifiedBy` in tables.json to know which agent to adjust
3. Consider tuning prompts in `src/prompts/`
