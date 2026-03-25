import 'api_service.dart';
import '../models/location.dart';

class LocationService {
  final _api = ApiService.instance.dio;

  Future<List<Location>> getAll({String? search}) async {
    final response = await _api.get('/locations', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return (response.data as List).map((e) => Location.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getOne(String id) async {
    final response = await _api.get('/locations/$id');
    return response.data;
  }

  Future<Location> create({required String code, String? description}) async {
    final response = await _api.post('/locations', data: {
      'code': code,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return Location.fromJson(response.data);
  }

  Future<Location> update(String id, {String? description}) async {
    final response = await _api.patch('/locations/$id', data: {
      if (description != null) 'description': description,
    });
    return Location.fromJson(response.data);
  }

  Future<void> check(String id, {required bool checked}) async {
    await _api.patch('/locations/$id/check', data: {'checked': checked});
  }

  Future<void> delete(String id) async {
    await _api.delete('/locations/$id');
  }

  Future<Map<String, dynamic>> transfer({
    required String sourceId,
    required String targetLocationId,
    List<String>? skuCodes,
    String? conflictResolution,
  }) async {
    final response = await _api.post('/locations/$sourceId/transfer', data: {
      'targetLocationId': targetLocationId,
      if (skuCodes != null) 'skuCodes': skuCodes,
      if (conflictResolution != null) 'conflictResolution': conflictResolution,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> copy({
    required String sourceId,
    required String targetLocationId,
    List<String>? skuCodes,
    String? conflictResolution,
  }) async {
    final response = await _api.post('/locations/$sourceId/copy', data: {
      'targetLocationId': targetLocationId,
      if (skuCodes != null) 'skuCodes': skuCodes,
      if (conflictResolution != null) 'conflictResolution': conflictResolution,
    });
    return response.data;
  }
}
