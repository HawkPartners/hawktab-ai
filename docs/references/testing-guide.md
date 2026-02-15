# Crosstab AI — Testing Guide

How the automated test suite works, what it covers, and how to use it.

---

## Quick Start

```bash
# Run all tests
npx vitest run

# Run tests in watch mode (re-runs on file changes)
npx vitest

# Run a specific test file
npx vitest run src/lib/validation/__tests__/WeightDetector.test.ts

# Run tests matching a pattern
npx vitest run -t "sortTables"

# Quality check (run before commits)
npm run lint && npx tsc --noEmit
```

---

## Test Philosophy

Tests are organized into tiers based on cost and speed:

| Tier | Type | AI Cost | Speed | Coverage |
|------|------|---------|-------|----------|
| **Tier 1** | Unit tests (deterministic modules) | Zero | < 1 second | All deterministic processors, validators, formatters |
| **Tier 2** | Integration tests (pipeline segments) | Zero | Seconds | Module-to-module data flow (planned) |
| **Tier 3** | Agent tests (AI calls) | Real API cost | Minutes | Agent output quality (manual/scripted) |

The current automated suite is **Tier 1 only** — all tests are deterministic, require no API keys, and complete in under a second.

---

## Test Structure

```
src/
├── lib/
│   ├── __tests__/
│   │   ├── fixtures.ts                    # Shared factory functions
│   │   └── retryWithPolicyHandling.test.ts
│   ├── validation/__tests__/
│   │   ├── WeightDetector.test.ts         # Weight variable detection
│   │   ├── LoopDetector.test.ts           # Loop pattern recognition
│   │   ├── LoopCollapser.test.ts          # Loop data stacking
│   │   ├── LoopContextResolver.test.ts    # Loop context enrichment
│   │   └── FillRateValidator.test.ts      # Fill rate pattern detection
│   ├── r/__tests__/
│   │   ├── sanitizeRExpression.test.ts    # R expression security validation
│   │   ├── RScriptGeneratorV2.test.ts     # R script generation + validation
│   │   └── transformStackedCuts.test.ts   # Loop cut transformation
│   ├── tables/__tests__/
│   │   ├── sortTables.test.ts             # Table ordering logic
│   │   ├── TablePostProcessor.test.ts     # Post-verification formatting rules
│   │   ├── TableGenerator.test.ts         # Deterministic table generation
│   │   └── GridAutoSplitter.test.ts       # Grid table splitting
│   ├── filters/__tests__/
│   │   └── FilterApplicator.test.ts       # Skip logic filter application
│   ├── processors/__tests__/
│   │   └── DataMapProcessor.test.ts       # Variable enrichment pipeline
│   └── excel/__tests__/
│       └── ExcelFormatter.test.ts         # Excel workbook generation
```

---

## Shared Test Fixtures

`src/lib/__tests__/fixtures.ts` provides factory functions that produce valid objects with sensible defaults. Tests override only the fields they care about:

```typescript
import { makeTable, makeRow, makeDataFileStats } from '../../__tests__/fixtures';

// Create a table with custom fields — everything else gets defaults
const table = makeTable({
  tableId: 'q1',
  questionId: 'Q1',
  rows: [
    makeRow({ variable: 'Q1', filterValue: '1', label: 'Yes' }),
    makeRow({ variable: 'Q1', filterValue: '2', label: 'No' }),
  ],
});
```

**Available factories:**

| Factory | Type | Purpose |
|---------|------|---------|
| `makeRow(overrides?)` | `ExtendedTableRow` | Table row with variable, label, filterValue |
| `makeTable(overrides?)` | `ExtendedTableDefinition` | Full table definition with all fields |
| `makeSavMeta(overrides?)` | `SavVariableMetadata` | SPSS variable metadata |
| `makeDataFileStats(columns, metadata?)` | `DataFileStats` | Dataset stats for WeightDetector |
| `makeQuestionItem(overrides?)` | `QuestionItem` | Single variable for TableGenerator |
| `makeQuestionGroup(overrides?)` | `QuestionGroup` | Grouped variables for TableGenerator |
| `makeRawVariable(overrides?)` | `RawDataMapVariable` | Raw variable for DataMapProcessor |

---

## Module Coverage

### WeightDetector (25 tests)
Tests the name-gate + confirmation-scoring approach for detecting weight variables in .sav files.

- **Name gate acceptance:** `wt`, `weight`, `wgt`, `w_total`, `rim_weight`, `W`, etc.
- **Name gate rejection:** `gender`, `Q3`, `wait` (contains "wait", not "weight")
- **Label not checked:** Column Q5 with label "body weight" is correctly rejected
- **Scoring signals:** numeric class, mean near 1.0, positive values, plausible range
- **Structural suffix penalty:** `wt_r1` gets -0.30 penalty
- **Edge cases:** text columns skipped, null mean skipped, A-format skipped

### sanitizeRExpression (47 tests)
Security-critical validation for user-provided R expressions before they reach R execution.

- **Valid expressions:** Standard R comparison, logical, and arithmetic operators
- **Dangerous functions:** `system()`, `eval()`, `source()`, `library()`, `file.remove()`, etc.
- **Injection vectors:** backtick-quoted function calls, shell metacharacters (`$(...)`, `; rm`)
- **Character allowlist:** Permits operators, rejects `@`, `#`, `{`, `}`
- **Case insensitivity:** `SYSTEM("cmd")` caught same as `system("cmd")`

### sortTables (12 tests)
Table ordering logic for Excel output.

- **Category ordering:** Screeners (S) before main (A/B/C) before other
- **Numeric ordering:** A2 before A10 (not lexicographic)
- **Suffix ordering:** S2 < S2a < S2b < S2dk
- **Loop iteration:** A7 < A7_1 < A7_2
- **Derived placement:** Base table before T2B/binned derivatives
- **Immutability:** Original array not mutated

### TablePostProcessor (22 tests)
Eight deterministic formatting rules applied after VerificationAgent.

| Rule | Action | Tested |
|------|--------|--------|
| 1. Empty fields | Replace null/undefined with defaults | Normalization + no-op |
| 2. Section cleanup | Strip "SECTION X:" prefix, force caps | Pattern stripping + already-clean |
| 3. Base text validation | Warn on question descriptions | Suspicious + proper text |
| 3b. Base text backfill | Fill from additionalFilter | Empty + already-set |
| 4. Trivial NETs | Remove NETs covering all values | Trivial + non-trivial |
| 5. Source ID casing | `[s1]` to `[S1]` in userNote | Lowercase + already-upper |
| 6. Duplicate rows | Warn on duplicate variable+filterValue | Duplicate + distinct |
| 7. Orphan indent | Reset indent when no NET parent | Orphan + valid parent |
| 8. Routing stripped | Remove (TERMINATE), (CONTINUE TO S4) | Routing + clean labels |

### FilterApplicator (8 tests)
Deterministic application of skip logic filters to table definitions.

- **Pass-through:** No matching filters, tables unchanged
- **Table-level filter:** Sets additionalFilter + baseText
- **Row-level split:** One table becomes N tables with correct row subsets
- **Invalid variables:** Flags for review instead of crashing
- **Provenance:** splitFromTableId set on split tables

### TableGenerator (9 tests)
Deterministic table generation from grouped datamap variables.

- **Frequency tables:** Categorical variables get one row per allowed value
- **Mean rows tables:** Numeric ranges get one row per variable
- **Binary flags:** filterValue = "1"
- **Scale labels:** Preferred over generic labels
- **Grid detection:** `r[N]c[N]` pattern detected as grid dimensions
- **Table ID sanitization:** Special characters removed, lowercased

### RScriptGeneratorV2 (14 tests)
R script generation and table validation before execution.

- **Table validation:** Correct frequency/mean_rows acceptance, empty rows rejection
- **Header rows:** `_HEADER_` filterValue allowed on frequency tables
- **Script structure:** Required library imports, data loading, JSON output
- **Cut definitions:** R expressions and stat letters in output
- **Weight handling:** Dual-pass loop when weightVariable provided
- **Significance thresholds:** Both values appear in script config
- **Invalid table handling:** Skipped with report, not in output

### DataMapProcessor (19 tests)
Variable enrichment pipeline from raw .sav metadata.

- **Parent inference:** `S8r1` to `S8`, `A3DKr99c1` to `A3DK`, `C3_1r15` to `C3_1`
- **Parent context:** Sub-variables get parent description as context
- **Type normalization:** admin, binary_flag, categorical_select, text_open
- **Admin rescue:** h-prefixed columns with value labels are not treated as admin
- **Scale label parsing:** `1=Strongly Agree,2=Agree` parsed correctly
- **Dependency detection:** "Of those..." pattern links to previous question
- **Dual output:** Verbose (all fields) vs agent (essential fields only)

### ExcelFormatter (8 tests)
Excel workbook generation from calculated tables.json.

- **Workbook validity:** Produces parseable ExcelJS workbook
- **Buffer output:** Non-empty Buffer for HTTP responses
- **Sheet structure:** Table of Contents + Crosstabs (default)
- **Display modes:** Single sheet (frequency/counts) or dual sheet (both)
- **Excluded tables:** Separate sheet, hideable via config
- **Weighted metadata:** Accepted without error
- **Empty tables:** Graceful handling with Table of Contents only

---

## UI Batch Load Testing

A dev-mode feature for testing the system under realistic concurrent load. It launches N projects simultaneously through the real `/api/projects/launch` endpoint, so it exercises the exact same code path real users hit — including FormData parsing, file validation, rate limiting, pLimit(3) pipeline concurrency, Sentry, PostHog, and R execution.

### Setup (one-time)

Before using the load test UI, you must upload your local test datasets to R2:

```bash
# Preview what would be uploaded (no changes made)
npx tsx scripts/upload-test-datasets-to-r2.ts --dry-run

# Upload datasets to R2 under dev-test/ prefix
npx tsx scripts/upload-test-datasets-to-r2.ts
```

The script scans every folder in `data/`, identifies ready datasets (`.sav` + survey document), and uploads each bundle to R2 with a manifest. Re-run whenever you add new datasets locally.

**Requirements:** R2 credentials in `.env.local` (`R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET_NAME`).

### Using the Load Test UI

1. Start the dev server: `npm run dev`
2. Navigate to `/dev/load-test` (requires admin role)
3. Select datasets from the manifest (fetched from R2)
4. Configure concurrency (1, 3, 5, 10, or 15 simultaneous launches)
5. Set a name prefix (defaults to "Load Test {M}/{D}")
6. Click Launch

Each dataset gets its own project named `{prefix} — {dataset-name}`. Projects appear on the real dashboard with real-time status. The monitoring panel on the load test page shows running/review/completed/failed counts, an overall progress bar, and elapsed time.

### What it tests

| Aspect | How it's tested |
|--------|----------------|
| Pipeline concurrency | `pLimit(3)` queues excess launches — only 3 R processes run at once |
| Rate limiting | Rapid-fire POSTs to the real launch endpoint (50 req/10min in dev) |
| R process memory | Multiple concurrent R processes sharing container memory |
| Convex write throughput | Many concurrent status mutations from parallel pipelines |
| HITL review under contention | Projects pause at `pending_review` — work through them manually |
| Dashboard performance | Many active runs visible simultaneously |
| Abort/cancel | Each pipeline has its own AbortController, isolated from others |

### Cleanup

The "Cleanup" button soft-deletes all projects matching the name prefix (sets `isDeleted: true`). It also removes associated runs and does best-effort R2 file cleanup. Requires typing the prefix to confirm.

### Key details

- **Dev-only.** The page and all API routes return 404 in production (`NODE_ENV === 'production'`).
- **No auto-approve.** Projects that reach `pending_review` stay there. This tests the real HITL flow.
- **Real API costs.** Each launched pipeline makes real AI agent calls. A batch of 15 datasets at ~$2-4 each is $30-60.
- **Wall-clock time.** 15 datasets at pLimit(3) means ~5 batches of 3, roughly 3-4 hours to complete.

### Files

| File | Purpose |
|------|---------|
| `scripts/upload-test-datasets-to-r2.ts` | One-time setup: uploads local datasets to R2 |
| `src/lib/loadTest/types.ts` | Shared types and constants |
| `src/lib/loadTest/helpers.ts` | Content-type mapping for R2 uploads |
| `src/app/api/dev/load-test/datasets/route.ts` | GET: returns dataset manifest from R2 |
| `src/app/api/dev/load-test/launch/route.ts` | POST: orchestrates launches via real endpoint |
| `src/app/api/dev/load-test/cleanup/route.ts` | POST: soft-deletes load test projects |
| `src/app/(product)/dev/load-test/page.tsx` | UI: dataset selector, config, monitoring |

---

## Writing New Tests

### Convention

1. **Test file location:** `src/lib/<module>/__tests__/<Module>.test.ts`
2. **Use shared fixtures:** Import from `../../__tests__/fixtures.ts`
3. **Test real logic:** Exercise actual code paths, not just smoke tests
4. **One assertion focus:** Each `it()` block tests one specific behavior
5. **No AI calls:** Tier 1 tests must be deterministic and free

### Template

```typescript
import { describe, it, expect } from 'vitest';
import { myFunction } from '../MyModule';
import { makeTable, makeRow } from '../../__tests__/fixtures';

describe('MyModule', () => {
  it('does the expected thing', () => {
    const input = makeTable({ /* only override what matters */ });
    const result = myFunction(input);
    expect(result.field).toBe('expected');
  });

  it('handles edge case', () => {
    const result = myFunction(makeTable({ rows: [] }));
    expect(result.errors).toHaveLength(1);
  });
});
```

### Mocking External Dependencies

When a module imports something that depends on environment variables or external services, mock it:

```typescript
import { vi } from 'vitest';

vi.mock('../../review', () => ({
  shouldFlagForReview: () => false,
  getReviewThresholds: () => ({ filter: 0.7 }),
}));
```

---

## CI Integration

Tests should be run before every commit:

```bash
npm run lint && npx tsc --noEmit && npx vitest run
```

Current performance: **256 tests in ~700ms** across 16 test files.
