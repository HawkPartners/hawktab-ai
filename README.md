# HawkTab AI

**Market Research Crosstab Automation Platform**

---

## Executive Summary

HawkTab AI is a production-ready crosstab automation system that transforms how market research firms generate statistical tables. By integrating directly with survey platforms (Decipher/Forsta), leveraging multi-provider AI (via Vercel AI SDK), and building on enterprise-grade infrastructure (Convex, WorkOS, Sentry), the system delivers accurate, statistically-tested crosstabs with minimal manual intervention.

**Core Thesis**: Crosstab generation is complex but automatable. The key is eliminating parsing ambiguity by going to the source (survey platform APIs), validating against actual data before output, and providing transparency at every step.

**Target Outcome**: Market researchers upload their survey materials and receive accurate crosstabs—with confidence scores, validation warnings, and statistical testing—ready for client delivery.

---

## The Problem

Market research firms face significant friction in crosstab generation:

| Pain Point | Impact |
|------------|--------|
| **Manual processing** | Hours spent mapping banner plans to survey variables |
| **Outsourcing costs** | $500-2000+ per project to external vendors |
| **Turnaround time** | Days waiting for external deliverables |
| **Quality variance** | Inconsistent output quality across vendors |
| **No transparency** | Black box processing with limited visibility |

## The Solution

An intelligent agent system that:
- **Integrates with Decipher/Forsta** to access survey structure, skip logic, and data directly
- **Validates banner expressions** against actual respondent data before generating output
- **Provides confidence scoring** so researchers know exactly where to focus review
- **Generates R syntax** for crosstab execution with statistical testing
- **Supports enterprise auth** (SSO, SCIM) for seamless organizational deployment

---

## Technology Stack

### Core Platform
| Layer | Technology | Purpose |
|-------|------------|---------|
| **Framework** | Next.js 15 + TypeScript | Type-safe web application |
| **Database** | Convex | Real-time reactive backend, TypeScript-native |
| **Auth** | WorkOS AuthKit | Enterprise SSO, SCIM, free to 1M MAU |
| **AI** | Vercel AI SDK | Multi-provider (OpenAI, Anthropic, Azure) |
| **File Storage** | Cloudflare R2 | S3-compatible, no egress fees |

### Observability
| Tool | Purpose |
|------|---------|
| **Sentry** | Error monitoring, session replay, performance |
| **PostHog** | Product analytics, feature flags, A/B testing |

### Data Processing
| Component | Purpose |
|-----------|---------|
| **Decipher API** | Direct survey platform integration |
| **R Runtime** | Statistical crosstab generation |
| **Zod Schemas** | Runtime type validation |

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

## Architecture Refactor (Next Phase)

The current MVP demonstrates the concept. The next phase transforms it into enterprise-ready infrastructure:

### Phase 1: Foundation
- [ ] Initialize Convex + WorkOS AuthKit
- [ ] Set up Sentry error monitoring
- [ ] Set up PostHog analytics
- [ ] Create Convex schema (projects, jobs, files)
- [ ] Configure Cloudflare R2 for file storage

### Phase 2: AI Layer Migration
- [ ] Migrate agents from OpenAI SDK to Vercel AI SDK
- [ ] Add multi-provider support (OpenAI, Anthropic, Azure)
- [ ] Implement provider selection per task type

### Phase 3: Reliability Improvements
- [ ] Implement pre-execution count validation
- [ ] Add validation warnings to output schema
- [ ] Update prompts for calibrated confidence scoring
- [ ] Create validation summary UI component

### Phase 4: Decipher Integration
- [ ] Build survey structure fetcher
- [ ] Parse skip logic from survey XML
- [ ] Integrate skip logic into validation
- [ ] Add Decipher as primary data source

See `architecture-refactor-prd.md` for the complete implementation roadmap.

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
- Windows: See installation notes in `docs/setup/windows-dependencies.md`

### Environment Setup

Create `.env.local`:
```env
# Required
OPENAI_API_KEY=your_api_key_here

# Optional (future)
ANTHROPIC_API_KEY=your_anthropic_key
AZURE_OPENAI_KEY=your_azure_key

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
| `architecture-refactor-prd.md` | Complete architecture plan and roadmap |
| `CLAUDE.md` | AI assistant context and coding guidelines |
| `docs/security-audit-prompt.md` | Security review checklist |
| `docs/architecture/` | Technical architecture details |

---

## Security

HawkTab AI is designed for enterprise deployment with security as a first-class concern:

- **Authentication**: WorkOS AuthKit with enterprise SSO/SCIM support
- **Authorization**: Row-level security via Convex policies
- **Error Monitoring**: Sentry with PII scrubbing
- **Audit Logging**: Full action history per project
- **Data Encryption**: TLS in transit, encrypted at rest

Security audits are conducted regularly. See `docs/security-audit-prompt.md`.

---

## Contributing

This project follows enterprise development practices:
- TypeScript strict mode required
- All changes require type checking (`npx tsc --noEmit`)
- ESLint must pass (`npm run lint`)
- Security considerations documented for each PR

---

## License

Proprietary - All Rights Reserved
