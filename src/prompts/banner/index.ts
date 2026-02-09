// Banner Processor prompt selector
import { BANNER_EXTRACTION_PROMPT_PRODUCTION } from './production';
import { BANNER_EXTRACTION_PROMPT_ALTERNATIVE } from './alternative';
import { BANNER_GENERATE_SYSTEM_PROMPT } from './generate-cuts';

export { buildBannerGenerateUserPrompt } from './generate-cuts';
export type { BannerGenerateUserPromptInput } from './generate-cuts';

export const getBannerPrompt = (version?: string): string => {
  const promptVersion = version || process.env.BANNER_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'alternative':
      return BANNER_EXTRACTION_PROMPT_ALTERNATIVE;
    case 'production':
    default:
      return BANNER_EXTRACTION_PROMPT_PRODUCTION;
  }
};

export const getBannerGeneratePrompt = (): string => {
  return BANNER_GENERATE_SYSTEM_PROMPT;
};