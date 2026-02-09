#!/usr/bin/env npx tsx
/**
 * Resume Pipeline from Loop Semantics Stage
 *
 * Loads saved pipeline artifacts and re-runs from the LoopSemanticsPolicyAgent
 * through R script generation, R execution, and Excel generation.
 * Avoids re-running expensive agent calls (Banner, Crosstab, SkipLogic, Filter, Verification).
 *
 * Usage:
 *   npx tsx scripts/test-loop-semantics-resume.ts [dataset] [pipelineId]
 *
 * Examples:
 *   npx tsx scripts/test-loop-semantics-resume.ts
 *     -> Uses most recent pipeline from first dataset in outputs/
 *
 *   npx tsx scripts/test-loop-semantics-resume.ts titos-growth-strategy
 *     -> Uses most recent pipeline from that dataset
 *
 *   npx tsx scripts/test-loop-semantics-resume.ts titos-growth-strategy pipeline-2026-02-08T07-04-55-204Z
 *     -> Uses specific pipeline
 */

// Load environment variables
import '../src/lib/loadEnv';

import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';
import { generateRScriptV2WithValidation } from '../src/lib/r/RScriptGeneratorV2';
import { formatTablesFileToBuffer } from '../src/lib/excel/ExcelFormatter';
import { runLoopSemanticsPolicyAgent, buildDatamapExcerpt } from '../src/agents/LoopSemanticsPolicyAgent';
import type { LoopSemanticsPolicy } from '../src/schemas/loopSemanticsPolicySchema';
import type { ExtendedTableDefinition, TableWithLoopFrame } from '../src/schemas/verificationAgentSchema';
import type { CutDefinition, CutGroup } from '../src/lib/tables/CutsSpec';
import type { LoopGroupMapping } from '../src/lib/validation/LoopCollapser';
import type { DeterministicResolverResult } from '../src/lib/validation/LoopContextResolver';
import type { VerboseDataMap } from '../src/lib/processors/DataMapProcessor';

// =============================================================================
// Console Colors
// =============================================================================

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
  magenta: '\x1b[35m',
};

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

// =============================================================================
// Parse Arguments
// =============================================================================

const args = process.argv.slice(2).filter(arg => !arg.startsWith('--'));
const argDataset = args[0];
const argPipelineId = args[1];

const OUTPUTS_DIR = path.join(process.cwd(), 'outputs');

// =============================================================================
// File Discovery (reused from test-r-regenerate.ts)
// =============================================================================

async function findDatasets(): Promise<string[]> {
  try {
    const entries = await fs.readdir(OUTPUTS_DIR, { withFileTypes: true });
    return entries
      .filter(e => e.isDirectory() && !e.name.startsWith('.'))
      .map(e => e.name)
      .sort();
  } catch {
    return [];
  }
}

async function findMostRecentPipeline(dataset: string): Promise<string | null> {
  const datasetPath = path.join(OUTPUTS_DIR, dataset);
  try {
    const entries = await fs.readdir(datasetPath, { withFileTypes: true });
    const pipelines = entries
      .filter(e => e.isDirectory() && e.name.startsWith('pipeline-'))
      .map(e => e.name)
      .sort()
      .reverse();
    return pipelines[0] || null;
  } catch {
    return null;
  }
}

async function findNextOutputPath(
  dir: string,
  baseName: string,
  ext: string
): Promise<{ path: string; index: number }> {
  try {
    const entries = await fs.readdir(dir);
    const existing = entries.filter(e => e.startsWith(baseName) && e.endsWith(ext));
    if (existing.length === 0) {
      return { path: path.join(dir, `${baseName}-1${ext}`), index: 1 };
    }
    let maxNum = 0;
    for (const file of existing) {
      const match = file.match(new RegExp(`^${baseName}(?:-(\\d+))?\\${ext}$`));
      if (match) {
        const num = match[1] ? parseInt(match[1], 10) : 0;
        maxNum = Math.max(maxNum, num);
      }
    }
    const nextIndex = maxNum + 1;
    return { path: path.join(dir, `${baseName}-${nextIndex}${ext}`), index: nextIndex };
  } catch {
    return { path: path.join(dir, `${baseName}-1${ext}`), index: 1 };
  }
}

async function findJsonFile(dir: string, pattern: string): Promise<string | null> {
  try {
    const files = await fs.readdir(dir);
    const match = files.find(f => f.includes(pattern) && f.endsWith('.json'));
    if (match) return path.join(dir, match);
  } catch { /* Directory doesn't exist */ }
  return null;
}

async function findSpssFile(dataset: string): Promise<string | null> {
  // Check data/test-data/<dataset>/ first, then data/<dataset>/inputs/
  const testDataDir = path.join(process.cwd(), 'data', 'test-data', dataset);
  try {
    const files = await fs.readdir(testDataDir);
    const spssFile = files.find(f => f.endsWith('.sav'));
    if (spssFile) return path.join(testDataDir, spssFile);
  } catch { /* not found */ }

  const inputsDir = path.join(process.cwd(), 'data', dataset, 'inputs');
  try {
    const files = await fs.readdir(inputsDir);
    const spssFile = files.find(f => f.endsWith('.sav'));
    if (spssFile) return path.join(inputsDir, spssFile);
  } catch { /* not found */ }

  return null;
}

// =============================================================================
// Load Pipeline Data
// =============================================================================

interface CrosstabOutput {
  bannerCuts: Array<{
    groupName: string;
    columns: Array<{
      name: string;
      adjusted: string;
      confidence: number;
      reason: string;
    }>;
  }>;
}

function loadCutsFromCrosstabOutput(data: CrosstabOutput): { cuts: CutDefinition[]; cutGroups: CutGroup[] } {
  const cuts: CutDefinition[] = [];
  const cutGroups: CutGroup[] = [];

  const totalCut: CutDefinition = {
    id: 'total.total',
    name: 'Total',
    rExpression: 'rep(TRUE, nrow(data))',
    statLetter: 'T',
    groupName: 'Total',
    groupIndex: 0,
  };
  cuts.push(totalCut);
  cutGroups.push({ groupName: 'Total', cuts: [totalCut] });

  let letterIndex = 0;
  const getNextLetter = () => {
    if (letterIndex < 26) {
      return String.fromCharCode(65 + letterIndex++);
    }
    const first = Math.floor(letterIndex / 26) - 1;
    const second = letterIndex % 26;
    letterIndex++;
    return String.fromCharCode(65 + first) + String.fromCharCode(65 + second);
  };

  for (const group of data.bannerCuts || []) {
    const groupCutDefs: CutDefinition[] = [];
    for (let i = 0; i < (group.columns || []).length; i++) {
      const col = group.columns[i];
      if (col.name && col.adjusted && col.confidence > 0) {
        if (col.name === 'Total' || group.groupName === 'Total') continue;
        const statLetter = getNextLetter();
        const cutDef: CutDefinition = {
          id: `${group.groupName.toLowerCase().replace(/\s+/g, '-')}.${col.name.toLowerCase().replace(/\s+/g, '_').replace(/[^a-z0-9_]/g, '')}`,
          name: col.name,
          rExpression: col.adjusted,
          statLetter,
          groupName: group.groupName,
          groupIndex: i,
        };
        cuts.push(cutDef);
        groupCutDefs.push(cutDef);
      }
    }
    if (groupCutDefs.length > 0) {
      cutGroups.push({ groupName: group.groupName, cuts: groupCutDefs });
    }
  }
  return { cuts, cutGroups };
}

// =============================================================================
// Run R Script
// =============================================================================

async function runRScript(scriptPath: string, workingDir: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const rscriptPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
    let rscriptPath = 'Rscript';
    for (const p of rscriptPaths) {
      try {
        require('child_process').execSync(`${p} --version`, { stdio: 'ignore' });
        rscriptPath = p;
        break;
      } catch { /* try next */ }
    }

    log(`  Running: ${rscriptPath} ${path.basename(scriptPath)}`, 'dim');
    const proc = spawn(rscriptPath, [scriptPath], { cwd: workingDir });

    let stderr = '';
    proc.stdout.on('data', (data) => { process.stdout.write(data); });
    proc.stderr.on('data', (data) => {
      stderr += data.toString();
      const msg = data.toString();
      if (!msg.includes('Attaching package') && !msg.includes('masked from')) {
        process.stderr.write(data);
      }
    });
    proc.on('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`R script failed with code ${code}\n${stderr}`));
    });
    proc.on('error', reject);
  });
}

// =============================================================================
// Main
// =============================================================================

async function main() {
  const startTime = Date.now();

  log('');
  log('======================================================================', 'magenta');
  log('  Resume Pipeline: Loop Semantics → R → Excel', 'bright');
  log('======================================================================', 'magenta');
  log('');

  // 1. Find source pipeline
  log('[1/6] Finding source pipeline...', 'cyan');

  let dataset = argDataset;
  let pipelineId = argPipelineId;

  if (!dataset) {
    const datasets = await findDatasets();
    if (datasets.length === 0) { log('No datasets found in outputs/', 'red'); process.exit(1); }
    dataset = datasets[0];
    log(`  Using dataset: ${dataset}`, 'dim');
  }

  if (!pipelineId) {
    const found = await findMostRecentPipeline(dataset);
    if (!found) { log(`No pipeline folders found in outputs/${dataset}/`, 'red'); process.exit(1); }
    pipelineId = found;
    log(`  Using most recent pipeline: ${pipelineId}`, 'dim');
  }

  const pipelinePath = path.join(OUTPUTS_DIR, dataset, pipelineId);
  try { await fs.access(pipelinePath); } catch {
    log(`Pipeline not found: ${pipelinePath}`, 'red');
    process.exit(1);
  }
  log(`  Source: outputs/${dataset}/${pipelineId}`, 'blue');

  // 2. Load saved artifacts
  log('');
  log('[2/6] Loading pipeline artifacts...', 'cyan');

  // Tables from verification
  const verificationDir = path.join(pipelinePath, 'verification');
  let tablesFile = await findJsonFile(verificationDir, 'verified-table-output');
  if (!tablesFile) tablesFile = await findJsonFile(verificationDir, 'verification-output-raw');
  if (!tablesFile) { log('  Missing: verification tables', 'red'); process.exit(1); }

  const rawData = JSON.parse(await fs.readFile(tablesFile, 'utf-8'));
  const rawTables: ExtendedTableDefinition[] = rawData.tables || [];
  let tables: TableWithLoopFrame[] = rawTables.map(t => ({ ...t, loopDataFrame: '' }));
  log(`  Tables: ${tables.length} from verification`, 'green');

  // Cuts from crosstab
  const crosstabDir = path.join(pipelinePath, 'crosstab');
  const crosstabFile = await findJsonFile(crosstabDir, 'crosstab-output');
  if (!crosstabFile) { log('  Missing: crosstab output', 'red'); process.exit(1); }
  const crosstabData: CrosstabOutput = JSON.parse(await fs.readFile(crosstabFile, 'utf-8'));
  const { cuts, cutGroups } = loadCutsFromCrosstabOutput(crosstabData);
  log(`  Cuts: ${cuts.length} in ${cutGroups.length} groups`, 'green');

  // Loop summary
  const loopSummaryPath = path.join(pipelinePath, 'loop-summary.json');
  let loopMappings: LoopGroupMapping[] = [];
  try {
    const loopSummary = JSON.parse(await fs.readFile(loopSummaryPath, 'utf-8'));
    loopMappings = (loopSummary.groups || []).map((g: any) => ({
      skeleton: g.skeleton,
      stackedFrameName: g.stackedFrameName,
      iterations: g.iterations,
      variables: g.variables.map((v: any) => ({
        baseName: v.baseName,
        label: v.label,
        iterationColumns: v.iterationColumns,
      })),
    }));
    log(`  Loop groups: ${loopMappings.length} (${loopMappings.map(m => `${m.stackedFrameName}: ${m.variables.length} vars x ${m.iterations.length} iters`).join(', ')})`, 'green');
  } catch {
    log('  No loop summary found — non-loop dataset', 'yellow');
  }

  // Deterministic resolver findings
  let deterministicFindings: DeterministicResolverResult = { iterationLinkedVariables: [], evidenceSummary: '' };
  const resolverPath = path.join(pipelinePath, 'loop-policy', 'deterministic-resolver.json');
  try {
    deterministicFindings = JSON.parse(await fs.readFile(resolverPath, 'utf-8'));
    log(`  Deterministic findings: ${deterministicFindings.iterationLinkedVariables.length} iteration-linked vars`, 'green');
  } catch {
    log('  No deterministic resolver findings found', 'yellow');
  }

  // Verbose datamap
  let verboseDataMap: VerboseDataMap[] = [];
  const datamapFile = await findJsonFile(pipelinePath, 'verbose');
  if (datamapFile) {
    verboseDataMap = JSON.parse(await fs.readFile(datamapFile, 'utf-8'));
    log(`  Datamap: ${verboseDataMap.length} variables`, 'green');
  } else {
    log('  No verbose datamap found', 'yellow');
  }

  // Tag tables with loop data frames (matches PipelineRunner logic — checks ALL rows)
  if (loopMappings.length > 0) {
    const baseNameToLoopIndex = new Map<string, number>();
    for (let i = 0; i < loopMappings.length; i++) {
      for (const v of loopMappings[i].variables) {
        baseNameToLoopIndex.set(v.baseName, i);
      }
    }

    let taggedCount = 0;
    tables = tables.map(t => {
      let loopDataFrame = '';
      for (const row of (t.rows || [])) {
        const loopIdx = baseNameToLoopIndex.get(row.variable);
        if (loopIdx !== undefined) {
          loopDataFrame = loopMappings[loopIdx].stackedFrameName;
          taggedCount++;
          break;
        }
      }
      return { ...t, loopDataFrame };
    });
    log(`  Tagged ${taggedCount} tables with loop data frames`, 'dim');
  }

  // 3. Run LoopSemanticsPolicyAgent
  log('');
  log('[3/6] Running LoopSemanticsPolicyAgent...', 'cyan');

  let loopSemanticsPolicy: LoopSemanticsPolicy | undefined;

  if (loopMappings.length > 0) {
    const agentStart = Date.now();

    try {
      loopSemanticsPolicy = await runLoopSemanticsPolicyAgent({
        loopSummary: loopMappings.map(m => ({
          stackedFrameName: m.stackedFrameName,
          iterations: m.iterations,
          variableCount: m.variables.length,
          skeleton: m.skeleton,
        })),
        bannerGroups: cutGroups.filter(g => g.groupName !== 'Total').map(g => ({
          groupName: g.groupName,
          columns: g.cuts.map(c => ({ name: c.name, original: c.name })),
        })),
        cuts: cuts.filter(c => c.name !== 'Total').map(c => ({
          name: c.name,
          groupName: c.groupName,
          rExpression: c.rExpression,
        })),
        deterministicFindings,
        datamapExcerpt: buildDatamapExcerpt(verboseDataMap, cuts, deterministicFindings),
        outputDir: pipelinePath,
      });

      // Save policy
      const loopPolicyDir = path.join(pipelinePath, 'loop-policy');
      await fs.mkdir(loopPolicyDir, { recursive: true });
      await fs.writeFile(
        path.join(loopPolicyDir, 'loop-semantics-policy.json'),
        JSON.stringify(loopSemanticsPolicy, null, 2),
        'utf-8',
      );

      const entityGroups = loopSemanticsPolicy.bannerGroups.filter(g => g.anchorType === 'entity');
      log(`  ${entityGroups.length} entity-anchored, ${loopSemanticsPolicy.bannerGroups.length - entityGroups.length} respondent-anchored`, 'green');

      const minGroupConfidence = Math.min(...loopSemanticsPolicy.bannerGroups.map(g => g.confidence));
      if (minGroupConfidence < 0.80) {
        log(`  WARNING: Human review recommended (min confidence: ${minGroupConfidence.toFixed(2)})`, 'yellow');
      }

      for (const bg of loopSemanticsPolicy.bannerGroups) {
        const anchor = bg.anchorType === 'entity' ? '🔗 entity' : '👤 respondent';
        log(`    ${bg.groupName}: ${anchor} (confidence: ${bg.confidence})`, 'dim');
        if (bg.implementation.aliasName) {
          log(`      alias: ${bg.implementation.aliasName} -> ${bg.implementation.sourcesByIteration.map(s => `${s.iteration}:${s.variable}`).join(', ')}`, 'dim');
        }
      }

      log(`  Duration: ${Date.now() - agentStart}ms`, 'dim');
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      log(`  LoopSemanticsPolicyAgent failed: ${errMsg}`, 'red');
      log(`  Proceeding without loop semantics policy`, 'yellow');
    }
  } else {
    log('  Skipping — no loop groups detected', 'yellow');
  }

  // 4. Find SPSS file and copy to pipeline
  const spssSourcePath = await findSpssFile(dataset);
  if (!spssSourcePath) { log(`  Missing: SPSS file for ${dataset}`, 'red'); process.exit(1); }
  const spssDestPath = path.join(pipelinePath, 'dataFile.sav');
  await fs.copyFile(spssSourcePath, spssDestPath);
  log(`  Copied SPSS data to pipeline folder`, 'dim');

  // 5. Generate R script
  log('');
  log('[4/6] Generating R script...', 'cyan');

  const rDir = path.join(pipelinePath, 'r');
  await fs.mkdir(rDir, { recursive: true });

  const { index: regenerationIndex } = await findNextOutputPath(rDir, 'master', '.R');

  const { script: rScript } = generateRScriptV2WithValidation(
    {
      tables,
      cuts,
      cutGroups,
      dataFilePath: 'dataFile.sav',
      significanceLevel: 0.10,
      bannerGroups: cutGroups.map(g => ({
        groupName: g.groupName,
        columns: g.cuts.map(c => ({ name: c.name, statLetter: c.statLetter })),
      })),
      loopMappings: loopMappings.length > 0 ? loopMappings : undefined,
      loopSemanticsPolicy,
    },
    { sessionId: path.basename(pipelinePath), outputDir: 'results' }
  );

  const rScriptPath = path.join(rDir, `master-${regenerationIndex}.R`);
  await fs.writeFile(rScriptPath, rScript);
  log(`  Saved: r/master-${regenerationIndex}.R (${Math.round(rScript.length / 1024)} KB)`, 'green');

  // 6. Run R script
  log('');
  log('[5/6] Running R script...', 'cyan');

  const resultsDir = path.join(pipelinePath, 'results');
  await fs.mkdir(resultsDir, { recursive: true });

  try {
    await runRScript(rScriptPath, pipelinePath);
    log('  R script completed', 'green');

    // Rename tables.json to tables-N.json
    const tablesJsonPath = path.join(resultsDir, 'tables.json');
    const tablesJsonNewPath = path.join(resultsDir, `tables-${regenerationIndex}.json`);
    try {
      await fs.access(tablesJsonPath);
      await fs.rename(tablesJsonPath, tablesJsonNewPath);
      log(`  Renamed: results/tables.json -> tables-${regenerationIndex}.json`, 'dim');
    } catch {
      log('  Missing: results/tables.json (R script may have failed)', 'red');
      process.exit(1);
    }

    // 7. Generate Excel
    log('');
    log('[6/6] Generating Excel...', 'cyan');

    try {
      const excelBuffer = await formatTablesFileToBuffer(tablesJsonNewPath);
      const { path: excelPath } = await findNextOutputPath(resultsDir, 'crosstabs', '.xlsx');
      await fs.writeFile(excelPath, excelBuffer);
      log(`  Saved: results/${path.basename(excelPath)}`, 'green');
    } catch (err) {
      log(`  Excel generation failed: ${err}`, 'red');
    }
  } catch (err) {
    log(`  R script failed: ${err}`, 'red');
    log('');
    log('The R script was still saved — you can inspect and debug it:', 'yellow');
    log(`  ${rScriptPath}`, 'dim');
  }

  // Cleanup
  try { await fs.unlink(spssDestPath); } catch { /* ignore */ }

  // Summary
  const totalDuration = Date.now() - startTime;
  log('');
  log('======================================================================', 'green');
  log('  Complete!', 'bright');
  log('======================================================================', 'green');
  log('');
  log(`Duration: ${(totalDuration / 1000).toFixed(1)}s`, 'blue');
  log(`Pipeline: outputs/${dataset}/${pipelineId}`, 'blue');
  log(`Regeneration: #${regenerationIndex}`, 'blue');
  log('');
  log('Files:', 'yellow');
  if (loopSemanticsPolicy) {
    log(`  loop-policy/loop-semantics-policy.json - Loop classification`, 'dim');
  }
  log(`  r/master-${regenerationIndex}.R            - Generated R script`, 'dim');
  log(`  results/tables-${regenerationIndex}.json   - R calculations`, 'dim');
  log(`  results/crosstabs-${regenerationIndex}.xlsx - Excel workbook`, 'dim');
  log('');
}

main().catch((err) => {
  log(`Error: ${err.message}`, 'red');
  console.error(err);
  process.exit(1);
});
