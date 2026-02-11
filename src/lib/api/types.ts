import type { BannerProcessingResult } from '@/agents/BannerAgent';
import type { ValidationResultType } from '@/schemas/agentOutputSchema';
import type { ExtendedTableDefinition } from '@/schemas/verificationAgentSchema';
import type { TableAgentOutput } from '@/schemas/tableAgentSchema';

export type PipelineStatus = 'in_progress' | 'pending_review' | 'resuming' | 'success' | 'partial' | 'error' | 'cancelled';

export interface PipelineSummary {
  pipelineId: string;
  dataset: string;
  timestamp: string;
  source: 'ui' | 'cli';
  status: PipelineStatus;
  currentStage?: string;
  options?: {
    loopStatTestingMode?: 'suppress' | 'complement';
  };
  inputs: {
    datamap: string;
    banner: string;
    spss: string;
    survey: string | null;
  };
  duration?: {
    ms: number;
    formatted: string;
  };
  outputs?: {
    variables: number;
    tableGeneratorTables: number;
    verifiedTables: number;
    validatedTables: number;
    excludedTables: number;
    totalTablesInR: number;
    cuts: number;
    bannerGroups: number;
    sorting: {
      screeners: number;
      main: number;
      other: number;
    };
    rValidation?: {
      passedFirstTime: number;
      fixedAfterRetry: number;
      excluded: number;
      durationMs: number;
    };
  };
  costs?: {
    byAgent: Array<{
      agent: string;
      model: string;
      calls: number;
      inputTokens: number;
      outputTokens: number;
      durationMs: number;
      estimatedCostUsd: number;
    }>;
    totals: {
      calls: number;
      inputTokens: number;
      outputTokens: number;
      totalTokens: number;
      durationMs: number;
      estimatedCostUsd: number;
    };
  };
  error?: string;
  review?: {
    flaggedColumnCount: number;
    reviewUrl: string;
  };
  errors?: {
    total: number;
    bySource: Record<string, number>;
    bySeverity: Record<string, number>;
    byAgent: Record<string, number>;
    byStageName: Record<string, number>;
    lastErrorAt: string;
    invalidLines: number;
  };
}

export interface AgentDataMapItem {
  Column: string;
  Description: string;
  Answer_Options: string;
}

export interface BannerGroupAgent {
  groupName: string;
  columns: Array<{
    name: string;
    original: string;
  }>;
}

export interface PathAResult {
  bannerResult: BannerProcessingResult;
  crosstabResult: { result: ValidationResultType; processingLog: string[] };
  agentBanner: BannerGroupAgent[];
  reviewRequired: boolean;
}

export interface PathBResult {
  tableAgentResults: TableAgentOutput[];
  verifiedTables: ExtendedTableDefinition[];
  surveyMarkdown: string | null;
}

export interface FlaggedCrosstabColumn {
  groupName: string;
  columnName: string;
  original: string;
  proposed: string;
  confidence: number;
  reasoning: string;
  userSummary: string;
  alternatives: Array<{
    expression: string;
    rank: number;
    userSummary: string;
  }>;
  uncertainties: string[];
  expressionType?: string;
}

export interface PathBStatus {
  status: 'running' | 'completed' | 'error';
  startedAt: string;
  completedAt: string | null;
  error: string | null;
}

export interface CrosstabReviewState {
  pipelineId: string;
  status: 'awaiting_review' | 'approved' | 'cancelled';
  createdAt: string;
  crosstabResult: ValidationResultType;
  flaggedColumns: FlaggedCrosstabColumn[];
  bannerResult: BannerProcessingResult;
  agentDataMap: AgentDataMapItem[];
  outputDir: string;
  pathBStatus: 'running' | 'completed' | 'error';
  pathBResult: PathBResult | null;
  decisions?: Array<{
    groupName: string;
    columnName: string;
    action: 'approve' | 'select_alternative' | 'provide_hint' | 'edit' | 'skip';
    selectedAlternative?: number;
    hint?: string;
    editedExpression?: string;
  }>;
}

export interface ParsedUploadFiles {
  dataMapFile: File;
  bannerPlanFile: File;
  dataFile: File;
  surveyFile: File | null;
  loopStatTestingMode: 'suppress' | 'complement' | undefined;
}

export interface SavedFilePaths {
  dataMapPath: string;
  bannerPlanPath: string;
  spssPath: string;
  surveyPath: string | null;
}
