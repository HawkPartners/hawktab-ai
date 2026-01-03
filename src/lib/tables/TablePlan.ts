import type { VerboseDataMapType } from '@/schemas/processingSchemas';

export type TableLevel = { value: number | string; label: string };

export type NumericMetrics = {
  mean: boolean;
  median: boolean;
  sd: boolean;
};

export type BucketSpec = {
  count: number;
  edges?: number[];  // Optional explicit bucket edges
};

export type SingleTableDefinition = {
  id: string;
  title: string;
  questionVar: string;
  tableType: 'single';
  levels?: TableLevel[];
  // Enhanced metadata from normalized typing
  normalizedType?: string;
  numericMetrics?: NumericMetrics;
  bucketSpec?: BucketSpec;
  rangeMin?: number;
  rangeMax?: number;
  scaleLabels?: { value: number | string; label: string }[];
  allowedValues?: (number | string)[];
};

export type MultiSubItem = {
  var: string;
  label: string;
  positiveValue: number | string;
  normalizedType?: string;
  allowedValues?: (number | string)[];
  // Base filter variable for follow-up questions
  // e.g., A3ar1 (Leqvio statin split) should filter on A3r2 > 0 (Leqvio prescribers)
  baseFilterVar?: string;
};

export type MultiSubTableDefinition = {
  id: string;
  title: string;
  questionVar: string;
  tableType: 'multi_subs';
  items: MultiSubItem[];
  // Enhanced metadata from normalized typing
  normalizedType?: string;
  rowSumConstraint?: boolean;
  // Bug 3 Fix: For categorical sub-questions with multiple values, track which value this table represents
  targetValue?: number | string;
};

export type TableDefinition = SingleTableDefinition | MultiSubTableDefinition;

export type TablePlan = {
  tables: TableDefinition[];
};

function slugify(input: string): string {
  // Use underscores instead of hyphens - hyphens break R variable names
  // (R interprets table_a1-value-1 as table_a1 minus value minus 1)
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
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

  // Helper: infer positive value for a sub item (now enhanced with normalized typing)
  const inferPositiveValue = (item: VerboseDataMapType): number | string => {
    // Use normalized type if available
    if (item.normalizedType === 'binary_flag') {
      return 1; // For binary flags, 1 is positive
    }
    
    if (item.normalizedType === 'matrix_single_choice' && item.allowedValues) {
      // For matrix questions, look for positive labels
      const levels = item.scaleLabels || parseAnswerOptions(item.answerOptions || '');
      if (levels && levels.length === 2) {
        const positiveLabels = ['yes', 'selected', 'agree', 'true', 'positive', 'satisfied'];
        const match = levels.find((lv) =>
          positiveLabels.some((p) => String(lv.label).toLowerCase().includes(p))
        );
        if (match) return match.value;
      }
      return item.allowedValues[0]; // Default to first allowed value
    }
    
    // Fallback to original heuristics
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
    if (item.normalizedType === 'admin') continue; // Skip admin fields based on normalized type
    if (parentsToSkip.has(varName)) continue; // prefer grouped subs
    
    // Use normalized typing to determine table handling
    let levels = item.scaleLabels || parseAnswerOptions(item.answerOptions || '');
    let numericMetrics: NumericMetrics | undefined;
    let bucketSpec: BucketSpec | undefined;
    
    // Handle based on normalized type
    if (item.normalizedType === 'numeric_range') {
      // For numeric ranges, don't use explicit levels, use metrics and buckets
      levels = undefined;
      numericMetrics = { mean: true, median: true, sd: true };
      // Default to 10 buckets, can be refined later
      bucketSpec = { count: 10 };
    } else if (item.normalizedType === 'percentage_per_option') {
      // For percentages, include metrics
      numericMetrics = { mean: true, median: true, sd: true };
    } else if (item.normalizedType === 'ordinal_scale') {
      // Use scale labels if available
      if (item.scaleLabels) {
        levels = item.scaleLabels;
      }
    } else if (!levels) {
      // Fallback to range synthesis
      levels = synthesizeLevelsFromRange(item.valueType);
    }
    
    // If levels are very large, drop explicit levels but still include table (let R infer from data)
    if (levels && levels.length > 30) {
      levels = undefined;
      bucketSpec = { count: 10 }; // Use buckets for large level sets
    }
    
    // Skip if no levels and not a numeric type
    if (!levels && !item.normalizedType?.includes('numeric') && !item.normalizedType?.includes('percentage') && !isNumericRange(item.valueType)) {
      continue;
    }
    
    tables.push({
      id: slugify(varName),
      title: item.description || varName,
      questionVar: varName,
      tableType: 'single',
      levels,
      normalizedType: item.normalizedType,
      numericMetrics,
      bucketSpec,
      rangeMin: item.rangeMin,
      rangeMax: item.rangeMax,
      scaleLabels: item.scaleLabels,
      allowedValues: item.allowedValues,
    });
  }

  // Grouped sub tables (multi_subs)
  // Bug 4 Fix: Detect column-structured variables (r#c# pattern) and group by row instead of parent
  const columnVarPattern = /^(.+r\d+)(c\d+)$/i;

  for (const [parentQ, groupItems] of subGroups) {
    // Filter out admin/meta sub variables (using both old and new methods)
    const validSubs = groupItems.filter((it) =>
      !isAdminField(it.column) && it.normalizedType !== 'admin'
    );
    if (validSubs.length === 0) continue;

    // Check if ANY item matches column pattern (r#c# structure)
    const hasColumnStructure = validSubs.some(item =>
      columnVarPattern.test(item.column)
    );

    if (hasColumnStructure) {
      // Bug 4: Regroup by ROW (e.g., A3ar1, A3ar2, A3ar3) instead of by parent (A3a)
      const rowGroups = new Map<string, VerboseDataMapType[]>();

      for (const item of validSubs) {
        const match = item.column.match(columnVarPattern);
        if (match) {
          const rowKey = match[1]; // "A3ar1", "A3ar2", etc.
          if (!rowGroups.has(rowKey)) rowGroups.set(rowKey, []);
          rowGroups.get(rowKey)!.push(item);
        } else {
          // Non-matching items go to a default group (shouldn't happen if data is consistent)
          const defaultKey = `${parentQ}_other`;
          if (!rowGroups.has(defaultKey)) rowGroups.set(defaultKey, []);
          rowGroups.get(defaultKey)!.push(item);
        }
      }

      // Create separate table for each row group
      for (const [rowKey, rowItems] of rowGroups) {
        // Use first item's context for title (all items in row share context)
        // Context contains treatment name like "A3ar1: Leqvio (inclisiran) - For each treatment..."
        const title = rowItems[0].context || rowKey;

        // Determine group normalized type from row items
        let groupNormalizedType: string | undefined;
        let rowSumConstraint: boolean | undefined;

        const subTypes = new Set(rowItems.map(s => s.normalizedType));
        if (subTypes.size === 1) {
          groupNormalizedType = rowItems[0].normalizedType;
        }

        if (rowItems.some(s => s.rowSumConstraint)) {
          rowSumConstraint = true;
        }

        // Detect follow-up pattern: A3ar1 → base filter A3r2, A3ar2 → base filter A3r3, etc.
        // Pattern: {prefix}a{r#} follows {prefix}{r#+1}
        // This is because r1 is typically "none/other" which doesn't have a follow-up
        let baseFilterVar: string | undefined;
        const followUpPattern = rowKey.match(/^(.+)ar(\d+)$/i);
        if (followUpPattern) {
          const prefix = followUpPattern[1]; // "A3"
          const rowNum = parseInt(followUpPattern[2], 10); // 1
          // Follow-up row N corresponds to parent row N+1 (because r1 is "statin only"/no follow-up)
          baseFilterVar = `${prefix}r${rowNum + 1}`; // "A3r2"
        }

        // Detect second-level follow-up pattern: A3br1 → base filter A3ar1c2, A3br2 → base filter A3ar2c2, etc.
        // Pattern: {prefix}br{rowNum} asks about patients from {prefix}ar{rowNum}c2 (those WITHOUT statin)
        // A3b asks "for those who received therapy WITHOUT a statin..." so base is A3a's "without statin" column
        const secondFollowUpPattern = rowKey.match(/^(.+)br(\d+)$/i);
        if (secondFollowUpPattern) {
          const prefix = secondFollowUpPattern[1]; // "A3"
          const rowNum = parseInt(secondFollowUpPattern[2], 10); // 1
          // A3br1 asks about Leqvio patients WITHOUT statin → filter on A3ar1c2 > 0
          baseFilterVar = `${prefix}ar${rowNum}c2`; // "A3ar1c2"
        }

        const items = rowItems.map<MultiSubItem>((sub) => ({
          var: sub.column,
          label: sub.description || sub.column,
          positiveValue: inferPositiveValue(sub),
          normalizedType: sub.normalizedType,
          allowedValues: sub.allowedValues,
          baseFilterVar, // All items in this row share the same base filter
        }));

        tables.push({
          id: slugify(rowKey),
          title,
          questionVar: rowKey,
          tableType: 'multi_subs',
          items,
          normalizedType: groupNormalizedType,
          rowSumConstraint,
        });
      }
    } else {
      // Default behavior: group by parentQuestion (no column structure)
      const parentMeta = parents.find((p) => (p.column || '').trim() === parentQ);
      const baseTitle =
        (validSubs.find((s) => (s.context || '').trim())?.context || '').trim() ||
        (parentMeta?.description || '').trim() ||
        parentQ;

      // Determine group normalized type from subs
      let groupNormalizedType: string | undefined;
      let rowSumConstraint: boolean | undefined;

      // Check if all subs have the same normalized type
      const subTypes = new Set(validSubs.map(s => s.normalizedType));
      if (subTypes.size === 1) {
        groupNormalizedType = validSubs[0].normalizedType;
      }

      // Check for row sum constraint (percentage distributions)
      if (validSubs.some(s => s.rowSumConstraint)) {
        rowSumConstraint = true;
      }

      // Bug 3 Fix: Check if we need separate tables per allowedValue
      // Conditions: categorical_select with multiple values (not binary_flag)
      const needsValueSplit =
        groupNormalizedType === 'categorical_select' &&
        validSubs[0].allowedValues &&
        validSubs[0].allowedValues.length > 1 &&
        // Exclude binary 0/1 cases (already handled by positiveValue logic)
        !(validSubs[0].allowedValues.length === 2 &&
          validSubs[0].allowedValues.includes(0) &&
          validSubs[0].allowedValues.includes(1));

      if (needsValueSplit && validSubs[0].allowedValues) {
        // Create separate table for each allowedValue
        const allowedValues = validSubs[0].allowedValues;

        // Try to get labels for values from scaleLabels
        const scaleLabels = validSubs[0].scaleLabels || parseAnswerOptions(validSubs[0].answerOptions || '');
        const getValueLabel = (val: number | string): string => {
          if (scaleLabels) {
            const match = scaleLabels.find(sl => sl.value === val || String(sl.value) === String(val));
            if (match) return match.label;
          }
          return String(val);
        };

        for (const targetVal of allowedValues) {
          const valueLabel = getValueLabel(targetVal);
          const title = `${baseTitle} - ${valueLabel}`;

          const items = validSubs.map<MultiSubItem>((sub) => ({
            var: sub.column,
            label: sub.description || sub.column,
            positiveValue: targetVal, // Use the target value for this table
            normalizedType: sub.normalizedType,
            allowedValues: sub.allowedValues,
          }));

          tables.push({
            id: slugify(`${parentQ}-value-${targetVal}`),
            title,
            questionVar: parentQ,
            tableType: 'multi_subs',
            items,
            normalizedType: groupNormalizedType,
            rowSumConstraint,
            targetValue: targetVal,
          });
        }
      } else {
        // Standard single table for this group
        const items = validSubs.map<MultiSubItem>((sub) => ({
          var: sub.column,
          label: sub.description || sub.column,
          positiveValue: inferPositiveValue(sub),
          normalizedType: sub.normalizedType,
          allowedValues: sub.allowedValues,
        }));

        tables.push({
          id: slugify(parentQ),
          title: baseTitle,
          questionVar: parentQ,
          tableType: 'multi_subs',
          items,
          normalizedType: groupNormalizedType,
          rowSumConstraint,
        });
      }
    }
  }

  return { tables };
}


