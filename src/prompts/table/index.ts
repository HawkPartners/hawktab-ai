// Table Agent prompt selector
import { TABLE_AGENT_INSTRUCTIONS_PRODUCTION } from './production';
import { TABLE_AGENT_INSTRUCTIONS_ALTERNATIVE } from './alternative';

export const getTablePrompt = (version?: string): string => {
  const promptVersion = version || process.env.TABLE_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'alternative':
      return TABLE_AGENT_INSTRUCTIONS_ALTERNATIVE;
    case 'production':
    default:
      return TABLE_AGENT_INSTRUCTIONS_PRODUCTION;
  }
};
