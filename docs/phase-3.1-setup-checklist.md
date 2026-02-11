# Phase 3.1 — Manual Setup Checklist

Code is written. These are the manual steps to wire up the cloud services before moving to Phase 3.2.

---

## 1. Convex (Database)

1. Go to [dashboard.convex.dev](https://dashboard.convex.dev) and create an account
2. From project root, run: `npx convex dev`
   - This creates the project, deploys the schema, and generates `convex/_generated/`
   - It will prompt you to link to a project — create a new one called `hawktab-ai`
3. Copy the deployment URL from the dashboard
4. Add to `.env.local`:
   ```
   CONVEX_URL=https://<your-deployment>.convex.cloud
   NEXT_PUBLIC_CONVEX_URL=https://<your-deployment>.convex.cloud
   ```
5. Verify: Open Convex dashboard — you should see 5 tables (organizations, users, orgMemberships, projects, runs)
6. Seed dev data: `npm run seed:dev`

---

## 2. Cloudflare R2 (File Storage)

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com) > R2
2. Create a bucket called `hawktab-dev`
3. Go to R2 > Manage R2 API Tokens > Create API Token
   - Permission: Object Read & Write
   - Scope: Apply to specific bucket > `hawktab-dev`
4. Add to `.env.local`:
   ```
   R2_ACCOUNT_ID=<from Cloudflare dashboard URL or overview page>
   R2_ACCESS_KEY_ID=<from API token creation>
   R2_SECRET_ACCESS_KEY=<from API token creation>
   R2_BUCKET_NAME=hawktab-dev
   ```
5. Verify: `npx tsx scripts/test-r2.ts` — should upload, download, list, and delete a test file

---

## 3. WorkOS (Auth)

1. Go to [workos.com](https://workos.com) and create an account
2. In the WorkOS dashboard:
   - Add redirect URI: `http://localhost:3000/auth/callback`
   - Create a test organization "Hawk Partners Dev"
3. Add to `.env.local`:
   ```
   WORKOS_CLIENT_ID=client_...
   WORKOS_API_KEY=sk_test_...
   WORKOS_COOKIE_PASSWORD=<run: openssl rand -base64 32>
   NEXT_PUBLIC_WORKOS_REDIRECT_URI=http://localhost:3000/auth/callback
   AUTH_BYPASS=true
   ```
4. Leave `AUTH_BYPASS=true` for now — flip to `false` when you want to test real login

---

## 4. Verify Everything Works

```bash
# Start both Convex and Next.js
npm run dev:all

# In another terminal:
curl http://localhost:3000/api/health
# Should return: { "status": "ok", ... }

# Navigate to http://localhost:3000/dashboard
# Should load without login redirect (AUTH_BYPASS=true)
```

---

## 5. Optional: Docker

Only needed when you want to test the containerized build:

```bash
docker build -t hawktab-ai .
docker run -p 3000:3000 --env-file .env.local hawktab-ai
curl http://localhost:3000/api/health
```

---

## After All Setup

Once the above is done, Phase 3.1 is complete and you're ready for **Phase 3.2** — wiring the cloud services into the existing UI (replacing in-memory job store with Convex, replacing tmpdir storage with R2, etc.).
