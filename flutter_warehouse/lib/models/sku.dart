class SkuLocation {
  final String locationId;
  final String locationCode;
  final int boxes;
  final int unitsPerBox;
  final int totalQty;
  final bool boxesOnly;
  /// Pieces that are not in a full-box configuration (mixed mode).
  final int loosePcs;
  /// Cartons that have no per-box spec (boxesOnly portion).
  final int unconfiguredCartons;

  SkuLocation({
    required this.locationId,
    required this.locationCode,
    required this.boxes,
    required this.unitsPerBox,
    required this.totalQty,
    this.boxesOnly = false,
    this.loosePcs = 0,
    this.unconfiguredCartons = 0,
  });

  /// Cartons that have a known per-box spec.
  int get configuredCartons => boxes - unconfiguredCartons;

  factory SkuLocation.fromJson(Map<String, dynamic> json) => SkuLocation(
        locationId: json['locationId'] ?? '',
        locationCode: json['locationCode'] ?? '',
        boxes: (json['boxes'] as num?)?.toInt() ?? 0,
        unitsPerBox: (json['unitsPerBox'] as num?)?.toInt() ?? 1,
        totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
        boxesOnly: json['boxesOnly'] == true,
        loosePcs: (json['loosePcs'] as num?)?.toInt() ?? 0,
        unconfiguredCartons: (json['unconfiguredCartons'] as num?)?.toInt() ?? 0,
      );
}

class Sku {
  final String id;
  final String sku;
  final String? name;
  final String? barcode;
  final int? cartonQty;
  final int? minStock;
  final List<SkuLocation> locations;
  final int totalQty;
  // 'active' | 'archived' — null/missing treated as 'active' (backwards compat)
  final String status;

  Sku({
    required this.id,
    required this.sku,
    this.name,
    this.barcode,
    this.cartonQty,
    this.minStock,
    this.locations = const [],
    this.totalQty = 0,
    this.status = 'active',
  });

  factory Sku.fromJson(Map<String, dynamic> json) => Sku(
        id: json['_id'] ?? '',
        sku: json['sku'] ?? '',
        name: json['name'],
        barcode: json['barcode'],
        cartonQty: json['cartonQty'],
        minStock: json['minStock'],
        locations: (json['locations'] as List?)
                ?.map((e) => SkuLocation.fromJson(e))
                .toList() ??
            [],
        totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'sku': sku,
        if (name != null) 'name': name,
        if (barcode != null) 'barcode': barcode,
        if (cartonQty != null) 'cartonQty': cartonQty,
        'status': status,
      };

  String get displayName => name != null && name!.isNotEmpty ? name! : sku;

  bool get isArchived => status == 'archived';

  /// True when every location for this SKU is in boxes-only mode (no per-box qty known).
  bool get allBoxesOnly => locations.isNotEmpty && locations.every((l) => l.boxesOnly);

  /// Total boxes across all locations.
  int get totalBoxes => locations.fold(0, (s, l) => s + l.boxes);

  /// Total loose pieces (not in a full box) across all locations.
  int get totalLoosePcs => locations.fold(0, (s, l) => s + l.loosePcs);

  /// Total cartons without a per-box spec across all locations.
  int get totalUnconfiguredCartons => locations.fold(0, (s, l) => s + l.unconfiguredCartons);

  /// Total cartons with a known per-box spec across all locations.
  int get totalConfiguredCartons => locations.fold(0, (s, l) => s + l.configuredCartons);
}
