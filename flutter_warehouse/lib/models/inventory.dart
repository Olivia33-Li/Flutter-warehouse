import '../l10n/app_localizations.dart';
import 'location.dart';

class InventoryConfig {
  final int boxes;
  final int unitsPerBox;

  InventoryConfig({required this.boxes, required this.unitsPerBox});

  int get qty => boxes * unitsPerBox;

  factory InventoryConfig.fromJson(Map<String, dynamic> json) => InventoryConfig(
        boxes: (json['boxes'] as num?)?.toInt() ?? 0,
        unitsPerBox: (json['unitsPerBox'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {'boxes': boxes, 'unitsPerBox': unitsPerBox};
}

class InventoryRecord {
  final String id;
  final String skuCode;
  final String? skuId;
  final String? skuName;
  final dynamic locationId; // String or populated Location object
  final int boxes;
  final int unitsPerBox;
  final List<InventoryConfig> configurations;
  final bool pendingCount;
  /// confirmed | pending_count | temporary
  final String stockStatus;
  /// When true: SKU is registered at this location but no quantity was provided.
  /// Display as "待清点" instead of a number.
  final bool quantityUnknown;

  /// When true: only box count is known, per-box qty is unknown.
  /// Display as "X 箱" without piece count.
  final bool boxesOnlyMode;

  InventoryRecord({
    required this.id,
    required this.skuCode,
    this.skuId,
    this.skuName,
    required this.locationId,
    required this.boxes,
    required this.unitsPerBox,
    this.configurations = const [],
    this.pendingCount = false,
    this.stockStatus = 'confirmed',
    this.quantityUnknown = false,
    this.boxesOnlyMode = false,
  });

  int get totalQty {
    if (boxesOnlyMode || quantityUnknown) return 0;
    if (configurations.isNotEmpty) return configurations.fold(0, (s, c) => s + c.qty);
    return boxes * unitsPerBox;
  }

  int get totalBoxes => configurations.isNotEmpty
      ? configurations.fold(0, (s, c) => s + c.boxes)
      : boxes;

  /// Human-readable quantity string with localization support.
  String qtyDisplayL10n(AppLocalizations l10n) {
    final box = l10n.unitBox;
    final pcs = l10n.unitPiece;
    if (quantityUnknown) return l10n.skuDetailQtyLinePending;
    if (boxesOnlyMode) return '$totalBoxes $box';
    if (configurations.length > 1) {
      final parts = configurations.map((c) => '${c.boxes}$box·${c.unitsPerBox}$pcs/$box').join(' + ');
      return '$parts = $totalQty $pcs';
    }
    if (unitsPerBox > 1) return '$totalBoxes$box · $totalQty$pcs';
    return '$totalQty $pcs';
  }

  /// Human-readable quantity string (Chinese fallback, kept for compatibility).
  String get qtyDisplay {
    if (quantityUnknown) return '待清点';
    if (boxesOnlyMode) return '$totalBoxes 箱';
    if (configurations.length > 1) {
      final parts = configurations.map((c) => '${c.boxes}箱·${c.unitsPerBox}件/箱').join(' + ');
      return '$parts = $totalQty 件';
    }
    if (unitsPerBox > 1) return '$totalBoxes箱 · $totalQty件';
    return '$totalQty 件';
  }

  Location? get location => locationId is Map ? Location.fromJson(locationId) : null;

  bool get isTemporary => stockStatus == 'temporary';

  factory InventoryRecord.fromJson(Map<String, dynamic> json) {
    final configs = (json['configurations'] as List?)
            ?.map((e) => InventoryConfig.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final pendingCount = json['pendingCount'] == true;
    return InventoryRecord(
      id: json['_id'] ?? '',
      skuCode: json['skuCode'] ?? '',
      skuId: json['skuId']?.toString(),
      skuName: json['skuName'],
      locationId: json['locationId'],
      boxes: (json['boxes'] as num?)?.toInt() ?? 0,
      unitsPerBox: (json['unitsPerBox'] as num?)?.toInt() ?? 1,
      configurations: configs,
      pendingCount: pendingCount,
      stockStatus: json['stockStatus'] as String? ??
          (pendingCount ? 'pending_count' : 'confirmed'),
      quantityUnknown: json['quantityUnknown'] == true,
      boxesOnlyMode: json['boxesOnlyMode'] == true,
    );
  }
}
