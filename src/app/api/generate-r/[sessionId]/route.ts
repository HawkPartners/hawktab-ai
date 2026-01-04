/**
 * GET /api/generate-r/[sessionId]
 * Purpose: Generate a single-file R script and validation summary for a session
 * Reads: temp-outputs/<sessionId>/{dataFile.sav, cut-tables.json|crosstab-output-*.json, dataMap-crosstab-agent*.json}
 * Writes: temp-outputs/<sessionId>/{r-script.R, r-validation.json}
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { RScriptAgent } from '@/agents/RScriptAgent';
import { buildTablePlanFromDataMap } from '@/lib/tables/TablePlan';
import { buildCutsSpec } from '@/lib/tables/CutsSpec';
import { buildRManifest } from '@/lib/r/Manifest';
import { PreflightGenerator } from '@/lib/r/PreflightGenerator';
import { ValidationGenerator } from '@/lib/r/ValidationGenerator';
import type { ValidationResultType } from '@/schemas/agentOutputSchema';
import { validateVerboseDataMap, type VerboseDataMapType } from '@/schemas/processingSchemas';
import type { ValidationStatus } from '@/schemas/humanValidationSchema';

export async function GET(_req: NextRequest, { params }: { params: Promise<{ sessionId: string }> }) {
  try {
    const { sessionId } = await params;
    if (!sessionId.startsWith('output-') || sessionId.includes('..') || sessionId.includes('/')) {
      return NextResponse.json({ error: 'Invalid sessionId' }, { status: 400 });
    }

    const sessionDir = path.join(process.cwd(), 'temp-outputs', sessionId);
    await fs.access(sessionDir);

    // Require session to be validated first
    const statusPath = path.join(sessionDir, 'validation-status.json');
    try {
      const statusContent = await fs.readFile(statusPath, 'utf-8');
      const status = JSON.parse(statusContent) as ValidationStatus;
      if (status.status !== 'validated') {
        return NextResponse.json({ error: 'Session not validated. Please complete validation before generating R.' }, { status: 409 });
      }
    } catch {
      return NextResponse.json({ error: 'Missing validation-status.json' }, { status: 404 });
    }

    const savPath = path.join(sessionDir, 'dataFile.sav');
    try {
      await fs.access(savPath);
    } catch {
      return NextResponse.json({ error: 'Missing dataFile.sav in session folder' }, { status: 400 });
    }

    const agent = new RScriptAgent();

    // Preferred path: deterministic manifest generation
    const files = await fs.readdir(sessionDir);
    const crosstabFile = files.find((f) => f.includes('crosstab-output') && f.endsWith('.json'));
    // Prefer verbose data map for TablePlan
    const verboseMapFile = files.find((f) => f.includes('dataMap-verbose') && f.endsWith('.json'));
    const dataMapFile = verboseMapFile ?? files.find((f) => f.includes('dataMap-crosstab-agent') && f.endsWith('.json'));
    if (!crosstabFile || !dataMapFile) {
      return NextResponse.json({ error: 'Missing crosstab or data map artifacts' }, { status: 400 });
    }
    const crosstabContent = await fs.readFile(path.join(sessionDir, crosstabFile), 'utf-8');
    const validation = JSON.parse(crosstabContent) as ValidationResultType;
    const dataMapContent = await fs.readFile(path.join(sessionDir, dataMapFile), 'utf-8');
    const dataMap = validateVerboseDataMap(JSON.parse(dataMapContent)) as VerboseDataMapType[];

    const tablePlan = buildTablePlanFromDataMap(dataMap);
    const cutsSpec = buildCutsSpec(validation);
    const manifest = buildRManifest(sessionId, tablePlan, cutsSpec);

    // Write manifest for introspection
    const rDir = path.join(sessionDir, 'r');
    await fs.mkdir(rDir, { recursive: true });
    const manifestPath = path.join(rDir, 'manifest.json');
    await fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2), 'utf-8');

    // Generate preflight script FIRST
    const preflightGen = new PreflightGenerator();
    const preflightScript = preflightGen.generatePreflightScript(
      `temp-outputs/${sessionId}/dataFile.sav`,
      tablePlan,
      `temp-outputs/${sessionId}/r/preflight.json`
    );
    const preflightPath = path.join(rDir, 'preflight.R');
    await fs.writeFile(preflightPath, preflightScript, 'utf-8');

    // Generate master R script deterministically (will use preflight.json if available)
    const master = await agent.generateMasterFromManifest(sessionId, manifest);
    const masterPath = path.join(rDir, 'master.R');
    await fs.writeFile(masterPath, master, 'utf-8');

    // Generate validation script
    const validationGen = new ValidationGenerator();
    const validationScript = validationGen.generateValidationScript(sessionId, tablePlan);
    const validationScriptPath = path.join(rDir, 'validation.R');
    await fs.writeFile(validationScriptPath, validationScript, 'utf-8');

    // Also run the existing summary validation to keep r-validation.json
    const summary = await agent.generate(sessionId);
    const validationPath = path.join(sessionDir, 'r-validation.json');
    await fs.writeFile(validationPath, JSON.stringify({ issues: summary.issues, stats: summary.stats }, null, 2), 'utf-8');

    return NextResponse.json({
      success: true,
      sessionId,
      files: {
        manifest: `temp-outputs/${sessionId}/r/manifest.json`,
        preflight: `temp-outputs/${sessionId}/r/preflight.R`,
        validation: `temp-outputs/${sessionId}/r/validation.R`,
        master: `temp-outputs/${sessionId}/r/master.R`,
        validationReport: `temp-outputs/${sessionId}/r-validation.json`,
      },
      stats: summary.stats,
    });
  } catch (error) {
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to generate R script' },
      { status: 500 },
    );
  }
}


