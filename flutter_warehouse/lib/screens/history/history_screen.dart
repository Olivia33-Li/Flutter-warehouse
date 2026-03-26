import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/history_service.dart';
import '../../models/change_record.dart';
import '../../widgets/error_view.dart';
import '../../widgets/audit_log_detail_sheet.dart';

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

  String? _filterBusinessAction;
  String? _filterEntity;
  String? _filterDateRange;
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

  (String?, String?) _dateRange() {
    if (_filterDateRange == null) return (null, null);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_filterDateRange) {
      case 'today':
        return (today.toIso8601String(), now.toIso8601String());
      case '7d':
        return (today
                .subtract(const Duration(days: 7))
                .toIso8601String(),
            now.toIso8601String());
      case '30d':
        return (today
                .subtract(const Duration(days: 30))
                .toIso8601String(),
            now.toIso8601String());
      default:
        return (null, null);
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (startDate, endDate) = _dateRange();
      final result = await _historyService.getAll(
        businessAction: _filterBusinessAction,
        entity: _filterEntity,
        keyword: _keywordCtrl.text.trim(),
        startDate: startDate,
        endDate: endDate,
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

  static String listSummary(ChangeRecord r) {
    final d = r.details;
    final ba = r.businessAction;
    if (d == null || ba == null) return r.description;
    switch (ba) {
      case '入库':
        return '${d['skuCode']} @ ${d['locationCode']} · +${d['addedQty'] ?? 0}件';
      case '出库':
        return '${d['skuCode']} @ ${d['locationCode']} · -${d['reducedQty'] ?? 0}件';
      case '调整':
        return '${d['skuCode']} @ ${d['locationCode']} · ${d['beforeQty'] ?? 0}→${d['afterQty'] ?? 0}件';
      case '录入':
        return '${d['skuCode']} @ ${d['locationCode']} · ${d['quantity'] ?? 0}件';
      case '删除库存':
      case '结构修改':
        return '${d['skuCode']} @ ${d['locationCode']}';
      case '批量转移':
      case '批量复制':
        return '${d['sourceCode']} → ${d['targetCode']} · ${d['total'] ?? 0}种SKU';
      case '标记已检查':
      case '取消已检查':
      case '新建库位':
      case '编辑库位':
      case '删除库位':
        return d['locationCode'] ?? '';
      default:
        return r.description;
    }
  }

  String _formatShort(DateTime dt) =>
      DateFormat('MM-dd HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('操作记录 ($_total)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                SearchBar(
                  controller: _keywordCtrl,
                  hintText: '搜索描述 / SKU / 库位 / 用户名...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_keywordCtrl.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _keywordCtrl.clear();
                          _load();
                        },
                      ),
                  ],
                  onChanged: (_) => _load(),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('全部', null, _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      }),
                      _chip('入库', '入库', _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      }),
                      _chip('出库', '出库', _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      }),
                      _chip('调整', '调整', _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      }),
                      _chip('录入', '录入', _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      }),
                      _chip('转移', '批量转移', _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      }),
                      _chip('复制', '批量复制', _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      }),
                      _chip('检查', '标记已检查', _filterBusinessAction, (v) {
                        setState(() => _filterBusinessAction = v);
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
                      const SizedBox(width: 8),
                      _chip('全部时间', null, _filterDateRange, (v) {
                        setState(() => _filterDateRange = v);
                        _load();
                      }),
                      _chip('今天', 'today', _filterDateRange, (v) {
                        setState(() => _filterDateRange = v);
                        _load();
                      }),
                      _chip('近7天', '7d', _filterDateRange, (v) {
                        setState(() => _filterDateRange = v);
                        _load();
                      }),
                      _chip('近30天', '30d', _filterDateRange, (v) {
                        setState(() => _filterDateRange = v);
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
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history,
                              size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('暂无操作记录',
                              style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _records.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, indent: 64, endIndent: 16),
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final style = AuditLogDetailSheet.badgeStyle(r);
                        return _RecordTile(
                          record: r,
                          style: style,
                          label: AuditLogDetailSheet.badgeLabel(r),
                          summaryText: listSummary(r),
                          timeLabel: _formatShort(r.createdAt),
                          onTap: () => AuditLogDetailSheet.show(context, r),
                        );
                      },
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
          visualDensity: VisualDensity.compact,
          onSelected: (_) => onTap(current == value ? null : value),
        ),
      );
}

// ── List tile ─────────────────────────────────────────────────────────────────
class _RecordTile extends StatelessWidget {
  final ChangeRecord record;
  final (Color, Color, IconData) style;
  final String label;
  final String summaryText;
  final String timeLabel;
  final VoidCallback onTap;

  const _RecordTile({
    required this.record,
    required this.style,
    required this.label,
    required this.summaryText,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = style;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: fg)),
                      ),
                      const SizedBox(width: 6),
                      Text(record.entity,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(summaryText,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${record.userName}  ·  $timeLabel',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
