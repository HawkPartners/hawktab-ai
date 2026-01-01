# HawkTab AI: Agent Flow Architecture

This document describes how the system processes survey data into crosstabs, both the current implementation and the proposed improvements.

---

## Current System Flow

### User Inputs (3 files)

| Input | Format | Purpose |
|-------|--------|---------|
| **Banner Plan** | PDF/DOC/DOCX | Defines what columns/cuts to include in crosstabs |
| **Data Map** | CSV | Variable definitions, labels, allowed values |
| **Data File** | SPSS (.sav) | Actual respondent data |

### Processing Pipeline

```mermaid
flowchart TD
    subgraph inputs["User Uploads"]
        BP[Banner Plan<br/>PDF/DOC]
        DM[Data Map<br/>CSV]
        DF[Data File<br/>SPSS]
    end

    subgraph phase1["Phase 1: Document Processing"]
        BP --> PDF[Convert to PDF]
        PDF --> IMG[Convert to Images<br/>300 DPI PNG]
        DM --> PARSE[State Machine Parser]
    end

    subgraph phase2["Phase 2: Banner Extraction"]
        IMG --> BPA[BannerPlanAgent]
        BPA --> |"Structured JSON"| BJSON[Banner JSON<br/>Groups, Columns, Cuts]
    end

    subgraph phase3["Phase 3: Variable Matching"]
        BJSON --> CTA[CrosstabAgent]
        PARSE --> |"Variables JSON"| CTA
        CTA --> |"Validated Cuts"| VCUTS[Validated Cuts<br/>with R Expressions]
    end

    subgraph phase4["Phase 4: R Generation & Execution"]
        VCUTS --> RSA[R Script Generator]
        DF --> RSA
        RSA --> RSCRIPT[Generated R Script]
        RSCRIPT --> EXEC[R Execution]
        EXEC --> OUTPUT[CSV/Excel Output]
    end

    style BPA fill:#e1f5fe
    style CTA fill:#e1f5fe
    style RSA fill:#e1f5fe
```

### Agent Descriptions

#### BannerPlanAgent
- **Input**: Images of banner plan document
- **Task**: Extract banner structure from visual document
- **Output**: Structured JSON with groups, columns, cuts, stat letters
- **Model**: GPT-4o (vision-capable)

#### CrosstabAgent
- **Input**: Banner JSON + Data Map JSON
- **Task**: Match banner expressions to actual variables, generate R syntax
- **Output**: Validated cuts with R expressions and confidence scores
- **Model**: o4-mini (reasoning)
- **Validation**: Checks if variables exist in data map (syntax validation)

#### R Script Generator
- **Input**: Validated cuts + SPSS data file path
- **Task**: Generate complete R script for crosstab calculations
- **Output**: Executable R script with statistical tests

### Current Limitations

| Issue | Root Cause |
|-------|------------|
| **AND/OR logic errors** | Agent interprets banner literally without understanding skip logic |
| **Zero-count cuts** | No validation that cuts will produce results before R execution |
| **Overconfident validation** | Agent validates syntax but not semantic correctness |
| **Fragile data map parsing** | CSV state machine infers relationships, doesn't know skip logic |

---

## Proposed System Flow

### User Inputs (5 options, 2 paths)

| Input | Format | Status | Purpose |
|-------|--------|--------|---------|
| **Decipher Survey Link** | URL | *New, Preferred* | Direct API access to survey structure, data, and skip logic |
| **Banner Plan** | PDF/DOC/DOCX | Current | Defines columns/cuts (or auto-generated from survey) |
| **Survey Document** | PDF/DOC | *New, Fallback* | Questionnaire for understanding skip logic when no API access |
| **Data Map** | CSV | *Deprecated* | Replaced by Decipher API datamap |
| **Data File** | SPSS (.sav) | *Deprecated* | Replaced by Decipher API data export |

### Processing Pipeline (Proposed)

```mermaid
flowchart TD
    subgraph inputs["User Inputs"]
        LINK[Decipher Link<br/>*Preferred*]
        BP[Banner Plan<br/>PDF/DOC]
        SURVEY[Survey Document<br/>*Fallback*]
        DM[Data Map CSV<br/>*Deprecated*]
        DF[Data File SPSS<br/>*Deprecated*]
    end

    subgraph api["Decipher API Integration"]
        LINK --> DAPI[Decipher API]
        DAPI --> |"GET /datamap"| DMJSON[Datamap JSON]
        DAPI --> |"GET /files/survey.xml"| SXML[Skip Logic XML]
        DAPI --> |"GET /data"| DJSON[Data JSON]
    end

    subgraph fallback["Manual Fallback Path"]
        DM -.-> CSVPARSE[CSV Parser]
        SURVEY -.-> SURVEYPDF[Convert to PDF]
        DF -.-> SPSS[SPSS File]
    end

    subgraph phase1["Phase 1: Banner Extraction"]
        BP --> BPPDF[Convert to PDF]
        BPPDF --> BPIMG[Convert to Images]
        BPIMG --> BEA[BannerExtractAgent]
        BEA --> |"Structured JSON"| RAWBANNER[Raw Banner JSON]
    end

    subgraph phase2["Phase 2: Banner Validation ⭐ NEW"]
        RAWBANNER --> BVA[BannerValidateAgent]
        SXML --> BVA
        SURVEYPDF -.-> BVA
        BVA --> |"Semantic Check"| VALIDATED[Validated Banner JSON<br/>+ Flags + Fixes]
    end

    subgraph phase2b["Phase 2b: Banner Expansion (Optional, TBD)"]
        VALIDATED -.-> BXA[BannerExpandAgent]
        BXA -.-> |"Additional Cuts"| EXPANDED[Expanded Banner JSON]
    end

    subgraph phase3["Phase 3: Variable Matching"]
        VALIDATED --> CTA[CrosstabAgent]
        EXPANDED -.-> CTA
        DMJSON --> CTA
        CSVPARSE -.-> CTA
        CTA --> |"R Expressions"| VCUTS[Validated Cuts]
    end

    subgraph phase4["Phase 4: R Generation & Execution"]
        VCUTS --> RSG[R Script Generator]
        DJSON --> RSG
        SPSS -.-> RSG
        RSG --> RSCRIPT[R Script]
        RSCRIPT --> EXEC[R Execution]
        EXEC --> OUTPUT[CSV/Excel Output]
    end

    style BEA fill:#e1f5fe
    style BVA fill:#fff9c4
    style BXA fill:#f5f5f5,stroke-dasharray: 5 5
    style CTA fill:#e1f5fe
    style RSG fill:#e1f5fe
    style LINK fill:#c8e6c9
    style DAPI fill:#c8e6c9
    style DM fill:#f5f5f5,stroke-dasharray: 5 5
    style DF fill:#f5f5f5,stroke-dasharray: 5 5
    style SURVEY fill:#fff3e0,stroke-dasharray: 5 5
    style CSVPARSE fill:#f5f5f5,stroke-dasharray: 5 5
    style SPSS fill:#f5f5f5,stroke-dasharray: 5 5
    style SURVEYPDF fill:#fff3e0,stroke-dasharray: 5 5
```

### Agent Descriptions (Proposed)

#### BannerExtractAgent (Renamed from BannerPlanAgent)
- **Input**: Images of banner plan document
- **Task**: Extract banner structure from visual document
- **Output**: Raw structured JSON with groups, columns, cuts
- **Model**: GPT-4o (vision-capable)
- **Change from current**: Name change only, same functionality

#### BannerValidateAgent ⭐ NEW
- **Input**: Raw Banner JSON + Skip Logic (from survey.xml or survey document)
- **Task**: Validate that banner cuts are semantically/logically possible
- **Output**: Validated Banner JSON with flags, suggested fixes, confidence adjustments
- **Model**: o4-mini (reasoning)
- **Key validation**:
  - Can `S2=1 AND S2a=1` ever be true? (Check skip logic)
  - Are there impossible combinations?
  - Suggest fixes: "Did you mean OR instead of AND?"
  - Add context notes for downstream agents

#### BannerExpandAgent (Optional, TBD)
- **Input**: Validated Banner JSON + Survey Context
- **Task**: Suggest additional useful cuts based on survey content
- **Output**: Expanded Banner JSON with suggested additional columns
- **Model**: o4-mini (reasoning)
- **Status**: Not in initial scope, architecture supports adding later
- **Use case**: "What other cuts would be useful for this survey?"

#### CrosstabAgent (Unchanged)
- **Input**: Validated Banner JSON + Data Map
- **Task**: Match banner expressions to actual variables, generate R syntax
- **Output**: Validated cuts with R expressions
- **Model**: o4-mini (reasoning)
- **Change from current**: Receives pre-validated input, less validation burden

#### R Script Generator (Unchanged)
- **Input**: Validated cuts + Data (SPSS or JSON)
- **Task**: Generate complete R script
- **Output**: Executable R script

---

## Key Differences: Current vs Proposed

| Aspect | Current | Proposed |
|--------|---------|----------|
| **Data source** | Manual file uploads | Decipher API (preferred) + manual fallback |
| **Skip logic** | Inferred by AI | Explicit from survey.xml or survey document |
| **Banner validation** | Syntax only (does variable exist?) | Semantic (is this logically possible?) |
| **Validation timing** | During variable matching | Before variable matching |
| **Error detection** | After R execution (zero-count cuts) | Before R execution |
| **Agent count** | 2 (Banner + Crosstab) | 3-4 (Extract + Validate + [Expand] + Crosstab) |

---

## Validation Flow Detail

```mermaid
flowchart LR
    subgraph current["Current: Validation During Matching"]
        B1[Banner JSON] --> C1[CrosstabAgent]
        C1 --> |"Does S2 exist?"| V1{Syntax Valid?}
        V1 --> |Yes| R1[R Expression]
        V1 --> |No| E1[Error]
    end

    subgraph proposed["Proposed: Validation Before Matching"]
        B2[Banner JSON] --> BV[BannerValidateAgent]
        BV --> |"Can S2=1 AND S2a=1 be true?"| V2{Semantically Valid?}
        V2 --> |Yes| C2[CrosstabAgent]
        V2 --> |No, suggest fix| F2[Flag + Suggest OR]
        F2 --> C2
        C2 --> R2[R Expression]
    end

    style BV fill:#fff9c4
    style V2 fill:#fff9c4
```

---

## Implementation Priority

1. **Phase 2**: Infrastructure (auth, database, deployment) - enables iteration
2. **Phase 3**: Decipher API integration - provides reliable data source
3. **Phase 3b**: BannerValidateAgent - catches semantic errors early
4. **Phase 4**: Reliability improvements (confidence calibration, diagnostics)
5. **Future**: BannerExpandAgent - consultant-style suggestions

---

*Document created: January 1, 2026*
*Status: Architectural proposal for discussion*
