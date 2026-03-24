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
  // 新建 SKU 时的额外字段
  final _skuNameCtrl = TextEditingController();
  final _skuBarcodeCtrl = TextEditingController();

  List<Sku> _skuResults = [];
  List<Location> _locResults = [];
  Sku? _selectedSku;
  Location? _selectedLoc;
  bool _isNewSku = false;     // 是否新建模式

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

  Future<void> _save() async {
    if (!_isNewSku && _selectedSku == null) {
      setState(() => _error = '请选择 SKU 或新建');
      return;
    }
    if (_isNewSku && _skuSearchCtrl.text.trim().isEmpty) {
      setState(() => _error = 'SKU 编号不能为空');
      return;
    }
    if (_selectedLoc == null) { setState(() => _error = '请选择库位'); return; }
    final qty = int.tryParse(_qtyCtrl.text);
    if (qty == null || qty <= 0) { setState(() => _error = '请输入有效箱数'); return; }

    setState(() { _saving = true; _error = null; });
    try {
      final cartonQty = int.tryParse(_cartonQtyCtrl.text);
      String skuCode;

      if (_isNewSku) {
        // 创建新 SKU
        final newSku = await SkuService().create(
          sku: _skuSearchCtrl.text.trim(),
          name: _skuNameCtrl.text.trim().isEmpty ? null : _skuNameCtrl.text.trim(),
          barcode: _skuBarcodeCtrl.text.trim().isEmpty ? null : _skuBarcodeCtrl.text.trim(),
          cartonQty: cartonQty,
        );
        skuCode = newSku.sku;
      } else {
        skuCode = _selectedSku!.sku;
        // 如填了每箱件数且与现有不同，更新 SKU
        if (cartonQty != null && cartonQty > 0 && cartonQty != _selectedSku!.cartonQty) {
          await SkuService().update(_selectedSku!.id, cartonQty: cartonQty);
        }
      }

      try {
        await InventoryService().create(
          skuCode: skuCode,
          locationId: _selectedLoc!.id,
          boxes: qty,
          unitsPerBox: cartonQty ?? 1,
        );
      } on DioException catch (e) {
        // 已有库存记录 → 自动转为入库操作
        final statusCode = e.response?.statusCode;
        if (statusCode == 409) {
          await InventoryService().stockIn(
            skuCode: skuCode,
            locationId: _selectedLoc!.id,
            boxes: qty,
            unitsPerBox: cartonQty ?? 1,
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
    super.dispose();
  }

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
                      // 搜索有结果但用户想新建
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
            const Text('库位', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              controller: _locSearchCtrl,
              decoration: InputDecoration(
                hintText: '搜索库位编号',
                border: const OutlineInputBorder(),
                suffixIcon: _locSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : _selectedLoc != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
              ),
              onChanged: (v) {
                if (_selectedLoc != null) setState(() => _selectedLoc = null);
                _searchLocs(v);
              },
            ),
            if (_locResults.isNotEmpty && _selectedLoc == null)
              Card(
                margin: const EdgeInsets.only(top: 4),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _locResults.length.clamp(0, 5),
                  itemBuilder: (_, i) {
                    final l = _locResults[i];
                    return ListTile(
                      dense: true,
                      title: Text(l.code),
                      subtitle: l.description != null ? Text(l.description!) : null,
                      onTap: () => setState(() {
                        _selectedLoc = l;
                        _locSearchCtrl.text = l.code;
                        _locResults = [];
                      }),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // ── 数量 ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('箱数 *', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '0',
                          border: OutlineInputBorder(),
                          suffixText: '箱',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('每箱件数', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cartonQtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '可选',
                          border: OutlineInputBorder(),
                          suffixText: '件/箱',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('保存库存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
