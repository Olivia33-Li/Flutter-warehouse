import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/inventory_service.dart';
import '../../services/import_service.dart';
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

  // CSV 格式说明
  void _showCsvFormatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV 文件格式说明'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('必填列（列名包含以下关键词即可）：',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _formatRow('SKU 编号', 'sku / item / code / product'),
              _formatRow('库位编号', 'location / loc / bin / warehouse'),
              _formatRow('数量（箱）', 'qty / quantity / carton / box'),
              const SizedBox(height: 12),
              const Text('可选列：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _formatRow('SKU 名称', 'name / description / desc'),
              _formatRow('条形码', 'barcode / upc / ean'),
              _formatRow('每箱件数', 'carton_qty / pcs / pieces / unit'),
              const SizedBox(height: 16),
              const Text('示例文件内容：',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'sku,name,location,qty\n'
                  'ABC001,苹果手机壳,A01-01,50\n'
                  'ABC002,充电线,A01-02,120\n'
                  'XYZ999,蓝牙耳机,B02-03,30',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              const Text('• 文件编码请使用 UTF-8\n• 相同 SKU+位置 的数量会累加',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('知道了')),
          FilledButton(
            onPressed: () { ctx.pop(); _importCsv(); },
            child: const Text('去选择文件'),
          ),
        ],
      ),
    );
  }

  Widget _formatRow(String label, String keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Text(keys,
                style: const TextStyle(fontSize: 13, color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  // CSV 导入
  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    try {
      final bytes = result.files.single.bytes!;
      final filename = result.files.single.name;
      final res = await ImportService().importCsvBytes(bytes, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '导入完成: 新增 ${res['created']}, 更新 ${res['updated']}, 跳过 ${res['skipped']}'),
        ));
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg ?? '导入失败'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red));
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

          // CSV 导入（editor+）
          if (user?.canEdit == true)
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('导入 CSV'),
              subtitle: const Text('点击查看格式说明并上传'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showCsvFormatDialog,
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
