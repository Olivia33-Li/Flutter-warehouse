import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../models/sku.dart';
import '../../services/sku_service.dart';
import '../../l10n/app_localizations.dart';

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
          SnackBar(content: Text('${AppLocalizations.of(context)!.navScanner}: $e')));
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
                    child: Text(AppLocalizations.of(context)!.scannerViewDetail),
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
                              Text(AppLocalizations.of(context)!.scannerTotalStock(sku.totalQty),
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                        Text(AppLocalizations.of(context)!.scannerStockLocations,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        ...sku.locations.map((loc) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.place_outlined),
                                title: Text(loc.locationCode,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                trailing: Text(AppLocalizations.of(context)!.scannerQtyPiece(loc.totalQty),
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
                          Text(AppLocalizations.of(context)!.scannerOutOfStock,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context)!.scannerAllZero,
                              style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () {
                              ctx.pop();
                              context.push('/skus/${sku.id}');
                              _lastCode = null;
                            },
                            icon: const Icon(Icons.edit),
                            label: Text(AppLocalizations.of(context)!.scannerRestock),
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
                  child: Text(AppLocalizations.of(context)!.scannerContinue),
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
            Text(AppLocalizations.of(context)!.scannerNotFound,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.scannerBarcode(code),
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ctx.pop();
                      _lastCode = null;
                    },
                    child: Text(AppLocalizations.of(context)!.scannerContinue),
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
                    label: Text(AppLocalizations.of(context)!.scannerAddProduct),
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
        title: Text(AppLocalizations.of(context)!.scannerMultipleFound),
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
        title: Text(AppLocalizations.of(context)!.scannerTitle),
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
              child: Text(
                AppLocalizations.of(context)!.scannerHint,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
