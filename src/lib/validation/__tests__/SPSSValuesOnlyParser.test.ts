import { describe, it, expect } from 'vitest';
import { parseSPSSValuesOnly } from '../SPSSValuesOnlyParser';
import fs from 'fs';
import path from 'path';

describe('SPSSValuesOnlyParser', () => {
  describe('with synthetic data', () => {
    it('parses basic variable values', () => {
      const content = `Variable Values,Unnamed: 1,Unnamed: 2
Value,,Label
status,1.0,Terminated
,2.0,Overquota
,3.0,Qualified
S1,1.0,Yes
,2.0,No
`;

      const result = parseSPSSValuesOnly(content);
      expect(result.length).toBe(2);

      expect(result[0].column).toBe('status');
      expect(result[0].answerOptions).toBe('1.0=Terminated,2.0=Overquota,3.0=Qualified');
      expect(result[0].level).toBe('parent');

      expect(result[1].column).toBe('S1');
      expect(result[1].answerOptions).toBe('1.0=Yes,2.0=No');
      expect(result[1].level).toBe('parent');
    });

    it('infers level from structural suffixes', () => {
      const content = `Variable Values,,
Value,,Label
S3r1,0.0,NO TO: Asthma
,1.0,Asthma
S3r2,0.0,NO TO: Diabetes
,1.0,Diabetes
S7r1c1,0.0,No
,1.0,Yes
`;

      const result = parseSPSSValuesOnly(content);
      expect(result.length).toBe(3);

      expect(result[0].column).toBe('S3r1');
      expect(result[0].level).toBe('sub');

      expect(result[1].column).toBe('S3r2');
      expect(result[1].level).toBe('sub');

      expect(result[2].column).toBe('S7r1c1');
      expect(result[2].level).toBe('sub');
    });

    it('has empty descriptions (not available in this format)', () => {
      const content = `Variable Values,,
Value,,Label
S4,1.0,Male
,2.0,Female
`;

      const result = parseSPSSValuesOnly(content);
      expect(result[0].description).toBe('');
    });

    it('infers value type from labels', () => {
      const content = `Variable Values,,
Value,,Label
S1,1.0,Yes
,2.0,No
F7,1.0,Alabama
,2.0,Alaska
,51.0,Wyoming
`;

      const result = parseSPSSValuesOnly(content);

      expect(result[0].valueType).toBe('Values: 1-2');
      expect(result[1].valueType).toBe('Values: 1-51');
    });

    it('throws on missing Variable Values section', () => {
      const content = `Some random content
with no sections
`;

      expect(() => parseSPSSValuesOnly(content)).toThrow(
        'Could not find "Variable Values"'
      );
    });
  });

  // Real file tests
  const ucbW5Path = path.join(
    process.cwd(),
    'data/test-data/UCB-Caregiver-ATU-W5-Data_1.7.25/UCB Caregiver ATU W5 Data 1.7.25__Sheet1.csv'
  );
  const hasRealFile = fs.existsSync(ucbW5Path);

  describe.skipIf(!hasRealFile)('with real UCB W5 file', () => {
    it('parses all coded variables', () => {
      const content = fs.readFileSync(ucbW5Path, 'utf-8');
      const result = parseSPSSValuesOnly(content);

      // Should have several hundred coded variables
      expect(result.length).toBeGreaterThan(500);

      // First variable should be status
      expect(result[0].column).toBe('status');
    });

    it('detects sub-variables correctly', () => {
      const content = fs.readFileSync(ucbW5Path, 'utf-8');
      const result = parseSPSSValuesOnly(content);

      // S3r1 should be a sub-variable
      const s3r1 = result.find((v) => v.column === 'S3r1');
      expect(s3r1).toBeDefined();
      expect(s3r1!.level).toBe('sub');
      expect(s3r1!.answerOptions).toContain('Asthma');
    });
  });
});
