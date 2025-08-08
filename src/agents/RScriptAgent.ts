/**
 * RScriptAgent
 * Purpose: Build a single-file R script from validation or cut-tables and summarize issues
 * Reads: temp-outputs/<sessionId>/{cut-tables.json|crosstab-output-*.json, dataMap-agent*.json}
 * Writes: returned to caller; API persists to {r-script.R, r-validation.json}
 * Invariants: expressions are R-ready; unknown variables detected via data map names
 */
import { promises as fs } from 'fs';
import * as path from 'path';
import { z } from 'zod';
import { withTrace, getGlobalTraceProvider } from '@openai/agents';
import type { ValidationResultType } from '@/schemas/agentOutputSchema';
import { DataMapSchema, type DataMapType, getVariableNames } from '@/schemas/dataMapSchema';
import { validateRSyntax } from '@/guardrails/outputValidation';

const RScriptIssueSchema = z.object({
  groupName: z.string(),
  name: z.string(),
  problems: z.array(z.string()),
});

const RScriptOutputSchema = z.object({
  script: z.string(),
  issues: z.array(RScriptIssueSchema),
  stats: z.object({
    groups: z.number(),
    columns: z.number(),
    syntaxIssues: z.number(),
    unknownVars: z.number(),
  }),
});

export type RScriptIssue = z.infer<typeof RScriptIssueSchema>;
export type RScriptOutput = z.infer<typeof RScriptOutputSchema>;

function extractUnknownVariables(expression: string, knownVars: Set<string>): string[] {
  const keywords = new Set<string>([
    'if', 'else', 'repeat', 'while', 'function', 'for', 'in', 'next', 'break',
    'TRUE', 'FALSE', 'NA', 'NULL', 'Inf', 'NaN', 'c', 'data', 'read_sav', 'library',
  ]);

  const tokens = expression.match(/[A-Za-z][A-Za-z0-9_]*/g) || [];
  const unknown: string[] = [];
  for (const t of tokens) {
    if (keywords.has(t)) continue;
    if (t.length <= 1) continue;
    if (!knownVars.has(t)) {
      // Avoid duplicates in a single expression
      if (!unknown.includes(t)) unknown.push(t);
    }
  }
  return unknown;
}

function buildRScript(sessionId: string, validation: ValidationResultType): { script: string; columns: number; groups: number } {
  const header = [
    '# HawkTab AI — Generated R Script',
    `# Session: ${sessionId}`,
    `# Generated: ${new Date().toISOString()}`,
    '',
    'library(haven)',
    `data <- read_sav('temp-outputs/${sessionId}/dataFile.sav')`,
    '',
  ];

  const lines: string[] = [...header];
  let columnCount = 0;
  for (const group of validation.bannerCuts) {
    lines.push('', `# ===== Group: ${group.groupName} =====`);
    for (const col of group.columns) {
      lines.push(`# ${col.name} | conf=${col.confidence.toFixed(3)} | ${col.reason.replace(/\r?\n/g, ' ')}`);
      lines.push(col.adjusted);
      columnCount += 1;
    }
  }

  return { script: lines.join('\n'), columns: columnCount, groups: validation.bannerCuts.length };
}

async function loadValidationOrCutTable(sessionDir: string): Promise<ValidationResultType> {
  // Prefer cut-tables.json if present for convenience
  const cutTablePath = path.join(sessionDir, 'cut-tables.json');
  try {
    const cutContent = await fs.readFile(cutTablePath, 'utf-8');
    const parsed = JSON.parse(cutContent) as {
      groups: Array<{ groupName: string; columns: Array<{ name: string; expression: string; confidence: number; reason: string }> }>; 
    };
    return {
      bannerCuts: parsed.groups.map((g) => ({
        groupName: g.groupName,
        columns: g.columns.map((c) => ({
          name: c.name,
          adjusted: c.expression,
          confidence: c.confidence,
          reason: c.reason,
        })),
      })),
    };
  } catch {}

  // Fallback to crosstab-output-*.json
  const files = await fs.readdir(sessionDir);
  const crosstab = files.find((f) => f.includes('crosstab-output') && f.endsWith('.json'));
  if (!crosstab) throw new Error('No crosstab output found');
  const content = await fs.readFile(path.join(sessionDir, crosstab), 'utf-8');
  return JSON.parse(content) as ValidationResultType;
}

async function loadAgentDataMap(sessionDir: string): Promise<DataMapType> {
  const files = await fs.readdir(sessionDir);
  const dataMapFile = files.find((f) => f.includes('dataMap-agent') && f.endsWith('.json'));
  if (!dataMapFile) throw new Error('Agent data map not found');
  const content = await fs.readFile(path.join(sessionDir, dataMapFile), 'utf-8');
  const parsed = JSON.parse(content);
  return DataMapSchema.parse(parsed);
}

export class RScriptAgent {
  async generate(sessionId: string): Promise<RScriptOutput> {
    const sessionDir = path.join(process.cwd(), 'temp-outputs', sessionId);

    const result = await withTrace(`R Script Generation - ${sessionId}`, async () => {
      const validation = await loadValidationOrCutTable(sessionDir);
      const dataMap = await loadAgentDataMap(sessionDir);
      const known = new Set(getVariableNames(dataMap));

      const { script, columns, groups } = buildRScript(sessionId, validation);

      const issues: RScriptIssue[] = [];
      let syntaxIssues = 0;
      let unknownVars = 0;

      for (const group of validation.bannerCuts) {
        for (const col of group.columns) {
          const problems: string[] = [];
          const syntax = validateRSyntax(col.adjusted);
          if (!syntax.valid) {
            syntaxIssues += 1;
            problems.push(...syntax.issues);
          }
          const unknown = extractUnknownVariables(col.adjusted, known);
          if (unknown.length > 0) {
            unknownVars += unknown.length;
            problems.push(`Unknown variables: ${unknown.join(', ')}`);
          }
          if (problems.length > 0) {
            issues.push({ groupName: group.groupName, name: col.name, problems });
          }
        }
      }

      const output: RScriptOutput = {
        script,
        issues,
        stats: {
          groups,
          columns,
          syntaxIssues,
          unknownVars,
        },
      };

      return RScriptOutputSchema.parse(output);
    });

    try {
      await getGlobalTraceProvider().forceFlush();
    } catch {
      // ignore trace flush errors
    }

    return result;
  }
}


