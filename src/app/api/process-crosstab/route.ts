// Single API endpoint for complete crosstab processing workflow
// Reference: Architecture doc "Single Endpoint Implementation"

/**
 * POST /api/process-crosstab
 * Purpose: Single entrypoint for upload → full pipeline processing
 * Reads: formData(dataMap, bannerPlan, dataFile, surveyDocument?)
 * Writes: outputs/{dataset}/pipeline-{timestamp}/
 * Status: Job tracked via /api/process-crosstab/status?jobId=...
 */
import { NextRequest, NextResponse } from 'next/server';
import { createJob, updateJob, getAbortSignal } from '../../../lib/jobStore';
import { generateSessionId } from '../../../lib/storage';
import { logAgentExecution } from '../../../lib/tracing';
import { validateEnvironment } from '../../../lib/env';
import { parseUploadFormData, validateUploadedFiles, saveFilesToStorage } from '../../../lib/api/fileHandler';
import { runPipelineFromUpload } from '../../../lib/api/pipelineOrchestrator';
import {
  persistSystemError,
  getGlobalSystemOutputDir,
} from '../../../lib/errors/ErrorPersistence';

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  const sessionId = generateSessionId();
  const job = createJob();

  // Get the abort signal for this job (used for cancellation support)
  const abortSignal = getAbortSignal(job.jobId);

  try {
    // Validate environment configuration
    const envValidation = validateEnvironment();
    if (!envValidation.valid) {
      return NextResponse.json(
        { error: 'Environment configuration invalid', details: envValidation.errors },
        { status: 500 }
      );
    }

    // Parse form data
    const formData = await request.formData();
    const parsed = parseUploadFormData(formData);
    if (!parsed) {
      return NextResponse.json(
        { error: 'Missing required files: dataMap, bannerPlan, and dataFile are required' },
        { status: 400 }
      );
    }

    // Run input guardrails
    const guardrailResult = await validateUploadedFiles({
      dataMap: parsed.dataMapFile,
      bannerPlan: parsed.bannerPlanFile,
      dataFile: parsed.dataFile,
    });
    if (!guardrailResult.success) {
      return NextResponse.json(
        { error: 'File validation failed', details: guardrailResult.errors, warnings: guardrailResult.warnings },
        { status: 400 }
      );
    }

    // Save files to temporary storage
    updateJob(job.jobId, { stage: 'parsing', percent: 10, message: 'Validating and saving files...' });

    const savedPaths = await saveFilesToStorage(parsed, sessionId);

    // Log successful file upload
    const fileCount = parsed.surveyFile ? 4 : 3;
    logAgentExecution(sessionId, 'FileUploadProcessor',
      { fileCount, sessionId },
      { saved: true },
      Date.now() - startTime
    );

    // Kick off background processing and return immediately so client can poll
    runPipelineFromUpload({
      jobId: job.jobId,
      sessionId,
      fileNames: {
        dataMap: parsed.dataMapFile.name,
        bannerPlan: parsed.bannerPlanFile.name,
        dataFile: parsed.dataFile.name,
        survey: parsed.surveyFile?.name ?? null,
      },
      savedPaths,
      abortSignal,
      loopStatTestingMode: parsed.loopStatTestingMode,
    }).catch((error) => {
      console.error('[API] Unhandled pipeline error:', error);
    });

    return NextResponse.json({ accepted: true, jobId: job.jobId, sessionId });

  } catch (error) {
    console.error('[API] Early processing error:', error);
    try {
      await persistSystemError({
        outputDir: getGlobalSystemOutputDir(),
        dataset: '',
        pipelineId: '',
        stageNumber: 0,
        stageName: 'API',
        severity: 'fatal',
        actionTaken: 'failed_pipeline',
        error,
        meta: { jobId: job.jobId, sessionId },
      });
    } catch {
      // ignore
    }
    updateJob(job.jobId, { stage: 'error', percent: 100, message: 'Processing error', error: error instanceof Error ? error.message : 'Unknown processing error' });
    return NextResponse.json(
      {
        error: 'Data processing failed',
        sessionId,
        details: process.env.NODE_ENV === 'development'
          ? (error instanceof Error ? error.message : String(error))
          : 'Processing error occurred',
        jobId: job.jobId
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
