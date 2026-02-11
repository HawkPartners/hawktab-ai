import '../src/lib/loadEnv';
import { uploadFile, downloadFile, listFiles, deleteFile, buildKey } from '../src/lib/r2';

async function main() {
  console.log('=== R2 Smoke Test ===\n');

  const key = buildKey('test-org', 'test-project', 'smoke-test', 'test.json');
  const testData = JSON.stringify({ hello: 'world', timestamp: new Date().toISOString() });

  // Upload
  console.log(`1. Uploading to key: ${key}`);
  await uploadFile(key, testData, 'application/json');
  console.log('   ✓ Upload successful\n');

  // Download and verify
  console.log('2. Downloading and verifying...');
  const downloaded = await downloadFile(key);
  const parsed = JSON.parse(downloaded.toString('utf-8'));
  if (parsed.hello !== 'world') {
    throw new Error('Downloaded data does not match uploaded data');
  }
  console.log(`   ✓ Download successful — data matches: ${JSON.stringify(parsed)}\n`);

  // List
  console.log('3. Listing files under prefix: test-org/test-project/');
  const files = await listFiles('test-org/test-project/');
  console.log(`   ✓ Found ${files.length} file(s): ${files.join(', ')}\n`);

  // Delete
  console.log(`4. Deleting key: ${key}`);
  await deleteFile(key);
  console.log('   ✓ Delete successful\n');

  // Verify deletion
  console.log('5. Verifying deletion...');
  const afterDelete = await listFiles('test-org/test-project/smoke-test/');
  if (afterDelete.length === 0) {
    console.log('   ✓ File confirmed deleted\n');
  } else {
    console.log(`   ⚠ Files still present: ${afterDelete.join(', ')}\n`);
  }

  console.log('=== R2 Smoke Test Complete ===');
}

main().catch((err) => {
  console.error('R2 smoke test failed:', err);
  process.exit(1);
});
