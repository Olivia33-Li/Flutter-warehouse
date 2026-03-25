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

  String? _filterBusinessAction;
  String? _filterEntity;
  String? _filterDateRange; // 'today' | '7d' | '30d'
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
        return (today.subtract(const Duration(days: 7)).toIso8601String(),
            now.toIso8601String());
      case '30d':
        return (today.subtract(const Duration(days: 30)).toIso8601String(),
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

  // ── Badge styling ──────────────────────────────────────────────
  static (Color, Color, IconData) badgeStyle(ChangeRecord r) {
    final ba = r.businessAction ?? r.action;
    switch (ba) {
      case '入库':
        return (Colors.green.shade600, Colors.green.shade50, Icons.add_box_outlined);
      case '出库':
        return (Colors.orange.shade700, Colors.orange.shade50, Icons.outbox_outlined);
      case '调整':
        return (Colors.blue.shade600, Colors.blue.shade50, Icons.tune);
      case '录入':
        return (Colors.teal.shade600, Colors.teal.shade50, Icons.edit_note);
      case '删除库存':
        return (Colors.red.shade600, Colors.red.shade50, Icons.delete_outline);
      case '结构修改':
        return (Colors.purple.shade600, Colors.purple.shade50, Icons.construction_outlined);
      case '批量转移':
        return (Colors.indigo.shade600, Colors.indigo.shade50, Icons.swap_horiz);
      case '批量复制':
        return (Colors.amber.shade700, Colors.amber.shade50, Icons.copy_outlined);
      case '新建库位':
        return (Colors.teal.shade600, Colors.teal.shade50, Icons.add_location_alt_outlined);
      case '编辑库位':
        return (Colors.blueGrey.shade600, Colors.blueGrey.shade50, Icons.edit_location_alt_outlined);
      case '删除库位':
        return (Colors.red.shade600, Colors.red.shade50, Icons.wrong_location_outlined);
      case '标记已检查':
        return (Colors.green.shade600, Colors.green.shade50, Icons.check_circle_outline);
      case '取消已检查':
        return (Colors.grey.shade600, Colors.grey.shade50, Icons.cancel_outlined);
      case '新建SKU':
        return (Colors.teal.shade600, Colors.teal.shade50, Icons.add_circle_outline);
      case '编辑SKU':
        return (Colors.blueGrey.shade600, Colors.blueGrey.shade50, Icons.edit_outlined);
      case '删除SKU':
        return (Colors.red.shade600, Colors.red.shade50, Icons.remove_circle_outline);
      case 'create':
        return (Colors.green.shade600, Colors.green.shade50, Icons.add_circle_outline);
      case 'update':
        return (Colors.blue.shade600, Colors.blue.shade50, Icons.edit_outlined);
      case 'delete':
        return (Colors.red.shade600, Colors.red.shade50, Icons.delete_outline);
      default:
        return (Colors.grey.shade600, Colors.grey.shade50, Icons.history);
    }
  }

  static String badgeLabel(ChangeRecord r) {
    if (r.businessAction != null) return r.businessAction!;
    switch (r.action) {
      case 'create': return '新增';
      case 'update': return '编辑';
      case 'delete': return '删除';
      default: return r.action;
    }
  }

  static String summary(ChangeRecord r) {
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
                      _chip('全部操作', null, _filterBusinessAction, (v) {
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
                  ? const Center(child: Text('暂无操作记录'))
                  : ListView.separated(
                      itemCount: _records.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final style = badgeStyle(r);
                        return _RecordTile(
                          record: r,
                          style: style,
                          label: badgeLabel(r),
                          summaryText: summary(r),
                          timeLabel: _formatShort(r.createdAt),
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20)),
                            ),
                            builder: (_) => _DetailSheet(
                              record: r,
                              style: style,
                              label: badgeLabel(r),
                            ),
                          ),
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

// ── Detail bottom sheet ───────────────────────────────────────────────────────
class _DetailSheet extends StatelessWidget {
  final ChangeRecord record;
  final (Color, Color, IconData) style;
  final String label;

  const _DetailSheet({
    required this.record,
    required this.style,
    required this.label,
  });

  String _formatFull(DateTime dt) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = style;
    final d = record.details;
    final ba = record.businessAction;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 22, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: fg)),
                      Text(
                        '${record.entity}  ·  ${record.userName}  ·  ${_formatFull(record.createdAt)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.all(16),
              children: [
                if (d != null && ba != null)
                  ..._buildDetails(d, ba, fg, bg)
                else ...[
                  _sectionHead('操作说明', Icons.description_outlined),
                  const SizedBox(height: 8),
                  Text(record.description,
                      style: const TextStyle(fontSize: 13)),
                ],
                if (record.changes != null &&
                    record.changes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionHead('变更详情', Icons.compare_arrows),
                  const SizedBox(height: 8),
                  ...record.changes!.entries.map((e) {
                    final before =
                        e.value['before']?.toString() ?? '无';
                    final after =
                        e.value['after']?.toString() ?? '无';
                    return Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13)),
                          ),
                          Expanded(
                            child: Text('$before  →  $after',
                                style:
                                    const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetails(
      Map<String, dynamic> d, String ba, Color fg, Color bg) {
    switch (ba) {
      case '入库':
        return [
          _sectionHead('入库详情', Icons.add_box_outlined),
          const SizedBox(height: 8),
          _kv('SKU', d['skuCode']),
          _kv('库位', d['locationCode']),
          _kv('箱数', '${d['boxes']}箱'),
          _kv('每箱件数', '${d['unitsPerBox']}件/箱'),
          _qtyBanner('+${d['addedQty'] ?? 0}件', Colors.green.shade600),
        ];
      case '出库':
        return [
          _sectionHead('出库详情', Icons.outbox_outlined),
          const SizedBox(height: 8),
          _kv('SKU', d['skuCode']),
          _kv('库位', d['locationCode']),
          _qtyBanner('-${d['reducedQty'] ?? 0}件', Colors.orange.shade700),
          if (d['remainingQty'] != null)
            _kv('出库后剩余', '${d['remainingQty']}件'),
        ];
      case '调整':
        return [
          _sectionHead('库存调整', Icons.tune),
          const SizedBox(height: 8),
          _kv('SKU', d['skuCode']),
          _kv('库位', d['locationCode']),
          _kv('调整方式', d['mode'] == 'config' ? '按箱规调整' : '按总数量调整'),
          const SizedBox(height: 8),
          _beforeAfter('${d['beforeQty'] ?? 0}件', '${d['afterQty'] ?? 0}件'),
          if (d['note'] != null &&
              d['note'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            _kv('备注', d['note']),
          ],
        ];
      case '录入':
        return [
          _sectionHead('录入库存', Icons.edit_note),
          const SizedBox(height: 8),
          _kv('SKU', d['skuCode']),
          _kv('库位', d['locationCode']),
          _kv('箱数', '${d['boxes']}箱'),
          _kv('每箱件数', '${d['unitsPerBox']}件/箱'),
          _qtyBanner('共${d['quantity'] ?? 0}件', Colors.teal.shade600),
        ];
      case '删除库存':
        return [
          _sectionHead('删除库存记录', Icons.delete_outline),
          const SizedBox(height: 8),
          _kv('SKU', d['skuCode']),
          _kv('库位', d['locationCode']),
          _kv('删除时库存', '${d['quantity'] ?? 0}件'),
        ];
      case '结构修改':
        return [
          _sectionHead('库存结构修改', Icons.construction_outlined),
          const SizedBox(height: 8),
          _kv('SKU', d['skuCode']),
          _kv('库位', d['locationCode']),
          const SizedBox(height: 8),
          _beforeAfter('${d['beforeQty'] ?? 0}件', '${d['afterQty'] ?? 0}件'),
        ];
      case '批量转移':
        return _batchDetails(d, fg, bg, isTransfer: true);
      case '批量复制':
        return _batchDetails(d, fg, bg, isTransfer: false);
      case '标记已检查':
      case '取消已检查':
        return [
          _sectionHead(ba, Icons.check_circle_outline),
          const SizedBox(height: 8),
          _kv('库位', d['locationCode']),
          if (d['checkedBy'] != null) _kv('检查人', d['checkedBy']),
          if (d['checkedAt'] != null)
            _kv(
                '检查时间',
                DateFormat('yyyy-MM-dd HH:mm').format(
                    DateTime.parse(d['checkedAt']).toLocal())),
        ];
      case '新建库位':
        return [
          _sectionHead('新建库位', Icons.add_location_alt_outlined),
          const SizedBox(height: 8),
          _kv('库位编码', d['locationCode']),
          if (d['description'] != null &&
              d['description'].toString().isNotEmpty)
            _kv('描述', d['description']),
        ];
      case '编辑库位':
        return [
          _sectionHead('编辑库位', Icons.edit_location_alt_outlined),
          const SizedBox(height: 8),
          _kv('库位', d['locationCode']),
        ];
      case '删除库位':
        return [
          _sectionHead('删除库位', Icons.wrong_location_outlined),
          const SizedBox(height: 8),
          _kv('库位', d['locationCode']),
        ];
      default:
        return [
          _sectionHead('操作说明', Icons.description_outlined),
          const SizedBox(height: 8),
          Text(record.description, style: const TextStyle(fontSize: 13)),
        ];
    }
  }

  List<Widget> _batchDetails(
      Map<String, dynamic> d, Color fg, Color bg,
      {required bool isTransfer}) {
    final lbl = isTransfer ? '转移' : '复制';
    final direct = _toList(isTransfer ? d['moved'] : d['copied']);
    final mid = _toList(isTransfer ? d['merged'] : d['stacked']);
    final over = _toList(d['overwritten']);
    final midLabel = isTransfer ? '合并' : '叠加';
    final total = d['total'] ?? direct.length + mid.length + over.length;

    return [
      _sectionHead('批量$lbl', isTransfer ? Icons.swap_horiz : Icons.copy_outlined),
      const SizedBox(height: 8),
      // Route banner
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Text('${d['sourceCode'] ?? ''}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: fg)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                  isTransfer ? Icons.arrow_forward : Icons.copy_outlined,
                  color: fg,
                  size: 18),
            ),
            Text('${d['targetCode'] ?? ''}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: fg)),
            const Spacer(),
            Text('共$total种SKU',
                style: TextStyle(fontSize: 12, color: fg)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (direct.isNotEmpty) ...[
        _skuGroup('直接$lbl', direct, Colors.green.shade700),
        const SizedBox(height: 8),
      ],
      if (mid.isNotEmpty) ...[
        _skuGroup(midLabel, mid, Colors.blue.shade700),
        const SizedBox(height: 8),
      ],
      if (over.isNotEmpty) ...[
        _skuGroup('覆盖', over, Colors.red.shade700),
        const SizedBox(height: 8),
      ],
      if (isTransfer)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.amber),
              SizedBox(width: 6),
              Expanded(
                child: Text('转移完成后，原库位对应的 SKU 数据已删除。',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _skuGroup(String title, List<String> skus, Color color) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 6),
              Text('$title（${skus.length}种）',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: skus
                .map((s) => Chip(
                      label: Text(s,
                          style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      backgroundColor:
                          color.withValues(alpha: 0.1),
                    ))
                .toList(),
          ),
        ],
      );

  List<String> _toList(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);

  Widget _sectionHead(String t, IconData icon) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(t,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey.shade700)),
        ],
      );

  Widget _kv(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: Text(value?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _qtyBanner(String text, Color color) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 16, color: color),
            const SizedBox(width: 8),
            Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: color)),
          ],
        ),
      );

  Widget _beforeAfter(String before, String after) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                const Text('调整前',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(before,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.arrow_forward,
                  color: Colors.grey.shade400, size: 20),
            ),
            Column(
              children: [
                const Text('调整后',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(after,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700)),
              ],
            ),
          ],
        ),
      );
}
