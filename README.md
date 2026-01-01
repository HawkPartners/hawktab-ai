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
| **Data Map Processing** | Production | CSV parsing with parent inference, 192+ variables |
| **CrossTab Agent** | Production | Expression validation with confidence scoring |
| **R Script Generation** | Production | Complete syntax generation with statistical summaries |
| **SPSS Integration** | Production | 99% variable match rate via `haven` package |
| **API Pipeline** | Production | Single endpoint, session-based processing |

### Key Achievements
- Successfully processes complex banner plans (19 columns, 6 groups)
- Handles sophisticated expressions like "IF HCP" with contextual inference
- Generates graduated confidence scores for human review prioritization
- Distinguishes overlapping categories (HCP vs NP/PA) using semantic understanding

---

## Next Steps

The MVP demonstrates the concept works. Next phases to make it usable by the team:

| Phase | Goal | Status |
|-------|------|--------|
| **1. Azure OpenAI** | Switch to Azure (compliance) | **Complete** |
| **2. Decipher + Reliability** | Skip logic from source, agent flow improvements | Not started |
| **3. Team Access** | Deploy, auth, shared storage | Not started |
| **Checkpoint** | Hawk Partners internal launch | — |
| **4. Bob Pilot** | External validation | — |

See `docs/architecture-refactor-prd.md` for full details.

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

Create `.env.local`:
```env
# Azure OpenAI (required - Phase 1 complete)
AZURE_API_KEY=your_azure_api_key
AZURE_RESOURCE_NAME=your_resource_name
AZURE_API_VERSION=2025-01-01-preview

# Model Configuration (Azure deployment names)
REASONING_MODEL=o4-mini
BASE_MODEL=gpt-5-nano

# Environment
NODE_ENV=development
```

### Development

```bash
npm run dev      # Start development server (Turbopack)
npm run lint     # ESLint checks
npx tsc --noEmit # TypeScript type checking
npm run build    # Production build
```

### Testing

Upload files via the web interface at http://localhost:3000:
1. Data Map (CSV) - Variable definitions
2. Banner Plan (PDF/DOC) - Crosstab specification
3. SPSS File (.sav) - Survey response data

Review outputs in `temp-outputs/output-{timestamp}/`

---

## Project Structure

```
hawktab-ai/
├── src/
│   ├── agents/           # AI agent implementations
│   ├── app/              # Next.js app router
│   │   └── api/          # API endpoints
│   ├── components/       # React components
│   ├── guardrails/       # Input/output validation
│   ├── lib/              # Core utilities
│   │   ├── processors/   # Data processing pipeline
│   │   ├── r/            # R script generation
│   │   └── tables/       # Table definitions
│   ├── prompts/          # AI prompt templates
│   └── schemas/          # Zod type definitions
├── convex/               # Convex backend (future)
├── docs/                 # Documentation
├── data/                 # Test data files
└── temp-outputs/         # Development outputs
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| `docs/architecture-refactor-prd.md` | Complete architecture plan and roadmap |
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
