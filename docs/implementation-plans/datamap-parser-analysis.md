# DataMap Parser Analysis

## Executive Summary

**Critical Finding**: Our current parser only handles 3 of 26 datamap files (12%). The vast majority (21 files, 81%) are in a completely different format that our parser cannot process at all.

**Recommendation**: We need a format detection layer that routes to the appropriate parser, plus a new parser for the SPSS Variable Information format.

---

## Format Distribution

| Format | Count | Percentage | Parser Status |
|--------|-------|------------|---------------|
| Antares Standard | 3 | 12% | ✓ Supported |
| SPSS Variable Info | 21 | 81% | ❌ Not supported |
| SPSS Values Only | 2 | 8% | ❌ Unusable (no question text) |

### Files by Format

**Antares Standard (parser works)**:
- `leqvio-monotherapy-demand-datamap.csv`
- `titos-growth-strategy/original-datamap.csv`

**SPSS Variable Info (parser returns 0 variables)**:
- All Spravato, GVHD, Onc CE, Cambridge Savings Bank, Iptacopan, Leqvio Segmentation, Meningitis files

**SPSS Values Only (unusable)**:
- UCB Caregiver ATU W5, W6

---

## Format Comparison

### Format 1: Antares Standard (What We Built For)

```csv
[S1]: What is your primary specialty?,,
Values: 1-99,,
,1,Cardiologist
,2,Internal Medicine / General Practitioner
,99,Other
,,
S5: Are you employed by any of the following?,,
Values: 0-1,,
,0,Unchecked
,1,Checked
,[S5r1],Advertising Agency
,[S5r2],Marketing/Market Research Firm
```

**Structure**:
- Variable definition: `[variable]: description,,`
- Value range: `Values: X-Y,,`
- Answer options: `,code,label`
- Sub-variables: `,[subvar],description`

### Format 2: SPSS Variable Information

```csv
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
record,1,record: Record number,Ordinal,Input,7,Right,F7,F7
S8r1,17,S8r1: Federally Qualified Health Center (FQHC)...,Ordinal,Input,19,Right,F19,F19
```

**Structure**:
- 9-column table from SPSS `DISPLAY DICTIONARY` command
- Variable info in Label column (truncated at ~200 chars)
- No answer options in this section (separate Variable Values section)
- Has both Variable Information AND Variable Values sections

### Format 3: SPSS Values Only

```csv
Variable Values,,Label
status,1,Terminated
,2,Overquota
S3r1,0,NO TO: Asthma
,1,Asthma
```

**Structure**:
- Just value codes and labels
- No question text at all
- Unusable without Variable Information section

---

## Parser Performance on Supported Format

### Leqvio Monotherapy Demand (Baseline)

| Metric | Value | Notes |
|--------|-------|-------|
| Total variables | 192 | |
| Parent questions | 62 | |
| Sub-variables | 130 | |
| With answer options | 22 (11%) | Most are numeric ranges without labels |
| With context | 130 (100%) | All sub-vars have parent context |
| Confidence | 0.97 | High |

### Tito's Growth Strategy (Complex)

| Metric | Value | Notes |
|--------|-------|-------|
| Total variables | 530 | Much larger survey |
| Parent questions | 141 | |
| Sub-variables | 389 | |
| With answer options | 81 (15%) | |
| With context | 137 (35%) | **65% missing context** |
| Confidence | 0.96 | Deceptively high |

**Gap Analysis for Tito's**:
- 252 sub-variables (65%) are missing context
- Examples missing context: `RD_resultsthreat_potential`, `hLOCATIONr1`
- Root cause: These sub-vars have labels but no clear parent question linkage

---

## Specific Patterns & Edge Cases

### 1. Loop Variables (Tito's)

Found 31 loop groups with `_1`, `_2` suffixes:
- `A4_1`, `A4_2` (drink type questions)
- `hLOCATION_1`, `hLOCATION_2`
- `A15_1`, `A15_2`

**Parser behavior**: Treats each as separate variable. Does NOT detect loop pattern.

### 2. Checkbox Pattern

```csv
Values: 0-1,,
,0,Unchecked
,1,Checked
,[S5r1],Advertising Agency
```

**Parser behavior**: Correctly identifies as `binary_flag` normalizedType.

### 3. Long Text in Answer Options

Some answer options exceed 100 characters. Parser captures them but they get truncated in some downstream uses.

### 4. Commas in Answer Option Text

```csv
,2,"Recommend a statin + ezetimibe first, add or switch to a PCSK9i if needed"
```

**Parser behavior**: Handles quoted strings correctly.

### 5. Missing Brackets (Quoted Questions)

```csv
"S5: Are you or is any member of your family currently employed..."
```

**Parser behavior**: Detects these (41 instances in Leqvio) but categorizes differently than bracketed vars.

### 6. Sub-Variables Without Parent Text

```csv
[hLOCATIONr1],at your home
[hLOCATIONr2],at someone else's home
```

**Parser behavior**: These have no description, just a label. Context enrichment struggles to find parent.

---

## Answer Option Coverage Analysis

### What the Parser Extracts

| Pattern | Leqvio | Tito's |
|---------|--------|--------|
| Explicit labeled options (1=Yes, 2=No) | ✓ | ✓ |
| Checkbox patterns (0=Unchecked, 1=Checked) | ✓ | ✓ |
| Numeric ranges (Values: 0-100) | ✓ | ✓ |
| Open text/numeric | ✓ | ✓ |

### What the Parser Misses

| Gap | Impact |
|-----|--------|
| SPSS format entirely | 81% of files unusable |
| Loop detection | Can't auto-stack or warn user |
| Context for label-only sub-vars | 65% of Tito's sub-vars missing context |
| Scale label extraction from ranges | Numeric ranges don't indicate meaning |

---

## Recommendations

### Priority 1: Format Detection Layer

Add automatic format detection at pipeline entry:

```typescript
function detectFormat(csvPath: string): 'antares' | 'spss_var_info' | 'spss_values' | 'unknown' {
  // Check for key patterns
  if (hasPattern('[variable]:')) return 'antares';
  if (hasPattern('Variable Information') && hasPattern('Position,Label')) return 'spss_var_info';
  if (hasPattern('Variable Values')) return 'spss_values';
  return 'unknown';
}
```

### Priority 2: SPSS Variable Info Parser

New parser that:
1. Skips to "Variable Information" header row
2. Parses 9-column table to extract variable names and labels
3. Skips to "Variable Values" section
4. Parses value codes and labels
5. Merges both into our ProcessedDataMapVariable format

### Priority 3: Context Enrichment Improvements

For Antares format, improve context finding for:
- Label-only sub-variables
- Nested sub-variables (r1c1 pattern)
- Loop iterations

### Priority 4: Loop Detection

Add multi-layer loop detection as described in reliability-plan.md:
1. Suffix pattern matching (_1, _2)
2. Both are parent questions
3. Answer options match
4. Data validation (subset response pattern)

---

## Appendix: Test Commands

```bash
# Analyze format distribution
python3 scripts/xlsx-to-csv.py

# Test parser on specific file
npx tsx scripts/test-parser-analysis.ts

# Run full parser test
npx tsx scripts/test-verification-agent.ts
```

---

*Analysis Date: February 5, 2026*
*Files Analyzed: 26 datamaps across test-data folder*
