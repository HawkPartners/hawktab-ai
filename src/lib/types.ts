/**
 * Shared types
 * Purpose: Common environment, limits, and execution context types for agents and APIs
 */

/**
 * Reasoning effort levels supported by Azure OpenAI GPT-5 and o-series models
 * - 'none': No reasoning (GPT-5.1 only)
 * - 'minimal': Fastest responses, basic reasoning
 * - 'low': Quick reasoning, good for simple tasks
 * - 'medium': Default, balanced reasoning (AI SDK default)
 * - 'high': Deep reasoning, complex tasks
 * - 'xhigh': Maximum reasoning (GPT-5.1-Codex-Max only)
 */
export type ReasoningEffort = 'none' | 'minimal' | 'low' | 'medium' | 'high' | 'xhigh';

/**
 * Per-agent reasoning effort configuration
 */
export interface AgentReasoningConfig {
  crosstabReasoningEffort: ReasoningEffort;
  bannerReasoningEffort: ReasoningEffort;
  verificationReasoningEffort: ReasoningEffort;
  skipLogicReasoningEffort: ReasoningEffort;
  filterTranslatorReasoningEffort: ReasoningEffort;
}

export interface ProcessingLimits {
  maxDataMapVariables: number;
  maxBannerColumns: number;
  // Legacy token limits (for backward compatibility)
  reasoningModelTokens: number;
  baseModelTokens: number;
  // Per-agent token limits
  crosstabModelTokens: number;
  bannerModelTokens: number;
  verificationModelTokens: number;
  skipLogicModelTokens: number;
  filterTranslatorModelTokens: number;
}

export interface PromptVersions {
  crosstabPromptVersion: string;
  bannerPromptVersion: string;
  verificationPromptVersion: string;
  skipLogicPromptVersion: string;
  filterTranslatorPromptVersion: string;
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
  verificationModel: string; // e.g., 'gpt-5-mini' - used by VerificationAgent (survey enhancement)
  skipLogicModel: string;    // e.g., 'gpt-5-mini' - used by SkipLogicAgent (survey rule extraction)
  filterTranslatorModel: string; // e.g., 'o4-mini' - used by FilterTranslatorAgent (R expression translation)

  // Deprecated (optional, for rollback purposes)
  openaiApiKey?: string;

  nodeEnv: 'development' | 'production';
  tracingEnabled: boolean;  // Renamed from tracingDisabled (positive naming)
  promptVersions: PromptVersions;
  processingLimits: ProcessingLimits;
  reasoningConfig: AgentReasoningConfig;
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