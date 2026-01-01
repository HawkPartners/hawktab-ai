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

  // Model configuration (Azure deployment names)
  const reasoningModel = process.env.REASONING_MODEL || 'o4-mini';
  const baseModel = process.env.BASE_MODEL || 'gpt-5-nano';

  const nodeEnv = (process.env.NODE_ENV as 'development' | 'production') || 'development';

  return {
    azureApiKey,
    azureResourceName,
    azureApiVersion,

    // Model configuration
    reasoningModel,
    baseModel,

    // Deprecated
    openaiApiKey: process.env.OPENAI_API_KEY,  // Optional, deprecated

    nodeEnv,
    tracingEnabled: process.env.TRACING_ENABLED !== 'false',  // Default: enabled
    promptVersions: {
      crosstabPromptVersion: process.env.CROSSTAB_PROMPT_VERSION || 'production',
      bannerPromptVersion: process.env.BANNER_PROMPT_VERSION || 'production',
    },
    processingLimits: {
      maxDataMapVariables: parseInt(process.env.MAX_DATA_MAP_VARIABLES || '1000'),
      maxBannerColumns: parseInt(process.env.MAX_BANNER_COLUMNS || '100'),
      reasoningModelTokens: parseInt(process.env.REASONING_MODEL_TOKENS || '100000'),
      baseModelTokens: parseInt(process.env.BASE_MODEL_TOKENS || '128000'),
    },
  };
};

/**
 * Task-based model selection
 * Models are chosen based on task requirements, not environment:
 * - Reasoning model (o4-mini): Complex validation tasks (CrosstabAgent)
 * - Base model (gpt-5-nano): Vision/extraction tasks (BannerAgent)
 */

/**
 * Get reasoning model for complex validation tasks
 * Used by: CrosstabAgent (requires deep reasoning for R syntax generation)
 *
 * NOTE: Using .chat() for Chat Completions API instead of Responses API
 * The Responses API (default in AI SDK v6) may not be available on all Azure deployments
 */
export const getReasoningModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.reasoningModel);  // Use Chat Completions API
};

/**
 * Get base model for vision/extraction tasks
 * Used by: BannerAgent (requires vision capability, simpler reasoning)
 *
 * NOTE: Using .chat() for Chat Completions API instead of Responses API
 * Vision should work with Chat Completions API on multimodal models
 */
export const getBaseModel = () => {
  const config = getEnvironmentConfig();
  const provider = getAzureProvider();
  return provider.chat(config.baseModel);  // Use Chat Completions API
};

/**
 * Get model name string (for logging)
 */
export const getReasoningModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.reasoningModel}`;
};

export const getBaseModelName = (): string => {
  const config = getEnvironmentConfig();
  return `azure/${config.baseModel}`;
};

export const getReasoningModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.reasoningModelTokens;
};

export const getBaseModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.baseModelTokens;
};

export const getPromptVersions = () => {
  const config = getEnvironmentConfig();
  return config.promptVersions;
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

    if (config.processingLimits.reasoningModelTokens < 1000) {
      errors.push('REASONING_MODEL_TOKENS must be at least 1000');
    }

    if (config.processingLimits.baseModelTokens < 1000) {
      errors.push('BASE_MODEL_TOKENS must be at least 1000');
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
