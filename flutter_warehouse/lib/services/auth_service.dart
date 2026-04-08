import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthService {
  final _api = ApiService.instance.dio;

  static const _recentAccountsKey = 'recent_accounts_v2';
  static const _maxRecentAccounts = 5;

  // In-memory user (same session, no prefs needed)
  static User? _memUser;

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
    // Register always persists (first-time setup flow)
    return _saveAndReturn(response.data, rememberMe: true);
  }

  Future<User> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _api.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return _saveAndReturn(response.data, rememberMe: rememberMe);
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

  /// Restores session on app startup.
  /// - In the same process: reads from static [_memUser].
  /// - After restart: only restores if remember-me was set.
  Future<User?> getCurrentUser() async {
    // Same process session
    if (_memUser != null) return _memUser;

    // Cross-restart: only when remember-me flag is set
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.rememberMeKey) != true) return null;

    final userJson = prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    try {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      // Warm up caches
      _memUser = user;
      AuthTokenCache.token = prefs.getString(AppConstants.tokenKey);
      AuthTokenCache.refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    // Clear in-memory session
    _memUser = null;
    AuthTokenCache.token = null;
    AuthTokenCache.refreshToken = null;

    // Clear persisted session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.rememberMeKey);
    // Recent accounts list is kept intentionally on logout
  }

  /// Updates stored user after a profile change (e.g. name edit, mustChangePassword cleared).
  Future<void> persistUser(User user) async {
    _memUser = user;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(AppConstants.rememberMeKey) == true) {
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    }
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

  Future<User> _saveAndReturn(Map<String, dynamic> data,
      {required bool rememberMe}) async {
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    // Always keep in memory for this session
    _memUser = user;
    AuthTokenCache.token = accessToken;
    AuthTokenCache.refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.rememberMeKey, rememberMe);

    if (rememberMe) {
      await prefs.setString(AppConstants.tokenKey, accessToken);
      await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    } else {
      // Clear any stale persisted session from a previous remember-me login
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.refreshTokenKey);
      await prefs.remove(AppConstants.userKey);
    }

    await _addRecentAccount(user);
    return user;
  }

  Future<void> _addRecentAccount(User user) async {
    final accounts = await getRecentAccounts();
    accounts.removeWhere((a) => a.username == user.username);
    accounts.insert(0, RecentAccount.fromUser(user));
    if (accounts.length > _maxRecentAccounts) {
      accounts.removeRange(_maxRecentAccounts, accounts.length);
    }
    await _persistRecentAccounts(accounts);
  }

  Future<void> _persistRecentAccounts(List<RecentAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _recentAccountsKey,
        jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }
}
