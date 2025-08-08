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

    // Load data map (agent version)
    let dataMapData = null;
    try {
      const files = await fs.readdir(sessionPath);
      const dataMapFile = files.find(f => f.includes('dataMap') && f.includes('agent') && f.endsWith('.json'));
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