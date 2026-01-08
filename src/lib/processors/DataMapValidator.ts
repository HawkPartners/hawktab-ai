/**
 * DataMapValidator.ts - Simplified Confidence + SPSS Validation
 * 
 * NOTE: This can be expanded later for more sophisticated validation
 * Focus: Keep core functionality working, remove over-engineering
 * 
 * Core functions:
 * - Calculate confidence scores for parsed variables
 * - Validate against SPSS files for column matching
 * - Simple pass/fail threshold checking
 */

import { ProcessedDataMapVariable } from './DataMapProcessor';
import { SPSSReader, SPSSValidationResult as SPSSReaderValidationResult } from './SPSSReader';

// ===== SIMPLIFIED TYPES =====

interface ConfidenceFactors {
  structuralIntegrity: number;  // 0-40 points (brackets, naming)
  contentCompleteness: number;  // 0-30 points (descriptions, values) 
  relationshipClarity: number;  // 0-30 points (parent-child relationships)
}

interface SPSSValidationResult {
  passed: boolean;
  confidence: number;
  columnMatches: {
    inBoth: number;
    onlyInDataMap: number;
    onlyInSPSS: number;
  };
  missingColumns?: string[];
  extraColumns?: string[];
  fullValidation?: SPSSReaderValidationResult;
}

// ===== CORE VALIDATOR CLASS =====

export class DataMapValidator {
  private spssReader = new SPSSReader();
  
  // Configuration
  private readonly CONFIDENCE_THRESHOLD = 0.75; // 75% confidence required
  private readonly WEIGHTS = {
    structuralIntegrity: 40,
    contentCompleteness: 30,
    relationshipClarity: 30
  };

  /**
   * Calculate overall confidence for all variables
   * Simplified from 5 factors to 3 core factors
   */
  calculateOverallConfidence(variables: ProcessedDataMapVariable[]): number {
    if (variables.length === 0) return 0;

    let totalScore = 0;
    let maxPossibleScore = 0;

    for (const variable of variables) {
      const factors = this.calculateConfidenceFactors(variable, variables);
      const variableScore = this.calculateWeightedScore(factors);
      
      totalScore += variableScore;
      maxPossibleScore += 100; // Each variable max 100
    }

    const overallConfidence = totalScore / maxPossibleScore;
    return Math.round(overallConfidence * 100) / 100; // Round to 2 decimal places
  }

  /**
   * Simple pass/fail based on confidence threshold
   */
  meetsConfidenceThreshold(confidence: number): boolean {
    return confidence >= this.CONFIDENCE_THRESHOLD;
  }

  /**
   * SPSS validation - real SPSS file processing
   */
  async validateAgainstSPSS(variables: ProcessedDataMapVariable[], spssPath?: string): Promise<SPSSValidationResult> {
    if (!spssPath) {
      console.log(`[DataMapValidator] No SPSS file provided, skipping validation`);
      return {
        passed: true,
        confidence: 1.0,
        columnMatches: { inBoth: 0, onlyInDataMap: 0, onlyInSPSS: 0 }
      };
    }

    try {
      console.log(`[DataMapValidator] Starting real SPSS validation: ${spssPath}`);
      
      // Use real SPSS reader to parse file
      const spssInfo = await this.spssReader.readSPSSInfo(spssPath);
      console.log(`[DataMapValidator] Successfully read SPSS file with ${spssInfo.totalVariables} variables`);
      
      // Get comprehensive validation results
      const fullValidation = this.spssReader.validateAgainstDataMap(spssInfo, variables);
      
      // Calculate confidence based on match rate
      const confidence = fullValidation.columnMatching.matchRate / 100;
      
      console.log(`[DataMapValidator] SPSS validation complete: ${fullValidation.columnMatching.matchRate}% match rate`);
      console.log(`[DataMapValidator] Summary: ${fullValidation.summary}`);
      
      return {
        passed: confidence >= 0.8, // 80% column match required
        confidence,
        columnMatches: {
          inBoth: fullValidation.columnMatching.matchedVariables.length,
          onlyInDataMap: fullValidation.columnMatching.missingInSav.length,
          onlyInSPSS: fullValidation.columnMatching.missingInDataMap.length
        },
        missingColumns: fullValidation.columnMatching.missingInSav,
        extraColumns: fullValidation.columnMatching.missingInDataMap,
        fullValidation
      };
      
    } catch (error) {
      console.error(`[DataMapValidator] SPSS validation failed:`, error);
      return {
        passed: false,
        confidence: 0,
        columnMatches: { inBoth: 0, onlyInDataMap: 0, onlyInSPSS: 0 },
        fullValidation: {
          performed: false,
          columnMatching: {
            dataMapVariables: variables.length,
            savVariables: 0,
            matchedVariables: [],
            missingInSav: [],
            missingInDataMap: [],
            matchRate: 0
          },
          categorizedMismatches: {
            explained: [],
            unexpected: []
          },
          summary: `SPSS validation failed: ${error instanceof Error ? error.message : 'Unknown error'}`
        }
      };
    }
  }

  // ===== PRIVATE METHODS =====

  private calculateConfidenceFactors(variable: ProcessedDataMapVariable, allVariables: ProcessedDataMapVariable[]): ConfidenceFactors {
    return {
      structuralIntegrity: this.scoreStructuralIntegrity(variable),
      contentCompleteness: this.scoreContentCompleteness(variable),
      relationshipClarity: this.scoreRelationshipClarity(variable, allVariables)
    };
  }

  private calculateWeightedScore(factors: ConfidenceFactors): number {
    let totalScore = 0;
    let maxPossibleScore = 0;

    Object.entries(factors).forEach(([key, value]) => {
      const weight = this.WEIGHTS[key as keyof ConfidenceFactors];
      totalScore += value;
      maxPossibleScore += weight;
    });

    return (totalScore / maxPossibleScore) * 100;
  }

  private scoreStructuralIntegrity(variable: ProcessedDataMapVariable): number {
    let score = this.WEIGHTS.structuralIntegrity;

    // Check column name quality
    if (!variable.column || variable.column.trim() === '') {
      return 0;
    }

    // Penalize very short or very long names
    if (variable.column.length < 2 || variable.column.length > 20) {
      score -= 10;
    }

    // Reward standard variable naming conventions
    if (variable.column.match(/^[QSAD]\d+/)) {
      // Standard survey question format (Q1, S2, A3, D4)
      score = Math.min(score, this.WEIGHTS.structuralIntegrity);
    } else {
      score -= 5;
    }

    // Check for formatting issues
    if (!/^[A-Za-z0-9_]+$/.test(variable.column)) {
      score -= 5;
    }

    return Math.max(0, score);
  }

  private scoreContentCompleteness(variable: ProcessedDataMapVariable): number {
    let score = this.WEIGHTS.contentCompleteness;

    // Check description completeness
    if (!variable.description || variable.description.trim() === '') {
      score -= 15;
    }

    // Check value type
    if (!variable.valueType || variable.valueType.trim() === '') {
      score -= 10;
    }

    // Check answer options for parent variables
    if (variable.level === 'parent') {
      if (variable.answerOptions === 'NA' || !variable.answerOptions) {
        // Check if this variable type typically needs answer options
        if (variable.valueType && variable.valueType.toLowerCase().includes('values:')) {
          score -= 5;
        }
      }
    }

    return Math.max(0, score);
  }

  private scoreRelationshipClarity(variable: ProcessedDataMapVariable, allVariables: ProcessedDataMapVariable[]): number {
    let score = this.WEIGHTS.relationshipClarity;

    if (variable.level === 'sub') {
      // Check if sub-variable has a clear parent
      const hasParent = variable.parentQuestion !== 'NA';
      
      if (!hasParent) {
        score -= 15;
      } else {
        // Check if parent actually exists in the dataset
        const parentExists = allVariables.some(v => 
          v.level === 'parent' && v.column === variable.parentQuestion
        );
        
        if (!parentExists) {
          score -= 10;
        }
      }

      // Reward variables with context information
      if (variable.context) {
        score = Math.min(score + 5, this.WEIGHTS.relationshipClarity);
      }
    }

    return Math.max(0, score);
  }
}

// Real SPSSReader is now imported from separate file