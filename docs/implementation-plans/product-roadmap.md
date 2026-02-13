**UI Polish & Design System**
- Strip overuse of non-clean icons; follow the design system and think B2B
- Loop detection info is too verbose — just show that a loop was detected and data will be stacked (consider showing stacking details at end of pipeline or only if the user can act on it)

**Developer Experience**
- Make agent debugging easier — every agent's tool calls and scratchpad output should be captured in a single accessible location for post-run inspection (context graphs)

**Configuration & Project Settings**
- Confirm all configuration options Antares asked about are present and surfaced in the UI
- Hide configuration options that aren't actionable for users — reduce noise
- Allow Excel file regeneration without a full pipeline re-run (e.g., changing theme or toggling excluded tables)

**Transparency & Interpretability**
- Add a page or section explaining the assumptions the pipeline made — in plain, non-technical language
- Explain how banner cuts are constructed and how to interpret them (especially for clients like Tito's where cuts may be less intuitive)
- Show base sizes per cut and how they change — consider making this interactive
- Include a subtle disclaimer (e.g., "validate base sizes as you see fit") — not heavy-handed, just present
- General principle: always surface what happened and why, written for non-technical readers

**Automated Testing & CI/CD**
- Build a dev-mode batch testing feature in the UI: a button that loads test datasets from R2 (or a `dev-test` folder) and runs them through the pipeline in parallel, simulating real user uploads
- Should skip HITL review and test the system under realistic load (as if 15 different users uploaded at different times)
- Consider concurrency of 5 for batch testing to stress-test the system and speed up test cycles
- Cost awareness: batch runs cost ~$28–30 each — also explore cheaper test methods that achieve similar coverage without full AI calls
- Playwright for automated UI/E2E testing — more feasible for a Next.js app than mobile

**Security**
- Conduct another security audit after feature freeze — new API routes have been added since the last audit
- Research the risk profile specific to deployed web apps vs. mobile apps

**Developer Documentation**
- Revisit `CLAUDE.md` to reinforce: "follow established codebase patterns before defaulting to training-data conventions" — cover not just security but Convex patterns, API layer usage, etc.
- https://github.com/anthropics/claude-code-action (can use this to execute security audits and pattern checks)
- Document the three `.env` files (`.env.local`, `.env.dev`, `.env.prod`) and their purposes in both `README.md` and `CLAUDE.md`
- Document the deployment flow: `dev` branch (feature work) → `staging` branch (Railway auto-deploys, cloud testing) → `production`

**Future Features**
- Revisit `future-features.md` to identify items that could realistically be tackled before the Antares deadline
