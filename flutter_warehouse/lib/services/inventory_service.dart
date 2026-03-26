import 'api_service.dart';
import '../models/inventory.dart';

class InventoryService {
  final _api = ApiService.instance.dio;

  Future<List<InventoryRecord>> getAll({String? skuCode, String? locationId}) async {
    final response = await _api.get('/inventory', queryParameters: {
      if (skuCode != null) 'skuCode': skuCode,
      if (locationId != null) 'locationId': locationId,
    });
    return (response.data as List).map((e) => InventoryRecord.fromJson(e)).toList();
  }

  Future<InventoryRecord> create({
    required String skuCode,
    required String locationId,
    required int boxes,
    required int unitsPerBox,
    String? note,
  }) async {
    final response = await _api.post('/inventory', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      'boxes': boxes,
      'unitsPerBox': unitsPerBox,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return InventoryRecord.fromJson(response.data);
  }

  Future<void> stockIn({
    required String skuCode,
    required String locationId,
    required int boxes,
    required int unitsPerBox,
    String? note,
  }) async {
    await _api.post('/transactions/in', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      'boxes': boxes,
      'unitsPerBox': unitsPerBox,
      if (note != null && note.isNotEmpty) 'note': note,
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
}
