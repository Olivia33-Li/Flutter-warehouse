import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

/// Static in-memory token cache.
/// AuthService writes here on login/refresh; ApiService reads here.
/// Avoids circular imports while sharing session state within one app process.
class AuthTokenCache {
  static String? token;
  static String? refreshToken;
}

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _refreshToken();
          if (refreshed) {
            final token = await _getToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// In-memory first, then SharedPreferences fallback (for remember-me sessions).
  Future<String?> _getToken() async {
    if (AuthTokenCache.token != null) return AuthTokenCache.token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<bool> _refreshToken() async {
    try {
      // In-memory first
      String? refreshToken = AuthTokenCache.refreshToken;
      if (refreshToken == null) {
        final prefs = await SharedPreferences.getInstance();
        refreshToken = prefs.getString(AppConstants.refreshTokenKey);
      }
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${AppConstants.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess = response.data['accessToken'] as String;
      final newRefresh = response.data['refreshToken'] as String;

      // Always update in-memory cache
      AuthTokenCache.token = newAccess;
      AuthTokenCache.refreshToken = newRefresh;

      // Persist only when remember-me is enabled
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(AppConstants.rememberMeKey) == true) {
        await prefs.setString(AppConstants.tokenKey, newAccess);
        await prefs.setString(AppConstants.refreshTokenKey, newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Dio get dio => _dio;
}
