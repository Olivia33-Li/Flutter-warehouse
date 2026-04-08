import 'api_service.dart';

class PasswordResetRequest {
  final String id;
  final String username;
  final String displayName;
  final String status; // pending | completed | rejected
  final String adminNote;
  final String userNote;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String resolvedBy;

  PasswordResetRequest({
    required this.id,
    required this.username,
    required this.displayName,
    required this.status,
    required this.adminNote,
    required this.userNote,
    required this.createdAt,
    this.resolvedAt,
    required this.resolvedBy,
  });

  factory PasswordResetRequest.fromJson(Map<String, dynamic> json) =>
      PasswordResetRequest(
        id: json['_id'] ?? '',
        username: json['username'] ?? '',
        displayName: json['displayName'] ?? '',
        status: json['status'] ?? 'pending',
        adminNote: json['adminNote'] ?? '',
        userNote: json['userNote'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt']).toLocal()
            : DateTime.now(),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt']).toLocal()
            : null,
        resolvedBy: json['resolvedBy'] ?? '',
      );

  String get statusLabel => switch (status) {
        'pending' => '待处理',
        'completed' => '已完成',
        'rejected' => '已拒绝',
        _ => status,
      };
}

class PasswordResetService {
  final _api = ApiService.instance.dio;

  /// Public — submit a reset request (no login required)
  Future<String> submitRequest({
    required String username,
    String? userNote,
  }) async {
    final response = await _api.post('/password-reset/request', data: {
      'username': username,
      if (userNote != null && userNote.isNotEmpty) 'userNote': userNote,
    });
    return response.data['message'] as String;
  }

  /// Admin — list all requests
  Future<List<PasswordResetRequest>> getAll({String? status}) async {
    final response = await _api.get('/password-reset', queryParameters: {
      if (status != null) 'status': status,
    });
    return (response.data as List)
        .map((e) => PasswordResetRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin — resolve a request
  Future<String> resolve({
    required String id,
    required String status, // 'completed' | 'rejected'
    String? adminNote,
    String? newPassword,
  }) async {
    final response = await _api.patch('/password-reset/$id/resolve', data: {
      'status': status,
      if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
      if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
    });
    return response.data['message'] as String;
  }

  /// Admin — delete a request record
  Future<void> remove(String id) async {
    await _api.delete('/password-reset/$id');
  }
}
