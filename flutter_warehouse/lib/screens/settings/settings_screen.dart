import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
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
  // 编辑 Profile
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
                  // 更新本地 provider
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

  // 修改密码
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

  // 导出 Excel
  Future<void> _exportExcel() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在生成 Excel，请稍候...')));

      final response = await ApiService.instance.dio.get(
        '/export/excel',
        options: Options(responseType: ResponseType.bytes),
      );

      final now = DateTime.now();
      final filename =
          'warehouse_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';

      final blob = html.Blob(
        [response.data as List<int>],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);

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

  // 用户管理（admin）
  Future<void> _showUsersDialog() async {
    try {
      final response = await ApiService.instance.dio.get('/users');
      final users = response.data as List;
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('用户管理'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (_, i) {
                final u = users[i];
                return ListTile(
                  title: Text(u['name']),
                  subtitle: Text('@${u['username']}'),
                  trailing: DropdownButton<String>(
                    value: u['role'],
                    items: ['admin', 'editor', 'viewer']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (role) async {
                      if (role == null) return;
                      try {
                        await ApiService.instance.dio
                            .patch('/users/${u['_id']}/role', data: {'role': role});
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _showUsersDialog();
                      } catch (_) {}
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('关闭')),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')));
    }
  }

  // 清空库存
  Future<void> _confirmClearInventory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('危险操作'),
        content: const Text('确定要清空所有库存记录吗？此操作不可恢复！'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => ctx.pop(true),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await InventoryService().clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('库存已清空')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')));
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
          // 用户信息
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(user?.name ?? ''),
            subtitle: Text('@${user?.username ?? ''}  •  ${user?.role ?? ''}'),
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

          // 用户管理（仅 admin）
          if (user?.isAdmin == true)
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('用户管理'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showUsersDialog,
            ),

          const Divider(),

          // 数据导入（仅 admin）
          if (user?.isAdmin == true)
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('数据导入'),
              subtitle: const Text('SKU 主档 / 库位主档 / 库存明细'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/import'),
            ),

          // 导出 Excel
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导出 Excel'),
            subtitle: const Text('导出全部 SKU、库位、库存及流水记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportExcel,
          ),

          const Divider(),

          // 危险区域（仅 admin）
          if (user?.isAdmin == true) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('危险区域',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('清空所有库存',
                  style: TextStyle(color: Colors.red)),
              subtitle: const Text('保留用户和操作记录'),
              onTap: _confirmClearInventory,
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
}
