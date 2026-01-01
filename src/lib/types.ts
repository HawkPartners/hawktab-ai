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
  // Azure OpenAI (required)
  azureApiKey: string;
  azureResourceName: string;
  azureApiVersion: string;  // e.g., '2024-10-21' for Azure AI Foundry

  // Model configuration (Azure deployment names)
  reasoningModel: string;  // e.g., 'o4-mini' - used by CrosstabAgent
  baseModel: string;       // e.g., 'gpt-5-nano' - used by BannerAgent (must support vision)

  // Deprecated (optional, for rollback purposes)
  openaiApiKey?: string;

  nodeEnv: 'development' | 'production';
  tracingEnabled: boolean;  // Renamed from tracingDisabled (positive naming)
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