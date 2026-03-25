import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/inventory_service.dart';
import '../models/inventory.dart';

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
  final bool canEdit;
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
    this.onChanged,
  });

  @override
  State<InventoryDetailSheet> createState() => _InventoryDetailSheetState();
}

class _InventoryDetailSheetState extends State<InventoryDetailSheet> {
  final _txService = TransactionService();
  final _invService = InventoryService();
  List<TransactionRecord>? _records;
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
      _records = await _txService.getForInventory(widget.skuCode, widget.locationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── 入库 ──
  Future<void> _showStockInDialog() async {
    final boxesCtrl = TextEditingController();
    final unitsCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('入库'),
          content: _operationDialogContent(
            ctx: ctx,
            header: '${widget.skuCode}  →  ${widget.locationCode}',
            children: [
              _qtyRow(boxesCtrl, unitsCtrl),
              const SizedBox(height: 10),
              _noteField(noteCtrl),
            ],
            err: err,
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              onPressed: saving ? null : () async {
                final boxes = int.tryParse(boxesCtrl.text) ?? 0;
                final units = int.tryParse(unitsCtrl.text) ?? 0;
                if (boxes <= 0 || units <= 0) {
                  setS(() => err = '请输入有效的箱数和每箱件数');
                  return;
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
                  setS(() { saving = false; err = '入库失败: $e'; });
                }
              },
              child: saving ? _spinner() : const Text('确认入库'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 出库 ──
  Future<void> _showStockOutDialog() async {
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('出库'),
          content: _operationDialogContent(
            ctx: ctx,
            header: '${widget.skuCode}  →  ${widget.locationCode}',
            subInfo: '当前库存: ${widget.totalQty} 件',
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '出库件数 *',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixText: '件',
                ),
              ),
              const SizedBox(height: 10),
              _noteField(noteCtrl),
            ],
            err: err,
          ),
          actions: [
            TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: saving ? null : () async {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) {
                  setS(() => err = '请输入有效件数');
                  return;
                }
                if (qty > widget.totalQty) {
                  setS(() => err = '出库数量不能超过当前库存 (${widget.totalQty} 件)');
                  return;
                }
                setS(() { saving = true; err = null; });
                try {
                  await _invService.stockOut(
                    skuCode: widget.skuCode,
                    locationId: widget.locationId,
                    quantity: qty,
                    note: noteCtrl.text.trim(),
                  );
                  if (ctx.mounted) ctx.pop();
                  widget.onChanged?.call();
                  _load();
                } catch (e) {
                  setS(() { saving = false; err = '出库失败: $e'; });
                }
              },
              child: saving ? _spinner() : const Text('确认出库'),
            ),
          ],
        ),
      ),
    );
  }

  // ── 库存调整 ──
  Future<void> _showAdjustDialog() async {
    // Initialize editable config rows: use configurations if present, else fall back to current boxes/unitsPerBox
    final configRows = widget.configurations.isNotEmpty
        ? widget.configurations
            .map((c) => <String, TextEditingController>{
                  'boxes': TextEditingController(text: c.boxes.toString()),
                  'units': TextEditingController(text: c.unitsPerBox.toString()),
                })
            .toList()
        : (widget.boxes > 0
            ? [
                <String, TextEditingController>{
                  'boxes': TextEditingController(text: widget.boxes.toString()),
                  'units': TextEditingController(text: widget.unitsPerBox.toString()),
                }
              ]
            : <Map<String, TextEditingController>>[]);

    final qtyCtrl = TextEditingController(text: widget.totalQty.toString());
    final noteCtrl = TextEditingController();
    final newBoxesCtrl = TextEditingController();
    final newUnitsCtrl = TextEditingController();

    // Default to config mode when we have any current inventory structure to show
    bool useConfigMode = widget.totalQty > 0;
    String? err;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // Real-time total preview
          final previewTotal = useConfigMode
              ? configRows.fold<int>(0, (s, row) {
                  final b = int.tryParse(row['boxes']!.text) ?? 0;
                  final u = int.tryParse(row['units']!.text) ?? 1;
                  return s + b * u;
                })
              : (int.tryParse(qtyCtrl.text) ?? 0);

          return AlertDialog(
            title: const Text('库存调整'),
            scrollable: true,
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${widget.skuCode}  @  ${widget.locationCode}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('当前库存: ${widget.totalQty} 件',
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade700)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mode toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                          value: false,
                          label: Text('按总数量'),
                          icon: Icon(Icons.numbers, size: 16)),
                      ButtonSegment(
                          value: true,
                          label: Text('按箱规'),
                          icon: Icon(Icons.view_list, size: 16)),
                    ],
                    selected: {useConfigMode},
                    onSelectionChanged: (v) => setS(() => useConfigMode = v.first),
                  ),
                  const SizedBox(height: 14),

                  // Total qty mode
                  if (!useConfigMode) ...[
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '调整后总件数 *',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixText: '件',
                      ),
                      onChanged: (_) => setS(() {}),
                    ),
                    const SizedBox(height: 6),
                    // Show how the total will be stored in terms of carton spec
                    Builder(builder: (_) {
                      final qty = int.tryParse(qtyCtrl.text) ?? 0;
                      // Use single existing spec if evenly divisible
                      final singleUnits = widget.configurations.length == 1
                          ? widget.configurations.first.unitsPerBox
                          : (widget.configurations.isEmpty && widget.unitsPerBox > 1
                              ? widget.unitsPerBox
                              : 0);
                      final canUseSpec = singleUnits > 1 && qty > 0 && qty % singleUnits == 0;
                      return Text(
                        canUseSpec
                            ? '将按当前箱规存储为 ${qty ~/ singleUnits} 箱 × $singleUnits件/箱 = $qty件'
                            : '用于盘点差异、货损等场景，直接修正总件数。',
                        style: TextStyle(
                          fontSize: 12,
                          color: canUseSpec
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      );
                    }),
                  ],

                  // Config mode
                  if (useConfigMode) ...[
                    const Text('各箱规库存:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ...List.generate(configRows.length, (i) {
                      final row = configRows[i];
                      final units =
                          int.tryParse(row['units']!.text) ?? 1;
                      final boxes =
                          int.tryParse(row['boxes']!.text) ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: row['boxes'],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: '$units件/箱',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixText: '箱',
                                ),
                                onChanged: (_) => setS(() {}),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('= ${boxes * units}件',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: Colors.red),
                              onPressed: () => setS(() {
                                final removed = configRows.removeAt(i);
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
                    const SizedBox(height: 4),
                    // Add new config row
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('新增箱规',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: newBoxesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '箱数',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixText: '箱',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: newUnitsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: '每箱件数',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixText: '件/箱',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              FilledButton(
                                onPressed: () {
                                  final b =
                                      int.tryParse(newBoxesCtrl.text) ?? 0;
                                  final u =
                                      int.tryParse(newUnitsCtrl.text) ?? 0;
                                  if (b > 0 && u > 0) {
                                    setS(() {
                                      configRows.add({
                                        'boxes': TextEditingController(
                                            text: b.toString()),
                                        'units': TextEditingController(
                                            text: u.toString()),
                                      });
                                      newBoxesCtrl.clear();
                                      newUnitsCtrl.clear();
                                    });
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('添加'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Preview total
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Text('调整后总库存: ',
                            style: TextStyle(fontSize: 13)),
                        Text('$previewTotal 件',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: previewTotal != widget.totalQty
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                            )),
                      ],
                    ),
                  ),

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
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
              FilledButton(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: saving
                    ? null
                    : () async {
                        if (useConfigMode) {
                          if (configRows.isEmpty) {
                            setS(() => err = '至少需要一种箱规');
                            return;
                          }
                          final configs = configRows.map((row) {
                            final b =
                                int.tryParse(row['boxes']!.text) ?? 0;
                            final u =
                                int.tryParse(row['units']!.text) ?? 0;
                            return {'boxes': b, 'unitsPerBox': u};
                          }).toList();
                          if (configs.any(
                              (c) => c['boxes']! <= 0 || c['unitsPerBox']! <= 0)) {
                            setS(() => err = '请输入有效的箱数和每箱件数');
                            return;
                          }
                          setS(() {
                            saving = true;
                            err = null;
                          });
                          try {
                            await _invService.stockAdjust(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              configurations: configs,
                              note: noteCtrl.text.trim().isEmpty
                                  ? null
                                  : noteCtrl.text.trim(),
                            );
                            if (ctx.mounted) ctx.pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() {
                              saving = false;
                              err = '调整失败: $e';
                            });
                          }
                        } else {
                          final qty = int.tryParse(qtyCtrl.text);
                          if (qty == null || qty < 0) {
                            setS(() => err = '请输入有效件数（≥0）');
                            return;
                          }
                          setS(() {
                            saving = true;
                            err = null;
                          });
                          try {
                            await _invService.stockAdjust(
                              skuCode: widget.skuCode,
                              locationId: widget.locationId,
                              quantity: qty,
                              note: noteCtrl.text.trim().isEmpty
                                  ? null
                                  : noteCtrl.text.trim(),
                            );
                            if (ctx.mounted) ctx.pop();
                            widget.onChanged?.call();
                            _load();
                          } catch (e) {
                            setS(() {
                              saving = false;
                              err = '调整失败: $e';
                            });
                          }
                        }
                      },
                child: saving ? _spinner() : const Text('确认调整'),
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
    qtyCtrl.dispose();
    noteCtrl.dispose();
    newBoxesCtrl.dispose();
    newUnitsCtrl.dispose();
  }

  // ── 修改库存结构 ──
  Future<void> _showEditStructureDialog() async {
    if (widget.inventoryRecordId == null) return;
    final boxesCtrl = TextEditingController(text: widget.boxes.toString());
    final unitsCtrl = TextEditingController(text: widget.unitsPerBox.toString());
    String? err;
    bool saving = false;
    int previewBoxes = widget.boxes;
    int previewUnits = widget.unitsPerBox;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final previewTotal = previewBoxes * previewUnits;
          return AlertDialog(
            title: const Text('修改库存结构'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 当前 → 修改后预览
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('当前', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('${widget.boxes}×${widget.unitsPerBox} = ${widget.totalQty}件',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('修改后', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('$previewBoxes×$previewUnits = $previewTotal件',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: previewTotal != widget.totalQty
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _qtyRow(
                  boxesCtrl, unitsCtrl,
                  onChanged: () => setS(() {
                    previewBoxes = int.tryParse(boxesCtrl.text) ?? 0;
                    previewUnits = int.tryParse(unitsCtrl.text) ?? 0;
                  }),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    widget.configurations.length > 1
                        ? '当前有 ${widget.configurations.length} 种箱规，保存后将合并为单一配置。\n此功能仅用于修正结构，不用于正式入出库或调整。'
                        : '该功能仅用于修正库存结构（箱数/每箱件数），\n不用于正式入库、出库或盘点调整。',
                    style: const TextStyle(fontSize: 12, color: Colors.brown),
                  ),
                ),
                if (err != null) ...[
                  const SizedBox(height: 8),
                  Text(err!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => ctx.pop(), child: const Text('取消')),
              FilledButton(
                onPressed: saving ? null : () async {
                  final boxes = int.tryParse(boxesCtrl.text) ?? 0;
                  final units = int.tryParse(unitsCtrl.text) ?? 0;
                  if (boxes <= 0 || units <= 0) {
                    setS(() => err = '请输入有效的箱数和每箱件数');
                    return;
                  }
                  setS(() { saving = true; err = null; });
                  try {
                    await _invService.update(
                      widget.inventoryRecordId!,
                      boxes: boxes,
                      unitsPerBox: units,
                    );
                    if (ctx.mounted) ctx.pop();
                    widget.onChanged?.call();
                    _load();
                  } catch (e) {
                    setS(() { saving = false; err = '修改失败: $e'; });
                  }
                },
                child: saving ? _spinner() : const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 共用 helper widgets ──
  Widget _operationDialogContent({
    required BuildContext ctx,
    required String header,
    String? subInfo,
    String? note,
    required List<Widget> children,
    String? err,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(header, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              if (subInfo != null)
                Text(subInfo, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(note, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
        const SizedBox(height: 14),
        ...children,
        if (err != null) ...[
          const SizedBox(height: 8),
          Text(err, style: const TextStyle(color: Colors.red, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _qtyRow(TextEditingController boxesCtrl, TextEditingController unitsCtrl,
      {VoidCallback? onChanged}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: boxesCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '箱数 *', border: OutlineInputBorder(),
              isDense: true, suffixText: '箱',
            ),
            onChanged: onChanged != null ? (_) => onChanged() : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: unitsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '每箱件数 *', border: OutlineInputBorder(),
              isDense: true, suffixText: '件/箱',
            ),
            onChanged: onChanged != null ? (_) => onChanged() : null,
          ),
        ),
      ],
    );
  }

  Widget _noteField(TextEditingController ctrl) => TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          labelText: '备注（可选）', border: OutlineInputBorder(), isDense: true,
        ),
      );

  Widget _spinner() => const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );

  Color _typeColor(String type) {
    switch (type) {
      case 'IN': return Colors.green;
      case 'OUT': return Colors.red;
      case 'ADJUST': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'IN': return '入库';
      case 'OUT': return '出库';
      case 'ADJUST': return '调整';
      default: return type;
    }
  }

  String _txDetail(TransactionRecord r) {
    if (r.type == 'IN' && r.boxes != null && r.unitsPerBox != null) {
      return '${r.boxes}箱 × ${r.unitsPerBox} = ${r.quantity}件';
    }
    if (r.type == 'ADJUST') return '调整为 ${r.quantity}件';
    return '${r.quantity}件';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // 拖动条
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.skuCode,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(widget.locationCode,
                            style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      ]),
                    ],
                  ),
                ),
                // 总库存徽章
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.totalQty > 0 ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.totalQty > 0 ? Colors.green.shade200 : Colors.orange.shade200),
                  ),
                  child: Text('${widget.totalQty} 件',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16,
                        color: widget.totalQty > 0
                            ? Colors.green.shade700 : Colors.orange.shade700,
                      )),
                ),
              ],
            ),
          ),

          // 当前库存结构（支持多箱规）
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: widget.configurations.isEmpty
                ? Text('${widget.boxes}箱 × ${widget.unitsPerBox}件/箱',
                    style: const TextStyle(color: Colors.grey, fontSize: 12))
                : Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    children: widget.configurations.map((c) => Text(
                          '${c.boxes}箱×${c.unitsPerBox}件/箱 = ${c.qty}件',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        )).toList(),
                  ),
          ),

          // 主操作按钮行
          if (widget.canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _actionBtn('入库', Icons.add_circle_outline, Colors.green, _showStockInDialog),
                  const SizedBox(width: 8),
                  _actionBtn('出库', Icons.remove_circle_outline, Colors.red, _showStockOutDialog),
                  const SizedBox(width: 8),
                  _actionBtn('调整', Icons.tune, Colors.orange, _showAdjustDialog),
                ],
              ),
            ),

          // 次操作行
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Row(
              children: [
                if (widget.canEdit && widget.inventoryRecordId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.edit_note, size: 15),
                    label: const Text('修改库存结构', style: TextStyle(fontSize: 12)),
                    onPressed: _showEditStructureDialog,
                  ),
                if (widget.showSkuNav && widget.skuId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.qr_code_2, size: 15),
                    label: const Text('SKU 详情', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      context.pop();
                      context.push('/skus/${widget.skuId}');
                    },
                  ),
                if (widget.showLocNav)
                  TextButton.icon(
                    icon: const Icon(Icons.place_outlined, size: 15),
                    label: const Text('库位详情', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      context.pop();
                      context.push('/locations/${widget.locationId}');
                    },
                  ),
              ],
            ),
          ),

          const Divider(height: 16),

          // 流水记录标题
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                const Text('入出库记录',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                if (_records != null)
                  Text('共 ${_records!.length} 条',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // 流水列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('加载失败，点击重试'),
                          onPressed: _load,
                        ))
                    : _records!.isEmpty
                        ? const Center(
                            child: Text('暂无记录', style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _records!.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final r = _records![i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _typeColor(r.type).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: _typeColor(r.type).withValues(alpha: 0.4)),
                                      ),
                                      child: Text(_typeLabel(r.type),
                                          style: TextStyle(
                                            color: _typeColor(r.type),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          )),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_txDetail(r),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500, fontSize: 14)),
                                          if (r.note != null && r.note!.isNotEmpty)
                                            Text(r.note!,
                                                style: const TextStyle(
                                                    color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MM-dd HH:mm').format(r.createdAt.toLocal()),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onPressed: onTap,
      ),
    );
  }
}
