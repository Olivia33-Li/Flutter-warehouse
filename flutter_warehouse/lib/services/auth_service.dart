import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final _api = ApiService.instance.dio;

  Future<User> register({
    required String username,
    required String name,
    required String password,
  }) async {
    final response = await _api.post('/auth/register', data: {
      'username': username,
      'name': name,
      'password': password,
    });
    return _saveAndReturn(response.data);
  }

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return _saveAndReturn(response.data);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _api.post('/auth/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
  }

  Future<User> _saveAndReturn(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, data['accessToken']);
    await prefs.setString(AppConstants.refreshTokenKey, data['refreshToken']);
    final user = User.fromJson(data['user']);
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    return user;
  }
}
