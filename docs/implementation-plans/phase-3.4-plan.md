# Phase 3.4 Implementation Plan: Dashboard, Project Detail, Roles & Cost Tracking

## Context

Phase 3.1–3.3 are complete: cloud infrastructure (Convex + R2 + WorkOS), pipeline cloud migration, and the new project wizard. What's missing is the day-to-day experience — where users see their projects, track progress, manage access, and understand costs. This phase makes Crosstab AI feel like a product Antares can use without hand-holding.

## Design Decisions

**Progress timeline stages**: The orchestrator writes these stage strings to Convex: `uploading` → `parsing` → `parallel_processing` → `crosstab_review_required` (optional) → `validating_r` → `generating_r` → `executing_r` → `writing_outputs` → `complete`. The timeline component maps these to 6 user-friendly steps. No schema change — client-side mapping only.

**Cost tracking**: Store `costSummary` inside `runs.result` (alongside `summary`, `r2Files`). The orchestrator already computes `getMetricsCollector().getSummary()` at line 1083 of `pipelineOrchestrator.ts` — it just doesn't write it to Convex. One-line addition. No separate `aiUsage` table. **Costs are NOT shown to users** — they're for internal use only (query Convex directly). No cost card on the project detail page.

**Role enforcement**: Minimal model — `admin` can manage members and see all projects; `member` can create projects and see own; `external_partner` can only view/download. A simple `canPerform(role, action)` utility. Gates on API routes + UI conditionals.

**Dashboard filters**: Client-side filtering on existing Convex query data (dataset is small). Tabs for status, Input for search.

**Settings page MVP**: Org name (read-only), your profile, member list with role badges. No invite flow for launch — manage via WorkOS dashboard.

---

## Work Units (in dependency order)

### 1. Cost Tracking — Persist to Convex

Add `costSummary` to the terminal `result` object in the orchestrator. The cost data is already computed at line 1083 but only written to disk.

**Modify**: `src/lib/api/pipelineOrchestrator.ts`
- At line ~1194, inside the `result: { ... }` object passed to `updateRunStatus`, add:
  ```
  costSummary: {
    totalCostUsd: costMetrics.totals.estimatedCostUsd,
    totalTokens: costMetrics.totals.totalTokens,
    totalCalls: costMetrics.totals.calls,
    byAgent: costMetrics.byAgent.map(a => ({
      agent: a.agentName, model: a.model, calls: a.calls,
      tokens: a.totalTokens, costUsd: a.estimatedCostUsd,
    })),
  }
  ```
- `costMetrics` is already in scope (line 1083)

**Verify**: Run pipeline via UI, check Convex dashboard → `runs` table → `result.costSummary` is populated.

---

### 2. Auth Provider — Add Role to Context

All permission-dependent UI and API gates need the user's role. Currently the auth context only has orgId, userId, email, name.

**Modify**: `src/providers/auth-provider.tsx`
- Add `role: 'admin' | 'member' | 'external_partner' | null` to `AuthContextValue` interface
- Add `role` prop to `AuthProviderProps`
- Pass through to context value

**Modify**: `src/app/(product)/layout.tsx`
- After `syncAuthToConvex`, query `orgMemberships.getByUserAndOrg` to get the role
- Pass `role` to `<AuthProvider>`

**Create**: `src/lib/permissions.ts`
- Export `Role` type and `Action` type
- Export `canPerform(role, action): boolean` with permission map:
  - `create_project`: admin, member
  - `cancel_run`: admin, member
  - `view_settings`: admin, member
  - `manage_members`: admin

**Verify**: In a component, `useAuthContext().role` returns `'admin'` or `'member'` in dev mode.

---

### 3. User Menu & Sign Out in App Header

Users need to see who they're logged in as and sign out. Currently the header just shows "Crosstab AI" text and a dark mode toggle.

**Create**: `src/app/(product)/actions.ts` — server action for WorkOS sign out

**Modify**: `src/components/app-header.tsx`
- Replace the "Crosstab AI" text span with a `UserMenu` component on the right side
- UserMenu: `DropdownMenu` (already installed) with:
  - Trigger: initials circle + name
  - Content: name/email/role display, Settings link, Sign out action
  - Use `useAuthContext()` for name/email/role
  - Sign out calls the server action (or is hidden in AUTH_BYPASS mode)
- Keep the `ModeToggle` alongside

**Verify**: Click user avatar in header → see name, email, role badge → click Sign out → redirected to landing page.

---

### 4. Dashboard — Status Tabs + Search

**Modify**: `src/app/(product)/dashboard/page.tsx`
- Add state: `searchQuery` (string), `statusFilter` ('all' | 'active' | 'completed' | 'failed')
- Add `filteredList` useMemo that filters `projectList` by status and search
- Add UI between header and list:
  - Search `Input` with `Search` icon (lucide)
  - `Tabs` component with TabsList/TabsTrigger for All / Active / Completed / Failed
  - Count badges on tabs
- Render `filteredList` instead of `projectList`
- Gate "New Project" button with `canPerform(role, 'create_project')`
- Add empty state for "no matches" (different from "no projects")

**Components used**: `Tabs`, `TabsList`, `TabsTrigger` (shadcn — already installed), `Input`, `Search` icon

**Verify**: Type in search box → list filters by name. Click status tabs → list filters by status. External partner doesn't see New Project button.

---

### 5. Progress Timeline Component

The biggest UX improvement — replace the text status message with a visual stage-by-stage timeline.

**Create**: `src/components/pipeline-timeline.tsx`
- Define `TIMELINE_STEPS` array mapping orchestrator stage strings to user-friendly labels:
  1. `parsing` → "Parsing Data"
  2. `parallel_processing` → "Analyzing & Building Tables"
  3. `crosstab_review_required` → "Review" (conditional — only show if pipeline paused here)
  4. `validating_r` → "Validating"
  5. `generating_r` / `executing_r` → "Running Analysis"
  6. `writing_outputs` → "Generating Excel"
- `getStepStatus()` function: given current stage + run status, returns 'completed' | 'active' | 'pending' | 'error' for each step
- Render as vertical timeline with:
  - Left column: icon (CheckCircle green / Loader2 blue spinning / Circle gray / XCircle red)
  - Connecting vertical line between steps
  - Label (font-medium) + description (text-sm text-muted-foreground)
  - Active step shows the run's `message` field
  - Progress percentage shown on active step

**Modify**: `src/app/(product)/projects/[projectId]/page.tsx`
- Replace the "Processing Banner" card (lines 332-366) for `in_progress`/`resuming` with:
  - Pipeline progress timeline inside a Card
  - Keep the cancel button in the card header
- Also show timeline for `pending_review` status (with the review step highlighted)

**Verify**: Start a pipeline → navigate to project detail → see timeline steps update in real-time via Convex subscription.

---

### 6. Project Detail — Config Summary

**Modify**: `src/app/(product)/projects/[projectId]/page.tsx`

**Config summary card** (after Input Files card):
- Read `project.config`
- Display as label/value pairs: project type, banner mode, display mode, theme, weight variable, stat testing threshold
- Simple `dl` list with `dt`/`dd` pairs

**Note**: Cost data is persisted in Work Unit 1 but intentionally NOT shown to users. Query Convex directly for internal cost analysis.

**Verify**: View a completed project → see configuration summary showing what settings were used.

---

### 7. API Route Permission Gates

**Modify**: `src/app/api/runs/[runId]/cancel/route.ts`
- Add `requireConvexAuth()` call
- Verify the run belongs to the requesting user's org

**Modify**: `src/app/api/runs/[runId]/download/[filename]/route.ts`
- Add `requireConvexAuth()` call
- Verify `run.orgId` matches `auth.convexOrgId`

**Modify**: `src/app/api/projects/launch/route.ts`
- Add role check: only admin/member can launch (already has auth, just add role gate)

**Verify**: Existing flows still work in dev (AUTH_BYPASS). Routes return 401/404 appropriately when auth fails or org doesn't match.

---

### 8. Settings Page MVP

**Add to Convex**: `convex/organizations.ts` — add `get` query (by Convex ID, not WorkOS ID)
**Add to Convex**: `convex/orgMemberships.ts` — add `listByOrg` query (joins with users table to get name/email)

**Rewrite**: `src/app/(product)/settings/page.tsx`
- Client component with three cards:
  1. **Organization**: name (read-only), from `api.organizations.get`
  2. **Your Profile**: name, email, role badge (from auth context)
  3. **Members**: list from `api.orgMemberships.listByOrg`, each row shows name, email, role badge
- Gate visibility: external_partner redirected away (or shown limited view)

**Verify**: Navigate to /settings → see org name, your profile with role, member list.

---

## File Change Summary

### New Files (3)
| File | Purpose |
|------|---------|
| `src/lib/permissions.ts` | `canPerform(role, action)` permission utility |
| `src/components/pipeline-timeline.tsx` | Visual pipeline progress component |
| `src/app/(product)/actions.ts` | Server action for WorkOS sign out |

### Modified Files (10)
| File | Change |
|------|--------|
| `src/lib/api/pipelineOrchestrator.ts` | Add `costSummary` to result object (~5 lines) |
| `src/providers/auth-provider.tsx` | Add `role` to context interface + provider |
| `src/app/(product)/layout.tsx` | Fetch membership role, pass to AuthProvider |
| `src/components/app-header.tsx` | Add UserMenu dropdown with sign out |
| `src/app/(product)/dashboard/page.tsx` | Add search, status tabs, filtered list, role gate on New Project |
| `src/app/(product)/projects/[projectId]/page.tsx` | Add timeline, config card |
| `src/app/(product)/settings/page.tsx` | Full rewrite — org, profile, members |
| `convex/organizations.ts` | Add `get` query |
| `convex/orgMemberships.ts` | Add `listByOrg` query |
| `src/app/api/runs/[runId]/cancel/route.ts` | Add auth + org check |

### Optionally Modified (2, if time permits)
| File | Change |
|------|--------|
| `src/app/api/runs/[runId]/download/[filename]/route.ts` | Add auth + org check |
| `src/app/api/projects/launch/route.ts` | Add role check on launch |

---

## Implementation Order

```
[1] Cost Backend ─────────────────────────────► standalone (internal only)
[2] Auth Provider + Permissions ──────────────► enables [3], [4], [7], [8]

After 1 & 2 are done (parallel):
[3] User Menu        ─── independent
[4] Dashboard Filters ── independent
[5] Progress Timeline ── independent

After 5:
[6] Config Summary on project detail (after 5 modifies the same page)

Then:
[7] API Permission Gates (depends on 2)
[8] Settings Page (depends on 2 + new Convex queries)
```

**If time is short**: Cut [7] (API gates) and [8] (settings). The auth middleware already protects all routes from unauthenticated access. Role-based gates within an org and the settings page can be a fast follow.

---

## Verification Plan

After all work units:
1. `npm run lint && npx tsc --noEmit` — clean build
2. `npm run dev` — start the app
3. Navigate to `/dashboard` → verify search and tabs filter correctly
4. Create a new project → launch pipeline → watch progress timeline update in real-time
5. After completion → verify config summary shows, downloads work
6. Click user menu → verify name/email/role → sign out works
7. Navigate to `/settings` → verify org info, profile, member list
8. Check Convex dashboard → `runs.result.costSummary` populated for completed runs
