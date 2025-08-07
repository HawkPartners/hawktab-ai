# HawkTab AI - Intelligent Crosstab Generation Platform

## Overview

HawkTab AI is an agent-first, AI-powered platform that automates crosstab generation for Hawk Partners' market research workflows. By leveraging OpenAI's Agents SDK and sophisticated data processing pipelines, we're replacing expensive outsourced crosstab generation with an intelligent system that understands complex banner plans and automatically maps them to survey data.

**The Problem**: Hawk Partners currently outsources crosstab generation to external vendors, which is costly, time-consuming, and creates dependencies on third parties.

**Our Solution**: An intelligent agent system that can read banner plans, understand data mappings, and generate validated R syntax for crosstab execution—all while maintaining enterprise-grade type safety, security, and observability.

---

## Vision

**A collaborative, web-based workspace where HawkPartners staff and research partners can:**
- Upload raw quant survey data (SPSS `.sav` files)
- Upload project banner plans (Excel, CSV, or similar)
- Upload the final questionnaire (PDF, DOCX, or text)
- Automatically generate high-quality crosstab outputs matching or exceeding the accuracy and clarity of existing providers (Joe/Antares)
- Receive QC analysis on soft launch/full data for speeders, straight-liners, logic issues, and routing errors
- Collaborate on projects with secure user access, notification, and threaded follow-ups for new tab requests or QC reviews

---

## Current Implementation Status ✅

### What's Working Now
- **Complete Processing Pipeline**: Upload CSV data maps, banner plans (PDF/DOC), and SPSS files through a single API endpoint
- **Intelligent CrossTab Agent**: Uses OpenAI's Agents SDK to validate banner expressions against data maps with confidence scoring
- **Sophisticated Data Processing**: 
  - State machine-based CSV parsing with parent inference
  - PDF-to-image banner extraction using Vision API
  - Dual output strategy (verbose for debugging, simplified for agents)
- **Production-Grade Architecture**:
  - Full TypeScript with Zod schemas for type safety
  - Environment-based model switching (reasoning vs base models)
  - Modular prompt system for A/B testing
  - Comprehensive tracing and observability
  - Session-based output organization

### Key Achievements
- Successfully processes 192 variables with 130 parent relationships
- 99% accuracy in SPSS variable matching
- Handles complex expressions like "IF HCP" with intelligent inference
- Distinguishes between overlapping categories (HCP vs NP/PA) using context
- Provides graduated confidence scores for human review prioritization
- Processes 19 columns across 6 banner groups in real-world tests

### Technology Stack
- **Framework**: Next.js 15 with TypeScript
- **AI/ML**: OpenAI Agents SDK, GPT-4o, O1 reasoning models
- **Data Processing**: Zod schemas, state machines, PDF processing
- **Development**: ESLint, Turbopack, hot reload

---

## Next Steps (In Progress)

- [x] **Tracing Export**: ✅ Implemented unified trace aggregation with `withTrace()` wrapper and `forceFlush()`
- [ ] **Banner Processing Agent**: Convert BannerProcessor to Agents SDK with scratchpad tool for proper group separation
- [ ] **Validation UI**: Visual interface for reviewing agent decisions
- [ ] **Banner Plan Merging**: Combine agent results with original plans
- [ ] **Total Column**: Add statistical total for significance testing
- [ ] **R Script Generation Agent**: Convert validated mappings to executable R
- [ ] **QA System**: Automated quality assurance for outputs
- [ ] **Human-in-the-Loop**: Trigger manual review for low confidence scores
- [ ] **Batch Processing**: Test across multiple files systematically

See [Future Enhancements](docs/future-enhancements.md) for detailed roadmap.

---

## End-State Features (Long-term Vision)

- **Multi-file intake:** SPSS file, banner plan, questionnaire—all uploadable to one project workspace.
- **Automated Parsing:**
  - **Questionnaire parsing:** Extracts all questions (IDs, text, routing, skips, terminates, programming notes).
  - **Banner plan parsing:** Reads tab spec (splits, cuts, filters, stat tests, etc.).
  - **Variable mapping:** Intelligently matches banner plan/questions to SPSS variable names, prompting user for ambiguous cases.
- **Human-in-the-Loop Orchestration:**
  - After auto-mapping, system displays all mapped questions, splits, and logic; user reviews and confirms before tabs are generated.
  - All follow-up tab requests or new cuts handled in threaded chat interface—LLM parses requests, confirms with user, and executes.
- **Cross-tab Generation:**
  - Clean, intuitive Excel output (matching Antares/Joe in data quality, basic formatting at MVP, with further polish later).
  - Support for significance testing, custom nets, weighting, and complex filters as needed.
- **QC and Data Validation:**
  - Checks for speeders, straight-liners, routing/logic errors, and skipped/terminated cases.
  - Compares actual data routing/terminations to programmed logic from parsed questionnaire.
  - Generates flagged respondent list and summary QC report.
- **Collaboration & Workflow:**
  - Project-based access for both internal and external partners.
  - Notifications for key events (file upload, mapping needed, output ready, follow-up request).
  - All actions and revisions threaded and logged per project.
- **Security and Data Privacy:** All data processing is internal or on a secure cloud, with strict access controls.

---

## File Format Requirements & Notes

This section contains important requirements for file formats and data preparation to ensure smooth processing:

### Data Map Requirements
- **Required Format**: CSV file (.csv) only - recruiters must export the data map as a standalone CSV file
- **Format**: The data map CSV should contain columns for:
  - Question ID/Number (e.g., "Q1", "Q2a") - column can be named: question, question_id, q, qid, etc.
  - Variable/Column name in the raw data - column can be named: variable, var, column, spss_variable, etc.
  - Description/Label (optional but helpful) - column can be named: description, label, question_text, etc.

### File Upload Requirements
- **Interim Data**: One or more SPSS (.sav) files containing preliminary data (soft launch, partial data, etc.)
- **Final Data**: Single SPSS (.sav) file containing the complete dataset
- **Banner Plan**: Word document (.doc or .docx) that will be converted to PDF
- **Questionnaire**: Word document (.doc or .docx) that will be converted to PDF
- **Data Map**: CSV file (.csv) mapping questions to data columns

### UI/UX Notes
- During the upload flow, provide clear instructions about file format requirements
- Consider adding tooltips or help text explaining what each file type should contain
- Add validation messages that guide users to correct file formats

### Future Considerations
- Standardize data map format with recruiters for consistent processing
- Create template files that recruiters can use to ensure compatibility
- Document any specific naming conventions or required columns
- **IMPORTANT**: The current iteration will be optimized for Antares—we'll need to add support for other research partners such as TestSet, etc.

---

## Getting Started

### Prerequisites
```bash
# Required Node.js 18+
npm install
```

### Environment Setup
Create `.env.local`:
```env
OPENAI_API_KEY=your_api_key_here
NODE_ENV=development

# Optional: Test alternative prompts
CROSSTAB_PROMPT_VERSION=production  # or 'alternative'
BANNER_PROMPT_VERSION=production    # or 'alternative'
```

### Development
```bash
npm run dev     # Start development server with Turbopack
npm run lint    # Run ESLint
npx tsc --noEmit  # Type checking
```

### Testing the System
1. Navigate to http://localhost:3000
2. Upload required files:
   - Data Map (CSV)
   - Banner Plan (PDF/DOC)
   - SPSS Data File (.sav)
3. Review outputs in `temp-outputs/output-{timestamp}/`

---

## Architecture Highlights

### Agent-First Approach
We use OpenAI's Agents SDK with a "one agent, multiple calls" strategy, processing banner groups individually for better focus and transparency. The agent uses context injection rather than heavy tool usage, providing full data structures directly in instructions.

### Type Safety & Best Practices
- **Zod-First Development**: All schemas defined before implementation
- **TypeScript Throughout**: Full type safety with strict mode
- **Error Boundaries**: Graceful degradation with intelligent fallbacks
- **Observability**: Comprehensive tracing at every stage

### Key Design Decisions
- **Group-by-Group Processing**: Maintains context within logical groupings
- **Dual Output Strategy**: Verbose for debugging, simplified for agents
- **Confidence Scoring**: Graduated scores (0.0-1.0) for prioritizing review
- **Session Organization**: Timestamp-based folders for clean output management

---

## Documentation

- [Architecture Overview](docs/openai-agents-architecture.md) - Technical specifications and patterns
- [Implementation Roadmap](docs/roadmap.md) - Completed phases and methodology
- [Future Enhancements](docs/future-enhancements.md) - Next steps and long-term vision

---

## Contributing

This is currently an internal Hawk Partners project. For questions or contributions, please contact the development team.

---

## License

Proprietary - Hawk Partners Internal Use Only