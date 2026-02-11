# How CrossTab AI Works

## The Problem

Market research runs on crosstabs. Every survey, every study, every strategic recommendation eventually passes through a crosstab — a structured breakdown of how different audience segments answered each question, complete with statistical testing that tells you whether the differences actually matter.

Building these crosstabs has traditionally been slow, manual, and expensive. A researcher receives a data file, a banner plan describing how to slice the data, and a survey document. They then spend hours — sometimes days — translating all of that into executable code, running the numbers, and formatting the output into something a client can actually read. Hawk Partners, like most research firms, outsourced much of this work.

CrossTab AI replaces that process with an intelligent pipeline. Upload your files, and the system reads, reasons about, validates, and executes the entire workflow — producing publication-ready Excel crosstabs.

The key to making this work isn't a single AI model. It's six specialized agents, each focused on one piece of the puzzle, orchestrated by a pipeline that knows when to think and when to just compute.

---

## The Architecture: Think Where It Matters, Compute Where You Can

CrossTab draws a sharp line between what requires intelligence and what doesn't. Some steps in crosstab generation — like figuring out what a banner plan is asking for — genuinely require reasoning. Others — like building a table structure from a known data schema — are entirely mechanical.

The system has six AI agents and several deterministic processors. The agents handle ambiguity, interpretation, and validation. The deterministic components handle everything else. This isn't just an efficiency play — it's a reliability one. Every time you can avoid asking an AI to do something, you remove a source of variability.

The pipeline orchestrates all of this, running independent workstreams in parallel and sequencing dependent ones, tracking costs and progress in real time, and providing the ability to cancel gracefully at any point.

---

## Before Anything Runs: Validation and Loop Detection

Before a single agent fires, the pipeline runs a critical validation step. The SPSS data file gets read through R, and the system extracts a comprehensive data map — every variable name, type, label, value range, and distribution. This isn't a quick skim; it's a thorough inventory of what's actually in the data.

During this same step, the system checks for loops. Surveys often ask the same battery of questions about multiple entities — rate Brand A on these five attributes, now rate Brand B on the same five. In the SPSS file, this creates iteration-linked variables (like `Brand_Satisfaction_1`, `Brand_Satisfaction_2`, etc.) that the system needs to detect and collapse into their base forms before anything else happens. If loops are found, the system flags this early and prepares a loop summary that several downstream components will need.

If the survey document exists, it also gets converted to markdown at this stage — a single, clean text representation that multiple agents can reference without redundant conversion.

Only after this groundwork is complete does the pipeline fan out into its parallel workstreams.

---

## The Six Agents

### 1. The Banner Agent — "What are we cutting by?"

Every crosstab study starts with a banner plan — a document (usually a PDF or Word file) that describes how to slice the data. It might say something like: *"Break results out by Gender (Male, Female), Age (18–34, 35–54, 55+), and Region (Northeast, South, Midwest, West)."*

The Banner Agent's job is to read that document and extract its structure. This sounds simple, but banner plans are designed for humans. They use visual formatting, implicit groupings, shorthand, and sometimes inconsistent labeling. There's no standard format.

The agent converts the document into images and uses vision capabilities to read each page, reasoning through the layout to identify banner groups and their columns. It produces two outputs: a verbose version with full reasoning and confidence scores (for debugging and quality assurance), and a simplified version that downstream agents can consume cleanly.

**Takes in:** A banner plan document (PDF or DOCX)
**Passes forward:** Structured banner groups — each with a name and a list of named columns

---

### 2. The Crosstab Agent — "Do these cuts actually exist in the data?"

The Banner Agent tells us *what* the client wants. The Crosstab Agent figures out *how* to get it from the actual data.

This is where the data map enters the picture. When CrossTab first ingests an SPSS data file, a validation step extracts a detailed map of every variable — its name, type, labels, value ranges, and distribution. The Crosstab Agent takes this map alongside the banner groups from the Banner Agent and attempts to match each requested cut to real variables in the dataset.

A banner column labeled "Male" needs to become something like `Q2 == 1` — a concrete R expression that filters the data correctly. The agent processes each banner group independently, validating that the variables it references actually exist and that its expressions make logical sense.

Every cut gets a confidence score. When the agent is uncertain — maybe a label is ambiguous, or multiple variables could match — it flags the issue. Users can provide hints to help resolve these cases, and the agent will retry with that additional context.

**Takes in:** The data map + banner groups from the Banner Agent
**Passes forward:** Validated R expressions for every cut, organized by banner group

---

### 3. The Skip Logic Agent — "Which questions should people actually see?"

Surveys aren't linear. If someone says they don't own a car, they shouldn't be asked about their car brand preference. These conditional rules — skip logic, show logic, filter logic — determine which respondents are eligible for which questions.

The Skip Logic Agent reads the full survey document in a single pass and extracts every conditional rule it can find. It's deliberately conservative: it only extracts rules that are clearly and explicitly stated, avoiding inference or guessing. For each rule, it captures what triggers it, which questions it affects, and how (skip, show, or filter).

It also identifies questions with *no* skip logic — which is just as important, because downstream processing needs to know which tables should show all respondents versus a filtered subset.

**Takes in:** The survey document (as markdown)
**Passes forward:** A complete list of skip/show/filter rules, plus a list of questions with no conditional logic

---

### 4. The Filter Translator Agent — "Turn those rules into code."

The Skip Logic Agent speaks in human terms: *"If Q3 = 'No', skip to Q7."* The R engine that will actually compute the crosstabs needs executable code: `Q3 != 2`. The Filter Translator Agent bridges that gap.

It takes each skip logic rule and translates it into a valid R filter expression, using the full data map as context to resolve variable names, value codes, and logical structure. It processes rules with controlled concurrency — three at a time — giving each rule focused attention rather than trying to translate everything in one shot.

This per-rule approach is a deliberate architectural choice. There are far fewer unique rules (typically dozens) than there are tables (potentially hundreds). By translating at the rule level, the system avoids redundant work while keeping each translation focused and debuggable.

Every translation gets validated against the data map to confirm the variables exist, and flagged if it needs human review.

**Takes in:** Skip logic rules + the full data map
**Passes forward:** Executable R filter expressions for each rule

---

### 5. The Verification Agent — "Make these tables actually useful."

By this point, the system has table definitions (built deterministically from the data map), filter expressions (from the Filter Translator), and validated cuts (from the Crosstab Agent). The tables are structurally correct, but they're not yet *good*.

The Verification Agent is where domain intelligence comes in. It takes each table definition and enhances it using the actual survey document as context. This means fixing answer labels to match the survey wording (not just the abbreviated data labels), adding NET rows where they make sense (like "Top 2 Box" for satisfaction scales or "Bottom 2 Box" for agreement scales), generating derived tables when appropriate, and flagging tables that should be excluded.

It processes tables in parallel (three at a time) and preserves any filters that were already applied. If the R validation step later finds errors in the generated expressions, those error details get fed back to the Verification Agent as context for a retry — creating a self-correcting loop.

**Takes in:** Table definitions + filters + the survey document + the data map
**Passes forward:** Enhanced table definitions with corrected labels, NET rows, and derived tables

---

### 6. The Loop Semantics Policy Agent — "How should we handle repeated data?"

This is the most specialized agent, and it only activates when the data contains loops — survey structures where the same questions were asked about multiple entities (like rating several brands on the same attributes). Looped data gets "stacked" in the SPSS file, meaning each respondent can have multiple rows.

The challenge is that banner cuts can mean different things in stacked data. A cut for "Brand A Users" might mean "only show rows where the entity is Brand A" (entity-anchored) or "only show respondents who use Brand A, but show all their entity ratings" (respondent-anchored). Getting this wrong produces silently incorrect results.

The Loop Semantics Policy Agent classifies each banner group as respondent-anchored or entity-anchored, specifying exactly how the R script should implement the filtering. It runs once per pipeline — a single classification call — and its output shapes how every downstream R expression handles the stacked data structure.

**Takes in:** Loop summary + banner groups + cuts + deterministic analysis findings
**Passes forward:** A per-banner-group policy dictating how stacked data should be filtered

---

## How The Agents Work Together

The pipeline doesn't run these agents one after another in a line. It runs three independent workstreams in parallel, then brings them together.

**Path A — The Banner Path** starts with the Banner Agent extracting structure from the plan document, then feeds that structure into the Crosstab Agent for validation against real data. This path answers the question: *"What are the columns of our crosstabs, and how do we compute them?"*

**Path B — The Table Path** is entirely deterministic. The Table Generator reads the data map and builds table definitions for every variable — no AI needed. This answers: *"What are the rows of our crosstabs?"*

**Path C — The Filter Path** starts with the Skip Logic Agent reading the survey, then feeds its rules into the Filter Translator Agent. This answers: *"Which respondents are eligible for which tables?"*

These three paths run simultaneously. Once they converge, the pipeline enters its sequential phase — a carefully ordered chain where each step depends on the one before it.

First, the **Filter Applicator** (deterministic) attaches the translated filter expressions to the appropriate tables. Then the **Verification Agent** enhances everything — fixing labels, adding NETs, generating derived tables. Then **R Validation** catches any expression errors, and if it finds them, feeds those errors back to the Verification Agent for a retry (up to three attempts). Then, if the data contains loops, the **Loop Semantics Policy Agent** classifies each banner group's relationship to the stacked data. Then the **R Script Generator** assembles a single executable R script, incorporating the loop policy if one exists. Then **R executes** that script against the actual SPSS data, computing every cell and running significance tests. And finally, the **Excel Formatter** produces the output workbook.

```
  ┌─────────────────────────────────────────────────────────────────────┐
  │                        SPSS Data File (.sav)                        │
  │                     ↓ Validation & Extraction ↓                     │
  │              Verbose Data Map + Loop Detection + Collapse            │
  │                  + Survey Conversion (if provided)                   │
  └──────────────────────────────┬──────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         ↓                       ↓                       ↓
  ┌──────────────────┐  ┌────────────────┐  ┌────────────────────┐
  │   PATH A:        │  │   PATH B:      │  │   PATH C:          │
  │   Banner Plan    │  │   Data Map     │  │   Survey Doc       │
  │       ↓          │  │       ↓        │  │       ↓            │
  │  Banner Agent    │  │  Table         │  │  Skip Logic        │
  │  (extraction)    │  │  Generator     │  │  Agent             │
  │       ↓          │  │  (deterministic)  │  (extraction)      │
  │  Crosstab Agent  │  │       ↓        │  │       ↓            │
  │  (validation)    │  │  Table         │  │  Filter Translator │
  │       ↓          │  │  Definitions   │  │  Agent             │
  │  Validated Cuts  │  │                │  │       ↓            │
  │                  │  │                │  │  R Expressions     │
  └────────┬─────────┘  └───────┬────────┘  └─────────┬──────────┘
           │                    │                      │
           └────────────────────┼──────────────────────┘
                                ↓
          ╔═════════════════════════════════════════════╗
          ║          SEQUENTIAL PHASE                   ║
          ╠═════════════════════════════════════════════╣
          ║                                             ║
          ║    Filter Applicator (deterministic)        ║
          ║                  ↓                          ║
          ║    Verification Agent (enhance & correct)   ║
          ║                  ↓                          ║
          ║         ┌─── R Validation ◄──┐              ║
          ║         │   (catch errors)   │              ║
          ║         │        ↓           │              ║
          ║         │   errors found? ───┘  (retry x3) ║
          ║         │        ↓ no errors                ║
          ║    Loop Semantics Policy Agent               ║
          ║    (if loops detected)                      ║
          ║                  ↓                          ║
          ║    R Script Generator                       ║
          ║                  ↓                          ║
          ║    R Execution (stats + sig tests)          ║
          ║                  ↓                          ║
          ║    Excel Formatter                          ║
          ║                                             ║
          ╚══════════════════╤══════════════════════════╝
                             ↓
                       crosstabs.xlsx
```

---

## The Feedback Loops

The system isn't a one-way conveyor belt. It has built-in correction mechanisms at multiple levels.

The most important is the **Verification-Validation retry loop**. After the Verification Agent enhances all the tables, R Validation attempts to execute every generated expression against the real data. When an expression fails — maybe a variable name was slightly off, or a filter condition doesn't parse — those error details get packaged up and fed back to the Verification Agent as context. The agent re-processes the failed tables with that knowledge, often fixing the issue without human intervention. This can happen up to three times, and in practice it catches the majority of expression errors that slip through the first pass.

At the user level, the **Crosstab Agent supports hints**. When a researcher reviews the pipeline output and sees that a cut was matched incorrectly or with low confidence, they can provide clarifying information — "this variable is actually Q5, not Q3" — and the agent re-processes with that guidance.

And running through every agent is the **scratchpad** — a reasoning tool that each agent uses to think through its decisions. These reasoning traces aren't just for show. They get saved alongside the outputs, creating a transparent audit trail that makes it possible to understand *why* the system made the choices it did. In a domain where accuracy is non-negotiable and clients need to trust the numbers, being able to trace a questionable result back to the agent's reasoning is essential.

---

## What Makes This Work

Three design principles run through the entire system.

**Separate intelligence from computation.** Six agents handle the parts that require genuine reasoning. Everything else — table construction, filter application, R script assembly, Excel formatting — is deterministic. This keeps costs down, speeds execution up, and reduces the surface area for errors.

**Validate at every boundary.** Every agent output conforms to a strict schema. Every R expression gets validated before execution. Every variable reference gets checked against the real data map. The system doesn't trust — it verifies.

**Preserve transparency.** Every agent records its reasoning. Every output includes confidence scores. Every pipeline run produces a detailed summary. When something goes wrong (and in a system this complex, something eventually will), you can trace exactly what happened and why.

The result is a system that takes what used to be hours of skilled manual work and compresses it into minutes — not by cutting corners, but by applying the right kind of intelligence to each piece of the problem.
