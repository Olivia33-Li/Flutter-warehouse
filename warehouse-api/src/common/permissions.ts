// ─── Permission constants ─────────────────────────────────────────────────────

export const PERM = {
  // User management — admin only
  USER_MANAGE: 'user:manage',

  // SKU
  SKU_VIEW:    'sku:view',
  SKU_WRITE:   'sku:write',    // create + edit (supervisor+)
  SKU_ARCHIVE: 'sku:archive',  // admin only
  SKU_DELETE:  'sku:delete',   // admin only

  // Location
  LOC_VIEW:   'loc:view',
  LOC_WRITE:  'loc:write',   // create + edit + check (supervisor+)
  LOC_DELETE: 'loc:delete',  // admin only

  // Inventory records
  INV_VIEW:      'inv:view',
  INV_WRITE:     'inv:write',      // create / delete record (supervisor+)
  INV_STOCK_IN:  'inv:stock_in',   // staff+
  INV_STOCK_OUT: 'inv:stock_out',  // staff+
  INV_TRANSFER:  'inv:transfer',   // staff+
  INV_ADJUST:    'inv:adjust',     // supervisor+ (requires note)
  INV_DELETE:    'inv:delete',     // admin only

  // History / audit logs
  HISTORY_VIEW_ALL: 'history:view_all',  // supervisor+
  HISTORY_VIEW_OWN: 'history:view_own',  // staff (own records only)

  // Data operations
  DATA_IMPORT: 'data:import',  // admin only
  DATA_EXPORT: 'data:export',  // supervisor+

  // System
  SYSTEM_SETTINGS: 'system:settings',  // admin only
  HIGH_RISK:       'system:high_risk', // admin only (clear all data, etc.)
} as const;

export type Permission = typeof PERM[keyof typeof PERM];
export type UserRole = 'admin' | 'supervisor' | 'staff';

// ─── Role → Permission mapping ────────────────────────────────────────────────

const SUPERVISOR_PERMS: Permission[] = [
  PERM.SKU_VIEW,   PERM.SKU_WRITE,
  PERM.LOC_VIEW,   PERM.LOC_WRITE,
  PERM.INV_VIEW,   PERM.INV_WRITE,
  PERM.INV_STOCK_IN, PERM.INV_STOCK_OUT, PERM.INV_TRANSFER, PERM.INV_ADJUST,
  PERM.HISTORY_VIEW_ALL,
  PERM.DATA_EXPORT,
];

const STAFF_PERMS: Permission[] = [
  PERM.SKU_VIEW,
  PERM.LOC_VIEW,
  PERM.INV_VIEW, PERM.INV_STOCK_IN, PERM.INV_STOCK_OUT, PERM.INV_TRANSFER,
  PERM.HISTORY_VIEW_OWN,
];

export const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
  admin:      Object.values(PERM) as Permission[],
  supervisor: SUPERVISOR_PERMS,
  staff:      STAFF_PERMS,
};

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Normalise legacy role names from the old schema (editor→supervisor, viewer→staff). */
export function normalizeRole(role: string): UserRole {
  if (role === 'editor')     return 'supervisor';
  if (role === 'viewer')     return 'staff';
  if (role === 'admin' || role === 'supervisor' || role === 'staff') return role as UserRole;
  return 'staff';
}

export function getRolePermissions(role: string): Permission[] {
  return ROLE_PERMISSIONS[normalizeRole(role)] ?? [];
}

export function hasPermission(role: string, permission: Permission): boolean {
  return getRolePermissions(role).includes(permission);
}

export const ROLE_LABEL: Record<UserRole, string> = {
  admin:      '管理员',
  supervisor: '仓库主管',
  staff:      '普通员工',
};
