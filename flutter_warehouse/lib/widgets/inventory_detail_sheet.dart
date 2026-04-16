import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
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
  String _qtyLabel(AppLocalizations l10n) => _quantityUnknown
      ? l10n.invDetailQtyUnknown
      : (_boxesOnlyMode
          ? l10n.invDetailBoxesValue(_boxes)
          : '$_qty ${l10n.invDetailPieceSuffix}');
  List<InventoryConfig> get _configs =>
      _invRecord != null ? _invRecord!.configurations : widget.configurations;

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
    final boxesCtrl = TextEditingController();
    final unitsCtrl = TextEditingController();
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
          final previewQty = (stockInMode == 'carton' && !isPending)
              ? (int.tryParse(boxesCtrl.text) ?? 0) * (int.tryParse(unitsCtrl.text) ?? 0)
              : (stockInMode == 'qty' && !isPending)
                  ? (int.tryParse(qtyCtrl.text) ?? 0)
                  : 0;
          final previewBoxes = stockInMode == 'boxesOnly'
              ? (int.tryParse(boxesCtrl.text) ?? 0)
              : 0;

          return AlertDialog(
            title: Text(l10n.invDetailStockInTitle),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.orange.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.skuCode}  @  ${widget.locationCode}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                            _invRecord?.pendingCount == true
                                ? l10n.invDetailCurrentStatusPending
                                : l10n.invDetailCurrentStock(_qtyLabel(l10n)),
                            style: TextStyle(
                                fontSize: 12,
                                color: isPending
                                    ? Colors.orange.shade700
                                    : Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 待清点 toggle
                    CheckboxListTile(
                      value: isPending,
                      onChanged: (v) => setS(() => isPending = v ?? false),
                      title: Text(l10n.inventoryPendingTitle,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(l10n.inventoryPendingSubtitle,
                          style: const TextStyle(fontSize: 12)),
                      secondary: Icon(Icons.pending_actions_outlined,
                          color: isPending ? Colors.orange : Colors.grey,
                          size: 20),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    const SizedBox(height: 8),

                    // Mode selector — always visible
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: 'carton',
                            label: Text(l10n.invDetailModeByCarton),
                            icon: const Icon(Icons.view_list, size: 16)),
                        ButtonSegment(
                            value: 'boxesOnly',
                            label: Text(l10n.invDetailModeBoxesOnly),
                            icon: const Icon(Icons.inventory_2_outlined, size: 16)),
                        ButtonSegment(
                            value: 'qty',
                            label: Text(l10n.invDetailModeByQty),
                            icon: const Icon(Icons.numbers, size: 16)),
                      ],
                      selected: {stockInMode},
                      onSelectionChanged: (v) =>
                          setS(() { stockInMode = v.first; err = null; }),
                    ),
                    const SizedBox(height: 14),

                    // Input area
                    if (stockInMode == 'boxesOnly') ...[
                      TextField(
                        controller: boxesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.invDetailBoxesLabel,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixText: l10n.invDetailBoxesSuffix,
                        ),
                        onChanged: (_) => setS(() {}),
                      ),
                      if (previewBoxes > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPending
                                ? Colors.orange.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: isPending
                                    ? Colors.orange.shade200
                                    : Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Text(isPending ? l10n.invDetailPendingBoxes : l10n.invDetailStockInBoxes,
                                  style: const TextStyle(fontSize: 13)),
                              Text(l10n.invDetailBoxesValue(previewBoxes),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isPending
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700)),
                              Text(l10n.invDetailCartonTBD,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ] else if (stockInMode == 'carton' && !isPending) ...[
                      _qtyRow(boxesCtrl, unitsCtrl,
                          onChanged: () => setS(() {})),
                      if (previewQty > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Text(l10n.invDetailStockInTotal,
                                  style: const TextStyle(fontSize: 13)),
                              Text(l10n.invDetailAddQty(previewQty),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.green.shade700)),
                              Text(l10n.invDetailNewTotal(_qty + previewQty),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ] else if (stockInMode == 'qty' && !isPending) ...[
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.invDetailStockInQtyLabel,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixText: l10n.invDetailPieceSuffix,
                        ),
                        onChanged: (_) => setS(() {}),
                      ),
                      if (previewQty > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Text(l10n.invDetailStockInTotal,
                                  style: const TextStyle(fontSize: 13)),
                              Text(l10n.invDetailAddQty(previewQty),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.green.shade700)),
                              Text(l10n.invDetailNewTotal(_qty + previewQty),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      // isPending + carton or qty: just mark record as pending
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.invDetailPendingMarkNote,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    _noteField(noteCtrl),

                    if (err != null) ...[
                      const SizedBox(height: 8),
                      Text(err!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: Text(l10n.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: isPending
                        ? Colors.orange.shade600
                        : Colors.green.shade600),
                onPressed: saving
                    ? null
                    : () async {
                        if (stockInMode == 'boxesOnly') {
                          // boxesOnly mode: add boxes, with or without pending
                          final boxes = int.tryParse(boxesCtrl.text) ?? 0;
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
                            if (ctx.mounted) ctx.pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                          return;
                        }
                        if (isPending) {
                          // carton or qty mode + pending: just mark existing record
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.markPending(
                              widget.inventoryRecordId!,
                              pending: true,
                            );
                            if (ctx.mounted) ctx.pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                          return;
                        }
                        int boxes, units;
                        if (stockInMode == 'carton') {
                          boxes = int.tryParse(boxesCtrl.text) ?? 0;
                          units = int.tryParse(unitsCtrl.text) ?? 0;
                          if (boxes <= 0 || units <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidBoxesAndUnits);
                            return;
                          }
                        } else {
                          final qty = int.tryParse(qtyCtrl.text) ?? 0;
                          if (qty <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidQty);
                            return;
                          }
                          boxes = 1;
                          units = qty;
                        }
                        setS(() { saving = true; err = null; });
                        try {
                          await _invService.stockIn(
                            skuCode: widget.skuCode,
                            locationId: widget.locationId,
                            boxes: boxes,
                            unitsPerBox: units,
                            note: noteCtrl.text.trim(),
                          );
                          if (ctx.mounted) ctx.pop();
                          widget.onChanged?.call();
                          _load();
                        } catch (e) {
                          setS(() { saving = false; err = _friendly(e, l10n); });
                        }
                      },
                child: saving
                    ? _spinner()
                    : Text(isPending ? l10n.invDetailConfirmPendingBtn : l10n.invDetailConfirmStockIn),
              ),
            ],
          );
        },
      ),
    );

    boxesCtrl.dispose();
    unitsCtrl.dispose();
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

          // ── preview bar ──
          Widget previewBar() => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Text(l10n.invDetailOutTotal, style: const TextStyle(fontSize: 13)),
                    Text(
                      stockOutMode == 'boxesOnly'
                          ? l10n.invDetailOutBoxesValue(totalOutBoxes)
                          : l10n.invDetailOutPcsValue(previewOut),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isOverLimit
                            ? Colors.red.shade700
                            : previewOut > 0 || totalOutBoxes > 0
                                ? Colors.orange.shade700
                                : Colors.grey.shade500,
                      ),
                    ),
                    if (!isOverLimit &&
                        (previewOut > 0 || totalOutBoxes > 0)) ...[
                      Text(
                        stockOutMode == 'carton'
                            ? l10n.invDetailRemainCartonBoxes(totalAvailableBoxes - totalOutBoxes)
                            : stockOutMode == 'boxesOnly'
                                ? l10n.invDetailRemainBoxes(_boxes - totalOutBoxes)
                                : l10n.invDetailRemainPcs(_qty - previewOut),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              );

          return AlertDialog(
            title: Text(l10n.invDetailStockOutTitle),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.skuCode}  @  ${widget.locationCode}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(l10n.invDetailCurrentStock(_qtyLabel(l10n)),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mode toggle — 3 options
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: 'carton',
                            label: Text(l10n.invDetailModeByCarton),
                            icon: const Icon(Icons.view_list, size: 16)),
                        ButtonSegment(
                            value: 'boxesOnly',
                            label: Text(l10n.invDetailModeBoxesOnly),
                            icon: const Icon(Icons.inventory_2_outlined, size: 16)),
                        ButtonSegment(
                            value: 'qty',
                            label: Text(l10n.invDetailModeByQty),
                            icon: const Icon(Icons.numbers, size: 16)),
                      ],
                      selected: {stockOutMode},
                      onSelectionChanged: (v) =>
                          setS(() { stockOutMode = v.first; err = null; }),
                    ),
                    const SizedBox(height: 14),

                    // ── 按箱规 mode ──
                    if (stockOutMode == 'carton') ...[
                      if (effectiveConfigs.isEmpty)
                        Text(l10n.invDetailNoCartonData,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13))
                      else ...[
                        Text(l10n.invDetailSelectOutBoxes,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        ...List.generate(effectiveConfigs.length, (i) {
                          final cfg = effectiveConfigs[i];
                          final outBoxes =
                              int.tryParse(configCtrls[i].text) ?? 0;
                          final outQty = outBoxes * cfg.unitsPerBox;
                          final overLimit = outBoxes > cfg.boxes;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 72,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(l10n.invDetailUnitsPerBoxDisplay(cfg.unitsPerBox),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      Text(l10n.invDetailTotalBoxesDisplay(cfg.boxes),
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: configCtrls[i],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: l10n.invDetailOutMaxBoxes(cfg.boxes),
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                      suffixText: l10n.invDetailBoxesSuffix,
                                      errorText: overLimit
                                          ? l10n.invDetailExceedBoxes(cfg.boxes)
                                          : null,
                                    ),
                                    onChanged: (_) => setS(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(l10n.invDetailEqPcs(outQty),
                                    style: TextStyle(
                                        color: overLimit
                                            ? Colors.red
                                            : Colors.grey.shade600,
                                        fontSize: 12)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],

                    // ── 仅箱数 mode ──
                    if (stockOutMode == 'boxesOnly') ...[
                      TextField(
                        controller: boxesOnlyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.invDetailOutBoxesLabel(_boxes),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixText: l10n.invDetailBoxesSuffix,
                        ),
                        onChanged: (_) => setS(() {}),
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.invDetailBoxesOnlyHelp,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],

                    // ── 按总数量 mode ──
                    if (stockOutMode == 'qty') ...[
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.invDetailOutQtyLabel,
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixText: l10n.invDetailPieceSuffix,
                        ),
                        onChanged: (_) => setS(() {}),
                      ),
                    ],

                    // Preview
                    const SizedBox(height: 8),
                    previewBar(),
                    const SizedBox(height: 10),
                    _noteField(noteCtrl),

                    if (err != null) ...[
                      const SizedBox(height: 8),
                      Text(err!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: Text(l10n.cancel)),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: saving
                    ? null
                    : () async {
                        int qty = 0;
                        List<Map<String, int>>? removalConfigs;

                        if (stockOutMode == 'carton') {
                          for (int i = 0; i < effectiveConfigs.length; i++) {
                            final outBoxes =
                                int.tryParse(configCtrls[i].text) ?? 0;
                            if (outBoxes < 0) {
                              setS(() => err = l10n.invDetailErrNegativeBoxes);
                              return;
                            }
                            if (outBoxes > effectiveConfigs[i].boxes) {
                              setS(() => err =
                                  l10n.invDetailErrExceedCartonBoxes(effectiveConfigs[i].unitsPerBox, effectiveConfigs[i].boxes));
                              return;
                            }
                          }
                          qty = configTotal;
                          if (qty <= 0) {
                            setS(() => err = l10n.invDetailErrAtLeastOneCarton);
                            return;
                          }
                          if (totalOutBoxes > totalAvailableBoxes) {
                            setS(() => err =
                                l10n.invDetailErrExceedStockBoxes(totalAvailableBoxes));
                            return;
                          }
                          removalConfigs = List.generate(
                                  effectiveConfigs.length, (i) {
                                final outBoxes =
                                    int.tryParse(configCtrls[i].text) ?? 0;
                                return {
                                  'boxes': outBoxes,
                                  'unitsPerBox':
                                      effectiveConfigs[i].unitsPerBox,
                                };
                              })
                              .where((c) => c['boxes']! > 0)
                              .toList();
                        } else if (stockOutMode == 'boxesOnly') {
                          final outBoxes =
                              int.tryParse(boxesOnlyCtrl.text) ?? 0;
                          if (outBoxes <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidBoxes);
                            return;
                          }
                          if (outBoxes > _boxes) {
                            setS(() => err =
                                l10n.invDetailErrExceedStockBoxes(_boxes));
                            return;
                          }
                          // send as configurations so backend handles boxes correctly
                          removalConfigs = [
                            {'boxes': outBoxes, 'unitsPerBox': _units > 0 ? _units : 1}
                          ];
                          qty = outBoxes * (_units > 0 ? _units : 1);
                        } else {
                          qty = int.tryParse(qtyCtrl.text) ?? 0;
                          if (qty <= 0) {
                            setS(() => err = l10n.invDetailErrInvalidQty);
                            return;
                          }
                          if (_qty > 0 && qty > _qty) {
                            setS(() => err =
                                l10n.invDetailErrExceedStockPcs(_qty));
                            return;
                          }
                        }

                        setS(() { saving = true; err = null; });
                        try {
                          await _invService.stockOut(
                            skuCode: widget.skuCode,
                            locationId: widget.locationId,
                            quantity: qty,
                            configurations:
                                removalConfigs?.isNotEmpty == true
                                    ? removalConfigs
                                    : null,
                            note: noteCtrl.text.trim(),
                          );
                          if (ctx.mounted) ctx.pop();
                          widget.onChanged?.call();
                          _load();
                        } catch (e) {
                          setS(() {
                            saving = false;
                            err = _friendly(e, l10n);
                          });
                        }
                      },
                child: saving ? _spinner() : Text(l10n.invDetailConfirmStockOut),
              ),
            ],
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
    // 'qty' | 'boxes_only' | 'configs' | 'sku_correct'
    String adjustMode = _configs.isNotEmpty ? 'configs' : 'qty';

    // ── 按总数量 state ──
    final qtyCtrl = TextEditingController(text: _qty.toString());

    // ── 按箱规 state — max 3 rows ──
    final configRows = _configs.isNotEmpty
        ? _configs
            .take(3)
            .map((c) => <String, TextEditingController>{
                  'boxes': TextEditingController(text: c.boxes.toString()),
                  'units': TextEditingController(text: c.unitsPerBox.toString()),
                })
            .toList()
        : (_boxes > 0
            ? [
                <String, TextEditingController>{
                  'boxes': TextEditingController(text: _boxes.toString()),
                  'units': TextEditingController(text: _units.toString()),
                }
              ]
            : <Map<String, TextEditingController>>[]);

    // ── 仅箱数 state — same specs as existing, only boxes editable ──
    // Each entry: { unitsPerBox (readonly), boxesCtrl }
    final boxesOnlySpecs = _configs.isNotEmpty
        ? _configs
            .map((c) => {
                  'unitsPerBox': c.unitsPerBox,
                  'ctrl': TextEditingController(text: c.boxes.toString()),
                })
            .toList()
        : [
            {
              'unitsPerBox': _units > 0 ? _units : 1,
              'ctrl': TextEditingController(text: _boxes.toString()),
            }
          ];

    // ── SKU更正 state ──
    Sku? selectedCorrectSku;

    // ── shared ──
    final noteCtrl = TextEditingController();
    String? err;
    bool saving = false;

    // Helper — add empty config row (up to 3)
    void addConfigRow(void Function(void Function()) setS) {
      if (configRows.length >= 3) return;
      setS(() => configRows.add({
            'boxes': TextEditingController(text: '0'),
            'units': TextEditingController(text: '1'),
          }));
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // ── live preview ──
          final configsTotal = configRows.fold<int>(0, (s, row) {
            final b = int.tryParse(row['boxes']!.text) ?? 0;
            final u = int.tryParse(row['units']!.text) ?? 1;
            return s + b * u;
          });
          final boxesOnlyTotal = boxesOnlySpecs.fold<int>(0, (s, spec) {
            final b = int.tryParse((spec['ctrl'] as TextEditingController).text) ?? 0;
            final u = spec['unitsPerBox'] as int;
            return s + b * u;
          });
          final previewTotal = adjustMode == 'qty'
              ? (int.tryParse(qtyCtrl.text) ?? 0)
              : adjustMode == 'boxes_only'
                  ? boxesOnlyTotal
                  : configsTotal;

          // ── header info bar ──
          Widget headerBar() => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${widget.skuCode}  @  ${widget.locationCode}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(l10n.invDetailCurrentStock(_qtyLabel(l10n)),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              );

          // ── 按总数量 panel ──
          Widget qtyPanel() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.invDetailAdjustedTotalLabel,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixText: l10n.invDetailPieceSuffix,
                    ),
                    onChanged: (_) => setS(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.invDetailAdjustQtyHelp,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  _previewRow(previewTotal, _qty),
                ],
              );

          // ── 仅箱数 panel — units readonly, only boxes editable ──
          Widget boxesOnlyPanel() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.invDetailBoxesOnlyPanelHelp,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(boxesOnlySpecs.length, (i) {
                    final spec = boxesOnlySpecs[i];
                    final ctrl = spec['ctrl'] as TextEditingController;
                    final u = spec['unitsPerBox'] as int;
                    final b = int.tryParse(ctrl.text) ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 每箱件数 — 只读
                          Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                Text('$u',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                Text(l10n.invDetailUnitsPerBoxSuffix,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 箱数 — 可编辑
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.invDetailBoxesAdjustLabel,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                suffixText: l10n.invDetailBoxesSuffix,
                              ),
                              onChanged: (_) => setS(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 小计
                          SizedBox(
                            width: 48,
                            child: Text(
                              l10n.invDetailSubtotalPcs(b * u),
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _previewRow(boxesOnlyTotal, _qty),
                ],
              );

          // ── 按箱规/箱数 panel ──
          Widget configsPanel() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.invDetailCartonGroupsLabel,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (configRows.length < 3)
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 15),
                          label: Text(l10n.invDetailAddCarton,
                              style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => addConfigRow(setS),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (configRows.isEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(l10n.invDetailAddFirstCarton),
                      onPressed: () => addConfigRow(setS),
                    )
                  else
                    ...List.generate(configRows.length, (i) {
                      final row = configRows[i];
                      final u =
                          int.tryParse(row['units']!.text) ?? 1;
                      final b =
                          int.tryParse(row['boxes']!.text) ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 箱规编号
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color:
                                    Colors.orange.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 件/箱
                            Expanded(
                              child: TextField(
                                controller: row['units'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.invDetailUnitsPerBoxLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixText: l10n.invDetailPieceSuffix,
                                ),
                                onChanged: (_) => setS(() {}),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // 箱数
                            Expanded(
                              child: TextField(
                                controller: row['boxes'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: l10n.invDetailBoxesAdjustLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixText: l10n.invDetailBoxesSuffix,
                                ),
                                onChanged: (_) => setS(() {}),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // 小计
                            SizedBox(
                              width: 44,
                              child: Text(
                                l10n.invDetailSubtotalPcs(b * u),
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            // 删除按钮
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 16, color: Colors.red),
                              onPressed: () => setS(() {
                                final removed =
                                    configRows.removeAt(i);
                                removed['boxes']!.dispose();
                                removed['units']!.dispose();
                              }),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  _previewRow(previewTotal, _qty),
                ],
              );

          // ── SKU更正 panel ──
          Widget skuCorrectPanel() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current SKU info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(l10n.invDetailSkuCorrectCurrent,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
                        Text(widget.skuCode,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 14,
                            color: Colors.purple.shade400),
                        const SizedBox(width: 8),
                        Text(
                          selectedCorrectSku?.sku ?? l10n.invDetailSkuCorrectSelectHint,
                          style: TextStyle(
                            fontWeight: selectedCorrectSku != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                            color: selectedCorrectSku != null
                                ? Colors.purple.shade700
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (selectedCorrectSku != null)
                          Icon(Icons.check_circle,
                              size: 14,
                              color: Colors.green.shade600),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // SKU search
                  _SkuSearchField(
                    labelText: l10n.invDetailSkuCorrectSearch,
                    excludeSkuCode: widget.skuCode,
                    onSelected: (sku) => setS(() => selectedCorrectSku = sku),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text(l10n.invDetailQtyRetained(_qtyLabel(l10n)),
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              );

          return AlertDialog(
            title: Text(l10n.invDetailAdjustTitle),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerBar(),
                    const SizedBox(height: 10),

                    // ── 4-way mode selector ──
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                        segments: [
                          ButtonSegment(
                            value: 'qty',
                            label: Text(l10n.invDetailAdjustModeQty),
                            icon: const Icon(Icons.numbers, size: 14),
                          ),
                          ButtonSegment(
                            value: 'boxes_only',
                            label: Text(l10n.invDetailAdjustModeBoxesOnly),
                            icon: const Icon(Icons.view_column, size: 14),
                          ),
                          ButtonSegment(
                            value: 'configs',
                            label: Text(l10n.invDetailAdjustModeCarton),
                            icon: const Icon(Icons.view_list, size: 14),
                          ),
                          ButtonSegment(
                            value: 'sku_correct',
                            label: Text(l10n.invDetailAdjustModeSkuCorrect),
                            icon: const Icon(Icons.find_replace, size: 14),
                          ),
                        ],
                        selected: {adjustMode},
                        onSelectionChanged: (v) => setS(() {
                          adjustMode = v.first;
                          err = null;
                          selectedCorrectSku = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── mode-specific panel ──
                    if (adjustMode == 'qty') qtyPanel(),
                    if (adjustMode == 'boxes_only') boxesOnlyPanel(),
                    if (adjustMode == 'configs') configsPanel(),
                    if (adjustMode == 'sku_correct') skuCorrectPanel(),

                    const SizedBox(height: 12),

                    // ── reason note (all modes) ──
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: adjustMode == 'sku_correct'
                            ? l10n.invDetailReasonSkuCorrect
                            : l10n.invDetailReasonAdjust,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        helperText: adjustMode == 'sku_correct'
                            ? l10n.invDetailReasonSkuCorrectHint
                            : l10n.invDetailReasonAdjustHint,
                      ),
                    ),

                    if (err != null) ...[
                      const SizedBox(height: 8),
                      Text(err!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => ctx.pop(),
                  child: Text(l10n.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: adjustMode == 'sku_correct'
                        ? Colors.purple
                        : Colors.orange),
                onPressed: saving
                    ? null
                    : () async {
                        final note = noteCtrl.text.trim();
                        if (note.isEmpty) {
                          setS(() => err = l10n.invDetailErrReasonRequired);
                          return;
                        }

                        // ── SKU更正 submit ──
                        if (adjustMode == 'sku_correct') {
                          if (selectedCorrectSku == null) {
                            setS(() => err = l10n.invDetailErrSelectNewSku);
                            return;
                          }
                          if (selectedCorrectSku!.sku.toUpperCase() ==
                              widget.skuCode.toUpperCase()) {
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
                            if (ctx.mounted) ctx.pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() => saving = false);
                            // 目标SKU已存在 → 弹合并确认框
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
                                      style: FilledButton.styleFrom(
                                          backgroundColor: Colors.orange),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: Text(l10n.invDetailMergeConfirm),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              // 重提交，附带 allowMerge
                              setS(() { saving = true; err = null; });
                              try {
                                await _invService.correctSku(
                                  inventoryId: widget.inventoryRecordId!,
                                  newSkuCode: selectedCorrectSku!.sku,
                                  note: note,
                                  allowMerge: true,
                                );
                                if (ctx.mounted) ctx.pop();
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

                        // ── 仅箱数 submit ──
                        if (adjustMode == 'boxes_only') {
                          final configs = boxesOnlySpecs.map((spec) {
                            final b = int.tryParse(
                                    (spec['ctrl'] as TextEditingController)
                                        .text) ??
                                0;
                            return {
                              'boxes': b,
                              'unitsPerBox': spec['unitsPerBox'] as int,
                            };
                          }).toList();
                          if (configs.every((c) => c['boxes']! <= 0)) {
                            setS(() => err = l10n.invDetailErrAtLeastOneBoxesGroup);
                            return;
                          }
                          // Filter out zero-box specs
                          final nonZero =
                              configs.where((c) => c['boxes']! > 0).toList();
                          setS(() {
                            saving = true;
                            err = null;
                          });
                          try {
                            await _invService.stockAdjust(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              configurations: nonZero,
                              adjustMode: 'boxes_only',
                              note: note,
                            );
                            if (ctx.mounted) ctx.pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() {
                              saving = false;
                              err = _friendly(e, l10n);
                            });
                          }
                          return;
                        }

                        // ── 按箱规 submit ──
                        if (adjustMode == 'configs') {
                          if (configRows.isEmpty) {
                            setS(() => err = l10n.invDetailErrAtLeastOneCartonGroup);
                            return;
                          }
                          final configs = configRows.map((row) {
                            final b = int.tryParse(row['boxes']!.text) ?? 0;
                            final u = int.tryParse(row['units']!.text) ?? 0;
                            return {'boxes': b, 'unitsPerBox': u};
                          }).toList();
                          if (configs.any(
                              (c) => c['boxes']! <= 0 || c['unitsPerBox']! <= 0)) {
                            setS(() => err = l10n.invDetailErrValidCartonGroup);
                            return;
                          }
                          setS(() { saving = true; err = null; });
                          try {
                            await _invService.stockAdjust(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              configurations: configs,
                              adjustMode: 'configs',
                              note: note,
                            );
                            if (ctx.mounted) ctx.pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() { saving = false; err = _friendly(e, l10n); });
                          }
                          return;
                        }

                        // ── 按总数量 submit ──
                        final qty = int.tryParse(qtyCtrl.text);
                        if (qty == null || qty < 0) {
                          setS(() => err = l10n.invDetailErrValidQtyGte0);
                          return;
                        }
                        setS(() { saving = true; err = null; });
                        try {
                          await _invService.stockAdjust(
                            skuCode: widget.skuCode,
                            locationId: widget.locationId,
                            quantity: qty,
                            adjustMode: 'qty',
                            note: note,
                          );
                          if (ctx.mounted) ctx.pop();
                          widget.onChanged?.call();
                          _load();
                        } catch (e) {
                          setS(() { saving = false; err = _friendly(e, l10n); });
                        }
                      },
                child: saving
                    ? _spinner()
                    : Text(adjustMode == 'sku_correct'
                        ? l10n.invDetailConfirmSkuCorrect
                        : adjustMode == 'boxes_only'
                            ? l10n.invDetailConfirmBoxesAdjust
                            : l10n.invDetailConfirmAdjust),
              ),
            ],
          );
        },
      ),
    );

    // Dispose all controllers
    for (final row in configRows) {
      row['boxes']?.dispose();
      row['units']?.dispose();
    }
    for (final spec in boxesOnlySpecs) {
      (spec['ctrl'] as TextEditingController).dispose();
    }
    qtyCtrl.dispose();
    noteCtrl.dispose();
  }

  // ── preview total row ──
  Widget _previewRow(int previewTotal, int currentQty) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Builder(builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Row(
          children: [
            Text(l10n.invDetailAdjustedTotalRow, style: const TextStyle(fontSize: 13)),
            Text(
              '$previewTotal ${l10n.invDetailPieceSuffix}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: previewTotal != currentQty
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
              ),
            ),
            if (previewTotal != currentQty) ...[
              Text(
                '  (${previewTotal > currentQty ? '+' : ''}${previewTotal - currentQty})',
                style: TextStyle(
                    fontSize: 12,
                    color: previewTotal > currentQty
                        ? Colors.green.shade600
                        : Colors.red.shade600),
              ),
            ],
          ],
          );
        }),
      );

  // ── 共用 helper widgets ──
  Widget _qtyRow(TextEditingController boxesCtrl, TextEditingController unitsCtrl,
      {VoidCallback? onChanged}) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: boxesCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.invDetailBoxesLabelStar, border: const OutlineInputBorder(),
              isDense: true, suffixText: l10n.invDetailBoxesSuffix,
            ),
            onChanged: onChanged != null ? (_) => onChanged() : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: unitsCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.invDetailUnitsLabelStar, border: const OutlineInputBorder(),
              isDense: true, suffixText: l10n.invDetailUnitsPerBoxSuffix,
            ),
            onChanged: onChanged != null ? (_) => onChanged() : null,
          ),
        ),
      ],
    );
  }

  Widget _noteField(TextEditingController ctrl) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: l10n.invDetailNoteOptional, border: const OutlineInputBorder(), isDense: true,
      ),
    );
  }


  Widget _spinner() => const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );

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
                        _quantityUnknown
                            ? l10n.invDetailQtyUnknownHeader
                            : (_configs.isEmpty
                                ? (_boxesOnlyMode
                                    ? l10n.invDetailBoxesOnlyHeader(_boxes)
                                    : l10n.invDetailBoxesAndPcs(_boxes, _qty))
                                : _configs
                                    .map((c) =>
                                        l10n.invDetailBoxesAndPcs(c.boxes, c.qty))
                                    .join('  ·  ')),
                        style: const TextStyle(
                            color: Color(0xFF8E8E9A), fontSize: 12),
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

  String _extractDetail() {
    final desc = record.description;
    final atIdx = desc.indexOf(' @ ');
    if (atIdx == -1) return desc;
    final afterAt = atIdx + 3;
    final spaceAfterLoc = desc.indexOf(' ', afterAt);
    if (spaceAfterLoc == -1) return '';
    return desc.substring(spaceAfterLoc + 1).trim();
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MM-dd HH:mm').format(record.createdAt.toLocal());
    final color = _color;
    final l10n = AppLocalizations.of(context)!;
    final action = record.businessAction ?? l10n.invDetailDefaultAction;
    final detail = _extractDetail();

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
