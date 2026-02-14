## 4. Developer Documentation

- Revisit `CLAUDE.md` to reinforce: "follow established codebase patterns before defaulting to training-data conventions" — cover not just security but Convex patterns, API layer usage, etc.
- https://github.com/anthropics/claude-code-action (can use this to execute security audits and pattern checks)
- Document the three `.env` files (`.env.local`, `.env.dev`, `.env.prod`) and their purposes in both `README.md` and `CLAUDE.md`
- Document the deployment flow: `dev` branch (feature work) → `staging` branch (Railway auto-deploys, cloud testing) → `production`

## Post-MVP: Message Testing & MaxDiff

**Goal**: Support message testing surveys (and MaxDiff studies with utility scores) by allowing users to upload message lists that get integrated into the datamap.

**What's needed**:
- Intake question: "Does this survey include messages?" → upload message list
- Message file parsing (Excel preferred, Word supported)
- Datamap enrichment: link message text to question variables
- Agent awareness: VerificationAgent uses actual message text in table labels

**Level of Effort**: Medium. Prioritize post-MVP based on Antares feedback.

- extensive testing & record demo / setup antares schedule email