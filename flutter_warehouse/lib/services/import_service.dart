import 'package:dio/dio.dart';
import 'api_service.dart';

class ImportService {
  final _api = ApiService.instance.dio;

  Future<Map<String, dynamic>> importCsvBytes(List<int> bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _api.post('/import/csv', data: formData);
    return response.data;
  }
}
