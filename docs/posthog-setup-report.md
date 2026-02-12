# PostHog Post-Wizard Report

The wizard has completed a deep integration of PostHog analytics into Crosstab AI. The integration uses the Next.js 15.3+ recommended `instrumentation-client.ts` approach for client-side initialization, with server-side tracking via `posthog-node` for API routes. A reverse proxy through Next.js rewrites ensures reliable event delivery by routing analytics through your own domain.

## Integration Summary

### Files Created
- `instrumentation-client.ts` — Client-side PostHog initialization (Next.js 15.3+ approach)
- `src/lib/posthog-server.ts` — Server-side PostHog client for API routes
- `src/components/TrackedLink.tsx` — Reusable tracked link component for server components

### Files Modified
- `next.config.ts` — Added reverse proxy rewrites for `/ingest/*` routes
- `.env.local` — Added `NEXT_PUBLIC_POSTHOG_KEY` and `NEXT_PUBLIC_POSTHOG_HOST`
- `src/providers/auth-provider.tsx` — Added user identification on login
- `src/app/global-error.tsx` — Added PostHog exception capture
- `src/app/(product)/projects/new/page.tsx` — Wizard and project creation tracking
- `src/app/(product)/projects/[projectId]/page.tsx` — Downloads, feedback, cancellation tracking
- `src/app/(product)/projects/[projectId]/review/page.tsx` — HITL review tracking
- `src/app/(product)/dashboard/page.tsx` — Project selection tracking
- `src/app/(marketing)/page.tsx` — CTA click tracking
- `src/app/api/projects/launch/route.ts` — Server-side launch success/error tracking

### Packages Installed
- `posthog-js` — Client-side SDK
- `posthog-node` — Server-side SDK

## Events Implemented

| Event Name | Description | File(s) |
|------------|-------------|---------|
| `cta_clicked` | User clicks primary CTA on landing page | `src/app/(marketing)/page.tsx` |
| `wizard_step_completed` | User completes a step in project setup wizard | `src/app/(product)/projects/new/page.tsx` |
| `file_uploaded` | User uploads a file (data, survey, banner) | `src/app/(product)/projects/new/page.tsx` |
| `project_created` | User successfully creates a new project | `src/app/(product)/projects/new/page.tsx` |
| `project_launch_success` | Pipeline successfully launched (server-side) | `src/app/api/projects/launch/route.ts` |
| `project_launch_error` | Pipeline launch failed (server-side) | `src/app/api/projects/launch/route.ts` |
| `project_selected` | User selects a project from dashboard | `src/app/(product)/dashboard/page.tsx` |
| `review_decision_made` | User makes a HITL review decision | `src/app/(product)/projects/[projectId]/review/page.tsx` |
| `review_submitted` | User submits all review decisions | `src/app/(product)/projects/[projectId]/review/page.tsx` |
| `pipeline_cancelled` | User cancels a running pipeline | `src/app/(product)/projects/[projectId]/page.tsx` |
| `feedback_submitted` | User submits output quality feedback | `src/app/(product)/projects/[projectId]/page.tsx` |
| `file_downloaded` | User downloads an output file | `src/app/(product)/projects/[projectId]/page.tsx` |

## Next Steps

We've built some insights and a dashboard for you to keep an eye on user behavior, based on the events we just instrumented:

### Dashboard
- [Analytics Basics](https://us.posthog.com/project/312289/dashboard/1274200) — Core analytics dashboard with all insights

### Insights
- [Project Creation Funnel](https://us.posthog.com/project/312289/insights/rcMVnDCS) — Tracks conversion from CTA click to project creation
- [File Downloads by Type](https://us.posthog.com/project/312289/insights/0fTmRiVS) — Shows which output files users download most
- [Review Decisions Breakdown](https://us.posthog.com/project/312289/insights/OaZi1b41) — Distribution of HITL review decisions
- [User Feedback Ratings](https://us.posthog.com/project/312289/insights/HDrgEFbv) — Feedback rating distribution over time
- [Pipeline Success Rate](https://us.posthog.com/project/312289/insights/X603Qfgi) — Ratio of successful launches to errors

### Agent Skill

We've left an agent skill folder in your project at `.claude/skills/posthog-integration-nextjs-app-router/`. You can use this context for further agent development when using Claude Code. This will help ensure the model provides the most up-to-date approaches for integrating PostHog.

## Technical Notes

- **Reverse Proxy**: Events are routed through `/ingest/*` to bypass ad blockers
- **User Identification**: Users are automatically identified via `convexUserId` when authenticated
- **Exception Capture**: Enabled via `capture_exceptions: true` in the client config
- **Debug Mode**: Automatically enabled in development (`NODE_ENV === 'development'`)
