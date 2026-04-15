class ChangeRecord {
  final String id;
  final String userId;
  final String userName;
  final String action;          // create | update | delete
  final String entity;          // SKU | 库位 | 库存
  final String? entityId;
  final String description;
  final String? businessAction; // 入库|出库|调整|录入|删除库存|结构修改|批量转移|批量转入|批量复制|批量复制进入|新建库位|编辑库位|删除库位|标记已检查|取消已检查|新建SKU|编辑SKU|删除SKU
  final Map<String, dynamic>? details;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;

  ChangeRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entity,
    this.entityId,
    required this.description,
    this.businessAction,
    this.details,
    this.changes,
    required this.createdAt,
  });

  factory ChangeRecord.fromJson(Map<String, dynamic> json) => ChangeRecord(
        id: json['_id'] ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName'] ?? '',
        action: json['action'] ?? '',
        entity: json['entity'] ?? '',
        entityId: json['entityId']?.toString(),
        description: json['description'] ?? '',
        businessAction: json['businessAction'],
        details: json['details'] as Map<String, dynamic>?,
        changes: json['changes'] as Map<String, dynamic>?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}
