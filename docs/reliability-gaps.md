# Reliability Gaps: Clean Input vs. Real-World Input

## The Core Problem

The current system works well when given clean, explicit inputs. But humans don't provide clean inputs - they provide what makes sense to *them*, expecting the system to interpret context like a human analyst (Joe) would.

**The goal of Phase 2**: Bridge the gap between "works with perfect input" and "works with realistic input."

---

## Documented Issues

### Issue 1: Ambiguous Role/Concept Filters

**What happens**: Banner plan says `IF Physician` or `IF NP/PA`

**Current behavior**: System finds *any* variable with "Physician" in a label and uses it

**The problem**:
- There might be multiple variables (S2, S2b, list variables) that reference physicians
- The system picks the first match, not necessarily the right one
- S2 (survey question) might define physician as values 1-5
- S2b (list variable) might have a separate "Physician" option with value 1
- These produce different respondent counts

**What Joe would do**: Look at the survey structure, understand that S2 is the primary screening question, and know that "Physician" means S2=1,2,3,4,5

**What the system needs**:
- Survey document context showing question flow and skip logic
- Understanding of which variables are "primary" vs "derived"
- Domain knowledge about common abbreviations (NP=Nurse Practitioner, PA=Physician Assistant)

**Phase 2 solution**: BannerValidateAgent with survey context can catch this and ask: "Did you mean S2=1-5 (Cardiologists, PCPs, etc.) or S2b=1 (list variable)?"

---

### Issue 2: "From List" References

**What happens**: Banner plan says `Tier 1 from list` or `Segment A from list`

**Current behavior**: System searches for variables with "Tier" or "Segment" and maps labels to values

**The problem**:
- "From list" implies a pre-defined list variable exists
- The label (A, B, C, D) needs to map to numeric codes (1, 2, 3, 4)
- System makes reasonable guesses but confidence should be lower

**What Joe would do**: Know which list variable the client uses, verify the mapping

**What the system needs**:
- Data map should indicate which variables are "list variables"
- Value labels need to be searchable and matchable

**Current status**: Mostly works, but medium-term could benefit from explicit list variable tagging in data map

---

### Issue 3: Placeholder/TBD Expressions

**What happens**: Banner plan says `Joe to find the right cutoff` or `TBD`

**Current behavior**: System infers from group name and applies statistical cutoff (median split)

**The problem**:
- This is a reasonable guess but requires human verification
- The "right" cutoff might be domain-specific, not statistical
- Confidence is appropriately low (0.50-0.65) but user might not notice

**What Joe would do**: Ask the client what cutoff they want, or use domain knowledge

**What the system needs**:
- Flag these for explicit human review (Phase 2c Review Point 1)
- Present options: "We applied median split. Did you want a specific value?"

**Phase 2 solution**: Review Point 1 surfaces these before data validation

---

### Issue 4: Calculations/Formatting vs. Data Cuts

**What happens**: Banner plan has a "Calculations/Rows" section describing T2B, B2B, means

**Current behavior**: System initially treated this as a data cut group

**The problem**:
- Formatting instructions look structurally similar to data cut definitions
- System needed explicit guidance to distinguish "filter respondents" from "format output"

**Fix applied**: Prompt now explicitly says: "If it tells you HOW to display results (not WHO to include), it's a note"

**Remaining risk**: Novel formatting instructions might still confuse the system

---

### Issue 5: AND vs OR Logic Ambiguity

**What happens**: Banner plan says `S2=1 AND S2a=1`

**Current behavior**: System generates `S2 == 1 & S2a == 1`

**The problem**:
- This might be logically impossible due to skip logic
- S2a might only show when S2≠1, making AND impossible
- System validates syntax, not semantics

**What Joe would do**: Know the survey structure and realize this should be OR

**What the system needs**:
- Survey skip logic context
- Ability to detect mutually exclusive conditions

**Phase 2 solution**: BannerValidateAgent checks against skip logic and suggests fixes

---

### Issue 6: Data Map Missing Actual Value Labels/Distribution

**What happens**: Banner plan says `Segment A from list`, system maps to variable with A=1, B=2, C=3, D=4

**Current behavior**: System guesses the ordinal mapping (letters to integers) based on common patterns

**The problem**:
- The data map CSV may not include the actual value labels for all variables
- The 1, 2, 3, 4 mapping is an educated guess, not verified
- Result: n=0 for segments because the actual values might be different
- Confidence was appropriately 0.75, but still produced zero results

**What Joe would do**: Open the SPSS file, look at the actual value labels, verify the mapping

**What the system needs**:
- Access to the actual .sav file to read value labels and distributions
- Or: enriched data map that includes value label metadata from SPSS
- Or: DataValidator (Phase 2b) catches n=0 before final output

**Potential solutions**:
1. **Data map enrichment**: When processing .sav, extract and include value labels in the data map
2. **Pre-validation scan**: Before R execution, run quick counts to verify cuts produce results
3. **Fallback on zero**: If a cut produces n=0, flag for human review with actual values found

**Note**: The system did the right thing by setting confidence to 0.75 (acknowledging uncertainty). The issue is we don't currently verify against actual data until R execution.

---

## What Context Would Make the System Smarter?

| Context | Currently Available | Would Enable |
|---------|--------------------|--------------|
| Data map (variable names, types, values) | ✅ Yes | Basic variable matching |
| Survey document (question text, skip logic) | ❌ No | Semantic validation, impossible logic detection |
| SPSS value labels from .sav | ❌ No | Verified value mappings, not guesses |
| Actual data distribution (n per value) | ❌ No | Catch n=0 before R execution |
| List variable tagging | ❌ No | Better "from list" handling |
| Previous project history | ❌ No | Learning client-specific conventions |
| Domain abbreviation dictionary | ❌ Partial (in prompts) | NP/PA, HCP, etc. expansion |

---

## The Phase 2 Value Proposition

**Without Phase 2**:
- Works if human provides clean, explicit banner plan
- Requires human to know variable names, avoid ambiguity
- Errors discovered at R execution (too late)

**With Phase 2**:
- Catches ambiguous expressions early
- Presents issues in human-understandable language
- Suggests fixes based on survey context
- Human validates at the right point (before R, not after)
- System learns what "IF Physician" means for this survey

---

## Key Insight

> "Joe would understand. Joe would say, 'Okay, what they mean is this.'"

The system needs to replicate Joe's contextual understanding, not just syntax parsing. This requires:
1. More context (survey document)
2. Earlier validation (before CrosstabAgent)
3. Human-in-the-loop at the right moment (plain language, not R code)
4. Graceful handling of ambiguity (ask, don't guess silently)

Phase 2 is not optional polish - it's the difference between "demo that works" and "tool that replaces Joe."

---

*Created: January 2, 2026*
*Last Updated: January 2, 2026*
*Status: Living document - add issues as discovered*
