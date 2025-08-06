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
    
    const spssVariableNames = spssInfo.variables.map(v => v.name.toLowerCase());
    const dataMapVariableNames = dataMapVariables.map(v => v.column.toLowerCase());
    
    // Column matching analysis
    const matchedVariables = dataMapVariableNames.filter(name => 
      spssVariableNames.includes(name)
    );
    
    const missingInSav = dataMapVariableNames.filter(name => 
      !spssVariableNames.includes(name)
    );
    
    const missingInDataMap = spssVariableNames.filter(name => 
      !dataMapVariableNames.includes(name)
    );
    
    const matchRate = Math.round((matchedVariables.length / dataMapVariableNames.length) * 100);
    
    console.log(`[SPSSReader] Column matching: ${matchedVariables.length}/${dataMapVariableNames.length} (${matchRate}%)`);
    
    // Value range validation
    const valueValidation = this.validateValueRanges(spssInfo, dataMapVariables);
    
    const summary = this.generateValidationSummary(matchedVariables.length, missingInSav, missingInDataMap, matchRate);
    
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
   * Generate human-readable validation summary
   */
  private generateValidationSummary(
    matchedCount: number, 
    missingInSav: string[], 
    missingInDataMap: string[], 
    matchRate: number
  ): string {
    let summary = `SPSS Validation Complete:\n`;
    summary += `- Matched ${matchedCount} variables (${matchRate}% match rate)\n`;
    
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
    
    return summary;
  }
}