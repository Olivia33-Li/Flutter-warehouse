import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/sku.dart';
import '../../models/location.dart';
import '../../services/sku_service.dart';
import '../../services/location_service.dart';
import '../../services/inventory_service.dart';
import '../../l10n/app_localizations.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _bg           = Color(0xFFF0EDE8);
const _surface      = Colors.white;
const _primaryDark  = Color(0xFF1E2D50);
const _locIcon      = Color(0xFF4CAF50);
const _invIcon      = Color(0xFFF59E0B);
const _borderColor  = Color(0xFFE0DDD9);
const _hintColor    = Color(0xFFB0ADAA);
const _bodyColor    = Color(0xFF1A1A2E);
const _mutedColor   = Color(0xFF8E8E9A);
const _activeTab    = Color(0xFF1E2D50);

class InventoryAddScreen extends StatefulWidget {
  final String? initialSkuId;
  final String? initialLocationId;
  const InventoryAddScreen({super.key, this.initialSkuId, this.initialLocationId});

  @override
  State<InventoryAddScreen> createState() => _InventoryAddScreenState();
}

class _InventoryAddScreenState extends State<InventoryAddScreen> {
  final _skuSearchCtrl  = TextEditingController();
  final _locSearchCtrl  = TextEditingController();
  final _qtyCtrl        = TextEditingController();
  final _cartonQtyCtrl  = TextEditingController();
  final _totalQtyCtrl   = TextEditingController();
  final _skuNameCtrl    = TextEditingController();
  final _skuBarcodeCtrl = TextEditingController();
  final _newLocCodeCtrl = TextEditingController();
  final _newLocDescCtrl = TextEditingController();
  final _noteCtrl       = TextEditingController();

  List<Sku>      _skuResults  = [];
  List<Location> _locResults  = [];
  Sku?      _selectedSku;
  Location? _selectedLoc;
  bool   _isNewSku    = false;
  bool   _isNewLoc    = false;
  String _inputMode   = 'carton'; // 'carton' | 'boxesOnly' | 'qty'
  bool   _isPending   = false;

  bool   _skuSearching = false;
  bool   _locSearching = false;
  bool   _saving       = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialSkuId != null) _loadInitialSku();
    if (widget.initialLocationId != null) _loadInitialLoc();
  }

  @override
  void dispose() {
    _skuSearchCtrl.dispose();
    _locSearchCtrl.dispose();
    _qtyCtrl.dispose();
    _cartonQtyCtrl.dispose();
    _skuNameCtrl.dispose();
    _skuBarcodeCtrl.dispose();
    _newLocCodeCtrl.dispose();
    _newLocDescCtrl.dispose();
    _totalQtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialSku() async {
    try {
      final data = await SkuService().getOne(widget.initialSkuId!);
      setState(() {
        _selectedSku = Sku.fromJson(data);
        _skuSearchCtrl.text = _selectedSku!.sku;
        if (_selectedSku!.cartonQty != null) {
          _cartonQtyCtrl.text = _selectedSku!.cartonQty.toString();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadInitialLoc() async {
    try {
      final data = await LocationService().getOne(widget.initialLocationId!);
      setState(() {
        _selectedLoc = Location.fromJson(data);
        _locSearchCtrl.text = _selectedLoc!.code;
      });
    } catch (_) {}
  }

  Future<void> _searchSkus(String q) async {
    if (q.isEmpty) {
      setState(() { _skuResults = []; _isNewSku = false; });
      return;
    }
    setState(() { _skuSearching = true; _isNewSku = false; });
    try {
      _skuResults = await SkuService().getAll(search: q);
    } finally {
      if (mounted) setState(() => _skuSearching = false);
    }
  }

  Future<void> _searchLocs(String q) async {
    if (q.isEmpty) { setState(() => _locResults = []); return; }
    setState(() => _locSearching = true);
    try {
      _locResults = await LocationService().getAll(search: q);
    } finally {
      if (mounted) setState(() => _locSearching = false);
    }
  }

  void _enterNewSkuMode() {
    setState(() {
      _isNewSku = true;
      _selectedSku = null;
      _skuResults = [];
      _skuNameCtrl.clear();
      _skuBarcodeCtrl.clear();
    });
  }

  void _enterNewLocMode() {
    setState(() {
      _isNewLoc = true;
      _selectedLoc = null;
      _locResults = [];
      _newLocDescCtrl.clear();
      if (_newLocCodeCtrl.text.isEmpty) {
        _newLocCodeCtrl.text = _locSearchCtrl.text.trim().toUpperCase();
      }
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_isNewSku && _selectedSku == null) {
      setState(() => _error = l10n.inventorySelectOrCreate);
      return;
    }
    if (_isNewSku && _skuSearchCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.inventorySkuCodeEmpty);
      return;
    }
    if (!_isNewLoc && _selectedLoc == null) { setState(() => _error = l10n.inventorySelectLocation); return; }
    if (_isNewLoc && _newLocCodeCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.inventoryLocationCodeEmpty);
      return;
    }

    int boxes = 0;
    int? unitsPerBox;
    bool boxesOnlyMode = false;
    if (_inputMode == 'carton') {
      final qty = int.tryParse(_qtyCtrl.text);
      if (qty == null || qty <= 0) { setState(() => _error = l10n.inventoryValidBoxCount); return; }
      final u = int.tryParse(_cartonQtyCtrl.text);
      if (u == null || u <= 0) { setState(() => _error = l10n.inventoryValidUnits); return; }
      boxes = qty;
      unitsPerBox = u;
    } else if (_inputMode == 'boxesOnly') {
      final qty = int.tryParse(_qtyCtrl.text);
      if (qty == null || qty <= 0) { setState(() => _error = l10n.inventoryValidBoxCount); return; }
      boxes = qty;
      boxesOnlyMode = true;
    } else {
      final total = int.tryParse(_totalQtyCtrl.text);
      if (total == null || total <= 0) { setState(() => _error = l10n.inventoryValidQty); return; }
      boxes = 1;
      unitsPerBox = total;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final cartonQty = _inputMode == 'carton' ? int.tryParse(_cartonQtyCtrl.text) : null;
      final note = _noteCtrl.text.trim();
      String skuCode;

      if (_isNewSku) {
        final newSku = await SkuService().create(
          sku: _skuSearchCtrl.text.trim(),
          name: _skuNameCtrl.text.trim().isEmpty ? null : _skuNameCtrl.text.trim(),
          barcode: _skuBarcodeCtrl.text.trim().isEmpty ? null : _skuBarcodeCtrl.text.trim(),
          cartonQty: cartonQty,
        );
        skuCode = newSku.sku;
      } else {
        skuCode = _selectedSku!.sku;
        if (cartonQty != null && cartonQty > 0 && cartonQty != _selectedSku!.cartonQty) {
          await SkuService().update(_selectedSku!.id, cartonQty: cartonQty);
        }
      }

      String locationId;
      if (_isNewLoc) {
        final newLoc = await LocationService().create(
          code: _newLocCodeCtrl.text.trim().toUpperCase(),
          description: _newLocDescCtrl.text.trim().isEmpty
              ? null
              : _newLocDescCtrl.text.trim(),
        );
        locationId = newLoc.id;
      } else {
        locationId = _selectedLoc!.id;
      }

      try {
        await InventoryService().create(
          skuCode: skuCode,
          locationId: locationId,
          boxes: boxes,
          unitsPerBox: unitsPerBox,
          note: note.isEmpty ? null : note,
          pendingCount: _isPending,
          boxesOnlyMode: boxesOnlyMode,
        );
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 409) {
          await InventoryService().stockIn(
            skuCode: skuCode,
            locationId: locationId,
            boxes: boxes,
            unitsPerBox: unitsPerBox,
            note: note.isEmpty ? null : note,
            boxesOnlyMode: boxesOnlyMode,
          );
        } else {
          rethrow;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.inventoryStockSaved)));
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() => _error = msg is List ? msg.join(', ') : (msg ?? AppLocalizations.of(context)!.saveFailed));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  InputDecoration _inputDeco(String hint, {Widget? prefixIcon}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _hintColor, fontSize: 14),
    filled: true,
    fillColor: _surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primaryDark, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    prefixIcon: prefixIcon,
  );

  Widget _sectionHeader({
    required String title,
    required IconData icon,
    required Color iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onSecondaryAction,
    String? secondaryLabel,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: _bodyColor)),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                const Icon(Icons.add, size: 14, color: _primaryDark),
                const SizedBox(width: 2),
                Text(actionLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _primaryDark,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        if (secondaryLabel != null && onSecondaryAction != null)
          GestureDetector(
            onTap: onSecondaryAction,
            child: Row(
              children: [
                const Icon(Icons.search, size: 14, color: _mutedColor),
                const SizedBox(width: 2),
                Text(secondaryLabel,
                    style: const TextStyle(
                        fontSize: 13, color: _mutedColor)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _modeTab(String label, String mode, IconData icon) {
    final selected = _inputMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _inputMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _activeTab : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: selected ? Colors.white : _mutedColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : _mutedColor,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _bodyColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.inventoryAddManualTitle,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _bodyColor),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SKU 部分 ────────────────────────────────────────────────────
            _sectionHeader(
              title: l10n.inventorySkuSection,
              icon: Icons.qr_code_rounded,
              iconColor: const Color(0xFF4A6CF7),
              actionLabel: _isNewSku ? null : l10n.inventoryNewSkuLabel,
              onAction: _isNewSku ? null : _enterNewSkuMode,
              secondaryLabel: _isNewSku ? l10n.inventorySearchExisting : null,
              onSecondaryAction: _isNewSku
                  ? () => setState(() {
                        _isNewSku = false;
                        _skuSearchCtrl.clear();
                        _skuNameCtrl.clear();
                        _skuBarcodeCtrl.clear();
                      })
                  : null,
            ),
            const SizedBox(height: 10),

            if (!_isNewSku) ...[
              TextField(
                controller: _skuSearchCtrl,
                style: const TextStyle(fontSize: 14, color: _bodyColor),
                decoration: _inputDeco(
                  l10n.inventorySearchSkuHint,
                  prefixIcon: const Icon(Icons.search, size: 18, color: _hintColor),
                ).copyWith(
                  suffixIcon: _skuSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : _selectedSku != null
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF4CAF50), size: 20)
                          : null,
                ),
                onChanged: (v) {
                  if (_selectedSku != null) setState(() => _selectedSku = null);
                  _searchSkus(v);
                },
              ),
              if (_skuResults.isNotEmpty && _selectedSku == null)
                _dropdownCard(children: [
                  ..._skuResults.take(5).map((s) => _dropdownItem(
                        title: s.sku,
                        subtitle: s.name,
                        onTap: () => setState(() {
                          _selectedSku = s;
                          _skuSearchCtrl.text = s.sku;
                          _skuResults = [];
                          if (s.cartonQty != null && _cartonQtyCtrl.text.isEmpty) {
                            _cartonQtyCtrl.text = s.cartonQty.toString();
                          }
                        }),
                      )),
                  _dropdownItem(
                    title: l10n.inventoryNewSkuTitle(_skuSearchCtrl.text),
                    titleColor: _primaryDark,
                    leading: const Icon(Icons.add_circle_outline,
                        color: _primaryDark, size: 18),
                    onTap: _enterNewSkuMode,
                  ),
                ]),
              if (_skuResults.isEmpty &&
                  _selectedSku == null &&
                  _skuSearchCtrl.text.isNotEmpty &&
                  !_skuSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 15, color: _mutedColor),
                      const SizedBox(width: 6),
                      Text(l10n.inventorySkuNotFound,
                          style: const TextStyle(color: _mutedColor, fontSize: 13)),
                      GestureDetector(
                        onTap: _enterNewSkuMode,
                        child: Text(l10n.inventoryCreateNewSku,
                            style: TextStyle(
                                color: _primaryDark,
                                fontSize: 13,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
            ],

            if (_isNewSku)
              _formCard(
                color: const Color(0xFFF0F3FF),
                borderColor: const Color(0xFFBCC8FF),
                children: [
                  TextField(
                    controller: _skuSearchCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 14, color: _bodyColor),
                    decoration: _inputDeco(l10n.inventorySkuCodeLabel),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _skuNameCtrl,
                    style: const TextStyle(fontSize: 14, color: _bodyColor),
                    decoration: _inputDeco(l10n.inventoryProductNameLabel),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _skuBarcodeCtrl,
                    style: const TextStyle(fontSize: 14, color: _bodyColor),
                    decoration: _inputDeco(l10n.inventoryBarcodeLabel),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // ── 库位部分 ────────────────────────────────────────────────────
            _sectionHeader(
              title: l10n.inventoryLocationSection,
              icon: Icons.location_on_rounded,
              iconColor: _locIcon,
              actionLabel: _isNewLoc ? null : l10n.inventoryNewLocationLabel,
              onAction: _isNewLoc ? null : _enterNewLocMode,
              secondaryLabel: _isNewLoc ? l10n.inventorySearchExisting : null,
              onSecondaryAction: _isNewLoc
                  ? () => setState(() {
                        _isNewLoc = false;
                        _locSearchCtrl.clear();
                        _newLocCodeCtrl.clear();
                        _newLocDescCtrl.clear();
                      })
                  : null,
            ),
            const SizedBox(height: 10),

            if (!_isNewLoc) ...[
              TextField(
                controller: _locSearchCtrl,
                style: const TextStyle(fontSize: 14, color: _bodyColor),
                decoration: _inputDeco(
                  l10n.inventorySearchLocationHint,
                  prefixIcon: const Icon(Icons.location_searching_rounded,
                      size: 18, color: _hintColor),
                ).copyWith(
                  suffixIcon: _locSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : _selectedLoc != null
                          ? const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF4CAF50), size: 20)
                          : null,
                ),
                onChanged: (v) {
                  if (_selectedLoc != null) setState(() => _selectedLoc = null);
                  _searchLocs(v);
                },
              ),
              if (_locResults.isNotEmpty && _selectedLoc == null)
                _dropdownCard(children: [
                  ..._locResults.take(5).map((l) => _dropdownItem(
                        title: l.code,
                        subtitle: l.description,
                        onTap: () => setState(() {
                          _selectedLoc = l;
                          _locSearchCtrl.text = l.code;
                          _locResults = [];
                        }),
                      )),
                  _dropdownItem(
                    title: l10n.inventoryNewLocationTitle(_locSearchCtrl.text),
                    titleColor: _primaryDark,
                    leading: const Icon(Icons.add_circle_outline,
                        color: _primaryDark, size: 18),
                    onTap: _enterNewLocMode,
                  ),
                ]),
              if (_locResults.isEmpty &&
                  _selectedLoc == null &&
                  _locSearchCtrl.text.isNotEmpty &&
                  !_locSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 15, color: _mutedColor),
                      const SizedBox(width: 6),
                      Text(l10n.inventoryLocationNotFound,
                          style: const TextStyle(color: _mutedColor, fontSize: 13)),
                      GestureDetector(
                        onTap: _enterNewLocMode,
                        child: Text(l10n.inventoryCreateNewLocation,
                            style: TextStyle(
                                color: _primaryDark,
                                fontSize: 13,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
            ],

            if (_isNewLoc)
              _formCard(
                color: const Color(0xFFF0FFF4),
                borderColor: const Color(0xFFB2E5C0),
                children: [
                  TextField(
                    controller: _newLocCodeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(fontSize: 14, color: _bodyColor),
                    decoration: _inputDeco(l10n.inventoryLocationCodeLabel),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newLocDescCtrl,
                    style: const TextStyle(fontSize: 14, color: _bodyColor),
                    decoration: _inputDeco(l10n.inventoryLocationDescLabel),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // ── 初始库存 ───────────────────────────────────────────────────
            _sectionHeader(
              title: l10n.inventoryInitialStockSection,
              icon: Icons.inventory_2_rounded,
              iconColor: _invIcon,
            ),
            const SizedBox(height: 10),

            // 待清点 card
            GestureDetector(
              onTap: () => setState(() => _isPending = !_isPending),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _isPending
                      ? const Color(0xFFFFF8EE)
                      : _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPending
                        ? const Color(0xFFFFD580)
                        : _borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _isPending ? _invIcon : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _isPending ? _invIcon : _borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: _isPending
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.inventoryPendingTitle,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _bodyColor)),
                          const SizedBox(height: 2),
                          Text(l10n.inventoryPendingSubtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: _mutedColor)),
                        ],
                      ),
                    ),
                    Icon(Icons.pending_actions_outlined,
                        size: 20,
                        color: _isPending ? _invIcon : _hintColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Mode tab row
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E5E1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _modeTab(l10n.inventoryModeCarton, 'carton', Icons.view_list_rounded)),
                  Expanded(child: _modeTab(l10n.inventoryModeBoxOnly, 'boxesOnly', Icons.inventory_2_outlined)),
                  Expanded(child: _modeTab(l10n.inventoryModeQty, 'qty', Icons.tag_rounded)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Quantity inputs
            StatefulBuilder(
              builder: (ctx, setS) {
                final il10n = AppLocalizations.of(ctx)!;
                if (_inputMode == 'boxesOnly') {
                  final boxes = int.tryParse(_qtyCtrl.text) ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(il10n.inventoryBoxesLabel,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _bodyColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 15, color: _bodyColor),
                        decoration: _inputDeco('0').copyWith(suffixText: il10n.inventoryBoxesSuffix),
                        onChanged: (_) => setS(() {}),
                      ),
                      if (boxes > 0) ...[
                        const SizedBox(height: 10),
                        _totalRow(il10n.inventoryBoxesTotal(boxes)),
                      ],
                    ],
                  );
                }
                if (_inputMode == 'qty') {
                  final total = int.tryParse(_totalQtyCtrl.text) ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(il10n.inventoryTotalQtyLabel,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _bodyColor)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _totalQtyCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 15, color: _bodyColor),
                        decoration: _inputDeco('0').copyWith(suffixText: il10n.inventoryTotalQtySuffix),
                        onChanged: (_) => setS(() {}),
                      ),
                      if (total > 0) ...[
                        const SizedBox(height: 10),
                        _totalRow(il10n.inventoryQtyTotal(total)),
                      ],
                    ],
                  );
                }
                // 按箱规
                final boxes = int.tryParse(_qtyCtrl.text) ?? 0;
                final units = int.tryParse(_cartonQtyCtrl.text) ?? 0;
                final total = boxes * units;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${il10n.inventoryBoxesLabel.replaceAll(' *', '')} × ${il10n.inventoryUnitsLabel.replaceAll(' *', '')}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: _mutedColor)),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(il10n.inventoryBoxesLabel,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _bodyColor)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _qtyCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 15, color: _bodyColor),
                                decoration: _inputDeco('0'),
                                onChanged: (_) => setS(() {}),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(10, 34, 10, 0),
                          child: Text('×',
                              style: TextStyle(
                                  fontSize: 18, color: _mutedColor)),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(il10n.inventoryUnitsLabel,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: _bodyColor)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _cartonQtyCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 15, color: _bodyColor),
                                decoration: _inputDeco('0'),
                                onChanged: (_) => setS(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _totalRow(total > 0 ? il10n.inventoryQtyTotal(total) : '—'),
                  ],
                );
              },
            ),

            if (_isPending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  border: Border.all(color: const Color(0xFFFFD580)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 15, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.inventoryPendingNote,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 备注 ────────────────────────────────────────────────────────
            const SizedBox(height: 20),
            Text(l10n.inventoryNoteLabel,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _bodyColor)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 14, color: _bodyColor),
              decoration: _inputDeco(l10n.inventoryAddNoteHint),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  border: Border.all(color: const Color(0xFFFFB3B3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 15, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primaryDark.withValues(alpha: 0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_isPending
                        ? Icons.pending_actions_outlined
                        : Icons.save_rounded,
                        size: 18),
                label: Text(
                  _isPending ? l10n.inventoryConfirmPending : l10n.inventorySaveStock,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared UI helpers ─────────────────────────────────────────────────────────

  Widget _dropdownCard({required List<Widget> children}) => Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      );

  Widget _dropdownItem({
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? leading,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14,
                            color: titleColor ?? _bodyColor,
                            fontWeight: FontWeight.w500)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: _mutedColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _formCard({
    required List<Widget> children,
    required Color color,
    required Color borderColor,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _totalRow(String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Text(AppLocalizations.of(context)!.inventoryTotal,
                style: const TextStyle(
                    fontSize: 14, color: _mutedColor)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _bodyColor)),
          ],
        ),
      );
}
