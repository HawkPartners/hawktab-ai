/**
 * @deprecated This module is deprecated as of Part 4 refactor.
 * TableGenerator.ts now handles table generation deterministically.
 * Kept for reference - will be deleted in future cleanup.
 *
 * Environment variables that are now deprecated:
 * - TABLE_MODEL
 * - TABLE_REASONING_EFFORT
 * - TABLE_PROMPT_VERSION
 * - TABLE_MODEL_TOKENS
 */

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
