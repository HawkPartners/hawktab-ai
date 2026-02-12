'use client';

import { useState } from 'react';
import { useQuery } from 'convex/react';
import posthog from 'posthog-js';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Loader2, Building2, User, Users, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { AppBreadcrumbs } from '@/components/app-breadcrumbs';
import { ConfirmDestructiveDialog } from '@/components/confirm-destructive-dialog';
import { useAuthContext } from '@/providers/auth-provider';
import { canPerform } from '@/lib/permissions';
import { api } from '../../../../convex/_generated/api';
import type { Id } from '../../../../convex/_generated/dataModel';

function roleBadgeVariant(role: string) {
  switch (role) {
    case 'admin':
      return 'default' as const;
    case 'external_partner':
      return 'outline' as const;
    default:
      return 'secondary' as const;
  }
}

function roleLabel(role: string) {
  switch (role) {
    case 'admin':
      return 'Admin';
    case 'external_partner':
      return 'Partner';
    default:
      return 'Member';
  }
}

export default function SettingsPage() {
  const { convexOrgId, convexUserId, name, email, role } = useAuthContext();
  const canViewSettings = canPerform(role, 'view_settings');
  const canRemoveMember = canPerform(role, 'remove_member');
  const [removingMember, setRemovingMember] = useState<{
    id: string;
    email: string;
    name: string;
  } | null>(null);

  const org = useQuery(
    api.organizations.get,
    convexOrgId ? { orgId: convexOrgId as Id<"organizations"> } : 'skip',
  );

  const members = useQuery(
    api.orgMemberships.listByOrg,
    convexOrgId ? { orgId: convexOrgId as Id<"organizations"> } : 'skip',
  );

  const isLoading = org === undefined;

  const handleRemoveMember = async () => {
    if (!removingMember) return;
    const res = await fetch(`/api/members/${encodeURIComponent(removingMember.id)}`, {
      method: 'DELETE',
    });
    if (!res.ok) {
      const data = await res.json();
      toast.error('Failed to remove member', {
        description: data?.error || 'Unknown error',
      });
      throw new Error(data?.error || 'Failed to remove member');
    }
    posthog.capture('member_removed', {
      removed_member_id: removingMember.id,
    });
    toast.success(`${removingMember.name} has been removed`);
    setRemovingMember(null);
  };

  return (
    <div>
      <AppBreadcrumbs segments={[{ label: 'Settings' }]} />

      <div className="mt-6 max-w-2xl">
        <h1 className="text-2xl font-bold tracking-tight mb-6">Settings</h1>

        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
          </div>
        ) : !canViewSettings ? (
          <Card>
            <CardContent className="p-6">
              <p className="text-sm text-muted-foreground">
                You don&apos;t have permission to view settings. Contact your organization admin for access.
              </p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-6">
            {/* Organization */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Building2 className="h-5 w-5 text-muted-foreground" />
                  Organization
                </CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="space-y-3 text-sm">
                  <div>
                    <dt className="text-muted-foreground">Name</dt>
                    <dd className="font-medium mt-0.5">{org?.name || 'Unknown'}</dd>
                  </div>
                </dl>
              </CardContent>
            </Card>

            {/* Your Profile */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <User className="h-5 w-5 text-muted-foreground" />
                  Your Profile
                </CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="space-y-3 text-sm">
                  <div>
                    <dt className="text-muted-foreground">Name</dt>
                    <dd className="font-medium mt-0.5">{name || 'Unknown'}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Email</dt>
                    <dd className="font-medium mt-0.5">{email || 'Unknown'}</dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">Role</dt>
                    <dd className="mt-0.5">
                      <Badge variant={roleBadgeVariant(role ?? 'member')}>
                        {roleLabel(role ?? 'member')}
                      </Badge>
                    </dd>
                  </div>
                </dl>
              </CardContent>
            </Card>

            {/* Members */}
            <Card>
              <CardHeader>
                <CardTitle className="text-lg flex items-center gap-2">
                  <Users className="h-5 w-5 text-muted-foreground" />
                  Members
                </CardTitle>
              </CardHeader>
              <CardContent>
                {members === undefined ? (
                  <div className="flex items-center justify-center py-6">
                    <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                  </div>
                ) : members.length === 0 ? (
                  <p className="text-sm text-muted-foreground">No members found.</p>
                ) : (
                  <div className="divide-y">
                    {members.map((member) => {
                      const isYou = String(member.userId) === convexUserId;
                      return (
                        <div
                          key={String(member._id)}
                          className="flex items-center justify-between py-3 first:pt-0 last:pb-0"
                        >
                          <div className="min-w-0">
                            <p className="text-sm font-medium truncate">
                              {member.name}
                              {isYou && (
                                <span className="text-muted-foreground font-normal ml-1">(you)</span>
                              )}
                            </p>
                            <p className="text-xs text-muted-foreground truncate">{member.email}</p>
                          </div>
                          <div className="flex items-center gap-2 ml-2 shrink-0">
                            <Badge variant={roleBadgeVariant(member.role)}>
                              {roleLabel(member.role)}
                            </Badge>
                            {canRemoveMember && !isYou && (
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-7 w-7 text-muted-foreground hover:text-red-500"
                                onClick={() =>
                                  setRemovingMember({
                                    id: String(member._id),
                                    email: member.email,
                                    name: member.name,
                                  })
                                }
                              >
                                <Trash2 className="h-4 w-4" />
                                <span className="sr-only">Remove {member.name}</span>
                              </Button>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        )}

        <ConfirmDestructiveDialog
          open={removingMember !== null}
          onOpenChange={(open) => {
            if (!open) setRemovingMember(null);
          }}
          title="Remove member"
          description={`This will remove ${removingMember?.name ?? 'this member'} from the organization. They will lose access immediately.`}
          confirmText={removingMember?.email ?? ''}
          confirmLabel="Type their email address to confirm"
          destructiveLabel="Remove Member"
          onConfirm={handleRemoveMember}
        />
      </div>
    </div>
  );
}
