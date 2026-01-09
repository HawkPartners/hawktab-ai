// Verification Agent prompt selector
import { VERIFICATION_AGENT_INSTRUCTIONS_PRODUCTION } from './production';
import { VERIFICATION_AGENT_INSTRUCTIONS_ALTERNATIVE } from './alternative';

export const getVerificationPrompt = (version?: string): string => {
  const promptVersion = version || process.env.VERIFICATION_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'alternative':
      return VERIFICATION_AGENT_INSTRUCTIONS_ALTERNATIVE;
    case 'production':
    default:
      return VERIFICATION_AGENT_INSTRUCTIONS_PRODUCTION;
  }
};

export { VERIFICATION_AGENT_INSTRUCTIONS_PRODUCTION };
