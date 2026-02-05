import { describe, it, expect } from 'vitest';
import { detectDataMapFormat } from '../FormatDetector';

describe('FormatDetector', () => {
  describe('Antares format', () => {
    it('detects Leqvio datamap (Antares format)', () => {
      const content = `[record]: Record number,,
Open numeric response,,
,,
[uuid]: Participant identifier,,
Open text response,,
,,
[status]: Participant status,,
Values: 1-4,,
,1,Terminated
,2,Overquota
,3,Qualified
,4,Partial
`;
      const result = detectDataMapFormat(content);
      expect(result.format).toBe('antares');
      expect(result.confidence).toBeGreaterThan(0.5);
    });

    it('detects Titos datamap (Antares format with BOM)', () => {
      const content = `\uFEFF[record]: Record number,,
Open numeric response,,
,,
[uuid]: Participant identifier,,
Open text response,,
,,
[date]: Completion time and date,,
Open text response,,
,,
[markers]: Acquired markers,,
Open text response,,
`;
      const result = detectDataMapFormat(content);
      expect(result.format).toBe('antares');
      expect(result.confidence).toBeGreaterThan(0.5);
    });
  });

  describe('SPSS Variable Info format', () => {
    it('detects Spravato datamap (SPSS Variable Info format)', () => {
      const content = `Unnamed: 0,Unnamed: 1,Unnamed: 2,Unnamed: 3,Unnamed: 4,Unnamed: 5,Unnamed: 6,Unnamed: 7,Unnamed: 8
File Information,,,,,,,,
,,,,,,,,
Notes,,,,,,,,
Output Created,,08-AUG-2025 12:35:06,,,,,,
Comments,,,,,,,,
Input,Data,"C:\\Users\\LauraHoff\\file.sav",,,,,,
,,,,,,,,
Variable Information,,,,,,,,
Variable,Position,Label,Measurement Level,Role,Column Width,Alignment,Print Format,Write Format
record,1,record: Record number,Ordinal,Input,7,Right,F7,F7
uuid,2,uuid: Participant identifier,Nominal,Input,16,Left,A16,A16
`;
      const result = detectDataMapFormat(content);
      expect(result.format).toBe('spss_variable_info');
      expect(result.confidence).toBeGreaterThan(0.7);
    });
  });

  describe('SPSS Values Only format', () => {
    it('detects SPSS values-only format', () => {
      const content = `Some header info
,,
Variable Values,,,,
Value,,Label,,
status,1,Terminated,,
,2,Overquota,,
,3,Qualified,,
S2a,1,Yes,,
,2,No,,
`;
      const result = detectDataMapFormat(content);
      expect(result.format).toBe('spss_values_only');
      expect(result.confidence).toBeGreaterThan(0.4);
    });
  });

  describe('Unknown format', () => {
    it('returns unknown for unrecognized content', () => {
      const content = `col1,col2,col3
a,b,c
d,e,f
`;
      const result = detectDataMapFormat(content);
      expect(result.format).toBe('unknown');
      expect(result.confidence).toBe(0);
    });

    it('returns unknown for empty content', () => {
      const result = detectDataMapFormat('');
      expect(result.format).toBe('unknown');
      expect(result.confidence).toBe(0);
    });
  });

  describe('signals', () => {
    it('reports detection signals', () => {
      const content = `[record]: Record number,,
Open numeric response,,
[uuid]: Participant identifier,,
Open text response,,
`;
      const result = detectDataMapFormat(content);
      expect(result.signals.length).toBeGreaterThan(0);
      expect(result.signals.some(s => s.includes('Antares'))).toBe(true);
    });
  });
});
