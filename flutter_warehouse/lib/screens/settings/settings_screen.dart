import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/web_download_stub.dart'
    if (dart.library.js_interop) '../../utils/web_download_web.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/api_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _bg            = Color(0xFFF5F3F0);
const _primary       = Color(0xFF1A1A2E);
const _muted         = Color(0xFFB5B5C0);
const _divider       = Color(0xFFF2F1EF);
const _dangerText    = Color(0xFFC07078);
const _buttonPrimary = Color(0xFF2C3E6B);

const _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 1))],
);

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
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('编辑个人信息',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                const SizedBox(height: 20),
                // Floating label input
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 14, color: _primary),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFFD5D3CF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Color(0xFFD5D3CF)),
                        ),
                        errorText: err,
                      ),
                    ),
                    Positioned(
                      left: 12, top: -9,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Text('显示名称',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF8E8E9A))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => ctx.pop(),
                      child: const Text('取消', style: TextStyle(color: Color(0xFF6E6E80))),
                    ),
                    const SizedBox(width: 8),
                    _PrimaryButton(
                      label: '保存',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('修改密码',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                const SizedBox(height: 16),
                _RoundedInput(controller: oldCtrl, hint: '原密码', obscure: true),
                const SizedBox(height: 16),
                _RoundedInput(controller: newCtrl, hint: '新密码（至少6位）', obscure: true),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => ctx.pop(),
                      child: const Text('取消', style: TextStyle(color: Color(0xFF6E6E80))),
                    ),
                    const SizedBox(width: 8),
                    _PrimaryButton(
                      label: '确认',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      String token = AuthTokenCache.token ?? '';
      if (token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString(AppConstants.tokenKey) ?? '';
      }
      const url = '${AppConstants.baseUrl}/export/excel';
      final now = DateTime.now();
      final filename =
          'warehouse_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';

      if (kIsWeb) {
        // Web: 下载为字节流，通过浏览器触发另存为
        final response = await Dio().get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        downloadBytesOnWeb(response.data!, filename);
      } else {
        // 移动端：保存到临时目录后用系统分享
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$filename';
        await Dio().download(url, filePath,
            options: Options(headers: {'Authorization': 'Bearer $token'}));
        await Share.shareXFiles([XFile(filePath)]);
      }

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

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final avatarColor = _avatarColor(user?.role ?? 'staff');
    final initial = (user?.name.isNotEmpty == true ? user!.name[0] : '?').toUpperCase();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
          children: [
            // ── Title ──────────────────────────────────────────────────
            const Text('设置',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _primary)),
            const SizedBox(height: 22),

            // ── User card ───────────────────────────────────────────────
            Container(
              decoration: _cardDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: avatarColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(initial,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: avatarColor)),
                  ),
                  const SizedBox(width: 14),
                  // Name + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _primary)),
                        const SizedBox(height: 2),
                        Text('@${user?.username ?? ''}  ·  ${user?.roleLabel ?? ''}',
                            style: const TextStyle(fontSize: 12, color: _muted)),
                      ],
                    ),
                  ),
                  // Edit button
                  GestureDetector(
                    onTap: () => _showEditProfileDialog(user?.name ?? ''),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.edit_outlined, size: 16, color: _muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Account section ─────────────────────────────────────────
            Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  _CardItem(
                    icon: Icons.lock_outline,
                    label: '修改密码',
                    onTap: _showChangePasswordDialog,
                  ),
                  const Divider(height: 1, color: _divider),
                  _CardItemSub(
                    icon: Icons.swap_horiz_outlined,
                    label: '切换账号',
                    subtitle: '退出当前账号并返回登录页',
                    onTap: _switchAccount,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 管理 section ────────────────────────────────────────────
            const _SectionLabel('管理'),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  if (user?.canManageUsers == true)
                    _CardItemSub(
                      icon: Icons.people_outline,
                      label: '用户管理',
                      subtitle: '创建账号 / 分配角色 / 停用账号',
                      onTap: _showUsersDialog,
                    ),
                  if (user?.canManageUsers == true)
                    const Divider(height: 1, color: _divider),
                  _CardItemSub(
                    icon: Icons.vpn_key_outlined,
                    label: '密码重置申请',
                    subtitle: '处理用户的忘记密码申请',
                    onTap: () => context.push('/password-reset-requests'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 数据 section ────────────────────────────────────────────
            const _SectionLabel('数据'),
            const SizedBox(height: 12),
            Container(
              decoration: _cardDecoration,
              child: Column(
                children: [
                  if (user?.canImport == true)
                    _CardItemSub(
                      icon: Icons.upload_file_outlined,
                      label: '数据导入',
                      subtitle: 'SKU 主档 / 库位主档 / 库存明细',
                      onTap: () => context.push('/import'),
                    ),
                  if (user?.canImport == true)
                    const Divider(height: 1, color: _divider),
                  if (user?.canExport == true)
                    _CardItemSub(
                      icon: Icons.download_outlined,
                      label: '导出 Excel',
                      subtitle: '导出全部 SKU、库位、库存及流水记录',
                      onTap: _exportExcel,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 危险区域 section ────────────────────────────────────────
            if (user?.canHighRisk == true) ...[
              const _SectionLabel('危险区域', danger: true),
              const SizedBox(height: 12),
              Container(
                decoration: _cardDecoration,
                child: InkWell(
                  onTap: _confirmClearAllData,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 16, color: _dangerText),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('清空所有业务数据',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _dangerText)),
                              SizedBox(height: 2),
                              Text('清空库存、SKU、库位、流水、日志及导入记录，仅保留用户账号',
                                  style: TextStyle(fontSize: 11, color: _muted),
                                  maxLines: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Logout button ───────────────────────────────────────────
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(currentUserProvider.notifier).logout();
                  if (mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, size: 16, color: _dangerText),
                label: const Text('退出登录',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _dangerText)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _avatarColor(String role) {
    switch (role) {
      case 'admin':      return const Color(0xFFE87040);
      case 'supervisor': return const Color(0xFF4A6CF7);
      default:           return const Color(0xFF4EBB6A);
    }
  }
}

// ── Shared UI helpers ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool danger;
  const _SectionLabel(this.text, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 0.25,
        color: danger ? const Color(0xB3D4736C) : _muted,
      ),
    );
  }
}

class _CardItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _CardItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 53,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 17, color: _primary),
              const SizedBox(width: 14),
              Expanded(child: Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _primary))),
              const Icon(Icons.chevron_right, size: 14, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardItemSub extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  const _CardItemSub({required this.icon, required this.label, required this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 71,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 17, color: _primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _primary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 11, color: _muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 14, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  const _RoundedInput({required this.controller, required this.hint, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
      borderSide: BorderSide(color: Color(0xFFD5D3CF), width: 1.2),
    );
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 14, color: _primary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _muted, fontSize: 14),
        contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF8090A8), width: 1.2),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _buttonPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _buttonPrimary.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              child: Row(
                children: [
                  const Text('用户管理',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: _muted),
                    onPressed: _load,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 35,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add_outlined, size: 14),
                      label: const Text('创建账号', style: TextStyle(fontSize: 13)),
                      onPressed: _showCreateDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonPrimary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: _buttonPrimary.withValues(alpha: 0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: _muted),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
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
                  separatorBuilder: (_, __) => const Divider(height: 1, color: _divider),
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    final uid = u['_id'] as String? ?? '';
                    final role = u['role'] as String? ?? 'staff';
                    final isActive = u['isActive'] != false;
                    final isSelf = uid == (currentUser?.id ?? '');
                    final avatarColor = _avatarColor(role);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: isActive ? avatarColor : Colors.grey.shade400,
                        child: Text(
                          (u['name'] as String? ?? '?').isNotEmpty
                              ? (u['name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(u['name'] as String? ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? _primary : Colors.grey)),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF1FE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('我',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF4A6CF7))),
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
                            color: isActive ? _muted : Colors.grey.shade400),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: _muted),
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

  Color _avatarColor(String role) {
    switch (role) {
      case 'admin':      return const Color(0xFFE87040);
      case 'supervisor': return const Color(0xFF4A6CF7);
      default:           return const Color(0xFF4EBB6A);
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
