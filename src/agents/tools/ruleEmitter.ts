/**
 * Rule Emitter tool for SkipLogicAgent
 *
 * Allows the model to emit skip/show rules incrementally as it reads the survey,
 * rather than producing all rules in a single JSON blob at the end.
 *
 * Benefits:
 * - Each rule is emitted at the moment of discovery when context is freshest
 * - Partial success: rules emitted before a failure are preserved
 * - Reduced memory burden: model doesn't need to hold all rules in working memory
 *
 * Follows the same global + context-isolated pattern as scratchpad.ts.
 */

import { tool } from 'ai';
import { SkipRuleSchema, type SkipRule } from '../../schemas/skipLogicSchema';
import { getPipelineEventBus } from '../../lib/events';

// =============================================================================
// Global Rule Emitter (single-pass mode)
// =============================================================================

/** Accumulated rules for the current session */
let emittedRules: SkipRule[] = [];

/**
 * Create a rule emitter tool for single-pass mode.
 * The model calls this tool to emit each rule as it discovers it.
 */
export function createRuleEmitterTool(agentName: string) {
  return tool({
    description:
      'Emit a skip/show/filter rule as soon as you discover it. Call this tool IMMEDIATELY when you confirm a rule — do not wait until the end. Each call records one rule. Fields are validated on submission; if validation fails you will see an error message and can fix and re-emit.',
    inputSchema: SkipRuleSchema,
    execute: async (input) => {
      const parsed = SkipRuleSchema.safeParse(input);

      if (!parsed.success) {
        const errors = parsed.error.issues
          .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
          .join('; ');
        const msg = `[ERROR] emitRule validation failed: ${errors}. Fix the fields and call emitRule again.`;

        if (!getPipelineEventBus().isEnabled()) {
          console.warn(`[${agentName}] ${msg}`);
        }

        return msg;
      }

      const rule = parsed.data;
      emittedRules.push(rule);

      const appliesStr = rule.appliesTo.join(', ');
      const logMsg = `Emitted rule ${rule.ruleId} (${rule.ruleType}) -> ${appliesStr}`;

      // Emit slot:log event for CLI integration
      getPipelineEventBus().emitSlotLog(agentName, 'emitRule', 'emit', logMsg);

      // Console logging when event bus is not active
      if (!getPipelineEventBus().isEnabled()) {
        console.log(`[${agentName}] ${logMsg}`);
      }

      return `[OK] Rule ${rule.ruleId} emitted (${emittedRules.length} total). Continue scanning.`;
    },
  });
}

/** Get all emitted rules (without clearing) */
export function getEmittedRules(): SkipRule[] {
  return [...emittedRules];
}

/** Clear emitted rules (call at start of new processing session) */
export function clearEmittedRules(): void {
  emittedRules = [];
}

// =============================================================================
// Context-Isolated Rule Emitter (chunked mode / parallel execution)
// =============================================================================

/** Context-isolated rule storage */
const contextEmitters = new Map<string, SkipRule[]>();

/**
 * Create a rule emitter tool for a specific context (e.g., chunk ID).
 * Returns rules in isolation from other contexts.
 */
export function createContextRuleEmitterTool(agentName: string, contextId: string) {
  return tool({
    description:
      'Emit a skip/show/filter rule as soon as you discover it. Call this tool IMMEDIATELY when you confirm a rule — do not wait until the end. Each call records one rule. Fields are validated on submission; if validation fails you will see an error message and can fix and re-emit.',
    inputSchema: SkipRuleSchema,
    execute: async (input) => {
      const parsed = SkipRuleSchema.safeParse(input);

      if (!parsed.success) {
        const errors = parsed.error.issues
          .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
          .join('; ');
        const msg = `[ERROR] emitRule validation failed: ${errors}. Fix the fields and call emitRule again.`;

        if (!getPipelineEventBus().isEnabled()) {
          console.warn(`[${agentName}:${contextId}] ${msg}`);
        }

        return msg;
      }

      const rule = parsed.data;

      if (!contextEmitters.has(contextId)) {
        contextEmitters.set(contextId, []);
      }
      contextEmitters.get(contextId)!.push(rule);

      const count = contextEmitters.get(contextId)!.length;
      const appliesStr = rule.appliesTo.join(', ');
      const logMsg = `Emitted rule ${rule.ruleId} (${rule.ruleType}) -> ${appliesStr}`;

      // Emit slot:log event for CLI integration
      getPipelineEventBus().emitSlotLog(agentName, contextId, 'emit', logMsg);

      // Console logging when event bus is not active
      if (!getPipelineEventBus().isEnabled()) {
        console.log(`[${agentName}:${contextId}] ${logMsg}`);
      }

      return `[OK] Rule ${rule.ruleId} emitted (${count} total for this chunk). Continue scanning.`;
    },
  });
}

/** Get emitted rules for a specific context */
export function getContextEmittedRules(contextId: string): SkipRule[] {
  return [...(contextEmitters.get(contextId) || [])];
}

/** Get all context-isolated emitted rules (for aggregation after parallel execution) */
export function getAllContextEmittedRules(): Array<{
  contextId: string;
  rules: SkipRule[];
}> {
  const all: Array<{ contextId: string; rules: SkipRule[] }> = [];
  for (const [contextId, rules] of contextEmitters) {
    all.push({ contextId, rules: [...rules] });
  }
  return all;
}

/** Clear all context-isolated emitters */
export function clearAllContextEmitters(): void {
  contextEmitters.clear();
}
