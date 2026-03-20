import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../services/sku_service.dart';

class SkuFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const SkuFormScreen({super.key, this.initial});

  @override
  State<SkuFormScreen> createState() => _SkuFormScreenState();
}

class _SkuFormScreenState extends State<SkuFormScreen> {
  final _skuCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _cartonQtyCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _skuCtrl.text = widget.initial!['sku'] ?? '';
      _nameCtrl.text = widget.initial!['name'] ?? '';
      _barcodeCtrl.text = widget.initial!['barcode'] ?? '';
      _cartonQtyCtrl.text = widget.initial!['cartonQty']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _cartonQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_skuCtrl.text.trim().isEmpty) {
      setState(() => _error = 'SKU 编号不能为空');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final service = SkuService();
      if (_isEdit) {
        await service.update(
          widget.initial!['_id'],
          name: _nameCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim(),
          cartonQty: int.tryParse(_cartonQtyCtrl.text),
        );
      } else {
        await service.create(
          sku: _skuCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim(),
          cartonQty: int.tryParse(_cartonQtyCtrl.text),
        );
      }
      if (mounted) context.pop();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'];
      setState(() { _error = msg is List ? msg.join(', ') : (msg ?? '保存失败'); });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '编辑 SKU' : '新增 SKU')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _skuCtrl,
            enabled: !_isEdit,
            decoration: const InputDecoration(
              labelText: 'SKU 编号 *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: '产品名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _barcodeCtrl,
            decoration: const InputDecoration(
              labelText: '条码',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cartonQtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '每箱个数',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isEdit ? '保存' : '创建'),
          ),
        ],
      ),
    );
  }
}
