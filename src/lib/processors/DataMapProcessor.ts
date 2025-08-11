/**
 * DataMapProcessor.ts - Consolidated State Machine
 * 
 * ALL-IN-ONE processor combining:
 * - State machine CSV parsing (from csv-parser.ts)
 * - Parent inference (from parent-inference.ts) 
 * - Context enrichment (from context-enrichment.ts)
 * - Internal validation
 * 
 * Workflow: CSV Upload → processDataMap() → Dual Outputs + Validation
 */

import fs from 'fs/promises';
import path from 'path';
import { DataMapValidator } from './DataMapValidator';

// ===== TYPES & INTERFACES =====

export interface RawDataMapVariable {
  level: 'parent' | 'sub';
  column: string;
  description: string;
  valueType: string;
  answerOptions: string;
  parentQuestion: string;
  context?: string;
}

export interface ProcessedDataMapVariable extends RawDataMapVariable {
  context?: string;
  confidence?: number;
  // Enrichment fields for normalized typing
  normalizedType?: 'numeric_range' | 'percentage_per_option' | 'ordinal_scale' | 
                   'matrix_single_choice' | 'binary_flag' | 'categorical_select' | 
                   'text_open' | 'admin';
  rangeMin?: number;
  rangeMax?: number;
  rangeStep?: number;
  allowedValues?: (number | string)[];
  scaleLabels?: { value: number | string; label: string }[];
  rowSumConstraint?: boolean;
  dependentOn?: string;
  dependentRule?: string;
}

export type VerboseDataMap = ProcessedDataMapVariable;

export interface AgentDataMap {
  Column: string;
  Description: string;
  Answer_Options: string;
  ParentQuestion?: string;
  Context?: string;
}

export interface ProcessingResult {
  success: boolean;
  verbose: VerboseDataMap[];
  agent: AgentDataMap[];
  validationPassed: boolean;
  confidence: number;
  errors: string[];
  warnings: string[];
}

// ===== STATE MACHINE ENUMS =====

enum ParsingState {
  SCANNING,
  IN_PARENT,
  IN_VALUES, 
  IN_OPTIONS,
  IN_SUB
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

// ===== MAIN PROCESSOR CLASS =====

export class DataMapProcessor {
  private validator = new DataMapValidator();

  /**
   * Main entry point - complete workflow
   * CSV Upload → Parse → Inference → Enrichment → Validation → Dual Outputs
   */
  async processDataMap(filePath: string, spssFilePath?: string, outputFolder?: string): Promise<ProcessingResult> {
    const errors: string[] = [];
    const warnings: string[] = [];

    try {
      // Step 1: State machine parsing
      console.log(`[DataMapProcessor] Starting CSV parsing: ${path.basename(filePath)}`);
      const rawVariables = await this.parseCSVStructure(filePath);
      console.log(`[DataMapProcessor] Parsed ${rawVariables.length} raw variables`);

      // Step 2: Parent inference 
      console.log(`[DataMapProcessor] Adding parent relationships`);
      const withParents = this.addParentRelationships(rawVariables);
      const parentCount = withParents.filter(v => v.parentQuestion !== 'NA').length;
      console.log(`[DataMapProcessor] Added parent relationships for ${parentCount} variables`);

      // Step 3: Context enrichment
      console.log(`[DataMapProcessor] Enriching context from original file`);
      const enriched = await this.addContextInformation(withParents, filePath);
      const contextCount = enriched.filter(v => v.context).length;
      console.log(`[DataMapProcessor] Added context for ${contextCount} variables`);
      
      // Step 3.5: Type normalization and pattern detection
      console.log(`[DataMapProcessor] Normalizing types and detecting patterns`);
      const normalized = this.normalizeVariableTypes(enriched);
      const normalizedCount = normalized.filter(v => v.normalizedType).length;
      console.log(`[DataMapProcessor] Normalized ${normalizedCount} variables`);

      // Step 4: Internal validation
      console.log(`[DataMapProcessor] Running validation`);
      const validationResult = await this.validateProcessedData(normalized, spssFilePath);
      console.log(`[DataMapProcessor] Validation confidence: ${validationResult.confidence.toFixed(2)}`);

      // Step 5: Generate dual outputs
      const dualOutputs = this.generateDualOutputs(normalized);
      
      // Development output in development mode
      if (process.env.NODE_ENV === 'development' && outputFolder) {
        await this.saveDevelopmentOutputs(dualOutputs, path.basename(filePath), outputFolder);
      }

      return {
        success: true,
        verbose: dualOutputs.verbose,
        agent: dualOutputs.agent,
        validationPassed: validationResult.passed,
        confidence: validationResult.confidence,
        errors,
        warnings
      };

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown processing error';
      console.error(`[DataMapProcessor] Error:`, errorMessage);
      
      return {
        success: false,
        verbose: [],
        agent: [],
        validationPassed: false,
        confidence: 0,
        errors: [errorMessage],
        warnings
      };
    }
  }

  // ===== STEP 1: STATE MACHINE PARSING =====

  private async parseCSVStructure(filePath: string): Promise<RawDataMapVariable[]> {
    const fileContent = await fs.readFile(filePath, 'utf-8');
    const lines = fileContent.trim().split('\n');
    
    const context: ParsingContext = {
      currentParent: null,
      currentValueType: null,
      currentDescription: null,
      answerOptions: [],
      state: ParsingState.SCANNING,
      variables: []
    };
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Skip empty lines - they reset context
      if (!line || line === ',,') {
        this.resetContext(context);
        continue;
      }
      
      this.processLine(line, context);
    }
    
    // Finalize any remaining context
    this.finalizeCurrentVariable(context);
    
    return context.variables;
  }

  private processLine(line: string, context: ParsingContext): void {
    const fields = this.parseCSVLine(line);
    
    // Check for bracket pattern (column definition)
    const bracketMatch = this.extractBracketContent(fields[0]);
    if (bracketMatch) {
      this.handleBracketLine(bracketMatch, fields, context);
      return;
    }
    
    // Check for Values: line
    if (fields[0].toLowerCase().startsWith('values:')) {
      this.handleValuesLine(fields[0], context);
      return;
    }
    
    // Check for answer options (lines starting with comma + number)
    if (fields[0] === '' && fields[1] && /^\d+$/.test(fields[1])) {
      this.handleAnswerOptionLine(fields, context);
      return;
    }
    
    // Check for sub-variable (comma + bracket)
    if (fields[0] === '' && fields[1]) {
      const subBracketMatch = this.extractBracketContent(fields[1]);
      if (subBracketMatch) {
        this.handleSubVariableLine(subBracketMatch, fields, context);
        return;
      }
    }
  }

  private extractBracketContent(text: string): string | null {
    const match = text.match(/\[([^\]]+)\]/);
    return match ? match[1] : null;
  }

  private handleBracketLine(columnName: string, fields: string[], context: ParsingContext): void {
    // Finalize previous variable if exists
    this.finalizeCurrentVariable(context);
    
    // Start new parent variable
    context.currentParent = columnName;
    context.currentDescription = this.extractDescription(fields[0]);
    context.state = ParsingState.IN_PARENT;
    context.answerOptions = [];
    context.currentValueType = null;
  }

  private handleValuesLine(valuesText: string, context: ParsingContext): void {
    context.currentValueType = valuesText.trim();
    context.state = ParsingState.IN_VALUES;
    
    // Parse numeric ranges from "Values: X-Y" pattern
    const rangeMatch = valuesText.match(/values\s*:\s*(-?\d+)\s*-\s*(-?\d+)/i);
    if (rangeMatch) {
      const min = parseInt(rangeMatch[1], 10);
      const max = parseInt(rangeMatch[2], 10);
      
      // Store range info in context for later use
      context.currentRangeMin = min;
      context.currentRangeMax = max;
    }
  }

  private handleAnswerOptionLine(fields: string[], context: ParsingContext): void {
    const optionNumber = fields[1];
    const optionText = fields[2] || '';
    
    if (optionNumber && optionText) {
      context.answerOptions.push(`${optionNumber}=${optionText}`);
      context.state = ParsingState.IN_OPTIONS;
    }
  }

  private handleSubVariableLine(columnName: string, fields: string[], context: ParsingContext): void {
    const description = fields[2] || '';
    
    // Create sub-variable using parent's value type
    const subVariable: RawDataMapVariable & { rangeMin?: number; rangeMax?: number } = {
      level: 'sub',
      column: columnName,
      description: description,
      valueType: context.currentValueType || '',
      answerOptions: 'NA',
      parentQuestion: 'NA'  // Will be set correctly in parent inference
    };
    
    // Propagate range info from parent context to sub-variables
    if (context.currentRangeMin !== undefined) {
      subVariable.rangeMin = context.currentRangeMin;
      subVariable.rangeMax = context.currentRangeMax;
    }
    
    context.variables.push(subVariable);
  }

  private extractDescription(bracketLine: string): string {
    // Extract description after the bracket and colon
    const match = bracketLine.match(/\[[^\]]+\]:\s*(.+)/);
    return match ? match[1].trim() : '';
  }

  private finalizeCurrentVariable(context: ParsingContext): void {
    if (context.currentParent && context.currentDescription) {
      const answerOptions = context.answerOptions.length > 0 
        ? context.answerOptions.join(',')
        : 'NA';
      
      const variable: RawDataMapVariable & { rangeMin?: number; rangeMax?: number } = {
        level: 'parent',
        column: context.currentParent,
        description: context.currentDescription,
        valueType: context.currentValueType || '',
        answerOptions: answerOptions,
        parentQuestion: 'NA'  // Will be set correctly in parent inference
      };
      
      // Add range info if available
      if (context.currentRangeMin !== undefined) {
        variable.rangeMin = context.currentRangeMin;
        variable.rangeMax = context.currentRangeMax;
      }
      
      context.variables.push(variable);
    }
  }

  private resetContext(context: ParsingContext): void {
    this.finalizeCurrentVariable(context);
    context.currentParent = null;
    context.currentDescription = null;
    context.currentValueType = null;
    context.answerOptions = [];
    context.state = ParsingState.SCANNING;
    // Clear range info
    context.currentRangeMin = undefined;
    context.currentRangeMax = undefined;
  }

  private parseCSVLine(line: string): string[] {
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

  // ===== STEP 2: PARENT INFERENCE =====

  private addParentRelationships(variables: RawDataMapVariable[]): ProcessedDataMapVariable[] {
    return variables.map(variable => {
      if (variable.level === 'sub') {
        const parentCode = this.inferParentFromSubVariable(variable.column);
        return {
          ...variable,
          parentQuestion: parentCode
        };
      }
      
      // Parent variables have no parent question
      return {
        ...variable,
        parentQuestion: 'NA'
      };
    });
  }

  private inferParentFromSubVariable(subVariableName: string): string {
    // Business rules from parent-inference.ts:
    // - R = Row, C = Column (structural indicators, not part of question ID)
    // - Parent questions are max 3 characters 
    // - Preserve meaningful sub-question letters (a, b, etc.)
    
    let parent = subVariableName;
    
    // Remove structural suffixes (R and C with numbers)
    // Order matters: remove most specific patterns first
    
    // Remove r\d+c\d+ (like r1c2, r2c1)
    parent = parent.replace(/r\d+c\d+$/i, '');
    
    // Remove c\d+ (like c1, c2, c3)
    parent = parent.replace(/c\d+$/i, '');
    
    // Remove r\d+ (like r1, r2, r3)  
    parent = parent.replace(/r\d+$/i, '');
    
    // Apply business rule: Max 3 characters for parent questions
    if (parent.length > 3) {
      parent = parent.substring(0, 3);
    }
    
    // If no change was made or result is too short, return 'NA'
    if (parent === subVariableName || parent.length < 2) {
      return 'NA';
    }
    
    return parent;
  }

  // ===== STEP 3.5: TYPE NORMALIZATION =====

  private normalizeVariableTypes(variables: ProcessedDataMapVariable[]): ProcessedDataMapVariable[] {
    const normalized = variables.map((variable) => {
      const enriched = { ...variable };
      
      // Skip admin fields
      if (this.isAdminField(variable.column)) {
        enriched.normalizedType = 'admin';
        return enriched;
      }
      
      // Check for open text responses
      if (variable.valueType?.toLowerCase().includes('open text') ||
          variable.valueType?.toLowerCase().includes('open numeric')) {
        enriched.normalizedType = 'text_open';
        return enriched;
      }
      
      // Detect binary flags (0/1 Unchecked/Checked)
      if (variable.answerOptions === '0=Unchecked,1=Checked') {
        enriched.normalizedType = 'binary_flag';
        enriched.allowedValues = [0, 1];
        return enriched;
      }
      
      // Check for percentage ranges (0-100)
      if (enriched.rangeMin === 0 && enriched.rangeMax === 100) {
        // Check if it's part of a percentage group (has siblings)
        const parentCode = variable.parentQuestion;
        if (parentCode !== 'NA') {
          const siblings = variables.filter(v => v.parentQuestion === parentCode);
          if (siblings.length > 1) {
            enriched.normalizedType = 'percentage_per_option';
            enriched.rowSumConstraint = true;
          } else {
            enriched.normalizedType = 'numeric_range';
          }
        } else {
          // Check if this parent has sub-items with 0-100 range
          const subs = variables.filter(v => v.parentQuestion === variable.column);
          if (subs.length > 0 && subs.every(s => s.rangeMin === 0 && s.rangeMax === 100)) {
            enriched.normalizedType = 'percentage_per_option';
            enriched.rowSumConstraint = true;
          } else {
            enriched.normalizedType = 'numeric_range';
          }
        }
        return enriched;
      }
      
      // Detect ordinal scales (1-5, 1-4)
      if (enriched.rangeMin === 1 && (enriched.rangeMax === 5 || enriched.rangeMax === 4)) {
        enriched.normalizedType = 'ordinal_scale';
        enriched.allowedValues = [];
        for (let i = enriched.rangeMin; i <= enriched.rangeMax; i++) {
          enriched.allowedValues.push(i);
        }
        
        // Parse scale labels if available
        if (variable.answerOptions && variable.answerOptions !== 'NA') {
          const labels = this.parseScaleLabels(variable.answerOptions);
          if (labels.length > 0) {
            enriched.scaleLabels = labels;
          }
        }
        return enriched;
      }
      
      // Detect matrix single-choice (exactly 2 options)
      if (enriched.rangeMin === 1 && enriched.rangeMax === 2) {
        // Check if parent has exactly 2 labeled options
        const optionParts = variable.answerOptions?.split(',') || [];
        if (optionParts.length === 2 && !optionParts.includes('NA')) {
          enriched.normalizedType = 'matrix_single_choice';
          enriched.allowedValues = [1, 2];
          return enriched;
        }
      }
      
      // Detect numeric ranges
      if (enriched.rangeMin !== undefined && enriched.rangeMax !== undefined) {
        enriched.normalizedType = 'numeric_range';
        enriched.rangeStep = 1; // Default to integer steps
        return enriched;
      }
      
      // Default to categorical select if has answer options
      if (variable.answerOptions && variable.answerOptions !== 'NA') {
        enriched.normalizedType = 'categorical_select';
        
        // Extract allowed values from answer options
        const allowedVals = this.extractAllowedValues(variable.answerOptions);
        if (allowedVals.length > 0) {
          enriched.allowedValues = allowedVals;
        }
        return enriched;
      }
      
      return enriched;
    });
    
    // Second pass: detect dependencies
    return this.detectDependencies(normalized);
  }
  
  private isAdminField(column: string): boolean {
    const col = column.toLowerCase();
    return col === 'record' || col === 'uuid' || col === 'date' || 
           col === 'status' || col.includes('time') || col.includes('_id') ||
           col.startsWith('ims_') || col.startsWith('npi_') || 
           col.includes('captured') || col === 'qtime';
  }
  
  private parseScaleLabels(answerOptions: string): { value: number | string; label: string }[] {
    const labels: { value: number | string; label: string }[] = [];
    const parts = answerOptions.split(',');
    
    for (const part of parts) {
      const match = part.match(/^(\d+)\s*=\s*(.+)$/);
      if (match) {
        labels.push({
          value: parseInt(match[1], 10),
          label: match[2].trim()
        });
      }
    }
    
    return labels;
  }
  
  private extractAllowedValues(answerOptions: string): (number | string)[] {
    const values: (number | string)[] = [];
    const parts = answerOptions.split(',');
    
    for (const part of parts) {
      const match = part.match(/^(\d+)\s*=/);
      if (match) {
        values.push(parseInt(match[1], 10));
      }
    }
    
    return values;
  }
  
  private detectDependencies(variables: ProcessedDataMapVariable[]): ProcessedDataMapVariable[] {
    return variables.map((variable) => {
      const enriched = { ...variable };
      
      // Check for "Of those..." pattern indicating dependency
      if (variable.description?.toLowerCase().includes('of those') ||
          variable.description?.toLowerCase().includes('of these')) {
        // Look for the previous question with similar code pattern
        const currentCode = variable.column.match(/^([A-Z]+)(\d+)/);
        if (currentCode) {
          const prefix = currentCode[1];
          const num = parseInt(currentCode[2], 10);
          
          // Look for previous question (e.g., S11 before S12)
          const prevCode = `${prefix}${num - 1}`;
          const prevVar = variables.find(v => v.column === prevCode);
          
          if (prevVar) {
            enriched.dependentOn = prevCode;
            
            // For numeric ranges, upper bound often equals previous question
            if (enriched.normalizedType === 'numeric_range' && prevVar.normalizedType === 'numeric_range') {
              enriched.dependentRule = `upperBoundEquals(${prevCode})`;
            }
          }
        }
      }
      
      return enriched;
    });
  }

  // ===== STEP 3: CONTEXT ENRICHMENT =====

  private async addContextInformation(variables: ProcessedDataMapVariable[], originalFilePath: string): Promise<ProcessedDataMapVariable[]> {
    // Read the original data map file to search for parent question text
    const fileContent = await fs.readFile(originalFilePath, 'utf-8');
    const lines = fileContent.trim().split('\n');

    // First pass: try to find context using parent question codes
    let processedVariables = variables.map(variable => {
      if (variable.level === 'sub' && variable.parentQuestion !== 'NA') {
        const parentCode = variable.parentQuestion;
        
        // Search through the raw data map for the parent question
        const context = this.findParentQuestionInRawData(lines, parentCode);
        
        if (context) {
          return {
            ...variable,
            context
          };
        }
      }
      
      return variable;
    });

    // Second pass: fallback for sub-questions still missing context
    processedVariables = processedVariables.map(variable => {
      if (variable.level === 'sub' && !variable.context) {
        const context = this.findContextFromColumnName(lines, variable.column);
        
        if (context) {
          return {
            ...variable,
            context
          };
        }
      }
      
      return variable;
    });

    // Third pass: similarity-based fallback for complex multi-dimensional questions
    processedVariables = processedVariables.map(variable => {
      if (variable.level === 'sub' && !variable.context) {
        const context = this.findBestContextMatch(lines, variable.column);
        
        if (context) {
          return {
            ...variable,
            context
          };
        }
      }
      
      return variable;
    });

    return processedVariables;
  }

  private findParentQuestionInRawData(lines: string[], parentCode: string): string | null {
    // Look for parent question text using multiple patterns
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Skip empty lines
      if (!line) continue;
      
      // Pattern 1: Lines starting with quotes and containing parent code with colon
      if (line.startsWith('"') && line.includes(`${parentCode}:`)) {
        const match = line.match(/^"(.+)"(,.*)?$/);
        if (match) {
          return match[1]; // Return the content inside quotes
        }
      }
      
      // Pattern 2: Lines starting with parent code and colon (no quotes)
      if (line.startsWith(`${parentCode}:`)) {
        const match = line.match(/^[^:]+:\s*(.+?)(,,.*)?$/);
        if (match) {
          return `${parentCode}: ${match[1]}`;
        }
      }
      
      // Pattern 3: Lines with bracketed parent code
      if (line.startsWith(`"[${parentCode}]:`)) {
        const match = line.match(/^"\[[^\]]+\]:\s*(.+?)"(,.*)?$/);
        if (match) {
          return `${parentCode}: ${match[1]}`;
        }
      }
    }
    
    return null;
  }

  private findContextFromColumnName(lines: string[], columnName: string): string | null {
    // Extract the base question code by removing suffix after the last 'c'
    const baseCode = this.extractBaseCodeFromColumn(columnName);
    
    if (!baseCode) {
      return null;
    }
    
    // Look for lines that start with the base code followed by a colon
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (!line) continue;
      
      // Look for lines starting with quotes and containing the base code with colon
      if (line.startsWith('"') && line.includes(`${baseCode}:`)) {
        const match = line.match(/^"(.+)"(,.*)?$/);
        if (match) {
          return match[1];
        }
      }
      
      // Also check for lines without quotes but starting with the base code
      if (line.startsWith(`${baseCode}:`)) {
        const match = line.match(/^[^:]+:\s*(.+?)(,,.*)?$/);
        if (match) {
          return `${baseCode}: ${match[1]}`;
        }
      }
    }
    
    return null;
  }

  private extractBaseCodeFromColumn(columnName: string): string | null {
    // Go from right to left, find the first 'c', and remove everything from that 'c' onwards
    for (let i = columnName.length - 1; i >= 0; i--) {
      if (columnName[i].toLowerCase() === 'c') {
        // Check if this 'c' is followed by digits (indicating it's a suffix)
        const afterC = columnName.substring(i + 1);
        if (/^\d+$/.test(afterC)) {
          return columnName.substring(0, i);
        }
      }
    }
    
    // If no 'c' with digits found, return the original column name
    return columnName;
  }

  private findBestContextMatch(lines: string[], columnName: string): string | null {
    // Extract key parts from column name for similarity matching
    const keyParts = this.extractKeyParts(columnName);
    
    if (!keyParts.base || !keyParts.suffix) {
      return null;
    }
    
    // Look for lines containing both the base code and suffix
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (!line) continue;
      
      // Check if line contains both base and suffix (case insensitive)
      const lowerLine = line.toLowerCase();
      const lowerBase = keyParts.base.toLowerCase();
      const lowerSuffix = keyParts.suffix.toLowerCase();
      
      if (lowerLine.includes(lowerBase) && lowerLine.includes(lowerSuffix)) {
        // Extract question text from quoted lines
        if (line.startsWith('"')) {
          const match = line.match(/^"(.+)"(,.*)?$/);
          if (match) {
            return match[1];
          }
        }
        
        // Extract question text from non-quoted lines with colon
        if (line.includes(':')) {
          const match = line.match(/^[^:]+:\s*(.+?)(,,.*)?$/);
          if (match) {
            return match[1];
          }
        }
      }
    }
    
    return null;
  }

  private extractKeyParts(columnName: string): { base: string | null, suffix: string | null } {
    // Extract base and suffix for similarity matching
    const baseMatch = columnName.match(/^([A-Za-z]+\d*)/);
    const base = baseMatch ? baseMatch[1] : null;
    
    const suffixMatch = columnName.match(/(c\d+)$/i);
    const suffix = suffixMatch ? suffixMatch[1] : null;
    
    return { base, suffix };
  }

  // ===== STEP 4: VALIDATION =====

  private async validateProcessedData(variables: ProcessedDataMapVariable[], spssFilePath?: string): Promise<{
    passed: boolean;
    confidence: number;
  }> {
    // Call our separate validator
    const confidence = this.validator.calculateOverallConfidence(variables);
    
    // SPSS validation using provided SPSS file path
    console.log(`[DataMapProcessor] Using SPSS file: ${spssFilePath || 'None provided'}`);
    const spssValidation = await this.validator.validateAgainstSPSS(variables, spssFilePath);
    
    // Combine data map confidence with SPSS validation confidence
    const combinedConfidence = spssValidation.passed 
      ? (confidence + spssValidation.confidence) / 2  // Average if SPSS validation passes
      : confidence * 0.8;  // Reduce confidence if SPSS validation fails
    
    // Use combined confidence for final result  
    const finalPassed = this.validator.meetsConfidenceThreshold(combinedConfidence) && spssValidation.passed;
    
    console.log(`[DataMapProcessor] Validation - Data Map Confidence: ${confidence.toFixed(2)}, SPSS Match: ${spssValidation.confidence.toFixed(2)}, Combined: ${combinedConfidence.toFixed(2)}, Passed: ${finalPassed}`);
    
    if (spssValidation.fullValidation) {
      console.log(`[DataMapProcessor] SPSS Details: ${spssValidation.fullValidation.summary}`);
    }
    
    return { passed: finalPassed, confidence: combinedConfidence };
  }

  // ===== STEP 5: DUAL OUTPUT GENERATION =====

  private generateDualOutputs(variables: ProcessedDataMapVariable[]): {
    verbose: VerboseDataMap[];
    agent: AgentDataMap[];
  } {
    // Generate verbose format with all enrichment fields
    const verbose: VerboseDataMap[] = variables.map(v => ({
      level: v.level,
      parentQuestion: v.parentQuestion,
      column: v.column,
      description: v.description,
      valueType: v.valueType,
      answerOptions: v.answerOptions,
      context: v.context || '',
      confidence: v.confidence,
      // Include enrichment fields
      normalizedType: v.normalizedType,
      rangeMin: v.rangeMin,
      rangeMax: v.rangeMax,
      rangeStep: v.rangeStep,
      allowedValues: v.allowedValues,
      scaleLabels: v.scaleLabels,
      rowSumConstraint: v.rowSumConstraint,
      dependentOn: v.dependentOn,
      dependentRule: v.dependentRule
    }));

    // Generate agent format (simplified for agent processing)
    const agent: AgentDataMap[] = variables.map(v => ({
      Column: v.column,
      Description: v.description,
      Answer_Options: v.answerOptions ?? '',
      ParentQuestion: v.parentQuestion !== 'NA' ? v.parentQuestion : undefined,
      Context: v.context || undefined
    }));

    return { verbose, agent };
  }

  // ===== DEVELOPMENT OUTPUT =====

  private async saveDevelopmentOutputs(outputs: { verbose: VerboseDataMap[]; agent: AgentDataMap[] }, filename: string, outputFolder: string): Promise<void> {
    try {
      const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolder);
      await fs.mkdir(outputDir, { recursive: true });

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const baseName = path.parse(filename).name;

      // Save verbose output
      const verboseFile = path.join(outputDir, `${baseName}-verbose-${timestamp}.json`);
      await fs.writeFile(verboseFile, JSON.stringify(outputs.verbose, null, 2));
      console.log(`[DataMapProcessor] Development output saved: ${baseName}-verbose-${timestamp}.json`);

      // Save agent output  
      const agentFile = path.join(outputDir, `${baseName}-agent-${timestamp}.json`);
      await fs.writeFile(agentFile, JSON.stringify(outputs.agent, null, 2));
      console.log(`[DataMapProcessor] Development output saved: ${baseName}-agent-${timestamp}.json`);

    } catch (error) {
      console.error('[DataMapProcessor] Failed to save development outputs:', error);
    }
  }
}