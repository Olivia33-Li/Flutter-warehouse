class ChangeRecord {
  final String id;
  final String userId;
  final String userName;
  final String action;  // create | update | delete
  final String entity;  // SKU | 库位 | 库存
  final String description;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;

  ChangeRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entity,
    required this.description,
    this.changes,
    required this.createdAt,
  });

  factory ChangeRecord.fromJson(Map<String, dynamic> json) => ChangeRecord(
        id: json['_id'] ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName'] ?? '',
        action: json['action'] ?? '',
        entity: json['entity'] ?? '',
        description: json['description'] ?? '',
        changes: json['changes'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}
