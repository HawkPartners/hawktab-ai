# HawkTab AI

**Crosstab Automation for Hawk Partners**

---

## What This Is

An internal tool to replace our current crosstab outsourcing workflow. Instead of sending data files to Joe or our fielding partners and waiting for tabs back, the team can generate them directly.

**Primary Goal**: Hawk Partners' 80-person team can log in, upload survey materials, and get accurate crosstabs—faster than outsourcing, with consistent quality.

**Secondary Goal**: If this works well internally, pilot with Bob's fielding company to validate external interest.

---

## The Problem We're Solving

| Current Workflow | Pain |
|------------------|------|
| Send data to Joe/fielding partner | Days of turnaround |
| Wait for tabs back | Blocking project timelines |
| Quality varies by vendor | Some beautiful, some not |
| Per-project cost | Adds up across many projects |
| No visibility | Black box until delivery |

## The Solution

An AI-powered system that:
- **Integrates with Decipher/Forsta** to access survey structure and skip logic directly
- **Validates banner expressions** against actual data before generating output
- **Uses Azure OpenAI** (compliance requirement—firm data stays in Azure)
- **Generates R syntax** for crosstab execution with statistical testing
- **Provides confidence scoring** so researchers know where to focus review

---

## Technology Stack

| Layer | Technology | Why |
|-------|------------|-----|
| **Framework** | Next.js 15 + TypeScript | Type-safe web application |
| **AI** | Vercel AI SDK + Azure OpenAI | Azure required for compliance |
| **Database** | Convex | 80 people need shared access, TypeScript-native |
| **Auth** | WorkOS AuthKit | Free for internal team, SSO available if we productize |
| **File Storage** | Cloudflare R2 | S3-compatible, generous free tier |
| **Error Monitoring** | Sentry | Know when things break |
| **Analytics** | PostHog (basic) | Usage tracking, low effort |
| **Survey Data** | Decipher API | Skip logic from source |
| **Stats Engine** | R Runtime | Crosstab generation |

---

## Current Implementation Status

### What's Working (MVP Foundation)

| Component | Status | Details |
|-----------|--------|---------|
| **Banner Processing** | Production | PDF/DOC extraction via Vision API, group separation |
| **Data Map Processing** | Production | CSV parsing with parent inference, type classification |
| **CrossTab Agent** | Production | Expression validation with confidence scoring |
| **Table Generator** | Production | Deterministic table structure from datamap (frequency vs mean) |
| **Verification Agent** | Production | Survey-aware label cleanup, NET rows, T2B, table splitting |
| **SkipLogic + FilterTranslator** | Production | Skip/show logic extraction and R filter translation |
| **Loop Detection + Stacking** | Production | LoopDetector, LoopCollapser, anchor/satellite detection, stacked R scripts |
| **Loop Semantics Policy** | Production | Classifies banner cuts as respondent- vs entity-anchored on stacked data |
| **Table Post-Processor** | Production | Deterministic post-pass: 7 formatting rules enforced after verification |
| **R Validation** | Production | Per-table validation, retry with error context |
| **R Script V2** | Production | JSON output with NET rows, derived tables, significance testing |
| **Excel Formatter** | Production | Antares-style output with NET row styling and indentation |
| **SPSS Integration** | Production | 99% variable match rate via `haven` package |
| **API Pipeline** | Production | Single endpoint, session-based processing |

### Key Achievements
- **TableGenerator**: Deterministic table structure based on `normalizedType` (no AI needed)
- **VerificationAgent**: Uses survey document to fix labels, add NETs, create T2B/B2B tables
- **SkipLogicAgent + FilterTranslatorAgent**: Extract skip/show rules from survey, translate to R filters, apply deterministically
- **RScriptGeneratorV2**: JSON output with `ExtendedTableDefinition` support (NET rows, indentation)
- **ExcelFormatter**: Bold NET rows, indented component rows, full banner group styling
- **Provenance Tracking**: `lastModifiedBy` field shows which agent created each table
- **R Validation**: Per-table validation catches errors before full script run
- **Loop/Stacked Data**: Automatic loop detection, variable collapsing, stacked R scripts, entity vs respondent anchoring
- **TablePostProcessor**: Deterministic post-pass enforces formatting consistency across parallel agent instances
- Successfully processes complex banner plans (19 columns, 6 groups)
- Handles sophisticated expressions like "IF HCP" with contextual inference
- Numbers match Joe's output on complex surveys with skip/show logic
- Decontaminated prompts: all agent prompts use generic, abstract examples to ensure generalizability

---

## Next Steps

### Current: Reliability Testing

Working through the reliability plan to ensure consistent, publication-quality output.

| Part | Description | Status |
|------|-------------|--------|
| 1 | Stable System for Testing | Complete |
| 2 | Leqvio Testing (iteration loop) | Complete |
| 3 | Loop/Stacked Data Support | Complete (core) |
| 4 | Broader Testing | Not started |

**Recent**: Tito's Future Growth (first stacked/looped data test) complete. 17 issues found, 12 resolved. See `docs/latest-runs-feedback.md`.

**Deadline**: Send updated version to Antares by February 16th.

See `docs/implementation-plans/reliability-plan.md`

### Then: Pre-Phase 2 Testing

Validate pipeline against `data/test-data/practice-files/` before proceeding:
→ `docs/implementation-plans/pre-phase-2-testing-plan.md`

### Roadmap

| Phase | Goal | Status |
|-------|------|--------|
| **1. Azure OpenAI** | Switch to Azure (compliance) | **Complete** |
| **1.5. Reliability** | Match Joe's output quality | **In Progress** |
| **2. Decipher + Reliability** | Skip logic from source, agent flow improvements | Not started |
| **3. Team Access** | Deploy, auth, shared storage | Not started |
| **Checkpoint** | Hawk Partners internal launch | — |

---

## Getting Started

### Prerequisites

**Node.js 18+**
```bash
npm install
```

**R Runtime** (for crosstab generation)
- macOS: `brew install r`
- Windows: Download from https://cran.r-project.org/bin/windows/base/
- Install packages: `Rscript -e "install.packages(c('haven','dplyr','tidyr'))"`

**PDF Processing** (for banner extraction)
- macOS: `brew install graphicsmagick ghostscript`

### Environment Setup

Copy `.env.example` to `.env.local` and fill in your Azure credentials.

**Per-Agent Configuration** (optional):
```bash
# Each agent can have independent model, token limit, and reasoning effort
CROSSTAB_MODEL=gpt-5-mini
CROSSTAB_MODEL_TOKENS=128000
CROSSTAB_REASONING_EFFORT=medium    # none | minimal | low | medium | high | xhigh

VERIFICATION_MODEL=gpt-5-mini
VERIFICATION_REASONING_EFFORT=high

BANNER_MODEL=gpt-5-nano
BANNER_REASONING_EFFORT=medium
```

### Development

```bash
npm run dev      # Start development server (Turbopack)
npm run lint     # ESLint checks
npx tsc --noEmit # TypeScript type checking
```

### Running the Pipeline

```bash
# Full pipeline (default dataset: Leqvio)
npx tsx scripts/test-pipeline.ts

# Specific dataset
npx tsx scripts/test-pipeline.ts data/test-data/titos-growth-strategy

# With options
npx tsx scripts/test-pipeline.ts --format=antares --display=both
npx tsx scripts/test-pipeline.ts --stop-after-verification
npx tsx scripts/test-pipeline.ts --concurrency=5
```

### Other Scripts

```bash
# Full pipeline: .sav → Banner → Crosstab → Tables → Verification → R → Excel
npx tsx scripts/test-pipeline.ts

# TableGenerator only (deterministic table generation, <1s)
npx tsx scripts/test-table-generator.ts

# VerificationAgent only (enhance tables using survey document)
npx tsx scripts/test-verification-agent.ts                     # Uses most recent pipeline output
npx tsx scripts/test-verification-agent.ts [folder]            # Uses specific output folder

# Regenerate R script from existing pipeline output
npx tsx scripts/test-r-regenerate.ts [dataset] [pipelineId]

# Validate .sav files across datasets
npx tsx scripts/test-validation-runner.ts

# Export Excel from existing tables.json
npx tsx scripts/export-excel.ts                    # Uses most recent session
npx tsx scripts/export-excel.ts [sessionId]        # Uses specific session
```

**Full Pipeline Output** (`outputs/<dataset>/pipeline-<timestamp>/`):
- `r/master.R` - Generated R script
- `results/tables.json` - Calculated tables with significance testing
- `results/crosstabs.xlsx` - Formatted Excel workbook
- `pipeline-summary.json` - Run metadata and timing

The pipeline runs 13 steps (6 AI agents + 7 deterministic steps):
1. **ValidationRunner** - Validate .sav, build verbose datamap, detect and collapse loops
2. **BannerAgent** *(AI)* - Extract banner structure from PDF/DOCX
3. **CrosstabAgent** *(AI)* - Validate and generate R expressions for cuts
4. **TableGenerator** - Build table definitions from datamap (deterministic)
5. **SkipLogicAgent** *(AI)* - Extract skip/show rules from survey
6. **FilterTranslatorAgent** *(AI)* + **FilterApplicator** - Translate rules to R, apply filters to tables
7. **VerificationAgent** *(AI)* - Enhance tables using survey document (fix labels, add NETs, T2B)
8. **TablePostProcessor** - Deterministic post-pass enforcing formatting consistency (7 rules)
9. **R Validation** - Validate each table's R code before full script run
10. **LoopSemanticsPolicyAgent** *(AI)* - Classify banner cuts for stacked data (if loops detected)
11. **RScriptGeneratorV2** - Generate R script with derived tables and loop policies
12. **R Execution** - Run R script to calculate tables with significance testing
13. **ExcelFormatter** - Format tables.json into Excel workbook

### Testing (UI)

Upload files via http://localhost:3000:
1. Data Map (CSV)
2. Banner Plan (PDF/DOC)
3. SPSS File (.sav)

---

## Project Structure

```
hawktab-ai/
├── src/
│   ├── agents/           # AI agents (Banner, Crosstab, Verification, SkipLogic, FilterTranslator, LoopSemantics)
│   ├── app/api/          # API endpoints
│   ├── lib/
│   │   ├── excel/        # ExcelFormatter and table renderers
│   │   ├── processors/   # DataMapProcessor, BannerProcessor
│   │   ├── r/            # RScriptGeneratorV2
│   │   ├── tables/       # TableGenerator, CutsSpec, TablePostProcessor, sortTables
│   │   └── validation/   # LoopDetector, LoopCollapser, RDataReader, ValidationRunner
│   ├── prompts/          # Agent prompt templates (production.ts + alternative.ts per agent)
│   └── schemas/          # Zod type definitions
├── scripts/              # CLI test scripts
├── data/test-data/       # Test datasets (23 projects)
│   └── practice-files/   # Default test dataset
├── docs/
│   ├── latest-runs-feedback.md    # Issue tracking from pipeline runs
│   └── implementation-plans/      # Architecture docs and plans
└── temp-outputs/         # Development outputs (git-ignored)
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| `docs/implementation-plans/reliability-plan.md` | Current work: reliability testing and evaluation |
| `docs/implementation-plans/table-agent-architecture.md` | Table/Verification agent architecture |
| `docs/implementation-plans/pre-phase-2-testing-plan.md` | Testing milestones |
| `docs/architecture-refactor-prd.md` | Overall architecture and roadmap |
| `CLAUDE.md` | AI assistant context and coding guidelines |
| `docs/audits/security-audit-prompt.md` | Security review checklist |

---

## Security

Key security decisions for handling Hawk Partners data:

- **Azure OpenAI**: Firm data stays in Azure tenant (compliance requirement)
- **Authentication**: WorkOS AuthKit (team login)
- **Error Monitoring**: Sentry with PII scrubbing
- **Data Encryption**: TLS in transit, encrypted at rest

See `docs/audits/security-audit-prompt.md` for security review checklist.

---

## Development Standards

- TypeScript strict mode required
- Run `npm run lint` and `npx tsc --noEmit` before commits
- Security considerations documented for changes

---

## License

Proprietary - Hawk Partners Internal Tool
