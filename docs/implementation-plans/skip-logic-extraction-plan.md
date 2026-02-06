# Skip Logic Extraction Architecture

**Status**: Planned (not started)
**Created**: 2026-02-06
**Priority**: After Part 2 (Tito's testing) is complete

---

## Problem Statement

The BaseFilterAgent is our most expensive agent. It makes **one AI call per table** (30+ calls for a typical survey), and each call receives the **entire survey markdown + entire datamap** as context. The agent re-reads the same survey every time, re-discovers the same skip rules, and independently reasons through each table's filter needs.

This works — it produces correct results — but it's slow, expensive, and architecturally redundant. The same skip rule ("ONLY SHOW THERAPY WHERE A3 > 0") gets re-discovered 5+ times across related tables.

### Why Non-NA Filtering Isn't Enough

The pipeline already applies `banner cut + non-NA` as a default base. For most tables, this is sufficient. But for questions with skip/show logic, non-NA filtering is **necessary but not sufficient**.

**Real example from Leqvio (A3a):**
- Survey says: "ONLY SHOW THERAPY WHERE A3 > 0"
- Non-NA filter produced base = 141 (wrong)
- Correct base (A3_Leqvio > 0) = 135 (matches Joe's reference)
- Reason: 6 respondents had coded values (not NA) in A3a despite A3_Leqvio = 0

The skip logic condition variable and the dependent variable don't always have aligned NA patterns. Fielding platforms may code "not shown" as 0 or some default rather than NA. **Skip logic rules live in the survey document, not in the data patterns.**

---

## Proposed Architecture

### Core Insight: Mirror the Banner/Crosstab Pattern

The Banner/Crosstab path already solves an analogous problem:
- **BannerAgent** reads the banner PDF/DOCX, extracts structure in plain text
- **CrosstabAgent** takes plain text + datamap, translates to R expressions
- Then: deterministic table generation

Apply the same pattern to skip logic:
- **SkipLogicAgent** reads the survey DOCX, extracts all skip rules in plain text
- **FilterTranslatorAgent** takes plain text rules + datamap, translates to R filter expressions
- Then: deterministic filter application

### Why Two Agents (Not One)

Each agent has a focused role it can do exceptionally well:

| | SkipLogicAgent | FilterTranslatorAgent |
|---|---|---|
| **Skill** | Reading comprehension | Data mapping |
| **Input** | Survey document | Plain text rules + datamap |
| **Output** | Structured skip rules in plain language | R filter expressions |
| **Strength** | Understands survey intent | Knows variable names and structure |

This also makes debugging easier — if a filter is wrong, you can tell whether the agent misread the survey (SkipLogicAgent) or mis-mapped variables (FilterTranslatorAgent).

---

## Agent Outputs

### SkipLogicAgent Output

```typescript
interface SkipLogicExtractionOutput {
  rules: SkipRule[];
  noRuleQuestions: string[];  // Questions with NO skip logic (guaranteed PASS)
}

interface SkipRule {
  ruleId: string;
  surveyText: string;           // Original text from survey (e.g., "[ASK IF S2=6 OR 7]")
  appliesTo: string[];          // Question IDs affected (e.g., ["S2a"])
  plainTextRule: string;        // Rewritten in clear language
  ruleType: 'table-level' | 'row-level';
  conditionDescription: string; // What the condition checks
  dependsOn?: string[];         // Other ruleIds this depends on (for cascading logic)
}
```

**Example output for Leqvio survey:**

```json
{
  "rules": [
    {
      "ruleId": "rule_1",
      "surveyText": "[ASK IF S2=6 OR 7]",
      "appliesTo": ["S2a"],
      "plainTextRule": "Only ask S2a to Nurse Practitioners and Physician's Assistants (S2 = 6 or 7)",
      "ruleType": "table-level",
      "conditionDescription": "S2 equals 6 or 7"
    },
    {
      "ruleId": "rule_2",
      "surveyText": "[ASK IF S2=1]",
      "appliesTo": ["S3a"],
      "plainTextRule": "Only ask S3a to Cardiologists (S2 = 1)",
      "ruleType": "table-level",
      "conditionDescription": "S2 equals 1"
    },
    {
      "ruleId": "rule_3",
      "surveyText": "[ASK IF S2=1-5]",
      "appliesTo": ["S4"],
      "plainTextRule": "Only ask S4 to physicians, not NP/PAs (S2 = 1 through 5)",
      "ruleType": "table-level",
      "conditionDescription": "S2 is between 1 and 5"
    },
    {
      "ruleId": "rule_4",
      "surveyText": "ONLY SHOW THERAPY WHERE A3>0",
      "appliesTo": ["A3a"],
      "plainTextRule": "For A3a, only show each therapy row to respondents who prescribed that therapy (A3 count > 0 for that specific therapy)",
      "ruleType": "row-level",
      "conditionDescription": "Each therapy row filtered by corresponding A3 therapy count > 0"
    },
    {
      "ruleId": "rule_5",
      "surveyText": "IF COL B (WITHOUT A STATIN) IN A3a FOR ANY ROW > 0. ONLY SHOW THERAPY WHERE A3>0",
      "appliesTo": ["A3b"],
      "plainTextRule": "A3b shown only if respondent indicated any therapy without a statin in A3a col B > 0, AND each therapy row only shown if A3 > 0 for that therapy",
      "ruleType": "row-level",
      "dependsOn": ["rule_4"],
      "conditionDescription": "Compound: A3a col B > 0 for any row AND per-therapy A3 > 0"
    },
    {
      "ruleId": "rule_6",
      "surveyText": "ONLY SHOW THERAPY WHERE A4>0",
      "appliesTo": ["A4a"],
      "plainTextRule": "For A4a, only show each therapy row to respondents who would prescribe that therapy in the new scenario (A4 count > 0)",
      "ruleType": "row-level",
      "conditionDescription": "Each therapy row filtered by corresponding A4 therapy count > 0"
    },
    {
      "ruleId": "rule_7",
      "surveyText": "IF COL B (WITHOUT A STATIN) IN A4a FOR ANY ROW > 0. ONLY SHOW THERAPY WHERE A4>0",
      "appliesTo": ["A4b"],
      "plainTextRule": "A4b shown only if respondent indicated any therapy without a statin in A4a col B > 0, AND each therapy row only shown if A4 > 0",
      "ruleType": "row-level",
      "dependsOn": ["rule_6"],
      "conditionDescription": "Compound: A4a col B > 0 for any row AND per-therapy A4 > 0"
    },
    {
      "ruleId": "rule_8",
      "surveyText": "[ASK IF PRESCRIBING IN A4 IS > OR < A3 FOR ROWS 2, 3, OR 4]",
      "appliesTo": ["A5"],
      "plainTextRule": "Only ask A5 if PCSK9i prescribing changed between A3 and A4 (Leqvio, Repatha, or Praluent counts differ)",
      "ruleType": "table-level",
      "conditionDescription": "A4 prescribing differs from A3 for any of rows 2, 3, or 4 (PCSK9 inhibitors)"
    },
    {
      "ruleId": "rule_9",
      "surveyText": "[ASK IF S2=2]",
      "appliesTo": ["B5"],
      "plainTextRule": "Only ask B5 to PCPs/Internal Medicine (S2 = 2)",
      "ruleType": "table-level",
      "conditionDescription": "S2 equals 2"
    }
  ],
  "noRuleQuestions": ["S1", "S5", "S6", "S7", "S8", "S9", "S10", "S11", "S12", "A1", "A2a", "A2b", "A3", "A4", "A6", "A7", "A8", "A9", "A10", "B1", "B2", "B3", "B4"]
}
```

### FilterTranslatorAgent Output

```typescript
interface FilterTranslationOutput {
  filters: TableFilter[];
}

interface TableFilter {
  ruleId: string;                // References SkipLogicAgent rule
  questionId: string;            // Question this filter applies to
  action: 'filter' | 'split';
  // For table-level filters:
  filterExpression?: string;     // R expression (e.g., "S2 %in% c(6, 7)")
  baseText?: string;             // Human-readable (e.g., "NPs and PAs")
  // For row-level splits:
  splits?: Array<{
    rowVariables: string[];      // Which datamap variables this split covers
    filterExpression: string;    // R expression for this split
    baseText: string;            // Human-readable base description
    splitLabel: string;          // Label for the split table (e.g., "Leqvio")
  }>;
}
```

---

## Pipeline Architecture (Before vs After)

### Current Pipeline (Serial)

```
Survey ──→ SurveyProcessor ──→ markdown
.sav ────→ RDataReader ──→ DataMapProcessor ──→ datamap

Banner PDF ──→ BannerAgent ──→ CrosstabAgent ──→ CutsSpec

datamap + CutsSpec ──→ TableGenerator ──→ tables
tables + survey + datamap ──→ VerificationAgent ──→ enhanced tables
enhanced tables + survey + datamap ──→ BaseFilterAgent ──→ filtered tables  ← BOTTLENECK
filtered tables ──→ R Script Generator ──→ R Script ──→ Excel
```

BaseFilterAgent is at the END of the serial chain. Every table waits for it.

### Proposed Pipeline (Parallel Tracks)

```
                         ┌──→ BannerAgent ──→ CrosstabAgent ──→ CutsSpec ──┐
Survey + .sav + datamap ─┤                                                  ├──→ TableGenerator
                         └──→ SkipLogicAgent ──→ FilterTranslatorAgent ─────┘
                              (NEW)               (NEW)                ↓
                                                              tables WITH filters
                                                              pre-split where needed
                                                                       ↓
                                                              VerificationAgent
                                                              (sees pre-scoped tables)
                                                                       ↓
                                                              R Script Generator ──→ Excel
```

Key changes:
- **Two parallel tracks** that merge at TableGenerator
- **Skip logic extraction runs concurrently** with banner/crosstab work
- **No BaseFilterAgent** — filters applied before VerificationAgent
- **VerificationAgent gets pre-scoped tables** — better analytical decisions

### Downstream Impact on VerificationAgent

VerificationAgent will need to know that certain tables were pre-split due to skip logic.
This affects how it handles NETs (can't NET across different bases) and how it labels tables.
The table definition should carry metadata indicating it was split, similar to the current
`splitFromTableId` field, so VerificationAgent can reason about it appropriately.

---

## Why This Is Better

### Performance
- **Current**: ~30 serial AI calls in BaseFilterAgent (one per table)
- **Proposed**: 2 parallel AI calls (SkipLogicAgent + FilterTranslatorAgent), running concurrently with existing banner work
- **Estimated reduction**: 90%+ fewer AI calls for skip logic

### Accuracy
- Each agent has a focused role → does it better
- SkipLogicAgent: only needs reading comprehension (survey → rules)
- FilterTranslatorAgent: only needs data mapping (rules + datamap → R expressions)
- The BaseFilterAgent had to do BOTH in a single call per table, with enormous context

### Debuggability
- If a filter is wrong: was the rule misread (SkipLogicAgent) or mis-mapped (FilterTranslatorAgent)?
- Clear provenance chain: surveyText → plainTextRule → filterExpression
- The `noRuleQuestions` list is explicit — you can verify "did we correctly identify ALL questions with no skip logic?"

### Scalability
- Rules extracted ONCE, applied to any number of tables
- Adding a new survey doesn't require tuning BaseFilterAgent — same two agents work
- The pattern (extract → translate → apply) scales to any survey complexity

---

## Known Challenges

### 1. Row-Level Detection
The SkipLogicAgent needs to distinguish "filter who sees the whole question" (table-level) from "filter which rows each person sees" (row-level). This requires understanding survey intent, not just parsing text.

**Mitigation**: The two-agent split helps. SkipLogicAgent just says "this is row-level, each therapy row depends on its own condition." FilterTranslatorAgent does the actual per-row variable mapping using the datamap.

### 2. Cascading Dependencies
A3b depends on A3a col B > 0, which depends on A3 > 0. The SkipLogicAgent needs to capture these chains via `dependsOn` references.

**Mitigation**: These are rare (1-2 per survey typically). The `dependsOn` field lets FilterTranslatorAgent build compound expressions.

### 3. Ambiguous/Complex Logic
Some skip rules are hard to parse: "ASK IF PRESCRIBING IN A4 IS > OR < A3 FOR ROWS 2, 3, OR 4" requires comparing two multi-row variables.

**Mitigation**: FilterTranslatorAgent can flag these as `humanReviewRequired` when it can't confidently translate to R. For the initial implementation, handling 80% of cases deterministically and flagging 20% is a huge win.

### 4. Variable Name Mapping for Row-Level Splits
When the survey says "each therapy" the FilterTranslatorAgent needs to know that "Leqvio" maps to `A3r2`, "Praluent" to `A3r3`, etc. This mapping comes from the datamap labels.

**Mitigation**: The CrosstabAgent already solves this exact problem for banner cuts. Same approach applies.

---

## Implementation Order (When Ready)

1. **SkipLogicAgent** — Build and validate output against Leqvio survey manually
2. **FilterTranslatorAgent** — Build and validate R expressions against known-correct filters
3. **Pipeline integration** — Wire into parallel track, merge at TableGenerator
4. **VerificationAgent updates** — Handle pre-split tables, skip logic metadata
5. **BaseFilterAgent removal** — Remove from pipeline once new path is validated
6. **Testing** — Validate base sizes match Joe's reference across all tables

---

## Relationship to Existing Work

- **Reliability Plan Part 2** (complete): Validated BaseFilterAgent works for Leqvio
- **Reliability Plan Part 3** (next): Tito's data with loops/stacking — skip logic extraction will be even more valuable here since loop data has complex per-iteration show logic
- **BaseFilterAgent prompt** (`src/prompts/basefilter/production.ts`): Contains 650+ lines of instructions that would be split between two simpler, focused prompts

---

## Decision Log

| Decision | Rationale |
|----------|-----------|
| Two agents (not one) | Mirrors proven Banner/Crosstab pattern; each agent has focused skill |
| Parallel with banner track | No added wall-clock time; skip logic extraction is independent |
| Pre-split before VerificationAgent | VerificationAgent makes better decisions with correctly-scoped tables |
| Eliminate BaseFilterAgent | Redundant once filters are applied upfront |
| Don't pre-compute base sizes from .sav | System already calculates bases correctly once filters are attached; no need to duplicate |
| AI for rule extraction (not regex) | Surveys vary too much for pure regex; AI handles natural language variation across 25+ surveys |
| Plain text intermediate format | Human-reviewable; easy to debug; decouples reading from mapping |
