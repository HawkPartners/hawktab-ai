/**
 * R Expression Sanitizer
 *
 * Validates user-provided R expressions (from HITL review edits) before they
 * reach R execution. Blocks dangerous R functions that could enable OS-level
 * code execution or filesystem access.
 *
 * Security context: User-edited expressions are interpolated into
 * `with(data, <expr>)` in CutExpressionValidator and RScriptGeneratorV2.
 * Without validation, an attacker could inject `system('...')` to achieve RCE.
 */

// R functions that enable OS command execution or dangerous filesystem operations
const DANGEROUS_R_FUNCTIONS = [
  // OS command execution
  'system',
  'system2',
  'shell',
  'shell.exec',
  'Sys.command',
  'pipe',
  'fifo',
  // Filesystem operations
  'file',
  'file.create',
  'file.remove',
  'file.rename',
  'file.copy',
  'file.exists',
  'file.info',
  'unlink',
  'readLines',
  'writeLines',
  'readRDS',
  'saveRDS',
  'load',
  'cat',
  'sink',
  'list.files',
  'dir',
  'dir.create',
  'tempfile',
  'tempdir',
  // Code execution / metaprogramming
  'source',
  'eval',
  'parse',
  'do.call',
  'get',
  'assign',
  'match.fun',
  'Recall',
  // Environment access
  'environment',
  'globalenv',
  'baseenv',
  'new.env',
  // Error handling abuse (can suppress sanitizer errors)
  'tryCatch',
  'withCallingHandlers',
  'on.exit',
  // Package management
  'library',
  'require',
  'install.packages',
  'download.file',
  'url',
  'browseURL',
  // System configuration
  'setwd',
  'Sys.setenv',
  'Sys.getenv',
  'Sys.sleep',
  'Sys.chmod',
  'Sys.umask',
  'Sys.readlink',
  'Sys.which',
  'proc.time',
  'quit',
  'q',
  // Low-level R internals
  '.Internal',
  '.Primitive',
  '.Call',
  '.External',
  '.C',
  '.Fortran',
];

// Build a regex that matches any of the dangerous function names followed by '('
// Handles: system("cmd"), system ('cmd'), system(  'cmd')
const DANGEROUS_FUNC_PATTERN = new RegExp(
  `\\b(${DANGEROUS_R_FUNCTIONS.join('|').replace(/\./g, '\\.')})\\s*\\(`,
  'i'
);

// Characters allowed in R cut expressions.
// Permits: variable names, numbers, comparison operators, logical operators,
// parentheses, strings, whitespace, R operators like %in%, &, |, !, ==, !=, etc.
const SAFE_CHARS_PATTERN = /^[a-zA-Z0-9_. ()%><=!&|,:"'\-\s\[\]\+\*\/\^~]+$/;

export interface SanitizeResult {
  safe: boolean;
  error?: string;
}

/**
 * Validate that an R expression is safe for execution.
 * Returns { safe: true } if the expression passes all checks,
 * or { safe: false, error: '...' } with a human-readable explanation.
 */
export function sanitizeRExpression(expr: string): SanitizeResult {
  if (!expr || expr.trim().length === 0) {
    return { safe: false, error: 'Expression is empty' };
  }

  // Check for dangerous function calls
  const dangerousMatch = expr.match(DANGEROUS_FUNC_PATTERN);
  if (dangerousMatch) {
    return {
      safe: false,
      error: `Expression contains disallowed R function: ${dangerousMatch[1]}()`,
    };
  }

  // Check for backtick execution (R backtick-quotes can reference functions)
  if (expr.includes('`') && /`[^`]+`\s*\(/.test(expr)) {
    return {
      safe: false,
      error: 'Expression contains backtick-quoted function call',
    };
  }

  // Check for shell-style injection attempts
  if (/\$\(/.test(expr) || /;\s*\w/.test(expr)) {
    return {
      safe: false,
      error: 'Expression contains shell metacharacters',
    };
  }

  // Check character allowlist
  if (!SAFE_CHARS_PATTERN.test(expr)) {
    // Find the offending character for a helpful error message
    const offending = expr.split('').find(ch => !SAFE_CHARS_PATTERN.test(ch));
    return {
      safe: false,
      error: `Expression contains disallowed character: '${offending}'`,
    };
  }

  return { safe: true };
}
