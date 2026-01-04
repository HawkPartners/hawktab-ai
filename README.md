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
| **R Script V2** | Production | JSON output with correct base sizing |
| **SPSS Integration** | Production | 99% variable match rate via `haven` package |
| **API Pipeline** | Production | Single endpoint, session-based processing |

### Key Achievements
- **TableAgent**: AI decides table structure based on `normalizedType` (replaces regex)
- **RScriptGeneratorV2**: JSON output with two table types (`frequency`, `mean_rows`)
- Successfully processes complex banner plans (19 columns, 6 groups)
- Handles sophisticated expressions like "IF HCP" with contextual inference
- Generates graduated confidence scores for human review prioritization

---

## Next Steps

### Immediate: Finalize Table Agent Architecture

| Step | Description | Status |
|------|-------------|--------|
| 5.5 | R significance testing | Verify |
| 6 | ExcelJS Formatter | Next |
| 7 | Excel Cleanup Agent (optional) | Planned |

See `docs/implementation-plans/table-agent-architecture.md`

### Then: Pre-Phase 2 Testing

Validate pipeline against `data/test-data/practice-files/` before proceeding:
→ `docs/implementation-plans/pre-phase-2-testing-plan.md`

### Roadmap

| Phase | Goal | Status |
|-------|------|--------|
| **1. Azure OpenAI** | Switch to Azure (compliance) | **Complete** |
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

### Development

```bash
npm run dev      # Start development server (Turbopack)
npm run lint     # ESLint checks
npx tsc --noEmit # TypeScript type checking
```

### Testing (CLI)

Test scripts that run against `data/test-data/practice-files/`:

```bash
# Full pipeline (DataMap → Banner → Crosstab → Table → R)
npx tsx scripts/test-pipeline.ts

# TableAgent only
npx tsx scripts/test-table-agent.ts

# R script generation from existing TableAgent output
npx tsx scripts/test-r-script-v2.ts
```

Output: `temp-outputs/test-pipeline-<dataset>-<timestamp>/`

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
│   ├── agents/           # AI agents (Banner, Crosstab, Table)
│   ├── app/api/          # API endpoints
│   ├── lib/
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
| `docs/implementation-plans/table-agent-architecture.md` | Current work: Steps 5.5-7 |
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
