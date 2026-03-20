class SkuLocation {
  final String locationId;
  final String locationCode;
  final int qty;

  SkuLocation({required this.locationId, required this.locationCode, required this.qty});

  factory SkuLocation.fromJson(Map<String, dynamic> json) => SkuLocation(
        locationId: json['locationId'] ?? '',
        locationCode: json['locationCode'] ?? '',
        qty: json['qty'] ?? 0,
      );
}

class Sku {
  final String id;
  final String sku;
  final String? name;
  final String? barcode;
  final int? cartonQty;
  final List<SkuLocation> locations;
  final int totalQty;

  Sku({
    required this.id,
    required this.sku,
    this.name,
    this.barcode,
    this.cartonQty,
    this.locations = const [],
    this.totalQty = 0,
  });

  factory Sku.fromJson(Map<String, dynamic> json) => Sku(
        id: json['_id'] ?? '',
        sku: json['sku'] ?? '',
        name: json['name'],
        barcode: json['barcode'],
        cartonQty: json['cartonQty'],
        locations: (json['locations'] as List?)
                ?.map((e) => SkuLocation.fromJson(e))
                .toList() ??
            [],
        totalQty: json['totalQty'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'sku': sku,
        if (name != null) 'name': name,
        if (barcode != null) 'barcode': barcode,
        if (cartonQty != null) 'cartonQty': cartonQty,
      };

  String get displayName => name != null && name!.isNotEmpty ? name! : sku;
}
