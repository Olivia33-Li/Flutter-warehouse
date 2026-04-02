import 'api_service.dart';
import '../models/inventory.dart';

class InventoryService {
  final _api = ApiService.instance.dio;

  Future<List<InventoryRecord>> getAll({
    String? skuCode,
    String? locationId,
    bool pendingOnly = false,
    String? stockStatus,
  }) async {
    final response = await _api.get('/inventory', queryParameters: {
      if (skuCode != null) 'skuCode': skuCode,
      if (locationId != null) 'locationId': locationId,
      if (pendingOnly) 'pendingOnly': 'true',
      if (stockStatus != null) 'stockStatus': stockStatus,
    });
    return (response.data as List).map((e) => InventoryRecord.fromJson(e)).toList();
  }

  Future<InventoryRecord> create({
    required String skuCode,
    required String locationId,
    int boxes = 0,
    int? unitsPerBox,
    String? note,
    bool pendingCount = false,
    bool boxesOnlyMode = false,
  }) async {
    final response = await _api.post('/inventory', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      'boxes': boxes,
      if (unitsPerBox != null) 'unitsPerBox': unitsPerBox,
      if (note != null && note.isNotEmpty) 'note': note,
      if (pendingCount) 'pendingCount': true,
      if (boxesOnlyMode) 'boxesOnlyMode': true,
    });
    return InventoryRecord.fromJson(response.data);
  }

  Future<InventoryRecord> markPending(String id, {required bool pending}) async {
    final response = await _api.patch('/inventory/$id', data: {'pendingCount': pending});
    return InventoryRecord.fromJson(response.data);
  }

  Future<void> stockIn({
    required String skuCode,
    required String locationId,
    required int boxes,
    int? unitsPerBox,
    String? note,
    bool boxesOnlyMode = false,
  }) async {
    await _api.post('/transactions/in', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      'boxes': boxes,
      if (unitsPerBox != null) 'unitsPerBox': unitsPerBox,
      if (note != null && note.isNotEmpty) 'note': note,
      if (boxesOnlyMode) 'boxesOnlyMode': true,
    });
  }

  Future<void> stockOut({
    required String skuCode,
    required String locationId,
    required int quantity,
    String? note,
  }) async {
    await _api.post('/transactions/out', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      'quantity': quantity,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> stockAdjust({
    required String skuCode,
    required String locationId,
    int? quantity,
    List<Map<String, int>>? configurations,
    String? note,
  }) async {
    await _api.post('/transactions/adjust', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      if (quantity != null) 'quantity': quantity,
      if (configurations != null) 'configurations': configurations,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<InventoryRecord> update(String id, {int? boxes, int? unitsPerBox}) async {
    final response = await _api.patch('/inventory/$id', data: {
      if (boxes != null) 'boxes': boxes,
      if (unitsPerBox != null) 'unitsPerBox': unitsPerBox,
    });
    return InventoryRecord.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/inventory/$id');
  }

  Future<void> clearAll() async {
    await _api.delete('/inventory');
  }

  /// Wipes all business data (inventory, SKUs, locations, transactions,
  /// audit logs, import logs) while preserving user accounts.
  Future<Map<String, dynamic>> clearAllData() async {
    final response = await _api.delete('/inventory/all-data');
    return response.data as Map<String, dynamic>;
  }
}
