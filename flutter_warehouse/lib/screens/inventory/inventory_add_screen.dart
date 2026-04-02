import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/sku.dart';
import '../../models/location.dart';
import '../../services/sku_service.dart';
import '../../services/location_service.dart';
import '../../services/inventory_service.dart';

class InventoryAddScreen extends StatefulWidget {
  final String? initialSkuId;
  final String? initialLocationId;
  const InventoryAddScreen({super.key, this.initialSkuId, this.initialLocationId});

  @override
  State<InventoryAddScreen> createState() => _InventoryAddScreenState();
}

class _InventoryAddScreenState extends State<InventoryAddScreen> {
  final _skuSearchCtrl = TextEditingController();
  final _locSearchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _cartonQtyCtrl = TextEditingController();
  final _totalQtyCtrl = TextEditingController();
  // 新建 SKU 时的额外字段
  final _skuNameCtrl = TextEditingController();
  final _skuBarcodeCtrl = TextEditingController();
  // 新建库位时的字段
  final _newLocCodeCtrl = TextEditingController();
  final _newLocDescCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  List<Sku> _skuResults = [];
  List<Location> _locResults = [];
  Sku? _selectedSku;
  Location? _selectedLoc;
  bool _isNewSku = false;     // 是否新建 SKU 模式
  bool _isNewLoc = false;     // 是否新建库位模式
  bool _useConfigMode = true; // true=按箱规，false=按总数量
  bool _isPending = false;    // 待清点模式

  bool _skuSearching = false;
  bool _locSearching = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialSkuId != null) _loadInitialSku();
    if (widget.initialLocationId != null) _loadInitialLoc();
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
      // Pre-fill code with whatever user typed so far
      if (_newLocCodeCtrl.text.isEmpty) {
        _newLocCodeCtrl.text = _locSearchCtrl.text.trim().toUpperCase();
      }
    });
  }

  Future<void> _save() async {
    if (!_isNewSku && _selectedSku == null) {
      setState(() => _error = '请选择 SKU 或新建');
      return;
    }
    if (_isNewSku && _skuSearchCtrl.text.trim().isEmpty) {
      setState(() => _error = 'SKU 编号不能为空');
      return;
    }
    if (!_isNewLoc && _selectedLoc == null) { setState(() => _error = '请选择库位'); return; }
    if (_isNewLoc && _newLocCodeCtrl.text.trim().isEmpty) {
      setState(() => _error = '库位编号不能为空');
      return;
    }

    int boxes;
    int? unitsPerBox;
    bool boxesOnlyMode = false;
    if (_isPending) {
      boxes = 0;
      unitsPerBox = 1;
    } else if (_useConfigMode) {
      final qty = int.tryParse(_qtyCtrl.text);
      if (qty == null || qty <= 0) { setState(() => _error = '请输入有效箱数'); return; }
      boxes = qty;
      final parsedUnits = int.tryParse(_cartonQtyCtrl.text);
      if (parsedUnits != null && parsedUnits > 0) {
        unitsPerBox = parsedUnits;
      } else {
        // No carton qty provided — boxes-only mode
        boxesOnlyMode = true;
      }
    } else {
      final total = int.tryParse(_totalQtyCtrl.text);
      if (total == null || total <= 0) { setState(() => _error = '请输入有效件数'); return; }
      boxes = 1;
      unitsPerBox = total;
    }

    setState(() { _saving = true; _error = null; });
    try {
      final cartonQty = (!_isPending && _useConfigMode) ? int.tryParse(_cartonQtyCtrl.text) : null;
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
        // 如填了每箱件数且与现有不同，同步更新 SKU 默认箱规
        if (cartonQty != null && cartonQty > 0 && cartonQty != _selectedSku!.cartonQty) {
          await SkuService().update(_selectedSku!.id, cartonQty: cartonQty);
        }
      }

      // 新建库位（如需要）
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
        // 已有库存记录 → 自动转为入库操作
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
          const SnackBar(content: Text('库存已保存')));
        Navigator.of(context).pop(true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() => _error = msg is List ? msg.join(', ') : (msg ?? '保存失败'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  Widget _summaryChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.green),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手动录入库存')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SKU 部分 ──
            Row(
              children: [
                const Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                if (!_isNewSku)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('新建 SKU'),
                    onPressed: _enterNewSkuMode,
                  ),
                if (_isNewSku)
                  TextButton.icon(
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('搜索已有'),
                    onPressed: () => setState(() {
                      _isNewSku = false;
                      _skuSearchCtrl.clear();
                      _skuNameCtrl.clear();
                      _skuBarcodeCtrl.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // 搜索已有 SKU
            if (!_isNewSku) ...[
              TextField(
                controller: _skuSearchCtrl,
                decoration: InputDecoration(
                  hintText: '搜索 SKU 编号 / 名称 / 条码',
                  border: const OutlineInputBorder(),
                  suffixIcon: _skuSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : _selectedSku != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                ),
                onChanged: (v) {
                  if (_selectedSku != null) setState(() => _selectedSku = null);
                  _searchSkus(v);
                },
              ),
              if (_skuResults.isNotEmpty && _selectedSku == null)
                Card(
                  margin: const EdgeInsets.only(top: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._skuResults.take(5).map((s) => ListTile(
                            dense: true,
                            title: Text(s.sku),
                            subtitle: s.name != null ? Text(s.name!) : null,
                            onTap: () => setState(() {
                              _selectedSku = s;
                              _skuSearchCtrl.text = s.sku;
                              _skuResults = [];
                              if (s.cartonQty != null && _cartonQtyCtrl.text.isEmpty) {
                                _cartonQtyCtrl.text = s.cartonQty.toString();
                              }
                            }),
                          )),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                        title: Text('新建 "${_skuSearchCtrl.text}"',
                            style: const TextStyle(color: Colors.blue)),
                        onTap: _enterNewSkuMode,
                      ),
                    ],
                  ),
                ),
              // 搜索了但没有结果
              if (_skuResults.isEmpty &&
                  _selectedSku == null &&
                  _skuSearchCtrl.text.isNotEmpty &&
                  !_skuSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('未找到，', style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: _enterNewSkuMode,
                        child: const Text('点击新建此 SKU',
                            style: TextStyle(color: Colors.blue,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
            ],

            // 新建 SKU 表单
            if (_isNewSku) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade50,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _skuSearchCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'SKU 编号 *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _skuNameCtrl,
                      decoration: const InputDecoration(
                        labelText: '商品名称',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _skuBarcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: '条形码（可选）',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── 库位部分 ──
            Row(
              children: [
                const Text('库位',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                if (!_isNewLoc)
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('新建库位'),
                    onPressed: _enterNewLocMode,
                  ),
                if (_isNewLoc)
                  TextButton.icon(
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('搜索已有'),
                    onPressed: () => setState(() {
                      _isNewLoc = false;
                      _locSearchCtrl.clear();
                      _newLocCodeCtrl.clear();
                      _newLocDescCtrl.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // 搜索已有库位
            if (!_isNewLoc) ...[
              TextField(
                controller: _locSearchCtrl,
                decoration: InputDecoration(
                  hintText: '搜索库位编号',
                  border: const OutlineInputBorder(),
                  suffixIcon: _locSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)))
                      : _selectedLoc != null
                          ? const Icon(Icons.check_circle,
                              color: Colors.green)
                          : null,
                ),
                onChanged: (v) {
                  if (_selectedLoc != null) {
                    setState(() => _selectedLoc = null);
                  }
                  _searchLocs(v);
                },
              ),
              if (_locResults.isNotEmpty && _selectedLoc == null)
                Card(
                  margin: const EdgeInsets.only(top: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._locResults.take(5).map((l) => ListTile(
                            dense: true,
                            title: Text(l.code),
                            subtitle: l.description != null
                                ? Text(l.description!)
                                : null,
                            onTap: () => setState(() {
                              _selectedLoc = l;
                              _locSearchCtrl.text = l.code;
                              _locResults = [];
                            }),
                          )),
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add_circle_outline,
                            color: Colors.blue),
                        title: Text('新建 "${_locSearchCtrl.text}"',
                            style:
                                const TextStyle(color: Colors.blue)),
                        onTap: _enterNewLocMode,
                      ),
                    ],
                  ),
                ),
              if (_locResults.isEmpty &&
                  _selectedLoc == null &&
                  _locSearchCtrl.text.isNotEmpty &&
                  !_locSearching)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      const Text('未找到，',
                          style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: _enterNewLocMode,
                        child: const Text('点击新建此库位',
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
            ],

            // 新建库位表单
            if (_isNewLoc) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade50,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _newLocCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: '库位编号 *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newLocDescCtrl,
                      decoration: const InputDecoration(
                        labelText: '描述（可选）',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ── 初始库存 ──
            const Text('初始库存',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),

            // 待清点 toggle
            CheckboxListTile(
              value: _isPending,
              onChanged: (v) => setState(() => _isPending = v ?? false),
              title: const Text('暂存 / 待清点'),
              subtitle: const Text('货已到位，数量暂未确认',
                  style: TextStyle(fontSize: 12)),
              secondary: Icon(Icons.pending_actions_outlined,
                  color: _isPending ? Colors.orange : Colors.grey),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              tileColor: _isPending ? Colors.orange.shade50 : null,
            ),

            if (!_isPending) ...[
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: true,
                      label: Text('按箱规'),
                      icon: Icon(Icons.view_list, size: 16)),
                  ButtonSegment(
                      value: false,
                      label: Text('按总数量'),
                      icon: Icon(Icons.numbers, size: 16)),
                ],
                selected: {_useConfigMode},
                onSelectionChanged: (v) =>
                    setState(() => _useConfigMode = v.first),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (ctx, setS) {
                  if (!_useConfigMode) {
                    final total = int.tryParse(_totalQtyCtrl.text) ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _totalQtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '总件数 *',
                            hintText: '0',
                            border: OutlineInputBorder(),
                            suffixText: '件',
                          ),
                          onChanged: (_) => setS(() {}),
                        ),
                        if (total > 0) ...[
                          const SizedBox(height: 8),
                          _summaryChip('合计 $total 件'),
                        ],
                      ],
                    );
                  }
                  // 按箱规
                  final boxes = int.tryParse(_qtyCtrl.text) ?? 0;
                  final units = int.tryParse(_cartonQtyCtrl.text);
                  final isBoxesOnly = units == null || units <= 0;
                  final total = isBoxesOnly ? 0 : boxes * units;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('箱数 *',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _qtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    border: OutlineInputBorder(),
                                    suffixText: '箱',
                                  ),
                                  onChanged: (_) => setS(() {}),
                                ),
                              ],
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(8, 22, 8, 0),
                            child: Text('×',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('每箱件数（可选）',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _cartonQtyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '留空=仅记箱数',
                                    border: OutlineInputBorder(),
                                    suffixText: '件/箱',
                                  ),
                                  onChanged: (_) => setS(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (boxes > 0) ...[
                        const SizedBox(height: 8),
                        isBoxesOnly
                            ? _summaryChip('$boxes 箱（箱规待录）')
                            : _summaryChip('合计 $total 件'),
                      ],
                    ],
                  );
                },
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        '将创建一条"待清点"记录，库存数量不计入合计。'
                        '后续确认数量后可通过"调整"更新。',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── 备注 ──
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '例：临时存放、待清点、数量未确认…',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_isPending
                        ? Icons.pending_actions_outlined
                        : Icons.save),
                label: Text(_isPending ? '确认暂存' : '保存库存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
