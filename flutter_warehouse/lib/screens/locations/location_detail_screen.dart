import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/inventory_service.dart';
import '../../services/sku_service.dart';
import '../../models/inventory.dart';
import '../../models/sku.dart';
import '../../widgets/error_view.dart';

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

    String? selectedSkuId = existing?.skuId is Map
        ? existing!.skuId['_id']
        : existing?.skuId?.toString();
    final qtyCtrl = TextEditingController(
      text: existing?.quantity.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '新增库存' : '编辑库存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedSkuId,
              decoration: const InputDecoration(
                  labelText: 'SKU', border: OutlineInputBorder()),
              items: skus
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.sku)))
                  .toList(),
              onChanged: (v) => selectedSkuId = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: '数量（箱）', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (selectedSkuId == null) return;
              try {
                await _inventoryService.upsert(
                  skuId: selectedSkuId!,
                  locationId: widget.id,
                  quantity: int.tryParse(qtyCtrl.text) ?? 0,
                );
                if (ctx.mounted) ctx.pop();
                _load();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('操作失败: $e')));
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
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
                  _info('总库存', '${data['totalQty'] ?? 0} 箱'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('库存 SKU (${inventory.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...inventory.map((record) {
            final sku = record.skuId is Map ? Sku.fromJson(record.skuId) : null;
            return Card(
              child: ListTile(
                title: Text(sku?.sku ?? '未知 SKU',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: sku?.name != null ? Text(sku!.name!) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${record.quantity} 箱',
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
