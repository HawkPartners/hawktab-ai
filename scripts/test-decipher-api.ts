/**
 * Decipher API Test Script
 *
 * Purpose: Validate Decipher API access and explore available data
 *
 * Usage:
 *   export DECIPHER_API_KEY="your-64-char-api-key"
 *   export DECIPHER_BASE_URL="https://v2.decipherinc.com"  # or your server
 *   export DECIPHER_SURVEY_PATH="selfserve/xxxx/yyyy"      # your survey path
 *
 *   npx tsx scripts/test-decipher-api.ts
 *
 * Or run interactively:
 *   npx tsx scripts/test-decipher-api.ts --interactive
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import * as readline from 'readline';

interface TestConfig {
  apiKey: string;
  baseUrl: string;
  surveyPath: string;
}

interface DecipherQuestion {
  qlabel: string;
  qtitle?: string;
  type?: string;
  cond?: string;
  variables?: DecipherVariable[];
  values?: { value: string | number; label: string }[];
}

interface DecipherVariable {
  label: string;
  qlabel: string;
  title?: string;
  qtitle?: string;
  type?: string;
  vgroup?: string;
  row?: string;
  col?: string;
  rowTitle?: string;
  colTitle?: string;
}

interface DecipherDatamap {
  questions?: DecipherQuestion[];
  variables?: DecipherVariable[];
}

interface DecipherDataResponse {
  complete: boolean;
  data?: Record<string, unknown>[];
}

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  cyan: '\x1b[36m',
  dim: '\x1b[2m',
};

function log(message: string, color: keyof typeof colors = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function fetchAPI<T>(url: string, apiKey: string): Promise<{ ok: boolean; status: number; data?: T; error?: string }> {
  try {
    const response = await fetch(url, {
      headers: {
        'x-apikey': apiKey,
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      return {
        ok: false,
        status: response.status,
        error: `${response.status} ${response.statusText}`
      };
    }

    const data = await response.json() as T;
    return { ok: true, status: response.status, data };
  } catch (error) {
    return {
      ok: false,
      status: 0,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

async function testDatamap(config: TestConfig): Promise<DecipherDatamap | null> {
  log('\n1. DATAMAP TEST', 'bright');
  log('   Endpoint: /api/v1/surveys/{path}/datamap?format=json', 'dim');

  const url = `${config.baseUrl}/api/v1/surveys/${config.surveyPath}/datamap?format=json`;
  const result = await fetchAPI<DecipherDatamap>(url, config.apiKey);

  if (!result.ok) {
    log(`   FAILED: ${result.error}`, 'red');
    return null;
  }

  const datamap = result.data!;
  const questionCount = datamap.questions?.length ?? 0;
  const variableCount = datamap.variables?.length ?? 0;

  log(`   Found ${questionCount} questions`, 'green');
  log(`   Found ${variableCount} variables`, 'green');

  // Check for skip logic
  const questionsWithCond = datamap.questions?.filter(q => q.cond) ?? [];
  log(`   Questions with skip logic (cond): ${questionsWithCond.length}`, questionsWithCond.length > 0 ? 'green' : 'yellow');

  if (questionsWithCond.length > 0) {
    log('\n   Sample skip logic conditions:', 'cyan');
    questionsWithCond.slice(0, 5).forEach(q => {
      log(`   - ${q.qlabel}: cond="${q.cond}"`, 'dim');
    });
  }

  // Show question types
  const types = new Set(datamap.questions?.map(q => q.type).filter(Boolean));
  if (types.size > 0) {
    log(`\n   Question types found: ${[...types].join(', ')}`, 'dim');
  }

  return datamap;
}

async function testDataExport(config: TestConfig): Promise<boolean> {
  log('\n2. DATA EXPORT TEST', 'bright');
  log('   Endpoint: /api/v1/surveys/{path}/data?format=json&limit=5', 'dim');

  const url = `${config.baseUrl}/api/v1/surveys/${config.surveyPath}/data?format=json&limit=5&cond=qualified`;
  const result = await fetchAPI<DecipherDataResponse>(url, config.apiKey);

  if (!result.ok) {
    log(`   FAILED: ${result.error}`, 'red');
    if (result.status === 403) {
      log('   Note: You may not have data access permission for this survey', 'yellow');
    }
    return false;
  }

  const response = result.data!;
  const recordCount = response.data?.length ?? 0;

  log(`   Retrieved ${recordCount} sample records`, 'green');
  log(`   Complete dataset: ${response.complete}`, 'green');

  if (recordCount > 0 && response.data) {
    const sampleRecord = response.data[0];
    const fieldCount = Object.keys(sampleRecord).length;
    log(`   Fields per record: ${fieldCount}`, 'dim');

    // Show sample fields
    const fields = Object.keys(sampleRecord).slice(0, 10);
    log(`   Sample fields: ${fields.join(', ')}${fieldCount > 10 ? '...' : ''}`, 'dim');
  }

  return true;
}

async function testSurveyMetadata(config: TestConfig): Promise<boolean> {
  log('\n3. SURVEY METADATA TEST', 'bright');
  log('   Endpoint: /api/v1/surveys/{path}', 'dim');

  const url = `${config.baseUrl}/api/v1/surveys/${config.surveyPath}`;
  const result = await fetchAPI<Record<string, unknown>>(url, config.apiKey);

  if (!result.ok) {
    log(`   FAILED: ${result.error}`, 'red');
    return false;
  }

  const metadata = result.data!;
  log(`   Survey accessible: YES`, 'green');

  // Show available metadata fields
  const fields = Object.keys(metadata);
  log(`   Metadata fields: ${fields.slice(0, 10).join(', ')}${fields.length > 10 ? '...' : ''}`, 'dim');

  // Check for status if available
  if ('state' in metadata) {
    log(`   Survey state: ${metadata.state}`, 'cyan');
  }
  if ('status' in metadata) {
    log(`   Survey status: ${metadata.status}`, 'cyan');
  }

  return true;
}

async function saveDatamapSample(datamap: DecipherDatamap, outputDir: string): Promise<void> {
  log('\n4. SAVING SAMPLE OUTPUT', 'bright');

  try {
    await fs.mkdir(outputDir, { recursive: true });

    // Save full datamap
    const datamapPath = path.join(outputDir, 'datamap-sample.json');
    await fs.writeFile(datamapPath, JSON.stringify(datamap, null, 2));
    log(`   Saved: ${datamapPath}`, 'green');

    // Save questions with conditions only
    const questionsWithCond = datamap.questions?.filter(q => q.cond) ?? [];
    if (questionsWithCond.length > 0) {
      const condPath = path.join(outputDir, 'skip-logic-sample.json');
      await fs.writeFile(condPath, JSON.stringify(questionsWithCond, null, 2));
      log(`   Saved: ${condPath}`, 'green');
    }

    // Save variable summary
    const variableSummary = datamap.variables?.slice(0, 50).map(v => ({
      label: v.label,
      qlabel: v.qlabel,
      type: v.type,
      title: v.title?.substring(0, 100),
    }));
    if (variableSummary) {
      const varPath = path.join(outputDir, 'variables-sample.json');
      await fs.writeFile(varPath, JSON.stringify(variableSummary, null, 2));
      log(`   Saved: ${varPath}`, 'green');
    }
  } catch (error) {
    log(`   Failed to save: ${error instanceof Error ? error.message : 'Unknown error'}`, 'red');
  }
}

async function promptForConfig(): Promise<TestConfig | null> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const question = (prompt: string): Promise<string> => {
    return new Promise(resolve => {
      rl.question(prompt, resolve);
    });
  };

  try {
    log('\n=== Decipher API Configuration ===\n', 'bright');

    const apiKey = await question('API Key (64 characters): ');
    if (!apiKey || apiKey.length < 10) {
      log('Invalid API key', 'red');
      return null;
    }

    const baseUrl = await question('Base URL [https://v2.decipherinc.com]: ');
    const surveyPath = await question('Survey Path (e.g., selfserve/1234/mysurvey): ');

    if (!surveyPath) {
      log('Survey path is required', 'red');
      return null;
    }

    return {
      apiKey,
      baseUrl: baseUrl || 'https://v2.decipherinc.com',
      surveyPath,
    };
  } finally {
    rl.close();
  }
}

async function main() {
  log('='.repeat(60), 'cyan');
  log('  DECIPHER API EXPLORATION TEST', 'bright');
  log('='.repeat(60), 'cyan');

  // Determine config source
  const isInteractive = process.argv.includes('--interactive');

  let config: TestConfig;

  if (isInteractive) {
    const inputConfig = await promptForConfig();
    if (!inputConfig) {
      process.exit(1);
    }
    config = inputConfig;
  } else {
    // Use environment variables
    config = {
      apiKey: process.env.DECIPHER_API_KEY || '',
      baseUrl: process.env.DECIPHER_BASE_URL || 'https://v2.decipherinc.com',
      surveyPath: process.env.DECIPHER_SURVEY_PATH || '',
    };

    if (!config.apiKey) {
      log('\nError: DECIPHER_API_KEY environment variable required', 'red');
      log('Or run with --interactive flag to enter manually', 'dim');
      log('\nUsage:', 'bright');
      log('  export DECIPHER_API_KEY="your-api-key"', 'dim');
      log('  export DECIPHER_BASE_URL="https://v2.decipherinc.com"', 'dim');
      log('  export DECIPHER_SURVEY_PATH="selfserve/1234/mysurvey"', 'dim');
      log('  npx tsx scripts/test-decipher-api.ts', 'dim');
      process.exit(1);
    }

    if (!config.surveyPath) {
      log('\nError: DECIPHER_SURVEY_PATH environment variable required', 'red');
      process.exit(1);
    }
  }

  log(`\nConfiguration:`, 'bright');
  log(`  Base URL: ${config.baseUrl}`, 'dim');
  log(`  Survey Path: ${config.surveyPath}`, 'dim');
  log(`  API Key: ${config.apiKey.substring(0, 8)}...${config.apiKey.substring(config.apiKey.length - 4)}`, 'dim');

  // Run tests
  const datamap = await testDatamap(config);
  await testDataExport(config);
  await testSurveyMetadata(config);

  // Save sample output if datamap succeeded
  if (datamap) {
    const outputDir = path.join(process.cwd(), 'temp-outputs', 'decipher-api-test');
    await saveDatamapSample(datamap, outputDir);
  }

  log('\n' + '='.repeat(60), 'cyan');
  log('  TEST COMPLETE', 'bright');
  log('='.repeat(60), 'cyan');

  if (datamap) {
    log('\nKey findings:', 'bright');
    const hasSkipLogic = (datamap.questions?.filter(q => q.cond).length ?? 0) > 0;
    log(`  - Skip logic available: ${hasSkipLogic ? 'YES' : 'NO'}`, hasSkipLogic ? 'green' : 'yellow');
    log(`  - Questions with structure: ${datamap.questions?.length ?? 0}`, 'dim');
    log(`  - Variables available: ${datamap.variables?.length ?? 0}`, 'dim');

    log('\nNext steps:', 'bright');
    log('  1. Review saved JSON files in temp-outputs/decipher-api-test/', 'dim');
    log('  2. Compare datamap structure to current CSV parsing', 'dim');
    log('  3. Identify which cond expressions are most useful', 'dim');
  }
}

main().catch(console.error);
