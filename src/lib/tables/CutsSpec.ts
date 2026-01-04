import type { ValidationResultType } from '@/schemas/agentOutputSchema';

/**
 * Enhanced CutDefinition with fields needed for significance testing
 */
export type CutDefinition = {
  id: string;
  name: string;
  rExpression: string;
  statLetter: string;     // Stat letter for significance testing (A, B, C, etc.)
  groupName: string;      // Group this cut belongs to (for within-group comparisons)
  groupIndex: number;     // Position within group
};

/**
 * Group of cuts for within-group significance testing
 */
export type CutGroup = {
  groupName: string;
  cuts: CutDefinition[];
};

/**
 * Complete cuts specification with group structure for stat testing
 */
export type CutsSpec = {
  cuts: CutDefinition[];
  groups: CutGroup[];           // Preserve group structure for stat testing
  totalCut: CutDefinition | null;  // Reference to Total column
};

function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Generate stat letter from index (A, B, C, ..., Z, AA, AB, ...)
 */
function getStatLetter(index: number): string {
  if (index < 26) {
    return String.fromCharCode(65 + index); // A-Z
  }
  // For 26+, use AA, AB, etc.
  const first = Math.floor(index / 26) - 1;
  const second = index % 26;
  return String.fromCharCode(65 + first) + String.fromCharCode(65 + second);
}

/**
 * Build CutsSpec from CrosstabAgent validation output
 *
 * Generates stat letters deterministically based on column order.
 * Total column is identified by name and tracked separately for stat testing.
 */
export function buildCutsSpec(validation: ValidationResultType): CutsSpec {
  const cuts: CutDefinition[] = [];
  const groups: CutGroup[] = [];
  let totalCut: CutDefinition | null = null;
  let letterIndex = 0;

  for (const group of validation.bannerCuts) {
    const groupCuts: CutDefinition[] = [];

    for (let i = 0; i < group.columns.length; i++) {
      const col = group.columns[i];
      const id = `${slugify(group.groupName)}.${slugify(col.name)}`;

      // Use 'T' for Total column, otherwise sequential letters
      const isTotal = col.name === 'Total' || group.groupName === 'Total';
      const statLetter = isTotal ? 'T' : getStatLetter(letterIndex);

      if (!isTotal) {
        letterIndex++;
      }

      const cut: CutDefinition = {
        id,
        name: col.name,
        rExpression: col.adjusted,
        statLetter,
        groupName: group.groupName,
        groupIndex: i,
      };

      cuts.push(cut);
      groupCuts.push(cut);

      // Track Total column separately
      if (isTotal) {
        totalCut = cut;
      }
    }

    groups.push({ groupName: group.groupName, cuts: groupCuts });
  }

  return { cuts, groups, totalCut };
}

/**
 * Get cuts belonging to a specific group
 */
export function getCutsByGroup(cutsSpec: CutsSpec, groupName: string): CutDefinition[] {
  const group = cutsSpec.groups.find(g => g.groupName === groupName);
  return group ? group.cuts : [];
}

/**
 * Get all stat letters used in the cuts spec
 */
export function getStatLetters(cutsSpec: CutsSpec): string[] {
  return cutsSpec.cuts.map(c => c.statLetter);
}

/**
 * Get group names in order
 */
export function getGroupNames(cutsSpec: CutsSpec): string[] {
  return cutsSpec.groups.map(g => g.groupName);
}
