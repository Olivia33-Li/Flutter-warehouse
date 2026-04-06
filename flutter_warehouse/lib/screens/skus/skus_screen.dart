import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/sku_service.dart';
import '../../models/sku.dart';
import '../../utils/search_utils.dart';
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

  List<Sku> _allSkus = [];
  List<Sku> _filtered = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  // 'active' | 'archived' | 'all'
  String _statusFilter = 'active';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _allSkus = await _skuService.getAll(statusFilter: _statusFilter);
      _applyFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = value.trim();
        _applyFilter();
      });
    });
  }

  void _applyFilter() {
    if (_query.isEmpty) {
      _filtered = _sort(_allSkus);
    } else {
      _filtered = _sort(_allSkus.where((s) {
        return fuzzyMatchAny([s.sku, s.name ?? '', s.barcode ?? ''], _query);
      }).toList());
    }
  }

  List<Sku> _sort(List<Sku> list) {
    // Archived always go last
    final active = list.where((s) => !s.isArchived).toList();
    final archived = list.where((s) => s.isArchived).toList();

    List<Sku> sortGroup(List<Sku> g) {
      final withStock = g.where((s) => s.totalQty > 0 || s.allBoxesOnly).toList();
      final noStock = g.where((s) => s.totalQty == 0 && !s.allBoxesOnly).toList();
      withStock.sort((a, b) => a.sku.compareTo(b.sku));
      noStock.sort((a, b) => a.sku.compareTo(b.sku));
      return [...withStock, ...noStock];
    }

    return [...sortGroup(active), ...sortGroup(archived)];
  }

  void _setStatusFilter(String value) {
    if (_statusFilter == value) return;
    setState(() => _statusFilter = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SKU 搜索'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
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
                          _onSearchChanged('');
                        },
                      ),
                  ],
                  onChanged: _onSearchChanged,
                ),
              ),
              // ── Status filter chips ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: '在用',
                      selected: _statusFilter == 'active',
                      onTap: () => _setStatusFilter('active'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: '含已归档',
                      selected: _statusFilter == 'all',
                      onTap: () => _setStatusFilter('all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: '仅归档',
                      selected: _statusFilter == 'archived',
                      color: Colors.grey,
                      onTap: () => _setStatusFilter('archived'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: user?.canEdit == true
          ? FloatingActionButton(
              heroTag: 'add_inventory',
              tooltip: '手动录入库存',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const InventoryAddScreen()))
                  .then((ok) { if (ok == true) _load(); }),
              child: const Icon(Icons.add_box),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _filtered.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _SkuCard(
                        sku: _filtered[i],
                        query: _query,
                        onTap: () => context.push('/skus/${_filtered[i].id}').then((_) => _load()),
                      ),
                    ),
    );
  }

  Widget _emptyState() {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          _statusFilter == 'archived' ? '暂无归档 SKU' : '暂无 SKU',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('未找到 "$_query"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('尝试缩短关键词，或忽略分隔符搜索',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? c.withOpacity(0.12) : Colors.transparent,
          border: Border.all(color: selected ? c : Colors.grey.shade400),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? c : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── SKU 列表卡片 ─────────────────────────────────────────────────────────────

class _SkuCard extends StatelessWidget {
  final Sku sku;
  final String query;
  final VoidCallback onTap;

  const _SkuCard({required this.sku, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isArchived = sku.isArchived;
    final hasStock = sku.totalQty > 0 || sku.allBoxesOnly;
    // Archived items are always visually dimmed
    final dimmed = isArchived || !hasStock;

    final locCount = sku.locations.length;
    final shownLocs = sku.locations.take(3).toList();
    final moreCount = locCount > 3 ? locCount - 3 : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      // Slightly reduced opacity for archived cards
      color: isArchived ? Colors.grey.shade100 : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: SKU code + archived badge (if applicable) + stock badge
              Row(
                children: [
                  if (isArchived) ...[
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Archived',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: RichText(
                      text: highlightMatch(
                        sku.sku,
                        query,
                        baseStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: dimmed ? Colors.grey.shade500 : null,
                          decoration: isArchived ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  if (!isArchived) _StockBadge(sku: sku),
                ],
              ),
              // Row 2: name
              if (sku.name != null && sku.name!.isNotEmpty) ...[
                const SizedBox(height: 2),
                RichText(
                  text: highlightMatch(
                    sku.name!,
                    query,
                    baseStyle: TextStyle(
                      color: dimmed ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              // Row 3: location chips (show for archived too if they have stock)
              if (shownLocs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...shownLocs.map((loc) => _LocChip(loc: loc, dimmed: dimmed)),
                    if (moreCount > 0)
                      _LocChip(label: '+$moreCount', dimmed: dimmed),
                  ],
                ),
              ] else if (!hasStock) ...[
                const SizedBox(height: 4),
                Text('暂无库存',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final Sku sku;
  const _StockBadge({required this.sku});

  @override
  Widget build(BuildContext context) {
    final qty = sku.allBoxesOnly
        ? sku.locations.fold(0, (s, l) => s + l.boxes)
        : sku.totalQty;
    final unit = sku.allBoxesOnly ? '箱' : '件';
    final min = sku.minStock;

    Color color;
    IconData? icon;

    if (qty == 0) {
      color = Colors.grey.shade400;
      icon = Icons.warning_amber_rounded;
    } else if (min != null && qty <= min) {
      color = Colors.orange.shade700;
      icon = Icons.trending_down;
    } else {
      color = Colors.green.shade700;
      icon = null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text('共 $qty $unit',
            style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class _LocChip extends StatelessWidget {
  final SkuLocation? loc;
  final String? label;
  final bool dimmed;

  const _LocChip({this.loc, this.label, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final text = label ??
        (loc!.boxesOnly
            ? '${loc!.locationCode} · ${loc!.boxes}箱'
            : '${loc!.locationCode} · ${loc!.totalQty}件');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dimmed ? Colors.grey.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dimmed ? Colors.grey.shade300 : Colors.blue.shade200,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: dimmed ? Colors.grey.shade400 : Colors.blue.shade700,
        ),
      ),
    );
  }
}
