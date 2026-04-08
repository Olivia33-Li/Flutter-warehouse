import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/sku_service.dart';

class SkuFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initial;
  const SkuFormScreen({super.key, this.initial});

  @override
  ConsumerState<SkuFormScreen> createState() => _SkuFormScreenState();
}

class _SkuFormScreenState extends ConsumerState<SkuFormScreen> {
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
    final isAdmin = ref.read(currentUserProvider)?.isAdmin ?? false;
    if (_skuCtrl.text.trim().isEmpty) {
      setState(() => _error = 'SKU 编号不能为空');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final service = SkuService();
      final newBarcode = _barcodeCtrl.text.trim();
      final originalBarcode = widget.initial?['barcode'] as String? ?? '';

      if (_isEdit) {
        await service.update(
          widget.initial!['_id'],
          name: _nameCtrl.text.trim(),
          // Only send barcode if admin and it changed
          barcode: (isAdmin && newBarcode != originalBarcode) ? newBarcode : null,
          cartonQty: int.tryParse(_cartonQtyCtrl.text),
        );
      } else {
        await service.create(
          sku: _skuCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          barcode: newBarcode.isEmpty ? null : newBarcode,
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

  void _showBarcodeHistory() {
    final id = widget.initial!['_id'] as String;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BarcodeHistorySheet(skuId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;

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

          // ── Barcode field ────────────────────────────────────────────────
          TextField(
            controller: _barcodeCtrl,
            enabled: isAdmin,
            decoration: InputDecoration(
              labelText: '条码',
              border: const OutlineInputBorder(),
              helperText: isAdmin ? null : '仅管理员可修改条码',
              helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              suffixIcon: (!isAdmin && _barcodeCtrl.text.isNotEmpty)
                  ? const Icon(Icons.lock_outline, size: 16)
                  : null,
            ),
          ),
          if (_isEdit) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.history, size: 16),
                label: const Text('查看条码历史', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _showBarcodeHistory,
              ),
            ),
          ] else
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

// ─── Barcode history bottom sheet ─────────────────────────────────────────────

class _BarcodeHistorySheet extends StatefulWidget {
  final String skuId;
  const _BarcodeHistorySheet({required this.skuId});

  @override
  State<_BarcodeHistorySheet> createState() => _BarcodeHistorySheetState();
}

class _BarcodeHistorySheetState extends State<_BarcodeHistorySheet> {
  final _service = SkuService();
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getBarcodeHistory(widget.skuId);
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    final history = (_data?['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final currentBarcode = _data?['currentBarcode'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                const Text('条码变更历史',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (currentBarcode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text('当前: $currentBarcode',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _data == null && _error == null
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)))
                    : history.isEmpty
                        ? Center(
                            child: Text('暂无条码变更记录',
                                style: TextStyle(color: Colors.grey.shade500)))
                        : ListView.builder(
                            controller: controller,
                            padding: const EdgeInsets.all(12),
                            itemCount: history.length,
                            itemBuilder: (_, i) {
                              final entry = history[i];
                              final barcode = entry['barcode'] as String? ?? '';
                              final changedBy = entry['changedBy'] as String? ?? '';
                              final source = entry['source'] as String? ?? '';
                              final changedAt = entry['changedAt'] != null
                                  ? DateTime.tryParse(entry['changedAt'] as String)
                                  : null;
                              final isCurrent = barcode == currentBarcode && i == 0;

                              final sourceLabel = switch (source) {
                                'manual' => '手动编辑',
                                'import' => '批量导入',
                                _ => source,
                              };

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              Text(barcode,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                      fontFamily: 'monospace')),
                                              if (isCurrent) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text('当前',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.green.shade700,
                                                          fontWeight:
                                                              FontWeight.w600)),
                                                ),
                                              ],
                                            ]),
                                            const SizedBox(height: 3),
                                            Text('$changedBy · $sourceLabel',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600)),
                                          ],
                                        ),
                                      ),
                                      if (changedAt != null)
                                        Text(fmt.format(changedAt.toLocal()),
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
