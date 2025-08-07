// Single API endpoint for complete crosstab processing workflow
// Reference: Architecture doc "Single Endpoint Implementation"

import { NextRequest, NextResponse } from 'next/server';
import { runAllGuardrails } from '../../../guardrails/inputValidation';
import { generateSessionId, saveUploadedFile } from '../../../lib/storage';
import { logAgentExecution } from '../../../lib/tracing';
import { validateEnvironment } from '../../../lib/env';
import { generateDualOutputs, prepareAgentContext } from '../../../lib/contextBuilder';
import { BannerProcessor } from '../../../lib/processors/BannerProcessor';
import { processAllGroups } from '../../../agents/CrosstabAgent';

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

    // Log successful file upload
    logAgentExecution(sessionId, 'FileUploadProcessor', 
      { fileCount: 3, sessionId }, 
      { saved: true }, 
      Date.now() - startTime
    );

    // Phase 5: Data Processing & Dual Output Strategy (COMPLETE)
    console.log(`[API] Starting Phase 5 data processing for session: ${sessionId}`);
    
    // Generate output folder timestamp for this processing session
    const outputFolderTimestamp = `output-${new Date().toISOString().replace(/[:.]/g, '-')}`;
    console.log(`[API] Output folder: ${outputFolderTimestamp}`);
    
    const dataMapPath = fileResults[0].filePath!;
    const bannerPlanPath = fileResults[1].filePath!;
    const spssPath = fileResults[2].filePath!;
    
    console.log(`[API] Data Map file: ${dataMapPath}`);
    console.log(`[API] Banner Plan file: ${bannerPlanPath}`);
    console.log(`[API] SPSS file: ${spssPath}`);
    
    // Real banner processing using BannerProcessor
    let bannerProcessingResult;
    try {
      const bannerProcessor = new BannerProcessor();
      bannerProcessingResult = await bannerProcessor.processDocument(bannerPlanPath, outputFolderTimestamp);
      console.log(`[API] Banner processing completed - Success: ${bannerProcessingResult.success}, Groups: ${bannerProcessingResult.agent.length}`);
    } catch (bannerError) {
      console.error('[API] Banner processing failed:', bannerError);
      // Create fallback result
      bannerProcessingResult = {
        verbose: {
          success: false,
          data: {
            success: false,
            extractionType: 'banner_extraction',
            timestamp: new Date().toISOString(),
            extractedStructure: {
              bannerCuts: [],
              notes: [],
              processingMetadata: {
                totalColumns: 0,
                groupCount: 0,
                statisticalLettersUsed: [],
                processingTimestamp: new Date().toISOString()
              }
            },
            errors: [bannerError instanceof Error ? bannerError.message : 'Banner processing failed'],
            warnings: null
          },
          timestamp: new Date().toISOString()
        },
        agent: [],
        success: false,
        confidence: 0,
        errors: [bannerError instanceof Error ? bannerError.message : 'Banner processing failed'],
        warnings: []
      };
    }

    try {
      // Use enhanced dual output generation with real banner processing result
      const dualOutputs = await generateDualOutputs(bannerProcessingResult, dataMapPath, spssPath, outputFolderTimestamp);
      
      console.log(`[API] Data processing completed - Success: ${dualOutputs.processing.success}, Confidence: ${dualOutputs.processing.confidence.toFixed(2)}`);

      // Phase 6: CrossTab Agent Processing
      let agentResults;
      let agentProcessingSucceeded = false;
      let processingLog: string[] = [];
      
      try {
        console.log(`[API] 🚀 Starting Phase 6: CrossTab Agent validation`);
        
        // Prepare agent context from dual outputs
        const agentContext = prepareAgentContext(dualOutputs);
        console.log(`[API] 📊 Agent context prepared - ${agentContext.metadata.dataMapVariables} variables, ${agentContext.metadata.bannerGroups} groups, ${agentContext.metadata.totalColumns} columns`);
        
        // Process all banner groups with CrossTab agent (group-by-group)
        const agentStartTime = Date.now();
        const agentResponse = await processAllGroups(agentContext.dataMap, agentContext.bannerPlan, outputFolderTimestamp);
        agentResults = agentResponse.result;
        processingLog = agentResponse.processingLog;
        const agentProcessingTime = Date.now() - agentStartTime;
        
        agentProcessingSucceeded = true;
        console.log(`[API] ✅ CrossTab Agent processing completed in ${agentProcessingTime}ms - ${agentResults.bannerCuts.length} groups validated`);
        console.log(`[API] 📋 Processing log entries: ${processingLog.length}`);
        
        // Enhanced logging with processing details
        console.log(`[API] 📈 Processing summary:`);
        console.log(`  - Groups processed: ${agentResults.bannerCuts.length}`);
        console.log(`  - Total columns: ${agentResults.bannerCuts.reduce((total, group) => total + group.columns.length, 0)}`);
        console.log(`  - Processing mode: group-by-group`);
        console.log(`  - Tracing: Enabled (check https://platform.openai.com/traces)`);
        
        // Log agent execution with enhanced info
        logAgentExecution(sessionId, 'CrosstabAgent', 
          { 
            groupsProcessed: agentResults.bannerCuts.length,
            columnsProcessed: agentResults.bannerCuts.reduce((total, group) => total + group.columns.length, 0),
            processingTime: agentProcessingTime,
            processingMode: 'group-by-group',
            logEntries: processingLog.length,
            tracingEnabled: process.env.OPENAI_AGENTS_DISABLE_TRACING !== 'true'
          }, 
          { success: true, agentResults }, 
          agentProcessingTime
        );
        
      } catch (agentError) {
        console.error('[API] ❌ CrossTab Agent processing failed:', agentError);
        agentResults = null;
        
        // Log agent failure  
        logAgentExecution(sessionId, 'CrosstabAgent', 
          { sessionId }, 
          { error: agentError instanceof Error ? agentError.message : 'Unknown agent error' }, 
          Date.now() - startTime
        );
      }

      // Log data processing completion
      logAgentExecution(sessionId, 'DataMapProcessor', 
        { dataMapPath, confidence: dualOutputs.processing.confidence }, 
        { success: dualOutputs.processing.success, validationPassed: dualOutputs.processing.validationPassed }, 
        Date.now() - startTime
      );

      const response = {
        success: true,
        sessionId,
        message: agentProcessingSucceeded 
          ? '🎉 Phase 6 COMPLETED: CrossTab agent validation successful!' 
          : 'Phase 5 completed with banner processing - CrossTab agent validation failed',
        files: {
          dataMap: {
            name: dataMapFile.name,
            size: dataMapFile.size,
            type: dataMapFile.type,
            processed: true
          },
          bannerPlan: {
            name: bannerPlanFile.name,
            size: bannerPlanFile.size,
            type: bannerPlanFile.type,
            processed: bannerProcessingResult.success
          },
          dataFile: {
            name: dataFile.name,
            size: dataFile.size,
            type: dataFile.type
          }
        },
        processing: {
          dataMapProcessing: {
            success: dualOutputs.processing.success,
            validationPassed: dualOutputs.processing.validationPassed,
            confidence: dualOutputs.processing.confidence,
            variablesProcessed: dualOutputs.agentDataMap.length,
            parentRelationships: dualOutputs.agentDataMap.filter(v => v.ParentQuestion).length,
            contextEnriched: dualOutputs.agentDataMap.filter(v => v.Context).length,
            errors: dualOutputs.processing.errors,
            warnings: dualOutputs.processing.warnings
          },
          bannerProcessing: {
            success: bannerProcessingResult.success,
            confidence: bannerProcessingResult.confidence,
            groupsExtracted: bannerProcessingResult.agent.length,
            columnsExtracted: bannerProcessingResult.agent.reduce((total, group) => total + group.columns.length, 0),
            errors: bannerProcessingResult.errors,
            warnings: bannerProcessingResult.warnings
          },
          crosstabAgentProcessing: agentProcessingSucceeded && agentResults ? {
            success: true,
            processingMode: 'group-by-group',
            tracingEnabled: process.env.OPENAI_AGENTS_DISABLE_TRACING !== 'true',
            tracesDashboard: 'https://platform.openai.com/traces',
            groupsValidated: agentResults.bannerCuts.length,
            columnsValidated: agentResults.bannerCuts.reduce((total, group) => total + group.columns.length, 0),
            averageConfidence: agentResults.bannerCuts.length > 0 
              ? agentResults.bannerCuts
                  .flatMap(group => group.columns)
                  .reduce((sum, col) => sum + col.confidence, 0) 
                / agentResults.bannerCuts.flatMap(group => group.columns).length
              : 0,
            highConfidenceColumns: agentResults.bannerCuts
              .flatMap(group => group.columns)
              .filter(col => col.confidence >= 0.8).length,
            lowConfidenceColumns: agentResults.bannerCuts
              .flatMap(group => group.columns)
              .filter(col => col.confidence < 0.5).length,
            processingLog: processingLog,
            processingLogEntries: processingLog.length
          } : {
            success: false,
            error: 'CrossTab agent processing failed'
          }
        },
        guardrails: {
          warnings: guardrailResult.warnings,
          metadata: guardrailResult.metadata
        },
        processingTimeMs: Date.now() - startTime,
        nextSteps: agentProcessingSucceeded ? [
          '✅ Data map processed with state machine + parent inference + context enrichment',
          '✅ Banner plan processed with PDF → Images → LLM extraction', 
          '✅ Dual outputs generated for both data map and banner plan (verbose + agent formats)',
          '✅ CrossTab agent validated all banner expressions against data map',
          '✅ R syntax generated for all columns with confidence scores',
          `${process.env.NODE_ENV === 'development' ? 'Development outputs saved to temp-outputs/' : ''}`,
          '🎉 PHASE 6 COMPLETED: Ready for crosstab execution!'
        ] : [
          '✅ Data map processed with state machine + parent inference + context enrichment',
          '✅ Banner plan processed with PDF → Images → LLM extraction',
          '✅ Dual outputs generated for both data map and banner plan (verbose + agent formats)',
          `${process.env.NODE_ENV === 'development' ? 'Development outputs saved to temp-outputs/' : ''}`,
          '⚠️  Phase 5 completed - Phase 6 CrossTab agent validation failed'
        ]
      };

      return NextResponse.json(response);

    } catch (processingError) {
      console.error('[API] Data processing error:', processingError);
      
      // Log processing failure
      logAgentExecution(sessionId, 'DataMapProcessor', 
        { dataMapPath }, 
        { error: processingError instanceof Error ? processingError.message : 'Unknown processing error' }, 
        Date.now() - startTime
      );

      return NextResponse.json(
        { 
          error: 'Data processing failed',
          sessionId,
          details: process.env.NODE_ENV === 'development' 
            ? processingError instanceof Error ? processingError.message : String(processingError)
            : 'Processing error occurred',
          files: {
            dataMap: { name: dataMapFile.name, processed: false },
            bannerPlan: { name: bannerPlanFile.name, processed: false },
            dataFile: { name: dataFile.name }
          }
        },
        { status: 500 }
      );
    }

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