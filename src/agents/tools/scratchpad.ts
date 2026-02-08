/**
 * Scratchpad tool for reasoning transparency
 * Provides enhanced thinking space for complex variable validation tasks
 * Accumulates entries for inclusion in processing logs
 */

import { tool } from 'ai';
import { z } from 'zod';
import { getPipelineEventBus } from '../../lib/events';

// Accumulated scratchpad entries for the current session
let scratchpadEntries: Array<{
  timestamp: string;
  agentName: string;
  action: string;
  content: string;
}> = [];

/**
 * Create a scratchpad tool for a specific agent
 * This factory function allows each agent to have its own attributed scratchpad
 */
export function createScratchpadTool(agentName: string) {
  return tool({
    description: 'Enhanced thinking space for reasoning models to show validation steps and reasoning. Use "add" to document your analysis, "read" to retrieve all previous entries (useful before producing final output), or "review" to add review notes.',
    inputSchema: z.object({
      action: z.enum(['add', 'review', 'read']).describe('Action: "add" new thoughts, "read" to retrieve all accumulated entries, or "review" to add review notes'),
      content: z.string().describe('Content to add (for "add"/"review"). For "read", pass empty string or a brief note about why you are reading.')
    }),
    execute: async ({ action, content }) => {
      const timestamp = new Date().toISOString();

      // For "read" action, return all accumulated entries without adding a new one
      if (action === 'read') {
        const entries = scratchpadEntries.filter(e => e.agentName === agentName);
        if (entries.length === 0) {
          return '[Read] No entries recorded yet.';
        }
        const formatted = entries.map((e, i) =>
          `[${i + 1}] (${e.action}) ${e.content}`
        ).join('\n\n');
        return `[Read] ${entries.length} entries:\n\n${formatted}`;
      }

      // Accumulate entry with agent attribution
      scratchpadEntries.push({ timestamp, agentName, action, content });

      // Log for real-time debugging (avoid UI mode to prevent spill)
      if (!getPipelineEventBus().isEnabled()) {
        console.log(`[${agentName} Scratchpad] ${action}: ${content}`);
      }

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
}

// Pre-created tools for each agent (for convenience)
export const crosstabScratchpadTool = createScratchpadTool('CrosstabAgent');
export const bannerScratchpadTool = createScratchpadTool('BannerAgent');
export const verificationScratchpadTool = createScratchpadTool('VerificationAgent');
export const skipLogicScratchpadTool = createScratchpadTool('SkipLogicAgent');
export const filterTranslatorScratchpadTool = createScratchpadTool('FilterTranslatorAgent');

// Legacy export for backward compatibility
// TODO: Migrate existing agents to use agent-specific tools
export const scratchpadTool = crosstabScratchpadTool;

/**
 * Get accumulated scratchpad entries and clear them
 * Call this after processing to include in output logs
 * 
 * @param agentName - Optional agent name filter. If provided, only returns and clears entries for that agent.
 *                    If not provided, returns and clears all entries (backward compatibility).
 */
export function getAndClearScratchpadEntries(agentName?: string): Array<{
  timestamp: string;
  agentName: string;
  action: string;
  content: string;
}> {
  if (agentName) {
    // Agent-specific: return and clear only entries for this agent
    const entries = scratchpadEntries.filter(e => e.agentName === agentName);
    scratchpadEntries = scratchpadEntries.filter(e => e.agentName !== agentName);
    return entries;
  } else {
    // Backward compatibility: return and clear all entries
    const entries = [...scratchpadEntries];
    scratchpadEntries = [];
    return entries;
  }
}

/**
 * Get accumulated entries without clearing (for inspection)
 */
export function getScratchpadEntries(): Array<{
  timestamp: string;
  agentName: string;
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
export type ScratchpadTool = ReturnType<typeof createScratchpadTool>;

// =============================================================================
// Context-Isolated Scratchpad (for parallel execution)
// =============================================================================

/**
 * Context-isolated scratchpad storage
 * Allows parallel agent calls to have independent scratchpad entries
 */
const contextScratchpads = new Map<string, Array<{
  timestamp: string;
  agentName: string;
  action: string;
  content: string;
}>>();

/**
 * Create a scratchpad tool for a specific context (e.g., tableId)
 * Returns entries in isolation from other contexts
 */
export function createContextScratchpadTool(agentName: string, contextId: string) {
  return tool({
    description: 'Enhanced thinking space for reasoning models to show validation steps and reasoning. Use "add" to document your analysis, "read" to retrieve all previous entries, or "review" to add review notes.',
    inputSchema: z.object({
      action: z.enum(['add', 'review', 'read']).describe('Action: "add" new thoughts, "read" to retrieve all accumulated entries, or "review" to add review notes'),
      content: z.string().describe('Content to add (for "add"/"review"). For "read", pass empty string or a brief note.')
    }),
    execute: async ({ action, content }) => {
      const timestamp = new Date().toISOString();

      // For "read" action, return all accumulated entries for this context
      if (action === 'read') {
        const entries = contextScratchpads.get(contextId) || [];
        if (entries.length === 0) {
          return '[Read] No entries recorded yet.';
        }
        const formatted = entries.map((e, i) =>
          `[${i + 1}] (${e.action}) ${e.content}`
        ).join('\n\n');
        return `[Read] ${entries.length} entries:\n\n${formatted}`;
      }

      // Get or create context-specific array
      if (!contextScratchpads.has(contextId)) {
        contextScratchpads.set(contextId, []);
      }
      contextScratchpads.get(contextId)!.push({ timestamp, agentName, action, content });

      // Emit slot:log event for CLI
      getPipelineEventBus().emitSlotLog(agentName, contextId, action, content);

      // Log for real-time debugging with context (avoid UI mode to prevent spill)
      if (!getPipelineEventBus().isEnabled()) {
        console.log(`[${agentName}:${contextId}] ${action}: ${content}`);
      }

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
}

/**
 * Get entries for a specific context and clear them
 */
export function getContextScratchpadEntries(contextId: string): Array<{
  timestamp: string;
  agentName: string;
  action: string;
  content: string;
}> {
  const entries = contextScratchpads.get(contextId) || [];
  contextScratchpads.delete(contextId);
  return entries;
}

/**
 * Get all context entries (for aggregation after parallel execution)
 */
export function getAllContextScratchpadEntries(): Array<{
  contextId: string;
  entries: Array<{ timestamp: string; agentName: string; action: string; content: string }>;
}> {
  const all: Array<{
    contextId: string;
    entries: Array<{ timestamp: string; agentName: string; action: string; content: string }>;
  }> = [];
  for (const [contextId, entries] of contextScratchpads) {
    all.push({ contextId, entries: [...entries] });
  }
  return all;
}

/**
 * Clear all context scratchpads
 */
export function clearAllContextScratchpads(): void {
  contextScratchpads.clear();
}

/**
 * Format scratchpad entries as markdown for human-readable output
 */
export function formatScratchpadAsMarkdown(
  agentName: string,
  entries: Array<{ timestamp: string; agentName?: string; action: string; content: string }>
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

    // Include agent name if available and different from header
    const agentPrefix = entry.agentName && entry.agentName !== agentName
      ? `**Agent**: ${entry.agentName}\n`
      : '';

    return `## Entry ${index + 1} - ${time}

${agentPrefix}**Action**: \`${entry.action}\`

${entry.content}
`;
  }).join('\n---\n\n');

  return header + formattedEntries;
}
