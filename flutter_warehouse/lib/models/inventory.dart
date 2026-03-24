import 'location.dart';

class InventoryRecord {
  final String id;
  final String skuCode;
  final String? skuId;
  final String? skuName;
  final dynamic locationId; // String or populated Location object
  final int boxes;
  final int unitsPerBox;

  InventoryRecord({
    required this.id,
    required this.skuCode,
    this.skuId,
    this.skuName,
    required this.locationId,
    required this.boxes,
    required this.unitsPerBox,
  });

  int get totalQty => boxes * unitsPerBox;

  Location? get location => locationId is Map ? Location.fromJson(locationId) : null;

  factory InventoryRecord.fromJson(Map<String, dynamic> json) => InventoryRecord(
        id: json['_id'] ?? '',
        skuCode: json['skuCode'] ?? '',
        skuId: json['skuId']?.toString(),
        skuName: json['skuName'],
        locationId: json['locationId'],
        boxes: (json['boxes'] as num?)?.toInt() ?? 0,
        unitsPerBox: (json['unitsPerBox'] as num?)?.toInt() ?? 1,
      );
}
