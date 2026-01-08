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
| **Table Agent** | Production | AI-based table structure decisions (frequency vs mean) |
| **Verification Agent** | Production | Survey-aware label cleanup, NET rows, T2B, table splitting |
| **R Script V2** | Production | JSON output with NET rows, derived tables, significance testing |
| **Excel Formatter** | Production | Antares-style output with NET row styling and indentation |
| **SPSS Integration** | Production | 99% variable match rate via `haven` package |
| **API Pipeline** | Production | Single endpoint, session-based processing |

### Key Achievements
- **TableAgent**: AI decides table structure based on `normalizedType` (replaces regex)
- **VerificationAgent**: Uses survey document to fix labels, add NETs, create T2B/B2B tables
- **RScriptGeneratorV2**: JSON output with `ExtendedTableDefinition` support (NET rows, indentation)
- **ExcelFormatter**: Bold NET rows, indented component rows, full banner group styling
- **Per-Agent Configuration**: Each agent has independent model, tokens, and reasoning effort settings
- Successfully processes complex banner plans (19 columns, 6 groups)
- Handles sophisticated expressions like "IF HCP" with contextual inference
- Generates graduated confidence scores for human review prioritization

---

## Next Steps

### Current: Reliability Testing

Working through the reliability plan to ensure consistent, publication-quality output.

| Part | Description | Status |
|------|-------------|--------|
| 1 | Bug Capture (compare to Joe's tabs) | Complete |
| 2 | VerificationAgent Implementation | Complete |
| 3 | Significance Testing (unpooled z-test) | Not started |
| 4 | Evaluation Framework (golden dataset) | Not started |
| 5 | Iteration on practice-files | Not started |
| 6 | Broader Testing (23 datasets) | Not started |

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

TABLE_MODEL=gpt-5-mini
TABLE_REASONING_EFFORT=high

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

### Testing (CLI)

Test scripts that run against `data/test-data/practice-files/`:

```bash
# Full pipeline: DataMap → Banner → Crosstab → Table → R → Excel
npx tsx scripts/test-pipeline.ts

# TableAgent only (table structure analysis)
npx tsx scripts/test-table-agent.ts

# VerificationAgent only (enhance tables using survey document)
npx tsx scripts/test-verification-agent.ts                     # Uses most recent pipeline output
npx tsx scripts/test-verification-agent.ts [folder]            # Uses specific output folder

# Test R script changes without re-running full pipeline
# Uses existing pipeline outputs → generates new R script → runs R → generates Excel
npx tsx scripts/test-r-changes.ts                  # Uses most recent pipeline output
npx tsx scripts/test-r-changes.ts [folder]         # Uses specific pipeline folder
# Output: temp-outputs/test-r-changes-<timestamp>/results/crosstabs-changes.xlsx

# Export Excel from existing tables.json (if pipeline was interrupted)
npx tsx scripts/export-excel.ts                    # Uses most recent session
npx tsx scripts/export-excel.ts [sessionId]        # Uses specific session

# DEPRECATED: Use test-r-changes.ts instead
# npx tsx scripts/test-r-script-v2.ts
```

**Full Pipeline Output** (`temp-outputs/test-pipeline-<dataset>-<timestamp>/`):
- `r/master.R` - Generated R script
- `results/tables.json` - Calculated tables with significance testing
- `results/crosstabs.xlsx` - Formatted Excel workbook (Antares-style)
- `pipeline-summary.json` - Run metadata and timing

The pipeline runs 8 steps:
1. **DataMapProcessor** - Parse datamap CSV with SPSS metadata
2. **BannerAgent** - Extract banner structure from PDF/DOCX
3. **CrosstabAgent** - Validate and generate R expressions for cuts
4. **TableAgent** - Analyze variables and generate table definitions
5. **VerificationAgent** - Enhance tables using survey document (fix labels, add NETs, T2B)
6. **RScriptGeneratorV2** - Generate R script with derived tables
7. **R Execution** - Run R script to calculate tables with significance testing
8. **ExcelFormatter** - Format tables.json into Antares-style Excel workbook

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
│   ├── agents/           # AI agents (Banner, Crosstab, Table, Verification)
│   ├── app/api/          # API endpoints
│   ├── lib/
│   │   ├── excel/        # ExcelFormatter and table renderers
│   │   ├── processors/   # DataMapProcessor, BannerProcessor
│   │   ├── r/            # RScriptGeneratorV2
│   │   └── tables/       # CutsSpec
│   ├── prompts/          # AI prompt templates
│   └── schemas/          # Zod type definitions
├── scripts/              # CLI test scripts
├── data/test-data/       # Test datasets (23 projects)
│   └── practice-files/   # Default test dataset
├── docs/implementation-plans/
│   ├── table-agent-architecture.md
│   └── pre-phase-2-testing-plan.md
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
