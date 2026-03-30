import 'api_service.dart';

class TransactionRecord {
  final String id;
  final String skuCode;
  final String locationCode;
  final String type; // IN | OUT | ADJUST
  final int quantity;
  final int? boxes;
  final int? unitsPerBox;
  final String? note;
  final String? businessAction; // 入库 | 出库 | 调整 | 录入 | 暂存 | 结构修改 | 批量转移 | 批量复制
  final String? operatorName;
  final DateTime createdAt;

  TransactionRecord({
    required this.id,
    required this.skuCode,
    required this.locationCode,
    required this.type,
    required this.quantity,
    this.boxes,
    this.unitsPerBox,
    this.note,
    this.businessAction,
    this.operatorName,
    required this.createdAt,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    final loc = json['locationId'];
    final locationCode = loc is Map ? (loc['code'] ?? '') : '';
    return TransactionRecord(
      id: json['_id'] ?? '',
      skuCode: json['skuCode'] ?? '',
      locationCode: locationCode as String,
      type: json['type'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      boxes: (json['boxes'] as num?)?.toInt(),
      unitsPerBox: (json['unitsPerBox'] as num?)?.toInt(),
      note: json['note'],
      businessAction: json['businessAction'],
      operatorName: json['operatorName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Human-readable action label for display
  String get actionLabel {
    if (businessAction != null && businessAction!.isNotEmpty) return businessAction!;
    return switch (type) {
      'IN' => '入库',
      'OUT' => '出库',
      'ADJUST' => '调整',
      _ => type,
    };
  }
}

class TransactionPage {
  final List<TransactionRecord> records;
  final int total;
  final int page;

  TransactionPage({
    required this.records,
    required this.total,
    required this.page,
  });
}

class TransactionService {
  final _api = ApiService.instance.dio;

  /// Fetch transactions for a specific SKU+location (used in inventory detail sheet)
  Future<List<TransactionRecord>> getForInventory(
    String skuCode,
    String locationId, {
    int limit = 100,
  }) async {
    final response = await _api.get('/transactions', queryParameters: {
      'skuCode': skuCode,
      'locationId': locationId,
      'limit': limit,
    });
    final records = response.data['records'] as List;
    return records.map((e) => TransactionRecord.fromJson(e)).toList();
  }

  /// General paginated query with filters (used in history / reports)
  Future<TransactionPage> getAll({
    String? skuCode,
    String? locationId,
    String? type,
    String? businessAction,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get('/transactions', queryParameters: {
      if (skuCode != null) 'skuCode': skuCode,
      if (locationId != null) 'locationId': locationId,
      if (type != null) 'type': type,
      if (businessAction != null) 'businessAction': businessAction,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
      'page': page,
      'limit': limit,
    });
    final data = response.data;
    return TransactionPage(
      records: (data['records'] as List)
          .map((e) => TransactionRecord.fromJson(e))
          .toList(),
      total: data['total'] ?? 0,
      page: data['page'] ?? page,
    );
  }
}
