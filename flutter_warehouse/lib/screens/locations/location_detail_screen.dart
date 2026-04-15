import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/inventory_service.dart';
import '../../services/history_service.dart';
import '../../services/sku_service.dart';
import '../../models/inventory.dart';
import '../../models/sku.dart';
import '../../models/location.dart';
import '../../models/change_record.dart';
import '../../widgets/error_view.dart';
import '../../widgets/inventory_detail_sheet.dart';
import '../../widgets/audit_log_detail_sheet.dart';
import '../history/history_screen.dart';

class LocationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const LocationDetailScreen({super.key, required this.id});

  @override
  ConsumerState<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  final _locationService = LocationService();
  final _inventoryService = InventoryService();
  final _historyService = HistoryService();
  Map<String, dynamic>? _data;
  ChangeRecord? _latestOp;
  ChangeRecord? _latestCheck;
  bool _loading = true;
  String? _error;

  // ── SKU 列表筛选状态 ──────────────────────────────────────────────────────────
  // 库存状态: 'all' | 'has_stock' | 'zero_stock'
  String _stockFilter = 'has_stock'; // 默认只显示有库存
  // 业务状态: 'all' | 'normal' | 'pending'
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _data = await _locationService.getOne(widget.id);
      final locationCode = _data?['code'] as String?;
      if (locationCode != null) {
        final opResult = await _historyService.getAll(
          locationCode: locationCode,
          inventoryChangingOnly: true,
          page: 1,
          limit: 1,
        );
        final checkResult = await _historyService.getAll(
          locationCode: locationCode,
          businessAction: '标记已检查',
          page: 1,
          limit: 1,
        );
        final opRecords = opResult['records'] as List<ChangeRecord>;
        final checkRecords = checkResult['records'] as List<ChangeRecord>;
        _latestOp = opRecords.isNotEmpty ? opRecords.first : null;
        _latestCheck = checkRecords.isNotEmpty ? checkRecords.first : null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showInventoryDialog({InventoryRecord? existing}) async {
    final skus = await SkuService().getAll();
    if (!mounted) return;

    String? selectedSkuCode = existing?.skuCode;
    String? selectedSkuName = existing != null
        ? skus.where((s) => s.sku == existing.skuCode).map((s) => s.name).firstOrNull
        : null;
    final boxesCtrl = TextEditingController(text: existing?.boxes.toString() ?? '');
    final unitsCtrl = TextEditingController(text: existing?.unitsPerBox.toString() ?? '1');
    final totalQtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String inputMode = 'carton'; // 'carton' | 'boxesOnly' | 'qty'
    bool isPending = false;
    String? dialogError;

    // SKU search state
    final skuSearchCtrl = TextEditingController();
    List<Sku> filteredSkus = [];
    bool showSkuResults = false;

    // Inline new-SKU creation state
    bool isCreatingNew = false;
    final newCodeCtrl = TextEditingController();
    final newNameCtrl = TextEditingController();
    String? createError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? '新增 SKU' : '编辑库存'),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SKU selector ─────────────────────────────────────
                  if (existing == null) ...[
                    // State A: SKU already selected → show chip
                    if (selectedSkuCode != null && !showSkuResults && !isCreatingNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SKU', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(selectedSkuCode!,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (selectedSkuName != null && selectedSkuName!.isNotEmpty)
                                    Text(selectedSkuName!,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: '重新选择',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setS(() {
                                selectedSkuCode = null;
                                selectedSkuName = null;
                                skuSearchCtrl.clear();
                                filteredSkus = [];
                                showSkuResults = false;
                              }),
                            ),
                          ],
                        ),
                      )
                    // State B: search field + results
                    else if (!isCreatingNew) ...[
                      TextField(
                        controller: skuSearchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'SKU',
                          hintText: '搜索编码 / 名称 / 条码',
                          prefixIcon: Icon(Icons.search, size: 18),
                          border: OutlineInputBorder(),
                          isDense: false,
                        ),
                        onChanged: (v) {
                          final q = v.trim().toLowerCase();
                          setS(() {
                            if (q.isEmpty) {
                              filteredSkus = [];
                              showSkuResults = false;
                            } else {
                              filteredSkus = skus.where((s) =>
                                s.sku.toLowerCase().contains(q) ||
                                (s.name?.toLowerCase().contains(q) ?? false) ||
                                (s.barcode?.toLowerCase().contains(q) ?? false),
                              ).toList();
                              showSkuResults = true;
                            }
                          });
                        },
                      ),
                      if (showSkuResults) ...[
                        const SizedBox(height: 2),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            children: [
                              ...filteredSkus.map((s) => ListTile(
                                dense: true,
                                title: Text(s.sku,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: (s.name != null && s.name!.isNotEmpty)
                                    ? Text(s.name!)
                                    : null,
                                trailing: (s.barcode != null && s.barcode!.isNotEmpty)
                                    ? Text(s.barcode!,
                                        style: TextStyle(
                                            color: Colors.grey.shade500, fontSize: 11))
                                    : null,
                                onTap: () => setS(() {
                                  selectedSkuCode = s.sku;
                                  selectedSkuName = s.name;
                                  showSkuResults = false;
                                  skuSearchCtrl.clear();
                                }),
                              )),
                              if (filteredSkus.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text('未找到匹配的 SKU',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              ListTile(
                                dense: true,
                                leading: const Icon(Icons.add,
                                    color: Colors.blue, size: 18),
                                title: const Text('+ 新建货号',
                                    style: TextStyle(
                                        color: Colors.blue, fontSize: 13)),
                                onTap: () => setS(() {
                                  newCodeCtrl.text =
                                      skuSearchCtrl.text.trim();
                                  newNameCtrl.clear();
                                  isCreatingNew = true;
                                  showSkuResults = false;
                                  createError = null;
                                }),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('新建货号',
                                style: TextStyle(fontSize: 13)),
                            style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2)),
                            onPressed: () => setS(() {
                              newCodeCtrl.clear();
                              newNameCtrl.clear();
                              isCreatingNew = true;
                              createError = null;
                            }),
                          ),
                        ),
                    ]
                    // State C: inline create-new form
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.add_box_outlined,
                                    size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text('新建货号',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue,
                                          fontSize: 13)),
                                ),
                                GestureDetector(
                                  onTap: () => setS(() {
                                    isCreatingNew = false;
                                    createError = null;
                                  }),
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: newCodeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'SKU 编码 *',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newNameCtrl,
                              decoration: const InputDecoration(
                                labelText: '货号名称（可选）',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            if (createError != null) ...[
                              const SizedBox(height: 6),
                              Text(createError!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 12)),
                            ],
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    textStyle:
                                        const TextStyle(fontSize: 13)),
                                onPressed: () async {
                                  final code = newCodeCtrl.text.trim();
                                  if (code.isEmpty) {
                                    setS(() => createError = '请输入 SKU 编码');
                                    return;
                                  }
                                  try {
                                    final nameVal =
                                        newNameCtrl.text.trim();
                                    final created =
                                        await SkuService().create(
                                      sku: code,
                                      name: nameVal.isEmpty
                                          ? null
                                          : nameVal,
                                    );
                                    skus.add(created);
                                    setS(() {
                                      selectedSkuCode = created.sku;
                                      selectedSkuName = created.name;
                                      isCreatingNew = false;
                                      createError = null;
                                    });
                                  } catch (e) {
                                    setS(() => createError = '创建失败: $e');
                                  }
                                },
                                child: const Text('创建'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ] else
                    // Editing existing inventory: show read-only SKU label
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('SKU',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        subtitle: Text(existing.skuCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),

                  // ── 暂存状态勾选（新增时可选，不改变录入方式） ──────────
                  if (existing == null) ...[
                    CheckboxListTile(
                      value: isPending,
                      onChanged: (v) => setS(() => isPending = v ?? false),
                      title: const Text('标记为暂存 / 待清点',
                          style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        isPending
                            ? '此记录将归入暂存分类，可填写实际数量'
                            : '勾选后归入暂存分类，数量仍正常录入',
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(Icons.pending_actions_outlined,
                          color: isPending ? Colors.orange : Colors.grey,
                          size: 20),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      tileColor: isPending ? Colors.orange.shade50 : null,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 8),
                    // 录入模式切换 — 勾选暂存后同样可用
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                            value: 'carton',
                            label: Text('按箱规'),
                            icon: Icon(Icons.inventory_2_outlined)),
                        ButtonSegment(
                            value: 'boxesOnly',
                            label: Text('仅箱数'),
                            icon: Icon(Icons.view_list)),
                        ButtonSegment(
                            value: 'qty',
                            label: Text('按总数量'),
                            icon: Icon(Icons.format_list_numbered)),
                      ],
                      selected: {inputMode},
                      onSelectionChanged: (s) =>
                          setS(() => inputMode = s.first),
                      style: const ButtonStyle(
                          visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── 数量录入区域（新增和编辑都显示，不受暂存影响） ──
                  if (existing != null || inputMode == 'carton') ...[
                    TextField(
                      controller: boxesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: '箱数',
                          border: OutlineInputBorder(),
                          suffixText: '箱'),
                      onChanged: (_) => setS(() {}),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: unitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: '每箱件数',
                          border: OutlineInputBorder(),
                          suffixText: '件/箱'),
                      onChanged: (_) => setS(() {}),
                    ),
                    Builder(builder: (_) {
                      final b = int.tryParse(boxesCtrl.text) ?? 0;
                      final u = int.tryParse(unitsCtrl.text) ?? 0;
                      if (b > 0 && u > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('共 ${b * u} 件',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ] else if (inputMode == 'boxesOnly') ...[
                    TextField(
                      controller: boxesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: '箱数',
                          border: OutlineInputBorder(),
                          suffixText: '箱',
                          helperText: '仅记录箱数，每箱件数可后续补充'),
                      onChanged: (_) => setS(() {}),
                    ),
                  ] else ...[
                    TextField(
                      controller: totalQtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: '初始总件数',
                          border: OutlineInputBorder(),
                          suffixText: '件'),
                    ),
                  ],

                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                        labelText: '备注（可选）',
                        border: OutlineInputBorder()),
                  ),

                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(dialogError!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              style: existing == null && isPending
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade600)
                  : null,
              onPressed: () async {
                if (existing == null && selectedSkuCode == null) {
                  setS(() => dialogError = '请选择 SKU');
                  return;
                }
                // 解析数量 — 暂存状态不再强制清零，允许填写实际数量
                int boxes, unitsPerBox;
                final effectiveMode =
                    existing != null ? 'carton' : inputMode;
                if (effectiveMode == 'carton') {
                  boxes = int.tryParse(boxesCtrl.text) ?? 0;
                  unitsPerBox = int.tryParse(unitsCtrl.text) ?? 0;
                  if (boxes <= 0 || unitsPerBox <= 0) {
                    setS(() => dialogError = '请输入有效的箱数和每箱件数');
                    return;
                  }
                } else if (effectiveMode == 'boxesOnly') {
                  boxes = int.tryParse(boxesCtrl.text) ?? 0;
                  unitsPerBox = 1;
                  if (boxes <= 0) {
                    setS(() => dialogError = '请输入有效箱数');
                    return;
                  }
                } else {
                  // 'qty'
                  final qty = int.tryParse(totalQtyCtrl.text) ?? 0;
                  if (qty <= 0) {
                    setS(() => dialogError = '请输入有效的数量');
                    return;
                  }
                  boxes = 1;
                  unitsPerBox = qty;
                }
                final note = noteCtrl.text.trim();
                try {
                  if (existing != null) {
                    await _inventoryService.update(
                      existing.id,
                      boxes: boxes,
                      unitsPerBox: unitsPerBox,
                    );
                  } else {
                    await _inventoryService.create(
                      skuCode: selectedSkuCode!,
                      locationId: widget.id,
                      boxes: boxes,
                      unitsPerBox: unitsPerBox,
                      note: note.isEmpty ? null : note,
                      pendingCount: isPending,
                      boxesOnlyMode: inputMode == 'boxesOnly',
                    );
                  }
                  if (ctx.mounted) ctx.pop();
                  _load();
                } catch (e) {
                  if (ctx.mounted) {
                    String msg = '操作失败，请重试';
                    if (e is DioException) {
                      final data = e.response?.data;
                      if (data is Map) {
                        final m = data['message'];
                        if (m is String && m.isNotEmpty) {
                          msg = m;
                        } else if (m is List && m.isNotEmpty) { msg = m.first.toString(); }
                      } else if (e.response?.statusCode == 400) {
                        msg = '参数错误，请检查输入';
                      }
                    }
                    setS(() => dialogError = msg);
                  }
                }
              },
              child: Text(existing == null && isPending ? '确认暂存' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bgColor    = Color(0xFFF5F3F0);
  static const _primary    = Color(0xFF4A6CF7);
  static const _titleColor = Color(0xFF1A1A2E);
  static const _mutedColor = Color(0xFF8E8E9A);
  static const _hintColor  = Color(0xFFB5B5C0);
  static const _tileBg     = Color(0xFFF9F8F6);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (_loading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final data      = _data!;
    final inventory = (data['inventory'] as List?)
        ?.map((e) => InventoryRecord.fromJson(e)).toList() ?? [];
    final skuCount  = (data['skuCount']   as num?)?.toInt() ?? 0;
    final totalBoxes= (data['totalBoxes'] as num?)?.toInt() ?? 0;
    final totalQty  = (data['totalQty']   as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _titleColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      data['code'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _titleColor, letterSpacing: -0.16),
                    ),
                  ),
                  const SizedBox(width: 32),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  _buildSummaryCard(data, totalBoxes, skuCount, totalQty),
                  const SizedBox(height: 20),
                  _buildSkuSectionHeader(inventory, user),
                  const SizedBox(height: 10),
                  _buildFilterChips(),
                  const SizedBox(height: 10),
                  Builder(builder: (_) {
                    final filtered = _filteredInventory(inventory);
                    if (filtered.isEmpty) return _buildEmptyState(inventory);
                    return Column(
                      children: filtered.map((r) => _buildSkuCard(r, data, user)).toList(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: user?.canEdit == true
          ? GestureDetector(
              onTap: _showInventoryDialog,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            )
          : null,
    );
  }

  // ── Summary card ────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(Map<String, dynamic> data, int totalBoxes, int skuCount, int totalQty) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statTile('SKU',  Icons.grid_view_rounded,       '$skuCount'),
              const SizedBox(width: 10),
              _statTile('总箱数', Icons.inventory_2_outlined,    '$totalBoxes'),
              const SizedBox(width: 10),
              _statTile('总件数', Icons.numbers_outlined, totalQty > 0 ? '$totalQty' : '—'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF2F1EF)),
          const SizedBox(height: 10),
          // 已检查 toggle
          Row(
            children: [
              const Text('已检查', style: TextStyle(fontSize: 12, color: _hintColor)),
              const Spacer(),
              Transform.scale(
                scale: 0.75,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: data['checked'] == true,
                  onChanged: (val) async {
                    await _locationService.check(widget.id, checked: val);
                    _load();
                  },
                  activeThumbColor: _primary,
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFF5F4F2)),
          _summaryInfoRow(
            '上次检查',
            _latestCheck == null ? '无检查记录' : _formatDate(_latestCheck!.createdAt.toIso8601String()),
            tappable: _latestCheck != null,
            onTap: _latestCheck != null ? () => _traceRowTap(_latestCheck!) : null,
          ),
          const Divider(height: 1, color: Color(0xFFF5F4F2)),
          _summaryInfoRow(
            '上次变更',
            _latestOp == null ? '无变更记录' : _formatDate(_latestOp!.createdAt.toIso8601String()),
            tappable: _data?['code'] != null,
            onTap: _data?['code'] != null ? _showLocationHistorySheet : null,
          ),
        ],
      ),
    );
  }

  void _traceRowTap(ChangeRecord record) {
    AuditLogDetailSheet.show(context, record);
  }

  void _showLocationHistorySheet() {
    final locationCode = _data?['code'] as String?;
    if (locationCode == null) return;

    final future = _historyService.getAll(
      locationCode: locationCode,
      inventoryChangingOnly: true,
      page: 1,
      limit: 10,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (_, snap) {
            final records = snap.hasData
                ? (snap.data!['records'] as List<ChangeRecord>)
                : <ChangeRecord>[];
            final total = snap.hasData ? (snap.data!['total'] as int) : 0;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // handle bar
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.history, size: 18, color: Color(0xFF5C6BC0)),
                          const SizedBox(width: 6),
                          Text(
                            '$locationCode 变更记录',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // content
                    if (snap.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      )
                    else if (snap.hasError)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('加载失败: ${snap.error}',
                            style: const TextStyle(color: Colors.red)),
                      )
                    else if (records.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text('暂无变更记录',
                            style: TextStyle(color: Color(0xFF9E9E9E))),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.55,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: records.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 56, endIndent: 16),
                          itemBuilder: (_, i) {
                            final r = records[i];
                            final style = AuditLogDetailSheet.badgeStyle(r);
                            final label = AuditLogDetailSheet.badgeLabel(r);
                            final (fg, bg, icon) = style;
                            return InkWell(
                              onTap: () {
                                AuditLogDetailSheet.show(sheetCtx, r);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // badge icon
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(icon, color: fg, size: 16),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: bg,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(label,
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: fg,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(r.userName,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF616161))),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            r.description,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF424242)),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDate(r.createdAt
                                                .toIso8601String()),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF9E9E9E)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        size: 14, color: Color(0xFFBDBDBD)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    // "查看全部" button
                    if (snap.hasData && total > 0) ...[
                      const Divider(height: 1),
                      TextButton(
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => HistoryScreen(
                                    initialLocationCode: locationCode),
                              ));
                            }
                          });
                        },
                        child: Text(
                          total > 10 ? '查看全部 $total 条记录' : '在操作记录页查看',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF5C6BC0)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statTile(String label, IconData icon, String value) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(color: _tileBg, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 11, color: _hintColor),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 10, color: _hintColor)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _titleColor)),
          ],
        ),
      ),
    );
  }

  Widget _summaryInfoRow(String label, String value, {bool tappable = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: _hintColor)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 12, color: _mutedColor)),
            if (tappable) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
            ],
          ],
        ),
      ),
    );
  }

  // ── SKU section header ──────────────────────────────────────────────────────

  Widget _buildSkuSectionHeader(List<InventoryRecord> inventory, dynamic user) {
    final filtered = _filteredInventory(inventory);
    final total = inventory.length;
    final shown = filtered.length;
    final label = shown == total ? '库存 SKU ($total)' : '库存 SKU ($shown / $total)';

    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _hintColor)),
        const Spacer(),
        if (inventory.isNotEmpty && user?.canEdit == true) ...[
          _headerActionBtn(
            icon: Icons.swap_horiz,
            label: '转移',
            bg: _primary.withValues(alpha: 0.06),
            fg: _primary.withValues(alpha: 0.7),
            onTap: () => _showTransferCopyDialog(isTransfer: true, inventory: inventory),
          ),
          const SizedBox(width: 8),
          _headerActionBtn(
            icon: Icons.copy_outlined,
            label: '复制',
            bg: const Color(0xFFFDF5E8),
            fg: const Color(0xFFD4A020),
            onTap: () => _showTransferCopyDialog(isTransfer: false, inventory: inventory),
          ),
        ],
      ],
    );
  }

  Widget _headerActionBtn({required IconData icon, required String label, required Color bg, required Color fg, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg)),
          ],
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(List<InventoryRecord> inventory) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 32, color: _hintColor),
          const SizedBox(height: 12),
          Text(
            inventory.isEmpty ? '暂无匹配的 SKU' : _filterEmptyMessage(),
            style: const TextStyle(fontSize: 13, color: _hintColor),
          ),
          if (inventory.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() { _stockFilter = 'all'; _statusFilter = 'all'; }),
              child: Text('清除筛选', style: TextStyle(fontSize: 12, color: _primary.withValues(alpha: 0.7))),
            ),
          ],
        ],
      ),
    );
  }

  // ── 筛选逻辑 ──────────────────────────────────────────────────────────────────

  bool _isPending(InventoryRecord r) =>
      r.pendingCount ||
      r.stockStatus == 'pending_count' ||
      r.stockStatus == 'temporary' ||
      r.quantityUnknown;

  bool _matchesStockFilter(InventoryRecord r) {
    final qty = r.totalQty;
    // 箱数用 totalBoxes：当库存存在 configurations 里时，根节点 boxes 为 0
    final boxes = r.totalBoxes;
    return switch (_stockFilter) {
      'has_stock' =>
        // 有库存：数量>0，待清点，或仅箱数记录有箱数
        qty > 0 || r.quantityUnknown || (r.boxesOnlyMode && boxes > 0),
      'zero_stock' =>
        // 0库存：数量=0 且非待清点 且非仅箱数有箱数
        qty == 0 && !r.quantityUnknown && !(r.boxesOnlyMode && boxes > 0),
      _ => true, // 'all'
    };
  }

  bool _matchesStatusFilter(InventoryRecord r) {
    final pending = _isPending(r);
    return switch (_statusFilter) {
      'normal'  => !pending,
      'pending' => pending,
      _ => true, // 'all'
    };
  }

  List<InventoryRecord> _filteredInventory(List<InventoryRecord> all) =>
      all.where((r) => _matchesStockFilter(r) && _matchesStatusFilter(r)).toList();

  String _filterEmptyMessage() {
    final stockLabel = switch (_stockFilter) {
      'has_stock'  => '有库存',
      'zero_stock' => '0库存',
      _ => '',
    };
    final statusLabel = switch (_statusFilter) {
      'normal'  => '正常',
      'pending' => '暂存',
      _ => '',
    };
    final parts = [stockLabel, statusLabel].where((s) => s.isNotEmpty).join(' + ');
    return parts.isEmpty
        ? '暂无库存 SKU'
        : '当前筛选「$parts」下暂无 SKU';
  }

  // ── Filter chips ────────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('库存:', style: TextStyle(fontSize: 10, color: _hintColor)),
          const SizedBox(width: 10),
          _filterChip(label: '全部',   selected: _stockFilter == 'all',        onTap: () => setState(() => _stockFilter = 'all')),
          const SizedBox(width: 8),
          _filterChip(label: '有库存', selected: _stockFilter == 'has_stock',   onTap: () => setState(() => _stockFilter = 'has_stock')),
          const SizedBox(width: 8),
          _filterChip(label: '0库存',  selected: _stockFilter == 'zero_stock',  onTap: () => setState(() => _stockFilter = 'zero_stock')),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Text('业务:', style: TextStyle(fontSize: 10, color: _hintColor)),
          const SizedBox(width: 10),
          _filterChip(label: '全部', selected: _statusFilter == 'all',     onTap: () => setState(() => _statusFilter = 'all')),
          const SizedBox(width: 8),
          _filterChip(label: '正常', selected: _statusFilter == 'normal',  onTap: () => setState(() => _statusFilter = 'normal')),
          const SizedBox(width: 8),
          _filterChip(label: '暂存', selected: _statusFilter == 'pending', onTap: () => setState(() => _statusFilter = 'pending')),
        ]),
      ],
    );
  }

  Widget _filterChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _primary.withValues(alpha: 0.08) : _bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: selected ? _primary : _mutedColor,
            ),
          ),
        ),
      ),
    );
  }

  // ── SKU card ────────────────────────────────────────────────────────────────

  Widget _buildSkuCard(InventoryRecord record, Map<String, dynamic> data, dynamic user) {
    final pending  = _isPending(record);
    final hasStock = record.quantityUnknown || record.totalQty > 0 || (record.boxesOnlyMode && record.boxes > 0);
    final dimmed   = !hasStock;

    Widget badge;
    if (pending) {
      badge = record.quantityUnknown
          ? _modeBadge('待清点', bg: const Color(0xFFF0E6FF), fg: const Color(0xFF7B5EA7))
          : _modeBadge('暂存',   bg: const Color(0xFFFFF0E0), fg: const Color(0xFFC07020));
    } else if (record.boxesOnlyMode) {
      badge = _modeBadge('仅箱数', bg: const Color(0xFFE8F0FF), fg: _primary);
    } else {
      badge = _modeBadge('按箱规', bg: const Color(0xFFEEF6EF), fg: const Color(0xFF5A9A6B));
    }

    String qtyLine;
    if (record.quantityUnknown) {
      qtyLine = '待补充库存信息';
    } else if (record.boxesOnlyMode) {
      qtyLine = '${record.boxes}箱 · 箱规待确认';
    } else {
      qtyLine = '${record.boxes}箱 · ${record.totalQty}件';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => InventoryDetailSheet(
              skuCode: record.skuCode,
              skuId: record.skuId,
              locationId: widget.id,
              locationCode: data['code'] ?? '',
              totalQty: record.totalQty,
              boxes: record.boxes,
              unitsPerBox: record.unitsPerBox,
              configurations: record.configurations,
              inventoryRecordId: record.id,
              showSkuNav: true,
              canEdit: user?.canEdit == true,
              canStockIn:  user?.can('inv:stock_in')  == true,
              canStockOut: user?.can('inv:stock_out') == true,
              canAdjust:   user?.can('inv:adjust')    == true,
              quantityUnknown: record.quantityUnknown,
              onChanged: _load,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.inventory_2_outlined, size: 14, color: _mutedColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            record.skuCode,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: dimmed ? _hintColor : _titleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          badge,
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        qtyLine,
                        style: TextStyle(fontSize: 12, color: dimmed ? const Color(0xFFD0D0D8) : _mutedColor),
                      ),
                    ],
                  ),
                ),
                if (user?.canEdit == true)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 18, color: _hintColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (v) async {
                      if (v == 'delete') {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定删除 ${data['code']} 中的\n${record.skuCode} 当前库存记录吗？\n此操作不可恢复。'),
                            actions: [
                              TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
                              FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => ctx.pop(true), child: const Text('删除')),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await _inventoryService.delete(record.id);
                          _load();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Colors.red), SizedBox(width: 8), Text('删除', style: TextStyle(color: Colors.red))])),
                    ],
                  )
                else
                  const Icon(Icons.chevron_right, size: 16, color: _hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _transferEmptyState({required bool isTransfer, required String srcCode}) {
    final iconBg = isTransfer ? const Color(0xFFE8F3FF) : const Color(0xFFFFF8ED);
    final iconColor = isTransfer ? const Color(0xFF4A6CF7) : const Color(0xFFD4A020);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(Icons.inbox_outlined, size: 22, color: iconColor),
          ),
          const SizedBox(height: 12),
          const Text('该库位暂无可操作的 SKU',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF8E8E9A))),
          const SizedBox(height: 6),
          Text('请确认库位 $srcCode 是否已录入库存，\n或联系管理员检查数据',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC5C5CE), height: 1.5)),
        ],
      ),
    );
  }

  Widget _modeBadge(String label, {required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  Future<void> _showTransferCopyDialog({
    required bool isTransfer,
    required List<InventoryRecord> inventory,
  }) async {
    final label = isTransfer ? '转移' : '复制';
    final srcCode = (_data?['code'] ?? '') as String;
    final accent = isTransfer ? const Color(0xFF4A9EFF) : const Color(0xFFD4A020);

    final searchCtrl = TextEditingController();
    // All selected by default
    Set<String> selectedSkus = inventory.map((r) => r.skuCode).toSet();
    Location? target;
    List<Location> searchResults = [];
    List<String> conflictSkus = [];
    String? resolution;
    bool searching = false;
    bool loadingTarget = false;
    bool saving = false;
    String? error;
    int step = 1; // 1=select SKUs, 2=choose location, 3=confirm

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // ── Step 1: SKU Selection ─────────────────────────────────────────
          Widget step1Content() {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inventory.length,
              itemBuilder: (_, i) {
                final r = inventory[i];
                final checked = selectedSkus.contains(r.skuCode);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setS(() {
                        if (checked) {
                          selectedSkus.remove(r.skuCode);
                        } else {
                          selectedSkus.add(r.skuCode);
                        }
                      }),
                      child: Container(
                        color: checked
                            ? accent.withValues(alpha: 0.06)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            // Custom square checkbox
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: checked
                                    ? accent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: checked
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFD0CEC9),
                                        width: 1.1),
                              ),
                              child: checked
                                  ? const Icon(Icons.check,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.skuCode,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A2E)),
                                  ),
                                  Text(
                                    _configText(r),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFFB5B5C0)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              r.qtyDisplay,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < inventory.length - 1)
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF5F4F2), indent: 20, endIndent: 20),
                  ],
                );
              },
            );
          }

          // ── Step 2: Location Search ───────────────────────────────────────
          Widget step2Content() {
            final createColor = isTransfer ? const Color(0xFF4A9EFF) : Colors.green.shade700;
            final createBg = isTransfer ? const Color(0xFFE8F3FF) : Colors.green.shade50;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '已选 ${selectedSkus.length} 种 SKU，请选择目标库位',
                    style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                // Custom search input
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFEAE8E4), width: 1.2),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                    decoration: InputDecoration(
                      hintText: '输入库位编码...',
                      hintStyle: const TextStyle(color: Color(0xFFC5C5CE), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFFB5B5C0)),
                      suffixIcon: searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                          : searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setS(() { searchCtrl.clear(); searchResults = []; }),
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFFB5B5C0)),
                                )
                              : null,
                    ),
                    onChanged: (v) async {
                      if (v.isEmpty) {
                        setS(() => searchResults = []);
                        return;
                      }
                      setS(() => searching = true);
                      try {
                        final res = await _locationService.getAll(search: v);
                        if (ctx.mounted) {
                          setS(() {
                            searchResults = res.where((l) => l.id != widget.id).toList();
                            searching = false;
                          });
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          setS(() => searching = false);
                        }
                      }
                    },
                  ),
                ),
                // Empty state
                if (searchCtrl.text.isEmpty && searchResults.isEmpty && !loadingTarget && !searching) ...[
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.search, size: 28, color: Color(0xFFD0CEC9)),
                        SizedBox(height: 10),
                        Text('输入库位编码以搜索目标位置',
                            style: TextStyle(color: Color(0xFFB5B5C0), fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                if (loadingTarget) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 20),
                ],
                // Search results
                if (searchResults.isNotEmpty && !loadingTarget)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0EFEC)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: searchResults.take(8).map((l) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          setS(() { target = l; searchResults = []; loadingTarget = true; error = null; });
                          try {
                            final tgtData = await _locationService.getOne(l.id);
                            final tInv = ((tgtData['inventory'] as List?) ?? [])
                                .map((e) => InventoryRecord.fromJson(e))
                                .toList();
                            final tCodes = tInv.map((r) => r.skuCode).toSet();
                            setS(() {
                              conflictSkus = selectedSkus.intersection(tCodes).toList();
                              resolution = null;
                              loadingTarget = false;
                              step = 3;
                            });
                          } catch (e) {
                            setS(() { loadingTarget = false; error = '加载目标库位失败'; });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A2E))),
                                    if (l.description != null)
                                      Text(l.description!, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E9A))),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                // 新建库位
                if (searchCtrl.text.trim().isNotEmpty &&
                    !searching &&
                    !loadingTarget &&
                    (searchResults.isEmpty ||
                        searchResults.every((l) =>
                            l.code.toUpperCase() != searchCtrl.text.trim().toUpperCase()))) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final code = searchCtrl.text.trim().toUpperCase();
                      setS(() { loadingTarget = true; error = null; });
                      try {
                        final newLoc = await _locationService.create(code: code);
                        setS(() {
                          target = newLoc;
                          searchResults = [];
                          conflictSkus = [];
                          resolution = null;
                          loadingTarget = false;
                          step = 3;
                        });
                      } catch (e) {
                        setS(() { loadingTarget = false; error = '创建库位失败: $e'; });
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: createBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sync, size: 16, color: createColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '新建库位 "${searchCtrl.text.trim().toUpperCase()}" 并$label到此',
                              style: TextStyle(color: createColor, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            );
          }

          // ── Step 3: Confirm ───────────────────────────────────────────────
          Widget step3Content() {
            final selectedInventory = inventory
                .where((r) => selectedSkus.contains(r.skuCode))
                .toList();
            final noConflict = selectedInventory
                .where((r) => !conflictSkus.contains(r.skuCode))
                .toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          isTransfer
                              ? Icons.swap_horiz
                              : Icons.copy_outlined,
                          size: 18,
                          color: accent),
                      const SizedBox(width: 8),
                      Text(
                        '$srcCode  →  ${target!.code}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: accent),
                      ),
                      const Spacer(),
                      Text('${selectedSkus.length} 种 SKU',
                          style:
                              TextStyle(fontSize: 12, color: accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                if (conflictSkus.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 15, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '目标库位已有 ${conflictSkus.length} 种相同 SKU，请选择处理方式：',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: conflictSkus
                              .map((s) => Chip(
                                    label: Text(s,
                                        style: const TextStyle(
                                            fontSize: 11)),
                                    visualDensity:
                                        VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor:
                                        Colors.red.shade100,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        if (isTransfer) ...[
                          _resolutionTile(
                              '合并',
                              'merge',
                              '将来源库存合并到目标已有库存中',
                              resolution,
                              (v) => setS(() => resolution = v)),
                          _resolutionTile(
                              '覆盖',
                              'overwrite',
                              '用来源库存替换目标已有库存',
                              resolution,
                              (v) => setS(() => resolution = v)),
                        ] else ...[
                          _resolutionTile(
                              '叠加',
                              'stack',
                              '将来源库存叠加到目标已有库存中',
                              resolution,
                              (v) => setS(() => resolution = v)),
                          _resolutionTile(
                              '覆盖',
                              'overwrite',
                              '用来源库存替换目标已有库存',
                              resolution,
                              (v) => setS(() => resolution = v)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (noConflict.isNotEmpty) ...[
                  Text(
                    '无冲突 SKU（${noConflict.length} 种，将直接$label）：',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: noConflict
                        .map((r) => Chip(
                              label: Text('${r.skuCode} · ${r.qtyDisplay}',
                                  style:
                                      const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                if (isTransfer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Colors.amber.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 15, color: Colors.amber),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '转移完成后，原库位对应的 SKU 库存数据将被删除。',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ],
              ],
            );
          }

          // ── Cancel / Back callback ───────────────────────────────────
          void onBack() {
            if (saving) return;
            if (step == 1) {
              ctx.pop();
            } else if (step == 2) {
              setS(() { step = 1; error = null; searchCtrl.clear(); searchResults = []; });
            } else {
              setS(() { step = 2; target = null; conflictSkus = []; resolution = null; error = null; searchCtrl.clear(); searchResults = []; });
            }
          }

          // ── Next / Confirm callback ──────────────────────────────────
          Future<void> onNext() async {
            if (step == 1) {
              if (selectedSkus.isNotEmpty) setS(() => step = 2);
              return;
            }
            if (step != 3) return;
            if (conflictSkus.isNotEmpty && resolution == null) return;
            setS(() { saving = true; error = null; });
            try {
              final Map<String, dynamic> result;
              final tgtCode = target!.code;
              if (isTransfer) {
                result = await _locationService.transfer(sourceId: widget.id, targetLocationId: target!.id, skuCodes: selectedSkus.toList(), conflictResolution: resolution);
              } else {
                result = await _locationService.copy(sourceId: widget.id, targetLocationId: target!.id, skuCodes: selectedSkus.toList(), conflictResolution: resolution);
              }
              if (ctx.mounted) ctx.pop();
              _load();
              if (mounted) _showOperationResultDialog(isTransfer: isTransfer, result: result, targetCode: tgtCode);
            } catch (e) {
              setS(() { saving = false; error = '$label失败: $e'; });
            }
          }

          final bool nextEnabled = step == 1
              ? selectedSkus.isNotEmpty
              : step == 3
                  ? !saving && (conflictSkus.isEmpty || resolution != null)
                  : false;

          // ── Figma-style Dialog ────────────────────────────────────────
          final iconBg = isTransfer ? const Color(0xFFE8F3FF) : const Color(0xFFFFF8ED);
          final iconColor = isTransfer ? const Color(0xFF4A6CF7) : const Color(0xFFD4A020);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 60, offset: Offset(0, 20))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                              child: Icon(isTransfer ? Icons.swap_horiz : Icons.copy_outlined, size: 15, color: iconColor),
                            ),
                            const SizedBox(width: 10),
                            Text('批量$label库存', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                          ],
                        ),
                        if (step == 1) ...[
                          const SizedBox(height: 10),
                          // Pill subtitle
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isTransfer
                                  ? const Color(0xFFE8F3FF)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '选择要$label的 SKU（来源：$srcCode）',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isTransfer
                                    ? const Color(0xFF4A9EFF)
                                    : const Color(0xFFD4A020),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Info row with toggle button
                          Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text:
                                          '${inventory.length} 种 SKU · ',
                                      style: const TextStyle(
                                          color: Color(0xFF5A5A6E)),
                                    ),
                                    TextSpan(
                                      text:
                                          '已选 ${selectedSkus.length} 种',
                                      style: TextStyle(
                                        color: selectedSkus.isEmpty
                                            ? const Color(0xFFB5B5C0)
                                            : accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setS(() {
                                  if (selectedSkus.length ==
                                      inventory.length) {
                                    selectedSkus = {};
                                  } else {
                                    selectedSkus = inventory
                                        .map((r) => r.skuCode)
                                        .toSet();
                                  }
                                }),
                                child: Text(
                                  selectedSkus.length == inventory.length
                                      ? '取消全选'
                                      : '全选',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: accent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ] else
                          const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  // Full-width divider
                  const Divider(height: 1, color: Color(0xFFF0EFEC)),
                  // Content
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      padding: step == 1
                          ? EdgeInsets.zero
                          : const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: switch (step) {
                        1 => inventory.isEmpty
                            ? _transferEmptyState(isTransfer: isTransfer, srcCode: srcCode)
                            : step1Content(),
                        2 => step2Content(),
                        _ => step3Content(),
                      },
                    ),
                  ),
                  // Footer
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFF0EFEC))),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onBack,
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: step == 1
                              ? const Text('取消',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF8E8E9A)))
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.arrow_back, size: 15, color: Color(0xFF8E8E9A)),
                                    SizedBox(width: 4),
                                    Text('返回', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF8E8E9A))),
                                  ],
                                ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: nextEnabled ? onNext : null,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: nextEnabled ? accent : const Color(0xFFD4D2CE),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: nextEnabled
                                    ? [BoxShadow(
                                        color: accent.withValues(alpha: 0.28),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6))]
                                    : null,
                              ),
                              child: Center(
                                child: saving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(
                                        step == 3
                                            ? '确认$label ${selectedSkus.length} 种'
                                            : step == 1
                                                ? (selectedSkus.isEmpty
                                                    ? '下一步'
                                                    : '下一步（已选 ${selectedSkus.length} 种）')
                                                : '确认$label',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    searchCtrl.dispose();
  }

  String _configText(InventoryRecord r) {
    if (r.configurations.isNotEmpty) {
      return r.configurations
          .map((c) => '${c.boxes}箱 × ${c.unitsPerBox}件/箱')
          .join(' + ');
    }
    return '${r.boxes}箱 × ${r.unitsPerBox}件/箱';
  }

  Future<void> _showOperationResultDialog({
    required bool isTransfer,
    required Map<String, dynamic> result,
    required String targetCode,
  }) async {
    final label = isTransfer ? '转移' : '复制';
    final srcCode = (_data?['code'] ?? '') as String;
    List<String> toList(dynamic v) =>
        v == null ? [] : List<String>.from(v as List);

    final direct = isTransfer ? toList(result['moved']) : toList(result['copied']);
    final merged = isTransfer ? toList(result['merged']) : toList(result['stacked']);
    final overwritten = toList(result['overwritten']);
    final mergeLabel = isTransfer ? '合并' : '叠加';
    final total = direct.length + merged.length + overwritten.length;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle,
                color: isTransfer ? Colors.blue : Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text('$label完成'),
          ],
        ),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTransfer ? Colors.blue.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$srcCode → $targetCode，共 $total 种 SKU',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isTransfer
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
                if (direct.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _resultSection('直接$label', direct, Colors.green.shade700),
                ],
                if (merged.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _resultSection(mergeLabel, merged, Colors.blue.shade700),
                ],
                if (overwritten.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _resultSection('覆盖', overwritten, Colors.red.shade700),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => ctx.pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _resultSection(String title, List<String> skus, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$title（${skus.length} 种）',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: skus
              .map((s) => Chip(
                    label:
                        Text(s, style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: color.withValues(alpha: 0.12),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _resolutionTile(
    String title,
    String value,
    String subtitle,
    String? groupValue,
    void Function(String) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: (v) => onChanged(v!),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

}
