/**
 * Scratchpad tool for reasoning transparency
 * Provides enhanced thinking space for complex variable validation tasks
 */

import { tool } from 'ai';
import { z } from 'zod';

// Scratchpad tool using Vercel AI SDK pattern
export const scratchpadTool = tool({
  description: 'Enhanced thinking space for reasoning models to show validation steps and reasoning. Use this to document your analysis process.',
  inputSchema: z.object({
    action: z.enum(['add', 'review']).describe('Action to perform: add new thoughts or review current analysis'),
    content: z.string().describe('Content to add or review in the thinking space')
  }),
  execute: async ({ action, content }) => {
    // Log for debugging
    console.log(`[CrossTab Agent Scratchpad] ${action}: ${content}`);

    switch (action) {
      case 'add':
        return `[Thinking] Added: ${content}`;
      case 'review':
        return `[Review] ${content}`;
      default:
        return `[Scratchpad] Unknown action: ${action}`;
    }
  }
});

// Type export for use in agent definitions
export type ScratchpadTool = typeof scratchpadTool;
