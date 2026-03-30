import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/history_service.dart';
import '../../models/change_record.dart';
import '../../widgets/error_view.dart';
import '../../widgets/audit_log_detail_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _historyService = HistoryService();
  final _keywordCtrl = TextEditingController();
  List<ChangeRecord> _records = [];
  bool _loading = true;
  String? _error;

  String? _filterBusinessAction;
  String? _filterEntity;
  String? _filterDateRange;
  DateTime? _customStart;
  DateTime? _customEnd;
  // null = all users (admin only); non-null = filter by username
  String? _filterUserName;
  bool _userFilterInitialized = false;
  int _page = 1;
  int _total = 0;
  static const _limit = 50;

  @override
  void initState() {
    super.initState();
    // _load() will be called after first build via didChangeDependencies
    // to ensure the user is available from the provider
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_userFilterInitialized) {
      _userFilterInitialized = true;
      final user = ref.read(currentUserProvider);
      if (user != null && !user.isAdmin) {
        _filterUserName = user.username;
      }
      _load();
    }
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
      case 'custom':
        return (
          _customStart?.toIso8601String(),
          _customEnd?.toIso8601String(),
        );
      default:
        return (null, null);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    DateTime? start = _customStart;
    DateTime? end = _customEnd;
    // which field the calendar is editing: true=start, false=end
    bool editingStart = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final calendarInitial = editingStart
              ? (start ?? now)
              : (end ?? now);
          final calendarFirst =
              editingStart ? DateTime(2020) : (start ?? DateTime(2020));

          Widget fieldBtn(String label, DateTime? val, bool isStart) {
            final active = editingStart == isStart;
            final primary = Theme.of(ctx).colorScheme.primary;
            return Expanded(
              child: GestureDetector(
                onTap: () => setS(() => editingStart = isStart),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: active ? primary.withValues(alpha: 0.08) : Colors.transparent,
                    border: Border.all(
                        color: active ? primary : Colors.grey.shade300,
                        width: active ? 1.5 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              color: active ? primary : Colors.grey.shade500)),
                      const SizedBox(height: 2),
                      Text(
                        val != null ? _fmtDate(val) : '请选择',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: val != null
                                ? (active ? primary : null)
                                : Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题栏
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      const Text('自定义时间范围',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                ),

                // 开始 / 结束 字段按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      fieldBtn('开始日期', start, true),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('→',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      fieldBtn('结束日期', end, false),
                    ],
                  ),
                ),

                // 内嵌日历 — 点选即确认，无需 OK 键
                CalendarDatePicker(
                  key: ValueKey(editingStart),
                  initialDate: calendarInitial.isAfter(now) ? now : calendarInitial,
                  firstDate: calendarFirst,
                  lastDate: now,
                  onDateChanged: (d) {
                    setS(() {
                      if (editingStart) {
                        start = DateTime(d.year, d.month, d.day, 0, 0, 0);
                        if (end != null && end!.isBefore(start!)) end = null;
                        editingStart = false; // 自动切到结束
                      } else {
                        end = DateTime(d.year, d.month, d.day, 23, 59, 59);
                      }
                    });
                  },
                ),

                // 操作按钮
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _customStart = null;
                            _customEnd = null;
                            _filterDateRange = null;
                          });
                          Navigator.of(ctx).pop();
                          _load();
                        },
                        child: Text('清空',
                            style:
                                TextStyle(color: Colors.grey.shade500)),
                      ),
                      const Spacer(),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('取消')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: start != null && end != null
                            ? () {
                                setState(() {
                                  _customStart = start;
                                  _customEnd = end;
                                  _filterDateRange = 'custom';
                                });
                                Navigator.of(ctx).pop();
                                _load();
                              }
                            : null,
                        child: const Text('应用'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';


  Future<void> _load({bool reset = true}) async {
    if (reset) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (startDate, endDate) = _dateRange();
      // Check actions are public — don't restrict to the current user's records
      final isCheckFilter = _filterBusinessAction == '标记已检查' ||
          _filterBusinessAction == '取消已检查';
      final result = await _historyService.getAll(
        businessAction: _filterBusinessAction,
        entity: _filterEntity,
        keyword: _keywordCtrl.text.trim(),
        startDate: startDate,
        endDate: endDate,
        userName: isCheckFilter ? null : _filterUserName,
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
          preferredSize: Size.fromHeight(
            ref.watch(currentUserProvider)?.isAdmin == true ? 154 : 112,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                if (ref.watch(currentUserProvider)?.isAdmin == true) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _chip('全部用户', null, _filterUserName, (v) {
                        setState(() => _filterUserName = v);
                        _load();
                      }),
                      _chip(
                        '我的记录',
                        ref.read(currentUserProvider)?.username,
                        _filterUserName,
                        (v) {
                          setState(() => _filterUserName = v);
                          _load();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // ── 操作类型 ──
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
                    // ── 对象类型 ──
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
                    // ── 时间 ──
                    _chip('全部时间', null, _filterDateRange, (v) {
                      setState(() {
                        _filterDateRange = v;
                        _customStart = null;
                        _customEnd = null;
                      });
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
                    FilterChip(
                      label: Text(
                        _filterDateRange == 'custom' &&
                                _customStart != null &&
                                _customEnd != null
                            ? '${_fmtDate(_customStart!)} ~ ${_fmtDate(_customEnd!)}'
                            : '自定义时间',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _filterDateRange == 'custom',
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) {
                        if (_filterDateRange == 'custom') {
                          setState(() {
                            _filterDateRange = null;
                            _customStart = null;
                            _customEnd = null;
                          });
                          _load();
                        } else {
                          _pickCustomRange();
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
