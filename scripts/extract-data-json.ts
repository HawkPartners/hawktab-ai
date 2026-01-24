/**
 * Extract Streamlined Data JSON
 *
 * Extracts only the calculated data values from tables.json,
 * stripping metadata and table-level fields.
 *
 * Usage:
 *   npx tsx scripts/extract-data-json.ts <path-to-tables.json> [output-path]
 *
 * If output-path is not provided, outputs to same directory as input with name 'data-streamlined.json'
 *
 * Input structure (tables.json):
 * {
 *   "metadata": { ... },
 *   "tables": {
 *     "s1": {
 *       "title": "...",
 *       "tableType": "frequency",
 *       "isDerived": false,
 *       "data": {
 *         "Total": {
 *           "stat_letter": "T",
 *           "S1_row_1": { "label": "...", "n": 180, "count": 60, "pct": 33, ... }
 *         }
 *       }
 *     }
 *   }
 * }
 *
 * Output structure (data-streamlined.json):
 * {
 *   "s1": {
 *     "Total": {
 *       "S1_row_1": { "n": 180, "count": 60, "pct": 33, "sig_higher_than": [], "sig_vs_total": null }
 *     }
 *   }
 * }
 */

import fs from 'fs/promises';
import path from 'path';

// Fields to keep for each row (the actual data)
const DATA_FIELDS = ['n', 'count', 'pct', 'mean', 'median', 'sd', 'sig_higher_than', 'sig_vs_total'];

// Fields to skip at the cut level
const CUT_META_FIELDS = ['stat_letter'];

interface RowData {
  n?: number;
  count?: number;
  pct?: number;
  mean?: number;
  median?: number;
  sd?: number;
  sig_higher_than?: string[] | string;
  sig_vs_total?: string | null | Record<string, unknown>;
}

interface StreamlinedData {
  [tableId: string]: {
    [cutName: string]: {
      [rowKey: string]: RowData;
    };
  };
}

interface TablesJson {
  metadata?: Record<string, unknown>;
  tables: {
    [tableId: string]: {
      title?: string;
      tableType?: string;
      isDerived?: boolean;
      data: {
        [cutName: string]: {
          stat_letter?: string;
          [rowKey: string]: unknown;
        };
      };
    };
  };
}

function extractStreamlinedData(tablesJson: TablesJson): StreamlinedData {
  const result: StreamlinedData = {};

  for (const [tableId, table] of Object.entries(tablesJson.tables)) {
    if (!table.data) continue;

    result[tableId] = {};

    for (const [cutName, cutData] of Object.entries(table.data)) {
      result[tableId][cutName] = {};

      for (const [key, value] of Object.entries(cutData)) {
        // Skip cut-level metadata
        if (CUT_META_FIELDS.includes(key)) continue;

        // This should be a row
        if (typeof value === 'object' && value !== null) {
          const rowData: RowData = {};

          // Extract only the data fields we care about
          for (const field of DATA_FIELDS) {
            if (field in value) {
              const fieldValue = (value as Record<string, unknown>)[field];

              // Normalize sig_higher_than to array
              if (field === 'sig_higher_than') {
                if (Array.isArray(fieldValue)) {
                  rowData.sig_higher_than = fieldValue;
                } else if (typeof fieldValue === 'string' && fieldValue) {
                  rowData.sig_higher_than = fieldValue.split('');
                } else {
                  rowData.sig_higher_than = [];
                }
              }
              // Normalize sig_vs_total
              else if (field === 'sig_vs_total') {
                if (fieldValue === null || fieldValue === undefined) {
                  rowData.sig_vs_total = null;
                } else if (typeof fieldValue === 'object' && Object.keys(fieldValue as object).length === 0) {
                  rowData.sig_vs_total = null;
                } else if (typeof fieldValue === 'string') {
                  rowData.sig_vs_total = fieldValue;
                } else {
                  rowData.sig_vs_total = null;
                }
              }
              // Keep numeric fields as-is
              else {
                (rowData as Record<string, unknown>)[field] = fieldValue as number;
              }
            }
          }

          // Only add if we have actual data
          if (Object.keys(rowData).length > 0) {
            result[tableId][cutName][key] = rowData;
          }
        }
      }
    }
  }

  return result;
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: npx tsx scripts/extract-data-json.ts <path-to-tables.json> [output-path]');
    console.error('');
    console.error('Examples:');
    console.error('  npx tsx scripts/extract-data-json.ts outputs/leqvio.../results/tables.json');
    console.error('  npx tsx scripts/extract-data-json.ts outputs/leqvio.../results/tables.json ./data-expected.json');
    process.exit(1);
  }

  const inputPath = args[0];
  const outputPath = args[1] || path.join(path.dirname(inputPath), 'data-streamlined.json');

  console.log(`Reading: ${inputPath}`);

  // Read input
  const inputContent = await fs.readFile(inputPath, 'utf-8');
  const tablesJson: TablesJson = JSON.parse(inputContent);

  // Validate structure
  if (!tablesJson.tables) {
    console.error('Error: Input file does not have a "tables" property');
    process.exit(1);
  }

  // Extract streamlined data
  const streamlined = extractStreamlinedData(tablesJson);

  // Count tables and rows
  const tableCount = Object.keys(streamlined).length;
  let totalRows = 0;
  for (const table of Object.values(streamlined)) {
    for (const cut of Object.values(table)) {
      totalRows += Object.keys(cut).length;
    }
  }

  // Write output
  await fs.writeFile(outputPath, JSON.stringify(streamlined, null, 2), 'utf-8');

  console.log(`Written: ${outputPath}`);
  console.log(`Tables: ${tableCount}`);
  console.log(`Total data rows: ${totalRows}`);
}

main().catch((err) => {
  console.error('Error:', err);
  process.exit(1);
});
