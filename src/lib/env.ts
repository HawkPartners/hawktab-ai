// Environment configuration helper for CrosstabAgent system

import { EnvironmentConfig } from './types';

export const getEnvironmentConfig = (): EnvironmentConfig => {
  // Validate required environment variables
  const openaiApiKey = process.env.OPENAI_API_KEY;
  if (!openaiApiKey) {
    throw new Error('OPENAI_API_KEY environment variable is required');
  }

  const nodeEnv = process.env.NODE_ENV as 'development' | 'production' || 'development';

  return {
    reasoningModel: process.env.REASONING_MODEL || 'o1-preview',
    baseModel: process.env.BASE_MODEL || 'gpt-4o',
    openaiApiKey,
    nodeEnv,
    tracingDisabled: process.env.OPENAI_AGENTS_DISABLE_TRACING === 'true',
    promptVersions: {
      crosstabPromptVersion: process.env.CROSSTAB_PROMPT_VERSION || 'production',
      bannerPromptVersion: process.env.BANNER_PROMPT_VERSION || 'production',
    },
    processingLimits: {
      maxDataMapVariables: parseInt(process.env.MAX_DATA_MAP_VARIABLES || '1000'),
      maxBannerColumns: parseInt(process.env.MAX_BANNER_COLUMNS || '100'),
      reasoningModelTokens: parseInt(process.env.REASONING_MODEL_TOKENS || '100000'),
      baseModelTokens: parseInt(process.env.BASE_MODEL_TOKENS || '32768'),
    },
  };
};

export const getModel = (): string => {
  const config = getEnvironmentConfig();
  
  // Use reasoning model for development, base model for production
  return config.nodeEnv === 'production' 
    ? config.baseModel
    : config.reasoningModel;
};

export const getModelTokenLimit = (): number => {
  const config = getEnvironmentConfig();
  
  // Return token limit based on current model
  return config.nodeEnv === 'production' 
    ? config.processingLimits.baseModelTokens
    : config.processingLimits.reasoningModelTokens;
};

export const getModelConfig = () => {
  const config = getEnvironmentConfig();
  const isProduction = config.nodeEnv === 'production';
  
  return {
    model: isProduction ? config.baseModel : config.reasoningModel,
    tokenLimit: isProduction ? config.processingLimits.baseModelTokens : config.processingLimits.reasoningModelTokens,
    environment: config.nodeEnv,
  };
};

export const getPromptVersions = () => {
  const config = getEnvironmentConfig();
  return config.promptVersions;
};

export const validateEnvironment = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = [];

  try {
    const config = getEnvironmentConfig();
    
    // Validate API key format
    if (!config.openaiApiKey.startsWith('sk-')) {
      errors.push('OPENAI_API_KEY must start with "sk-"');
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