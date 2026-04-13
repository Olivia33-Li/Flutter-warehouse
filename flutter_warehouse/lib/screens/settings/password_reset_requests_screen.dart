import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../services/password_reset_service.dart';

const _bg      = Color(0xFFF5F3F0);
const _primary = Color(0xFF1A1A2E);
const _muted   = Color(0xFFB5B5C0);
const _divider = Color(0xFFF0EFEC);

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
                _InfoRow('用户名', '@${req.username}'),
                _InfoRow('申请时间', DateFormat('yyyy-MM-dd HH:mm').format(req.createdAt)),
                if (req.userNote.isNotEmpty) _InfoRow('用户备注', req.userNote),
                const Divider(height: 20),

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
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(Icons.arrow_back_ios, size: 18, color: _primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '密码重置申请',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _load,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Icon(Icons.refresh, size: 20, color: _primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pill filter tabs
            Center(
              child: _PillFilterBar(
                selected: _filterStatus,
                onChanged: (v) {
                  setState(() => _filterStatus = v);
                  _load();
                },
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                      ? const Center(
                          child: Text('暂无申请记录',
                              style: TextStyle(color: _muted)))
                      : ListView.separated(
                          itemCount: _requests.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: _divider, indent: 20),
                          itemBuilder: (_, i) => _RequestItem(
                            req: _requests[i],
                            onResolve: () => _showResolveDialog(_requests[i]),
                            onDelete: () => _confirmDelete(_requests[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pill filter bar ──────────────────────────────────────────────────────────

class _PillFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _PillFilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (label: '全部', value: null as String?),
      (label: '待处理', value: 'pending' as String?),
      (label: '已完成', value: 'completed' as String?),
      (label: '已拒绝', value: 'rejected' as String?),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 1.2, 1.2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFEEEDEA), width: 1.2),
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.map((tab) {
          final isActive = selected == tab.value;
          return GestureDetector(
            onTap: () => onChanged(tab.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isActive ? _primary : Colors.transparent,
                borderRadius: BorderRadius.circular(40),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive) ...[
                    const Icon(Icons.check, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : _muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Request list item ────────────────────────────────────────────────────────

class _RequestItem extends StatelessWidget {
  final PasswordResetRequest req;
  final VoidCallback onResolve;
  final VoidCallback onDelete;

  const _RequestItem({
    required this.req,
    required this.onResolve,
    required this.onDelete,
  });

  Color get _statusColor => switch (req.status) {
        'pending'   => Colors.orange,
        'completed' => const Color(0xFF4EBB6A),
        'rejected'  => const Color(0xFFC07078),
        _           => Colors.grey,
      };

  IconData get _statusIcon => switch (req.status) {
        'pending'   => Icons.hourglass_empty,
        'completed' => Icons.check_circle_outline,
        'rejected'  => Icons.cancel_outlined,
        _           => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM-dd HH:mm');
    final isPending = req.status == 'pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_statusIcon, color: _statusColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      req.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '@${req.username}',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '申请时间：${fmt.format(req.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: _muted),
                ),
                if (req.resolvedBy.isNotEmpty)
                  Text(
                    '处理人：${req.resolvedBy}  ${req.resolvedAt != null ? fmt.format(req.resolvedAt!) : ''}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPending) ...[
            _StatusBadge(status: req.status),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: onResolve,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('处理'),
            ),
          ] else ...[
            _StatusBadge(status: req.status),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: const Color(0xFFD0D0D8),
              onPressed: onDelete,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, borderColor, textColor) = switch (status) {
      'completed' => (
          '已完成',
          const Color(0xFFC5E6D2),
          const Color(0xFF4EBB6A),
        ),
      'rejected' => (
          '已拒绝',
          const Color(0xFFF5C5C8),
          const Color(0xFFC07078),
        ),
      'pending' => (
          '待处理',
          const Color(0xFFFFDDA8),
          const Color(0xFFE09030),
        ),
      _ => (
          '未知',
          const Color(0xFFD0D0D8),
          const Color(0xFF9090A0),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }
}

// ─── Info row (used in resolve dialog) ───────────────────────────────────────

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
