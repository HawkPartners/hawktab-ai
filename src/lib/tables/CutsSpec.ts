import type { ValidationResultType } from '@/schemas/agentOutputSchema';

export type CutDefinition = {
  id: string;
  name: string;
  rExpression: string;
};

export type CutsSpec = {
  cuts: CutDefinition[];
};

function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

export function buildCutsSpec(validation: ValidationResultType): CutsSpec {
  const cuts: CutDefinition[] = [];
  for (const group of validation.bannerCuts) {
    for (const col of group.columns) {
      const id = `${slugify(group.groupName)}.${slugify(col.name)}`;
      cuts.push({ id, name: col.name, rExpression: col.adjusted });
    }
  }
  return { cuts };
}


