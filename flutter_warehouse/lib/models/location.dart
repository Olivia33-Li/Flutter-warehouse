class Location {
  final String id;
  final String code;
  final String? description;

  Location({required this.id, required this.code, this.description});

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        id: json['_id'] ?? '',
        code: json['code'] ?? '',
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'code': code,
        if (description != null) 'description': description,
      };

  String get displayName =>
      description != null && description!.isNotEmpty ? '$code - $description' : code;
}
