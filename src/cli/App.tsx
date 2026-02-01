/**
 * HawkTab AI CLI App
 *
 * Main Ink application component with state management and event handling.
 */

import React, { useReducer, useCallback, useState, useEffect } from 'react';
import { Box } from 'ink';
import { PipelineView, StageDetail, LogView, CostBar, KeyHints } from './components';
import { usePipelineEvents, useNavigation } from './hooks';
import { appReducer, type AppAction } from './state/reducer';
import { createInitialAppState } from './state/types';
import type { PipelineEvent } from '../lib/events/types';

// =============================================================================
// App Component
// =============================================================================

interface AppProps {
  onExit: () => void;
}

export function App({ onExit }: AppProps): React.ReactElement {
  const [state, dispatch] = useReducer(appReducer, createInitialAppState());
  const [startTime] = useState(Date.now());
  const [currentTime, setCurrentTime] = useState(Date.now());

  // Update elapsed time every second
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentTime(Date.now());
    }, 1000);
    return () => clearInterval(interval);
  }, []);

  // Handle pipeline events
  const handleEvent = useCallback((event: PipelineEvent) => {
    dispatch({ type: 'event', event } as AppAction);
  }, []);

  usePipelineEvents({ onEvent: handleEvent });

  // Handle navigation
  const handleNavAction = useCallback((action: AppAction) => {
    dispatch(action);
  }, []);

  useNavigation({
    onAction: handleNavAction,
    onQuit: onExit,
  });

  // Calculate elapsed time
  const elapsedMs = state.pipeline.startTime
    ? currentTime - state.pipeline.startTime
    : currentTime - startTime;

  // Get logs for current table (if in log view)
  const currentTableLogs = state.navigation.selectedTableId
    ? state.pipeline.logsByTable.get(state.navigation.selectedTableId) || []
    : [];

  // Get current stage for detail view
  const currentStage = state.pipeline.stages[state.navigation.selectedStage];

  // Determine which agent name to show in log view
  const currentAgentName = currentStage?.name || 'Unknown';

  return (
    <Box flexDirection="column" height="100%">
      {/* Main View Area */}
      <Box flexDirection="column" flexGrow={1}>
        {state.navigation.level === 'pipeline' && (
          <PipelineView
            stages={state.pipeline.stages}
            selectedIndex={state.navigation.selectedStage}
            dataset={state.pipeline.dataset}
          />
        )}

        {state.navigation.level === 'stage' && currentStage && (
          <StageDetail
            stage={currentStage}
            selectedSlotIndex={state.navigation.selectedSlot}
            recentCompletions={state.pipeline.recentCompletions}
          />
        )}

        {state.navigation.level === 'log' && state.navigation.selectedTableId && (
          <LogView
            tableId={state.navigation.selectedTableId}
            agentName={currentAgentName}
            logs={currentTableLogs}
            scrollOffset={state.navigation.logScrollOffset}
          />
        )}
      </Box>

      {/* Footer */}
      <Box flexDirection="column">
        <CostBar
          totalCostUsd={state.pipeline.totalCostUsd}
          elapsedMs={elapsedMs}
          tableCount={state.pipeline.tableCount}
        />
        <KeyHints level={state.navigation.level} />
      </Box>
    </Box>
  );
}
