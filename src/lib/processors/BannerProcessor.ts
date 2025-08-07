// BannerProcessor.ts - Document → PDF → Images → JSON extraction
// Streamlined implementation inspired by reference system, optimized for our architecture
// Reference: temp-reference/part1-agent.ts, preprocessing.ts, pdf-processor.ts

import fs from 'fs/promises';
import path from 'path';
import mammoth from 'mammoth';
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';
import pdf2pic from 'pdf2pic';
import sharp from 'sharp';
import OpenAI from 'openai';
import { z } from 'zod';
import { VerboseBannerPlan, AgentBannerGroup } from '../contextBuilder';
import { validateEnvironment } from '../env';

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

// Banner extraction schemas (simplified from part1-schemas.ts)
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

// Banner extraction prompt (streamlined from part1-agent.ts)
const BANNER_EXTRACTION_PROMPT = `
You are analyzing a banner plan document to extract crosstab column specifications and notes.

EXTRACTION GOALS:
1. Identify all table structures containing column definitions (these are "banner cuts")
2. Extract column names and their filter expressions exactly as written
3. Assign statistical letters (A, B, C...) in sequence
4. Group related columns into logical banner cuts
5. Extract all notes sections exactly as written

BANNER CUT DETECTION:
- Look for tabular layouts with headers and rows
- Common headers: "Column", "Group", "Filter", "Definition"
- May contain statistical letter assignments
- Tables often grouped by specialty, demographics, tiers, etc.

COLUMN EXTRACTION:
- Name: The descriptive column name (e.g., "Cards", "PCPs", "HCP")
- Original: The exact filter expression as written (e.g., "S2=1", "IF HCP")
- Preserve exact syntax including typos or ambiguities

NOTES EXTRACTION:
- Look for sections with headings like "Calculations/Rows", "Main Tab Notes", etc.
- Extract text exactly as written - preserve formatting
- Common note types: calculation_rows, main_tab_notes, other

STATISTICAL LETTERS:
- Assign letters A, B, C... Z, then AA, AB, AC...
- Follow left-to-right, top-to-bottom order
- Reserve 'T' for Total column
- Each column gets unique letter

OUTPUT REQUIREMENTS:
- Exact JSON schema compliance
- No interpretation of business logic - pure extraction only
- Include metadata about processing context

Extract all banner cut structures, column names, filter expressions, assign statistical letters in sequence, and extract all notes sections exactly as written.
`;

export class BannerProcessor {
  private openai: OpenAI;

  constructor() {
    // Validate environment and initialize OpenAI client
    const envValidation = validateEnvironment();
    if (!envValidation.valid) {
      throw new Error(`Environment validation failed: ${envValidation.errors.join(', ')}`);
    }

    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });
  }

  // Main entry point - complete banner processing workflow
  async processDocument(filePath: string): Promise<BannerProcessingResult> {
    console.log(`[BannerProcessor] Starting document processing: ${path.basename(filePath)}`);
    const startTime = Date.now();
    
    try {
      // Step 1: Ensure we have a PDF
      const pdfPath = await this.ensurePDF(filePath);
      console.log(`[BannerProcessor] PDF ready: ${path.basename(pdfPath)}`);

      // Step 2: Convert PDF to images
      const images = await this.convertPDFToImages(pdfPath);
      console.log(`[BannerProcessor] Generated ${images.length} images for processing`);

      if (images.length === 0) {
        return this.createFailureResult('No images could be generated from PDF');
      }

      // Step 3: Extract banner structure using OpenAI Vision
      const extractionResult = await this.extractBannerStructure(images);
      console.log(`[BannerProcessor] Extraction completed - Success: ${extractionResult.success}`);

      // Step 4: Generate dual outputs
      const dualOutputs = this.generateDualOutputs(extractionResult);
      
      // Step 5: Save development outputs (same pattern as DataMapProcessor)
      if (process.env.NODE_ENV === 'development') {
        await this.saveDevelopmentOutputs(dualOutputs, filePath);
      }
      
      const processingTime = Date.now() - startTime;
      console.log(`[BannerProcessor] Processing completed in ${processingTime}ms`);

      return {
        verbose: dualOutputs.verbose,
        agent: dualOutputs.agent,
        success: extractionResult.success,
        confidence: this.calculateOverallConfidence(extractionResult),
        errors: extractionResult.errors || [],
        warnings: extractionResult.warnings || []
      };

    } catch (error) {
      console.error('[BannerProcessor] Processing failed:', error);
      return this.createFailureResult(
        error instanceof Error ? error.message : 'Unknown processing error'
      );
    }
  }

  // Step 1: Document → PDF conversion (if needed)
  private async ensurePDF(filePath: string): Promise<string> {
    const fileExt = path.extname(filePath).toLowerCase();
    
    // If already PDF, return as-is
    if (fileExt === '.pdf') {
      return filePath;
    }

    // Convert Word documents to PDF
    if (['.doc', '.docx'].includes(fileExt)) {
      const outputPath = filePath.replace(/\.(doc|docx)$/i, '.pdf');
      const result = await this.convertWordToPDF(filePath, outputPath);
      
      if (!result.success || !result.pdfPath) {
        throw new Error(`Word to PDF conversion failed: ${result.error}`);
      }
      
      return result.pdfPath;
    }

    throw new Error(`Unsupported file format: ${fileExt}`);
  }

  // Word document conversion (simplified from document-converter.ts)
  private async convertWordToPDF(wordFilePath: string, outputPdfPath: string): Promise<{success: boolean; pdfPath?: string; error?: string}> {
    try {
      // Check file size
      const stats = await fs.stat(wordFilePath);
      if (stats.size > BANNER_CONFIG.maxFileSizeMB * 1024 * 1024) {
        return {
          success: false,
          error: `File size exceeds ${BANNER_CONFIG.maxFileSizeMB}MB limit`
        };
      }

      // Extract text from Word document
      const buffer = await fs.readFile(wordFilePath);
      const result = await mammoth.extractRawText({ buffer });
      
      if (result.messages.length > 0) {
        console.warn('Word conversion warnings:', result.messages);
      }
      
      // Create PDF document
      const pdfDoc = await PDFDocument.create();
      const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
      const fontSize = 12;
      const lineHeight = fontSize * 1.2;
      const margin = 50;
      
      // Split text into lines and pages
      const lines = result.value.split('\n');
      let currentPage = pdfDoc.addPage();
      const { width, height } = currentPage.getSize();
      let y = height - margin;
      
      for (const line of lines) {
        // Check if we need a new page
        if (y < margin + lineHeight) {
          currentPage = pdfDoc.addPage();
          y = height - margin;
        }
        
        // Draw the text
        currentPage.drawText(line, {
          x: margin,
          y,
          size: fontSize,
          font,
          color: rgb(0, 0, 0),
          maxWidth: width - 2 * margin,
        });
        
        y -= lineHeight;
      }
      
      // Save the PDF
      const pdfBytes = await pdfDoc.save();
      await fs.writeFile(outputPdfPath, pdfBytes);
      
      return {
        success: true,
        pdfPath: outputPdfPath
      };
      
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown conversion error'
      };
    }
  }

  // Step 2: PDF → High-res images (inspired by preprocessing.ts)
  private async convertPDFToImages(pdfPath: string): Promise<ProcessedImage[]> {
    const images: ProcessedImage[] = [];
    
    try {
      // Convert PDF to images using pdf2pic
      const convert = pdf2pic.fromPath(pdfPath, {
        density: BANNER_CONFIG.imageDPI,
        saveFilename: 'page',
        savePath: path.dirname(pdfPath),
        format: BANNER_CONFIG.imageFormat,
        width: BANNER_CONFIG.maxImageResolution,
        height: BANNER_CONFIG.maxImageResolution
      });

      // Get PDF page count
      const pdfBuffer = await fs.readFile(pdfPath);
      const pdfDoc = await PDFDocument.load(pdfBuffer);
      const pageCount = pdfDoc.getPageCount();

      // Convert each page
      for (let pageNum = 1; pageNum <= pageCount; pageNum++) {
        try {
          const result = await convert(pageNum);
          
          if (result && result.path) {
            // Optimize image with Sharp
            const optimizedBuffer = await sharp(result.path)
              .png({ quality: 95 })
              .resize({ 
                width: BANNER_CONFIG.maxImageResolution, 
                height: BANNER_CONFIG.maxImageResolution, 
                fit: 'inside',
                withoutEnlargement: true 
              })
              .toBuffer();

            // Get image metadata
            const metadata = await sharp(optimizedBuffer).metadata();
            
            // Convert to base64
            const base64 = optimizedBuffer.toString('base64');

            images.push({
              pageNumber: pageNum,
              base64,
              width: metadata.width || 0,
              height: metadata.height || 0,
              format: BANNER_CONFIG.imageFormat
            });

            // Clean up temporary file
            try {
              await fs.unlink(result.path);
            } catch {
              // Ignore cleanup errors
            }
          }
        } catch (pageError) {
          console.error(`Error converting page ${pageNum}:`, pageError);
          // Continue with other pages
        }
      }

      console.log(`[BannerProcessor] Successfully converted ${images.length}/${pageCount} pages`);
      return images;

    } catch (error) {
      console.error('[BannerProcessor] PDF to image conversion failed:', error);
      return [];
    }
  }

  // Step 3: Images → JSON extraction (direct OpenAI call, not agent-based)
  private async extractBannerStructure(images: ProcessedImage[]): Promise<BannerExtractionResult> {
    try {
      // Prepare image content for OpenAI
      const imageContent = images.map(img => ({
        type: 'image_url' as const,
        image_url: {
          url: `data:image/${img.format};base64,${img.base64}`,
          detail: 'high' as const
        }
      }));

      // Make direct OpenAI API call with vision + structured output
      const completion = await this.openai.chat.completions.create({
        model: process.env.BASE_MODEL || 'gpt-4o',
        max_tokens: parseInt(process.env.BASE_MODEL_TOKENS || '32768'),
        temperature: 0.1,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: BANNER_EXTRACTION_PROMPT
              },
              ...imageContent
            ]
          }
        ],
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'banner_extraction',
            schema: {
              type: 'object',
              properties: {
                success: { type: 'boolean' },
                extractionType: { type: 'string', enum: ['banner_extraction'] },
                timestamp: { type: 'string' },
                extractedStructure: {
                  type: 'object',
                  properties: {
                    bannerCuts: {
                      type: 'array',
                      items: {
                        type: 'object',
                        properties: {
                          groupName: { type: 'string' },
                          columns: {
                            type: 'array',
                            items: {
                              type: 'object',
                              properties: {
                                name: { type: 'string' },
                                original: { type: 'string' },
                                statLetter: { type: 'string' },
                                adjusted: { type: 'string', default: '' },
                                confidence: { type: 'number', minimum: 0, maximum: 1, default: 1 },
                                requiresInference: { type: 'boolean', default: false },
                                crossRefStatus: { type: 'string', default: '' },
                                inferenceReason: { type: 'string', default: '' },
                                humanInLoopRequired: { type: 'boolean', default: false },
                                aiRecommended: { type: 'boolean', default: false },
                                uncertainties: { type: 'array', items: { type: 'string' }, default: [] }
                              },
                              required: ['name', 'original', 'statLetter']
                            }
                          }
                        },
                        required: ['groupName', 'columns']
                      }
                    },
                    notes: {
                      type: 'array',
                      items: {
                        type: 'object',
                        properties: {
                          type: { type: 'string', enum: ['calculation_rows', 'main_tab_notes', 'other'] },
                          original: { type: 'string' },
                          adjusted: { type: 'string', default: '' }
                        },
                        required: ['type', 'original']
                      },
                      default: []
                    },
                    processingMetadata: {
                      type: 'object',
                      properties: {
                        totalColumns: { type: 'number' },
                        groupCount: { type: 'number' },
                        statisticalLettersUsed: { type: 'array', items: { type: 'string' } },
                        processingTimestamp: { type: 'string' }
                      },
                      required: ['totalColumns', 'groupCount', 'statisticalLettersUsed', 'processingTimestamp']
                    }
                  },
                  required: ['bannerCuts', 'processingMetadata']
                },
                errors: { type: 'array', items: { type: 'string' } },
                warnings: { type: 'array', items: { type: 'string' } }
              },
              required: ['success', 'extractionType', 'timestamp', 'extractedStructure']
            }
          }
        }
      });

      // Parse and validate the response
      const content = completion.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No content returned from OpenAI');
      }

      const rawResult = JSON.parse(content);
      
      // Add required fields if missing
      const processedResult = {
        ...rawResult,
        extractionType: 'banner_extraction' as const,
        timestamp: new Date().toISOString(),
        extractedStructure: {
          ...rawResult.extractedStructure,
          processingMetadata: {
            ...rawResult.extractedStructure.processingMetadata,
            processingTimestamp: new Date().toISOString()
          }
        }
      };

      // Validate with Zod schema
      const validatedResult = BannerExtractionResultSchema.parse(processedResult);
      
      console.log(`[BannerProcessor] Extraction successful - ${validatedResult.extractedStructure.bannerCuts.length} banner cuts, ${validatedResult.extractedStructure.processingMetadata.totalColumns} columns`);
      
      return validatedResult;

    } catch (error) {
      console.error('[BannerProcessor] Structure extraction failed:', error);
      
      return {
        success: false,
        extractionType: 'banner_extraction' as const,
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
        errors: [error instanceof Error ? error.message : 'Unknown extraction error'],
        warnings: null
      };
    }
  }

  // Step 4: Generate dual outputs (verbose + agent formats)
  private generateDualOutputs(extractionResult: BannerExtractionResult): { verbose: VerboseBannerPlan; agent: AgentBannerGroup[] } {
    // Verbose format (matches our existing VerboseBannerPlan interface)
    const verbose: VerboseBannerPlan = {
      success: extractionResult.success,
      data: {
        success: extractionResult.success,
        extractionType: extractionResult.extractionType,
        timestamp: extractionResult.timestamp,
        extractedStructure: {
          bannerCuts: extractionResult.extractedStructure.bannerCuts.map(cut => ({
            groupName: cut.groupName,
            columns: cut.columns.map(col => ({
              name: col.name,
              original: col.original,
              adjusted: col.adjusted,
              statLetter: col.statLetter,
              confidence: col.confidence,
              requiresInference: col.requiresInference,
              crossRefStatus: col.crossRefStatus,
              inferenceReason: col.inferenceReason,
              humanInLoopRequired: col.humanInLoopRequired,
              aiRecommended: col.aiRecommended,
              uncertainties: col.uncertainties
            }))
          })),
          notes: extractionResult.extractedStructure.notes || [],
          processingMetadata: extractionResult.extractedStructure.processingMetadata
        },
        errors: extractionResult.errors,
        warnings: extractionResult.warnings
      },
      timestamp: extractionResult.timestamp
    };

    // Agent format (simplified for downstream agent processing)
    const agent: AgentBannerGroup[] = extractionResult.extractedStructure.bannerCuts.map(cut => ({
      groupName: cut.groupName,
      columns: cut.columns.map(col => ({
        name: col.name,
        original: col.original
      }))
    }));

    return { verbose, agent };
  }

  // Helper: Calculate overall confidence from extraction result
  private calculateOverallConfidence(result: BannerExtractionResult): number {
    if (!result.success || result.extractedStructure.bannerCuts.length === 0) {
      return 0;
    }

    // Average confidence across all columns
    const allColumns = result.extractedStructure.bannerCuts.flatMap(cut => cut.columns);
    if (allColumns.length === 0) {
      return 0;
    }

    const totalConfidence = allColumns.reduce((sum, col) => sum + col.confidence, 0);
    return totalConfidence / allColumns.length;
  }

  // Helper: Create failure result
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
      confidence: 0,
      errors: [error],
      warnings: []
    };
  }

  // ===== DEVELOPMENT OUTPUT =====

  private async saveDevelopmentOutputs(outputs: { verbose: VerboseBannerPlan; agent: AgentBannerGroup[] }, originalFilePath: string): Promise<void> {
    try {
      const outputDir = path.join(process.cwd(), 'temp-outputs');
      await fs.mkdir(outputDir, { recursive: true });

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const baseName = path.parse(originalFilePath).name;

      // Save verbose output
      const verboseFile = path.join(outputDir, `banner-${baseName}-verbose-${timestamp}.json`);
      await fs.writeFile(verboseFile, JSON.stringify(outputs.verbose, null, 2));
      console.log(`[Dev Output] Saved banner verbose: ${verboseFile}`);

      // Save agent output  
      const agentFile = path.join(outputDir, `banner-${baseName}-agent-${timestamp}.json`);
      await fs.writeFile(agentFile, JSON.stringify(outputs.agent, null, 2));
      console.log(`[Dev Output] Saved banner agent: ${agentFile}`);

    } catch (error) {
      console.warn(`[Dev Output] Failed to save banner outputs:`, error);
    }
  }

}