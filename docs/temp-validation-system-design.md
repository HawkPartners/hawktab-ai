# Validation and Grading System Design (Temporary Doc)

## Overview & Conceptual Framework

### What This System Will Enable

**For Immediate Development:**
- **Manual Validation Workflows**: Review each agent's output with side-by-side comparisons (original input vs agent extraction)
- **Ground Truth Building**: Capture human corrections and feedback to build training datasets
- **Performance Tracking**: Quantify agent accuracy, confidence calibration, and error patterns over time
- **Quality Assurance**: Ensure outputs meet standards before downstream processing (R script generation)

**For Long-term Improvement:**
- **Automated Grading**: Use validated examples to automatically score new outputs without human review
- **Prompt Optimization**: A/B test different prompt versions using objective accuracy metrics
- **Error Pattern Recognition**: Identify systematic issues (e.g., "always misses HCP vs NP/PA distinctions")
- **Confidence Recalibration**: Adjust agent confidence scores based on actual human acceptance rates

### How The System Works Conceptually

```
Agent Processing → Validation Queue → Human Review → Tracking Database
     ↓                    ↓              ↓              ↓
Original Output    Structured UI    Accept/Reject   Performance Metrics
    ↓                    ↓         Edit/Feedback         ↓
Stored JSON       Side-by-side      Corrections    Automated Grading
                  Comparison         Captured       (Future Phase)
```

**Core Philosophy:**
1. **Agent-First Design**: Leverage OpenAI Agents SDK native validation patterns (`needsApproval`, state serialization)
2. **Modular Validation**: Each agent (Banner, Crosstab) has its own validation workflow
3. **Structured Output Folder**: All validation data stored in session-based folder structure
4. **Type-Safe Implementation**: Full TypeScript with Zod schemas for validation records

### Output Folder Structure
```
temp-outputs/
└── output-2025-08-07T13-17-41-662Z/
    ├── banner-bannerPlan-verbose-[timestamp].json
    ├── banner-bannerPlan-agent-[timestamp].json
    ├── dataMap-verbose-[timestamp].json
    ├── dataMap-agent-[timestamp].json
    ├── crosstab-output-[timestamp].json
    └── validations-[timestamp]/
        ├── banner-validation-[sessionId].json
        ├── crosstab-validation-[sessionId].json
        └── validation-summary.json
```

## Phased Implementation Plan

### Phase 1: Foundation & Data Structures (Week 1-2)

#### 1.1 Core Validation Schema Definition
```typescript
// Define comprehensive Zod schemas for validation records
interface ValidationRecord {
  sessionId: string;
  agentType: 'banner' | 'crosstab';
  timestamp: string;
  originalInput: BannerImages | CrosstabContext;
  agentOutput: any;
  humanDecision: 'accept' | 'reject' | 'edit';
  corrections?: any;
  feedback?: string;
  validationTime: number;
  confidence: number;
}
```

#### 1.2 Storage System Implementation
- **ValidationStorage class**: Handle reading/writing validation records to structured folders
- **Session-based organization**: Extend existing output folder structure with `/validations-[timestamp]/`
- **JSON serialization**: Type-safe validation record persistence
- **Concurrent access handling**: Multiple validations for same session

#### 1.3 API Route Extensions
- **Extend existing `/api/process-crosstab`**: Add validation links to response
- **New `/api/validate/banner/[sessionId]`**: Serve validation UI for banner outputs
- **New `/api/validate/crosstab/[sessionId]`**: Serve validation UI for crosstab outputs
- **Validation status tracking**: Mark sessions as validated/pending

### Phase 2: Banner Agent Validation UI (Week 2-3)

#### 2.1 BannerAgent Validation Interface
**UI Components:**
- **Multi-Image Viewer**: Display original banner plan images with zoom/pan controls
- **JSON Structure Editor**: Interactive editing of extracted banner cuts and metadata
- **Group Validation**: Visual highlighting of identified groups with accept/reject per group
- **Side-by-side Layout**: Original images left, extracted JSON structure right

**Validation Workflow:**
1. Load session data (images + agent output)
2. Present structured comparison view
3. Enable group-by-group or wholesale accept/reject/edit
4. Capture corrections with reasoning
5. Store validation record in session folder

#### 2.2 Integration with OpenAI Agents SDK
- **Leverage `needsApproval` pattern**: Pause BannerAgent execution for human validation
- **State serialization**: Store intermediate states for resume capability
- **Tool approval workflow**: Use SDK's built-in validation hooks

#### 2.3 Banner-Specific Metrics
- **Group Separation Accuracy**: Did agent correctly identify logical groups?
- **Column Extraction Precision**: How many columns were missed/incorrectly parsed?
- **Statistical Letter Assignment**: Accuracy of A, B, C... assignments

### Phase 3: Crosstab Agent Validation UI (Week 3-4)

#### 3.1 CrosstabAgent Validation Interface
**UI Components:**
- **Context Display**: Show data map variables (192) and banner groups (6) as reference
- **Mapping Validation Grid**: Column-by-column review of agent mappings
- **Confidence Visualization**: Color-coded confidence scores with sorting/filtering
- **Scratchpad Review**: Display agent reasoning for each mapping decision
- **R Syntax Preview**: Show generated R code with syntax highlighting

**Advanced Features:**
- **Variable Search**: Quick lookup in data map context
- **Bulk Operations**: Accept/reject multiple similar mappings
- **Confidence Thresholds**: Auto-flag low-confidence mappings for review
- **Comparison Mode**: Side-by-side original vs corrected mappings

#### 3.2 Crosstab-Specific Metrics
- **Variable Mapping Accuracy**: Correct data map variable identification
- **Confidence Calibration**: Correlation between agent confidence and human acceptance
- **Expression Complexity Handling**: Performance on simple vs complex filter expressions
- **Reasoning Quality**: Assessment of scratchpad logic quality

### Phase 4: Performance Analytics Dashboard (Week 4-5)

#### 4.1 Metrics Computation Engine
- **Real-time Analytics**: Compute metrics from validation records on-demand
- **Historical Trending**: Track accuracy improvements over time
- **Error Pattern Analysis**: Most common correction types by category
- **Confidence Distribution**: Analysis of agent confidence vs human acceptance

#### 4.2 Dashboard Components
- **Overall Accuracy Metrics**: Banner vs Crosstab agent performance comparison
- **Validation Throughput**: Time metrics for human review process
- **Error Category Breakdown**: Common failure modes with examples
- **Confidence Calibration Plots**: Visual representation of agent confidence reliability

#### 4.3 Export and Reporting
- **CSV Export**: Validation data for external analysis
- **Summary Reports**: Weekly/monthly accuracy reports
- **Trend Analysis**: Performance changes over time
- **Correction Patterns**: Most frequent human interventions

### Phase 5: Automated Grading Foundation (Week 5-6)

#### 5.1 Ground Truth Dataset Construction
- **Validation Record Mining**: Extract patterns from human corrections
- **Test Case Generation**: Create standardized test scenarios
- **Known-Good Examples**: Build reference dataset for automated comparison
- **Error Pattern Recognition**: Classify common mistake categories

#### 5.2 Automated Scoring Implementation
- **Similarity Matching**: Compare new outputs against validated examples
- **Pattern-Based Grading**: Recognize previously corrected error types
- **Confidence Adjustment**: Recalibrate agent confidence based on validation history
- **Quality Score Generation**: Automated quality assessment without human review

#### 5.3 Integration Points
- **Pre-validation Scoring**: Flag likely errors before human review
- **Validation Prioritization**: Review low-scoring outputs first
- **Continuous Learning**: Update grading models with new validation data
- **A/B Testing Support**: Compare prompt versions using automated metrics

### Phase 6: Production Readiness (Week 6+)

#### 6.1 Performance Optimization
- **Lazy Loading**: Load validation data on-demand for large sessions
- **Caching Strategy**: Cache computed metrics for faster dashboard loading
- **Batch Processing**: Handle multiple validation sessions efficiently
- **Response Time Optimization**: Minimize UI latency for real-time validation

#### 6.2 Advanced Workflow Features
- **Validation Assignment**: Route sessions to specific reviewers
- **Review Status Tracking**: In-progress vs completed validation states
- **Collaborative Validation**: Multiple reviewers for complex cases
- **Approval Hierarchies**: Senior review for critical corrections

#### 6.3 Cloud Migration Preparation
- **Database Schema Design**: Plan transition from JSON files to structured database
- **API Standardization**: Ensure validation endpoints work with cloud storage
- **State Management**: Prepare for distributed validation workflows
- **Security Considerations**: Validate sensitive data handling patterns

## Implementation Notes

### Technical Considerations
- **OpenAI SDK Integration**: Maximize use of native validation patterns
- **Type Safety**: All validation interfaces backed by Zod schemas
- **Error Handling**: Graceful degradation for incomplete validation sessions
- **Performance**: Optimize for datasets with 192 variables and 19+ columns

### Quality Assurance
- **Linting**: Maintain ESLint compliance throughout validation codebase
- **Type Checking**: Zero TypeScript errors in validation system
- **Testing Strategy**: Unit tests for validation logic, integration tests for UI workflows
- **Documentation**: Maintain clear documentation for validation workflows

### Future Extensibility
- **Plugin Architecture**: Easy addition of new agent types for validation
- **Customizable Metrics**: User-defined performance indicators
- **Integration APIs**: Webhook support for external validation tools
- **Machine Learning Ready**: Data formats compatible with ML training pipelines