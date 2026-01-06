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

## Banner Generation

Agent-created banner plans when none provided.

**Concept**: Given survey document + data map, an agent could identify the most important cuts:
1. Parse survey to find key demographic/screening questions
2. Identify common segmentation variables (specialty, role, region, etc.)
3. Propose banner groups with suggested cuts
4. Human reviews and adjusts before proceeding

**Use case**: Partners who don't have a banner plan yet, or want AI suggestions for what cuts to include.

**Complexity**: Medium - requires survey understanding + domain knowledge about what makes useful crosstab cuts.

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

## Polish

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

*Created: January 6, 2026*
*Status: Tracking only - none blocking current work*
