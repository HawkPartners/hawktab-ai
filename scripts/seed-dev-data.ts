import '../src/lib/loadEnv';
import { ConvexHttpClient } from 'convex/browser';
import { anyApi } from 'convex/server';

// Use anyApi for scripts — fully typed api requires generated types from `npx convex dev`
const api = anyApi;

async function main() {
  const url = process.env.CONVEX_URL || process.env.NEXT_PUBLIC_CONVEX_URL;
  if (!url) {
    console.error('CONVEX_URL or NEXT_PUBLIC_CONVEX_URL is not set. Run `npx convex dev` first.');
    process.exit(1);
  }

  console.log('=== Seeding Convex Dev Data ===\n');
  const client = new ConvexHttpClient(url);

  // 1. Upsert dev organization
  console.log('1. Upserting dev organization...');
  const orgId = await client.mutation(api.organizations.upsert, {
    workosOrgId: 'dev_org_001',
    name: 'Hawk Partners Dev',
    slug: 'hawk-partners-dev',
  });
  console.log(`   ✓ Organization: ${orgId}\n`);

  // 2. Upsert dev user
  console.log('2. Upserting dev user...');
  const userId = await client.mutation(api.users.upsert, {
    workosUserId: 'dev_user_001',
    email: 'jason@hawkpartners.com',
    name: 'Jason (Dev)',
  });
  console.log(`   ✓ User: ${userId}\n`);

  // 3. Upsert membership
  console.log('3. Upserting membership...');
  const membershipId = await client.mutation(api.orgMemberships.upsert, {
    userId,
    orgId,
    role: 'admin',
  });
  console.log(`   ✓ Membership: ${membershipId}\n`);

  // 4. Verify
  console.log('4. Verifying...');
  const org = await client.query(api.organizations.getByWorkosId, { workosOrgId: 'dev_org_001' });
  const user = await client.query(api.users.getByWorkosId, { workosUserId: 'dev_user_001' });
  console.log(`   ✓ Org: ${org?.name} (${org?.slug})`);
  console.log(`   ✓ User: ${user?.name} (${user?.email})\n`);

  console.log('=== Seed Complete ===');
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
