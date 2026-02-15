# MaxDiff Message Testing Support - Implementation Plan

**Status:** Planning
**Created:** 2026-02-15
**Owner:** Jason + Claude

---

## Overview

Add first-class support for MaxDiff message testing projects to Crosstab AI. MaxDiff projects test multiple messages (claims, value propositions, etc.) to determine which are most motivating/preferred. The output is typically:
- Raw MaxDiff choice data (which message was most/least preferred in each set)
- **Anchored Probability Index (API) scores** (0-200 scale, calculated by MaxDiff simulator)

### Key Principle
**API scores are optional, not blocking.** The pipeline should run successfully for MaxDiff projects whether or not the simulator has appended API scores. If API scores are missing, we still generate crosstabs for demographics and other variables—many users want to report on screener data, firmographics, etc., even without message analysis.

---

## Current State

### What Exists
1. **UI intake form** asks two questions when user selects MaxDiff project type:
   - "Do you have the messages?" (Yes/No)
   - "Is the Anchored Probability Index included?" (Yes/No)

2. **Currently BLOCKS pipeline** if API not included (❌ this needs to change)

3. **No message upload workflow** or message-to-variable matching

4. **No alternate message handling** (messages with A/B versions that get averaged together)

### What's Missing
- Message upload interface (Excel or in-app table)
- Message-to-variable matching logic
- Alternate message detection and linking
- API score detection and validation
- Graceful degradation when API scores absent
- Special formatting/labeling for API variables in crosstabs

---

## Requirements

### 1. API Score Handling (Optional, Not Blocking)

#### Detection
```typescript
interface APIDetectionResult {
  hasAPIScores: boolean;
  apiVariables: string[];        // e.g., ["AnchProbInd_1", "AnchProbInd_2", ...]
  apiCount: number;
  anchor: string | null;         // The anchor message variable (usually last)
  confidence: 'high' | 'medium' | 'low';
}
```

**Detection logic:**
1. Search .sav for variables matching pattern: `/^AnchProbInd_\d+$/`
2. Check variable labels for "API:" prefix (Caplyta pattern)
3. Verify data type is numeric with reasonable range (0-200)
4. Count: expect N messages + 1 anchor = N+1 API variables
5. Last API variable usually labeled "API: Anchor" or similar

**Validation:**
- If user said "Yes, API included" but we don't detect API variables → Warning, continue anyway
- If we detect API variables but user said "No" → Info message, proceed with API support
- If API variable count doesn't match message count → Warning, attempt partial match

#### Graceful Degradation
- **WITH API:** Generate crosstabs for API variables + standard demographics
- **WITHOUT API:** Generate crosstabs for raw MaxDiff choice data + standard demographics
- **UI indicator:** Show badge/chip on run page: "API Detected ✓" or "API Not Found (raw data only)"

---

### 2. Message Upload & Standardized Format

#### Required Format

**Option A: Excel Upload**
Required columns (exact names, case-insensitive):
1. `message_id` or `code` — Message identifier (e.g., "I1", "E1", "S10", "1", "2")
2. `message` or `message_text` — Full message text
3. `is_alternate` — Boolean or "Yes"/"No" indicating if this is an alternate version
4. `alternate_to` — If is_alternate=true, which message ID is this an alternate of? (e.g., "I1" for I1A)

Optional columns:
- `category` — Grouping (e.g., "Safety", "Efficacy", "Dosing") [not used for splitting, just metadata]

**Option B: In-App Table Editor** (like environment variable editor)
- 4-column table UI: message_id | message_text | is_alternate | alternate_to
- Add/remove rows
- **Paste from Excel (smart detection)** — critical feature for easy copying
- Download as .xlsx template
- Real-time validation as user types

#### Schema Validation
```typescript
interface MessageDefinition {
  id: string;                    // "I1", "S10", "1", etc.
  text: string;                  // Full message text
  isAlternate: boolean;          // Is this an alternate version?
  alternateGroup?: string;       // Links alternates together (e.g., "I1" for both I1 and I1A)
  category?: string;             // Optional grouping
  truncatedLabel?: string;       // From .sav (for validation)
  apiVariable?: string;          // Matched variable name
  matchConfidence?: number;      // 0-1
}
```

#### Upload Flow
1. User uploads .xlsx or fills in-app table
2. Validate column presence and names
3. Parse and normalize (trim whitespace, normalize booleans)
4. Check for duplicate message IDs
5. Detect alternate groups (either explicit column or pattern like "I1"/"I1A")
6. Store in Convex with project metadata

---

### 3. Message-to-Variable Matching

#### Matching Strategy (Waterfall)

**Step 1: Code-based matching (highest confidence)**
- Extract code from API variable label: `"API: S10 - Rates of sexual..."` → `"S10"`
- Match to message `id` in uploaded data
- Pattern: `/^API:\s*([A-Z0-9_]+(?:\s+OR\s+ALT\s+[A-Z0-9_]+)?)\s*-/`
- Handles alternates: "I1 OR ALT I1A" → match both I1 and I1A messages

**Step 2: Text-based fuzzy matching (medium confidence)**
- If code extraction fails, try text matching
- Normalize both .sav label and message text:
  - Remove punctuation except periods
  - Lowercase
  - Collapse whitespace
  - Truncate message text to same length as label
- Calculate similarity score (Levenshtein or simple ratio)
- Match if similarity > 0.85

**Step 3: Position-based (fallback, actually pretty reliable)**
- If both fail, fall back to position
- `AnchProbInd_1` → Message #1 in upload order
- This is actually how most simulators work, so it's a reasonable default
- No special user approval needed (but show which method was used)

#### Alternate Handling

**Detection:**
```typescript
// From label: "API: I1 OR ALT I1A - Only CAPLYTA is indicated..."
const alternatePattern = /^API:\s*(\w+)\s+OR\s+ALT\s+(\w+)/;
const match = label.match(alternatePattern);
// match[1] = "I1", match[2] = "I1A"
```

**Reporting:**
- Create single table row for alternate group
- Label: Use primary message text (or concatenate if requested)
- Data: Average/combine API scores from both alternates
- Note in table context: "Combined I1/I1A (n=XX each)"

---

### 4. Pipeline Integration

#### Deterministic Processor (No Agent Needed)
```typescript
class MessageProcessor {
  detectAPIScores(datamap: DataMap): APIDetectionResult;

  matchMessages(
    apiVariables: string[],
    messages: MessageDefinition[],
    datamap: DataMap
  ): MessageMatch[];

  groupAlternates(matches: MessageMatch[]): MessageGroup[];

  validateMatches(matches: MessageMatch[]): ValidationReport;
}
```

**Pipeline modifications:**
1. **After DataMapProcessor:**
   - Run `MessageProcessor.detectAPIScores()`
   - Mark MaxDiff variables in datamap metadata
   - If user uploaded messages: run `matchMessages()`
   - Store results in pipeline context

2. **In TableGenerator:**
   - **DO NOT SPLIT MaxDiff variables** (keep them all together)
   - For API variables, use matched message text as row label (not truncated .sav label)
   - For alternate groups, create single row (not two)

3. **Agent Prompts (ALL agents):**
   - Add MaxDiff-specific instructions: "This is a MaxDiff project. You'll see variables that look like loops or separate measures (e.g., AnchProbInd_1-31). These are message scores and should stay together. Do NOT split them."
   - Applies to: VerificationAgent, FilterTranslatorAgent, SkipLogicAgent

4. **In ExcelFormatter:**
   - Add filename suffix: `-API.xlsx` or `-raw.xlsx`
   - Message text might be long → adjust column width
   - Base text might be different for API tables

---

### 5. UI/UX Changes

#### Upload Interface (New Page/Modal)

**Route:** `/projects/[id]/messages`

**Sections:**
1. **Upload Method Selector**
   - [ ] Upload Excel file
   - [ ] Enter messages manually

2. **Excel Upload** (if selected)
   - Drag-and-drop or file picker
   - Template download link
   - Validation feedback (green checkmarks or red errors)

3. **Manual Entry Table** (if selected)
   - 3 columns: Message ID | Message Text | Is Alternate?
   - Add Row / Remove Row buttons
   - Paste from clipboard (smart parse)

4. **Preview & Validation**
   - Table showing parsed messages
   - Warnings for duplicates, missing data
   - Alternate grouping preview: "I1 + I1A will be combined"

5. **Save & Match**
   - Button: "Save Messages"
   - Shows matching preview (if .sav already uploaded)
   - Confidence indicators per match

#### Project Dashboard Updates

**MaxDiff-specific badges:**
- "✓ API Detected (31 messages)"
- "⚠ API Not Found (raw data only)"
- "✓ Messages Linked (28/31 matched)"

**Warnings (not blocking):**
- "No Anchored Probability Index found. Crosstabs will show raw MaxDiff data and demographics only."
- "3 messages could not be auto-matched. Please review message linking."

---

### 6. Data Storage (Convex Schema)

#### New Table: `messages`
```typescript
export default defineTable({
  projectId: v.id("projects"),
  messages: v.array(v.object({
    id: v.string(),                    // "I1", "S10", etc.
    text: v.string(),                  // Full message
    isAlternate: v.boolean(),
    alternateGroup: v.optional(v.string()),
    category: v.optional(v.string()),
  })),
  uploadMethod: v.union(v.literal("excel"), v.literal("manual")),
  uploadedAt: v.number(),
  uploadedBy: v.id("users"),
})
  .index("by_project", ["projectId"]);
```

#### Update `projects` table:
```typescript
// Add to existing schema
{
  isMaxDiff: v.boolean(),
  hasAPIScores: v.optional(v.boolean()),  // User-declared
  detectedAPIScores: v.optional(v.boolean()),  // System-detected
  apiVariableCount: v.optional(v.number()),
}
```

#### New Table: `messageMatches` (per pipeline run)
```typescript
export default defineTable({
  runId: v.id("runs"),
  matches: v.array(v.object({
    messageId: v.string(),
    apiVariable: v.string(),
    matchMethod: v.union(
      v.literal("code"),
      v.literal("text"),
      v.literal("position")
    ),
    confidence: v.number(),
    isAlternateGroup: v.boolean(),
    alternateVariables: v.optional(v.array(v.string())),
  })),
})
  .index("by_run", ["runId"]);
```

---

## Implementation Phases

### Phase 0: Audit Current Behavior (Investigation)
**Goal:** Understand what the current pipeline does with MaxDiff data and identify failure modes.

**Tasks:**
1. Run pipeline on Caplyta MaxDiff dataset
2. Identify what caused splitting (FilterTranslatorAgent? Loop detection?)
3. Check if raw utility scores got split into separate tables (they shouldn't)
4. Review scratchpad traces to see where things went wrong
5. Document specific fixes needed in prompts/processors

**Questions to answer:**
- Why did the system split MaxDiff variables?
- Was it loop detection catching them as repeated measures?
- Was it FilterTranslatorAgent applying filters incorrectly?
- Did VerificationAgent try to organize them into sections?
- What do the base sizes look like (are they different per variable)?

**Outputs:**
- List of specific bugs/issues to fix
- Prompt modifications needed for MaxDiff-specific handling
- DataMap processor changes (if needed)

---

### Phase 1: API Detection & Graceful Degradation (MVP)
**Goal:** Make MaxDiff projects non-blocking. Detect API scores if present, proceed either way.

**Tasks:**
1. Update UI: Change from blocking error to calm informational message
   - "We didn't find Anchored Probability Index variables. You can re-upload your .sav file with API scores (look for `AnchProbInd_*` variables), or proceed with raw MaxDiff data."
2. Implement `MessageProcessor.detectAPIScores()`
   - Auto-exclude anchor variable (value = 100 for all respondents)
3. Add pipeline context flag: `hasAPIScores: boolean`
4. Update TableGenerator: don't split MaxDiff variables
5. Add to output filename: `crosstabs-API.xlsx` or `crosstabs-raw.xlsx`
6. Add badge to UI showing status (not a warning, just info)

**Success Criteria:**
- User can run pipeline for MaxDiff project without API scores
- Pipeline completes successfully, generates crosstabs for demo variables
- All MaxDiff variables stay together (not split)
- UI shows clear indicator: "API Detected ✓" or "Raw Data Only"

---

### Phase 2: Message Upload & Storage
**Goal:** Allow users to upload/enter message definitions.

**Tasks:**
1. Create Convex schema: `messages` table
2. Build upload UI: `/projects/[id]/messages`
3. Excel parser with validation
4. Manual entry table with paste support
5. Download template function
6. Store messages in Convex

**Success Criteria:**
- User can upload Excel with 3 required columns
- User can manually enter messages in table
- Validation catches errors (duplicate IDs, missing columns)
- Messages stored and retrievable per project

---

### Phase 3: Message-to-Variable Matching
**Goal:** Automatically match uploaded messages to API variables in .sav file.

**Tasks:**
1. Implement code-based matching (regex extraction)
2. Implement text-based fuzzy matching (fallback)
3. Implement position-based matching (low confidence, requires approval)
4. Alternate detection and grouping
5. Store matches in `messageMatches` table per run
6. Show matching preview in UI with confidence scores

**Success Criteria:**
- 90%+ auto-match rate on Caplyta and Spravato test datasets
- Alternates correctly grouped (I1 + I1A)
- UI shows which messages matched and method used
- User can manually override poor matches

---

### Phase 4: Reporting Integration
**Goal:** Use matched messages in crosstab output.

**Tasks:**
1. Update TableGenerator: use message text for row labels
2. Combine alternate groups into single row
3. Update VerificationAgent prompt: provide message context
4. Excel formatting: adjust column width for long messages
5. Optional: color-code by category

**Success Criteria:**
- API crosstabs show full message text, not truncated labels
- Alternates combined into single row
- Excel readable (proper column widths)
- Output matches Joe's format (compare to existing MaxDiff tabs)

---

### Phase 5: Advanced Features (Future)
- In-app message editing (post-upload)
- Message category-based table sections
- Top Box analysis (API > 150)
- Message ranking tables
- Export message match report (CSV/PDF)

---

## Edge Cases & Error Handling

### 1. API Variable Count Mismatch
**Scenario:** User uploads 31 messages, but only 28 API variables detected.

**Handling:**
- Proceed with partial matching
- Warn: "3 messages could not be matched to API variables"
- Show unmatched messages in UI for manual review

### 2. Alternate Detection Failure
**Scenario:** Label says "I1 OR ALT I1A" but only I1 exists in message upload.

**Handling:**
- Match I1 only
- Warn: "Alternate I1A referenced but not found in message list"
- Suggest: "Did you mean to mark I1 as having an alternate?"

### 3. Multiple Match Candidates
**Scenario:** Two messages have very similar text, both match the same variable.

**Handling:**
- Use code-based match if available (deterministic)
- If text-based: pick highest confidence, flag as "low confidence"
- Require user approval before proceeding

### 4. No Matches Found
**Scenario:** Zero messages auto-match.

**Handling:**
- Offer position-based matching (with explanation)
- Require explicit user approval
- Allow manual mapping interface

### 5. Missing Message Upload
**Scenario:** User runs pipeline but didn't upload messages, yet API scores exist.

**Handling:**
- Use truncated .sav labels (better than nothing)
- Show info banner: "Upload messages for better labeling"
- Pipeline proceeds normally

---

## Testing Strategy

### Unit Tests
- `detectAPIScores()` with various .sav structures
- Code extraction regex (various label formats)
- Fuzzy text matching with different similarity thresholds
- Alternate grouping logic

### Integration Tests
- Full pipeline with Caplyta dataset (has API scores + alternates)
- Full pipeline with Spravato dataset (no API scores)
- Message upload → matching → table generation flow

### Manual QA
- Compare output to Joe's MaxDiff crosstabs
- Verify message text matches exactly
- Check alternate grouping (no duplicate rows)
- Test Excel formatting (column widths, readability)

---

## Open Questions (Resolved)

1. **Message category usage:** ✓ RESOLVED
   - Do NOT auto-create sections by category
   - Category is metadata only, not used for table organization
   - Show all messages together

2. **Top Box analysis:** ✓ RESOLVED
   - This is a prompting strategy / VerificationAgent decision
   - Not a data processing concern
   - Can be added later via agent instructions

3. **Anchor message:** ✓ RESOLVED
   - Anchor is constant 100 for all respondents (reference point)
   - Auto-detect: if API variable has all values = 100, exclude from reporting
   - Typically the last variable: `AnchProbInd_31: "API: Anchor"`

4. **Manual override UI:** ✓ RESOLVED
   - If auto-match is poor, user should use manual editor from scratch
   - System should work flawlessly if they upload in the correct format
   - Focus on making the format clear and easy to follow (template + instructions)

5. **Message versioning:** ✓ RESOLVED
   - No versioning needed
   - By the time user has data file, messages are final
   - If they need to update, they re-upload (simple overwrite)

---

## Success Metrics

### MVP (Phase 1)
- [ ] 100% of MaxDiff projects can run pipeline (no blocking)
- [ ] API detection accuracy: 95%+ (test on 10 datasets)
- [ ] Clear UI feedback on API status

### Full Feature (Phase 4)
- [ ] Message auto-match rate: 90%+ on real datasets
- [ ] Alternate grouping: 100% correct (no duplicate rows)
- [ ] User feedback: "Easier than manual Excel editing"
- [ ] Time savings: 30min → 5min for message setup

---

## Related Docs
- [Design System](../design-system.md) — For UI components
- [Security Patterns](../../CLAUDE.md#security_patterns) — File upload validation
- [Pipeline Architecture](../../CLAUDE.md#pipeline_architecture) — Where MessageProcessor fits

---

## Reality Check & Prioritization

**Complexity Assessment:**
This is a substantial feature with multiple moving parts:
- Message upload/storage
- Matching logic
- Prompt modifications
- UI changes
- Testing on real datasets

**Recommendation:**
- **Phase 0** is critical — understand current failure modes first
- **Phase 1** is worth doing (graceful degradation, don't block users)
- **Phases 2-4** are "nice to have" but not urgent

**Alternative approach for immediate launch:**
- Remove message testing from current UI, or mark as "Coming Soon"
- Not every project is message testing
- Focus on getting core crosstab functionality stable
- Revisit MaxDiff support in dedicated sprint later

**If we proceed:**
- Expect 2-3 days for Phase 0 + Phase 1
- Another 3-5 days for Phases 2-4
- Testing on real datasets takes time
- User feedback loop will reveal edge cases

---

## Notes
- This is a v1 design. We'll iterate based on real-world usage.
- Focus on robustness over cleverness — simple, deterministic matching beats complex ML.
- Make the upload format clear and strict — if user follows it, matching should be 100% reliable.
- Position-based matching is actually a reasonable default (that's how simulators work).
