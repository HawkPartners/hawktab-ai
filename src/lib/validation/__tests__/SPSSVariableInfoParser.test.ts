import { describe, it, expect } from 'vitest';
import { parseSPSSVariableInfo } from '../SPSSVariableInfoParser';
import fs from 'fs';
import path from 'path';

// Read the real Spravato test file
const spssFilePath = path.join(
  process.cwd(),
  'data/test-data/Spravato_4.23.25/Spravato 4.23.25__Sheet1.csv'
);
const hasRealFile = fs.existsSync(spssFilePath);

describe('SPSSVariableInfoParser', () => {
  describe('with synthetic data', () => {
    it('parses basic variable information', () => {
      const content = `Unnamed: 0,Unnamed: 1
File Information,,
,,
Variable Information,,,,,,,,
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
record,1,record: Record number,Ordinal,Input,7,Right,F7,F7
uuid,2,uuid: Participant identifier,Nominal,Input,16,Left,A16,A16
S1,3,S1: What is your age?,Ordinal,Input,2,Right,F2,F2
Variables in the working file,,,,,,,,
,,
Variable Values,,,,,,,,
Value,,Label,,,,,,
S1,1,18-24,,,,,,
,2,25-34,,,,,,
,3,35-44,,,,,,
`;

      const result = parseSPSSVariableInfo(content);
      expect(result.length).toBe(3);

      // Check record
      expect(result[0].column).toBe('record');
      expect(result[0].description).toBe('Record number');
      expect(result[0].valueType).toBe('Open numeric response');
      expect(result[0].answerOptions).toBe('NA');

      // Check uuid
      expect(result[1].column).toBe('uuid');
      expect(result[1].description).toBe('Participant identifier');
      expect(result[1].valueType).toBe('Open text response');

      // Check S1
      expect(result[2].column).toBe('S1');
      expect(result[2].description).toBe('What is your age?');
      expect(result[2].answerOptions).toBe('1=18-24,2=25-34,3=35-44');
      expect(result[2].valueType).toBe('Values: 1-3');
    });

    it('handles continuation rows in Variable Values', () => {
      const content = `Variable Information,,,,,,,,
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
S4,10,S4: In which state do you live?,Ordinal,Input,2,Right,F2,F2
,,
Variable Values,,,,,,,,
Value,,Label,,,,,,
S4,1,Alaska,,,,,,
,2,Alabama,,,,,,
,3,Arkansas,,,,,,
`;

      const result = parseSPSSVariableInfo(content);
      expect(result.length).toBe(1);
      expect(result[0].answerOptions).toBe('1=Alaska,2=Alabama,3=Arkansas');
    });

    it('handles variables without value labels', () => {
      const content = `Variable Information,,,,,,,,
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
S7,16,S7: How many patients?,Ordinal,Input,19,Right,F19,F19
S8r1,17,S8r1: Practice setting 1,Ordinal,Input,19,Right,F19,F19
,,
Variable Values,,,,,,,,
Value,,Label,,,,,,
`;

      const result = parseSPSSVariableInfo(content);
      expect(result.length).toBe(2);
      expect(result[0].answerOptions).toBe('NA');
      expect(result[0].valueType).toBe('Open numeric response');
    });

    it('handles truncated labels', () => {
      const longLabel = 'S2a: ' + 'x'.repeat(260);
      const content = `Variable Information,,,,,,,,
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
S2a,7,"${longLabel}",Ordinal,Input,1,Right,F1,F1
,,
Variable Values,,,,,,,,
Value,,Label,,,,,,
S2a,1,Yes,,,,,,
,2,No,,,,,,
`;

      const result = parseSPSSVariableInfo(content);
      expect(result.length).toBe(1);
      expect(result[0].description.length).toBeGreaterThan(200);
    });

    it('skips preamble correctly', () => {
      const content = `Unnamed: 0,Unnamed: 1,Unnamed: 2
File Information,,,,,,,,
,,,,,,,,
Notes,,,,,,,,
Output Created,,08-AUG-2025 12:35:06,,,,,,
Comments,,,,,,,,
Input,Data,"C:\\Users\\file.sav",,,,,,
,Active Dataset,DataSet1,,,,,,
,,,,,,,,
Variable Information,,,,,,,,
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
record,1,record: Record number,Ordinal,Input,7,Right,F7,F7
`;

      const result = parseSPSSVariableInfo(content);
      expect(result.length).toBe(1);
      expect(result[0].column).toBe('record');
    });

    it('throws on missing Variable Information section', () => {
      const content = `Some random content
with no sections
`;

      expect(() => parseSPSSVariableInfo(content)).toThrow(
        'Could not find "Variable Information"'
      );
    });

    it('all variables are level=parent', () => {
      const content = `Variable Information,,,,,,,,
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
S1,1,S1: Q1,Ordinal,Input,1,Right,F1,F1
S1r1,2,S1r1: Row 1,Ordinal,Input,1,Right,F1,F1
S1r2,3,S1r2: Row 2,Ordinal,Input,1,Right,F1,F1
`;

      const result = parseSPSSVariableInfo(content);
      // SPSS format doesn't have parent/sub structure — all parsed as 'parent'
      // Parent inference is done later by DataMapProcessor
      expect(result.every((v) => v.level === 'parent')).toBe(true);
    });
  });

  describe.skipIf(!hasRealFile)('with real Spravato file', () => {
    it('parses all variables from Spravato CSV', () => {
      const content = fs.readFileSync(spssFilePath, 'utf-8');
      const result = parseSPSSVariableInfo(content);

      // Spravato has ~565 variables
      expect(result.length).toBeGreaterThan(500);
      expect(result.length).toBeLessThan(700);

      // First variable should be 'record'
      expect(result[0].column).toBe('record');
      expect(result[0].description).toBe('Record number');
    });

    it('correctly parses variable labels', () => {
      const content = fs.readFileSync(spssFilePath, 'utf-8');
      const result = parseSPSSVariableInfo(content);

      // Find S4 (state question)
      const s4 = result.find((v) => v.column === 'S4');
      expect(s4).toBeDefined();
      expect(s4!.description).toContain('state');
    });

    it('correctly parses value labels for S4', () => {
      const content = fs.readFileSync(spssFilePath, 'utf-8');
      const result = parseSPSSVariableInfo(content);

      const s4 = result.find((v) => v.column === 'S4');
      expect(s4).toBeDefined();
      expect(s4!.answerOptions).toContain('Alaska');
      expect(s4!.answerOptions).toContain('Alabama');
    });

    it('handles variables with grid-like names', () => {
      const content = fs.readFileSync(spssFilePath, 'utf-8');
      const result = parseSPSSVariableInfo(content);

      // S8r1 through S8r8 should all be parsed
      const s8Vars = result.filter((v) => v.column.startsWith('S8r'));
      expect(s8Vars.length).toBeGreaterThanOrEqual(8);
    });

    it('handles multi-dimensional variables like S13r1c1', () => {
      const content = fs.readFileSync(spssFilePath, 'utf-8');
      const result = parseSPSSVariableInfo(content);

      const s13Vars = result.filter((v) => v.column.startsWith('S13r'));
      expect(s13Vars.length).toBeGreaterThanOrEqual(12);
    });
  });
});
