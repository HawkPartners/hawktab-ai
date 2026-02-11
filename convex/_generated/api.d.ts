/**
 * AUTO-GENERATED STUB — Overwritten by `npx convex dev`.
 * Provides minimal types so the project compiles before Convex is configured.
 */
/* eslint-disable @typescript-eslint/no-explicit-any */
import type { FilterApi, FunctionReference } from "convex/server";

declare const fullApi: any;
export declare const api: FilterApi<typeof fullApi, FunctionReference<any, "public">>;
export declare const internal: FilterApi<typeof fullApi, FunctionReference<any, "internal">>;
