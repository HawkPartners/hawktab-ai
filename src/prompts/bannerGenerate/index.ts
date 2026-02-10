// BannerGenerateAgent prompt selector
import { BANNER_GENERATE_SYSTEM_PROMPT_PRODUCTION } from './production';

export { buildBannerGenerateUserPrompt } from './production';
export type { BannerGenerateUserPromptInput } from './production';

export const getBannerGeneratePrompt = (version?: string): string => {
  const promptVersion = version || process.env.BANNER_GENERATE_PROMPT_VERSION || 'production';

  switch (promptVersion) {
    case 'production':
    default:
      return BANNER_GENERATE_SYSTEM_PROMPT_PRODUCTION;
  }
};
