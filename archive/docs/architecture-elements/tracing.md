## Tracing

Setup:
- Use `withTrace()` to wrap major flows so runs collapse into a single trace with spans per group/step.
- Force flush via `getGlobalTraceProvider().forceFlush()` where appropriate.

Where:
- `src/lib/tracing.ts`
- Call sites in agents and API routes.


