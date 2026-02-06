import { describe, it, expect } from 'vitest';
import {
  deriveBaseName,
  resolveBaseToColumn,
  cleanLabel,
  collapseLoopVariables,
} from '../LoopCollapser';
import type { LoopDetectionResult } from '../types';
import type { VerboseDataMap } from '../../processors/DataMapProcessor';

// =============================================================================
// Helper to create a minimal VerboseDataMap variable
// =============================================================================

function makeVar(column: string, description: string, overrides?: Partial<VerboseDataMap>): VerboseDataMap {
  return {
    level: 'sub',
    column,
    description,
    valueType: 'numeric',
    answerOptions: '1=Yes, 2=No',
    parentQuestion: '',
    ...overrides,
  };
}

// =============================================================================
// deriveBaseName
// =============================================================================

describe('deriveBaseName', () => {
  it('simple: A1_* → A1', () => {
    expect(deriveBaseName('A1_*')).toBe('A1');
  });

  it('grid+loop: A16_*r1 → A16r1', () => {
    expect(deriveBaseName('A16_*r1')).toBe('A16r1');
  });

  it('named prefix: hCHANNEL_*r1 → hCHANNELr1', () => {
    expect(deriveBaseName('hCHANNEL_*r1')).toBe('hCHANNELr1');
  });

  it('OE suffix: A13_*r99oe → A13r99oe', () => {
    expect(deriveBaseName('A13_*r99oe')).toBe('A13r99oe');
  });

  it('no separator before wildcard: A*r1 → Ar1', () => {
    expect(deriveBaseName('A*r1')).toBe('Ar1');
  });
});

// =============================================================================
// resolveBaseToColumn
// =============================================================================

describe('resolveBaseToColumn', () => {
  it('simple: A1_* + 2 → A1_2', () => {
    expect(resolveBaseToColumn('A1_*', '2')).toBe('A1_2');
  });

  it('grid+loop: A16_*r1 + 3 → A16_3r1', () => {
    expect(resolveBaseToColumn('A16_*r1', '3')).toBe('A16_3r1');
  });

  it('named prefix: hCHANNEL_*r1 + 1 → hCHANNEL_1r1', () => {
    expect(resolveBaseToColumn('hCHANNEL_*r1', '1')).toBe('hCHANNEL_1r1');
  });
});

// =============================================================================
// cleanLabel
// =============================================================================

describe('cleanLabel', () => {
  it('strips "VAR: " prefix', () => {
    expect(cleanLabel('A1_1: In a few words, describe...', 'A1_1'))
      .toBe('In a few words, describe...');
  });

  it('strips "VAR - " prefix', () => {
    expect(cleanLabel('Q3_2 - Rate your satisfaction', 'Q3_2'))
      .toBe('Rate your satisfaction');
  });

  it('leaves label without prefix unchanged', () => {
    expect(cleanLabel('Just a normal label', 'A1_1'))
      .toBe('Just a normal label');
  });

  it('handles empty label', () => {
    expect(cleanLabel('', 'A1_1')).toBe('');
  });

  it('strips prefix case-insensitively', () => {
    expect(cleanLabel('a1_1: something', 'A1_1')).toBe('something');
  });
});

// =============================================================================
// collapseLoopVariables
// =============================================================================

describe('collapseLoopVariables', () => {
  it('returns unchanged datamap when no loops detected', () => {
    const vars = [makeVar('S1', 'Gender'), makeVar('S2', 'Age')];
    const detection: LoopDetectionResult = {
      hasLoops: false,
      loops: [],
      nonLoopVariables: ['S1', 'S2'],
    };

    const result = collapseLoopVariables(vars, detection);
    expect(result.collapsedDataMap).toHaveLength(2);
    expect(result.loopMappings).toHaveLength(0);
    expect(result.collapsedVariableNames.size).toBe(0);
  });

  it('collapses simple loop: A1_1, A2_1, A1_2, A2_2 → A1, A2', () => {
    const vars = [
      makeVar('A1_1', 'A1_1: Rate drink 1'),
      makeVar('A2_1', 'A2_1: Describe drink 1'),
      makeVar('A1_2', 'A1_2: Rate drink 2'),
      makeVar('A2_2', 'A2_2: Describe drink 2'),
    ];

    const detection: LoopDetectionResult = {
      hasLoops: true,
      loops: [{
        skeleton: 'A-N-_-N',
        iteratorPosition: 3,  // The last numeric token position
        iterations: ['1', '2'],
        bases: ['A1_*', 'A2_*'],
        variables: ['A1_1', 'A2_1', 'A1_2', 'A2_2'],
        diversity: 2,
      }],
      nonLoopVariables: [],
    };

    const result = collapseLoopVariables(vars, detection);

    // Should have 2 collapsed variables instead of 4
    expect(result.collapsedDataMap).toHaveLength(2);
    expect(result.collapsedDataMap[0].column).toBe('A1');
    expect(result.collapsedDataMap[1].column).toBe('A2');

    // Labels should be cleaned
    expect(result.collapsedDataMap[0].description).toBe('Rate drink 1');
    expect(result.collapsedDataMap[1].description).toBe('Describe drink 1');

    // Loop mappings
    expect(result.loopMappings).toHaveLength(1);
    expect(result.loopMappings[0].stackedFrameName).toBe('stacked_loop_1');
    expect(result.loopMappings[0].iterations).toEqual(['1', '2']);
    expect(result.loopMappings[0].variables).toHaveLength(2);

    // Variable mapping
    const v1 = result.loopMappings[0].variables[0];
    expect(v1.baseName).toBe('A1');
    expect(v1.iterationColumns).toEqual({ '1': 'A1_1', '2': 'A1_2' });

    // Collapsed names
    expect(result.collapsedVariableNames.has('A1_1')).toBe(true);
    expect(result.collapsedVariableNames.has('A1_2')).toBe(true);

    // baseNameToLoopIndex
    expect(result.baseNameToLoopIndex.get('A1')).toBe(0);
    expect(result.baseNameToLoopIndex.get('A2')).toBe(0);
  });

  it('preserves non-loop variables alongside collapsed ones', () => {
    const vars = [
      makeVar('S1', 'Gender'),
      makeVar('A1_1', 'A1_1: Rate drink 1'),
      makeVar('A2_1', 'A2_1: Describe drink 1'),
      makeVar('A1_2', 'A1_2: Rate drink 2'),
      makeVar('A2_2', 'A2_2: Describe drink 2'),
      makeVar('S2', 'Age'),
    ];

    const detection: LoopDetectionResult = {
      hasLoops: true,
      loops: [{
        skeleton: 'A-N-_-N',
        iteratorPosition: 3,
        iterations: ['1', '2'],
        bases: ['A1_*', 'A2_*'],
        variables: ['A1_1', 'A2_1', 'A1_2', 'A2_2'],
        diversity: 2,
      }],
      nonLoopVariables: ['S1', 'S2'],
    };

    const result = collapseLoopVariables(vars, detection);

    // S1, A1, A2, S2 (collapsed loop vars appear where iteration 1 was)
    expect(result.collapsedDataMap).toHaveLength(4);
    expect(result.collapsedDataMap.map(v => v.column)).toEqual(['S1', 'A1', 'A2', 'S2']);
  });

  it('handles multiple independent loop groups', () => {
    const vars = [
      makeVar('A1_1', 'Rate drink 1'), makeVar('A2_1', 'Describe drink 1'),
      makeVar('A1_2', 'Rate drink 2'), makeVar('A2_2', 'Describe drink 2'),
      makeVar('B1_1', 'Rate brand 1'), makeVar('B2_1', 'Describe brand 1'),
      makeVar('B1_2', 'Rate brand 2'), makeVar('B2_2', 'Describe brand 2'),
      makeVar('B1_3', 'Rate brand 3'), makeVar('B2_3', 'Describe brand 3'),
    ];

    const detection: LoopDetectionResult = {
      hasLoops: true,
      loops: [
        {
          skeleton: 'A-N-_-N',
          iteratorPosition: 3,
          iterations: ['1', '2'],
          bases: ['A1_*', 'A2_*'],
          variables: ['A1_1', 'A2_1', 'A1_2', 'A2_2'],
          diversity: 2,
        },
        {
          skeleton: 'B-N-_-N',
          iteratorPosition: 3,
          iterations: ['1', '2', '3'],
          bases: ['B1_*', 'B2_*'],
          variables: ['B1_1', 'B2_1', 'B1_2', 'B2_2', 'B1_3', 'B2_3'],
          diversity: 2,
        },
      ],
      nonLoopVariables: [],
    };

    const result = collapseLoopVariables(vars, detection);

    // Two loop groups → two mappings
    expect(result.loopMappings).toHaveLength(2);
    expect(result.loopMappings[0].stackedFrameName).toBe('stacked_loop_1');
    expect(result.loopMappings[1].stackedFrameName).toBe('stacked_loop_2');

    // 4 collapsed variables total (A1, A2, B1, B2)
    expect(result.collapsedDataMap).toHaveLength(4);

    // baseNameToLoopIndex correctly maps to different loop groups
    expect(result.baseNameToLoopIndex.get('A1')).toBe(0);
    expect(result.baseNameToLoopIndex.get('B1')).toBe(1);
  });

  it('handles non-contiguous iterations', () => {
    const vars = [
      makeVar('A1_1', 'Q1 iter 1'), makeVar('A2_1', 'Q2 iter 1'),
      makeVar('A1_3', 'Q1 iter 3'), makeVar('A2_3', 'Q2 iter 3'),
      makeVar('A1_8', 'Q1 iter 8'), makeVar('A2_8', 'Q2 iter 8'),
    ];

    const detection: LoopDetectionResult = {
      hasLoops: true,
      loops: [{
        skeleton: 'A-N-_-N',
        iteratorPosition: 3,
        iterations: ['1', '3', '8'],
        bases: ['A1_*', 'A2_*'],
        variables: ['A1_1', 'A2_1', 'A1_3', 'A2_3', 'A1_8', 'A2_8'],
        diversity: 2,
      }],
      nonLoopVariables: [],
    };

    const result = collapseLoopVariables(vars, detection);

    expect(result.loopMappings[0].iterations).toEqual(['1', '3', '8']);
    expect(result.loopMappings[0].variables[0].iterationColumns).toEqual({
      '1': 'A1_1', '3': 'A1_3', '8': 'A1_8',
    });
  });

  it('handles grid+loop collapse: A16_1r1, A16_1r2, A16_2r1, A16_2r2', () => {
    const vars = [
      makeVar('A16_1r1', 'A16_1r1: Rate attr 1'),
      makeVar('A16_1r2', 'A16_1r2: Rate attr 2'),
      makeVar('A16_2r1', 'A16_2r1: Rate attr 1'),
      makeVar('A16_2r2', 'A16_2r2: Rate attr 2'),
    ];

    const detection: LoopDetectionResult = {
      hasLoops: true,
      loops: [{
        skeleton: 'A-N-_-N-r-N',
        iteratorPosition: 3, // The position of the iteration number (after _)
        iterations: ['1', '2'],
        bases: ['A16_*r1', 'A16_*r2'],
        variables: ['A16_1r1', 'A16_1r2', 'A16_2r1', 'A16_2r2'],
        diversity: 2,
      }],
      nonLoopVariables: [],
    };

    const result = collapseLoopVariables(vars, detection);

    expect(result.collapsedDataMap).toHaveLength(2);
    expect(result.collapsedDataMap[0].column).toBe('A16r1');
    expect(result.collapsedDataMap[1].column).toBe('A16r2');

    expect(result.loopMappings[0].variables[0].iterationColumns).toEqual({
      '1': 'A16_1r1', '2': 'A16_2r1',
    });
  });

  it('copies metadata from iteration-1 variable', () => {
    const vars = [
      makeVar('A1_1', 'Rate drink 1', {
        valueType: 'numeric',
        answerOptions: '1=Poor, 2=Fair, 3=Good, 4=Excellent',
        parentQuestion: 'A1_1',
        normalizedType: 'ordinal_scale',
      }),
      makeVar('A1_2', 'Rate drink 2', {
        valueType: 'numeric',
        answerOptions: '1=Poor, 2=Fair, 3=Good, 4=Excellent',
        parentQuestion: 'A1_2',
        normalizedType: 'ordinal_scale',
      }),
      makeVar('A2_1', 'Describe drink 1'),
      makeVar('A2_2', 'Describe drink 2'),
    ];

    const detection: LoopDetectionResult = {
      hasLoops: true,
      loops: [{
        skeleton: 'A-N-_-N',
        iteratorPosition: 3,
        iterations: ['1', '2'],
        bases: ['A1_*', 'A2_*'],
        variables: ['A1_1', 'A2_1', 'A1_2', 'A2_2'],
        diversity: 2,
      }],
      nonLoopVariables: [],
    };

    const result = collapseLoopVariables(vars, detection);

    // Collapsed A1 should have iteration-1's metadata
    const collapsedA1 = result.collapsedDataMap.find(v => v.column === 'A1')!;
    expect(collapsedA1.answerOptions).toBe('1=Poor, 2=Fair, 3=Good, 4=Excellent');
    expect(collapsedA1.normalizedType).toBe('ordinal_scale');
  });
});
