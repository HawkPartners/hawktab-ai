/**
 * GET /api/export-workbook/[sessionId]
 * Purpose: Generate Excel workbook from CSV results (single sheet, stacked tables)
 * Reads: results/*.csv files
 * Returns: Excel workbook download
 */
import { NextRequest, NextResponse } from 'next/server';
import { promises as fs } from 'fs';
import * as path from 'path';
import ExcelJS from 'exceljs';

export async function GET(
  _req: NextRequest,
  { params }: { params: Promise<{ sessionId: string }> }
) {
  try {
    const { sessionId } = await params;
    
    // Validate sessionId
    if (!sessionId.startsWith('output-') || sessionId.includes('..') || sessionId.includes('/')) {
      return NextResponse.json({ error: 'Invalid sessionId' }, { status: 400 });
    }

    const sessionPath = path.join(process.cwd(), 'temp-outputs', sessionId);
    const resultsDir = path.join(sessionPath, 'results');

    // Check if results directory exists
    try {
      await fs.access(resultsDir);
    } catch {
      return NextResponse.json({ error: 'No results found. Execute R script first.' }, { status: 404 });
    }

    // Get all CSV files
    const resultFiles = await fs.readdir(resultsDir);
    const csvFiles = resultFiles.filter(f => f.endsWith('.csv')).sort();

    if (csvFiles.length === 0) {
      return NextResponse.json({ error: 'No CSV result files found' }, { status: 404 });
    }

    console.log(`[Excel Export] Processing ${csvFiles.length} CSV files for workbook`);

    // Create workbook
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'HawkTab AI';
    workbook.created = new Date();
    
    // Add single worksheet for all tables
    const worksheet = workbook.addWorksheet('Crosstabs', {
      properties: { tabColor: { argb: 'FF006BB3' } }
    });

    let currentRow = 1;
    const tableGap = 2; // Rows between tables

    // Process each CSV file
    for (const csvFile of csvFiles) {
      const csvPath = path.join(resultsDir, csvFile);
      const csvContent = await fs.readFile(csvPath, 'utf-8');
      
      // Parse CSV manually (simple parser for our controlled output)
      const lines = csvContent.split('\n').filter(line => line.trim());
      if (lines.length === 0) continue;

      // Extract table name from filename
      const tableName = csvFile.replace('.csv', '').replace(/-/g, ' ');
      
      // Add table title
      worksheet.getCell(currentRow, 1).value = `Table: ${tableName}`;
      worksheet.getCell(currentRow, 1).font = { bold: true, size: 12 };
      worksheet.getCell(currentRow, 1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE0E0E0' }
      };
      currentRow++;

      // Parse and add CSV data
      const data: string[][] = [];
      for (const line of lines) {
        // Simple CSV parsing (handles quoted values with commas)
        const row: string[] = [];
        let current = '';
        let inQuotes = false;
        
        for (let i = 0; i < line.length; i++) {
          const char = line[i];
          if (char === '"') {
            inQuotes = !inQuotes;
          } else if (char === ',' && !inQuotes) {
            row.push(current.trim());
            current = '';
          } else {
            current += char;
          }
        }
        row.push(current.trim());
        data.push(row);
      }

      // Add headers (first row)
      if (data.length > 0) {
        const headers = data[0];
        for (let col = 0; col < headers.length; col++) {
          const cell = worksheet.getCell(currentRow, col + 1);
          cell.value = headers[col];
          cell.font = { bold: true };
          cell.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFD9E1F2' }
          };
          cell.border = {
            top: { style: 'thin' },
            left: { style: 'thin' },
            bottom: { style: 'thin' },
            right: { style: 'thin' }
          };
        }
        currentRow++;

        // Add data rows
        for (let i = 1; i < data.length; i++) {
          const row = data[i];
          for (let col = 0; col < row.length; col++) {
            const cell = worksheet.getCell(currentRow, col + 1);
            cell.value = row[col];
            cell.border = {
              top: { style: 'thin' },
              left: { style: 'thin' },
              bottom: { style: 'thin' },
              right: { style: 'thin' }
            };
            
            // Style first column differently (row labels)
            if (col === 0) {
              cell.fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFF2F2F2' }
              };
            }
          }
          currentRow++;
        }
      }

      // Add gap between tables
      currentRow += tableGap;
    }

    // Auto-fit columns
    worksheet.columns.forEach(column => {
      if (column && column.values) {
        let maxLength = 0;
        column.values.forEach((value) => {
          if (value) {
            const length = String(value).length;
            if (length > maxLength) {
              maxLength = length;
            }
          }
        });
        column.width = Math.min(50, Math.max(10, maxLength + 2));
      }
    });

    // Generate buffer
    const buffer = await workbook.xlsx.writeBuffer();

    // Return as downloadable file
    return new NextResponse(buffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="crosstabs-${sessionId}.xlsx"`,
        'Content-Length': buffer.byteLength.toString()
      }
    });

  } catch (error) {
    console.error('[Excel Export] Error:', error);
    return NextResponse.json(
      { 
        error: 'Failed to generate Excel workbook',
        details: process.env.NODE_ENV === 'development' 
          ? error instanceof Error ? error.message : String(error)
          : undefined
      },
      { status: 500 }
    );
  }
}