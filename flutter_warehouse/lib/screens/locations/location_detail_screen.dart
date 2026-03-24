import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/inventory_service.dart';
import '../../services/sku_service.dart';
import '../../models/inventory.dart';
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('库存 SKU (${inventory.length})',
              style: Theme.of(context).textTheme.titleMedium),
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
                    showSkuNav: true,
                    canEdit: user?.canEdit == true,
                    onStockIn: _load,
                  ),
                ),
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
                        onPressed: () async {
                          await _inventoryService.delete(record.id);
                          _load();
                        },
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
