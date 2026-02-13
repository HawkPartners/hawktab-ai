import { describe, it, expect } from 'vitest';
import { sanitizeRExpression } from '../sanitizeRExpression';

describe('sanitizeRExpression', () => {
  describe('valid expressions', () => {
    const validExpressions = [
      'Q3 == 1',
      'x %in% c(1, 2, 3)',
      'age >= 18 & age <= 65',
      'gender != 2',
      '!is.na(Q5)',
      '"Yes" == label',
      '(A + B) / 2',
      'x > 0 | y < 10',
      "Q1 == 'test'",
      'score * 100',
      'x ^ 2',
      'Q3 %in% c(1,2,3) & Q4 == 1',
    ];

    for (const expr of validExpressions) {
      it(`accepts: ${expr}`, () => {
        const result = sanitizeRExpression(expr);
        expect(result.safe).toBe(true);
        expect(result.error).toBeUndefined();
      });
    }
  });

  describe('empty/whitespace', () => {
    it('rejects empty string', () => {
      const result = sanitizeRExpression('');
      expect(result.safe).toBe(false);
      expect(result.error).toContain('empty');
    });

    it('rejects whitespace-only', () => {
      const result = sanitizeRExpression('   ');
      expect(result.safe).toBe(false);
      expect(result.error).toContain('empty');
    });
  });

  describe('dangerous functions', () => {
    const dangerous = [
      { expr: 'system("rm -rf /")', func: 'system' },
      { expr: 'eval(parse(text="x"))', func: 'eval' },
      { expr: 'source("malicious.R")', func: 'source' },
      { expr: 'library(evil)', func: 'library' },
      { expr: 'file.remove("data.sav")', func: 'file.remove' },
      { expr: 'quit()', func: 'quit' },
      { expr: 'do.call(system, "cmd")', func: 'do.call' },
      { expr: 'require(evil)', func: 'require' },
      { expr: 'unlink("file")', func: 'unlink' },
    ];

    for (const { expr, func } of dangerous) {
      it(`blocks ${func}()`, () => {
        const result = sanitizeRExpression(expr);
        expect(result.safe).toBe(false);
        expect(result.error).toContain('disallowed R function');
        expect(result.error).toContain(func);
      });
    }
  });

  it('catches dangerous functions with extra whitespace', () => {
    const result = sanitizeRExpression('system  (  "cmd"  )');
    expect(result.safe).toBe(false);
    expect(result.error).toContain('system');
  });

  it('catches dangerous functions case-insensitively', () => {
    const result1 = sanitizeRExpression('SYSTEM("cmd")');
    expect(result1.safe).toBe(false);

    const result2 = sanitizeRExpression('System("cmd")');
    expect(result2.safe).toBe(false);
  });

  describe('backtick injection', () => {
    it('catches backtick-quoted function call', () => {
      const result = sanitizeRExpression('`system`("cmd")');
      expect(result.safe).toBe(false);
      expect(result.error).toContain('backtick');
    });

    it('catches eval via backticks', () => {
      const result = sanitizeRExpression('`eval`()');
      expect(result.safe).toBe(false);
      expect(result.error).toContain('backtick');
    });
  });

  describe('shell metacharacters', () => {
    it('catches $(whoami)', () => {
      const result = sanitizeRExpression('$(whoami)');
      expect(result.safe).toBe(false);
      expect(result.error).toContain('shell metacharacters');
    });

    it('catches semicolon injection', () => {
      const result = sanitizeRExpression('Q1 == 1; rm');
      expect(result.safe).toBe(false);
      expect(result.error).toContain('shell metacharacters');
    });
  });

  describe('disallowed characters', () => {
    it('catches @ character', () => {
      const result = sanitizeRExpression('user@domain');
      expect(result.safe).toBe(false);
      expect(result.error).toContain("'@'");
    });

    it('catches # character', () => {
      const result = sanitizeRExpression('Q1 # comment');
      expect(result.safe).toBe(false);
      expect(result.error).toContain("'#'");
    });

    it('catches { character', () => {
      const result = sanitizeRExpression('if (TRUE) { x }');
      expect(result.safe).toBe(false);
      expect(result.error).toContain("'{'");
    });

    it('catches } character', () => {
      const result = sanitizeRExpression('function() }');
      expect(result.safe).toBe(false);
      expect(result.error).toContain("'}'");
    });
  });

  describe('allowed special characters', () => {
    const allowed = [
      { expr: 'x + y - z', desc: 'arithmetic operators' },
      { expr: 'x * y / z', desc: 'multiply/divide' },
      { expr: 'x ^ 2', desc: 'power' },
      { expr: '~formula', desc: 'tilde' },
      { expr: 'Q1[1]', desc: 'brackets' },
      { expr: 'x < y', desc: 'less than' },
      { expr: 'x > y', desc: 'greater than' },
      { expr: 'x >= y', desc: 'greater equal' },
      { expr: 'x <= y', desc: 'less equal' },
      { expr: 'x == y', desc: 'equality' },
      { expr: 'x != y', desc: 'not equal' },
      { expr: 'x & y', desc: 'and' },
      { expr: 'x | y', desc: 'or' },
      { expr: 'x %in% c(1,2)', desc: 'pipe-in operator' },
    ];

    for (const { expr, desc } of allowed) {
      it(`allows ${desc}: ${expr}`, () => {
        const result = sanitizeRExpression(expr);
        expect(result.safe).toBe(true);
      });
    }
  });
});
