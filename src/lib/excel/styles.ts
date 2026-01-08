/**
 * Excel Styles for Antares-style Crosstab Formatting
 *
 * Color scheme and border styles matching reference:
 * docs/reference-crosstab-images/referenence-antares-output.png
 */

import type { Fill, Borders, Font, Alignment, Border } from 'exceljs';

// =============================================================================
// Colors (ARGB format for ExcelJS)
// =============================================================================

export const COLORS = {
  // Header colors
  titleBackground: 'FFE0E0E0',      // Light gray for title row
  groupHeaderBackground: 'FFD9E1F2', // Light blue for group/column headers
  baseRowBackground: 'FFFFF2CC',    // Light yellow for base n row
  labelColumnBackground: 'FFE2EFDA', // Light teal for row labels

  // Data colors
  dataBackground: 'FFFFFFFF',       // White for data cells

  // Border colors
  borderDark: 'FF000000',           // Black for borders
  borderLight: 'FFD0D0D0',          // Light gray for thin borders

  // Text colors
  textPrimary: 'FF000000',          // Black
  textSecondary: 'FF666666',        // Gray for secondary text
} as const;

// =============================================================================
// Fills
// =============================================================================

export const FILLS: Record<string, Fill> = {
  title: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.titleBackground },
  },
  groupHeader: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.groupHeaderBackground },
  },
  baseRow: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.baseRowBackground },
  },
  labelColumn: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.labelColumnBackground },
  },
  data: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.dataBackground },
  },
};

// =============================================================================
// Border Styles
// =============================================================================

const thinBorderStyle: Partial<Border> = { style: 'thin', color: { argb: COLORS.borderDark } };
const mediumBorderStyle: Partial<Border> = { style: 'medium', color: { argb: COLORS.borderDark } };

export const BORDERS: Record<string, Partial<Borders>> = {
  // All sides thin
  thin: {
    top: thinBorderStyle,
    left: thinBorderStyle,
    bottom: thinBorderStyle,
    right: thinBorderStyle,
  },
  // All sides medium (for box around table)
  medium: {
    top: mediumBorderStyle,
    left: mediumBorderStyle,
    bottom: mediumBorderStyle,
    right: mediumBorderStyle,
  },
  // Heavy right border (between groups)
  groupSeparatorRight: {
    top: thinBorderStyle,
    left: thinBorderStyle,
    bottom: thinBorderStyle,
    right: mediumBorderStyle,
  },
  // Heavy left border (start of new group)
  groupSeparatorLeft: {
    top: thinBorderStyle,
    left: mediumBorderStyle,
    bottom: thinBorderStyle,
    right: thinBorderStyle,
  },
  // Top border only (for table box top)
  boxTop: {
    top: mediumBorderStyle,
  },
  // Bottom border only (for table box bottom)
  boxBottom: {
    bottom: mediumBorderStyle,
  },
  // Left border only (for table box left)
  boxLeft: {
    left: mediumBorderStyle,
  },
  // Right border only (for table box right)
  boxRight: {
    right: mediumBorderStyle,
  },
};

// =============================================================================
// Fonts
// =============================================================================

export const FONTS: Record<string, Partial<Font>> = {
  title: {
    bold: true,
    size: 11,
    color: { argb: COLORS.textPrimary },
  },
  header: {
    bold: true,
    size: 10,
    color: { argb: COLORS.textPrimary },
  },
  statLetter: {
    bold: false,
    size: 9,
    color: { argb: COLORS.textSecondary },
  },
  label: {
    bold: false,
    size: 10,
    color: { argb: COLORS.textPrimary },
  },
  labelNet: {
    bold: true,
    size: 10,
    color: { argb: COLORS.textPrimary },
  },
  data: {
    bold: false,
    size: 10,
    color: { argb: COLORS.textPrimary },
  },
  significance: {
    bold: false,
    size: 9,
    color: { argb: COLORS.textSecondary },
  },
  footer: {
    bold: false,
    size: 9,
    italic: true,
    color: { argb: COLORS.textSecondary },
  },
};

// =============================================================================
// Alignments
// =============================================================================

export const ALIGNMENTS: Record<string, Partial<Alignment>> = {
  left: {
    horizontal: 'left',
    vertical: 'middle',
  },
  center: {
    horizontal: 'center',
    vertical: 'middle',
  },
  right: {
    horizontal: 'right',
    vertical: 'middle',
  },
  wrapText: {
    horizontal: 'left',
    vertical: 'middle',
    wrapText: true,
  },
};

// =============================================================================
// Column Widths
// =============================================================================

export const COLUMN_WIDTHS = {
  label: 30,        // Row labels column
  data: 10,         // Data columns (n, %, etc.)
  statLetter: 6,    // Stat letter column width
  min: 8,           // Minimum column width
  max: 50,          // Maximum column width
} as const;

// =============================================================================
// Row Heights
// =============================================================================

export const ROW_HEIGHTS = {
  title: 20,        // Title row
  header: 18,       // Header rows
  data: 16,         // Data rows
  footer: 14,       // Footer rows
  gap: 8,           // Gap between tables
} as const;

// =============================================================================
// Table Spacing
// =============================================================================

export const TABLE_SPACING = {
  gapBetweenTables: 2,  // Number of blank rows between tables
  startRow: 1,          // Starting row for first table
  startCol: 1,          // Starting column (A = 1)
} as const;
