/**
 * SPSSReader.ts - Real SPSS File Processing
 * 
 * Based on reference implementation but adapted for our clean architecture
 * Uses sav-reader library for actual .sav file parsing
 * 
 * Key features:
 * - Real SPSS variable extraction
 * - Column matching validation  
 * - Value range validation
 * - Clean error handling
 */

import fs from 'fs/promises';
import { ProcessedDataMapVariable } from './DataMapProcessor';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { SavFileReader, SavBufferReader } = require('sav-reader');

// ===== TYPES =====

export interface SPSSVariable {
  name: string;
  label?: string;
  type: 'numeric' | 'string';
  format?: string;
  valueLabels?: Record<number, string>;
  measure?: 'nominal' | 'ordinal' | 'scale';
}

export interface SPSSDataInfo {
  variables: SPSSVariable[];
  totalVariables: number;
  recordCount: number;
  fileInfo: {
    version: string;
    created: string;
  };
}

/**
 * Categorized mismatch - explains why a variable is missing/extra
 */
export interface CategorizedMismatch {
  variable: string;
  category: 'numeric_prefix' | 'duplicate_column' | 'case_mismatch' | 'unexpected';
  explanation: string;
  matchedWith?: string; // The variable it resolved to (if any)
}

export interface SPSSValidationResult {
  performed: boolean;
  columnMatching: {
    dataMapVariables: number;
    savVariables: number;
    matchedVariables: string[];
    missingInSav: string[];
    missingInDataMap: string[];
    matchRate: number;
  };
  /** Categorized explanations for mismatches */
  categorizedMismatches: {
    explained: CategorizedMismatch[];
    unexpected: CategorizedMismatch[];
  };
  valueValidation?: {
    validatedVariables: number;
    rangeIssues: Array<{
      variable: string;
      dataMapRange: string;
      actualRange: string;
      issue: string;
    }>;
  };
  summary: string;
}

// ===== MAIN SPSS READER CLASS =====

export class SPSSReader {
  /**
   * Read SPSS file information from file path
   */
  async readSPSSInfo(filePath: string): Promise<SPSSDataInfo> {
    try {
      console.log(`[SPSSReader] Reading SPSS file: ${filePath}`);
      
      // Check if file exists
      await fs.access(filePath);
      
      // Use sav-reader to parse the SPSS file
      const sav = new SavFileReader(filePath);
      await sav.open();
      
      console.log(`[SPSSReader] SPSS file opened successfully`);
      
      // Extract file metadata
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const meta = sav.meta as any;
      
      if (!meta) {
        throw new Error('No metadata found in SPSS file - file may be corrupted or not a valid .sav file');
      }
      
      if (!meta.sysvars) {
        throw new Error('No system variables found in SPSS file metadata');
      }
      
      console.log(`[SPSSReader] Found ${meta.sysvars.length} variables in SPSS file`);
      
      const variables: SPSSVariable[] = [];
      
      // Process each variable from the SPSS file using sysvars array
      for (const varData of meta.sysvars) {
        const spssVar: SPSSVariable = {
          name: varData.name,
          label: varData.label || undefined,
          type: varData.type === 'numeric' ? 'numeric' : 'string',
          format: varData.format || undefined,
        };
        
        // Get value labels for this variable
        try {
          const valueLabels = meta.getValueLabels(varData.name);
          if (valueLabels && Object.keys(valueLabels).length > 0) {
            spssVar.valueLabels = {};
            for (const [value, label] of Object.entries(valueLabels)) {
              const numValue = parseFloat(value);
              if (!isNaN(numValue)) {
                spssVar.valueLabels[numValue] = label as string;
              }
            }
          }
        } catch {
          // Value labels not available for this variable - continue
        }
        
        // Set measure level if available
        if (varData.measure !== undefined) {
          switch (varData.measure) {
            case 1:
              spssVar.measure = 'nominal';
              break;
            case 2:
              spssVar.measure = 'ordinal';
              break;
            case 3:
              spssVar.measure = 'scale';
              break;
          }
        }
        
        variables.push(spssVar);
      }
      
      console.log(`[SPSSReader] Processed ${variables.length} variables from SPSS file`);
      
      const result: SPSSDataInfo = {
        variables,
        totalVariables: variables.length,
        recordCount: meta.header?.n_cases || 0,
        fileInfo: {
          version: meta.header?.product || 'Unknown',
          created: meta.header?.created || 'Unknown'
        }
      };
      
      // Close SPSS file if close method exists
      if (typeof sav.close === 'function') {
        try {
          await sav.close();
        } catch (closeError) {
          console.warn(`[SPSSReader] Warning: Could not close SPSS file:`, closeError);
        }
      }
      return result;
      
    } catch (error) {
      console.error(`[SPSSReader] Error reading SPSS file:`, error);
      throw new Error(`Failed to read SPSS file: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Read SPSS file information from buffer (alternative method)
   */
  async readSPSSInfoFromBuffer(buffer: Buffer): Promise<SPSSDataInfo> {
    try {
      console.log(`[SPSSReader] Reading SPSS file from buffer (${buffer.length} bytes)`);
      
      // Use sav-reader to parse the SPSS file from buffer
      const sav = new SavBufferReader(buffer);
      await sav.open();
      
      // Extract file metadata
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const meta = sav.meta as any;
      
      if (!meta || !meta.sysvars) {
        throw new Error('No valid SPSS metadata found in buffer');
      }
      
      const variables: SPSSVariable[] = [];
      
      // Process each variable from the SPSS file using sysvars array
      for (const varData of meta.sysvars) {
        const spssVar: SPSSVariable = {
          name: varData.name,
          label: varData.label || undefined,
          type: varData.type === 'numeric' ? 'numeric' : 'string',
          format: varData.format || undefined,
        };
        
        // Get value labels for this variable
        try {
          const valueLabels = meta.getValueLabels(varData.name);
          if (valueLabels && Object.keys(valueLabels).length > 0) {
            spssVar.valueLabels = {};
            for (const [value, label] of Object.entries(valueLabels)) {
              const numValue = parseFloat(value);
              if (!isNaN(numValue)) {
                spssVar.valueLabels[numValue] = label as string;
              }
            }
          }
        } catch {
          // Value labels not available for this variable
        }
        
        // Set measure level if available
        if (varData.measure !== undefined) {
          switch (varData.measure) {
            case 1:
              spssVar.measure = 'nominal';
              break;
            case 2:
              spssVar.measure = 'ordinal';
              break;
            case 3:
              spssVar.measure = 'scale';
              break;
          }
        }
        
        variables.push(spssVar);
      }
      
      const result: SPSSDataInfo = {
        variables,
        totalVariables: variables.length,
        recordCount: meta.header?.n_cases || 0,
        fileInfo: {
          version: meta.header?.product || 'Unknown',
          created: meta.header?.created || 'Unknown'
        }
      };
      
      // Close SPSS file if close method exists
      if (typeof sav.close === 'function') {
        try {
          await sav.close();
        } catch (closeError) {
          console.warn(`[SPSSReader] Warning: Could not close SPSS file:`, closeError);
        }
      }
      return result;
      
    } catch (error) {
      throw new Error(`Failed to read SPSS file from buffer: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Validate data map variables against SPSS file variables
   */
  validateAgainstDataMap(spssInfo: SPSSDataInfo, dataMapVariables: ProcessedDataMapVariable[]): SPSSValidationResult {
    console.log(`[SPSSReader] Validating ${dataMapVariables.length} data map variables against ${spssInfo.totalVariables} SPSS variables`);

    // Keep original case for display, use lowercase for matching
    const spssVariableNamesOriginal = spssInfo.variables.map(v => v.name);
    const dataMapVariableNamesOriginal = dataMapVariables.map(v => v.column);
    const spssVariableNames = spssVariableNamesOriginal.map(v => v.toLowerCase());
    const dataMapVariableNames = dataMapVariableNamesOriginal.map(v => v.toLowerCase());

    // Column matching analysis (case-insensitive)
    const matchedVariables = dataMapVariableNames.filter(name =>
      spssVariableNames.includes(name)
    );

    // Get original-case names for mismatches (for display)
    const missingInSav = dataMapVariableNamesOriginal.filter(name =>
      !spssVariableNames.includes(name.toLowerCase())
    );

    const missingInDataMap = spssVariableNamesOriginal.filter(name =>
      !dataMapVariableNames.includes(name.toLowerCase())
    );

    const matchRate = Math.round((matchedVariables.length / dataMapVariableNames.length) * 100);

    console.log(`[SPSSReader] Column matching: ${matchedVariables.length}/${dataMapVariableNames.length} (${matchRate}%)`);

    // Categorize mismatches (uses original case for display)
    const categorizedMismatches = this.categorizeMismatches(
      missingInSav,
      missingInDataMap,
      spssVariableNamesOriginal,
      dataMapVariableNamesOriginal
    );

    console.log(`[SPSSReader] Mismatches: ${categorizedMismatches.explained.length} explained, ${categorizedMismatches.unexpected.length} unexpected`);

    // Value range validation
    const valueValidation = this.validateValueRanges(spssInfo, dataMapVariables);

    const summary = this.generateValidationSummary(
      matchedVariables.length,
      missingInSav,
      missingInDataMap,
      matchRate,
      categorizedMismatches
    );

    return {
      performed: true,
      columnMatching: {
        dataMapVariables: dataMapVariableNames.length,
        savVariables: spssVariableNames.length,
        matchedVariables,
        missingInSav,
        missingInDataMap,
        matchRate
      },
      categorizedMismatches,
      valueValidation,
      summary
    };
  }
  
  /**
   * Validate value ranges between data map and SPSS variables
   */
  private validateValueRanges(spssInfo: SPSSDataInfo, dataMapVariables: ProcessedDataMapVariable[]) {
    const rangeIssues: Array<{
      variable: string;
      dataMapRange: string;
      actualRange: string;
      issue: string;
    }> = [];
    
    // For each variable with value labels in SPSS, check against datamap ranges
    for (const spssVar of spssInfo.variables) {
      if (spssVar.valueLabels) {
        const dataMapVar = dataMapVariables.find(v => 
          v.column.toLowerCase() === spssVar.name.toLowerCase()
        );
        
        if (dataMapVar && dataMapVar.valueType) {
          // Extract expected range from datamap (e.g., "Values: 1-4")
          const rangeMatch = dataMapVar.valueType.match(/Values:\s*(\d+)-(\d+)/);
          if (rangeMatch) {
            const expectedMin = parseInt(rangeMatch[1]);
            const expectedMax = parseInt(rangeMatch[2]);
            const actualValues = Object.keys(spssVar.valueLabels).map(Number);
            const actualMin = Math.min(...actualValues);
            const actualMax = Math.max(...actualValues);
            
            if (actualMin !== expectedMin || actualMax !== expectedMax) {
              rangeIssues.push({
                variable: spssVar.name,
                dataMapRange: `${expectedMin}-${expectedMax}`,
                actualRange: `${actualMin}-${actualMax}`,
                issue: 'Value range mismatch between datamap and SPSS file'
              });
            }
          }
        }
      }
    }
    
    return {
      validatedVariables: spssInfo.variables.filter(v => v.valueLabels).length,
      rangeIssues
    };
  }
  
  /**
   * Categorize mismatches using a waterfall approach:
   * 1. x-prefix (SPSS numeric-start naming)
   * 2. *_dupe* pattern (duplicate columns)
   * 3. Case-insensitive match
   * 4. Whatever's left = unexpected
   */
  private categorizeMismatches(
    missingInSav: string[],
    missingInDataMap: string[],
    spssVariableNames: string[],
    dataMapVariableNames: string[]
  ): { explained: CategorizedMismatch[]; unexpected: CategorizedMismatch[] } {
    const explained: CategorizedMismatch[] = [];
    const unexpected: CategorizedMismatch[] = [];

    // Track which SPSS variables have been "used" to explain a mismatch
    const usedSpssVars = new Set<string>();

    // Process variables missing in SPSS (datamap has it, SPSS doesn't)
    for (const dmVar of missingInSav) {
      const dmVarLower = dmVar.toLowerCase();
      let categorized = false;

      // 1. Try x-prefix: datamap has "834_flag", SPSS has "x834_flag"
      const xPrefixMatch = spssVariableNames.find(
        spssVar => spssVar.toLowerCase() === 'x' + dmVarLower && !usedSpssVars.has(spssVar.toLowerCase())
      );
      if (xPrefixMatch) {
        explained.push({
          variable: dmVar,
          category: 'numeric_prefix',
          explanation: `SPSS prefixes numeric-start names with 'x'`,
          matchedWith: xPrefixMatch
        });
        usedSpssVars.add(xPrefixMatch.toLowerCase());
        categorized = true;
        continue;
      }

      // 2. Try case-insensitive match (catches exact case differences)
      const caseMatch = spssVariableNames.find(
        spssVar => spssVar.toLowerCase() === dmVarLower &&
                   spssVar !== dmVar &&
                   !usedSpssVars.has(spssVar.toLowerCase())
      );
      if (caseMatch) {
        explained.push({
          variable: dmVar,
          category: 'case_mismatch',
          explanation: `Case difference (harmless)`,
          matchedWith: caseMatch
        });
        usedSpssVars.add(caseMatch.toLowerCase());
        categorized = true;
        continue;
      }

      if (!categorized) {
        unexpected.push({
          variable: dmVar,
          category: 'unexpected',
          explanation: `Variable in datamap not found in SPSS file`
        });
      }
    }

    // Process variables missing in datamap (SPSS has it, datamap doesn't)
    for (const spssVar of missingInDataMap) {
      const spssVarLower = spssVar.toLowerCase();

      // Skip if already used to explain a datamap mismatch
      if (usedSpssVars.has(spssVarLower)) {
        continue;
      }

      let categorized = false;

      // 1. Check if this is an x-prefixed version of a datamap var
      if (spssVarLower.startsWith('x')) {
        const withoutX = spssVarLower.slice(1);
        const dmMatch = dataMapVariableNames.find(dm => dm.toLowerCase() === withoutX);
        if (dmMatch) {
          // Already handled in the missingInSav loop
          categorized = true;
          continue;
        }
      }

      // 2. Try *_dupe* pattern (duplicate columns in SPSS)
      if (/_dupe\d*$/i.test(spssVar)) {
        const baseName = spssVar.replace(/_dupe\d*$/i, '');
        const baseMatch = dataMapVariableNames.find(
          dm => dm.toLowerCase() === baseName.toLowerCase()
        );
        explained.push({
          variable: spssVar,
          category: 'duplicate_column',
          explanation: `SPSS duplicate column`,
          matchedWith: baseMatch || baseName
        });
        categorized = true;
        continue;
      }

      // 3. Case-insensitive match (already handled in missingInSav)
      const caseMatch = dataMapVariableNames.find(
        dm => dm.toLowerCase() === spssVarLower && dm !== spssVar
      );
      if (caseMatch) {
        // Already handled
        categorized = true;
        continue;
      }

      if (!categorized) {
        unexpected.push({
          variable: spssVar,
          category: 'unexpected',
          explanation: `Variable in SPSS file not documented in datamap`
        });
      }
    }

    return { explained, unexpected };
  }

  /**
   * Generate human-readable validation summary
   */
  private generateValidationSummary(
    matchedCount: number,
    missingInSav: string[],
    missingInDataMap: string[],
    matchRate: number,
    categorizedMismatches?: { explained: CategorizedMismatch[]; unexpected: CategorizedMismatch[] }
  ): string {
    const totalDataMapVars = matchedCount + missingInSav.length;
    let summary = `SPSS Validation Complete:\n`;
    summary += `- Matched ${matchedCount}/${totalDataMapVars} variables (${matchRate}%)\n`;

    // Show categorized mismatches if available
    if (categorizedMismatches) {
      const { explained, unexpected } = categorizedMismatches;

      if (explained.length > 0) {
        summary += `\nExplained differences:\n`;
        for (const m of explained) {
          const arrow = m.matchedWith ? ` ↔ ${m.matchedWith}` : '';
          const categoryLabel = this.getCategoryLabel(m.category);
          summary += `  • ${m.variable}${arrow} (${categoryLabel})\n`;
        }
      }

      summary += `\nUnexpected differences: ${unexpected.length}\n`;
      if (unexpected.length > 0) {
        for (const m of unexpected) {
          summary += `  ⚠ ${m.variable}: ${m.explanation}\n`;
        }
      }

      // Final verdict
      if (unexpected.length === 0) {
        summary += `\n✓ All differences resolved - data is consistent`;
      } else {
        summary += `\n⚠ ${unexpected.length} difference(s) need review`;
      }
    } else {
      // Fallback to old format if no categorization
      if (missingInSav.length > 0) {
        summary += `- ${missingInSav.length} variables in datamap missing from SPSS file\n`;
      }
      if (missingInDataMap.length > 0) {
        summary += `- ${missingInDataMap.length} variables in SPSS file not documented in datamap\n`;
      }

      if (matchRate >= 95) {
        summary += `- Excellent data consistency!`;
      } else if (matchRate >= 85) {
        summary += `- Good data consistency with minor gaps`;
      } else {
        summary += `- Significant data consistency issues require review`;
      }
    }

    return summary;
  }

  /**
   * Get human-readable label for mismatch category
   */
  private getCategoryLabel(category: CategorizedMismatch['category']): string {
    switch (category) {
      case 'numeric_prefix':
        return 'numeric-start naming convention';
      case 'duplicate_column':
        return 'duplicate column';
      case 'case_mismatch':
        return 'case difference';
      case 'unexpected':
        return 'unexpected';
    }
  }
}