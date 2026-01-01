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
// NOTE: withTrace and getGlobalTraceProvider removed - using structured console logging instead
import type { ValidationResultType } from '@/schemas/agentOutputSchema';
import { DataMapSchema, type DataMapType, getVariableNames } from '@/schemas/dataMapSchema';
import { validateRSyntax } from '@/guardrails/outputValidation';
import type { RManifest } from '@/lib/r/Manifest';

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
  // Whitelist common R functions and constants to avoid flagging them as variables
  const whitelist = new Set<string>([
    // Control flow and constants
    'if', 'else', 'repeat', 'while', 'function', 'for', 'in', 'next', 'break',
    'TRUE', 'FALSE', 'NA', 'NULL', 'Inf', 'NaN',
    // Base utilities
    'c', 'is.na', 'isnan', 'is.infinite',
    // Stats helpers used in prompts
    'median', 'mean', 'quantile', 'ntile',
    // Named args commonly seen
    'na', 'rm', 'na.rm', 'probs',
    // IO used in the generated script header
    'data', 'read_sav', 'library'
  ]);

  // Tokenize: capture identifiers and dotted names (e.g., na.rm)
  const tokens = expression.match(/[A-Za-z][A-Za-z0-9_.]*/g) || [];
  const unknown: string[] = [];
  for (const token of tokens) {
    // Skip single letters and whitelisted known language/function tokens
    if (token.length <= 1) continue;
    if (whitelist.has(token)) continue;
    // If token contains a dot, also check the part before the dot (e.g., na.rm -> na, rm)
    if (token.includes('.')) {
      const parts = token.split('.');
      if (parts.some((p) => whitelist.has(p))) continue;
    }
    if (!knownVars.has(token)) {
      // Avoid duplicates in a single expression
      if (!unknown.includes(token)) unknown.push(token);
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

    // Structured logging replaces withTrace()
    const startTime = Date.now();
    console.log(`[RScriptAgent] Starting R Script Generation for session: ${sessionId}`);

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

    const result = RScriptOutputSchema.parse(output);

    const duration = Date.now() - startTime;
    console.log(`[RScriptAgent] R Script Generation completed (${duration}ms) - ${groups} groups, ${columns} columns`);

    return result;
  }

  // Generate a single master R script from a deterministic manifest
  async generateMasterFromManifest(sessionId: string, manifest: RManifest): Promise<string> {
    const sanitize = (s: string) => s.replace(/[^A-Za-z0-9_]/g, '_');

    const header = [
      '# HawkTab AI — master R (deterministic)',
      `# Session: ${sessionId}`,
      `# Generated: ${new Date().toISOString()}`,
      '',
      'library(haven)',
      'library(jsonlite)',
      'library(dplyr)',
      `data <- read_sav('${manifest.dataFilePath}')`,
      '',
      '# Load preflight statistics if available',
      `preflight_path <- 'temp-outputs/${sessionId}/r/preflight.json'`,
      'preflight_stats <- NULL',
      'if (file.exists(preflight_path)) {',
      '  preflight_stats <- fromJSON(preflight_path)',
      '  cat("Loaded preflight statistics\\n")',
      '} else {',
      '  cat("No preflight statistics found, using defaults\\n")',
      '}',
      '',
    ];

    const cutLines: string[] = [];
    cutLines.push('warnings <- character()');
    cutLines.push('');
    // Define cuts with tryCatch, then add only valid ones to cuts list
    for (const cut of manifest.cutsSpec.cuts) {
      const varName = `cut_${sanitize(cut.id)}`;
      const nameEsc = cut.name.replace(/'/g, "\\'");
      cutLines.push(`# Cut: ${cut.name}`);
      cutLines.push(`${varName} <- tryCatch({ with(data, ${cut.rExpression}) }, error = function(e) { warnings <<- c(warnings, paste0('cut:', '${nameEsc}', ':', e$message)); NULL })`);
    }
    cutLines.push('');
    cutLines.push('cuts <- list()');
    for (const cut of manifest.cutsSpec.cuts) {
      const varName = `cut_${sanitize(cut.id)}`;
      const nameEsc = cut.name.replace(/'/g, "\\'");
      cutLines.push(`if (!is.null(${varName}) && is.logical(${varName})) { cuts[['${nameEsc}']] <- ${varName} } else { warnings <- c(warnings, paste0('cut_invalid:', '${nameEsc}')) }`);
    }
    cutLines.push('');

    // Preflight arrays for JSON report
    cutLines.push('preflight_cuts <- lapply(names(cuts), function(nm) list(name = nm, valid = TRUE, error = NA))');
    cutLines.push('');

    const helper = [
      `dir.create('temp-outputs/${sessionId}/results', recursive = TRUE, showWarnings = FALSE)`,
      '',
      '# Enhanced write_table with preflight statistics',
      'write_table <- function(data, var_name, levels_df, table_id, table_meta = NULL) {',
      "  v <- tryCatch({ data[[var_name]] }, error = function(e) { warnings <<- c(warnings, paste0('var:', var_name, ':', e$message)); return(NULL) })",
      '  if (is.null(v)) { return(invisible(NULL)) }',
      '  ',
      '  # Check for preflight stats for this variable',
      '  var_stats <- NULL',
      '  bucket_edges <- NULL',
      '  if (!is.null(preflight_stats) && !is.null(preflight_stats$variables[[var_name]])) {',
      '    var_stats <- preflight_stats$variables[[var_name]]',
      '    bucket_edges <- var_stats$bucketEdges',
      '  }',
      '  ',
      '  # Use bucketing for numeric variables if available',
      '  if (!is.null(bucket_edges) && is.numeric(v) && is.null(levels_df)) {',
      '    # Create buckets using preflight edges',
      '    v_bucketed <- cut(v, breaks = bucket_edges, include.lowest = TRUE, right = FALSE)',
      '    levels(v_bucketed) <- paste0("[", head(bucket_edges, -1), "-", tail(bucket_edges, -1), ")")',
      '    v <- v_bucketed',
      '  } else if (!is.null(levels_df)) {',
      '    v <- factor(v, levels = levels_df$value, labels = levels_df$label)',
      '  }',
      '  ',
      '  count_list <- lapply(cuts, function(idx) {',
      "    tab <- table(v[idx], useNA = 'no')",
      '    if (is.factor(v)) {',
      '      lv <- levels(v)',
      '      res <- as.integer(tab[lv])',
      '      res[is.na(res)] <- 0',
      '      res',
      '    } else {',
      '      as.integer(tab)',
      '    }',
      '  })',
      '  counts <- do.call(cbind, count_list)',
      '  colnames(counts) <- names(cuts)',
      '  rn <- if (is.factor(v)) levels(v) else rownames(table(v))',
      '  rownames(counts) <- rn',
      '  col_totals <- colSums(counts)',
      '  denom <- ifelse(col_totals == 0, 1, col_totals)',
      '  perc <- sweep(counts, 2, denom, "/") * 100',
      '  ',
      '  # Add numeric statistics if requested',
      '  out <- data.frame(Level = rownames(counts), counts, perc, check.names = FALSE)',
      '  ',
      '  # Append statistics row for numeric variables',
      '  if (!is.null(var_stats) && !is.null(table_meta$numericMetrics)) {',
      '    if (table_meta$numericMetrics$mean || table_meta$numericMetrics$median || table_meta$numericMetrics$sd) {',
      '      stats_row <- data.frame(Level = "Statistics", matrix(NA, nrow = 1, ncol = ncol(out) - 1), check.names = FALSE)',
      '      if (table_meta$numericMetrics$mean) {',
      '        stats_row$Level <- paste0(stats_row$Level, " Mean=", round(var_stats$mean, 2))',
      '      }',
      '      if (table_meta$numericMetrics$median) {',
      '        stats_row$Level <- paste0(stats_row$Level, " Median=", round(var_stats$median, 2))',
      '      }',
      '      if (table_meta$numericMetrics$sd) {',
      '        stats_row$Level <- paste0(stats_row$Level, " SD=", round(var_stats$sd, 2))',
      '      }',
      '      out <- rbind(out, stats_row)',
      '    }',
      '  }',
      '  ',
      `  write.csv(out, sprintf('temp-outputs/${sessionId}/results/%s.csv', table_id), row.names = FALSE)`,
      '}',
      '',
      'write_multi_table <- function(data, items_df, cuts_list, table_id, title) {',
      "  build_item <- function(row) { var <- row[['var']]; label <- row[['label']]; pos <- row[['positiveValue']];",
      "    v <- tryCatch({ data[[var]] }, error = function(e) { warnings <<- c(warnings, paste0('var:', var, ':', e$message)); return(NULL) })",
      '    if (is.null(v)) { return(NULL) }',
      '    res_list <- lapply(cuts_list, function(idx) { sum(v[idx] == pos, na.rm = TRUE) })',
      '    counts <- as.integer(unlist(res_list))',
      '    names(counts) <- names(cuts_list)',
      '    total <- sapply(cuts_list, function(idx) sum(!is.na(v[idx])))',
      '    denom <- ifelse(total == 0, 1, total)',
      '    perc <- (counts / denom) * 100',
      '    data.frame(Item = label, t(counts), t(perc), check.names = FALSE)',
      '  }',
      '  rows <- lapply(seq_len(nrow(items_df)), function(i) build_item(items_df[i, ]))',
      '  rows <- Filter(Negate(is.null), rows)',
      "  if (length(rows) == 0) { warnings <<- c(warnings, paste0('multi_empty:', table_id)); return(invisible(NULL)) }",
      '  out <- do.call(rbind, rows)',
      `  write.csv(out, sprintf('temp-outputs/${sessionId}/results/%s.csv', table_id), row.names = FALSE)`,
      '}',
      '',
    ];

    const tableCalls: string[] = [];
    // Build preflight for variables
    tableCalls.push('preflight_vars <- list()');
    for (const t of manifest.tablePlan.tables) {
      if (t.tableType === 'single') {
        const levelsDef = t.levels
          ? `data.frame(value=c(${t.levels.map((l) => `${l.value}`).join(',')}), label=c(${t.levels
              .map((l) => `'${String(l.label).replace(/'/g, "\\'")}'`)
              .join(',')}))`
          : 'NULL';
        // Build table metadata for numeric statistics
        let tableMeta = 'NULL';
        if (t.numericMetrics) {
          tableMeta = `list(numericMetrics=list(mean=${t.numericMetrics.mean ? 'TRUE' : 'FALSE'}, median=${t.numericMetrics.median ? 'TRUE' : 'FALSE'}, sd=${t.numericMetrics.sd ? 'TRUE' : 'FALSE'}))`;
        }
        tableCalls.push(`ok <- tryCatch({ data[['${t.questionVar}']]; TRUE }, error = function(e) { warnings <<- c(warnings, paste0('var:', '${t.questionVar}', ':', e$message)); FALSE })`);
        tableCalls.push(`preflight_vars <- append(preflight_vars, list(list(var='${t.questionVar}', valid=ok)))`);
        tableCalls.push(`if (ok) write_table(data, '${t.questionVar}', ${levelsDef}, '${t.id}', ${tableMeta})`);
      } else if (t.tableType === 'multi_subs') {
        // Build items data.frame for R
        const items = (t as { tableType: 'multi_subs'; items: Array<{ var: string; label: string; positiveValue: number | string }>} ).items;
        const itemVars = items.map((it) => `'${String(it.var).replace(/'/g, "\\'")}'`).join(',');
        const itemLabels = items.map((it) => `'${String(it.label).replace(/'/g, "\\'")}'`).join(',');
        const itemPos = items.map((it) => `${it.positiveValue}`).join(',');
        const df = `data.frame(var=c(${itemVars}), label=c(${itemLabels}), positiveValue=c(${itemPos}), stringsAsFactors=FALSE)`;
        tableCalls.push(`items_df <- ${df}`);
        tableCalls.push(`write_multi_table(data, items_df, cuts, '${t.id}', '${t.title.replace(/'/g, "\\'")}')`);
      }
    }
    // Write preflight summary JSON
    tableCalls.push(`preflight <- list(cuts = preflight_cuts, vars = preflight_vars, warnings = warnings)`);
    tableCalls.push(`write_json(preflight, 'temp-outputs/${sessionId}/r/preflight.json', auto_unbox = TRUE, pretty = TRUE)`);

    return [...header, ...cutLines, ...helper, ...tableCalls, ''].join('\n');
  }
}
