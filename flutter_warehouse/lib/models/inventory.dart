import 'sku.dart';
import 'location.dart';

class InventoryRecord {
  final String id;
  final dynamic skuId; // String or Sku object
  final dynamic locationId; // String or Location object
  final int quantity;

  InventoryRecord({
    required this.id,
    required this.skuId,
    required this.locationId,
    required this.quantity,
  });

  Sku? get sku => skuId is Map ? Sku.fromJson(skuId) : null;
  Location? get location => locationId is Map ? Location.fromJson(locationId) : null;

  factory InventoryRecord.fromJson(Map<String, dynamic> json) => InventoryRecord(
        id: json['_id'] ?? '',
        skuId: json['skuId'],
        locationId: json['locationId'],
        quantity: json['quantity'] ?? 0,
      );
}
