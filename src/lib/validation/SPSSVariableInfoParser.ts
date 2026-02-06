/**
 * SPSSVariableInfoParser.ts
 *
 * Parses SPSS Variable Info CSV format → RawDataMapVariable[].
 *
 * This format comes from SPSS "DISPLAY DICTIONARY" output exported to CSV.
 * It has two main sections:
 * 1. Variable Information - 9-column table with variable metadata
 * 2. Variable Values - value labels (continuation rows have blank first column)
 *
 * Key challenges:
 * - Skip preamble (File Information, Notes, etc.)
 * - Label field contains "VarName: Question text" — split on first ':'
 * - Labels truncated at ~255 chars
 * - Variable Values continuation rows have blank first column
 * - Some variables have no value labels
 */

import type { RawDataMapVariable } from '../processors/DataMapProcessor';
import { parseCSVLine, hasStructuralSuffix, parseVariableValuesSection } from './spss-utils';

// =============================================================================
// Types
// =============================================================================

interface SPSSVariable {
  variable: string;
  position: number;
  label: string;
  description: string;
  measurementLevel: string;
  printFormat: string;
}


// =============================================================================
// Parser
// =============================================================================

/**
 * Parse SPSS Variable Info CSV content into RawDataMapVariable[].
 */
export function parseSPSSVariableInfo(content: string): RawDataMapVariable[] {
  const lines = content.split('\n');

  // Step 1: Find Variable Information section
  const varInfoStart = findSectionStart(lines, 'Variable Information');
  if (varInfoStart === -1) {
    throw new Error('Could not find "Variable Information" section in SPSS CSV');
  }

  // Step 2: Parse Variable Information table
  const variables = parseVariableInformation(lines, varInfoStart);

  // Step 3: Find Variable Values section
  const varValuesStart = findSectionStart(lines, 'Variable Values');
  const valueLabels = varValuesStart !== -1
    ? parseVariableValuesSection(lines, varValuesStart)
    : new Map<string, { value: string; label: string }[]>();

  // Step 4: Convert to RawDataMapVariable[]
  return variables.map((v) => {
    const labels = valueLabels.get(v.variable) || [];
    const answerOptions = labels.length > 0
      ? labels.map((l) => `${l.value}=${l.label}`).join(',')
      : 'NA';

    // Determine value type from print format and answer options
    const valueType = inferValueType(v, labels);

    // Infer level from structural suffixes in variable name
    const level = hasStructuralSuffix(v.variable) ? 'sub' as const : 'parent' as const;

    return {
      level,
      column: v.variable,
      description: v.description,
      valueType,
      answerOptions,
      parentQuestion: 'NA',
    };
  });
}

// =============================================================================
// Section Parsing
// =============================================================================

/**
 * Find the line index where a section starts.
 */
function findSectionStart(lines: string[], sectionName: string): number {
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    // Match "Variable Information,,,,,,," or just "Variable Information"
    if (trimmed.startsWith(sectionName)) {
      return i;
    }
  }
  return -1;
}

/**
 * Parse the Variable Information 9-column table.
 */
function parseVariableInformation(lines: string[], startIndex: number): SPSSVariable[] {
  const variables: SPSSVariable[] = [];

  // Skip to the header row (Variable,Position,Label,...)
  let headerIndex = startIndex + 1;
  while (headerIndex < lines.length) {
    const line = lines[headerIndex].trim();
    if (line.startsWith('Variable,Position,Label') || line.startsWith('Variable,Position,"Label"')) {
      break;
    }
    headerIndex++;
    if (headerIndex - startIndex > 5) {
      throw new Error('Could not find Variable Information header row');
    }
  }

  // Parse rows after header until we hit an empty section or next section
  for (let i = headerIndex + 1; i < lines.length; i++) {
    const line = lines[i].trim();

    // End of section: empty line, or next section marker
    if (!line || line === ',,,,,,,,' || line.startsWith('Variables in the working file') || line.startsWith('Variable Values')) {
      break;
    }

    const fields = parseCSVLine(line);
    const varName = fields[0]?.trim();
    if (!varName) continue;

    const position = parseInt(fields[1], 10);
    const rawLabel = fields[2]?.trim() || '';
    const measurementLevel = fields[3]?.trim() || '';
    const printFormat = fields[7]?.trim() || '';

    // Extract description from label: "VarName: Question text" → "Question text"
    const description = extractDescription(varName, rawLabel);

    variables.push({
      variable: varName,
      position,
      label: rawLabel,
      description,
      measurementLevel,
      printFormat,
    });
  }

  return variables;
}

// =============================================================================
// Helpers
// =============================================================================

/**
 * Extract description from SPSS label.
 * Labels are formatted as "VarName: Question text".
 * Split on first ':' and take the rest.
 */
function extractDescription(varName: string, rawLabel: string): string {
  if (!rawLabel) return '';

  // Check if label starts with "VarName:" pattern
  const prefix = `${varName}:`;
  if (rawLabel.startsWith(prefix)) {
    return rawLabel.substring(prefix.length).trim();
  }

  // Sometimes labels use slightly different formats
  const colonIndex = rawLabel.indexOf(':');
  if (colonIndex > 0 && colonIndex < 30) {
    // Only split if colon is near the start (likely variable name prefix)
    const beforeColon = rawLabel.substring(0, colonIndex).trim();
    // Verify the part before colon looks like a variable name
    if (/^[\w_]+$/.test(beforeColon)) {
      return rawLabel.substring(colonIndex + 1).trim();
    }
  }

  return rawLabel;
}

/**
 * Infer value type string from SPSS metadata.
 */
function inferValueType(variable: SPSSVariable, labels: { value: string; label: string }[]): string {
  const fmt = variable.printFormat.toUpperCase();

  // String formats
  if (fmt.startsWith('A')) {
    return 'Open text response';
  }

  // Date/time formats
  if (fmt.startsWith('DATE') || fmt.startsWith('DATETIME') || fmt.startsWith('TIME')) {
    return 'Open text response';
  }

  // Has value labels → categorical
  if (labels.length > 0) {
    const values = labels.map((l) => parseInt(l.value, 10)).filter((v) => !isNaN(v));
    if (values.length >= 2) {
      const min = Math.min(...values);
      const max = Math.max(...values);
      return `Values: ${min}-${max}`;
    }
    return `Values: ${labels.map((l) => l.value).join(',')}`;
  }

  // Numeric without labels
  if (fmt.startsWith('F')) {
    return 'Open numeric response';
  }

  return '';
}

