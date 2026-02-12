'use client';

import { createContext, useContext, type ReactNode } from 'react';
import type { Role } from '@/lib/permissions';

interface AuthContextValue {
  convexOrgId: string | null;
  convexUserId: string | null;
  email: string | null;
  name: string | null;
  role: Role | null;
}

const AuthContext = createContext<AuthContextValue>({
  convexOrgId: null,
  convexUserId: null,
  email: null,
  name: null,
  role: null,
});

interface AuthProviderProps {
  children: ReactNode;
  convexOrgId?: string | null;
  convexUserId?: string | null;
  email?: string | null;
  name?: string | null;
  role?: Role | null;
}

export function AuthProvider({
  children,
  convexOrgId = null,
  convexUserId = null,
  email = null,
  name = null,
  role = null,
}: AuthProviderProps) {
  return (
    <AuthContext.Provider
      value={{
        convexOrgId: convexOrgId ?? null,
        convexUserId: convexUserId ?? null,
        email: email ?? null,
        name: name ?? null,
        role: role ?? null,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuthContext(): AuthContextValue {
  return useContext(AuthContext);
}
