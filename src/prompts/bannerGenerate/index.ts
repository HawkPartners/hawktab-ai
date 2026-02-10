// BannerGenerateAgent prompt selector
import { BANNER_GENERATE_SYSTEM_PROMPT_PRODUCTION } from './production';
import { BANNER_GENERATE_SYSTEM_PROMPT_ALTERNATIVE } from './alternative';

export { buildBannerGenerateUserPrompt } from './production';
export type { BannerGenerateUserPromptInput } from './production';

export const getBannerGeneratePrompt = (version?: string): string => {
  const promptVersion = version || process.env.BANNER_GENERATE_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'alternative':
      return BANNER_GENERATE_SYSTEM_PROMPT_ALTERNATIVE;
    case 'production':
    default:
      return BANNER_GENERATE_SYSTEM_PROMPT_PRODUCTION;
  }
};
