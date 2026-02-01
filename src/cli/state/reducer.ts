/**
 * CLI State Reducer
 *
 * Handles state updates from pipeline events and navigation actions.
 */

import type {
  AppState,
  PipelineState,
  NavigationState,
  SlotState,
  LogEntry,
} from './types';
import { createInitialPipelineState } from './types';
import type { PipelineEvent } from '../../lib/events/types';

// =============================================================================
// Constants
// =============================================================================

const MAX_RECENT_LOGS = 100;
const MAX_LOGS_PER_TABLE = 50;
const MAX_RECENT_COMPLETIONS = 10;
const DEFAULT_CONCURRENCY = 3;

// =============================================================================
// Action Types
// =============================================================================

export type NavigationAction =
  | { type: 'nav:up' }
  | { type: 'nav:down' }
  | { type: 'nav:enter' }
  | { type: 'nav:back' }
  | { type: 'nav:scroll-up' }
  | { type: 'nav:scroll-down' };

export type PipelineAction = { type: 'event'; event: PipelineEvent };

export type AppAction = NavigationAction | PipelineAction;

// =============================================================================
// Pipeline State Reducer
// =============================================================================

function pipelineReducer(state: PipelineState, event: PipelineEvent): PipelineState {
  switch (event.type) {
    case 'pipeline:start': {
      return {
        ...createInitialPipelineState(),
        dataset: event.dataset,
        outputDir: event.outputDir,
        totalStages: event.totalStages,
        status: 'running',
        startTime: event.timestamp,
      };
    }

    case 'pipeline:complete': {
      return {
        ...state,
        status: 'completed',
        endTime: event.timestamp,
        totalCostUsd: event.totalCostUsd,
        tableCount: event.tableCount,
      };
    }

    case 'pipeline:failed': {
      return {
        ...state,
        status: 'failed',
        error: event.error,
        failedStage: event.failedStage ?? null,
        endTime: event.timestamp,
      };
    }

    case 'stage:start': {
      const stages = [...state.stages];
      const stageIndex = event.stageNumber - 1;
      if (stageIndex >= 0 && stageIndex < stages.length) {
        stages[stageIndex] = {
          ...stages[stageIndex],
          status: 'running',
          startTime: event.timestamp,
          // Initialize slots for parallel agents
          slots: isParallelAgent(event.name)
            ? createInitialSlots(DEFAULT_CONCURRENCY)
            : [],
        };
      }
      return { ...state, stages };
    }

    case 'stage:complete': {
      const stages = [...state.stages];
      const stageIndex = event.stageNumber - 1;
      if (stageIndex >= 0 && stageIndex < stages.length) {
        stages[stageIndex] = {
          ...stages[stageIndex],
          status: 'completed',
          durationMs: event.durationMs,
          costUsd: event.costUsd ?? null,
        };
      }
      return { ...state, stages };
    }

    case 'stage:failed': {
      const stages = [...state.stages];
      const stageIndex = event.stageNumber - 1;
      if (stageIndex >= 0 && stageIndex < stages.length) {
        stages[stageIndex] = {
          ...stages[stageIndex],
          status: 'failed',
          error: event.error,
        };
      }
      return { ...state, stages };
    }

    case 'agent:progress': {
      const stages = [...state.stages];
      const stageIndex = getStageIndexForAgent(event.agentName);
      if (stageIndex >= 0 && stageIndex < stages.length) {
        stages[stageIndex] = {
          ...stages[stageIndex],
          progress: {
            completed: event.completed,
            total: event.total,
          },
        };
      }
      return { ...state, stages };
    }

    case 'slot:start': {
      const stages = [...state.stages];
      const stageIndex = getStageIndexForAgent(event.agentName);
      if (stageIndex >= 0 && stageIndex < stages.length) {
        const slots = [...stages[stageIndex].slots];
        if (event.slotIndex >= 0 && event.slotIndex < slots.length) {
          slots[event.slotIndex] = {
            ...slots[event.slotIndex],
            status: 'running',
            tableId: event.tableId,
            startTime: event.timestamp,
            latestLog: null,
          };
          stages[stageIndex] = { ...stages[stageIndex], slots };
        }
      }
      return { ...state, stages };
    }

    case 'slot:log': {
      // Add to recent logs
      const logEntry: LogEntry = {
        timestamp: event.timestamp,
        source: event.agentName,
        tableId: event.tableId,
        action: event.action,
        content: event.content,
      };

      const recentLogs = [logEntry, ...state.recentLogs].slice(0, MAX_RECENT_LOGS);

      // Add to per-table logs
      const logsByTable = new Map(state.logsByTable);
      const tableLogs = logsByTable.get(event.tableId) || [];
      logsByTable.set(
        event.tableId,
        [logEntry, ...tableLogs].slice(0, MAX_LOGS_PER_TABLE)
      );

      // Update slot with latest log
      const stages = [...state.stages];
      const stageIndex = getStageIndexForAgent(event.agentName);
      if (stageIndex >= 0 && stageIndex < stages.length) {
        const slots = [...stages[stageIndex].slots];
        // Find slot by tableId
        const slotIndex = slots.findIndex((s) => s.tableId === event.tableId);
        if (slotIndex >= 0) {
          slots[slotIndex] = {
            ...slots[slotIndex],
            latestLog: event.content.substring(0, 60) + (event.content.length > 60 ? '...' : ''),
          };
          stages[stageIndex] = { ...stages[stageIndex], slots };
        }
      }

      return { ...state, stages, recentLogs, logsByTable };
    }

    case 'slot:complete': {
      const stages = [...state.stages];
      const stageIndex = getStageIndexForAgent(event.agentName);
      if (stageIndex >= 0 && stageIndex < stages.length) {
        const slots = [...stages[stageIndex].slots];
        if (event.slotIndex >= 0 && event.slotIndex < slots.length) {
          slots[event.slotIndex] = {
            ...slots[event.slotIndex],
            status: 'idle',
            tableId: null,
            latestLog: null,
            startTime: null,
          };
          stages[stageIndex] = { ...stages[stageIndex], slots };
        }
      }

      // Add to recent completions
      const recentCompletions = [
        { tableId: event.tableId, durationMs: event.durationMs, timestamp: event.timestamp },
        ...state.recentCompletions,
      ].slice(0, MAX_RECENT_COMPLETIONS);

      return { ...state, stages, recentCompletions };
    }

    case 'cost:update': {
      return {
        ...state,
        totalCostUsd: event.totalCostUsd,
      };
    }

    default:
      return state;
  }
}

// =============================================================================
// Navigation State Reducer
// =============================================================================

function navigationReducer(
  state: NavigationState,
  action: NavigationAction,
  pipelineState: PipelineState
): NavigationState {
  switch (action.type) {
    case 'nav:up': {
      if (state.level === 'pipeline') {
        return {
          ...state,
          selectedStage: Math.max(0, state.selectedStage - 1),
        };
      }
      if (state.level === 'stage') {
        return {
          ...state,
          selectedSlot: Math.max(0, state.selectedSlot - 1),
        };
      }
      if (state.level === 'log') {
        return {
          ...state,
          logScrollOffset: Math.max(0, state.logScrollOffset - 1),
        };
      }
      return state;
    }

    case 'nav:down': {
      if (state.level === 'pipeline') {
        return {
          ...state,
          selectedStage: Math.min(pipelineState.stages.length - 1, state.selectedStage + 1),
        };
      }
      if (state.level === 'stage') {
        const stage = pipelineState.stages[state.selectedStage];
        const maxSlot = (stage?.slots.length || 1) - 1;
        return {
          ...state,
          selectedSlot: Math.min(maxSlot, state.selectedSlot + 1),
        };
      }
      if (state.level === 'log') {
        return {
          ...state,
          logScrollOffset: state.logScrollOffset + 1,
        };
      }
      return state;
    }

    case 'nav:enter': {
      if (state.level === 'pipeline') {
        const stage = pipelineState.stages[state.selectedStage];
        // Only drill into parallel agent stages
        if (stage && stage.slots.length > 0) {
          return {
            ...state,
            level: 'stage',
            selectedSlot: 0,
          };
        }
      }
      if (state.level === 'stage') {
        const stage = pipelineState.stages[state.selectedStage];
        const slot = stage?.slots[state.selectedSlot];
        if (slot?.tableId) {
          return {
            ...state,
            level: 'log',
            selectedTableId: slot.tableId,
            logScrollOffset: 0,
          };
        }
      }
      return state;
    }

    case 'nav:back': {
      if (state.level === 'log') {
        return {
          ...state,
          level: 'stage',
          selectedTableId: null,
          logScrollOffset: 0,
        };
      }
      if (state.level === 'stage') {
        return {
          ...state,
          level: 'pipeline',
          selectedSlot: 0,
        };
      }
      return state;
    }

    case 'nav:scroll-up': {
      return {
        ...state,
        logScrollOffset: Math.max(0, state.logScrollOffset - 5),
      };
    }

    case 'nav:scroll-down': {
      return {
        ...state,
        logScrollOffset: state.logScrollOffset + 5,
      };
    }

    default:
      return state;
  }
}

// =============================================================================
// Combined Reducer
// =============================================================================

export function appReducer(state: AppState, action: AppAction): AppState {
  if (action.type === 'event') {
    return {
      ...state,
      pipeline: pipelineReducer(state.pipeline, action.event),
    };
  }

  // Navigation action
  return {
    ...state,
    navigation: navigationReducer(state.navigation, action, state.pipeline),
  };
}

// =============================================================================
// Helpers
// =============================================================================

function isParallelAgent(stageName: string): boolean {
  return stageName === 'VerificationAgent' || stageName === 'BaseFilterAgent';
}

function createInitialSlots(count: number): SlotState[] {
  const slots: SlotState[] = [];
  for (let i = 0; i < count; i++) {
    slots.push({
      index: i,
      status: 'idle',
      tableId: null,
      latestLog: null,
      startTime: null,
    });
  }
  return slots;
}

function getStageIndexForAgent(agentName: string): number {
  switch (agentName) {
    case 'BannerAgent':
      return 1; // Stage 2
    case 'CrosstabAgent':
      return 2; // Stage 3
    case 'VerificationAgent':
      return 4; // Stage 5
    case 'BaseFilterAgent':
      return 5; // Stage 6
    default:
      return -1;
  }
}
