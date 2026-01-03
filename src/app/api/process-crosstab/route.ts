// Single API endpoint for complete crosstab processing workflow
// Reference: Architecture doc "Single Endpoint Implementation"

/**
 * POST /api/process-crosstab
 * Purpose: Single entrypoint for upload → BannerAgent → DataMap processing → CrosstabAgent
 * Reads: formData(dataMap, bannerPlan, dataFile)
 * Writes: temp-outputs/output-<ts>/{inputs.json, dataFile.sav, banner-*.json, dataMap-*.json, crosstab-output-*.json, validation-status.json}
 * Status: Job tracked via /api/process-crosstab/status?jobId=...
 */
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
import { exec } from 'child_process';
import { promisify } from 'util';
// import { DataMapSchema, type DataMapType } from '@/schemas/dataMapSchema';
import type { ValidationStatus } from '../../../schemas/humanValidationSchema';
import type { ValidationResultType } from '../../../schemas/agentOutputSchema';
import type { VerboseDataMapType } from '../../../schemas/processingSchemas';
import { buildTablePlanFromDataMap } from '../../../lib/tables/TablePlan';
import { buildCutsSpec } from '../../../lib/tables/CutsSpec';
import { buildRManifest } from '../../../lib/r/Manifest';
import { generateMasterRScript } from '../../../lib/r/RScriptGenerator';
import { createBugTrackerTemplate } from '../../../lib/utils/bugTrackerTemplate';

const execAsync = promisify(exec);

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
      const processingStartTime = Date.now();
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

        // Crosstab agent with unified trace and per-group progress callback
        const agentContext = prepareAgentContext(dualOutputs);
        updateJob(job.jobId, { stage: 'crosstab_agent', percent: 65, message: `Validating banner expressions (0/${agentContext.bannerPlan.bannerCuts.length})...` });
        const _totalGroups = agentContext.bannerPlan.bannerCuts.length || 1;
        const base = 65;
        const span = 20; // 65% → 85% reserved for crosstab
        await processAllGroups(
          agentContext.dataMap,
          agentContext.bannerPlan,
          outputFolderTimestamp,
          (completed, total) => {
            const percent = Math.min(95, base + Math.floor((completed / total) * span));
            updateJob(job.jobId, { stage: 'crosstab_agent', percent, message: `Validating banner expressions (${completed}/${total})...` });
          }
        );

        // Write outputs and persist SPSS to session outputs
        updateJob(job.jobId, { stage: 'writing_outputs', percent: 85, message: 'Writing outputs and status...' });
        
        const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolderTimestamp);
        await fs.mkdir(outputDir, { recursive: true });

        // Create bug tracker template for this run
        const runTimestamp = outputFolderTimestamp.replace('output-', '');
        await createBugTrackerTemplate({
          runTimestamp,
          outputFolder: outputFolderTimestamp,
          datasetName: dataFile.name.replace(/\.(sav|csv|xlsx?)$/i, '')
        });

        // Persist SPSS file into session folder with stable name for R
        try {
          const stableSavPath = path.join(outputDir, 'dataFile.sav');
          await fs.copyFile(spssPath, stableSavPath);
        } catch (e) {
          console.error('[API] Failed to copy SPSS file:', e);
        }

        // Write minimal inputs manifest for downstream tools
        try {
          const inputs = {
            dataFile: 'dataFile.sav',
            bannerPlanFile: 'banner-*.json',
            dataMapFile: 'dataMap-*.json',
          };
          await fs.writeFile(path.join(outputDir, 'inputs.json'), JSON.stringify(inputs, null, 2));
        } catch {}

        // For MVP: Skip validation and proceed directly to R generation
        const skipValidation = true; // MVP mode - always skip validation for now
        
        if (skipValidation) {
          // Continue with R generation and Excel export for MVP
          console.log('[API] MVP Mode: Proceeding to R generation without validation');
          updateJob(job.jobId, { stage: 'generating_r', percent: 88, message: 'Generating R scripts...' });
          
          // Wait a bit for files to be written
          await new Promise(resolve => setTimeout(resolve, 500));
          
          try {
            // Find the crosstab and datamap files
            const files = await fs.readdir(outputDir);
            console.log('[API] Files in output directory:', files);
            
            const crosstabFile = files.find(f => f.includes('crosstab-output') && f.endsWith('.json'));
            const dataMapFile = files.find(f => f.includes('dataMap') && f.includes('verbose') && f.endsWith('.json'));
            
            if (crosstabFile && dataMapFile) {
              console.log(`[API] Found required files - Crosstab: ${crosstabFile}, DataMap: ${dataMapFile}`);
              
              // Load validation results and data map
              const crosstabContent = await fs.readFile(path.join(outputDir, crosstabFile), 'utf-8');
              const validation = JSON.parse(crosstabContent) as ValidationResultType;
              console.log(`[API] Loaded validation with ${validation.bannerCuts?.length || 0} banner groups`);
              
              const dataMapContent = await fs.readFile(path.join(outputDir, dataMapFile), 'utf-8');
              const dataMap = JSON.parse(dataMapContent) as VerboseDataMapType[];
              console.log(`[API] Loaded data map with ${dataMap.length} variables`);
              
              // Build TablePlan and CutsSpec
              console.log(`[API] Building TablePlan from ${dataMap.length} variables`);
              const tablePlan = buildTablePlanFromDataMap(dataMap);
              const cutsSpec = buildCutsSpec(validation);
              
              console.log(`[API] Generated ${tablePlan.tables.length} tables and ${cutsSpec.cuts.length} cuts`);
              
              // Build and save R manifest
              const manifest = buildRManifest(outputFolderTimestamp, tablePlan, cutsSpec);
              const rDir = path.join(outputDir, 'r');
              await fs.mkdir(rDir, { recursive: true });
              
              await fs.writeFile(
                path.join(rDir, 'manifest.json'),
                JSON.stringify(manifest, null, 2),
                'utf-8'
              );
              
              // Generate and save master R script
              const masterScript = generateMasterRScript(manifest, outputFolderTimestamp);
              const masterPath = path.join(rDir, 'master.R');
              await fs.writeFile(masterPath, masterScript, 'utf-8');
              
              // Create results directory
              const resultsDir = path.join(outputDir, 'results');
              await fs.mkdir(resultsDir, { recursive: true });
              
              // Try to execute R script
              updateJob(job.jobId, { stage: 'executing_r', percent: 92, message: 'Executing R script...' });
              
              // Find R in common locations
              let rCommand = 'Rscript';
              const rPaths = [
                '/opt/homebrew/bin/Rscript',  // Homebrew on Apple Silicon
                '/usr/local/bin/Rscript',      // Homebrew on Intel Mac
                '/usr/bin/Rscript',             // System R
                'Rscript'                       // In PATH
              ];
              
              for (const rPath of rPaths) {
                try {
                  await execAsync(`${rPath} --version`, { timeout: 1000 });
                  rCommand = rPath;
                  console.log(`[API] Found R at: ${rPath}`);
                  break;
                } catch {
                  // Try next path
                }
              }
              
              try {
                const { stdout, stderr } = await execAsync(
                  `cd "${outputDir}" && ${rCommand} "${masterPath}"`,
                  {
                    maxBuffer: 10 * 1024 * 1024,
                    timeout: 60000
                  }
                );
                
                console.log('[API] R execution stdout:', stdout.substring(0, 500));
                if (stderr && !stderr.includes('Warning')) {
                  console.error('[API] R execution stderr:', stderr.substring(0, 500));
                }
                
                // Check if CSV files were generated
                const resultFiles = await fs.readdir(resultsDir);
                const csvFiles = resultFiles.filter(f => f.endsWith('.csv'));
                
                if (csvFiles.length > 0) {
                  console.log(`[API] Successfully generated ${csvFiles.length} CSV files`);

                  // Write run summary with timing info
                  const processingEndTime = Date.now();
                  const durationMs = processingEndTime - processingStartTime;
                  const durationSec = (durationMs / 1000).toFixed(1);
                  const runSummary = {
                    sessionId: outputFolderTimestamp,
                    timing: {
                      startTime: new Date(processingStartTime).toISOString(),
                      endTime: new Date(processingEndTime).toISOString(),
                      durationMs,
                      durationFormatted: `${durationSec}s`
                    },
                    outputs: {
                      tablesGenerated: tablePlan.tables.length,
                      cutsGenerated: cutsSpec.cuts.length,
                      csvFilesCreated: csvFiles.length,
                      files: csvFiles
                    },
                    status: 'success'
                  };
                  await fs.writeFile(
                    path.join(outputDir, 'run-summary.json'),
                    JSON.stringify(runSummary, null, 2)
                  );
                  console.log(`[API] Run completed in ${durationSec}s - summary saved to run-summary.json`);

                  updateJob(job.jobId, {
                    stage: 'complete',
                    percent: 100,
                    message: `Complete! Generated ${csvFiles.length} crosstab tables in ${durationSec}s. Download Excel at /api/export-workbook/${outputFolderTimestamp}`,
                    sessionId: outputFolderTimestamp,
                    downloadUrl: `/api/export-workbook/${outputFolderTimestamp}`
                  });
                } else {
                  console.warn('[API] R executed but no CSV files generated');
                  updateJob(job.jobId, { 
                    stage: 'complete', 
                    percent: 100, 
                    message: 'R scripts generated but no tables produced. Check R installation.',
                    sessionId: outputFolderTimestamp 
                  });
                }
                
              } catch (rError) {
                const errorMessage = rError instanceof Error ? rError.message : String(rError);
                console.error('[API] R execution failed:', errorMessage);
                
                // R not installed or failed - still mark as complete with scripts generated
                if (errorMessage.includes('command not found') || errorMessage.includes('Rscript')) {
                  updateJob(job.jobId, { 
                    stage: 'complete', 
                    percent: 100, 
                    message: 'R scripts generated successfully. R not installed - manual execution required.',
                    sessionId: outputFolderTimestamp,
                    warning: 'R is not installed. Scripts saved in r/master.R'
                  });
                } else {
                  updateJob(job.jobId, { 
                    stage: 'complete', 
                    percent: 100, 
                    message: 'R scripts generated. Execution failed - check R installation.',
                    sessionId: outputFolderTimestamp,
                    warning: errorMessage.substring(0, 200)
                  });
                }
              }
              
            } else {
              // No crosstab output found, just complete without R generation
              console.warn('[API] Missing crosstab or datamap files for R generation');
              updateJob(job.jobId, { 
                stage: 'complete', 
                percent: 100, 
                message: 'Processing complete. Validation outputs saved.',
                sessionId: outputFolderTimestamp 
              });
            }
            
          } catch (rGenError) {
            console.error('[API] R generation error:', rGenError);
            // Still mark as complete even if R generation fails
            updateJob(job.jobId, { 
              stage: 'complete', 
              percent: 100, 
              message: 'Validation complete. R generation failed.',
              sessionId: outputFolderTimestamp,
              warning: rGenError instanceof Error ? rGenError.message : 'R generation error'
            });
          }
          
        } else {
          // Original validation flow (for production)
          const validationStatus: ValidationStatus = {
            sessionId: outputFolderTimestamp,
            status: 'pending',
            createdAt: new Date().toISOString(),
          };
          await fs.writeFile(path.join(outputDir, 'validation-status.json'), JSON.stringify(validationStatus, null, 2));
          
          updateJob(job.jobId, { stage: 'queued_for_validation', percent: 95, message: 'Queued for validation', sessionId: outputFolderTimestamp });
          updateJob(job.jobId, { stage: 'complete', percent: 100, message: 'Complete' });
        }
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