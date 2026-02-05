/**
 * LoopDetector.ts
 *
 * Detects loop/iteration patterns in variable names using tokenization
 * and diversity analysis. Pure functions, no external dependencies.
 *
 * Algorithm:
 * 1. Tokenize each variable name into alpha/numeric/separator tokens
 * 2. Create a skeleton pattern (e.g., 'A4_1' → 'A-N-_-N')
 * 3. Group variables by skeleton
 * 4. For each numeric position, compute diversity (unique bases per iteration value)
 * 5. Iterator = position with highest diversity (>= 3 unique bases, >= 2 iterations)
 */

import type { Token, LoopGroup, LoopDetectionResult } from './types';

// =============================================================================
// Tokenization
// =============================================================================

/**
 * Tokenize a variable name into alpha, numeric, and separator tokens.
 * e.g., 'A4_1' → [{alpha,'A'}, {numeric,'4'}, {sep,'_'}, {numeric,'1'}]
 */
export function tokenize(varName: string): Token[] {
  const tokens: Token[] = [];
  let i = 0;

  while (i < varName.length) {
    const char = varName[i];

    if (/[a-zA-Z]/.test(char)) {
      // Collect consecutive alpha chars
      let value = '';
      while (i < varName.length && /[a-zA-Z]/.test(varName[i])) {
        value += varName[i];
        i++;
      }
      tokens.push({ type: 'alpha', value });
    } else if (/[0-9]/.test(char)) {
      // Collect consecutive digits
      let value = '';
      while (i < varName.length && /[0-9]/.test(varName[i])) {
        value += varName[i];
        i++;
      }
      tokens.push({ type: 'numeric', value });
    } else {
      // Separator (_, -, etc.)
      tokens.push({ type: 'separator', value: char });
      i++;
    }
  }

  return tokens;
}

/**
 * Create a skeleton pattern from tokens.
 * Replaces specific values with type indicators.
 * e.g., [{alpha,'A'}, {numeric,'4'}, {sep,'_'}, {numeric,'1'}] → 'A-N-_-N'
 *
 * Alpha tokens keep their value (they distinguish question stems).
 * Numeric tokens become 'N'.
 * Separator tokens keep their value.
 */
export function createSkeleton(tokens: Token[]): string {
  return tokens
    .map((t) => {
      switch (t.type) {
        case 'alpha':
          return t.value;
        case 'numeric':
          return 'N';
        case 'separator':
          return t.value;
      }
    })
    .join('-');
}

// =============================================================================
// Loop Detection
// =============================================================================

/**
 * Detect loop patterns in a list of variable names.
 */
export function detectLoops(variableNames: string[]): LoopDetectionResult {
  if (variableNames.length === 0) {
    return { hasLoops: false, loops: [], nonLoopVariables: [] };
  }

  // Step 1: Tokenize and group by skeleton
  const tokenized = variableNames.map((name) => ({
    name,
    tokens: tokenize(name),
    skeleton: '',
  }));

  for (const item of tokenized) {
    item.skeleton = createSkeleton(item.tokens);
  }

  // Group by skeleton
  const skeletonGroups = new Map<string, typeof tokenized>();
  for (const item of tokenized) {
    const group = skeletonGroups.get(item.skeleton) || [];
    group.push(item);
    skeletonGroups.set(item.skeleton, group);
  }

  // Step 2: For each group with multiple members, analyze numeric positions
  const detectedLoops: LoopGroup[] = [];
  const loopVariableSet = new Set<string>();

  for (const [skeleton, members] of skeletonGroups.entries()) {
    // Need at least 3 variables to consider a loop group
    if (members.length < 3) continue;

    // Find numeric token positions
    const sampleTokens = members[0].tokens;
    const numericPositions: number[] = [];
    for (let i = 0; i < sampleTokens.length; i++) {
      if (sampleTokens[i].type === 'numeric') {
        numericPositions.push(i);
      }
    }

    if (numericPositions.length < 2) continue; // Need at least 2 numeric positions for a loop

    // Step 3: For each numeric position, compute diversity.
    // Only consider positions preceded by a separator (like '_') as loop iterator candidates.
    // This filters out grid dimensions (r1, c1) which are preceded by alpha tokens.
    const loopCandidatePositions = numericPositions.filter((pos) => {
      if (pos === 0) return true; // First position is always a candidate
      return sampleTokens[pos - 1].type === 'separator';
    });

    let bestPosition = -1;
    let bestDiversity = 0;
    let bestIterations: string[] = [];
    let bestBases: string[] = [];

    for (const pos of loopCandidatePositions) {
      // Group by the value at this position → for each value, collect unique bases
      const iterationToVariables = new Map<string, Set<string>>();

      for (const member of members) {
        const iterValue = member.tokens[pos].value;

        // Build the base by replacing this position's value with a placeholder
        const baseParts = member.tokens.map((t, i) =>
          i === pos ? '*' : t.value
        );
        const base = baseParts.join('');

        if (!iterationToVariables.has(iterValue)) {
          iterationToVariables.set(iterValue, new Set());
        }
        iterationToVariables.get(iterValue)!.add(base);
      }

      const iterations = Array.from(iterationToVariables.keys());
      if (iterations.length < 2) continue; // Need at least 2 iterations

      // Diversity = number of unique bases across all iterations
      const allBases = new Set<string>();
      for (const bases of iterationToVariables.values()) {
        for (const base of bases) {
          allBases.add(base);
        }
      }
      const diversity = allBases.size;

      if (diversity > bestDiversity) {
        bestDiversity = diversity;
        bestPosition = pos;
        bestIterations = iterations.sort((a, b) => parseInt(a) - parseInt(b));
        bestBases = Array.from(allBases).sort();
      }
    }

    // Step 4: Apply thresholds
    if (bestDiversity >= 3 && bestIterations.length >= 2) {
      const loop: LoopGroup = {
        skeleton,
        iteratorPosition: bestPosition,
        iterations: bestIterations,
        bases: bestBases,
        variables: members.map((m) => m.name),
        diversity: bestDiversity,
      };

      detectedLoops.push(loop);
      for (const member of members) {
        loopVariableSet.add(member.name);
      }
    }
  }

  // Collect non-loop variables
  const nonLoopVariables = variableNames.filter(
    (name) => !loopVariableSet.has(name)
  );

  return {
    hasLoops: detectedLoops.length > 0,
    loops: detectedLoops,
    nonLoopVariables,
  };
}
