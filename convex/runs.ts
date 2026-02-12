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

export const create = internalMutation({
  args: {
    projectId: v.id("projects"),
    orgId: v.id("organizations"),
    config: configArg,
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("runs", {
      projectId: args.projectId,
      orgId: args.orgId,
      status: "in_progress",
      stage: "uploading",
      progress: 0,
      message: "Starting pipeline...",
      config: args.config,
      cancelRequested: false,
    });
  },
});

export const get = query({
  args: { runId: v.id("runs") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.runId);
  },
});

export const requestCancel = internalMutation({
  args: { runId: v.id("runs") },
  handler: async (ctx, args) => {
    await ctx.db.patch(args.runId, {
      cancelRequested: true,
      status: "cancelled",
      message: "Pipeline cancelled by user",
    });
  },
});

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

export const updateStatus = internalMutation({
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
    // Runtime guard: if result is provided, it must be an object with a pipelineId string
    if (args.result !== undefined) {
      if (typeof args.result !== 'object' || args.result === null || Array.isArray(args.result)) {
        throw new Error("result must be a non-null, non-array object");
      }
      if (typeof (args.result as Record<string, unknown>).pipelineId !== 'string') {
        throw new Error("result.pipelineId must be a string");
      }
    }
    const { runId, ...fields } = args;
    await ctx.db.patch(runId, fields);
  },
});

/**
 * Store or update review state inside runs.result.reviewState.
 * Called by the orchestrator when HITL review is needed and when PathB completes.
 */
export const updateReviewState = internalMutation({
  args: {
    runId: v.id("runs"),
    reviewState: v.any(),
  },
  handler: async (ctx, args) => {
    if (typeof args.reviewState !== 'object' || args.reviewState === null || Array.isArray(args.reviewState)) {
      throw new Error("reviewState must be a non-null, non-array object");
    }

    const run = await ctx.db.get(args.runId);
    if (!run) throw new Error("Run not found");

    const existingResult = (run.result ?? {}) as Record<string, unknown>;
    await ctx.db.patch(args.runId, {
      result: { ...existingResult, reviewState: args.reviewState },
    });
  },
});

/**
 * Atomically merge a single key into runs.result.reviewR2Keys.
 * Eliminates race conditions when Path B and Path C complete concurrently.
 */
export const mergeReviewR2Key = internalMutation({
  args: {
    runId: v.id("runs"),
    key: v.string(),
    value: v.string(),
  },
  handler: async (ctx, args) => {
    const run = await ctx.db.get(args.runId);
    if (!run) throw new Error("Run not found");

    const existingResult = (run.result ?? {}) as Record<string, unknown>;
    const existingR2Keys = (existingResult.reviewR2Keys ?? {}) as Record<string, unknown>;

    await ctx.db.patch(args.runId, {
      result: {
        ...existingResult,
        reviewR2Keys: { ...existingR2Keys, [args.key]: args.value },
      },
    });
  },
});

/**
 * Append a feedback entry to runs.result.feedback array.
 * Creates the array if it doesn't exist.
 */
export const addFeedbackEntry = internalMutation({
  args: {
    runId: v.id("runs"),
    entry: v.any(),
  },
  handler: async (ctx, args) => {
    if (typeof args.entry !== 'object' || args.entry === null || Array.isArray(args.entry)) {
      throw new Error("entry must be a non-null, non-array object");
    }

    const run = await ctx.db.get(args.runId);
    if (!run) throw new Error("Run not found");

    const existingResult = (run.result ?? {}) as Record<string, unknown>;
    const existingFeedback = (existingResult.feedback ?? []) as unknown[];

    await ctx.db.patch(args.runId, {
      result: {
        ...existingResult,
        feedback: [...existingFeedback, args.entry],
      },
    });
  },
});
