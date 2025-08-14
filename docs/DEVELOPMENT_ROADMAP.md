# HawkTab AI Development Roadmap

## Current Status (MVP Complete)

### System Overview
HawkTab AI is a sophisticated crosstab automation system that processes market research data through a multi-phase pipeline using OpenAI Agents SDK, generating statistical tables via R scripts.

### Core Components & Functionality

1. **Three-Phase Processing Pipeline**
   - **Phase 5**: Banner PDF/DOC extraction + Data Map CSV processing with dual output strategy (verbose/agent JSON)
   - **Phase 6**: CrossTab Agent validation with group-by-group processing and confidence scoring
   - **Phase 7**: R script generation, execution, and CSV/Excel export

2. **Input Processing**
   - Accepts Banner Plans (PDF/DOC/DOCX), Data Maps (CSV), and SPSS files (.sav)
   - BannerAgent uses vision capabilities to extract column specifications from document images
   - DataMapProcessor employs state machine parsing with parent-child relationship inference

3. **Agent-Based Validation**
   - CrossTab Agent processes banner groups individually with injected context
   - Generates R expressions with confidence scores (0.0-1.0) based on variable mapping quality
   - Uses scratchpad tool for transparent reasoning and debugging

4. **R Integration & Output**
   - Dynamically generates R scripts using haven/dplyr libraries
   - Produces individual CSV tables plus combined workbook (COMBINED_TABLES.csv)
   - Non-blocking error handling allows partial table generation
   - Excel export with professional formatting via `/api/export-workbook/[sessionId]`

5. **API Architecture**
   - Single endpoint design (`/api/process-crosstab`) handles complete workflow
   - Job tracking system for async processing with progress monitoring
   - Environment-aware model selection (reasoning vs base models)

### Current Capabilities
- Successfully processes 192+ variables with 130+ parent relationships
- Handles complex banner logic (specialty cuts, role-based filtering, sub-groups)
- Generates statistical summaries (N, Mean, Median, SD) across all banner cuts
- 99% SPSS variable match rate with confidence-based validation

### Known Limitations & Issues
- R script data frame initialization occasionally fails with certain table structures
- Some complex banner expressions may not translate perfectly to R syntax
- Error recovery could be more granular at the table level
- Limited support for weighted data and significance testing

---

## Executive Summary - Development Phases

**Goal**: Transform HawkTab AI from MVP to production-ready system that generates statistically-tested, professionally-formatted crosstabs with zero manual intervention.

**Core Innovation**: Agent-orchestrated pipeline with self-healing capabilities, where specialized agents validate and fix issues automatically rather than failing.

**Key Phases**:
- **Phase 0**: Organize test data from Antares (10 projects)
- **Phase 1**: Add survey processing with IBM Docling
- **Phase 2**: Survey Agent creates comprehensive JSON structure
- **Phase 3**: Multi-layer validation ensuring data alignment
- **Phase 4**: R Script Agent orchestrates generation with specialized tools
- **Phase 5**: Add statistical testing and professional Excel formatting
- **Phase 6**: Systematic testing through all 10 projects
- **Phase 7**: Production infrastructure preparation

**Success Criteria**: First project working 100% end-to-end enables demo; all 10 projects validated enables production launch.

---

## Next Steps

### Phase 0: Data Preparation & Analysis (Pre-Development)

#### 0.1 Organize Antares Test Data
- [ ] Create folder structure for 10 test projects from Antares
- [ ] Each project folder should contain:
  - Data map (CSV)
  - Raw SPSS file (.sav)
  - Banner plan (PDF/DOC/DOCX)
  - Questionnaire/Survey document
- [ ] Verify all files are present and accessible for batch testing

#### 0.2 Data Map Format Analysis
- [ ] Analyze the data map format provided by Antares
- [ ] Determine if current parsing logic can handle their format
- [ ] Decide whether to:
  - Parse as-is (preferred - no special requests to Antares)
  - Request adjustments (only if absolutely necessary)
- [ ] Document the standard data map format they can consistently output

### Phase 1: Data Processing & File Upload

#### 1.1 Update UI for Four File Uploads
- [ ] Modify UI to accept 4 file types:
  - Banner Plan (PDF/DOC/DOCX) 
  - Data Map (CSV)
  - SPSS File (.sav)
  - Survey/Questionnaire (PDF/DOC/DOCX) - NEW

#### 1.2 Implement Processing Pipelines
- [ ] **Banner Plan**: Keep existing image processing pipeline (PDF → Images → Agent)
- [ ] **Data Map**: Update parsing logic for new Antares format
- [ ] **Survey**: Implement IBM Docling (D-O-C-L-I-N-G) for document → markdown conversion
- [ ] **SPSS**: Keep existing processing

#### 1.3 Parallel Processing Implementation
- [ ] Enable simultaneous processing of:
  - Banner plan image generation
  - Data map parsing
  - Survey document conversion

### Phase 2: Survey Agent & JSON Structure Generation

#### 2.1 Survey Agent Implementation
- [ ] Create new Survey Agent that:
  - Takes markdown from Docling conversion
  - Takes parsed data map for variable mapping
  - Generates comprehensive survey JSON structure

#### 2.2 Survey JSON Output Structure
- [ ] Include for each question:
  - Question number
  - Question text
  - Answer options (mapped to data map variables)
  - Terminal criteria
  - Survey logic/skip patterns
  - Programming notes
  - Question type (open-end, scale, numeric, etc.)
  - Valid ranges for numeric questions
  - All metadata a human would extract from reading the survey

### Phase 3: Validation & Enhancement

#### 3.1 Banner Plan Validation (Existing + Enhanced)
- [ ] Keep existing CrossTab Agent validation
- [ ] Enhance to access SPSS file for valid answer options
- [ ] Either use data map values OR implement more robust validation
- [ ] Ensure suggestions are actually valid against available data

#### 3.2 User Validation Workflow
- [ ] User validates banner plan output
- [ ] User validates survey JSON structure
- [ ] Allow corrections/fixes after validation
- [ ] All outputs validated against data map variables

#### 3.3 Final Validated Outputs
- [ ] Validated banner plan (uses data map variables)
- [ ] Robust survey JSON (uses same variable names as data map)
- [ ] Both structures fully aligned with data map

**Phase 3 Output**: Three fully validated, aligned structures ready for R script generation

### Phase 4: R Script Agent & Orchestration

**Key Innovation**: Move from deterministic processing to agent-orchestrated generation with self-healing capabilities. The R Script Agent acts as a conductor, using specialized tools but making intelligent decisions about fixes and validation.

#### 4.1 Additional UI Inputs
- [ ] Collect project metadata upfront:
  - Research objectives
  - Project name
  - Project code
  - Contact email
  - Any specific analysis requirements

#### 4.2 R Script Agent Implementation
- [ ] Create orchestration agent with system prompt for crosstab generation
- [ ] Agent has access to all validated outputs from Phase 3:
  - Validated banner plan (with cuts and column definitions)
  - Survey JSON structure (with question types, ranges, logic)
  - Data map (ground truth for variables)
  - SPSS file (actual data)
- [ ] Self-healing capabilities - can fix issues autonomously
- [ ] Maintains conversation history for debugging/audit trail

#### 4.3 Tool Development for R Script Agent

##### Tool 1: Verify Cuts
- [ ] **Purpose**: Validate banner plan cuts against actual SPSS data
- [ ] **Implementation**: 
  - Take banner plan expressions
  - Run against SPSS to verify they produce valid subsets
  - Return success/failure with specific issues
- [ ] **Error Handling**: Agent fixes invalid cuts based on available variables

##### Tool 2: Create Tables Structure
- [ ] **Purpose**: Transform survey JSON into R-ready table definitions
- [ ] **Implementation**:
  - Convert survey questions into table structures
  - Map question types to appropriate statistical treatments
  - Include all metadata (ranges, scales, etc.)
- [ ] **Output**: R-compatible table definitions

##### Tool 3: Validate Tables
- [ ] **Purpose**: Cross-check table definitions with Survey Agent
- [ ] **Implementation**:
  - Pass table structure back to Survey Agent
  - Survey Agent verifies against original survey document
  - Flag missing questions or misaligned mappings
- [ ] **Feedback Loop**: Corrections applied automatically

##### Tool 4: Create Crosstabs
- [ ] **Purpose**: Generate final R script for crosstab execution
- [ ] **Implementation**:
  - Combine verified cuts and validated tables
  - Generate R syntax with proper statistical calculations
  - Include error handling within R script
- [ ] **Validation**: Test run portions to ensure syntax validity

#### 4.4 Orchestration Flow
1. R Script Agent receives all inputs
2. Runs Verify Cuts → fixes issues if found
3. Runs Create Tables → transforms survey to tables
4. Runs Validate Tables → confirms with Survey Agent
5. Runs Create Crosstabs → generates final R script
6. Each step includes validation and self-correction

#### 4.5 Validation Philosophy
- [ ] **Goal**: Zero manual intervention required
- [ ] **Strategy**: Multiple validation checkpoints with automatic correction
- [ ] **Key Principles**:
  - Validate early and often
  - Agent fixes issues rather than failing
  - Cross-validation between agents (R Script ↔ Survey Agent)
  - Test partial outputs before full generation
- [ ] **Error Recovery**: Each tool returns specific error details for targeted fixes

#### 4.6 Output Decision Point
- [ ] Determine output format at this stage:
  - **Option A**: Output R script only (for review/modification)
  - **Option B**: Execute and output tables directly
  - **Option C**: Both script and initial table results
- [ ] Consider user workflow preferences
- [ ] Ensure output is "production-ready" regardless of format chosen

**Phase 4 Output**: Validated, executable R script that reliably generates crosstabs

### Phase 5: Statistical Enhancement & Polish

#### 5.1 Template Generation System
- [ ] **Library Decision**: Evaluate Excel.js vs Sheet.js (Excel.js preferred for formatting)
- [ ] **Template Creation**: Deterministic process that takes:
  - Banner plan (determines columns/cuts)
  - Survey JSON (determines rows/questions)
  - Outputs Excel template with proper structure
- [ ] **Design Philosophy**: "Copy Joe's stat testing look with Antares simplicity"
- [ ] **Template Features**:
  - Proper spacing for stat testing results
  - Column structure based on banner cuts
  - Row structure based on survey questions

#### 5.2 CSV to Template Mapping
- [ ] Parse R script output CSVs
- [ ] Map data to correct cells in template
- [ ] Preserve space for statistical testing columns
- [ ] Handle dynamic column counts based on cuts
- [ ] Ensure proper alignment of data to template structure

#### 5.3 Statistical Testing Implementation
- [ ] **Default**: 90% confidence level (configurable in UI)
- [ ] **Testing Types**:
  - Column comparisons
  - Significance indicators
  - Confidence intervals where appropriate
- [ ] **Integration**: Results populate reserved template spaces
- [ ] **Banner-Aware**: Testing adapts based on cut types

#### 5.4 Excel Formatting & Enhancement
- [ ] **Using Excel.js**:
  - Merge cells where needed
  - Apply color coding for different column types
  - Add borders and professional formatting
  - Nothing complex - just enough for readability
- [ ] **Optional Enhancements**:
  - Custom branding
  - Conditional formatting
  - Navigation aids

#### 5.5 Output Validation
- [ ] **Survey Agent Re-check**: Verify all expected tables are present
- [ ] **R Script Agent Review**: Confirm execution completeness
- [ ] **Quality Checks** (automated where possible):
  - Table completeness
  - Data consistency
  - Formula validation
  - Format compliance

### Phase 6: Quality Assurance & Testing Strategy

#### 6.1 Continuous Quality Throughout Pipeline
- [ ] Add validation checkpoints at each phase
- [ ] Implement early error detection
- [ ] Create feedback loops between phases
- [ ] Log all decisions for audit trail

#### 6.2 Project-by-Project Testing Protocol
- [ ] **Test Project 1**: 
  - Run end-to-end
  - Compare outputs to Joe's reference crosstabs
  - Fix all edge cases
  - Achieve 100% accuracy
- [ ] **Test Project 2**:
  - Run end-to-end
  - Fix new edge cases
  - Verify Project 1 still works
- [ ] **Continue through all 10 projects**:
  - Each project may introduce new edge cases
  - Always regression test previous projects
  - Document all fixes and patterns learned

#### 6.3 Demo Readiness Criteria
- [ ] **MVP Demo** (after Project 1 validated):
  - Show complete end-to-end workflow
  - Demonstrate one fully working project
  - Note remaining projects in progress
- [ ] **Production Ready** (after all 10 validated):
  - All projects work with 100% reliability
  - Edge cases documented and handled
  - Performance optimized

#### 6.4 Human Validation Points
- [ ] Manual comparison of percentages/counts
- [ ] Review of statistical test results
- [ ] Verification of table completeness
- [ ] Format and readability check

### Phase 7: Infrastructure & Deployment Prep

#### 7.1 Data Storage Refactoring
- [ ] Review current local file storage approach
- [ ] Design abstraction layer for easy production swap
- [ ] Consider path management for different environments
- [ ] Maintain local development simplicity

#### 7.2 Production Considerations
- [ ] Security and input validation (implement as we go)
- [ ] Guardrails and error boundaries
- [ ] Performance optimization
- [ ] Concurrent user support
- [ ] Cost optimization for API calls

#### 7.3 Final Output Delivery
- [ ] Excel download via UI
- [ ] Shareable links for results
- [ ] Version tracking for analyses
- [ ] Audit logs for compliance

---

## Additional Considerations & Potential Gaps

### Performance & Scalability
- [ ] **Caching Strategy**: Cache parsed documents, agent responses where appropriate
- [ ] **Batch Processing**: Handle multiple projects in queue
- [ ] **Parallel Execution**: Run independent phases simultaneously
- [ ] **Token Optimization**: Minimize API calls through smart context management

### Error Recovery & Resilience
- [ ] **Partial Failure Handling**: Continue processing what's possible
- [ ] **Retry Logic**: Smart retries for transient failures
- [ ] **Fallback Strategies**: Alternative approaches when primary fails
- [ ] **Error Reporting**: Clear, actionable error messages

### User Experience Enhancements
- [ ] **Progress Indicators**: Real-time status for long-running processes
- [ ] **Preview Mode**: See partial results before completion
- [ ] **Edit Capability**: Manual override of agent decisions
- [ ] **History Tracking**: View and restore previous runs

### Integration Points
- [ ] **API Design**: RESTful endpoints for external integration
- [ ] **Webhook Support**: Notify external systems on completion
- [ ] **Export Options**: Multiple format support beyond Excel
- [ ] **Import Templates**: Support for custom banner/survey formats

### Monitoring & Observability
- [ ] **Comprehensive Logging**: Track all agent decisions and tool executions
- [ ] **Performance Metrics**: Processing time, accuracy rates, API usage
- [ ] **Alert System**: Notify on failures or anomalies
- [ ] **Debug Mode**: Verbose output for troubleshooting

### Documentation & Training
- [ ] **User Guide**: Step-by-step usage instructions
- [ ] **API Documentation**: For developers/integrators
- [ ] **Best Practices**: Guidelines for optimal results
- [ ] **Troubleshooting Guide**: Common issues and solutions

---

## Implementation Priority Order

1. **Phase 0**: Data preparation (immediate - needed for all testing)
2. **Phase 1-2**: File processing & Survey Agent (foundation for everything else)
3. **Phase 3-4**: Validation & R Script Agent (core functionality)
4. **Phase 5**: Polish & stats (makes output production-ready)
5. **Phase 6**: Testing protocol (throughout, but formalized at end)
6. **Phase 7**: Infrastructure (as needed for production)

**Key Milestone**: After first project validates 100%, demo to stakeholders

---

*Last Updated: August 14, 2025*