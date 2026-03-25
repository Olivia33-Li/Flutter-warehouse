import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/inventory_service.dart';
import '../../services/sku_service.dart';
import '../../models/inventory.dart';
import '../../models/location.dart';
import '../../widgets/error_view.dart';
import '../../widgets/inventory_detail_sheet.dart';

class LocationDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const LocationDetailScreen({super.key, required this.id});

  @override
  ConsumerState<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends ConsumerState<LocationDetailScreen> {
  final _locationService = LocationService();
  final _inventoryService = InventoryService();
  Map<String, dynamic>? _data;
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
    final boxesCtrl = TextEditingController(text: existing?.boxes.toString() ?? '');
    final unitsCtrl = TextEditingController(text: existing?.unitsPerBox.toString() ?? '1');
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? '新增库存' : '编辑库存'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (existing == null)
                DropdownButtonFormField<String>(
                  value: selectedSkuCode,
                  decoration: const InputDecoration(
                      labelText: 'SKU', border: OutlineInputBorder()),
                  items: skus
                      .map((s) => DropdownMenuItem(value: s.sku, child: Text(s.sku)))
                      .toList(),
                  onChanged: (v) => selectedSkuCode = v,
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('SKU', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  subtitle: Text(existing.skuCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: boxesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '箱数', border: OutlineInputBorder(), suffixText: '箱'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: unitsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '每箱数量', border: OutlineInputBorder(), suffixText: '件/箱'),
              ),
              if (dialogError != null) ...[
                const SizedBox(height: 8),
                Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: () async {
                final boxes = int.tryParse(boxesCtrl.text) ?? 0;
                final unitsPerBox = int.tryParse(unitsCtrl.text) ?? 0;
                if (boxes <= 0 || unitsPerBox <= 0) {
                  setS(() => dialogError = '请输入有效的箱数和每箱数量');
                  return;
                }
                if (selectedSkuCode == null) {
                  setS(() => dialogError = '请选择 SKU');
                  return;
                }
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
              child: const Text('保存'),
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
                  if (data['lastInventoryChangedAt'] != null) ...[
                    const Divider(),
                    _info('最后变更', _formatDate(data['lastInventoryChangedAt'])),
                  ],
                  const Divider(),
                  // 已检查开关
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text('已检查',
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                  if (data['lastCheckedAt'] != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 80),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 13, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(data['lastCheckedAt']),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (data['lastCheckedBy'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person_outline,
                                            size: 13, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          data['lastCheckedBy'],
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    onChanged: _load,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${record.totalQty}件',
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

    final searchCtrl = TextEditingController();
    Location? target;
    List<Location> searchResults = [];
    List<String> conflictSkus = [];
    String? resolution; // merge/overwrite for transfer; overwrite/stack for copy
    bool searching = false;
    bool loadingTarget = false;
    bool saving = false;
    String? error;
    bool showConfirm = false; // step 1=select, step 2=confirm

    await showDialog(
      context: context,
      barrierDismissible: !saving,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Widget step1Content() => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('将 $srcCode 的库存批量$label到目标库位',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 12),
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
                        if (ctx.mounted)
                          setS(() {
                            searchResults =
                                res.where((l) => l.id != widget.id).toList();
                            searching = false;
                          });
                      } catch (_) {
                        if (ctx.mounted) setS(() => searching = false);
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
                        border: Border.all(color: Colors.grey.shade300),
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
                                      final data = await _locationService
                                          .getOne(l.id);
                                      final tInv = ((data['inventory']
                                                  as List?) ??
                                              [])
                                          .map((e) =>
                                              InventoryRecord.fromJson(e))
                                          .toList();
                                      final srcCodes = inventory
                                          .map((r) => r.skuCode)
                                          .toSet();
                                      final tCodes = tInv
                                          .map((r) => r.skuCode)
                                          .toSet();
                                      setS(() {
                                        conflictSkus = srcCodes
                                            .intersection(tCodes)
                                            .toList();
                                        resolution = null;
                                        loadingTarget = false;
                                        showConfirm = true;
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
                  // 新建库位选项：输入内容不为空且搜索结束后显示
                  if (searchCtrl.text.trim().isNotEmpty && !searching && !loadingTarget &&
                      (searchResults.isEmpty ||
                          searchResults.every((l) =>
                              l.code.toUpperCase() !=
                              searchCtrl.text.trim().toUpperCase()))) ...[
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
                            showConfirm = true;
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
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_location_alt_outlined,
                                size: 16, color: Colors.green.shade700),
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

          Widget step2Content() {
            final noConflict =
                inventory.where((r) => !conflictSkus.contains(r.skuCode));

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isTransfer
                        ? Colors.blue.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          isTransfer
                              ? Icons.swap_horiz
                              : Icons.copy_outlined,
                          size: 18,
                          color: isTransfer
                              ? Colors.blue.shade700
                              : Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '$srcCode  →  ${target!.code}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isTransfer
                                ? Colors.blue.shade700
                                : Colors.orange.shade700),
                      ),
                      const Spacer(),
                      Text(
                        '${inventory.length} 种 SKU',
                        style: TextStyle(
                            fontSize: 12,
                            color: isTransfer
                                ? Colors.blue.shade600
                                : Colors.orange.shade600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Conflict section
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
                            Text(
                              '目标库位已有 ${conflictSkus.length} 种相同 SKU，请选择处理方式：',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: conflictSkus
                              .map((s) => Chip(
                                    label: Text(s,
                                        style:
                                            const TextStyle(fontSize: 11)),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: Colors.red.shade100,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        // Resolution radio buttons
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

                // No-conflict SKUs
                if (noConflict.isNotEmpty) ...[
                  Text(
                    '无冲突 SKU（${noConflict.length} 种，将直接$label）：',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: noConflict
                        .map((r) => Chip(
                              label: Text('${r.skuCode} · ${r.totalQty}件',
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Transfer warning
                if (isTransfer)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 6),
                        const Expanded(
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
                    isTransfer ? Icons.swap_horiz : Icons.copy_outlined,
                    size: 20,
                    color: isTransfer ? Colors.blue : Colors.orange),
                const SizedBox(width: 8),
                Text('批量$label库存'),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: showConfirm ? step2Content() : step1Content(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () {
                        if (showConfirm) {
                          setS(() {
                            showConfirm = false;
                            target = null;
                            conflictSkus = [];
                            resolution = null;
                            error = null;
                          });
                        } else {
                          ctx.pop();
                        }
                      },
                child: Text(showConfirm ? '← 返回' : '取消'),
              ),
              if (showConfirm)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isTransfer ? Colors.blue : Colors.orange,
                  ),
                  onPressed: saving ||
                          (conflictSkus.isNotEmpty && resolution == null)
                      ? null
                      : () async {
                          setS(() { saving = true; error = null; });
                          try {
                            final Map<String, dynamic> result;
                            final tgtCode = target!.code;
                            if (isTransfer) {
                              result = await _locationService.transfer(
                                sourceId: widget.id,
                                targetLocationId: target!.id,
                                conflictResolution: resolution,
                              );
                            } else {
                              result = await _locationService.copy(
                                sourceId: widget.id,
                                targetLocationId: target!.id,
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
                              strokeWidth: 2, color: Colors.white))
                      : Text('确认$label'),
                ),
            ],
          );
        },
      ),
    );

    searchCtrl.dispose();
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
