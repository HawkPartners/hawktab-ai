# AGENTS.md

## Build/Lint/Test Commands
```bash
npm run dev          # Development with Turbopack hot reload
npm run build        # Production build
npm run start        # Start production server
npm run lint         # ESLint checks (run before commits)
npx tsc --noEmit     # TypeScript type checking (run before commits)
```

## Code Style Guidelines
- Use TypeScript with strict typing
- Follow Next.js 15 conventions
- Use Zod for schema validation (v3.25.67 exactly)
- Use '@/*' path aliases for imports
- Prefer named exports over default exports
- Use camelCase for variables/functions, PascalCase for components/classes
- Handle errors gracefully with try/catch and fallback responses
- Use async/await for asynchronous operations
- Log important operations with descriptive messages

## Architecture Patterns
- Agent-first implementation with context injection
- Group-by-group processing strategy
- Dual output strategy (verbose + agent-optimized JSON)
- Schema-first development with Zod
- Environment-based model selection (reasoning in dev, base in prod)

## Critical Requirements
- Use `outputType` (not `outputSchema`) with OpenAI Agents SDK
- Inject full JSON context into agent instructions
- Use scratchpad tool for reasoning transparency
- Generate confidence scores (0.0-1.0) for all validations
- Handle failures gracefully with low-confidence fallbacks

## Cursor/Copilot Rules
- Prioritize correctness over speed
- Maintain existing code patterns and conventions
- Preserve detailed logging in development
- Ensure all agent interactions are traceable
- Keep Zod version locked at 3.25.67