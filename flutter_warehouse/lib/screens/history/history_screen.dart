import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../services/history_service.dart';
import '../../models/change_record.dart';
import '../../widgets/error_view.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _historyService = HistoryService();
  final _keywordCtrl = TextEditingController();
  List<ChangeRecord> _records = [];
  bool _loading = true;
  String? _error;
  String? _filterAction;
  String? _filterEntity;
  int _page = 1;
  int _total = 0;
  static const _limit = 50;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _historyService.getAll(
        action: _filterAction,
        entity: _filterEntity,
        keyword: _keywordCtrl.text.trim(),
        page: _page,
        limit: _limit,
      );
      _records = result['records'] as List<ChangeRecord>;
      _total = result['total'] as int;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'create': return Colors.green;
      case 'update': return Colors.blue;
      case 'delete': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'create': return '新增';
      case 'update': return '编辑';
      case 'delete': return '删除';
      default: return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('操作记录 ($_total)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                SearchBar(
                  controller: _keywordCtrl,
                  hintText: '搜索操作描述或用户名...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_keywordCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () { _keywordCtrl.clear(); _load(); },
                      ),
                  ],
                  onChanged: (_) => _load(),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('全部操作', null, _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      _chip('新增', 'create', _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      _chip('编辑', 'update', _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      _chip('删除', 'delete', _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      const SizedBox(width: 8),
                      _chip('全部对象', null, _filterEntity, (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      }),
                      _chip('SKU', 'SKU', _filterEntity, (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      }),
                      _chip('库位', '库位', _filterEntity, (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      }),
                      _chip('库存', '库存', _filterEntity, (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _records.isEmpty
                  ? const Center(child: Text('暂无操作记录'))
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _actionColor(r.action),
                            radius: 20,
                            child: Text(
                              _actionLabel(r.action),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                          title: Text(r.description),
                          subtitle: Text(
                            '${r.entity}  •  ${r.userName}  •  '
                            '${DateFormat('MM-dd HH:mm').format(r.createdAt.toLocal())}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: r.changes != null && r.changes!.isNotEmpty,
                          dense: true,
                          onTap: r.changes != null && r.changes!.isNotEmpty
                              ? () => _showChanges(context, r)
                              : null,
                        );
                      },
                    ),
    );
  }

  void _showChanges(BuildContext context, ChangeRecord r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('变更详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: r.changes!.entries.map((e) {
            final before = e.value['before']?.toString() ?? '无';
            final after = e.value['after']?.toString() ?? '无';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(e.key,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                  ),
                  Expanded(
                    child: Text('$before → $after',
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('关闭')),
        ],
      ),
    );
  }

  Widget _chip(
    String label,
    String? value,
    String? current,
    ValueChanged<String?> onTap,
  ) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: current == value,
          onSelected: (_) => onTap(current == value ? null : value),
        ),
      );
}
