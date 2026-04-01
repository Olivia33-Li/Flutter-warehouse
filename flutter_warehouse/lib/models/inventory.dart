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
  /// Display as "未填写数量" instead of a number.
  final bool quantityUnknown;

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
  });

  int get totalQty => configurations.isNotEmpty
      ? configurations.fold(0, (s, c) => s + c.qty)
      : boxes * unitsPerBox;

  /// Human-readable quantity string. Use this for display instead of totalQty directly.
  String get qtyDisplay => quantityUnknown ? '未填写数量' : '$totalQty 件';

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
    );
  }
}
