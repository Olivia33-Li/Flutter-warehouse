import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../services/sku_service.dart';
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import '../../models/inventory.dart';
import '../../models/location.dart';
import '../../widgets/error_view.dart';
import '../../widgets/inventory_detail_sheet.dart';

class SkuDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const SkuDetailScreen({super.key, required this.id});

  @override
  ConsumerState<SkuDetailScreen> createState() => _SkuDetailScreenState();
}

class _SkuDetailScreenState extends ConsumerState<SkuDetailScreen> {
  final _skuService = SkuService();
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
      _data = await _skuService.getOne(widget.id);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showInventoryDialog({InventoryRecord? existing}) async {
    final locSearchCtrl = TextEditingController();
    final boxesCtrl = TextEditingController(text: existing?.boxes.toString() ?? '');
    final unitsCtrl = TextEditingController(
      text: existing?.unitsPerBox.toString() ??
          (_data?['cartonQty']?.toString() ?? '1'),
    );
    final newLocCodeCtrl = TextEditingController();
    final newLocDescCtrl = TextEditingController();

    String? selectedLocationId = existing?.locationId is Map
        ? existing!.locationId['_id']
        : existing?.locationId?.toString();
    String? selectedLocationCode = existing?.locationId is Map
        ? existing!.locationId['code']
        : null;

    List<Location> locResults = [];
    bool isNewLoc = false;
    bool locSearching = false;
    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          Future<void> searchLocs(String q) async {
            if (q.isEmpty) { setS(() => locResults = []); return; }
            setS(() => locSearching = true);
            try {
              locResults = await LocationService().getAll(search: q);
            } finally {
              if (ctx.mounted) setS(() => locSearching = false);
            }
          }

          return AlertDialog(
            title: Text(existing == null ? '添加库位库存' : '编辑库存'),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 库位选择
                    Row(
                      children: [
                        const Text('库位', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (!isNewLoc)
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('新建库位'),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            onPressed: () => setS(() {
                              isNewLoc = true;
                              selectedLocationId = null;
                              selectedLocationCode = null;
                              locSearchCtrl.clear();
                              locResults = [];
                            }),
                          ),
                        if (isNewLoc)
                          TextButton.icon(
                            icon: const Icon(Icons.search, size: 14),
                            label: const Text('搜索已有'),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            onPressed: () => setS(() {
                              isNewLoc = false;
                              newLocCodeCtrl.clear();
                              newLocDescCtrl.clear();
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (!isNewLoc) ...[
                      // 已选中显示
                      if (selectedLocationId != null)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(selectedLocationCode ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setS(() {
                              selectedLocationId = null;
                              selectedLocationCode = null;
                            }),
                          ),
                        )
                      else ...[
                        TextField(
                          controller: locSearchCtrl,
                          decoration: InputDecoration(
                            hintText: '输入库位编号搜索',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: locSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(width: 14, height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2)))
                                : null,
                          ),
                          onChanged: (v) => searchLocs(v),
                        ),
                        if (locResults.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                ...locResults.take(5).map((l) => ListTile(
                                      dense: true,
                                      title: Text(l.code),
                                      subtitle: l.description != null ? Text(l.description!) : null,
                                      onTap: () => setS(() {
                                        selectedLocationId = l.id;
                                        selectedLocationCode = l.code;
                                        locSearchCtrl.clear();
                                        locResults = [];
                                      }),
                                    )),
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.add_circle_outline,
                                      color: Colors.blue, size: 18),
                                  title: Text('新建 "${locSearchCtrl.text}"',
                                      style: const TextStyle(color: Colors.blue, fontSize: 13)),
                                  onTap: () => setS(() {
                                    isNewLoc = true;
                                    newLocCodeCtrl.text = locSearchCtrl.text;
                                    locResults = [];
                                  }),
                                ),
                              ],
                            ),
                          ),
                        if (locResults.isEmpty &&
                            locSearchCtrl.text.isNotEmpty &&
                            !locSearching)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: GestureDetector(
                              onTap: () => setS(() {
                                isNewLoc = true;
                                newLocCodeCtrl.text = locSearchCtrl.text;
                              }),
                              child: Text('未找到，点击新建 "${locSearchCtrl.text}"',
                                  style: const TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontSize: 13)),
                            ),
                          ),
                      ],
                    ],

                    // 新建库位表单
                    if (isNewLoc) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: newLocCodeCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: '库位编号 *',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: newLocDescCtrl,
                              decoration: const InputDecoration(
                                labelText: '描述（可选）',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 箱数
                    TextField(
                      controller: boxesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '箱数',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixText: '箱',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 每箱数量
                    TextField(
                      controller: unitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '每箱数量',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixText: '件/箱',
                      ),
                    ),

                    if (dialogError != null) ...[
                      const SizedBox(height: 8),
                      Text(dialogError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
              FilledButton(
                onPressed: () async {
                  final boxes = int.tryParse(boxesCtrl.text) ?? 0;
                  final unitsPerBox = int.tryParse(unitsCtrl.text) ?? 0;
                  if (boxes <= 0) {
                    setS(() => dialogError = '请输入有效箱数');
                    return;
                  }
                  if (unitsPerBox <= 0) {
                    setS(() => dialogError = '请输入每箱数量');
                    return;
                  }
                  String? locId = selectedLocationId;
                  try {
                    if (isNewLoc) {
                      final code = newLocCodeCtrl.text.trim();
                      if (code.isEmpty) {
                        setS(() => dialogError = '库位编号不能为空');
                        return;
                      }
                      final newLoc = await LocationService().create(
                        code: code,
                        description: newLocDescCtrl.text.trim().isEmpty
                            ? null
                            : newLocDescCtrl.text.trim(),
                      );
                      locId = newLoc.id;
                    }
                    if (locId == null) {
                      setS(() => dialogError = '请选择或新建库位');
                      return;
                    }
                    if (existing != null) {
                      await _inventoryService.update(
                        existing.id,
                        boxes: boxes,
                        unitsPerBox: unitsPerBox,
                      );
                    } else {
                      await _inventoryService.create(
                        skuCode: _data!['sku'],
                        locationId: locId,
                        boxes: boxes,
                        unitsPerBox: unitsPerBox,
                      );
                    }
                    if (ctx.mounted) ctx.pop();
                    _load();
                  } catch (e) {
                    final msg = e is DioException
                        ? (e.response?.data?['message'] ?? '操作失败')
                        : '操作失败: $e';
                    setS(() => dialogError = msg is List ? msg.join(', ') : msg.toString());
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteInventory(String id) async {
    try {
      await _inventoryService.delete(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')));
      }
    }
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
      appBar: AppBar(
        title: Text(data['sku'] ?? ''),
        actions: [
          if (user?.canEdit == true)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/skus/new',
                  extra: data).then((_) => _load()),
            ),
        ],
      ),
      floatingActionButton: user?.canEdit == true
          ? FloatingActionButton(
              onPressed: _showInventoryDialog,
              child: const Icon(Icons.add_location),
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
                  _info('SKU', data['sku']),
                  if (data['name'] != null) _info('名称', data['name']),
                  if (data['barcode'] != null) _info('条码', data['barcode']),
                  if (data['cartonQty'] != null)
                    _info('每箱个数', '${data['cartonQty']} 件'),
                  const Divider(),
                  _info('总库存', '${data['totalQty'] ?? 0} 件'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('库存位置 (${inventory.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...inventory.map((record) {
            final loc = record.locationId is Map
                ? Location.fromJson(record.locationId)
                : null;
            final locId = loc?.id ?? (record.locationId is Map ? record.locationId['_id'] : null);
            return Card(
              child: ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(loc?.code ?? '未知位置',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: loc?.description != null ? Text(loc!.description!) : null,
                onTap: locId != null
                    ? () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => InventoryDetailSheet(
                          skuCode: data['sku'] as String,
                          skuId: widget.id,
                          locationId: locId,
                          locationCode: loc?.code ?? '',
                          totalQty: record.totalQty,
                          showLocNav: true,
                          canEdit: user?.canEdit == true,
                          onStockIn: _load,
                        ),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${record.boxes}箱 × ${record.unitsPerBox} = ${record.totalQty}件',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (user?.canEdit == true) ...[
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _showInventoryDialog(existing: record),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _deleteInventory(record.id),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
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
