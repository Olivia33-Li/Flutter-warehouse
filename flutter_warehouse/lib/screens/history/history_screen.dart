import 'package:flutter/material.dart';
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
      case 'add': return Colors.green;
      case 'edit': return Colors.blue;
      case 'delete': return Colors.red;
      case 'import': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'add': return '新增';
      case 'edit': return '编辑';
      case 'delete': return '删除';
      case 'import': return '导入';
      default: return action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('操作记录 (${_total})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                SearchBar(
                  controller: _keywordCtrl,
                  hintText: '搜索关键词...',
                  leading: const Icon(Icons.search),
                  onChanged: (_) => _load(),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('全部操作', null, _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      _filterChip('新增', 'add', _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      _filterChip('编辑', 'edit', _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      _filterChip('删除', 'delete', _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      _filterChip('导入', 'import', _filterAction, (v) {
                        setState(() => _filterAction = v);
                        _load();
                      }),
                      const SizedBox(width: 12),
                      _filterChip('全部对象', null, _filterEntity, (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      }),
                      _filterChip('SKU', 'sku', _filterEntity, (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      }),
                      _filterChip('位置', 'location', _filterEntity, (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      }),
                      _filterChip('库存', 'inventory', _filterEntity, (v) {
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
                  ? const Center(child: Text('暂无记录'))
                  : ListView.builder(
                      itemCount: _records.length,
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _actionColor(r.action),
                            child: Text(
                              _actionLabel(r.action),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                          title: Text(r.description),
                          subtitle: Text(
                            '${r.userName}  •  ${DateFormat('MM-dd HH:mm').format(r.createdAt.toLocal())}',
                          ),
                          dense: true,
                        );
                      },
                    ),
    );
  }

  Widget _filterChip(
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
