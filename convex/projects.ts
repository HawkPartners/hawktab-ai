import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

export const create = mutation({
  args: {
    orgId: v.id("organizations"),
    name: v.string(),
    projectType: v.union(v.literal("crosstab"), v.literal("other")),
    config: v.any(),
    intake: v.any(),
    fileKeys: v.array(v.string()),
    createdBy: v.id("users"),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("projects", {
      orgId: args.orgId,
      name: args.name,
      projectType: args.projectType,
      config: args.config,
      intake: args.intake,
      fileKeys: args.fileKeys,
      createdBy: args.createdBy,
    });
  },
});

export const get = query({
  args: { projectId: v.id("projects") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.projectId);
  },
});

export const updateFileKeys = mutation({
  args: {
    projectId: v.id("projects"),
    fileKeys: v.array(v.string()),
  },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.projectId, { fileKeys: args.fileKeys });
  },
});

export const listByOrg = query({
  args: { orgId: v.id("organizations") },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("projects")
      .withIndex("by_org", (q) => q.eq("orgId", args.orgId))
      .order("desc")
      .collect();
  },
});
