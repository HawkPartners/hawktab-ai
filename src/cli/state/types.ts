/**
 * CLI State Types
 *
 * TypeScript interfaces for the CLI state management.
 */

import type { StageStatus, SlotStatus } from '../../lib/events/types';

// =============================================================================
// Slot State
// =============================================================================

export interface SlotState {
  /** Slot index (0, 1, 2) */
  index: number;
  /** Current status */
  status: SlotStatus;
  /** Table ID being processed (if running) */
  tableId: string | null;
  /** Latest log entry */
  latestLog: string | null;
  /** Start time (for duration calculation) */
  startTime: number | null;
}

// =============================================================================
// Stage State
// =============================================================================

export interface StageState {
  /** Stage number (1-10) */
  number: number;
  /** Stage name */
  name: string;
  /** Current status */
  status: StageStatus;
  /** Duration in ms (set when completed) */
  durationMs: number | null;
  /** Cost in USD (set when completed) */
  costUsd: number | null;
  /** Error message (if failed) */
  error: string | null;
  /** Start time */
  startTime: number | null;
  /** Progress info (for agents with parallel processing) */
  progress: {
    completed: number;
    total: number;
  } | null;
  /** Parallel slots (for VerificationAgent, BaseFilterAgent) */
  slots: SlotState[];
}

// =============================================================================
// Log Entry
// =============================================================================

export interface LogEntry {
  /** Timestamp */
  timestamp: number;
  /** Agent or stage name */
  source: string;
  /** Table ID (if applicable) */
  tableId: string | null;
  /** Action type (add, review, etc.) */
  action: string;
  /** Log content */
  content: string;
}

// =============================================================================
// Completed Table
// =============================================================================

export interface CompletedTable {
  /** Table ID */
  tableId: string;
  /** Duration in ms */
  durationMs: number;
  /** Completion timestamp */
  timestamp: number;
}

// =============================================================================
// Pipeline State
// =============================================================================

export interface PipelineState {
  /** Dataset name */
  dataset: string;
  /** Output directory */
  outputDir: string;
  /** Total number of stages */
  totalStages: number;
  /** Pipeline status */
  status: 'idle' | 'running' | 'completed' | 'failed';
  /** Pipeline start time */
  startTime: number | null;
  /** Pipeline end time */
  endTime: number | null;
  /** Total cost in USD */
  totalCostUsd: number;
  /** Total table count */
  tableCount: number;
  /** Error message (if failed) */
  error: string | null;
  /** Failed stage (if failed) */
  failedStage: number | null;
  /** All stages */
  stages: StageState[];
  /** Recent log entries (limited buffer) */
  recentLogs: LogEntry[];
  /** Logs per table ID (for drill-down view) */
  logsByTable: Map<string, LogEntry[]>;
  /** Recently completed tables (for display) */
  recentCompletions: CompletedTable[];
}

// =============================================================================
// Navigation State
// =============================================================================

export type ViewLevel = 'pipeline' | 'stage' | 'log';

export interface NavigationState {
  /** Current view level */
  level: ViewLevel;
  /** Selected stage index (0-based) */
  selectedStage: number;
  /** Selected slot index (0-based, for stage view) */
  selectedSlot: number;
  /** Selected table ID (for log view) */
  selectedTableId: string | null;
  /** Log scroll position */
  logScrollOffset: number;
}

// =============================================================================
// Combined State
// =============================================================================

export interface AppState {
  pipeline: PipelineState;
  navigation: NavigationState;
}

// =============================================================================
// Initial State Factory
// =============================================================================

import { STAGE_NAMES, TOTAL_STAGES } from '../../lib/events/types';

export function createInitialPipelineState(): PipelineState {
  const stages: StageState[] = [];
  for (let i = 1; i <= TOTAL_STAGES; i++) {
    stages.push({
      number: i,
      name: STAGE_NAMES[i],
      status: 'pending',
      durationMs: null,
      costUsd: null,
      error: null,
      startTime: null,
      progress: null,
      slots: [],
    });
  }

  return {
    dataset: '',
    outputDir: '',
    totalStages: TOTAL_STAGES,
    status: 'idle',
    startTime: null,
    endTime: null,
    totalCostUsd: 0,
    tableCount: 0,
    error: null,
    failedStage: null,
    stages,
    recentLogs: [],
    logsByTable: new Map(),
    recentCompletions: [],
  };
}

export function createInitialNavigationState(): NavigationState {
  return {
    level: 'pipeline',
    selectedStage: 0,
    selectedSlot: 0,
    selectedTableId: null,
    logScrollOffset: 0,
  };
}

export function createInitialAppState(): AppState {
  return {
    pipeline: createInitialPipelineState(),
    navigation: createInitialNavigationState(),
  };
}
