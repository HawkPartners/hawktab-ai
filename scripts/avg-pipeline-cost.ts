#!/usr/bin/env npx tsx
/**
 * Scans all pipeline-summary.json files in outputs/ and reports cost stats.
 *
 * Usage:
 *   npx tsx scripts/avg-pipeline-cost.ts
 *   npx tsx scripts/avg-pipeline-cost.ts --latest   # only the most recent run per dataset
 */
import fs from 'fs';
import path from 'path';

const OUTPUTS_DIR = path.resolve(import.meta.dirname, '..', 'outputs');
const latestOnly = process.argv.includes('--latest');

interface RunInfo {
  dataset: string;
  pipeline: string;
  timestamp: string;
  cost: number;
  tokens: number;
  durationMin: number;
  agents: number;
}

// Recursively find all pipeline-summary.json files
function findSummaries(dir: string): string[] {
  const results: string[] = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...findSummaries(full));
    } else if (entry.name === 'pipeline-summary.json') {
      results.push(full);
    }
  }
  return results;
}

const summaryFiles = findSummaries(OUTPUTS_DIR);

if (summaryFiles.length === 0) {
  console.log('No pipeline-summary.json files found in outputs/');
  process.exit(0);
}

const runs: RunInfo[] = [];

for (const file of summaryFiles) {
  try {
    const raw = JSON.parse(fs.readFileSync(file, 'utf-8'));
    const totals = raw?.costs?.totals;
    if (!totals || typeof totals.estimatedCostUsd !== 'number') continue;

    const relPath = path.relative(OUTPUTS_DIR, file);
    const parts = relPath.split(path.sep);

    runs.push({
      dataset: raw.dataset || parts[0] || 'unknown',
      pipeline: parts[1] || 'unknown',
      timestamp: raw.timestamp || '',
      cost: totals.estimatedCostUsd,
      tokens: totals.totalTokens || 0,
      durationMin: (raw.duration?.ms || 0) / 60_000,
      agents: totals.calls || 0,
    });
  } catch {
    // skip malformed files
  }
}

if (runs.length === 0) {
  console.log('No valid cost data found in any pipeline-summary.json.');
  process.exit(0);
}

// Sort by timestamp descending
runs.sort((a, b) => b.timestamp.localeCompare(a.timestamp));

// If --latest, keep only the most recent run per dataset
let display = runs;
if (latestOnly) {
  const seen = new Set<string>();
  display = runs.filter((r) => {
    if (seen.has(r.dataset)) return false;
    seen.add(r.dataset);
    return true;
  });
}

// Print table
const pad = (s: string, n: number) => s.padEnd(n);
const rpad = (s: string, n: number) => s.padStart(n);

console.log();
console.log(
  pad('Dataset', 45),
  rpad('Cost', 8),
  rpad('Tokens', 12),
  rpad('Time', 8),
  rpad('Calls', 6),
);
console.log('-'.repeat(82));

for (const r of display) {
  console.log(
    pad(r.dataset.slice(0, 44), 45),
    rpad('$' + r.cost.toFixed(2), 8),
    rpad(r.tokens.toLocaleString(), 12),
    rpad(r.durationMin.toFixed(1) + 'm', 8),
    rpad(String(r.agents), 6),
  );
}

console.log('-'.repeat(82));

const totalCost = display.reduce((s, r) => s + r.cost, 0);
const avgCost = totalCost / display.length;
const minCost = Math.min(...display.map((r) => r.cost));
const maxCost = Math.max(...display.map((r) => r.cost));
const avgTokens = display.reduce((s, r) => s + r.tokens, 0) / display.length;
const avgDuration = display.reduce((s, r) => s + r.durationMin, 0) / display.length;

console.log();
console.log(`  Runs:     ${display.length}${latestOnly ? ' (latest per dataset)' : ''}`);
console.log(`  Avg cost: $${avgCost.toFixed(2)}`);
console.log(`  Min cost: $${minCost.toFixed(2)}`);
console.log(`  Max cost: $${maxCost.toFixed(2)}`);
console.log(`  Total:    $${totalCost.toFixed(2)}`);
console.log(`  Avg tokens: ${Math.round(avgTokens).toLocaleString()}`);
console.log(`  Avg time:   ${avgDuration.toFixed(1)}m`);
console.log();
