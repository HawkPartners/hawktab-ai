/**
 * spss-utils.ts
 *
 * Shared utilities for SPSS parsers (Variable Info and Values Only).
 */

/**
 * Parse a CSV line handling quoted fields.
 */
export function parseCSVLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i++) {
    const char = line[i];

    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += char;
    }
  }

  result.push(current);
  return result;
}

/**
 * Detect structural suffixes that indicate a sub-variable.
 *
 * Patterns (order matters — check most specific first):
 * - r\d+c\d+   → grid cell (S13r1c1)
 * - r\d+oe     → open-ended row (S2r98oe)
 * - r\d+       → row item (S8r1)
 * - c\d+       → column item (standalone column index)
 *
 * NOT sub-variables:
 * - h-prefixed  → hidden/computed (hS4, hAge)
 * - d-prefixed  → derived (dTier)
 * - NDP_        → calculated
 * - system vars → record, uuid, date, status
 */
export function hasStructuralSuffix(varName: string): boolean {
  // System/admin variables are never sub-variables
  const lower = varName.toLowerCase();
  if (['record', 'uuid', 'date', 'status'].includes(lower)) return false;

  // Check for structural suffix patterns
  return /r\d+c\d+$/i.test(varName) ||   // r1c1 grid pattern
         /r\d+oe$/i.test(varName) ||      // r6oe open-ended pattern
         /r\d+$/i.test(varName) ||         // r1 row pattern
         /c\d+$/i.test(varName);           // c1 column-only pattern
}

/**
 * Parse a Variable Values section from SPSS CSV.
 *
 * Format:
 *   Value,,Label
 *   status,1,Terminated
 *   ,2,Overquota
 *   S1,1,Yes
 *   ,2,No
 *
 * Continuation rows (blank first column) belong to the previous variable.
 * Returns a Map of variable name → array of {value, label} pairs.
 */
export function parseVariableValuesSection(
  lines: string[],
  startIndex: number
): Map<string, { value: string; label: string }[]> {
  const valueMap = new Map<string, { value: string; label: string }[]>();

  // Skip header rows (Value,,Label)
  let dataStart = startIndex + 1;
  while (dataStart < lines.length) {
    const line = lines[dataStart].trim();
    if (line.startsWith('Value,') || line.startsWith('"Value"')) {
      dataStart++;
      break;
    }
    dataStart++;
    if (dataStart - startIndex > 3) {
      // No header found, assume data starts right after
      dataStart = startIndex + 1;
      break;
    }
  }

  let currentVariable = '';

  for (let i = dataStart; i < lines.length; i++) {
    const line = lines[i];
    if (!line.trim()) continue;

    const fields = parseCSVLine(line);
    const firstField = fields[0]?.trim() || '';
    const valueField = fields[1]?.trim() || '';
    const labelField = fields[2]?.trim() || '';

    if (!valueField && !labelField) continue;

    if (firstField) {
      // New variable
      currentVariable = firstField;
      if (!valueMap.has(currentVariable)) {
        valueMap.set(currentVariable, []);
      }
    }

    if (currentVariable && valueField) {
      const labels = valueMap.get(currentVariable) || [];
      labels.push({ value: valueField, label: labelField });
      valueMap.set(currentVariable, labels);
    }
  }

  return valueMap;
}
