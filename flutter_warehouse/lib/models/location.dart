class Location {
  final String id;
  final String code;
  final String? description;
  final int skuCount;
  final int totalQty;
  final int totalBoxes;
  final DateTime? checkedAt;

  Location({
    required this.id,
    required this.code,
    this.description,
    this.skuCount = 0,
    this.totalQty = 0,
    this.totalBoxes = 0,
    this.checkedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['_id'] ?? '',
        code: json['code'] ?? '',
        description: json['description'],
        skuCount: (json['skuCount'] as num?)?.toInt() ?? 0,
        totalQty: (json['totalQty'] as num?)?.toInt() ?? 0,
        totalBoxes: (json['totalBoxes'] as num?)?.toInt() ?? 0,
        checkedAt: json['checkedAt'] != null
            ? DateTime.tryParse(json['checkedAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        if (description != null) 'description': description,
      };

  bool get isEmpty => skuCount == 0;

  String get displayName =>
      description != null && description!.isNotEmpty ? '$code - $description' : code;
}
