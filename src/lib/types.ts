/**
 * Shared types
 * Purpose: Common environment, limits, and execution context types for agents and APIs
 */

export interface ProcessingLimits {
  maxDataMapVariables: number;
  maxBannerColumns: number;
  reasoningModelTokens: number;
  baseModelTokens: number;
}

export interface PromptVersions {
  crosstabPromptVersion: string;
  bannerPromptVersion: string;
}

export interface EnvironmentConfig {
  reasoningModel: string;
  baseModel: string;
  openaiApiKey: string;
  nodeEnv: 'development' | 'production';
  tracingDisabled: boolean;
  promptVersions: PromptVersions;
  processingLimits: ProcessingLimits;
}

export interface FileUploadResult {
  success: boolean;
  filePath?: string;
  error?: string;
}

export interface ProcessingContext {
  sessionId: string;
  timestamp: string;
  environment: 'development' | 'production';
  model: string;
}

// Agent execution results
export interface AgentExecutionResult<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  context: ProcessingContext;
}