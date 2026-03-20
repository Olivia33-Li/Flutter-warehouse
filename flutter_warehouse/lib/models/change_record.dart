class ChangeRecord {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String entity;
  final String description;
  final DateTime createdAt;

  ChangeRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entity,
    required this.description,
    required this.createdAt,
  });

  factory ChangeRecord.fromJson(Map<String, dynamic> json) => ChangeRecord(
        id: json['_id'] ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName'] ?? '',
        action: json['action'] ?? '',
        entity: json['entity'] ?? '',
        description: json['description'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}
