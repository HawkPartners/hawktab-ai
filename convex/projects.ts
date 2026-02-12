import { v } from "convex/values";
import { query, internalMutation } from "./_generated/server";

// Typed config validator — mirrors schema.ts configValidator
const configArg = v.object({
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

// Typed intake validator — mirrors schema.ts intakeValidator
const intakeArg = v.object({
  dataMap: v.optional(v.union(v.string(), v.null())),
  dataFile: v.optional(v.union(v.string(), v.null())),
  bannerPlan: v.optional(v.union(v.string(), v.null())),
  survey: v.optional(v.union(v.string(), v.null())),
  messageList: v.optional(v.union(v.string(), v.null())),
  bannerMode: v.optional(v.union(v.literal("upload"), v.literal("auto_generate"))),
});

export const create = internalMutation({
  args: {
    orgId: v.id("organizations"),
    name: v.string(),
    projectType: v.union(v.literal("crosstab"), v.literal("other")),
    config: configArg,
    intake: intakeArg,
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
    const project = await ctx.db.get(args.projectId);
    if (project?.isDeleted) return null;
    return project;
  },
});

export const updateFileKeys = internalMutation({
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
    const projects = await ctx.db
      .query("projects")
      .withIndex("by_org", (q) => q.eq("orgId", args.orgId))
      .order("desc")
      .collect();
    return projects.filter((p) => !p.isDeleted);
  },
});

export const softDelete = internalMutation({
  args: {
    projectId: v.id("projects"),
    orgId: v.id("organizations"),
  },
  handler: async (ctx, args) => {
    const project = await ctx.db.get(args.projectId);
    if (!project || project.orgId !== args.orgId) {
      throw new Error("Project not found in organization");
    }
    if (project.isDeleted) {
      throw new Error("Project has already been deleted");
    }
    await ctx.db.patch(args.projectId, {
      isDeleted: true,
      deletedAt: Date.now(),
    });
  },
});
