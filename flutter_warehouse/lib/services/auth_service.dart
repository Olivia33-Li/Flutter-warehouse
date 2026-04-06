import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final _api = ApiService.instance.dio;

  static const _recentAccountsKey = 'recent_accounts_v2';
  static const _maxRecentAccounts = 5;

  // ── Auth ────────────────────────────────────────────────────────────────────

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
    try {
      return User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    // Recent accounts list is kept intentionally on logout
  }

  // ── Recent accounts ─────────────────────────────────────────────────────────

  Future<List<RecentAccount>> getRecentAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentAccountsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => RecentAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> removeRecentAccount(String username) async {
    final accounts = await getRecentAccounts();
    accounts.removeWhere((a) => a.username == username);
    await _persistRecentAccounts(accounts);
  }

  Future<void> clearRecentAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentAccountsKey);
  }

  // ── Internals ────────────────────────────────────────────────────────────────

  Future<User> _saveAndReturn(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, data['accessToken'] as String);
    await prefs.setString(AppConstants.refreshTokenKey, data['refreshToken'] as String);
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    await _addRecentAccount(user);
    return user;
  }

  Future<void> _addRecentAccount(User user) async {
    final accounts = await getRecentAccounts();
    // Remove existing entry for this username, then insert at front
    accounts.removeWhere((a) => a.username == user.username);
    accounts.insert(0, RecentAccount.fromUser(user));
    // Keep only the most recent N
    if (accounts.length > _maxRecentAccounts) {
      accounts.removeRange(_maxRecentAccounts, accounts.length);
    }
    await _persistRecentAccounts(accounts);
  }

  Future<void> _persistRecentAccounts(List<RecentAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentAccountsKey, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }
}
