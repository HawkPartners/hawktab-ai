/**
 * usePipelineEvents Hook
 *
 * Subscribes to pipeline events and updates state accordingly.
 */

import { useEffect, useCallback } from 'react';
import { getPipelineEventBus } from '../../lib/events';
import type { PipelineEvent } from '../../lib/events/types';

export interface UsePipelineEventsOptions {
  onEvent: (event: PipelineEvent) => void;
}

export function usePipelineEvents({ onEvent }: UsePipelineEventsOptions): void {
  const handleEvent = useCallback(
    (event: PipelineEvent) => {
      onEvent(event);
    },
    [onEvent]
  );

  useEffect(() => {
    const bus = getPipelineEventBus();

    // Enable event bus when UI is mounted
    bus.enable();

    // Subscribe to all events using wildcard
    bus.on('*', handleEvent);

    return () => {
      // Unsubscribe on unmount
      bus.off('*', handleEvent);

      // Disable event bus when UI is unmounted
      bus.disable();
    };
  }, [handleEvent]);
}
