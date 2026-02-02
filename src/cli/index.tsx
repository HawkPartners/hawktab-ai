#!/usr/bin/env node
/**
 * HawkTab AI CLI Entry Point
 *
 * Usage:
 *   hawktab                Show interactive menu (default)
 *   hawktab run [dataset]  Run the pipeline
 *   hawktab demo           Show UI in demo mode (no pipeline)
 *   hawktab help           Show help
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
    $ hawktab              Show interactive menu
    $ hawktab run [dataset]  Run the pipeline
    $ hawktab demo         Show UI in demo mode (no pipeline)
    $ hawktab help         Show this help

  Options
    --no-ui              Run without interactive UI (plain output mode)
    --format=FORMAT      Excel format: joe (default) or antares
    --display=MODE       Display mode: frequency (default), counts, or both
    --concurrency=N      Override parallel processing limit (default: 3)
    --stop-after-verification  Stop pipeline before R/Excel generation
    --stat-thresholds=X,Y  Significance thresholds (e.g., 0.05,0.10 for dual confidence)
    --stat-min-base=N    Minimum base size for significance testing (default: 0)

  Examples
    $ hawktab
    $ hawktab run
    $ hawktab run data/leqvio-monotherapy-demand-NOV217
    $ hawktab run --format=antares --display=both
    $ hawktab run --stat-thresholds=0.05,0.10 --stat-min-base=30
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
      statThresholds: {
        type: 'string',
        default: '',
      },
      statMinBase: {
        type: 'number',
        default: -1,  // -1 means use env default
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

  // Show interactive menu if no command provided (new default behavior)
  if (!command) {
    // Enable event bus for when user starts pipeline from menu
    const bus = getPipelineEventBus();
    bus.enable();

    suppressConsole();

    // Track if pipeline has been started
    let pipelineStarted = false;

    const { waitUntilExit, unmount } = render(
      <App
        initialMode="menu"
        onExit={() => {
          unmount();
          process.exit(0);
        }}
        onStartPipeline={() => {
          if (pipelineStarted) return;
          pipelineStarted = true;

          // Start pipeline with default options
          runPipeline(DEFAULT_DATASET, {
            format: 'joe',
            displayMode: 'frequency',
            stopAfterVerification: false,
            concurrency: 3,
            quiet: true,
          })
            .then((result) => {
              if (!result.success) {
                console.error(`\nPipeline failed: ${result.error}`);
              }
            })
            .catch((error) => {
              console.error('\nUnexpected error:', error);
            });
        }}
      />
    );

    await waitUntilExit();
    return;
  }

  // Show help
  if (command === 'help' || command === '--help' || command === '-h') {
    cli.showHelp();
    return;
  }

  // Handle demo command - show UI without running pipeline
  if (command === 'demo') {
    suppressConsole();

    const { waitUntilExit, unmount } = render(
      <App
        initialMode="pipeline"
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
    console.error('Use "hawktab" for interactive menu, "hawktab run [dataset]", or "hawktab help"');
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

  // Parse stat testing options (CLI overrides env)
  type StatTestingOverride = { thresholds?: number[]; minBase?: number };
  const statTesting: StatTestingOverride = {};
  if (cli.flags.statThresholds) {
    const parsed = cli.flags.statThresholds
      .split(',')
      .map((s: string) => parseFloat(s.trim()))
      .filter((n: number) => !isNaN(n) && n > 0 && n < 1);
    if (parsed.length > 0) {
      statTesting.thresholds = parsed.sort((a: number, b: number) => a - b);
    }
  }
  if (cli.flags.statMinBase >= 0) {
    statTesting.minBase = cli.flags.statMinBase;
  }

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
      statTesting: Object.keys(statTesting).length > 0 ? statTesting : undefined,
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

  // Create a promise that resolves when the App is ready to receive events
  let resolveReady: () => void;
  const readyPromise = new Promise<void>((resolve) => {
    resolveReady = resolve;
  });

  // Render the Ink app
  const { waitUntilExit, unmount } = render(
    <App
      initialMode="pipeline"
      dataset={dataset}
      onExit={() => {
        unmount();
        process.exit(0);
      }}
      onReady={() => {
        resolveReady();
      }}
    />
  );

  // Wait for App to be ready before starting pipeline
  // This ensures the event bus subscription is set up first
  await readyPromise;

  // Run the pipeline - now the UI is subscribed and ready for events
  runPipeline(dataset, {
    format,
    displayMode,
    stopAfterVerification,
    concurrency,
    quiet: true, // Suppress console output in UI mode
    statTesting: Object.keys(statTesting).length > 0 ? statTesting : undefined,
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
