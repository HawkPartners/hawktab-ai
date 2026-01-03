/**
 * Shared types
 * Purpose: Common environment, limits, and execution context types for agents and APIs
 */

export interface ProcessingLimits {
  maxDataMapVariables: number;
  maxBannerColumns: number;
  // Legacy token limits (for backward compatibility)
  reasoningModelTokens: number;
  baseModelTokens: number;
  // Per-agent token limits
  crosstabModelTokens: number;
  bannerModelTokens: number;
  tableModelTokens: number;
}

export interface PromptVersions {
  crosstabPromptVersion: string;
  bannerPromptVersion: string;
  tablePromptVersion: string;
}

export interface EnvironmentConfig {
  // Azure OpenAI (required)
  azureApiKey: string;
  azureResourceName: string;
  azureApiVersion: string;  // e.g., '2024-10-21' for Azure AI Foundry

  // Legacy model configuration (for backward compatibility)
  reasoningModel: string;  // e.g., 'o4-mini' - alias for crosstabModel
  baseModel: string;       // e.g., 'gpt-5-nano' - alias for bannerModel

  // Per-agent model configuration (Azure deployment names)
  crosstabModel: string;   // e.g., 'o4-mini' - used by CrosstabAgent (complex validation)
  bannerModel: string;     // e.g., 'gpt-5-nano' - used by BannerAgent (vision/extraction)
  tableModel: string;      // e.g., 'gpt-5-nano' - used by TableAgent (table definitions)

  // Deprecated (optional, for rollback purposes)
  openaiApiKey?: string;

  nodeEnv: 'development' | 'production';
  tracingEnabled: boolean;  // Renamed from tracingDisabled (positive naming)
  tableAgentOnly: boolean;  // Stop after TableAgent, skip R generation (for testing)
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