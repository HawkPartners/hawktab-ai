/**
 * AgentMetrics
 *
 * Tracks token usage and costs across all agents in the pipeline.
 * Provides aggregate metrics for pipeline runs.
 *
 * Usage:
 *   const metrics = new AgentMetricsCollector();
 *
 *   // After each agent call:
 *   metrics.record('VerificationAgent', 'gpt-4o', { input: 1500, output: 800 }, 2341);
 *
 *   // At end of pipeline:
 *   const summary = await metrics.getSummary();
 */

import {
  calculateCost,
  formatCost,
  type TokenUsage,
  type CostBreakdown,
} from './CostCalculator';

// =============================================================================
// Types
// =============================================================================

export interface AgentMetric {
  agentName: string;
  model: string;
  tokens: TokenUsage;
  durationMs: number;
  cost?: CostBreakdown;
  timestamp: Date;
}

export interface AgentSummary {
  agentName: string;
  model: string;
  calls: number;
  totalInputTokens: number;
  totalOutputTokens: number;
  totalTokens: number;
  totalDurationMs: number;
  avgDurationMs: number;
  estimatedCostUsd: number;
}

export interface PipelineSummary {
  byAgent: AgentSummary[];
  totals: {
    calls: number;
    inputTokens: number;
    outputTokens: number;
    totalTokens: number;
    durationMs: number;
    estimatedCostUsd: number;
  };
  timestamp: string;
}

// =============================================================================
// Metrics Collector
// =============================================================================

export class AgentMetricsCollector {
  private metrics: AgentMetric[] = [];

  /**
   * Record metrics from an agent call
   *
   * @param agentName - Name of the agent (BannerAgent, CrosstabAgent, etc.)
   * @param model - Model used (from env or response)
   * @param tokens - Token usage { input, output }
   * @param durationMs - Call duration in milliseconds
   */
  record(
    agentName: string,
    model: string,
    tokens: TokenUsage,
    durationMs: number
  ): void {
    this.metrics.push({
      agentName,
      model,
      tokens,
      durationMs,
      timestamp: new Date(),
    });
  }

  /**
   * Get all recorded metrics
   */
  getMetrics(): AgentMetric[] {
    return [...this.metrics];
  }

  /**
   * Get summary with cost calculations
   */
  async getSummary(): Promise<PipelineSummary> {
    // Calculate costs for all metrics
    const metricsWithCosts = await Promise.all(
      this.metrics.map(async (m) => ({
        ...m,
        cost: await calculateCost(m.model, m.tokens),
      }))
    );

    // Group by agent
    const byAgentMap = new Map<string, AgentMetric[]>();
    for (const metric of metricsWithCosts) {
      const key = `${metric.agentName}|${metric.model}`;
      if (!byAgentMap.has(key)) {
        byAgentMap.set(key, []);
      }
      byAgentMap.get(key)!.push(metric);
    }

    // Build per-agent summaries
    const byAgent: AgentSummary[] = [];
    for (const [key, agentMetrics] of byAgentMap) {
      const [agentName, model] = key.split('|');
      const totalInputTokens = agentMetrics.reduce((sum, m) => sum + m.tokens.input, 0);
      const totalOutputTokens = agentMetrics.reduce((sum, m) => sum + m.tokens.output, 0);
      const totalDurationMs = agentMetrics.reduce((sum, m) => sum + m.durationMs, 0);
      const estimatedCostUsd = agentMetrics.reduce(
        (sum, m) => sum + (m.cost?.totalCost || 0),
        0
      );

      byAgent.push({
        agentName,
        model,
        calls: agentMetrics.length,
        totalInputTokens,
        totalOutputTokens,
        totalTokens: totalInputTokens + totalOutputTokens,
        totalDurationMs,
        avgDurationMs: Math.round(totalDurationMs / agentMetrics.length),
        estimatedCostUsd,
      });
    }

    // Sort by agent name
    byAgent.sort((a, b) => a.agentName.localeCompare(b.agentName));

    // Calculate totals
    const totals = {
      calls: this.metrics.length,
      inputTokens: byAgent.reduce((sum, a) => sum + a.totalInputTokens, 0),
      outputTokens: byAgent.reduce((sum, a) => sum + a.totalOutputTokens, 0),
      totalTokens: byAgent.reduce((sum, a) => sum + a.totalTokens, 0),
      durationMs: byAgent.reduce((sum, a) => sum + a.totalDurationMs, 0),
      estimatedCostUsd: byAgent.reduce((sum, a) => sum + a.estimatedCostUsd, 0),
    };

    return {
      byAgent,
      totals,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Format summary for console display
   */
  async formatSummary(): Promise<string> {
    const summary = await this.getSummary();
    const lines: string[] = [];

    lines.push('');
    lines.push('═'.repeat(70));
    lines.push('  Pipeline Cost Summary');
    lines.push('═'.repeat(70));
    lines.push('');

    // Per-agent breakdown
    for (const agent of summary.byAgent) {
      lines.push(`  ${agent.agentName} (${agent.model})`);
      lines.push(`    Calls: ${agent.calls}`);
      lines.push(
        `    Tokens: ${agent.totalInputTokens.toLocaleString()} in / ${agent.totalOutputTokens.toLocaleString()} out`
      );
      lines.push(`    Duration: ${(agent.totalDurationMs / 1000).toFixed(1)}s total, ${(agent.avgDurationMs / 1000).toFixed(2)}s avg`);
      lines.push(`    Cost: ${formatCost(agent.estimatedCostUsd)}`);
      lines.push('');
    }

    // Totals
    lines.push('─'.repeat(70));
    lines.push(`  TOTAL`);
    lines.push(`    Calls: ${summary.totals.calls}`);
    lines.push(
      `    Tokens: ${summary.totals.inputTokens.toLocaleString()} in / ${summary.totals.outputTokens.toLocaleString()} out (${summary.totals.totalTokens.toLocaleString()} total)`
    );
    lines.push(`    Agent Time: ${(summary.totals.durationMs / 1000).toFixed(1)}s (cumulative, may exceed wall-clock due to parallelism)`);
    lines.push(`    Estimated Cost: ${formatCost(summary.totals.estimatedCostUsd)}`);
    lines.push('═'.repeat(70));
    lines.push('');

    return lines.join('\n');
  }

  /**
   * Clear all recorded metrics
   */
  clear(): void {
    this.metrics = [];
  }
}

// =============================================================================
// Singleton Instance (for pipeline-wide tracking)
// =============================================================================

let globalCollector: AgentMetricsCollector | null = null;

/**
 * Get the global metrics collector (creates one if needed)
 */
export function getMetricsCollector(): AgentMetricsCollector {
  if (!globalCollector) {
    globalCollector = new AgentMetricsCollector();
  }
  return globalCollector;
}

/**
 * Reset the global metrics collector
 */
export function resetMetricsCollector(): void {
  globalCollector = new AgentMetricsCollector();
}

// =============================================================================
// Convenience Functions
// =============================================================================

/**
 * Record metrics to the global collector
 */
export function recordAgentMetrics(
  agentName: string,
  model: string,
  tokens: TokenUsage,
  durationMs: number
): void {
  getMetricsCollector().record(agentName, model, tokens, durationMs);
}

/**
 * Get and format the global summary
 */
export async function getPipelineCostSummary(): Promise<string> {
  return getMetricsCollector().formatSummary();
}
