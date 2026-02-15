/**
 * TablePostProcessor
 *
 * Deterministic post-pass that enforces formatting rules after VerificationAgent.
 * Runs once, after all parallel agent instances finish, ensuring consistency
 * that prompt-only guidance cannot guarantee across concurrent calls.
 *
 * Design principles:
 * - Auto-fix formatting issues (severity: 'fix')
 * - Warn only on semantic issues needing human judgment (severity: 'warn')
 * - Never make semantic decisions (no label changes, no exclusions, no NET creation)
 */

import type { ExtendedTableDefinition } from '../../schemas/verificationAgentSchema';

// ─── Types ───────────────────────────────────────────────────────────────────

export interface PostPassAction {
  tableId: string;
  rule: string;
  severity: 'fix' | 'warn';
  detail: string;
}

export interface PostPassResult {
  tables: ExtendedTableDefinition[];
  actions: PostPassAction[];
  stats: {
    tablesProcessed: number;
    totalFixes: number;
    totalWarnings: number;
  };
}

// ─── Individual Rules ────────────────────────────────────────────────────────

/**
 * Rule 1: Replace undefined/null with safe defaults for Azure OpenAI compatibility.
 */
function normalizeEmptyFields(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  let fixed = false;

  // Table-level fields
  const stringFields = [
    'tableId', 'questionId', 'questionText', 'sourceTableId',
    'excludeReason', 'surveySection', 'baseText', 'userNote',
    'tableSubtitle', 'additionalFilter', 'splitFromTableId',
  ] as const;

  const tableCopy = { ...table };

  for (const field of stringFields) {
    if (tableCopy[field] === undefined || tableCopy[field] === null) {
      (tableCopy as Record<string, unknown>)[field] = '';
      fixed = true;
    }
  }

  // Row-level fields
  const rows = tableCopy.rows.map(row => {
    const rowCopy = { ...row };
    if (rowCopy.variable === undefined || rowCopy.variable === null) { (rowCopy as Record<string, unknown>).variable = ''; fixed = true; }
    if (rowCopy.label === undefined || rowCopy.label === null) { (rowCopy as Record<string, unknown>).label = ''; fixed = true; }
    if (rowCopy.filterValue === undefined || rowCopy.filterValue === null) { (rowCopy as Record<string, unknown>).filterValue = ''; fixed = true; }
    if (rowCopy.isNet === undefined || rowCopy.isNet === null) { (rowCopy as Record<string, unknown>).isNet = false; fixed = true; }
    if (rowCopy.netComponents === undefined || rowCopy.netComponents === null) { (rowCopy as Record<string, unknown>).netComponents = []; fixed = true; }
    if (rowCopy.indent === undefined || rowCopy.indent === null) { (rowCopy as Record<string, unknown>).indent = 0; fixed = true; }
    return rowCopy;
  });

  if (fixed) {
    actions.push({
      tableId: table.tableId,
      rule: 'empty_fields_normalized',
      severity: 'fix',
      detail: 'Replaced undefined/null fields with safe defaults',
    });
  }

  return { ...tableCopy, rows };
}

/**
 * Rule 2: Strip "SECTION X:" prefix, force ALL CAPS, trim whitespace.
 */
function cleanSurveySection(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  if (!table.surveySection) return table;

  let cleaned = table.surveySection.trim();

  // Strip "SECTION X:" or "Section X:" prefix (with or without number)
  const sectionPrefixPattern = /^SECTION\s+\d*[A-Z]?\s*[:.\-–—]\s*/i;
  if (sectionPrefixPattern.test(cleaned)) {
    cleaned = cleaned.replace(sectionPrefixPattern, '');
  }

  // Force ALL CAPS
  cleaned = cleaned.toUpperCase().trim();

  if (cleaned !== table.surveySection) {
    actions.push({
      tableId: table.tableId,
      rule: 'survey_section_cleaned',
      severity: 'fix',
      detail: `"${table.surveySection}" → "${cleaned}"`,
    });
    return { ...table, surveySection: cleaned };
  }

  return table;
}

/**
 * Rule 3: Heuristic check for question-description patterns in baseText.
 * Warns but does not auto-fix (semantic decision).
 */
function validateBaseText(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  if (!table.baseText) return table;

  const text = table.baseText.trim();

  // Patterns that suggest a question description rather than an audience description
  const suspiciousPatterns = [
    /^about\s+/i,           // "About the drink at..."
    /^awareness\s+of\s+/i,  // "Awareness of treatment options"
    /^usage\s+of\s+/i,      // "Usage of product X"
    /^satisfaction\s+with/i, // "Satisfaction with service"
    /^likelihood\s+/i,      // "Likelihood to recommend"
    /^frequency\s+of\s+/i,  // "Frequency of use"
    /^future\s+/i,          // "Future growth of..."
    /^importance\s+of\s+/i, // "Importance of features"
    /^perception\s+of\s+/i, // "Perception of brand"
    /^preference\s+for\s+/i,// "Preference for product"
    /^attitudes?\s+toward/i, // "Attitude toward brand"
  ];

  for (const pattern of suspiciousPatterns) {
    if (pattern.test(text)) {
      actions.push({
        tableId: table.tableId,
        rule: 'suspicious_base_text',
        severity: 'warn',
        detail: `baseText "${text}" looks like a question description, not an audience. Should describe WHO was asked, not WHAT was asked.`,
      });
      break;
    }
  }

  return table;
}

/**
 * Rule 3b: Backfill baseText when a filter is applied but baseText is empty.
 * Safety net — surfaces the R expression so users can see what's applied.
 */
function backfillBaseText(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  // Only act when a filter exists but base text is missing
  if (!table.additionalFilter || table.additionalFilter.trim() === '') return table;
  if (table.baseText && table.baseText.trim() !== '') return table;

  // Last-resort fallback: surface the R expression so users can see what's applied
  actions.push({
    tableId: table.tableId,
    rule: 'base_text_backfill',
    severity: 'fix',
    detail: `baseText was empty despite additionalFilter "${table.additionalFilter}" — backfilled from filter expression`,
  });

  return { ...table, baseText: `Respondents matching filter: ${table.additionalFilter}` };
}

/**
 * Rule 4: Remove same-variable NETs that cover ALL non-NET options + reset orphaned indent.
 */
function checkTrivialNets(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  const rows = [...table.rows.map(r => ({ ...r }))];
  const indicesToRemove: Set<number> = new Set();

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    if (!row.isNet || !row.filterValue || row.netComponents.length > 0) continue;

    // Same-variable NET: check if filterValue covers all non-NET values for this variable
    const variable = row.variable;
    const netValues = new Set(row.filterValue.split(',').map(v => v.trim()));

    // Collect all non-NET filterValues for the same variable in this table
    const nonNetValues = new Set<string>();
    for (const other of rows) {
      if (other === row) continue;
      if (other.variable !== variable) continue;
      if (other.isNet) continue;
      if (other.variable === '_CAT_') continue;
      // For single values or comma-separated
      for (const v of other.filterValue.split(',')) {
        const trimmed = v.trim();
        if (trimmed) nonNetValues.add(trimmed);
      }
    }

    if (nonNetValues.size === 0) continue;

    // Check: does the NET cover ALL non-NET values?
    const allCovered = [...nonNetValues].every(v => netValues.has(v));
    if (allCovered && netValues.size <= nonNetValues.size) {
      indicesToRemove.add(i);
      actions.push({
        tableId: table.tableId,
        rule: 'trivial_net_removed',
        severity: 'fix',
        detail: `Removed trivial NET "${row.label}" (filterValue "${row.filterValue}") — covers all ${nonNetValues.size} options for variable ${variable}`,
      });
    }
  }

  if (indicesToRemove.size === 0) return table;

  // Remove trivial NETs and fix orphaned indentation
  const filteredRows = rows.filter((_, i) => !indicesToRemove.has(i));

  // Reset indent for any rows that now have no NET parent above them
  for (let i = 0; i < filteredRows.length; i++) {
    if (filteredRows[i].indent > 0) {
      // Look backward for a NET parent
      let hasParent = false;
      for (let j = i - 1; j >= 0; j--) {
        if (filteredRows[j].isNet && filteredRows[j].indent === 0) {
          hasParent = true;
          break;
        }
        if (filteredRows[j].indent === 0 && !filteredRows[j].isNet) {
          break; // Hit a non-NET top-level row — no parent
        }
      }
      if (!hasParent) {
        filteredRows[i] = { ...filteredRows[i], indent: 0 };
      }
    }
  }

  return { ...table, rows: filteredRows };
}

/**
 * Rule 5: Normalize source ID casing in userNote: [s1] → [S1].
 */
function normalizeSourceIdCasing(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  if (!table.userNote) return table;

  // Match [s1], [s12a], [q5r2], etc. — lowercase IDs in brackets
  const pattern = /\[([a-z][a-z0-9_]*)\]/g;
  const original = table.userNote;
  const fixed = original.replace(pattern, (_match, id: string) => `[${id.toUpperCase()}]`);

  if (fixed !== original) {
    actions.push({
      tableId: table.tableId,
      rule: 'source_id_casing_normalized',
      severity: 'fix',
      detail: `userNote: "${original}" → "${fixed}"`,
    });
    return { ...table, userNote: fixed };
  }

  return table;
}

/**
 * Rule 6: Flag duplicate (variable, filterValue) pairs within a table.
 */
function detectDuplicateRows(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  const seen = new Map<string, number>();

  for (let i = 0; i < table.rows.length; i++) {
    const row = table.rows[i];
    if (row.variable === '_CAT_') continue;
    const key = `${row.variable}::${row.filterValue}`;
    if (seen.has(key)) {
      actions.push({
        tableId: table.tableId,
        rule: 'duplicate_row_detected',
        severity: 'warn',
        detail: `Duplicate (variable="${row.variable}", filterValue="${row.filterValue}") at rows ${seen.get(key)} and ${i}`,
      });
    } else {
      seen.set(key, i);
    }
  }

  return table;
}

/**
 * Rule 7: Reset indent to 0 for rows with no preceding NET parent.
 */
function checkOrphanIndent(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  let modified = false;
  const rows = table.rows.map((row, i) => {
    if (row.indent <= 0) return row;

    // Look backward for a NET parent
    let hasParent = false;
    for (let j = i - 1; j >= 0; j--) {
      const candidate = table.rows[j];
      if (candidate.isNet && candidate.indent === 0) {
        // Check that the parent's filterValue contains this row's filterValue
        if (candidate.filterValue) {
          const parentValues = new Set(candidate.filterValue.split(',').map(v => v.trim()));
          const childValues = row.filterValue.split(',').map(v => v.trim());
          if (childValues.every(v => parentValues.has(v))) {
            hasParent = true;
          }
        }
        break; // Stop at first NET parent candidate
      }
      if (candidate.indent === 0 && !candidate.isNet) {
        break; // Hit a non-NET top-level row
      }
    }

    if (!hasParent) {
      modified = true;
      actions.push({
        tableId: table.tableId,
        rule: 'orphan_indent_reset',
        severity: 'fix',
        detail: `Row "${row.label}" (variable=${row.variable}, filterValue="${row.filterValue}") had indent=${row.indent} with no valid NET parent — reset to 0`,
      });
      return { ...row, indent: 0 };
    }

    return row;
  });

  if (modified) {
    return { ...table, rows };
  }
  return table;
}

/**
 * Rule 8: Strip survey routing instructions from row labels.
 * Removes (TERMINATE), (CONTINUE), (ASK Q5), (SKIP TO S4), (END SURVEY), (SCREEN OUT), etc.
 */
function stripRoutingInstructions(table: ExtendedTableDefinition, actions: PostPassAction[]): ExtendedTableDefinition {
  // Match parenthesized routing instructions at the end of labels or standalone
  // Covers: (TERMINATE), (CONTINUE TO S4), (ASK S3a), (SKIP TO Q5), (END SURVEY), (SCREEN OUT), (GO TO S2)
  const routingPattern = /\s*\((?:TERMINATE|CONTINUE(?:\s+TO\s+\S+)?|ASK\s+\S+|SKIP\s+TO\s+\S+|END\s+SURVEY|SCREEN\s*OUT|GO\s+TO\s+\S+)\)\s*/gi;

  let modified = false;
  const rows = table.rows.map(row => {
    if (!routingPattern.test(row.label)) return row;

    const cleaned = row.label.replace(routingPattern, '').trim();
    if (cleaned !== row.label) {
      modified = true;
      actions.push({
        tableId: table.tableId,
        rule: 'routing_instruction_stripped',
        severity: 'fix',
        detail: `Row label: "${row.label}" → "${cleaned}"`,
      });
      return { ...row, label: cleaned };
    }
    return row;
  });

  if (modified) {
    return { ...table, rows };
  }
  return table;
}

// ─── Orchestrator ────────────────────────────────────────────────────────────

/**
 * Apply all post-pass rules to the verified tables.
 * Rules run sequentially per table (order matters: empty fields first, then content, then structural).
 */
export function normalizePostPass(tables: ExtendedTableDefinition[]): PostPassResult {
  const actions: PostPassAction[] = [];

  const processed = tables.map(table => {
    let t = table;

    // Phase 1: Field normalization (must run first)
    t = normalizeEmptyFields(t, actions);

    // Phase 2: Content normalization
    t = cleanSurveySection(t, actions);
    t = validateBaseText(t, actions);
    t = backfillBaseText(t, actions);
    t = normalizeSourceIdCasing(t, actions);
    t = stripRoutingInstructions(t, actions);

    // Phase 3: Structural fixes (depend on clean fields)
    t = checkTrivialNets(t, actions);
    t = detectDuplicateRows(t, actions);
    t = checkOrphanIndent(t, actions);

    return t;
  });

  return {
    tables: processed,
    actions,
    stats: {
      tablesProcessed: tables.length,
      totalFixes: actions.filter(a => a.severity === 'fix').length,
      totalWarnings: actions.filter(a => a.severity === 'warn').length,
    },
  };
}
