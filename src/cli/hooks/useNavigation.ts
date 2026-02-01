/**
 * useNavigation Hook
 *
 * Handles keyboard input for navigation.
 */

import { useInput } from 'ink';
import type { NavigationAction } from '../state/reducer';

export interface UseNavigationOptions {
  onAction: (action: NavigationAction) => void;
  onQuit: () => void;
}

export function useNavigation({ onAction, onQuit }: UseNavigationOptions): void {
  useInput((input, key) => {
    // Quit
    if (input === 'q' || input === 'Q') {
      onQuit();
      return;
    }

    // Navigation up
    if (input === 'k' || key.upArrow) {
      onAction({ type: 'nav:up' });
      return;
    }

    // Navigation down
    if (input === 'j' || key.downArrow) {
      onAction({ type: 'nav:down' });
      return;
    }

    // Drill down
    if (key.return) {
      onAction({ type: 'nav:enter' });
      return;
    }

    // Go back
    if (key.escape) {
      onAction({ type: 'nav:back' });
      return;
    }

    // Page up (fast scroll)
    if (key.pageUp || (input === 'u' && key.ctrl)) {
      onAction({ type: 'nav:scroll-up' });
      return;
    }

    // Page down (fast scroll)
    if (key.pageDown || (input === 'd' && key.ctrl)) {
      onAction({ type: 'nav:scroll-down' });
      return;
    }
  });
}
