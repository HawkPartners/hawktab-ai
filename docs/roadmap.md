# CrosstabAgent Implementation Roadmap

> **Architecture Reference**: See `/docs/openai-agents-architecture.md` for detailed technical specifications, schemas, and implementation patterns.

## Overview

This roadmap implements a focused cross-reference validation system using OpenAI Agents SDK. We're building **one agent, multiple calls** architecture that processes banner groups individually for better focus and debugging.

**Scope**: Cross-reference validation only - from banner plan + data map → validated mappings with confidence scores. Post-orchestrator processing (R script generation, execution) is explicitly out of scope.

---

## Phase 1: Foundation & Dependencies ⚡

### 1.1 Install Critical Dependencies
- [x] **Install exact Zod version**: `npm install zod@3.25.67`
  - ⚠️ **CRITICAL**: SDK does not work with zod@3.25.68+
  - Reference: Architecture doc section "Installation & Setup"
- [x] **Install OpenAI Agents SDK**: `npm install @openai/agents`
- [x] **Web search OpenAI Agents JS SDK** for latest compatibility updates if needed
- [x] **Verify package.json** contains exact versions:
  ```json
  {
    "zod": "3.25.67",
    "@openai/agents": "latest"
  }
  ```

### 1.2 Environment Configuration
- [x] **Create/update `.env.local`** with development variables:
  ```env
  # Required
  OPENAI_API_KEY=your_api_key_here
  
  # Model Configuration  
  REASONING_MODEL=o4-mini-2025-04-16
  BASE_MODEL=gpt-4.1-2025-04-14
  REASONING_MODEL_TOKENS=100000
  BASE_MODEL_TOKENS=32768
  
  # Environment
  NODE_ENV=development
  
  # Tracing
  OPENAI_AGENTS_DISABLE_TRACING=false
  
  # Processing Limits
  MAX_DATA_MAP_VARIABLES=1000
  MAX_BANNER_COLUMNS=100
  ```

- [x] **Create `.env.production`** with production variables:
  ```env
  # Same structure but production values
  NODE_ENV=production
  REASONING_MODEL=o4-mini-2025-04-16
  BASE_MODEL=gpt-4.1-2025-04-14
  REASONING_MODEL_TOKENS=100000
  BASE_MODEL_TOKENS=32768
  ```

### 1.3 Basic Validation
- [x] **Run type checking**: `npx tsc --noEmit`
- [x] **Run linting**: `npm run lint`
- [x] **Verify environment loading** in development mode

---

## Phase 2: Project Structure & Core Setup 🏗️

### 2.1 Directory Structure
Create directory structure per architecture doc "Simplified Directory Structure":

- [x] **Create `src/agents/` directory**
- [x] **Create `src/schemas/` directory** 
- [x] **Create `src/lib/` directory**
- [x] **Create `src/guardrails/` directory**
- [x] **Update `src/api/` for single endpoint approach**

### 2.2 Core Configuration Files
- [x] **Create `src/lib/types.ts`** - TypeScript definitions
- [x] **Create `src/lib/tracing.ts`** - Tracing configuration
- [x] **Create `src/agents/index.ts`** - Agent exports
- [x] **Update `tsconfig.json`** with proper path mappings if needed

### 2.3 Environment Integration
- [x] **Create environment helper** in `src/lib/env.ts`:
  ```typescript
  export const getModel = () => 
    process.env.NODE_ENV === 'production' 
      ? process.env.BASE_MODEL || 'gpt-4o-mini'
      : process.env.REASONING_MODEL || 'o1-preview';
  ```

### 2.4 Validation
- [x] **Run type checking**: `npx tsc --noEmit`
- [x] **Run linting**: `npm run lint`
- [x] **Verify directory structure matches architecture doc**

---

## Phase 3: Schema Definitions (Zod-First) 📝

> **Critical**: All schemas must be defined before any implementation. Reference architecture doc "Data Schemas" section.

### 3.1 Data Map Schema
- [x] **Create `src/schemas/dataMapSchema.ts`**:
  ```typescript
  import { z } from 'zod';
  
  // Simplified for agent processing
  export const DataMapSchema = z.array(z.object({
    Column: z.string(),        // "S2", "S2a", "A3r1"
    Description: z.string(),   // Question text
    Answer_Options: z.string() // "1=Cardiologist,2=Internal Medicine"
  }));
  
  export type DataMapType = z.infer<typeof DataMapSchema>;
  ```

### 3.2 Banner Plan Schema  
- [x] **Create `src/schemas/bannerPlanSchema.ts`**:
  ```typescript
  import { z } from 'zod';
  
  // Simplified input schema
  export const BannerPlanInputSchema = z.object({
    bannerCuts: z.array(z.object({
      groupName: z.string(),
      columns: z.array(z.object({
        name: z.string(),     // "Cards", "PCPs", "HCP"
        original: z.string()  // "S2=1 AND S2a=1", "IF HCP"
      }))
    }))
  });
  
  export type BannerPlanInputType = z.infer<typeof BannerPlanInputSchema>;
  ```

### 3.3 Validation Result Schema
- [x] **Create `src/schemas/validationSchema.ts`**:
  ```typescript
  import { z } from 'zod';
  
  // Agent output schema - keep simple to avoid SDK issues
  export const ValidationResultSchema = z.object({
    bannerCuts: z.array(z.object({
      groupName: z.string(),
      columns: z.array(z.object({
        name: z.string(),
        adjusted: z.string().describe('R syntax expression'),
        confidence: z.number().min(0).max(1),
        reason: z.string()
      }))
    }))
  });
  
  export type ValidationResultType = z.infer<typeof ValidationResultSchema>;
  ```

### 3.4 Context Builder Types
- [x] **Create interfaces in `src/lib/contextBuilder.ts`** per architecture doc
- [x] **Reference architecture doc "Context Builder Implementation" section**

### 3.5 Validation
- [x] **Test schema compilation**: Import all schemas in a test file
- [x] **Run type checking**: `npx tsc --noEmit`
- [x] **Run linting**: `npm run lint`
- [x] **Verify schemas follow SDK constraints** (no unions with discriminators, <5 nesting levels)

---

## Phase 4: File Upload & Storage Integration 📁

### 4.1 Update Upload Components
- [x] **Review existing `src/components/FileUpload.tsx`**
- [x] **Update to support new processing workflow**
- [x] **Add validation for required file types** (.csv/.xlsx for data map, .pdf/.doc for banner)
- [x] **Reference existing upload pattern but prepare for single endpoint**

### 4.2 Storage Integration
- [x] **Review existing file storage approach**
- [x] **Prepare for dual output file generation**:
  ```
  temp/
  ├── banner-plan-verbose.json    # Full metadata
  ├── banner-plan-agent.json      # Simplified for agent
  ├── data-map-verbose.json       # Full structure  
  └── data-map-agent.json         # Only essential fields
  ```

### 4.3 File Validation & Guardrails
- [x] **Create `src/guardrails/inputValidation.ts`**
- [x] **Implement file type/size validation**
- [x] **Add content safety checks as needed**
- [x] **GUARDRAILS**: Implement token limit checking per environment config
- [x] **GUARDRAILS**: Add data map size validation against MAX_DATA_MAP_VARIABLES
- [x] **Reference**: Architecture doc "Guardrails-First Development"

### 4.4 Validation
- [x] **Test file upload still works**
- [x] **Run type checking**: `npx tsc --noEmit`
- [x] **Run linting**: `npm run lint`

**🧪 TESTING CHECKPOINT COMPLETED**: File upload tested successfully with real files - guardrails working, API endpoint responding correctly, tracing active!

---

## Phase 5: Data Processing & Dual Output Strategy ✅ **COMPLETED**

### 5.1 Context Builder Implementation
- [x] **Implement `src/lib/contextBuilder.ts`** per architecture doc ✅
- [x] **Enhanced dual output generation** with sophisticated processing ✅
- [x] **Support for both mock and real processing results** ✅

### 5.2 Data Map Processing (DataMapProcessor.ts)
- [x] **Consolidated state machine parsing** (192 variables successfully parsed) ✅
- [x] **Parent inference with regex patterns** (130 parent relationships detected) ✅  
- [x] **Context enrichment with 3-pass search** (130 variables context enriched) ✅
- [x] **Real SPSS validation** (192/192 variable match with .sav files) ✅
- [x] **Development outputs** in temp-outputs/ directory ✅

### 5.3 Banner Processing (BannerProcessor.ts) 
- [x] **Document conversion** (Word/DOC → PDF) ✅
- [x] **PDF to high-resolution images** (pdf2pic + sharp optimization) ✅
- [x] **LLM extraction** with OpenAI Vision API ✅
- [x] **Structured output** with banner cuts and notes ✅
- [x] **Dual output generation** (verbose + agent formats) ✅
- [x] **Development outputs** in temp-outputs/ directory ✅

### 5.4 Integration & API Updates
- [x] **API route updated** with real banner processing ✅
- [x] **Replace mockBannerData** with BannerProcessor ✅
- [x] **Enhanced contextBuilder.ts** integration ✅
- [x] **Comprehensive error handling** and fallbacks ✅

### 5.5 Final Validation
- [x] **Test dual output generation with real data files** ✅
- [x] **Verify simplified JSON structure matches schemas** ✅
- [x] **Run type checking**: `npx tsc --noEmit` ✅
- [x] **Run linting**: `npm run lint` ✅
- [x] **End-to-end testing** with file uploads ✅

**🎉 PHASE 5 COMPLETED**: Sophisticated data processing pipeline ready for CrossTab agent!

**Final Results:**
- **Data Map Processing**: 192 variables, 130 parent relationships, 192/192 SPSS matches
- **Banner Processing**: 19 columns, 6 banner cuts successfully extracted
- **Dual Outputs**: Both verbose and agent formats generated in temp-outputs/
- **Clean Architecture**: TypeScript + ESLint compliant, comprehensive error handling

---

## Phase 6: Core Agent Implementation ✅ **COMPLETED**

> **Reference**: Architecture doc "Working Agent Implementation" and "Group-Focused Processing Strategy"

### 6.1 Scratchpad Tool
- [x] **Create scratchpad tool** in `src/agents/tools/scratchpad.ts` ✅
- [x] **Proper SDK pattern** using `tool()` function from '@openai/agents' ✅
- [x] **Zod parameter validation** with action and content fields ✅
- [x] **Reasoning transparency** for complex validation tasks ✅

### 6.2 CrosstabAgent Implementation  
- [x] **Create `src/agents/CrosstabAgent.ts`** ✅
- [x] **Proper OpenAI Agents SDK integration** with Agent class ✅
- [x] **Correct outputType usage** (not outputSchema) ✅
- [x] **Context injection strategy** with enhanced instructions ✅
- [x] **Group-by-group processing** with individual agent instances ✅
- [x] **Comprehensive error handling** with fallback responses ✅

### 6.3 System Prompt Development
- [x] **Enhanced system prompt** with comprehensive validation patterns ✅
- [x] **Variable matching strategies** (direct, conceptual, incomplete) ✅
- [x] **Confidence rating scale** (0.95-1.0 direct, 0.85-0.94 complex, etc.) ✅
- [x] **R syntax conversion rules** (equality, multiple values, logic operators) ✅
- [x] **Conceptual matching strategy** for unclear expressions ✅
- [x] **Quality standards** with detailed reasoning requirements ✅
- [x] **TRACING**: Scratchpad usage instructions for transparency ✅

### 6.4 Group Processing Logic
- [x] **Group-by-group processing** implemented in `processAllGroups()` ✅
- [x] **Individual group processing** with `processGroup()` function ✅
- [x] **Result combination logic** with `combineValidationResults()` ✅
- [x] **Parallel processing option** for future optimization ✅
- [x] **Sequential processing** as primary strategy ✅

### 6.5 Validation & Integration
- [x] **Agent creation tested** with proper SDK patterns ✅
- [x] **OutputType property verified** (not outputSchema) ✅
- [x] **API integration completed** in `/src/app/api/process-crosstab/route.ts` ✅
- [x] **Comprehensive error handling** and metrics calculation ✅
- [x] **TRACING**: Agent execution logging implemented ✅
- [x] **Context preparation** with `prepareAgentContext()` function ✅
- [x] **Result validation** with confidence score calculations ✅

**🎉 PHASE 6 COMPLETED**: CrossTab Agent fully operational and integrated!

---

## Phase 7: API Integration & Group Processing ✅ **COMPLETED**

### 7.1 Single Endpoint Implementation
- [x] **Create `src/app/api/process-crosstab/route.ts`** ✅
- [x] **Complete workflow integration** (Phase 5 + Phase 6) ✅
- [x] **Proper Next.js API route structure** with POST handler ✅
- [x] **Environment validation** and configuration ✅
- [x] **File upload processing** with guardrails integration ✅

### 7.2 Integration with Upload Flow
- [x] **Single endpoint handles complete workflow** ✅
- [x] **File validation with guardrails** before processing ✅
- [x] **Session management** with unique session IDs ✅
- [x] **Comprehensive error handling** at all stages ✅

### 7.3 Group-by-Group Processing
- [x] **Complete processing loop** implemented ✅
- [x] **Individual group error handling** with fallbacks ✅
- [x] **Result combination logic** with validation metrics ✅
- [x] **TRACING**: Execution logging for each processing stage ✅
- [x] **Agent context preparation** from dual outputs ✅

### 7.4 Response Formatting
- [x] **Comprehensive response structure** with processing details ✅
- [x] **Success/failure indicators** for each processing stage ✅
- [x] **Detailed metrics** (confidence scores, validation counts) ✅
- [x] **Development vs. production messaging** ✅
- [x] **Next steps guidance** based on processing results ✅

### 7.5 Validation
- [x] **API endpoint fully functional** ✅
- [x] **Integration points verified** between all phases ✅
- [x] **TRACING**: Comprehensive logging in development mode ✅
- [x] **Error handling tested** with fallback mechanisms ✅

**🎉 PHASE 7 COMPLETED**: Full API integration with end-to-end processing workflow!

**🧪 CONTINUOUS TESTING**: Begin testing individual components with `npm run dev` as they're implemented

---

## Phase 8: Integration & Validation ✅

### 8.1 End-to-End Integration
- [ ] **Connect all components** in the processing pipeline
- [ ] **Test data flow**: Upload → Parsing → Dual Output → Agent → Response
- [ ] **Verify error handling** at each stage

### 8.2 Environment Testing
- [ ] **Test development environment** with reasoning model
- [ ] **Test production environment** with base model
- [ ] **Verify environment variable switching**

### 8.3 Real Data Testing (Ongoing from Phase 5+)
- [ ] **Test with provided JSON files**:
  - `banner-part1-result-20250806_141904.json`
  - `raw-datamap.csv`
- [ ] **Verify dual output generation works**
- [ ] **Test complete workflow with `npm run dev`**
- [ ] **Upload real files and verify end-to-end processing**
- [ ] **TRACING**: Verify all execution steps are properly logged

### 8.4 Final Validation
- [ ] **Run comprehensive type checking**: `npx tsc --noEmit`
- [ ] **Run linting with fixes**: `npm run lint --fix`
- [ ] **Verify all imports are correct**
- [ ] **Check for any unused dependencies**

### 8.5 Documentation & Handoff
- [ ] **Update README if needed** with new API endpoint
- [ ] **Verify architecture doc accuracy**
- [ ] **Prepare for real file upload testing**

---

## Testing Strategy 🧪

**No automated testing required** - testing will be done via real uploads:

1. **Development Testing**: `npm run dev` → upload files → verify processing
2. **Real File Testing**: Upload actual `.csv`, `.pdf`, `.sav` files
3. **Response Validation**: Verify output matches `ValidationResultSchema`
4. **Error Handling**: Test with invalid files, missing data, etc.

## Key Principles Throughout 🎯

1. **Zod-First**: All schemas before implementation, always reference Zod best practices
2. **Type Safety**: Run `npx tsc --noEmit` after every phase
3. **Linting**: Run `npm run lint` consistently 
4. **SDK Compatibility**: Always use `outputType` not `outputSchema`
5. **Tracing-First**: Always implement tracing/observability before agent execution - this is CRITICAL for debugging
6. **Architecture Reference**: Reference `/docs/openai-agents-architecture.md` for all technical decisions
7. **Web Search**: Search "OpenAI Agents SDK JS" when encountering issues

## Success Criteria ✨

- [ ] **Single API endpoint** handles complete workflow
- [ ] **Group-by-group processing** works with real banner data
- [ ] **Dual output strategy** generates correct simplified/verbose JSONs
- [ ] **CrosstabAgent** produces validated mappings with confidence scores
- [ ] **Environment switching** works between development/production
- [ ] **Type checking** passes without errors
- [ ] **Linting** passes without errors
- [ ] **Ready for real file uploads** and testing

---

> **Next Phase**: After successful implementation, extend scope to include post-orchestrator processing (R script generation, execution, etc.)