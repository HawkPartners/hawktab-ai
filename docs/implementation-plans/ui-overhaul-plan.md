# UI Overhaul Implementation Plan

## Overview

This document architects the transformation of HawkTab AI's web application from its current state (a functional but minimal upload interface) into a production-grade, cloud-ready product that external parties like Antares can use. It covers the complete journey from today's codebase to Phase 3.1 of the product roadmap, designed to be implemented incrementally.

**Current State**: A single-page Next.js app with file upload, polling-based job tracking, basic HITL review, and a slide-out pipeline history. No route groups, no auth, no persistent job store, no storage abstraction. All Phase 2 pipeline features (stat testing, weights, themes, AI banner, display modes, loop handling) are implemented in the CLI/pipeline but have no UI exposure.

**Target State**: A multi-page web application with marketing pages, an enterprise-grade project management experience, full exposure of all pipeline configuration options, cloud-ready abstractions, and a foundation for auth and multi-tenancy.

**Philosophy**: Each phase delivers a shippable improvement, but we will **design for the hosted reality from day one** (long-running background jobs, secure storage, org-scoped data). “Local-first” is a development strategy, not a product constraint. The abstraction layers we build in early phases make cloud migration a configuration swap, not a rewrite.

*Created: February 9, 2026*

---

## What’s Missing Today (for Antares to actually use it)

The plan correctly focuses on local UI structure, but **external usability requires a few non-negotiables** that are easy to accidentally defer because they aren’t “UI.”

### Non-Negotiables for an External Pilot

These aren’t polish; they’re the minimum bar for someone outside Hawk to trust the system.

1. **Hosted execution model**: Production cannot run the pipeline inside a request/response handler. The UI must assume “enqueue job → worker runs → UI observes status.”
2. **Secure file handling**:
   - Upload/download must be auth-scoped to org/project/run.
   - Cloud uploads should support **direct-to-object-store** (browser → R2/S3 via signed URLs) to avoid app-server timeouts and memory limits.
3. **Durable run history + determinism**:
   - Users must be able to come back later and download artifacts / complete HITL.
   - Confirmed decisions (especially banner cut mappings) should be **persisted and reused** on re-runs to avoid “it worked last time but not this time.”
4. **Data lifecycle**: Clear retention + deletion semantics (manual delete, and optionally auto-expiration).
5. **Supportability**: A “download debug bundle” / “share support link” path so failures are actionable without screen-sharing.

### Core Workflows to Design Around

The app should feel optimized for these real patterns (including what Antares described):

- **Interim → Final**: Set up project once, run interim datasets during field, then re-run with final data quickly (same structure, fast validation).
- **HITL as a checkpoint**: Review can happen asynchronously; a run can safely pause and be resumed later.
- **Re-run with intent**: Re-run should mean “same cuts, same tables, new data / new settings,” not “roll the dice again.”

## Architecture Audit: Current State

### What Exists

| Component | Location | State |
|-----------|----------|-------|
| Home page (upload + tracking) | `src/app/page.tsx` | Working but monolithic (547 lines) |
| Pipeline detail page | `src/app/pipelines/[pipelineId]/page.tsx` | Working (718 lines) |
| HITL review page | `src/app/pipelines/[pipelineId]/review/page.tsx` | Working (593 lines) |
| Pipeline history (slide-out) | `src/components/PipelineHistory.tsx` | Working (100 lines) |
| Root layout | `src/app/layout.tsx` | Minimal — header + theme toggle only |
| Job store | `src/lib/jobStore.ts` | In-memory `Map`, not persisted |
| File storage | `src/lib/storage.ts` | Hardcoded to `/tmp/hawktab-ai/` |
| Main API route | `src/app/api/process-crosstab/route.ts` | Working but 1,312 lines — monolithic |
| Pipeline listing API | `src/app/api/pipelines/route.ts` | Working — filesystem scan |
| 16 shadcn/ui primitives | `src/components/ui/` | Available (button, card, badge, dialog, sheet, etc.) |

### What's Missing

| Need | Gap |
|------|-----|
| Route groups | No `(marketing)/` or `(product)/` separation |
| Dashboard | No project list, no org context |
| New project wizard | Upload is a flat form, no intake questions |
| Pipeline config UI | Display mode, stat testing, themes, weights — all CLI-only |
| Storage abstraction | `StorageProvider` interface doesn't exist |
| Job persistence | `JobStore` interface doesn't exist — jobs lost on restart |
| Real-time progress | Polling at 1.5s intervals (works, but not scalable) |
| Navigation | No sidebar, no breadcrumbs, no app shell |
| Marketing pages | No landing page, no value proposition |
| Auth foundation | No login, no org structure, no roles |

### Pipeline Features Needing UI Exposure

These are all **implemented and working** in the pipeline (Phase 2 complete) but only accessible via CLI flags. The UI must surface them.

| Feature | CLI Access | UI Surface Needed |
|---------|-----------|-------------------|
| Display mode | `--display=frequency\|counts\|both` | Radio/select in project config |
| Separate workbooks | `--separate-workbooks` | Toggle (visible when display=both) |
| Color theme | `--theme=classic\|coastal\|...` | Theme picker with previews |
| Stat testing thresholds | `STAT_THRESHOLDS` env var | Numeric input(s) |
| Stat testing methods | `STAT_PROPORTION_TEST`, `STAT_MEAN_TEST` | Select (advanced section) |
| Min base size | `STAT_MIN_BASE` env var | Numeric input |
| Weight variable | `--weight=VAR` / `--no-weight` | Select from detected candidates |
| Loop stat testing mode | `--loop-stat-testing=suppress\|complement` | Toggle (visible when loops detected) |
| AI-generated banner | `--objectives`, `--cuts`, `--project-type` | Text areas + select in banner step |
| Stop after verification | `--stop-after-verification` | Toggle (advanced section) |

---

## Phase Plan

### Phase A: Foundation & App Shell
*Restructure the app, build the skeleton, establish patterns.*

### Phase D: Abstractions & Cloud Readiness (Pulled Forward)
*Introduce `StorageProvider` / `JobStore` / `ProjectStore` seams early so Phase B/C are built on persistent primitives and don’t need a rewrite for cloud.*

### Phase B: New Project Experience
*Replace the flat upload form with a guided wizard that exposes all pipeline config.*

### Phase C: Project Management & Results
*Dashboard, project list, enhanced results page, pipeline progress.*

### Phase F: Auth & Multi-Tenancy Foundation
*Org-scoped data model + middleware scaffolding now; WorkOS enforcement later.*

### Phase E: Marketing & Polish
*Landing page, visual identity, onboarding. Can run in parallel once product routes exist.*

Each phase is described in detail below.

---

## Phase A: Foundation & App Shell

**Goal**: Establish the route structure, app shell, and shared layout patterns that all subsequent phases build on. No new features — just restructuring.

### A.1 Route Group Structure

Reorganize from the current flat structure to Next.js route groups:

```
src/app/
├── (marketing)/
│   ├── layout.tsx              # Marketing layout (no sidebar, minimal chrome)
│   └── page.tsx                # Landing page (placeholder for Phase E)
│
├── (product)/
│   ├── layout.tsx              # Product layout (sidebar + header + org context)
│   ├── dashboard/
│   │   └── page.tsx            # Project list (placeholder for Phase C)
│   ├── projects/
│   │   ├── new/
│   │   │   └── page.tsx        # New project wizard (Phase B)
│   │   └── [projectId]/
│   │       ├── page.tsx        # Project detail / results
│   │       └── review/
│   │           └── page.tsx    # HITL review
│   └── settings/
│       └── page.tsx            # User/org settings (placeholder)
│
├── api/                        # API routes (unchanged location)
└── layout.tsx                  # Root layout (theme, fonts, providers)
```

**Migration note**: The current `/pipelines/[pipelineId]` routes become `/projects/[projectId]`. Add a redirect from the old path for any bookmarked URLs. Internally, "pipeline" stays as the execution concept; "project" is the user-facing concept that wraps one or more pipeline runs.

### A.2 Product Layout (App Shell)

The `(product)/layout.tsx` provides the consistent chrome for all logged-in pages:

```
┌──────────────────────────────────────────────────────┐
│  [Logo] HawkTab AI          [Org Selector] [Avatar]  │
├────────────┬─────────────────────────────────────────┤
│            │                                          │
│  Dashboard │  <page content>                          │
│  Projects  │                                          │
│  ─────────│                                          │
│  Recent:   │                                          │
│  • Proj A  │                                          │
│  • Proj B  │                                          │
│  • Proj C  │                                          │
│            │                                          │
│  ─────────│                                          │
│  Settings  │                                          │
│            │                                          │
└────────────┴─────────────────────────────────────────┘
```

**Components to build**:
- `AppSidebar` — Collapsible sidebar with navigation + recent projects
- `AppHeader` — Logo, org selector (placeholder until auth), user menu
- `Breadcrumbs` — Context breadcrumb bar below header

**Design**: Use shadcn/ui `Sidebar` component (already available via Radix). The sidebar collapses to icons on narrow viewports.

### A.3 Shared State & Context Providers

Wrap the product layout with providers that subsequent phases need:

- **`ProjectProvider`** — Currently active project context (replaces localStorage `ACTIVE_JOB_KEY` / `ACTIVE_PIPELINE_KEY` pattern)
- **`PipelineStatusProvider`** — Polling/subscription for active job status (extracted from the current `page.tsx` polling logic)

These are React contexts initially backed by `useState` + localStorage. Phase D replaces the backing store with persistent abstractions.

### A.4 Clean Up Current Monoliths

Before building new features, break apart the two largest files:

**`src/app/api/process-crosstab/route.ts` (1,312 lines)** → Split into:
- `route.ts` — HTTP handler (request parsing, response formatting)
- `pipelineOrchestrator.ts` — Pipeline execution coordination
- `hitlManager.ts` — HITL pause/resume logic
- `fileHandler.ts` — File upload processing and validation

**`src/app/page.tsx` (547 lines)** → Split into:
- Upload form component
- Job status tracker component
- Loop detection hook (already partially extracted)

This isn't feature work, but it prevents future phases from editing thousand-line files.

### A.5 Deliverables

| Deliverable | Description |
|-------------|-------------|
| Route groups work | Marketing and product routes load correctly |
| App shell renders | Sidebar, header, breadcrumbs visible on all product pages |
| Existing pages accessible | Pipeline detail and HITL review work at new URLs |
| API route refactored | `process-crosstab` split into focused modules |
| No regressions | Current upload → process → review → download flow works |

---

## Phase B: New Project Experience

**Goal**: Replace the flat upload form with a multi-step wizard that captures all the context the pipeline needs — file uploads, project configuration, and intake questions. This is where every Phase 2 feature gets its UI surface.

### B.1 New Project Wizard Flow

The wizard lives at `(product)/projects/new/page.tsx` and uses a step-based layout:

```
Step 1: Upload Files  →  Step 2: Project Setup  →  Step 3: Configuration  →  Step 4: Review & Launch
```

Each step is a panel within a single page (not separate routes) using controlled state. Users can navigate back to previous steps.

### B.2 Step 1: Upload Files

**What changes from today**:
- Remove the separate "datamap" upload — `.sav` is the source of truth (datamap is extracted automatically)
- Clearly communicate which files are required vs optional
- Add helper text for each upload slot

| File | Required | Accepted Formats | Helper Text |
|------|----------|------------------|-------------|
| Data file (.sav) | Yes | `.sav` | "SPSS data file with qualified respondents only. Terminated/disqualified respondents should be filtered out before upload." |
| Survey document | Yes | PDF, DOCX | "The questionnaire document. Used for skip logic detection and table verification." |
| Banner plan | No | PDF, DOCX | "Your banner specification. If not provided, HawkTab will generate suggested cuts from your data." |

**On data file upload**, trigger:
1. Loop detection (existing `/api/loop-detect` endpoint) → show result badge
2. Weight detection (new lightweight endpoint or extend loop-detect) → populate weight candidates for Step 3

**Banner plan branching**: If no banner plan is uploaded, Step 2 activates the AI-generated banner flow.

### B.3 Step 2: Project Setup

Context capture that feeds into agent prompts. This consolidates the former Phase 1.5 (pre-flight) and 2.5 (upfront context) into a clean intake experience.

**Always shown**:
- **Project name** — Free text, auto-suggested from data file name
- **Project type** — Select: Standard, ATU, Segmentation, MaxDiff, Demand, Concept Test, Tracking
  - Feeds into `--project-type` pipeline option and agent prompt context

**Conditional questions** (shown based on project type selection):
- **Segmentation**: "Does your data file include segment assignments?" (Yes/No) → If No, show warning that segment banner cuts won't work
- **MaxDiff**: "Can you upload the message list?" (file upload) + "Does your data include anchored probability scores?" (Yes/No)
- **Conjoint/DCM**: "Can you upload choice task definitions?" (file upload)

**If no banner plan uploaded** (AI-generated banner flow):
- **Research objectives** — Text area: "What are you trying to learn from this study?" → feeds `--objectives`
- **Cut suggestions** — Text area: "Any specific variables or groups you'd like to cross-tabulate by?" → feeds `--cuts`
- Info callout: "HawkTab will propose 3-5 banner groups based on your data and objectives. You'll review and approve them before processing begins."

### B.4 Step 3: Configuration

All pipeline settings that the user can control, organized into clear sections.

**Output Settings** (always visible):
| Control | Type | Options | Default |
|---------|------|---------|---------|
| Display mode | Radio group | Percentages only / Counts only / Both | Percentages only |
| Separate workbooks | Toggle | On/Off | Off |
| | | *(visible when display mode = Both)* | |
| Color theme | Theme picker | 6 theme cards with color swatches | Classic |

**Statistical Testing** (collapsible section, default collapsed with "Using defaults" summary):
| Control | Type | Options | Default |
|---------|------|---------|---------|
| Confidence level(s) | Input(s) | Single or dual thresholds | 90% (0.10) |
| Min base size | Number input | 0+ | 0 (no minimum) |
| Proportion test | Select | Unpooled z-test / Pooled z-test | Unpooled z-test |
| Mean test | Select | Welch's t-test / Student's t-test | Welch's t-test |

**Weight Settings** (visible only when weight candidates detected):
| Control | Type | Options | Default |
|---------|------|---------|---------|
| Apply weighting | Toggle | On/Off | Off (with recommendation if detected) |
| Weight variable | Select | Detected candidates from .sav | First detected candidate |

**Loop Settings** (visible only when loops detected):
| Control | Type | Options | Default |
|---------|------|---------|---------|
| Loop stat testing | Radio | Suppress within-group / Complement testing | Suppress |

**Advanced** (collapsed by default):
| Control | Type | Options | Default |
|---------|------|---------|---------|
| Stop after verification | Toggle | On/Off | Off |

### B.5 Step 4: Review & Launch

Summary of all selections before kicking off the pipeline:

```
┌──────────────────────────────────────────────┐
│  Review Your Project                          │
│                                              │
│  📁 Files                                    │
│  Data: Cambridge Savings Bank W1.sav         │
│  Survey: CSB W1 Survey.pdf                   │
│  Banner: CSB Banner Plan.docx                │
│                                              │
│  📋 Project                                  │
│  Name: Cambridge Savings Bank W1             │
│  Type: Standard                              │
│                                              │
│  ⚙️ Output                                   │
│  Display: Percentages only                   │
│  Theme: Coastal                              │
│  Workbooks: Single                           │
│                                              │
│  📊 Statistics                               │
│  Confidence: 90%                             │
│  Methods: Unpooled z-test, Welch's t-test    │
│  Min base: None                              │
│                                              │
│  [Launch Pipeline]                           │
└──────────────────────────────────────────────┘
```

Clicking "Launch Pipeline" calls the process-crosstab API with all configuration options as FormData fields (extending the current API to accept config parameters alongside files).

### B.6 API Changes

Extend `POST /api/process-crosstab` to accept configuration from FormData:

| FormData Field | Type | Maps To |
|----------------|------|---------|
| `displayMode` | string | `PipelineOptions.display` |
| `separateWorkbooks` | boolean | `PipelineOptions.separateWorkbooks` |
| `theme` | string | `PipelineOptions.theme` |
| `statThresholds` | string | `PipelineOptions.statThresholds` |
| `statMinBase` | number | `PipelineOptions.statMinBase` |
| `statProportionTest` | string | `PipelineOptions.statProportionTest` |
| `statMeanTest` | string | `PipelineOptions.statMeanTest` |
| `weightVariable` | string | `PipelineOptions.weight` |
| `loopStatTesting` | string | `PipelineOptions.loopStatTesting` |
| `projectType` | string | `PipelineOptions.projectType` |
| `objectives` | string | `PipelineOptions.objectives` |
| `cutSuggestions` | string | `PipelineOptions.cuts` |
| `projectName` | string | `PipelineOptions.projectName` |
| `stopAfterVerification` | boolean | `PipelineOptions.stopAfterVerification` |

The API route parses these from FormData and passes them to `PipelineRunner.runPipeline()` — same function the CLI script calls. No pipeline logic changes needed.

### B.7 Deliverables

| Deliverable | Description |
|-------------|-------------|
| Multi-step wizard | 4-step flow: Upload → Setup → Config → Review |
| All Phase 2 features exposed | Display mode, themes, stat testing, weights, loop config, AI banner |
| Project type intake | Conditional questions per project type |
| AI banner flow | Objectives + cuts when no banner plan provided |
| Weight detection UI | Auto-detect + select in config step |
| API extended | process-crosstab accepts all config options |

---

## Phase C: Project Management & Results

**Goal**: Build the dashboard, enhance the results page, and create a proper project lifecycle experience.

### C.1 Dashboard (Project List)

`(product)/dashboard/page.tsx` — The landing page after login.

**Table columns**:
| Column | Source | Notes |
|--------|--------|-------|
| Project Name | `pipeline-summary.json → projectName` or dataset name | Link to project detail |
| Status | Pipeline status badge | `success`, `in_progress`, `pending_review`, `error`, `cancelled` |
| Tables | Count from summary | Quick quality indicator |
| Created | Timestamp | Relative time ("2 hours ago") |
| Duration | From summary | Human-readable |
| Actions | Download / View / Delete | Context menu |

**Features**:
- Sort by any column (default: newest first)
- Filter by status
- Search by project name
- Empty state with "Create New Project" CTA

**Data source**: The existing `GET /api/pipelines` endpoint returns this data. Extend it with `projectName` field from pipeline summary.

### C.2 Enhanced Project Detail Page

Rebuild `(product)/projects/[projectId]/page.tsx` with clearer sections:

**Status Bar** (top of page):
- Pipeline status badge with stage detail
- Duration / elapsed time
- Action buttons: Download Excel, View Review (if pending), Re-run, Cancel

**Pipeline Progress Timeline** (visible during processing):
```
✅ Files uploaded           →  Parsed .sav, extracted 847 variables
✅ Banner plan analyzed     →  5 groups, 23 cuts
✅ Crosstab mapping         →  2 groups flagged for review
⏳ Table generation         →  Building 156 tables...
⬜ Verification
⬜ R validation
⬜ Excel generation
```

This replaces the current toast-based polling with a visual timeline. The data is already available in the job status stages (`banner_complete`, `crosstab_complete`, etc.).

**Results Section** (after completion):
- Summary cards: Tables, Cuts, Banner Groups, Variables, Duration, Cost
- Download buttons: Excel workbook(s), R script, tables.json
- If weighted: separate download buttons for weighted/unweighted outputs
- If separate workbooks: separate download buttons for percentages/counts
- Configuration summary (what settings were used)
- **Table list (MVP, not full preview)**:
  - Render a searchable list of tables from `tables.json` (tableId, title, base text, excluded flag)
  - Allow include/exclude toggles and bulk actions (“exclude empties”, “include all”)
  - “Regenerate Excel” uses the modified table metadata without re-running agents (fast iteration)
  - This is the bridge toward the Long-term Vision “Interactive Table Review” without needing pixel-perfect HTML table rendering yet.

**Feedback Section** (existing, enhanced):
- Current feedback form (rating + notes + table IDs) stays
- Add: link to re-run with same config or modified config

### C.3 Pipeline Progress (Real-Time Updates)

Replace the current polling approach with a cleaner pattern:

**Current**: `setInterval` every 1.5s calling `GET /api/process-crosstab?jobId=...`

**Improved**:
- Keep polling for now (SSE or WebSockets would be premature before cloud)
- Increase interval to 3s for non-active tabs (use `document.hidden`)
- Add a `PipelineProgressProvider` context that manages the poll lifecycle
- Render progress as a timeline component, not toasts
- Show agent cost accumulation in real-time (metrics already collected)

**Important**: Don't over-engineer the real-time layer. Polling works fine locally. Phase D will create the abstraction that lets us swap to Convex subscriptions later.

### C.4 Project Re-Run

When a user wants to adjust settings and re-run:
- "Re-run" button on the project detail page
- Pre-populates the wizard (Step 3: Config) with the previous run's settings
- Allows swapping the data file to support **interim → final** runs while keeping the same project structure
- Creates a new pipeline run under the same project (versioned: `pipeline-<timestamp-2>`)
- Re-uses persisted, user-confirmed decisions where possible (e.g., locked banner cut mappings) so the re-run is deterministic
- Previous runs are accessible via a "Run History" expandable section

### C.5 Deliverables

| Deliverable | Description |
|-------------|-------------|
| Dashboard page | Sortable, filterable project list |
| Enhanced detail page | Timeline progress, summary cards, organized downloads |
| Progress timeline | Visual stage-by-stage tracking |
| Re-run support | Pre-populate config from previous run |
| Sidebar integration | Recent projects in sidebar, auto-update |

---

## Phase D: Abstractions & Cloud Readiness

**Goal**: Introduce the interface abstractions that make Phase 3.2 (Cloud Deployment) a configuration swap. Everything continues to work locally, but the seams are in place.

### D.0 Project/Run API Shape (to avoid cloud rewrites)

Even if the implementation is local-first, the **contract** should match the hosted world:

- **Project** = user-facing container (name, type, config, intake answers, files)
- **Run** = one execution of the pipeline (status, stages, artifacts, cost)

Recommended API shape (local implementations can still back these with filesystem JSON):

- `POST /api/projects` → create project record (no execution)
- `POST /api/projects/:projectId/files` → register uploads (local: multipart; cloud: signed upload URLs + “commit”)
- `POST /api/projects/:projectId/runs` → enqueue run using stored file keys + config snapshot
- `GET /api/runs/:runId` → status + progress + artifact manifest
- `POST /api/runs/:runId/cancel` → durable cancel request (runner checks cancel flag)

This prevents the UI from being tightly coupled to a single monolithic `process-crosstab` “upload+run” endpoint that will not survive cloud timeouts.

### D.1 StorageProvider Interface

```typescript
// src/lib/storage/StorageProvider.ts
export interface StorageProvider {
  // Upload a file, get back a storage key
  upload(key: string, data: Buffer | ReadableStream, metadata?: Record<string, string>): Promise<string>;

  // Optional: allow browser → storage direct uploads.
  // Local impl can return an `/api/uploads/*` URL; cloud impl should return a signed R2/S3 URL.
  getUploadUrl?(
    key: string,
    options?: { expiresIn?: number; contentType?: string; contentLength?: number }
  ): Promise<{ url: string; method: 'PUT' | 'POST'; headers: Record<string, string> }>;

  // Download a file by key
  download(key: string): Promise<Buffer>;

  // Get a URL for client-side download (local: /api route, cloud: signed URL)
  getDownloadUrl(key: string, expiresIn?: number): Promise<string>;

  // Check if a file exists
  exists(key: string): Promise<boolean>;

  // Delete a file
  delete(key: string): Promise<void>;

  // List files under a prefix
  list(prefix: string): Promise<string[]>;
}
```

**Local implementation**: `LocalStorageProvider` — reads/writes to `outputs/` directory (same as today, just abstracted).

**Cloud implementation** (Phase 3.2): `R2StorageProvider` — Cloudflare R2 with signed URLs.

**Key naming convention**: `{orgId}/{projectId}/{runId}/{filename}` — scoped for multi-tenancy from day one.

### D.2 JobStore Interface

```typescript
// src/lib/jobs/JobStore.ts
export interface JobRecord {
  jobId: string;
  projectId: string;
  status: JobStatus;
  stage: PipelineStage;
  progress: StageProgress[];
  config: PipelineOptions;
  result?: JobResult;
  error?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface JobStore {
  create(job: Omit<JobRecord, 'createdAt' | 'updatedAt'>): Promise<JobRecord>;
  get(jobId: string): Promise<JobRecord | null>;
  update(jobId: string, updates: Partial<JobRecord>): Promise<JobRecord>;
  listByProject(projectId: string): Promise<JobRecord[]>;
  listActive(): Promise<JobRecord[]>;

  // Cancellation must be durable (works across server/worker boundaries in cloud).
  requestCancel(jobId: string): Promise<void>;
  isCancelRequested(jobId: string): Promise<boolean>;
}
```

**Local implementation**: `FileJobStore` — JSON files in the pipeline output directory. Survives server restarts (unlike current in-memory Map). The local runner can still use an in-memory `AbortController` registry, but cancellation intent should also be persisted so the UI reflects it reliably.

**Cloud implementation** (Phase 3.2): `ConvexJobStore` — Convex database with real-time subscriptions.

### D.3 ProjectStore Interface

```typescript
// src/lib/projects/ProjectStore.ts
export interface ProjectRecord {
  projectId: string;
  orgId: string;
  name: string;
  projectType: ProjectType;
  config: ProjectConfig;
  intake: IntakeAnswers;
  runs: string[];  // jobIds
  createdAt: Date;
  updatedAt: Date;
}

export interface ProjectStore {
  create(project: Omit<ProjectRecord, 'createdAt' | 'updatedAt'>): Promise<ProjectRecord>;
  get(projectId: string): Promise<ProjectRecord | null>;
  update(projectId: string, updates: Partial<ProjectRecord>): Promise<ProjectRecord>;
  list(orgId: string, options?: { status?: string; limit?: number }): Promise<ProjectRecord[]>;
  delete(projectId: string): Promise<void>;
}
```

**Local implementation**: `FileProjectStore` — JSON index file + per-project folders.

**Cloud implementation**: `ConvexProjectStore`.

### D.4 Status Updates Abstraction

```typescript
// src/lib/realtime/StatusBroadcaster.ts
export interface StatusBroadcaster {
  // Send a status update for a job
  broadcast(jobId: string, update: StatusUpdate): void;

  // Subscribe to updates (returns unsubscribe function)
  subscribe(jobId: string, callback: (update: StatusUpdate) => void): () => void;
}
```

**Local implementation**: `PollingStatusBroadcaster` — writes to JobStore, client polls. (Same behavior as today, but abstracted.)

**Cloud implementation**: `ConvexStatusBroadcaster` — Convex real-time subscriptions.

### D.5 Wiring It Up

Create a central `services.ts` that instantiates the right implementations:

```typescript
// src/lib/services.ts
import { LocalStorageProvider } from './storage/LocalStorageProvider';
import { FileJobStore } from './jobs/FileJobStore';
import { FileProjectStore } from './projects/FileProjectStore';
import { PollingStatusBroadcaster } from './realtime/PollingStatusBroadcaster';

// In cloud deployment, these imports change to cloud implementations
export const storageProvider = new LocalStorageProvider();
export const jobStore = new FileJobStore();
export const projectStore = new FileProjectStore();
export const statusBroadcaster = new PollingStatusBroadcaster();
```

All API routes and pipeline code import from `services.ts` instead of directly accessing the filesystem or in-memory Map.

### D.6 Migration Path

1. Define interfaces
2. Implement local versions that match current behavior
3. Refactor API routes to use interfaces (one route at a time)
4. Verify no regressions
5. The cloud swap (Phase 3.2) only touches `services.ts` imports

### D.7 Deliverables

| Deliverable | Description |
|-------------|-------------|
| StorageProvider | Interface + LocalStorageProvider |
| JobStore | Interface + FileJobStore (persistent across restarts) |
| ProjectStore | Interface + FileProjectStore |
| StatusBroadcaster | Interface + PollingStatusBroadcaster |
| services.ts | Central service registry |
| All API routes migrated | Use interfaces instead of direct fs/Map access |
| Pipeline integration | PipelineRunner uses StorageProvider + JobStore |

---

## Phase E: Marketing & Polish

**Goal**: Build the public-facing marketing page and establish visual identity. This is what Antares (and future prospects) see before they log in.

### E.1 Landing Page

`(marketing)/page.tsx` — Single scroll page with clear sections:

1. **Hero**: Bold headline + value proposition + "Get Started" CTA
   - "Publication-Ready Crosstabs, Automated."
   - Subhead explaining the .sav → Excel pipeline

2. **How It Works**: 3-step visual (Upload → Configure → Download)

3. **Capabilities**: Feature cards
   - 6 AI agents working in parallel
   - Statistical testing with configurable thresholds
   - Loop/stacked data support
   - Weight detection and dual-pass output
   - HITL review for quality assurance
   - 6 color themes

4. **For Research Teams**: Enterprise pitch
   - Multi-project management
   - Consistent output across analysts
   - Audit trail and provenance tracking

5. **CTA Footer**: "Log In" button (routes to WorkOS, or directly to dashboard pre-auth)

### E.2 Marketing Layout

`(marketing)/layout.tsx`:
- Minimal header: Logo + "Log In" button
- No sidebar
- Footer with basic links

### E.3 Visual Identity

- **Color palette**: Derive from the `classic` theme palette (professional blues/greens)
- **Typography**: System font stack (already in place) or upgrade to a professional sans-serif
- **Logo**: HawkTab AI wordmark (design separately)
- **Tone**: Professional, confident, not flashy. Enterprise research audience.

### E.4 Deliverables

| Deliverable | Description |
|-------------|-------------|
| Landing page | Hero + How It Works + Capabilities + CTA |
| Marketing layout | Separate from product layout |
| Visual consistency | Color palette and typography aligned |

---

## Phase F: Auth & Multi-Tenancy Foundation

**Goal**: Lay the groundwork for WorkOS authentication and organization structure. This phase builds the data model and UI scaffolding — actual WorkOS integration happens in Phase 3.3 of the product roadmap.

### F.1 Organization Data Model

Extend ProjectStore with organization context:

```typescript
export interface Organization {
  orgId: string;
  name: string;
  slug: string;
  createdAt: Date;
}

export interface OrgMembership {
  userId: string;
  orgId: string;
  role: 'admin' | 'member' | 'external_partner';
}
```

**Local implementation**: Single hardcoded org ("HawkPartners") with a single user. The data model exists; enforcement comes with WorkOS.

### F.2 Auth Middleware Scaffold

```typescript
// src/middleware.ts
export function middleware(request: NextRequest) {
  // Phase F: Pass through (no auth enforcement)
  // Phase 3.3: Validate WorkOS session, inject userId/orgId
  return NextResponse.next();
}

export const config = {
  matcher: ['/(product)/:path*', '/api/:path*'],
};
```

The middleware exists but is a no-op. When WorkOS is integrated, it validates the session and attaches user/org context.

### F.3 UI Auth Scaffolding

- **Org selector** in header: Shows hardcoded "HawkPartners" for now. Will become a dropdown when multi-org is live.
- **User menu**: Shows "Demo User" for now. Will show actual user name/avatar post-auth.
- **Login/logout**: "Log In" button routes to dashboard (no actual auth). Post-WorkOS, routes to WorkOS hosted login.

### F.4 Scoped Data Access

Even before auth is enforced, design all data access to be org-scoped:

```typescript
// All queries include orgId
projectStore.list(orgId, { status: 'active' });
storageProvider.list(`${orgId}/${projectId}/`);
jobStore.listByProject(projectId); // projectId already scoped to org
```

This means the cloud migration doesn't need to retrofit scoping — it's already there.

### F.5 Deliverables

| Deliverable | Description |
|-------------|-------------|
| Organization model | Interface + local implementation |
| Auth middleware scaffold | No-op middleware ready for WorkOS |
| Org-scoped data access | All stores query by orgId |
| UI placeholders | Org selector, user menu, login button |

---

## Implementation Sequence & Dependencies

```
Phase A ─────────────────────────────────────────────────────────
  (Foundation)   Route groups, app shell, API refactor
         │
         ├──────────────> Phase D ──────────────────────────────
         │                  (Abstractions: stores + storage seams)
         │                         │
         │                         ├──────> Phase B ────────────
         │                         │          (New Project Wizard)
         │                         │
         │                         └──────> Phase C ────────────
         │                                    (Dashboard + Results)
         │
         └──────────────> Phase E ──────────────────────────────
                           (Marketing — can run in parallel)

Phase C + Phase D ──────> Phase F ──────────────────────────────
                           (Auth Foundation)
```

**Key dependencies**:
- Phase A must complete before D (route structure + refactors)
- Phase D should start immediately after A and land early (so B/C are built on persistent primitives)
- Phase B and C can be interleaved (wizard needed before dashboard is useful)
- Phase E (Marketing) can run in parallel once `(marketing)/` routes exist — it's independent
- Phase F depends on C (project management) and D (abstractions)

---

## Risk Considerations

### Data Migration
- Current pipeline outputs are in `outputs/<dataset>/pipeline-<timestamp>/` with no org/project wrapper
- Phase D's FileProjectStore needs to index existing outputs retroactively
- Write a one-time migration script that creates project records from existing `pipeline-summary.json` files

### API Route Backward Compatibility
- The current API serves both the web UI and potentially CLI tooling
- Phase B adds new FormData fields to `process-crosstab` — must remain backward compatible (new fields are optional)
- Consider versioning the API if breaking changes are needed

### Long-Running Pipeline + Server Restarts
- The FileJobStore (Phase D) persists job records, but if the server restarts mid-pipeline, the Node.js process dies and the pipeline is lost
- For local: accept this limitation (user re-runs)
- For cloud (Phase 3.2): Railway container persistence + checkpoint-based resume

### Performance with Many Projects
- The current `GET /api/pipelines` scans the filesystem on every request
- With 50+ projects, this becomes slow
- Phase D's ProjectStore with a JSON index file makes listing fast (no directory scanning)

---

## What This Plan Does NOT Cover

These are explicitly out of scope for this plan and belong to their respective roadmap phases:

| Item | Where It Lives |
|------|---------------|
| Cloud deployment (Vercel, R2, Railway, Convex) | Product Roadmap Phase 3.2 |
| WorkOS integration (actual auth) | Product Roadmap Phase 3.3 |
| Cost tracking persistence & dashboard | Product Roadmap Phase 3.4 |
| Structured logging & Sentry | Product Roadmap Phase 3.5 |
| Interactive table review (browser rendering) | Long-term Vision |
| Configurable assumptions & regeneration | Long-term Vision |
| Variable selection persistence | Long-term Vision |
| Predictive confidence scoring | Long-term Vision |

This plan builds the foundation that those features will plug into. The abstractions in Phase D are specifically designed so that Phase 3.2-3.5 are configuration changes, not rewrites.

---

## Success Criteria

The UI overhaul is complete when:

1. **All Phase 2 pipeline features** are accessible from the web UI (no CLI-only features remain)
2. **A new user** can upload files, configure their project, launch a pipeline, review HITL decisions, and download results — without touching the terminal
3. **The dashboard** shows all projects with status, and users can navigate between them
4. **Cloud readiness**: Swapping to R2/Convex/WorkOS requires only changing implementation classes in `services.ts`
5. **No regressions**: The CLI pipeline (`test-pipeline.ts`, `batch-pipeline.ts`) continues to work unchanged
6. **The landing page** communicates what HawkTab does to someone who has never seen it

---

*This plan should be iterated phase by phase. Start with Phase A (foundation), validate the architecture with Phase B (the most user-facing change), and adjust the remaining phases based on what we learn.*
