/**
 * Pipeline Event Types
 *
 * Type definitions for events emitted by the pipeline and agents.
 * Used by the CLI to display real-time progress.
 */

// =============================================================================
// Stage Events
// =============================================================================

export type StageStatus = 'pending' | 'running' | 'completed' | 'failed';

export interface StageInfo {
  /** Stage identifier (1-10) */
  stageNumber: number;
  /** Human-readable stage name */
  name: string;
  /** Current status */
  status: StageStatus;
  /** Duration in ms (set when completed) */
  durationMs?: number;
  /** Cost in USD (set when completed) */
  costUsd?: number;
  /** Error message if failed */
  error?: string;
}

export interface StageStartEvent {
  type: 'stage:start';
  stageNumber: number;
  name: string;
  timestamp: number;
}

export interface StageCompleteEvent {
  type: 'stage:complete';
  stageNumber: number;
  name: string;
  durationMs: number;
  costUsd?: number;
  timestamp: number;
}

export interface StageFailedEvent {
  type: 'stage:failed';
  stageNumber: number;
  name: string;
  error: string;
  timestamp: number;
}

// =============================================================================
// Agent Progress Events
// =============================================================================

export interface AgentProgressEvent {
  type: 'agent:progress';
  /** Agent name (e.g., 'VerificationAgent') */
  agentName: string;
  /** Number of items completed */
  completed: number;
  /** Total number of items */
  total: number;
  timestamp: number;
}

// =============================================================================
// Parallel Slot Events
// =============================================================================

export type SlotStatus = 'idle' | 'running' | 'completed';

export interface SlotInfo {
  /** Slot index (0, 1, 2 for concurrency=3) */
  slotIndex: number;
  /** Current status */
  status: SlotStatus;
  /** Table ID currently being processed */
  tableId?: string;
  /** Latest log message */
  latestLog?: string;
}

export interface SlotStartEvent {
  type: 'slot:start';
  /** Agent name (e.g., 'VerificationAgent') */
  agentName: string;
  /** Slot index (0, 1, 2) */
  slotIndex: number;
  /** Table ID being processed */
  tableId: string;
  timestamp: number;
}

export interface SlotLogEvent {
  type: 'slot:log';
  /** Agent name */
  agentName: string;
  /** Slot index or table ID (we'll derive slot from tableId) */
  tableId: string;
  /** Log action (add, review) */
  action: string;
  /** Log content */
  content: string;
  timestamp: number;
}

export interface SlotCompleteEvent {
  type: 'slot:complete';
  /** Agent name */
  agentName: string;
  /** Slot index */
  slotIndex: number;
  /** Table ID that completed */
  tableId: string;
  /** Duration in ms */
  durationMs: number;
  timestamp: number;
}

// =============================================================================
// Cost Events
// =============================================================================

export interface CostUpdateEvent {
  type: 'cost:update';
  /** Agent name */
  agentName: string;
  /** Model used */
  model: string;
  /** Input tokens */
  inputTokens: number;
  /** Output tokens */
  outputTokens: number;
  /** Cost for this call in USD */
  costUsd: number;
  /** Cumulative total cost in USD */
  totalCostUsd: number;
  timestamp: number;
}

// =============================================================================
// Pipeline Events
// =============================================================================

export interface PipelineStartEvent {
  type: 'pipeline:start';
  /** Dataset name */
  dataset: string;
  /** Total number of stages */
  totalStages: number;
  /** Output directory */
  outputDir: string;
  timestamp: number;
}

export interface PipelineCompleteEvent {
  type: 'pipeline:complete';
  /** Dataset name */
  dataset: string;
  /** Total duration in ms */
  durationMs: number;
  /** Total cost in USD */
  totalCostUsd: number;
  /** Number of tables generated */
  tableCount: number;
  /** Output directory */
  outputDir: string;
  timestamp: number;
}

export interface PipelineFailedEvent {
  type: 'pipeline:failed';
  /** Dataset name */
  dataset: string;
  /** Error message */
  error: string;
  /** Stage where failure occurred */
  failedStage?: number;
  timestamp: number;
}

// =============================================================================
// Validation Events
// =============================================================================

export interface ValidationStageStartEvent {
  type: 'validation:stage:start';
  /** Validation stage number (1-5) */
  stage: number;
  /** Stage name */
  name: string;
  timestamp: number;
}

export interface ValidationStageCompleteEvent {
  type: 'validation:stage:complete';
  /** Validation stage number (1-5) */
  stage: number;
  /** Stage name */
  name: string;
  /** Duration in ms */
  durationMs: number;
  timestamp: number;
}

export interface ValidationWarningEvent {
  type: 'validation:warning';
  /** Validation stage number */
  stage: number;
  /** Warning message */
  message: string;
  timestamp: number;
}

export interface ValidationCompleteEvent {
  type: 'validation:complete';
  /** Whether pipeline can proceed */
  canProceed: boolean;
  /** Detected format */
  format: string;
  /** Number of errors */
  errorCount: number;
  /** Number of warnings */
  warningCount: number;
  /** Total duration in ms */
  durationMs: number;
  timestamp: number;
}

// =============================================================================
// System Log Events
// =============================================================================

export type SystemLogLevel = 'info' | 'warn' | 'error' | 'debug';

export interface SystemLogEvent {
  type: 'system:log';
  /** Log level */
  level: SystemLogLevel;
  /** Log message */
  message: string;
  /** Optional stage name */
  stageName?: string;
  timestamp: number;
}

// =============================================================================
// Union Type
// =============================================================================

export type PipelineEvent =
  | StageStartEvent
  | StageCompleteEvent
  | StageFailedEvent
  | AgentProgressEvent
  | SlotStartEvent
  | SlotLogEvent
  | SlotCompleteEvent
  | CostUpdateEvent
  | PipelineStartEvent
  | PipelineCompleteEvent
  | PipelineFailedEvent
  | ValidationStageStartEvent
  | ValidationStageCompleteEvent
  | ValidationWarningEvent
  | ValidationCompleteEvent
  | SystemLogEvent;

// =============================================================================
// Stage Definitions
// =============================================================================

export const STAGE_NAMES: Record<number, string> = {
  1: 'DataMapProcessor',
  2: 'BannerAgent',
  3: 'CrosstabAgent',
  4: 'TableGenerator',
  5: 'SkipLogicAgent',
  6: 'FilterApplicator',
  7: 'VerificationAgent',
  8: 'R Validation',
  9: 'R Script Generation',
  10: 'R Execution',
  11: 'Excel Export',
};

export const TOTAL_STAGES = 11;
