/**
 * TableQueue - Async producer-consumer queue for Path B pipeline
 *
 * Enables overlapping execution of TableAgent (producer) and VerificationAgent (consumer).
 * - Producer pushes tables as each question group completes
 * - Consumer pulls tables and processes them, blocking when queue is empty
 * - Clean completion signaling when producer finishes
 */

import { TableDefinition } from '@/schemas/tableAgentSchema';

/**
 * Item in the queue representing a single table with its question context
 */
export interface TableQueueItem {
  table: TableDefinition;
  questionId: string;
  questionText: string;
}

/**
 * Async queue for producer-consumer coordination between TableAgent and VerificationAgent.
 *
 * Usage:
 * ```typescript
 * const queue = new TableQueue();
 *
 * // Producer (TableAgent)
 * queue.push({ table, questionId, questionText });
 * queue.markDone(); // When all tables produced
 *
 * // Consumer (VerificationAgent)
 * while (true) {
 *   const item = await queue.pull();
 *   if (item === null) break; // Producer done, queue empty
 *   await processTable(item);
 * }
 * ```
 */
export class TableQueue {
  private queue: TableQueueItem[] = [];
  private resolvers: Array<(value: TableQueueItem | null) => void> = [];
  private producerDone = false;
  private producerError: Error | null = null;
  private totalPushed = 0;
  private totalPulled = 0;

  /**
   * Producer adds a table to the queue.
   * If consumer is waiting, resolves immediately without queueing.
   */
  push(item: TableQueueItem): void {
    if (this.producerDone) {
      console.warn('[TableQueue] Warning: push called after markDone');
      return;
    }

    this.totalPushed++;

    if (this.resolvers.length > 0) {
      // Consumer is waiting - resolve immediately
      const resolver = this.resolvers.shift()!;
      resolver(item);
    } else {
      // No consumer waiting - add to queue
      this.queue.push(item);
    }
  }

  /**
   * Producer signals that all tables have been produced.
   * All waiting consumers will receive null.
   */
  markDone(error?: Error): void {
    this.producerDone = true;
    this.producerError = error || null;

    // Resolve all waiting consumers with null
    for (const resolver of this.resolvers) {
      resolver(null);
    }
    this.resolvers = [];
  }

  /**
   * Consumer pulls the next table from the queue.
   * - Returns immediately if queue has items
   * - Blocks (via Promise) if queue empty but producer not done
   * - Returns null if queue empty AND producer done (signals completion)
   * - Throws if producer encountered an error
   */
  async pull(): Promise<TableQueueItem | null> {
    // Check for producer error
    if (this.producerError) {
      throw this.producerError;
    }

    // Return from queue if available
    if (this.queue.length > 0) {
      this.totalPulled++;
      return this.queue.shift()!;
    }

    // Queue empty and producer done - signal completion
    if (this.producerDone) {
      return null;
    }

    // Queue empty but producer still running - wait
    return new Promise((resolve) => {
      this.resolvers.push((item) => {
        if (item !== null) {
          this.totalPulled++;
        }
        resolve(item);
      });
    });
  }

  /**
   * Check if producer has finished (regardless of queue contents)
   */
  get isDone(): boolean {
    return this.producerDone;
  }

  /**
   * Current number of items waiting in queue
   */
  get length(): number {
    return this.queue.length;
  }

  /**
   * Total items pushed by producer
   */
  get pushed(): number {
    return this.totalPushed;
  }

  /**
   * Total items pulled by consumer
   */
  get pulled(): number {
    return this.totalPulled;
  }

  /**
   * Number of consumers waiting for items
   */
  get waitingConsumers(): number {
    return this.resolvers.length;
  }

  /**
   * Get queue statistics for logging/debugging
   */
  getStats(): {
    pushed: number;
    pulled: number;
    pending: number;
    waiting: number;
    done: boolean;
    hasError: boolean;
  } {
    return {
      pushed: this.totalPushed,
      pulled: this.totalPulled,
      pending: this.queue.length,
      waiting: this.resolvers.length,
      done: this.producerDone,
      hasError: this.producerError !== null,
    };
  }
}
