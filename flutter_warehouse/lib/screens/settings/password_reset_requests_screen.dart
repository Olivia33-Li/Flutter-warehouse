import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../services/password_reset_service.dart';

class PasswordResetRequestsScreen extends StatefulWidget {
  const PasswordResetRequestsScreen({super.key});

  @override
  State<PasswordResetRequestsScreen> createState() =>
      _PasswordResetRequestsScreenState();
}

class _PasswordResetRequestsScreenState
    extends State<PasswordResetRequestsScreen> {
  final _service = PasswordResetService();
  List<PasswordResetRequest> _requests = [];
  bool _loading = true;
  String? _filterStatus; // null = all

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getAll(status: _filterStatus);
      setState(() => _requests = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showResolveDialog(PasswordResetRequest req) async {
    final noteCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    String action = 'completed';
    String? err;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('处理申请 — ${req.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                _InfoRow('用户名', '@${req.username}'),
                _InfoRow('申请时间', DateFormat('yyyy-MM-dd HH:mm').format(req.createdAt)),
                if (req.userNote.isNotEmpty) _InfoRow('用户备注', req.userNote),
                const Divider(height: 20),

                // Action selector
                const Text('操作', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'completed', label: Text('重置密码')),
                    ButtonSegment(value: 'rejected', label: Text('拒绝申请')),
                  ],
                  selected: {action},
                  onSelectionChanged: (v) => setS(() => action = v.first),
                ),
                const SizedBox(height: 14),

                // New password field (only when completing)
                if (action == 'completed') ...[
                  TextField(
                    controller: pwdCtrl,
                    decoration: const InputDecoration(
                      labelText: '临时密码 *（至少 6 位）',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setS(() => err = null),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '用户下次登录时将被强制修改此密码。',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                ],

                // Admin note
                TextField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: action == 'rejected' ? '拒绝原因（可选）' : '备注（可选）',
                    hintText: action == 'completed' ? '例如：已通知用户' : '',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
            FilledButton(
              style: action == 'rejected'
                  ? FilledButton.styleFrom(backgroundColor: Colors.red)
                  : null,
              onPressed: () async {
                if (action == 'completed') {
                  if (pwdCtrl.text.length < 6) {
                    setS(() => err = '密码至少需要 6 位');
                    return;
                  }
                }
                try {
                  final msg = await _service.resolve(
                    id: req.id,
                    status: action,
                    adminNote: noteCtrl.text.trim(),
                    newPassword: action == 'completed' ? pwdCtrl.text : null,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)));
                    _load();
                  }
                } on DioException catch (e) {
                  final m = e.response?.data?['message'];
                  setS(() => err = m is List ? m.join(', ') : (m ?? '操作失败'));
                }
              },
              child: Text(action == 'completed' ? '确认重置' : '确认拒绝'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(PasswordResetRequest req) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确认删除 @${req.username} 的申请记录？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.remove(req.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _requests.where((r) => r.status == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('密码重置申请'),
            if (pending > 0)
              Text('$pending 条待处理',
                  style: const TextStyle(fontSize: 12, color: Colors.orange)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<String?>(
              segments: const [
                ButtonSegment(value: null, label: Text('全部')),
                ButtonSegment(value: 'pending', label: Text('待处理')),
                ButtonSegment(value: 'completed', label: Text('已完成')),
                ButtonSegment(value: 'rejected', label: Text('已拒绝')),
              ],
              selected: {_filterStatus},
              onSelectionChanged: (v) {
                setState(() => _filterStatus = v.first);
                _load();
              },
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? Center(
                        child: Text('暂无申请记录',
                            style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 16),
                        itemBuilder: (_, i) => _RequestTile(
                          req: _requests[i],
                          onResolve: () => _showResolveDialog(_requests[i]),
                          onDelete: () => _confirmDelete(_requests[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final PasswordResetRequest req;
  final VoidCallback onResolve;
  final VoidCallback onDelete;

  const _RequestTile({
    required this.req,
    required this.onResolve,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM-dd HH:mm');
    final isPending = req.status == 'pending';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _statusColor(req.status).withValues(alpha: 0.15),
        child: Icon(_statusIcon(req.status),
            color: _statusColor(req.status), size: 20),
      ),
      title: Row(
        children: [
          Text(req.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text('@${req.username}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor(req.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(req.statusLabel,
                style: TextStyle(
                    color: _statusColor(req.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text('申请时间：${fmt.format(req.createdAt)}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          if (req.userNote.isNotEmpty)
            Text('用户备注：${req.userNote}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          if (req.adminNote.isNotEmpty)
            Text('管理员备注：${req.adminNote}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          if (req.resolvedBy.isNotEmpty)
            Text(
                '处理人：${req.resolvedBy}  ${req.resolvedAt != null ? fmt.format(req.resolvedAt!) : ''}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
      isThreeLine: true,
      trailing: isPending
          ? FilledButton.tonal(
              onPressed: onResolve,
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12)),
              child: const Text('处理'),
            )
          : IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.grey.shade400,
              onPressed: onDelete,
            ),
    );
  }

  Color _statusColor(String s) => switch (s) {
        'pending' => Colors.orange,
        'completed' => Colors.green,
        'rejected' => Colors.red,
        _ => Colors.grey,
      };

  IconData _statusIcon(String s) => switch (s) {
        'pending' => Icons.hourglass_empty,
        'completed' => Icons.check_circle_outline,
        'rejected' => Icons.cancel_outlined,
        _ => Icons.help_outline,
      };
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text('$label：',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
