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
    // Mode A – single carton spec
    int? boxes,
    int? unitsPerBox,
    // Mode A (multi-spec) – mixed configurations
    List<Map<String, int>>? configurations,
    // Mode B – boxes only, pcs/carton unknown
    bool boxesOnlyMode = false,
    // Mode C – piece count delta, no carton structure
    int? addQuantity,
    // Common
    String? note,
    bool pendingCount = false,
  }) async {
    await _api.post('/transactions/in', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      if (configurations != null && configurations.isNotEmpty)
        'configurations': configurations
      else if (boxes != null) ...{
        'boxes': boxes,
        if (unitsPerBox != null) 'unitsPerBox': unitsPerBox,
      },
      if (addQuantity != null) 'addQuantity': addQuantity,
      if (boxesOnlyMode) 'boxesOnlyMode': true,
      if (pendingCount) 'pendingCount': true,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> stockOut({
    required String skuCode,
    required String locationId,
    int? quantity,              // by-qty: deduct from loosePcs
    List<Map<String, int>>? configurations, // by-carton: deduct from configurations
    int? unconfiguredCartons,   // cartons-only: deduct from unconfiguredCartons
    String? note,
  }) async {
    await _api.post('/transactions/out', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      if (quantity != null) 'quantity': quantity,
      if (configurations != null && configurations.isNotEmpty) 'configurations': configurations,
      if (unconfiguredCartons != null && unconfiguredCartons > 0)
        'unconfiguredCartons': unconfiguredCartons,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> stockAdjust({
    required String skuCode,
    required String locationId,
    int? quantity,
    List<Map<String, int>>? configurations,
    int loosePcs = 0,  // pcs not in any carton spec
    String adjustMode = 'qty', // 'qty' | 'mixed'
    String? note,
  }) async {
    await _api.post('/transactions/adjust', data: {
      'skuCode': skuCode,
      'locationId': locationId,
      if (quantity != null) 'quantity': quantity,
      if (configurations != null && configurations.isNotEmpty) 'configurations': configurations,
      if (loosePcs > 0) 'loosePcs': loosePcs,
      'adjustMode': adjustMode,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> correctSku({
    required String inventoryId,
    required String newSkuCode,
    required String note,
    bool allowMerge = false,
  }) async {
    await _api.post('/transactions/correct-sku', data: {
      'inventoryId': inventoryId,
      'newSkuCode': newSkuCode,
      'note': note,
      if (allowMerge) 'allowMerge': true,
    });
  }

  Future<void> confirmPending({
    required String inventoryId,
    String? newSkuCode,
    required String note,
  }) async {
    await _api.post('/transactions/confirm-pending', data: {
      'inventoryId': inventoryId,
      if (newSkuCode != null && newSkuCode.isNotEmpty) 'newSkuCode': newSkuCode,
      'note': note,
    });
  }

  Future<void> splitPending({
    required String inventoryId,
    required List<Map<String, dynamic>> splits,
    required String note,
  }) async {
    await _api.post('/transactions/split-pending', data: {
      'inventoryId': inventoryId,
      'splits': splits,
      'note': note,
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
