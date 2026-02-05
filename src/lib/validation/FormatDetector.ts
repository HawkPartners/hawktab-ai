/**
 * FormatDetector.ts
 *
 * Detects DataMap format from CSV content. Pure function, no dependencies.
 *
 * Supported formats:
 * - Antares: Lines starting with [VariableName]: Description
 * - SPSS Variable Info: Has "Variable Information" section with 9-column table
 * - SPSS Values Only: Has "Variable Values" but no "Variable Information"
 */

import type { DataMapFormat, FormatDetectionResult } from './types';

/**
 * Detect the format of a DataMap CSV file from its content.
 */
export function detectDataMapFormat(content: string): FormatDetectionResult {
  const signals: string[] = [];
  let antaresScore = 0;
  let spssVariableInfoScore = 0;
  let spssValuesOnlyScore = 0;

  const lines = content.split('\n').slice(0, 100); // Only check first 100 lines

  // --- Antares signals ---
  // Lines starting with [VarName]: description
  const antaresLinePattern = /^\[[\w_]+\]:/;
  let antaresLineCount = 0;
  for (const line of lines) {
    if (antaresLinePattern.test(line.trim())) {
      antaresLineCount++;
    }
  }
  if (antaresLineCount >= 2) {
    antaresScore += 3;
    signals.push(`Found ${antaresLineCount} Antares-style [VarName]: lines`);
  }

  // "Values:" line after bracket line (Antares pattern)
  const hasValuesAfterBracket = lines.some(
    (line, i) =>
      antaresLinePattern.test(line.trim()) &&
      i + 1 < lines.length &&
      /^(Values:|Open\s)/i.test(lines[i + 1].trim())
  );
  if (hasValuesAfterBracket) {
    antaresScore += 2;
    signals.push('Found Values:/Open line after bracket line (Antares)');
  }

  // --- SPSS Variable Info signals ---
  const hasVariableInformation = lines.some(
    (line) => line.trim().startsWith('Variable Information')
  );
  if (hasVariableInformation) {
    spssVariableInfoScore += 4;
    signals.push('Found "Variable Information" section header');
  }

  // 9-column header: Variable,Position,Label,...
  const hasSpssHeader = lines.some((line) =>
    /^Variable,Position,Label/i.test(line.trim())
  );
  if (hasSpssHeader) {
    spssVariableInfoScore += 3;
    signals.push('Found SPSS Variable Info header (Variable,Position,Label)');
  }

  // File Information / Notes preamble
  const hasPreamble = lines.some(
    (line) =>
      line.trim().startsWith('File Information') ||
      line.trim().startsWith('Notes')
  );
  if (hasPreamble) {
    spssVariableInfoScore += 1;
    signals.push('Found SPSS preamble (File Information/Notes)');
  }

  // --- SPSS Values Only signals ---
  // Check full content for Variable Values section (may not be in first 100 lines)
  const hasVariableValues = content.includes('Variable Values');
  if (hasVariableValues && !hasVariableInformation) {
    spssValuesOnlyScore += 4;
    signals.push('Found "Variable Values" without "Variable Information"');
  }

  // --- Determine format ---
  const scores: { format: DataMapFormat; score: number }[] = [
    { format: 'antares', score: antaresScore },
    { format: 'spss_variable_info', score: spssVariableInfoScore },
    { format: 'spss_values_only', score: spssValuesOnlyScore },
  ];

  scores.sort((a, b) => b.score - a.score);

  const bestMatch = scores[0];

  if (bestMatch.score === 0) {
    return {
      format: 'unknown',
      confidence: 0,
      signals: signals.length > 0 ? signals : ['No format signals detected'],
    };
  }

  // Confidence: normalize to 0-1 range (max possible score ~8)
  const confidence = Math.min(bestMatch.score / 7, 1);

  return {
    format: bestMatch.format,
    confidence,
    signals,
  };
}
