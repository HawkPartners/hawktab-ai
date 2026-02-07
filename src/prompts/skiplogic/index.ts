// SkipLogic Agent prompt selector
import { SKIP_LOGIC_AGENT_INSTRUCTIONS_PRODUCTION } from './production';

export const getSkipLogicPrompt = (version?: string): string => {
  const promptVersion = version || process.env.SKIPLOGIC_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'production':
    default:
      return SKIP_LOGIC_AGENT_INSTRUCTIONS_PRODUCTION;
  }
};

export { SKIP_LOGIC_AGENT_INSTRUCTIONS_PRODUCTION };
