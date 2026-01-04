// Agent exports for HawkTab AI system
// Migrated to Vercel AI SDK + Azure OpenAI (Phase 1 complete)

// CrossTab Agent exports - Phase 6 Implementation
// NOTE: createCrosstabAgent REMOVED - no longer exists after migration to generateText()
export {
  processGroup,
  processAllGroups,
  processAllGroupsParallel,
  validateAgentResult,
  isValidAgentResult
} from './CrosstabAgent';

// Banner Agent exports (class-based)
export { BannerAgent } from './BannerAgent';
export type { BannerProcessingResult, ProcessedImage } from './BannerAgent';

// Table Agent exports (decides how to display data as tables)
export {
  processDataMap,
  processQuestionGroup,
  processAllGroups as processTableGroups,
  groupDataMapByParent,
  getAllTableDefinitions,
  calculateOverallConfidence,
  EXCLUDED_NORMALIZED_TYPES,
} from './TableAgent';

// Tool exports
export { scratchpadTool } from './tools/scratchpad';

// Core types
export type { AgentExecutionResult } from '../lib/types';