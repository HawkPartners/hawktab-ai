'use client';

import { createContext, useContext, type ReactNode } from 'react';
import type { Id } from '../../convex/_generated/dataModel';

interface AuthContextValue {
  convexOrgId: string | null;
  convexUserId: string | null;
  email: string | null;
  name: string | null;
}

const AuthContext = createContext<AuthContextValue>({
  convexOrgId: null,
  convexUserId: null,
  email: null,
  name: null,
});

interface AuthProviderProps {
  children: ReactNode;
  convexOrgId?: Id<"organizations"> | null;
  convexUserId?: Id<"users"> | null;
  email?: string | null;
  name?: string | null;
}

export function AuthProvider({
  children,
  convexOrgId = null,
  convexUserId = null,
  email = null,
  name = null,
}: AuthProviderProps) {
  return (
    <AuthContext.Provider
      value={{
        convexOrgId: convexOrgId ?? null,
        convexUserId: convexUserId ?? null,
        email: email ?? null,
        name: name ?? null,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuthContext(): AuthContextValue {
  return useContext(AuthContext);
}
