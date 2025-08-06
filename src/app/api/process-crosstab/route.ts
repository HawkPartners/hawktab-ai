// Single API endpoint for complete crosstab processing workflow
// Reference: Architecture doc "Single Endpoint Implementation"

import { NextRequest, NextResponse } from 'next/server';
import { runAllGuardrails } from '../../../guardrails/inputValidation';
import { generateSessionId, saveUploadedFile } from '../../../lib/storage';
import { logAgentExecution } from '../../../lib/tracing';
import { validateEnvironment } from '../../../lib/env';

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  const sessionId = generateSessionId();
  
  try {
    // Validate environment configuration
    const envValidation = validateEnvironment();
    if (!envValidation.valid) {
      return NextResponse.json(
        { 
          error: 'Environment configuration invalid',
          details: envValidation.errors
        },
        { status: 500 }
      );
    }

    // Parse form data
    const formData = await request.formData();
    const dataMapFile = formData.get('dataMap') as File;
    const bannerPlanFile = formData.get('bannerPlan') as File;
    const dataFile = formData.get('dataFile') as File;

    if (!dataMapFile || !bannerPlanFile || !dataFile) {
      return NextResponse.json(
        { error: 'Missing required files: dataMap, bannerPlan, and dataFile are required' },
        { status: 400 }
      );
    }

    // Run input guardrails
    const files = {
      dataMap: dataMapFile,
      bannerPlan: bannerPlanFile,
      dataFile: dataFile
    };

    const guardrailResult = await runAllGuardrails(files);
    if (!guardrailResult.success) {
      return NextResponse.json(
        { 
          error: 'File validation failed',
          details: guardrailResult.errors,
          warnings: guardrailResult.warnings
        },
        { status: 400 }
      );
    }

    // Save files to temporary storage
    const fileResults = await Promise.all([
      saveUploadedFile(dataMapFile, sessionId, `dataMap.${dataMapFile.name.split('.').pop()}`),
      saveUploadedFile(bannerPlanFile, sessionId, `bannerPlan.${bannerPlanFile.name.split('.').pop()}`),
      saveUploadedFile(dataFile, sessionId, `dataFile.${dataFile.name.split('.').pop()}`)
    ]);

    const failedSaves = fileResults.filter(result => !result.success);
    if (failedSaves.length > 0) {
      return NextResponse.json(
        { 
          error: 'Failed to save uploaded files',
          details: failedSaves.map(result => result.error)
        },
        { status: 500 }
      );
    }

    // Log successful processing start
    logAgentExecution(sessionId, 'FileUploadProcessor', 
      { fileCount: 3, sessionId }, 
      { saved: true }, 
      Date.now() - startTime
    );

    // For Phase 4, return success with file info
    // In later phases, this will trigger the actual agent processing
    const response = {
      success: true,
      sessionId,
      message: 'Files uploaded and validated successfully',
      files: {
        dataMap: {
          name: dataMapFile.name,
          size: dataMapFile.size,
          type: dataMapFile.type
        },
        bannerPlan: {
          name: bannerPlanFile.name,
          size: bannerPlanFile.size,
          type: bannerPlanFile.type
        },
        dataFile: {
          name: dataFile.name,
          size: dataFile.size,
          type: dataFile.type
        }
      },
      guardrails: {
        warnings: guardrailResult.warnings,
        metadata: guardrailResult.metadata
      },
      processingTimeMs: Date.now() - startTime,
      nextSteps: [
        'Files saved to temporary storage',
        'Ready for Phase 5: Data Processing & Dual Output Strategy',
        'Agent processing will be implemented in Phase 6'
      ]
    };

    return NextResponse.json(response);

  } catch (error) {
    console.error('API processing error:', error);
    
    // Log failed execution
    logAgentExecution(sessionId, 'FileUploadProcessor', 
      { sessionId }, 
      { error: error instanceof Error ? error.message : 'Unknown error' }, 
      Date.now() - startTime
    );

    return NextResponse.json(
      { 
        error: 'Internal server error',
        sessionId,
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : String(error)
          : 'An unexpected error occurred'
      },
      { status: 500 }
    );
  }
}

// Handle other HTTP methods
export async function GET() {
  return NextResponse.json(
    { 
      error: 'Method not allowed',
      message: 'This endpoint only accepts POST requests with file uploads'
    },
    { status: 405 }
  );
}