/**
 * Environment configuration
 * Purpose: Resolve AI model provider, token limits, prompt versions, reasoning effort, and validation
 *
 * Provider selection:
 * - AI_PROVIDER=azure (default): Uses Azure OpenAI. Requires AZURE_API_KEY, AZURE_RESOURCE_NAME.
 * - AI_PROVIDER=openai: Uses OpenAI directly. Requires OPENAI_API_KEY.
 *
 * Per-Agent Configuration Pattern (works with both providers):
 * - CROSSTAB_MODEL, CROSSTAB_MODEL_TOKENS, CROSSTAB_PROMPT_VERSION, CROSSTAB_REASONING_EFFORT
 * - BANNER_MODEL, BANNER_MODEL_TOKENS, BANNER_PROMPT_VERSION, BANNER_REASONING_EFFORT
 * - VERIFICATION_MODEL, VERIFICATION_MODEL_TOKENS, VERIFICATION_PROMPT_VERSION, VERIFICATION_REASONING_EFFORT
 */

import { createAzure } from '@ai-sdk/azure';
import { createOpenAI } from '@ai-sdk/openai';
import { EnvironmentConfig, AIProvider, ReasoningEffort } from './types';

// =============================================================================
// Stat Testing Configuration
// =============================================================================

/**
 * Proportion test types (for frequency tables)
 * - 'unpooled_z': Unpooled z-test for proportions (WinCross default)
 * - 'pooled_z': Pooled z-test for proportions
 */
export type ProportionTestType = 'unpooled_z' | 'pooled_z';

/**
 * Mean test types (for mean_rows tables)
 * - 'welch_t': Welch's t-test (unequal variances - more robust)
 * - 'student_t': Student's t-test (assumes equal variances)
 */
export type MeanTestType = 'welch_t' | 'student_t';

/**
 * Statistical testing configuration
 */
export interface StatTestingConfig {
  /** Significance thresholds (e.g., [0.05, 0.10] for dual 95%/90% confidence) */
  thresholds: number[];
  /** Proportion test type for frequency tables */
  proportionTest: ProportionTestType;
  /** Mean test type for mean_rows tables */
  meanTest: MeanTestType;
  /** Minimum base size for testing (0 = no minimum) */
  minBase: number;
}

/**
 * Default stat testing configuration (matches WinCross defaults)
 */
export const DEFAULT_STAT_TESTING_CONFIG: StatTestingConfig = {
  thresholds: [0.10],           // 90% confidence
  proportionTest: 'unpooled_z', // WinCross default
  meanTest: 'welch_t',          // More robust for unequal variances
  minBase: 0,                   // No minimum (WinCross tests all data)
};

/**
 * Valid reasoning effort levels for Azure OpenAI GPT-5 and o-series models
 * @see https://learn.microsoft.com/en-us/azure/ai-foundry/openai/how-to/reasoning
 */
const VALID_REASONING_EFFORTS: ReasoningEffort[] = ['none', 'minimal', 'low', 'medium', 'high', 'xhigh'];

/**
 * Parse and validate reasoning effort from environment variable
 * Defaults to 'medium' (AI SDK default) if not specified or invalid
 */
function parseReasoningEffort(value: string | undefined, agentName: string): ReasoningEffort {
  if (!value) return 'medium';
  const normalized = value.toLowerCase().trim() as ReasoningEffort;
  if (VALID_REASONING_EFFORTS.includes(normalized)) {
    return normalized;
  }
  console.warn(`[env.ts] Invalid ${agentName}_REASONING_EFFORT "${value}", using default "medium"`);
  return 'medium';
}

// =============================================================================
// Provider Management
// =============================================================================

// Cached provider instances
let azureProvider: ReturnType<typeof createAzure> | null = null;
let openaiProvider: ReturnType<typeof createOpenAI> | null = null;

/**
 * Resolve which AI provider to use from AI_PROVIDER env var.
 * Default: 'azure' for backward compatibility.
 */
function resolveAIProvider(): AIProvider {
  const value = (process.env.AI_PROVIDER || 'azure').toLowerCase().trim();
  if (value === 'openai') return 'openai';
  if (value === 'azure') return 'azure';
  console.warn(`[env.ts] Invalid AI_PROVIDER "${value}", falling back to "azure"`);
  return 'azure';
}

export const getAzureProvider = () => {
  if (!azureProvider) {
    const config = getEnvironmentConfig();
    if (!config.azureApiKey || !config.azureResourceName) {
      throw new Error('Azure provider requires AZURE_API_KEY and AZURE_RESOURCE_NAME');
    }
    azureProvider = createAzure({
      resourceName: config.azureResourceName,
      apiKey: config.azureApiKey,
      apiVersion: config.azureApiVersion,
      useDeploymentBasedUrls: true,
    });
  }
  return azureProvider;
};

export const getOpenAIProvider = () => {
  if (!openaiProvider) {
    const config = getEnvironmentConfig();
    if (!config.openaiApiKey) {
      throw new Error('OpenAI provider requires OPENAI_API_KEY');
    }
    openaiProvider = createOpenAI({
      apiKey: config.openaiApiKey,
    });
  }
  return openaiProvider;
};

/**
 * Get the active chat model provider based on AI_PROVIDER setting.
 * Returns a function that accepts a model/deployment name and returns an AI SDK model.
 */
export const getActiveProvider = () => {
  const provider = resolveAIProvider();
  if (provider === 'openai') {
    return getOpenAIProvider();
  }
  return getAzureProvider();
};

export const getEnvironmentConfig = (): EnvironmentConfig => {
  const aiProvider = resolveAIProvider();

  // Validate credentials based on selected provider
  const azureApiKey = process.env.AZURE_API_KEY || '';
  const azureResourceName = process.env.AZURE_RESOURCE_NAME || '';
  const openaiApiKey = process.env.OPENAI_API_KEY;

  if (aiProvider === 'azure') {
    if (!azureApiKey) {
      throw new Error('AZURE_API_KEY environment variable is required when AI_PROVIDER=azure');
    }
    if (!azureResourceName) {
      throw new Error('AZURE_RESOURCE_NAME environment variable is required when AI_PROVIDER=azure');
    }
  } else if (aiProvider === 'openai') {
    if (!openaiApiKey) {
      throw new Error('OPENAI_API_KEY environment variable is required when AI_PROVIDER=openai');
    }
  }

  // Azure API version (only relevant for Azure provider)
  const azureApiVersion = process.env.AZURE_API_VERSION || '2025-01-01-preview';

  // Per-agent model configuration (Azure deployment names / OpenAI model IDs)
  // Model names are the same for both providers (gpt-5-mini, o4-mini, etc.)
  const crosstabModel = process.env.CROSSTAB_MODEL || process.env.REASONING_MODEL || 'o4-mini';
  const bannerModel = process.env.BANNER_MODEL || process.env.BASE_MODEL || 'gpt-5-nano';
  const verificationModel = process.env.VERIFICATION_MODEL || process.env.TABLE_MODEL || 'gpt-5-mini';
  const bannerGenerateModel = process.env.BANNER_GENERATE_MODEL || verificationModel;
  const skipLogicModel = process.env.SKIPLOGIC_MODEL || verificationModel;
  const filterTranslatorModel = process.env.FILTERTRANSLATOR_MODEL || crosstabModel;
  const loopSemanticsModel = process.env.LOOP_SEMANTICS_MODEL || verificationModel;

  // Legacy model aliases (for backward compatibility)
  const reasoningModel = process.env.REASONING_MODEL || crosstabModel;
  const baseModel = process.env.BASE_MODEL || bannerModel;

  // Per-agent reasoning effort configuration
  const crosstabReasoningEffort = parseReasoningEffort(process.env.CROSSTAB_REASONING_EFFORT, 'CROSSTAB');
  const bannerReasoningEffort = parseReasoningEffort(process.env.BANNER_REASONING_EFFORT, 'BANNER');
  const bannerGenerateReasoningEffort = parseReasoningEffort(process.env.BANNER_GENERATE_REASONING_EFFORT || 'high', 'BANNER_GENERATE');
  const verificationReasoningEffort = parseReasoningEffort(process.env.VERIFICATION_REASONING_EFFORT, 'VERIFICATION');
  const skipLogicReasoningEffort = parseReasoningEffort(process.env.SKIPLOGIC_REASONING_EFFORT, 'SKIPLOGIC');
  const filterTranslatorReasoningEffort = parseReasoningEffort(process.env.FILTERTRANSLATOR_REASONING_EFFORT, 'FILTERTRANSLATOR');
  const loopSemanticsReasoningEffort = parseReasoningEffort(process.env.LOOP_SEMANTICS_REASONING_EFFORT, 'LOOP_SEMANTICS');

  const nodeEnv = (process.env.NODE_ENV as 'development' | 'production') || 'development';

  return {
    aiProvider,
    azureApiKey,
    azureResourceName,
    azureApiVersion,
    openaiApiKey,

    // Legacy model configuration (for backward compatibility)
    reasoningModel,
    baseModel,

    // Per-agent model configuration
    crosstabModel,
    bannerModel,
    bannerGenerateModel,
    verificationModel,
    skipLogicModel,
    filterTranslatorModel,
    loopSemanticsModel,

    nodeEnv,
    tracingEnabled: process.env.TRACING_ENABLED !== 'false',
    promptVersions: {
      crosstabPromptVersion: process.env.CROSSTAB_PROMPT_VERSION || 'production',
      bannerPromptVersion: process.env.BANNER_PROMPT_VERSION || 'production',
      verificationPromptVersion: process.env.VERIFICATION_PROMPT_VERSION || 'production',
      skipLogicPromptVersion: process.env.SKIPLOGIC_PROMPT_VERSION || 'production',
      filterTranslatorPromptVersion: process.env.FILTERTRANSLATOR_PROMPT_VERSION || 'production',
      loopSemanticsPromptVersion: process.env.LOOP_SEMANTICS_PROMPT_VERSION || 'production',
      bannerGeneratePromptVersion: process.env.BANNER_GENERATE_PROMPT_VERSION || 'production',
    },
    processingLimits: {
      maxDataMapVariables: parseInt(process.env.MAX_DATA_MAP_VARIABLES || '1000'),
      maxBannerColumns: parseInt(process.env.MAX_BANNER_COLUMNS || '100'),
      reasoningModelTokens: parseInt(process.env.REASONING_MODEL_TOKENS || '100000'),
      baseModelTokens: parseInt(process.env.BASE_MODEL_TOKENS || '128000'),
      crosstabModelTokens: parseInt(process.env.CROSSTAB_MODEL_TOKENS || process.env.REASONING_MODEL_TOKENS || '100000'),
      bannerModelTokens: parseInt(process.env.BANNER_MODEL_TOKENS || process.env.BASE_MODEL_TOKENS || '128000'),
      bannerGenerateModelTokens: parseInt(process.env.BANNER_GENERATE_MODEL_TOKENS || process.env.VERIFICATION_MODEL_TOKENS || '128000'),
      verificationModelTokens: parseInt(process.env.VERIFICATION_MODEL_TOKENS || process.env.TABLE_MODEL_TOKENS || '128000'),
      skipLogicModelTokens: parseInt(process.env.SKIPLOGIC_MODEL_TOKENS || process.env.VERIFICATION_MODEL_TOKENS || '128000'),
      filterTranslatorModelTokens: parseInt(process.env.FILTERTRANSLATOR_MODEL_TOKENS || process.env.CROSSTAB_MODEL_TOKENS || '100000'),
      loopSemanticsModelTokens: parseInt(process.env.LOOP_SEMANTICS_MODEL_TOKENS || process.env.VERIFICATION_MODEL_TOKENS || '128000'),
    },
    reasoningConfig: {
      crosstabReasoningEffort,
      bannerReasoningEffort,
      bannerGenerateReasoningEffort,
      verificationReasoningEffort,
      skipLogicReasoningEffort,
      filterTranslatorReasoningEffort,
      loopSemanticsReasoningEffort,
    },
  };
};

/**
 * Per-Agent Model Selection
 * Each agent has its own model configuration for flexibility.
 * Uses getActiveProvider() to route through Azure or OpenAI based on AI_PROVIDER.
 *
 * NOTE: Using .chat() for Chat Completions API instead of Responses API
 * The Responses API (default in AI SDK v6) may not be available on all Azure deployments.
 */

export const getCrosstabModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.crosstabModel);
};

export const getBannerModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.bannerModel);
};

export const getBannerGenerateModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.bannerGenerateModel);
};

export const getVerificationModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.verificationModel);
};

export const getSkipLogicModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.skipLogicModel);
};

export const getFilterTranslatorModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.filterTranslatorModel);
};

export const getLoopSemanticsModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.loopSemanticsModel);
};

/**
 * Get per-agent model name strings (for logging)
 */
export const getCrosstabModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.crosstabModel}`;
};

export const getBannerModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.bannerModel}`;
};

export const getBannerGenerateModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.bannerGenerateModel}`;
};

export const getVerificationModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.verificationModel}`;
};

export const getSkipLogicModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.skipLogicModel}`;
};

export const getFilterTranslatorModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.filterTranslatorModel}`;
};

export const getLoopSemanticsModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.loopSemanticsModel}`;
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

export const getBannerGenerateModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.bannerGenerateModelTokens;
};

export const getVerificationModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.verificationModelTokens;
};

export const getSkipLogicModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.skipLogicModelTokens;
};

export const getFilterTranslatorModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.filterTranslatorModelTokens;
};

export const getLoopSemanticsModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  return config.processingLimits.loopSemanticsModelTokens;
};

// =============================================================================
// Per-Agent Reasoning Effort Configuration
// Used to configure how much reasoning effort the model applies
// =============================================================================

/**
 * Get per-agent reasoning effort levels
 * Returns the configured reasoning effort for each agent
 * Used with providerOptions: { openai: { reasoningEffort: '...' } }
 */
export const getCrosstabReasoningEffort = (): ReasoningEffort => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig.crosstabReasoningEffort;
};

export const getBannerReasoningEffort = (): ReasoningEffort => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig.bannerReasoningEffort;
};

export const getBannerGenerateReasoningEffort = (): ReasoningEffort => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig.bannerGenerateReasoningEffort;
};

export const getVerificationReasoningEffort = (): ReasoningEffort => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig.verificationReasoningEffort;
};

export const getSkipLogicReasoningEffort = (): ReasoningEffort => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig.skipLogicReasoningEffort;
};

export const getFilterTranslatorReasoningEffort = (): ReasoningEffort => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig.filterTranslatorReasoningEffort;
};

export const getLoopSemanticsReasoningEffort = (): ReasoningEffort => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig.loopSemanticsReasoningEffort;
};

/**
 * Get all reasoning effort configuration (for logging/debugging)
 */
export const getReasoningConfig = () => {
  const config = getEnvironmentConfig();
  return config.reasoningConfig;
};

// =============================================================================
// Stat Testing Configuration
// =============================================================================

/**
 * Parse significance thresholds from environment variable
 * Supports single value (e.g., "0.10") or comma-separated dual values (e.g., "0.05,0.10")
 */
function parseStatThresholds(value: string | undefined): number[] {
  if (!value) return DEFAULT_STAT_TESTING_CONFIG.thresholds;

  const parts = value.split(',').map(p => parseFloat(p.trim())).filter(n => !isNaN(n) && n > 0 && n < 1);
  if (parts.length === 0) {
    console.warn(`[env.ts] Invalid STAT_THRESHOLDS "${value}", using default "${DEFAULT_STAT_TESTING_CONFIG.thresholds.join(',')}"`);
    return DEFAULT_STAT_TESTING_CONFIG.thresholds;
  }

  // Sort ascending (lower threshold = higher confidence first)
  return parts.sort((a, b) => a - b);
}

/**
 * Parse proportion test type from environment variable
 */
function parseProportionTest(value: string | undefined): ProportionTestType {
  if (!value) return DEFAULT_STAT_TESTING_CONFIG.proportionTest;
  const normalized = value.toLowerCase().trim();
  if (normalized === 'unpooled_z' || normalized === 'pooled_z') {
    return normalized;
  }
  console.warn(`[env.ts] Invalid STAT_PROPORTION_TEST "${value}", using default "${DEFAULT_STAT_TESTING_CONFIG.proportionTest}"`);
  return DEFAULT_STAT_TESTING_CONFIG.proportionTest;
}

/**
 * Parse mean test type from environment variable
 */
function parseMeanTest(value: string | undefined): MeanTestType {
  if (!value) return DEFAULT_STAT_TESTING_CONFIG.meanTest;
  const normalized = value.toLowerCase().trim();
  if (normalized === 'welch_t' || normalized === 'student_t') {
    return normalized;
  }
  console.warn(`[env.ts] Invalid STAT_MEAN_TEST "${value}", using default "${DEFAULT_STAT_TESTING_CONFIG.meanTest}"`);
  return DEFAULT_STAT_TESTING_CONFIG.meanTest;
}

/**
 * Parse minimum base size from environment variable
 */
function parseMinBase(value: string | undefined): number {
  if (!value) return DEFAULT_STAT_TESTING_CONFIG.minBase;
  const parsed = parseInt(value, 10);
  if (isNaN(parsed) || parsed < 0) {
    console.warn(`[env.ts] Invalid STAT_MIN_BASE "${value}", using default "${DEFAULT_STAT_TESTING_CONFIG.minBase}"`);
    return DEFAULT_STAT_TESTING_CONFIG.minBase;
  }
  return parsed;
}

/**
 * Get statistical testing configuration from environment variables
 *
 * Environment variables:
 * - STAT_THRESHOLDS: Comma-separated significance thresholds (e.g., "0.05,0.10")
 * - STAT_PROPORTION_TEST: "unpooled_z" (default) or "pooled_z"
 * - STAT_MEAN_TEST: "welch_t" (default) or "student_t"
 * - STAT_MIN_BASE: Minimum base size for testing (default: 0 = no minimum)
 */
export function getStatTestingConfig(): StatTestingConfig {
  return {
    thresholds: parseStatThresholds(process.env.STAT_THRESHOLDS),
    proportionTest: parseProportionTest(process.env.STAT_PROPORTION_TEST),
    meanTest: parseMeanTest(process.env.STAT_MEAN_TEST),
    minBase: parseMinBase(process.env.STAT_MIN_BASE),
  };
}

/**
 * Format stat testing config for display
 * Returns a human-readable description of the current settings
 */
export function formatStatTestingConfig(config: StatTestingConfig): string {
  const lines: string[] = [];

  // Confidence levels
  if (config.thresholds.length === 1) {
    const confidence = Math.round((1 - config.thresholds[0]) * 100);
    lines.push(`Confidence Level: ${confidence}% (p < ${config.thresholds[0]})`);
  } else {
    const confidences = config.thresholds.map(t => Math.round((1 - t) * 100));
    lines.push(`Confidence Levels: ${confidences.join('%, ')}% (p < ${config.thresholds.join(', ')})`);
    lines.push(`Notation: uppercase (p < ${config.thresholds[0]}), lowercase (p < ${config.thresholds[1]})`);
  }

  // Test types
  const proportionTestName = config.proportionTest === 'unpooled_z'
    ? 'Unpooled z-test (WinCross default)'
    : 'Pooled z-test';
  lines.push(`Proportion Test: ${proportionTestName}`);

  const meanTestName = config.meanTest === 'welch_t'
    ? "Welch's t-test (unequal variances)"
    : "Student's t-test (equal variances)";
  lines.push(`Mean Test: ${meanTestName}`);

  // Minimum base
  if (config.minBase > 0) {
    lines.push(`Minimum Base: ${config.minBase} (cells below this are not tested)`);
  } else {
    lines.push(`Minimum Base: None (testing all cells)`);
  }

  return lines.join('\n  ');
}

// =============================================================================
// Legacy Model Selection (Backward Compatibility)
// These functions are deprecated but maintained for existing code
// =============================================================================

/**
 * @deprecated Use getCrosstabModel() instead
 */
export const getReasoningModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.reasoningModel);
};

/**
 * @deprecated Use getBannerModel() instead
 */
export const getBaseModel = () => {
  const config = getEnvironmentConfig();
  const provider = getActiveProvider();
  return provider.chat(config.baseModel);
};

/**
 * @deprecated Use getCrosstabModelName() instead
 */
export const getReasoningModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.reasoningModel}`;
};

/**
 * @deprecated Use getBannerModelName() instead
 */
export const getBaseModelName = (): string => {
  const config = getEnvironmentConfig();
  return `${config.aiProvider}/${config.baseModel}`;
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

export const validateEnvironment = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = [];

  try {
    const config = getEnvironmentConfig();

    // Provider-specific credential validation
    if (config.aiProvider === 'azure') {
      if (config.azureApiKey.length < 10) {
        errors.push('AZURE_API_KEY appears too short');
      }
      if (!/^[a-zA-Z0-9-]+$/.test(config.azureResourceName)) {
        errors.push('AZURE_RESOURCE_NAME should only contain alphanumeric characters and hyphens');
      }
    } else if (config.aiProvider === 'openai') {
      if (!config.openaiApiKey || config.openaiApiKey.length < 10) {
        errors.push('OPENAI_API_KEY appears too short or missing');
      }
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

    if (config.processingLimits.crosstabModelTokens < 1000) {
      errors.push('CROSSTAB_MODEL_TOKENS must be at least 1000');
    }

    if (config.processingLimits.bannerModelTokens < 1000) {
      errors.push('BANNER_MODEL_TOKENS must be at least 1000');
    }

    if (config.processingLimits.verificationModelTokens < 1000) {
      errors.push('VERIFICATION_MODEL_TOKENS must be at least 1000');
    }

    // Validate stat testing config
    const statConfig = getStatTestingConfig();
    if (statConfig.thresholds.length === 0) {
      errors.push('STAT_THRESHOLDS must have at least one value');
    }
    for (const threshold of statConfig.thresholds) {
      if (threshold <= 0 || threshold >= 1) {
        errors.push(`Invalid stat threshold ${threshold}: must be between 0 and 1`);
      }
    }

  } catch (error) {
    errors.push(error instanceof Error ? error.message : 'Unknown environment error');
  }

  return {
    valid: errors.length === 0,
    errors,
  };
};

// =============================================================================
// Review Threshold Configuration (re-export from review module)
// =============================================================================

export { getReviewThresholds, type ReviewThresholds } from './review/ReviewConfig';

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
