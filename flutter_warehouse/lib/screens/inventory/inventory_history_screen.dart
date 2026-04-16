import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/history_service.dart';
import '../../models/change_record.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/audit_log_detail_sheet.dart';

class InventoryHistoryScreen extends StatefulWidget {
  final String skuCode;
  final String? skuId;
  final String locationId;
  final String locationCode;

  const InventoryHistoryScreen({
    super.key,
    required this.skuCode,
    this.skuId,
    required this.locationId,
    required this.locationCode,
  });

  @override
  State<InventoryHistoryScreen> createState() => _InventoryHistoryScreenState();
}

class _InventoryHistoryScreenState extends State<InventoryHistoryScreen> {
  final _service = HistoryService();
  final _scrollCtrl = ScrollController();

  List<ChangeRecord> _records = [];
  int _total = 0;
  int _page = 1;
  bool _loading = false;
  bool _loadingMore = false;
  String? _errorMsg; // user-friendly, never raw DioException
  String? _typeFilter; // null=全部 | IN | OUT | ADJUST | TRANSFER

  static const _limit = 30;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 150) {
      _loadMore();
    }
  }

  /// Convert raw exception to a user-readable string.
  String _friendlyError(Object e) {
    final l10n = AppLocalizations.of(context)!;
    final raw = e.toString();
    if (raw.contains('404')) return l10n.errApiNotFound;
    if (raw.contains('401') || raw.contains('403')) return l10n.errPermission;
    if (raw.contains('SocketException') || raw.contains('Connection refused')) {
      return l10n.errCannotConnectServer;
    }
    if (raw.contains('DioException') || raw.contains('DioError')) {
      return l10n.errNetworkFailed;
    }
    return l10n.errLoadRetry;
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
      if (reset) { _records = []; _page = 1; }
    });
    try {
      final data = await _service.getAll(
        entity: 'inventory',
        skuCode: widget.skuCode,
        locationCode: widget.locationCode,
        type: _typeFilter,
        page: 1,
        limit: _limit,
      );
      final list = data['records'] as List<ChangeRecord>;
      setState(() {
        _records = list;
        _total = (data['total'] as num?)?.toInt() ?? list.length;
        _page = 1;
      });
    } catch (e) {
      setState(() => _errorMsg = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _records.length >= _total) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final data = await _service.getAll(
        entity: 'inventory',
        skuCode: widget.skuCode,
        locationCode: widget.locationCode,
        type: _typeFilter,
        page: nextPage,
        limit: _limit,
      );
      final list = data['records'] as List<ChangeRecord>;
      setState(() {
        _records = [..._records, ...list];
        _total = (data['total'] as num?)?.toInt() ?? _total;
        _page = nextPage;
      });
    } catch (_) {
      // silently ignore — user still sees what was already loaded
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setFilter(String? type) {
    if (_typeFilter == type) return;
    setState(() => _typeFilter = type);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invHistoryTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SKU + location context row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Row(
                  children: [
                    Text(widget.skuCode,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    _LocationChip(widget.locationCode),
                    const Spacer(),
                    if (!_loading && _errorMsg == null && _total > 0)
                      Text(l10n.historyTotalRecords(_total),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              // Type filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    _TypeChip(label: l10n.historyFilterAll, selected: _typeFilter == null,
                        onTap: () => _setFilter(null)),
                    const SizedBox(width: 8),
                    _TypeChip(label: l10n.historyFilterIn, color: Colors.green,
                        selected: _typeFilter == 'IN',
                        onTap: () => _setFilter('IN')),
                    const SizedBox(width: 8),
                    _TypeChip(label: l10n.historyFilterOut, color: Colors.red,
                        selected: _typeFilter == 'OUT',
                        onTap: () => _setFilter('OUT')),
                    const SizedBox(width: 8),
                    _TypeChip(label: l10n.historyFilterAdjust, color: Colors.orange,
                        selected: _typeFilter == 'ADJUST',
                        onTap: () => _setFilter('ADJUST')),
                    const SizedBox(width: 8),
                    _TypeChip(label: l10n.historyFilterTransfer, color: Colors.blue,
                        selected: _typeFilter == 'TRANSFER',
                        onTap: () => _setFilter('TRANSFER')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(_errorMsg!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.retry),
                onPressed: _load,
              ),
            ],
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 56, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Text(
              _typeFilter == null
                  ? AppLocalizations.of(context)!.invHistoryEmpty
                  : AppLocalizations.of(context)!.invHistoryEmptyFiltered,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
            if (_typeFilter != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _setFilter(null),
                child: Text(AppLocalizations.of(context)!.invHistoryViewAll),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: _records.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (_, i) {
          if (i == _records.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }
          return _HistoryTile(record: _records[i]);
        },
      ),
    );
  }
}

// ─── Location chip ────────────────────────────────────────────────────────────

class _LocationChip extends StatelessWidget {
  final String code;
  const _LocationChip(this.code);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, size: 12, color: Colors.grey),
            const SizedBox(width: 3),
            Text(code,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
}

// ─── Type filter chip ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─── History tile ─────────────────────────────────────────────────────────────

class _HistoryTile extends StatefulWidget {
  final ChangeRecord record;
  const _HistoryTile({required this.record});

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  static const _actionColor = <String, Color>{
    '入库': Colors.green,
    '录入': Colors.green,
    '暂存': Colors.teal,
    '出库': Colors.red,
    '删除库存': Colors.red,
    '调整': Colors.orange,
    '结构修改': Colors.orange,
    '批量转移': Colors.blue,
    '批量复制': Colors.indigo,
    'SKU更正': Colors.purple,
    'SKU更正并合并': Colors.deepOrange,
    '暂存转正式': Colors.teal,
    '暂存拆分': Colors.deepPurple,
  };

  static const _actionIcon = <String, IconData>{
    '入库': Icons.add_circle_outline,
    '录入': Icons.add_box_outlined,
    '暂存': Icons.inventory_2_outlined,
    '出库': Icons.remove_circle_outline,
    '删除库存': Icons.delete_outline,
    '调整': Icons.tune,
    '结构修改': Icons.edit_outlined,
    '批量转移': Icons.swap_horiz,
    '批量复制': Icons.copy_all,
    'SKU更正': Icons.find_replace,
    'SKU更正并合并': Icons.merge,
    '暂存转正式': Icons.check_circle_outline,
    '暂存拆分': Icons.call_split,
  };

  Color get _color {
    final action = widget.record.businessAction ?? '';
    return _actionColor[action] ?? Colors.grey.shade500;
  }

  IconData get _icon {
    final action = widget.record.businessAction ?? '';
    return _actionIcon[action] ?? Icons.history;
  }

  /// 取 "@ LOC " 之后的部分作为摘要行
  String _buildSummary(AppLocalizations l10n) {
    final d = widget.record.details;
    final ba = widget.record.businessAction;
    final pcs = l10n.unitPiece;
    if (d != null && ba != null) {
      switch (ba) {
        case '入库':
          return '+${d['addedQty'] ?? 0}$pcs';
        case '出库':
          return '-${d['reducedQty'] ?? 0}$pcs';
        case '调整':
          final note = d['note'];
          final noteStr = (note != null && note.toString().isNotEmpty) ? '  ${l10n.auditNote}: $note' : '';
          return '${d['beforeQty'] ?? 0}→${d['afterQty'] ?? 0}$pcs$noteStr';
        case '录入':
          return '${d['quantity'] ?? 0}$pcs';
        case '删除库存':
          return '${d['quantity'] ?? 0}$pcs';
        case '批量转移':
        case '批量复制':
          return '${d['sourceCode']} → ${d['targetCode']}';
        case '标记已检查':
        case '取消已检查':
          return d['locationCode']?.toString() ?? '';
      }
    }
    // fallback: strip leading "action @ loc " prefix from server description
    final desc = widget.record.description;
    final atIdx = desc.indexOf(' @ ');
    if (atIdx == -1) return '';
    final afterAt = atIdx + 3;
    final spaceAfterLoc = desc.indexOf(' ', afterAt);
    if (spaceAfterLoc == -1) return '';
    return desc.substring(spaceAfterLoc + 1).trim();
  }

  // ── 展开区域：结构化 details（暂存拆分）或完整 description ──────────────────

  Widget _buildExpandedBody(Color color) {
    final details = widget.record.details;
    if (details != null && details['targets'] is List) {
      return _buildSplitDetails(details, color);
    }
    // 通用：完整 description 文本
    return _buildDescriptionText(color);
  }

  Widget _buildSplitDetails(Map<String, dynamic> details, Color color) {
    final l10n = AppLocalizations.of(context)!;
    final src = details['source'] as Map<String, dynamic>?;
    final targets = (details['targets'] as List).cast<Map<String, dynamic>>();
    final note = details['note'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source pending
          if (src != null) ...[
            _detailRow(l10n.invHistorySplitSrc, '${src['skuCode']}  ${src['qtyDesc']}',
                icon: Icons.inventory_2_outlined, color: Colors.grey.shade600),
            const SizedBox(height: 6),
          ],
          // Split targets list
          _detailLabel(l10n.invHistorySplitTargets, color),
          const SizedBox(height: 4),
          ...targets.map((t) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  children: [
                    Icon(Icons.subdirectory_arrow_right,
                        size: 13, color: color.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(t['skuCode'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(t['qtyDesc'] as String,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              )),
          // Source record disposition
          const SizedBox(height: 6),
          _detailRow(l10n.invHistorySplitSrc, l10n.invHistorySplitCleared,
              icon: Icons.check_circle_outline, color: Colors.green.shade700),
          // Reason
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(l10n.invHistoryReason, note,
                icon: Icons.notes_outlined, color: Colors.grey.shade600),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionText(Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        widget.record.description,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.5),
      ),
    );
  }

  Widget _detailLabel(String label, Color color) => Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 0.3),
      );

  Widget _detailRow(String label, String value,
      {IconData? icon, Color? color}) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 4),
        ],
        Text('$label：',
            style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = _color;
    final action = AuditLogDetailSheet.translateAction(widget.record.businessAction, l10n).isNotEmpty
        ? AuditLogDetailSheet.translateAction(widget.record.businessAction, l10n)
        : l10n.invDetailDefaultAction;
    final summary = _buildSummary(l10n);
    final fmt = DateFormat('yyyy-MM-dd HH:mm');

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action badge + summary
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Text(action,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            )),
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            summary,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                            maxLines: _expanded ? null : 1,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      // Expand toggle
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Operator + time
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(widget.record.userName,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                      const SizedBox(width: 10),
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 3),
                      Text(
                          fmt.format(widget.record.createdAt.toLocal()),
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                  // Expanded body
                  if (_expanded) _buildExpandedBody(color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
