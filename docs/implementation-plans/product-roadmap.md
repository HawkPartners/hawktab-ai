## 2. UI Batch Load Testing

### Goal

A dev-mode feature in the actual UI that launches N projects simultaneously against the real pipeline. Projects appear on the dashboard, progress in real-time, and complete (or fail) just like real user uploads. This tests the system under realistic concurrent load.

### Why This Matters

- Antares will have multiple analysts uploading concurrently. We need to know what happens when 5, 10, 15 projects run at once.
- The CLI batch script runs datasets sequentially — it doesn't test concurrency at all.
- We need to validate: Railway container limits, R process memory under load, Convex write throughput, rate limiter behavior, abort/cancel under contention, dashboard performance with many active runs.

### Current Architecture Constraints

| Component | Constraint | Impact on Load Test |
|-----------|-----------|-------------------|
| `pLimit(3)` in launch route | Max 3 pipelines executing simultaneously | Queues beyond 3 — by design. Load test will show how the queue drains. |
| Rate limit (critical tier) | 5 requests per 10 min (50 in dev) | 15 rapid launches will be fine in dev mode. In prod, might need a bypass for load testing. |
| R processes | Each spawns ~500MB-1GB memory | 3 concurrent × 1GB = 3GB. If pLimit raised to 5+, memory grows fast. Railway container sizing matters. |
| Convex mutations | All internalMutation, no contention | Safe. Convex handles concurrent writes natively. |
| AbortController per pipeline | Each pipeline has its own | Isolated. No cross-pipeline interference. |
| Circuit breaker | Module-level singleton, but set/cleared per pipeline | Safe — each pipeline sets its own breaker instance. |

### Design

**Where it lives**: Dev-only route at `/dev/load-test`, gated behind `canPerform(auth.role, 'admin')` + `NODE_ENV === 'development'`. This means it's available locally and on staging (which runs as `development`), but never in production.

**How it works**:

1. **Dataset Source**: Test datasets stored in R2 under a `dev-test/` prefix. A one-time setup script (`scripts/upload-test-datasets-to-r2.ts`) reads from local `data/` folders and uploads each dataset bundle (`.sav` + survey doc + optional banner plan) to R2. The load test UI fetches the dataset list from R2 and downloads files to construct FormData payloads. This avoids shipping test data in the Docker image, works on Railway (where `data/` doesn't exist), and simulates real file uploads.

2. **Configuration UI**:
   - Select datasets (checkboxes) or "Select All"
   - Concurrency mode: Sequential (1 at a time) | Batch (configurable: 3, 5, 10, 15)
   - Project name prefix (e.g., "Load Test 2/13" → "Load Test 2/13 — Leqvio Demand W1")

3. **Execution**: Hits the real `/api/projects/launch` endpoint — one POST per dataset, fired according to the concurrency setting. No special batch endpoint. This tests the exact same code path real users hit.

4. **HITL Review**: Projects that reach the `pending_review` stage will pause there, just like real projects. No auto-approve. This is intentional — it tests the realistic scenario where multiple projects queue for review simultaneously. The operator works through them manually, which validates the review UI under contention.

5. **Monitoring**: A dedicated summary panel on the load test page shows: total launched, in-progress, pending review, completed, failed, average duration, and any rate-limit rejections. Projects also appear on the real dashboard with real-time status — both views are useful.

6. **Cleanup**: A "Delete load test projects" button that soft-deletes all projects matching the name prefix (sets `isDeleted: true`). Consistent with the existing deletion pattern. Prevents dashboard clutter.

### Key Decisions

- **Use the real launch endpoint, not a backdoor.** The whole point is testing the production code path under load. If we add a special batch endpoint, we're testing something different.
- **pLimit(3) is intentional.** Don't remove it for load testing. We want to see how the queue behaves. If 15 projects launch and 3 run at a time, we'll see the queue drain over ~45 min × 5 batches ≈ 3-4 hours. That's realistic.
- **Rate limiting in dev**: Already 10x multiplied (50 req/10min on critical tier). 15 rapid launches won't hit it. Staging also runs as `development`, so the multiplier applies there too.
- **R2 for test datasets**: Keeps the Docker image lean. Datasets are uploaded once via a setup script. Works on Railway where local `data/` doesn't exist. The load test UI fetches file URLs from R2 and constructs real FormData payloads.
- **No auto-approve for HITL review.** Projects pause at `pending_review` just like production. This tests the real flow — including what happens when multiple reviews queue up. If you want to bypass review for speed, use the CLI batch script (`scripts/batch-pipeline.ts`) with `--stop-after-verification` instead.
- **Soft-delete for cleanup.** Matches the existing project deletion pattern (`isDeleted` flag). Recoverable if needed.
- **All concurrency presets (1, 3, 5, 10, 15).** Even though `pLimit(3)` caps actual concurrent R processes, higher concurrency settings test the queue draining behavior, rate limiter, and Convex write throughput under rapid-fire launches.

### Railway Considerations

- **Current**: Likely a single container with default memory. Need to check Railway dashboard for limits.
- **For load testing**: May need to bump memory to 4-8GB if running 3+ concurrent R processes.
- **Scaling**: Railway supports horizontal scaling (multiple instances). If we ever need true production concurrency beyond 3, we'd add replicas. But for now, pLimit(3) on a single instance is the right architecture.

### Implementation Plan

1. **R2 upload script** (`scripts/upload-test-datasets-to-r2.ts`): Scans local `data/` folders, identifies dataset bundles (`.sav` + survey doc + optional banner plan), uploads each to R2 under `dev-test/{dataset-name}/`. Run once to seed R2, re-run to update.

2. **API routes**:
   - `GET /api/dev/load-test/datasets` — Lists available datasets from R2 `dev-test/` prefix. Returns dataset names and file metadata. Gated behind admin + dev env.
   - `POST /api/dev/load-test/launch` — Accepts dataset list + concurrency config. Downloads files from R2, constructs FormData, and POSTs to `/api/projects/launch` for each dataset, respecting the concurrency setting. Returns the list of created project/run IDs.
   - `POST /api/dev/load-test/cleanup` — Soft-deletes all projects matching a given name prefix.

3. **UI page** (`src/app/(product)/dev/load-test/page.tsx`): Admin-gated, dev-env-only. Contains:
   - Dataset selector (checkboxes, "Select All")
   - Concurrency picker (1, 3, 5, 10, 15)
   - Name prefix input (defaults to "Load Test {date}")
   - Launch button
   - Monitoring panel (polls Convex for runs matching launched IDs)
   - Cleanup button

4. **Monitoring component**: Uses existing Convex queries (`api.runs.listByOrg`) with client-side filtering by the launched project IDs. Displays: total, in-progress, pending review, completed, failed, average duration, rate-limit rejections (tracked client-side from 429 responses during launch).

5. **Convex cleanup mutation**: `internalMutation` that soft-deletes projects by name prefix within an org. Called by the cleanup API route.

---

## 3. Security

- Conduct another security audit after feature freeze — new API routes have been added since the last audit
- Research the risk profile specific to deployed web apps vs. mobile apps

## 4. Developer Documentation

- Revisit `CLAUDE.md` to reinforce: "follow established codebase patterns before defaulting to training-data conventions" — cover not just security but Convex patterns, API layer usage, etc.
- https://github.com/anthropics/claude-code-action (can use this to execute security audits and pattern checks)
- Document the three `.env` files (`.env.local`, `.env.dev`, `.env.prod`) and their purposes in both `README.md` and `CLAUDE.md`
- Document the deployment flow: `dev` branch (feature work) → `staging` branch (Railway auto-deploys, cloud testing) → `production`
