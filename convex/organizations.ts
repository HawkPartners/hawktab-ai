import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

export const getByWorkosId = query({
  args: { workosOrgId: v.string() },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("organizations")
      .withIndex("by_workos_org_id", (q) => q.eq("workosOrgId", args.workosOrgId))
      .unique();
  },
});

export const get = query({
  args: { orgId: v.id("organizations") },
  handler: async (ctx, args) => {
    return await ctx.db.get(args.orgId);
  },
});

export const upsert = mutation({
  args: {
    workosOrgId: v.string(),
    name: v.string(),
    slug: v.string(),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("organizations")
      .withIndex("by_workos_org_id", (q) => q.eq("workosOrgId", args.workosOrgId))
      .unique();

    if (existing) {
      await ctx.db.patch(existing._id, { name: args.name, slug: args.slug });
      return existing._id;
    }

    return await ctx.db.insert("organizations", {
      workosOrgId: args.workosOrgId,
      name: args.name,
      slug: args.slug,
    });
  },
});
