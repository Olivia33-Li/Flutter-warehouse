import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/history_service.dart';
import '../../services/api_service.dart';
import '../../models/change_record.dart';
import '../../widgets/error_view.dart';
import '../../widgets/audit_log_detail_sheet.dart';
import '../../l10n/app_localizations.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final String? initialLocationCode;
  const HistoryScreen({super.key, this.initialLocationCode});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _historyService = HistoryService();
  String? _filterLocationCode;
  final _keywordCtrl = TextEditingController();
  List<ChangeRecord> _records = [];
  bool _loading = true;
  String? _error;

  String? _filterBusinessAction;
  String? _filterEntity;
  String? _filterDateRange;
  DateTime? _customStart;
  DateTime? _customEnd;
  String? _filterUserName;
  bool _userFilterInitialized = false;
  List<_FilterOption> _userOptions = const [_FilterOption(label: '', value: null)];
  int _page = 1;
  int _total = 0;
  static const _limit = 50;

  @override
  void initState() {
    super.initState();
    _keywordCtrl.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_userFilterInitialized) {
      _userFilterInitialized = true;
      _filterLocationCode = widget.initialLocationCode;
      final user = ref.read(currentUserProvider);
      if (user != null && !user.canViewAllHistory) {
        _filterUserName = user.username;
      }
      if (user?.canManageUsers == true) _loadUsers();
      _load();
    }
  }

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final resp = await ApiService.instance.dio.get('/users');
      final list = resp.data as List;
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _userOptions = [
          _FilterOption(label: l10n.historyAllUsersTab, value: null),
          ...list.map((u) {
            final name = (u['name'] as String? ?? '').isNotEmpty
                ? u['name'] as String
                : u['username'] as String;
            return _FilterOption(label: name, value: u['username'] as String);
          }),
        ];
      });
    } catch (_) {}
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
        return (_customStart?.toIso8601String(), _customEnd?.toIso8601String());
      default:
        return (null, null);
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    DateTime? start = _customStart;
    DateTime? end = _customEnd;
    bool editingStart = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final l10n = AppLocalizations.of(ctx)!;
          final calendarInitial =
              editingStart ? (start ?? now) : (end ?? now);
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
                    color: active
                        ? primary.withValues(alpha: 0.08)
                        : Colors.transparent,
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
                        val != null ? _fmtDate(val) : l10n.historyPleaseSelect,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                  child: Row(
                    children: [
                      Text(l10n.historyCustomRangeTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      fieldBtn(l10n.historyStartDate, start, true),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('→',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      fieldBtn(l10n.historyEndDate, end, false),
                    ],
                  ),
                ),
                CalendarDatePicker(
                  key: ValueKey(editingStart),
                  initialDate:
                      calendarInitial.isAfter(now) ? now : calendarInitial,
                  firstDate: calendarFirst,
                  lastDate: now,
                  onDateChanged: (d) {
                    setS(() {
                      if (editingStart) {
                        start = DateTime(d.year, d.month, d.day, 0, 0, 0);
                        if (end != null && end!.isBefore(start!)) end = null;
                        editingStart = false;
                      } else {
                        end = DateTime(d.year, d.month, d.day, 23, 59, 59);
                      }
                    });
                  },
                ),
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
                        child: Text(l10n.historyClear,
                            style:
                                TextStyle(color: Colors.grey.shade500)),
                      ),
                      const Spacer(),
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(l10n.cancel)),
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
                        child: Text(l10n.historyApply),
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
      final isCheckFilter = _filterBusinessAction == '标记已检查' ||
          _filterBusinessAction == '取消已检查';
      final result = await _historyService.getAll(
        businessAction: _filterBusinessAction,
        entity: _filterEntity,
        keyword: _keywordCtrl.text.trim(),
        startDate: startDate,
        endDate: endDate,
        userName: isCheckFilter ? null : _filterUserName,
        locationCode: _filterLocationCode,
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

  static String listSummary(ChangeRecord r, AppLocalizations l10n) {
    final d = r.details;
    final ba = r.businessAction;
    if (d == null || ba == null) {
      // Strip Chinese action prefix (e.g. "入库: SKU @ LOC detail" → "SKU @ LOC detail")
      final desc = r.description;
      final colonIdx = desc.indexOf(': ');
      return colonIdx != -1 ? desc.substring(colonIdx + 2).trim() : desc;
    }
    final pcs = l10n.unitPiece;
    switch (ba) {
      case '入库':
        return '${d['skuCode']} @ ${d['locationCode']} · +${d['addedQty'] ?? 0}$pcs';
      case '出库':
        return '${d['skuCode']} @ ${d['locationCode']} · -${d['reducedQty'] ?? 0}$pcs';
      case '调整':
        return '${d['skuCode']} @ ${d['locationCode']} · ${d['beforeQty'] ?? 0}→${d['afterQty'] ?? 0}$pcs';
      case '录入':
        return '${d['skuCode']} @ ${d['locationCode']} · ${d['quantity'] ?? 0}$pcs';
      case '删除库存':
      case '结构修改':
        return '${d['skuCode']} @ ${d['locationCode']}';
      case '批量转移':
      case '批量复制':
        return '${d['sourceCode']} → ${d['targetCode']} · ${l10n.historyBulkSkuCount(d['total'] ?? 0)}';
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

  // ── Label helpers ───────────────────────────────────────────────────────────

  String _actionLabel(AppLocalizations l10n) => _filterBusinessAction ?? l10n.historyActionTypeLabel;

  String _entityLabel(AppLocalizations l10n) => switch (_filterEntity) {
    'sku'       => 'SKU',
    'location'  => l10n.historyEntityLocation,
    'inventory' => l10n.historyEntityInventory,
    _           => l10n.historyEntityLabel,
  };

  String _dateLabel(AppLocalizations l10n) {
    switch (_filterDateRange) {
      case 'today':
        return l10n.historyToday;
      case '7d':
        return l10n.historyLast7Days;
      case '30d':
        return l10n.historyLast30Days;
      case 'custom':
        if (_customStart != null && _customEnd != null) {
          return '${_fmtDate(_customStart!)}~${_fmtDate(_customEnd!)}';
        }
        return l10n.historyCustomRange;
      default:
        return l10n.historyTimeLabel;
    }
  }

  String _userLabel(AppLocalizations l10n) {
    if (_filterUserName == null) return l10n.historyUserLabel;
    final match = _userOptions.where((o) => o.value == _filterUserName).firstOrNull;
    return match?.label ?? _filterUserName!;
  }

  // ── User tabs ───────────────────────────────────────────────────────────────

  Widget _buildUserTabs() {
    final l10n = AppLocalizations.of(context)!;
    final currentUsername = ref.read(currentUserProvider)?.username;
    final isAll = _filterUserName == null;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabButton(l10n.historyAllUsersTab, isAll, () {
            setState(() => _filterUserName = null);
            _load();
          }),
          _tabButton(l10n.historyMyRecords, !isAll, () {
            setState(() => _filterUserName = currentUsername);
            _load();
          }),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // ── Search box ──────────────────────────────────────────────────────────────

  Widget _buildSearchBox() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _keywordCtrl,
        onChanged: (_) => _load(),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.historySearchHint,
          hintStyle:
              TextStyle(fontSize: 14, color: Colors.grey.shade400),
          prefixIcon:
              Icon(Icons.search, size: 20, color: Colors.grey.shade400),
          suffixIcon: _keywordCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      size: 18, color: Colors.grey.shade400),
                  onPressed: () {
                    _keywordCtrl.clear();
                    _load();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canViewAll   = currentUser?.canViewAllHistory == true;
    final canPickUser  = currentUser?.canManageUsers == true;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(l10n.historyTitle,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: canViewAll
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildUserTabs(),
                ),
              ]
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search + filter row ─────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBox(),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 操作类型 dropdown
                    _FilterDropdown(
                      label: _actionLabel(l10n),
                      active: _filterBusinessAction != null,
                      options: [
                        _FilterOption(label: l10n.historyFilterAll, value: null),
                        _FilterOption(label: l10n.historyFilterImport, value: '导入'),
                        _FilterOption(label: l10n.historyFilterNew, value: '新增SKU'),
                        _FilterOption(label: l10n.historyFilterEntry, value: '录入'),
                        _FilterOption(label: l10n.historyFilterAdjust, value: '调整'),
                        _FilterOption(label: l10n.historyFilterTransfer, value: '批量转移'),
                        _FilterOption(label: l10n.historyFilterCopy, value: '批量复制'),
                        _FilterOption(label: l10n.historyFilterCheck, value: '标记已检查'),
                        _FilterOption(label: l10n.historyFilterIn, value: '入库'),
                        _FilterOption(label: l10n.historyFilterOut, value: '出库'),
                      ],
                      selected: _filterBusinessAction,
                      onSelect: (v) {
                        setState(() => _filterBusinessAction = v);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    // 对象 dropdown
                    _FilterDropdown(
                      label: _entityLabel(l10n),
                      active: _filterEntity != null,
                      options: [
                        _FilterOption(label: l10n.historyFilterAll, value: null),
                        _FilterOption(label: l10n.historyEntitySku, value: 'sku'),
                        _FilterOption(label: l10n.historyEntityLocationLabel, value: 'location'),
                        _FilterOption(label: l10n.historyEntityInventoryLabel, value: 'inventory'),
                      ],
                      selected: _filterEntity,
                      onSelect: (v) {
                        setState(() => _filterEntity = v);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    // 用户 dropdown (admin only)
                    if (canPickUser) ...[
                      _FilterDropdown(
                        label: _userLabel(l10n),
                        active: _filterUserName != null &&
                            _filterUserName != ref.read(currentUserProvider)?.username,
                        options: _userOptions,
                        selected: _filterUserName,
                        onSelect: (v) {
                          setState(() => _filterUserName = v);
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    // 时间 dropdown
                    _DateFilterDropdown(
                      label: _dateLabel(l10n),
                      active: _filterDateRange != null,
                      selected: _filterDateRange,
                      onSelect: (v) {
                        setState(() {
                          _filterDateRange = v;
                          if (v != 'custom') {
                            _customStart = null;
                            _customEnd = null;
                          }
                        });
                        _load();
                      },
                      onCustom: _pickCustomRange,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Record count ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              l10n.historyTotalRecords(_total),
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          // ── List ────────────────────────────────────────────────────
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.historyNoRecords,
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _records[i];
        final style = AuditLogDetailSheet.badgeStyle(r);
        return _RecordTile(
          record: r,
          style: style,
          label: AuditLogDetailSheet.badgeLabel(r, AppLocalizations.of(context)!),
          summaryText: listSummary(r, AppLocalizations.of(context)!),
          timeLabel: _formatShort(r.createdAt),
          onTap: () => AuditLogDetailSheet.show(context, r),
        );
      },
    );
  }
}

// ── Filter option model ───────────────────────────────────────────────────────

class _FilterOption {
  final String label;
  final String? value;
  const _FilterOption({required this.label, required this.value});
}

// ── Value wrapper: lets showMenu distinguish null-value selection from dismissal
class _V<T> {
  final T value;
  const _V(this.value);
}

// ── Generic filter dropdown ───────────────────────────────────────────────────

class _FilterDropdown extends StatefulWidget {
  final String label;
  final bool active;
  final List<_FilterOption> options;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _FilterDropdown({
    required this.label,
    required this.active,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
  bool _isOpen = false;

  Future<void> _showOptions() async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    if (mounted) setState(() => _isOpen = true);

    final result = await showMenu<_V<String?>>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      items: widget.options.map((opt) {
        final sel = opt.value == widget.selected;
        return PopupMenuItem<_V<String?>>(
          value: _V(opt.value),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            opt.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              color: sel
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFF444455),
            ),
          ),
        );
      }).toList(),
    );

    if (mounted) setState(() => _isOpen = false);
    if (result != null) widget.onSelect(result.value);
  }

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: widget.label,
      active: widget.active,
      open: _isOpen,
      onTap: _showOptions,
    );
  }
}

// ── Date filter dropdown (has custom range option) ────────────────────────────

class _DateFilterDropdown extends StatefulWidget {
  final String label;
  final bool active;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final VoidCallback onCustom;

  const _DateFilterDropdown({
    required this.label,
    required this.active,
    required this.selected,
    required this.onSelect,
    required this.onCustom,
  });

  @override
  State<_DateFilterDropdown> createState() => _DateFilterDropdownState();
}

class _DateFilterDropdownState extends State<_DateFilterDropdown> {
  bool _isOpen = false;

  List<_FilterOption> _dateOptions(AppLocalizations l10n) => [
    _FilterOption(label: l10n.historyAllTime, value: null),
    _FilterOption(label: l10n.historyToday, value: 'today'),
    _FilterOption(label: l10n.historyLast7Days, value: '7d'),
    _FilterOption(label: l10n.historyLast30Days, value: '30d'),
  ];

  Future<void> _showOptions() async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero),
            ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    if (mounted) setState(() => _isOpen = true);

    final result = await showMenu<_V<String?>>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      items: [
        ..._dateOptions(AppLocalizations.of(context)!).map((opt) {
          final sel = opt.value == widget.selected;
          return PopupMenuItem<_V<String?>>(
            value: _V(opt.value),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              opt.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                color: sel
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF444455),
              ),
            ),
          );
        }),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<_V<String?>>(
          value: const _V('custom'),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context)!.historyCustomRange,
            style: TextStyle(
              fontSize: 14,
              fontWeight: widget.selected == 'custom'
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: widget.selected == 'custom'
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFF444455),
            ),
          ),
        ),
      ],
    );

    if (mounted) setState(() => _isOpen = false);
    if (result != null) {
      if (result.value == 'custom') {
        widget.onCustom();
      } else {
        widget.onSelect(result.value);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: widget.label,
      active: widget.active,
      open: _isOpen,
      onTap: _showOptions,
    );
  }
}

// ── Pill trigger button ───────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool open;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.active,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use a soft neutral active color matching Figma (dark outline when active/open)
    final isHighlighted = active || open;
    final borderColor =
        isHighlighted ? const Color(0xFF1A1A2E) : const Color(0xFFDDDDE5);
    final bgColor = isHighlighted
        ? const Color(0xFF1A1A2E).withValues(alpha: 0.05)
        : Colors.white;
    final textColor =
        isHighlighted ? const Color(0xFF1A1A2E) : const Color(0xFF888898);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: textColor,
              ),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: const Duration(milliseconds: 150),
              child: Icon(Icons.keyboard_arrow_down,
                  size: 14, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Record card ───────────────────────────────────────────────────────────────

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

  (Color, Color) _entityColors() {
    switch (record.entity) {
      case 'SKU':
        return (Colors.teal.shade700, Colors.teal.shade50);
      case '库存':
        return (Colors.green.shade700, Colors.green.shade50);
      case '库位':
        return (Colors.blue.shade700, Colors.blue.shade50);
      default:
        return (Colors.grey.shade600, Colors.grey.shade100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = style;
    final (tagFg, tagBg) = _entityColors();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Action icon ────────────────────────────────────────
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: fg),
              ),
              const SizedBox(width: 12),
              // ── Content ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            record.entity.toLowerCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: tagFg),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summaryText,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${record.userName}  ·  $timeLabel',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 16, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
