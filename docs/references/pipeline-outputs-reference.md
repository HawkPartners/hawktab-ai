# Pipeline Outputs Reference

**Last updated:** 2026-02-15

This document defines what files SHOULD be written to the output directory on every pipeline run for complete debugging capability.

---

## 📁 Required Output Structure

```
outputs/{dataset}/pipeline-{timestamp}/
├── inputs/                          # Original uploaded files
│   ├── data-file.sav
│   ├── survey-document.{pdf,docx}
│   └── banner-plan.{pdf,docx}      # (if upload mode)
│
├── banner/                          # BannerAgent outputs
│   ├── scratchpad-banner-*.md      ⭐ AI reasoning trace
│   └── banner-generated.json       # (if auto-generate mode)
│
├── crosstab/                        # CrosstabAgent outputs
│   ├── scratchpad-crosstab-*.md    ⭐ AI reasoning trace
│   └── crosstab-output-*.json      # Validated cut expressions
│
├── skiplogic/                       # SkipLogicAgent outputs
│   ├── scratchpad-skiplogic-*.md   ⭐ AI reasoning trace
│   └── skip-rules-*.json           # Extracted skip logic
│
├── filtertranslator/                # FilterTranslatorAgent outputs
│   ├── scratchpad-filtertranslator-*.md ⭐ AI reasoning trace
│   └── filter-expressions-*.json   # Translated R filters
│
├── verification/                    # VerificationAgent outputs
│   ├── scratchpad-verification-*.md ⭐ AI reasoning trace
│   ├── verification-output-raw.json
│   └── verified-table-output-*.json
│
├── loop-policy/                     # Loop handling outputs
│   ├── deterministic-resolver.json  ✅ Currently written
│   ├── loop-semantics-policy.json   ❌ MISSING in pipelineOrchestrator
│   └── scratchpad-loop-semantics.md ⭐ AI reasoning trace
│
├── tablegenerator/                  # TableGenerator outputs
│   └── tables-generated-*.json     # Before verification
│
├── postpass/                        # TablePostProcessor outputs
│   └── postpass-report.json        ⭐ What was fixed
│
├── validation/                      # R validation outputs
│   └── validation-execution.log    # R validation details
│
├── r/                               # R script
│   ├── master.R                    ✅ Currently uploaded to R2
│   └── static-validation-report.json # (if validation issues)
│
├── results/                         # Final outputs
│   ├── crosstabs.xlsx              ✅ Currently uploaded to R2
│   ├── crosstabs-weighted.xlsx     ✅ Currently uploaded to R2
│   ├── crosstabs-unweighted.xlsx   ✅ Currently uploaded to R2
│   ├── crosstabs-counts.xlsx       ✅ Currently uploaded to R2
│   ├── tables.json                 ✅ Currently uploaded to R2
│   ├── tables-weighted.json        ✅ Currently uploaded to R2
│   └── tables-unweighted.json      ✅ Currently uploaded to R2
│
├── logs/                            # Consolidated logs
│   └── pipeline.log                ✅ Currently uploaded to R2
│
├── errors/                          # Error tracking
│   └── errors.ndjson               # Structured error log
│
├── pipeline-summary.json            ✅ Currently uploaded to R2
├── validation-execution.log         # Top-level validation log
└── {dataset}-verbose-*.json         # DataMap verbose output
```

---

## 🐛 Current Inconsistencies

### ❌ **Missing: loop-semantics-policy.json**
**Issue:** Generated in `pipelineOrchestrator.ts` but never written to disk
**Impact:** Can't debug loop classification decisions
**Fix:** Add write after line 1511

```typescript
// After: console.log(`LoopSemantics: ${loopSemanticsPolicy.bannerGroups.length} groups classified`);
// ADD:
const loopPolicyDir = path.join(outputDir, 'loop-policy');
await fs.mkdir(loopPolicyDir, { recursive: true });
await fs.writeFile(
  path.join(loopPolicyDir, 'loop-semantics-policy.json'),
  JSON.stringify(loopSemanticsPolicy, null, 2),
  'utf-8'
);
```

---

### ❌ **Conditional: loop-policy/ folder**
**Issue:** Only created if loops detected
**Why:** Should always exist for consistency (empty if no loops)
**Fix:** Create folder unconditionally

---

### ⚠️ **Inconsistent: Scratchpad filenames**
**Issue:** Some use timestamps, some don't
**Examples:**
- `scratchpad-banner-generate.md` (no timestamp)
- `scratchpad-verification-2026-02-09T08-53-57-128Z.md` (has timestamp)

**Why inconsistent:** Different agents use different naming patterns
**Impact:** Hard to glob for `scratchpad-*.md` reliably
**Fix:** Standardize to always include timestamps

---

### ⚠️ **Conditional: Static validation report**
**Issue:** `r/static-validation-report.json` only written if validation issues found
**Why:** Should always exist (empty array if no issues)
**Fix:** Write even when empty

---

## 📤 What's Currently Uploaded to R2

**From `OUTPUT_FILES_TO_UPLOAD` in R2FileManager.ts:**

```typescript
[
  'results/crosstabs.xlsx',
  'results/crosstabs-weighted.xlsx',
  'results/crosstabs-unweighted.xlsx',
  'results/crosstabs-counts.xlsx',
  'results/crosstabs-weighted-counts.xlsx',
  'results/tables.json',
  'results/tables-weighted.json',
  'results/tables-unweighted.json',
  'r/master.R',
  'pipeline-summary.json',
  'logs/pipeline.log',
]
```

**Missing from R2 (but exist locally):**
- All agent scratchpads (reasoning traces)
- All detailed agent outputs
- Loop policy files
- Postpass reports
- Validation logs
- Error logs

---

## 🎯 Phase 0: Fix Inconsistencies

### **Priority 1: Write loop-semantics-policy.json**
Always write this file in `pipelineOrchestrator.ts` after generating the policy.

### **Priority 2: Standardize scratchpad naming**
All scratchpads should use format: `scratchpad-{agentName}-{timestamp}.md`

### **Priority 3: Create loop-policy/ unconditionally**
Even if no loops, create the folder and write empty policy.

### **Priority 4: Write static-validation-report.json unconditionally**
Even if no issues, write `{ invalidTables: 0, warnings: [] }`.

---

## 📦 Phase 1: Upload Everything

After fixing inconsistencies, add to `OUTPUT_FILES_TO_UPLOAD`:

```typescript
const DEBUGGING_FILES_TO_UPLOAD = [
  // Agent scratchpads (reasoning traces)
  'banner/scratchpad-*.md',
  'crosstab/scratchpad-*.md',
  'skiplogic/scratchpad-*.md',
  'filtertranslator/scratchpad-*.md',
  'verification/scratchpad-*.md',
  'loop-policy/scratchpad-*.md',

  // Agent outputs
  'banner/banner-generated.json',
  'crosstab/crosstab-output-*.json',
  'skiplogic/skip-rules-*.json',
  'filtertranslator/filter-expressions-*.json',
  'verification/verification-output-raw.json',
  'verification/verified-table-output-*.json',
  'tablegenerator/tables-generated-*.json',

  // Loop handling
  'loop-policy/deterministic-resolver.json',
  'loop-policy/loop-semantics-policy.json',

  // Post-processing
  'postpass/postpass-report.json',

  // Validation
  'validation/validation-execution.log',
  'validation-execution.log',
  'r/static-validation-report.json',

  // Errors
  'errors/errors.ndjson',

  // DataMap
  '*-verbose-*.json',
  '*-crosstab-agent-*.json',
];
```

---

## 💾 Storage Impact

| Category | Files | Avg Size | Per Run | 1000 Runs/Year |
|----------|-------|----------|---------|----------------|
| Excel (current) | 5 files | 5 MB | $0.015 | $15 |
| Logs (current) | 2 files | 0.5 MB | $0.001 | $1 |
| **Scratchpads** | ~7 files | 0.5 MB | $0.001 | $1 |
| **Agent outputs** | ~10 files | 1 MB | $0.003 | $3 |
| **Loop/validation** | ~5 files | 0.2 MB | $0.0006 | $0.60 |
| **Total NEW** | ~22 files | ~1.7 MB | ~$0.005 | ~$5 |

**Cost increase:** ~$5/year for complete debugging capability.

---

## 🚀 Recommendation

1. **Fix loop-semantics-policy.json** (5 minutes)
2. **Audit other missing files** (check if they're written)
3. **Standardize naming** (quick refactor)
4. **Then upload everything to R2** (update OUTPUT_FILES_TO_UPLOAD)

---

## Notes

- **Scratchpads** are the most valuable for debugging AI behavior
- **Postpass reports** show what deterministic fixes were applied
- **Loop policy** is critical for understanding iteration-linked variable handling
- All files should be written **unconditionally** (empty if not applicable)
