/**
 * Console output capture for pipeline runs
 *
 * Hooks console.log/warn/error to:
 * 1. Add context prefix: [Project Name | runId | stage]
 * 2. Write to logs/pipeline.log file
 *
 * Benefits:
 * - Searchable Railway logs by project name and run ID
 * - Full sequential log file persisted in R2
 * - No need to update 142+ console call sites
 */

import { createWriteStream, type WriteStream } from 'fs';
import { promises as fs } from 'fs';
import * as path from 'path';

interface CaptureContext {
  projectName: string;
  runId: string;
  stage?: string;
}

interface OriginalConsoleMethods {
  log: typeof console.log;
  warn: typeof console.warn;
  error: typeof console.error;
}

export class ConsoleCapture {
  private logPath: string;
  private logStream: WriteStream | null = null;
  private writeQueue = Promise.resolve();
  private originalMethods: OriginalConsoleMethods | null = null;
  private context: CaptureContext;

  constructor(outputDir: string, context: CaptureContext) {
    this.logPath = path.join(outputDir, 'logs', 'pipeline.log');
    this.context = context;
  }

  /**
   * Start capturing console output
   * Hooks console methods and begins writing to log file
   */
  async start(): Promise<void> {
    // Create logs directory
    await fs.mkdir(path.dirname(this.logPath), { recursive: true });

    // Open log file stream
    this.logStream = createWriteStream(this.logPath, { flags: 'a' });

    // Save original console methods
    this.originalMethods = {
      log: console.log,
      warn: console.warn,
      error: console.error,
    };

    // Build context prefix: [Project | runId]
    const shortRunId = this.context.runId.slice(-8);
    const basePrefix = `[${this.context.projectName} | ${shortRunId}]`;

    // Hook console.log
    console.log = (...args: unknown[]) => {
      const message = this.formatMessage(args);
      const prefixed = `${basePrefix} ${message}`;
      this.write('INFO', message);
      this.originalMethods!.log(prefixed);
    };

    // Hook console.warn
    console.warn = (...args: unknown[]) => {
      const message = this.formatMessage(args);
      const prefixed = `${basePrefix} ${message}`;
      this.write('WARN', message);
      this.originalMethods!.warn(prefixed);
    };

    // Hook console.error
    console.error = (...args: unknown[]) => {
      const message = this.formatMessage(args);
      const prefixed = `${basePrefix} ${message}`;
      this.write('ERROR', message);
      this.originalMethods!.error(prefixed);
    };
  }

  /**
   * Stop capturing and restore original console methods
   */
  async stop(): Promise<void> {
    if (this.originalMethods) {
      console.log = this.originalMethods.log;
      console.warn = this.originalMethods.warn;
      console.error = this.originalMethods.error;
      this.originalMethods = null;
    }

    // Wait for pending writes
    await this.writeQueue;

    // Close log stream
    if (this.logStream) {
      await new Promise<void>((resolve) => {
        this.logStream!.end(() => resolve());
      });
      this.logStream = null;
    }
  }

  /**
   * Format console arguments into a single message string
   */
  private formatMessage(args: unknown[]): string {
    return args
      .map((arg) => {
        if (typeof arg === 'string') return arg;
        if (arg instanceof Error) return `${arg.message}\n${arg.stack}`;
        try {
          return JSON.stringify(arg);
        } catch {
          return String(arg);
        }
      })
      .join(' ');
  }

  /**
   * Write log entry to file with timestamp and level
   * Uses write queue to prevent interleaving (same pattern as ErrorPersistence)
   */
  private write(level: string, message: string): void {
    if (!this.logStream) return;

    const timestamp = new Date().toISOString();
    const line = `[${timestamp}] [${level}] ${message}\n`;

    // Queue writes to prevent interleaving from concurrent operations
    this.writeQueue = this.writeQueue.then(
      () =>
        new Promise<void>((resolve, reject) => {
          this.logStream!.write(line, (err) => {
            if (err) reject(err);
            else resolve();
          });
        })
    );
  }
}
