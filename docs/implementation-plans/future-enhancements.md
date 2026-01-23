# Future Enhancements

Tracked ideas for post-reliability improvements. These are not blocking current work.

---

## Human-in-the-Loop

Once reliability testing is complete with clean inputs, add human validation steps for broader input handling.

### Banner Plan Validation

After BannerAgent extracts cuts, show the user what was extracted before proceeding:
- Display banner groups and columns in plain language
- Highlight any flagged issues (if BannerValidateAgent is implemented)
- Allow user to confirm, adjust, or reject cuts
- User corrections flow back into the pipeline

**Why here**: Users can validate "S2=1 OR S2a=1 for Cardiologists" - this is their language. They cannot validate R expressions downstream.

### Table Validation

After TableAgent decides table structure, show the user before R execution:
- Display proposed tables (question → table type, rows, hints)
- Flag any low-confidence decisions
- Allow user to adjust table structure, add/remove tables
- User can mark tables to skip

**Why here**: Users know what tables they want in the final output. Catching issues here avoids wasted R computation.

### Sample Size Review

After R calculates base sizes, show sample counts before final output:
- Display base n per cut across all banner groups
- Flag zero-count (n=0) and low-count (n<30) cuts
- User can mark cuts to exclude from final output

---

## Banner Generation / AI-Recommended Cuts

Intelligent banner plan creation and enhancement.

### Use Cases

1. **No banner plan provided**: Partner uploads survey + data, AI generates recommended cuts from scratch
2. **Expand existing banner**: Partner has basic banner, AI suggests additional valuable cuts
3. **Validate coverage**: AI reviews banner against survey to identify missing important segments

### Why This Requires a New Agent

Considered adding this to existing agents, but:
- **BannerAgent**: Optimized for extraction (image → structured data), not generation
- **CrosstabAgent**: Has data map access but focused on validation, not recommendation
- **TableAgent/VerificationAgent**: Wrong stage of pipeline, don't have banner context

Each existing agent is reliable because it's narrowly focused. Adding generation responsibilities would compromise that reliability.

### Architectural Options

**Option A: Single RecommendationAgent**
```
Inputs: Survey document + Data map
Output: Recommended banner groups with cuts
```
- Pros: Simple, one call
- Cons: Large context, may miss nuances

**Option B: Dual-Agent System**
```
SurveyAnalysisAgent: Survey → Key variables + segments identified
CutRecommendationAgent: Survey analysis + Data map → Recommended cuts
```
- Pros: Separation of concerns, can debug each step
- Cons: More complexity, slower

**Option C: Single Agent with Multiple Tools**
```
RecommendationAgent with tools:
  - survey_parser: Extract question structure and logic
  - datamap_analyzer: Identify variable types and distributions
  - cut_generator: Propose cuts based on analysis
```
- Pros: Agent decides what tools to use when
- Cons: Tool design complexity

### Input Requirements

| Input | Required? | What It Provides |
|-------|-----------|------------------|
| Survey document | Yes (for generation) | Question text, answer options, skip logic context |
| Data map | Yes | Variable names, types, available answer codes |
| Existing banner | Optional | Context for expansion suggestions |
| SPSS data | Optional | Actual distributions for base size warnings |

### Output Format

```typescript
interface BannerRecommendation {
  groups: Array<{
    groupName: string;
    rationale: string;  // Why this grouping makes sense
    columns: Array<{
      name: string;
      suggestedFilter: string;  // Human-readable, not R syntax
      variableSource: string;   // Which variable(s) this uses
      confidence: number;
      reasoning: string;
    }>;
  }>;
  warnings: Array<{
    type: 'low_base' | 'missing_variable' | 'complex_logic';
    message: string;
  }>;
  alternatives: Array<{
    instead_of: string;
    suggestion: string;
    reason: string;
  }>;
}
```

### User Flow

1. User uploads survey + data map (no banner)
2. RecommendationAgent analyzes and proposes cuts
3. UI shows proposed banner with rationale for each cut
4. User can:
   - Accept all
   - Accept with modifications
   - Add their own cuts
   - Reject and upload their own banner
5. Approved banner flows into normal pipeline (BannerAgent skipped, CrosstabAgent validates)

### Implementation Complexity

**High** - This is not a simple addition:
- Requires domain knowledge about market research segmentation
- Needs to understand survey skip logic to avoid impossible cuts
- Must balance comprehensiveness vs. manageable number of cuts
- UI for reviewing/editing recommendations needs design

### When to Implement

After MVP launch, based on user feedback. If partners frequently ask "what cuts should I include?", this becomes valuable. If partners always have clear banner plans, lower priority.

### Research Needed

- What makes a "good" cut in market research? (Talk to analysts)
- Common patterns: demographics, screening questions, key behaviors
- How many cuts is typical? (Too few = missing insights, too many = unreadable output)
- Should AI explain trade-offs? ("Adding Region gives geographic insights but splits base sizes")

---

## Table Enhancements

### Bucketing for Numeric Questions

For single-row mean questions (like S6 "Years in clinical practice"), Joe shows:
- Mean/Median/Std Dev (we already calculate this)
- **PLUS** bucketed frequency distribution: "3-9 years", "10-15 years", "16-25 years"
- **PLUS** NET roll-ups: "15 Years or Less Time (Total)", "More Than 15 Years (Total)"

**The coordination problem**:
- R can easily bucket using `cut()` - but doesn't know semantic labels
- TableAgent could suggest buckets from question text - but doesn't know data's min/max range

**Possible approaches**:
1. TableAgent suggests bucket strategy + labels, R implements with actual data
2. R generates buckets with generic labels, VerificationAgent improves labels
3. DataMapProcessor extracts value ranges from SPSS metadata, passes to TableAgent
4. Hybrid: R detects data range, passes back to agent for label generation

### Demo Table at Top

Joe's tabs include a summary "demo table" at the very top:
- Takes all banner cuts and displays them as ROWS instead of columns
- Shows distribution/breakdown for each cut
- Gives quick high-level overview of sample composition
- Appears before all other tables

**Implementation**: Derived table generated in R (similar to T2B/B2B) or TableAgent. Uses bannerGroups metadata.

### Ranking Alternative Display

Joe sometimes shows a single table with ALL rankings for each answer option:
- Rank 1, 2, 3, etc. as columns
- Each answer option as a row
- Instead of separate tables per rank

Both valid approaches - room for interpretation on which to use.

---

## Input Validation Agents

### BannerValidateAgent

Validates banner cuts against survey skip logic BEFORE CrosstabAgent processing.

**When to implement**: If messy/ambiguous banner plans become a frequent problem.

**What it does**:
- Checks if cut expressions are semantically possible
- Fixes impossible logic: "S2=1 AND S2a=1" → "S2=1 OR S2a=1" (when skip logic makes AND impossible)
- Flags ambiguous expressions for human review

**Current status**: Not needed - clean banner plans produce correct output.

### DataValidator

Validates that cuts produce respondents BEFORE R execution.

**When to implement**: If zero-count cuts causing R errors becomes a problem.

**What it does**:
- Runs sample queries against actual data
- Returns sample counts per cut: `{"Cardiologists": 77, "Midwest": 0}`
- Flags zero-count and low-count (n<30) cuts
- Human can mark cuts to skip before R execution

**Current status**: Not needed - clean banner plans avoid zero-count issues.

---

## Infrastructure

### Logging System

Detailed implementation plan exists in `logging-implementation-plan.md`.

**Summary**: Replace 134 scattered `console.*` calls with structured, context-rich logging. Wide events for pipeline operations. Environment-aware log levels.

### Decipher API Integration

Direct integration with Decipher survey platform API.

**What it provides**:
- Survey structure with skip logic (no inference needed)
- Variable metadata from source
- Direct data export (no SPSS upload)

**When to implement**: If CSV data map parsing becomes unreliable, or if partners want to skip file uploads entirely.

**Research**: See `docs/research/decipher-api-exploration.md`

---

## MVP Launch (Team Access)

Enable the 80-person Hawk Partners team to use the tool with proper authentication, persistent storage, and error visibility.

**Goal**: Team members can log in, create projects, upload files, and track processing status.

### Project-Based Organization (Critical)

The UI must be project-based from day one. Each project is isolated:
- **Projects**: Each crosstab job is a distinct project with its own files and outputs
- **Organizations**: Teams/groups share access to certain projects
- **Access Control**: Users only see projects they have access to
- **No global dumping ground**: Unlike some vendors where everything is in one area, we want Discord-style project separation

This structure enables:
- Clean history per project
- Collaboration without confusion
- Easy re-runs and iterations on same project
- Clear ownership and access patterns

WorkOS AuthKit + Convex should support this naturally, but the UI must be designed around this principle.

### Technology Stack

| Component | Technology | What It Replaces | Why |
|-----------|------------|------------------|-----|
| **Authentication** | WorkOS AuthKit | No auth | Free for 80 users, SSO available later |
| **Database** | Convex | Filesystem (`temp-outputs/`) | Real-time subscriptions, TypeScript-native |
| **File Storage** | Cloudflare R2 | Local filesystem | S3-compatible, no egress fees |
| **R Execution** | Railway Docker | Local R installation | Vercel serverless doesn't have R |
| **Error Monitoring** | Sentry | Console logging | Know when things break |
| **Analytics** | PostHog (minimal) | None | Usage tracking |

### Key Architectural Changes

- **Real-time updates**: Convex provides subscriptions - when job status changes, all clients update automatically (no polling)
- **User-scoped projects**: Each user sees only their projects
- **Cloud file storage**: Files persist in R2, not local temp directories
- **Remote R execution**: Railway Docker container exposes HTTP endpoint for R scripts

### Accounts (Already Created)

- Convex: hawktab-ai
- Cloudflare R2: hawktab-ai (bucket created, no token yet)
- Railway: 30-day free trial
- Sentry: javascript-nextjs project
- PostHog: hawktab-ai

### When to Implement

After reliability testing proves the pipeline works correctly. This is infrastructure work that can happen in parallel with showing Bob a demo.

---

## Pipeline Optimizations

### Streaming TableAgent → VerificationAgent

**Idea**: Instead of waiting for TableAgent to complete all tables before starting VerificationAgent, stream tables to VerificationAgent as they become available.

**Current flow**:
```
TableAgent:        [Group1] [Group2] [Group3] [Group4] [Group5] ... [Done]
                                                                      │
VerificationAgent:                                                   [All tables at once]
```

**Proposed flow**:
```
TableAgent:        [Group1] [Group2] [Group3] [Group4] [Group5] ...
                      │        │        │
                      ▼        ▼        ▼
VerificationAgent:   [G1]    [G2]    [G3]    [G4]    [G5] ...
                   (starts after ~30% of tables ready)
```

**Implementation considerations**:
- TableAgent already processes groups sequentially - emit results as each completes
- VerificationAgent would need to accept a stream/queue rather than a full array
- Simple backpressure: if VerificationAgent catches up, it waits for the next table
- Need synchronization to ensure VerificationAgent doesn't overtake TableAgent

**Estimated savings**: ~15 minutes (VerificationAgent work overlaps with TableAgent)

**When to implement**: After all agents are finalized. Adding new agents to the pipeline would require re-optimizing, so better to wait until agent architecture is stable.

*Added: January 15, 2026*

---

## Polish

### Fix "Number Stored as Text" Warning in Excel

Excel shows warning icons on cells where numeric values are stored as text strings.

**Root cause**:
- `formatNumber()` in table renderers returns `val.toString()` instead of keeping numbers as numbers
- Percentages use string interpolation (`` `${pct}%` ``) instead of Excel number formatting

**Fix**:
- Assign numeric values directly to `cell.value` (not stringified)
- Use `cell.numFmt` for formatting (e.g., `'0.0'` for decimals, `'0%'` for percentages)
- Store percentages as decimals (0.42) with Excel percentage format

**Files**: `src/lib/excel/tableRenderers/frequencyTable.ts`, `meanRowsTable.ts`

**Effort**: ~15-20 lines across both renderers

*Added: January 15, 2026*

### Joe's Advanced Formatting

Features from Joe's output that are nice-to-have but not MVP:
- Continuous flowing tables without boundaries
- Inline significance letters in data cells (red letters)
- Percentages-only format (no counts)
- Advanced color/styling

### Additional Test Datasets

After practice-files success, test against all 23 datasets in `data/test-data/`:
- CART-Segmentation-Data
- Cambridge-Savings-Bank W1/W2
- GVHD-Data
- Iptacopan-Data
- Leqvio (Demand W1/W2/W3, Segmentation HCP/Patients)
- Meningitis-Vax-Data
- Onc-CE W2-W6
- Spravato
- UCB-Caregiver-ATU W1-W6

---

## Long-Term Vision: Validated Data Foundation

*This section captures strategic thinking about what HawkTab AI could become. None of this is on the current roadmap - our focus remains on reliability and production-readiness for traditional crosstabs. But it's worth documenting where we think the product could go.*

### Context: The Antares Conversation (January 2026)

In a discussion with Antares (Bob Hettel, Raina Friedman), we validated that:

1. **Traditional crosstabs aren't going away** - They remain foundational for market research, even as tools evolve
2. **The pain point is real but bounded** - Tab production takes skilled people and time, but the tools have improved
3. **No one else is doing what HawkTab does** - AI interpretation of unstructured inputs (banner plans without specs, messy Word docs) is novel
4. **The industry is shifting toward analysis** - Tools like Displayr and Q are adding AI features for exploration, not just tab production

Bob's quote: *"I've not seen anybody kind of going down this road... commercially speaking."*

### Two Markets, Two Value Propositions

| Market | What They Want | HawkTab Value | Growth Potential |
|--------|---------------|---------------|------------------|
| **Field partners** (Antares, Sago, etc.) | Fast, reliable tabs from messy inputs | Speed + handling unstructured specs | Finite - limited number of field partners |
| **Consultancies** (Hawk Partners, similar firms) | Tabs + ability to answer client questions | Validated data foundation + follow-ups | Larger - many consultancies need this |

**Field partners are in the data processing business.** They produce tabs and move to the next project. They won't pay more for exploration features.

**Consultancies are in the insights business.** They need tabs as a starting point, but the real work is interpreting and answering questions. That's where additional capabilities matter.

### The Validated Data Foundation Concept

The crosstab pipeline creates valuable artifacts as a byproduct:

| Artifact | What It Contains | Why It Matters |
|----------|------------------|----------------|
| **Validated datamap** | Variables, types, labels - all verified against real data | AI can only reference what actually exists |
| **Approved banner** | Cuts that work, human-validated via HITL | Future queries use proven expressions |
| **Survey context** | Question text, scale meanings, skip logic | AI understands what questions mean |
| **Proven R expressions** | Code that actually executed successfully | New queries build on working patterns |

This is essentially **RAG (Retrieval-Augmented Generation) for data analysis** - the AI is grounded in verified artifacts, not trying to figure things out cold.

### What This Enables (Eventually)

**Current**: Raw survey data → HawkTab → Static crosstabs (Excel) → Done

**Future**: Raw survey data → HawkTab → **Validated data package** → Crosstabs + ability to answer follow-ups

The follow-up capability isn't full BI exploration. It's narrower:
- "Can you also show me that by region?" → Uses approved cuts
- "What if we combined Tier 1 and 2?" → Quick re-cut from validated data
- "Show me just the top 3 brands" → Subset of existing analysis

The AI generates R code that MUST execute against real data. The execution IS the validation. If the code runs and produces a table, the result is real - not hallucinated.

### Why This Could Be More Reliable Than Alternatives

| Displayr/Q Approach | HawkTab Approach |
|---------------------|------------------|
| AI analyzes data fresh each time | Validation happens ONCE at setup |
| "Checkable outputs" = human reviews AFTER | AI is CONSTRAINED to validated artifacts |
| Must infer survey structure | Survey structure already parsed and verified |
| Must figure out what cuts make sense | Cuts already approved by human (HITL) |

The key insight: **HawkTab's advantage isn't exploration itself - it's the validation layer that precedes it.**

### Strategic Implications

**Phase 1 (current)**: Win crosstabs for field partners. Prove reliability. Get Antares using it successfully.

**Phase 2 (future)**: Same product, one more capability - follow-up questions from validated data. Now relevant to consultancies who care about insights.

This is NOT:
- Building a BI platform (Displayr's turf)
- Creating interactive dashboards
- Becoming a full analytics tool

This IS:
- Leveraging the validation work already done
- Enabling "one more question" without starting over
- Providing AI analysis that's trustworthy because it's constrained

### The Growth Question

Building for efficiency (faster tabs) has a ceiling. Building for growth means asking: *What would make consultancies choose HawkTab over just using Displayr or Q directly?*

The answer: **"AI analysis you can trust because it's constrained to validated data."**

Consultancies don't want to become data analysts. They want answers they can trust. If HawkTab can provide validated crosstabs PLUS the ability to answer follow-up questions with the same level of reliability, that's a differentiated value proposition.

### When to Revisit This

After:
1. Reliability plan is complete (Parts 4-7)
2. Antares is using the product successfully
3. Market validation with 5-10 similar firms
4. Clear product-market fit for crosstabs

Then: Test the hypothesis. Can we build a follow-up query interface that uses validated artifacts? Does it feel meaningfully more reliable? Would consultancies pay for it?

### Reference

- **Antares transcript**: `docs/antares-hawktabai-discussion-transcript-012226.txt`
- **Competitive analysis**: Displayr, Q, WinCross, Decipher/Forsta
- **Key differentiator**: AI interpretation of unstructured inputs + validated data foundation

*Added: January 23, 2026*

---

*Created: January 6, 2026*
*Updated: January 23, 2026*
*Status: Tracking only - none blocking current work*
