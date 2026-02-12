# Phase 3.5b — Observability

## Context

Sentry was installed via wizard (base SDK only). The pipeline has good internal tracking (AgentMetrics for costs, ErrorPersistence for failures, EventBus for stages) but none of it flows to an external system. In production, we'd have no visibility — errors would be silent, pipeline failures invisible, and debugging would require SSH access to read console output.

This phase wires everything into Sentry and introduces **wide events** (inspired by Stripe's canonical log lines): one rich, structured event per pipeline run that contains everything you'd need to debug it. Instead of hunting through scattered console.logs, you query one event.

## Architecture

```
Pipeline Run
  └── WideEvent (accumulates context throughout run, emits once at end)
       ├── stage records (name, status, duration)
       ├── agent call records (model, tokens, cost, duration)
       ├── run metadata (dataset, orgId, config, outcome)
       └── computed totals (cost, duration, table count)
  └── Sentry Transaction (pipeline.run)
       ├── Stage Spans (DataMapProcessor, BannerAgent, ...)
       └── Agent Breadcrumbs (per-call details)
```

Two pipeline execution paths both get instrumented:
- **PipelineRunner.ts** (CLI/scripts) — direct WideEvent + Sentry spans
- **pipelineOrchestrator.ts** (web UI) — same WideEvent pattern

Since both paths use the singleton `AgentMetricsCollector`, wiring Sentry breadcrumbs + WideEvent through it automatically covers all 7 agents without touching any agent files.

## Implementation Steps

### Step 1: Create `src/lib/observability/wide-event.ts` (~120 lines)

Core `WideEvent` class — the main new abstraction.

- Constructor: takes `{ pipelineId, dataset, orgId?, userId? }`
- `.set(key, value)` — accumulate arbitrary key-value pairs
- `.recordStage(name, status, durationMs, error?)` — record a stage completion
- `.recordAgentCall({ agentName, model, inputTokens, outputTokens, durationMs, costUsd })` — record an agent call
- `.finish(outcome, error?)` — compute totals, emit to Sentry + console

`finish()` behavior:
1. Computes totals: token counts, cost, agent calls, duration
2. `Sentry.captureEvent()` with level `info` (success) or `error` (failure), tags for pipelineId/dataset/orgId/outcome, all accumulated fields as extras
3. Emits one canonical JSON line to console for local debugging

### Step 2: Create `src/lib/observability/sentry-pipeline.ts` (~100 lines)

Thin Sentry span helpers that keep SDK details out of PipelineRunner.

- `startPipelineTransaction(opts)` — starts a manual Sentry span for a background pipeline run (uses `Sentry.startSpanManual` since pipeline runs outside HTTP request lifecycle)
- Returns `PipelineSpanContext` with:
  - `.startStage(name)` — create child span for a stage, returns `{ finish(status) }`
  - `.finish(status)` — end the root transaction
- `setSentryUser(authContext)` — set Sentry user tags from auth

### Step 3: Update `src/lib/observability/AgentMetrics.ts` (~15 new lines)

Key integration point — changes here auto-instrument all agents.

- Add `wideEvent` field + `bindWideEvent(event)` method to `AgentMetricsCollector`
- In `record()`, after existing logic:
  - `this.wideEvent?.recordAgentCall(...)` — enrich canonical event
  - `Sentry.addBreadcrumb(...)` — agent call breadcrumb for error context

### Step 4: Update `src/lib/observability/index.ts`

Add exports for `WideEvent`, `startPipelineTransaction`, `setSentryUser`.

### Step 5: Production-harden Sentry configs

**`sentry.server.config.ts`**:
- DSN from `process.env.SENTRY_DSN` (fallback to current value)
- `environment: process.env.NODE_ENV`
- `tracesSampleRate`: 1.0 dev, 0.2 production
- `sendDefaultPii: false` in production
- `ignoreErrors: ['AbortError']` (pipeline cancellation is not an error)
- `beforeSend` to strip sensitive data

**`sentry.edge.config.ts`**: Same env-based config.

**`src/instrumentation-client.ts`**: Same env-based sampling + PII controls.

### Step 6: Replace `src/lib/tracing.ts`

Replace 60-line scaffolding with slim file that:
- Re-exports from new observability modules
- Keeps `logAgentExecution()` as deprecated wrapper → `Sentry.addBreadcrumb()` (one call site in `process-crosstab/route.ts`)

### Step 7: Set Sentry user context in `src/lib/auth.ts` (~4 lines)

After building `AuthContext` in both bypass and real auth paths:
```typescript
setSentryUser(ctx);
```

### Step 8: Wire up PipelineRunner.ts

At pipeline start (after `pipelineId` created ~line 211):
- Create `WideEvent`, bind to metrics collector, start Sentry transaction

After each `stageTiming[...] = ...` line (~12 locations):
- `wideEvent.recordStage(...)` — one line each

At pipeline success/failure/early-return paths:
- `wideEvent.finish(outcome)`, `transaction.finish(status)`, unbind

~48 new lines total, all additive. No existing lines modified.

### Step 9: Wire up pipelineOrchestrator.ts

Same pattern at `runPipelineFromUpload()` (~line 338):
- Create WideEvent with orgId/userId from params
- Bind to metrics collector
- Finish at success/error paths

~30 new lines.

### Step 10: Cleanup

- Delete `src/app/sentry-example-page/page.tsx`
- Delete `src/app/api/sentry-example-api/route.ts`
- Add `SENTRY_DSN` to `.env.example`

### Step 11: Verify

- `npm run lint && npx tsc --noEmit`
- Run `npm run dev`, hit a few pages, check Sentry receives page load transactions
- Check Sentry user context is set on authenticated requests

## Files Summary

| Action | File |
|--------|------|
| NEW | `src/lib/observability/wide-event.ts` |
| NEW | `src/lib/observability/sentry-pipeline.ts` |
| MODIFY | `src/lib/observability/AgentMetrics.ts` |
| MODIFY | `src/lib/observability/index.ts` |
| MODIFY | `sentry.server.config.ts` |
| MODIFY | `sentry.edge.config.ts` |
| MODIFY | `src/instrumentation-client.ts` |
| REPLACE | `src/lib/tracing.ts` |
| MODIFY | `src/lib/auth.ts` |
| MODIFY | `src/lib/pipeline/PipelineRunner.ts` |
| MODIFY | `src/lib/api/pipelineOrchestrator.ts` |
| MODIFY | `.env.example` |
| DELETE | `src/app/sentry-example-page/page.tsx` |
| DELETE | `src/app/api/sentry-example-api/route.ts` |

## Out of Scope

- **Replacing 765 console.logs** — separate cleanup, not this phase
- **Sentry alerting rules** — configured in Sentry dashboard UI after deploy
- **API route canonical log lines** — Sentry auto-instruments Next.js routes
- **PostHog** — that's Phase 3.5e
