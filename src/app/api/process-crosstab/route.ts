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
import { createJob, updateJob } from '../../../lib/jobStore';
import { runAllGuardrails } from '../../../guardrails/inputValidation';
import { generateSessionId, saveUploadedFile } from '../../../lib/storage';
import { logAgentExecution } from '../../../lib/tracing';
import { validateEnvironment } from '../../../lib/env';
import { BannerAgent } from '../../../agents/BannerAgent';
import { processAllGroups as processCrosstabGroups } from '../../../agents/CrosstabAgent';
import { processDataMap as processTableAgent } from '../../../agents/TableAgent';
import { verifyAllTables } from '../../../agents/VerificationAgent';
import { processSurvey } from '../../../lib/processors/SurveyProcessor';
import { DataMapProcessor } from '../../../lib/processors/DataMapProcessor';
import { promises as fs } from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import { buildCutsSpec } from '../../../lib/tables/CutsSpec';
import { sortTables, getSortingMetadata } from '../../../lib/tables/sortTables';
import { generateRScriptV2WithValidation } from '../../../lib/r/RScriptGeneratorV2';
import { ExcelFormatter } from '../../../lib/excel/ExcelFormatter';
import { toExtendedTable, type ExtendedTableDefinition } from '../../../schemas/verificationAgentSchema';
import type { VerboseDataMapType } from '../../../schemas/processingSchemas';
import type { TableAgentOutput } from '../../../schemas/tableAgentSchema';

const execAsync = promisify(exec);

/**
 * Sanitize dataset name for use in file paths
 */
function sanitizeDatasetName(filename: string): string {
  return filename
    .replace(/\.(sav|csv|xlsx?)$/i, '') // Remove extension
    .replace(/[^a-zA-Z0-9-_]/g, '-')     // Replace special chars
    .replace(/-+/g, '-')                  // Collapse multiple dashes
    .replace(/^-|-$/g, '')               // Remove leading/trailing dashes
    .toLowerCase();
}

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
    const surveyFile = formData.get('surveyDocument') as File | null;

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

    const fileSavePromises = [
      saveUploadedFile(dataMapFile, sessionId, `dataMap.${dataMapFile.name.split('.').pop()}`),
      saveUploadedFile(bannerPlanFile, sessionId, `bannerPlan.${bannerPlanFile.name.split('.').pop()}`),
      saveUploadedFile(dataFile, sessionId, `dataFile.${dataFile.name.split('.').pop()}`)
    ];

    // Save survey file if provided
    if (surveyFile) {
      fileSavePromises.push(
        saveUploadedFile(surveyFile, sessionId, `survey.${surveyFile.name.split('.').pop()}`)
      );
    }

    const fileResults = await Promise.all(fileSavePromises);

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
    const fileCount = surveyFile ? 4 : 3;
    logAgentExecution(sessionId, 'FileUploadProcessor',
      { fileCount, sessionId },
      { saved: true },
      Date.now() - startTime
    );

    // Kick off background processing and return immediately so client can poll
    ;(async () => {
      const processingStartTime = Date.now();

      // Create output folder path immediately - same pattern as test-pipeline.ts
      const datasetName = sanitizeDatasetName(dataFile.name);
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const pipelineId = `pipeline-${timestamp}`;
      const outputDir = path.join(process.cwd(), 'outputs', datasetName, pipelineId);

      try {
        console.log(`[API] Starting full pipeline processing for session: ${sessionId}`);
        console.log(`[API] Output directory: ${outputDir}`);

        // Create output directory first
        await fs.mkdir(outputDir, { recursive: true });

        const dataMapPath = fileResults[0].filePath!;
        const bannerPlanPath = fileResults[1].filePath!;
        const spssPath = fileResults[2].filePath!;
        const surveyPath = surveyFile ? fileResults[3]?.filePath : null;

        // Copy input files to inputs/ folder with original names
        const inputsDir = path.join(outputDir, 'inputs');
        await fs.mkdir(inputsDir, { recursive: true });
        await fs.copyFile(dataMapPath, path.join(inputsDir, dataMapFile.name));
        await fs.copyFile(bannerPlanPath, path.join(inputsDir, bannerPlanFile.name));
        await fs.copyFile(spssPath, path.join(inputsDir, dataFile.name));
        if (surveyPath && surveyFile) {
          await fs.copyFile(surveyPath, path.join(inputsDir, surveyFile.name));
        }
        console.log('[API] Copied input files to inputs/ folder');

        // Copy SPSS to output dir root (needed for R script execution)
        const spssDestPath = path.join(outputDir, 'dataFile.sav');
        await fs.copyFile(spssPath, spssDestPath);

        // -------------------------------------------------------------------------
        // Step 1: DataMapProcessor
        // -------------------------------------------------------------------------
        updateJob(job.jobId, { stage: 'parsing', percent: 15, message: 'Processing data map...' });
        console.log('[API] Step 1: Processing data map...');

        const dataMapProcessor = new DataMapProcessor();
        const dataMapResult = await dataMapProcessor.processDataMap(dataMapPath, spssPath, outputDir);
        const verboseDataMap = dataMapResult.verbose as VerboseDataMapType[];
        console.log(`[API] Processed ${verboseDataMap.length} variables`);

        // -------------------------------------------------------------------------
        // Step 2: BannerAgent
        // -------------------------------------------------------------------------
        updateJob(job.jobId, { stage: 'banner_agent', percent: 25, message: 'Extracting banner plan...' });
        console.log('[API] Step 2: Extracting banner plan...');

        const bannerAgent = new BannerAgent();
        const bannerResult = await bannerAgent.processDocument(bannerPlanPath, outputDir);

        const extractedStructure = bannerResult.verbose?.data?.extractedStructure;
        const groupCount = extractedStructure?.bannerCuts?.length || 0;
        const columnCount = (extractedStructure?.processingMetadata as { totalColumns?: number })?.totalColumns || 0;
        console.log(`[API] Extracted ${groupCount} groups, ${columnCount} columns`);

        // CRITICAL: Fail early if banner extraction returned 0 groups
        if (!bannerResult.success || groupCount === 0) {
          const errorMsg = bannerResult.errors?.join('; ') || 'Banner extraction failed - 0 groups extracted';
          console.error(`[API] Banner extraction failed: ${errorMsg}`);

          // Write a partial summary for debugging
          const failureSummary = {
            pipelineId,
            dataset: datasetName,
            timestamp: new Date().toISOString(),
            source: 'ui',  // Mark as UI-created (vs test script)
            status: 'error',
            error: errorMsg,
            inputs: {
              datamap: dataMapFile.name,
              banner: bannerPlanFile.name,
              spss: dataFile.name,
              survey: surveyFile?.name || null
            }
          };
          await fs.writeFile(
            path.join(outputDir, 'pipeline-summary.json'),
            JSON.stringify(failureSummary, null, 2)
          );

          updateJob(job.jobId, {
            stage: 'error',
            percent: 100,
            message: 'Banner extraction failed',
            error: errorMsg,
            pipelineId,
            dataset: datasetName
          });
          return; // Stop pipeline
        }

        // -------------------------------------------------------------------------
        // Step 3: CrosstabAgent
        // -------------------------------------------------------------------------
        updateJob(job.jobId, { stage: 'crosstab_agent', percent: 45, message: 'Validating banner expressions...' });
        console.log('[API] Step 3: Validating banner expressions...');

        // Build simple data structures for CrosstabAgent
        const agentDataMap = dataMapResult.agent.map(v => ({
          Column: v.Column,
          Description: v.Description,
          Answer_Options: v.Answer_Options,
        }));

        const agentBanner = bannerResult.agent || [];

        const crosstabResult = await processCrosstabGroups(
          agentDataMap,
          { bannerCuts: agentBanner.map(g => ({ groupName: g.groupName, columns: g.columns })) },
          outputDir,
          (completed, total) => {
            const percent = Math.min(65, 45 + Math.floor((completed / total) * 20));
            updateJob(job.jobId, {
              stage: 'crosstab_agent',
              percent,
              message: `Validating banner expressions (${completed}/${total})...`
            });
          }
        );
        console.log(`[API] Validated ${crosstabResult.result.bannerCuts.length} groups`);

        // -------------------------------------------------------------------------
        // Step 4: TableAgent
        // -------------------------------------------------------------------------
        updateJob(job.jobId, { stage: 'table_agent', percent: 70, message: 'Analyzing table structures...' });
        console.log('[API] Step 4: Analyzing table structures...');

        const { results: tableAgentResults } = await processTableAgent(verboseDataMap, outputDir);
        const tableAgentTables = tableAgentResults.flatMap(r => r.tables);
        console.log(`[API] Generated ${tableAgentTables.length} table definitions`);

        // -------------------------------------------------------------------------
        // Step 5: VerificationAgent
        // -------------------------------------------------------------------------
        updateJob(job.jobId, { stage: 'verification_agent', percent: 80, message: 'Verifying tables...' });
        console.log('[API] Step 5: Verifying tables...');

        let verifiedTables: ExtendedTableDefinition[];

        if (surveyPath) {
          try {
            console.log(`[API] Processing survey document...`);
            const surveyResult = await processSurvey(surveyPath, outputDir);

            if (surveyResult.markdown) {
              console.log(`[API] Survey markdown: ${surveyResult.markdown.length} characters`);

              const verificationResult = await verifyAllTables(
                tableAgentResults as TableAgentOutput[],
                surveyResult.markdown,
                verboseDataMap,
                { outputDir }
              );
              verifiedTables = verificationResult.tables;
              console.log(`[API] VerificationAgent produced ${verifiedTables.length} tables (${verificationResult.metadata.tablesModified} modified)`);
            } else {
              console.warn(`[API] Survey processing failed: ${surveyResult.warnings.join(', ')}`);
              verifiedTables = tableAgentResults.flatMap(group =>
                group.tables.map(t => toExtendedTable(t, group.questionId))
              );
            }
          } catch (verifyError) {
            console.error(`[API] VerificationAgent failed:`, verifyError);
            verifiedTables = tableAgentResults.flatMap(group =>
              group.tables.map(t => toExtendedTable(t, group.questionId))
            );
          }
        } else {
          console.log(`[API] No survey file - using TableAgent output directly`);
          verifiedTables = tableAgentResults.flatMap(group =>
            group.tables.map(t => toExtendedTable(t, group.questionId))
          );

          // Create verification folder with passthrough output
          const verificationDir = path.join(outputDir, 'verification');
          await fs.mkdir(verificationDir, { recursive: true });
          await fs.writeFile(
            path.join(verificationDir, 'verification-output-raw.json'),
            JSON.stringify({ tables: verifiedTables }, null, 2),
            'utf-8'
          );
        }

        // Sort tables for logical Excel output order
        console.log('[API] Sorting tables...');
        const sortingMetadata = getSortingMetadata(verifiedTables);
        const sortedTables = sortTables(verifiedTables);
        console.log(`[API] Screeners: ${sortingMetadata.screenerCount}, Main: ${sortingMetadata.mainCount}, Other: ${sortingMetadata.otherCount}`);

        // -------------------------------------------------------------------------
        // Step 6: R Script Generation
        // -------------------------------------------------------------------------
        updateJob(job.jobId, { stage: 'generating_r', percent: 85, message: 'Generating R script...' });
        console.log('[API] Step 6: Generating R script...');

        const cutsSpec = buildCutsSpec(crosstabResult.result);
        const rDir = path.join(outputDir, 'r');
        await fs.mkdir(rDir, { recursive: true });

        const { script: masterScript, validation: validationReport } = generateRScriptV2WithValidation(
          { tables: sortedTables, cuts: cutsSpec.cuts },
          { sessionId: pipelineId, outputDir: 'results' }
        );

        const masterPath = path.join(rDir, 'master.R');
        await fs.writeFile(masterPath, masterScript, 'utf-8');

        // Save validation report if there were any issues
        if (validationReport.invalidTables > 0 || validationReport.warnings.length > 0) {
          const validationPath = path.join(rDir, 'validation-report.json');
          await fs.writeFile(validationPath, JSON.stringify(validationReport, null, 2), 'utf-8');
          console.log(`[API] Validation issues: ${validationReport.invalidTables} invalid, ${validationReport.warnings.length} warnings`);
        }

        console.log(`[API] Generated R script (${Math.round(masterScript.length / 1024)} KB)`);
        console.log(`[API] Valid tables: ${validationReport.validTables}/${validationReport.totalTables}`);

        // -------------------------------------------------------------------------
        // Step 7: R Execution
        // -------------------------------------------------------------------------
        updateJob(job.jobId, { stage: 'executing_r', percent: 90, message: 'Executing R script...' });
        console.log('[API] Step 7: Executing R script...');

        // Create results directory
        const resultsDir = path.join(outputDir, 'results');
        await fs.mkdir(resultsDir, { recursive: true });

        // Find R
        let rCommand = 'Rscript';
        const rPaths = ['/opt/homebrew/bin/Rscript', '/usr/local/bin/Rscript', '/usr/bin/Rscript', 'Rscript'];
        for (const rPath of rPaths) {
          try {
            await execAsync(`${rPath} --version`, { timeout: 1000 });
            rCommand = rPath;
            console.log(`[API] Found R at: ${rPath}`);
            break;
          } catch {
            // Try next
          }
        }

        let rExecutionSuccess = false;
        let excelGenerated = false;

        try {
          await execAsync(
            `cd "${outputDir}" && ${rCommand} "${masterPath}"`,
            { maxBuffer: 10 * 1024 * 1024, timeout: 120000 }
          );

          // Check for JSON output
          const resultFiles = await fs.readdir(resultsDir);
          if (resultFiles.includes('tables.json')) {
            console.log(`[API] Successfully generated tables.json`);
            rExecutionSuccess = true;

            // -------------------------------------------------------------------------
            // Step 8: Excel Export
            // -------------------------------------------------------------------------
            updateJob(job.jobId, { stage: 'writing_outputs', percent: 95, message: 'Generating Excel workbook...' });
            console.log('[API] Step 8: Generating Excel workbook...');

            const tablesJsonPath = path.join(resultsDir, 'tables.json');
            const excelPath = path.join(resultsDir, 'crosstabs.xlsx');

            try {
              const formatter = new ExcelFormatter();
              await formatter.formatFromFile(tablesJsonPath);
              await formatter.saveToFile(excelPath);
              excelGenerated = true;
              console.log(`[API] Generated crosstabs.xlsx`);
            } catch (excelError) {
              console.error(`[API] Excel generation failed:`, excelError);
            }
          }
        } catch (rError) {
          const errorMsg = rError instanceof Error ? rError.message : String(rError);
          if (errorMsg.includes('command not found')) {
            console.warn(`[API] R not installed - script saved for manual execution`);
          } else {
            console.error(`[API] R execution failed:`, errorMsg.substring(0, 200));
          }
        }

        // -------------------------------------------------------------------------
        // Cleanup temporary files
        // -------------------------------------------------------------------------
        console.log('[API] Cleaning up temporary files...');

        // Remove dataFile.sav (only needed for R execution)
        try {
          await fs.unlink(spssDestPath);
        } catch { /* File may not exist */ }

        // Remove banner-images/ folder
        try {
          await fs.rm(path.join(outputDir, 'banner-images'), { recursive: true });
        } catch { /* Folder may not exist */ }

        // Remove survey conversion artifacts
        try {
          const allFiles = await fs.readdir(outputDir);
          for (const file of allFiles) {
            if (file.endsWith('.html') || (file.endsWith('.png') && file.includes('_html_'))) {
              await fs.unlink(path.join(outputDir, file));
            }
          }
        } catch { /* Ignore cleanup errors */ }

        // -------------------------------------------------------------------------
        // Write pipeline summary and complete
        // -------------------------------------------------------------------------
        const processingEndTime = Date.now();
        const durationMs = processingEndTime - processingStartTime;
        const durationSec = (durationMs / 1000).toFixed(1);

        const pipelineSummary = {
          pipelineId,
          dataset: datasetName,
          timestamp: new Date().toISOString(),
          source: 'ui',  // Mark as UI-created (vs test script)
          duration: {
            ms: durationMs,
            formatted: `${durationSec}s`
          },
          status: excelGenerated ? 'success' : (rExecutionSuccess ? 'partial' : 'error'),
          inputs: {
            datamap: dataMapFile.name,
            banner: bannerPlanFile.name,
            spss: dataFile.name,
            survey: surveyFile?.name || null
          },
          outputs: {
            variables: verboseDataMap.length,
            tableAgentTables: tableAgentTables.length,
            verifiedTables: sortedTables.length,
            tables: sortedTables.length,
            cuts: cutsSpec.cuts.length,
            bannerGroups: groupCount,
            sorting: {
              screeners: sortingMetadata.screenerCount,
              main: sortingMetadata.mainCount,
              other: sortingMetadata.otherCount
            }
          }
        };

        await fs.writeFile(
          path.join(outputDir, 'pipeline-summary.json'),
          JSON.stringify(pipelineSummary, null, 2)
        );
        console.log(`[API] Pipeline completed in ${durationSec}s - summary saved`);

        // Update job status
        if (excelGenerated) {
          updateJob(job.jobId, {
            stage: 'complete',
            percent: 100,
            message: `Complete! Generated ${sortedTables.length} crosstab tables in ${durationSec}s`,
            sessionId,
            pipelineId,
            dataset: datasetName,
            downloadUrl: `/api/pipelines/${encodeURIComponent(pipelineId)}/files/results/crosstabs.xlsx`
          });
        } else if (rExecutionSuccess) {
          updateJob(job.jobId, {
            stage: 'complete',
            percent: 100,
            message: 'R execution complete but Excel generation failed.',
            sessionId,
            pipelineId,
            dataset: datasetName,
            warning: 'Excel generation failed. Check results/tables.json'
          });
        } else {
          updateJob(job.jobId, {
            stage: 'complete',
            percent: 100,
            message: 'R scripts generated. Execution failed - check R installation.',
            sessionId,
            pipelineId,
            dataset: datasetName,
            warning: 'R execution failed. Scripts saved in r/master.R'
          });
        }

      } catch (processingError) {
        console.error('[API] Pipeline error:', processingError);
        updateJob(job.jobId, {
          stage: 'error',
          percent: 100,
          message: 'Processing error',
          error: processingError instanceof Error ? processingError.message : 'Unknown error',
          pipelineId,
          dataset: datasetName
        });
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
