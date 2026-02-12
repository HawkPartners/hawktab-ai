import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

// ---------------------------------------------------------------------------
// Typed sub-validators (replaces v.any() where shape is known)
// ---------------------------------------------------------------------------

/**
 * Project/Run config — mirrors ProjectConfigSchema from src/schemas/projectConfigSchema.ts.
 * All fields optional because the legacy /api/process-crosstab route writes a minimal config.
 */
const configValidator = v.object({
  projectSubType: v.optional(v.union(v.literal("standard"), v.literal("segmentation"), v.literal("maxdiff"))),
  bannerMode: v.optional(v.union(v.literal("upload"), v.literal("auto_generate"))),
  researchObjectives: v.optional(v.string()),
  bannerHints: v.optional(v.string()),
  format: v.optional(v.union(v.literal("joe"), v.literal("antares"))),
  displayMode: v.optional(v.union(v.literal("frequency"), v.literal("counts"), v.literal("both"))),
  separateWorkbooks: v.optional(v.boolean()),
  theme: v.optional(v.string()),
  statTesting: v.optional(v.object({
    thresholds: v.optional(v.array(v.number())),
    minBase: v.optional(v.number()),
  })),
  weightVariable: v.optional(v.string()),
  loopStatTestingMode: v.optional(v.union(v.literal("suppress"), v.literal("complement"))),
  stopAfterVerification: v.optional(v.boolean()),
});

/**
 * Project intake — the files provided at project creation.
 * Shape varies between wizard (Phase 3.3) and legacy flow.
 */
const intakeValidator = v.object({
  dataMap: v.optional(v.union(v.string(), v.null())),
  dataFile: v.optional(v.union(v.string(), v.null())),
  bannerPlan: v.optional(v.union(v.string(), v.null())),
  survey: v.optional(v.union(v.string(), v.null())),
  messageList: v.optional(v.union(v.string(), v.null())),
  bannerMode: v.optional(v.union(v.literal("upload"), v.literal("auto_generate"))),
});

// ---------------------------------------------------------------------------
// Schema
// ---------------------------------------------------------------------------

export default defineSchema({
  organizations: defineTable({
    workosOrgId: v.string(),
    name: v.string(),
    slug: v.string(),
  })
    .index("by_workos_org_id", ["workosOrgId"])
    .index("by_slug", ["slug"]),

  users: defineTable({
    workosUserId: v.string(),
    email: v.string(),
    name: v.string(),
  })
    .index("by_workos_user_id", ["workosUserId"])
    .index("by_email", ["email"]),

  orgMemberships: defineTable({
    userId: v.id("users"),
    orgId: v.id("organizations"),
    role: v.union(
      v.literal("admin"),
      v.literal("member"),
      v.literal("external_partner")
    ),
  })
    .index("by_user_and_org", ["userId", "orgId"])
    .index("by_org", ["orgId"]),

  projects: defineTable({
    orgId: v.id("organizations"),
    name: v.string(),
    projectType: v.union(v.literal("crosstab"), v.literal("other")),
    config: configValidator,
    intake: intakeValidator,
    fileKeys: v.array(v.string()),
    createdBy: v.id("users"),
  }).index("by_org", ["orgId"]),

  runs: defineTable({
    projectId: v.id("projects"),
    orgId: v.id("organizations"),
    status: v.union(
      v.literal("in_progress"),
      v.literal("pending_review"),
      v.literal("resuming"),
      v.literal("success"),
      v.literal("partial"),
      v.literal("error"),
      v.literal("cancelled")
    ),
    stage: v.optional(v.string()),
    progress: v.optional(v.number()),
    message: v.optional(v.string()),
    config: configValidator,
    // result is deeply polymorphic — accumulates pipelineId, outputDir, downloadUrl,
    // reviewState, feedback, r2Files, costSummary across pipeline stages.
    // Risk mitigated by internalMutation conversion (H7).
    result: v.optional(v.any()),
    error: v.optional(v.string()),
    cancelRequested: v.boolean(),
    lastHeartbeat: v.optional(v.number()),
  })
    .index("by_project", ["projectId"])
    .index("by_org", ["orgId"])
    .index("by_status", ["status"]),
});
