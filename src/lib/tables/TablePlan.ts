import type { VerboseDataMapType } from '@/schemas/processingSchemas';

export type TableLevel = { value: number | string; label: string };

export type SingleTableDefinition = {
  id: string;
  title: string;
  questionVar: string;
  tableType: 'single';
  levels?: TableLevel[];
};

export type MultiSubItem = { var: string; label: string; positiveValue: number | string };

export type MultiSubTableDefinition = {
  id: string;
  title: string;
  questionVar: string;
  tableType: 'multi_subs';
  items: MultiSubItem[];
};

export type TableDefinition = SingleTableDefinition | MultiSubTableDefinition;

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

function isNumericRange(valueType: string | undefined): boolean {
  if (!valueType) return false;
  return /values\s*:\s*\d+\s*-\s*\d+/i.test(valueType);
}

export function buildTablePlanFromDataMap(dataMap: VerboseDataMapType[]): TablePlan {
  const tables: TableDefinition[] = [];

  // Normalize
  const parents = dataMap.filter((it) => (it.level || '').toLowerCase() === 'parent');
  const subs = dataMap.filter((it) => (it.level || '').toLowerCase() === 'sub');

  // Group sub rows by parentQuestion
  const subGroups = new Map<string, VerboseDataMapType[]>();
  for (const sub of subs) {
    const parent = (sub.parentQuestion || '').trim();
    if (!parent || parent.toUpperCase() === 'NA') continue;
    if (!subGroups.has(parent)) subGroups.set(parent, []);
    subGroups.get(parent)!.push(sub);
  }

  // Helper: infer positive value for a sub item
  const inferPositiveValue = (item: VerboseDataMapType): number | string => {
    // Value type heuristics
    const vt = item.valueType || '';
    if (/values\s*:\s*0\s*-\s*1/i.test(vt)) return 1;
    if (/values\s*:\s*1\s*-\s*2/i.test(vt)) return 1;
    // Try from explicit options
    const levels = parseAnswerOptions(item.answerOptions || '');
    if (levels && levels.length === 2) {
      const positiveLabels = ['yes', 'selected', 'agree', 'true', 'positive', 'satisfied'];
      const match = levels.find((lv) =>
        positiveLabels.some((p) => String(lv.label).toLowerCase().includes(p))
      );
      if (match) return match.value;
      // fallback to value 1 if present
      const one = levels.find((lv) => lv.value === 1 || String(lv.value) === '1');
      if (one) return one.value;
    }
    return 1; // safe default
  };

  // Prefer grouped sub tables over parent single when both exist
  const parentsToSkip = new Set<string>();
  for (const [parentQ, groupItems] of subGroups) {
    if (groupItems.length > 0) parentsToSkip.add(parentQ);
  }

  // Parent tables first
  for (const item of parents) {
    const varName: string = item.column;
    if (isAdminField(varName)) continue;
    if (parentsToSkip.has(varName)) continue; // prefer grouped subs
    let levels = parseAnswerOptions(item.answerOptions || '');
    if (!levels) levels = synthesizeLevelsFromRange(item.valueType);
    // If levels are very large, drop explicit levels but still include table (let R infer from data)
    if (levels && levels.length > 30) levels = undefined;
    // If we still have no levels but valueType indicates a numeric range (possibly large), include the table without levels
    if (!levels && !isNumericRange(item.valueType)) continue;
    tables.push({
      id: slugify(varName),
      title: item.description || varName,
      questionVar: varName,
      tableType: 'single',
      levels,
    });
  }

  // Grouped sub tables (multi_subs)
  for (const [parentQ, groupItems] of subGroups) {
    // Filter out admin/meta sub variables
    const validSubs = groupItems.filter((it) => !isAdminField(it.column));
    if (validSubs.length === 0) continue;
    // Title preference: any non-empty context from subs; fallback to parent description; fallback to parentQ
    const parentMeta = parents.find((p) => (p.column || '').trim() === parentQ);
    const title =
      (validSubs.find((s) => (s.context || '').trim())?.context || '').trim() ||
      (parentMeta?.description || '').trim() ||
      parentQ;
    const items = validSubs.map<MultiSubItem>((sub) => ({
      var: sub.column,
      label: sub.description || sub.column,
      positiveValue: inferPositiveValue(sub),
    }));
    tables.push({
      id: slugify(parentQ),
      title,
      questionVar: parentQ,
      tableType: 'multi_subs',
      items,
    });
  }

  return { tables };
}


