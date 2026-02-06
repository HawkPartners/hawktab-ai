/**
 * SPSSValuesOnlyParser.ts
 *
 * Parses SPSS "Values Only" CSV format → RawDataMapVariable[].
 *
 * This format contains ONLY the Variable Values section — no Variable Information table.
 * It only includes variables that have coded value labels (e.g., 1=Yes, 2=No).
 * Open-ended text variables, numeric variables without labels, and metadata
 * columns (record, uuid, date) are absent.
 *
 * The .sav file supplement (adding missing columns) is handled separately
 * by ValidationRunner Stage 4, not here.
 */

import type { RawDataMapVariable } from '../processors/DataMapProcessor';
import { hasStructuralSuffix, parseVariableValuesSection } from './spss-utils';

/**
 * Find the line index where a section starts.
 */
function findSectionStart(lines: string[], sectionName: string): number {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (trimmed.startsWith(sectionName)) {
      return i;
    }
  }
  return -1;
}

/**
 * Parse SPSS Values Only CSV content into RawDataMapVariable[].
 */
export function parseSPSSValuesOnly(content: string): RawDataMapVariable[] {
  const lines = content.split('\n');

  // Find Variable Values section
  const valuesStart = findSectionStart(lines, 'Variable Values');
  if (valuesStart === -1) {
    throw new Error('Could not find "Variable Values" section in SPSS CSV');
  }

  // Parse value labels
  const valueLabels = parseVariableValuesSection(lines, valuesStart);

  // Convert to RawDataMapVariable[]
  // Maintain insertion order from the Map (preserves survey question ordering)
  const variables: RawDataMapVariable[] = [];

  for (const [varName, labels] of valueLabels) {
    const answerOptions = labels.length > 0
      ? labels.map((l) => `${l.value}=${l.label}`).join(',')
      : 'NA';

    // Infer value type from value labels
    const valueType = inferValueTypeFromLabels(labels);

    // Infer level from structural suffixes
    const level = hasStructuralSuffix(varName) ? 'sub' as const : 'parent' as const;

    variables.push({
      level,
      column: varName,
      description: '', // No descriptions available in Values Only format
      valueType,
      answerOptions,
      parentQuestion: 'NA',
    });
  }

  return variables;
}

/**
 * Infer value type from value labels alone (no print format available).
 */
function inferValueTypeFromLabels(labels: { value: string; label: string }[]): string {
  if (labels.length === 0) return '';

  const values = labels
    .map((l) => parseFloat(l.value))
    .filter((v) => !isNaN(v));

  if (values.length >= 2) {
    const min = Math.min(...values);
    const max = Math.max(...values);
    return `Values: ${min}-${max}`;
  }

  if (values.length === 1) {
    return `Values: ${values[0]}`;
  }

  return `Values: ${labels.map((l) => l.value).join(',')}`;
}
