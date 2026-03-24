import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../models/sku.dart';
import '../../services/sku_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController();
  bool _processing = false;
  String? _lastCode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code == _lastCode || _processing) return;

    _lastCode = code;
    setState(() => _processing = true);

    try {
      final skus = await SkuService().getAll(search: code);
      if (!mounted) return;

      if (skus.isEmpty) {
        _showNotFoundSheet(code);
      } else if (skus.length == 1) {
        _showInventorySheet(skus.first);
      } else {
        _showPickDialog(skus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('查询失败: $e')));
        _lastCode = null;
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showInventorySheet(Sku sku) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sku.sku,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        if (sku.name != null)
                          Text(sku.name!,
                              style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ctx.pop();
                      context.push('/skus/${sku.id}');
                      _lastCode = null;
                    },
                    child: const Text('查看详情'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 库存状态
            Expanded(
              child: sku.totalQty > 0
                  ? ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('总库存: ${sku.totalQty} 箱',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                        const Text('库存位置:',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        ...sku.locations.map((loc) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.place_outlined),
                                title: Text(loc.locationCode,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                trailing: Text('${loc.totalQty} 件',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                onTap: () {
                                  ctx.pop();
                                  context.push('/locations/${loc.locationId}');
                                  _lastCode = null;
                                },
                              ),
                            )),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 64, color: Colors.orange.shade400),
                          const SizedBox(height: 12),
                          const Text('该商品已断货',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('所有位置库存为 0',
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              ctx.pop();
                              context.push('/skus/${sku.id}');
                              _lastCode = null;
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('去补货'),
                          ),
                        ],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    ctx.pop();
                    _lastCode = null;
                  },
                  child: const Text('继续扫码'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotFoundSheet(String code) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('未找到该商品',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('条码: $code', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ctx.pop();
                      _lastCode = null;
                    },
                    child: const Text('继续扫码'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ctx.pop();
                      context.push('/skus/new');
                      _lastCode = null;
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('新增商品'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPickDialog(List<Sku> skus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('找到多个匹配'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: skus
              .map((s) => ListTile(
                    title: Text(s.sku),
                    subtitle: s.name != null ? Text(s.name!) : null,
                    onTap: () {
                      ctx.pop();
                      _showInventorySheet(s);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫码查询'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_processing)
            const Center(child: CircularProgressIndicator()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: const Text(
                '将条码/二维码对准框内',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
