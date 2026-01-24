/**
 * Compare Pipeline Output to Golden Datasets
 *
 * Compares actual pipeline output against golden datasets and generates
 * a comparison report for human annotation.
 *
 * Usage:
 *   npx tsx scripts/compare-to-golden.ts <pipeline-output-folder>
 *
 * Example:
 *   npx tsx scripts/compare-to-golden.ts outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-01-09T16-54-54-155Z
 *
 * Golden datasets expected at:
 *   data/<dataset>/golden-datasets/banner-expected.json
 *   data/<dataset>/golden-datasets/crosstab-expected.json
 *   data/<dataset>/golden-datasets/verification-expected.json
 *   data/<dataset>/golden-datasets/data-expected.json
 *
 * Output:
 *   <pipeline-output-folder>/comparison-report.json
 */

import fs from 'fs/promises';
import path from 'path';

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
  diffType: 'missing_in_actual' | 'missing_in_expected' | 'field_mismatch' | 'value_mismatch' | 'array_mismatch';
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
    status: 'pending_review' | 'in_progress' | 'reviewed';
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

// =============================================================================
// Utility Functions
// =============================================================================

function generateDiffId(index: number): string {
  return `diff_${String(index + 1).padStart(3, '0')}`;
}

/**
 * Deep compare two values, returning true if equal
 */
function deepEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true;
  if (a === null || b === null) return a === b;
  if (typeof a !== typeof b) return false;

  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) return false;
    return a.every((val, i) => deepEqual(val, b[i]));
  }

  if (typeof a === 'object' && typeof b === 'object') {
    const aKeys = Object.keys(a as object);
    const bKeys = Object.keys(b as object);
    if (aKeys.length !== bKeys.length) return false;
    return aKeys.every(key =>
      deepEqual((a as Record<string, unknown>)[key], (b as Record<string, unknown>)[key])
    );
  }

  return false;
}

/**
 * Get a concise representation of a value for display
 */
function summarizeValue(value: unknown, maxLen = 100): string {
  const str = JSON.stringify(value);
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 3) + '...';
}

// =============================================================================
// Banner Comparison
// =============================================================================

interface BannerColumn {
  name: string;
  [key: string]: unknown;
}

interface BannerGroup {
  groupName: string;
  columns: BannerColumn[];
}

interface BannerData {
  bannerCuts: BannerGroup[];
  notes?: unknown[];
  processingMetadata?: unknown;
}

function compareBanner(expected: BannerData, actual: BannerData, diffs: DiffEntry[], startIndex: number): ComparisonSummary {
  let total = 0;
  let matches = 0;
  let diffIndex = startIndex;

  // Compare banner cuts/groups
  const expectedGroups = expected.bannerCuts || [];
  const actualGroups = actual.bannerCuts || [];

  // Build maps for easier lookup
  const expectedGroupMap = new Map<string, BannerGroup>();
  const actualGroupMap = new Map<string, BannerGroup>();

  for (const group of expectedGroups) {
    expectedGroupMap.set(group.groupName, group);
  }
  for (const group of actualGroups) {
    actualGroupMap.set(group.groupName, group);
  }

  // Check for missing groups
  for (const [groupName, expectedGroup] of expectedGroupMap) {
    const actualGroup = actualGroupMap.get(groupName);

    if (!actualGroup) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'banner',
        groupName,
        diffType: 'missing_in_actual',
        expected: expectedGroup,
        actual: null,
        annotation: null,
        attribution: null,
        notes: '',
      });
      continue;
    }

    // Compare columns within the group
    const expectedColMap = new Map<string, BannerColumn>();
    const actualColMap = new Map<string, BannerColumn>();

    for (const col of expectedGroup.columns) {
      expectedColMap.set(col.name, col);
    }
    for (const col of actualGroup.columns) {
      actualColMap.set(col.name, col);
    }

    // Check each expected column
    for (const [colName, expectedCol] of expectedColMap) {
      total++;
      const actualCol = actualColMap.get(colName);

      if (!actualCol) {
        diffs.push({
          id: generateDiffId(diffIndex++),
          category: 'banner',
          groupName,
          columnName: colName,
          diffType: 'missing_in_actual',
          expected: expectedCol,
          actual: null,
          annotation: null,
          attribution: null,
          notes: '',
        });
        continue;
      }

      // Compare key fields
      // - name: column name from banner plan (shouldn't be made up)
      // - original: original expression from banner plan
      // - adjusted: adjusted/validated expression
      // - statLetter: statistical letter assignment
      // - humanInLoopRequired: boolean - tracks if model lacks confidence
      // - requiresInference: boolean - tracks if model is making assumptions
      const keyFields = ['name', 'original', 'adjusted', 'statLetter', 'humanInLoopRequired', 'requiresInference'];
      let hasFieldDiff = false;

      for (const field of keyFields) {
        if (field in expectedCol || field in actualCol) {
          const expVal = (expectedCol as Record<string, unknown>)[field];
          const actVal = (actualCol as Record<string, unknown>)[field];
          if (!deepEqual(expVal, actVal)) {
            hasFieldDiff = true;
            diffs.push({
              id: generateDiffId(diffIndex++),
              category: 'banner',
              groupName,
              columnName: colName,
              diffType: 'field_mismatch',
              field,
              expected: expVal,
              actual: actVal,
              annotation: null,
              attribution: null,
              notes: '',
            });
          }
        }
      }

      if (!hasFieldDiff) {
        matches++;
      }
    }

    // Check for extra columns in actual
    for (const [colName] of actualColMap) {
      if (!expectedColMap.has(colName)) {
        total++;
        diffs.push({
          id: generateDiffId(diffIndex++),
          category: 'banner',
          groupName,
          columnName: colName,
          diffType: 'missing_in_expected',
          expected: null,
          actual: actualColMap.get(colName),
          annotation: null,
          attribution: null,
          notes: '',
        });
      }
    }
  }

  // Check for extra groups in actual
  for (const [groupName] of actualGroupMap) {
    if (!expectedGroupMap.has(groupName)) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'banner',
        groupName,
        diffType: 'missing_in_expected',
        expected: null,
        actual: actualGroupMap.get(groupName),
        annotation: null,
        attribution: null,
        notes: '',
      });
    }
  }

  return { total, matches, diffs: total - matches };
}

// =============================================================================
// Crosstab Comparison
// =============================================================================

interface CrosstabColumn {
  name: string;
  adjusted: string;
  confidence?: number;
  reason?: string;
}

interface CrosstabGroup {
  groupName: string;
  columns: CrosstabColumn[];
}

interface CrosstabData {
  bannerCuts: CrosstabGroup[];
}

function compareCrosstab(expected: CrosstabData, actual: CrosstabData, diffs: DiffEntry[], startIndex: number): ComparisonSummary {
  let total = 0;
  let matches = 0;
  let diffIndex = startIndex;

  const expectedGroups = expected.bannerCuts || [];
  const actualGroups = actual.bannerCuts || [];

  const expectedGroupMap = new Map<string, CrosstabGroup>();
  const actualGroupMap = new Map<string, CrosstabGroup>();

  for (const group of expectedGroups) {
    expectedGroupMap.set(group.groupName, group);
  }
  for (const group of actualGroups) {
    actualGroupMap.set(group.groupName, group);
  }

  for (const [groupName, expectedGroup] of expectedGroupMap) {
    const actualGroup = actualGroupMap.get(groupName);

    if (!actualGroup) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'crosstab',
        groupName,
        diffType: 'missing_in_actual',
        expected: expectedGroup,
        actual: null,
        annotation: null,
        attribution: null,
        notes: '',
      });
      continue;
    }

    const expectedColMap = new Map<string, CrosstabColumn>();
    const actualColMap = new Map<string, CrosstabColumn>();

    for (const col of expectedGroup.columns) {
      expectedColMap.set(col.name, col);
    }
    for (const col of actualGroup.columns) {
      actualColMap.set(col.name, col);
    }

    for (const [colName, expectedCol] of expectedColMap) {
      total++;
      const actualCol = actualColMap.get(colName);

      if (!actualCol) {
        diffs.push({
          id: generateDiffId(diffIndex++),
          category: 'crosstab',
          groupName,
          columnName: colName,
          diffType: 'missing_in_actual',
          expected: expectedCol,
          actual: null,
          annotation: null,
          attribution: null,
          notes: '',
        });
        continue;
      }

      // Compare key fields
      // - name: column name (should match banner plan)
      // - adjusted: R syntax expression (the core output)
      const keyFields = ['name', 'adjusted'];
      let hasFieldDiff = false;

      for (const field of keyFields) {
        if (field in expectedCol || field in actualCol) {
          const expVal = (expectedCol as unknown as Record<string, unknown>)[field];
          const actVal = (actualCol as unknown as Record<string, unknown>)[field];
          if (!deepEqual(expVal, actVal)) {
            hasFieldDiff = true;
            diffs.push({
              id: generateDiffId(diffIndex++),
              category: 'crosstab',
              groupName,
              columnName: colName,
              diffType: 'field_mismatch',
              field,
              expected: expVal,
              actual: actVal,
              annotation: null,
              attribution: null,
              notes: '',
            });
          }
        }
      }

      if (!hasFieldDiff) {
        matches++;
      }
    }

    // Check for extra columns
    for (const [colName] of actualColMap) {
      if (!expectedColMap.has(colName)) {
        total++;
        diffs.push({
          id: generateDiffId(diffIndex++),
          category: 'crosstab',
          groupName,
          columnName: colName,
          diffType: 'missing_in_expected',
          expected: null,
          actual: actualColMap.get(colName),
          annotation: null,
          attribution: null,
          notes: '',
        });
      }
    }
  }

  // Check for extra groups
  for (const [groupName] of actualGroupMap) {
    if (!expectedGroupMap.has(groupName)) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'crosstab',
        groupName,
        diffType: 'missing_in_expected',
        expected: null,
        actual: actualGroupMap.get(groupName),
        annotation: null,
        attribution: null,
        notes: '',
      });
    }
  }

  return { total, matches, diffs: total - matches };
}

// =============================================================================
// Structure (Verification) Comparison
// =============================================================================

interface TableRow {
  variable: string;
  label: string;
  filterValue: string;
  isNet?: boolean;
  netComponents?: string[];
  indent?: number;
}

interface TableDefinition {
  tableId: string;
  questionId?: string;
  title: string;
  tableType: string;
  rows: TableRow[];
  sourceTableId?: string;
  isDerived?: boolean;
  exclude?: boolean;
  excludeReason?: string;
}

interface VerificationData {
  tables: TableDefinition[];
  allChanges?: unknown[];
}

function compareStructure(expected: VerificationData, actual: VerificationData, diffs: DiffEntry[], startIndex: number): ComparisonSummary {
  let total = 0;
  let matches = 0;
  let diffIndex = startIndex;

  const expectedTables = expected.tables || [];
  const actualTables = actual.tables || [];

  const expectedMap = new Map<string, TableDefinition>();
  const actualMap = new Map<string, TableDefinition>();

  for (const table of expectedTables) {
    expectedMap.set(table.tableId, table);
  }
  for (const table of actualTables) {
    actualMap.set(table.tableId, table);
  }

  for (const [tableId, expectedTable] of expectedMap) {
    const actualTable = actualMap.get(tableId);

    if (!actualTable) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'structure',
        tableId,
        diffType: 'missing_in_actual',
        expected: { tableId, title: expectedTable.title },
        actual: null,
        annotation: null,
        attribution: null,
        notes: '',
      });
      continue;
    }

    // Compare table-level fields
    const tableFields = ['tableType', 'title', 'isDerived', 'exclude'];
    for (const field of tableFields) {
      total++;
      const expVal = (expectedTable as unknown as Record<string, unknown>)[field];
      const actVal = (actualTable as unknown as Record<string, unknown>)[field];

      if (!deepEqual(expVal, actVal)) {
        diffs.push({
          id: generateDiffId(diffIndex++),
          category: 'structure',
          tableId,
          diffType: 'field_mismatch',
          path: field,
          field,
          expected: expVal,
          actual: actVal,
          annotation: null,
          attribution: null,
          notes: '',
        });
      } else {
        matches++;
      }
    }

    // Compare rows
    const expectedRows = expectedTable.rows || [];
    const actualRows = actualTable.rows || [];

    // Row count
    total++;
    if (expectedRows.length !== actualRows.length) {
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'structure',
        tableId,
        diffType: 'field_mismatch',
        path: 'rows.length',
        field: 'rowCount',
        expected: expectedRows.length,
        actual: actualRows.length,
        annotation: null,
        attribution: null,
        notes: '',
      });
    } else {
      matches++;
    }

    // Compare individual rows by index (order matters)
    const minRows = Math.min(expectedRows.length, actualRows.length);
    for (let i = 0; i < minRows; i++) {
      const expRow = expectedRows[i];
      const actRow = actualRows[i];

      // Key row fields
      const rowFields = ['variable', 'label', 'filterValue', 'isNet'];
      for (const field of rowFields) {
        total++;
        const expVal = (expRow as unknown as Record<string, unknown>)[field];
        const actVal = (actRow as unknown as Record<string, unknown>)[field];

        if (!deepEqual(expVal, actVal)) {
          diffs.push({
            id: generateDiffId(diffIndex++),
            category: 'structure',
            tableId,
            diffType: 'field_mismatch',
            path: `rows[${i}].${field}`,
            field,
            rowKey: expRow.variable,
            expected: expVal,
            actual: actVal,
            annotation: null,
            attribution: null,
            notes: '',
          });
        } else {
          matches++;
        }
      }
    }
  }

  // Check for extra tables
  for (const [tableId, actualTable] of actualMap) {
    if (!expectedMap.has(tableId)) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'structure',
        tableId,
        diffType: 'missing_in_expected',
        expected: null,
        actual: { tableId, title: actualTable.title },
        annotation: null,
        attribution: null,
        notes: '',
      });
    }
  }

  return { total, matches, diffs: total - matches };
}

// =============================================================================
// Data Comparison
// =============================================================================

interface StreamlinedRowData {
  n?: number;
  count?: number;
  pct?: number;
  mean?: number;
  median?: number;
  sd?: number;
  sig_higher_than?: string[];
  sig_vs_total?: string | null;
}

interface StreamlinedData {
  [tableId: string]: {
    [cutName: string]: {
      [rowKey: string]: StreamlinedRowData;
    };
  };
}

function compareData(expected: StreamlinedData, actual: StreamlinedData, diffs: DiffEntry[], startIndex: number): ComparisonSummary {
  let total = 0;
  let matches = 0;
  let diffIndex = startIndex;

  // Get all table IDs
  const allTableIds = new Set([...Object.keys(expected), ...Object.keys(actual)]);

  for (const tableId of allTableIds) {
    const expectedTable = expected[tableId] || {};
    const actualTable = actual[tableId] || {};

    if (!expected[tableId]) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'data',
        tableId,
        diffType: 'missing_in_expected',
        expected: null,
        actual: `Table with ${Object.keys(actualTable).length} cuts`,
        annotation: null,
        attribution: null,
        notes: '',
      });
      continue;
    }

    if (!actual[tableId]) {
      total++;
      diffs.push({
        id: generateDiffId(diffIndex++),
        category: 'data',
        tableId,
        diffType: 'missing_in_actual',
        expected: `Table with ${Object.keys(expectedTable).length} cuts`,
        actual: null,
        annotation: null,
        attribution: null,
        notes: '',
      });
      continue;
    }

    // Compare cuts within table
    const allCuts = new Set([...Object.keys(expectedTable), ...Object.keys(actualTable)]);

    for (const cut of allCuts) {
      const expectedCut = expectedTable[cut] || {};
      const actualCut = actualTable[cut] || {};

      if (!expectedTable[cut]) {
        total++;
        diffs.push({
          id: generateDiffId(diffIndex++),
          category: 'data',
          tableId,
          cut,
          diffType: 'missing_in_expected',
          expected: null,
          actual: `Cut with ${Object.keys(actualCut).length} rows`,
          annotation: null,
          attribution: null,
          notes: '',
        });
        continue;
      }

      if (!actualTable[cut]) {
        total++;
        diffs.push({
          id: generateDiffId(diffIndex++),
          category: 'data',
          tableId,
          cut,
          diffType: 'missing_in_actual',
          expected: `Cut with ${Object.keys(expectedCut).length} rows`,
          actual: null,
          annotation: null,
          attribution: null,
          notes: '',
        });
        continue;
      }

      // Compare rows within cut
      const allRows = new Set([...Object.keys(expectedCut), ...Object.keys(actualCut)]);

      for (const rowKey of allRows) {
        const expectedRow = expectedCut[rowKey];
        const actualRow = actualCut[rowKey];

        if (!expectedRow) {
          total++;
          diffs.push({
            id: generateDiffId(diffIndex++),
            category: 'data',
            tableId,
            cut,
            rowKey,
            diffType: 'missing_in_expected',
            expected: null,
            actual: actualRow,
            annotation: null,
            attribution: null,
            notes: '',
          });
          continue;
        }

        if (!actualRow) {
          total++;
          diffs.push({
            id: generateDiffId(diffIndex++),
            category: 'data',
            tableId,
            cut,
            rowKey,
            diffType: 'missing_in_actual',
            expected: expectedRow,
            actual: null,
            annotation: null,
            attribution: null,
            notes: '',
          });
          continue;
        }

        // Compare data fields
        const dataFields = ['n', 'count', 'pct', 'mean', 'median', 'sd', 'sig_higher_than', 'sig_vs_total'];
        let rowMatches = true;

        for (const field of dataFields) {
          if (field in expectedRow || field in actualRow) {
            total++;
            const expVal = (expectedRow as Record<string, unknown>)[field];
            const actVal = (actualRow as Record<string, unknown>)[field];

            if (!deepEqual(expVal, actVal)) {
              rowMatches = false;
              diffs.push({
                id: generateDiffId(diffIndex++),
                category: 'data',
                tableId,
                cut,
                rowKey,
                diffType: 'value_mismatch',
                field,
                expected: expVal,
                actual: actVal,
                annotation: null,
                attribution: null,
                notes: '',
              });
            } else {
              matches++;
            }
          }
        }
      }
    }
  }

  return { total, matches, diffs: total - matches };
}

// =============================================================================
// Main Comparison Function
// =============================================================================

async function loadJsonFile(filePath: string): Promise<unknown | null> {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    return JSON.parse(content);
  } catch {
    return null;
  }
}

function extractDatasetName(pipelineFolder: string): string {
  // Extract dataset name from path like "outputs/leqvio-monotherapy-demand-NOV217/pipeline-..."
  const parts = pipelineFolder.split(path.sep);
  for (let i = parts.length - 1; i >= 0; i--) {
    if (parts[i].startsWith('pipeline-')) {
      return parts[i - 1] || 'unknown';
    }
  }
  return 'unknown';
}

function extractRunTimestamp(pipelineFolder: string): string {
  // Extract timestamp from "pipeline-2026-01-09T16-54-54-155Z"
  const folderName = path.basename(pipelineFolder);
  const match = folderName.match(/pipeline-(.+)/);
  if (match) {
    // Convert back to ISO format
    return match[1].replace(/-(\d{2})-(\d{2})-(\d{3})Z$/, ':$1:$2.$3Z');
  }
  return new Date().toISOString();
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: npx tsx scripts/compare-to-golden.ts <pipeline-output-folder>');
    console.error('');
    console.error('Example:');
    console.error('  npx tsx scripts/compare-to-golden.ts outputs/leqvio-monotherapy-demand-NOV217/pipeline-2026-01-09T16-54-54-155Z');
    process.exit(1);
  }

  const pipelineFolder = args[0];
  const datasetName = extractDatasetName(pipelineFolder);

  console.log(`\n🔍 Comparing pipeline output to golden datasets`);
  console.log(`   Dataset: ${datasetName}`);
  console.log(`   Pipeline: ${pipelineFolder}\n`);

  // Locate golden datasets
  const goldenDir = path.join('data', datasetName, 'golden-datasets');

  // Locate actual outputs
  const bannerActualPath = path.join(pipelineFolder, 'banner', 'banner-output-raw.json');
  const crosstabActualPath = path.join(pipelineFolder, 'crosstab', 'crosstab-output-raw.json');
  const verificationActualPath = path.join(pipelineFolder, 'verification', 'verification-output-raw.json');
  const dataActualPath = path.join(pipelineFolder, 'results', 'data-streamlined.json');

  // Load all files
  const bannerExpected = await loadJsonFile(path.join(goldenDir, 'banner-expected.json')) as BannerData | null;
  const crosstabExpected = await loadJsonFile(path.join(goldenDir, 'crosstab-expected.json')) as CrosstabData | null;
  const verificationExpected = await loadJsonFile(path.join(goldenDir, 'verification-expected.json')) as VerificationData | null;
  const dataExpected = await loadJsonFile(path.join(goldenDir, 'data-expected.json')) as StreamlinedData | null;

  const bannerActual = await loadJsonFile(bannerActualPath) as BannerData | null;
  const crosstabActual = await loadJsonFile(crosstabActualPath) as CrosstabData | null;
  const verificationActual = await loadJsonFile(verificationActualPath) as VerificationData | null;
  const dataActual = await loadJsonFile(dataActualPath) as StreamlinedData | null;

  // Initialize report
  const differences: DiffEntry[] = [];
  const report: ComparisonReport = {
    metadata: {
      dataset: datasetName,
      runTimestamp: extractRunTimestamp(pipelineFolder),
      pipelineFolder,
      generatedAt: new Date().toISOString(),
      status: 'pending_review',
    },
    summary: {
      banner: { total: 0, matches: 0, diffs: 0 },
      crosstab: { total: 0, matches: 0, diffs: 0 },
      structure: { total: 0, matches: 0, diffs: 0 },
      data: { total: 0, matches: 0, diffs: 0 },
    },
    overall: {
      totalDiffs: 0,
      reviewed: 0,
      acceptable: 0,
      wrong: 0,
    },
    differences: [],
  };

  // Compare Banner
  if (bannerExpected && bannerActual) {
    console.log('📋 Comparing banner...');
    report.summary.banner = compareBanner(bannerExpected, bannerActual, differences, differences.length);
    console.log(`   Total: ${report.summary.banner.total}, Matches: ${report.summary.banner.matches}, Diffs: ${report.summary.banner.diffs}`);
  } else {
    console.log('⚠️  Banner comparison skipped (missing files)');
    if (!bannerExpected) console.log(`   Missing: ${path.join(goldenDir, 'banner-expected.json')}`);
    if (!bannerActual) console.log(`   Missing: ${bannerActualPath}`);
  }

  // Compare Crosstab
  if (crosstabExpected && crosstabActual) {
    console.log('📋 Comparing crosstab...');
    report.summary.crosstab = compareCrosstab(crosstabExpected, crosstabActual, differences, differences.length);
    console.log(`   Total: ${report.summary.crosstab.total}, Matches: ${report.summary.crosstab.matches}, Diffs: ${report.summary.crosstab.diffs}`);
  } else {
    console.log('⚠️  Crosstab comparison skipped (missing files)');
    if (!crosstabExpected) console.log(`   Missing: ${path.join(goldenDir, 'crosstab-expected.json')}`);
    if (!crosstabActual) console.log(`   Missing: ${crosstabActualPath}`);
  }

  // Compare Structure (Verification)
  if (verificationExpected && verificationActual) {
    console.log('📋 Comparing structure (verification)...');
    report.summary.structure = compareStructure(verificationExpected, verificationActual, differences, differences.length);
    console.log(`   Total: ${report.summary.structure.total}, Matches: ${report.summary.structure.matches}, Diffs: ${report.summary.structure.diffs}`);
  } else {
    console.log('⚠️  Structure comparison skipped (missing files)');
    if (!verificationExpected) console.log(`   Missing: ${path.join(goldenDir, 'verification-expected.json')}`);
    if (!verificationActual) console.log(`   Missing: ${verificationActualPath}`);
  }

  // Compare Data
  if (dataExpected && dataActual) {
    console.log('📋 Comparing data...');
    report.summary.data = compareData(dataExpected, dataActual, differences, differences.length);
    console.log(`   Total: ${report.summary.data.total}, Matches: ${report.summary.data.matches}, Diffs: ${report.summary.data.diffs}`);
  } else {
    console.log('⚠️  Data comparison skipped (missing files)');
    if (!dataExpected) console.log(`   Missing: ${path.join(goldenDir, 'data-expected.json')}`);
    if (!dataActual) console.log(`   Missing: ${dataActualPath}`);
  }

  // Finalize report
  report.differences = differences;
  report.overall.totalDiffs = differences.length;

  // Write report
  const reportPath = path.join(pipelineFolder, 'comparison-report.json');
  await fs.writeFile(reportPath, JSON.stringify(report, null, 2), 'utf-8');

  // Summary
  console.log('\n────────────────────────────────────────');
  console.log('📊 COMPARISON SUMMARY');
  console.log('────────────────────────────────────────');
  console.log(`   Banner:     ${report.summary.banner.diffs} diffs / ${report.summary.banner.total} total`);
  console.log(`   Crosstab:   ${report.summary.crosstab.diffs} diffs / ${report.summary.crosstab.total} total`);
  console.log(`   Structure:  ${report.summary.structure.diffs} diffs / ${report.summary.structure.total} total`);
  console.log(`   Data:       ${report.summary.data.diffs} diffs / ${report.summary.data.total} total`);
  console.log('────────────────────────────────────────');
  console.log(`   TOTAL DIFFS: ${report.overall.totalDiffs}`);
  console.log('────────────────────────────────────────');
  console.log(`\n✅ Report saved: ${reportPath}`);

  if (report.overall.totalDiffs > 0) {
    console.log(`\n📝 Next step: Review ${reportPath} and annotate differences`);
  } else {
    console.log(`\n🎉 Perfect match! No differences found.`);
  }
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
