import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/sku_service.dart';
import '../../models/sku.dart';
import '../../widgets/error_view.dart';
import '../inventory/inventory_add_screen.dart';

class SkusScreen extends ConsumerStatefulWidget {
  const SkusScreen({super.key});

  @override
  ConsumerState<SkusScreen> createState() => _SkusScreenState();
}

class _SkusScreenState extends ConsumerState<SkusScreen> {
  final _searchCtrl = TextEditingController();
  final _skuService = SkuService();
  List<Sku> _skus = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String? search]) async {
    setState(() { _loading = true; _error = null; });
    try {
      _skus = await _skuService.getAll(search: search);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SKU 搜索'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: '搜索 SKU / 名称 / 条码...',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _load();
                    },
                  ),
              ],
              onChanged: (v) => _load(v),
            ),
          ),
        ),
      ),
      floatingActionButton: user?.canEdit == true
          ? FloatingActionButton(
              heroTag: 'add_inventory',
              tooltip: '手动录入库存',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const InventoryAddScreen())).then((ok) {
                if (ok == true) _load();
              }),
              child: const Icon(Icons.add_box),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _skus.isEmpty
                  ? const Center(child: Text('暂无 SKU'))
                  : ListView.builder(
                      itemCount: _skus.length,
                      itemBuilder: (_, i) {
                        final sku = _skus[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => context.push('/skus/${sku.id}').then((_) => _load()),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(sku.sku,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 15)),
                                      ),
                                      Text('共 ${sku.totalQty} 件',
                                          style: TextStyle(
                                              color: sku.totalQty > 0
                                                  ? Colors.green.shade700
                                                  : Colors.grey,
                                              fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  if (sku.name != null) ...[
                                    const SizedBox(height: 2),
                                    Text(sku.name!,
                                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  ],
                                  if (sku.locations.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: sku.locations.map((loc) => Chip(
                                        label: Text('${loc.locationCode}  ${loc.totalQty}件',
                                            style: const TextStyle(fontSize: 12)),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )).toList(),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    const Text('暂无库存',
                                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
