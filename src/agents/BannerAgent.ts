/**
 * BannerAgent
 * Purpose: Extract banner groups and columns from DOC/PDF via Agents SDK (with scratchpad)
 * Reads: uploaded banner plan file (doc/docx/pdf → converted to images)
 * Writes (dev): temp-outputs/output-<ts>/banner-*-{verbose|agent}-<ts>.json
 * Invariants: focus on logical group separation; preserve column names and originals
 */

import { Agent, run } from '@openai/agents';
import fs from 'fs/promises';
import path from 'path';
import mammoth from 'mammoth';
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';
import pdf2pic from 'pdf2pic';
import sharp from 'sharp';
import { z } from 'zod';
import { VerboseBannerPlan, AgentBannerGroup } from '../lib/contextBuilder';
import { getPromptVersions } from '../lib/env';
import { getBannerPrompt } from '../prompts';
import { scratchpadTool } from './tools/scratchpad';
import { getModel, getModelTokenLimit } from '../lib/env';

// Types for internal processing
export interface ProcessedImage {
  pageNumber: number;
  base64: string;
  width: number;
  height: number;
  format: string;
}

export interface BannerProcessingResult {
  verbose: VerboseBannerPlan;
  agent: AgentBannerGroup[];
  success: boolean;
  confidence: number;
  errors: string[];
  warnings: string[];
}

// Banner extraction schemas (same as BannerProcessor)
const BannerColumnSchema = z.object({
  name: z.string(),
  original: z.string(),
  adjusted: z.string().default(''),
  statLetter: z.string(),
  confidence: z.number().min(0).max(1).default(1),
  requiresInference: z.boolean().default(false),
  crossRefStatus: z.string().default(''),
  inferenceReason: z.string().default(''),
  humanInLoopRequired: z.boolean().default(false),
  aiRecommended: z.boolean().default(false),
  uncertainties: z.array(z.string()).default([])
});

const BannerCutSchema = z.object({
  groupName: z.string(),
  columns: z.array(BannerColumnSchema)
});

const BannerNotesSchema = z.object({
  type: z.enum(['calculation_rows', 'main_tab_notes', 'other']),
  original: z.string(),
  adjusted: z.string().default('')
});

const ExtractedBannerStructureSchema = z.object({
  bannerCuts: z.array(BannerCutSchema),
  notes: z.array(BannerNotesSchema).default([]),
  processingMetadata: z.object({
    totalColumns: z.number(),
    groupCount: z.number(),
    statisticalLettersUsed: z.array(z.string()),
    processingTimestamp: z.string()
  })
});

const BannerExtractionResultSchema = z.object({
  success: z.boolean(),
  extractionType: z.literal('banner_extraction'),
  timestamp: z.string(),
  extractedStructure: ExtractedBannerStructureSchema,
  errors: z.array(z.string()).nullable(),
  warnings: z.array(z.string()).nullable()
});

type BannerExtractionResult = z.infer<typeof BannerExtractionResultSchema>;

// Configuration
const BANNER_CONFIG = {
  maxFileSizeMB: 50,
  maxProcessingTimeMs: 300000, // 5 minutes
  imageFormat: 'png' as const,
  imageDPI: 300,
  maxImageResolution: 4096,
  confidenceThreshold: 0.7
};

// Get modular banner extraction prompt based on environment variable
const getBannerExtractionPrompt = (): string => {
  const promptVersions = getPromptVersions();
  return getBannerPrompt(promptVersions.bannerPromptVersion);
};

// Create Banner Agent with scratchpad tool
const createBannerAgent = (images: ProcessedImage[]) => {
  const enhancedInstructions = `
${getBannerExtractionPrompt()}

IMAGES TO ANALYZE:
You have ${images.length} image(s) of the banner plan document to analyze.

PROCESSING REQUIREMENTS:
- Use your scratchpad to think through the group identification process
- Identify visual separators, merged headers, and logical groupings
- Create separate bannerCuts entries for each logical group
- Show your reasoning for group boundaries in the scratchpad
- Extract all columns with exact filter expressions

Begin analysis now.
`;

  const agent = new Agent({
    name: 'BannerAgent',
    instructions: enhancedInstructions,
    model: getModel(),
    outputType: BannerExtractionResultSchema,
    tools: [scratchpadTool],
    modelSettings: {
      maxTokens: Math.min(getModelTokenLimit(), 32000)
    }
  });

  return agent;
};

export class BannerAgent {
  // Main entry point - complete banner processing workflow
  async processDocument(filePath: string, outputFolder?: string): Promise<BannerProcessingResult> {
    console.log(`[BannerAgent] Starting document processing: ${path.basename(filePath)}`);
    const startTime = Date.now();
    
    try {
      // Step 1: Ensure we have a PDF
      const pdfPath = await this.ensurePDF(filePath);
      console.log(`[BannerAgent] PDF ready: ${path.basename(pdfPath)}`);

      // Step 2: Convert PDF to images
      const images = await this.convertPDFToImages(pdfPath);
      console.log(`[BannerAgent] Generated ${images.length} images for processing`);

      if (images.length === 0) {
        return this.createFailureResult('No images could be generated from PDF');
      }

      // Step 3: Extract banner structure using Banner Agent
      const extractionResult = await this.extractBannerStructureWithAgent(images);
      console.log(`[BannerAgent] Agent extraction completed - Success: ${extractionResult.success}`);

      // Step 4: Generate dual outputs
      const dualOutputs = this.generateDualOutputs(extractionResult);
      
      // Step 5: Save development outputs
      if (process.env.NODE_ENV === 'development' && outputFolder) {
        await this.saveDevelopmentOutputs(dualOutputs, filePath, outputFolder);
      }
      
      const processingTime = Date.now() - startTime;
      console.log(`[BannerAgent] Processing completed in ${processingTime}ms`);

      return {
        verbose: dualOutputs.verbose,
        agent: dualOutputs.agent,
        success: extractionResult.success,
        confidence: this.calculateConfidence(extractionResult),
        errors: extractionResult.errors || [],
        warnings: extractionResult.warnings || []
      };

    } catch (error) {
      console.error('[BannerAgent] Processing failed:', error);
      return this.createFailureResult(
        error instanceof Error ? error.message : 'Unknown processing error'
      );
    }
  }

  // Agent-based extraction with scratchpad reasoning
  private async extractBannerStructureWithAgent(images: ProcessedImage[]): Promise<BannerExtractionResult> {
    console.log(`[BannerAgent] Starting agent-based extraction with ${images.length} images`);
    
    try {
      const agent = createBannerAgent(images);
      
      // Prepare image content for agent (using Agents SDK format)
      const imageContent = images.map(img => ({
        type: 'input_image' as const,
        image: `data:image/${img.format};base64,${img.base64}`
      }));

      // Run agent with images
      const result = await run(
        agent,
        [
          {
            role: 'user',
            content: [
              {
                type: 'input_text',
                text: 'Analyze the banner plan images and extract column specifications with proper group separation.'
              },
              ...imageContent
            ]
          }
        ],
        {
          maxTurns: 15 // Allow for scratchpad interactions
        }
      );

      // Handle potential type assertion issues from SDK
      const extractionResult = result.finalOutput as unknown as BannerExtractionResult;
      
      if (!extractionResult || !extractionResult.extractedStructure) {
        throw new Error('Invalid agent response structure');
      }

      console.log(`[BannerAgent] Agent extracted ${extractionResult.extractedStructure.bannerCuts.length} groups`);
      
      return extractionResult;
      
    } catch (error) {
      console.error('[BannerAgent] Agent extraction failed:', error);
      
      // Return structured failure result
      return {
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
        errors: [error instanceof Error ? error.message : 'Agent extraction failed'],
        warnings: null
      };
    }
  }

  // Step 1: DOC/DOCX → PDF conversion
  private async ensurePDF(filePath: string): Promise<string> {
    const ext = path.extname(filePath).toLowerCase();
    
    if (ext === '.pdf') {
      return filePath;
    }
    
    if (ext === '.doc' || ext === '.docx') {
      return await this.convertDocToPDF(filePath);
    }
    
    throw new Error(`Unsupported file format: ${ext}. Only PDF, DOC, and DOCX files are supported.`);
  }

  private async convertDocToPDF(docPath: string): Promise<string> {
    console.log(`[BannerAgent] Converting ${path.basename(docPath)} to PDF`);
    
    try {
      // Extract text content from DOC/DOCX
      const result = await mammoth.extractRawText({ path: docPath });
      const textContent = result.value;
      
      if (!textContent.trim()) {
        throw new Error('No text content found in document');
      }
      
      // Create PDF from text content with proper multi-page handling
      const pdfDoc = await PDFDocument.create();
      const helveticaFont = await pdfDoc.embedFont(StandardFonts.Helvetica);
      const fontSize = 12;
      const lineHeight = fontSize * 1.2;
      const margin = 50;
      
      // Split text into lines and pages (matching old implementation)
      const lines = textContent.split('\n');
      let currentPage = pdfDoc.addPage();
      const { width, height } = currentPage.getSize();
      let y = height - margin;
      
      for (const line of lines) {
        // Check if we need a new page
        if (y < margin + lineHeight) {
          currentPage = pdfDoc.addPage();
          y = height - margin;
        }
        
        // Draw the text line by line
        currentPage.drawText(line, {
          x: margin,
          y,
          size: fontSize,
          font: helveticaFont,
          color: rgb(0, 0, 0),
          maxWidth: width - 2 * margin,
        });
        
        y -= lineHeight;
      }
      
      // Save PDF
      const pdfBytes = await pdfDoc.save();
      const pdfPath = docPath.replace(/\.(doc|docx)$/i, '.pdf');
      await fs.writeFile(pdfPath, pdfBytes);
      
      console.log(`[BannerAgent] PDF created: ${path.basename(pdfPath)}`);
      return pdfPath;
      
    } catch (error) {
      throw new Error(`DOC to PDF conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Step 2: PDF → Images conversion
  private async convertPDFToImages(pdfPath: string): Promise<ProcessedImage[]> {
    console.log(`[BannerAgent] Converting PDF to images: ${path.basename(pdfPath)}`);
    
    try {
      // Create temp directory for image conversion
      const tempDir = path.join(process.cwd(), 'temp-images');
      await fs.mkdir(tempDir, { recursive: true });
      
      // Get PDF page count first
      const pdfBuffer = await fs.readFile(pdfPath);
      const pdfDoc = await PDFDocument.load(pdfBuffer);
      const pageCount = pdfDoc.getPageCount();
      
      const convert = pdf2pic.fromPath(pdfPath, {
        density: BANNER_CONFIG.imageDPI,
        saveFilename: 'page',
        savePath: tempDir,
        format: BANNER_CONFIG.imageFormat,
        width: BANNER_CONFIG.maxImageResolution,
        height: BANNER_CONFIG.maxImageResolution
      });
      
      // Convert each page individually (more reliable than bulk)
      const processedImages: ProcessedImage[] = [];
      
      for (let pageNum = 1; pageNum <= pageCount; pageNum++) {
        try {
          const result = await convert(pageNum);
          
          if (result && result.path) {
            // Read and optimize image
            const imageBuffer = await fs.readFile(result.path);
            const optimizedBuffer = await sharp(imageBuffer)
              .resize(BANNER_CONFIG.maxImageResolution, BANNER_CONFIG.maxImageResolution, { 
                fit: 'inside',
                withoutEnlargement: true 
              })
              .png({ quality: 90 })
              .toBuffer();
            
            const base64 = optimizedBuffer.toString('base64');
            const metadata = await sharp(optimizedBuffer).metadata();
            
            processedImages.push({
              pageNumber: pageNum,
              base64,
              width: metadata.width || 0,
              height: metadata.height || 0,
              format: BANNER_CONFIG.imageFormat
            });
            
            // Clean up temp file
            await fs.unlink(result.path);
          }
        } catch (pageError) {
          console.error(`[BannerAgent] Error converting page ${pageNum}:`, pageError);
          // Continue with other pages
        }
      }
      
      console.log(`[BannerAgent] Successfully converted ${processedImages.length}/${pageCount} pages`);
      
      // Clean up temp directory
      try {
        await fs.rm(tempDir, { recursive: true });
      } catch (cleanupError) {
        console.warn(`[BannerAgent] Failed to clean up temp directory: ${cleanupError}`);
      }
      
      console.log(`[BannerAgent] Generated ${processedImages.length} optimized images`);
      return processedImages;
      
    } catch (error) {
      throw new Error(`PDF to images conversion failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  // Generate dual outputs (verbose + agent)
  private generateDualOutputs(extractionResult: BannerExtractionResult) {
    // Verbose output (full structure)
    const verbose: VerboseBannerPlan = {
      success: extractionResult.success,
      data: extractionResult,
      timestamp: new Date().toISOString()
    };

    // Agent output (simplified structure)
    const agent: AgentBannerGroup[] = extractionResult.success 
      ? extractionResult.extractedStructure.bannerCuts.map(group => ({
          groupName: group.groupName,
          columns: group.columns.map(col => ({
            name: col.name,
            original: col.original
          }))
        }))
      : [];

    return { verbose, agent };
  }

  // Calculate confidence score based on extraction results
  private calculateConfidence(result: BannerExtractionResult): number {
    if (!result.success || result.extractedStructure.bannerCuts.length === 0) {
      return 0.0;
    }

    const totalColumns = result.extractedStructure.bannerCuts
      .reduce((sum, group) => sum + group.columns.length, 0);
    
    const groupCount = result.extractedStructure.bannerCuts.length;
    
    // Higher confidence for multiple groups with reasonable column distribution
    let confidence = 0.7; // Base confidence
    
    if (groupCount > 1) confidence += 0.2; // Bonus for multiple groups
    if (groupCount >= 4) confidence += 0.1; // Extra bonus for 4+ groups
    if (totalColumns >= 10) confidence += 0.1; // Bonus for substantial content
    
    return Math.min(confidence, 1.0);
  }

  // Create failure result
  private createFailureResult(error: string): BannerProcessingResult {
    return {
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
          errors: [error],
          warnings: null
        },
        timestamp: new Date().toISOString()
      },
      agent: [],
      success: false,
      confidence: 0.0,
      errors: [error],
      warnings: []
    };
  }

  // Save development outputs
  private async saveDevelopmentOutputs(
    dualOutputs: { verbose: VerboseBannerPlan; agent: AgentBannerGroup[] },
    originalFilePath: string,
    outputFolder: string
  ): Promise<void> {
    try {
      const outputDir = path.join(process.cwd(), 'temp-outputs', outputFolder);
      await fs.mkdir(outputDir, { recursive: true });

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const baseName = path.basename(originalFilePath, path.extname(originalFilePath));

      // Save verbose output
      const verboseFilename = `banner-${baseName}-verbose-${timestamp}.json`;
      const verbosePath = path.join(outputDir, verboseFilename);
      await fs.writeFile(verbosePath, JSON.stringify(dualOutputs.verbose, null, 2), 'utf-8');

      // Save agent output
      const agentFilename = `banner-${baseName}-agent-${timestamp}.json`;
      const agentPath = path.join(outputDir, agentFilename);
      await fs.writeFile(agentPath, JSON.stringify(dualOutputs.agent, null, 2), 'utf-8');

      console.log(`[BannerAgent] Development outputs saved: ${verboseFilename}, ${agentFilename}`);
    } catch (error) {
      console.error('[BannerAgent] Failed to save development outputs:', error);
    }
  }
}