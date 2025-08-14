/**
 * GET /api/generate-crosstabs/[sessionId]
 * Purpose: Complete crosstab generation workflow (R generation → execution → Excel export)
 * This is a convenience endpoint for MVP demo that runs the complete pipeline
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import { exec } from 'child_process';
import { promisify } from 'util';
import type { ValidationResultType } from '@/schemas/agentOutputSchema';
import type { VerboseDataMapType } from '@/schemas/processingSchemas';
import { buildTablePlanFromDataMap } from '@/lib/tables/TablePlan';
import { buildCutsSpec } from '@/lib/tables/CutsSpec';
import { buildRManifest } from '@/lib/r/Manifest';
import { generateMasterRScript } from '@/lib/r/RScriptGenerator';

const execAsync = promisify(exec);

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ sessionId: string }> }
) {
  try {
    const { sessionId } = await params;
    
    // Validate sessionId
    if (!sessionId.startsWith('output-') || sessionId.includes('..') || sessionId.includes('/')) {
      return NextResponse.json({ error: 'Invalid sessionId' }, { status: 400 });
    }

    const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);
    
    // Check if session exists
    try {
      await fs.access(sessionPath);
    } catch {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 });
    }

    console.log(`[Crosstab Generation] Starting complete workflow for session: ${sessionId}`);

    // Step 1: Generate R scripts
    console.log('[Crosstab Generation] Step 1: Generating R scripts...');
    
    const files = await fs.readdir(sessionPath);
    
    // Find required files
    const crosstabFile = files.find(f => f.includes('crosstab-output') && f.endsWith('.json'));
    const dataMapFile = files.find(f => f.includes('dataMap') && f.includes('verbose') && f.endsWith('.json'));
    const dataFile = files.find(f => f === 'dataFile.sav');
    
    if (!crosstabFile || !dataMapFile || !dataFile) {
      return NextResponse.json({ 
        error: 'Missing required files',
        details: {
          crosstab: !!crosstabFile,
          dataMap: !!dataMapFile,
          dataFile: !!dataFile
        }
      }, { status: 404 });
    }

    // Load validation results and data map
    const crosstabContent = await fs.readFile(path.join(sessionPath, crosstabFile), 'utf-8');
    const validation = JSON.parse(crosstabContent) as ValidationResultType;
    
    const dataMapContent = await fs.readFile(path.join(sessionPath, dataMapFile), 'utf-8');
    const dataMap = JSON.parse(dataMapContent) as VerboseDataMapType[];

    // Build TablePlan and CutsSpec
    const tablePlan = buildTablePlanFromDataMap(dataMap);
    const cutsSpec = buildCutsSpec(validation);
    
    console.log(`[Crosstab Generation] Generated ${tablePlan.tables.length} tables and ${cutsSpec.cuts.length} cuts`);

    // Build and save R manifest
    const manifest = buildRManifest(sessionId, tablePlan, cutsSpec);
    const rDir = path.join(sessionPath, 'r');
    await fs.mkdir(rDir, { recursive: true });
    
    await fs.writeFile(
      path.join(rDir, 'manifest.json'), 
      JSON.stringify(manifest, null, 2), 
      'utf-8'
    );

    // Generate and save master R script
    const masterScript = generateMasterRScript(manifest, sessionId);
    const masterPath = path.join(rDir, 'master.R');
    await fs.writeFile(masterPath, masterScript, 'utf-8');

    // Create results directory
    const resultsDir = path.join(sessionPath, 'results');
    await fs.mkdir(resultsDir, { recursive: true });

    // Step 2: Execute R script
    console.log('[Crosstab Generation] Step 2: Executing R script...');
    
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
        console.log(`[Crosstab Generation] Found R at: ${rPath}`);
        break;
      } catch {
        // Try next path
      }
    }
    
    try {
      const { stdout, stderr } = await execAsync(
        `cd "${sessionPath}" && ${rCommand} "${masterPath}"`,
        {
          maxBuffer: 10 * 1024 * 1024,
          timeout: 60000
        }
      );

      if (stderr && !stderr.includes('Warning')) {
        console.error('[Crosstab Generation] R stderr:', stderr);
      }
      
      // Check generated CSV files
      const resultFiles = await fs.readdir(resultsDir);
      const csvFiles = resultFiles.filter(f => f.endsWith('.csv'));
      
      console.log(`[Crosstab Generation] Generated ${csvFiles.length} CSV files`);

      if (csvFiles.length === 0) {
        return NextResponse.json({
          error: 'R script executed but no results generated',
          rOutput: { stdout, stderr }
        }, { status: 500 });
      }

      // Step 3: Return success with download link
      console.log('[Crosstab Generation] Step 3: Complete! Excel workbook ready for download');
      
      const baseUrl = req.headers.get('host') || 'localhost:3000';
      const protocol = req.headers.get('x-forwarded-proto') || 'http';
      const downloadUrl = `${protocol}://${baseUrl}/api/export-workbook/${sessionId}`;

      return NextResponse.json({
        success: true,
        sessionId,
        stats: {
          tables: tablePlan.tables.length,
          cuts: cutsSpec.cuts.length,
          csvFiles: csvFiles.length,
          totalCells: tablePlan.tables.length * (cutsSpec.cuts.length + 1)
        },
        files: {
          rScript: `r/master.R`,
          manifest: `r/manifest.json`,
          csvResults: csvFiles.map(f => `results/${f}`)
        },
        download: {
          url: downloadUrl,
          filename: `crosstabs-${sessionId}.xlsx`
        },
        message: `Successfully generated ${csvFiles.length} crosstab tables. Download Excel workbook from the URL above.`
      });

    } catch (execError) {
      console.error('[Crosstab Generation] R execution failed:', execError);
      
      const errorMessage = execError instanceof Error ? execError.message : String(execError);
      const errorObj = execError as { stdout?: string; stderr?: string };
      
      if (errorMessage.includes('command not found') || errorMessage.includes('Rscript')) {
        return NextResponse.json({
          error: 'R is not installed',
          solution: 'Please install R from https://www.r-project.org/',
          alternativeMessage: 'R scripts have been generated successfully in r/master.R. You can run them manually once R is installed.'
        }, { status: 500 });
      }

      return NextResponse.json({
        error: 'R execution failed',
        details: errorMessage,
        rOutput: {
          stdout: errorObj.stdout?.substring(0, 1000),
          stderr: errorObj.stderr?.substring(0, 1000)
        }
      }, { status: 500 });
    }

  } catch (error) {
    console.error('[Crosstab Generation] Error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to generate crosstabs',
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : String(error)
          : undefined
      },
      { status: 500 }
    );
  }
}