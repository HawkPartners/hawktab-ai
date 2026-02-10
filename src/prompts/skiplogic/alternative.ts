/**
 * SkipLogicAgent Alternative Prompt
 *
 * Identical to production. Both slots synchronized as a baseline for
 * future iteration. Composes the same core + scratchpad sections.
 */

import { SKIP_LOGIC_CORE_INSTRUCTIONS, SKIP_LOGIC_SCRATCHPAD_PROTOCOL } from './production';

export const SKIP_LOGIC_AGENT_INSTRUCTIONS_ALTERNATIVE = `
${SKIP_LOGIC_CORE_INSTRUCTIONS}

${SKIP_LOGIC_SCRATCHPAD_PROTOCOL}
`;
