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
    bool byCarton = true;
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

                  // ── Mode toggle + 待清点 (create only) ────────────────
                  if (existing == null) ...[
                    CheckboxListTile(
                      value: isPending,
                      onChanged: (v) => setS(() => isPending = v ?? false),
                      title: const Text('暂存 / 待清点',
                          style: TextStyle(fontSize: 14)),
                      subtitle: const Text('货已到位，数量暂未确认',
                          style: TextStyle(fontSize: 12)),
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
                    if (!isPending) ...[
                      const SizedBox(height: 8),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                              value: true,
                              label: Text('按箱规'),
                              icon: Icon(Icons.inventory_2_outlined)),
                          ButtonSegment(
                              value: false,
                              label: Text('按总数量'),
                              icon: Icon(Icons.format_list_numbered)),
                        ],
                        selected: {byCarton},
                        onSelectionChanged: (s) =>
                            setS(() => byCarton = s.first),
                        style: const ButtonStyle(
                            visualDensity: VisualDensity.compact),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border:
                              Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '将创建"待清点"记录，数量不计入合计，后续可通过调整确认。',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],

                  // ── Quantity fields (hidden when pending or editing) ──
                  if (!isPending) ...[
                    if (existing != null || byCarton) ...[
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
                int boxes, unitsPerBox;
                if (isPending) {
                  boxes = 0;
                  unitsPerBox = 1;
                } else if (existing != null || byCarton) {
                  boxes = int.tryParse(boxesCtrl.text) ?? 0;
                  unitsPerBox = int.tryParse(unitsCtrl.text) ?? 0;
                  if (boxes <= 0 || unitsPerBox <= 0) {
                    setS(() => dialogError = '请输入有效的箱数和每箱件数');
                    return;
                  }
                } else {
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
                    );
                  }
                  if (ctx.mounted) ctx.pop();
                  _load();
                } catch (e) {
                  if (ctx.mounted) {
                    setS(() => dialogError = '操作失败: $e');
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: ErrorView(message: _error!, onRetry: _load));

    final data = _data!;
    final inventory = (data['inventory'] as List?)
        ?.map((e) => InventoryRecord.fromJson(e))
        .toList() ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(data['code'] ?? '')),
      floatingActionButton: user?.canEdit == true
          ? FloatingActionButton(
              onPressed: _showInventoryDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info('位置代码', data['code']),
                  if (data['description'] != null)
                    _info('描述', data['description']),
                  const Divider(),
                  _info('SKU 种类', '${data['skuCount'] ?? 0}'),
                  _info('总库存', '${data['totalQty'] ?? 0} 件'),
                  const Divider(),
                  // 已检查开关
                  Row(
                    children: [
                      const SizedBox(
                        width: 80,
                        child: Text('已检查',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                      Switch(
                        value: data['checked'] == true,
                        onChanged: (val) async {
                          await _locationService.check(widget.id, checked: val);
                          _load();
                        },
                      ),
                    ],
                  ),
                  // 上次检查
                  _traceRow(
                    label: '上次检查',
                    record: _latestCheck,
                    emptyText: '无检查记录',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                  const SizedBox(height: 4),
                  // 上次变更
                  _traceRow(
                    label: '上次变更',
                    record: _latestOp,
                    emptyText: '无变更记录',
                    icon: Icons.edit_outlined,
                    iconColor: Colors.blue,
                  ),
                  // Changed-after-check warning
                  if (() {
                    final changedAt = data['lastInventoryChangedAt'] as String?;
                    final checkedAt = data['lastCheckedAt'] as String?;
                    if (changedAt == null || checkedAt == null) return false;
                    final changed = DateTime.tryParse(changedAt);
                    final checked = DateTime.tryParse(checkedAt);
                    return changed != null && checked != null && changed.isAfter(checked);
                  }()) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_outlined,
                              size: 14, color: Colors.orange.shade700),
                          const SizedBox(width: 6),
                          Text('检查后库存已变更',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('库存 SKU (${inventory.length})',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (inventory.isNotEmpty && user?.canEdit == true) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('转移', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showTransferCopyDialog(
                      isTransfer: true, inventory: inventory),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('复制', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _showTransferCopyDialog(
                      isTransfer: false, inventory: inventory),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...inventory.map((record) {
            return Card(
              child: ListTile(
                title: Text(record.skuCode,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: record.skuName != null ? Text(record.skuName!) : null,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
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
                    quantityUnknown: record.quantityUnknown,
                    onChanged: _load,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(record.qtyDisplay,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (user?.canEdit == true)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('确认删除'),
                              content: Text(
                                '确定删除 ${data['code']} 中的\n${record.skuCode} 当前库存记录吗？\n此操作不可恢复。'),
                              actions: [
                                TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => ctx.pop(true),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await _inventoryService.delete(record.id);
                            _load();
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showTransferCopyDialog({
    required bool isTransfer,
    required List<InventoryRecord> inventory,
  }) async {
    final label = isTransfer ? '转移' : '复制';
    final srcCode = (_data?['code'] ?? '') as String;
    final accent = isTransfer ? Colors.blue : Colors.orange;

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
            final allSelected = selectedSkus.length == inventory.length;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择要$label的 SKU（来源：$srcCode）',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${inventory.length} 种 SKU · 已选 ${selectedSkus.length} 种',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setS(() {
                        if (allSelected) {
                          selectedSkus = {};
                        } else {
                          selectedSkus =
                              inventory.map((r) => r.skuCode).toSet();
                        }
                      }),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        allSelected ? '取消全选' : '全选',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: inventory.length,
                    itemBuilder: (_, i) {
                      final r = inventory[i];
                      final checked = selectedSkus.contains(r.skuCode);
                      return InkWell(
                        onTap: () => setS(() {
                          if (checked) {
                            selectedSkus.remove(r.skuCode);
                          } else {
                            selectedSkus.add(r.skuCode);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 2),
                          child: Row(
                            children: [
                              Checkbox(
                                value: checked,
                                onChanged: (v) => setS(() {
                                  if (v == true) {
                                    selectedSkus.add(r.skuCode);
                                  } else {
                                    selectedSkus.remove(r.skuCode);
                                  }
                                }),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.skuCode,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: checked
                                            ? null
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    Text(
                                      _configText(r),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: checked
                                            ? Colors.grey.shade600
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                r.qtyDisplay,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: checked
                                      ? null
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          // ── Step 2: Location Search ───────────────────────────────────────
          Widget step2Content() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '已选 ${selectedSkus.length} 种 SKU，请选择目标库位',
                      style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: '搜索库位编号...',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: searching
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)))
                          : null,
                    ),
                    onChanged: (v) async {
                      if (v.isEmpty) {
                        setS(() => searchResults = []);
                        return;
                      }
                      setS(() => searching = true);
                      try {
                        final res =
                            await _locationService.getAll(search: v);
                        if (ctx.mounted) {
                          setS(() {
                            searchResults = res
                                .where((l) => l.id != widget.id)
                                .toList();
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
                  if (loadingTarget) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (searchResults.isNotEmpty && !loadingTarget)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: searchResults
                            .take(8)
                            .map((l) => ListTile(
                                  dense: true,
                                  title: Text(l.code),
                                  subtitle: l.description != null
                                      ? Text(l.description!)
                                      : null,
                                  onTap: () async {
                                    setS(() {
                                      target = l;
                                      searchResults = [];
                                      loadingTarget = true;
                                      error = null;
                                    });
                                    try {
                                      final tgtData =
                                          await _locationService
                                              .getOne(l.id);
                                      final tInv = ((tgtData[
                                                      'inventory']
                                                  as List?) ??
                                              [])
                                          .map((e) =>
                                              InventoryRecord
                                                  .fromJson(e))
                                          .toList();
                                      final tCodes = tInv
                                          .map((r) => r.skuCode)
                                          .toSet();
                                      setS(() {
                                        conflictSkus = selectedSkus
                                            .intersection(tCodes)
                                            .toList();
                                        resolution = null;
                                        loadingTarget = false;
                                        step = 3;
                                      });
                                    } catch (e) {
                                      setS(() {
                                        loadingTarget = false;
                                        error = '加载目标库位失败';
                                      });
                                    }
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  // 新建库位
                  if (searchCtrl.text.trim().isNotEmpty &&
                      !searching &&
                      !loadingTarget &&
                      (searchResults.isEmpty ||
                          searchResults.every((l) =>
                              l.code.toUpperCase() !=
                              searchCtrl.text
                                  .trim()
                                  .toUpperCase()))) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final code =
                            searchCtrl.text.trim().toUpperCase();
                        setS(() {
                          loadingTarget = true;
                          error = null;
                        });
                        try {
                          final newLoc =
                              await _locationService.create(code: code);
                          setS(() {
                            target = newLoc;
                            searchResults = [];
                            conflictSkus = [];
                            resolution = null;
                            loadingTarget = false;
                            step = 3;
                          });
                        } catch (e) {
                          setS(() {
                            loadingTarget = false;
                            error = '创建库位失败: $e';
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_location_alt_outlined,
                                size: 16,
                                color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '新建库位 "${searchCtrl.text.trim().toUpperCase()}" 并$label到此',
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13)),
                  ],
                ],
              );

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

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                    isTransfer
                        ? Icons.swap_horiz
                        : Icons.copy_outlined,
                    size: 20,
                    color: accent),
                const SizedBox(width: 8),
                Text('批量$label库存'),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: switch (step) {
                  1 => step1Content(),
                  2 => step2Content(),
                  _ => step3Content(),
                },
              ),
            ),
            actions: [
              // ── Left: Cancel / Back ──────────────────────────────────
              TextButton(
                onPressed: saving
                    ? null
                    : () {
                        if (step == 1) {
                          ctx.pop();
                        } else if (step == 2) {
                          setS(() {
                            step = 1;
                            error = null;
                            searchCtrl.clear();
                            searchResults = [];
                          });
                        } else {
                          setS(() {
                            step = 2;
                            target = null;
                            conflictSkus = [];
                            resolution = null;
                            error = null;
                            searchCtrl.clear();
                            searchResults = [];
                          });
                        }
                      },
                child: Text(step == 1 ? '取消' : '← 返回'),
              ),

              // ── Step 1: Next button ───────────────────────────────────
              if (step == 1)
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: accent),
                  onPressed: selectedSkus.isEmpty
                      ? null
                      : () => setS(() => step = 2),
                  child:
                      Text('下一步（已选 ${selectedSkus.length} 种）'),
                ),

              // ── Step 3: Confirm button ────────────────────────────────
              if (step == 3)
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: accent),
                  onPressed: saving ||
                          (conflictSkus.isNotEmpty &&
                              resolution == null)
                      ? null
                      : () async {
                          setS(() {
                            saving = true;
                            error = null;
                          });
                          try {
                            final Map<String, dynamic> result;
                            final tgtCode = target!.code;
                            if (isTransfer) {
                              result = await _locationService.transfer(
                                sourceId: widget.id,
                                targetLocationId: target!.id,
                                skuCodes: selectedSkus.toList(),
                                conflictResolution: resolution,
                              );
                            } else {
                              result = await _locationService.copy(
                                sourceId: widget.id,
                                targetLocationId: target!.id,
                                skuCodes: selectedSkus.toList(),
                                conflictResolution: resolution,
                              );
                            }
                            if (ctx.mounted) ctx.pop();
                            _load();
                            if (mounted) {
                              _showOperationResultDialog(
                                isTransfer: isTransfer,
                                result: result,
                                targetCode: tgtCode,
                              );
                            }
                          } catch (e) {
                            setS(() {
                              saving = false;
                              error = '$label失败: $e';
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : Text('确认$label ${selectedSkus.length} 种'),
                ),
            ],
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

  Widget _traceRow({
    required String label,
    required ChangeRecord? record,
    required String emptyText,
    required IconData icon,
    required Color iconColor,
  }) {
    final (fg, bg, _) = record != null
        ? AuditLogDetailSheet.badgeStyle(record)
        : (Colors.grey.shade500, Colors.grey.shade100, Icons.history);
    final badgeLabel = record != null ? AuditLogDetailSheet.badgeLabel(record) : null;

    return InkWell(
      onTap: record != null ? () => AuditLogDetailSheet.show(context, record) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
              child: record == null
                  ? Text(emptyText,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(icon, size: 13, color: iconColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_formatDate(record.createdAt.toIso8601String())}  ·  ${record.userName}',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (badgeLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(badgeLabel,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: fg)),
                          ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right,
                            size: 14, color: Colors.grey.shade400),
                      ],
                    ),
            ),
          ],
        ),
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

  Widget _info(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            Expanded(
                child: Text(value ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );
}
