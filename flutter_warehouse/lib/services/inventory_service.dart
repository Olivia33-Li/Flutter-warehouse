import 'api_service.dart';
import '../models/inventory.dart';

class InventoryService {
  final _api = ApiService.instance.dio;

  Future<List<InventoryRecord>> getAll({String? skuId, String? locationId}) async {
    final response = await _api.get('/inventory', queryParameters: {
      if (skuId != null) 'skuId': skuId,
      if (locationId != null) 'locationId': locationId,
    });
    return (response.data as List).map((e) => InventoryRecord.fromJson(e)).toList();
  }

  Future<InventoryRecord> upsert({
    required String skuId,
    required String locationId,
    required int quantity,
  }) async {
    final response = await _api.put('/inventory', data: {
      'skuId': skuId,
      'locationId': locationId,
      'quantity': quantity,
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
