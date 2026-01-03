// Table Agent prompt selector
import { TABLE_AGENT_INSTRUCTIONS_PRODUCTION } from './production';

export const getTablePrompt = (version?: string): string => {
  const promptVersion = version || process.env.TABLE_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'production':
    default:
      return TABLE_AGENT_INSTRUCTIONS_PRODUCTION;
  }
};
