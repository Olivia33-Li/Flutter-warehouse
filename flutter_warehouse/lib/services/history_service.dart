import 'api_service.dart';
import '../models/change_record.dart';

class HistoryService {
  final _api = ApiService.instance.dio;

  Future<Map<String, dynamic>> getAll({
    String? userId,
    String? action,
    String? entity,
    String? keyword,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _api.get('/history', queryParameters: {
      if (userId != null) 'userId': userId,
      if (action != null) 'action': action,
      if (entity != null) 'entity': entity,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
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
