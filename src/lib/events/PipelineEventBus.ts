/**
 * Pipeline Event Bus
 *
 * Singleton EventEmitter for pipeline events. Agents and pipeline stages
 * emit events here, and the CLI subscribes to update its UI.
 */

import { EventEmitter } from 'events';
import type {
  PipelineEvent,
  StageStartEvent,
  StageCompleteEvent,
  StageFailedEvent,
  AgentProgressEvent,
  SlotStartEvent,
  SlotLogEvent,
  SlotCompleteEvent,
  CostUpdateEvent,
  PipelineStartEvent,
  PipelineCompleteEvent,
  PipelineFailedEvent,
  ValidationStageStartEvent,
  ValidationStageCompleteEvent,
  ValidationWarningEvent,
  ValidationCompleteEvent,
  SystemLogEvent,
  SystemLogLevel,
} from './types';

// =============================================================================
// Event Bus Class
// =============================================================================

class PipelineEventBus extends EventEmitter {
  private enabled: boolean = false;

  constructor() {
    super();
    // Increase max listeners since we may have many subscribers
    this.setMaxListeners(50);
  }

  /**
   * Enable event emission (called when CLI UI is active)
   */
  enable(): void {
    this.enabled = true;
  }

  /**
   * Disable event emission (default, for non-UI mode)
   */
  disable(): void {
    this.enabled = false;
  }

  /**
   * Check if event bus is enabled
   */
  isEnabled(): boolean {
    return this.enabled;
  }

  /**
   * Emit a pipeline event (only if enabled)
   */
  emitEvent(event: PipelineEvent): void {
    if (!this.enabled) return;
    this.emit(event.type, event);
    this.emit('*', event); // Wildcard for catch-all listeners
  }

  // =============================================================================
  // Typed Event Helpers
  // =============================================================================

  emitStageStart(stageNumber: number, name: string): void {
    const event: StageStartEvent = {
      type: 'stage:start',
      stageNumber,
      name,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitStageComplete(stageNumber: number, name: string, durationMs: number, costUsd?: number): void {
    const event: StageCompleteEvent = {
      type: 'stage:complete',
      stageNumber,
      name,
      durationMs,
      costUsd,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitStageFailed(stageNumber: number, name: string, error: string): void {
    const event: StageFailedEvent = {
      type: 'stage:failed',
      stageNumber,
      name,
      error,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitAgentProgress(agentName: string, completed: number, total: number): void {
    const event: AgentProgressEvent = {
      type: 'agent:progress',
      agentName,
      completed,
      total,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitSlotStart(agentName: string, slotIndex: number, tableId: string): void {
    const event: SlotStartEvent = {
      type: 'slot:start',
      agentName,
      slotIndex,
      tableId,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitSlotLog(agentName: string, tableId: string, action: string, content: string): void {
    const event: SlotLogEvent = {
      type: 'slot:log',
      agentName,
      tableId,
      action,
      content,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitSlotComplete(agentName: string, slotIndex: number, tableId: string, durationMs: number): void {
    const event: SlotCompleteEvent = {
      type: 'slot:complete',
      agentName,
      slotIndex,
      tableId,
      durationMs,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitCostUpdate(
    agentName: string,
    model: string,
    inputTokens: number,
    outputTokens: number,
    costUsd: number,
    totalCostUsd: number
  ): void {
    const event: CostUpdateEvent = {
      type: 'cost:update',
      agentName,
      model,
      inputTokens,
      outputTokens,
      costUsd,
      totalCostUsd,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitPipelineStart(dataset: string, totalStages: number, outputDir: string): void {
    const event: PipelineStartEvent = {
      type: 'pipeline:start',
      dataset,
      totalStages,
      outputDir,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitPipelineComplete(
    dataset: string,
    durationMs: number,
    totalCostUsd: number,
    tableCount: number,
    outputDir: string
  ): void {
    const event: PipelineCompleteEvent = {
      type: 'pipeline:complete',
      dataset,
      durationMs,
      totalCostUsd,
      tableCount,
      outputDir,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitPipelineFailed(dataset: string, error: string, failedStage?: number): void {
    const event: PipelineFailedEvent = {
      type: 'pipeline:failed',
      dataset,
      error,
      failedStage,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  // =============================================================================
  // Validation Event Helpers
  // =============================================================================

  emitValidationStageStart(stage: number, name: string): void {
    const event: ValidationStageStartEvent = {
      type: 'validation:stage:start',
      stage,
      name,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitValidationStageComplete(stage: number, name: string, durationMs: number): void {
    const event: ValidationStageCompleteEvent = {
      type: 'validation:stage:complete',
      stage,
      name,
      durationMs,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitValidationWarning(stage: number, message: string): void {
    const event: ValidationWarningEvent = {
      type: 'validation:warning',
      stage,
      message,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  emitValidationComplete(
    canProceed: boolean,
    format: string,
    errorCount: number,
    warningCount: number,
    durationMs: number
  ): void {
    const event: ValidationCompleteEvent = {
      type: 'validation:complete',
      canProceed,
      format,
      errorCount,
      warningCount,
      durationMs,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }

  // =============================================================================
  // System Log Helpers
  // =============================================================================

  emitSystemLog(level: SystemLogLevel, message: string, stageName?: string): void {
    const event: SystemLogEvent = {
      type: 'system:log',
      level,
      message,
      stageName,
      timestamp: Date.now(),
    };
    this.emitEvent(event);
  }
}

// =============================================================================
// Singleton Instance
// =============================================================================

let instance: PipelineEventBus | null = null;

/**
 * Get the global pipeline event bus instance
 */
export function getPipelineEventBus(): PipelineEventBus {
  if (!instance) {
    instance = new PipelineEventBus();
  }
  return instance;
}

/**
 * Reset the event bus (for testing)
 */
export function resetPipelineEventBus(): void {
  if (instance) {
    instance.removeAllListeners();
  }
  instance = new PipelineEventBus();
}

// Export types
export type { PipelineEventBus };
