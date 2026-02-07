/**
 * Shared retry utility for handling Azure OpenAI content policy errors.
 *
 * Content policy errors are transient - retrying the same request often succeeds
 * because Azure's content moderation can be overly sensitive to certain patterns.
 */

export interface RetryOptions {
  /** Maximum number of attempts (default: 3) */
  maxAttempts?: number;
  /** Delay between retries in milliseconds (default: 2000, rate limits use 15000) */
  delayMs?: number;
  /** Delay for rate limit errors in milliseconds (default: 15000) */
  rateLimitDelayMs?: number;
  /** Callback invoked on each retry attempt */
  onRetry?: (attempt: number, error: Error) => void;
  /** AbortSignal to cancel retries */
  abortSignal?: AbortSignal;
}

export interface RetryResult<T> {
  /** Whether the operation succeeded */
  success: boolean;
  /** The result if successful */
  result?: T;
  /** Error message if all retries failed */
  error?: string;
  /** Number of attempts made */
  attempts: number;
  /** Whether the final error was a policy error */
  wasPolicyError: boolean;
}

/**
 * Patterns that indicate a content policy/moderation error from Azure OpenAI.
 * These errors are often transient and worth retrying.
 */
const POLICY_ERROR_PATTERNS = [
  'usage policy',
  'content policy',
  'flagged as potentially violating',
  'content_filter',
  'content_policy_violation',
  'responsibleaipolicy',
  'content management policy',
];

/**
 * Patterns that indicate a transient/retryable error (not policy, but still worth retrying).
 * Includes null output, timeouts, rate limits, and server errors.
 */
const RETRYABLE_ERROR_PATTERNS = [
  'invalid output',
  'no output',
  'timeout',
  'econnreset',
  'econnrefused',
  'socket hang up',
  'network error',
  '429',
  'rate limit',
  'too many requests',
  'throttl',
  '502',
  '503',
  '504',
  'service unavailable',
  'bad gateway',
  'gateway timeout',
];

/**
 * Check if an error is a rate limit error (needs longer backoff).
 */
export function isRateLimitError(error: unknown): boolean {
  if (!error) return false;
  const message = error instanceof Error
    ? error.message.toLowerCase()
    : String(error).toLowerCase();
  return message.includes('429') || message.includes('rate limit') || message.includes('too many requests') || message.includes('throttl');
}

/**
 * Check if an error is a content policy/moderation error.
 */
export function isPolicyError(error: unknown): boolean {
  if (!error) return false;

  const message = error instanceof Error
    ? error.message.toLowerCase()
    : String(error).toLowerCase();

  return POLICY_ERROR_PATTERNS.some(pattern => message.includes(pattern));
}

/**
 * Check if an error is retryable (policy error OR transient error).
 */
export function isRetryableError(error: unknown): boolean {
  if (isPolicyError(error)) return true;
  if (!error) return false;

  const message = error instanceof Error
    ? error.message.toLowerCase()
    : String(error).toLowerCase();

  return RETRYABLE_ERROR_PATTERNS.some(pattern => message.includes(pattern));
}

/**
 * Sleep for the specified duration, respecting abort signal.
 */
async function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) {
      reject(new Error('Aborted'));
      return;
    }

    const timeout = setTimeout(resolve, ms);

    signal?.addEventListener('abort', () => {
      clearTimeout(timeout);
      reject(new Error('Aborted'));
    }, { once: true });
  });
}

/**
 * Execute an async function with retry logic for content policy errors.
 *
 * Only retries on policy errors - other errors are propagated immediately.
 *
 * @example
 * ```typescript
 * const result = await retryWithPolicyHandling(
 *   async () => {
 *     const { output } = await generateText({ ... });
 *     return output;
 *   },
 *   {
 *     onRetry: (attempt, err) => {
 *       console.warn(`Retry ${attempt}/3: ${err.message}`);
 *     }
 *   }
 * );
 *
 * if (result.success) {
 *   // Use result.result
 * } else {
 *   // Handle failure, result.error contains message
 * }
 * ```
 */
export async function retryWithPolicyHandling<T>(
  fn: () => Promise<T>,
  options?: RetryOptions
): Promise<RetryResult<T>> {
  const maxAttempts = options?.maxAttempts ?? 3;
  const baseDelayMs = options?.delayMs ?? 2000;
  const rateLimitDelayMs = options?.rateLimitDelayMs ?? 15000;
  const onRetry = options?.onRetry;
  const abortSignal = options?.abortSignal;

  let lastError: Error | undefined;
  let wasPolicyError = false;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    // Check for abort before each attempt
    if (abortSignal?.aborted) {
      return {
        success: false,
        error: 'Operation was cancelled',
        attempts: attempt - 1,
        wasPolicyError: false,
      };
    }

    try {
      const result = await fn();
      return {
        success: true,
        result,
        attempts: attempt,
        wasPolicyError: false,
      };
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error));
      wasPolicyError = isPolicyError(error);
      const retryable = isRetryableError(error);

      // Only retry on retryable errors (policy errors, transient failures, rate limits)
      if (!retryable) {
        return {
          success: false,
          error: lastError.message,
          attempts: attempt,
          wasPolicyError,
        };
      }

      // Don't retry if this was the last attempt
      if (attempt === maxAttempts) {
        break;
      }

      // Notify about retry
      onRetry?.(attempt, lastError);

      // Use longer delay for rate limits, exponential backoff for others
      const rateLimit = isRateLimitError(error);
      const delayMs = rateLimit
        ? rateLimitDelayMs * attempt  // 15s, 30s, 45s for rate limits
        : baseDelayMs * attempt;      // 2s, 4s, 6s for others

      // Wait before retrying
      try {
        await sleep(delayMs, abortSignal);
      } catch {
        // Aborted during sleep
        return {
          success: false,
          error: 'Operation was cancelled',
          attempts: attempt,
          wasPolicyError: true,
        };
      }
    }
  }

  // All retries exhausted
  return {
    success: false,
    error: lastError?.message ?? 'Unknown error after retries',
    attempts: maxAttempts,
    wasPolicyError,
  };
}
