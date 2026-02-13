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

  const deployKey = process.env.CONVEX_DEPLOY_KEY;
  if (!deployKey) {
    console.error('CONVEX_DEPLOY_KEY is not set. Required for calling internalMutation functions.');
    console.error('Add it to .env.local (find it in the Convex dashboard under Settings > Deploy Key).');
    process.exit(1);
  }

  const workosOrgId = process.env.WORKOS_ORG_ID;
  if (!workosOrgId) {
    console.error('WORKOS_ORG_ID is not set.');
    console.error('Find it in the WorkOS dashboard → Organizations → click your org → ID starts with org_');
    console.error('Add it to .env.local: WORKOS_ORG_ID=org_XXXXXXXXX');
    process.exit(1);
  }

  console.log('=== Seeding Domain → Org Mappings ===\n');
  console.log(`WorkOS Org ID: ${workosOrgId}\n`);
  const client = new ConvexHttpClient(url);
  (client as unknown as { setAdminAuth(token: string): void }).setAdminAuth(deployKey);

  // ---------------------------------------------------------------------------
  // 1. Hawk Partners — internal team
  // ---------------------------------------------------------------------------
  console.log('1. Upserting hawkpartners.com mapping...');
  const hawkId = await client.mutation(api.domainOrgMappings.upsert, {
    domain: 'hawkpartners.com',
    workosOrgId,
    defaultRole: 'member',
    isActive: true,
  });
  console.log(`   ✓ hawkpartners.com → ${workosOrgId} (role: member) — ${hawkId}\n`);

  // ---------------------------------------------------------------------------
  // 2. Antares — external partner
  // ---------------------------------------------------------------------------
  // To enable: set ANTARES_DOMAIN in .env.local (e.g., ANTARES_DOMAIN=antares.com)
  const antaresDomain = process.env.ANTARES_DOMAIN;
  if (antaresDomain) {
    console.log(`2. Upserting ${antaresDomain} mapping...`);
    const antaresId = await client.mutation(api.domainOrgMappings.upsert, {
      domain: antaresDomain,
      workosOrgId, // Same org — Antares users join the Hawk org as external_partner
      defaultRole: 'external_partner',
      isActive: true,
    });
    console.log(`   ✓ ${antaresDomain} → ${workosOrgId} (role: external_partner) — ${antaresId}\n`);
  } else {
    console.log('2. Skipping Antares — ANTARES_DOMAIN not set in .env.local\n');
  }

  // ---------------------------------------------------------------------------
  // Verify
  // ---------------------------------------------------------------------------
  console.log('Verifying...');
  const hawkMapping = await client.query(api.domainOrgMappings.getByDomain, { domain: 'hawkpartners.com' });
  console.log(`   ✓ hawkpartners.com: ${hawkMapping ? `active, role=${hawkMapping.defaultRole}` : 'NOT FOUND'}`);

  if (antaresDomain) {
    const antaresMapping = await client.query(api.domainOrgMappings.getByDomain, { domain: antaresDomain });
    console.log(`   ✓ ${antaresDomain}: ${antaresMapping ? `active, role=${antaresMapping.defaultRole}` : 'NOT FOUND'}`);
  }

  console.log('\n=== Seed Complete ===');
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
