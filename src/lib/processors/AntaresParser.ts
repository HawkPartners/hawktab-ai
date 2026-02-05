/**
 * AntaresParser.ts
 *
 * Extracted from DataMapProcessor.ts — the Antares state machine CSV parser.
 * Parses Antares-format DataMap CSV files into RawDataMapVariable[].
 *
 * Antares format characteristics:
 * - Lines starting with [VariableName]: Description
 * - "Values:" or "Open text/numeric response" lines for value types
 * - Answer options as: ,number,label
 * - Sub-variables as: ,[SubVariableName],Description
 * - Empty lines reset context
 */

import fs from 'fs/promises';
import type { RawDataMapVariable } from './DataMapProcessor';

// =============================================================================
// State Machine Enums
// =============================================================================

enum ParsingState {
  SCANNING,
  IN_PARENT,
  IN_VALUES,
  IN_OPTIONS,
  IN_SUB,
}

interface ParsingContext {
  currentParent: string | null;
  currentValueType: string | null;
  currentDescription: string | null;
  answerOptions: string[];
  state: ParsingState;
  variables: RawDataMapVariable[];
  currentRangeMin?: number;
  currentRangeMax?: number;
}

// Extended type for internal use (includes range info)
type RawVarWithRange = RawDataMapVariable & {
  rangeMin?: number;
  rangeMax?: number;
};

// =============================================================================
// Public API
// =============================================================================

/**
 * Parse an Antares-format DataMap CSV file into raw variables.
 */
export async function parseAntaresFile(filePath: string): Promise<RawVarWithRange[]> {
  const fileContent = await fs.readFile(filePath, 'utf-8');
  return parseAntaresContent(fileContent);
}

/**
 * Parse Antares-format DataMap CSV content into raw variables.
 */
export function parseAntaresContent(content: string): RawVarWithRange[] {
  const lines = content.trim().split('\n');

  const context: ParsingContext = {
    currentParent: null,
    currentValueType: null,
    currentDescription: null,
    answerOptions: [],
    state: ParsingState.SCANNING,
    variables: [],
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();

    // Skip empty lines - they reset context
    if (!line || line === ',,') {
      resetContext(context);
      continue;
    }

    processLine(line, context);
  }

  // Finalize any remaining context
  finalizeCurrentVariable(context);

  return context.variables as RawVarWithRange[];
}

// =============================================================================
// State Machine
// =============================================================================

function processLine(line: string, context: ParsingContext): void {
  const fields = parseCSVLine(line);

  // Check for bracket pattern (column definition)
  const bracketMatch = extractBracketContent(fields[0]);
  if (bracketMatch) {
    handleBracketLine(bracketMatch, fields, context);
    return;
  }

  // Check for Values: line
  if (fields[0].toLowerCase().startsWith('values:')) {
    handleValuesLine(fields[0], context);
    return;
  }

  // Check for Open text/numeric response line (appears after variable definition)
  if (fields[0].toLowerCase().startsWith('open ')) {
    handleValuesLine(fields[0], context);
    return;
  }

  // Check for answer options (lines starting with comma + number)
  if (fields[0] === '' && fields[1] && /^\d+$/.test(fields[1])) {
    handleAnswerOptionLine(fields, context);
    return;
  }

  // Check for sub-variable (comma + bracket)
  if (fields[0] === '' && fields[1]) {
    const subBracketMatch = extractBracketContent(fields[1]);
    if (subBracketMatch) {
      handleSubVariableLine(subBracketMatch, fields, context);
      return;
    }
  }
}

function extractBracketContent(text: string): string | null {
  const match = text.match(/\[([^\]]+)\]/);
  return match ? match[1] : null;
}

function handleBracketLine(
  columnName: string,
  fields: string[],
  context: ParsingContext
): void {
  // Finalize previous variable if exists
  finalizeCurrentVariable(context);

  // Start new parent variable
  context.currentParent = columnName;
  context.currentDescription = extractDescription(fields[0]);
  context.state = ParsingState.IN_PARENT;
  context.answerOptions = [];
  context.currentValueType = null;
}

function handleValuesLine(valuesText: string, context: ParsingContext): void {
  context.currentValueType = valuesText.trim();
  context.state = ParsingState.IN_VALUES;

  // Parse numeric ranges from "Values: X-Y" pattern
  const rangeMatch = valuesText.match(/values\s*:\s*(-?\d+)\s*-\s*(-?\d+)/i);
  if (rangeMatch) {
    context.currentRangeMin = parseInt(rangeMatch[1], 10);
    context.currentRangeMax = parseInt(rangeMatch[2], 10);
  }
}

function handleAnswerOptionLine(
  fields: string[],
  context: ParsingContext
): void {
  const optionNumber = fields[1];
  const optionText = fields[2] || '';

  if (optionNumber && optionText) {
    context.answerOptions.push(`${optionNumber}=${optionText}`);
    context.state = ParsingState.IN_OPTIONS;
  }
}

function handleSubVariableLine(
  columnName: string,
  fields: string[],
  context: ParsingContext
): void {
  const description = fields[2] || '';

  const subVariable: RawVarWithRange = {
    level: 'sub',
    column: columnName,
    description: description,
    valueType: context.currentValueType || '',
    answerOptions: 'NA',
    parentQuestion: 'NA', // Will be set correctly in parent inference
  };

  // Propagate range info from parent context to sub-variables
  if (context.currentRangeMin !== undefined) {
    subVariable.rangeMin = context.currentRangeMin;
    subVariable.rangeMax = context.currentRangeMax;
  }

  context.variables.push(subVariable);
}

function extractDescription(bracketLine: string): string {
  // Extract description after the bracket and colon
  const match = bracketLine.match(/\[[^\]]+\]:\s*(.+)/);
  return match ? match[1].trim() : '';
}

function finalizeCurrentVariable(context: ParsingContext): void {
  if (context.currentParent && context.currentDescription) {
    const answerOptions =
      context.answerOptions.length > 0
        ? context.answerOptions.join(',')
        : 'NA';

    const variable: RawVarWithRange = {
      level: 'parent',
      column: context.currentParent,
      description: context.currentDescription,
      valueType: context.currentValueType || '',
      answerOptions: answerOptions,
      parentQuestion: 'NA', // Will be set correctly in parent inference
    };

    // Add range info if available
    if (context.currentRangeMin !== undefined) {
      variable.rangeMin = context.currentRangeMin;
      variable.rangeMax = context.currentRangeMax;
    }

    context.variables.push(variable);
  }
}

function resetContext(context: ParsingContext): void {
  finalizeCurrentVariable(context);
  context.currentParent = null;
  context.currentDescription = null;
  context.currentValueType = null;
  context.answerOptions = [];
  context.state = ParsingState.SCANNING;
  context.currentRangeMin = undefined;
  context.currentRangeMax = undefined;
}

function parseCSVLine(line: string): string[] {
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
      result.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }

  result.push(current.trim());
  return result;
}
