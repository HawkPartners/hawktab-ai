/**
 * SurveyProcessor.ts
 *
 * Converts survey DOCX documents to markdown for agent consumption.
 * Uses LibreOffice for DOCX → HTML conversion, then turndown for HTML → Markdown.
 *
 * Part of VerificationAgent pipeline - provides survey context for table enhancement.
 */

import { exec } from 'child_process';
import { promisify } from 'util';
import * as fs from 'fs/promises';
import * as path from 'path';
import TurndownService from 'turndown';

const execAsync = promisify(exec);

// ===== TYPES =====

export interface SurveyResult {
  markdown: string;
  characterCount: number;
  warnings: string[];
}

export interface SurveyProcessorOptions {
  /** Keep intermediate HTML file for debugging */
  keepHtml?: boolean;
  /** Custom LibreOffice path (defaults to macOS location) */
  libreOfficePath?: string;
}

// ===== CONSTANTS =====

const DEFAULT_LIBREOFFICE_PATHS = [
  '/Applications/LibreOffice.app/Contents/MacOS/soffice',
  '/usr/bin/soffice',
  '/usr/local/bin/soffice',
];

// ===== MAIN FUNCTION =====

/**
 * Process a survey DOCX file to markdown.
 *
 * @param docxPath - Path to the survey DOCX file
 * @param outputDir - Directory for intermediate files (HTML)
 * @param options - Processing options
 * @returns SurveyResult with markdown content and metadata
 */
export async function processSurvey(
  docxPath: string,
  outputDir: string,
  options: SurveyProcessorOptions = {}
): Promise<SurveyResult> {
  const warnings: string[] = [];

  // Validate input file exists
  try {
    await fs.access(docxPath);
  } catch {
    return {
      markdown: '',
      characterCount: 0,
      warnings: [`Survey file not found: ${docxPath}`],
    };
  }

  // Find LibreOffice
  const libreOfficePath = options.libreOfficePath || (await findLibreOffice());
  if (!libreOfficePath) {
    return {
      markdown: '',
      characterCount: 0,
      warnings: ['LibreOffice not found. Install LibreOffice to process survey documents.'],
    };
  }

  try {
    // Step 1: DOCX → HTML via LibreOffice
    console.log('[SurveyProcessor] Converting DOCX to HTML...');
    await execAsync(
      `"${libreOfficePath}" --headless --convert-to html --outdir "${outputDir}" "${docxPath}"`
    );

    // Step 2: Find and read HTML file
    const basename = path.basename(docxPath, path.extname(docxPath));
    const htmlPath = path.join(outputDir, `${basename}.html`);

    let html: string;
    try {
      html = await fs.readFile(htmlPath, 'utf-8');
    } catch {
      return {
        markdown: '',
        characterCount: 0,
        warnings: [`HTML conversion failed - file not created: ${htmlPath}`],
      };
    }

    // Step 3: HTML → Markdown
    console.log('[SurveyProcessor] Converting HTML to Markdown...');
    const turndown = new TurndownService({
      headingStyle: 'atx',
      codeBlockStyle: 'fenced',
      bulletListMarker: '-',
    });

    // Customize turndown to preserve tables
    turndown.addRule('tables', {
      filter: ['table'],
      replacement: function (content, _node) {
        // Keep tables as-is in a simple format
        return '\n\n' + content + '\n\n';
      },
    });

    const markdown = turndown.turndown(html);

    // Step 4: Cleanup (unless keepHtml is true)
    if (!options.keepHtml) {
      await fs.unlink(htmlPath).catch(() => {
        warnings.push(`Could not clean up HTML file: ${htmlPath}`);
      });
    }

    console.log(`[SurveyProcessor] Conversion complete: ${markdown.length} characters`);

    return {
      markdown,
      characterCount: markdown.length,
      warnings,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    return {
      markdown: '',
      characterCount: 0,
      warnings: [`Survey conversion failed: ${errorMessage}`],
    };
  }
}

// ===== HELPER FUNCTIONS =====

/**
 * Find LibreOffice installation path.
 */
async function findLibreOffice(): Promise<string | null> {
  for (const libPath of DEFAULT_LIBREOFFICE_PATHS) {
    try {
      await fs.access(libPath);
      return libPath;
    } catch {
      // Try next path
    }
  }
  return null;
}

/**
 * Extract a section of the survey around a specific question number.
 * Useful for context optimization when survey is too long.
 *
 * @param markdown - Full survey markdown
 * @param questionId - Question ID to find (e.g., "A1", "S8")
 * @param windowChars - Characters to include before/after match
 * @returns Extracted section or full markdown if not found
 */
export function extractQuestionSection(
  markdown: string,
  questionId: string,
  windowChars: number = 2000
): string {
  // Create regex pattern to find question (e.g., "A1.", "A1:", "A1 ", "A1)")
  const pattern = new RegExp(`\\b${questionId}[.:\\s)]`, 'i');
  const match = markdown.match(pattern);

  if (!match || match.index === undefined) {
    // Question not found, return full markdown
    return markdown;
  }

  const matchIndex = match.index;
  const start = Math.max(0, matchIndex - windowChars);
  const end = Math.min(markdown.length, matchIndex + windowChars);

  // Try to start/end at line boundaries
  let adjustedStart = start;
  let adjustedEnd = end;

  if (start > 0) {
    const lineStart = markdown.lastIndexOf('\n', start);
    if (lineStart !== -1) {
      adjustedStart = lineStart + 1;
    }
  }

  if (end < markdown.length) {
    const lineEnd = markdown.indexOf('\n', end);
    if (lineEnd !== -1) {
      adjustedEnd = lineEnd;
    }
  }

  const section = markdown.slice(adjustedStart, adjustedEnd);

  // Add markers to show this is a section
  const prefix = adjustedStart > 0 ? '...\n\n' : '';
  const suffix = adjustedEnd < markdown.length ? '\n\n...' : '';

  return prefix + section + suffix;
}

/**
 * Get basic stats about the survey markdown.
 */
export function getSurveyStats(markdown: string): {
  characterCount: number;
  lineCount: number;
  estimatedTokens: number;
} {
  return {
    characterCount: markdown.length,
    lineCount: markdown.split('\n').length,
    // Rough estimate: ~4 chars per token for English text
    estimatedTokens: Math.ceil(markdown.length / 4),
  };
}
