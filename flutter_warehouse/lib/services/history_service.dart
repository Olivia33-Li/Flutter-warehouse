import 'api_service.dart';
import '../models/change_record.dart';

class HistoryService {
  final _api = ApiService.instance.dio;

  Future<Map<String, dynamic>> getAll({
    String? action,
    String? entity,
    String? businessAction,
    String? type,       // IN | OUT | ADJUST | TRANSFER — mapped to businessActions on backend
    String? skuCode,    // filters by "skuCode @ locationCode" in description
    String? keyword,
    String? startDate,
    String? endDate,
    String? userName,
    String? locationCode,
    bool? inventoryChangingOnly,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get('/audit-logs', queryParameters: {
      if (action != null) 'action': action,
      if (entity != null) 'entity': entity,
      if (businessAction != null) 'businessAction': businessAction,
      if (type != null) 'type': type,
      if (skuCode != null && skuCode.isNotEmpty) 'skuCode': skuCode,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (userName != null && userName.isNotEmpty) 'userName': userName,
      if (locationCode != null) 'locationCode': locationCode,
      if (inventoryChangingOnly == true) 'inventoryChangingOnly': 'true',
      'page': page,
      'limit': limit,
    });

    final data = response.data;
    return {
      'records': (data['records'] as List).map((e) => ChangeRecord.fromJson(e)).toList(),
      'total': data['total'],
      'page': data['page'],
    };
  }
}
