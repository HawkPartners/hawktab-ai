# Heartbeat + Cron Reconciler — Audit Findings

## Context

After implementing the heartbeat mechanism + Convex cron reconciler (roadmap item 3.5f #8), we ran a multi-agent audit covering: design approach, Convex schema/mutations, heartbeat helper module, pipeline orchestrator exit paths, review completion flow, and missing coverage search.

**Verdict**: The design is sound and the implementation covers all exit paths correctly (21 traced through the orchestrator, 3 through `completePipeline`). No critical bugs. Seven actionable findings below, ordered by recommended fix sequence.

---

## Findings

### 1. Bump `resuming` staleness threshold from 10 to 15 minutes — `IMPORTANT`

**Problem**: The post-review pipeline includes VerificationAgent (parallel LLM calls), R Validation (up to 8 retries/table), R execution (120s timeout), and Excel generation. Complex datasets could legitimately take 15–25 minutes. While the heartbeat keeps the run alive, any transient Convex connectivity causing missed heartbeats narrows the safety margin. With a 30-second heartbeat interval and 10-minute threshold, you'd need ~20 consecutive failures for a false positive — unlikely but possible during a Convex blip.

**Fix**: One-line change in `convex/runs.ts`:
```typescript
const RESUMING_STALE_MS = 15 * 60 * 1000; // was 10
```

Worst-case user wait for dead `resuming` run goes from ~15min to ~20min. Acceptable trade-off for eliminating false-positive risk.

**Files**: `convex/runs.ts` (line 231)

**Level of Effort**: Trivial

---

### 2. Extract shared `ACTIVE_STATUSES` constant — `IMPORTANT`

**Problem**: The set `["in_progress", "resuming"]` appears in three separate locations in `convex/runs.ts`:
- Line 114 (`updateStatus` mutation) — decides whether to auto-refresh `lastHeartbeat`
- Line 214 (`heartbeat` mutation) — guards against heartbeating non-active runs
- Lines 235 + 254 (`reconcileStaleRuns`) — implicitly, via two separate index queries

Adding or renaming a status requires updating all three independently. Easy to miss one.

**Fix**: Extract a constant at the top of `convex/runs.ts`:
```typescript
const ACTIVE_STATUSES = ["in_progress", "resuming"] as const;
```
Reference it in all three locations.

**Files**: `convex/runs.ts`

**Level of Effort**: Trivial

---

### 3. Add manual heartbeat in review route after R2 upload — `IMPORTANT`

**Problem**: After `completePipeline()` returns, its `finally` block has already called `stopHeartbeat()` (`reviewCompletion.ts:915`). But the review route then does R2 uploads and Convex terminal status updates (`route.ts:255–312`) with no heartbeat coverage. If R2 hangs, the run sits in `resuming` with no heartbeat. The cron could mark it `error` after the staleness threshold.

Same gap exists in the fire-and-forget `.then()` handler (`route.ts:340–392`).

**Mitigating factors**: R2 uploads are typically fast (seconds). The `updateStatus` call that sets the terminal status also auto-refreshes `lastHeartbeat` (belt-and-suspenders in `updateStatus`), so once that lands, the run leaves `resuming`. The real window is only the R2 upload duration.

**Fix**: Send one manual `sendHeartbeat(runId)` in the review route after R2 upload completes but before the terminal `updateStatus`. Apply to both the awaited path and the fire-and-forget `.then()` path.

**Files**: `src/app/api/runs/[runId]/review/route.ts` (lines ~267 and ~370)

**Level of Effort**: Trivial

---

### 4. Switch `setInterval` to recursive `setTimeout` in heartbeat helper — `IMPORTANT`

**Problem**: `heartbeat.ts:39` uses `setInterval` with an async callback. `sendHeartbeat()` is an HTTP request to Convex. If Convex is slow (e.g., 60s response), the 30-second interval fires a new callback while the previous one is still in-flight. Over time, this stacks concurrent HTTP requests.

**Fix**: Replace `setInterval` with recursive `setTimeout`:
```typescript
export function startHeartbeatInterval(runId: string, intervalMs = 30_000): () => void {
  let stopped = false;
  let timer: ReturnType<typeof setTimeout>;

  async function tick() {
    if (stopped) return;
    await sendHeartbeat(runId);
    if (!stopped) timer = setTimeout(tick, intervalMs);
  }

  sendHeartbeat(runId); // initial, non-blocking
  timer = setTimeout(tick, intervalMs);

  return () => { stopped = true; clearTimeout(timer!); };
}
```

This guarantees the next heartbeat fires `intervalMs` after the previous one **completes**, eliminating overlap.

**Files**: `src/lib/api/heartbeat.ts`

**Level of Effort**: Small

---

### 5. Add `pending_review` reconciliation with 48-hour threshold — `MINOR`

**Problem**: The reconciler only checks `in_progress` and `resuming` runs. A run in `pending_review` is intentionally long-lived (user may take hours to review), but it can get permanently stuck if:
- The R2 review state upload failed (logged as non-fatal at `pipelineOrchestrator.ts:996`)
- The container restarts, losing local review state
- The user hits the review page and gets a 409 ("Review state was lost")
- The run sits in `pending_review` forever with no cleanup

**Fix**: Add a third query in `reconcileStaleRuns` for `pending_review` runs older than 48 hours:
```typescript
const PENDING_REVIEW_STALE_MS = 48 * 60 * 60 * 1000; // 48 hours
```
Error message: "Review expired — please re-run your project."

**Files**: `convex/runs.ts` (inside `reconcileStaleRuns`)

**Level of Effort**: Small

---

### 6. Add terminal status update in review route outer catch — `MINOR`

**Problem**: If `completePipeline` somehow throws to the route level (`route.ts:415–424`), the HTTP response is 500 but the Convex run stays in `resuming` until the cron eventually marks it stale. The user sees a 500 error immediately but the run stays "in progress" in the UI for up to 15+ minutes.

**Fix**: Add an `updateRunStatus` call in the outer catch block:
```typescript
catch (error) {
  // Mark run as errored immediately, don't wait for cron
  await updateRunStatus(runId, { status: 'error', error: 'Unexpected failure during review completion' });
  return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
}
```

**Files**: `src/app/api/runs/[runId]/review/route.ts` (lines ~415–424)

**Level of Effort**: Trivial

---

### 7. Add consecutive-failure logging to heartbeat helper — `MINOR`

**Problem**: If Convex is completely down, `sendHeartbeat` fails every 30 seconds with `console.warn` — up to 180 identical warnings per pipeline run. No escalation, no way to notice the pattern in logs.

**Fix**: Add a consecutive failure counter. After 5 failures, log one `console.error("Heartbeat: ${count} consecutive failures for run ${runId}")`. Log "Heartbeat: recovered" when it succeeds again. Don't change the non-fatal behavior — just improve observability.

**Files**: `src/lib/api/heartbeat.ts`

**Level of Effort**: Small

---

## Not Fixing (By Design)

**`in_progress` worst-case detection of ~95 minutes**: A container crash early in a 45–60 min pipeline could leave a dead spinner for up to 95 minutes. This is a known trade-off of the 90-minute threshold and 5-minute cron interval. The user can always cancel and re-run. Shortening the threshold risks false positives on legitimately long pipelines.

**No "Re-run" button in error UI**: The "Pipeline interrupted" error message tells users to re-run, but there's no action button. This is a UX polish item for the broader 3.5f work, not a heartbeat-specific fix. Noted for future.

**Status type duplication across Convex/TypeScript**: The status union is manually mirrored in 4 places (schema validators, mutation args, TypeScript types). No compile-time enforcement. This predates the heartbeat feature and is broader tech debt.

---

*Created: February 12, 2026*
*Source: Multi-agent audit of heartbeat implementation (5 parallel agents covering design, schema, helper module, orchestrator exit paths, review flow, and coverage search)*
