import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../widgets/audit_log_detail_sheet.dart';
import '../services/history_service.dart';
import '../services/inventory_service.dart';
import '../services/sku_service.dart';
import '../models/inventory.dart';
import '../models/change_record.dart';
import '../models/sku.dart';

class InventoryDetailSheet extends StatefulWidget {
  final String skuCode;
  final String? skuId;
  final String locationId;
  final String locationCode;
  final int totalQty;
  final int boxes;
  final int unitsPerBox;
  final List<InventoryConfig> configurations;
  final String? inventoryRecordId; // for edit/delete
  final bool showSkuNav;
  final bool showLocNav;
  // Granular permission flags — pass from parent based on user.can*
  final bool canEdit;    // legacy alias: shows all three buttons (supervisor+)
  final bool canStockIn;
  final bool canStockOut;
  final bool canAdjust;
  final bool quantityUnknown;
  final VoidCallback? onChanged; // called after any mutation

  const InventoryDetailSheet({
    super.key,
    required this.skuCode,
    this.skuId,
    required this.locationId,
    required this.locationCode,
    required this.totalQty,
    required this.boxes,
    required this.unitsPerBox,
    this.configurations = const [],
    this.inventoryRecordId,
    this.showSkuNav = false,
    this.showLocNav = false,
    this.canEdit = false,
    this.canStockIn = false,
    this.canStockOut = false,
    this.canAdjust = false,
    this.quantityUnknown = false,
    this.onChanged,
  });

  @override
  State<InventoryDetailSheet> createState() => _InventoryDetailSheetState();
}

class _InventoryDetailSheetState extends State<InventoryDetailSheet> {
  final _historyService = HistoryService();
  final _invService = InventoryService();
  List<ChangeRecord>? _recentRecords; // recent 5 audit log entries for this SKU+loc
  InventoryRecord? _invRecord;
  bool _loading = true;
  String? _error;

  // Permission helpers — honour both legacy canEdit and granular flags
  bool get _canStockIn  => widget.canStockIn  || widget.canEdit;
  bool get _canStockOut => widget.canStockOut || widget.canEdit;
  bool get _canAdjust   => widget.canAdjust   || widget.canEdit;

  bool get _isPending {
    final r = _invRecord;
    if (r == null) return false;
    return r.pendingCount ||
        r.stockStatus == 'pending_count' ||
        r.stockStatus == 'temporary';
  }

  /// Converts a raw exception into a short user-friendly message.
  String _friendly(Object e, AppLocalizations l10n) {
    // Dio 5.x: response body is in e.response.data, NOT in toString().
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.first.toString();
      }
      final code = e.response?.statusCode;
      if (code == 403) return l10n.errPermissionDenied;
      if (code == 401) return l10n.errSessionExpired;
      if (code == 404) return l10n.errResourceNotFound;
      if (code != null && code >= 400) return l10n.errRequestFailed(code);
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return l10n.errCannotConnectServer;
      }
      return l10n.errNetworkFailed;
    }
    return l10n.errOperationFailed;
  }

  // Live getters — prefer freshly-loaded data over stale widget props
  int get _qty => _invRecord?.totalQty ?? widget.totalQty;
  int get _boxes => _invRecord?.boxes ?? widget.boxes;
  int get _units => _invRecord?.unitsPerBox ?? widget.unitsPerBox;
  bool get _quantityUnknown => _invRecord?.quantityUnknown ?? widget.quantityUnknown;
  bool get _boxesOnlyMode => _invRecord?.boxesOnlyMode ?? false;
  String _qtyLabel(AppLocalizations l10n) {
    if (_quantityUnknown) return l10n.invDetailQtyUnknown;
    if (_boxesOnlyMode) return l10n.invDetailBoxesValue(_boxes);
    final pcsStr = '$_qty ${l10n.invDetailPieceSuffix}';
    if (_boxes > 0) return '$pcsStr · $_boxes ${l10n.invDetailBoxesSuffix}';
    return pcsStr;
  }
  List<InventoryConfig> get _configs =>
      _invRecord != null ? _invRecord!.configurations : widget.configurations;

  /// Builds the spec subtitle shown in the sheet header.
  /// Shows each carton spec as "N ctn × M pcs/ctn", then unconfigured cartons,
  /// then loose pcs — clearly separated with " + ".
  String _buildSpecSubtitle(AppLocalizations l10n) {
    if (_quantityUnknown) return l10n.invDetailQtyUnknownHeader;

    final parts = <String>[];

    // Each carton spec with a known unitsPerBox
    for (final c in _configs) {
      parts.add(l10n.locDetailConfigCarton(c.boxes, c.unitsPerBox));
    }

    // Cartons without a per-box spec
    final noSpec = _invRecord?.unconfiguredCartons ?? 0;
    if (noSpec > 0) parts.add('$noSpec ${l10n.unitBox} ${l10n.skuNoSpec}');

    // Loose pieces
    final loose = _invRecord?.loosePcs ?? 0;
    if (loose > 0) parts.add('$loose ${l10n.unitPiece}');

    if (parts.isNotEmpty) return parts.join('\n');

    // Fallback for legacy records (flat boxes/unitsPerBox, no configurations)
    if (_boxesOnlyMode) return l10n.invDetailBoxesOnlyHeader(_boxes);
    return l10n.invDetailBoxesAndPcs(_boxes, _qty);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      // Critical: load current inventory state
      final invList = await _invService.getAll(
          skuCode: widget.skuCode, locationId: widget.locationId);
      if (invList.isNotEmpty && mounted) _invRecord = invList.first;

      // Non-critical: load recent 5 audit log entries for this SKU+location
      try {
        final data = await _historyService.getAll(
          entity: 'inventory',
          skuCode: widget.skuCode,
          locationCode: widget.locationCode,
          page: 1,
          limit: 5,
        );
        if (mounted) {
          setState(() => _recentRecords = data['records'] as List<ChangeRecord>);
        }
      } catch (_) {
        if (mounted) setState(() => _recentRecords = []);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _viewAllHistory() {
    context.push('/inventory/history', extra: {
      'skuCode': widget.skuCode,
      'locationId': widget.locationId,
      'locationCode': widget.locationCode,
      'skuId': widget.skuId,
    });
  }

  // ── 入库 ──
  Future<void> _showStockInDialog() async {
    final l10n = AppLocalizations.of(context)!;

    // Mode A: multi-row config list (up to 3 specs)
    // Pre-fill pcs/carton with existing inventory value if available
    final existingUnits = _units > 0 ? _units.toString() : '';
    final List<Map<String, TextEditingController>> configRows = [
      {'boxes': TextEditingController(), 'units': TextEditingController(text: existingUnits)},
    ];
    final boxesOnlyCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String stockInMode = 'carton'; // 'carton' | 'boxesOnly' | 'qty'
    bool isPending = false;
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // Total qty from all config rows
          int configsTotal = 0;
          for (final row in configRows) {
            final b = int.tryParse(row['boxes']!.text) ?? 0;
            final u = int.tryParse(row['units']!.text) ?? 0;
            configsTotal += b * u;
          }

          final previewQty = stockInMode == 'carton' && !isPending
              ? configsTotal
              : stockInMode == 'qty' && !isPending
                  ? (int.tryParse(qtyCtrl.text) ?? 0)
                  : 0;
          final previewBoxes = stockInMode == 'boxesOnly'
              ? (int.tryParse(boxesOnlyCtrl.text) ?? 0)
              : 0;

          final accentColor =
              isPending ? Colors.orange.shade600 : Colors.green.shade600;

          Widget inputArea() {
            if (stockInMode == 'boxesOnly') {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: boxesOnlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _roundedDec(l10n.invDetailBoxesLabel,
                      suffix: l10n.invDetailBoxesSuffix),
                  onChanged: (_) => setS(() {}),
                ),
                if (previewBoxes > 0) ...[
                  const SizedBox(height: 10),
                  _previewCard(
                    isPending ? l10n.invDetailPendingBoxes : l10n.invDetailStockInBoxes,
                    l10n.invDetailBoxesValue(previewBoxes),
                    accentColor,
                    sub: l10n.invDetailCartonTBD,
                  ),
                ],
              ]);
            } else if (stockInMode == 'carton' && !isPending) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Multi-spec rows
                ...configRows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      // Row number badge
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text('${idx + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      // Cartons field
                      Expanded(
                        child: TextField(
                          controller: row['boxes'],
                          keyboardType: TextInputType.number,
                          decoration: _roundedDec(l10n.invDetailBoxesLabel,
                              suffix: l10n.invDetailBoxesSuffix),
                          onChanged: (_) => setS(() {}),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('×', style: TextStyle(fontSize: 16,
                            color: Colors.grey)),
                      ),
                      // Pcs/carton field
                      Expanded(
                        child: TextField(
                          controller: row['units'],
                          keyboardType: TextInputType.number,
                          decoration: _roundedDec(l10n.invDetailUnitsPerBoxLabel,
                              suffix: l10n.invDetailUnitsPerBoxSuffix),
                          onChanged: (_) => setS(() {}),
                        ),
                      ),
                      // Remove row button (only when >1 row)
                      if (configRows.length > 1)
                        GestureDetector(
                          onTap: () => setS(() {
                            row['boxes']!.dispose();
                            row['units']!.dispose();
                            configRows.removeAt(idx);
                          }),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(Icons.remove_circle_outline,
                                size: 20, color: Colors.red.shade400),
                          ),
                        ),
                    ]),
                  );
                }),
                // Add spec row button (up to 3)
                if (configRows.length < 3)
                  TextButton.icon(
                    onPressed: () => setS(() => configRows.add(
                      {'boxes': TextEditingController(), 'units': TextEditingController()},
                    )),
                    icon: Icon(Icons.add_circle_outline,
                        size: 16, color: Colors.green.shade600),
                    label: Text(l10n.invDetailAddConfigRow,
                        style: TextStyle(fontSize: 13, color: Colors.green.shade600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (previewQty > 0) ...[
                  const SizedBox(height: 10),
                  _previewCard(
                    l10n.invDetailStockInTotal,
                    l10n.invDetailAddQty(previewQty),
                    Colors.green.shade600,
                    sub: l10n.invDetailNewTotal(_qty + previewQty),
                  ),
                ],
              ]);
            } else if (stockInMode == 'qty' && !isPending) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _roundedDec(l10n.invDetailStockInQtyLabel,
                      suffix: l10n.invDetailPieceSuffix),
                  onChanged: (_) => setS(() {}),
                ),
                if (previewQty > 0) ...[
                  const SizedBox(height: 10),
                  _previewCard(
                    l10n.invDetailStockInTotal,
                    l10n.invDetailAddQty(previewQty),
                    Colors.green.shade600,
                    sub: l10n.invDetailNewTotal(_qty + previewQty),
                  ),
                ],
              ]);
            } else {
              // isPending + carton/qty mode: just show info
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.invDetailPendingMarkNote,
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800))),
                ]),
              );
            }
          }

          return _dialogWrapper(
            ctx: ctx,
            title: l10n.invDetailStockInTitle,
            body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.skuCode}  @  ${widget.locationCode}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    _invRecord?.pendingCount == true
                        ? l10n.invDetailCurrentStatusPending
                        : l10n.invDetailCurrentStock(_qtyLabel(l10n)),
                    style: TextStyle(fontSize: 12,
                        color: isPending ? Colors.orange.shade700 : Colors.green.shade700)),
                ]),
              ),
              const SizedBox(height: 14),
              // Pending toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  value: isPending,
                  onChanged: (v) => setS(() => isPending = v ?? false),
                  title: Text(l10n.inventoryPendingTitle,
                      style: const TextStyle(fontSize: 14)),
                  subtitle: Text(l10n.inventoryPendingSubtitle,
                      style: const TextStyle(fontSize: 12)),
                  secondary: Icon(Icons.pending_actions_outlined,
                      color: isPending ? Colors.orange : Colors.grey, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              // Mode selector
              _sectionLabel(l10n.invDetailQtyEntryMode),
              _modeSelector(
                ['carton', 'boxesOnly', 'qty'],
                [l10n.invDetailModeByCarton, l10n.invDetailModeBoxesOnly, l10n.invDetailModeByQty],
                stockInMode,
                (v) => setS(() { stockInMode = v; err = null; }),
              ),
              const SizedBox(height: 14),
              inputArea(),
              const SizedBox(height: 12),
              _noteField(noteCtrl),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ]),
            footer: Column(children: [
              _dialogActionBtn(
                label: isPending ? l10n.invDetailConfirmPendingBtn : l10n.invDetailConfirmStockIn,
                icon: Icons.download_outlined,
                color: accentColor,
                loading: saving,
                onPressed: saving
                    ? null
                    : () async {
                        if (stockInMode == 'boxesOnly') {
                          final boxes = int.tryParse(boxesOnlyCtrl.text) ?? 0;
                          if (boxes <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidBoxes);
                            return;
                          }
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.stockIn(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              boxes: boxes,
                              boxesOnlyMode: true,
                              pendingCount: isPending,
                              note: noteCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                          return;
                        }
                        if (isPending) {
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.markPending(
                              widget.inventoryRecordId!,
                              pending: true,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                          return;
                        }
                        if (stockInMode == 'carton') {
                          // Build configurations list, validate all rows
                          final configs = <Map<String, int>>[];
                          for (final row in configRows) {
                            final b = int.tryParse(row['boxes']!.text) ?? 0;
                            final u = int.tryParse(row['units']!.text) ?? 0;
                            if (b <= 0 || u <= 0) {
                              setS(() => err = l10n.invDetailErrInvalidBoxesAndUnits);
                              return;
                            }
                            configs.add({'boxes': b, 'unitsPerBox': u});
                          }
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.stockIn(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              configurations: configs,
                              note: noteCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                        } else {
                          // qty mode: send addQuantity directly
                          final qty = int.tryParse(qtyCtrl.text) ?? 0;
                          if (qty <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidQty);
                            return;
                          }
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.stockIn(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              addQuantity: qty,
                              note: noteCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                        }
                      },
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel,
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            ]),
          );
        },
      ),
    );

    // Dispose all controllers
    for (final row in configRows) {
      row['boxes']!.dispose();
      row['units']!.dispose();
    }
    boxesOnlyCtrl.dispose();
    qtyCtrl.dispose();
    noteCtrl.dispose();
  }

  // ── 出库 ──
  Future<void> _showStockOutDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final effectiveConfigs = _configs.isNotEmpty
        ? _configs
        : (_boxes > 0
            ? [InventoryConfig(boxes: _boxes, unitsPerBox: _units)]
            : <InventoryConfig>[]);

    // 'carton' | 'boxesOnly' | 'qty'
    String stockOutMode = effectiveConfigs.isNotEmpty ? 'carton' : 'qty';

    // 按箱规 controllers (one per config row)
    final configCtrls = List.generate(
        effectiveConfigs.length, (_) => TextEditingController(text: '0'));
    // 仅箱数 controller
    final boxesOnlyCtrl = TextEditingController(text: '0');
    // 按总数量 controller
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // ── live calculations ──
          final configTotal = List.generate(effectiveConfigs.length, (i) {
            final b = int.tryParse(configCtrls[i].text) ?? 0;
            return b * effectiveConfigs[i].unitsPerBox;
          }).fold<int>(0, (a, b) => a + b);

          final totalOutBoxes = stockOutMode == 'carton'
              ? List.generate(effectiveConfigs.length,
                      (i) => int.tryParse(configCtrls[i].text) ?? 0)
                  .fold<int>(0, (a, b) => a + b)
              : stockOutMode == 'boxesOnly'
                  ? (int.tryParse(boxesOnlyCtrl.text) ?? 0)
                  : 0;
          final totalAvailableBoxes =
              effectiveConfigs.fold<int>(0, (s, c) => s + c.boxes);

          final previewOut = stockOutMode == 'carton'
              ? configTotal
              : stockOutMode == 'boxesOnly'
                  ? totalOutBoxes * (_units > 0 ? _units : 1)
                  : (int.tryParse(qtyCtrl.text) ?? 0);

          final isOverLimit = stockOutMode == 'carton'
              ? totalOutBoxes > totalAvailableBoxes
              : stockOutMode == 'boxesOnly'
                  ? totalOutBoxes > _boxes
                  : (_qty > 0 && previewOut > _qty);

          Widget inputArea() {
            if (stockOutMode == 'carton') {
              if (effectiveConfigs.isEmpty) {
                return Text(l10n.invDetailNoCartonData,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ...List.generate(effectiveConfigs.length, (i) {
                  final cfg = effectiveConfigs[i];
                  final outBoxes = int.tryParse(configCtrls[i].text) ?? 0;
                  final overLimit = outBoxes > cfg.boxes;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Read-only pcs/box badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.invDetailUnitsPerBoxLabel,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Container(
                            width: 88,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${cfg.unitsPerBox} ${l10n.invDetailPieceSuffix}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 28, left: 10, right: 10),
                        child: Text('×',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      ),
                      // Boxes input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.invDetailOutBoxesColHeader,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            const SizedBox(height: 4),
                            TextField(
                              controller: configCtrls[i],
                              keyboardType: TextInputType.number,
                              decoration: _roundedDec(
                                l10n.invDetailOutMaxBoxes(cfg.boxes),
                                suffix: l10n.invDetailBoxesSuffix,
                              ).copyWith(
                                errorText: overLimit ? l10n.invDetailExceedBoxes(cfg.boxes) : null,
                              ),
                              onChanged: (_) => setS(() {}),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  );
                }),
              ]);
            } else if (stockOutMode == 'boxesOnly') {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: boxesOnlyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _roundedDec(l10n.invDetailOutBoxesLabel(_boxes),
                      suffix: l10n.invDetailBoxesSuffix),
                  onChanged: (_) => setS(() {}),
                ),
                const SizedBox(height: 6),
                Text(l10n.invDetailBoxesOnlyHelp,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ]);
            } else {
              return TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: _roundedDec(l10n.invDetailOutQtyLabel,
                    suffix: l10n.invDetailPieceSuffix),
                onChanged: (_) => setS(() {}),
              );
            }
          }

          return _dialogWrapper(
            ctx: ctx,
            title: l10n.invDetailStockOutTitle,
            body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${widget.skuCode}  @  ${widget.locationCode}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_buildSpecSubtitle(l10n),
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                ]),
              ),
              const SizedBox(height: 14),
              _sectionLabel(l10n.invDetailQtyEntryMode),
              _modeSelector(
                ['carton', 'boxesOnly', 'qty'],
                [l10n.invDetailModeByCarton, l10n.invDetailModeBoxesOnly, l10n.invDetailModeByQty],
                stockOutMode,
                (v) => setS(() { stockOutMode = v; err = null; }),
              ),
              const SizedBox(height: 14),
              inputArea(),
              const SizedBox(height: 10),
              // Preview
              _previewCard(
                l10n.invDetailOutTotal,
                stockOutMode == 'boxesOnly'
                    ? l10n.invDetailOutBoxesValue(totalOutBoxes)
                    : l10n.invDetailOutPcsValue(previewOut),
                isOverLimit ? Colors.red.shade600 : (previewOut > 0 || totalOutBoxes > 0)
                    ? Colors.orange.shade600 : Colors.grey.shade400,
                sub: (!isOverLimit && (previewOut > 0 || totalOutBoxes > 0))
                    ? (stockOutMode == 'carton'
                        ? l10n.invDetailRemainCartonBoxes(totalAvailableBoxes - totalOutBoxes)
                        : stockOutMode == 'boxesOnly'
                            ? l10n.invDetailRemainBoxes(_boxes - totalOutBoxes)
                            : l10n.invDetailRemainPcs(_qty - previewOut))
                    : null,
              ),
              const SizedBox(height: 12),
              _noteField(noteCtrl),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ]),
            footer: Column(children: [
              _dialogActionBtn(
                label: l10n.invDetailConfirmStockOut,
                icon: Icons.upload_outlined,
                color: Colors.red.shade500,
                loading: saving,
                onPressed: saving
                    ? null
                    : () async {
                        int qty = 0;
                        List<Map<String, int>>? removalConfigs;

                        if (stockOutMode == 'carton') {
                          for (int i = 0; i < effectiveConfigs.length; i++) {
                            final outBoxes = int.tryParse(configCtrls[i].text) ?? 0;
                            if (outBoxes < 0) {
                              setS(() => err = l10n.invDetailErrNegativeBoxes);
                              return;
                            }
                            if (outBoxes > effectiveConfigs[i].boxes) {
                              setS(() => err = l10n.invDetailErrExceedCartonBoxes(
                                  effectiveConfigs[i].unitsPerBox, effectiveConfigs[i].boxes));
                              return;
                            }
                          }
                          qty = configTotal;
                          if (qty <= 0) {
                            setS(() => err = l10n.invDetailErrAtLeastOneCarton);
                            return;
                          }
                          if (totalOutBoxes > totalAvailableBoxes) {
                            setS(() => err = l10n.invDetailErrExceedStockBoxes(totalAvailableBoxes));
                            return;
                          }
                          removalConfigs = List.generate(effectiveConfigs.length, (i) {
                            final outBoxes = int.tryParse(configCtrls[i].text) ?? 0;
                            return {'boxes': outBoxes, 'unitsPerBox': effectiveConfigs[i].unitsPerBox};
                          }).where((c) => c['boxes']! > 0).toList();
                        } else if (stockOutMode == 'boxesOnly') {
                          final outBoxes = int.tryParse(boxesOnlyCtrl.text) ?? 0;
                          if (outBoxes <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidBoxes);
                            return;
                          }
                          if (outBoxes > _boxes) {
                            setS(() => err = l10n.invDetailErrExceedStockBoxes(_boxes));
                            return;
                          }
                          removalConfigs = [{'boxes': outBoxes, 'unitsPerBox': _units > 0 ? _units : 1}];
                          qty = outBoxes * (_units > 0 ? _units : 1);
                        } else {
                          qty = int.tryParse(qtyCtrl.text) ?? 0;
                          if (qty <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidQty);
                            return;
                          }
                          if (_qty > 0 && qty > _qty) {
                            setS(() => err = l10n.invDetailErrExceedStockPcs(_qty));
                            return;
                          }
                        }

                        setS(() { saving = true; err = null; });
                        try {
                          await _invService.stockOut(
                            skuCode: widget.skuCode,
                            locationId: widget.locationId,
                            quantity: qty,
                            configurations: removalConfigs?.isNotEmpty == true ? removalConfigs : null,
                            note: noteCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          widget.onChanged?.call();
                          _load();
                        } catch (e) {
                          setS(() { saving = false; err = _friendly(e, l10n); });
                        }
                      },
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel, style: TextStyle(color: Colors.grey.shade600)),
              ),
            ]),
          );
        },
      ),
    );

    for (final ctrl in configCtrls) {
      ctrl.dispose();
    }
    boxesOnlyCtrl.dispose();
    qtyCtrl.dispose();
    noteCtrl.dispose();
  }

  // ── 库存调整（4种模式：按总数量 / 按箱规 / 仅箱数 / SKU更正） ──
  Future<void> _showAdjustDialog() async {
    final l10n = AppLocalizations.of(context)!;
    // 'mixed' | 'sku_correct'
    String adjustMode = 'mixed';

    // ── Mixed mode state: carton specs + loose pcs + only cartons ──
    // Initialise from live record: boxesOnlyMode → all boxes go to unconfiguredCartons
    final _initUnconfiguredCartons =
        _invRecord?.unconfiguredCartons ?? (_boxesOnlyMode ? _boxes : 0);
    final unconfiguredCartonsCtrl =
        TextEditingController(text: _initUnconfiguredCartons.toString());

    // Build config rows from configurations array.
    // Only fall back to a single flat-spec row for LEGACY records (unitsPerBox > 0,
    // no unconfiguredCartons). New-model records store cartons-without-spec in
    // unconfiguredCartons — never convert those into a carton-spec row.
    final configRows = _configs.isNotEmpty
        ? _configs
            .map((c) => <String, TextEditingController>{
                  'boxes': TextEditingController(text: c.boxes.toString()),
                  'units': TextEditingController(text: c.unitsPerBox.toString()),
                })
            .toList()
        : (!_boxesOnlyMode && _boxes > 0 && _units > 0 && _initUnconfiguredCartons == 0
            ? [<String, TextEditingController>{
                'boxes': TextEditingController(text: _boxes.toString()),
                'units': TextEditingController(text: _units.toString()),
              }]
            : <Map<String, TextEditingController>>[]);

    final loosePcsCtrl =
        TextEditingController(text: (_invRecord?.loosePcs ?? 0).toString());

    // ── SKU correct state ──
    Sku? selectedCorrectSku;

    // ── shared ──
    final noteCtrl = TextEditingController();
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // ── live totals (mixed mode) ──
          int configsPcs = 0;
          int totalCartons = 0;
          for (final row in configRows) {
            final b = int.tryParse(row['boxes']!.text) ?? 0;
            final u = int.tryParse(row['units']!.text) ?? 0;
            configsPcs += b * u;
            totalCartons += b;
          }
          final loosePcs = int.tryParse(loosePcsCtrl.text) ?? 0;
          final unconfiguredCartonsVal = int.tryParse(unconfiguredCartonsCtrl.text) ?? 0;
          final mixedTotal = configsPcs + loosePcs; // pcs only; unconfigured don't count
          final totalCartonsAll = totalCartons + unconfiguredCartonsVal;

          // ── header bar ──
          Widget headerBar() => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: adjustMode == 'sku_correct'
                      ? Colors.purple.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: adjustMode == 'sku_correct'
                        ? Colors.purple.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    adjustMode == 'sku_correct' ? Icons.find_replace : Icons.tune_outlined,
                    size: 18,
                    color: adjustMode == 'sku_correct'
                        ? Colors.purple.shade600 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.skuCode}  @  ${widget.locationCode}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(_buildSpecSubtitle(l10n),
                            style: TextStyle(
                                fontSize: 12,
                                color: adjustMode == 'sku_correct'
                                    ? Colors.purple.shade600 : Colors.orange.shade700)),
                      ],
                    ),
                  ),
                ]),
              );

          // ── Mixed panel: carton specs + loose pcs ──
          Widget mixedPanel() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // section label + add button
                  Row(children: [
                    Expanded(
                      child: Text(l10n.invDetailCartonSpecsLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 15),
                      label: Text(l10n.invDetailAddCarton,
                          style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => setS(() => configRows.add({
                        'boxes': TextEditingController(text: ''),
                        'units': TextEditingController(text: ''),
                      })),
                    ),
                  ]),
                  const SizedBox(height: 6),

                  // carton spec rows
                  if (configRows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.invDetailAddFirstCarton,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    )
                  else
                    ...configRows.asMap().entries.map((entry) {
                      final i = entry.key;
                      final row = entry.value;
                      final b = int.tryParse(row['boxes']!.text) ?? 0;
                      final u = int.tryParse(row['units']!.text) ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                          // numbered badge
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text('${i + 1}',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          const SizedBox(width: 6),
                          // pcs/carton
                          Expanded(
                            child: TextField(
                              controller: row['units'],
                              keyboardType: TextInputType.number,
                              decoration: _roundedDec(l10n.invDetailUnitsPerBoxLabel,
                                  suffix: l10n.invDetailPieceSuffix),
                              onChanged: (_) => setS(() {}),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                            child: Text('×', style: TextStyle(fontSize: 15, color: Colors.grey)),
                          ),
                          // cartons
                          Expanded(
                            child: TextField(
                              controller: row['boxes'],
                              keyboardType: TextInputType.number,
                              decoration: _roundedDec(l10n.invDetailBoxesAdjustLabel,
                                  suffix: l10n.invDetailBoxesSuffix),
                              onChanged: (_) => setS(() {}),
                            ),
                          ),
                          // subtotal
                          if (u > 0 && b > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text('=${b * u}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ),
                          // remove
                          GestureDetector(
                            onTap: () => setS(() {
                              final removed = configRows.removeAt(i);
                              removed['boxes']!.dispose();
                              removed['units']!.dispose();
                            }),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(Icons.remove_circle_outline,
                                  size: 18, color: Colors.red.shade300),
                            ),
                          ),
                        ]),
                      );
                    }),

                  const SizedBox(height: 4),
                  // Only cartons field (no pcs/carton spec)
                  TextField(
                    controller: unconfiguredCartonsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _roundedDec('Only cartons (no spec)',
                        suffix: l10n.invDetailBoxesSuffix),
                    onChanged: (_) => setS(() {}),
                  ),

                  const SizedBox(height: 4),
                  // Loose pcs field
                  TextField(
                    controller: loosePcsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _roundedDec(l10n.invDetailLoosePcsLabel,
                        suffix: l10n.invDetailPieceSuffix),
                    onChanged: (_) => setS(() {}),
                  ),

                  const SizedBox(height: 10),
                  // Summary preview
                  _previewCard(
                    l10n.invDetailAdjustedTotalRow,
                    '$mixedTotal ${l10n.invDetailPieceSuffix}'
                        '${totalCartonsAll > 0 ? '  ·  $totalCartonsAll ${l10n.invDetailBoxesSuffix}' : ''}',
                    mixedTotal != _qty ? Colors.orange : Colors.green,
                    sub: mixedTotal != _qty
                        ? '(${mixedTotal > _qty ? '+' : ''}${mixedTotal - _qty})'
                        : null,
                  ),
                ],
              );

          // ── SKU correct panel ──
          Widget skuCorrectPanel() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(children: [
                      Text(l10n.invDetailSkuCorrectCurrent,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Text(widget.skuCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 14, color: Colors.purple.shade400),
                      const SizedBox(width: 8),
                      Text(
                        selectedCorrectSku?.sku ?? l10n.invDetailSkuCorrectSelectHint,
                        style: TextStyle(
                          fontWeight: selectedCorrectSku != null ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                          color: selectedCorrectSku != null ? Colors.purple.shade700 : Colors.grey.shade400,
                        ),
                      ),
                      if (selectedCorrectSku != null)
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  _SkuSearchField(
                    labelText: l10n.invDetailSkuCorrectSearch,
                    excludeSkuCode: widget.skuCode,
                    onSelected: (sku) => setS(() => selectedCorrectSku = sku),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(l10n.invDetailQtyRetained(_qtyLabel(l10n)),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ]),
                  ),
                ],
              );

          final actionColor = adjustMode == 'sku_correct' ? Colors.purple : Colors.orange;
          final confirmLabel = adjustMode == 'sku_correct'
              ? l10n.invDetailConfirmSkuCorrect
              : l10n.invDetailConfirmAdjust;

          return _dialogWrapper(
            ctx: ctx,
            title: l10n.invDetailAdjustTitle,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerBar(),
                const SizedBox(height: 14),

                // mode selector: Mixed / SKU Correct
                _sectionLabel(l10n.invDetailQtyEntryMode),
                _modeSelector(
                  ['mixed', 'sku_correct'],
                  [
                    l10n.invDetailAdjustModeMixed,
                    l10n.invDetailAdjustModeSkuCorrect,
                  ],
                  adjustMode,
                  (v) => setS(() { adjustMode = v; err = null; selectedCorrectSku = null; }),
                ),
                const SizedBox(height: 14),

                if (adjustMode == 'mixed') mixedPanel(),
                if (adjustMode == 'sku_correct') skuCorrectPanel(),

                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: _roundedDec(
                    adjustMode == 'sku_correct'
                        ? l10n.invDetailReasonSkuCorrect
                        : l10n.invDetailReasonAdjust,
                    hint: adjustMode == 'sku_correct'
                        ? l10n.invDetailReasonSkuCorrectHint
                        : l10n.invDetailReasonAdjustHint,
                  ),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
            footer: Column(children: [
              _dialogActionBtn(
                label: confirmLabel,
                icon: adjustMode == 'sku_correct' ? Icons.find_replace : Icons.tune_outlined,
                color: actionColor,
                loading: saving,
                onPressed: saving
                    ? null
                    : () async {
                        final note = noteCtrl.text.trim();
                        if (note.isEmpty) {
                          setS(() => err = l10n.invDetailErrReasonRequired);
                          return;
                        }

                        // ── SKU correct submit ──
                        if (adjustMode == 'sku_correct') {
                          if (selectedCorrectSku == null) {
                            setS(() => err = l10n.invDetailErrSelectNewSku);
                            return;
                          }
                          if (selectedCorrectSku!.sku.toUpperCase() == widget.skuCode.toUpperCase()) {
                            setS(() => err = l10n.invDetailErrSameSkuNotAllowed);
                            return;
                          }
                          if (widget.inventoryRecordId == null) {
                            setS(() => err = l10n.invDetailErrNoInventoryId);
                            return;
                          }
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.correctSku(
                              inventoryId: widget.inventoryRecordId!,
                              newSkuCode: selectedCorrectSku!.sku,
                              note: note,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() => saving = false);
                            if (e is DioException &&
                                e.response?.data is Map &&
                                e.response?.data['code'] == 'MERGE_REQUIRED') {
                              final msg = e.response!.data['message'] as String;
                              if (!ctx.mounted) return;
                              final confirm = await showDialog<bool>(
                                context: ctx,
                                builder: (c) => AlertDialog(
                                  title: Text(l10n.invDetailMergeConfirmTitle),
                                  content: Text(msg),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: Text(l10n.cancel),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: Text(l10n.invDetailMergeConfirm),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              setS(() { saving = true; err = null; });
                              try {
                                await _invService.correctSku(
                                  inventoryId: widget.inventoryRecordId!,
                                  newSkuCode: selectedCorrectSku!.sku,
                                  note: note,
                                  allowMerge: true,
                                );
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                widget.onChanged?.call();
                                _load();
                              } catch (e2) {
                                setS(() { saving = false; err = _friendly(e2, l10n); });
                              }
                            } else {
                              setS(() => err = _friendly(e, l10n));
                            }
                          }
                          return;
                        }

                        // ── Mixed submit ──
                        if (adjustMode == 'mixed') {
                          final loose = int.tryParse(loosePcsCtrl.text) ?? 0;
                          final onlyCartons = int.tryParse(unconfiguredCartonsCtrl.text) ?? 0;
                          // Validate all non-empty spec rows
                          final configs = <Map<String, int>>[];
                          for (final row in configRows) {
                            final b = int.tryParse(row['boxes']!.text) ?? 0;
                            final u = int.tryParse(row['units']!.text) ?? 0;
                            if (b == 0 && u == 0) continue; // ignore blank rows
                            if (b <= 0 || u <= 0) {
                              setS(() => err = l10n.invDetailErrMixedInvalidSpec);
                              return;
                            }
                            configs.add({'boxes': b, 'unitsPerBox': u});
                          }
                          // all-zero is allowed: zero-out operation
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.stockAdjust(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              configurations: configs.isNotEmpty ? configs : null,
                              loosePcs: loose,
                              unconfiguredCartons: onlyCartons,
                              adjustMode: 'mixed',
                              note: note,
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                          return;
                        }

                      },
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel,
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            ]),
          );
        },
      ),
    );

    // Dispose all controllers
    for (final row in configRows) {
      row['boxes']?.dispose();
      row['units']?.dispose();
    }
    unconfiguredCartonsCtrl.dispose();
    loosePcsCtrl.dispose();
    noteCtrl.dispose();
  }

  // ── 共用 helper widgets ──
  // ── Dialog UI helpers ───────────────────────────────────────────────────────

  static const _kNavy = Color(0xFF1E293B);

  InputDecoration _roundedDec(String label, {String? suffix, String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kNavy, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white,
      );

  Widget _modeSelector(
    List<String> values,
    List<String> labels,
    String selected,
    void Function(String) onChange,
  ) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50),
      child: Row(
        children: List.generate(values.length, (i) {
          final sel = values[i] == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChange(values[i]),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? _kNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(labels[i],
                    style: TextStyle(
                        color: sel ? Colors.white : Colors.grey.shade600,
                        fontWeight:
                            sel ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _previewCard(String label, String value, Color color,
      {String? sub}) =>
      Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade700)),
            Row(children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color)),
              if (sub != null) ...[
                const SizedBox(width: 6),
                Text(sub,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ]),
          ],
        ),
      );

  Widget _dialogActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool loading = false,
  }) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: color.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26)),
            elevation: 0,
          ),
          onPressed: onPressed,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ]),
        ),
      );

  Widget _dialogWrapper({
    required BuildContext ctx,
    required String title,
    required Widget body,
    required Widget footer,
  }) =>
      Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle),
                            child: Icon(Icons.close,
                                size: 18,
                                color: Colors.grey.shade600),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      body,
                      const SizedBox(height: 8),
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: footer,
            ),
          ],
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
      );

  Widget _noteField(TextEditingController ctrl) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: ctrl,
      decoration: _roundedDec(l10n.invDetailNoteOptional),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
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

          // ── Header: icon + SKU·location title + qty subtitle ────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Grey circle icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.location_on_outlined,
                      size: 16, color: Color(0xFF8E8E9A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.skuCode} · ${widget.locationCode}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSpecSubtitle(l10n),
                        style: const TextStyle(
                            color: Color(0xFF8E8E9A), fontSize: 12),
                        maxLines: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Action buttons ───────────────────────────────────────────────
          if (_canStockIn || _canStockOut || _canAdjust)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Row(
                children: [
                  if (_canStockIn) ...[
                    _FigmaActionBtn(
                      label: l10n.invDetailStockIn,
                      icon: Icons.south_outlined,
                      bg: const Color(0xFFEEF6EF),
                      border: const Color(0xFFD4E8D8),
                      fg: const Color(0xFF5A9A6B),
                      onTap: _showStockInDialog,
                    ),
                  ],
                  if (_canStockIn && (_canStockOut || _canAdjust))
                    const SizedBox(width: 10),
                  if (_canStockOut) ...[
                    _FigmaActionBtn(
                      label: l10n.invDetailStockOut,
                      icon: Icons.north_outlined,
                      bg: const Color(0xFFFEF2F2),
                      border: const Color(0xFFF0D4D4),
                      fg: const Color(0xFFC07068),
                      onTap: _showStockOutDialog,
                    ),
                  ],
                  if (_canStockOut && _canAdjust) const SizedBox(width: 10),
                  if (_canAdjust) ...[
                    _FigmaActionBtn(
                      label: l10n.invDetailAdjust,
                      icon: Icons.tune,
                      bg: const Color(0xFFFDF5E8),
                      border: const Color(0xFFEDDCB8),
                      fg: const Color(0xFFD4A020),
                      onTap: _showAdjustDialog,
                    ),
                  ],
                ],
              ),
            ),

          // ── Pending confirm / split row ───────────────────────────────────
          if (_isPending && _canAdjust)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle_outline,
                          size: 15, color: Colors.teal),
                      label: Text(l10n.invDetailConfirmPendingLabel,
                          style: const TextStyle(color: Colors.teal, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side:
                            BorderSide(color: Colors.teal.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                      ),
                      onPressed: _showConfirmPendingDialog,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.call_split,
                          size: 15, color: Colors.deepPurple),
                      label: Text(l10n.invDetailSplitPendingLabel,
                          style:
                              const TextStyle(color: Colors.deepPurple, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.deepPurple.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                      ),
                      onPressed: _showSplitPendingDialog,
                    ),
                  ),
                ],
              ),
            ),

          // ── Nav links ─────────────────────────────────────────────────────
          if (widget.showSkuNav && widget.skuId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    context.pop();
                    context.push('/skus/${widget.skuId}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 13,
                          color: const Color(0xFF4A6CF7).withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        l10n.invDetailSkuDetail,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A6CF7).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.showLocNav)
            Padding(
              padding: EdgeInsets.fromLTRB(24, widget.showSkuNav && widget.skuId != null ? 4 : 6, 24, 0),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    context.pop();
                    context.push('/locations/${widget.locationId}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new, size: 13,
                          color: const Color(0xFF4A6CF7).withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        l10n.invDetailLocDetail,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A6CF7).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Divider ──────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Divider(height: 1, color: Color(0xFFF2F1EF)),
          ),

          // ── 最近操作 header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 17, 24, 0),
            child: Row(
              children: [
                Text(
                  l10n.invDetailRecentOps,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB5B5C0)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _viewAllHistory,
                  child: Text(
                    l10n.invDetailViewAll,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A6CF7).withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── History list ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.invDetailLoadFailed),
                          onPressed: _load,
                        ))
                    : (_recentRecords == null || _recentRecords!.isEmpty)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history_outlined,
                                    size: 24, color: Color(0xFFC5C5CE)),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.invDetailNoRecords,
                                  style: const TextStyle(
                                      color: Color(0xFFC5C5CE),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            itemCount: _recentRecords!.length + 1,
                            itemBuilder: (_, i) {
                              if (i == _recentRecords!.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.history,
                                        size: 16),
                                    label: Text(l10n.invDetailViewAll),
                                    onPressed: _viewAllHistory,
                                  ),
                                );
                              }
                              final r = _recentRecords![i];
                              return _AuditCard(record: r);
                            },
                          ),
          ),
        ],
        ),
      ),
    );
  }

  // ── 确认为正式 ──
  Future<void> _showConfirmPendingDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final noteCtrl = TextEditingController();
    bool changeSku = false;
    Sku? selectedNewSku;
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l10n.invDetailConfirmOfficialTitle),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.skuCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('${widget.locationCode}  ·  $_qtyLabel',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(height: 2),
                        Text(l10n.invDetailPendingToOfficial,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.teal,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional SKU change toggle
                  Row(
                    children: [
                      Checkbox(
                        value: changeSku,
                        onChanged: (v) => setS(() {
                          changeSku = v ?? false;
                          if (!changeSku) selectedNewSku = null;
                        }),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Text(l10n.invDetailCorrectSkuCode, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (changeSku) ...[
                    const SizedBox(height: 6),
                    _SkuSearchField(
                      labelText: l10n.invDetailSearchNewSku,
                      excludeSkuCode: widget.skuCode,
                      onSelected: (sku) => setS(() {
                        selectedNewSku = sku;
                        err = null;
                      }),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Note field
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.invDetailConfirmReasonLabel,
                      hintText: l10n.invDetailConfirmReasonHint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setS(() => err = null),
                  ),

                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!,
                        style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final note = noteCtrl.text.trim();
                      if (note.isEmpty) {
                        setS(() => err = l10n.invDetailErrReasonEmpty);
                        return;
                      }
                      if (changeSku && selectedNewSku == null) {
                        setS(() => err = l10n.invDetailErrSelectNewSkuCode);
                        return;
                      }

                      setS(() { saving = true; err = null; });
                      try {
                        await _invService.confirmPending(
                          inventoryId: _invRecord!.id,
                          newSkuCode: changeSku ? selectedNewSku!.sku : null,
                          note: note,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          widget.onChanged?.call();
                          await _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.invDetailConfirmedOfficial)),
                            );
                          }
                        }
                      } catch (e) {
                        setS(() { saving = false; err = _friendly(e, l10n); });
                      }
                    },
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              child: saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                  : Text(l10n.invDetailConfirmToOfficial),
            ),
          ],
        ),
      ),
    );
    noteCtrl.dispose();
  }

  // ── 拆分为多个正式SKU ──
  Future<void> _showSplitPendingDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final noteCtrl = TextEditingController();

    // ── Source metadata ───────────────────────────────────────────────────────
    // Infer source recording mode from the live record state.
    final validateInBoxes = _boxesOnlyMode; // box-space vs piece-space balance
    final originalAmount  = validateInBoxes ? _boxes : _qty;
    final amountUnit      = validateInBoxes ? l10n.invDetailBoxesSuffix : l10n.invDetailPieceSuffix;
    final sourceLabel     = _boxesOnlyMode
        ? l10n.invDetailSourceModeBoxesOnly
        : (_configs.isEmpty && _boxes <= 1 && _qty > 0)
            ? l10n.invDetailSourceModeQty
            : l10n.invDetailSourceModeCarton;
    // Default mode for each split target mirrors the source recording mode.
    final defaultMode = _boxesOnlyMode
        ? 'boxesOnly'
        : (_configs.isEmpty && _boxes <= 1 && _qty > 0)
            ? 'qty'
            : 'carton';

    // ── Per-entry helpers ────────────────────────────────────────────────────
    Map<String, dynamic> newEntry() => {
      'sku':      null,
      'mode':     defaultMode,
      'boxes':    TextEditingController(),
      'units':    TextEditingController(),
      'totalQty': TextEditingController(),
    };
    void disposeEntry(Map<String, dynamic> s) {
      (s['boxes']    as TextEditingController).dispose();
      (s['units']    as TextEditingController).dispose();
      (s['totalQty'] as TextEditingController).dispose();
    }

    final splits = <Map<String, dynamic>>[newEntry()];
    String? err;
    bool saving = false;

    // Balance contribution from each split target.
    int splitContrib(List<Map<String, dynamic>> list) => list.fold(0, (sum, s) {
      final mode = s['mode'] as String;
      if (validateInBoxes) {
        // Box space: every mode contributes its box count
        return sum + (int.tryParse((s['boxes'] as TextEditingController).text) ?? 0);
      }
      if (mode == 'carton') {
        final b = int.tryParse((s['boxes']    as TextEditingController).text) ?? 0;
        final u = int.tryParse((s['units']    as TextEditingController).text) ?? 0;
        return sum + b * u;
      }
      if (mode == 'qty') {
        return sum + (int.tryParse((s['totalQty'] as TextEditingController).text) ?? 0);
      }
      return sum; // boxesOnly target in piece-space → 0 (user must switch mode)
    });

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final total    = splitContrib(splits);
          final balanced = total == originalAmount;

          return AlertDialog(
            title: Text(l10n.invDetailSplitTitle),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Source banner ──────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.deepPurple.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.invDetailSplitSource(widget.skuCode),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text(
                                  l10n.invDetailSplitSourceInfo(widget.locationCode, sourceLabel),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                                Text(
                                  l10n.invDetailSplitTotalConserve(originalAmount, amountUnit),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.deepPurple.shade600,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: balanced
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: balanced
                                      ? Colors.green
                                      : Colors.orange),
                            ),
                            child: Text(
                              balanced
                                  ? l10n.invDetailSplitBalanced
                                  : l10n.invDetailSplitProgress(total, originalAmount),
                              style: TextStyle(
                                fontSize: 11,
                                color: balanced
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Split entries ──────────────────────────────────────
                    ...List.generate(splits.length, (i) {
                      final s          = splits[i];
                      final selectedSku = s['sku'] as Sku?;
                      final entryMode  = s['mode'] as String;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: index + SKU name + delete
                            Row(
                              children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    selectedSku != null
                                        ? '${selectedSku.sku}'
                                            '${selectedSku.name != null ? "  ${selectedSku.name}" : ""}'
                                        : l10n.invDetailSplitNoSku,
                                    style: TextStyle(
                                      fontWeight: selectedSku != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 13,
                                      color: selectedSku != null
                                          ? Colors.deepPurple.shade700
                                          : Colors.grey.shade400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (splits.length > 1)
                                  InkWell(
                                    onTap: () => setS(() {
                                      disposeEntry(s);
                                      splits.removeAt(i);
                                    }),
                                    child: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: Colors.red),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Mode selector (per entry, independently switchable)
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                    value: 'carton',
                                    label: Text(l10n.invDetailSplitModeByCarton,
                                        style: const TextStyle(fontSize: 11)),
                                    icon: const Icon(Icons.view_list, size: 13)),
                                ButtonSegment(
                                    value: 'boxesOnly',
                                    label: Text(l10n.invDetailSplitModeBoxesOnly,
                                        style: const TextStyle(fontSize: 11)),
                                    icon: const Icon(Icons.inventory_2_outlined,
                                        size: 13)),
                                ButtonSegment(
                                    value: 'qty',
                                    label: Text(l10n.invDetailSplitModeByQty,
                                        style: const TextStyle(fontSize: 11)),
                                    icon: const Icon(Icons.numbers, size: 13)),
                              ],
                              selected: {entryMode},
                              onSelectionChanged: (v) =>
                                  setS(() => s['mode'] = v.first),
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // SKU picker
                            _SkuSearchField(
                              labelText: l10n.invDetailSplitSearchSku,
                              onSelected: (sku) =>
                                  setS(() => s['sku'] = sku),
                            ),
                            const SizedBox(height: 8),

                            // Input area — changes with mode
                            if (entryMode == 'carton') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: s['boxes']
                                          as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: l10n.invDetailSplitBoxesLabel,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        suffixText: l10n.invDetailSplitBoxesSuffix,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setS(() {}),
                                    ),
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('×',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey)),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: s['units']
                                          as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: l10n.invDetailSplitUnitsLabel,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        suffixText: l10n.invDetailSplitUnitsSuffix,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setS(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.invDetailSplitCalcPcs((int.tryParse((s['boxes'] as TextEditingController).text) ?? 0) * (int.tryParse((s['units'] as TextEditingController).text) ?? 0)),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ] else if (entryMode == 'boxesOnly') ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: s['boxes']
                                          as TextEditingController,
                                      decoration: InputDecoration(
                                        labelText: l10n.invDetailSplitBoxesLabel,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                        suffixText: l10n.invDetailSplitBoxesSuffix,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setS(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(l10n.invDetailSplitCartonTBD,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade600)),
                                ],
                              ),
                            ] else ...[
                              // qty mode
                              TextField(
                                controller: s['totalQty']
                                    as TextEditingController,
                                decoration: InputDecoration(
                                  labelText: l10n.invDetailSplitTotalQtyLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixText: l10n.invDetailSplitTotalQtySuffix,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setS(() {}),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    // Add split button
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(l10n.invDetailAddSplitTarget,
                          style: const TextStyle(fontSize: 13)),
                      onPressed: () => setS(() => splits.add(newEntry())),
                    ),

                    const Divider(height: 16),

                    // Note
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.invDetailSplitReasonLabel,
                        hintText: l10n.invDetailSplitReasonHint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setS(() => err = null),
                    ),

                    if (err != null) ...[
                      const SizedBox(height: 8),
                      Text(err!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () {
                        for (final s in splits) {
                          disposeEntry(s);
                        }
                        Navigator.pop(ctx);
                      },
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final note = noteCtrl.text.trim();
                        if (note.isEmpty) {
                          setS(() => err = l10n.invDetailErrSplitReasonEmpty);
                          return;
                        }
                        // Per-entry validation
                        for (int i = 0; i < splits.length; i++) {
                          final s    = splits[i];
                          final mode = s['mode'] as String;
                          if (s['sku'] == null) {
                            setS(() =>
                                err = l10n.invDetailErrSplitSelectSku(i + 1));
                            return;
                          }
                          if (mode == 'carton') {
                            if ((int.tryParse((s['boxes'] as TextEditingController).text) ?? 0) <= 0) {
                              setS(() => err = l10n.invDetailErrSplitBoxesMustBePositive(i + 1));
                              return;
                            }
                            if ((int.tryParse((s['units'] as TextEditingController).text) ?? 0) <= 0) {
                              setS(() => err = l10n.invDetailErrSplitUnitsMustBePositive(i + 1));
                              return;
                            }
                          } else if (mode == 'boxesOnly') {
                            if ((int.tryParse((s['boxes'] as TextEditingController).text) ?? 0) <= 0) {
                              setS(() => err = l10n.invDetailErrSplitBoxesMustBePositive(i + 1));
                              return;
                            }
                          } else {
                            if ((int.tryParse((s['totalQty'] as TextEditingController).text) ?? 0) <= 0) {
                              setS(() => err = l10n.invDetailErrSplitTotalQtyMustBePositive(i + 1));
                              return;
                            }
                          }
                        }
                        // Balance check
                        final total = splitContrib(splits);
                        if (total != originalAmount) {
                          setS(() => err =
                              l10n.invDetailErrSplitUnbalanced(total, originalAmount, amountUnit));
                          return;
                        }
                        // Build payload
                        final splitData = splits.map((s) {
                          final mode = s['mode'] as String;
                          final sku  = (s['sku'] as Sku).sku;
                          if (mode == 'carton') {
                            return <String, dynamic>{
                              'skuCode':    sku,
                              'boxes':      int.parse((s['boxes'] as TextEditingController).text.trim()),
                              'unitsPerBox': int.parse((s['units'] as TextEditingController).text.trim()),
                            };
                          } else if (mode == 'boxesOnly') {
                            return <String, dynamic>{
                              'skuCode':    sku,
                              'boxes':      int.parse((s['boxes'] as TextEditingController).text.trim()),
                              'unitsPerBox': 0, // signals boxesOnly on backend
                            };
                          } else {
                            return <String, dynamic>{
                              'skuCode':  sku,
                              'boxes':    0,
                              'unitsPerBox': 0,
                              'totalQty': int.parse((s['totalQty'] as TextEditingController).text.trim()),
                            };
                          }
                        }).toList();

                        setS(() { saving = true; err = null; });
                        try {
                          await _invService.splitPending(
                            inventoryId: _invRecord!.id,
                            splits: splitData,
                            note: note,
                          );
                          if (mounted) {
                            for (final s in splits) {
                              disposeEntry(s);
                            }
                            Navigator.pop(ctx);
                            widget.onChanged?.call();
                            await _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(l10n.invDetailSplitSuccess)));
                            }
                          }
                        } catch (e) {
                          setS(() { saving = false; err = _friendly(e, l10n); });
                        }
                      },
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.deepPurple),
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l10n.invDetailConfirmSplit),
              ),
            ],
          );
        },
      ),
    );
    noteCtrl.dispose();
  }

}

// ─── Figma-style action button (入库 / 出库 / 库存调整) ────────────────────────

class _FigmaActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color border;
  final Color fg;
  final VoidCallback onTap;

  const _FigmaActionBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.border,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Compact audit-log card for the sheet summary ────────────────────────────

class _AuditCard extends StatelessWidget {
  final ChangeRecord record;

  const _AuditCard({required this.record});

  static const _actionColor = <String, Color>{
    '入库': Colors.green,
    '录入': Colors.green,
    '暂存': Colors.teal,
    '出库': Colors.red,
    '删除库存': Colors.red,
    '调整': Colors.orange,
    '结构修改': Colors.orange,
    '批量转移': Colors.blue,
    '批量复制': Colors.indigo,
    'SKU更正': Colors.purple,
    'SKU更正并合并': Colors.deepOrange,
    '暂存转正式': Colors.teal,
    '暂存拆分': Colors.deepPurple,
  };

  Color get _color =>
      _actionColor[record.businessAction ?? ''] ?? Colors.grey.shade500;

  String _buildDetail(AppLocalizations l10n) {
    final d = record.details;
    final ba = record.businessAction;
    final pcs = l10n.unitPiece;
    if (d == null || ba == null) return '';
    switch (ba) {
      case '入库':
        if (d['boxesOnlyMode'] == true) {
          return '+${d['boxes'] ?? 0} ${l10n.invDetailBoxesSuffix}';
        }
        return '+${d['addedQty'] ?? 0}$pcs';
      case '出库':
        return '-${d['reducedQty'] ?? 0}$pcs';
      case '调整':
        final before = d['beforeQty'] ?? 0;
        final after = d['afterQty'] ?? 0;
        final note = d['note'];
        final noteStr = (note != null && note.toString().isNotEmpty) ? '  ${l10n.auditNote}: $note' : '';
        return '$before→$after$pcs$noteStr';
      case '录入':
        return '${d['quantity'] ?? 0}$pcs';
      case '删除库存':
        return '${d['quantity'] ?? 0}$pcs';
      case '批量转移':
      case '批量复制':
        return '${d['sourceCode']} → ${d['targetCode']}';
      case '标记已检查':
      case '取消已检查':
      case '新建库位':
      case '编辑库位':
      case '删除库位':
        return d['locationCode']?.toString() ?? '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MM-dd HH:mm').format(record.createdAt.toLocal());
    final color = _color;
    final l10n = AppLocalizations.of(context)!;
    final action = AuditLogDetailSheet.translateAction(record.businessAction, l10n)
        .isNotEmpty
        ? AuditLogDetailSheet.translateAction(record.businessAction, l10n)
        : l10n.invDetailDefaultAction;
    final detail = _buildDetail(l10n);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(action,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.isNotEmpty)
                  Text(detail,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                Text(record.userName,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── SKU search autocomplete field ───────────────────────────────────────────
// Reusable widget: search by keyword, show dropdown, require selection.

class _SkuSearchField extends StatefulWidget {
  final String labelText;
  final String? excludeSkuCode; // exclude this SKU from results (e.g. current SKU)
  final void Function(Sku sku) onSelected;

  const _SkuSearchField({
    required this.labelText,
    required this.onSelected,
    this.excludeSkuCode,
  });

  @override
  State<_SkuSearchField> createState() => _SkuSearchFieldState();
}

class _SkuSearchFieldState extends State<_SkuSearchField> {
  final _ctrl = TextEditingController();
  final _skuService = SkuService();
  final _focusNode = FocusNode();

  List<Sku> _results = [];
  bool _searching = false;
  bool _showDropdown = false;
  Sku? _selected;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.trim().isEmpty) {
      setState(() { _results = []; _showDropdown = false; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final all = await _skuService.getAll(search: v.trim());
        final filtered = widget.excludeSkuCode != null
            ? all.where((s) =>
                s.sku.toUpperCase() != widget.excludeSkuCode!.toUpperCase()).toList()
            : all;
        if (mounted) setState(() { _results = filtered; _showDropdown = true; _searching = false; });
      } catch (_) {
        if (mounted) setState(() { _searching = false; _showDropdown = false; });
      }
    });
  }

  void _select(Sku sku) {
    setState(() {
      _selected = sku;
      _showDropdown = false;
      _ctrl.text = sku.sku;
    });
    _focusNode.unfocus();
    widget.onSelected(sku);
  }

  void _clear() {
    setState(() {
      _selected = null;
      _results = [];
      _showDropdown = false;
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selected state — show chip
        if (_selected != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selected!.sku,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (_selected!.name != null && _selected!.name!.isNotEmpty)
                        Text(_selected!.name!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _clear,
                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

        // Search field — hidden when selected
        if (_selected == null) ...[
          TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: widget.labelText,
              hintText: AppLocalizations.of(context)!.invDetailSkuSearchHint,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () { _ctrl.clear(); setState(() { _results = []; _showDropdown = false; }); },
                        )
                      : const Icon(Icons.search, size: 18),
            ),
            onChanged: _onChanged,
          ),
          if (_showDropdown) ...[
            const SizedBox(height: 2),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(AppLocalizations.of(context)!.invDetailSkuNotFound,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final sku = _results[i];
                        return InkWell(
                          onTap: () => _select(sku),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(sku.sku,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      if (sku.name != null && sku.name!.isNotEmpty)
                                        Text(sku.name!,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                if (sku.isArchived)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(AppLocalizations.of(context)!.invDetailSkuArchived,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ],
    );
  }
}
