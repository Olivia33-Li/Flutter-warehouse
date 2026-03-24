import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../services/transaction_service.dart';
import '../services/inventory_service.dart';

class InventoryDetailSheet extends StatefulWidget {
  final String skuCode;
  final String? skuId;
  final String locationId;
  final String locationCode;
  final int totalQty;
  final bool showSkuNav;
  final bool showLocNav;
  final bool canEdit;
  /// Called after a successful stock-in so the parent can refresh.
  final VoidCallback? onStockIn;

  const InventoryDetailSheet({
    super.key,
    required this.skuCode,
    this.skuId,
    required this.locationId,
    required this.locationCode,
    required this.totalQty,
    this.showSkuNav = false,
    this.showLocNav = false,
    this.canEdit = false,
    this.onStockIn,
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
      _records = await _txService.getForInventory(
        widget.skuCode,
        widget.locationId,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 信息行
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.skuCode}  →  ${widget.locationCode}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: boxesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '箱数 *',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixText: '箱',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '每箱件数 *',
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixText: '件/箱',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
                  isDense: true,
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
              onPressed: saving
                  ? null
                  : () async {
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
                        widget.onStockIn?.call();
                        _load(); // 刷新流水
                      } catch (e) {
                        setS(() {
                          saving = false;
                          err = '入库失败: $e';
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('确认入库'),
            ),
          ],
        ),
      ),
    );
  }

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
      return '${r.boxes} 箱 × ${r.unitsPerBox} = ${r.quantity} 件';
    }
    if (r.type == 'ADJUST') return '调整为 ${r.quantity} 件';
    return '${r.quantity} 件';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // 拖动条
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 头部：SKU + 库位 + 总量
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
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(widget.locationCode,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                // 总库存徽章
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.totalQty > 0
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.totalQty > 0
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Text(
                    '${widget.totalQty} 件',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: widget.totalQty > 0
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 操作按钮行
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                // 入库按钮（最重要，始终显示给有权限的用户）
                if (widget.canEdit)
                  FilledButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('入库'),
                    onPressed: _showStockInDialog,
                  ),
                if (widget.canEdit) const SizedBox(width: 8),
                // 导航按钮
                if (widget.showSkuNav && widget.skuId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.qr_code_2, size: 16),
                    label: const Text('SKU 详情'),
                    onPressed: () {
                      context.pop();
                      context.push('/skus/${widget.skuId}');
                    },
                  ),
                if (widget.showLocNav)
                  TextButton.icon(
                    icon: const Icon(Icons.place_outlined, size: 16),
                    label: const Text('库位详情'),
                    onPressed: () {
                      context.pop();
                      context.push('/locations/${widget.locationId}');
                    },
                  ),
              ],
            ),
          ),

          const Divider(height: 20),

          // 流水记录标题
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                const Text('入出库记录',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const Spacer(),
                if (_records != null)
                  Text('共 ${_records!.length} 条',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
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
                        ),
                      )
                    : _records!.isEmpty
                        ? const Center(
                            child: Text('暂无流水记录',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            controller: scrollCtrl,
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _records!.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final r = _records![i];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _typeColor(r.type)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: _typeColor(r.type)
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        _typeLabel(r.type),
                                        style: TextStyle(
                                          color: _typeColor(r.type),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(_txDetail(r),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14)),
                                          if (r.note != null &&
                                              r.note!.isNotEmpty)
                                            Text(r.note!,
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MM-dd HH:mm')
                                          .format(r.createdAt.toLocal()),
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
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
}
