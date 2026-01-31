# Verification Agent Improvements

**Status**: Discovery
**Last Updated**: 2026-01-30
**Context**: Review of `outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-01-30T23-51-44-742Z/`

---

## The Core Problem

The VerificationAgent is treating its job as "enrich every table with every possible analytical view" when it should be "produce the tables an analyst would actually use to write a report."

It's optimizing for **completeness** when it should optimize for **usefulness**.

### Important Context

The agent is actually pretty good — almost there. It learned the *mechanics* of table generation (T2B, NETs, splits, etc.) and does them correctly. What's missing is the *judgment* layer: knowing when to apply these techniques and when to hold back.

The original prompt was written to teach mechanics. Now that the agent has those down, we need to go back and add purpose, context, and judicious thinking.

---

## Root Cause Analysis

### 1. The Agent Doesn't Understand the Output Medium

The agent has no mental model of what the final Excel workbook looks like or how analysts navigate it. It's generating tables in isolation without considering:

- **Visual density**: A 75-row table with Brand × Situation × Scale is technically complete but practically unusable
- **Cognitive load**: Analysts scan tables quickly — they need clear story per table, not everything in one place
- **Navigation**: More tables means more scrolling/clicking — each table should earn its place

**Why this happens**: The prompt describes the *mechanics* of creating tables (T2B, NETs, splits) but not the *purpose* (supporting analyst workflow). The agent knows HOW to create derived views but not WHEN they add value.

### 2. The Agent Treats All Enrichments as Equally Valuable

Current behavior: "I found a scale → add T2B. I found a grid → add splits. I found mean_rows → add frequency distribution."

This is mechanical application of rules without judgment. The prompt says "ADD T2B FOR SCALES" but doesn't say "...only when the T2B is the primary analytical output, not when you're creating 50 of them."

**Why this happens**: The prompt's action list reads like a checklist to complete, not a toolkit to use judiciously. There's no concept of diminishing returns or table economy.

### 3. Confusion About What "Table" Means to an Analyst

The agent thinks a "table" is a data structure. To an analyst, a "table" is a **story** — it answers one question clearly.

Examples of good table stories:
- "How likely are physicians to prescribe Leqvio without a statin?" (one brand, full scale)
- "Which brand has the highest likelihood of prescribing without a statin?" (all brands, T2B only)

Examples of bad table stories:
- "Here's everything about A8" (75 rows of everything)
- "Here's T2B, B2B, MB, and full scale for all brands in one situation" (what's the question?)

**Why this happens**: The prompt focuses on data completeness, not analytical clarity. It doesn't ask "what question does this table answer?"

### 4. Indentation Semantics Are Misunderstood

The agent uses `indent: 1` to mean "visually related to the row above" when it actually means "this row is a component of the NET above and its values sum into that NET."

This leads to structural errors like indenting "No issues" under "Experienced issues (NET)" when "No issues" is explicitly NOT part of that NET.

**Why this happens**: The prompt explains indentation in terms of visual hierarchy, not data hierarchy. The agent sees it as formatting, not semantics.

### 5. No Concept of "Earned" Tables

Every derived table has a cost (clutter, navigation, analyst time) and a benefit (analytical insight). The agent creates tables without weighing this tradeoff.

Examples:
- A "Medicare (NET)" table when the overview already has Medicare as a row — does the separate table add insight?
- Frequency distributions for every numeric variable — are analysts actually segmenting by these bins?
- "Any of the above (NET)" at 100% — this is pure noise

**Why this happens**: The prompt rewards creation ("add T2B", "add splits") without ever discussing deletion or restraint.

---

## Observed Symptoms

These are the specific issues we saw, mapped to root causes:

| Symptom | Root Cause |
|---------|------------|
| A8 has 75-row flat table + derived tables still showing all scale values | #1, #2, #3 |
| A9 has "No issues" indented under "Experienced issues (NET)" | #4 |
| B1 creates 10 tables for one question (mean + 8 distributions + NET) | #2, #5 |
| "Any of the above" NET created when it's 100% | #5 |
| Multiple A1 tables but unclear which is which | #3 |
| Question text paraphrased instead of verbatim | Prompt says verbatim but not enforced |
| Tables don't tell unique stories — repeat same info differently | #3 |
| Grid scales shown as flat Brand × Scale × Value | #1, #3 |

---

## Questions to Explore

Before writing prompt fixes, we should think through:

1. **What does a "good" table set look like for A8?**
   - Should there be an overview at all, or just derived views?
   - How many tables is "right" for a 3-brand × 3-situation × 5-scale grid?
   - What's the ideal comparison table structure?

2. **When should the agent NOT create a derived table?**
   - What's the threshold for "this adds value"?
   - Can we articulate rules, or is it judgment?

3. **How do we teach "table as story"?**
   - Should the agent articulate what question each table answers?
   - Would a "table purpose" field help?

4. **Should we add a subtitle/focus field to the schema?**
   - This would let the agent differentiate "A8 - Leqvio" vs "A8 - Repatha"
   - Currently it tries to cram this into questionText, which doesn't work

5. **Is there a simpler mental model we can give the agent?**
   - Current prompt is very long with many rules
   - Maybe fewer rules, but better conceptual framing?

---

## Potential Directions

Not solutions yet, just directions to consider:

### Direction A: Add "Table Economy" Principles
Teach the agent that tables have costs. Introduce concepts like:
- Every table should answer ONE clear question
- Prefer fewer, clearer tables over more, cluttered ones
- If a derived table doesn't add insight beyond the overview, don't create it

### Direction B: Prescriptive Patterns for Common Cases
Instead of general rules, give specific patterns:
- "For a Brand × Situation × Scale grid, create: (1) T2B comparison per situation, (2) full scale per brand, (3) skip the massive overview"
- This is less flexible but more reliable

### Direction C: Add a "Table Purpose" Requirement
Force the agent to articulate what question each table answers before creating it. If it can't state the question clearly, don't create the table.

### Direction D: Restructure the Prompt
Current prompt is action-oriented ("here's how to add T2B"). Maybe restructure around outcomes:
- "What makes a table useful?"
- "When should you create vs. skip a derived view?"
- "How should an analyst navigate your output?"

### Direction E: Add Negative Examples
The prompt has lots of "do this" but few "don't do this" examples. Showing anti-patterns might help.

---

## Key Realization

The agent isn't bad — it's actually impressive what it can do. The original prompt was focused on getting it to generate tables *correctly* (mechanics). Now that it can do that, we need to add the *judgment* layer.

The prompt doesn't tell the agent:
- What its purpose is at a higher level
- That it should think judiciously
- That there are trade-offs to consider

It reads like a technical spec, not a mission brief.

---

## The Restructure

The prompt needs to be reorganized around:

1. **Here's what you're doing** — Taking basic tables and enriching them
2. **Here's why you're doing it** — Analysts use these to write reports; they need to see the story quickly
3. **Here's how your output will be used** — Navigated in Excel, scanned for insights, compared across cuts
4. **Here are the trade-offs** — More tables = more clutter; every table has a cost
5. **Here are your constraints** — Be judicious, be efficient, earn each table
6. **Here's your mandate** — Enrich thoughtfully, not mechanically

### The Efficiency Mindset

> "You can make 5 tables worth of content in 3 tables — not by making them longer, but by getting to the essence of what needs to be shown."

This is the key insight. The agent should ask:
- Are all of these tables really needed, or only some?
- Are these unique from one another?
- Is there overlapping insight? (There shouldn't be)
- The data is the same — am I cutting it in meaningfully different ways?

### Scratchpad Enhancement

After generating all tables for a question, add a reflection step:

> "Review: I created N tables for [question]. Let me check:
> - Does each tell a unique story?
> - Is any insight duplicated?
> - Could I show this more efficiently with fewer tables?
> - Would an analyst actually use each of these?"

This creates a checkpoint before moving on.

---

## Next Steps

1. ~~Pick one or two problematic tables (A8, A9) and manually design what "good" output looks like~~
   - Actually: Start by drafting the "mission brief" framing for the prompt
   - Then use A8/A9 to test whether the new framing produces better judgment

2. Restructure prompt with the new framing (purpose → usage → trade-offs → constraints → actions)

3. Add scratchpad reflection checkpoint

4. Test on same dataset, compare outputs

---

## Appendix: Raw Feedback Notes

From `formatting-fixes.md`:

- Model needs consistent question numbering approach
- Need subtitle field for table differentiation
- Exclude tables more aggressively (TERMINATE criteria = 0% variance)
- Use plain English, not variable codes like "S2=1"
- Verbatim question text, not paraphrased
- Tables should tell unique stories, not repeat same info
- Grid + scale should never be flattened into one table
- Mean_rows → frequency isn't always needed
- NET indentation logic is wrong (A9)
- A8 is the canonical example of what NOT to do
