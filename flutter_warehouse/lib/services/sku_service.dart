import 'api_service.dart';
import '../models/sku.dart';

class SkuService {
  final _api = ApiService.instance.dio;

  Future<List<Sku>> getAll({String? search}) async {
    final response = await _api.get('/skus', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (response.data as List).map((e) => Sku.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    final response = await _api.get('/skus/$id');
    return response.data;
  }

  Future<Sku> create({
    required String sku,
    String? name,
    String? barcode,
    int? cartonQty,
  }) async {
    final response = await _api.post('/skus', data: {
      'sku': sku,
      if (name != null && name.isNotEmpty) 'name': name,
      if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
      if (cartonQty != null) 'cartonQty': cartonQty,
    });
    return Sku.fromJson(response.data);
  }

  Future<Sku> update(String id, {
    String? name,
    String? barcode,
    int? cartonQty,
  }) async {
    final response = await _api.patch('/skus/$id', data: {
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (cartonQty != null) 'cartonQty': cartonQty,
    });
    return Sku.fromJson(response.data);
  }

  Future<void> delete(String id) async {
    await _api.delete('/skus/$id');
  }
}
