#!/usr/bin/env node
/**
 * HawkTab AI CLI Entry Point
 *
 * Usage:
 *   hawktab                Show help
 *   hawktab run [dataset]  Run the pipeline
 *   hawktab demo           Show UI in demo mode (no pipeline)
 *
 * Options:
 *   --no-ui              Run without interactive UI (plain output)
 *   --format=joe|antares Excel format (default: joe)
 *   --display=frequency|counts|both Display mode (default: frequency)
 *   --concurrency=N      Override parallel limit
 *   --stop-after-verification Stop before R/Excel generation
 */

// Load environment variables BEFORE any other imports that might need them
import '../lib/loadEnv';

import React from 'react';
import { render } from 'ink';
import meow from 'meow';
import { App } from './App';
import { getPipelineEventBus } from '../lib/events';
import { runPipeline, DEFAULT_DATASET } from '../lib/pipeline';
import type { ExcelFormat, DisplayMode } from '../lib/excel/ExcelFormatter';

// =============================================================================
// CLI Definition
// =============================================================================

const cli = meow(
  `
  Usage
    $ hawktab              Show this help
    $ hawktab run [dataset]  Run the pipeline
    $ hawktab demo         Show UI in demo mode (no pipeline)

  Options
    --no-ui              Run without interactive UI (plain output mode)
    --format=FORMAT      Excel format: joe (default) or antares
    --display=MODE       Display mode: frequency (default), counts, or both
    --concurrency=N      Override parallel processing limit (default: 3)
    --stop-after-verification  Stop pipeline before R/Excel generation

  Examples
    $ hawktab run
    $ hawktab run data/leqvio-monotherapy-demand-NOV217
    $ hawktab run --format=antares --display=both
    $ hawktab run --no-ui
    $ hawktab demo
`,
  {
    importMeta: import.meta,
    flags: {
      noUi: {
        type: 'boolean',
        default: false,
      },
      format: {
        type: 'string',
        default: 'joe',
      },
      display: {
        type: 'string',
        default: 'frequency',
      },
      concurrency: {
        type: 'number',
        default: 3,
      },
      stopAfterVerification: {
        type: 'boolean',
        default: false,
      },
    },
  }
);

// =============================================================================
// Main
// =============================================================================

// =============================================================================
// Console Suppression for UI Mode
// =============================================================================

function suppressConsole(): void {
  // Suppress console output so it doesn't interfere with Ink UI
  // The pipeline emits events that the UI listens to instead
  const noop = () => {};
  console.log = noop;
  console.info = noop;
  console.warn = noop;
  // Keep console.error for critical errors
}

// =============================================================================
// Main
// =============================================================================

async function main(): Promise<void> {
  const [command, datasetFolder] = cli.input;

  // Show help if no command provided
  if (!command) {
    cli.showHelp();
    return;
  }

  // Handle demo command - show UI without running pipeline
  if (command === 'demo') {
    suppressConsole();

    const { waitUntilExit, unmount } = render(
      <App
        onExit={() => {
          unmount();
          process.exit(0);
        }}
      />
    );

    await waitUntilExit();
    return;
  }

  if (command !== 'run') {
    console.error(`Unknown command: ${command}`);
    console.error('Use "hawktab run [dataset]" or "hawktab demo"');
    process.exit(1);
  }

  // Determine dataset folder (default if not provided)
  const dataset = datasetFolder || DEFAULT_DATASET;

  // Parse options
  const format = (cli.flags.format === 'antares' ? 'antares' : 'joe') as ExcelFormat;
  const displayMode = (['frequency', 'counts', 'both'].includes(cli.flags.display)
    ? cli.flags.display
    : 'frequency') as DisplayMode;
  const concurrency = cli.flags.concurrency || 3;
  const stopAfterVerification = cli.flags.stopAfterVerification;

  // Check for --no-ui flag
  if (cli.flags.noUi) {
    // Run in plain output mode (no UI, just console output)
    console.log('Running pipeline in plain output mode...\n');

    const result = await runPipeline(dataset, {
      format,
      displayMode,
      stopAfterVerification,
      concurrency,
      quiet: false, // Show console output
    });

    if (!result.success) {
      console.error(`\nPipeline failed: ${result.error}`);
      process.exit(1);
    }

    process.exit(0);
  }

  // Enable event bus for UI mode
  const bus = getPipelineEventBus();
  bus.enable();

  // Suppress console output so it doesn't interfere with the UI
  // The pipeline emits events that the UI displays instead
  suppressConsole();

  // Render the Ink app
  const { waitUntilExit, unmount } = render(
    <App
      onExit={() => {
        unmount();
        process.exit(0);
      }}
    />
  );

  // Run the pipeline in parallel with the UI
  // The UI will receive events from the pipeline
  runPipeline(dataset, {
    format,
    displayMode,
    stopAfterVerification,
    concurrency,
    quiet: true, // Suppress console output in UI mode
  })
    .then((result) => {
      if (!result.success) {
        // Let the UI show the error, don't exit immediately
        console.error(`\nPipeline failed: ${result.error}`);
      }
      // Keep the UI running so user can see final state
      // They can press 'q' to exit
    })
    .catch((error) => {
      console.error('\nUnexpected error:', error);
      unmount();
      process.exit(1);
    });

  // Wait for the app to exit (user presses 'q')
  await waitUntilExit();
}

// Run main
main().catch((error) => {
  console.error('CLI Error:', error);
  process.exit(1);
});

// =============================================================================
// Export for programmatic usage
// =============================================================================

export { App } from './App';
export * from '../lib/events';
export { runPipeline } from '../lib/pipeline';
