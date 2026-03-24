import 'api_service.dart';

class TransactionRecord {
  final String id;
  final String type; // IN | OUT | ADJUST
  final int quantity;
  final int? boxes;
  final int? unitsPerBox;
  final String? note;
  final DateTime createdAt;

  TransactionRecord({
    required this.id,
    required this.type,
    required this.quantity,
    this.boxes,
    this.unitsPerBox,
    this.note,
    required this.createdAt,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) =>
      TransactionRecord(
        id: json['_id'] ?? '',
        type: json['type'] ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        boxes: (json['boxes'] as num?)?.toInt(),
        unitsPerBox: (json['unitsPerBox'] as num?)?.toInt(),
        note: json['note'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
      );
}

class TransactionService {
  final _api = ApiService.instance.dio;

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
}
