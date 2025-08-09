import type { VerboseDataMapType } from '@/schemas/processingSchemas';

export type TableLevel = { value: number | string; label: string };

export type TableDefinition = {
  id: string;
  title: string;
  questionVar: string;
  tableType: 'single';
  levels?: TableLevel[];
};

export type TablePlan = {
  tables: TableDefinition[];
};

function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function isAdminField(name: string): boolean {
  const n = name.toLowerCase();
  return (
    n.includes('record') ||
    n === 'uuid' ||
    n.endsWith('_id') ||
    n === 'id' ||
    n.includes('start') ||
    n.includes('end') ||
    n.includes('date') ||
    n.includes('time')
  );
}

export function parseAnswerOptions(options: string): TableLevel[] | undefined {
  if (!options || !options.trim()) return undefined;
  // Accept multiple separators: comma, semicolon, pipe, or newline
  const parts = options
    .split(/[,;|\n]+/)
    .map((p) => p.trim())
    .filter(Boolean);
  const levels: TableLevel[] = [];
  for (const part of parts) {
    // Accept '=', ':', or ' - ' as delimiters between value and label
    const match = part.match(/^([^=:]+)\s*(?:=|:|\s-\s)\s*(.+)$/);
    if (!match) continue;
    const rawValue = match[1];
    const label = match[2];
    const num = Number(rawValue.trim());
    const value: number | string = Number.isFinite(num) ? num : rawValue.trim();
    if (String(label).length === 0) continue;
    levels.push({ value, label });
  }
  if (levels.length === 0) return undefined;
  return levels;
}

function synthesizeLevelsFromRange(valueType: string | undefined): TableLevel[] | undefined {
  if (!valueType) return undefined;
  const m = valueType.match(/values\s*:\s*(\d+)\s*-\s*(\d+)/i);
  if (!m) return undefined;
  const start = Number(m[1]);
  const end = Number(m[2]);
  if (!Number.isFinite(start) || !Number.isFinite(end)) return undefined;
  const size = Math.abs(end - start) + 1;
  if (size <= 0 || size > 12) return undefined; // guard for MVP
  const levels: TableLevel[] = [];
  const step = start <= end ? 1 : -1;
  for (let v = start; step > 0 ? v <= end : v >= end; v += step) {
    levels.push({ value: v, label: String(v) });
  }
  return levels;
}

export function buildTablePlanFromDataMap(dataMap: VerboseDataMapType[]): TablePlan {
  const tables: TableDefinition[] = [];

  // Parent-first, then subs not covered
  const parents = dataMap.filter((it) => (it.level || '').toLowerCase() === 'parent');
  const subs = dataMap.filter((it) => (it.level || '').toLowerCase() === 'sub');

  const considerParent = (item: VerboseDataMapType) => {
    const varName: string = item.column;
    if (isAdminField(varName)) return;
    let levels = parseAnswerOptions(item.answerOptions || '');
    if (!levels) levels = synthesizeLevelsFromRange(item.valueType);
    if (!levels) return;
    if (levels.length > 30) return; // MVP cap

    tables.push({
      id: slugify(varName),
      title: item.description || varName,
      questionVar: varName,
      tableType: 'single',
      levels,
    });
  };

  for (const item of parents) considerParent(item);

  // Sub rows: if binary value range, emit standalone tables using parent context for title
  for (const item of subs) {
    const varName: string = item.column;
    if (isAdminField(varName)) continue;
    let levels = parseAnswerOptions(item.answerOptions || '');
    if (!levels) levels = synthesizeLevelsFromRange(item.valueType);
    // Only include subs if we have binary levels or explicit options
    if (!levels || levels.length === 0) continue;
    if (levels.length > 2 && !item.parentQuestion) continue;
    const title = item.context || item.description || varName;
    tables.push({
      id: slugify(varName),
      title,
      questionVar: varName,
      tableType: 'single',
      levels,
    });
  }

  return { tables };
}


