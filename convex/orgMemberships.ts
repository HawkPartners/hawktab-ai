import { v } from "convex/values";
import { query, internalMutation } from "./_generated/server";

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

export const listByOrg = query({
  args: { orgId: v.id("organizations") },
  handler: async (ctx, args) => {
    const memberships = await ctx.db
      .query("orgMemberships")
      .withIndex("by_org", (q) => q.eq("orgId", args.orgId))
      .collect();

    // Join with users table to get name and email
    const results = await Promise.all(
      memberships.map(async (m) => {
        const user = await ctx.db.get(m.userId);
        return {
          _id: m._id,
          role: m.role,
          userId: m.userId,
          name: user?.name ?? "Unknown",
          email: user?.email ?? "",
        };
      })
    );

    return results;
  },
});

export const upsert = internalMutation({
  args: {
    userId: v.id("users"),
    orgId: v.id("organizations"),
    role: v.optional(
      v.union(
        v.literal("admin"),
        v.literal("member"),
        v.literal("external_partner")
      )
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
      // Don't overwrite role on subsequent logins — only update if explicitly provided
      if (args.role) {
        await ctx.db.patch(existing._id, { role: args.role });
      }
      return existing._id;
    }

    // New membership: use provided role or default to "member"
    return await ctx.db.insert("orgMemberships", {
      userId: args.userId,
      orgId: args.orgId,
      role: args.role ?? "member",
    });
  },
});
