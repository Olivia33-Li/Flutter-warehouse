import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sku_service.dart';
import '../../models/sku.dart';
import '../../utils/search_utils.dart';
import '../../utils/stock_display_utils.dart';
import '../../widgets/error_view.dart';
import '../inventory/inventory_add_screen.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _bgColor      = Color(0xFFF5F3F0);
const _primary      = Color(0xFF4A6CF7);
const _titleColor   = Color(0xFF1A1A2E);
const _hintColor    = Color(0xFFC5C5CE);
const _mutedColor   = Color(0xFF8E8E9A);
const _searchBg     = Color(0xFFE8E6E3);
const _stockGreen   = Color(0xFF67C23A);
const _chipBg       = Color(0xFFE8F3FF);
const _chipText     = Color(0xFF4A9EFF);

class SkusScreen extends ConsumerStatefulWidget {
  const SkusScreen({super.key});

  @override
  ConsumerState<SkusScreen> createState() => _SkusScreenState();
}

class _SkusScreenState extends ConsumerState<SkusScreen> {
  final _searchCtrl = TextEditingController();
  final _skuService = SkuService();

  List<Sku> _allSkus  = [];
  List<Sku> _filtered = [];
  bool _loading       = true;
  String? _error;
  String _query        = '';
  String _statusFilter = 'active'; // 'active' | 'archived' | 'all'
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
    final active   = list.where((s) => !s.isArchived).toList();
    final archived = list.where((s) => s.isArchived).toList();

    List<Sku> sortGroup(List<Sku> g) {
      final withStock = g.where((s) => s.totalQty > 0 || s.allBoxesOnly).toList();
      final noStock   = g.where((s) => s.totalQty == 0 && !s.allBoxesOnly).toList();
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
      backgroundColor: _bgColor,
      floatingActionButton: user?.canEdit == true
          ? _Fab(onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const InventoryAddScreen()))
              .then((ok) { if (ok == true) _load(); }))
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Text(
                AppLocalizations.of(context)!.skuScreenTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: _titleColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Search bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SearchBar(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter tabs ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterTab(
                    label: AppLocalizations.of(context)!.skuFilterActive,
                    selected: _statusFilter == 'active',
                    onTap: () => _setStatusFilter('active'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: AppLocalizations.of(context)!.skuFilterAll,
                    selected: _statusFilter == 'all',
                    onTap: () => _setStatusFilter('all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterTab(
                    label: AppLocalizations.of(context)!.skuFilterArchived,
                    selected: _statusFilter == 'archived',
                    onTap: () => _setStatusFilter('archived'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── List ───────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ErrorView(message: _error!, onRetry: _load)
                      : _filtered.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => _SkuCard(
                                sku: _filtered[i],
                                query: _query,
                                onTap: () => context
                                    .push('/skus/${_filtered[i].id}')
                                    .then((_) => _load()),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          _statusFilter == 'archived'
              ? AppLocalizations.of(context)!.skuEmptyArchived
              : AppLocalizations.of(context)!.skuEmpty,
          style: const TextStyle(color: _mutedColor),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.skuNoResult(_query),
              style: const TextStyle(color: _mutedColor, fontSize: 15)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context)!.skuSearchTip,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, size: 18, color: _hintColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: _titleColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.skuSearchHint,
                hintStyle: TextStyle(fontSize: 14, color: _hintColor),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Icon(Icons.close, size: 16, color: _hintColor),
                    ),
                  )
                : const SizedBox(width: 14),
          ),
        ],
      ),
    );
  }
}

// ── Filter tab ────────────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primary.withValues(alpha: 0.9) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: selected ? 6 : 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _mutedColor,
          ),
        ),
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────────

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}

// ── SKU card ──────────────────────────────────────────────────────────────────

class _SkuCard extends StatelessWidget {
  final Sku sku;
  final String query;
  final VoidCallback onTap;

  const _SkuCard({required this.sku, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isArchived = sku.isArchived;
    final hasStock   = sku.totalQty > 0 || sku.allBoxesOnly;
    final dimmed     = isArchived || !hasStock;

    final shownLocs = sku.locations.take(3).toList();
    final moreCount = sku.locations.length > 3 ? sku.locations.length - 3 : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: isArchived
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: SKU + archived badge + stock
            Row(
              children: [
                if (isArchived) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Archived',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: dimmed ? Colors.grey.shade400 : _titleColor,
                        letterSpacing: -0.15,
                        decoration: isArchived
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
                if (!isArchived) _StockLabel(sku: sku),
              ],
            ),

            // Row 2: name (subtle, if present)
            if (sku.name != null && sku.name!.isNotEmpty) ...[
              const SizedBox(height: 2),
              RichText(
                text: highlightMatch(
                  sku.name!,
                  query,
                  baseStyle: TextStyle(
                    fontSize: 12,
                    color: dimmed ? Colors.grey.shade300 : _mutedColor,
                  ),
                ),
              ),
            ],

            // Row 3: location chips
            if (shownLocs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...shownLocs.map((loc) => _LocChip(loc: loc, dimmed: dimmed, cartonQty: sku.cartonQty)),
                  if (moreCount > 0)
                    _LocChip(label: '+$moreCount', dimmed: dimmed),
                ],
              ),
            ] else if (!hasStock) ...[
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context)!.skuNoStock,
                  style: const TextStyle(color: _hintColor, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Stock display helper — see utils/stock_display_utils.dart ─────────────────

// ── Stock label ───────────────────────────────────────────────────────────────

class _StockLabel extends StatelessWidget {
  final Sku sku;
  const _StockLabel({required this.sku});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final min  = sku.minStock;

    final configuredCartons   = sku.totalConfiguredCartons;
    final noSpecCartons        = sku.totalUnconfiguredCartons;
    final loosePcs             = sku.totalLoosePcs;
    final hasStock             = configuredCartons > 0 || noSpecCartons > 0 || loosePcs > 0;

    Color color;
    IconData? icon;

    if (!hasStock) {
      color = Colors.grey.shade400;
      icon  = Icons.warning_amber_rounded;
    } else if (min != null && sku.totalQty > 0 && sku.totalQty <= min) {
      color = Colors.orange.shade600;
      icon  = Icons.trending_down;
    } else {
      color = _stockGreen;
      icon  = null;
    }

    final label = buildStockLabel(
      configuredCartons: configuredCartons,
      noSpecCartons:     noSpecCartons,
      loosePcs:          loosePcs,
      cartonQty:         sku.cartonQty,
      l10n:              l10n,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 2),
        ],
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: color),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

// ── Location chip ─────────────────────────────────────────────────────────────

class _LocChip extends StatelessWidget {
  final SkuLocation? loc;
  final String? label;
  final bool dimmed;
  final int? cartonQty;

  const _LocChip({this.loc, this.label, required this.dimmed, this.cartonQty});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String text;
    if (label != null) {
      text = label!;
    } else {
      final l   = loc!;
      final qty = buildStockLabel(
        configuredCartons: l.configuredCartons,
        noSpecCartons:     l.unconfiguredCartons,
        loosePcs:          l.loosePcs,
        cartonQty:         cartonQty,
        l10n:              l10n,
      );
      text = '${l.locationCode} · $qty';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dimmed ? Colors.grey.shade100 : _chipBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: dimmed ? Colors.grey.shade400 : _chipText,
        ),
      ),
    );
  }
}
