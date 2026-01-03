/**
 * Scratchpad tool for reasoning transparency
 * Provides enhanced thinking space for complex variable validation tasks
 * Accumulates entries for inclusion in processing logs
 */

import { tool } from 'ai';
import { z } from 'zod';

// Accumulated scratchpad entries for the current session
let scratchpadEntries: Array<{
  timestamp: string;
  action: string;
  content: string;
}> = [];

// Scratchpad tool using Vercel AI SDK pattern
export const scratchpadTool = tool({
  description: 'Enhanced thinking space for reasoning models to show validation steps and reasoning. Use this to document your analysis process.',
  inputSchema: z.object({
    action: z.enum(['add', 'review']).describe('Action to perform: add new thoughts or review current analysis'),
    content: z.string().describe('Content to add or review in the thinking space')
  }),
  execute: async ({ action, content }) => {
    const timestamp = new Date().toISOString();

    // Accumulate entry
    scratchpadEntries.push({ timestamp, action, content });

    // Log for real-time debugging
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

/**
 * Get all accumulated scratchpad entries and clear the buffer
 * Call this after processing to include in output logs
 */
export function getAndClearScratchpadEntries(): Array<{
  timestamp: string;
  action: string;
  content: string;
}> {
  const entries = [...scratchpadEntries];
  scratchpadEntries = [];
  return entries;
}

/**
 * Get accumulated entries without clearing (for inspection)
 */
export function getScratchpadEntries(): Array<{
  timestamp: string;
  action: string;
  content: string;
}> {
  return [...scratchpadEntries];
}

/**
 * Clear scratchpad entries (call at start of new processing session)
 */
export function clearScratchpadEntries(): void {
  scratchpadEntries = [];
}

// Type export for use in agent definitions
export type ScratchpadTool = typeof scratchpadTool;

/**
 * Format scratchpad entries as markdown for human-readable output
 */
export function formatScratchpadAsMarkdown(
  agentName: string,
  entries: Array<{ timestamp: string; action: string; content: string }>
): string {
  const header = `# ${agentName} Scratchpad Trace

Generated: ${new Date().toISOString()}
Total entries: ${entries.length}

---
`;

  if (entries.length === 0) {
    return header + '\n*No scratchpad entries recorded.*\n';
  }

  const formattedEntries = entries.map((entry, index) => {
    const time = new Date(entry.timestamp).toLocaleTimeString('en-US', {
      hour12: false,
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      fractionalSecondDigits: 3
    });

    return `## Entry ${index + 1} - ${time}

**Action**: \`${entry.action}\`

${entry.content}
`;
  }).join('\n---\n\n');

  return header + formattedEntries;
}
