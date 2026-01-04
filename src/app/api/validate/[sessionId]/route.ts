/**
 * /api/validate/[sessionId]
 * GET: Load validation payload and artifacts for a session
 * POST: Save validation results and mark status validated
 * DELETE: Optional — remove validation-status to exclude from queue
 * Reads: temp-outputs/<sessionId>/{validation-status.json, *banner*.json, *dataMap*.json, *crosstab-output*.json}
 * Writes: temp-outputs/<sessionId>/{validation-results.json, validation-status.json}
 */

import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import type { ValidationStatus, ValidationSession } from '../../../../schemas/humanValidationSchema';
import { buildTablePlanFromDataMap } from '@/lib/tables/TablePlan';
import { buildCutsSpec } from '@/lib/tables/CutsSpec';
import { buildRManifest } from '@/lib/r/Manifest';
import { RScriptAgent } from '@/agents/RScriptAgent';
import type { ValidationResultType } from '@/schemas/agentOutputSchema';
import { validateVerboseDataMap, type VerboseDataMapType } from '@/schemas/processingSchemas';

// Load session data for validation
export async function GET(_request: NextRequest, { params }: { params: Promise<{ sessionId: string }> }) {
  try {
    const { sessionId } = await params;
    const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);

    // Check if session directory exists
    try {
      await fs.access(sessionPath);
    } catch {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    // Load validation status
    let validationStatus: ValidationStatus | null = null;
    try {
      const statusPath = path.join(sessionPath, 'validation-status.json');
      const statusContent = await fs.readFile(statusPath, 'utf-8');
      validationStatus = JSON.parse(statusContent);
    } catch {
      return NextResponse.json(
        { error: 'No validation status found for this session' },
        { status: 404 }
      );
    }

    // Load banner data (agent version for simplified structure)
    let bannerData = null;
    try {
      const files = await fs.readdir(sessionPath);
      const bannerFile = files.find(f => f.includes('banner') && f.includes('agent') && f.endsWith('.json'));
      if (bannerFile) {
        const bannerPath = path.join(sessionPath, bannerFile);
        const bannerContent = await fs.readFile(bannerPath, 'utf-8');
        bannerData = JSON.parse(bannerContent);
      }
    } catch (error) {
      console.error('[Validate] Error loading banner data:', error);
    }

    // Load data map (crosstab-agent version)
    let dataMapData = null;
    try {
      const files = await fs.readdir(sessionPath);
      const dataMapFile = files.find(f => f.includes('dataMap') && f.includes('crosstab-agent') && f.endsWith('.json'));
      if (dataMapFile) {
        const dataMapPath = path.join(sessionPath, dataMapFile);
        const dataMapContent = await fs.readFile(dataMapPath, 'utf-8');
        dataMapData = JSON.parse(dataMapContent);
      }
    } catch (error) {
      console.error('[Validate] Error loading data map:', error);
    }

    // Load crosstab output
    let crosstabData = null;
    try {
      const files = await fs.readdir(sessionPath);
      const crosstabFile = files.find(f => f.includes('crosstab-output') && f.endsWith('.json'));
      if (crosstabFile) {
        const crosstabPath = path.join(sessionPath, crosstabFile);
        const crosstabContent = await fs.readFile(crosstabPath, 'utf-8');
        crosstabData = JSON.parse(crosstabContent);
      }
    } catch (error) {
      console.error('[Validate] Error loading crosstab data:', error);
    }

    // Load existing validation results if any
    let existingValidation = null;
    try {
      const validationPath = path.join(sessionPath, 'validation-results.json');
      const validationContent = await fs.readFile(validationPath, 'utf-8');
      existingValidation = JSON.parse(validationContent);
    } catch {
      // No existing validation, that's fine
    }

    return NextResponse.json({
      sessionId,
      status: validationStatus,
      data: {
        banner: bannerData,
        dataMap: dataMapData,
        crosstab: crosstabData
      },
      existingValidation
    });

  } catch (error) {
    console.error('[Validate] Error loading session:', error);
    return NextResponse.json(
      { 
        error: 'Failed to load session data',
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : String(error)
          : undefined
      },
      { status: 500 }
    );
  }
}

// Save validation results
export async function POST(request: NextRequest, { params }: { params: Promise<{ sessionId: string }> }) {
  try {
    const { sessionId } = await params;
    const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);

    // Check if session directory exists
    try {
      await fs.access(sessionPath);
    } catch {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    // Parse validation data from request
    const validationData: ValidationSession = await request.json();

    // Save validation results
    const validationPath = path.join(sessionPath, 'validation-results.json');
    await fs.writeFile(
      validationPath,
      JSON.stringify(validationData, null, 2)
    );

    // Update validation status
    const statusPath = path.join(sessionPath, 'validation-status.json');
    const updatedStatus: ValidationStatus = {
      sessionId,
      status: 'validated',
      createdAt: validationData.timestamp || new Date().toISOString(),
      validatedAt: new Date().toISOString()
    };
    await fs.writeFile(
      statusPath,
      JSON.stringify(updatedStatus, null, 2)
    );

    console.log(`[Validate] Saved validation results for session: ${sessionId}`);

    // After marking validated, auto-generate R artifacts in the background
    (async () => {
      try {
        const sessionDir = path.join(process.cwd(), 'temp-outputs', sessionId);
        const files = await fs.readdir(sessionDir);
        const crosstabFile = files.find((f) => f.includes('crosstab-output') && f.endsWith('.json'));
        const verboseMapFile = files.find((f) => f.includes('dataMap-verbose') && f.endsWith('.json'));
        const dataMapFile = verboseMapFile ?? files.find((f) => f.includes('dataMap-crosstab-agent') && f.endsWith('.json'));
        if (!crosstabFile || !dataMapFile) {
          console.warn('[Validate] Skipping R generation - missing artifacts');
          return;
        }
        const savPath = path.join(sessionDir, 'dataFile.sav');
        try { await fs.access(savPath); } catch { console.warn('[Validate] Skipping R generation - missing dataFile.sav'); return; }

        const crosstabContent = await fs.readFile(path.join(sessionDir, crosstabFile), 'utf-8');
        const validation = JSON.parse(crosstabContent) as ValidationResultType;
        const dataMapContent = await fs.readFile(path.join(sessionDir, dataMapFile), 'utf-8');
        const dataMap = validateVerboseDataMap(JSON.parse(dataMapContent)) as VerboseDataMapType[];

        const tablePlan = buildTablePlanFromDataMap(dataMap);
        const cutsSpec = buildCutsSpec(validation);
        const manifest = buildRManifest(sessionId, tablePlan, cutsSpec);

        const rDir = path.join(sessionDir, 'r');
        await fs.mkdir(rDir, { recursive: true });
        await fs.writeFile(path.join(rDir, 'manifest.json'), JSON.stringify(manifest, null, 2), 'utf-8');

        const agent = new RScriptAgent();
        const master = await agent.generateMasterFromManifest(sessionId, manifest);
        await fs.writeFile(path.join(rDir, 'master.R'), master, 'utf-8');

        const summary = await agent.generate(sessionId);
        await fs.writeFile(path.join(sessionDir, 'r-validation.json'), JSON.stringify({ issues: summary.issues, stats: summary.stats }, null, 2), 'utf-8');

        console.log(`[Validate] R generation complete for session: ${sessionId}`);
      } catch (err) {
        console.warn('[Validate] R generation failed after validation:', err);
      }
    })();

    return NextResponse.json({
      success: true,
      sessionId,
      message: 'Validation results saved successfully',
      validatedAt: updatedStatus.validatedAt
    });

  } catch (error) {
    console.error('[Validate] Error saving validation:', error);
    return NextResponse.json(
      { 
        error: 'Failed to save validation results',
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : String(error)
          : undefined
      },
      { status: 500 }
    );
  }
}

// Mark session as skipped (optional endpoint)
export async function DELETE(_request: NextRequest, { params }: { params: Promise<{ sessionId: string }> }) {
  try {
    const { sessionId } = await params;
    const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);

    // Check if session directory exists
    try {
      await fs.access(sessionPath);
    } catch {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    // Remove validation status file to exclude from queue
    const statusPath = path.join(sessionPath, 'validation-status.json');
    try {
      await fs.unlink(statusPath);
      console.log(`[Validate] Removed validation status for session: ${sessionId}`);
    } catch (error) {
      console.error('[Validate] Error removing validation status:', error);
    }

    return NextResponse.json({
      success: true,
      sessionId,
      message: 'Session removed from validation queue'
    });

  } catch (error) {
    console.error('[Validate] Error removing session:', error);
    return NextResponse.json(
      { 
        error: 'Failed to remove session from queue',
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : String(error)
          : undefined
      },
      { status: 500 }
    );
  }
}