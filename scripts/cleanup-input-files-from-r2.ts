/**
 * One-time migration script to delete all input files from R2.
 *
 * Purpose: Remove input files stored in R2 across all orgs/projects.
 * Input files (survey, banner, .sav) are no longer uploaded to R2 as of Phase 1.
 * Users already have these files locally, and re-runs will require re-upload.
 *
 * Safety:
 * - Requires explicit --confirm flag to actually delete files
 * - Dry-run mode by default (preview what would be deleted)
 * - Only deletes files in subfolders matching pattern: {orgId}/{projectId}/inputs/
 * - Never touches output files (results/, r/, etc.)
 * - Logs all actions to audit file
 *
 * Usage:
 *   npx tsx scripts/cleanup-input-files-from-r2.ts              # Dry-run (preview)
 *   npx tsx scripts/cleanup-input-files-from-r2.ts --confirm    # Actually delete
 */

import '../src/lib/loadEnv';
import { listAllFiles, deletePrefix } from '@/lib/r2/r2';
import { promises as fs } from 'fs';
import * as path from 'path';

interface CleanupStats {
  totalScanned: number;
  inputFilesFound: number;
  prefixesDeleted: number;
  filesDeleted: number;
  errors: number;
  startTime: number;
  endTime?: number;
}

async function cleanupInputFiles(dryRun: boolean): Promise<void> {
  const stats: CleanupStats = {
    totalScanned: 0,
    inputFilesFound: 0,
    prefixesDeleted: 0,
    filesDeleted: 0,
    errors: 0,
    startTime: Date.now(),
  };

  const auditLog: string[] = [];
  const timestamp = new Date().toISOString();

  console.log('\n========================================');
  console.log('R2 Input File Cleanup Script');
  console.log('========================================');
  console.log(`Mode: ${dryRun ? 'DRY-RUN (preview only)' : 'LIVE DELETE'}`);
  console.log(`Started: ${timestamp}\n`);

  auditLog.push(`[${timestamp}] Cleanup started (${dryRun ? 'DRY-RUN' : 'LIVE DELETE'})`);

  try {
    // Step 1: List all objects in R2 bucket
    console.log('[Step 1/3] Scanning R2 bucket for all files...');
    const allKeys = await listAllFiles(''); // Scan entire bucket
    stats.totalScanned = allKeys.length;
    console.log(`           Found ${stats.totalScanned.toLocaleString()} total files in R2\n`);
    auditLog.push(`Scanned ${stats.totalScanned} total files`);

    // Step 2: Filter to only input files (*/inputs/*)
    console.log('[Step 2/3] Filtering for input files (*/inputs/*)...');
    const inputFiles = allKeys.filter(key => key.includes('/inputs/'));
    stats.inputFilesFound = inputFiles.length;
    console.log(`           Found ${stats.inputFilesFound.toLocaleString()} input files\n`);
    auditLog.push(`Found ${stats.inputFilesFound} input files to delete`);

    if (stats.inputFilesFound === 0) {
      console.log('✓ No input files found. Nothing to clean up.\n');
      auditLog.push('No input files found - cleanup not needed');
      stats.endTime = Date.now();
      await writeAuditLog(auditLog, stats);
      return;
    }

    // Step 3: Preview or delete
    console.log('[Step 3/3] Processing input files...\n');

    if (dryRun) {
      // DRY-RUN: Show preview
      console.log('DRY-RUN MODE - Would delete the following files:\n');
      const preview = inputFiles.slice(0, 20);
      preview.forEach((key, idx) => {
        console.log(`  ${idx + 1}. ${key}`);
      });
      if (inputFiles.length > 20) {
        console.log(`  ... and ${inputFiles.length - 20} more files\n`);
      }

      // Group by org for stats
      const byOrg = new Map<string, number>();
      inputFiles.forEach(key => {
        const orgId = key.split('/')[0];
        byOrg.set(orgId, (byOrg.get(orgId) || 0) + 1);
      });

      console.log('\nBreakdown by organization:');
      Array.from(byOrg.entries())
        .sort((a, b) => b[1] - a[1])
        .forEach(([orgId, count]) => {
          console.log(`  ${orgId}: ${count} files`);
        });

      console.log('\n⚠️  This is a preview only. No files were deleted.');
      console.log('    To actually delete these files, run with --confirm flag:\n');
      console.log('    npx tsx scripts/cleanup-input-files-from-r2.ts --confirm\n');

      auditLog.push('DRY-RUN completed - no files deleted');
    } else {
      // LIVE DELETE: Group by prefix and delete in batches
      console.log('LIVE DELETE MODE - Deleting input files...\n');

      // Extract unique prefixes (e.g., "orgId/projectId/inputs/")
      const prefixes = new Set<string>();
      inputFiles.forEach(key => {
        // Find the prefix ending with "/inputs/"
        const inputsIdx = key.indexOf('/inputs/');
        if (inputsIdx !== -1) {
          const prefix = key.substring(0, inputsIdx + 8); // Include trailing slash
          prefixes.add(prefix);
        }
      });

      console.log(`Found ${prefixes.size} unique input prefixes to delete\n`);
      auditLog.push(`Deleting ${prefixes.size} prefixes containing ${inputFiles.length} files`);

      for (const prefix of Array.from(prefixes)) {
        try {
          console.log(`Deleting: ${prefix} ...`);
          const result = await deletePrefix(prefix);
          stats.prefixesDeleted++;
          stats.filesDeleted += result.deleted;
          stats.errors += result.errors;

          const statusEmoji = result.errors > 0 ? '⚠️' : '✓';
          console.log(`  ${statusEmoji} Deleted ${result.deleted} files${result.errors > 0 ? `, ${result.errors} errors` : ''}`);

          auditLog.push(`${prefix}: deleted ${result.deleted}, errors ${result.errors}`);
        } catch (err) {
          console.error(`  ✗ Failed to delete ${prefix}:`, err);
          stats.errors++;
          auditLog.push(`${prefix}: ERROR - ${err instanceof Error ? err.message : String(err)}`);
        }
      }

      console.log('\n✓ Deletion complete\n');
      auditLog.push('Live deletion completed');
    }

    stats.endTime = Date.now();
    await writeAuditLog(auditLog, stats);
    printSummary(stats, dryRun);

  } catch (error) {
    console.error('\n✗ Fatal error during cleanup:', error);
    auditLog.push(`FATAL ERROR: ${error instanceof Error ? error.message : String(error)}`);
    stats.endTime = Date.now();
    await writeAuditLog(auditLog, stats);
    throw error;
  }
}

async function writeAuditLog(entries: string[], stats: CleanupStats): Promise<void> {
  const logPath = path.join(process.cwd(), 'cleanup-input-files-audit.log');
  const content = [
    '========================================',
    'R2 Input File Cleanup Audit Log',
    '========================================',
    '',
    ...entries,
    '',
    '--- Summary ---',
    `Total files scanned: ${stats.totalScanned}`,
    `Input files found: ${stats.inputFilesFound}`,
    `Prefixes deleted: ${stats.prefixesDeleted}`,
    `Files deleted: ${stats.filesDeleted}`,
    `Errors: ${stats.errors}`,
    `Duration: ${stats.endTime ? ((stats.endTime - stats.startTime) / 1000).toFixed(1) : 'N/A'}s`,
    '',
  ].join('\n');

  await fs.writeFile(logPath, content, 'utf-8');
  console.log(`\n📝 Audit log written to: ${logPath}`);
}

function printSummary(stats: CleanupStats, dryRun: boolean): void {
  const durationSeconds = stats.endTime ? (stats.endTime - stats.startTime) / 1000 : 0;

  console.log('========================================');
  console.log('Summary');
  console.log('========================================');
  console.log(`Total files scanned:  ${stats.totalScanned.toLocaleString()}`);
  console.log(`Input files found:    ${stats.inputFilesFound.toLocaleString()}`);
  if (!dryRun) {
    console.log(`Prefixes deleted:     ${stats.prefixesDeleted}`);
    console.log(`Files deleted:        ${stats.filesDeleted.toLocaleString()}`);
    console.log(`Errors:               ${stats.errors}`);
  }
  console.log(`Duration:             ${durationSeconds.toFixed(1)}s`);
  console.log('========================================\n');

  if (!dryRun && stats.errors > 0) {
    console.log('⚠️  Some errors occurred. Check the audit log for details.\n');
  }
}

// Main execution
const args = process.argv.slice(2);
const dryRun = !args.includes('--confirm');

if (dryRun) {
  console.log('\n⚠️  Running in DRY-RUN mode (preview only)');
  console.log('    No files will be deleted.\n');
}

cleanupInputFiles(dryRun)
  .then(() => {
    console.log('✓ Script completed successfully\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n✗ Script failed:', error);
    process.exit(1);
  });
