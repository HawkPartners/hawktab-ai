/**
 * Excel Styles for Crosstab Formatting
 *
 * Two style sets:
 * - Antares: Original vertical stacking format
 * - Joe: Horizontal layout with minimal borders, colored sections
 */

import type { Fill, Borders, Font, Alignment, Border } from 'exceljs';

// =============================================================================
// Colors (ARGB format for ExcelJS)
// =============================================================================

export const COLORS = {
  // Header colors (Antares)
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

  // Joe format colors
  sigLetterRed: 'FFCC0000',         // Red for significance letters

  // Joe format - section colors (matching Joe's tabs)
  joeContext: 'FFE4DFEC',           // Purple/lavender for context column
  joeBase: 'FFE4DFEC',              // Purple/lavender for base row
  joeLabel: 'FFFFF2CC',             // Yellow for label column (answer options)
  joeHeader: 'FFDCE6F1',            // Light blue for header/banner area
  joeHeaderStatLetter: 'FFDCE6F1',  // Same blue for stat letter row
  joeDataAlt1: 'FFDCE6F1',          // Light blue for alternating data (cut group 1)
  joeDataAlt2: 'FFFFFFFF',          // White for alternating data

  // Joe format - banner group data colors (rotating palette)
  // Each group has two shades (A = lighter, B = slightly darker) for row alternation
  joeGroup0A: 'FFDCE6F1',           // Light blue (Total) - shade A
  joeGroup0B: 'FFC5D9F1',           // Light blue - shade B (slightly darker)
  joeGroup1A: 'FFE2EFDA',           // Light green - shade A
  joeGroup1B: 'FFD4E6C8',           // Light green - shade B
  joeGroup2A: 'FFFFF2CC',           // Light yellow - shade A
  joeGroup2B: 'FFFFE699',           // Light yellow - shade B
  joeGroup3A: 'FFFCE4D6',           // Light peach/orange - shade A
  joeGroup3B: 'FFF8CBAD',           // Light peach/orange - shade B
  joeGroup4A: 'FFE4DFEC',           // Light purple - shade A
  joeGroup4B: 'FFD9D2E9',           // Light purple - shade B
  joeGroup5A: 'FFDAEEF3',           // Light teal - shade A
  joeGroup5B: 'FFCBE4EE',           // Light teal - shade B
} as const;

// =============================================================================
// Fills
// =============================================================================

export const FILLS: Record<string, Fill> = {
  // Antares fills
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

  // Joe format fills
  joeContext: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeContext },
  },
  joeBase: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeBase },
  },
  joeLabel: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeLabel },
  },
  joeHeader: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeHeader },
  },
  joeDataWhite: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.dataBackground },
  },
  joeDataBlue: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeDataAlt1 },
  },

  // Joe format - banner group fills (rotating palette for data cells)
  // Shade A (lighter) - used for even rows (0, 2, 4, ...)
  joeGroup0A: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup0A },
  },
  joeGroup1A: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup1A },
  },
  joeGroup2A: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup2A },
  },
  joeGroup3A: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup3A },
  },
  joeGroup4A: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup4A },
  },
  joeGroup5A: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup5A },
  },
  // Shade B (slightly darker) - used for odd rows (1, 3, 5, ...)
  joeGroup0B: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup0B },
  },
  joeGroup1B: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup1B },
  },
  joeGroup2B: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup2B },
  },
  joeGroup3B: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup3B },
  },
  joeGroup4B: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup4B },
  },
  joeGroup5B: {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: COLORS.joeGroup5B },
  },
};

// Helper to get group fill by index and row (cycles through available colors, alternates shades)
export function getGroupFill(groupIndex: number, rowIndex: number = 0): Fill {
  const isEvenRow = rowIndex % 2 === 0;

  // Shade A fills (lighter) for even rows
  const groupFillsA = [
    FILLS.joeGroup0A,
    FILLS.joeGroup1A,
    FILLS.joeGroup2A,
    FILLS.joeGroup3A,
    FILLS.joeGroup4A,
    FILLS.joeGroup5A,
  ];

  // Shade B fills (slightly darker) for odd rows
  const groupFillsB = [
    FILLS.joeGroup0B,
    FILLS.joeGroup1B,
    FILLS.joeGroup2B,
    FILLS.joeGroup3B,
    FILLS.joeGroup4B,
    FILLS.joeGroup5B,
  ];

  const fills = isEvenRow ? groupFillsA : groupFillsB;
  return fills[groupIndex % fills.length];
}

// Helper to get group fill shade A only (for spacer columns, headers, etc.)
export function getGroupFillShadeA(groupIndex: number): Fill {
  const groupFillsA = [
    FILLS.joeGroup0A,
    FILLS.joeGroup1A,
    FILLS.joeGroup2A,
    FILLS.joeGroup3A,
    FILLS.joeGroup4A,
    FILLS.joeGroup5A,
  ];
  return groupFillsA[groupIndex % groupFillsA.length];
}

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
// Joe Format Borders - Minimal, structural only
// =============================================================================

// Double-line border style for group separation
const doubleBorderStyle: Partial<Border> = { style: 'double', color: { argb: COLORS.borderDark } };

export const JOE_BORDERS: Record<string, Partial<Borders>> = {
  // No border (default for most cells)
  none: {},

  // Double-line border for group separation (Joe style)
  doubleRight: {
    right: doubleBorderStyle,
  },
  doubleLeft: {
    left: doubleBorderStyle,
  },

  // Thick borders for structural separation
  thickTop: {
    top: mediumBorderStyle,
  },
  thickBottom: {
    bottom: mediumBorderStyle,
  },
  thickLeft: {
    left: mediumBorderStyle,
  },
  thickRight: {
    right: mediumBorderStyle,
  },

  // Combined structural borders
  thickTopLeft: {
    top: mediumBorderStyle,
    left: mediumBorderStyle,
  },
  thickTopRight: {
    top: mediumBorderStyle,
    right: mediumBorderStyle,
  },
  thickBottomLeft: {
    bottom: mediumBorderStyle,
    left: mediumBorderStyle,
  },
  thickBottomRight: {
    bottom: mediumBorderStyle,
    right: mediumBorderStyle,
  },
  thickLeftRight: {
    left: mediumBorderStyle,
    right: mediumBorderStyle,
  },
  thickTopBottom: {
    top: mediumBorderStyle,
    bottom: mediumBorderStyle,
  },

  // Three-sided borders
  thickTopLeftRight: {
    top: mediumBorderStyle,
    left: mediumBorderStyle,
    right: mediumBorderStyle,
  },
  thickBottomLeftRight: {
    bottom: mediumBorderStyle,
    left: mediumBorderStyle,
    right: mediumBorderStyle,
  },
  thickTopBottomLeft: {
    top: mediumBorderStyle,
    bottom: mediumBorderStyle,
    left: mediumBorderStyle,
  },
  thickTopBottomRight: {
    top: mediumBorderStyle,
    bottom: mediumBorderStyle,
    right: mediumBorderStyle,
  },

  // All sides thick (for special cells)
  thickAll: {
    top: mediumBorderStyle,
    bottom: mediumBorderStyle,
    left: mediumBorderStyle,
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
  // Joe format fonts
  significanceLetterRed: {
    bold: true,  // Bold to make sig letters pop
    size: 10,
    color: { argb: COLORS.sigLetterRed },
  },
  context: {
    bold: false,
    size: 10,
    color: { argb: COLORS.textPrimary },
  },
  // Joe format - bold base row
  joeBaseBold: {
    bold: true,
    italic: true,
    size: 10,
    color: { argb: COLORS.textPrimary },
  },
  // Joe format - red stat letters in header
  joeStatLetterRed: {
    bold: false,
    size: 10,
    color: { argb: COLORS.sigLetterRed },
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

// Joe format column widths
export const COLUMN_WIDTHS_JOE = {
  context: 25,      // Context/question column (merged per table)
  label: 35,        // Answer label column
  value: 15,        // Value columns (percent or count) - wider for readability
  significance: 5,  // Significance letter columns
  spacer: 2,        // Spacer columns between groups
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
