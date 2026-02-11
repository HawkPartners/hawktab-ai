import { v } from "convex/values";
import { query, mutation } from "./_generated/server";

export const getByUserAndOrg = query({
  args: {
    userId: v.id("users"),
    orgId: v.id("organizations"),
  },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("orgMemberships")
      .withIndex("by_user_and_org", (q) =>
        q.eq("userId", args.userId).eq("orgId", args.orgId)
      )
      .unique();
  },
});

export const upsert = mutation({
  args: {
    userId: v.id("users"),
    orgId: v.id("organizations"),
    role: v.union(
      v.literal("admin"),
      v.literal("member"),
      v.literal("external_partner")
    ),
  },
  handler: async (ctx, args) => {
    const existing = await ctx.db
      .query("orgMemberships")
      .withIndex("by_user_and_org", (q) =>
        q.eq("userId", args.userId).eq("orgId", args.orgId)
      )
      .unique();

    if (existing) {
      await ctx.db.patch(existing._id, { role: args.role });
      return existing._id;
    }

    return await ctx.db.insert("orgMemberships", {
      userId: args.userId,
      orgId: args.orgId,
      role: args.role,
    });
  },
});
