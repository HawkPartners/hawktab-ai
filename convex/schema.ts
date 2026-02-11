import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

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
    config: v.any(),
    intake: v.any(),
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
    config: v.any(),
    result: v.optional(v.any()),
    error: v.optional(v.string()),
    cancelRequested: v.boolean(),
  })
    .index("by_project", ["projectId"])
    .index("by_org", ["orgId"]),
});
