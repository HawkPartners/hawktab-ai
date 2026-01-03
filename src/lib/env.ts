/**
 * Environment configuration
 * Purpose: Resolve Azure OpenAI model, token limits, prompt versions, and validation
 * Required: AZURE_API_KEY, AZURE_RESOURCE_NAME, REASONING_MODEL, BASE_MODEL
 * Optional: NODE_ENV, prompt versions, token/limit overrides
 */

import { createAzure } from '@ai-sdk/azure';
import { EnvironmentConfig } from './types';

// Create Azure provider instance (cached)
let azureProvider: ReturnType<typeof createAzure> | null = null;

export const getAzureProvider = () => {
  if (!azureProvider) {
    const config = getEnvironmentConfig();
    azureProvider = createAzure({
      resourceName: config.azureResourceName,
      apiKey: config.azureApiKey,
      // Use explicit API version for Azure AI Foundry compatibility
      apiVersion: config.azureApiVersion,
      // Use deployment-based URLs (standard Azure OpenAI format)
      // URL format: https://{resourceName}.openai.azure.com/openai/deployments/{deploymentId}/...?api-version={apiVersion}
      useDeploymentBasedUrls: true,
    });
  }
  return azureProvider;
};

export const getEnvironmentConfig = (): EnvironmentConfig => {
  // Validate required Azure environment variables
  const azureApiKey = process.env.AZURE_API_KEY;
  const azureResourceName = process.env.AZURE_RESOURCE_NAME;

  if (!azureApiKey) {
    throw new Error('AZURE_API_KEY environment variable is required');
  }
  if (!azureResourceName) {
    throw new Error('AZURE_RESOURCE_NAME environment variable is required');
  }

  // Azure API version (for Azure AI Foundry compatibility)
  // See: https://learn.microsoft.com/en-us/azure/ai-services/openai/api-version-lifecycle
  const azureApiVersion = process.env.AZURE_API_VERSION || '2025-01-01-preview';

  // Per-agent model configuration (Azure deployment names)
  // New: Each agent has its own model configuration
  const crosstabModel = process.env.CROSSTAB_MODEL || process.env.REASONING_MODEL || 'o4-mini';
  const bannerModel = process.env.BANNER_MODEL || process.env.BASE_MODEL || 'gpt-5-nano';
  const tableModel = process.env.TABLE_MODEL || 'gpt-5-nano';

  // Legacy model aliases (for backward compatibility)
  const reasoningModel = process.env.REASONING_MODEL || crosstabModel;
  const baseModel = process.env.BASE_MODEL || bannerModel;

  const nodeEnv = (process.env.NODE_ENV as 'development' | 'production') || 'development';

  return {
    azureApiKey,
    azureResourceName,
    azureApiVersion,

    // Legacy model configuration (for backward compatibility)
    reasoningModel,
    baseModel,

    // Per-agent model configuration
    crosstabModel,
    bannerModel,
    tableModel,

    // Deprecated
    openaiApiKey: process.env.OPENAI_API_KEY,  // Optional, deprecated

    nodeEnv,
    tracingEnabled: process.env.TRACING_ENABLED !== 'false',  // Default: enabled
    tableAgentOnly: process.env.TABLE_AGENT_ONLY === 'true',  // Stop after TableAgent, skip R generation
    promptVersions: {
      crosstabPromptVersion: process.env.CROSSTAB_PROMPT_VERSION || 'production',
      bannerPromptVersion: process.env.BANNER_PROMPT_VERSION || 'production',
      tablePromptVersion: process.env.TABLE_PROMPT_VERSION || 'production',
    },
    processingLimits: {
      maxDataMapVariables: parseInt(process.env.MAX_DATA_MAP_VARIABLES || '1000'),
      maxBannerColumns: parseInt(process.env.MAX_BANNER_COLUMNS || '100'),
      // Legacy token limits (for backward compatibility)
      reasoningModelTokens: parseInt(process.env.REASONING_MODEL_TOKENS || '100000'),
      baseModelTokens: parseInt(process.env.BASE_MODEL_TOKENS || '128000'),
      // Per-agent token limits
      crosstabModelTokens: parseInt(process.env.CROSSTAB_MODEL_TOKENS || process.env.REASONING_MODEL_TOKENS || '100000'),
      bannerModelTokens: parseInt(process.env.BANNER_MODEL_TOKENS || process.env.BASE_MODEL_TOKENS || '128000'),
      tableModelTokens: parseInt(process.env.TABLE_MODEL_TOKENS || '128000'),
    },
  };
};

/**
 * Per-Agent Model Selection
 * Each agent has its own model configuration for flexibility:
 * - CrosstabAgent: Complex validation, R syntax generation (requires reasoning)
 * - BannerAgent: Vision/extraction tasks (requires multimodal support)
 * - TableAgent: Table definition generation (new agent)
 *
 * NOTE: Using .chat() for Chat Completions API instead of Responses API
 * The Responses API (default in AI SDK v6) may not be available on all Azure deployments
 */

/**
 * Get CrosstabAgent model for complex validation tasks
 * Used by: CrosstabAgent (requires deep reasoning for R syntax generation)
 */
export const getCrosstabModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.crosstabModel);
};

/**
 * Get BannerAgent model for vision/extraction tasks
 * Used by: BannerAgent (requires vision capability, simpler reasoning)
 */
export const getBannerModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.bannerModel);
};

/**
 * Get TableAgent model for table definition generation
 * Used by: TableAgent (generates table definitions from datamap + survey)
 */
export const getTableModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.tableModel);
};

/**
 * Get per-agent model name strings (for logging)
 */
export const getCrosstabModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.crosstabModel}`;
};

export const getBannerModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.bannerModel}`;
};

export const getTableModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.tableModel}`;
};

/**
 * Get per-agent token limits
 */
export const getCrosstabModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.crosstabModelTokens;
};

export const getBannerModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.bannerModelTokens;
};

export const getTableModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.tableModelTokens;
};

// =============================================================================
// Legacy Model Selection (Backward Compatibility)
// These functions are deprecated but maintained for existing code
// =============================================================================

/**
 * @deprecated Use getCrosstabModel() instead
 * Get reasoning model for complex validation tasks
 */
export const getReasoningModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.reasoningModel);
};

/**
 * @deprecated Use getBannerModel() instead
 * Get base model for vision/extraction tasks
 */
export const getBaseModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.baseModel);
};

/**
 * @deprecated Use getCrosstabModelName() instead
 */
export const getReasoningModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.reasoningModel}`;
};

/**
 * @deprecated Use getBannerModelName() instead
 */
export const getBaseModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.baseModel}`;
};

/**
 * @deprecated Use getCrosstabModelTokenLimit() instead
 */
export const getReasoningModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.reasoningModelTokens;
};

/**
 * @deprecated Use getBannerModelTokenLimit() instead
 */
export const getBaseModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.baseModelTokens;
};

export const getPromptVersions = () => {
  const config = getEnvironmentConfig();
  return config.promptVersions;
};

/**
 * Check if TABLE_AGENT_ONLY mode is enabled
 * When true, API stops after TableAgent processing and returns JSON definitions
 * instead of triggering R script generation
 */
export const isTableAgentOnlyMode = (): boolean => {
  const config = getEnvironmentConfig();
  return config.tableAgentOnly;
};

export const validateEnvironment = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = [];

  try {
    const config = getEnvironmentConfig();

    // Azure API key format is flexible (not sk-* like OpenAI)
    if (config.azureApiKey.length < 10) {
      errors.push('AZURE_API_KEY appears too short');
    }

    // Validate resource name format
    if (!/^[a-zA-Z0-9-]+$/.test(config.azureResourceName)) {
      errors.push('AZURE_RESOURCE_NAME should only contain alphanumeric characters and hyphens');
    }

    // Validate processing limits
    if (config.processingLimits.maxDataMapVariables < 1) {
      errors.push('MAX_DATA_MAP_VARIABLES must be greater than 0');
    }

    if (config.processingLimits.maxBannerColumns < 1) {
      errors.push('MAX_BANNER_COLUMNS must be greater than 0');
    }

    // Legacy token limit validation (for backward compatibility)
    if (config.processingLimits.reasoningModelTokens < 1000) {
      errors.push('REASONING_MODEL_TOKENS must be at least 1000');
    }

    if (config.processingLimits.baseModelTokens < 1000) {
      errors.push('BASE_MODEL_TOKENS must be at least 1000');
    }

    // Per-agent token limit validation
    if (config.processingLimits.crosstabModelTokens < 1000) {
      errors.push('CROSSTAB_MODEL_TOKENS must be at least 1000');
    }

    if (config.processingLimits.bannerModelTokens < 1000) {
      errors.push('BANNER_MODEL_TOKENS must be at least 1000');
    }

    if (config.processingLimits.tableModelTokens < 1000) {
      errors.push('TABLE_MODEL_TOKENS must be at least 1000');
    }

  } catch (error) {
    errors.push(error instanceof Error ? error.message : 'Unknown environment error');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

// Legacy compatibility exports (deprecated - will be removed in future)
// These redirect to the appropriate task-based functions for any code that hasn't been migrated yet

/**
 * @deprecated Use getReasoningModel() or getBaseModel() instead based on task requirements
 */
export const getModel = (): string => {
  console.warn('[env.ts] getModel() is deprecated. Use getReasoningModel() or getBaseModel() based on task requirements.');
  const config = getEnvironmentConfig();
  // Default to reasoning model for backward compatibility
  return config.reasoningModel;
};

/**
 * @deprecated Use getReasoningModelTokenLimit() or getBaseModelTokenLimit() instead
 */
export const getModelTokenLimit = (): number => {
  console.warn('[env.ts] getModelTokenLimit() is deprecated. Use getReasoningModelTokenLimit() or getBaseModelTokenLimit().');
  const config = getEnvironmentConfig();
  // Default to reasoning model tokens for backward compatibility
  return config.processingLimits.reasoningModelTokens;
};

/**
 * @deprecated Model selection is now task-based, not environment-based
 */
export const getModelConfig = () => {
  console.warn('[env.ts] getModelConfig() is deprecated. Model selection is now task-based.');
  const config = getEnvironmentConfig();

  return {
    model: config.reasoningModel,
    tokenLimit: config.processingLimits.reasoningModelTokens,
    environment: config.nodeEnv,
  };
};
