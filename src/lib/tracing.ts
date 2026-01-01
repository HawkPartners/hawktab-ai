/**
 * Tracing helpers
 * Purpose: Structured logging for observability (Sentry integration in Phase 2)
 * Usage: Call logAgentExecution() to record agent operations with timing
 */

export interface TracingConfig {
  enabled: boolean;
  externalProvider?: string;
  includeSensitiveData: boolean;
}

export const getTracingConfig = (): TracingConfig => {
  return {
    // Changed from OPENAI_AGENTS_DISABLE_TRACING to generic TRACING_ENABLED
    // Default: enabled (must explicitly set to 'false' to disable)
    enabled: process.env.TRACING_ENABLED !== 'false',
    externalProvider: process.env.TRACE_EXTERNAL_PROVIDER,
    includeSensitiveData: false, // Never include sensitive data in traces
  };
};

export const createTraceSession = (sessionId: string) => {
  const config = getTracingConfig();
  
  if (!config.enabled) {
    return null;
  }

  // Future: integrate with external providers like AgentOps
  return {
    sessionId,
    startTime: new Date(),
    config,
  };
};

export const logAgentExecution = (
  sessionId: string,
  agentName: string,
  input: unknown,
  output: unknown,
  duration: number
) => {
  const config = getTracingConfig();
  
  if (!config.enabled) {
    return;
  }

  // For now, log to console in development
  if (process.env.NODE_ENV === 'development') {
    console.log(`[TRACE:${sessionId}] ${agentName}`, {
      duration: `${duration}ms`,
      inputType: typeof input,
      outputType: typeof output,
    });
  }

  // Future: send to external providers
};