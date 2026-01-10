/**
 * Calculate Metrics from Comparison Report
 *
 * Calculates accuracy metrics from an annotated comparison report.
 *
 * Usage:
 *   npx tsx scripts/calculate-metrics.ts <path-to-comparison-report.json>
 *
 * Example:
 *   npx tsx scripts/calculate-metrics.ts outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-01-09T16-54-54-155Z/comparison-report.json
 *
 * Metrics calculated:
 * - Strict accuracy: Exact match to golden dataset (no diffs)
 * - Practical accuracy: Excludes "acceptable" differences
 * - Wrong rate: Percentage of differences marked as "wrong"
 */

import fs from 'fs/promises';

// =============================================================================
// Types
// =============================================================================

interface DiffEntry {
  id: string;
  category: 'banner' | 'crosstab' | 'structure' | 'data';
  tableId?: string;
  groupName?: string;
  columnName?: string;
  rowKey?: string;
  cut?: string;
  diffType: string;
  path?: string;
  field?: string;
  expected: unknown;
  actual: unknown;
  annotation: 'acceptable' | 'wrong' | null;
  attribution: string | null;
  notes: string;
}

interface ComparisonSummary {
  total: number;
  matches: number;
  diffs: number;
}

interface ComparisonReport {
  metadata: {
    dataset: string;
    runTimestamp: string;
    pipelineFolder: string;
    generatedAt: string;
    status: string;
  };
  summary: {
    banner: ComparisonSummary;
    crosstab: ComparisonSummary;
    structure: ComparisonSummary;
    data: ComparisonSummary;
  };
  overall: {
    totalDiffs: number;
    reviewed: number;
    acceptable: number;
    wrong: number;
  };
  differences: DiffEntry[];
}

interface CategoryMetrics {
  total: number;
  matches: number;
  diffs: number;
  acceptable: number;
  wrong: number;
  unreviewed: number;
  strictAccuracy: number;
  practicalAccuracy: number;
}

interface AttributionBreakdown {
  [attribution: string]: number;
}

interface Metrics {
  dataset: string;
  runTimestamp: string;
  calculatedAt: string;
  reviewStatus: {
    totalDiffs: number;
    reviewed: number;
    unreviewed: number;
    percentReviewed: number;
  };
  byCategory: {
    banner: CategoryMetrics;
    crosstab: CategoryMetrics;
    structure: CategoryMetrics;
    data: CategoryMetrics;
  };
  overall: {
    totalComparisons: number;
    totalMatches: number;
    totalDiffs: number;
    acceptable: number;
    wrong: number;
    strictAccuracy: number;
    practicalAccuracy: number;
    wrongRate: number;
  };
  attribution: AttributionBreakdown;
  topIssues: Array<{
    category: string;
    diffType: string;
    count: number;
    example: string;
  }>;
}

// =============================================================================
// Metric Calculation
// =============================================================================

function calculateCategoryMetrics(
  summary: ComparisonSummary,
  diffs: DiffEntry[],
  category: string
): CategoryMetrics {
  const categoryDiffs = diffs.filter(d => d.category === category);
  const acceptable = categoryDiffs.filter(d => d.annotation === 'acceptable').length;
  const wrong = categoryDiffs.filter(d => d.annotation === 'wrong').length;
  const unreviewed = categoryDiffs.filter(d => d.annotation === null).length;

  const strictAccuracy = summary.total > 0
    ? (summary.matches / summary.total) * 100
    : 100;

  // Practical accuracy: treat acceptable differences as matches
  const practicalMatches = summary.matches + acceptable;
  const practicalAccuracy = summary.total > 0
    ? (practicalMatches / summary.total) * 100
    : 100;

  return {
    total: summary.total,
    matches: summary.matches,
    diffs: summary.diffs,
    acceptable,
    wrong,
    unreviewed,
    strictAccuracy: Math.round(strictAccuracy * 100) / 100,
    practicalAccuracy: Math.round(practicalAccuracy * 100) / 100,
  };
}

function calculateMetrics(report: ComparisonReport): Metrics {
  const diffs = report.differences;

  // Calculate per-category metrics
  const bannerMetrics = calculateCategoryMetrics(report.summary.banner, diffs, 'banner');
  const crosstabMetrics = calculateCategoryMetrics(report.summary.crosstab, diffs, 'crosstab');
  const structureMetrics = calculateCategoryMetrics(report.summary.structure, diffs, 'structure');
  const dataMetrics = calculateCategoryMetrics(report.summary.data, diffs, 'data');

  // Overall metrics
  const totalComparisons =
    report.summary.banner.total +
    report.summary.crosstab.total +
    report.summary.structure.total +
    report.summary.data.total;

  const totalMatches =
    report.summary.banner.matches +
    report.summary.crosstab.matches +
    report.summary.structure.matches +
    report.summary.data.matches;

  const totalDiffs = diffs.length;
  const acceptable = diffs.filter(d => d.annotation === 'acceptable').length;
  const wrong = diffs.filter(d => d.annotation === 'wrong').length;
  const reviewed = acceptable + wrong;
  const unreviewed = totalDiffs - reviewed;

  const strictAccuracy = totalComparisons > 0
    ? (totalMatches / totalComparisons) * 100
    : 100;

  const practicalMatches = totalMatches + acceptable;
  const practicalAccuracy = totalComparisons > 0
    ? (practicalMatches / totalComparisons) * 100
    : 100;

  const wrongRate = totalDiffs > 0
    ? (wrong / totalDiffs) * 100
    : 0;

  // Attribution breakdown
  const attribution: AttributionBreakdown = {};
  for (const diff of diffs) {
    if (diff.attribution) {
      attribution[diff.attribution] = (attribution[diff.attribution] || 0) + 1;
    }
  }

  // Top issues (group by category + diffType)
  const issueGroups = new Map<string, { count: number; example: DiffEntry }>();
  for (const diff of diffs) {
    const key = `${diff.category}:${diff.diffType}`;
    const existing = issueGroups.get(key);
    if (existing) {
      existing.count++;
    } else {
      issueGroups.set(key, { count: 1, example: diff });
    }
  }

  const topIssues = Array.from(issueGroups.entries())
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 10)
    .map(([key, value]) => {
      const [category, diffType] = key.split(':');
      let example = '';
      if (value.example.tableId) example = value.example.tableId;
      if (value.example.groupName) example = value.example.groupName;
      if (value.example.columnName) example += ` → ${value.example.columnName}`;
      if (value.example.field) example += ` (${value.example.field})`;
      return { category, diffType, count: value.count, example };
    });

  return {
    dataset: report.metadata.dataset,
    runTimestamp: report.metadata.runTimestamp,
    calculatedAt: new Date().toISOString(),
    reviewStatus: {
      totalDiffs,
      reviewed,
      unreviewed,
      percentReviewed: totalDiffs > 0 ? Math.round((reviewed / totalDiffs) * 100) : 100,
    },
    byCategory: {
      banner: bannerMetrics,
      crosstab: crosstabMetrics,
      structure: structureMetrics,
      data: dataMetrics,
    },
    overall: {
      totalComparisons,
      totalMatches,
      totalDiffs,
      acceptable,
      wrong,
      strictAccuracy: Math.round(strictAccuracy * 100) / 100,
      practicalAccuracy: Math.round(practicalAccuracy * 100) / 100,
      wrongRate: Math.round(wrongRate * 100) / 100,
    },
    attribution,
    topIssues,
  };
}

// =============================================================================
// Display Functions
// =============================================================================

function formatPercent(value: number): string {
  return `${value.toFixed(2)}%`;
}

function displayMetrics(metrics: Metrics): void {
  console.log('\n════════════════════════════════════════════════════════════════');
  console.log('                    EVALUATION METRICS REPORT                    ');
  console.log('════════════════════════════════════════════════════════════════');
  console.log(`Dataset:      ${metrics.dataset}`);
  console.log(`Run:          ${metrics.runTimestamp}`);
  console.log(`Calculated:   ${metrics.calculatedAt}`);

  // Review Status
  console.log('\n┌─────────────────────────────────────────────────────────────┐');
  console.log('│  REVIEW STATUS                                              │');
  console.log('├─────────────────────────────────────────────────────────────┤');
  console.log(`│  Total Differences: ${String(metrics.reviewStatus.totalDiffs).padStart(5)}                                 │`);
  console.log(`│  Reviewed:          ${String(metrics.reviewStatus.reviewed).padStart(5)}  (${formatPercent(metrics.reviewStatus.percentReviewed).padStart(7)})                    │`);
  console.log(`│  Unreviewed:        ${String(metrics.reviewStatus.unreviewed).padStart(5)}                                 │`);
  console.log('└─────────────────────────────────────────────────────────────┘');

  if (metrics.reviewStatus.unreviewed > 0) {
    console.log('\n⚠️  Warning: Not all differences have been reviewed.');
    console.log('   Practical accuracy may change after full review.\n');
  }

  // Overall Metrics
  console.log('┌─────────────────────────────────────────────────────────────┐');
  console.log('│  OVERALL ACCURACY                                           │');
  console.log('├─────────────────────────────────────────────────────────────┤');
  console.log(`│  Total Comparisons: ${String(metrics.overall.totalComparisons).padStart(6)}                               │`);
  console.log(`│  Total Matches:     ${String(metrics.overall.totalMatches).padStart(6)}                               │`);
  console.log(`│  Total Diffs:       ${String(metrics.overall.totalDiffs).padStart(6)}                               │`);
  console.log('├─────────────────────────────────────────────────────────────┤');
  console.log(`│  Strict Accuracy:   ${formatPercent(metrics.overall.strictAccuracy).padStart(8)}   (exact match)            │`);
  console.log(`│  Practical Accuracy:${formatPercent(metrics.overall.practicalAccuracy).padStart(8)}   (excl. acceptable)       │`);
  console.log('├─────────────────────────────────────────────────────────────┤');
  console.log(`│  Acceptable Diffs:  ${String(metrics.overall.acceptable).padStart(6)}                               │`);
  console.log(`│  Wrong Diffs:       ${String(metrics.overall.wrong).padStart(6)}                               │`);
  console.log(`│  Wrong Rate:        ${formatPercent(metrics.overall.wrongRate).padStart(8)}   (of all diffs)           │`);
  console.log('└─────────────────────────────────────────────────────────────┘');

  // Per-Category Breakdown
  console.log('\n┌─────────────────────────────────────────────────────────────┐');
  console.log('│  ACCURACY BY CATEGORY                                       │');
  console.log('├──────────────┬───────────┬───────────┬───────────┬──────────┤');
  console.log('│  Category    │   Total   │  Strict   │ Practical │   Wrong  │');
  console.log('├──────────────┼───────────┼───────────┼───────────┼──────────┤');

  const categories = [
    { name: 'Banner', data: metrics.byCategory.banner },
    { name: 'Crosstab', data: metrics.byCategory.crosstab },
    { name: 'Structure', data: metrics.byCategory.structure },
    { name: 'Data', data: metrics.byCategory.data },
  ];

  for (const cat of categories) {
    const name = cat.name.padEnd(12);
    const total = String(cat.data.total).padStart(7);
    const strict = formatPercent(cat.data.strictAccuracy).padStart(9);
    const practical = formatPercent(cat.data.practicalAccuracy).padStart(9);
    const wrong = String(cat.data.wrong).padStart(6);
    console.log(`│  ${name}│ ${total}   │ ${strict} │ ${practical} │ ${wrong}   │`);
  }

  console.log('└──────────────┴───────────┴───────────┴───────────┴──────────┘');

  // Attribution Breakdown
  if (Object.keys(metrics.attribution).length > 0) {
    console.log('\n┌─────────────────────────────────────────────────────────────┐');
    console.log('│  ERROR ATTRIBUTION                                          │');
    console.log('├─────────────────────────────────────────────────────────────┤');

    const sortedAttribution = Object.entries(metrics.attribution)
      .sort((a, b) => b[1] - a[1]);

    for (const [source, count] of sortedAttribution) {
      console.log(`│  ${source.padEnd(25)} ${String(count).padStart(5)} issue(s)                │`);
    }

    console.log('└─────────────────────────────────────────────────────────────┘');
  }

  // Top Issues
  if (metrics.topIssues.length > 0) {
    console.log('\n┌─────────────────────────────────────────────────────────────┐');
    console.log('│  TOP ISSUES                                                 │');
    console.log('├─────────────────────────────────────────────────────────────┤');

    for (const issue of metrics.topIssues.slice(0, 5)) {
      const desc = `${issue.category}/${issue.diffType}`.padEnd(30);
      const count = String(issue.count).padStart(3);
      console.log(`│  ${desc} ${count}x  (e.g., ${issue.example.slice(0, 18)})  │`);
    }

    console.log('└─────────────────────────────────────────────────────────────┘');
  }

  console.log('\n════════════════════════════════════════════════════════════════\n');
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: npx tsx scripts/calculate-metrics.ts <path-to-comparison-report.json>');
    console.error('');
    console.error('Example:');
    console.error('  npx tsx scripts/calculate-metrics.ts outputs/.../comparison-report.json');
    process.exit(1);
  }

  const reportPath = args[0];

  // Load report
  let report: ComparisonReport;
  try {
    const content = await fs.readFile(reportPath, 'utf-8');
    report = JSON.parse(content);
  } catch (err) {
    console.error(`Error reading report: ${reportPath}`);
    console.error(err);
    process.exit(1);
  }

  // Calculate metrics
  const metrics = calculateMetrics(report);

  // Display metrics
  displayMetrics(metrics);

  // Save metrics JSON alongside report
  const metricsPath = reportPath.replace('comparison-report.json', 'metrics.json');
  await fs.writeFile(metricsPath, JSON.stringify(metrics, null, 2), 'utf-8');
  console.log(`✅ Metrics saved: ${metricsPath}`);
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
