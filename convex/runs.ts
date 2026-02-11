import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

export const listByOrg = query({
  args: { orgId: v.id("organizations") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("runs")
      .withIndex("by_org", (q) => q.eq("orgId", args.orgId))
      .order("desc")
      .collect();
  },
});

export const getByProject = query({
  args: { projectId: v.id("projects") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("runs")
      .withIndex("by_project", (q) => q.eq("projectId", args.projectId))
      .order("desc")
      .collect();
  },
});

export const updateStatus = mutation({
  args: {
    runId: v.id("runs"),
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
    result: v.optional(v.any()),
    error: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const { runId, ...fields } = args;
    await ctx.db.patch(runId, fields);
  },
});
