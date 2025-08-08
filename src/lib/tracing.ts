/**
 * Tracing helpers
 * Purpose: Configure lightweight tracing and console logging in development
 * Usage: wrap major flows with withTrace() in agents; call forceFlush via provider when needed
 */

export interface TracingConfig {
  enabled: boolean;
  externalProvider?: string;
  includeSensitiveData: boolean;
}

export const getTracingConfig = (): TracingConfig => {
  return {
    enabled: process.env.OPENAI_AGENTS_DISABLE_TRACING !== 'true',
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