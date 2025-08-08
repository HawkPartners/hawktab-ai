// Single API endpoint for complete crosstab processing workflow
// Reference: Architecture doc "Single Endpoint Implementation"

import { NextRequest, NextResponse } from 'next/server';
import { createJob, updateJob } from '../../../lib/jobStore';
import { runAllGuardrails } from '../../../guardrails/inputValidation';
import { generateSessionId, saveUploadedFile } from '../../../lib/storage';
import { logAgentExecution } from '../../../lib/tracing';
import { validateEnvironment } from '../../../lib/env';
import { generateDualOutputs, prepareAgentContext } from '../../../lib/contextBuilder';
import { BannerAgent, type BannerProcessingResult } from '../../../agents/BannerAgent';
import { processAllGroups } from '../../../agents/CrosstabAgent';
import { promises as fs } from 'fs';
import * as path from 'path';
import type { ValidationStatus } from '../../../schemas/humanValidationSchema';

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  const sessionId = generateSessionId();
  const job = createJob();
  
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
    updateJob(job.jobId, { stage: 'parsing', percent: 10, message: 'Validating and saving files...' });

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

    // Log successful file upload
    logAgentExecution(sessionId, 'FileUploadProcessor', 
      { fileCount: 3, sessionId }, 
      { saved: true }, 
      Date.now() - startTime
    );

    // Kick off background processing and return immediately so client can poll
    ;(async () => {
      try {
        console.log(`[API] Starting Phase 5 data processing for session: ${sessionId}`);
        const outputFolderTimestamp = `output-${new Date().toISOString().replace(/[:.]/g, '-')}`;
        const dataMapPath = fileResults[0].filePath!;
        const bannerPlanPath = fileResults[1].filePath!;
        const spssPath = fileResults[2].filePath!;

        // Banner extraction
        let bannerProcessingResult: BannerProcessingResult;
        try {
          updateJob(job.jobId, { stage: 'banner_agent', percent: 25, message: 'Running banner extraction...' });
          const bannerAgent = new BannerAgent();
          bannerProcessingResult = await bannerAgent.processDocument(bannerPlanPath, outputFolderTimestamp);
        } catch (_bannerError) {
          const nowIso = new Date().toISOString();
          bannerProcessingResult = {
            verbose: {
              success: false,
              data: {
                success: false,
                extractionType: 'banner_extraction',
                timestamp: nowIso,
                extractedStructure: {
                  bannerCuts: [],
                  notes: [],
                  processingMetadata: {
                    totalColumns: 0,
                    groupCount: 0,
                    statisticalLettersUsed: [],
                    processingTimestamp: nowIso
                  }
                },
                errors: ['Banner extraction failed'],
                warnings: []
              },
              timestamp: nowIso
            },
            agent: [],
            success: false,
            confidence: 0,
            errors: ['Banner extraction failed'],
            warnings: []
          };
        }

        // Dual outputs
        updateJob(job.jobId, { stage: 'parsing', percent: 40, message: 'Generating dual outputs...' });
        const dualOutputs = await generateDualOutputs(bannerProcessingResult, dataMapPath, spssPath, outputFolderTimestamp);

        // Crosstab agent
        updateJob(job.jobId, { stage: 'crosstab_agent', percent: 65, message: 'Validating banner expressions...' });
        const agentContext = prepareAgentContext(dualOutputs);
        await processAllGroups(agentContext.dataMap, agentContext.bannerPlan, outputFolderTimestamp);

        // Write validation status
        updateJob(job.jobId, { stage: 'writing_outputs', percent: 85, message: 'Writing outputs and status...' });
        if (process.env.NODE_ENV === 'development') {
          try {
            const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolderTimestamp);
            const validationStatus: ValidationStatus = {
              sessionId: outputFolderTimestamp,
              status: 'pending',
              createdAt: new Date().toISOString(),
            };
            await fs.writeFile(path.join(outputDir, 'validation-status.json'), JSON.stringify(validationStatus, null, 2));
          } catch {}
        }

        updateJob(job.jobId, { stage: 'queued_for_validation', percent: 95, message: 'Queued for validation', sessionId: outputFolderTimestamp });
        updateJob(job.jobId, { stage: 'complete', percent: 100, message: 'Complete' });
      } catch (processingError) {
        updateJob(job.jobId, { stage: 'error', percent: 100, message: 'Processing error', error: processingError instanceof Error ? processingError.message : 'Unknown error' });
      }
    })();

    return NextResponse.json({ accepted: true, jobId: job.jobId, sessionId });

    } catch (error) {
      console.error('[API] Early processing error:', error);
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