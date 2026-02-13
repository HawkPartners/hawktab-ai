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

**Where it lives**: Settings page or a dev-only route (`/dev/load-test`), gated behind `canPerform(auth.role, 'admin')` + `NODE_ENV === 'development'` or a feature flag.

**How it works**:

1. **Dataset Source**: Test datasets stored in R2 under a `dev-test/` prefix (uploaded once manually). Each dataset is a bundle: `.sav` + survey doc + optional banner plan. This avoids shipping test data in the Docker image and simulates real file uploads from R2.

2. **Configuration UI**:
   - Select datasets (checkboxes) or "Select All"
   - Concurrency mode: Sequential (1 at a time) | Batch (configurable: 3, 5, 10, 15)
   - Project name prefix (e.g., "Load Test 2/13" → "Load Test 2/13 — Leqvio Demand W1")
   - Option: Skip HITL review (auto-approve all tables)
   - Option: Stop after verification (skip R/Excel for faster iteration)

3. **Execution**: Hits the real `/api/projects/launch` endpoint — one POST per dataset, fired according to the concurrency setting. No special batch endpoint. This tests the exact same code path real users hit.

4. **Monitoring**: Projects appear on the real dashboard with real-time status. A small load-test summary panel shows: total launched, in-progress, completed, failed, average duration, and any rate-limit rejections.

5. **Cleanup**: A "Delete load test projects" button that removes all projects matching the name prefix. Prevents dashboard clutter.

### Key Decisions

- **Use the real launch endpoint, not a backdoor.** The whole point is testing the production code path under load. If we add a special batch endpoint, we're testing something different.
- **pLimit(3) is intentional.** Don't remove it for load testing. We want to see how the queue behaves. If 15 projects launch and 3 run at a time, we'll see the queue drain over ~45 min × 5 batches ≈ 3-4 hours. That's realistic.
- **Rate limiting in dev**: Already 10x multiplied (50 req/10min on critical tier). 15 rapid launches won't hit it. In staging/prod, we may need a `load-test` bypass or temporary tier override.
- **R2 for test datasets**: Keeps the Docker image lean. Datasets are uploaded once via a setup script. The load test UI fetches file URLs from R2 and passes them to the launch endpoint.

### Railway Considerations

- **Current**: Likely a single container with default memory. Need to check Railway dashboard for limits.
- **For load testing**: May need to bump memory to 4-8GB if running 3+ concurrent R processes.
- **Scaling**: Railway supports horizontal scaling (multiple instances). If we ever need true production concurrency beyond 3, we'd add replicas. But for now, pLimit(3) on a single instance is the right architecture.

### Implementation Plan

1. Create a dev-only API route `POST /api/dev/load-test` that accepts dataset list + concurrency config
2. Build the load test UI page at `/dev/load-test` (admin-gated)
3. Write an R2 dataset upload script (`scripts/upload-test-datasets-to-r2.ts`) that bundles local test data and pushes to R2
4. The load test route downloads datasets from R2 → creates temp files → calls `/api/projects/launch` for each, respecting the concurrency setting
5. Add a summary/monitoring component that polls run status via Convex queries
6. Add cleanup mutation to delete load-test projects by name prefix

---

## 3. Security

- Conduct another security audit after feature freeze — new API routes have been added since the last audit
- Research the risk profile specific to deployed web apps vs. mobile apps

## 4. Developer Documentation

- Revisit `CLAUDE.md` to reinforce: "follow established codebase patterns before defaulting to training-data conventions" — cover not just security but Convex patterns, API layer usage, etc.
- https://github.com/anthropics/claude-code-action (can use this to execute security audits and pattern checks)
- Document the three `.env` files (`.env.local`, `.env.dev`, `.env.prod`) and their purposes in both `README.md` and `CLAUDE.md`
- Document the deployment flow: `dev` branch (feature work) → `staging` branch (Railway auto-deploys, cloud testing) → `production`
