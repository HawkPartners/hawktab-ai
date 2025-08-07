// CrossTab Agent prompt selector
import { CROSSTAB_VALIDATION_INSTRUCTIONS_PRODUCTION } from './production';
import { CROSSTAB_VALIDATION_INSTRUCTIONS_ALTERNATIVE } from './alternative';

export const getCrosstabPrompt = (version?: string): string => {
  const promptVersion = version || process.env.CROSSTAB_PROMPT_VERSION || 'production';
  
  switch (promptVersion) {
    case 'alternative':
      return CROSSTAB_VALIDATION_INSTRUCTIONS_ALTERNATIVE;
    case 'production':
    default:
      return CROSSTAB_VALIDATION_INSTRUCTIONS_PRODUCTION;
  }
};