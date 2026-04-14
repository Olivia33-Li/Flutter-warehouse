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

// ── Design tokens ──────────────────────────────────────────────────────────────
const _bgColor      = Color(0xFFF0EDE8);
const _primary      = Color(0xFF4A6CF7);
const _primaryDark  = Color(0xFF1E2D50);
const _titleColor   = Color(0xFF1A1A2E);
const _mutedColor   = Color(0xFF8E8E9A);
const _hintColor    = Color(0xFFC5C5CE);
const _searchBg     = Color(0xFFE8E5E1);
const _borderColor  = Color(0xFFE0DDD9);

class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen> {
  final _searchCtrl      = TextEditingController();
  final _locationService = LocationService();

  List<Location> _allLocations = [];
  List<Location> _filtered     = [];
  bool   _loading = true;
  String? _error;
  String _query   = '';
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
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        size: 16, color: _primary),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '新增位置',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _titleColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 位置代码 input
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 14, color: _titleColor),
                decoration: _dialogInputDeco('位置代码 *'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              // 描述 input
              TextField(
                controller: descCtrl,
                style: const TextStyle(fontSize: 14, color: _titleColor),
                decoration: _dialogInputDeco('描述（可选）'),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => ctx.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _mutedColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: const Text('取消',
                        style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('创建',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _dialogInputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7F5F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryDark, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '位置管理',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (!_loading && _error == null)
                    Text(
                      '${_allLocations.length} 个库位',
                      style: const TextStyle(
                          fontSize: 13, color: _mutedColor),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SearchBar(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 14),

            // ── List / states ────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _filtered.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => _LocationCard(
                                location: _filtered[i],
                                query: _query,
                                onTap: () => context
                                    .push('/locations/${_filtered[i].id}')
                                    .then((_) => _load()),
                              ),
                            ),
            ),
          ],
        ),
      ),

      // ── FAB area ─────────────────────────────────────────────────────────
      floatingActionButton: user?.canEdit == true
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Secondary: 新增位置
                GestureDetector(
                  onTap: _showAddDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 16, color: _primary),
                        SizedBox(width: 6),
                        Text(
                          '新增位置',
                          style: TextStyle(
                            fontSize: 13,
                            color: _titleColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Primary: 录入库存
                GestureDetector(
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => const InventoryAddScreen()))
                      .then((ok) { if (ok == true) _load(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: _primaryDark,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryDark.withValues(alpha: 0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_rounded,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          '录入库存',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _emptyState() {
    if (_query.isEmpty) {
      return const Center(
        child: Text('暂无位置',
            style: TextStyle(color: _mutedColor, fontSize: 14)),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: _hintColor),
          const SizedBox(height: 12),
          Text('未找到 "$_query"',
              style: const TextStyle(color: _mutedColor, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('尝试缩短关键词，或忽略大小写搜索',
              style: TextStyle(color: _hintColor, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Search bar ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: _searchBg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 18, color: _hintColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: _titleColor),
              decoration: InputDecoration(
                hintText: '搜索位置码 / 备注...',
                hintStyle:
                    const TextStyle(fontSize: 14, color: _hintColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixIcon: controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          controller.clear();
                          onChanged('');
                        },
                        child: const Icon(Icons.close,
                            size: 15, color: _hintColor),
                      )
                    : null,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 32, minHeight: 0),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ── Location card ──────────────────────────────────────────────────────────────

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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: code + badge ─────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: highlightMatch(
                          location.code,
                          query,
                          baseStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isEmpty ? _hintColor : _titleColor,
                          ),
                        ),
                      ),
                    ),
                    if (location.checkedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_circle_outline,
                            size: 15, color: Colors.green.shade500),
                      ),
                    _stockBadge(isEmpty),
                  ],
                ),

                // ── Description ───────────────────────────────────────
                if (location.description != null &&
                    location.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  RichText(
                    text: highlightMatch(
                      location.description!,
                      query,
                      baseStyle: const TextStyle(
                          color: _mutedColor, fontSize: 12),
                    ),
                  ),
                ],

                // ── Stats row ─────────────────────────────────────────
                if (!isEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _statItem(Icons.category_outlined,
                          '${location.skuCount} SKU'),
                      if (location.totalBoxes > 0) ...[
                        const SizedBox(width: 12),
                        _statItem(Icons.inventory_2_outlined,
                            '${location.totalBoxes} 箱'),
                      ],
                      if (location.totalQty > 0) ...[
                        const SizedBox(width: 12),
                        _statItem(Icons.tag_rounded,
                            '${location.totalQty} 件'),
                      ],
                      if (location.checkedAt != null) ...[
                        const SizedBox(width: 12),
                        _statItem(
                          Icons.schedule_outlined,
                          '检查 ${_formatDate(location.checkedAt!)}',
                          color: Colors.green.shade600,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stockBadge(bool isEmpty) {
    if (isEmpty) {
      return const Text('空位置',
          style: TextStyle(color: _hintColor, fontSize: 12));
    }
    if (location.totalBoxes > 0) {
      return Text(
        '${location.totalBoxes} 箱',
        style: const TextStyle(
            color: _primary, fontWeight: FontWeight.w600, fontSize: 14),
      );
    }
    return Text(
      '${location.totalQty} 件',
      style: const TextStyle(
          color: Color(0xFF67C23A),
          fontWeight: FontWeight.w600,
          fontSize: 14),
    );
  }

  Widget _statItem(IconData icon, String label, {Color? color}) {
    final c = color ?? _mutedColor;
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
