/**
 * LoopCollapser.ts
 *
 * Collapses looped wide-format variables into single base variables for the pipeline.
 * When a survey asks "Rate Drink 1" and "Rate Drink 2" (stored as A1_1, A2_1, A1_2, A2_2),
 * this module collapses them so A1, A2 each appear once in the datamap.
 *
 * The R script generator then uses LoopGroupMapping to create stacked data frames
 * in memory (one per loop group) for computing crosstab tables.
 *
 * Pure functions, no I/O.
 */

import type { LoopDetectionResult, LoopGroup } from './types';
import type { VerboseDataMap } from '../processors/DataMapProcessor';

// =============================================================================
// Types
// =============================================================================

export interface LoopVariableMapping {
  /** Collapsed base name used in the datamap (e.g., 'A1', 'A16r1') */
  baseName: string;
  /** Clean label from iteration 1 */
  label: string;
  /** Map of iteration value → original column name (e.g., { '1': 'A1_1', '2': 'A1_2' }) */
  iterationColumns: Record<string, string>;
}

export interface LoopGroupMapping {
  /** Skeleton pattern from LoopDetector (e.g., 'A-N-_-N') */
  skeleton: string;
  /** R variable name for the stacked data frame (e.g., 'stacked_loop_1') */
  stackedFrameName: string;
  /** Sorted iteration values (e.g., ['1', '2']) */
  iterations: string[];
  /** Per-variable mapping from base name to iteration columns */
  variables: LoopVariableMapping[];
}

export interface LoopCollapseResult {
  /** Datamap with loop variables collapsed to single base entries */
  collapsedDataMap: VerboseDataMap[];
  /** Mapping info needed by R script generator */
  loopMappings: LoopGroupMapping[];
  /** Set of original column names that were removed (replaced by base names) */
  collapsedVariableNames: Set<string>;
  /** Lookup: base name → index into loopMappings array */
  baseNameToLoopIndex: Map<string, number>;
}

// =============================================================================
// Core Functions
// =============================================================================

/**
 * Derive the collapsed base name from a LoopDetector base pattern.
 * Removes the wildcard `*` and any adjacent separator.
 *
 * Examples:
 *   'A1_*'       → 'A1'
 *   'A16_*r1'    → 'A16r1'
 *   'hCHANNEL_*r1' → 'hCHANNELr1'
 *   'A1_*r99oe'  → 'A1r99oe'
 */
export function deriveBaseName(basePattern: string): string {
  // The wildcard replaces the iterator value.
  // The base pattern format is like 'A1_*', 'A16_*r1', etc.
  // We need to remove '_*' (separator + wildcard)
  return basePattern.replace(/[_]*\*[_]*/g, '');
}

/**
 * Resolve a base pattern + iteration value to the original column name.
 *
 * Examples:
 *   resolveBaseToColumn('A1_*', '2') → 'A1_2'
 *   resolveBaseToColumn('A16_*r1', '3') → 'A16_3r1'
 */
export function resolveBaseToColumn(basePattern: string, iteration: string): string {
  return basePattern.replace('*', iteration);
}

/**
 * Clean a variable label by stripping the variable-name prefix pattern.
 * Many SPSS labels start with "A1_1: " or "A1_1 - " — we strip that.
 *
 * Examples:
 *   cleanLabel('A1_1: In a few words...', 'A1_1') → 'In a few words...'
 *   cleanLabel('Q3_2 - Rate your satisfaction', 'Q3_2') → 'Rate your satisfaction'
 *   cleanLabel('Just a normal label', 'A1_1') → 'Just a normal label'
 */
export function cleanLabel(label: string, originalVarName: string): string {
  if (!label) return label;

  // Try stripping "VARNAME: " or "VARNAME - " prefix
  const escapedVar = originalVarName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const prefixPattern = new RegExp(`^${escapedVar}\\s*[:\\-]\\s*`, 'i');
  const cleaned = label.replace(prefixPattern, '');

  return cleaned || label;
}

/**
 * Merge LoopGroups that share identical iteration values into unified groups.
 * Different skeletons (A-N-_-N vs A-N-_-N-r-N) are fine — they all stack the
 * same way once you know the iterator position. The skeleton-level detection is
 * an internal detail; the output should be one group per unique iteration set.
 */
export function mergeLoopGroups(loops: LoopGroup[]): LoopGroup[] {
  // Group by sorted iteration values (e.g., "1,2")
  const byIterations = new Map<string, LoopGroup[]>();
  for (const loop of loops) {
    const key = [...loop.iterations].sort((a, b) => +a - +b).join(',');
    const existing = byIterations.get(key) || [];
    existing.push(loop);
    byIterations.set(key, existing);
  }

  // Merge groups with same iterations
  const merged: LoopGroup[] = [];
  for (const [, groups] of byIterations) {
    if (groups.length === 1) {
      merged.push(groups[0]);
    } else {
      merged.push({
        skeleton: groups.map(g => g.skeleton).join(' + '),  // Informational only
        iteratorPosition: groups[0].iteratorPosition,        // Not used downstream
        iterations: groups[0].iterations,                    // Same for all
        bases: groups.flatMap(g => g.bases),
        variables: groups.flatMap(g => g.variables),
        diversity: groups.reduce((sum, g) => sum + g.diversity, 0),
      });
    }
  }
  return merged;
}

/**
 * Collapse loop variables in the datamap into single base entries.
 *
 * For each LoopGroup detected by LoopDetector:
 * 1. Iterate through bases (e.g., ['A1_*', 'A2_*', ...])
 * 2. Derive clean base name for each (A1_* → A1)
 * 3. Find iteration-1 variable in verbose datamap → copy its metadata
 * 4. Clean the label
 * 5. Build LoopVariableMapping with iteration→column mapping
 * 6. Replace all iteration-specific variables with single collapsed variable
 * 7. Non-loop variables pass through unchanged
 */
export function collapseLoopVariables(
  verboseDataMap: VerboseDataMap[],
  loopDetection: LoopDetectionResult,
): LoopCollapseResult {
  if (!loopDetection.hasLoops || loopDetection.loops.length === 0) {
    return {
      collapsedDataMap: [...verboseDataMap],
      loopMappings: [],
      collapsedVariableNames: new Set(),
      baseNameToLoopIndex: new Map(),
    };
  }

  // Merge skeleton-based groups that share the same iteration values
  const mergedLoops = mergeLoopGroups(loopDetection.loops);

  // Build lookup: column name → verbose variable
  const varByColumn = new Map<string, VerboseDataMap>();
  for (const v of verboseDataMap) {
    varByColumn.set(v.column, v);
  }

  // Track which original columns are consumed by loops
  const collapsedVariableNames = new Set<string>();
  const baseNameToLoopIndex = new Map<string, number>();
  const loopMappings: LoopGroupMapping[] = [];

  // Process each (merged) loop group
  for (let loopIdx = 0; loopIdx < mergedLoops.length; loopIdx++) {
    const loop = mergedLoops[loopIdx];
    const stackedFrameName = `stacked_loop_${loopIdx + 1}`;

    const variableMappings: LoopVariableMapping[] = [];

    for (const basePattern of loop.bases) {
      const baseName = deriveBaseName(basePattern);

      // Build iteration → column mapping
      const iterationColumns: Record<string, string> = {};
      for (const iter of loop.iterations) {
        const colName = resolveBaseToColumn(basePattern, iter);
        iterationColumns[iter] = colName;
        collapsedVariableNames.add(colName);
      }

      // Find the first available iteration's variable for metadata
      let sourceVar: VerboseDataMap | undefined;
      let sourceColName = '';
      for (const iter of loop.iterations) {
        const colName = iterationColumns[iter];
        sourceVar = varByColumn.get(colName);
        if (sourceVar) {
          sourceColName = colName;
          break;
        }
      }

      if (!sourceVar) continue; // Skip if no iteration found in datamap

      // Clean the label
      const cleanedLabel = cleanLabel(sourceVar.description, sourceColName);

      variableMappings.push({
        baseName,
        label: cleanedLabel,
        iterationColumns,
      });

      baseNameToLoopIndex.set(baseName, loopIdx);
    }

    loopMappings.push({
      skeleton: loop.skeleton,
      stackedFrameName,
      iterations: [...loop.iterations],
      variables: variableMappings,
    });
  }

  // Build collapsed datamap:
  // - Non-loop variables pass through unchanged
  // - Loop variables are replaced by a single collapsed entry at the position of the first iteration
  const collapsedDataMap: VerboseDataMap[] = [];
  const insertedBases = new Set<string>(); // Track which bases we've already inserted

  for (const v of verboseDataMap) {
    if (!collapsedVariableNames.has(v.column)) {
      // Non-loop variable — pass through
      collapsedDataMap.push(v);
    } else {
      // Loop variable — check if we need to insert the collapsed entry
      // Find which loop group and base this belongs to
      for (const mapping of loopMappings) {
        for (const varMapping of mapping.variables) {
          // Check if this column is the first iteration of this base
          const firstIter = mapping.iterations[0];
          if (varMapping.iterationColumns[firstIter] === v.column && !insertedBases.has(varMapping.baseName)) {
            // Insert collapsed variable at this position
            const collapsed: VerboseDataMap = {
              ...v,
              column: varMapping.baseName,
              description: varMapping.label,
              // Keep parent inference pointing to the base name
              parentQuestion: deriveBaseParent(v.parentQuestion, mapping),
            };
            collapsedDataMap.push(collapsed);
            insertedBases.add(varMapping.baseName);
          }
        }
      }
      // Other iterations are dropped (not inserted)
    }
  }

  return {
    collapsedDataMap,
    loopMappings,
    collapsedVariableNames,
    baseNameToLoopIndex,
  };
}

/**
 * Derive the collapsed parent question name.
 * If the parent is itself a loop variable, collapse it too.
 * Otherwise return as-is.
 */
function deriveBaseParent(parentQuestion: string, mapping: LoopGroupMapping): string {
  if (!parentQuestion) return parentQuestion;

  // Check if the parent matches any base pattern in this loop group
  for (const varMapping of mapping.variables) {
    for (const iter of mapping.iterations) {
      if (varMapping.iterationColumns[iter] === parentQuestion) {
        return varMapping.baseName;
      }
    }
  }

  return parentQuestion;
}
