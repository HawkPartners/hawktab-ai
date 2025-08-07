// Agent exports for CrosstabAgent system

// CrossTab Agent exports - Phase 6 Implementation
export { 
  createCrosstabAgent, 
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