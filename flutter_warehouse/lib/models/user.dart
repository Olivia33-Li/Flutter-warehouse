// ─── Permission constants (mirrors backend src/common/permissions.ts) ──────────

class Perm {
  static const userManage   = 'user:manage';

  static const skuView      = 'sku:view';
  static const skuWrite     = 'sku:write';
  static const skuArchive   = 'sku:archive';
  static const skuDelete    = 'sku:delete';

  static const locView      = 'loc:view';
  static const locWrite     = 'loc:write';
  static const locDelete    = 'loc:delete';

  static const invView      = 'inv:view';
  static const invWrite     = 'inv:write';
  static const invStockIn   = 'inv:stock_in';
  static const invStockOut  = 'inv:stock_out';
  static const invTransfer  = 'inv:transfer';
  static const invAdjust    = 'inv:adjust';
  static const invDelete    = 'inv:delete';

  static const historyViewAll = 'history:view_all';
  static const historyViewOwn = 'history:view_own';

  static const dataImport   = 'data:import';
  static const dataExport   = 'data:export';

  static const systemSettings = 'system:settings';
  static const highRisk       = 'system:high_risk';
}

// ─── Role → permissions mapping ───────────────────────────────────────────────

const _allPerms = [
  Perm.userManage,
  Perm.skuView, Perm.skuWrite, Perm.skuArchive, Perm.skuDelete,
  Perm.locView, Perm.locWrite, Perm.locDelete,
  Perm.invView, Perm.invWrite, Perm.invStockIn, Perm.invStockOut,
  Perm.invTransfer, Perm.invAdjust, Perm.invDelete,
  Perm.historyViewAll, Perm.historyViewOwn,
  Perm.dataImport, Perm.dataExport,
  Perm.systemSettings, Perm.highRisk,
];

const _supervisorPerms = [
  Perm.skuView, Perm.skuWrite,
  Perm.locView, Perm.locWrite,
  Perm.invView, Perm.invWrite, Perm.invStockIn, Perm.invStockOut,
  Perm.invTransfer, Perm.invAdjust,
  Perm.historyViewAll,
  Perm.dataExport,
];

const _staffPerms = [
  Perm.skuView,
  Perm.locView,
  Perm.invView, Perm.invStockIn, Perm.invStockOut, Perm.invTransfer,
  Perm.historyViewOwn,
];

const _rolePermissions = <String, List<String>>{
  'admin':      _allPerms,
  'supervisor': _supervisorPerms,
  'staff':      _staffPerms,
  // legacy names — normalise on read
  'editor':     _supervisorPerms,
  'viewer':     _staffPerms,
};

// ─── User model ───────────────────────────────────────────────────────────────

class User {
  final String id;
  final String username;
  final String name;
  final String role; // 'admin' | 'supervisor' | 'staff'
  final bool isActive;
  final DateTime? lastLoginAt;
  /// When true, user must change their password before using the app.
  final bool mustChangePassword;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.isActive = true,
    this.lastLoginAt,
    this.mustChangePassword = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['_id'] ?? json['id'] ?? '',
        username: json['username'] ?? '',
        name: json['name'] ?? '',
        role: _normalizeRole(json['role'] as String? ?? 'staff'),
        isActive: json['isActive'] != false,
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'].toString())
            : null,
        mustChangePassword: json['mustChangePassword'] == true,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'username': username,
        'name': name,
        'role': role,
        'isActive': isActive,
        if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.toIso8601String(),
        'mustChangePassword': mustChangePassword,
      };

  User copyWith({String? name, String? role, bool? isActive, bool? mustChangePassword}) => User(
        id: id,
        username: username,
        name: name ?? this.name,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        lastLoginAt: lastLoginAt,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );

  // ── Role helpers ────────────────────────────────────────────────────────────

  bool get isAdmin      => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
  bool get isStaff      => role == 'staff';

  /// Backwards-compat alias used throughout the app.
  bool get canEdit => isAdmin || isSupervisor;

  String get roleLabel => switch (role) {
        'admin'      => '管理员',
        'supervisor' => '仓库主管',
        'staff'      => '普通员工',
        _            => role,
      };

  String get displayName => name.isNotEmpty ? name : username;

  // ── Permission helpers ──────────────────────────────────────────────────────

  List<String> get permissions =>
      _rolePermissions[role] ?? _staffPerms;

  bool can(String permission) => permissions.contains(permission);

  bool get canManageUsers     => can(Perm.userManage);
  bool get canImport          => can(Perm.dataImport);
  bool get canExport          => can(Perm.dataExport);
  bool get canAdjustInventory => can(Perm.invAdjust);
  bool get canViewAllHistory  => can(Perm.historyViewAll);
  bool get canDeleteInventory => can(Perm.invDelete);
  bool get canWriteSku        => can(Perm.skuWrite);
  bool get canArchiveSku      => can(Perm.skuArchive);
  bool get canDeleteSku       => can(Perm.skuDelete);
  bool get canWriteLoc        => can(Perm.locWrite);
  bool get canDeleteLoc       => can(Perm.locDelete);
  bool get canHighRisk        => can(Perm.highRisk);
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _normalizeRole(String role) {
  if (role == 'editor') return 'supervisor';
  if (role == 'viewer') return 'staff';
  if (role == 'admin' || role == 'supervisor' || role == 'staff') return role;
  return 'staff';
}

// ─── Recent account (for login screen history) ────────────────────────────────

class RecentAccount {
  final String username;
  final String name;
  final String role;
  final DateTime lastLoginAt;

  RecentAccount({
    required this.username,
    required this.name,
    required this.role,
    required this.lastLoginAt,
  });

  factory RecentAccount.fromUser(User user) => RecentAccount(
        username: user.username,
        name: user.name,
        role: user.role,
        lastLoginAt: user.lastLoginAt ?? DateTime.now(),
      );

  factory RecentAccount.fromJson(Map<String, dynamic> json) => RecentAccount(
        username: json['username'] ?? '',
        name: json['name'] ?? '',
        role: _normalizeRole(json['role'] as String? ?? 'staff'),
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.tryParse(json['lastLoginAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'name': name,
        'role': role,
        'lastLoginAt': lastLoginAt.toIso8601String(),
      };

  String get roleLabel => switch (role) {
        'admin'      => '管理员',
        'supervisor' => '仓库主管',
        'staff'      => '普通员工',
        _            => role,
      };
}
