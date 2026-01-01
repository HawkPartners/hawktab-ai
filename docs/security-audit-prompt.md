# HawkTab AI Security Audit Prompt

You are conducting a comprehensive security audit of the HawkTab AI codebase. HawkTab AI is an enterprise market research platform that handles sensitive survey data, integrates with survey platforms (Decipher/Forsta), processes files (SPSS, PDF, CSV), and uses AI/LLM for data processing.

---

## Audit Scope

- **Next.js 15** web application (App Router)
- **Convex** backend (TypeScript functions, real-time database)
- **WorkOS AuthKit** authentication (SSO, SCIM, user management)
- **Third-party integrations**: OpenAI/Anthropic (AI), Sentry (errors), PostHog (analytics), Cloudflare R2 (storage)
- **Data processing**: SPSS files, survey data, banner plans, R script execution

---

## Security Priorities (in order)

1. **Data Protection**: Survey response data, organization data, API keys, file uploads
2. **Authentication/Authorization**: WorkOS integration, Convex policies, multi-tenant isolation
3. **AI/LLM Security**: Prompt injection, model output validation, API key exposure
4. **Input Validation**: File uploads, user inputs, API parameters
5. **API Security**: Rate limiting, CORS, error handling
6. **Server-Side Security**: R script execution, file processing, shell commands

---

## Audit Instructions

### Phase 1: Automated Checks

Run these checks and document findings:

```bash
# TypeScript type safety
npx tsc --noEmit

# ESLint security rules
npm run lint

# Check for secrets in codebase
grep -r "sk-" --include="*.ts" --include="*.tsx" src/
grep -r "OPENAI_API_KEY" --include="*.ts" --include="*.tsx" src/
grep -r "password" --include="*.ts" --include="*.tsx" src/

# Check for console.log with sensitive data
grep -r "console.log" --include="*.ts" --include="*.tsx" src/

# Check dependencies for known vulnerabilities
npm audit
```

### Phase 2: Code Review

Review the following areas for vulnerabilities:

#### 1. API Routes (`src/app/api/`)

For each API route, verify:
- [ ] Authentication check at route entry (WorkOS identity verification)
- [ ] Input validation with Zod schemas
- [ ] Error responses don't leak internal details
- [ ] No sensitive data in response bodies
- [ ] Rate limiting for expensive operations
- [ ] Proper HTTP methods (no GET for mutations)

**Common issues to look for**:
```typescript
// BAD: No auth check
export async function POST(req: Request) {
  const data = await req.json();
  // ... processing without verifying user
}

// GOOD: Auth check first
export async function POST(req: Request) {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) {
    return new Response('Unauthorized', { status: 401 });
  }
  // ... processing with verified user
}
```

#### 2. Convex Functions (`convex/`)

For each Convex function, verify:
- [ ] Queries/mutations check authentication where needed
- [ ] Organization-scoped data access (multi-tenant isolation)
- [ ] No overly permissive policies
- [ ] Sensitive fields excluded from query results
- [ ] Input validation on all arguments

**Multi-tenant isolation check**:
```typescript
// BAD: Returns all projects
export const getProjects = query({
  handler: async (ctx) => {
    return ctx.db.query("projects").collect();
  },
});

// GOOD: Scoped to user's organization
export const getProjects = query({
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Unauthenticated");

    return ctx.db.query("projects")
      .withIndex("by_org", q => q.eq("orgId", identity.orgId))
      .collect();
  },
});
```

#### 3. AI/LLM Security (`src/agents/`, `src/prompts/`)

For AI integrations, verify:
- [ ] User input is not directly concatenated into prompts
- [ ] System prompts are protected from extraction
- [ ] Model outputs are validated before use
- [ ] API keys not exposed to client
- [ ] Token/usage limits enforced
- [ ] Structured outputs validated with Zod

**Prompt injection check**:
```typescript
// BAD: Direct user input in prompt
const prompt = `Analyze this data: ${userInput}`;

// GOOD: Structured input with clear boundaries
const prompt = `
You are analyzing survey data.
<user_data>
${JSON.stringify(sanitizedData)}
</user_data>
Only respond with the specified JSON schema.
`;
```

#### 4. File Processing (`src/lib/processors/`)

For file handling, verify:
- [ ] File type validation before processing
- [ ] File size limits enforced
- [ ] Uploaded files stored securely (not in public paths)
- [ ] Temp files cleaned up after processing
- [ ] No path traversal vulnerabilities
- [ ] SPSS/CSV parsing doesn't execute code

**File upload check**:
```typescript
// Verify file types server-side, not just by extension
const ALLOWED_TYPES = ['application/pdf', 'text/csv', 'application/x-spss-sav'];
if (!ALLOWED_TYPES.includes(file.type)) {
  throw new Error('Invalid file type');
}

// Check file size
const MAX_SIZE = 50 * 1024 * 1024; // 50MB
if (file.size > MAX_SIZE) {
  throw new Error('File too large');
}
```

#### 5. R Script Execution (`src/lib/r/`)

For R script execution, verify:
- [ ] Scripts are generated from validated templates, not user input
- [ ] No shell injection in R execution commands
- [ ] Execution timeout enforced
- [ ] Output file paths are controlled
- [ ] Error output doesn't leak sensitive paths

**Shell command check**:
```typescript
// BAD: User input in shell command
exec(`Rscript ${userProvidedPath}`);

// GOOD: Controlled paths only
const scriptPath = path.join(SAFE_SCRIPTS_DIR, `${sessionId}.R`);
exec(`Rscript ${scriptPath}`, { timeout: 60000 });
```

#### 6. Error Handling and Logging

For error handling, verify:
- [ ] Errors don't expose stack traces to clients
- [ ] Sensitive data not logged (API keys, PII, survey responses)
- [ ] Sentry configured to scrub PII
- [ ] Console.log statements reviewed for sensitive data

**Logging check**:
```typescript
// BAD: Logging sensitive data
console.log('User data:', userData);
Sentry.captureException(error, { extra: { apiKey, userData } });

// GOOD: Structured, sanitized logging
console.log('Processing started', { sessionId, fileCount: files.length });
Sentry.captureException(error, { extra: { sessionId } });
```

### Phase 3: Threat Modeling

Consider attack vectors specific to HawkTab AI:

#### Data Exposure
- Could an attacker access another organization's survey data?
- Could uploaded SPSS files be accessed by unauthorized users?
- Are crosstab results properly scoped to organizations?

#### AI/LLM Attacks
- Could prompt injection extract system prompts or API keys?
- Could malicious input cause the model to generate harmful output?
- Are AI-generated R scripts validated before execution?

#### Multi-Tenant Security
- Is organization isolation enforced at the database level?
- Could a user access projects from another organization?
- Are file storage paths scoped to prevent cross-tenant access?

#### Server-Side Execution
- Could R script generation be exploited for code injection?
- Are there SSRF risks in file processing or API calls?
- Is shell command execution properly sandboxed?

### Phase 4: Compliance & Best Practices

- [ ] OWASP Top 10 Web Application Security Risks addressed
- [ ] Sensitive data encrypted at rest and in transit
- [ ] API keys stored in environment variables, not code
- [ ] CORS configured appropriately
- [ ] Content Security Policy headers set
- [ ] Secure cookie attributes (HttpOnly, Secure, SameSite)

---

## Output Format

Provide findings in this structure:

### CRITICAL (Fix Immediately)
- Clear security risk that could lead to data breach
- Exploitable with moderate effort
- High impact if exploited

### HIGH PRIORITY (Fix Before Production)
- Security concern requiring specific conditions
- Moderate impact
- Should not ship without addressing

### MEDIUM PRIORITY (Address Soon)
- Defense-in-depth improvement
- Low probability of exploitation
- Performance or privacy enhancement

### LOW PRIORITY (Track for Later)
- Best practice improvement
- Minimal security impact
- Nice-to-have hardening

### STRENGTHS (Document Good Practices)
- Security measures working correctly
- Areas of low risk
- Patterns to replicate elsewhere

For each finding, include:
1. **Location**: File path and line numbers
2. **Risk Level**: Critical/High/Medium/Low
3. **Description**: What the issue is
4. **Impact**: What could happen if exploited
5. **Fix**: Specific code changes with examples
6. **Verification**: How to confirm the fix worked

---

## Special Considerations for HawkTab AI

1. **Pre-production MVP**: Currently in development with test data, but architecture decisions affect future security posture

2. **Enterprise B2B context**: Will serve market research firms who handle sensitive client data—security failures impact customer trust

3. **Multi-provider AI**: Uses OpenAI, potentially Anthropic/Azure—each provider has different security models

4. **R script execution**: Statistical computing requires shell access—carefully sandboxed

5. **Decipher API integration**: Third-party survey platform—verify we're not bypassing their security

6. **File processing pipeline**: Handles multiple file formats (SPSS, PDF, CSV)—each is an attack surface

---

## Audit Checklist Summary

```
[ ] API routes authenticated and authorized
[ ] Convex functions enforce multi-tenant isolation
[ ] AI prompts protected from injection
[ ] File uploads validated and sandboxed
[ ] R script execution sandboxed with timeouts
[ ] Errors don't leak sensitive information
[ ] Logging excludes PII and secrets
[ ] Environment variables used for secrets
[ ] Dependencies free of critical vulnerabilities
[ ] OWASP Top 10 addressed
```

---

## Previous Audit Notes

Document the date and findings of each audit:

| Date | Auditor | Critical | High | Medium | Low | Notes |
|------|---------|----------|------|--------|-----|-------|
| YYYY-MM-DD | Name | 0 | 0 | 0 | 0 | Initial audit |

---

Run this audit and provide actionable findings prioritized by risk and effort.
