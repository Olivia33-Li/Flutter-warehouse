import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../models/location.dart';
import '../../utils/search_utils.dart';
import '../../widgets/error_view.dart';
import '../inventory/inventory_add_screen.dart';

class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  final _searchCtrl = TextEditingController();
  final _locationService = LocationService();

  List<Location> _allLocations = [];
  List<Location> _filtered = [];
  bool _loading = true;
  String? _error;
  String _query = '';
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
      _allLocations = await _locationService.getAll();
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
      _filtered = _sort(_allLocations);
    } else {
      _filtered = _sort(_allLocations.where((loc) {
        return fuzzyMatchAny([loc.code, loc.description ?? ''], _query);
      }).toList());
    }
  }

  List<Location> _sort(List<Location> list) {
    final withStock = list.where((l) => l.skuCount > 0).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    final empty = list.where((l) => l.skuCount == 0).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    return [...withStock, ...empty];
  }

  void _showAddDialog() {
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增位置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                  labelText: '位置代码 *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                  labelText: '描述', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              try {
                await _locationService.create(
                  code: codeCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                if (ctx.mounted) ctx.pop();
                _load();
              } on DioException catch (e) {
                final msg = e.response?.data?['message'];
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(msg ?? '创建失败')));
                }
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('位置管理'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: '搜索位置码 / 备注...',
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
        ),
      ),
      floatingActionButton: user?.canEdit == true
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'add_location',
                  tooltip: '新增库位',
                  onPressed: _showAddDialog,
                  child: const Icon(Icons.add_location_alt),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'add_inventory',
                  tooltip: '录入库存',
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const InventoryAddScreen()))
                      .then((ok) { if (ok == true) _load(); }),
                  child: const Icon(Icons.add_box),
                ),
              ],
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
                      itemBuilder: (_, i) => _LocationCard(
                        location: _filtered[i],
                        query: _query,
                        onTap: () => context
                            .push('/locations/${_filtered[i].id}')
                            .then((_) => _load()),
                      ),
                    ),
    );
  }

  Widget _emptyState() {
    if (_query.isEmpty) {
      return const Center(child: Text('暂无位置'));
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
          Text('尝试缩短关键词，或忽略大小写搜索',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── 位置列表卡片 ──────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final Location location;
  final String query;
  final VoidCallback onTap;

  const _LocationCard({
    required this.location,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = location.skuCount == 0;
    final allBoxesOnly = location.totalQty == 0 && location.totalBoxes > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Location code with highlight
                  Expanded(
                    child: RichText(
                      text: highlightMatch(
                        location.code,
                        query,
                        baseStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isEmpty ? Colors.grey.shade500 : null,
                        ),
                      ),
                    ),
                  ),
                  // Checked badge
                  if (location.checkedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.green.shade600),
                    ),
                  // Stock summary
                  const SizedBox(width: 8),
                  _stockLabel(allBoxesOnly, isEmpty),
                ],
              ),
              // Description
              if (location.description != null && location.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                RichText(
                  text: highlightMatch(
                    location.description!,
                    query,
                    baseStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              // Stats row: X SKU · Y箱 · Z件
              if (!isEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statChip(Icons.category_outlined, '${location.skuCount} SKU'),
                    if (location.totalBoxes > 0) ...[
                      const SizedBox(width: 8),
                      _statChip(Icons.inventory_2_outlined, '${location.totalBoxes} 箱'),
                    ],
                    if (location.totalQty > 0) ...[
                      const SizedBox(width: 8),
                      _statChip(Icons.numbers_outlined, '${location.totalQty} 件'),
                    ],
                    if (location.checkedAt != null) ...[
                      const SizedBox(width: 8),
                      _statChip(
                        Icons.schedule_outlined,
                        '检查 ${_formatDate(location.checkedAt!)}',
                        color: Colors.green.shade700,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stockLabel(bool allBoxesOnly, bool isEmpty) {
    if (isEmpty) {
      return Text('空位置',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
    }
    // Prefer boxes; fall back to qty only if no boxes at all
    if (location.totalBoxes > 0) {
      return Text('${location.totalBoxes} 箱',
          style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13));
    }
    return Text('${location.totalQty} 件',
        style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 13));
  }

  Widget _statChip(IconData icon, String label, {Color? color}) {
    final c = color ?? Colors.grey.shade600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return DateFormat('MM/dd').format(dt);
  }
}
