export type Role = 'admin' | 'member' | 'external_partner';

export type Action =
  | 'create_project'
  | 'cancel_run'
  | 'view_settings'
  | 'manage_members';

const PERMISSION_MAP: Record<Action, Role[]> = {
  create_project: ['admin', 'member'],
  cancel_run: ['admin', 'member'],
  view_settings: ['admin', 'member'],
  manage_members: ['admin'],
};

export function canPerform(role: Role | null, action: Action): boolean {
  if (!role) return false;
  return PERMISSION_MAP[action].includes(role);
}
