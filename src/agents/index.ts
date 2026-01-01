// Agent exports for CrosstabAgent system

// CrossTab Agent exports - Phase 6 Implementation
// NOTE: createCrosstabAgent REMOVED - no longer exists after migration to generateText()
export {
  processGroup,
  processAllGroups,
  processAllGroupsParallel,
  validateAgentResult,
  isValidAgentResult
} from './CrosstabAgent';

// Tool exports
export { scratchpadTool } from './tools/scratchpad';

// Core types
export type { AgentExecutionResult } from '../lib/types';