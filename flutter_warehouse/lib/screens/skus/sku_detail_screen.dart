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
import '../../l10n/app_localizations.dart';
import '../../utils/stock_display_utils.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _bgColor    = Color(0xFFF5F3F0);
const _primary    = Color(0xFF4A6CF7);
const _titleColor = Color(0xFF1A1A2E);
const _mutedColor = Color(0xFF8E8E9A);
const _hintColor  = Color(0xFFB5B5C0);
const _inputBg    = Color(0xFFF9F8F6);
const _greenBg    = Color(0xFFEEF6EF);
const _greenText  = Color(0xFF5A9A6B);

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
  bool _specsExpanded = false;

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

  // ── Add location (bottom sheet) ────────────────────────────────────────────

  Future<void> _showAddLocationSheet() async {
    final locSearchCtrl = TextEditingController();
    final boxesCtrl     = TextEditingController();
    final unitsCtrl     = TextEditingController(text: _data?['cartonQty']?.toString() ?? '1');
    final qtyCtrl       = TextEditingController();
    final noteCtrl      = TextEditingController();
    final newLocCodeCtrl = TextEditingController();
    final newLocDescCtrl = TextEditingController();

    String? selectedLocationId;
    String? selectedLocationCode;
    List<Location> locResults = [];
    bool isNewLoc      = false;
    bool locSearching  = false;
    String inputMode   = 'carton'; // 'carton' | 'boxesOnly' | 'qty'
    bool isPending     = false;
    bool saving        = false;
    String? sheetError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

          final previewBoxes = int.tryParse(boxesCtrl.text) ?? 0;
          final previewUnits = int.tryParse(unitsCtrl.text) ?? 0;
          final previewQty = inputMode == 'carton'
              ? previewBoxes * previewUnits
              : inputMode == 'boxesOnly'
                  ? previewBoxes
                  : (int.tryParse(qtyCtrl.text) ?? 0);

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Drag handle ──────────────────────────────────────────
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E6E2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),

                  // ── Title ────────────────────────────────────────────────
                  Text(
                    AppLocalizations.of(ctx)!.skuDetailNewLocation,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Location selector ────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(ctx)!.skuDetailLocationSection,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6E6E80),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setS(() {
                          isNewLoc = !isNewLoc;
                          if (isNewLoc) {
                            selectedLocationId = null;
                            selectedLocationCode = null;
                            locSearchCtrl.clear();
                            locResults = [];
                          } else {
                            newLocCodeCtrl.clear();
                            newLocDescCtrl.clear();
                          }
                        }),
                        child: Text(
                          isNewLoc ? AppLocalizations.of(ctx)!.inventorySearchExisting : AppLocalizations.of(ctx)!.skuDetailNewLocationButton,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _primary.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!isNewLoc) ...[
                    if (selectedLocationId != null)
                      // Selected location pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _greenBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: _greenText),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedLocationCode ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _greenText,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setS(() {
                                selectedLocationId = null;
                                selectedLocationCode = null;
                              }),
                              child: const Icon(Icons.close, size: 16, color: _hintColor),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Search input
                      _SheetInput(
                        controller: locSearchCtrl,
                        hint: AppLocalizations.of(ctx)!.skuDetailSearchLocationHint,
                        icon: Icons.location_on_outlined,
                        onChanged: (v) => searchLocs(v),
                        suffix: locSearching
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                      if (locResults.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
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
                                leading: const Icon(Icons.add_circle_outline, color: _primary, size: 18),
                                title: Text(
                                  AppLocalizations.of(ctx)!.skuDetailNewLocationTitle(locSearchCtrl.text),
                                  style: const TextStyle(color: _primary, fontSize: 13),
                                ),
                                onTap: () => setS(() {
                                  isNewLoc = true;
                                  newLocCodeCtrl.text = locSearchCtrl.text;
                                  locResults = [];
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (locResults.isEmpty &&
                          locSearchCtrl.text.isNotEmpty &&
                          !locSearching) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => setS(() {
                            isNewLoc = true;
                            newLocCodeCtrl.text = locSearchCtrl.text;
                          }),
                          child: Text(
                            AppLocalizations.of(ctx)!.skuDetailLocationNotFound,
                            style: const TextStyle(
                              color: _primary,
                              decoration: TextDecoration.underline,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],

                  if (isNewLoc) ...[
                    _SheetInput(
                      controller: newLocCodeCtrl,
                      hint: AppLocalizations.of(ctx)!.skuDetailLocationCodeHint,
                      icon: Icons.location_on_outlined,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 8),
                    _SheetInput(
                      controller: newLocDescCtrl,
                      hint: AppLocalizations.of(ctx)!.skuDetailLocationDescHint,
                      icon: Icons.notes_outlined,
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Initial inventory ────────────────────────────────────
                  Text(
                    AppLocalizations.of(ctx)!.skuDetailInitialStock,
                    style: TextStyle(
                      fontSize: 10,
                      color: _hintColor,
                      letterSpacing: 0.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Pending toggle
                  GestureDetector(
                    onTap: () => setS(() => isPending = !isPending),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isPending ? const Color(0xFFFFF3E0) : _inputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: isPending
                            ? Border.all(color: Colors.orange.shade200)
                            : null,
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: isPending ? Colors.orange.shade500 : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: isPending ? Colors.orange.shade500 : const Color(0xFFD4D2CE),
                              ),
                            ),
                            child: isPending
                                ? const Icon(Icons.check, size: 12, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(ctx)!.skuDetailPendingTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isPending ? Colors.orange.shade800 : _titleColor,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(ctx)!.skuDetailPendingSubtitle,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isPending ? Colors.orange.shade600 : _hintColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!isPending) ...[
                    const SizedBox(height: 14),

                    // Mode tabs
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE8E4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _ModeTab(
                            label: AppLocalizations.of(ctx)!.skuDetailModeCarton,
                            selected: inputMode == 'carton',
                            onTap: () => setS(() => inputMode = 'carton'),
                          ),
                          _ModeTab(
                            label: AppLocalizations.of(ctx)!.skuDetailModeBoxOnly,
                            selected: inputMode == 'boxesOnly',
                            onTap: () => setS(() => inputMode = 'boxesOnly'),
                          ),
                          _ModeTab(
                            label: AppLocalizations.of(ctx)!.skuDetailModeQty,
                            selected: inputMode == 'qty',
                            onTap: () => setS(() => inputMode = 'qty'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Input fields
                    if (inputMode == 'carton') ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _LabeledInput(
                              label: AppLocalizations.of(ctx)!.skuDetailBoxesLabel,
                              controller: boxesCtrl,
                              hint: '0',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setS(() {}),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 20, left: 10, right: 10),
                            child: Text(
                              '×',
                              style: TextStyle(fontSize: 16, color: _hintColor),
                            ),
                          ),
                          Expanded(
                            child: _LabeledInput(
                              label: AppLocalizations.of(ctx)!.skuDetailUnitsLabel,
                              controller: unitsCtrl,
                              hint: _data?['cartonQty']?.toString() ?? '1',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setS(() {}),
                            ),
                          ),
                        ],
                      ),
                    ] else if (inputMode == 'boxesOnly') ...[
                      _LabeledInput(
                        label: AppLocalizations.of(ctx)!.skuDetailBoxesLabel,
                        controller: boxesCtrl,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setS(() {}),
                      ),
                    ] else ...[
                      _LabeledInput(
                        label: AppLocalizations.of(ctx)!.skuDetailTotalLabel,
                        controller: qtyCtrl,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setS(() {}),
                      ),
                    ],

                    // Preview
                    if (previewQty > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _greenBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          inputMode == 'carton'
                              ? AppLocalizations.of(ctx)!.skuDetailInitialPreviewCarton(previewBoxes, previewUnits, previewQty)
                              : inputMode == 'boxesOnly'
                                  ? AppLocalizations.of(ctx)!.skuDetailInitialPreviewBoxOnly(previewQty)
                                  : AppLocalizations.of(ctx)!.skuDetailInitialPreviewQty(previewQty),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _greenText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 14),

                  // ── Note ─────────────────────────────────────────────────
                  Text(
                    AppLocalizations.of(ctx)!.skuDetailNoteLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SheetInput(
                    controller: noteCtrl,
                    hint: AppLocalizations.of(ctx)!.inventoryAddNoteHint,
                  ),

                  // Error
                  if (sheetError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      sheetError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Action buttons ───────────────────────────────────────
                  Row(
                    children: [
                      // Cancel
                      Expanded(
                        child: GestureDetector(
                          onTap: saving ? null : () => ctx.pop(),
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3F0),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              AppLocalizations.of(ctx)!.cancel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6E6E80),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Confirm
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: saving
                              ? null
                              : () async {
                                  String? locId = selectedLocationId;
                                  final sl10n = AppLocalizations.of(ctx)!;
                                  if (!isNewLoc && locId == null) {
                                    setS(() => sheetError = sl10n.inventorySelectOrCreate);
                                    return;
                                  }
                                  int boxes = 0, units = 0;
                                  int? initialQty; // for qty mode only
                                  if (isPending) {
                                    boxes = 0;
                                    units = 1;
                                  } else if (inputMode == 'carton') {
                                    boxes = int.tryParse(boxesCtrl.text) ?? 0;
                                    units = int.tryParse(unitsCtrl.text) ?? 0;
                                    if (boxes <= 0) {
                                      setS(() => sheetError = sl10n.skuDetailValidBoxes);
                                      return;
                                    }
                                    if (units <= 0) {
                                      setS(() => sheetError = sl10n.skuDetailValidBoxes);
                                      return;
                                    }
                                  } else if (inputMode == 'boxesOnly') {
                                    boxes = int.tryParse(boxesCtrl.text) ?? 0;
                                    units = 1;
                                    if (boxes <= 0) {
                                      setS(() => sheetError = sl10n.skuDetailValidBoxesOnly);
                                      return;
                                    }
                                  } else {
                                    // qty mode: store as loosePcs via stockIn after create
                                    final qty = int.tryParse(qtyCtrl.text) ?? 0;
                                    if (qty <= 0) {
                                      setS(() => sheetError = sl10n.skuDetailValidQty);
                                      return;
                                    }
                                    initialQty = qty;
                                  }
                                  setS(() { saving = true; sheetError = null; });
                                  try {
                                    if (isNewLoc) {
                                      final code = newLocCodeCtrl.text.trim().toUpperCase();
                                      if (code.isEmpty) {
                                        setS(() { saving = false; sheetError = sl10n.inventoryLocationCodeEmpty; });
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
                                    final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                                    final skuCode = _data!['sku'] as String;
                                    await _inventoryService.create(
                                      skuCode: skuCode,
                                      locationId: locId!,
                                      boxes: initialQty != null ? 0 : boxes,
                                      unitsPerBox: initialQty != null ? null : units,
                                      note: note,
                                      pendingCount: isPending,
                                      boxesOnlyMode: inputMode == 'boxesOnly',
                                    );
                                    // qty mode: add the initial stock as loosePcs
                                    if (initialQty != null) {
                                      await _inventoryService.stockIn(
                                        skuCode: skuCode,
                                        locationId: locId!,
                                        addQuantity: initialQty,
                                        note: note,
                                      );
                                    }
                                    if (ctx.mounted) ctx.pop();
                                    _load();
                                  } catch (e) {
                                    final msg = e is DioException
                                        ? (e.response?.data?['message'] ?? sl10n.pwdResetOperationFailed)
                                        : '${sl10n.pwdResetOperationFailed}: $e';
                                    setS(() {
                                      saving = false;
                                      sheetError = msg is List
                                          ? msg.join(', ')
                                          : msg.toString();
                                    });
                                  }
                                },
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: (isPending ? Colors.orange.shade600 : _primary)
                                  .withValues(alpha: saving ? 0.5 : 0.9),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: saving
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: (isPending ? Colors.orange : _primary)
                                            .withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            alignment: Alignment.center,
                            child: saving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    isPending ? AppLocalizations.of(ctx)!.skuDetailConfirmPending : AppLocalizations.of(ctx)!.skuDetailCreate,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Delete inventory ───────────────────────────────────────────────────────

  Future<void> _deleteInventory(InventoryRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    final loc = record.locationId is Map ? record.locationId['code'] : '?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skuDetailDeleteConfirmTitle),
        content: Text(l10n.skuDetailDeleteConfirmContent(loc, _data?['sku'] ?? '')),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => ctx.pop(true),
            child: Text(l10n.skuDetailDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _inventoryService.delete(record.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.skuDetailDeleteFailed(e.toString()))));
      }
    }
  }

  // ── Archive / Restore ──────────────────────────────────────────────────────

  Future<void> _archiveSku() async {
    final l10n = AppLocalizations.of(context)!;
    final data = _data!;
    final skuCode = data['sku'] as String;
    final inventoryList = (data['inventory'] as List?) ?? [];
    final String content = inventoryList.isNotEmpty
        ? l10n.skuDetailArchiveWithStockContent(skuCode, inventoryList.length)
        : l10n.skuDetailArchiveContent(skuCode);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skuDetailArchiveTitle),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade700),
            onPressed: () => ctx.pop(true),
            child: Text(l10n.skuDetailConfirmArchive),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _skuService.archive(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.skuDetailArchived(skuCode))));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.skuDetailOperationFailed(e.toString())), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _restoreSku() async {
    final l10n = AppLocalizations.of(context)!;
    final skuCode = _data?['sku'] as String? ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.skuDetailRestoreTitle),
        content: Text(l10n.skuDetailRestoreContent(skuCode)),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => ctx.pop(true), child: Text(l10n.skuDetailConfirmRestore)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _skuService.restore(widget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.skuDetailRestored(skuCode))));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.skuDetailOperationFailed(e.toString())), backgroundColor: Colors.red));
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // ── Header (shared across loading/error/loaded states) ────────────────
    Widget header = Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/skus'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: _titleColor),
            ),
          ),
          Expanded(
            child: Text(
              _data?['sku'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _titleColor,
                letterSpacing: -0.16,
              ),
            ),
          ),
          if (_data != null && user?.isAdmin == true)
            GestureDetector(
              onTap: ((_data!['status'] as String? ?? 'active') == 'archived')
                  ? _restoreSku
                  : _archiveSku,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  ((_data!['status'] as String? ?? 'active') == 'archived')
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 18,
                  color: _mutedColor,
                ),
              ),
            ),
          if (_data != null)
            GestureDetector(
              onTap: () => context.push('/skus/new', extra: _data).then((_) => _load()),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.edit_outlined, size: 15, color: _titleColor),
              ),
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );

    if (_loading) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              header,
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: Column(
            children: [
              header,
              Expanded(child: ErrorView(message: _error!, onRetry: _load)),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    final isArchived = (data['status'] as String? ?? 'active') == 'archived';
    final inventory = (data['inventory'] as List?)
        ?.map((e) => InventoryRecord.fromJson(e))
        .toList() ?? [];

    final locCount     = inventory.length;
    final cartonQty    = data['cartonQty'] as int?;
    final totalConfiguredCartons = inventory.fold(0, (int s, r) => s + (r.boxes - r.unconfiguredCartons));
    final totalNoSpecCartons     = inventory.fold(0, (int s, r) => s + r.unconfiguredCartons);
    final totalLoosePcs          = inventory.fold(0, (int s, r) => s + r.loosePcs);
    // Map<unitsPerBox, totalBoxes> aggregated across all locations
    final specMap = <int, int>{};
    for (final r in inventory) {
      for (final c in r.configurations) {
        specMap[c.unitsPerBox] = (specMap[c.unitsPerBox] ?? 0) + c.boxes;
      }
    }
    final distinctSpecCount = specMap.length;

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            header,
            const SizedBox(height: 12),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // ── Archived banner ────────────────────────────────────
                  if (isArchived)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.archive_outlined, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.skuDetailArchivedNotice,
                              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Summary card ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Stats grid: left big + right small
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: total boxes (always boxes, not pieces)
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 98),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _inputBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.widgets_outlined,
                                            size: 12, color: _hintColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.skuDetailTotalStock,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: _hintColor,
                                            letterSpacing: 0.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      buildStockLabel(
                                        configuredCartons: totalConfiguredCartons,
                                        noSpecCartons:     totalNoSpecCartons,
                                        loosePcs:          totalLoosePcs,
                                        cartonQty:         cartonQty,
                                        l10n:              l10n,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: _titleColor,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    if (distinctSpecCount > 0) ...[
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: () => setState(() => _specsExpanded = !_specsExpanded),
                                        behavior: HitTestBehavior.opaque,
                                        child: Row(
                                          children: [
                                            Text(
                                              l10n.skuDetailSpecCount(distinctSpecCount),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: _mutedColor,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            AnimatedRotation(
                                              turns: _specsExpanded ? 0.5 : 0,
                                              duration: const Duration(milliseconds: 200),
                                              child: const Icon(
                                                Icons.expand_more,
                                                size: 14,
                                                color: _mutedColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeInOut,
                                        child: _specsExpanded
                                            ? Padding(
                                                padding: const EdgeInsets.only(top: 8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: specMap.entries.map((e) {
                                                    return Padding(
                                                      padding: const EdgeInsets.only(bottom: 3),
                                                      child: Text(
                                                        l10n.locDetailConfigCarton(e.value, e.key),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: _mutedColor,
                                                        ),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right: location count only (fixed 98px, top-aligned)
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 100,
                                height: 98,
                                padding: const EdgeInsets.only(left: 14),
                                decoration: BoxDecoration(
                                  color: _inputBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 12, color: _hintColor),
                                    const SizedBox(width: 10),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.skuDetailLocationCol,
                                          style: const TextStyle(fontSize: 10, color: _hintColor),
                                        ),
                                        Text(
                                          '$locCount',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: _titleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (cartonQty != null) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFF2F1EF)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                l10n.skuDetailDefaultCarton,
                                style: const TextStyle(fontSize: 12, color: _hintColor),
                              ),
                              const Spacer(),
                              Text(
                                l10n.skuDetailCartonQtyDisplay(cartonQty as int),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5A5A6E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Inventory locations section ─────────────────────────
                  Text(
                    l10n.skuDetailStockLocations,
                    style: const TextStyle(fontSize: 12, color: _hintColor),
                  ),
                  const SizedBox(height: 10),

                  // Location cards
                  ...inventory.map((record) {
                    final loc = record.locationId is Map
                        ? Location.fromJson(record.locationId)
                        : null;
                    final locId = loc?.id ??
                        (record.locationId is Map ? record.locationId['_id'] : null);

                    return _LocationCard(
                      record: record,
                      location: loc,
                      canEdit: user?.canEdit == true,
                      cartonQty: cartonQty,
                      onTap: locId != null
                          ? () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              builder: (_) => InventoryDetailSheet(
                                skuCode: data['sku'] as String,
                                skuId: widget.id,
                                locationId: locId,
                                locationCode: loc?.code ?? '',
                                totalQty: record.totalQty,
                                boxes: record.boxes,
                                unitsPerBox: record.unitsPerBox,
                                configurations: record.configurations,
                                inventoryRecordId: record.id,
                                showLocNav: true,
                                canEdit: user?.canEdit == true,
                                canStockIn: user?.can('inv:stock_in') == true,
                                canStockOut: user?.can('inv:stock_out') == true,
                                canAdjust: user?.can('inv:adjust') == true,
                                quantityUnknown: record.quantityUnknown,
                                onChanged: _load,
                              ),
                            )
                          : null,
                      onDelete: () => _deleteInventory(record),
                    );
                  }),

                  // ── Add location dashed button ─────────────────────────
                  if (user?.canEdit == true && !isArchived) ...[
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: _showAddLocationSheet,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFDDDBD7),
                            width: 1.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 14, color: _hintColor),
                            const SizedBox(width: 6),
                            Text(
                              l10n.skuDetailAddLocation,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location card ──────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final InventoryRecord record;
  final Location? location;
  final bool canEdit;
  final int? cartonQty;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const _LocationCard({
    required this.record,
    required this.location,
    required this.canEdit,
    this.cartonQty,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final String subtitle;
    if (record.quantityUnknown) {
      subtitle = l10n.skuDetailQtyLinePending;
    } else {
      subtitle = buildStockLabel(
        configuredCartons: record.boxes - record.unconfiguredCartons,
        noSpecCartons:     record.unconfiguredCartons,
        loosePcs:          record.loosePcs,
        cartonQty:         cartonQty,
        l10n:              l10n,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
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
            child: Row(
              children: [
                // Location icon square
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: _mutedColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Code + (pending badge only) + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            location?.code ?? l10n.skuDetailUnknownLocation,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _titleColor,
                            ),
                          ),
                          if (record.quantityUnknown) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.skuDetailBadgePending,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFD4820A),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: _mutedColor),
                      ),
                    ],
                  ),
                ),

                // More menu (edit permission only)
                if (canEdit)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, size: 18, color: _hintColor),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(ctx)!.skuDetailStockDelete, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const Icon(Icons.more_horiz, size: 18, color: _hintColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom-sheet helper widgets ────────────────────────────────────────────────

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? _titleColor : const Color(0xFF9A99A5),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const _SheetInput({
    required this.controller,
    required this.hint,
    this.icon,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            const SizedBox(width: 16),
            Icon(icon, size: 14, color: _hintColor),
            const SizedBox(width: 10),
          ] else
            const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: textCapitalization,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: _titleColor),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    const TextStyle(fontSize: 14, color: Color(0xFFC5C5CE)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixIcon: suffix,
                suffixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _LabeledInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: _hintColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: _inputBg,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: _titleColor),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(fontSize: 14, color: Color(0xFFC5C5CE)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
