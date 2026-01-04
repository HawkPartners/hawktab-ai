# Logging Implementation Plan

## Overview

This plan addresses the gap between HawkTab AI's current ad-hoc logging (134 `console.*` statements across 21 files) and modern observability best practices. Inspired by the [Logging Sucks](https://loggingsucks.com/) philosophy and [Honeycomb's wide events approach](https://charity.wtf/2022/08/15/live-your-best-life-with-structured-events/), we'll implement a generous, context-rich logging system designed for debugging complex AI pipelines.

**Philosophy**: When you're debugging a failed crosstab run at 2am, you want MORE information, not less. Logs are cheap; missing context when something breaks is expensive. We log generously, structure everything, and let environment configuration control what's visible.

---

## The Problem with Current Logging

### What We Have Now (Not Great)

| Issue | Impact |
|-------|--------|
| **134 scattered `console.*` calls** | No unified control, inconsistent format |
| **No log levels** | Can't suppress DEBUG in production |
| **String-based messages** | Not machine-parseable, hard to filter |
| **No request context** | Can't trace issues across agent calls |
| **Timing in ~30% of operations** | Missing performance data |
| **No correlation IDs** | Can't follow a job through the pipeline |

### What "Logging Sucks" Teaches Us

Traditional logging is broken because it treats each log line as independent. In reality, a single crosstab generation touches:
- File upload validation → BannerAgent → CrosstabAgent → TableAgent → R execution → Excel formatting

When something fails, you need the **context of the entire request**, not isolated log lines.

**Solution**: Wide Events - accumulate context throughout the request, emit structured events at key boundaries.

---

## Implementation Status

| Step | Description | Status |
|------|-------------|--------|
| 0 | Understand current state | ✅ Complete |
| 1 | Create Logger foundation | ⏳ Next |
| 2 | Implement Wide Events | 📋 Planned |
| 3 | Migrate console.* calls | 📋 Planned |
| 4 | Add structured agent logging | 📋 Planned |
| 5 | Add API request/response logging | 📋 Planned |
| 6 | Environment configuration | 📋 Planned |
| 7 | Future: Sentry integration | 📋 Planned (Phase 2) |

---

## Step 1: Logger Foundation

### 1.1 Create `src/lib/logger.ts`

A centralized logger with log levels, structured output, and environment-aware configuration.

**Log Levels** (in order of severity):
- `error` - Something broke, needs attention
- `warn` - Unexpected but recoverable
- `info` - Key operational events (request start/end, agent completion)
- `debug` - Detailed debugging info (variable values, intermediate states)
- `trace` - Very verbose (every function entry/exit, all data)

**Key Features**:
```typescript
// Structured, context-aware logging
logger.info('BannerAgent processing started', {
  sessionId: 'abc123',
  filename: 'bannerplan.docx',
  fileSize: 45123,
  imageCount: 3
});

// Automatic timing
const timer = logger.startTimer('R script execution');
// ... do work ...
timer.done({ rowsProcessed: 1500, tablesGenerated: 45 });

// Child loggers with inherited context
const agentLogger = logger.child({
  sessionId: 'abc123',
  agent: 'CrosstabAgent'
});
agentLogger.debug('Processing group', { groupName: 'Specialty' });
```

### 1.2 Environment Configuration

Add to `.env.example`:
```bash
# Logging Configuration
LOG_LEVEL=debug                 # error | warn | info | debug | trace
LOG_FORMAT=pretty               # pretty | json
LOG_INCLUDE_TIMESTAMP=true      # Include ISO timestamp in logs
LOG_INCLUDE_FILE_LINE=true      # Include source file:line (dev only)
```

**Environment Defaults**:
| Environment | LOG_LEVEL | LOG_FORMAT | Notes |
|-------------|-----------|------------|-------|
| development | `debug` | `pretty` | Human-readable, verbose |
| production | `info` | `json` | Structured, aggregatable |
| test | `error` | `json` | Quiet tests |

### 1.3 Implementation

```typescript
// src/lib/logger.ts
import { getEnvironmentConfig } from './env';

type LogLevel = 'error' | 'warn' | 'info' | 'debug' | 'trace';
type LogContext = Record<string, unknown>;

interface LoggerConfig {
  level: LogLevel;
  format: 'pretty' | 'json';
  includeTimestamp: boolean;
  includeFileLine: boolean;
}

const LOG_LEVELS: Record<LogLevel, number> = {
  error: 0,
  warn: 1,
  info: 2,
  debug: 3,
  trace: 4,
};

export function createLogger(baseContext: LogContext = {}) {
  const config = getLoggerConfig();

  const shouldLog = (level: LogLevel): boolean => {
    return LOG_LEVELS[level] <= LOG_LEVELS[config.level];
  };

  const formatMessage = (
    level: LogLevel,
    message: string,
    context: LogContext
  ): string => {
    const fullContext = { ...baseContext, ...context };

    if (config.format === 'json') {
      return JSON.stringify({
        timestamp: new Date().toISOString(),
        level,
        message,
        ...fullContext,
      });
    }

    // Pretty format for development
    const timestamp = config.includeTimestamp
      ? `[${new Date().toISOString()}] `
      : '';
    const contextStr = Object.keys(fullContext).length > 0
      ? ` ${JSON.stringify(fullContext)}`
      : '';
    return `${timestamp}[${level.toUpperCase()}] ${message}${contextStr}`;
  };

  const log = (level: LogLevel, message: string, context: LogContext = {}) => {
    if (!shouldLog(level)) return;

    const formatted = formatMessage(level, message, context);

    switch (level) {
      case 'error':
        console.error(formatted);
        break;
      case 'warn':
        console.warn(formatted);
        break;
      default:
        console.log(formatted);
    }
  };

  return {
    error: (msg: string, ctx?: LogContext) => log('error', msg, ctx),
    warn: (msg: string, ctx?: LogContext) => log('warn', msg, ctx),
    info: (msg: string, ctx?: LogContext) => log('info', msg, ctx),
    debug: (msg: string, ctx?: LogContext) => log('debug', msg, ctx),
    trace: (msg: string, ctx?: LogContext) => log('trace', msg, ctx),

    // Create child logger with inherited context
    child: (childContext: LogContext) => {
      return createLogger({ ...baseContext, ...childContext });
    },

    // Timer utility
    startTimer: (operation: string) => {
      const start = Date.now();
      return {
        done: (resultContext?: LogContext) => {
          const duration = Date.now() - start;
          log('info', `${operation} completed`, {
            ...resultContext,
            durationMs: duration,
          });
        },
      };
    },
  };
}

// Default logger instance
export const logger = createLogger();
```

---

## Step 2: Wide Events for Pipeline Operations

### 2.1 The Wide Event Pattern

Instead of scattered logs, we build a "wide event" - a single rich object that accumulates context throughout a pipeline run.

```typescript
// src/lib/wideEvent.ts

export interface PipelineEvent {
  // Identity
  sessionId: string;
  requestId: string;
  startedAt: string;

  // Request context
  files: {
    datamap?: { name: string; size: number; variables?: number };
    banner?: { name: string; size: number; format?: string };
    spss?: { name: string; size: number; rows?: number };
  };

  // Pipeline phases with timing
  phases: {
    phase5?: PhaseResult;  // Data processing
    phase6?: PhaseResult;  // CrosstabAgent
    tableAgent?: PhaseResult;
    rExecution?: PhaseResult;
    excelFormat?: PhaseResult;
  };

  // Agent details
  agents: {
    banner?: AgentResult;
    crosstab?: AgentResult;
    table?: AgentResult;
  };

  // Output
  result: {
    success: boolean;
    tablesGenerated?: number;
    errorMessage?: string;
    errorStack?: string;
  };

  // Performance
  totalDurationMs: number;
}

interface PhaseResult {
  startedAt: string;
  durationMs: number;
  success: boolean;
  details?: Record<string, unknown>;
}

interface AgentResult {
  model: string;
  promptTokens?: number;
  completionTokens?: number;
  durationMs: number;
  toolCalls?: number;
  confidence?: number;
}
```

### 2.2 Wide Event Builder

```typescript
// Build event throughout request lifecycle
export class PipelineEventBuilder {
  private event: Partial<PipelineEvent>;
  private startTime: number;

  constructor(sessionId: string, requestId: string) {
    this.startTime = Date.now();
    this.event = {
      sessionId,
      requestId,
      startedAt: new Date().toISOString(),
      files: {},
      phases: {},
      agents: {},
      result: { success: false },
    };
  }

  addFile(type: 'datamap' | 'banner' | 'spss', info: object) {
    this.event.files![type] = info;
    return this;
  }

  startPhase(name: keyof PipelineEvent['phases']) {
    return {
      end: (success: boolean, details?: object) => {
        this.event.phases![name] = {
          startedAt: new Date().toISOString(),
          durationMs: Date.now() - this.startTime,
          success,
          details,
        };
      },
    };
  }

  recordAgent(name: keyof PipelineEvent['agents'], result: AgentResult) {
    this.event.agents![name] = result;
    return this;
  }

  complete(success: boolean, result?: object) {
    this.event.result = { success, ...result };
    this.event.totalDurationMs = Date.now() - this.startTime;
    return this.event as PipelineEvent;
  }

  // Emit the wide event
  emit() {
    const finalEvent = this.complete(
      this.event.result?.success ?? false,
      this.event.result
    );

    // Log as structured JSON (easily ingested by observability tools)
    logger.info('Pipeline completed', finalEvent as LogContext);

    // Future: Send to Sentry, Honeycomb, etc.
    return finalEvent;
  }
}
```

### 2.3 Usage in API Route

```typescript
// src/app/api/process-crosstab/route.ts

export async function POST(request: Request) {
  const requestId = crypto.randomUUID();
  const sessionId = generateSessionId();

  // Create wide event builder at request start
  const pipelineEvent = new PipelineEventBuilder(sessionId, requestId);
  const log = logger.child({ sessionId, requestId });

  try {
    // Log file uploads
    pipelineEvent.addFile('datamap', {
      name: files.datamap.name,
      size: files.datamap.size
    });

    // Phase 5: Data Processing
    const phase5 = pipelineEvent.startPhase('phase5');
    log.info('Starting Phase 5: Data processing');
    // ... processing ...
    phase5.end(true, { variables: dataMap.variables.length });

    // BannerAgent
    log.debug('Running BannerAgent', { imageCount: images.length });
    const bannerStart = Date.now();
    const bannerResult = await runBannerAgent(/* ... */);
    pipelineEvent.recordAgent('banner', {
      model: getBannerModelName(),
      durationMs: Date.now() - bannerStart,
      confidence: bannerResult.confidence,
    });

    // ... continue through pipeline ...

    // Success - emit wide event
    pipelineEvent.complete(true, {
      tablesGenerated: tables.length
    }).emit();

    return NextResponse.json({ success: true, sessionId });

  } catch (error) {
    log.error('Pipeline failed', {
      error: error instanceof Error ? error.message : 'Unknown',
      stack: error instanceof Error ? error.stack : undefined,
    });

    // Failure - still emit wide event with error context
    pipelineEvent.complete(false, {
      errorMessage: error instanceof Error ? error.message : 'Unknown error',
      errorStack: error instanceof Error ? error.stack : undefined,
    }).emit();

    throw error;
  }
}
```

---

## Step 3: Migrate Existing Console Calls

### 3.1 Migration Strategy

Replace `console.*` calls incrementally, component by component:

| Priority | Component | Current Count | Complexity |
|----------|-----------|---------------|------------|
| 1 | `process-crosstab/route.ts` | 21 | High (main API) |
| 2 | `BannerAgent.ts` | 25 | Medium |
| 3 | `DataMapProcessor.ts` | 18 | Medium |
| 4 | `CrosstabAgent.ts` | 8 | Low |
| 5 | `TableAgent.ts` | 10 | Low |
| 6 | Other files | ~52 | Low |

### 3.2 Migration Patterns

**Before**:
```typescript
console.log(`[BannerAgent] Processing completed in ${processingTime}ms`);
```

**After**:
```typescript
log.info('Processing completed', {
  agent: 'BannerAgent',
  durationMs: processingTime,
  success: true
});
```

**Before**:
```typescript
console.error(`[API] R execution failed:`, error);
```

**After**:
```typescript
log.error('R execution failed', {
  phase: 'rExecution',
  error: error instanceof Error ? error.message : String(error),
  command: rCommand,
  exitCode: result.exitCode,
});
```

### 3.3 Preserving Component Prefixes

For backward compatibility in development, use child loggers:

```typescript
// At top of BannerAgent.ts
const log = logger.child({ component: 'BannerAgent' });

// Calls like log.info('...') will include component: 'BannerAgent'
```

---

## Step 4: Structured Agent Logging

### 4.1 Agent Execution Logging

Each agent call should log:
- Model used
- Token usage (if available)
- Tool calls made
- Confidence score
- Duration

```typescript
// src/lib/agentLogger.ts

export interface AgentLogContext {
  agent: string;
  model: string;
  sessionId: string;
}

export function logAgentStart(ctx: AgentLogContext, input: object) {
  const log = logger.child(ctx);
  log.info('Agent started', {
    inputKeys: Object.keys(input),
    inputSize: JSON.stringify(input).length,
  });
}

export function logAgentComplete(
  ctx: AgentLogContext,
  result: {
    success: boolean;
    durationMs: number;
    toolCalls?: number;
    confidence?: number;
    outputSize?: number;
  }
) {
  const log = logger.child(ctx);
  log.info('Agent completed', result);
}

export function logAgentToolCall(
  ctx: AgentLogContext,
  toolName: string,
  input: unknown,
  output: unknown
) {
  const log = logger.child(ctx);
  log.debug('Tool called', {
    tool: toolName,
    inputType: typeof input,
    outputType: typeof output,
  });
}
```

### 4.2 Scratchpad Integration

The scratchpad tool already captures agent reasoning. Integrate with logger:

```typescript
// In scratchpad.ts execute function
logger.trace('Scratchpad entry', {
  agent: agentName,
  action,
  contentLength: content.length,
  // Don't log full content at trace level to avoid bloat
  contentPreview: content.substring(0, 100),
});
```

---

## Step 5: API Request/Response Logging

### 5.1 Request Logging Middleware

Log every API request with context:

```typescript
// src/lib/requestLogger.ts

export function logRequest(request: Request, sessionId: string) {
  const log = logger.child({
    sessionId,
    path: new URL(request.url).pathname,
    method: request.method,
  });

  log.info('Request received', {
    contentType: request.headers.get('content-type'),
    contentLength: request.headers.get('content-length'),
    userAgent: request.headers.get('user-agent'),
  });

  return log;
}

export function logResponse(
  log: ReturnType<typeof logger.child>,
  status: number,
  durationMs: number,
  responseSize?: number
) {
  const level = status >= 500 ? 'error' : status >= 400 ? 'warn' : 'info';
  log[level]('Response sent', {
    status,
    durationMs,
    responseSize,
  });
}
```

### 5.2 Error Boundary Logging

Ensure all errors are captured with context:

```typescript
// Wrap in try/catch with detailed error logging
try {
  // ... api logic ...
} catch (error) {
  log.error('Unhandled error', {
    error: error instanceof Error ? error.message : String(error),
    stack: error instanceof Error ? error.stack : undefined,
    type: error?.constructor?.name,
    // Include any request context that might help debug
    phase: currentPhase,
    lastSuccessfulStep: lastStep,
  });
  throw error;
}
```

---

## Step 6: Environment Configuration

### 6.1 Update `src/lib/env.ts`

Add logging configuration to environment config:

```typescript
// Add to EnvironmentConfig interface
export interface EnvironmentConfig {
  // ... existing fields ...

  // Logging configuration
  logging: {
    level: 'error' | 'warn' | 'info' | 'debug' | 'trace';
    format: 'pretty' | 'json';
    includeTimestamp: boolean;
    includeFileLine: boolean;
    enableWideEvents: boolean;
  };
}

// In getEnvironmentConfig()
logging: {
  level: (process.env.LOG_LEVEL as LogLevel) ||
    (nodeEnv === 'production' ? 'info' : 'debug'),
  format: (process.env.LOG_FORMAT as 'pretty' | 'json') ||
    (nodeEnv === 'production' ? 'json' : 'pretty'),
  includeTimestamp: process.env.LOG_INCLUDE_TIMESTAMP !== 'false',
  includeFileLine: nodeEnv === 'development',
  enableWideEvents: process.env.LOG_WIDE_EVENTS !== 'false',
},
```

### 6.2 Update `.env.example`

```bash
# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

# Log level: error | warn | info | debug | trace
# Default: debug (development), info (production)
LOG_LEVEL=debug

# Output format: pretty (human readable) | json (structured)
# Default: pretty (development), json (production)
LOG_FORMAT=pretty

# Include ISO timestamp in logs
# Default: true
LOG_INCLUDE_TIMESTAMP=true

# Enable wide event logging (single structured event per request)
# Default: true
LOG_WIDE_EVENTS=true
```

---

## Step 7: Future - Sentry Integration

### 7.1 Planned Integration (Phase 2)

The existing `tracing.ts` has placeholders for Sentry:

```typescript
// Future enhancement to tracing.ts
import * as Sentry from '@sentry/nextjs';

export const logAgentExecution = (/* ... */) => {
  const config = getTracingConfig();

  // Existing console logging
  if (process.env.NODE_ENV === 'development') {
    logger.debug('Agent execution', { sessionId, agentName, duration });
  }

  // Send to Sentry as breadcrumb
  if (config.externalProvider === 'sentry') {
    Sentry.addBreadcrumb({
      category: 'agent',
      message: `${agentName} completed`,
      data: { sessionId, duration },
      level: 'info',
    });
  }
};
```

### 7.2 Error Capture

```typescript
// Enhance error logging to capture in Sentry
export function captureError(
  error: Error,
  context: Record<string, unknown>
) {
  logger.error(error.message, { ...context, stack: error.stack });

  if (process.env.SENTRY_DSN) {
    Sentry.withScope((scope) => {
      Object.entries(context).forEach(([key, value]) => {
        scope.setExtra(key, value);
      });
      Sentry.captureException(error);
    });
  }
}
```

---

## What We Log (Generously)

Following the "Logging Sucks" philosophy of generous logging:

### Always Log (INFO level)
- Request start/end with timing
- Each pipeline phase start/end
- Agent execution completion
- File operations (read/write/delete)
- R script execution results
- Final output generation

### Debug Level (Development Default)
- Variable counts and sizes
- Intermediate data shapes
- Tool calls within agents
- Confidence scores at each step
- Group-by-group processing details

### Trace Level (Very Verbose)
- Full request/response payloads (sanitized)
- Every scratchpad entry
- Function entry/exit
- Cache hits/misses
- All environment config values

### Error Level (Always)
- Exceptions with full stack traces
- Validation failures with input context
- External service failures (Azure, R)
- File system errors

---

## What We NEVER Log

Per CLAUDE.md security requirements:

- API keys or tokens
- User PII (names, emails, company names)
- Full file contents (only metadata)
- Sensitive survey responses
- Authentication credentials
- Internal network addresses

```typescript
// Sanitization helper
export function sanitizeForLog(obj: unknown): unknown {
  if (typeof obj !== 'object' || obj === null) return obj;

  const SENSITIVE_KEYS = [
    'apiKey', 'token', 'password', 'secret', 'credential',
    'email', 'name', 'phone', 'address', 'ssn'
  ];

  const sanitized = { ...obj as Record<string, unknown> };
  for (const key of Object.keys(sanitized)) {
    if (SENSITIVE_KEYS.some(s => key.toLowerCase().includes(s))) {
      sanitized[key] = '[REDACTED]';
    } else if (typeof sanitized[key] === 'object') {
      sanitized[key] = sanitizeForLog(sanitized[key]);
    }
  }
  return sanitized;
}
```

---

## Implementation Order

### Phase 1: Foundation (Immediate)
1. Create `src/lib/logger.ts` with basic log levels
2. Add logging config to `env.ts`
3. Update `.env.example`
4. Create child logger pattern

### Phase 2: Migration (1-2 days)
5. Migrate `process-crosstab/route.ts` (highest value)
6. Migrate agent files (BannerAgent, CrosstabAgent, TableAgent)
7. Migrate processors (DataMapProcessor, SPSSReader)
8. Migrate remaining files

### Phase 3: Wide Events (After Migration)
9. Implement `PipelineEventBuilder`
10. Integrate into main API route
11. Add to other critical paths

### Phase 4: Observability (Phase 2 - Later)
12. Sentry integration
13. Structured JSON export for aggregation
14. Dashboard/monitoring setup

---

## Success Criteria

After implementation:

1. **Single source of log control** - Change LOG_LEVEL to adjust all output
2. **Structured by default** - Every log is JSON-parseable in production
3. **Request traceability** - Follow any request through all agents/phases via sessionId
4. **Performance visibility** - Every significant operation has timing
5. **Debug without code changes** - Increase LOG_LEVEL to get more detail
6. **Production-safe** - No sensitive data ever logged
7. **Wide event per request** - One comprehensive event capturing entire pipeline

---

## References

- [Logging Sucks](https://loggingsucks.com/) - Core inspiration for generous, context-rich logging
- [Live Your Best Life With Structured Events](https://charity.wtf/2022/08/15/live-your-best-life-with-structured-events/) - Wide events philosophy
- [Observability Engineering (O'Reilly)](https://www.honeycomb.io/observability-engineering-oreilly-book) - Comprehensive observability guide
- [Better Stack: 12 Logging Best Practices](https://betterstack.com/community/guides/logging/logging-best-practices/) - Practical dos and don'ts

---

*Created: January 4, 2026*
*Status: Ready for Implementation*
