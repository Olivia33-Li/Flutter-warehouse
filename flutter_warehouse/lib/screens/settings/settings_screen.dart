import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/api_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ── Edit Profile ────────────────────────────────────────────────────────────

  Future<void> _showEditProfileDialog(String currentName) async {
    final nameCtrl = TextEditingController(text: currentName);
    String? err;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('编辑个人信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: '显示名称', border: OutlineInputBorder()),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) {
                  setS(() => err = '名称不能为空');
                  return;
                }
                try {
                  final response = await ApiService.instance.dio
                      .patch('/auth/profile', data: {'name': nameCtrl.text.trim()});
                  ref.read(currentUserProvider.notifier).updateName(response.data['name']);
                  if (ctx.mounted) ctx.pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('个人信息已更新')));
                  }
                } on DioException catch (e) {
                  final msg = e.response?.data?['message'];
                  setS(() => err = msg is List ? msg.join(', ') : (msg ?? '更新失败'));
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Change Password ─────────────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog() async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    String? err;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('修改密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: '原密码', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: '新密码（至少6位）', border: OutlineInputBorder()),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                try {
                  await AuthService().changePassword(
                    oldPassword: oldCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  if (ctx.mounted) ctx.pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('密码修改成功')));
                  }
                } on DioException catch (e) {
                  final msg = e.response?.data?['message'];
                  setS(() => err = msg is List ? msg.join(', ') : (msg ?? '修改失败'));
                }
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Export Excel ────────────────────────────────────────────────────────────

  Future<void> _exportExcel() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在生成 Excel，请稍候...')));
    try {
      // Use in-memory token first (covers non-remember-me sessions),
      // fall back to SharedPreferences for remember-me sessions after restart.
      String token = AuthTokenCache.token ?? '';
      if (token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(AppConstants.tokenKey) ?? '';
      }
      const url = '${AppConstants.baseUrl}/export/excel';

      final now = DateTime.now();
      final filename =
          'warehouse_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';

      final xhr = web.XMLHttpRequest();
      xhr.open('GET', url);
      xhr.responseType = 'blob';
      xhr.setRequestHeader('Authorization', 'Bearer $token');

      final completer = Completer<void>();
      xhr.onLoad.listen((_) {
        if (xhr.status == 200) {
          final blob = xhr.response as web.Blob;
          final blobUrl = web.URL.createObjectURL(blob);
          (web.document.createElement('a') as web.HTMLAnchorElement)
            ..href = blobUrl
            ..setAttribute('download', filename)
            ..click();
          web.URL.revokeObjectURL(blobUrl);
          completer.complete();
        } else {
          completer.completeError('HTTP ${xhr.status}');
        }
      });
      xhr.onError.listen((_) => completer.completeError('网络错误'));
      xhr.send();
      await completer.future;

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已下载: $filename')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ── User Management Dialog ──────────────────────────────────────────────────

  Future<void> _showUsersDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => _UserManagementDialog(),
    );
  }

  // ── Switch Account ──────────────────────────────────────────────────────────

  Future<void> _switchAccount() async {
    await ref.read(currentUserProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  // ── Clear All Data ──────────────────────────────────────────────────────────

  Future<void> _confirmClearAllData() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
          SizedBox(width: 8),
          Text('危险操作'),
        ]),
        content: const Text(
          '此操作将清空以下所有数据：\n\n'
          '• 全部库存记录\n'
          '• 全部 SKU 主档\n'
          '• 全部库位主档\n'
          '• 全部出入库流水\n'
          '• 全部操作日志\n'
          '• 全部导入记录\n\n'
          '仅保留用户账号。\n\n'
          '此操作不可恢复！',
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => ctx.pop(true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (confirm1 != true || !mounted) return;

    final confirmCtrl = TextEditingController();
    String? confirmErr;
    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('二次确认'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请输入"清空数据"以确认操作：'),
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: '清空数据',
                  errorText: confirmErr,
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                if (confirmCtrl.text.trim() != '清空数据') {
                  setS(() => confirmErr = '输入不正确');
                  return;
                }
                ctx.pop(true);
              },
              child: const Text('确认清空'),
            ),
          ],
        ),
      ),
    );
    if (confirm2 != true || !mounted) return;

    try {
      final result = await InventoryService().clearAllData();
      if (!mounted) return;
      final deleted = result['deleted'] as Map<String, dynamic>? ?? {};
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          '清空完成：库存 ${deleted['inventories']} 条，'
          'SKU ${deleted['skus']} 条，库位 ${deleted['locations']} 条，'
          '流水 ${deleted['transactions']} 条，日志 ${deleted['auditLogs']} 条，'
          '导入记录 ${deleted['importLogs']} 条',
        ),
        duration: const Duration(seconds: 6),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ── 用户信息 ─────────────────────────────────────────────────────
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _roleColor(user?.role ?? 'staff').withOpacity(0.15),
              child: Text(
                (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase(),
                style: TextStyle(color: _roleColor(user?.role ?? 'staff'),
                    fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user?.name ?? ''),
            subtitle: Text('@${user?.username ?? ''}  ·  ${user?.roleLabel ?? ''}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '编辑个人信息',
              onPressed: () => _showEditProfileDialog(user?.name ?? ''),
            ),
          ),
          const Divider(),

          // 修改密码
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('修改密码'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),

          // 切换账号
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text('切换账号'),
            subtitle: const Text('退出当前账号并返回登录页'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _switchAccount,
          ),

          const Divider(),

          // 用户管理（仅管理员）
          if (user?.canManageUsers == true)
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('用户管理'),
              subtitle: const Text('创建账号 / 分配角色 / 停用账号'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showUsersDialog,
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('密码重置申请'),
              subtitle: const Text('处理用户的忘记密码申请'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/password-reset-requests'),
            ),

          // 数据导入（仅管理员）
          if (user?.canImport == true)
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('数据导入'),
              subtitle: const Text('SKU 主档 / 库位主档 / 库存明细'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/import'),
            ),

          // 导出 Excel（管理员 + 仓库主管）
          if (user?.canExport == true)
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('导出 Excel'),
              subtitle: const Text('导出全部 SKU、库位、库存及流水记录'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _exportExcel,
            ),

          const Divider(),

          // 危险区域（仅管理员）
          if (user?.canHighRisk == true) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('危险区域',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('清空所有业务数据',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('清空库存、SKU、库位、流水、日志及导入记录，仅保留用户账号'),
              onTap: _confirmClearAllData,
            ),
          ],

          const Divider(),

          // 退出登录
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(currentUserProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return Colors.red.shade700;
      case 'supervisor': return Colors.blue.shade700;
      default:           return Colors.green.shade700;
    }
  }
}

// ─── User Management Dialog ───────────────────────────────────────────────────

class _UserManagementDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UserManagementDialog> createState() => _UserManagementDialogState();
}

class _UserManagementDialogState extends ConsumerState<_UserManagementDialog> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.instance.dio.get('/users');
      setState(() => _users = List<Map<String, dynamic>>.from(response.data as List));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'staff';
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('创建账号'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                      labelText: '用户名', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: '显示名称', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: '初始密码（至少6位）', border: OutlineInputBorder(), isDense: true),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(
                      labelText: '角色', border: OutlineInputBorder(), isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'admin',      child: Text('管理员')),
                    DropdownMenuItem(value: 'supervisor', child: Text('仓库主管')),
                    DropdownMenuItem(value: 'staff',      child: Text('普通员工')),
                  ],
                  onChanged: (v) => setS(() => role = v ?? 'staff'),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: saving ? null : () async {
                if (userCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty || passCtrl.text.length < 6) {
                  setS(() => err = '请填写完整信息，密码至少6位');
                  return;
                }
                setS(() { saving = true; err = null; });
                try {
                  await ApiService.instance.dio.post('/users', data: {
                    'username': userCtrl.text.trim().toLowerCase(),
                    'name': nameCtrl.text.trim(),
                    'password': passCtrl.text,
                    'role': role,
                  });
                  if (ctx.mounted) ctx.pop();
                  _load();
                } on DioException catch (e) {
                  final msg = e.response?.data?['message'];
                  setS(() { saving = false; err = msg is List ? msg.join(', ') : (msg ?? '创建失败'); });
                }
              },
              child: saving
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setRole(String userId, String currentRole) async {
    String newRole = currentRole;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('修改角色'),
          content: DropdownButtonFormField<String>(
            initialValue: newRole,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'admin',      child: Text('管理员')),
              DropdownMenuItem(value: 'supervisor', child: Text('仓库主管')),
              DropdownMenuItem(value: 'staff',      child: Text('普通员工')),
            ],
            onChanged: (v) => setS(() => newRole = v ?? currentRole),
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                try {
                  await ApiService.instance.dio.patch('/users/$userId/role', data: {'role': newRole});
                  if (ctx.mounted) ctx.pop();
                  _load();
                } catch (_) {}
              },
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(String userId, bool currentlyActive) async {
    final action = currentlyActive ? '停用' : '启用';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('确认$action'),
        content: Text('确定要$action该账号吗？${currentlyActive ? '停用后该用户将无法登录。' : ''}'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
          FilledButton(
            style: currentlyActive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            onPressed: () => ctx.pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final endpoint = currentlyActive ? '/users/$userId/disable' : '/users/$userId/enable';
      await ApiService.instance.dio.patch(endpoint);
      _load();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? '操作失败'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _resetPassword(String userId) async {
    final ctrl = TextEditingController();
    String? err;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('重置密码'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: '新密码（至少6位）', border: OutlineInputBorder()),
              ),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.length < 6) {
                  setS(() => err = '密码至少6位');
                  return;
                }
                try {
                  await ApiService.instance.dio
                      .patch('/users/$userId/reset-password', data: {'newPassword': ctrl.text});
                  if (ctx.mounted) ctx.pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('密码已重置')));
                  }
                } on DioException catch (e) {
                  final msg = e.response?.data?['message'];
                  setS(() => err = msg ?? '重置失败');
                }
              },
              child: const Text('重置'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Dialog(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Text('用户管理',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('创建账号'),
                    onPressed: _showCreateDialog,
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text('加载失败: $_error',
                    style: const TextStyle(color: Colors.red)),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final uid = u['_id'] as String? ?? '';
                    final role = u['role'] as String? ?? 'staff';
                    final isActive = u['isActive'] != false;
                    final isSelf = uid == (currentUser?.id ?? '');

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isActive
                            ? _roleColor(role).withOpacity(0.12)
                            : Colors.grey.shade200,
                        child: Text(
                          (u['name'] as String? ?? '?').isNotEmpty
                              ? (u['name'] as String)[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: isActive ? _roleColor(role) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(u['name'] as String? ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? null : Colors.grey)),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('我', style: TextStyle(
                                  fontSize: 10, color: Colors.blue.shade700)),
                            ),
                          ],
                          if (!isActive) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('已停用',
                                  style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '@${u['username'] ?? ''}  ·  ${_roleLabelOf(role)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.grey.shade600 : Colors.grey.shade400),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'role',
                              child: ListTile(dense: true, leading: Icon(Icons.badge),
                                  title: Text('修改角色'), contentPadding: EdgeInsets.zero)),
                          PopupMenuItem(value: 'toggle',
                              child: ListTile(dense: true,
                                  leading: Icon(isActive ? Icons.block : Icons.check_circle,
                                      color: isActive ? Colors.red : Colors.green),
                                  title: Text(isActive ? '停用账号' : '启用账号',
                                      style: TextStyle(
                                          color: isActive ? Colors.red : Colors.green)),
                                  contentPadding: EdgeInsets.zero)),
                          const PopupMenuItem(value: 'password',
                              child: ListTile(dense: true, leading: Icon(Icons.lock_reset),
                                  title: Text('重置密码'), contentPadding: EdgeInsets.zero)),
                        ],
                        onSelected: (action) async {
                          if (action == 'role')     await _setRole(uid, role);
                          if (action == 'toggle')   await _toggleActive(uid, isActive);
                          if (action == 'password') await _resetPassword(uid);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':      return Colors.red.shade700;
      case 'supervisor': return Colors.blue.shade700;
      default:           return Colors.green.shade700;
    }
  }

  String _roleLabelOf(String role) {
    switch (role) {
      case 'admin':      return '管理员';
      case 'supervisor': return '仓库主管';
      default:           return '普通员工';
    }
  }
}
