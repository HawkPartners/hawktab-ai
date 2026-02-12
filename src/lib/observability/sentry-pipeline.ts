/**
 * Sentry pipeline span helpers.
 *
 * Thin wrapper that keeps Sentry SDK details out of PipelineRunner.
 * Pipeline runs happen outside the HTTP request lifecycle, so we use
 * `Sentry.startSpanManual` for manual span management.
 */

import * as Sentry from '@sentry/nextjs';
import type { AuthContext } from '@/lib/auth';

// =============================================================================
// Types
// =============================================================================

export interface StageSpan {
  finish: (status: 'ok' | 'error') => void;
}

export interface PipelineSpanContext {
  startStage: (name: string) => StageSpan;
  finish: (status: 'ok' | 'error') => void;
}

interface PipelineTransactionOpts {
  pipelineId: string;
  dataset: string;
  orgId?: string;
}

// =============================================================================
// Span helpers
// =============================================================================

/**
 * Start a manual Sentry span for a background pipeline run.
 * Returns a context object with helpers for child spans.
 */
export function startPipelineTransaction(opts: PipelineTransactionOpts): PipelineSpanContext {
  let rootSpanRef: Sentry.Span | undefined;

  // Start the root span via Sentry's manual API.
  // `startSpanManual` gives us a span we must explicitly end.
  Sentry.startSpanManual(
    {
      name: 'pipeline.run',
      op: 'pipeline',
      attributes: {
        'pipeline.id': opts.pipelineId,
        'pipeline.dataset': opts.dataset,
        ...(opts.orgId ? { 'pipeline.org_id': opts.orgId } : {}),
      },
    },
    (span) => {
      rootSpanRef = span;
    },
  );

  return {
    startStage(name: string): StageSpan {
      let stageSpanRef: Sentry.Span | undefined;

      Sentry.startSpanManual(
        {
          name: `pipeline.stage.${name}`,
          op: 'pipeline.stage',
          attributes: { 'stage.name': name },
        },
        (span) => {
          stageSpanRef = span;
        },
      );

      return {
        finish(status: 'ok' | 'error') {
          if (stageSpanRef) {
            stageSpanRef.setStatus({
              code: status === 'ok' ? 1 : 2, // 1 = OK, 2 = ERROR in OpenTelemetry
              message: status,
            });
            stageSpanRef.end();
          }
        },
      };
    },

    finish(status: 'ok' | 'error') {
      if (rootSpanRef) {
        rootSpanRef.setStatus({
          code: status === 'ok' ? 1 : 2,
          message: status,
        });
        rootSpanRef.end();
      }
    },
  };
}

/**
 * Set Sentry user context from auth.
 */
export function setSentryUser(auth: AuthContext): void {
  Sentry.setUser({ id: auth.userId, email: auth.email });
  Sentry.setTag('org_id', auth.orgId);
}
