/**
 * @deprecated Replaced by SkipLogicAgent + FilterTranslatorAgent + FilterApplicator.
 * This file is kept only for backward compatibility with existing pipeline outputs.
 * Do not add new features here. See src/prompts/skiplogic/ and src/prompts/filtertranslator/.
 */
// BaseFilter Agent prompt selector
import { BASEFILTER_AGENT_INSTRUCTIONS_PRODUCTION } from './production';

export const getBaseFilterPrompt = (version?: string): string => {
  const promptVersion = version || process.env.BASEFILTER_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'production':
    default:
      return BASEFILTER_AGENT_INSTRUCTIONS_PRODUCTION;
  }
};

export { BASEFILTER_AGENT_INSTRUCTIONS_PRODUCTION };
